#include 'protheus.ch'
#include 'fwprintsetup.ch'
#include 'rptdef.ch'
#include 'danfeetiqueta.ch'
#Include 'topconn.ch'

//-------------------------------------------------------------------
/*/{Protheus.doc} ImpDfEtq
Impressão de danfe simplificada - Etiqueta

@param		cUrl			Endereço do Web Wervice no TSS
            cIdEnt			Entidade do TSS para processamento
			lUsaColab		Totvs Colaboração ou não
/*/
//-------------------------------------------------------------------
User function ImpEtiqueta() //(cUrl, cIdEnt, lUsaColab)

	Local lOk        := .F.
	Local aArea      := {}
	Local aAreaCB5   := {}
	Local aAreaSF3   := {}
	Local aAreaSF2   := {}
	Local aAreaSF1   := {}
	Local aAreaSA1   := {}
	Local aAreaSA2   := {}
	Local cNotaIni   := ""
	Local cNotaFim   := ""
	Local cSerie     := ""
	Local dDtIni     := ctod("")
	Local dDtFim     := ctod("")
	Local nTipoDoc   := 0
	Local nTipImp    := 0
	Local cLocImp    := ""
	Local nTamSerie  := 0
	Local lSdoc      := .F.
	Local cQuery  	 := ""
	Local lMv_Logod  := .F.
	Local cLogo      := ""
	Local cLogoD	 := ""
	Local oPrinter   := nil
	Local oSetup     := nil
	Local nLinha     := 0
	Local nColuna    := 0
	Local cGrpCompany:= ""
	Local cCodEmpGrp := ""
	Local cUnitGrp	 := ""
	Local cFilGrp	 := ""
	Local cDescLogo  := ""
	Local oFontTit   := nil
	Local oFontInf   := nil
	Local nAtual     := 0
	Local nTotal     := 0
	Local nNotas     := 0
	Local aNotas     := {}
	Local nContDanfe := 0

    /*
    Local aParam     := {}
	Local cAviso     := ""
	Local cErro      := ""
    Local cProtocolo := ""
    Local cDpecProt  := ""
    Local cNota      := ""
	Local cXml       := ""
    Local oTotal     := nil
    Local cTotNota   := ""
    Local cHautNfe   := ""
    Local dDautNfe   := ctod("")
    Local aNFe       := {}
    Local aEmit      := {}
    Local aDest      := {}
    Local cCgc       := ""
    Local cNome      := ""
    Local cInscr     := ""
    Local cUF        := ""
    Local lSeek      := .F.
    Local cCodCliFor := ""
    Local cLoja      := ""
    */
	default cUrl      := "" //PARAMIXB[1]
	default cIdEnt    := "" //PARAMIXB[2]
	default lUsaColab := .F.//PARAMIXB[3]

	private oRetNF   := nil
	private oNFe     := nil

	Begin sequence

		aArea := getArea()

		dbSelectArea("CB5")
		aAreaCB5 := CB5->(getArea())

		dbSelectArea("SF3")
		aAreaSF3 := SF3->(getArea())

		dbSelectArea("SF2")
		aAreaSF2 := SF2->(getArea())

		dbSelectArea("SF1")
		aAreaSF1 := SF1->(getArea())

		dbSelectArea("SA1")
		aAreaSA1 := SA1->(getArea())

		dbSelectArea("SA2")
		aAreaSA2 := SA2->(getArea())

		If !Pergunte("NFDANFETIQ",.T.)
			break
		EndIf

		cNotaIni := MV_PAR01 // Nota Inicial
		cNotaFim := MV_PAR02 // Nota Final
		cSerie   := MV_PAR03 // Serie
		dDtIni   := MV_PAR04 // Data de emissão Inicial
		dDtFim   := MV_PAR05 // Data de emissão Final
		nTipoDoc := MV_PAR06 // Tipo de Operação (1 - Entrada / 2 - Saída)
		nTipImp  := MV_PAR07 // Tipo de Impressora (1 - Térmica / 2 - Normal)
		cLocImp  := MV_PAR08 // Impressora

    /*
    // Validações para impressoras termicas
    if nTipImp == 1
        if empty(cLocImp)
     		Help(NIL, NIL, STR0001, NIL, STR0002, 1, 0, NIL, NIL, NIL, NIL, NIL, {STR0003}) //Local de impressão não informado., Informe um Local de impressão cadastrado., Acesse a rotina 'Locais de Impressão'.
            break
        else
            CB5->(dbSetOrder(1))
            if !CB5->(DbSeek( xFilial("CB5") + padR(cLocImp, GetSX3Cache("CB5_CODIGO", "X3_TAMANHO")) )) .or. !CB5SetImp(cLocImp)
                Help(NIL, NIL, STR0004 + " - " + alltrim(cLocImp) + ".", NIL, STR0002, 1, 0, NIL, NIL, NIL, NIL, NIL, {STR0003}) //Local de impressão não encontrado, Informe um Local de impressão cadastrado., Acesse a rotina 'Locais de Impressão'.
                break
            endif
        endif
    endif
    */

		if val(cNotaIni) > val(cNotaFim)
			Help(NIL, NIL, STR0005, NIL, STR0006, 1, 0, NIL, NIL, NIL, NIL, NIL, {STR0007}) //Valores de numeração de documentos inválidos., Informe um intervalo válido de notas., Verifique as informações do intervalo de notas.
			break
		endif

		nTamSerie := GetSX3Cache("F3_SERIE", "X3_TAMANHO")
		lSdoc := nTamSerie == 14
		cSerie := Padr(cSerie, nTamSerie )

		cAliasQry := getNextAlias()

		cQuery := "SELECT F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, A1_NOME, A1_END, A1_COMPLEM, F2_CHVNFE, A1_CGC, "
		cQuery += "A1_EST, A1_COD_MUN, A1_MUN, A1_BAIRRO, A1_CEP, A1_REGIAO, F2_VOLUME1 "
		cQuery += "FROM " + Retsqlname("SF2") + " SF2, " + Retsqlname("SA1") + " SA1 "
		cQuery += "WHERE 0=0 "
		cQuery += "AND SF2.F2_CLIENTE   = SA1.A1_COD "
		cQuery += "AND SF2.F2_LOJA      = SA1.A1_LOJA "
		cQuery += "AND SF2.F2_DOC      >= '" + cNotaIni + "' "
		cQuery += "AND SF2.F2_DOC      <= '" + cNotaFim + "' "
		cQuery += "AND SF2.F2_SERIE     = '" + cSerie + "' "
		cQuery += "AND (SF2.F2_EMISSAO >= '" + DTOS(dDtIni) + "' AND SF2.F2_EMISSAO <= '" + DTOS(dDtFim) + "')"
		cQuery += "AND SF2.D_E_L_E_T_   = '' "
		cQuery += "AND SA1.D_E_L_E_T_   = '' "
		cQuery += "ORDER BY 1"

		TCQuery cQuery NEW ALIAS (cAliasQry)

		//Conta quantos registros existem, e seta no tamanho da régua
		Count To nTotal

		(cAliasQry)->(dbGoTop())

		While !((cAliasQry)->(Eof()))

			AAdd(aNotas,{(cAliasQry)->F2_DOC   ,;
				(cAliasQry)->F2_SERIE  ,;
				(cAliasQry)->F2_CLIENTE,;
				(cAliasQry)->F2_LOJA   ,;
				(cAliasQry)->A1_NOME   ,;
				(cAliasQry)->A1_END    ,;
				(cAliasQry)->A1_COMPLEM,;
				(cAliasQry)->F2_CHVNFE ,;
				(cAliasQry)->A1_CGC    ,;
				(cAliasQry)->A1_EST    ,;
				(cAliasQry)->A1_BAIRRO ,;
				(cAliasQry)->A1_CEP    ,;
				(cAliasQry)->A1_COD_MUN,;
				(cAliasQry)->A1_MUN    ,;
				(cAliasQry)->A1_REGIAO ,;
				(cAliasQry)->F2_VOLUME1})

			nAtual++
			(cAliasQry)->(DbSkip())

		EndDo

		If val(cNotaIni) == 0 .or. val(cNotaFim) == 0
			Help(NIL, NIL, STR0008, NIL, STR0006, 1, 0, NIL, NIL, NIL, NIL, NIL, {STR0007}) //Documentos não encontrados para impressão do DANFE., Informe um intervalo válido de notas., Informe um intervalo válido de notas.
			break
		endif

		If nTipImp == 2

			oPrinter := FWMSPrinter():New("DANFE_ETIQUETA_" + cIdEnt + "_" + Dtos(MSDate())+StrTran(Time(),":",""),,.F.,,.T.,,,,,.F.)
			oSetup   := FWPrintSetup():New(PD_ISTOTVSPRINTER + PD_DISABLEORIENTATION + PD_DISABLEPAPERSIZE + PD_DISABLEPREVIEW + PD_DISABLEMARGIN,"DANFE SIMPLIFICADA")
			oSetup:SetPropert(PD_PRINTTYPE   , 2) //Spool
			oSetup:SetPropert(PD_ORIENTATION , 2)
			oSetup:SetPropert(PD_DESTINATION , 1)
			oSetup:SetPropert(PD_MARGIN , {0,0,0,0})
			oSetup:SetPropert(PD_PAPERSIZE   , 2)

			If !oSetup:Activate() == PD_OK
				Break
			EndIf

			lMv_Logod  := If(GetNewPar("MV_LOGOD", "N" ) == "S", .T., .F.   )

			If lMv_Logod
				cGrpCompany	:= alltrim(FWGrpCompany())
				cCodEmpGrp	:= alltrim(FWCodEmp())
				cUnitGrp	:= alltrim(FWUnitBusiness())
				cFilGrp		:= alltrim(FWFilial())

				If !empty(cUnitGrp)
					cDescLogo := cGrpCompany + cCodEmpGrp + cUnitGrp + cFilGrp
				Else
					cDescLogo := cEmpAnt + cFilAnt
				EndIf

				cLogoD := GetSrvProfString("Startpath","") + "DANFE" + cDescLogo + ".BMP"
				If !file(cLogoD)
					cLogoD	:= GetSrvProfString("Startpath","") + "DANFE" + cEmpAnt + ".BMP"
					If !file(cLogoD)
						lMv_Logod := .F.
					EndIf
				EndIf
			EndIf

			If lMv_Logod
				cLogo := cLogoD
			Else
				cLogo := FisxLogo("1")
			EndIf

			oFontTit      := TFont():New( "Arial", , -8, .T.) //Fonte para os titulos
			oFontTit:Bold := .T.						      //Setado negrito
			oFontInf      := TFont():New( "Arial", , -8, .T.) //Fonte para as informações
			oFontInf:Bold := .F.						      //Setado negrito := .F.

			oPrinter:SetPortrait()	//oPrinter:SetLandscape() //Define a orientacao como paisagem
			oPrinter:setPaperSize(9) 	                      //Define tipo papel A4
			oPrinter:setCopies(val(oSetup:cQtdCopia))

			If oSetup:GetProperty(PD_PRINTTYPE) == IMP_PDF
				oPrinter:nDevice  := IMP_PDF
				oPrinter:cPathPDF := if( empty(oSetup:aOptions[PD_VALUETYPE]), SuperGetMV('MV_RELT',,"\SPOOL\") , oSetup:aOptions[PD_VALUETYPE] )
			elseIf oSetup:GetProperty(PD_PRINTTYPE) == IMP_SPOOL
				oPrinter:nDevice  := IMP_SPOOL
				fwWriteProfString(GetPrinterSession(),"DEFAULT", oSetup:aOptions[PD_VALUETYPE], .T.)
				oPrinter:cPrinter := oSetup:aOptions[PD_VALUETYPE]
			Endif

		endif

		If Empty(aNotas)
			Help(NIL, NIL, STR0009, NIL, STR0010, 1, 0, NIL, NIL, NIL, NIL, NIL, {STR0011})// STR0009 - Não foram Localizados os XMLs para geração do DANFE etiqueta.
			Break                                                                          // STR0010 - Verifique se o(s) documento(s) consta(m) como autorizado(s) através da rotina Monitor.
		EndIf

		aEmit := array(9)
		aEmit[1] := RTRIM(SM0->M0_NOMECOM)
		aEmit[2] := RTRIM(SM0->M0_ENDCOB)
		aEmit[3] := RTRIM(SM0->M0_BAIRCOB)
		aEmit[4] := RTRIM(SM0->M0_CIDCOB)
		aEmit[5] := RTRIM(SM0->M0_ESTCOB)
		aEmit[6] := RTRIM(SM0->M0_CEPCOB)
		aEmit[7] := RTRIM(SM0->M0_CGC)
		aEmit[8] := RTRIM(SM0->M0_INSC)
		aEmit[9] := If(!GetNewPar("MV_SPEDEND",.F.),SM0->M0_ESTCOB,SM0->M0_ESTENT)

		//SA1->(dbSetOrder(1))
		//SA2->(dbSetOrder(1))
		//SF3->(dbSetOrder(5)) // F3_FILIAL+F3_SERIE+F3_NFISCAL+F3_CLIEFOR+F3_LOJA+F3_IDENTFT
		//SF2->(dbSetOrder(1)) // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
		//SF1->(dbSetOrder(1)) // F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO

		SF2->(dbSeek(xFilial("SF2") + cNotaIni + cSerie))

		For nNotas := 1 to len(aNotas)

			aNFe := array(4)
			aNfe[1] := RTRIM(aNotas[nNotas][1])
			aNfe[2] := RTRIM(aNotas[nNotas][2])
			aNfe[3] := RTRIM(aNotas[nNotas][3])
			aNfe[4] := RTRIM(aNotas[nNotas][8])


			aDest := array(7)
			aDest[1] := RTRIM(aNotas[nNotas][5])
			aDest[2] := RTRIM(aNotas[nNotas][6])
			aDest[3] := RTRIM(aNotas[nNotas][10])
			aDest[4] := RTRIM(aNotas[nNotas][14])			
			aDest[5] := RTRIM(aNotas[nNotas][11])
			aDest[6] := RTRIM(aNotas[nNotas][12])
			aDest[7] := RTRIM(aNotas[nNotas][9])

			nContDanfe += 1

			If nTipImp == 1 // 1 - Térmica

				impZebra(aNfe, aEmit, aDest)

			ElseIf nTipImp == 2 // 2 - Normal

				If nContDanfe == 1
					oPrinter:StartPage()  //Define inicio da pagina
					nLinha     := 0
					nColuna    := 0
				ElseIf nContDanfe == 2
					nLinha     := 0
					nColuna    := 250
				ElseIf nContDanfe == 3
					nLinha     := 0
					nColuna    := 500
				ElseIf nContDanfe == 4
					nLinha     := 250
					nColuna    := 0
				ElseIf nContDanfe == 5
					nLinha     := 250
					nColuna    := 250
				ElseIf nContDanfe == 6
					nLinha     := 250
					nColuna    := 500
					oPrinter:EndPage()
					nContDanfe := 0
				EndIf

				EtiqFedex(oPrinter, nLinha, nColuna, oFontTit, oFontInf, aEmit, aNfe, aDest)

			Endif

			lOk := .T.

		Next

		If lOk
			If nTipImp == 1 // - Térmica

				MSCBCLOSEPRINTER()

			ElseIf nTipImp == 2 // - Normal

				If nContDanfe <> 6

					oPrinter:EndPage()

				EndIf

				oPrinter:Print()

			EndIf
		EndIf

	End sequence

	fwFreeObj(oPrinter)
	fwFreeObj(oSetup)
	fwFreeObj(oFontTit)
	fwFreeObj(oFontInf)
	restArea(aAreaSA2)
	restArea(aAreaSA1)
	restArea(aAreaSF3)
	restArea(aAreaSF2)
	restArea(aAreaSF1)
	restArea(aAreaCB5)
	restArea(aArea)

return

/*static Function ValAtrib(atributo)
Return (type(atributo))
*/
//-------------------------------------------------------------------
/*/{Protheus.doc} EtiqFedex
Impressão normal de danfe simplificada - Etiqueta 

/*/
//-------------------------------------------------------------------
static function EtiqFedex(oPrinter, nPosY, nPosX, oFontTit, oFontInf, aEmit, aNfe, aDest)

	Local cTitRemetente    := "REMETENTE"
	Local cTitDestinatario := "DESTINATARIO"
	Local cTitNotaFiscal   := "NOTA FISCAL"
	Local cTitVolume	   := "VOLUME"
	Local cTitQtdePecas    := "QTDE PEÇAS"
	Local cTitSeparador    := "SEPARADOR"
	Local cTitOrdemSepara  := "ORDEM DE SEPARAÇÃO"
	Local cLogo            := GetSrvProfString("Startpath","") + "lgmid.png"

	dbSelectArea("CB7")
	dbSetOrder(1)
	SDC->(dbSeek(xFilial("CB7")+aNfe[1]))

	// Box Principal
	// box (eixo Y inicio, eixo X inicio, eixo y fim, eixo x fim)
	oPrinter:Box( 30 + nPosY, 30 + nPosX, 270 + nPosY, 270 + nPosX, "-6") // box (eixo Y inicio, eixo X inicio, eixo y fim, eixo x fim)

	// Box Remetente
	oPrinter:Box(  30 + nPosY, 30 + nPosX,  90 + nPosY, 270 + nPosX, "-4")
	oPrinter:SayBitmap( 35 + nPosY, 215 + nPosX, cLogo, 50, 50)
	oPrinter:Say(  40 + nPosY, 35 + nPosX, cTitRemetente        ,oFontTit) //say (y,x)
	oPrinter:Say(  50 + nPosY, 35 + nPosX, aEmit[1]             ,oFontInf)
	oPrinter:Say(  60 + nPosY, 35 + nPosX, aEmit[2]             ,oFontInf)
	oPrinter:Say(  70 + nPosY, 35 + nPosX, aEmit[3] + " - " + aEmit[4] + " - " + aEmit[5] + " - " + aEmit[6] ,oFontInf)
	oPrinter:Say(  80 + nPosY, 35 + nPosX, "CNPJ - " + aEmit[7] ,oFontInf)

	// Box Destinatario
	oPrinter:Box(  90 + nPosY, 30 + nPosX,  150 + nPosY, 270 + nPosX, "-4")
	oPrinter:Say( 100 + nPosY, 35 + nPosX, cTitDestinatario           ,oFontTit) //say (y,x)
	oPrinter:Say( 110 + nPosY, 35 + nPosX, aDest[1]                   ,oFontInf)
	oPrinter:Say( 120 + nPosY, 35 + nPosX, aDest[2]                   ,oFontInf)
	oPrinter:Say( 130 + nPosY, 35 + nPosX, aDest[3] + " - " + aDest[4] + " - " + aDest[5] + " - " + aDest[6] ,oFontInf)
	oPrinter:Say( 140 + nPosY, 35 + nPosX, "CNPJ - " + aDest[7]       ,oFontInf)

	// Box Nota Fiscal
	oPrinter:Box( 150 + nPosY, 30 + nPosX, 175 + nPosY, 110 + nPosX, "-4")
	oPrinter:Say( 160 + nPosY, 40 + nPosX, cTitNotaFiscal            ,oFontTit)
	oPrinter:Say( 170 + nPosY, 50 + nPosX, aNfe[1]		             ,oFontInf)

	// Box Volume
	oPrinter:Box( 150 + nPosY, 110 + nPosX, 175 + nPosY, 190 + nPosX, "-4")
	oPrinter:Say( 160 + nPosY, 135 + nPosX, cTitVolume               ,oFontTit)
	oPrinter:Say( 170 + nPosY, 135 + nPosX, "0000/000" + aNfe[2]     ,oFontInf)

	// Box Qtde Peças
	oPrinter:Box( 150 + nPosY, 190 + nPosX, 175 + nPosY, 270 + nPosX, "-4")
	oPrinter:Say( 160 + nPosY, 205 + nPosX, cTitQtdePecas            ,oFontTit)
	oPrinter:Say( 170 + nPosY, 220 + nPosX, "0000"                   ,oFontInf)

	// Box Separador
	oPrinter:Box( 175 + nPosY, 30  + nPosX, 200 + nPosY, 270 + nPosX, "-4")
	oPrinter:Say( 185 + nPosY, 35  + nPosX, cTitSeparador            ,oFontTit) //say (y,x)
	oPrinter:Say( 195 + nPosY, 35  + nPosX, "SEPARADOR"              ,oFontInf)

	// Box Ordem Separação
	oPrinter:Box( 200 + nPosY, 30  + nPosX, 225 + nPosY, 270 + nPosX, "-4")
	oPrinter:Say( 210 + nPosY, 35  + nPosX, cTitOrdemSepara          ,oFontTit) //say (y,x)
	oPrinter:Say( 220 + nPosY, 35  + nPosX, "0000000000"             ,oFontInf)

	// Box Codigo de Barras
	oPrinter:Box(      225 + nPosY, 30 + nPosX, 270 + nPosY, 270 + nPosX, "-4")
	oPrinter:Code128c( 257 + nPosY, 43 + nPosX, aNfe[4]                 , 31)
	oPrinter:Say(      265 + nPosY, 60 + nPosX, aNfe[4]                 , oFontInf)

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} impZebra
Impressão de danfe simplificada - Etiqueta para impressora Zebra

@param		aNfe		Dados da Nota
            aEmit		Dados do Emitente da Nota
			aDest		Dados do Destinatário da Nota

/*/ 
//-------------------------------------------------------------------
static function impZebra(aNFe, aEmit, aDest)
    /*
    Local cFontMaior := "016,013" //Fonte maior - títulos dos campos obrigatórios do DANFE ("altura da fonte, largura da fonte")
    Local cFontMenor := "015,008" //Fonte menor - campos variáveis do DANFE ("altura da fonte, largura da fonte")

    Local lProtEPEC  := .F.
    Local lNomeEmit  := .F.
    Local lNomeDest  := .F.

    Local nNome      := 1
    Local nCNPJ      := 2
    Local nIE        := 3
    Local nUF        := 4
    Local nChave     := 1
    Local nProtocolo := 2
    Local nProt_EPEC := 3
    Local nOperacao  := 5
    Local nNumero    := 6
    Local nSerie     := 7
    Local nData      := 8
    Local nValor     := 9
    Local nTamEmit   := len( allTrim( aEmit[nNome] ) ) //Quantidade de caracteres da razão social do emitente
    Local nTamDest   := len( allTrim( aDest[nNome] ) ) //Quantidade de caracteres da razão social do destinatário
    Local nMaxNome   := 34 //Quantidade de caracteres máxima da primeira linha da razão social
    */
	Default aNFe     := {}
	Default aEmit    := {}
	Default aDest    := {}

	MSCBPRINTER("ZEBRA","LPT1",,,.F.,,,,,,)

	MSCBCHKSTATUS(.F.)

	//Inicializa a impressão
	MSCBBegin(1,6,150)

	//Criação do Box
	MSCBBox(13,13,97,97)


	//Criação das linhas Horizontais - sentido: de cima para baixo
	MSCBLineH(13, 034, 97)
	MSCBLineH(13, 055, 97)
	MSCBLineH(13, 064, 97)
	MSCBLineH(13, 073, 97)
	MSCBLineH(13, 082, 97)
	//MSCBLineH(02, 101, 98)
	//MSCBLineH(02, 111, 98)
	//MSCBLineH(02, 138, 98)
    /*
    //Criação das linhas verticais - sentido: da direita para esquerda
    MSCBLineV(32, 84, 101)
    MSCBLineV(64, 84, 101)

    //Imprime o código de barras
    //MSCBSayBar(14, 24, aNFe[nChave], "N", "C", 10, .F., .F., .F., "C", 2, 1, .F., .F., "1", .T.)

    //lProtEPEC  := !empty( aNFe[nProt_EPEC] ) //Se utilizado evento EPEC para emissão da Nota lProtEPEC = .T.
    //lEmitJurid := len( aEmit[nCNPJ] ) == 14 //Se emitente pessoa jurídica lEmitJurid = .T.
    //lDestJurid := len( aDest[nCNPJ] ) == 14 //Se destinatário pessoa jurídica lDestJurid = .T.

    //Criação dos campos de textos fixos da etiqueta
    MSCBSay(17.5, 06.25, "DANFE SIMPLIFICADO - ETIQUETA", "N", "A", cFontMaior)
    MSCBSay(04  , 15   , "CHAVE DE ACESSO:"             , "N", "A", cFontMaior)

    if !lProtEPEC
        MSCBSay(22.5, 48.75, "PROTOCOLO DE AUTORIZACAO:"     , "N", "A", cFontMaior)
    else
        MSCBSay(16.5, 48.75, "PROTOCOLO DE AUTORIZACAO EPEC:", "N", "A", cFontMaior)
    endIf

    MSCBSay(04, 60, "NOME/RAZAO SOCIAL:", "N", "A", cFontMaior)

    if lEmitJurid
        MSCBSay(04, 66.25 , "CNPJ:", "N", "A", cFontMaior)
    else
        MSCBSay(04, 66.25 , "CPF:", "N", "A", cFontMaior)
    endIf

    MSCBSay(04  , 70    , "IE:"               , "N", "A", cFontMaior)
    MSCBSay(04  , 73.75 , "UF:"               , "N", "A", cFontMaior)
    MSCBSay(04  , 88.75 , "SERIE:"            , "N", "A", cFontMaior)
    MSCBSay(04  , 93.75 , "N_A7:"             , "N", "A", cFontMaior)
    MSCBSay(34  , 88.75 , "DATA EMISSAO:"     , "N", "A", cFontMaior)
    MSCBSay(65.5, 88.75 , "TIPO OPER.:"       , "N", "A", cFontMaior)
    MSCBSay(65.5, 92.5  , "0 - ENTRADA"       , "N", "A", cFontMenor)
    MSCBSay(65.5, 96.25 , "1 - SAIDA"         , "N", "A", cFontMenor)
    MSCBSay(35  , 105.5 , "DESTINATARIO"      , "N", "A", cFontMaior)
    MSCBSay(04  , 113.75, "NOME/RAZAO SOCIAL:", "N", "A", cFontMaior)

    if lDestJurid
        MSCBSay(04, 120, "CNPJ:", "N", "A", cFontMaior)
    else
        MSCBSay(04, 120, "CPF:" , "N", "A", cFontMaior)
    endIf

    MSCBSay(04  , 123.75, "IE:"         , "N", "A", cFontMaior)
    MSCBSay(04  , 127.5 , "UF:"         , "N", "A", cFontMaior)
    MSCBSay(04  , 142.5 , "VALOR TOTAL:", "N", "A", cFontMaior)
    MSCBSay(62.5, 142.5 , "R$"          , "N", "A", cFontMaior)

    //lNomeEmit := nTamEmit > nMaxNome //Se quantidade de caracteres da razão social do emitente for maior que o permitido para a primeira linha lNomeEmit := T
    //lNomeDest := nTamDest > nMaxNome //Se quantidade de caracteres da razão social do destinatário for maior que o permitido para a primeira linha lNomeDest := T

    //Criação dos campos de textos variáveis da etiqueta
    //MSCBSay(09, 39, transform( aNFe[nChave], "@R 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999" ), "N", "A", cFontMenor)

    /*
    if !lProtEPEC
        MSCBSay(38.75, 53.75, aNFe[nProtocolo], "N", "A", cFontMenor)
    else
        MSCBSay(38.75, 53.75, aNFe[nProt_EPEC], "N", "A", cFontMenor)
    endIf

    if lNomeEmit
        MSCBSay(44, 60, allTrim( subStr( aEmit[nNome], 1, nMaxNome ) ), "N", "A", cFontMenor)
        MSCBSay(04, 62.5, allTrim( subStr( aEmit[nNome], nMaxNome + 1, nTamEmit ) ), "N", "A", cFontMenor)
    else
        MSCBSay(44, 60, allTrim( aEmit[nNome] ), "N", "A", cFontMenor)
    endIf

    if lEmitJurid
        MSCBSay(15, 66.25, transform( aEmit[nCNPJ], "@R 99.999.999/9999-99" ), "N", "A", cFontMenor) //Emitente pessoa jurídica
    else
        MSCBSay(15, 66.25, transform( aEmit[nCNPJ], "@R 999.999.999-99" ), "N", "A", cFontMenor) //Emitente pessoa física
    endIf

    MSCBSay(11, 70,    aEmit[nIE], "N", "A", cFontMenor)
    MSCBSay(11, 73.75, aEmit[nUF], "N", "A", cFontMenor)
    MSCBSay(18, 88.75, aNFe[nSerie], "N", "A", cFontMenor)
    MSCBSay(11, 93.75, aNFe[nNumero], "N", "A", cFontMenor)
    MSCBSay(40, 93.75, ajustaData( aNFe[nData] ) , "N", "A", cFontMenor)
    MSCBSay(93, 88.75, aNFe[nOperacao], "N", "A", cFontMenor)

    if lNomeDest
        MSCBSay(44, 113.75, allTrim( subStr( aDest[nNome], 1, nMaxNome ) ), "N", "A", cFontMenor)
        MSCBSay(04, 116.25, allTrim( subStr( aDest[nNome], nMaxNome + 1, nTamDest ) ), "N", "A", cFontMenor)
    else
        MSCBSay(44, 113.75, allTrim( aDest[nNome] ), "N", "A", cFontMenor)
    endIf

    if lDestJurid
        MSCBSay(15, 120, transform( aDest[nCNPJ], "@R 99.999.999/9999-99" ), "N", "A", cFontMenor) //Destinatário pessoa jurídica
    else
        MSCBSay(15, 120, transform( aDest[nCNPJ], "@R 999.999.999-99" ), "N", "A", cFontMenor) //Destinatário pessoa física
    endIf

    MSCBSay(11, 123.75, aDest[nIE]  , "N", "A", cFontMenor)
    MSCBSay(11, 127.5 , aDest[nUF]  , "N", "A", cFontMenor)
    MSCBSay(70, 142.5 , aNFe[nValor], "N", "A", cFontMenor)
    */
	//Finaliza a impressão
	MSCBEND()

return

//-------------------------------------------------------------------
/*/{Protheus.doc} ajustaData
Recebe um dado do tipo data (AAAAMMDD) e devolve uma string no
formato (DD/MM/AAAA)

@param		dData		Dado do tipo data(AAAAMMDD)
@return     cDataForm	String formatada com a data (DD/MM/AAAA)

/*/
//-------------------------------------------------------------------
/*static function ajustaData( dData )

    Local cDia      := ""
    Local cMes      := ""
    Local cAno      := ""
    Local cDataForm := ""

    default dData   := Date()

    cDia := strZero( day( dData ), 2 )
    cMes := strZero( month( dData ), 2 )
    cAno := allTrim( str( year( dData ) ) )

    cDataForm = cDia + "/" + cMes + "/" + cAno

return cDataForm*/
