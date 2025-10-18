#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MT410TOK
Ponto de entrada utilizado para quando for uma exclus�o de pedido chamar rotina de cancelamento/devolu��o de cobran�a no portal da Blu.
@type function
@version 2.0 
@author Raphael
@since 26/08/2020
@return lRet, logico, se pode prosseguir a exclus�o do pedido.
/*/
User Function MT410TOK() 

	Local lRet   := .T.
	Local aArea  := GetArea()
	Local _nOper := PARAMIXB[1]
	Local lUseBlu  := .T.

    //Parametro para verIficar se as rotina BLU est� ativa
    lUseBlu :=  GetMv('CP_BLUUSE')

	If lUseBlu

		//se for exclus�o com condi��o de pagamento BLU
		If _nOper = 1 .And. Alltrim(SC5->C5_CONDPAG) $ Alltrim(Getmv("CP_BLUCOND")) .And. Empty(SC5->C5_LIBEROK)   	
				If !Empty(SC5->C5_XNUMBLU) .or. !Empty(SC5->C5_XIDBLU)
					//Chamada da rotina de cancelamento/devolu��o de cobran�a BLU, passando no paramentro (1= cobran�a,numero BLU na tabela ZBL)
					lRet := U_BLUCANC("1",SC5->C5_FILIAL,SC5->C5_XNUMBLU)
				Endif		
		EndIf
	
	EndIf

    RestArea(aArea)

Return lRet
