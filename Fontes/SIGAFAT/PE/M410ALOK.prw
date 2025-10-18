#Include "PROTHEUS.CH"
#INCLUDE "parmtype.ch"
 
User Function M410ALOK()
 
    Local lRet := .T.

    If !Empty(SC5->C5_NOTA)
        If ALTERA   //Altera��o
            MsgAlert("ALTERA��O - Pedido j� faturado.","ATEN��O")
        ElseIf !INCLUI .And. !ALTERA    //Exclus�o
            MsgAlert("EXCLUS�O - Pedido j� faturado.","ATEN��O")
        ElseIf INCLUI .And. IsInCallStack("A410COPIA")  //C�pia
            MsgAlert("C�PIA - Pedido j� faturado.","ATEN��O")
        EndIf
        lRet := .F.
    EndIf

Return lRet
