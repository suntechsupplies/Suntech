#include 'protheus.ch'
#include 'parmtype.ch'
#include 'totvs.ch'
#include 'restful.ch'
#Include 'tbiconn.ch'
#Include 'topconn.ch'  

/*/{Protheus.doc} BluFat2
	Rotina para verificar status de uma cobrança no portal BLU. A verIficação deve ocorrer quando o campo ZBL_STATUS estiver igual a '1','2','6','7' e '8'
    e o campo ZBL_BLUID não pode estar vazio.   
    @type Function
    @version 2.0
    @author Cyberpolos
    @since 2/7/2020
    	
	Status de cobrança Blu : https://integracao.useblu.com.br/sobre-apis
	
	statusCode status message
    1 - Aguardando aprovação
    2 - Aprovado, aguardando o valor total para pagamento automático
    3 - Pagamento realizado
    4 - Pagamento cancelado
    5 - Pagamento rejeitado
    6 - Agendamento aprovado para o dia AAAA-MM-DD
    7 - Em processamento
    8 - Pagamento aguardando faturamento ou cancelamento de nota
/*/
User Function BluFat2(_aEmp) 

    Local _cFil     := ""
	Local aHeader   := {}
    Local cAmbProd  := ""
	Local cFatura   := ""
	Local cBluRef   := ""
	Local cIdBlu    := ""
    Local _cEnv 	:= ""
	Local cIntegra  := ""
	Local cJSON     := ""
	Local cInvoice  := ""
    Local cKindPg   := ""
	Local cMailSt   := ""
	Local cMsgBlu   := ""
	Local cMsgInt   := ""
	Local cMsgLog   := ""
	Local cNumBlu   := ""
	Local cPath     := ""
	Local cPathId   := ""
	Local cStaNew   := ""
	Local cStatus   := ""
	Local cToken    := ""
	Local cTpMail   := ""
	Local cUrl      := ""
	Local cUuIdPg   := ""
	Local cUuIdFat  := ""
	Local dDtPag    := Nil
	local lAltDesc  := .F.
	local lRet      := .F.
	Local lUseBlu   := .F.
    Local nIdPaga   := 0
	Local nIdParc   := 0
    Local nRatePg   := 0
    Local nRateVl   := 0
    Local nValPg    := 0
    Local nRatePgBl := 0
    Local nRateVlBl := 0
    Local nValPgBl  := 0
	Local nX        := 0
	Local oChanger  := Nil
	Local oJson     := Nil
    Private cAlias  := ""
	Private cAlias2 := ""
	Private cLog    := "|" + Replicate( '-' ,62) +"|"+ CRLF
    Private lSchedule := .F.

     // Inicializa ambiente pelo schedule
	If Select("SX6") == 0
		RPCSetType(3)  		//| Nao utilizar licenca	
		RpcSetEnv(_aEmp[1] ,_aEmp[2])
		lSchedule := .T.		
	Endif    
	//+-------------------------------------------------------
	// tratamento para nao haver execucao concorrente
	//+-------------------------------------------------------
	if !(LockByName('BluFat2', .T., .F.))
        ConOut("BluFat2 ja esta em execucao")
        if lSchedule
            RpcClearEnv()
        Endif
        Return
	Endif 

    lUseBlu  :=  GetMv('CP_BLUUSE')   // Parametro para verificar se as rotina BLU está ativa
    lAltDesc :=  GetMv('CP_BLUADES')  // Se altera o desconto conforme autorização selecionada no portal

    If lUseBlu  //|Se rotinas API BLU estiver ativada

        cLog+= "[BluFat2] | INICIO: " +DTOC(date())+ " - "+time() +"|" + CRLF

        lRet :=  zGetZBL() //| busca as integrações para verificar status

        If lRet //|se houver integrações para se verificar o status

            _cEnv 	:= AllTrim(Upper(GetEnvServer())) //Ambiente em execução
            cAmbProd := AllTrim(Upper(GetMv('CP_BLUPROD')))  //Nome do ambiente de produção

            cToken  := "Bearer "+ GetMv('CP_BLUTOKE') //| Token de integração
            cUrl     := IIf(_cEnv $(cAmbProd),GetMv('CP_BLUURL1'),GetMv('CP_BLUURL0')) // Url Principal da API BLU | define se é homologação ou produção
            cPathId :=  GetMv('CP_BLUURL3')           //| Parte da URL de GET de consulta de cobrança da API BLU
                
            (cAlias)->(DbGotop())   

            While (cAlias)->(!Eof()) 

                _cFil := (cAlias)->FILIAL
                cNumBlu := (cAlias)->NUMBLU
                cUuId   := Alltrim((cAlias)->BLUID)
                cStatus := Alltrim((cAlias)->STATUS)
                nIdPaga := (cAlias)->IDPAGA
                cFatura := Alltrim((cAlias)->DOC) + Alltrim((cAlias)->SERIE)
                
                //| Header para validar acesso ao portal  
                aHeader := {}  //limpo o array        
                Aadd(aHeader,"uuid:"+cUuId)
                Aadd(aHeader,"Authorization:"+ cToken)
                
                cPath := StrTran(cPathId,'{uuid}',cUuId)  //| add o uuid na URL de consulta

                oRest := FwRest():New(cUrl)               //| acesso ao portal
                oRest:setPath(cPath)                      //| parte de envio de cobrança no portal
                
                If oRest:Get(aHeader)               	  //| validações para conclusão do envio	                
                    
                    cJson := DecodeUTF8(oRest:GetResult(), "cp1252")   //| recebe resposta do Get contendo dados para o Json

                    //| Objeto Json   
                    oJson := JsonObject():new() 
                    oJson:fromJson(cJson)  
                    
                    cIdBlu  := Alltrim(oJson:GetJsonText("uuid"))
                    cStaNew := Alltrim(oJson:GetJsonText("status_code"))
                    cMsgInt := Alltrim(oJson:GetJsonText("status"))
                    cMsgBlu := Alltrim(oJson:GetJsonText("message"))
                    
                    //Tratativa para o tipo de pagamento utilizado
                    cKindPg := IIf(Alltrim(oJson:GetJsonText("kind")) = "payment_collection_on_time_by_charger","1",;  //1=A Vista
                               IIF(Alltrim(oJson:GetJsonText("kind")) = "payment_collection_optimized","2",;           //2=Antecipação Zero
                               IIF(Alltrim(oJson:GetJsonText("kind")) = "payment_collection_blu_billet","3","" )))     //3=Boleto Blu


                    
                    //Tratativa para pegar % de pagamento feito por parte da Blu
                    If Alltrim(oJson:GetJsonText("charger_increase_or_discount_rate")) <> "null" .And. ;
                       Alltrim(oJson:GetJsonText("charger_increase_or_discount")) <> "null"
                                                
                        nRatePgBl := IIf(Val(oJson:GetJsonText("charger_increase_or_discount_rate")) < 0,;
                                       Val(oJson:GetJsonText("charger_increase_or_discount_rate")) * -1,;
                                       Val(oJson:GetJsonText("charger_increase_or_discount_rate")))
                        nRateVlBl := IIf(Val(oJson:GetJsonText("charger_increase_or_discount")) < 0,;
                                       Val(oJson:GetJsonText("charger_increase_or_discount")) * -1,;
                                       Val(oJson:GetJsonText("charger_increase_or_discount")))
                        nValPgBl  := Val(oJson:GetJsonText("charger_value"))

                    EndIf      
                    
                    //Tratativa para pegar % de pagamento
                    If Alltrim(oJson:GetJsonText("increase_or_discount_rate")) <> "null" .And. ;
                       Alltrim(oJson:GetJsonText("increase_or_discount")) <> "null"
                                                
                        nRatePg := IIf(Val(oJson:GetJsonText("increase_or_discount_rate")) < 0,;
                                       Val(oJson:GetJsonText("increase_or_discount_rate")) * -1,;
                                       Val(oJson:GetJsonText("increase_or_discount_rate")))
                        nRateVl := IIf(Val(oJson:GetJsonText("increase_or_discount")) < 0,;
                                       Val(oJson:GetJsonText("increase_or_discount")) * -1,;
                                       Val(oJson:GetJsonText("increase_or_discount")))
                        nValPg  := Val(oJson:GetJsonText("value"))

                    EndIf                   

                    oChanger := oJson:GetJsonObject('installments_of_charger')

                    If !Empty(oChanger)

                        For nX:= 1 To len(oChanger)

                           cInvoice:= oChanger[nX]['payment_plan_invoice_number']

                            If  cInvoice == cFatura

                                nIdParc := oChanger[nX]['id']
                                cUuIdFat:= oChanger[nX]['uuid']
                                dDtPag  := STOD(StrTran(oChanger[nX]['released_at'],'-',''))
                                cBluRef := oChanger[nX]['payment_collection_reference'] 
                                cUuIdPg := oChanger[nX]['payment_plan_uuid']                                                              

                                nX:= len(oChanger)

                            EndIf

                        Next nX

                    EndIf

                    DbSelectArea("ZBL")
                    DbSetOrder(1)

                    If DbSeek(_cFil+cNumBlu)     

                        //| Se for Fatura e não consta Id junto a cobrança, significa que houve algum erro na integração
                        //e como e utilizado o mesmo bluid para consulta, não deixo gravar o status da cobrança, mantenho 
                        //o status de erro na integração da fatura.
                        If ZBL->ZBL_ORIGEM $("SF2") .And. nIdParc = 0

                          cStaNew :=  cStatus 
                          cMsgBlu := ZBL->ZBL_MSGBLU

                        EndIf             
                   
                        If cStatus <> cStaNew 

                            cIntegra := IIf(cStaNew $('3|8'),'3',cStaNew)                        

                            cMsgLog := alltrim(ZBL_LOGORI) + CRLF 
                            cMsgLog += cStaNew + ' - '+ cMsgInt + ' | '+DTOC(date())+ " - "+time()

                            cTpMail := ""
                            cMailSt := ""
                            
                            If  cStaNew $('3|8') //| Tratativa para determinar o tipo de email que sera enviado.

                                cTpMail := IIf(ZBL->ZBL_ORIGEM $('SC5|SE1') .and. ZBL->ZBL_TPMAIL <> '2','2',ZBL->ZBL_TPMAIL)
                                cMailSt := IIf(ZBL->ZBL_TPMAIL <> cTpMail,'N',ZBL->ZBL_MAILST)
                            
                            ElseIf cStaNew $('4|5|9')

                                cTpMail := IIf(ZBL->ZBL_ORIGEM $('SC5|SE1') .and. cStaNew $('4|9'),'4',;
                                           IIf(ZBL->ZBL_ORIGEM $('SC5|SE1') .and. cStaNew = '5','5',ZBL->ZBL_TPMAIL))
                            
                                cMailSt := IIf(ZBL->ZBL_TPMAIL <> cTpMail,'N',ZBL->ZBL_MAILST)
                                
                                If ZBL->ZBL_ORIGEM == 'SE1'   //| como não foi aprovado, libero o titulo para ficar disponivel para seleção.
                                    zGetSE1(ZBL->ZBL_CODCLI,ZBL->ZBL_LOJA,cNumBlu,cStaNew,_cFil)
                                EndIf

                            EndIf                        
                        
                            RecLock("ZBL",.F.)
                                
                                ZBL_INTEGR := cIntegra
                                ZBL_STATUS := cStaNew
                                ZBL_MSGINT := cMsgInt
                                ZBL_MSGBLU := cMsgBlu
                                ZBL_LOGORI := cMsgLog                            
                                ZBL_IDPAGA := nIdParc
                                ZBL_UUIDPG := cUuIdPg
                                ZBL_DTPAGA := dDtPag  
                                ZBL_BLURTP := nRatePgBl   
                                ZBL_BLURTV := nRateVlBl
                                ZBL_BLUPG  := nValPgBl
                                ZBL_RATEPG := nRatePg                            
                                ZBL_RATEVL := nRateVl                            
                                ZBL_VALPG  := nValPg                            
                                ZBL_TIPOPG := cKindPg                            
                                ZBL_TPMAIL := cTpMail
                                ZBL_MAILST := cMailSt                            
                                ZBL_BLUREF := cBluRef                            
                                ZBL_UUIDFT := cUuIdFat                            

                            ZBL->(MsunLock())

                        Else

                            RecLock("ZBL",.F.)

                                ZBL_MSGBLU := cMsgBlu
                            
                            ZBL->(MsunLock())

                        EndIf 

                        If cStaNew $('3|8')
                            
                            //Tratativa para alterar o valor do desconto do pedido, conforme o aprovado no portal
                            If ZBL->ZBL_ORIGEM == "SC5" .And. lAltDesc

                                DbSelectArea("SC5")
                                DbSetOrder(1)

                                If SC5->(DbSeek(ZBL->ZBL_FILIAL+ZBL->ZBL_PEDIDO)) 

                                    If ZBL->ZBL_RATEPG <> SC5->C5_DESC1 

                                      zAltDesc(ZBL->ZBL_FILIAL,ZBL->ZBL_PEDIDO,ZBL->ZBL_CODCLI,ZBL->ZBL_LOJA,ZBL->ZBL_RATEPG)

                                    EndIf

                                EndIf


                            EndIf

                            DbSelectArea("SC9")
                            DbSetOrder(2)

                            If SC9->(DbSeek(ZBL->ZBL_FILIAL+ZBL->ZBL_CODCLI+ZBL->ZBL_LOJA+ZBL->ZBL_PEDIDO))

                                While !EOF() .And. SC9->C9_CLIENTE+SC9->C9_LOJA+SC9->C9_PEDIDO == ;
                                                   ZBL->ZBL_CODCLI+ZBL->ZBL_LOJA+ZBL->ZBL_PEDIDO
                                     
                                    If SC9->C9_XNUMBLU == ZBL->ZBL_NUMBLU
                                    
                                        RecLock("SC9",.F.)
                                            SC9->C9_XBLULIB = "S"
                                        SC9->(MsunLock())

                                    EndIf

                                    SC9->(dbskip())

                                EndDo
                            
                            EndIf

                        EndIf
                        
                        If nIdPaga <> nIdParc

                            RecLock("ZBL",.F.)
                                                                                        
                                ZBL_IDPAGA := nIdParc
                                ZBL_UUIDPG := cUuIdPg
                                ZBL_DTPAGA := dDtPag    
                                ZBL_RATEPG := nRatePg                            
                                ZBL_RATEVL := nRateVl                            
                                ZBL_VALPG  := nValPg
                                ZBL_TIPOPG := cKindPg 
                                ZBL_BLUREF := cBluRef                            
                                ZBL_UUIDFT := cUuIdFat          

                            ZBL->(MsunLock())

                            If Alltrim(ZBL->ZBL_ORIGEM) == "SF2"

                                //| gravo informações na SF2
                                DbSelectArea("SF2")
                                If SF2->(DbSeek(ZBL->ZBL_FILIAL+ZBL->ZBL_DOC+ZBL->ZBL_SERIE+ZBL->ZBL_CODCLI+ZBL->ZBL_LOJA))

                                    RecLock("SF2",.F.)

                                        SF2->F2_XIDFAT	:=  nIdParc
                                        SF2->F2_XUUIDFT :=  cUuIdFat                                

                                    SF2->(MsunLock())
                                
                                EndIf
                           
                                //| gravo informações na SE1
                                DbSelectArea("SE1")
                                DbSetOrder(2)

                                If SE1->(DbSeek(ZBL->ZBL_FILIAL+ZBL->ZBL_CODCLI+ZBL->ZBL_LOJA+ZBL->ZBL_SERIE+ZBL->ZBL_DOC))

                                    While !EOF() .and. SE1->E1_CLIENTE+SE1->E1_LOJA+SE1->E1_PREFIXO+SE1->E1_NUM == ;
                                                    ZBL->ZBL_CODCLI+ZBL->ZBL_LOJA+ZBL->ZBL_SERIE+ZBL->ZBL_DOC

                                        RecLock("SE1",.F.)

                                            SE1->E1_XIDFAT	:=  nIdParc
                                            SE1->E1_XUUIDFT :=  cUuIdFat

                                        SE1->(MsunLock())

                                        SE1->(dbskip())

                                    EndDo

                                EndIf

                            ElseIf Alltrim(ZBL->ZBL_ORIGEM) == "SE1"

                                 zGetSE1(ZBL->ZBL_CODCLI,ZBL->ZBL_LOJA,cNumBlu,cStaNew,_cFil)

                            EndIf
                                    
                        EndIf
                    
                    EndIf

                    FreeObj(oJson)
                    
                Else
                    
                    //| Se não foi possivel enviar a cobrança, gravamos mensagem.
                    dBselectArea("ZBL")
                    dBsetOrder(1)

                    DbSeek(_cFil+cNumBlu)

                        RecLock("ZBL",.F.)
                                                                    
                            ZBL_MSGBLU :=  oRest:GetLastError()

                        ZBL->(MsunLock())

                EndIf
                
                cUuIdPg := ""
                cBluRef := ""
                cUuIdFat:= ""
                cStaNew := ""
                cMsgInt := ""
                cMsgBlu := ""
                nIdParc := 0
                nRatePg := 0
                nRateVl := 0
                nValPg  := 0
                
                (cAlias)->(dbSkip())

            EndDo 

        EndIf

        //u_BluMail(_aEmp) //| chamada para rotina de envio de e-mail
        
        cLog += "[BluFat2] | FIM: " +DTOC(date())+ " - "+time() + CRLF
        cLog += "|" + Replicate('-',62) +"|"+ CRLF
        conout(cLog)
    
    EndIf

    If lSchedule
        RpcClearEnv()
    Endif

