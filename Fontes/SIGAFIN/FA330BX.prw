#include "PROTHEUS.CH"

user function FA330BX()

	Local aAreaSE1 := GetArea()
	Local lRet     := .T.

	DbSelectArea("SE1")

	//Suntech (Ricardo Araujo) - Gravar campo de controle para Integra��o via API 10/03/2024
	Reclock("SE1",.F.)
	    SE1->E1_ZSTATUS	:= "4"
	MsUnlock()
	
	MsgAlert("Ap�s Compensa��o com Sucesso - FA330BX")

	RestArea(aAreaSE1)

Return lRet
