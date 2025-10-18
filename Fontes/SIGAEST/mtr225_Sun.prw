#INCLUDE "MATR225.CH"
#INCLUDE "TOTVS.CH"

STATIC lPCPREVATU	:= FindFunction('PCPREVATU')  .AND.  SuperGetMv("MV_REVFIL",.F.,.F.)
/*/{Protheus.doc} MTR225_SUN
Rotina     	Relacao simplificada das estruturas    
@Project    SunTech
@Author     Alexandre Caetano
@Since      27/01/22
@Version    P12.1.27
@Type       Function
@History 	
@Param		
@Return		Nil												 
/*/
User Function MTR225_SUN()
	Local oReport		as object
	Local aParamBox		as array
	Local aRet			as array
	Local aOpcCust		as array
	Local cProd			as character
	Local cRevi			as character
	Local cPicProd		as character
	Local cPicRevi		as character
	Local cTamProd		as character
	Local cTamRevi		as character

	Private cUltRevi	as character
	Private bValProd	as codeblock
	Private cProdSX1	as character
	Private nOpcCust	as character

	cProd      	:= Space( GetSx3Cache( "B1_COD" 	,"X3_TAMANHO") )
    cRevi      	:= Space( GetSx3Cache( "G1_REVFIM"  ,"X3_TAMANHO") )

    cPicProd    := GetSx3Cache( "B1_COD"      		,"X3_PICTURE")
    cPicRevi    := GetSx3Cache( "G1_REVFIM"        	,"X3_PICTURE")

    cTamProd    := GetSx3Cache( "B1_COD"    		,"X3_TAMANHO")
    cTamRevi    := GetSx3Cache( "G1_REVFIM"       	,"X3_TAMANHO")

	bValProd	:= {|| cUltRevi	:= U_Mtr225S1(mv_par01) }

	aParamBox 	:= {}
	aRet		:= {}
	aOpcCust	:= {}

	aAdd( aOpcCust	,"1-Sim" )
	aAdd( aOpcCust	,"2-Não" )
	
	aAdd(aParamBox	,{1,"Produto 		 "  	,cProd	,cPicProd	,"Eval(bValProd)"	,"SB1"	,""    	,70   		,.t.} )
    aAdd(aParamBox	,{1,"Revisão 		 "  	,cRevi 	,cPicRevi	,"" 				,"" 	,""  	,cTamRevi	,.f.} )

	aAdd(aParamBox	,{2,"Imprime Custo "  		,1		,aOpcCust	,70					,""		,.t.} )
	
	If ParamBox(aParamBox,"Selecione o Produto",@aRet)
		cProdSX1	:= mv_par01		
		nOpcCust	:= mv_par03
		oReport		:= ReportDef(cUltRevi	,mv_par01)
		oReport:PrintDialog()
	Endif

