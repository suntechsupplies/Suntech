#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'

/*/{Protheus.doc} A010TOK
Ponto de Entrada na confirmacao do cadastro/alteracao do Produto (MATA010)
@author Victor Freidinger
@since 03/09/2019
@type function
/*/

User Function A010TOK()

	Local aArea	:= GetArea()
	Local lRet  := .T.

	If INCLUI
		
		buscaZZ2(M->B1_COD)
		
		Reclock("SB1",.F.)	    
        	SB1->B1_ZSTATUS := "3" //Ricardo Araujo Suntech 08/02/2023 11:43		
		SB1->(MsUnLock())

	EndIf

	If M->B1_CODBAR <> M->B1_CODGTIN .AND. M->B1_TIPO = "PA" //Ricardo Araujo Suntech 05/07/2023 11:54
		MsgInfo("<b>Os campos Cod Barras e Cod GTIN estão diferentes. Favor revise o cadastro.</b>", "Atenção")
		lRet := .F.
	EndIf

	RestArea(aArea)	
	
Return lRet

/* Funcao para inserir novo registro na tabela ZZ2 com o ï¿½ltimo cï¿½digo de barras +1 e o cï¿½digo do produto incluï¿½do */
Static Function buscaZZ2(cCodPro)

	Local aArea		 := GetArea()
	Local cCodBarZZ2 := ""
	Local cQuery     := ""
	//local lRet       := .T.

	cQuery := " SELECT MAX(ZZ2_CODBAR) AS maiorCodBar " + CRLF
	cQuery += "   FROM " + retSqlName("ZZ2") + " ZZ2" + CRLF
	cQuery += "  WHERE " + retSqlDel("ZZ2") + CRLF
	cQuery += "    AND " + retSqlFil("ZZ2") + CRLF

	TCQUERY cQuery NEW ALIAS "TABZZ2"

	dbSelectArea("ZZ2")

	cCodBarZZ2 := Soma1(TABZZ2->maiorCodBar)
	Reclock("ZZ2", .T.)
	ZZ2_CODBAR := cCodBarZZ2
	ZZ2_PRODUT := cCodPro
	ZZ2_QUANT  := 1
	MsUnlock()

	TABZZ2->(DbCloseArea())

	RestArea(aArea)	

Return
