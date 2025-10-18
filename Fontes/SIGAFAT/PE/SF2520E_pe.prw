#INCLUDE "totvs.ch"
#INCLUDE "parmtype.ch"

/*/{Protheus.doc} SF2520E

Ponto de Entrada executado na exclusão da Nota Fiscal.

@type function
@author Deivid A. C. de Lima
@since 19/04/2010

@see MSGNF04
/*/
User Function SF2520E() 
	Local lRet := .T.

	//Executa o Wizard do Acelerador de Mensagens da NF na exclusão da Nota Fiscal de Saída
	If ExistBlock("MSGNF04",.F.,.T.)
		ExecBlock("MSGNF04",.F.,.T.,{})
	Endif

Return lRet
