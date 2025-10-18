#include 'protheus.ch'
#include 'parmtype.ch'
#include 'totvs.ch'
#include 'restful.ch'
#Include 'tbiconn.ch'
#Include 'topconn.ch'  

/*/{Protheus.doc} BluFat1
	@author Cyberpolos
	@since 29/06/2020
	@version 1.0  
	@obs Cliete BLU
	@description  Rotina utilizada para inserir cobrança no Portal da Blu.   
	@type Function
	
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
User Function BluFat1(_aEmp)

	Local aHeader   := {}
    Local cAmbProd  := ""
	Local cBoleto   := ""
	Local cCnpjCli  := ""
	Local cCnpjEmp  := ""
	Local cCond     := ""
	Local cDocFat   := ""
	Local cDtAgenda := ""
	Local cDtFat    := ""
    Local _cEnv 	:= ""
	Local cFatura   := ""
    Local _cFil     := ""
	Local cIdBlu    := ""
	Local cJSON     := ""
	Local cMsgBlu   := ""
	Local cMsgInt   := ""
	Local cMsgLog   := ""
	Local cNumBlu   := ""
	Local cNumFat   := ""
	Local cPath     := ""
	Local cStaFat   := ""
	Local cStatus   := ""
	Local cToken    := ""
	Local cUrl      := ""
    Local cValDev   := ""
	Local lRet      := .F.
	Local lRet2     := .F.
	Local lRet3     := .F.
	Local lDevSal   := .F.
	Local lUseBlu   := .T.
	Local nValFat   := 0
	Local nValor    := 0
    Local nX        := 0
    Local nY        := 0
    Local nZ        := 0
    Local nBluTaxa  := 0
    Local nValDesc  := 0
    Local nValTotal := 0
	Local oJson     := Nil
	Local oRest     := Nil
    Local lSchedule := .F.
	Private cAlias  := ""
	Private cAlias2 := ""
	Private cAlias3 := ""
	Private cLog    := "|" + Replicate('-',62) +"|"+ CRLF

    // Inicializa ambiente pelo schedule
	If Select("SX6") == 0
		RPCSetType(3)  		//| Nao utilizar licenca	
		RpcSetEnv(_aEmp[1] ,_aEmp[2])
		lSchedule := .T.		
	Endif    
	//+-------------------------------------------------------
	// tratamento para nao haver execucao concorrente
	//+-------------------------------------------------------
	if !(LockByName('BluFat1', .T., .F.))
        ConOut("BluFat1 ja esta em execucao")
        if lSchedule
            RpcClearEnv()
        Endif
        Return
	Endif    

    //Parametro para verIficar se as rotina BLU está ativa
    lUseBlu :=  GetMv('CP_BLUUSE')    
    lDevSal :=  GetMv('CP_BLUDEVP') //| Se devolve saldo em pedidos parciais.

    If lUseBlu  //Se rotinas API BLU estiver ativada    

        _cEnv 	:= AllTrim(Upper(GetEnvServer())) //Ambiente em execução
        cAmbProd := AllTrim(Upper(GetMv('CP_BLUPROD')))  //Nome do ambiente de produção

        cLog+= "[BluFat1] | INICIO: " +DTOC(date())+ " - "+time() +"|" + CRLF

        cToken   := "Bearer "+ GetMv( 'CP_BLUTOKE' ) // Token de integração
        cUrl     := IIf(_cEnv $(cAmbProd),GetMv('CP_BLUURL1'),GetMv('CP_BLUURL0')) // Url Principal da API BLU | define se é homologação ou produção
        cCnpjEmp := GetMv('CP_BLUCNPJ') //cnpj da empresa cadastrada junto a blu

        lRet :=  zGetZBL() // busca as integrações que seram processadas             
       
        If lRet  //|se houver registro para integrar pedido/cobrança
            
            cPath  :=  GetMv('CP_BLUURL2') //| Parte da URL de POST de inclusão de cobrança da API BLU
                    
            //Header para validar acesso ao portal           
            Aadd(aHeader,"Content-Type:application/json")
            Aadd(aHeader,"Authorization:"+ cToken)  

            (cAlias)->(DbGotop())        
            
            While (cAlias)->(!Eof())           

                _cFil  := (cAlias)->FILIAL
                cNumBlu  := (cAlias)->NUMBLU
                nValor   := (cAlias)->VLPORT                  
                //cCnpjCli := '90622223666' CNPJ //cnpj cliente teste
                cCnpjCli := (cAlias)->CNPJ //cnpj cliente 
                cFatura  := IIf(Alltrim((cAlias)->ORIGEM) == 'SC5', 'true', 'false')
                cBoleto  := 'false'
            
                //|informações da cobrança
                cJson:= '' 
                cJson+= '{'
                cJson+='"blu_billet_days":" ",' 
                cJson+='"blu_billet":' + cBoleto + "," 
                cJson+='"representative_cpf_cnpj":"' + cCnpjEmp + '",' 
                cJson+='"document_number":"' + cNumBlu + '",' 
                cJson+='"charged":"' + cCnpjCli + '",'
                cJson+='"value":"'+ cValToChar(nValor)+ '",' 
                cJson+='"scheduled_at":"",'
                cJson+='"billing_later":' + cFatura 
                cJson+= '}'

                For nX := 1 To 5 //Caso não consiga obter resposta tenta 5 vezes com intervalo de 2 seg

                    oRest := FwRest():New(cUrl)      //|acesso ao portal
                    oRest:setPath(cPath)             //|parte de envio de cobrança no portal
                    oRest:SetPostParams(cJson)       //|parametros com a cobrança 

                    If oRest:Post(aHeader)	         //|validações para conclusão do envio	 
            
                        cJson := DecodeUTF8(oRest:GetResult(), "cp1252")    //| recebe o resultado do Post
                    
                        //Objeto Json 
                        oJson := JsonObject():new()   
                        oJson:fromJson(cJson)  
                        
                        cIdBlu	    := Alltrim(oJson:GetJsonText("uuid"))
                        cStatus     := Alltrim(oJson:GetJsonText("status_code"))
                        cMsgInt     := Alltrim(oJson:GetJsonText("status"))   
                        cMsgBlu     := Alltrim(oJson:GetJsonText("message"))    

                        FreeObj(oJson)
                        
                        DbSelectArea("ZBL")
                        DbSetOrder(1)

                        //|Se tiver um retorno de status valido e o codigo BluId "uuid"
                        If cStatus $('1|2|3|4|5|6|7|8') .and. !empty(cIdBlu)
                    
                            DbSeek(_cFil+cNumBlu)

                            cMsgLog := alltrim(ZBL_LOGORI) + CRLF 
                            cMsgLog += replicate('- ',60) + CRLF 
                            cMsgLog += 'Status integração Portal BLU ' + CRLF + CRLF 
                            cMsgLog += cStatus + ' - '+ cMsgInt + ' | '+DTOC(date())+ " - "+time()

                            RecLock("ZBL",.F.)

                                ZBL_INTEGR := '1'
                                ZBL_TPMAIL := '1'
                                ZBL_MAILST := 'N'
                                ZBL_BLUID  := cIdBlu
                                ZBL_STATUS := cStatus
                                ZBL_MSGINT := cMsgInt
                                ZBL_MSGBLU := cMsgBlu
                                ZBL_LOGORI := cMsgLog

                            ZBL->(MsunLock())

                            If ZBL->ZBL_ORIGEM <> "SE1"

                                DbSelectArea("SC5")
                                SC5->(DbSeek(_cFil + (cAlias)->PEDIDO))

                                RecLock("SC5",.F.)

                                    SC5->C5_XIDBLU := cIdBlu

                                SC5->(MsunLock())

                            EndIf


                        Else  //|senão houve erro na integração, gravamos a mensagem

                            DbSeek(_cFil+cNumBlu)

                            RecLock("ZBL",.F.)

                                ZBL_INTEGR := '0'
                                ZBL_TPMAIL := '0'
                                ZBL_MAILST := 'N'
                                ZBL_MSGINT := 'ERRO NO PROCESSO DE INTEGRAÇÃO'                                            
                                ZBL_MSGBLU := cMsgBlu

                            ZBL->(MsunLock())
                            
                        EndIf
                        
                        nX := 5  //para sair do For já que houve reposta do Post
                        FreeObj(oJson)
                        
                    Else

                        //| Se não foi possivel enviar a cobrança, gravamos mensagem.
                        DbSelectArea("ZBL")
                        DbSetOrder(1)

                        DbSeek(_cFil+cNumBlu)

                            RecLock("ZBL",.F.)

                                ZBL_INTEGR := ' '
                               // ZBL_TPMAIL := '0'
                               // ZBL_MAILST := 'N'
                                ZBL_MSGINT := 'ERRO NO ENVIO DA INTEGRAÇÃO'                                            
                                ZBL_MSGBLU := oRest:GetLastError()

                            ZBL->(MsunLock())

                        Sleep(2000) //Aguardo 2 segundos para tentar novo Post
                                                        
                    EndIf

                Next nX 
            
                (cAlias)->(DbSkip())

            EndDo

            (cAlias)->(DbCloseArea())
            
        EndIf
        
        lRet2 := zGet2ZBL() //|Verifica se há Faturamento para ser integrado
        
        If lRet2 //| Se houver integrações de Faturamento há serem realizados.
            
            cPathId   :=  GetMv('CP_BLUURL4') //| Parte da URL de POST de envio de FATURAMENTO na API BLU
            nBluTaxa  :=  GetMV('CP_BLUTAXA') //| % da taxa blu
            nValDesc  :=  GetMV('CP_BLUTXPT') //| % do desconto dado no pedido.
            (cAlias2)->(DbGotop())   

            While (cAlias2)->(!Eof()) 
                
                _cFil := (cAlias2)->FILIAL
                cNumBlu := (cAlias2)->NUMBLU
                cUuId   := Alltrim((cAlias2)->BLUID)
                cNumFat := Alltrim((cAlias2)->DOC) + Alltrim((cAlias2)->SERIE)                
                cDtFat  := Dtos(date()) //(cAlias2)->DTFAT

                If (cAlias2)->TIPOPG <> '1'
                    nValTotal := Round((cAlias2)->VALOR / (1-nValDesc/100),2)
                    //nValFat := Round((cAlias2)->VALOR - ((cAlias2)->VALOR * nBluTaxa /100),2)     
                    nValFat := Round(nValTotal - (nValTotal* (nBluTaxa+nValDesc) /100),2)  
                Else
                    nValFat := (cAlias2)->VALOR
                EndIf                

                //Header para validar acesso ao portal  
                aHeader := {}  //limpo o array        
                Aadd(aHeader,"Authorization:"+ cToken)           

                //informações da cobrança
                cJson:= '' 
                cJson+= '{'
                cJson+='"payment_plans": {' 
                cJson+='"type": "",' 
                cJson+='"key": "",' 
                cJson+='"invoice_number":"' + cNumFat + '",' 
                cJson+='"value":"'+ cValToChar(nValFat)+ '",' 
                cJson+='"date":"' + cDtFat + '" '
                cJson+= '} }'

                cPath := StrTran(cPathId,'{uuid}',cUuId)  //| add o uuid na URL de faturamento
                
                For nY:= 1 To 5 //Caso não consiga obter resposta tenta 5 vezes com intervalo de 2 seg

                    oRest := FwRest():New(cUrl)     //| acesso ao portal
                    oRest:setPath(cPath)            //| parte de envio de cobrança no portal
                    oRest:SetPostParams(cJson)      //| parametros com a cobrança 

                    If oRest:Post(aHeader)	  //| validações para conclusão do envio	
                    
                        cJson := DecodeUTF8(oRest:GetResult(), "cp1252") //| recebe resposta do Post enviado

                        //Objeto Json   
                        oJson := JsonObject():new() 
                        oJson:fromJson(cJson)  
                        
                        cIdBlu  := Alltrim(oJson:GetJsonText("uuid"))
                        cDocFat := Alltrim(oJson:GetJsonText("invoice_number"))
                        cStaFat := Alltrim(oJson:GetJsonText("status"))
                        cMsgBlu := Alltrim(oJson:GetJsonText("message"))

                        If cStaFat $("billed")//!Empty(cIdBlu)
                                                            
                            DbSelectArea("ZBL")
                            DbSetOrder(1)

                            DbSeek(_cFil+cNumBlu)

                            cMsgLog := AllTrim(ZBL_LOGORI) + CRLF 
                            cMsgLog += replicate('- ',60) + CRLF 
                            cMsgLog += 'Status integração Portal BLU ' + CRLF + CRLF 
                            cMsgLog += cStaFat + ' - '+ cMsgBlu + ' | '+DTOC(date())+ " - "+time()
                                                
                            RecLock("ZBL",.F.)
                                    
                                ZBL_INTEGR := '3'
                                ZBL_UUIDPG := cIdBlu
                                ZBL_MSGINT := cMsgBlu
                                ZBL_LOGORI := cMsgLog
                                ZBL_MSGBLU := cStaFat + ' - '+ cMsgBlu

                            ZBL->(MsunLock())     

                        Else

                            //| Se não foi possivel enviar o faturamento, gravamos mensagem.
                            DbSelectArea("ZBL")
                            DbSetOrder(1)

                            DbSeek(_cFil+cNumBlu)

                            RecLock("ZBL",.F.)

                                ZBL_INTEGR := '0'                                        
                                ZBL_MSGINT := cStaFat + ' - '+ cMsgBlu
                                ZBL_MSGBLU := cMsgBlu
                                ZBL_TPMAIL := '0'
                                ZBL_MAILST := 'N'

                            ZBL->(MsunLock())

                        EndIf      

                        nY := 5  //para sair do For, já que houve reposta do Post
                        FreeObj(oJson)
                        
                    Else
                        
                        //| Se não foi possivel enviar o faturamento, gravamos mensagem.
                        DbSelectArea("ZBL")
                        DbSetOrder(1)

                        DbSeek(_cFil+cNumBlu)

                            RecLock("ZBL",.F.)

                                ZBL_INTEGR := ' '                                        
                                ZBL_MSGBLU := "ERRO AO ENVIAR FATURAMENTO: " + oRest:GetLastError()
                                //ZBL_TPMAIL := '0'
                                //ZBL_MAILST := 'N'

                            ZBL->(MsunLock())

                        Sleep(2000) //Aguardo 2 segundos para tentar novo Post

                    EndIf
                
                Next nY

                (cAlias2)->(DbSkip())
        
            EndDo

            (cAlias2)->(DbCloseArea())
            
        EndIf

        lRet3 := zGet3ZBL()   

        //Tratativa para devolução de quando o titulo ja foi baixado e ainda existe saldo da aprovação
        //Inicialmente a divergencia  de arredondamento entre o protheus e o portal blu
        //casos identificado de R$ 0,01
        If  lRet3  .and. lDevSal

            cPathId :=  GetMv('CP_BLUURL6')  //Url de post de devolução do portal Blu

            (cAlias3)->(DbGotop())   

            While (cAlias3)->(!Eof()) 

                If (cAlias3)->DEVOLUCAO > 0 

                    _cFil := (cAlias3)->FILIAL
                    cNumBlu := (cAlias3)->NUMBLU
                    cUuId   := Alltrim((cAlias3)->BLUID)
                
                    //Header para validar acesso ao portal  
                    aHeader := {}  //limpo o array     
                    // Aadd(aHeader,"uuid:"+cUuId)
                    Aadd(aHeader,"Authorization:"+ cToken)

                    cPath := StrTran(cPathId,'{uuid}',cUuId)  //add o uuid na URL de consulta

                    For nZ:= 1 To 5 //Caso não consiga obter resposta tenta 5 vezes com intervalo de 2 seg

                        oRest := FwRest():New(cUrl)       //acesso ao portal
                        oRest:setPath(cPath) 

                        If oRest:Post(aHeader)  // validações para conclusão do envio	

                            //Variavel contendo dados para o Json
                            cJson := DecodeUTF8(oRest:GetResult(), "cp1252")

                            //Objeto Json   
                            oJson := JsonObject():new() 
                            oJson:fromJson(cJson)  
                            
                            cIdBlu  := Alltrim(oJson:GetJsonText("uuid"))
                            cDocNum := Alltrim(oJson:GetJsonText("document_number"))
                            cValDev := Alltrim(oJson:GetJsonText("value"))
                            cMsgBlu := Alltrim(oJson:GetJsonText("message"))

                            DbSelectArea("ZBL")
                            DbSetOrder(1)

                            DbSeek(_cFil+cNumBlu)

                            If "FATURAMENTO SERÁ FINALIZADO" $(Upper(AllTrim(cMsgBlu))) 

                                cMsgLog := AllTrim(ZBL_LOGORI) + CRLF 
                                cMsgLog += replicate('- ',60) + CRLF 
                                cMsgLog += 'Devolução Portal BLU ' +  ' | '+DTOC(date())+ " - "+time() + CRLF + CRLF 
                                cMsgLog += cIdBlu + CRLF 
                                cMsgLog += cDocNum + CRLF 
                                //cMsgLog += cValDev + CRLF 
                                cMsgLog += cMsgBlu + CRLF 
                                                    
                                RecLock("ZBL",.F.)   
                                    ZBL_LOGORI := cMsgLog                            
                                ZBL->(MsunLock()) 
                            Else

                                RecLock("ZBL",.F.)                                                                    
                                    ZBL_MSGBLU := AllTrim(cMsgBlu)
                                    ZBL_TPMAIL := '6'
                                    ZBL_MAILST := 'N'
                                ZBL->(MsunLock())  

                            EndIf
                                

                            nZ := 5  //para sair do For, já que houve reposta do Post
                            FreeObj(oJson)

                        Else

                            //| Se não foi possivel enviar o faturamento, gravamos mensagem.
                            DbSelectArea("ZBL")
                            DbSetOrder(1)

                            DbSeek(_cFil+cNumBlu)

                            RecLock("ZBL",.F.)
                                                                        
                                ZBL_MSGBLU := "ERRO AO ENVIAR DEVOLUCAO: " + oRest:GetLastError()
                                ZBL_TPMAIL := '6'
                                ZBL_MAILST := 'N'

                            ZBL->(MsunLock())    

                            Sleep(2000) //Aguardo 2 segundos para tentar novo Post                
                        
                        EndIf

                    Next nZ

                EndIf
                
                (cAlias3)->(DbSkip())

            EndDo

            (cAlias3)->(DbCloseArea())

        EndIf

        //| Chamada para rotina de envio de e-mail
        //u_BluMail(_aEmp)

        cLog += "[BluFat1] | FIM: " +DTOC(date())+ " - "+time() + CRLF
        cLog += "|" + Replicate('-',62) +"|"+ CRLF
        conout(cLog)
        
    EndIf

    If lSchedule
        RpcClearEnv()
    Endif

Return

/*/{Protheus.doc} zGetZBL
select para pegar registros de cobrança/pedido que devem ser integrados no portal BLU.
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
    cQuery+=" ZBL_VLPORT AS VLPORT," 
    cQuery+=" ZBL_CODCLI AS CLIENTE," 
    cQuery+=" ZBL_LOJA AS LOJA,"
    cQuery+=" ZBL_INTEGR AS STATUS,"
    cQuery+=" ZBL_ORIGEM AS ORIGEM,"
    cQuery+=" ZBL_PEDIDO AS PEDIDO,"
    cQuery+=" ZBL_CGC AS CNPJ"
    cQuery+=" FROM" 
    cQuery+="	"+Retsqlname("ZBL") + " A (NOLOCK)"
    cQuery+=" WHERE" 
    cQuery+="	A.D_E_L_E_T_ = ' ' " 
    cQuery+="	AND ZBL_INTEGR = ' ' "  
    cQuery+="	AND ZBL_ORIGEM <> 'SF2' "
    cQuery+=" ORDER BY ZBL_NUMBLU"  

    TCQuery cQuery NEW ALIAS (cAlias)

    count To nTotal
    
    If nTotal = 0 //|Se não há registros, defino para não seguir
        (cAlias)->(DbCloseArea())

        cLog += "Não há integrações para realizar no portal BLU." + CRLF
        lRet := .F.     
    
   
    Else  //|senão habilitado a seguir
      
       cLog += "Localizado(s) "+cValToChar(nTotal) + " registro(s) para integração."+ CRLF
       lRet := .T.

    EndIf

