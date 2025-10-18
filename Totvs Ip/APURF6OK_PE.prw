#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} APURF6OK
Ponto de Entrada para atualizar o histórico do Contas a Pagar com o número da Nota conforme a Guia de ICMS
@author Victor Freidinger
@since 25/07/2019
@type function
/*/

user function APURF6OK()
	
	local lRet := .T.
	
	Reclock("SE2", .F.)
	SE2->E2_HIST := "Ref.: NF " + SF2->F2_DOC
	MsUnlock()
	
return lRet