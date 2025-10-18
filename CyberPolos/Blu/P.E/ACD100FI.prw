#include 'protheus.ch'
#include "rwmake.ch"

/*/{Protheus.doc} ACD100FI
Ponto de entrada utilizado para adicionar filtro na ordem de separação. Ao liberar um pedido
com condição de pagamento BLU, o campo C9_XBLULIB é preenchido com 'N', somente será alterado
quando a cobrança for aprovada no portal BLU.
@type User Function
@version 2.0
@author Cyberpolos
@since 10/09/2020
@return Array, retorna informando a opção e o filtro a ser adicionado.
/*/

User Function ACD100FI()

    Local aArea    := GetArea()
    Local aAreaSC9 := SC9->(GetArea())
    Local cFiltro  := ""
    Local nOrig    := 1 // 1 = Pedido de Venda / 2 = Nota Fiscal / 3 = Ordem de Produção
    Local lUseBlu  := .T.

    //Parametro para verIficar se as rotina BLU está ativa
    lUseBlu :=  GetMv('CP_BLUUSE')

    If lUseBlu
        cFiltro := " C9_XBLULIB <> 'N' "
    Else
        cFiltro := " C9_PEDIDO <> ' ' "         
    EndIf

    RestArea(aAreaSC9) 
    RestArea(aArea)

Return {nOrig,cFiltro}