Return

/*/{Protheus.doc} zGetZBL
select para pegar registros que devem ser integrados no portal BLU.
@type Static Function
@version 2.0
@author Cyberpolos
@since 06/07/2020
@Return lRet, retorna se há itens para integração.
/*/
Static Function zGetZBL() 

    Local cQuery := ""
    Local lRet   := .F.
    Local nTotal := 0
    
    cAlias    := GetNextAlias()
    
    cQuery+=" SELECT " 
    cQuery+=" ZBL_FILIAL AS FILIAL," 
    cQuery+=" ZBL_NUMBLU AS NUMBLU," 
    cQuery+=" ZBL_VALOR AS VALOR," 
    cQuery+=" ZBL_CODCLI AS CLIENTE," 
    cQuery+=" ZBL_LOJA AS LOJA,"
    cQuery+=" ZBL_STATUS AS STATUS,"
    cQuery+=" ZBL_ORIGEM AS ORIGEM,"
    cQuery+=" ZBL_BLUID AS BLUID,"
    cQuery+=" ZBL_IDPAGA AS IDPAGA,"
    cQuery+=" ZBL_DOC AS DOC,"
    cQuery+=" ZBL_SERIE AS SERIE"
    cQuery+=" FROM" 
    cQuery+="	"+Retsqlname("ZBL") + " A (NOLOCK)"
    cQuery+=" WHERE" 
    cQuery+="	A.D_E_L_E_T_ = ' ' " 
    cQuery+="	AND ZBL_STATUS NOT IN ('3','4','5','9') "  
    cQuery+="	AND ZBL_INTEGR <> ' ' "  
    cQuery+=" ORDER BY ZBL_NUMBLU"  

    TCQuery cQuery NEW ALIAS (cAlias)

    count To nTotal
    
    If nTotal = 0  //|Se não há registros, defino para não seguir
        (cAlias)->(DbCloseArea())

        cLog += "Não há integrações para ser verIficado o status." + CRLF
        lRet := .F.     
    
    Else //| senão habilitado a seguir
     
       cLog += "Localizado(s) "+cValToChar(nTotal) + " registro(s) para verificar status."+ CRLF
       lRet := .T.

    EndIf

