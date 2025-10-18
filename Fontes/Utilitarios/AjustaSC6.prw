#Include "Protheus.ch"
#Include 'topconn.ch' 

User Function AjustaSC6()

    If (Pergunte("AJUSC6",.T.))
        Processa({|| ExecutaAjuste()}, "Executando...")
    EndIf

Return

Static Function ExecutaAjuste()

Local cQuery   := ""
Local aArea    := GetArea()
Local nTotal   := 0
Local nAtual   := 0
Local cFilialx := ""
Local cNota    := ""
Local cItem    := ""
Local cProduto := ""

    cAliasSC6:= GetNextAlias()

    cQuery+="SELECT C6_ITEM, C6_QTDVEN, C6_QTDENT, C6_QTDEMP, D2_QUANT, C6_NOTA, D2_DOC, C6_NUM, "
    cQuery+="D2_PEDIDO, D2_EMISSAO, * FROM "
    cQuery+=Retsqlname("SC5") + " SC5010,  " + Retsqlname("SC6") + " SC6010, " + Retsqlname("SD2") + " SD2010 "
    cQuery+="WHERE 0=0 "
    cQuery+="AND SC5010.C5_FILIAL  =  SC6010.C6_FILIAL "
    cQuery+="AND SC5010.C5_NUM     =  SC6010.C6_NUM "
    cQuery+="AND SC5010.C5_CLIENTE =  SD2010.D2_CLIENTE "
    cQuery+="AND SC5010.C5_LOJACLI =  SD2010.D2_LOJA "
    cQuery+="AND SC6010.C6_FILIAL  =  SD2010.D2_FILIAL "
    cQuery+="AND SC6010.C6_NUM     =  SD2010.D2_PEDIDO "
    cQuery+="AND SC6010.C6_NOTA    =  SD2010.D2_DOC "
    cQuery+="AND SC6010.C6_ITEM    =  SD2010.D2_ITEMPV "
    cQuery+="AND SC6010.D_E_L_E_T_ = '' "
    cQuery+="AND SC5010.D_E_L_E_T_ = '' "
    cQuery+="AND SD2010.D_E_L_E_T_ = '' "
    cQuery+="AND SC5010.C5_EMISSAO >= '" + DTOS(MV_PAR01) + "' "
    cQuery+="AND SC5010.C5_EMISSAO <= '" + DTOS(MV_PAR02) + "' "
    cQuery+="AND SC6010.C6_NUM     >= '" + MV_PAR03 + "' "
    cQuery+="AND SC6010.C6_NUM     <= '" + MV_PAR04 + "' "
    cQuery+="AND SC6010.C6_PRODUTO >= '" + MV_PAR05 + "' "
    cQuery+="AND SC6010.C6_PRODUTO <= '" + MV_PAR06 + "' "
    cQuery+="AND SC6010.C6_ENTREG  >= '" + DTOS(MV_PAR07) + "' "
    cQuery+="AND SC6010.C6_ENTREG  <= '" + DTOS(MV_PAR08) + "' "
    cQuery+="AND SC6010.C6_QTDVEN  <> SC6010.C6_QTDENT "
    cQuery+="AND SC6010.C6_BLQ     <> 'R' "
    cQuery+="ORDER BY SC6010.C6_NUM"
    
    TCQuery cQuery NEW ALIAS (cAliasSC6)
     
    //Conta quantos registros existem, e seta no tamanho da régua
    Count To nTotal
    ProcRegua(nTotal)

    //Volta ao registro inicial da consulta
    (cAliasSC6)->(DbGoTop())

    While !((cAliasSC6)->(Eof()))

        dbSelectArea("SC6")
		dbSetOrder(1)

        cFilialx := (cAliasSC6)->C6_FILIAL
        cNota    := (cAliasSC6)->C6_NUM
        cItem    := (cAliasSC6)->C6_ITEM
        cProduto := (cAliasSC6)->C6_PRODUTO

        If dbSeek((cAliasSC6)->C6_FILIAL+(cAliasSC6)->C6_NUM+(cAliasSC6)->C6_ITEM+(cAliasSC6)->C6_PRODUTO)

            If (cAliasSC6)->C6_NOTA <> '' .AND. (cAliasSC6)->C6_QTDVEN <> (cAliasSC6)->C6_QTDENT .AND. (cAliasSC6)->C6_BLQ <> 'R' 

                DbSelectArea("SC6")
                SC6->(dbSeek((cAliasSC6)->C6_FILIAL+(cAliasSC6)->C6_NUM+(cAliasSC6)->C6_ITEM+(cAliasSC6)->C6_PRODUTO))

                RecLock("SC6",.F.)

                    SC6->C6_QTDENT := (cAliasSC6)->C6_QTDVEN

                    If (cAliasSC6)->C6_QTDEMP <> 0

                        SC6->C6_QTDEMP := 0

                    EndIf 

                SC6->(MsunLock())

            EndIf        
        EndIf

        (cAliasSC6)->(DbSkip())

        //Incrementa a mensagem na régua
        nAtual++
        IncProc("Corrigindo registro " + cValToChar(nAtual) + " de " + cValToChar(nTotal) + "...")       

    EndDo

    (cAliasSC6)->(DbCloseArea())      
    RestArea(aArea)

    MsgInfo(cValToChar(nAtual) + " registros corrigidos com Sucesso!")   

Return
