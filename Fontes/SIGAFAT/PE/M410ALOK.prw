#Include "PROTHEUS.CH"
#INCLUDE "parmtype.ch"
 
User Function M410ALOK()
 
    Local lRet := .T.

    If !Empty(SC5->C5_NOTA)
        If ALTERA   //Alteração
            MsgAlert("ALTERAÇÂO - Pedido já faturado.","ATENÇÃO")
        ElseIf !INCLUI .And. !ALTERA    //Exclusão
            MsgAlert("EXCLUSÃO - Pedido já faturado.","ATENÇÃO")
        ElseIf INCLUI .And. IsInCallStack("A410COPIA")  //Cópia
            MsgAlert("CÓPIA - Pedido já faturado.","ATENÇÃO")
        EndIf
        lRet := .F.
    EndIf

Return lRet
