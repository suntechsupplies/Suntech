#include 'protheus.ch'
#include 'parmtype.ch'

/*
Rotina		:	MT220TOK
Autor		:	Dione Oliveira
Data		:	29/07/2019
Descricao	:	Rotina para não permitir incluir saldo inicial sem informar o valor total do produto
Obs	 		:
*/

User function MT220TOK()
	
	Local cRet		:= 	.T.
	Local aArea := GetArea()
	Local aAreaB9 := SB9->(GetArea())

	IF M->B9_QINI <> 0 .And. M->B9_VINI1 == 0
		Alert("Nao é permitido incluir saldo inicial sem informar o valor total do produto")
		cRet := .F.
	EndIf

	RestArea(aAreaB9)
	RestArea(aArea)
	
return cRet