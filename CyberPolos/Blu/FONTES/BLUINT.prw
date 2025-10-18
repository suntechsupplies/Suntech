#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch' 
#include 'rwmake.ch'   
#Include "tbiconn.ch"

/*/{Protheus.doc} BluInt
Rotina ira fazer intergração da cobrança e fatura na tabela ZBL.
@type User Function
@version 2.0
@author Cyberpolos
@since 14/07/2020
@Return Return_type, Return_description
/*/

/*/{Protheus.doc} BluInt
Rotina ira fazer intergração da cobrança e fatura na tabela ZBL.
@type User Function
@version 2.0
@author Cyberpolos
@since 14/07/2020
@param cOpcao, character, tipo de cobrança que será realizada 1=Conbrança 2=Fatura
@param cNum, character, param_description
@param cSerie, character, param_description
@Return Return_type, Return_description
/*/
User Function BluInt(cOpcao,cNum,cSerie,_cFil)

    Local aArea     := GetArea()
    Local aAreaX6   := SX6->(GetArea())
    Local aRelImp   := Nil
    Local cLog      := ""
    Local cDevSal   := ""
    Local cTipoPG   := ""
    Local lRet      := .F.
    Local _nValFret := 0
    Local _nTotal   := 0
    Local _nVlPortal:= 0
    Local _nTxPortal:= 0
    Local nRatePg   := 0
    Local nRateVl   := 0
    Local nValPg    := 0
    Private cAlias  := ""
    Private cAlias2 := ""
    Private cNumBlu := ""
    Private cProBlu := ""
    Private nNrItem := 0

    //lTpBaixa := GetMv('CP_BLUFIN4') 
    aRelImp  := MaFisRelImp("MT100",{"SF2","SD2"})

    If cOpcao = "1" //| 1= incluir cobrança na ZBL

        lRet:= zGetSc5(cNum)

        If lRet

            _nTxPortal :=  GetMv('CP_BLUTXPT')       

            (cAlias)->(DbGoTop())

            //| Tratativa para calcular o valor do pedido com impostos para enviar ao portal Blu.
            MaFisIni((cAlias)->CLIENTE,;		// 1-Codigo Cliente/Fornecedor
            (cAlias)->LOJA,;			        // 2-Loja do Cliente/Fornecedor
            If( (cAlias)->TIPO$'DB',"F","C"),;	// 3-C:Cliente , F:Fornecedor
            (cAlias)->TIPO,;				    // 4-Tipo da NF
            (cAlias)->TIPOCLI,;			        // 5-Tipo do Cliente/Fornecedor
            aRelImp,;							// 6-Relacao de Impostos que suportados no arquivo
            ,;						   			// 7-Tipo de complemento
            ,;									// 8-Permite Incluir Impostos no Rodape .T./.F.
            "SB1",;							    // 9-Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
            "MATA461")							// 10-Nome da rotina que esta utilizando a funcao

            If (cAlias)->DESCONT > 0
                MaFisAlt("NF_DESCONTO", Min(MaFisRet(, "NF_VALMERC")-0.01, (cAlias)->DESCONT+MaFisRet(, "NF_DESCONTO")) )
            EndIf

            _nValFret := (cAlias)->FRETE

            lRet:= zGetSC6(cNum)

            If lRet

                (cAlias2)->(DbGoTop())

                //| Enquanto houver itens
                While (cAlias2)->(!EoF()) 
                    
                    //| Adiciona o item nos tratamentos de impostos
                    SB1->(DbSeek(FWxFilial("SB1")+(cAlias2)->PRODUTO))
                    MaFisAdd((cAlias2)->PRODUTO,;                   // 01 - Codigo do Produto                    ( Obrigatorio )
                        (cAlias2)->TES,;                            // 02 - Codigo do TES                        ( Opcional )
                        (cAlias2)->QTDVEN,;                         // 03 - Quantidade                           ( Obrigatorio )
                        (cAlias2)->PRCVEN,;                         // 04 - Preco Unitario                       ( Obrigatorio )
                        (cAlias2)->VALDESC,;                        // 05 - Desconto
                        (cAlias2)->NFORI,;                          // 06 - Numero da NF Original                ( Devolucao/Benef )
                        (cAlias2)->SERIORI,;                        // 07 - Serie da NF Original                 ( Devolucao/Benef )
                        0,;                                         // 08 - RecNo da NF Original no arq SD1/SD2
                        IIF(_nValFret > 0, _nValFret/nNrItem,0),;   // 09 - Valor do Frete do Item               ( Opcional )
                        0,;                                         // 10 - Valor da Despesa do item             ( Opcional )
                        0,;                                         // 11 - Valor do Seguro do item              ( Opcional )
                        0,;                                         // 12 - Valor do Frete Autonomo              ( Opcional )
                        (cAlias2)->VALOR,;                          // 13 - Valor da Mercadoria                  ( Obrigatorio )
                        0,;                                         // 14 - Valor da Embalagem                   ( Opcional )
                        SB1->(RecNo()),;                            // 15 - RecNo do SB1
                        0)                                          // 16 - RecNo do SF4
                            
                    (cAlias2)->(DbSkip())

                EndDo

                //(cAlias2)->(DbCloseArea())
            
                _nTotal   := MaFisRet(,'NF_TOTAL')  //| Pegando total
            
                MaFisEnd()

                _nTVlPortal := _nTotal / (1 - _nTxPortal/100)  //Add a taxa de desconto ao valor total do pedido.
            
                cLog := "Pedido - " + cNum + " | "+ DTOC(date())+ " - "+time()+ CRLF
            
                DbSelectArea("ZBL")

                Begin Transaction

                    RecLock("ZBL",.T.)

                        ZBL->ZBL_FILIAL := xFilial("ZBL")
                        ZBL->ZBL_NUMBLU := cNumBlu
                        ZBL->ZBL_VALOR  := _nTotal
                        ZBL->ZBL_VLPORT := _nTVlPortal
                        ZBL->ZBL_CODCLI := (cAlias)->CLIENTE
                        ZBL->ZBL_LOJA   := (cAlias)->LOJA
                        ZBL->ZBL_NOME   := (cAlias)->NOME
                        ZBL->ZBL_INTEGR := ' '  //status  = aguardando integração
                        ZBL->ZBL_DATA   := Date()
                        ZBL->ZBL_USER   := Alltrim(Substr(cUsername,1,20))
                        ZBL->ZBL_LOGORI := cLog
                        ZBL->ZBL_CGC    := Alltrim((cAlias)->CNPJ)
                        ZBL->ZBL_BAIXAT := "N" 
                        ZBL->ZBL_ORIGEM := 'SC5'
                        ZBL->ZBL_PEDIDO := cNum    
                        ZBL->ZBL_DEVSAL := (cAlias)->DEVSAL                    

                    ZBL->(MsunLock())

                    SC5->(DbSeek(FWxFilial('SC5') + cNum))

                    RecLock("SC5",.F.)
                        SC5->C5_XNUMBLU := cNumBlu
                    SC5->(MsunLock())

                    DbSelectArea((cAlias2))
                    (cAlias2)->(DbGoTop())

                    DbSelectArea("SC9")
                    DbSetOrder(2)
                    
                    While (cAlias2)->(!EoF()) 

                        If SC9->(DbSeek((cAlias2)->FILIAL+(cAlias2)->CLIENTE+(cAlias2)->LOJA +(cAlias2)->PEDIDO+(cAlias2)->ITEM))

                            RecLock("SC9",.F.) 
                                SC9->C9_XNUMBLU := cNumBlu
                            MsUnlock()

                        EndIf	
                        (cAlias2)->(DbSkip())

                    EndDo
                
                End Transaction

                (cAlias2)->(DbCloseArea())

                (cAlias)->(DbCloseArea())

               MsgInfo("Cobrança BLU nº "+cNumBlu+ ", gerada com sucesso. Aguarde integração automática ao Portal BLU.", "Pedido - "+cNum)

            EndIf

        EndIf

    elseIf cOpcao = "2" //| 2= incluir fatura na ZBL

        lRet:= zGetSf2(cNum,cSerie,_cFil)

        If lRet            
            
            (cAlias)->(DbGoTop())

            While (cAlias)->(!EoF())

                //Pega o numero BLU
                cNumBlu := GetMv('CP_BLUNUM')  
                cProBlu := Soma1(cNumBlu)
            
                //Altera para prox. numero de BLU no parametro
                SX6->(Dbseek(xFilial()+"CP_BLUNUM"))
                SX6->(RecLock("SX6",.F.))
                    SX6->X6_CONTEUDO := cProBlu //Conteudo em Portugues
                    SX6->X6_CONTENG  := cProBlu //Conteudo em Ingles
                    SX6->X6_CONTSPA  := cProBlu //Conteudo em Espanhol
                SX6->(MsUnlock())

                DbSelectArea("ZBL")
                ZBL->(DbSeek((cAlias)->FILIAL+(cAlias)->NUMBLU))
                
                nRatePg    := ZBL->ZBL_RATEPG
                nRateVl    := ZBL->ZBL_RATEVL
                nValPg     := ZBL->ZBL_VALPG
                cTipoPG    := ZBL->ZBL_TIPOPG
                _nVlPortal := ZBL->ZBL_VLPORT
                cDevSal    := ZBL->ZBL_DEVSAL

                _nTotal    := (cAlias)->TOTAL //- (((cAlias)->TOTAL * nRatePg) / 100 )

                cLog := "NF " +  (cAlias)->DOC + " / "+ (cAlias)->SERIE + " | "+ DTOC(date())+ " - "+time()+ CRLF 

                Begin Transaction

                    RecLock("ZBL",.T.)

                        ZBL->ZBL_FILIAL := (cAlias)->FILIAL
                        ZBL->ZBL_NUMBLU := cNumBlu
                        ZBL->ZBL_VALOR  := _nTotal
                        ZBL->ZBL_VLPORT := _nVlPortal
                        ZBL->ZBL_CODCLI := (cAlias)->CLIENTE
                        ZBL->ZBL_LOJA   := (cAlias)->LOJA
                        ZBL->ZBL_NOME   := (cAlias)->NOME
                        ZBL->ZBL_INTEGR := ' '  //status  = aguardando integração
                        ZBL->ZBL_DATA   := Date()
                        ZBL->ZBL_USER   := Alltrim(Substr(cUsername,1,20))
                        ZBL->ZBL_LOGORI := cLog
                        ZBL->ZBL_CGC    := Alltrim((cAlias)->CNPJ)
                        ZBL->ZBL_BLUID  := (cAlias)->IDBLU
                        ZBL->ZBL_BAIXAT := "N"
                        ZBL->ZBL_ORIGEM := 'SF2'
                        ZBL->ZBL_PEDIDO := (cAlias)->PEDIDO
                        ZBL->ZBL_TIPFAT := 'NF'
                        ZBL->ZBL_DOC    := (cAlias)->DOC
                        ZBL->ZBL_SERIE  := (cAlias)->SERIE
                        ZBL->ZBL_VALFAT := (cAlias)->TOTAL
                        ZBL->ZBL_DTFAT  := STOD((cAlias)->EMISSAO)
                        ZBL->ZBL_RATEPG := nRatePg
                        ZBL->ZBL_TIPOPG := cTipoPG
                        ZBL->ZBL_RATEVL := nRateVl
                        ZBL->ZBL_VALPG  := nValPg
                        ZBL->ZBL_DEVSAL := cDevSal
                        
                    ZBL->(MsunLock())
                    
                    //| gravo informações na SF2
                    DbSelectArea("SF2")
                    SF2->(DbSeek((cAlias)->FILIAL+(cAlias)->DOC+(cAlias)->SERIE+(cAlias)->CLIENTE+(cAlias)->LOJA))

                    RecLock("SF2",.F.)

                        SF2->F2_XNUMBLU :=  cNumBlu
                        SF2->F2_XIDBLU 	:=  (cAlias)->IDBLU

                    SF2->(MsunLock())
                    
                    //| gravo informações na SE1
                    DbSelectArea("SE1")
                    DbSetOrder(2)

                    SE1->(DbSeek((cAlias)->FILIAL+(cAlias)->CLIENTE+(cAlias)->LOJA+(cAlias)->SERIE+(cAlias)->DOC))

                        While !EOF() .and. SE1->E1_CLIENTE+SE1->E1_LOJA+SE1->E1_PREFIXO+SE1->E1_NUM == ;
                                        (cAlias)->CLIENTE+(cAlias)->LOJA+(cAlias)->SERIE+(cAlias)->DOC

                            RecLock("SE1",.F.)

                                SE1->E1_XNUMBLU :=  cNumBlu
                                SE1->E1_XIDBLU 	:=  (cAlias)->IDBLU

                            SE1->(MsunLock())

                            SE1->(dbskip())

                        EndDo

                End Transaction

                (cAlias)->(dbskip())
            
            EndDo

            (cAlias)->(DbCloseArea())

        EndIf

    EndIf 

    RestArea(aAreaX6)
    RestArea(aArea)
         
