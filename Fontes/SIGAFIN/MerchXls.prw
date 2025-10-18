#Include "Protheus.ch"
#Include "tbiconn.ch"
#Include "TopConn.ch"

/*---------------------------------------------------------
{Protheus.doc} 	merchXls
TODO 			Relatorio Excel para integração com Merchant
@author 	    Atlanta
@since 			30/12/2020
@version 		1.0
@type 			User Function
---------------------------------------------------------*/
User Function MerchXls()

	Local aBotoes	:= {}
	Local aSays		:= {}
	Private nOpcao	:= 0 

	//Tela de aviso e acesso aos parametros
	AAdd(aSays,"[GERAÇÃO DE ARQUIVO XLSX - INTEGRAÇÃO MERCHANT]")
	AAdd(aSays,"Esse programa irá listar os títulos em formato XLSX, conforme os parâmetros informados")

	AAdd(aBotoes,{ 5,.T.,{|| Parametros() } } )
	AAdd(aBotoes,{ 1,.T.,{|| nOpcao := 1, FechaBatch() }} )
	AAdd(aBotoes,{ 2,.T.,{|| FechaBatch() }} )        
	FormBatch( "[Integração Merchant] - Títulos em Atraso para Cobrança Externa", aSays, aBotoes )

    If nOpcao == 1
		Processa({|| RFINA001_Prc()})
	EndIf

Return(Nil)      