Return(Nil)
/*/{Protheus.doc} ReportDef
Rotina     	A funcao estatica ReportDef devera ser criada para todos 
			os relatorios que poderao ser agendados pelo usuario. 
@Project    SunTech
@Author     Alexandre Caetano
@Since      27/01/22
@Version    P12.1.27
@Type       Function
@History 	
@Param		cUltRevi	,character	,Ultima revisão 
			cProd		,character	,produto
@Return		Nil												 
/*/
Static Function ReportDef(	cUltRevi	as character	,;
							cProd		as character		)
	Local oReport
	Local oSection1
	Local oSection2
	Local nB1_cod  
	Local nB1_desc 
	Local nB1_tipo 
	Local nB1_grupo
	Local nB1_um   
	Local nG1_QTD 
	Local cTitQtd	:= GetSX3Cache( "G1_QUANT"	,"X3_TITULO"	)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Criacao do componente de impressao                                      ³
	//³                                                                        ³
	//³TReport():New                                                           ³
	//³ExpC1 : Nome do relatorio                                               ³
	//³ExpC2 : Titulo                                                          ³
	//³ExpC3 : Pergunte                                                        ³
	//³ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao  ³
	//³ExpC5 : Descricao                                                       ³
	//³                                                                        ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oReport:= TReport():New("MATR225",OemToAnsi(STR0001),"MTR225_SUN", {|oReport| ReportPrint(oReport)},OemToAnsi(STR0002)+" "+OemToAnsi(STR0003)+" "+OemToAnsi(STR0004))  //"Este programa emite a relacao de estrutura de um determinado produto"##"selecionado pelo usuario. Esta relacao nao demonstra custos. Caso o"##"produto use opcionais, sera listada a estrutura com os opcionais padrao."
	oReport:SetPortrait()

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica as perguntas selecionadas                           ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Variaveis utilizadas para parametros ³
	//³ mv_par01   // Produto de             ³
	//³ mv_par02   // Produto ate            ³
	//³ mv_par03   // Tipo de                ³
	//³ mv_par04   // Tipo ate               ³
	//³ mv_par05   // Grupo de               ³
	//³ mv_par06   // Grupo ate              ³
	//³ mv_par07   // Salta Pagina: Sim/Nao  ³
	//³ mv_par08   // Qual Rev da Estrut     ³
	//³ mv_par09   // Imprime Ate Nivel ?    ³
	//³ mv_par10   // Data de referência?    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Pergunte(oReport:uParam,.F.)

	//Verifica se o MV_PAR10 existe no pergunte MTR225 -> Protecao de fonte.
	AjstPergt()

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Criacao da secao utilizada pelo relatorio                               ³
	//³                                                                        ³
	//³TRSection():New                                                         ³
	//³ExpO1 : Objeto TReport que a secao pertence                             ³
	//³ExpC2 : Descricao da seçao                                              ³
	//³ExpA3 : Array com as tabelas utilizadas pela secao. A primeira tabela   ³
	//³        sera considerada como principal para a secao.                   ³
	//³ExpA4 : Array com as Ordens do relatorio                                ³
	//³ExpL5 : Carrega campos do SX3 como celulas                              ³
	//³        Default : False                                                 ³
	//³ExpL6 : Carrega ordens do Sindex                                        ³
	//³        Default : False                                                 ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Sessao 1                                                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oSection1 := TRSection():New(oReport,STR0036,{"SG1","SB1"}) //"Detalhes do produto Pai"
	oSection1:SetHeaderBreak(.f.)
	oSection1:SetHeaderPage(.f.)
	oSection1:SetHeaderSection(.f.)

	nB1_cod   	:= tamSX3('B1_COD')[1] + 1
	nB1_desc  	:= tamSX3('B1_DESC')[1] + 1
	nB1_tipo  	:= tamSX3('B1_TIPO')[1] + 1
	nB1_grupo	:= tamSX3('B1_GRUPO')[1] + 1
	nB1_um    	:= tamSX3('B1_UM')[1] + 1
	nG1_QTD  	:= tamSX3('G1_QUANT')[1] + 1

	TRCell():New(oSection1,'G1_COD'	    ,'SG1',""   ,/*Picture*/,nB1_cod        ,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection1,'B1_DESC'   	,'SB1',""   ,/*Picture*/,nB1_desc       ,/*lPixel*/,/*{|| code-block de impressao }*/)
    TRCell():New(oSection1,''	        ,''   ,' '	,/*Picture*/,/*Tamanho*/	,/*lPixel*/,/*{|| code-block de impressao }*/)  // Incluído por solicitação do Jairo em 21/03/2022

	oSection1:SetNoFilter("SB1")
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Sessao 2                                                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oSection2 := TRSection():New(oSection1,STR0037,{'SG1','SB1'}) // "Estruturas"
	oSection2:SetHeaderPage()

	TRCell():New(oSection2,'G1_COMP'		,'SG1'	,STR0020	,/*Picture*/					,nB1_cod		,/*lPixel*/,/*{|| code-block de impressao }*/) //B1_COD deve ter o mesmo tamanho que G1_COMP, por isso usei a variável que já tinha a informação na memória, sem realizar a busca novamente na tabela 
	If nB1_desc > 30
		TRCell():New(oSection2,'B1_DESC'	,'SB1'	,STR0024	,/*Picture*/					,30				,/*lPixel*/,/*{|| code-block de impressao }*/)
	Else
		TRCell():New(oSection2,'B1_DESC'	,'SB1'	,STR0024	,/*Picture*/					,nB1_desc		,/*lPixel*/,/*{|| code-block de impressao }*/)
	EndIf

    TRCell():New(oSection2,'B1_TIPO'	,'SB1',STR0022			,/*Picture*/					,/*Tamanho*/	,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,'B1_GRUPO'	,'SB1',STR0023			,/*Picture*/					,/*Tamanho*/	,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,'B1_UM'		,'SB1',STR0027			,/*Picture*/					,nB1_um			,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,''	        ,     ,' '		        ,/*Picture*/					,/*Tamanho*/	,/*lPixel*/,/*{|| code-block de impressao }*/)  // Incluído por solicitação do Jairo em 21/03/2022
    TRCell():New(oSection2,'G1_QUANT' 	,'SB2',cTitQtd			,/*Picture*/					,nG1_QTD		,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,'CUNITA' 	,'SB1',"C. Unitário   "	,'@!'							,10				,/*lPixel*/,/*{|| code-block de impressao }*/)
	TRCell():New(oSection2,'CTOTAL' 	,'SB1',"C. Total      "	,'@!'							,10				,/*lPixel*/,/*{|| code-block de impressao }*/)

	oSection2:SetNoFilter("SB1")

