#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'

/*/{Protheus.doc} ImpMostr
Etiqueta de Produtos Mostruario
@author Victor Freidinger
@since 12/07/2019
@type function
/*/

#DEFINE VELOCIDADE_IMPRESSORA 4
#DEFINE NLININI	 004
#DEFINE NQUEBNOR 004

user function ImpMostr()

	While ValidPerg()
		Processa({|| imprEtiq002() }, "Aguarde...", "Imprimindo...",.F.)
	EndDo

return

static function imprEtiq002()

	Local nQtdEtiq 	:= 1
	Local nLinha	:= NLININI
	Local nColuna   := 003
	Local nQuebra	:= NQUEBNOR
	Local cBarZZ2   := ""
	Local lSeg      := .F.
	Local nI        := 0
	Local cPorta    := "LPT1"
	Local aProduto  := {}
	Local cProduto  := MV_PAR01
	Local cModelo   := MV_PAR02
	Local nImpress  := MV_PAR03

	Local nX        := 1
	Local nJ        := 1

	private cZPL

	dbselectarea("SBS")
	If !CB5SetImp("000001")
		MsgStop("Problemas no local de impressão!")
		return
	endif

	MSCBPRINTER("ZEBRA",cPorta,,,.f.,,,,,,)
	MSCBCHKSTATUS(.F.)

	MSCBBEGIN(nQtdEtiq,VELOCIDADE_IMPRESSORA)

	aProduto := buscaItem(cProduto, cModelo)

	for nJ := 1 to len(aProduto)

		MSCBBEGIN(nQtdEtiq,VELOCIDADE_IMPRESSORA)

		nX := 1

		for nI := 1 to nImpress

			nLinha  := NLININI

			if lSeg
				MSCBBEGIN(nQtdEtiq,VELOCIDADE_IMPRESSORA)
				nColuna := 003
				nLinha  := NLININI
				lSeg := .F.
			endif

			if cValToChar(Mod(nX,2)) == "0"
				nColuna := 038
				// lSeg := .T.
			endif

			if cValToChar(Mod(nX,2)) == "1" .AND. nX > 1
				nColuna := 073
				lSeg := .T.
			endif

			nX := nX+1

			if nX > 3
				nX := 1
			endif

			/* COLUNA, LINHA, TEXTO */

			if !Empty(aProduto[nJ,1])
				MSCBSAY(nColuna,nLinha,aProduto[nJ,1],"N","0","18",,,,,.t.) // Código + Descrição Modelo
				nLinha := nLinha+2.5
			endif
			if !Empty(aProduto[nJ,4])
				MSCBSAY(nColuna,nLinha,aProduto[nJ,4],"N","0","18",,,,,.t.) // Código + Descrição Modelo
				nLinha := nLinha+3
			endif
			if !Empty(aProduto[nJ,5])
				MSCBSAYBAR(nColuna+2,nLinha,aProduto[nJ,5],"N","MB04",4,.F.,.F.,.F.,,2,1,.F.,.F.,"1",.T.) // Código Barras EAN
				nLinha := nLinha+4.5
				cEAN := SUBSTR(aProduto[nJ,5], 1, 1)
				MSCBSAY(nColuna,nLinha,cEAN,"N","0","019",,,,,.t.) // Código EAN
				cEan := SUBSTR(aProduto[nJ,5], 2, 6)
				MSCBSAY(nColuna+4,nLinha,cEAN,"N","0","019",,,,,.t.) // Código EAN
				cEan := SUBSTR(aProduto[nJ,5], 8, 6)
				MSCBSAY(nColuna+15,nLinha,cEAN,"N","0","019",,,,,.t.) // Código EAN
			endif

			if lSeg .OR. nI == nImpress
				MSCBInfoEti("ETQ_AAB"+cValToChar(nJ),"100X100")
				cZPL := MSCBEND()
				//MSCBCLOSEPRINTER()
			endif

			//cZPL := cZPL

		next nI

	next nJ

	//memoWrite("c:\temp\aaa"+cValToChar(nJ)+".txt",cZPL)

	MSCBCLOSEPRINTER()

return

static function buscaItem(cCodPro, cModelo)

	local aSBS     := {}
	local cQuery02 := ""
	local cQuery03 := ""
	local cAlias   := getNextAlias()
	local cCodSBS  := ""

	/* BS_FILIAL+BS_BASE+BS_ID+BS_CODIGO */
	/* 1 01 0006 0010 003  */
	/* BASE PRODUTO TIPO ARMACAO LENTE */
	/* 1 OCULOS THRUSTER BLACK MINERAL BRONZE */

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
				aAdd(aSBS, {SB1->B1_COD, Substr(SB1->B1_COD, 1, 1), Substr(SB1->B1_COD, 2, 2), AllTrim(SBSMOD->descricao), AllTrim(SB1->B1_CODBAR)}) // Produto
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
				aAdd(aSBS, {(cAlias)->B1_COD, Substr((cAlias)->B1_COD, 1, 1), Substr((cAlias)->B1_COD, 2, 2), AllTrim(SBSMOD->descricao), AllTrim((cAlias)->B1_CODBAR)}) // Produto
			endif

			SBSMOD->(dbCloseArea())

			(cAlias)->(dbSkip())
		enddo

		(cAlias)->(dbCloseArea())

	endif

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

	aAdd(aParamBox,{1,"Código Produto ",Space(getSX3Cache("B1_COD","X3_TAMANHO")),"","","SB1","",80,.F.}) //MV_PAR01
	aAdd(aParamBox,{1,"Modelo ",Space(getSX3Cache("BS_DESCR","X3_TAMANHO")),"","","SBSMOD","",80,.F.}) //MV_PAR02
	aAdd(aParamBox,{1,"Quantidade de Etiquetas",0,"@E 9,999","mv_par03>0","","",20,.T.}) // MV_PAR03

	If ParamBox(aParamBox,"Etiqueta Mostruário",@aRet,,,,,,,"ImpMostr",.T.,.T.)
		lRet := .T.
	EndIf

Return lRet
/*
user function xPTO2()

	rpcClearEnv()
	//RpcSetEnv("99","01")
	RPCSetEnv("01", "01", "admin", "agis9", "EST")
	Define MSDialog oMainWND from 0,0 to 400, 500 pixel
	@ 5,5 button "ETIQ002" of oMainWND pixel action u_etiq002()
	Activate MSDialog oMainWND

return
*/
