#include 'protheus.ch'
#include "rwmake.ch"

/*/{Protheus.doc} M410PVNF
Ponto de entrada usado para validar quando um pedido Blu pode ser gerado NF.
@type function
@version 
@author Cyberpolos
@since 26/08/2020
@return lRet,logico, se pode ser gerado NF.
/*/
User Function M410PVNF()

    Local aArea := GetArea()
    Local lRet  := .T.
    Local lUseBlu  := .T.

    //Parametro para verIficar se as rotina BLU est� ativa
    lUseBlu :=  GetMv('CP_BLUUSE')

    If !Empty(Alltrim(SC5->C5_XNUMBLU)) .And. lUseBlu
        dbSelectArea("ZBL")
        If ZBL->(DbSeek(FWxFilial("ZBL")+SC5->C5_XNUMBLU))		
            If ZBL->ZBL_STATUS $("3|8")
                lRet := .T.
            Else
                lRet := .F.
                If Empty(ZBL->ZBL_STATUS)
                    MsgInfo("Cobran�a BLU "+ZBL->ZBL_NUMBLU+", ainda n�o integrado ao portal BLU, impossibilitando gera��o de NF.",;
                    "Pedido "+SC5->C5_NUM)
                Else			
                    MsgInfo("Cobran�a BLU "+ZBL->ZBL_NUMBLU+", com status "+Alltrim(ZBL->ZBL_STATUS)+" - "+Alltrim(ZBL->ZBL_MSGINT)+;
                    ", impossibilitando a gera��o de NF.","Pedido "+SC5->C5_NUM)
                EndIf
            EndIf
        Else
            lRet := .F.
            MsgInfo("N�o foi poss�vel localizar a cobran�a BLU "+ Alltrim(ZBL->ZBL_NUMBLU)+",  impossibilitando gera��o de NF.",;
            "Pedido "+SC5->C5_NUM)
        EndIf
    EndIf

    RestArea(aArea)

Return lRet