Return(oReport)
/*/{Protheus.doc} ReportPrint
Rotina     	A funcao estatica ReportPrint devera ser criada para todos 
			os relatorios que poderao ser agendados pelo usuario. 
@Project    SunTech
@Author     Alexandre Caetano
@Since      27/01/22
@Version    P12.1.27
@Type       Function
@History 	
@Param		oReport		,object		,Objeto do Relatorio 			
@Return		Nil												 
/*/
Static Function ReportPrint(oReport)
	Local oSection1 := oReport:Section(1)
	Local oSection2 := oReport:Section(1):Section(1)
	Local cProduto 	:= ""
	Local nNivel   	:= 0
	Local lContinua := .T.
	Local lDatRef   := !Empty(mv_par10)
	Private lNegEstr:=GETMV("MV_NEGESTR")

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³	Processando a Sessao 1                                       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	dbSelectArea('SG1')
	dbSetOrder(1)
	MsSeek(xFilial('SG1')+mv_par01,.T.)
	oReport:SetMeter(SG1->(LastRec()))
	oSection1:Init(.F.)

	While !oReport:Cancel() .And. !Eof() .And. SG1->G1_FILIAL+SG1->G1_COD <= xFilial('SG1')+mv_par02

		oReport:IncMeter()

		If lDatRef .And. (SG1->G1_INI > mv_par10 .Or. SG1->G1_FIM < mv_par10)
			SG1->(dbSkip())
			Loop
		EndIf

		cProduto := SG1->G1_COD
		nNivel   := 2
		lContinua:=.T.
		
		dbSelectArea('SB1')
		MsSeek(xFilial('SB1')+cProduto)

		If	RetFldProd(SB1->B1_COD,"B1_TIPO") == "PI" 
			SG1->( dbSkip() ) 
			Loop
		Endif
			
		If Eof() .Or. SB1->B1_TIPO < mv_par03 .Or. SB1->B1_TIPO > mv_par04 .Or. SB1->B1_GRUPO < mv_par05 .Or. SB1->B1_GRUPO > mv_par06
			dbSelectArea('SG1')
			While !oReport:Cancel() .And. !Eof() .And. xFilial('SG1')+cProduto == SG1->G1_FILIAL+SG1->G1_COD
				dbSkip()
				oReport:IncMeter()
			EndDo
			lContinua := .F.
		EndIf

		If lContinua	
			
			oSection1:Init(.F.)
			oReport:SkipLine()     
			
			oSection1:PrintLine()
			oReport:SkipLine()     
			oSection1:Finish()

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³	Impressao da Sessao 2                                        ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			oSection2:Init()
			
			//-- Explode Estrutura
			MR225ExplG(oReport,oSection2,cProduto,IIf(RetFldProd(SB1->B1_COD,"B1_QB")==0,1,RetFldProd(SB1->B1_COD,"B1_QB")),nNivel,RetFldProd(SB1->B1_COD,"B1_OPC"),IIf(RetFldProd(SB1->B1_COD,"B1_QB")==0,1,RetFldProd(SB1->B1_COD,"B1_QB"))	,IIf(Empty(mv_par08),IIF(lPCPREVATU , PCPREVATU(SB1->B1_COD), SB1->B1_REVATU ),mv_par08))

			oSection2:Finish()
			
			//-- Verifica se salta ou nao pagina
			If mv_par07 == 1
				oSection1:SetPageBreak(.T.)
			Else    
				oReport:ThinLine() //-- Impressao de Linha Simples
			EndIf	 
		
		EndIf
		dbSelectArea("SG1")
	EndDo

	//-- Devolve a condicao original do arquivo principal
	dbSelectArea("SG1")
	Set Filter To
	dbSetOrder(1)