Return lRet

/*/{Protheus.doc} zGet2ZBL
Select para pegar numero das faturas que devem ser integrada ao portal BLU
@type Static Function
@version 
@author Cyberpolos
@since 7/7/2020
@Return lRet, retorna se há itens para integração.
/*/
Static Function zGet2ZBL()   

    Local cQuery := ''
    Local lRet   := .F.
    Local nTotal := 0
      
    cAlias2 := GetNextAlias()
    
    cQuery+=" SELECT " 
    cQuery+=" ZBL_FILIAL AS FILIAL," 
    cQuery+=" ZBL_NUMBLU AS NUMBLU," 
    cQuery+=" ZBL_BLUID AS BLUID," 
    cQuery+=" ZBL_DOC AS DOC," 
    cQuery+=" ZBL_SERIE AS SERIE," 
    cQuery+=" ZBL_VALOR AS VALOR," 
    cQuery+=" ZBL_VALPG AS VALPG," 
    cQuery+=" ZBL_TIPOPG AS TIPOPG," 
    cQuery+=" ZBL_DTFAT AS DTFAT," 
    cQuery+=" ZBL_TIPFAT AS TIPFAT,"
    cQuery+=" ZBL_INTEGR AS INTEGR"
    cQuery+=" FROM" 
    cQuery+="	"+Retsqlname("ZBL") + " A (NOLOCK)"
    cQuery+=" WHERE" 
    cQuery+="	A.D_E_L_E_T_ = ' ' " 
    cQuery+="	AND ZBL_INTEGR = ' ' "  
    cQuery+="	AND ZBL_DOC <> ' ' "  
    cQuery+="	AND ZBL_ORIGEM = 'SF2' "
    cQuery+=" ORDER BY ZBL_NUMBLU"  

    TCQuery cQuery NEW ALIAS (cAlias2)

    count To nTotal
    
    If nTotal = 0 //|Se não há registros, defino para não seguir
        (cAlias2)->(DbCloseArea())

        cLog += "Não ha fatura(s) para realizar integração ao portal BLU." + CRLF
        lRet := .F.         
   
    Else  //|senão habilitado a seguir
      
       cLog += "Localizado(s) "+cValToChar(nTotal) + " registro(s) de fatura(s) para integração."+ CRLF
       lRet := .T.

    EndIf

