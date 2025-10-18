#Include "Totvs.ch"

/*/{Protheus.doc} CH_P_PED
@author Ihorran Milholi
@since 17/05/2021
@version 1.0
/*/

/*
oPedido = JSON do Pedido
*/

User Function CH_G_PCAN(oPedido)

Local aArea     := GetArea()
Local aErros    := {}
Local cDataCan  := SubString(dtos(ddatabase),1,4)+'-'+SubString(dtos(ddatabase),5,2)+'-'+SubString(dtos(ddatabase),7,2)+'T00:00:00.000-03:00'

Private lBloqueados := .t.

//numero do pedido do parceiro
If (Valtype(oPedido['codigoErp']) == "C")
    //posiciona no pedido de venda
    SC5->(dbSetOrder(1))
    If SC5->(dbSeek(xFilial("SC5")+Padr(oPedido['codigoErp'],FWSX3Util():GetFieldStruct("C5_NUM")[3])))
        IF (Empty(SC5->C5_NOTA))
            //apaga amarracao do codigo de marketplace
            Reclock("SC5",.f.)
            SC5->C5_PEDECOM := ""
            SC5->(msUnLock())
            //Realiza estorno de liberação de estoque e credito      
            SC9->(dbSetOrder(1))
            If SC9->(dbSeek(xFilial('SC9')+SC5->C5_NUM))
                While SC9->(!Eof()) .and. xFilial('SC9')+SC5->C5_NUM == SC9->C9_FILIAL+SC9->C9_PEDIDO
                    If Empty(SC9->C9_NFISCAL)
                        SC6->(dbSetOrder(1))
                        SC6->(dbSeek(xFilial("SC6")+SC9->C9_PEDIDO+SC9->C9_ITEM))                                           
                        Begin Transaction
                            SC9->(a460Estorna())
                        End Transaction
                    EndIf
                    SC9->(dbSkip())
                EndDo    
            EndIf
            //eliminacao de residuo
            SC6->(dbSetOrder(1))
            If SC6->(dbSeek(xFilial("SC6")+SC5->C5_NUM))
                While SC6->(!Eof()) .And. xFilial("SC6")+SC5->C5_NUM == SC6->C6_FILIAL+SC6->C6_NUM
                    If SC6->C6_QTDVEN - SC6->C6_QTDENT > 0
                        MaAvalSC6("SC6",4,"SC5",Nil,Nil,Nil,Nil,Nil,Nil)
                        MaResDoFat(,.T.,.F.)
                    EndIf
                    SC6->(dbSkip())
                EndDo
                SC6->(MaLiberOk({SC5->C5_NUM},.T.)) 
            EndIf
        EndIf
        //verifica se foi eliminado residuo
        If (SC5->C5_NOTA == 'XXXXXXXXX')
            oPedido['dataCancelado'] := cDataCan
        Else
            aAdd(aErros,"Não foi possivel realizar a baixa do Pedido")
        EndIf
    Else
        oPedido['dataCancelado'] := cDataCan
    EndIf
EndIf        
        
//retorna a area
RestArea(aArea)

Return {oPedido,aErros}
