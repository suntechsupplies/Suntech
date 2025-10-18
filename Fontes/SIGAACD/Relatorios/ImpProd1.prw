#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'

/*---------------------------------------------------------
{Protheus.doc} 	ImpMostr
				Etiqueta de Produtos Mostruario
@author 		Carlos Eduardo Saturnino
@since 			05/05/2021
@type 			function
---------------------------------------------------------*/

#DEFINE VELOCIDADE_IMPRESSORA 4
#DEFINE NLININI	 004
#DEFINE NQUEBNOR 004

user function ImpProd1()

	If ValidPerg()
		Processa({|| imprEtiq2() }, "Aguarde...", "Imprimindo...",.F.)
	EndIf

return

static function imprEtiq2()

	local nQtdEtiq 	:= 1
	local nLinha	:= NLININI
	local nColuna   := 003
	local lSeg      := .F.
	local cPorta    := "LPT1"
	local aProduto  := {}
	local cProduto  := MV_PAR01
	local cModelo   := MV_PAR02
	local nImpress  := MV_PAR03

	local nJ

	private cZPL

	dbselectarea("SBS")
	If !CB5SetImp("000001")
		MsgStop("Problemas no local de impressão!")
		return
	endif

	MSCBPRINTER("ZEBRA",cPorta,,,.f.,,,,,,)
	MSCBCHKSTATUS(.F.)

	MSCBBEGIN(nQtdEtiq,VELOCIDADE_IMPRESSORA)

	aProduto := buscaItem(cProduto, cModelo, nImpress)
	
	for nJ := 1 to Len(aProduto)
	
		nLinha  := NLININI
		
		If Mod(nJ,3) == 1
			MSCBBEGIN(nQtdEtiq	, VELOCIDADE_IMPRESSORA	,,)
			nColuna := 003
			nLinha  := NLININI
			lSeg := .F.			
		ElseIf Mod(nJ,3) == 2
			nColuna := 038
		Else
			nColuna := 073
			lSeg := .T.
		Endif

		if !Empty(aProduto[nJ,1])
			MSCBSAY(nColuna,nLinha,aProduto[nJ,1],"N","0","18",,,,,.t.) 					// Código
			nLinha := nLinha+2.5
		endif
		
		if !Empty(aProduto[nJ,4])
			MSCBSAY(nColuna,nLinha,aProduto[nJ,4],"N","0","18",,,,,.t.) 					// Descrição Modelo
			nLinha := nLinha+3
		endif
		
		if !Empty(aProduto[nJ,5])															// Codigo de Barras

			//MSCBSay - Imprime Codigo de Barras
			//			nXmm		,nYmm		,aConteudo		, cRotação 	, cTypePrt	,nAltura	, lDigVer	, lLinha	,lLinBaixo	, cSubSetIni,nLargura	, nRelação	, lCompacta	, lSerial	, cIncr	, lZerosL
			MSCBSAYBAR(nColuna+2	,nLinha		,aProduto[nJ,5]	,"N"		,"MB07"		,4			,.F.		,.F.		,.F.		,			,1			,1			,.F.		,.F.		,"1"	,.T.		) // Código Barras EAN
		
			nLinha := nLinha+4.5
			//MSCBSay - Imprime uma String 
			//	   ( nXmm	 	,nYmm 	,cTexto 		,cRotação 	,cFonte ,cTam [ *lReverso ] [ lSerial ] [ cIncr ] [ *lZerosL ] [ lNoAlltrim ] )
			MSCBSAY(nColuna+5	,nLinha	,aProduto[nJ,5]	,"N"		,"0"	,"021",,,,,.t.)	// Código EAN

		endif

		if lSeg .OR. nJ == nImpress
			MSCBInfoEti("ETQ_AAB"+cValToChar(nJ),"100X100")
			cZPL := MSCBEND()
		endif


	next nJ

	MSCBCLOSEPRINTER()

return

