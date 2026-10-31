#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'

/*/{Protheus.doc} ImpProd
Etiqueta de Produtos
@author Victor Freidinger
@since 02/07/2019
@type function
/*/

#DEFINE VELOCIDADE_IMPRESSORA 4
#DEFINE NLININI	 003

user function ImpProd()

	while ValidPerg()
		Processa({|| imprEtiq001() }, "Aguarde...", "Imprimindo...",.F.)
	enddo

return

static function imprEtiq001()

	local nQtdEtiq 	:= 1
	local nLinha	:= NLININI
	local nColuna   := 005

	local cBarZZ2   := ""

	local lSeg      := .F.
	local nI        := 0
	local cPorta    := "LPT1"
	local aProduto  := {}
	local cProduto  := MV_PAR01
	local nImpress  := MV_PAR02
	local cTextoEtiqueta := ""
	local aLinhasTexto := {}
	local aLinhasModelo := {}
	local aPosTexto := {40,37,34}
	local nIdxLinha := 0
	local nIdxModelo := 0

	private cZPL

	If !CB5SetImp("000001")
		MsgStop("Problemas no local de impressão!")
		return
	endif

	MSCBPRINTER("ZEBRA",cPorta,,,.f.,,,,,,)
	//MSCBPRINTER("ELTRON",cPorta,,,.f.,,,,,,)
	MSCBCHKSTATUS(.F.)

	MSCBBEGIN(nQtdEtiq,VELOCIDADE_IMPRESSORA)

	for nI := 1 to nImpress

		nLinha  := NLININI

		if lSeg
			MSCBBEGIN(nQtdEtiq,VELOCIDADE_IMPRESSORA)
			nColuna := 005
			nLinha  := NLININI
			lSeg := .F.
		endif

		if cValToChar(Mod(nI,2)) == "0"
			nColuna := 055
			lSeg := .T.
		endif
		nLinha := nLinha+3

		aProduto := buscaItem(cProduto)
		cTextoEtiqueta := AllTrim(SB1->B1_ZZCOEMB)

		cBarZZ2 := buscaZZ2(cProduto)

		if Empty(cBarZZ2)
			// Ricardo Araujo em 07/04/2022
			msgAlert("Código de Barras não encontrado. Verifique tabela ZZ2! Entrar em contato com o TI.")
			return
		else

			// Ricardo Araujo em 07/04/2022
			if len(aProduto) <= 0
				msgAlert("Produto não encontrado! Entrar em contato com o TI.")
				return
			else
				cTextoEtiqueta := Lower(cTextoEtiqueta)
				aLinhasTexto := {}
				if !Empty(cTextoEtiqueta)
					aLinhasTexto := quebraTextoEtiqueta(cTextoEtiqueta,55,3)
					if Len(aLinhasTexto) == 0
						MsgAlert("O texto da etiqueta excede o limite de tres linhas.")
						MSCBCLOSEPRINTER()
						return
					endif
				endif

				// INICIO - Texto lateral rotacionado em 90 graus
				for nIdxLinha := 1 to Len(aLinhasTexto)
					MSCBSAY(nColuna+aPosTexto[nIdxLinha],6,aLinhasTexto[nIdxLinha],"R","0","018",,,,,.t.)
				next nIdxLinha
				// FIM - Texto lateral rotacionado em 90 graus

				/* COLUNA, LINHA, TEXTO */
				MSCBSAY(nColuna+5,nLinha,cBarZZ2,"N","0","020",,,,,.t.) // Código Barras ZZ2
				nLinha := nLinha+3 
				MSCBSAYBAR(nColuna+5,nLinha,cBarZZ2,"N","MB07",10,.f.,.F.,.F.,,2,2,.t.)
				nLinha := nLinha+11
				if !Empty(aProduto[4])
					aLinhasModelo := quebraTextoEtiqueta(aProduto[4],18,2)
					if Len(aLinhasModelo) == 0
						MsgAlert("A descrição do modelo excede o limite de duas linhas.")
						MSCBCLOSEPRINTER()
						return
					endif
					for nIdxModelo := 1 to Len(aLinhasModelo)
						MSCBSAY(nColuna,nLinha,aLinhasModelo[nIdxModelo],"N","0","030",,,,,.t.) // 0006 Modelo
						nLinha := nLinha+3
					next nIdxModelo
				endif
				MSCBSAY(nColuna,nLinha,aProduto[1],"N","0","035",,,,,.t.) // Cód Produto
				nLinha := nLinha+5
				if !Empty(aProduto[5])
					MSCBSAY(nColuna,nLinha,aProduto[5],"N","0","020",,,,,.t.) // 0010 Armacao
					nLinha := nLinha+3
				endif
				if !Empty(aProduto[6])
					MSCBSAY(nColuna,nLinha,aProduto[6],"N","0","020",,,,,.t.) // 003 Lente
					nLinha := nLinha+3
				endif
				if !Empty(aProduto[7])
					MSCBSAY(nColuna,nLinha,aProduto[7],"N","0","020",,,,,.t.) // Categoria
					nLinha := nLinha+3
				endif
				if !Empty(aProduto[8])
					MSCBSAYBAR(nColuna+05,nLinha, aProduto[8],"N","MB04",10,.F.,.F.,.F.,,2,1,.F.,.F.,"1",.T.) // Código Barras EAN
					nLinha := nLinha+14
					cEAN := SUBSTR(aProduto[8], 1, 1)
					MSCBSAY(nColuna+3,nLinha,cEAN,"N","0","021",,,,,.t.) // Código EAN
					cEan := SUBSTR(aProduto[8], 2, 6)
					MSCBSAY(nColuna+06,nLinha,cEAN,"N","0","021",,,,,.t.) // Código EAN
					cEan := SUBSTR(aProduto[8], 8, 6)
					MSCBSAY(nColuna+18,nLinha,cEAN,"N","0","021",,,,,.t.) // Código EAN
				endif
				if lSeg .OR. nI == nImpress
					MSCBInfoEti("ETQ_AAA","100X100")
					cZPL := MSCBEND()
					//MSCBCLOSEPRINTER()
				endif

			endif

		endif

	next nI

	//memoWrite("c:\temp\aaa.txt",cZPL)

	MSCBCLOSEPRINTER()

	//U_ImpProd()	/*Vamos Implementar?*/

