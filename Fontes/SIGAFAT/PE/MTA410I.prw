#Include "Protheus.ch"

User Function MTA410I()


    Local aAreaOld := GetArea()

	dbSelectArea("SC5")
	If RecLock("SC5",.F.)
		Replace C5_FECENT With Date()+5
		MsUnLock()
	EndIf

	RestArea(aAreaOld)

Return
