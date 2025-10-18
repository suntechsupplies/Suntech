#include 'protheus.ch'
#include "rwmake.ch"

/*/{Protheus.doc} ACD100FI
Ponto de entrada utilizado para adicionar filtro na ordem de separa��o. Ao liberar um pedido
com condi��o de pagamento BLU, o campo C9_XBLULIB � preenchido com 'N', somente ser� alterado
quando a cobran�a for aprovada no portal BLU.
@type User Function
@version 2.0
@author Cyberpolos
@since 10/09/2020
@return Array, retorna informando a op��o e o filtro a ser adicionado.
/*/

User Function ACD100FI()

    Local aArea    := GetArea()
    Local aAreaSC9 := SC9->(GetArea())
    Local cFiltro  := ""
    Local nOrig    := 1 // 1 = Pedido de Venda / 2 = Nota Fiscal / 3 = Ordem de Produ��o
    Local lUseBlu  := .T.

    //Parametro para verIficar se as rotina BLU est� ativa
    lUseBlu :=  GetMv('CP_BLUUSE')

    If lUseBlu
        cFiltro := " C9_XBLULIB <> 'N' "
    Else
        cFiltro := " C9_PEDIDO <> ' ' "         
    EndIf

    RestArea(aAreaSC9) 
    RestArea(aArea)

Return {nOrig,cFiltro}