static function buscaItem(cCodPro, cModelo, nQuant)

	local aSBS     := {}
	local cQuery02 := ""
	local cQuery03 := ""
	local cAlias   := getNextAlias()
	local cCodSBS  := ""
	local nY

	/* BS_FILIAL+BS_BASE+BS_ID+BS_CODIGO */
	/* 1 01 0006 0010 003  */
	/* BASE PRODUTO TIPO ARMACAO LENTE */
	/* 1 OCULOS THRUSTER BLACK MINERAL BRONZE */
	
	For nY := 1 to nQuant

		if Empty(cModelo)

			if POSICIONE("SB1", 1, xFilial("SB1")+cCodPro, "!eof()")

				cQuery02 := " SELECT BS_DESCR AS descricao " + CRLF
				cQuery02 += "   FROM " + retSqlName("SBS") + " SBS" + CRLF
				cQuery02 += "  WHERE BS_BASE = '" + Substr(SB1->B1_COD, 1, 1) + "'" + CRLF
				cQuery02 += "    AND BS_ID = '02' " + CRLF
				cQuery02 += "    AND BS_CODIGO = '" +  Substr(SB1->B1_COD, 4, 4) + "'" + CRLF
				cQuery02 += "    AND " + retSqlDel("SBS") + CRLF
				cQuery02 += "    AND " + retSqlFil("SBS") + CRLF

				TCQUERY cQuery02 NEW ALIAS "SBSMOD"

				if !Empty(SBSMOD->descricao)
					aAdd(aSBS, {SB1->B1_COD, Substr(SB1->B1_COD, 1, 1), Substr(SB1->B1_COD, 2, 2), AllTrim(SBSMOD->descricao), Alltrim(buscaZZ2(SB1->B1_COD))}) // Produto
				endif

				SBSMOD->(dbCloseArea())

			endif

		else

			//cCodSBS := POSICIONE("SBS", "ZZMODELO", xFilial("SBS")+cModelo,"BS_CODIGO")
			cCodSBS := POSICIONE("SBS",,XFILIAL("SBS")+CMODELO,"BS_CODIGO","ZZMODELO")

			cQuery03 := " SELECT B1_COD " + CRLF
			cQuery03 += "      , B1_CODBAR " + CRLF
			cQuery03 += "   FROM " + retSqlName("SB1") + " SB1" + CRLF
			cQuery03 += "  WHERE SUBSTRING(B1_COD, 4,4) = '" + AllTrim(cCodSBS) + "'" + CRLF
			cQuery03 += "    AND " + retSqlDel("SB1") + CRLF
			cQuery03 += "    AND " + retSqlFil("SB1") + CRLF

			TcQuery cQuery03 New Alias (cAlias)

			while (cAlias)->(!eof())

				cQuery02 := " SELECT BS_DESCR AS descricao " + CRLF
				cQuery02 += "   FROM " + retSqlName("SBS") + " SBS" + CRLF
				cQuery02 += "  WHERE BS_BASE = '" + Substr((cAlias)->B1_COD, 1, 1) + "'" + CRLF
				cQuery02 += "    AND BS_ID = '02' " + CRLF
				cQuery02 += "    AND BS_CODIGO = '" +  Substr((cAlias)->B1_COD, 4, 4) + "'" + CRLF
				cQuery02 += "    AND " + retSqlDel("SBS") + CRLF
				cQuery02 += "    AND " + retSqlFil("SBS") + CRLF

				TCQUERY cQuery02 NEW ALIAS "SBSMOD"

				if !Empty(SBSMOD->descricao)
					aAdd(aSBS, {(cAlias)->B1_COD, Substr((cAlias)->B1_COD, 1, 1), Substr((cAlias)->B1_COD, 2, 2), AllTrim(SBSMOD->descricao), Alltrim(buscaZZ2(SB1->B1_COD))}) // Produto
				endif

				SBSMOD->(dbCloseArea())

				(cAlias)->(dbSkip())
			enddo

			(cAlias)->(dbCloseArea())

		endif
	
	Next nY

	/* POSICÃO 01 =  Código do Produto B1_COD */
	/* POSICÃO 02 =  Base */
	/* POSICÃO 03 =  Linha */
	/* POSICÃO 04 =  Modelo */
	/* POSICÃO 05 =  Código EAN para código de barras B1_CODBAR */

return aSBS

Static Function ValidPerg()

	Local aRet		:= {}
	Local aParamBox	:= {}
	Local lRet 		:= .F.

	aAdd(aParamBox,{1,"Código Produto ",space(getSX3Cache("B1_COD","X3_TAMANHO")),"","","SB1","",50,.F.}) //MV_PAR01
	aAdd(aParamBox,{1,"Modelo ",space(getSX3Cache("BS_DESCR","X3_TAMANHO")),"","","SBSMOD","",50,.F.}) //MV_PAR02
	aAdd(aParamBox,{1,"Quantidade de Etiquetas",0,"@E 9,999","mv_par03>0","","",20,.T.}) // MV_PAR03

	If ParamBox(aParamBox,"Etiqueta Mostruário",@aRet,,,,,,,"ImpMostr",.T.,.T.)
		lRet := .t.
	EndIf

Return lRet

static function buscaZZ2(cCodPro)

	local cCodBarZZ2 := ""

	If Select("TABZZ2") > 0
		TABZZ2->(dbCloseArea())
	Endif

	BeginSQL Alias "TABZZ2"
	
		SELECT 	MAX(ZZ2_CODBAR) AS maiorCodBar
		  FROM 	%Table:ZZ2% ZZ2
		 WHERE	ZZ2.ZZ2_FILIAL = %Exp:FwxFilial("ZZ2")%
		   AND	ZZ2.%NotDel%
	
	EndSQL

	dbSelectArea("ZZ2")
	ZZ2->(dbSetOrder(2))
	cCodBarZZ2 := Soma1(TABZZ2->maiorCodBar)
	
	If Reclock("ZZ2", .T.)
		ZZ2_CODBAR := cCodBarZZ2
		ZZ2_PRODUT := cCodPro
		ZZ2_QUANT  := 1
		MsUnlock()
		TABZZ2->(DbCloseArea())
	Endif

return (Alltrim(cCodBarZZ2))
