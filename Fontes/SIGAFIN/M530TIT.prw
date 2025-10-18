#include "PROTHEUS.CH"

User Function M530TIT()

	Local aAreaSE1 := GetArea()
	Local lRet     := .T.

	cTipo := 'PA'

	RestArea(aAreaSE1)

Return lRet