return

static function quebraTextoEtiqueta(cTexto,nMaxCaracteres,nMaxLinhas)

	local aLinhas := {}
	local cRestante := AllTrim(cTexto)
	local cPalavra := ""
	local cLinha := ""
	local nEspaco := 0

	while !Empty(cRestante)
		nEspaco := At(" ",cRestante)
		if nEspaco > 0
			cPalavra := Left(cRestante,nEspaco-1)
			cRestante := AllTrim(SubStr(cRestante,nEspaco+1))
		else
			cPalavra := cRestante
			cRestante := ""
		endif

		if !Empty(cPalavra)
			if Len(cPalavra) > nMaxCaracteres
				return {}
			endif

			if Empty(cLinha)
				cLinha := cPalavra
			elseif Len(cLinha)+1+Len(cPalavra) <= nMaxCaracteres
				cLinha += " "+cPalavra
			else
				AAdd(aLinhas,cLinha)
				if Len(aLinhas) >= nMaxLinhas
					return {}
				endif
				cLinha := cPalavra
			endif
		endif
	enddo

	if !Empty(cLinha)
		AAdd(aLinhas,cLinha)
	endif

return aLinhas

static function buscaItem(cCodPro)

	local aSBS     := {}
	local cQuery02 := ""
	local cQuery03 := ""
	local cQuery04 := ""

	/* BS_FILIAL+BS_BASE+BS_ID+BS_CODIGO */
	/* 1 01 0006 0010 003  */
	/* BASE PRODUTO TIPO ARMACAO LENTE */
	/* 1 OCULOS THRUSTER BLACK MINERAL BRONZE */

	if POSICIONE("SB1", 1, xFilial("SB1")+cCodPro, "!eof()")

		aAdd(aSBS, SB1->B1_COD) // Produto
		aAdd(aSBS, Substr(SB1->B1_COD, 1, 1)) // Base
		aAdd(aSBS, Substr(SB1->B1_COD, 2, 2)) // Linha

		cQuery02 := " SELECT BS_DESCR AS descricao " + CRLF
		cQuery02 += "   FROM " + retSqlName("SBS") + " SBS" + CRLF
		cQuery02 += "  WHERE BS_BASE = '" + Substr(SB1->B1_COD, 1, 1) + "'" + CRLF
		cQuery02 += "    AND BS_ID = '02' " + CRLF
		cQuery02 += "    AND BS_CODIGO = '" +  Substr(SB1->B1_COD, 4, 4) + "'" + CRLF
		cQuery02 += "    AND " + retSqlDel("SBS") + CRLF
		cQuery02 += "    AND " + retSqlFil("SBS") + CRLF
		
		TCQUERY cQuery02 NEW ALIAS "SBSMOD"

		if !Empty(SBSMOD->descricao)
			aAdd(aSBS, AllTrim(SBSMOD->descricao)) // Modelo
		else
			aAdd(aSBS, "")
		endif

		SBSMOD->(dbCloseArea())

		cQuery03 := " SELECT BS_DESCR AS descricao " + CRLF
		cQuery03 += "   FROM " + retSqlName("SBS") + " SBS" + CRLF
		cQuery03 += "  WHERE BS_BASE = '" + Substr(SB1->B1_COD, 1, 1) + "'" + CRLF
		cQuery03 += "    AND BS_ID = '03' " + CRLF
		cQuery03 += "    AND BS_CODIGO = '" +  Substr(SB1->B1_COD, 8, 4) + "'" + CRLF
		cQuery03 += "    AND " + retSqlDel("SBS")
		cQuery03 += "    AND " + retSqlFil("SBS")

		TCQUERY cQuery03 NEW ALIAS "SBSARM"

		if !Empty(SBSARM->descricao)
			aAdd(aSBS, AllTrim(SBSARM->descricao)) // Armacao
		else
			aAdd(aSBS, "")
		endif

		SBSARM->(dbCloseArea())

		cQuery04 := " SELECT BS_DESCR AS descricao " + CRLF
		cQuery04 += "   FROM " + retSqlName("SBS") + " SBS" + CRLF
		cQuery04 += "  WHERE BS_BASE = '" + Substr(SB1->B1_COD, 1, 1) + "'" + CRLF
		cQuery04 += "    AND BS_ID = '04' " + CRLF
		cQuery04 += "    AND BS_CODIGO = '" +  Substr(SB1->B1_COD, 12, 3) + "'" + CRLF
		cQuery04 += "    AND " + retSqlDel("SBS")
		cQuery04 += "    AND " + retSqlFil("SBS")

		TCQUERY cQuery04 NEW ALIAS "SBSLEN"

		if !Empty(SBSLEN->descricao)
			aAdd(aSBS, AllTrim(SBSLEN->descricao)) // Lente
		else
			aAdd(aSBS, "")
		endif

		SBSLEN->(dbCloseArea())

		if Empty(SB1->B1_ZZCATEG)
			aAdd(aSBS, "1")
		else
			aAdd(aSBS, "CAT. FILTRO " + SB1->B1_ZZCATEG)
		endif // Categoria

		if !Empty(SB1->B1_CODBAR)
			aAdd(aSBS, AllTrim(SB1->B1_CODBAR)) // Código EAN
		else
			aAdd(aSBS, "")
		endif
	endif

	/* POSICÃO 01 =  Código do Produto B1_COD */
	/* POSICÃO 02 =  Base */
	/* POSICÃO 03 =  Linha */
	/* POSICÃO 04 =  Modelo */
	/* POSICÃO 05 =  Armacao */
	/* POSICÃO 06 =  Lente */
	/* POSICÃO 07 =  Categoria do Produto B1_ZZCATEG */
	/* POSICÃO 08 =  Código EAN para código de barras B1_CODBAR */