Return(Nil)
/*/{Protheus.doc} MR225ExplG
Rotina     	Faz a explosao de uma estrutura  
@Project    SunTech
@Author     Alexandre Caetano
@Since      27/01/22
@Version    P12.1.27
@Type       Function
@History 	
@Param		oReport		,object		,Objeto do Relatorio 
			oSection2	,object		,Sessao a ser impressa
			cProduto	,character	,Codigo do produto a ser explodido
			nQuantPai	,numeric	,Quantidade do pai a ser explodida
			nNivel		,numeric	,Nivel a ser impresso
			cOpcionais	,numeric	,Opcionais do produto
			nQtdBase	,numeric	,Quantidade do Produto Nivel Anterior
			cRevisao	,character	,Numero da Revisao
@Return		Nil												 
/*/
Static Function MR225ExplG(oReport,oSection2,cProduto,nQuantPai,nNivel,cOpcionais,nQtdBase,cRevisao)
	Local nReg 		  := 0
	Local nQuantItem  := 0
	Local cAteNiv     := If(mv_par09=Space(3),"999",mv_par09)
	Local cRevEst	  := ''
	Local lDatRef     := !Empty(mv_par10)
	Local cCUnita	  := Space(10)
	Local cCTotal     := Space(10)
	Local nEmpTot	  := 0
	Local cB2CM1	  := 0

	dbSelectArea('SG1')
	While !oReport:Cancel() .And. !Eof() .And. G1_FILIAL+G1_COD == xFilial('SG1')+cProduto
		oSection2:IncMeter()
		nReg       := Recno()
		nQuantItem := ExplEstr(nQuantPai,Iif(lDatRef,mv_par10,Nil),cOpcionais,cRevisao)
		dbSelectArea('SG1')
		If nNivel <= Val(cAteNiv) // Verifica ate qual Nivel devera ser impresso
			If (lNegEstr .Or. (!lNegEstr .And. QtdComp(nQuantItem,.T.) > QtdComp(0) )) .And. (QtdComp(nQuantItem,.T.) # QtdComp(0,.T.))

				SB2->( dbSetOrder(1) )	//B2_FILIAL+B2_COD+B2_LOCAL
				SB2->( msSeek( FWxFilial("SB2")+SG1->G1_COMP) )
			
				dbSelectArea('SB1')
				dbSetOrder(1)
				MsSeek(xFilial('SB1')+SG1->G1_COMP)

				//Soma quantidade empenhada de todos os armazéns
				Do While FWxFilial("SB2")+SG1->G1_COMP == SB2->B2_FILIAL+SB2->B2_COD
				
					nEmpTot	+= SB2->B2_QEMP
					if cB2CM1 < SB2->B2_CM1
						cB2CM1 := SB2->B2_CM1
					Endif
			
					SB2->( dbSkip() )
				Enddo
				//-----------------------------------------------------------		

				If Valtype(mv_par11) <> "N"		
					mv_par11	:= val(mv_par11)
				Endif

				if mv_par11 = 2 	//Não
					cCUnita	:= Space(10)
					cCTotal := Space(10)
				Else				//Sim
					cCUnita	:= Transform( ( cB2CM1 )							,GetSX3Cache( "B2_CM1"	,"X3_PICTURE"	)	)
					cCTotal := Transform( ( SB2->B2_CM1 * SG1->G1_QUANT )		,GetSX3Cache( "B2_CM1"	,"X3_PICTURE"	)	)
				Endif

				oSection2:Cell('G1_QUANT' ):SetValue( SG1->G1_QUANT   )
				oSection2:Cell('CUNITA'   ):SetValue( cCUnita   )
				oSection2:Cell('CTOTAL'   ):SetValue( cCTotal	)
			
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Impressao da Sessao 2			                ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				oSection2:PrintLine()
			
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Verifica se existe sub-estrutura                ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				dbSelectArea('SG1')
				MsSeek(xFilial('SG1')+G1_COMP)
				cRevEst := IIF(lPCPREVATU , PCPREVATU(SB1->B1_COD), SB1->B1_REVATU )
				If Found()
					MR225ExplG(oReport,oSection2,G1_COD,nQuantItem,nNivel+1,cOpcionais,IIf(RetFldProd(SB1->B1_COD,"B1_QB")==0,1,RetFldProd(SB1->B1_COD,"B1_QB")),If(!Empty(cRevEst),cRevEst,mv_par08))
				EndIf

				dbGoto(nReg)

			EndIf
		EndIf
		dbSkip()
	EndDo

Return(Nil)
/*/{Protheus.doc} AjstPergt
Rotina     	Verifica se o pergunte 10 existe para o pergunte MTR225.
			Se nao existir, inicializa o MV_PAR10 como branco para o programa manter o seu funcionamento.
@Project    SunTech
@Author     Alexandre Caetano
@Since      27/01/22
@Version    P12.1.27
@Type       Function
@History 	
@Param		
@Return		Nil												 
/*/
Static Function AjstPergt()
	Local oUtilX1 := FWSX1Util():New()
	Local nPos    := 0

	oUtilX1:AddGroup('MTR225_SUN')
	oUtilX1:SearchGroup()
	
	nPos := aScan(oUtilX1:aGrupo,{|x| AllTrim(x[1]) == "MTR225_SUN" })
	If nPos > 0
		If Len(oUtilX1:aGrupo[nPos][2]) < 10
			//Nao existe o pergunte 10 para o MTR225. Inicializa o MV_PAR10.
			mv_par10 := StoD('')
		EndIf
	EndIf

	SetMVValue("MTR225_SUN","MV_PAR01",cProdSx1)
	SetMVValue("MTR225_SUN","MV_PAR02",cProdSx1)
	SetMVValue("MTR225_SUN","MV_PAR08",cUltRevi)
	SetMVValue("MTR225_SUN","MV_PAR11",nOpcCust)

	mv_par01	:= cProdSx1
	mv_par02	:= cProdSx1
	mv_par08	:= cUltRevi
	mv_par11	:= nOpcCust

Return(Nil)
/*/{Protheus.doc} Mtr225S1
Rotina     	Busca a ultima revisão
@Project    SunTech
@Author     Alexandre Caetano
@Since      27/01/22
@Version    P12.1.27
@Type       Function
@History 	
@Param		cProd	,character	,Produto
@Return		Nil												 
/*/
User Function Mtr225S1(cProd	as character )
	Local aAreaSG1	as array
	Local cRet		as character

	Private cNmTRB  := GetNextAlias()
	Private nEstru	:= 0

	aAreaSG1	:= GetArea("SG1")
	cRet		:= "   "

	SG1->( dbSetOrder(1) ) //Filial + Componente + Produto
	If SG1->( dbSeek( FWxFilial("SG1") + cProd ) )

		Do While SG1->( !EoF() ) .and.  FWxFilial("SG1") + cProd == SG1->G1_FILIAL + SG1->G1_COD

			if cRet < SG1->G1_REVINI
				cRet := SG1->G1_REVINI
			Endif

			SG1->( dbSkip() )
		Enddo

	Endif

	mv_par02	:= cRet

	RestArea(aAreaSG1)

Return(cRet)
/*/{Protheus.doc} Mtr225S2
Rotina     	Atualiza pergunte - função chamada pelo valid do SX1
@Project    SunTech
@Author     Alexandre Caetano
@Since      28/01/22
@Version    P12.1.27
@Type       Function
@History 	
@Param		
@Return		Nil												 
/*/
User Function Mtr225S2()

	SetMVValue("MTR225_SUN","MV_PAR01",cProdSx1)
	SetMVValue("MTR225_SUN","MV_PAR02",cProdSx1)
	SetMVValue("MTR225_SUN","MV_PAR08",cUltRevi)
	SetMVValue("MTR225_SUN","MV_PAR11",nOpcCust)

Return(.t.)