Return

/*/{Protheus.doc} zGetSC5
description
@type function
@version 
@author Cyberpolos
@since 24/07/2020
@param cNumPed, character, numero do pedido de venda
@return return_type, logico, retorna se conseguiu informações para add a ZBL
/*/
Static Function zGetSC5(cNumPed)

    Local aAreaX6 := SX6->(GetArea())
    Local cQuery  := ""
    Local lRet    := .F.
    Local _nTotal  := 0
    
    cAlias    := GetNextAlias()
    
    cQuery+=" SELECT " 
    cQuery+=" C5_FILIAL AS FILIAL," 
    cQuery+=" C5_CLIENTE AS CLIENTE," 
    cQuery+=" C5_LOJACLI AS LOJA," 
    cQuery+=" C5_TIPO AS TIPO," 
    cQuery+=" C5_TIPOCLI AS TIPOCLI," 
    cQuery+=" C5_DESCONT AS DESCONT," 
    cQuery+=" C5_FRETE AS FRETE," 
    cQuery+=" A1_NREDUZ AS NOME,"
    cQuery+=" A1_CGC AS CNPJ,"
    cQuery+=" A1_XDEVSAL AS DEVSAL"
    cQuery+=" FROM" 
    cQuery+="	"+Retsqlname("SC5") + " A (NOLOCK)"
    cQuery+=" INNER JOIN "+Retsqlname("SA1") + " B (NOLOCK) ON B.A1_COD = A.C5_CLIENTE AND B.A1_LOJA = A.C5_LOJACLI AND B.D_E_L_E_T_ = ' ' "
    cQuery+=" WHERE" 
    cQuery+="	A.D_E_L_E_T_ = ' ' " 
    cQuery+="	AND A.C5_FILIAL = '"+  xFilial("SC5") + "'"
    cQuery+="	AND A.C5_NUM = '"+  cNumPed + "'"
    
    TCQuery cQuery NEW ALIAS (cAlias)

    count To _nTotal

    If _nTotal = 0

        (cAlias)->(DbCloseArea())
           MsgInfo("Não há registros para incluir", "Atenção")   
        lRet := .F.
    
    else
        
        lRet := .T.

        //Pega o numero BLU
        cNumBlu := GetMv('CP_BLUNUM')  
        cProBlu := Soma1(cNumBlu)
    
        //Altera para prox. numero de BLU no parametro
        SX6->(Dbseek(xFilial()+"CP_BLUNUM"))
        SX6->(RecLock("SX6",.F.))
            SX6->X6_CONTEUDO := cProBlu //Conteudo em Portugues
            SX6->X6_CONTENG  := cProBlu //Conteudo em Ingles
            SX6->X6_CONTSPA  := cProBlu //Conteudo em Espanhol
        SX6->(MsUnlock())

    EndIf

    RestArea(aAreaX6)