/*---------------------------------------------------------
{Protheus.doc} 	RFINA001_Prc
TODO 			Processamento Relatorio Excel para 
                integração com Merchant
@author 		Atlanta
@since 			30/12/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			User Function
---------------------------------------------------------*/
Static Function RFINA001_PRC()

    Local aArea     := GetArea()
    Local cAliasTMP := GetNextAlias()
    Local cExcel    := ""               // Configuração de cabeçalho da planilha
    Local cExcel1   := ""               // Dados
    Local cExcel2   := ""               // Configuração de rodapé da planilha
    Local _nActRow  := 1
    Local _cFileName:= ''
    Local _cLFile   := ''
    Local _nHandle  := 0
    Local _cFile    := ''


    Private cNatureza := GetMV("HB_MERCNAT")

    BeginSQL Alias cAliasTMP
        
        SELECT		  A1_FILIAL								                AS FILIAL
                    , A1_NOME								                AS CLIENTE
                    , A1_COD								                AS CODIGO_DEVEDOR
                    , A1_COD+A1_LOJA                                        AS CODLJ_DEVEDOR
                    , A1_NREDUZ								                AS NOME_FANTASIA
                    , CASE LEN(LTRIM(RTRIM(A1_COMPLEM)))
                        WHEN 0 THEN  A1_END
                        ELSE RTRIM(LTRIM(A1_END)) + ' - '+ RTRIM(LTRIM(A1_COMPLEM))	
                      END									                AS ENDERECO
                    , A1_BAIRRO								                AS BAIRRO
                    , A1_CEP								                AS CEP
                    , A1_MUN								                AS CIDADE
                    , A1_EST								                AS ESTADO
                    , A1_CGC								                AS CNPJ
                    , A1_INSCR								                AS INCRICAO_ESTADUAL
                    , A1_CONTATO							                AS CONTATO_DEVEDOR
                    , A1_EMAIL								                AS EMAIL_DEVEDOR
                    , A1_TEL								                AS TELEFONE_DEVEDOR	
                    , A1_ZZTEL2								                AS CELULAR_DEVEDOR
                    , E1_NUM					            			    AS NUMERO_TITULO
                    , E1_PARCELA               							    AS PARCELA_TITULO
			        ,CONVERT(VARCHAR, CONVERT(DATETIME, E1_VENCREA), 103)   AS VENCIMENTO_TITULO
                    , E1_SALDO								                AS VALOR_TITULO
                    , E1_DESCONT							                AS DESCONTO_TITULO
                    , E1_HIST								                AS OBS_TITULO
                    , E1_ACRESC                                             AS TAXA_PROTESTO
                    , E1_NATUREZ                                            
                    , E1_ZZOBSER                                            AS HISTORICO
        FROM 		SE1010 A
        INNER JOIN 	SA1010 B
        ON			A.E1_CLIENTE    = B.A1_COD
        AND			A.E1_LOJA 	    = B.A1_LOJA
        WHERE		A.E1_VENCREA  BETWEEN %Exp:MV_PAR01% And %Exp:MV_PAR02%
        AND         A.E1_PREFIXO  BETWEEN %Exp:MV_PAR03% And %Exp:MV_PAR04%
        AND         A.E1_NUM      BETWEEN %Exp:MV_PAR05% And %Exp:MV_PAR06%
        AND         A.E1_PARCELA  BETWEEN %Exp:MV_PAR07% And %Exp:MV_PAR08%
        AND         A.E1_TIPO     BETWEEN %Exp:MV_PAR09% And %Exp:MV_PAR10%
        AND         A.E1_CLIENTE  BETWEEN %Exp:MV_PAR11% And %Exp:MV_PAR12%
        AND         A.E1_LOJA     BETWEEN %Exp:MV_PAR13% And %Exp:MV_PAR14%
        AND         A.E1_VENCTO   BETWEEN %Exp:MV_PAR15% And %Exp:MV_PAR16%
        AND         A.E1_SALDO > 0
        AND         A.E1_NATUREZ NOT IN (%Exp:MV_PAR19%)
        AND			A.%NotDel%
        AND			B.%NotDel%
        ORDER BY 	A.E1_EMISSAO

    EndSQL

    _cFile := "c:\temp\Query_" + Dtos(dDatabase) + "_" + StrTran(Time(),":","") + ".TXT"
	MemoWrite(_cFile, GetLastQuery()[2])


    (cAliasTMP)->(dbGotop())
    While (cAliasTMP)->( ! Eof())
        _nActRow ++
        (cAliasTMP)->(dbSkip())
    EndDo

    (cAliasTMP)->(dbGotop())

    cExcel := '<?xml version="1.0"?>'
    cExcel += '<?mso-application progid="Excel.Sheet"?>'
    cExcel += '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"'
    cExcel += ' xmlns:o="urn:schemas-microsoft-com:office:office"'
    cExcel += ' xmlns:x="urn:schemas-microsoft-com:office:excel"'
    cExcel += ' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"'
    cExcel += ' xmlns:html="http://www.w3.org/TR/REC-html40">'
    cExcel += ' <DocumentProperties xmlns="urn:schemas-microsoft-com:office:office">'
    cExcel += '  <Author>Merchant</Author>'
    cExcel += '  <LastAuthor>Carlos Eduardo Saturnino</LastAuthor>'
    cExcel += '  <LastPrinted>2021-03-09T14:52:40Z</LastPrinted>'
    cExcel += '  <Created>2015-08-17T12:26:55Z</Created>'
    cExcel += '  <LastSaved>2021-01-04T20:06:06Z</LastSaved>'
    cExcel += '  <Company>Microsoft</Company>'
    cExcel += '  <Version>16.00</Version>'
    cExcel += ' </DocumentProperties>'
    cExcel += ' <OfficeDocumentSettings xmlns="urn:schemas-microsoft-com:office:office">'
    cExcel += '  <AllowPNG/>'
    cExcel += ' </OfficeDocumentSettings>'
    cExcel += ' <ExcelWorkbook xmlns="urn:schemas-microsoft-com:office:excel">'
    cExcel += '  <WindowHeight>7695</WindowHeight>'
    cExcel += '  <WindowWidth>20490</WindowWidth>'
    cExcel += '  <WindowTopX>32767</WindowTopX>'
    cExcel += '  <WindowTopY>32767</WindowTopY>'
    cExcel += '  <ProtectStructure>False</ProtectStructure>'
    cExcel += '  <ProtectWindows>False</ProtectWindows>'
    cExcel += ' </ExcelWorkbook>'
    cExcel += ' <Styles>'
    cExcel += '  <Style ss:ID="Default" ss:Name="Normal">'
    cExcel += '   <Alignment ss:Vertical="Bottom"/>'
    cExcel += '   <Borders/>'
    cExcel += '   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000"/>'
    cExcel += '   <Interior/>'
    cExcel += '   <NumberFormat/>'
    cExcel += '   <Protection/>'
    cExcel += '  </Style>'
    cExcel += '  <Style ss:ID="s62">'
    cExcel += '   <NumberFormat ss:Format="00000"/>'
    cExcel += '  </Style>'
    cExcel += '  <Style ss:ID="s63">'
    cExcel += '   <NumberFormat ss:Format="000000000\-00"/>'
    cExcel += '  </Style>'
    cExcel += '  <Style ss:ID="s64">'
    cExcel += '   <NumberFormat ss:Format="Short Date"/>'
    cExcel += '  </Style>'
    cExcel += '  <Style ss:ID="s65">'
    cExcel += '   <NumberFormat'
    cExcel += '    ss:Format="_-&quot;R$&quot;\ * #,##0.00_-;\-&quot;R$&quot;\ * #,##0.00_-;_-&quot;R$&quot;\ * &quot;-&quot;??_-;_-@_-"/>'
    cExcel += '  </Style>'
    cExcel += '  <Style ss:ID="s67">'
    cExcel += '   <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>'
    cExcel += '   <Borders>'
    cExcel += '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="2"/>'
    cExcel += '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>'
    cExcel += '   </Borders>'
    cExcel += '   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000"/>'
    cExcel += '  </Style>'
    cExcel += '  <Style ss:ID="s71">'
    cExcel += '   <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>'
    cExcel += '   <Borders>'
    cExcel += '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="2"/>'
    cExcel += '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>'
    cExcel += '   </Borders>'
    cExcel += '   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#FF0000"'
    cExcel += '    ss:Bold="1"/>'
    cExcel += '   <Interior ss:Color="#EEECE1" ss:Pattern="Solid"/>'
    cExcel += '  </Style>'
    cExcel += '  <Style ss:ID="s72">'
    cExcel += '   <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>'
    cExcel += '   <Borders>'
    cExcel += '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>'
    cExcel += '   </Borders>'
    cExcel += '   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#FF0000"/>'
    cExcel += '   <Interior ss:Color="#EEECE1" ss:Pattern="Solid"/>'
    cExcel += '  </Style>'
    cExcel += '  <Style ss:ID="s73">'
    cExcel += '   <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>'
    cExcel += '   <Borders>'
    cExcel += '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="2"/>'
    cExcel += '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>'
    cExcel += '   </Borders>'
    cExcel += '   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#FF0000"/>'
    cExcel += '   <Interior ss:Color="#EEECE1" ss:Pattern="Solid"/>'
    cExcel += '  </Style>'
    cExcel += '  <Style ss:ID="s74">'
    cExcel += '   <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>'
    cExcel += '   <Borders>'
    cExcel += '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>'
    cExcel += '   </Borders>'
    cExcel += '   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#FF0000"/>'
    cExcel += '   <Interior ss:Color="#EEECE1" ss:Pattern="Solid"/>'
    cExcel += '   <NumberFormat ss:Format="00000000"/>'
    cExcel += '  </Style>'
    cExcel += '  <Style ss:ID="s75">'
    cExcel += '   <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>'
    cExcel += '   <Borders>'
    cExcel += '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>'
    cExcel += '   </Borders>'
    cExcel += '   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#FF0000"/>'
    cExcel += '   <Interior ss:Color="#EEECE1" ss:Pattern="Solid"/>'
    cExcel += '   <NumberFormat ss:Format="@"/>'
    cExcel += '  </Style>'
    cExcel += '  <Style ss:ID="s76">'
    cExcel += '   <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>'
    cExcel += '   <Borders>'
    cExcel += '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>'
    cExcel += '   </Borders>'
    cExcel += '   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#FF0000"'
    cExcel += '    ss:Bold="1"/>'
    cExcel += '   <Interior ss:Color="#D8E4BC" ss:Pattern="Solid"/>'
    cExcel += '   <NumberFormat ss:Format="0"/>'
    cExcel += '  </Style>'
    cExcel += '  <Style ss:ID="s77">'
    cExcel += '   <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>'
    cExcel += '   <Borders>'
    cExcel += '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="2"/>'
    cExcel += '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>'
    cExcel += '   </Borders>'
    cExcel += '   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#FF0000"'
    cExcel += '    ss:Bold="1"/>'
    cExcel += '   <Interior ss:Color="#D8E4BC" ss:Pattern="Solid"/>'
    cExcel += '   <NumberFormat ss:Format="0"/>'
    cExcel += '  </Style>'
    cExcel += '  <Style ss:ID="s78">'
    cExcel += '   <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>'
    cExcel += '   <Borders>'
    cExcel += '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="2"/>'
    cExcel += '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>'
    cExcel += '   </Borders>'
    cExcel += '   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#FF0000"/>'
    cExcel += '   <Interior ss:Color="#EEECE1" ss:Pattern="Solid"/>'
    cExcel += '   <NumberFormat ss:Format="@"/>'
    cExcel += '  </Style>'
    cExcel += '  <Style ss:ID="s79">'
    cExcel += '   <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>'
    cExcel += '   <Borders>'
    cExcel += '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>'
    cExcel += '   </Borders>'
    cExcel += '   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#FF0000"/>'
    cExcel += '   <Interior ss:Color="#EEECE1" ss:Pattern="Solid"/>'
    cExcel += '   <NumberFormat ss:Format="yyyymmdd"/>'
    cExcel += '  </Style>'
    cExcel += '  <Style ss:ID="s80">'
    cExcel += '   <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>'
    cExcel += '   <Borders>'
    cExcel += '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>'
    cExcel += '   </Borders>'
    cExcel += '   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#FF0000"/>'
    cExcel += '   <Interior ss:Color="#EEECE1" ss:Pattern="Solid"/>'
    cExcel += '   <NumberFormat ss:Format="Fixed"/>'
    cExcel += '  </Style>'
    cExcel += '  <Style ss:ID="s81">'
    cExcel += '   <Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/>'
    cExcel += '   <Borders>'
    cExcel += '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1"/>'
    cExcel += '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2"/>'
    cExcel += '   </Borders>'
    cExcel += '   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#FF0000"/>'
    cExcel += '   <Interior ss:Color="#EEECE1" ss:Pattern="Solid"/>'
    cExcel += '   <NumberFormat ss:Format="Standard"/>'
    cExcel += '  </Style>'
    cExcel += ' </Styles>'
    cExcel += ' <Worksheet ss:Name="PLANILHA BORDERO">'
    cExcel += '  <Table ss:ExpandedColumnCount="26" ss:ExpandedRowCount="'+ cValtoChar(_nActRow) +'" x:FullColumns="1"'
    cExcel += '   x:FullRows="1" ss:DefaultRowHeight="15">'
    cExcel += '   <Column ss:Index="2" ss:Width="35.25"/>'
    cExcel += '   <Column ss:Width="45"/>'
    cExcel += '   <Column ss:Width="53.25"/>'
    cExcel += '   <Column ss:Width="128.25"/>'
    cExcel += '   <Column ss:AutoFitWidth="0" ss:Width="54"/>'
    cExcel += '   <Column ss:Width="109.5"/>'
    cExcel += '   <Column ss:Width="53.25"/>'
    cExcel += '   <Column ss:StyleID="s62" ss:Width="53.25"/>'
    cExcel += '   <Column ss:Width="53.25" ss:Span="1"/>'
    cExcel += '   <Column ss:Index="12" ss:StyleID="s63" ss:Width="96"/>'
    cExcel += '   <Column ss:StyleID="s63" ss:Width="76.5"/>'
    cExcel += '   <Column ss:Width="53.25"/>'
    cExcel += '   <Column ss:AutoFitWidth="0" ss:Width="118.5"/>'
    cExcel += '   <Column ss:Width="59.25"/>'
    cExcel += '   <Column ss:Width="63"/>'
    cExcel += '   <Column ss:AutoFitWidth="0" ss:Width="50.25"/>'
    cExcel += '   <Column ss:Index="20" ss:StyleID="s64" ss:Width="71.25"/>'
    cExcel += '   <Column ss:StyleID="s65" ss:Width="76.5"/>'
    cExcel += '   <Column ss:StyleID="s65" ss:Width="71.25"/>'
    cExcel += '   <Column ss:StyleID="s65" ss:AutoFitWidth="0" ss:Width="61.5"/>'
    cExcel += '   <Column ss:Width="71.25" ss:Span="1"/>'
    cExcel += '   <Column ss:Index="26" ss:AutoFitWidth="0" ss:Width="161.25"/>'
    cExcel += '   <Row ss:AutoFitHeight="0" ss:Height="75.75" ss:StyleID="s67">'
    cExcel += '    <Cell ss:StyleID="s71"><Data ss:Type="String">VERSAO</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s72"><Data ss:Type="String">FILIAL</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s72"><Data ss:Type="String">CLIENTE</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s73"><Data ss:Type="String">CODIGO DEVEDOR</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s71"><Data ss:Type="String">RAZAO SOCIAL COMPLETA DO DEVEDOR</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s72"><Data ss:Type="String">NOME FANTASIA DEVEDOR</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s72"><Data ss:Type="String">ENDERECO DEVEDOR</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s72"><Data ss:Type="String">BAIRRO DEVEDOR</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s74"><Data ss:Type="String">CEP DEVEDOR</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s72"><Data ss:Type="String">CIDADE DEVEDOR</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s72"><Data ss:Type="String">UF DEVEDOR</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s75"><Data ss:Type="String">CNPJ OU CPF DEVEDOR</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s75"><Data ss:Type="String">INSCRICAO ESTADUAL DEVEDOR</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s76"><Data ss:Type="String">CONTATO DEVEDOR</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s76"><Data ss:Type="String">E-MAIL DEVEDOR um somente</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s76"><ss:Data ss:Type="String"'
    cExcel += '      xmlns="http://www.w3.org/TR/REC-html40"><B><Font html:Color="#FF0000">TELEFONE DEVEDOR </Font><Font'
    cExcel += '        html:Color="#000080">sem DDD</Font><Font html:Color="#FF0000"> um somente</Font></B></ss:Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s77"><ss:Data ss:Type="String"'
    cExcel += '      xmlns="http://www.w3.org/TR/REC-html40"><B><Font html:Color="#FF0000">CELULAR DEVEDOR </Font><Font'
    cExcel += '        html:Color="#003366">Sem DDD</Font><Font html:Color="#FF0000"> um somente</Font></B></ss:Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s78"><Data ss:Type="String">NUMERO TITULO</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s75"><Data ss:Type="String">PARCELA TITULO</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s79"><Data ss:Type="String">DATA VENCIMENTO</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s80"><Data ss:Type="String">VALOR TITULO</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s81"><Data ss:Type="String">VALOR ABATIMENTO</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s81"><Data ss:Type="String">TAXA DE PROSTESTO</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s73"><Data ss:Type="String">OBSERVACAO</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s73"><Data ss:Type="String">PROTESTADO</Data></Cell>'
    cExcel += '    <Cell ss:StyleID="s73"><Data ss:Type="String">HISTORICO</Data></Cell>'
    cExcel += '   </Row>'


     While (cAliasTMP)->( !Eof() ) .And. ! (Alltrim((cAliasTMP)->E1_NATUREZ)  $ MV_PAR19)

        cExcel1 += '   <Row ss:AutoFitHeight="0">'
        cExcel1 += '    <Cell><Data ss:Type="String">1501</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + FwFilial("SE1") + '</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">7180</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + (cAliasTMP)->CODLJ_DEVEDOR + '</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + Alltrim((cAliasTMP)->CLIENTE) + '</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + Alltrim((cAliasTMP)->NOME_FANTASIA) + '</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + Alltrim((cAliasTMP)->ENDERECO) + '</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + Alltrim((cAliasTMP)->BAIRRO) + '</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + (cAliasTMP)->CEP + '</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + Alltrim((cAliasTMP)->CIDADE) + '</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + (cAliasTMP)->ESTADO + '</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + Alltrim((cAliasTMP)->CNPJ) + '</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + Alltrim((cAliasTMP)->INCRICAO_ESTADUAL) + '</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + Alltrim((cAliasTMP)->CONTATO_DEVEDOR) + '</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + Alltrim((cAliasTMP)->EMAIL_DEVEDOR) + '</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + Alltrim((cAliasTMP)->TELEFONE_DEVEDOR) + '</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + alltrim((cAliasTMP)->CELULAR_DEVEDOR) + '</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + Alltrim((cAliasTMP)->NUMERO_TITULO) + '</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + Alltrim((cAliasTMP)->PARCELA_TITULO) +'</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + Alltrim((cAliasTMP)->VENCIMENTO_TITULO) +'</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + cValtoChar((cAliasTMP)->VALOR_TITULO) + '</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + cValtoChar((cAliasTMP)->DESCONTO_TITULO) + '</Data></Cell>'
        cExcel1 += '    <Cell><Data ss:Type="String">' + cValtoChar((cAliasTMP)->TAXA_PROTESTO) + '</Data></Cell>'
        cExcel1 += '    <Cell ss:StyleID="s65"><Data ss:Type="String">' + Alltrim((cAliasTMP)->OBS_TITULO) + '</Data></Cell>'
        cExcel1 += '    <Cell ss:StyleID="s65"><Data ss:Type="String">S</Data></Cell>'
        cExcel1 += '    <Cell ss:StyleID="s65"><Data ss:Type="String">' + Alltrim((cAliasTMP)->HISTORICO) + '</Data></Cell>'
        cExcel1 += '   </Row>'

        (cAliasTMP)->(dbSkip())

    End 

    cExcel2 += '  </Table>'
    cExcel2 += '  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">'
    cExcel2 += '   <PageSetup>'
    cExcel2 += '    <Layout x:Orientation="Landscape"/>'
    cExcel2 += '    <Header x:Margin="0.31496062992125984"/>'
    cExcel2 += '    <Footer x:Margin="0.31496062992125984"/>'
    cExcel2 += '    <PageMargins x:Bottom="0.78740157480314965" x:Left="0.19685039370078741"'
    cExcel2 += '     x:Right="0.19685039370078741" x:Top="0.78740157480314965"/>'
    cExcel2 += '   </PageSetup>'
    cExcel2 += '   <Unsynced/>'
    cExcel2 += '   <FitToPage/>'
    cExcel2 += '   <Print>'
    cExcel2 += '    <FitHeight>999</FitHeight>'
    cExcel2 += '    <ValidPrinterInfo/>'
    cExcel2 += '    <PaperSizeIndex>9</PaperSizeIndex>'
    cExcel2 += '    <Scale>40</Scale>'
    cExcel2 += '    <HorizontalResolution>600</HorizontalResolution>'
    cExcel2 += '    <VerticalResolution>600</VerticalResolution>'
    cExcel2 += '   </Print>'
    cExcel2 += '   <TabColorIndex>56</TabColorIndex>'
    cExcel2 += '   <Zoom>74</Zoom>'
    cExcel2 += '   <Selected/>'
    cExcel2 += '   <LeftColumnVisible>8</LeftColumnVisible>'
    cExcel2 += '   <Panes>'
    cExcel2 += '    <Pane>'
    cExcel2 += '     <Number>3</Number>'
    cExcel2 += '     <ActiveRow>2</ActiveRow>'
    cExcel2 += '     <ActiveCol>25</ActiveCol>'
    cExcel2 += '    </Pane>'
    cExcel2 += '   </Panes>'
    cExcel2 += '   <ProtectObjects>False</ProtectObjects>'
    cExcel2 += '   <ProtectScenarios>False</ProtectScenarios>'
    cExcel2 += '  </WorksheetOptions>'
    cExcel2 += ' </Worksheet>'
    cExcel2 += '</Workbook>'

	// Atribui o nome ao arquivo DDMMAA
	_cFileName	:= MV_PAR18 + GravaData(dDataBase,.F.,4) + '.XML'

	// Formata o caminho de criação do Arquivo
	_cLFile     := MV_PAR17 + "\" + _cFileName
	
	// Cria o Arquivo
	_nHandle := FCreate(_cLFile)

	// Grava o Cabealho do Pedido de Vendas
	//FWRITE(_nHandle,cExcel) 
    FWRITE(_nHandle,cExcel+cExcel1+cExcel2) 

  	// Fecha o Arquivo
	FCLOSE(_nHandle)

	// Avisa em caso de erro de gravação do arquivo
	If _nHandle == -1 
		If !lJob
			MsgAlert('Erro de gravação do arquivo no disco. Arquivo ' + _cFileName )
			Conout(_cFileName + Space( 17 - Len(_cFileName) ) + '. Erro de gravação do arquivo no disco')
		Endif
	Else
        Aviso("MerchXLS","O Arquivo será gravado com a extensão XML por motivos de compatibilidade de lay-out do modelo. Caso necessário, salve-o com a extensão XLSX !!!" ,{"OK"})
        ShellExecute("open",_cLFile,"","",5)
    Endif
	

    RestArea(aArea)

