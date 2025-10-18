#INCLUDE "totvs.ch"
#INCLUDE "parmtype.ch"

/*/{Protheus.doc} SF1100E

Ponto de Entrada executado na exclusão da Nota Fiscal.

@type function
@author Deivid A. C. de Lima
@since 19/04/2010

@see MSGNF03
/*/
User Function SF1100E() 
	Local lRet := .T.

	//Executa o Wizard do Acelerador de Mensagens da NF na exclusão da Nota Fiscal de Entrada
	If ExistBlock("MSGNF03",.F.,.T.)
		ExecBlock("MSGNF03",.F.,.T.,{})
	Endif

Return lRet