Return lRet

/*/{Protheus.doc} zGetSF2
description
@type function
@version 
@author ataki
@since 7/24/2020
@param cNumDoc, character, param_description
@param cSerie, character, param_description
@return return_type, return_description
/*/
Static Function zGetSF2(cNumDoc,cSerie,_cFil)
    
    Local cQuery  := ""
    Local lRet    := .F.
    Local _nTotal  := 0
    
    cAlias    := GetNextAlias()
    
    cQuery+=" SELECT " 
    cQuery+=" F2_FILIAL AS FILIAL," 
    cQuery+=" F2_DOC AS DOC," 
    cQuery+=" F2_SERIE AS SERIE," 
    cQuery+=" F2_CLIENTE AS CLIENTE," 
    cQuery+=" F2_LOJA AS LOJA," 
    cQuery+=" F2_EMISSAO AS EMISSAO," 
    cQuery+=" sum(D2_VALBRUT) AS TOTAL," 
    cQuery+=" F2_TIPO AS TIPO," 
    cQuery+=" F2_TIPOCLI AS TIPOCLI," 
    cQuery+=" A1_NREDUZ AS NOME,"
    cQuery+=" A1_CGC AS CNPJ,"
    cQuery+=" D2_PEDIDO AS PEDIDO,"
    cQuery+=" C5_XNUMBLU AS NUMBLU,"
    cQuery+=" C5_XIDBLU AS IDBLU"
    cQuery+=" FROM" 
    cQuery+="	"+Retsqlname("SF2") + " A (NOLOCK)"
    cQuery+=" INNER JOIN "+Retsqlname("SA1") + " B (NOLOCK) ON B.A1_COD = A.F2_CLIENTE AND B.A1_LOJA = A.F2_LOJA AND B.D_E_L_E_T_ = ' ' "
    cQuery+=" INNER JOIN "+Retsqlname("SD2") + " C (NOLOCK) ON C.D2_FILIAL = A.F2_FILIAL AND C.D2_DOC = A.F2_DOC AND C.D2_SERIE = A.F2_SERIE AND C.D_E_L_E_T_ = ' ' "
    cQuery+=" INNER JOIN "+Retsqlname("SC5") + " D (NOLOCK) ON D.C5_FILIAL = C.D2_FILIAL AND D.C5_NUM = C.D2_PEDIDO AND D.D_E_L_E_T_ = ' ' "
    cQuery+=" WHERE" 
    cQuery+="	A.D_E_L_E_T_ = ' ' " 
    cQuery+="	AND A.F2_FILIAL = '"+ _cFil + "'"
    cQuery+="	AND A.F2_DOC = '"+  cNumDoc + "'"
    cQuery+="	AND A.F2_SERIE = '"+  cSerie + "'"
    cQuery+=" group by F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA,F2_EMISSAO,F2_TIPO,F2_TIPOCLI,A1_NREDUZ,A1_CGC,D2_PEDIDO,C5_XNUMBLU,C5_XIDBLU "
    
    TCQuery cQuery NEW ALIAS (cAlias)

    count To _nTotal

    If _nTotal = 0

        (cAlias)->(DbCloseArea())
           MsgInfo("Não há registros para incluir", "Atenção")   
        lRet := .F.
    
    else
        
       lRet := .T.

    EndIf    