Return()

/*---------------------------------------------------------
{Protheus.doc} 	Parametros
TODO 			Criação do Parambox
@author 		Atlanta
@since 			30/12/2020
@version 		1.0
@type 			User Function
---------------------------------------------------------*/
Static Function Parametros()

	Private cCadastro	:= "Arquivo XLSX - Merchant" 	      
	Private cLoad 		:= ""	                                		
	Private aParamBox	:= {}
	Private aRet		:= {}  
	Private nQtdTit		:= 0
	Private nTotal		:= 0
	Private lCanSave	:= .F.
	Private lUserSave 	:= .F.
	Private lCentered 	:= .T. 
    Private bVldParams	:= {|| VldParams() }    
    Private cExcel      := ''
    Private cExcelTrb   := ''

	//Parametros da rotina
	aAdd(aParamBox, {1,"Emissão De"                 ,dDataBase,"","","","",60,.T.})                                 // 01
	aAdd(aParamBox, {1,"Emissão Ate"                ,dDataBase,"","","","",60,.T.})                                 // 02
	aAdd(aParamBox, {1,"Prefixo De"                 ,Space(Len(SE1->E1_PREFIXO)),"","","","",30,.F.})               // 03
	aAdd(aParamBox, {1,"Prefixo Ate"                ,Replicate("z", Len(SE1->E1_PREFIXO)),"","","","",30,.T.})      // 04
	aAdd(aParamBox, {1,"Titulo De"                  ,Space(Len(SE1->E1_NUM)),"","","","",50,.F.})                   // 05
	aAdd(aParamBox, {1,"Titulo Ate"                 ,Replicate("z", Len(SE1->E1_NUM)),"","","","",50,.T.})          // 06
	aAdd(aParamBox, {1,"Parcela De"                 ,Space(Len(SE1->E1_PARCELA)),"","","","",15,.F.})               // 07
	aAdd(aParamBox, {1,"Parcela Ate"                ,Replicate("z", Len(SE1->E1_PARCELA)),"","","","",15,.T.})      // 08
	aAdd(aParamBox, {1,"Tipo De"                    ,Space(Len(SE1->E1_TIPO)),"","","","",30,.F.})                  // 09
	aAdd(aParamBox, {1,"Tipo Ate"                   ,Replicate("z", Len(SE1->E1_TIPO)),"","","","",30,.T.})         // 10
	aAdd(aParamBox, {1,"Cliente De"                 ,Space(Len(SE1->E1_CLIENTE)),"","","SA1","",45,.F.})            // 11
	aAdd(aParamBox, {1,"Cliente Ate"                ,Replicate("z", Len(SE1->E1_CLIENTE)),"","","SA1","",45,.T.})   // 12
	aAdd(aParamBox, {1,"Loja De"                    ,Space(Len(SE1->E1_LOJA)),"","","","",20,.F.})                  // 13
	aAdd(aParamBox, {1,"Loja Ate"                   ,Replicate("z", Len(SE1->E1_LOJA)),"","","","",20,.T.})         // 14
	aAdd(aParamBox, {1,"Vencimento Real De"         ,CtoD(""),"","","","",60,.T.})                                  // 15
	aAdd(aParamBox, {1,"Vencimento Real Ate"        ,CtoD(""),"","","","",60,.T.})                                  // 16
    aAdd(aParamBox, {1,"Diretório Gavação"          ,"c:\temp\","","","","",250,.T.})                               // 17
    aAdd(aParamBox, {1,"Nome do Arquivo"            ,"Planilha_Merchant","","","","",250,.T.})                      // 18
    aAdd(aParamBox, {1,"Naturezas a desconsiderar"  ,GetMV("HB_MERCNAT"),"","","","",250,.T.})                      // 19

    ParamBox(aParambox, "Parâmetros", @aRet, /*bVldParams*/, , lCentered, , , , cLoad, lCanSave, lUserSave)
    
Return(nOpcao)
