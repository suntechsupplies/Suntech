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

    //Parametro para verIficar se as rotina BLU está ativa
    lUseBlu :=  GetMv('CP_BLUUSE')

    If !Empty(Alltrim(SC5->C5_XNUMBLU)) .And. lUseBlu
        dbSelectArea("ZBL")
        If ZBL->(DbSeek(FWxFilial("ZBL")+SC5->C5_XNUMBLU))		
            If ZBL->ZBL_STATUS $("3|8")
                lRet := .T.
            Else
                lRet := .F.
                If Empty(ZBL->ZBL_STATUS)
                    MsgInfo("Cobrança BLU "+ZBL->ZBL_NUMBLU+", ainda não integrado ao portal BLU, impossibilitando geração de NF.",;
                    "Pedido "+SC5->C5_NUM)
                Else			
                    MsgInfo("Cobrança BLU "+ZBL->ZBL_NUMBLU+", com status "+Alltrim(ZBL->ZBL_STATUS)+" - "+Alltrim(ZBL->ZBL_MSGINT)+;
                    ", impossibilitando a geração de NF.","Pedido "+SC5->C5_NUM)
                EndIf
            EndIf
        Else
            lRet := .F.
            MsgInfo("Não foi possível localizar a cobrança BLU "+ Alltrim(ZBL->ZBL_NUMBLU)+",  impossibilitando geração de NF.",;
            "Pedido "+SC5->C5_NUM)
        EndIf
    EndIf

    RestArea(aArea)

Return lRet