Return lRet

/*/{Protheus.doc} zGetSE1
Usada para buscar titulos que devem ter o campo E1_XNUMBLU limpos, já que não foi aprovada a cobrança e assim liberando este para novo envio.
@type Static Function
@version 2.0
@author Cyberpolos
@since 24/07/2020
@param cCliente, character, codigo do clinte
@param cLoja, character, loja do cliente
@param cNumBlu, character, numero da cobrança Blu
@param cStatus, character, status da cobrança Blu
/*/
Static Function zGetSE1(cCliente,cLoja,cNumBlu,cStatus,_cFil)

    Local cQuery   := ""
    Local nTotal   := 0
    
    cAlias2    := GetNextAlias()
    
    cQuery+=" SELECT " 
    cQuery+=" E1_FILIAL AS FILIAL," 
    cQuery+=" E1_PREFIXO AS PREFIXO," 
    cQuery+=" E1_NUM AS NUM," 
    cQuery+=" E1_PARCELA AS PARCELA,"
    cQuery+=" E1_CLIENTE AS CLIENTE,"
    cQuery+=" E1_LOJA AS LOJA,"
    cQuery+=" E1_XNUMBLU AS NUMBLU,"
    cQuery+=" ZBL_BLUID  AS BLUID,"
    cQuery+=" ZBL_IDPAGA AS IDPAGA,"
    cQuery+=" ZBL_UUIDFT AS UUIDFT"
    cQuery+=" FROM" 
    cQuery+="	"+Retsqlname("SE1") + " A (NOLOCK)"
    cQuery+=" INNER JOIN "+Retsqlname("ZBL") + " B (NOLOCK) ON B.ZBL_NUMBLU = A.E1_XNUMBLU "
    cQuery+=" AND B.ZBL_FILIAL = A.E1_FILIAL AND B.ZBL_CODCLI = A.E1_CLIENTE "
    cQuery+=" AND B.ZBL_LOJA = A.E1_LOJA AND B.D_E_L_E_T_= ' ' " 
    cQuery+=" WHERE" 
    cQuery+="	A.D_E_L_E_T_ = ' ' " 
    cQuery+="	AND E1_XNUMBLU = '" +  cNumBlu + "'"
    cQuery+="	AND E1_CLIENTE = '" +  cCliente + "'"
    cQuery+="	AND E1_LOJA = '" +  cLoja + "'"
    cQuery+=" ORDER BY E1_NUM,E1_PARCELA"  

    TCQuery cQuery NEW ALIAS (cAlias2)

    count To nTotal
    
    If nTotal = 0
        (cAlias2)->(DbCloseArea())

        cLog += "[zGetSE1] - Não há integrações para ser verIficado o status." + CRLF
          
    Else 
           
        (cAlias2)->(DbGotop())

        If cStatus $('4|5')

            //| gravo informações na SE1
            dbSelectArea("SE1")
            DbSetOrder(2)

            SE1->(DbSeek(_cFil+(cAlias2)->CLIENTE+(cAlias2)->LOJA+(cAlias2)->PREFIXO+(cAlias2)->NUM+(cAlias2)->PARCELA))

                While !EOF() .and. SE1->E1_CLIENTE+SE1->E1_LOJA+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_XNUMBLU==;
                                (cAlias2)->CLIENTE+(cAlias2)->LOJA+(cAlias2)->PREFIXO+(cAlias2)->NUM+(cAlias2)->NUMBLU

                    RecLock("SE1",.F.)

                        SE1->E1_XNUMBLU := ' '
                        
                    SE1->(MsunLock())

                    SE1->(dbskip())

                EndDo
        
        Else

            //| gravo informações na SE1
            dbSelectArea("SE1")
            DbSetOrder(2)

            While  (cAlias2)->(!EOF())

               If SE1->(DbSeek(_cFil+(cAlias2)->CLIENTE+(cAlias2)->LOJA+(cAlias2)->PREFIXO+(cAlias2)->NUM+(cAlias2)->PARCELA))

                     RecLock("SE1",.F.)

                        SE1->E1_XIDBLU  := (cAlias2)->BLUID
                        SE1->E1_XIDFAT  := (cAlias2)->IDPAGA
                        SE1->E1_XUUIDFT := (cAlias2)->UUIDFT
                        
                    SE1->(MsunLock())

                   (cAlias2)->(dbskip())

               EndIf

            EndDo

        EndIf

        (cAlias2)->(DbCloseArea())

        cLog += "[zGetSE1] - Localizado(s) "+cValToChar(nTotal) + " registro(s) para verificar status."+ CRLF
    
    EndIf

