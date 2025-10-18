#INCLUDE "rwmake.ch"
/*-------------------------------------------------------------------------------
{Protheus.doc}  CalcPeso
                Calcula peso dos ítens do pedido de vendas
@type           function
@version        1.0
@author         Carlos Eduardo Saturnino - Atlanta Consulting
@since          06/04/2022
@param          nValor, numeric, quantidade do item
@return         nValor, quantidade do item
-------------------------------------------------------------------------------*/
User Function CalcPeso(nValor)

    Local nPesoBruto := 0
    Local nPesoLiqui := 0
    Local _nItem

    nPosItem := ASCAN(aHeader, {|aVal| Alltrim(aVal[2]) == "C6_ITEM"})
    nPosProd := ASCAN(aHeader, {|aVal| Alltrim(aVal[2]) == "C6_PRODUTO"})
    nPosQtde := ASCAN(aHeader, {|aVal| Alltrim(aVal[2]) == "C6_QTDVEN"})
    nPosQtdL := ASCAN(aHeader, {|aVal| Alltrim(aVal[2]) == "C6_QTDLIB"})

    For _nItem := 1 to Len(aCols)                    

        If ! aCols[_nItem,Len(aHeader)+1]

            Posicione("SB1",1,xFilial("SB1")+aCols[_nItem,nPosProd],"")
            Posicione("SB5",1,xFilial("SB5")+aCols[_nItem,nPosProd],"")
            
            // Posiciona-se no item do pedido atual gravado e efetua o abatimento caso o mesmo já tenha sido atendido parcialmente
            If SC6->(dbSetOrder(2), dbSeek(xFilial("SC6")+aCols[_nItem,nPosProd]+M->C5_NUM+aCols[_nItem,nPosItem]))
        
                If !Empty(aCols[_nItem,nPosQtdL])

                    nPesoLiqui += ((aCols[_nItem,nPosQtdL]) * SB1->B1_PESO)
                    nPesoBruto += ((aCols[_nItem,nPosQtdL]) * SB1->B1_PESBRU)    

                Else				 

                    nPesoLiqui += ((aCols[_nItem,nPosQtde] - SC6->C6_QTDENT) * SB1->B1_PESO)
                    nPesoBruto += ((aCols[_nItem,nPosQtde] - SC6->C6_QTDENT) * SB1->B1_PESBRU)    
                
                Endif

            Else
            
                If !Empty(aCols[_nItem,nPosQtdL])
                    nPesoLiqui += (aCols[_nItem,nPosQtdL] * SB1->B1_PESO)
                    nPesoBruto += (aCols[_nItem,nPosQtdL] * SB1->B1_PESBRU)
                Else
                    nPesoLiqui += (aCols[_nItem,nPosQtde] * SB1->B1_PESO)
                    nPesoBruto += (aCols[_nItem,nPosQtde] * SB1->B1_PESBRU)
                Endif
            
            Endif
        EndIf
    Next

    M->C5_PBRUTO := nPesoBruto
    M->C5_PESOL  := nPesoLiqui       

    GetDRefresh() 

Return nValor
