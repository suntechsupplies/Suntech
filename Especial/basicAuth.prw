#INCLUDE "PROTHEUS.CH"
#INCLUDE "TBICONN.CH"

User Function basicAuth(cEncoded)

	Local lUserExists 		:= .F.
	Local lPasswordCorrect	:= .F.
	Local lAuthorized 		:= .F.
	Local aInfoUser 		:= {}

	aInfoUser := StrTokArr(Decode64(cEncoded), ":")
	PswOrder(2)
	lUserExists := PswSeek(aInfoUser[1], .T.)

	If lUserExists
		lPasswordCorrect := PswName(aInfoUser[2])

		If lPasswordCorrect
			lAuthorized := .T.
		Else
			lAuthorized := .F.
		EndIf

	Else
		lAuthorized := .F.    
	EndIf

Return lAuthorized