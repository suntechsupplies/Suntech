#Include "rwmake.ch"
#Include "protheus.ch"
 
User Function MT410BRW()
 
Local aAreaSC5 := SC5->(GetArea())
Local aAreaSA3 := SA3->(GetArea())
Local cCodUser := RetCodUsr()      //Retorna o código do usuário
Local cCodVen  := ""
 
SA3->(dbSetOrder(7))
If SA3->(dbSeek(xFilial("SA3")+cCodUser)) // Localiza Vendedor pelo código do usuário
     cCodVen := SA3->A3_COD
EndIf
 
If !Empty(cCodVen)
     //Filtra somente os pedidos do vendedor
     dbSelectArea("SC5")
     Set Filter To &("SC5->C5_VEND1 == '" + cCodVen + "'")
Else
     //Mostra todos os pedidos
     dbSelectArea("SC5")
     Set Filter To
EndIf
 
RestArea(aAreaSC5)
RestArea(aAreaSA3)
 
Return
