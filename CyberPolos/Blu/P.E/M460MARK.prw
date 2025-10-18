#include 'protheus.ch'
#include "rwmake.ch"
#Include 'tbiconn.ch'
#Include 'topconn.ch'  

/*/{Protheus.doc} M460MARK
Ponto de entrada usado para validar quando um pedido Blu pode ser gerado NF.
@type function
@version 2.0
@author Cyberpolos
@since 26/08/2020
@return lRet,logico, se pode ser gerado NF.
/*/
User Function M460MARK()
  
    Local aArea    := GetArea("SC9")
    Local aAreaC9  := SC9->(GetArea())
    Local aAreaC5  := SC5->(GetArea())
    Local cAlias   := ""
    Local cMark    := paramIxb[1]
    Local lInverte := ParamIXB[2]
    Local lRet     := .T.
    Local lUseBlu  := .T.
    Local cLog     := ""
    Local cQuery   := ""
    Local cPedido  := ""
    Local cNumBlu  := ""
    Local cCliente := ""
    Local cLoja    := ""
    Local nPedDesm := 0
    
    
    //Parametro para verIficar se as rotina BLU está ativa
    lUseBlu :=  GetMv('CP_BLUUSE')

    If lUseBlu

        Pergunte("MT461A", .F.)

        cAlias  := GetNextAlias()

        cQuery :="SELECT C9_OK, C9_FILIAL, C9_PRODUTO, C9_ITEM, C9_PEDIDO, C9_CLIENTE, C9_LOJA, "
        cQuery +="C9_XBLULIB, C9_XNUMBLU "
        cQuery +=" FROM "+RETSQLNAME("SC9")+" " 
        cQuery +=" WHERE D_E_L_E_T_<>'*'"
        cQuery +=" AND C9_FILIAL='"+FWxFilial("SC9")+"' " 
        cQuery +=" AND C9_OK"+Iif(lInverte, " <> ", " = ")+ "'"+cMark+"' " 
        cQuery +=" AND C9_CLIENTE >= '" + MV_PAR07 + "' AND C9_CLIENTE <= '" + MV_PAR08 + "' "                            
        cQuery +=" AND C9_LOJA >= '" + MV_PAR09 + "' AND C9_LOJA <= '" + MV_PAR10 + "' "                                  
        cQuery +=" AND C9_DATALIB >= '" + dToS(MV_PAR11) + "' AND C9_DATALIB <= '" + dToS(MV_PAR12) + "' "                
        cQuery +=" AND C9_PEDIDO >= '" + MV_PAR05 + "' AND C9_PEDIDO <= '" + MV_PAR06 + "' "                               
        cQuery +=" AND C9_BLEST = '' AND C9_BLCRED = ''"    

        TCQuery cQuery NEW ALIAS (cAlias)

        (cAlias)->(DbGoTop())        
              
        While (cAlias)->(!EOF())     

            cCliente := (cAlias)->C9_CLIENTE
            cLoja    := (cAlias)->C9_LOJA
            cPedido  := (cAlias)->C9_PEDIDO
            cNumBlu  := (cAlias)->C9_XNUMBLU
    
            If (cAlias)->C9_XBLULIB == 'N'

                clog +=  (cAlias)->C9_PEDIDO + " - Cliente: "+ (cAlias)->C9_CLIENTE + " - Loja: "+ (cAlias)->C9_LOJA + CRLF
                lRet := .F.     
                nPedDesm++

                While (cAlias)->(!EOF())  .And. cCliente == (cAlias)->C9_CLIENTE .And. cLoja == (cAlias)->C9_LOJA .And. cPedido == (cAlias)->C9_PEDIDO

                    DbSelectArea("SC9")
                    DbSetOrder(2)

                    If SC9->(DbSeek((cAlias)->C9_FILIAL+(cAlias)->C9_CLIENTE+(cAlias)->C9_LOJA +(cAlias)->C9_PEDIDO+(cAlias)->C9_ITEM))

                        RecLock("SC9",.F.) 
                            SC9->C9_OK := Iif(lInverte, cMark,' ')
                        MsUnlock()

                    EndIf	

                    (cAlias)->(dbskip())

                EndDo   

            Else        

               (cAlias)->(dbskip())     
                    
            EndIf           

        EndDo

        If nPedDesm > 0
            MsgInfo("Pedido(s) abaixo não contam autorizados/integrados ao portal Blu."+CRLF+CRLF+ cLog,"Atenção")   
        EndIf
        
    EndIf

   (cAlias)->(DbCloseArea())

    RestArea(aAreaC5)
    RestArea(aAreaC9)
    RestArea(aArea)

    //Restaurando a pergunta do botão Prep.Doc.
    Pergunte("MT460A", .F.)

Return lRet