return aSBS

Static Function ValidPerg()

	Local aRet		:= {}
	Local aParamBox	:= {}
	Local lRet 		:= .F.

	if funName() == "MATA010"
		//MV_PAR01 := SB1->B1_COD
		aAdd(aParamBox,{1,"Código Produto ",SB1->B1_COD,"","","SB1","",80,.T.}) //MV_PAR01
		aAdd(aParamBox,{1,"Quantidade de Etiquetas",0,"@E 9,999","mv_par02>0","","",20,.F.}) // MV_PAR02
	else
		aAdd(aParamBox,{1,"Código Produto ",space(getSX3Cache("B1_COD","X3_TAMANHO")),"","","SB1","",80,.T.}) //MV_PAR01
		aAdd(aParamBox,{1,"Quantidade de Etiquetas",0,"@E 9,999","mv_par02>0","","",20,.F.}) // MV_PAR02
	endif

	If ParamBox(aParamBox,"Etiqueta Produto",@aRet,,,,,,,"ImpProd",.F.,.T.)
		lRet := .t.
	EndIf

Return lRet

static function buscaZZ2(cCodPro)

	local cCodBarZZ2 := ""
	local cQuery     := ""

	cQuery := " SELECT MAX(ZZ2_CODBAR) AS maiorCodBar " + CRLF
	cQuery += "   FROM " + retSqlName("ZZ2") + " ZZ2" + CRLF
	//cQuery += "  WHERE ZZ2_PRODUT = '" + cCodPro + "'" + CRLF
	cQuery += "  WHERE " + retSqlDel("ZZ2") + CRLF
	cQuery += "    AND " + retSqlFil("ZZ2") + CRLF

	TCQUERY cQuery NEW ALIAS "TABZZ2"

	dbSelectArea("ZZ2")

	//if POSICIONE("ZZ2", 2, xFilial("ZZ2")+cCodPro, "!eof()")
	cCodBarZZ2 := Soma1(TABZZ2->maiorCodBar)
	Reclock("ZZ2", .T.)
	ZZ2_CODBAR := cCodBarZZ2
	ZZ2_PRODUT := cCodPro
	ZZ2_QUANT  := 1
	MsUnlock()
	//endif

	TABZZ2->(DbCloseArea())

return cCodBarZZ2