Return lRet


/*/{Protheus.doc} zGet3ZBL
Select para pegar numero das faturas que devem ser integrada ao portal BLU
@type Static Function
@version 
@author Cyberpolos
@since 7/7/2020
@Return lRet, retorna se há itens para integração.
/*/
Static Function zGet3ZBL()   

    Local cQuery := ''
    Local lRet   := .F.
    Local nTotal := 0
      
    cAlias3 := GetNextAlias()
    
    cQuery+=" SELECT " 
    cQuery+=" ZBL_FILIAL AS FILIAL," 
    cQuery+=" ZBL_NUMBLU AS NUMBLU," 
    cQuery+=" ZBL_BLUID AS BLUID," 
    cQuery+=" ZBL_DOC AS DOC," 
    cQuery+=" ZBL_SERIE AS SERIE," 
    cQuery+=" ZBL_VALOR AS VALOR," 
    cQuery+=" ZBL_VALPG AS VALPG," 
    cQuery+=" ZBL_DTFAT AS DTFAT," 
    cQuery+=" IIF(ZBL_ORIGEM = 'SF2', (ZBL_VALPG - ZBL_VALFAT),0) AS DEVOLUCAO,"
    cQuery+=" ZBL_TIPFAT AS TIPFAT,"
    cQuery+=" ZBL_INTEGR AS INTEGR,"
    cQuery+=" ZBL_STATUS AS STATUS"
    cQuery+=" FROM" 
    cQuery+="	"+Retsqlname("ZBL") + " A (NOLOCK)"
    cQuery+=" WHERE" 
    cQuery+="	A.D_E_L_E_T_ = ' ' " 
    cQuery+="	AND ZBL_INTEGR = '3' "  
    cQuery+="	AND ZBL_STATUS = '8' "  
    cQuery+="	AND ZBL_DOC <> ' ' "  
    cQuery+="	AND ZBL_UUIDPG <> ' ' "  
    cQuery+="	AND ZBL_DTFAT <= CONVERT(VARCHAR(10), GETDATE() -3, 112) "  
    cQuery+="	AND ZBL_ORIGEM = 'SF2' "
    cQuery+=" ORDER BY ZBL_NUMBLU"  

    TCQuery cQuery NEW ALIAS (cAlias3)

    count To nTotal
    
    If nTotal = 0 //|Se não há registros, defino para não seguir
        (cAlias3)->(DbCloseArea())

        cLog += "Não ha devolução para realizar integração ao portal BLU." + CRLF
        lRet := .F.         
   
    Else  //|senão habilitado a seguir
      
       cLog += "Localizado(s) "+cValToChar(nTotal) + " registro(s) de devolução para integração."+ CRLF
       lRet := .T.

    EndIf

Return lRet
