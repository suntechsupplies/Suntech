#include 'protheus.ch'
#include "rwmake.ch"

/*/{Protheus.doc} M410ALOK
Ponto de entrada utilizado para n�o permitir altera��es no pedido com condi��o de pagamento Blu, ap�s este ter sido liberado.
@type function
@version 2.0
@author Cyberpolos
@since 26/08/2020
@return lRet,logico, se o pedido pode ser alterado.
/*/
User Function M410ALOK()

    Local aArea := GetArea()
    Local lRet  := .T.
    Local lUseBlu  := .T.

    //Parametro para verIficar se as rotina BLU est� ativa
    lUseBlu :=  GetMv('CP_BLUUSE')

    If ALTERA .And. Alltrim(SC5->C5_CONDPAG) $ Alltrim(Getmv("CP_BLUCOND")) .And. !Empty(SC5->C5_XNUMBLU) .And. lUseBlu

        lRet  := .F.
        MsgInfo("Infelizmente por ser um pedido com condi��o de pagamento BLU, este pedido n�o pode ser alterado.","Aten��o")        
     
    Endif

    RestArea(aArea)

Return lRet