Return 

Static Function zAltDesc(_cFil,_cPedido,_cCodCli,_cLoja,_nPDesc)

    Local lCont   := .F.
    Local nPrcVen := 0
    Local nValor  := 0

    DbSelectArea("SC5")
    DbSetOrder(1)

    If SC5->(DbSeek(_cFil+_cPedido)) 

        Begin Transaction

            RecLock("SC5",.F.)
                SC5->C5_DESC1 := _nPDesc
            SC5->(MsunLock())

            DbSelectArea("SC6")
            DbSetOrder(1)

            If SC6->(DbSeek(_cFil+_cPedido)) 

                While SC6->(!EOF()) .And. SC6->C6_NUM == _cPedido .And. SC6->C6_CLI == _cCodCli .And. SC6->C6_LOJA == _cLoja

                    nPrcVen := NoRound(SC6->C6_PRUNIT - ((SC6->C6_PRUNIT *_nPDesc)/100 ),2) 
                    nValor  := nPrcVen * SC6->C6_QTDVEN  

                    RecLock("SC6",.F.)

                        SC6->C6_PRCVEN := nPrcVen
                        SC6->C6_VALOR  := nValor

                    SC6->(MsunLock())

                    DbSelectArea("SC9")
                    DbSetOrder(2)

                    If SC9->(DbSeek(SC6->C6_FILIAL+SC6->C6_CLI+SC6->C6_LOJA+SC6->C6_NUM+SC6->C6_ITEM))

                        RecLock("SC9",.F.)
                            SC9->C9_PRCVEN := nPrcVen
                        SC9->(MsunLock())

                    EndIf

                    nPrcVen := 0
                    nValor  := 0
                    
                    SC6->(dbskip())

                EndDo

            Else
                    lCont := .F.
            EndIf

        End Transaction

    Else
        lCont := .F.
    EndIf

Return 
