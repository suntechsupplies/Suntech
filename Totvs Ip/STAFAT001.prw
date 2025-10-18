#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'

/*/{Protheus.doc} STAFAT01
Função chamada no gatilho do CNPJ do cadastro de Cliente para buscar o último código e loja conforme a raiz do CNPJ
@author Victor Freidinger
@since 06/09/2019
@type function

Campo Origem: A1_CGC
Campo Destino: A1_CGC
Parametro(A1_CGC)

/*/

user function STAFAT01(cCNPJ)

	local cQuery := ""
	local cAlias := getNextAlias()
	local cLoja  := ""
	local cCod   := ""
	local cRaiz  := ""
	local aArea  := getArea()

	cRaiz := SUBSTR(cCNPJ, 1, 8)

	dbSelectArea("SA1")
	cQuery := " SELECT MAX(A1_LOJA) AS maiorLoja " + CRLF
	cQuery += "      , A1_COD " + CRLF
	cQuery += "   FROM " + retSqlName("SA1") + " SA1" +  CRLF
	cQuery += "  WHERE SUBSTRING(A1_CGC, 1, 8) = '" + cRaiz + "'" + CRLF
	cQuery += "    AND SUBSTRING(A1_COD, 1, 1) = 'C' " + CRLF
	cQuery += "    AND " + retSqlDel("SA1") + CRLF
	cQuery += "    AND " + retSqlFil("SA1") + CRLF
	cQuery += "  GROUP BY A1_COD " + CRLF
	cQuery += "  ORDER BY 1 DESC " + CRLF

	TcQuery cQuery New Alias (cAlias)

	if !Empty((cAlias)->maiorLoja)
		cCod  := (cAlias)->A1_COD
		cLoja := (cAlias)->maiorLoja
		cLoja := Soma1(cLoja)
	else
		cCod  := ultCli()
		cLoja := "01"		
	endif

	(cAlias)->(dbCloseArea())
	
	//gdFieldPut("A1_COD", cCod)
	//gdFieldPut("A1_LOJA", cLoja)
	
	M->A1_COD := cCod
	M->A1_LOJA := cLoja
	
	restArea(aArea)

return cCNPJ

/* Função para buscar último código do cliente quando não encontrar Raiz */
static function ultCli()

	local cQueryM := ""
	local cCod    := ""

	cQueryM := " SELECT MAX(A1_COD) AS maiorCod " + CRLF
	cQueryM += "   FROM " + retSqlName("SA1") + " SA1" +  CRLF
	cQueryM += "  WHERE SUBSTRING(A1_COD, 1, 1) = 'C' " + CRLF
	cQueryM += "    AND " + retSqlDel("SA1") + CRLF
	cQueryM += "    AND " + retSqlFil("SA1") + CRLF

	TCQUERY cQueryM NEW ALIAS "SA1TMP"

	cCod := SA1TMP->maiorCod
	cCod := Soma1(cCod)

	SA1TMP->(dbCloseArea())

return cCod