#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'tbiconn.ch'
#Include 'topconn.ch'  
#include 'rwmake.ch'

User Function BluPped(_cFil,cPedido)
        
    Local aRet     := {}
    Local cLog     := ""
    Local nPorcPed := 0
    Local nQtdNec  := 0
    Local _nTotSc6 := 0
    Local _nTotSc9 := 0
    Local lRet     := .F.

    _nTotSc6 := GetSc6(_cFil,cPedido)    

    If _nTotSc6 > 0

        nPorcPed := GetMv('CP_BLUPPED') 

        nQtdNec := ((_nTotSc6 * nPorcPed) /100 )

        _nTotSc9 := GetSc9(_cFil,cPedido)  

        If _nTotSc9 >= nQtdNec
            
            cLog := "Pedido atingiu "+cValToChar(Round(((_nTotSc9 /_nTotSc6)*100),0))+"% (qtd "+cValToChar(_nTotSc9)+")."
            cLog += " Qtd total do pedido "+ cValToChar(_nTotSc6)+", e será integrado ao portal BLU"
            cLog += " | user: "+Alltrim(cUserName) + " - " +DTOC(Date())
            MsgInfo("Pedido "+cPedido+" atingiu "+cValToChar(nPorcPed)+"% e será integrado ao portal BLU","Atenção")
            lRet := .T.

        Else
            
            cLog := "Pedido com "+cValToChar(Round(((_nTotSc9 /_nTotSc6)*100),0))+"% (qtd "+cValToChar(_nTotSc9)+"), dos "
            cLog +=  cValToChar(nPorcPed)+"% (qtd "+cValToChar(nQtdNec)+ ") necessario. Qtd total pedido "+ cValToChar(_nTotSc6)+"."
            cLog += "NAO sera integrado ao portal Blu | user: "+Alltrim(cUserName) + " - " +DTOC(Date())

            MsgInfo("Pedido "+cPedido+" NÃO atingiu "+cValToChar(nPorcPed)+"% ,impossibilitando sua integração ao portal BLU","Atenção")
            lRet := .F.

        EndIf

        aAdd(aRet,{lRet,cLog})

    EndIf            

Return aRet

Static Function GetSc6(_cFil,cPedido)

    Local cAlias  := ""
    Local cQuery  := ""
    Local _nTotal := 0

    cAlias  := GetNextAlias()
    
    cQuery+=" SELECT " 
    cQuery+=" SUM( C6_QTDVEN) AS TOTAL" 
    cQuery+=" FROM" 
    cQuery+="	"+Retsqlname("SC6") + " A (NOLOCK)"
    cQuery+=" WHERE" 
    cQuery+="	A.D_E_L_E_T_ = ' ' " 
    cQuery+="	AND A.C6_FILIAL = '"+ _cFil + "'"
    cQuery+="	AND A.C6_NUM  = '"+  cPedido + "'"

    TCQuery cQuery NEW ALIAS (cAlias)

    (cAlias)->(DbGoTop())

     _nTotal := (cAlias)->TOTAL

    (cAlias)->(DbCloseArea())

Return _nTotal


Static Function GetSc9(_cFil,cPedido)

    Local cAlias  := ""
    Local cQuery  := ""
    Local _nTotal := 0

    cAlias  := GetNextAlias()
    
    cQuery+=" SELECT " 
    cQuery+=" SUM(C9_QTDLIB) AS TOTAL" 
    cQuery+=" FROM" 
    cQuery+="	"+Retsqlname("SC9") + " B (NOLOCK)"
    cQuery+=" WHERE" 
    cQuery+="	B.D_E_L_E_T_ = ' ' " 
    cQuery+="	AND B.C9_FILIAL = '"+ _cFil + "'"
    cQuery+="	AND B.C9_PEDIDO  = '"+  cPedido + "'"
    cQuery+="	AND B.C9_BLEST <> '02' "
    cQuery+="	AND B.C9_BLCRED = ' '  "

    TCQuery cQuery NEW ALIAS (cAlias)

    (cAlias)->(DbGoTop())

     _nTotal := (cAlias)->TOTAL

    (cAlias)->(DbCloseArea())

Return _nTotal