Return lRet

Static Function zGetSC6(cNumPed)

    Local cQuery  := ""
    Local lSemBlq := GetMv("CP_BLUCEST")
    Local lRet    := .F.
    Local _nTotal  := 0

    cAlias2    := GetNextAlias()

    cQuery+=" SELECT " 
    cQuery+=" C6_PRODUTO AS PRODUTO," 
    cQuery+=" C6_NUM AS PEDIDO," 
    cQuery+=" C6_FILIAL AS FILIAL," 
    cQuery+=" C6_TES AS TES," 
    cQuery+=" C6_QTDVEN AS QTDVEN," 
    cQuery+=" C6_PRCVEN AS PRCVEN," 
    cQuery+=" C6_VALDESC AS VALDESC," 
    cQuery+=" C6_NFORI AS NFORI," 
    cQuery+=" C6_SERIORI AS SERIORI," 
    cQuery+=" C6_VALOR AS VALOR, " 
    cQuery+=" C6_CLI AS CLIENTE, " 
    cQuery+=" C6_LOJA AS LOJA, " 
    cQuery+=" C6_NUM AS NUM, " 
    cQuery+=" C6_ITEM AS ITEM " 
    cQuery+=" FROM" 
    cQuery+="	"+Retsqlname("SC6") + " A (NOLOCK)"

    If lSemBlq
        cQuery+=" INNER JOIN "+Retsqlname("SC9") + " B (NOLOCK) ON B.C9_FILIAL = A.C6_FILIAL AND B.C9_PEDIDO = A.C6_NUM "
        cQuery+=" AND B.C9_ITEM = A.C6_ITEM AND B.C9_CLIENTE = A.C6_CLI AND B.C9_LOJA = A.C6_LOJA AND B.D_E_L_E_T_ = ' ' "
        cQuery+=" AND B.C9_BLEST <> '02' "
    EndIf

    cQuery+=" WHERE" 
    cQuery+="	A.D_E_L_E_T_ = ' ' " 
    cQuery+="	AND A.C6_FILIAL = '"+  xFilial("SC6") + "'"
    cQuery+="	AND A.C6_NUM = '"+  cNumPed + "'"

    TCQuery cQuery NEW ALIAS (cAlias2)

    count To _nTotal

    If _nTotal = 0

        (cAlias2)->(DbCloseArea())
           MsgInfo("Não localizados itens para integração Blu.", "Atenção")   
        lRet := .F.
    
    Else
         
         nNrItem := _nTotal
         lRet := .T.

    EndIf

Return lRet
