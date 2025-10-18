#include 'protheus.ch'
#include 'parmtype.ch'
#include 'totvs.ch'
#include 'restful.ch'
#Include 'tbiconn.ch'
#Include 'topconn.ch'  

/*/{Protheus.doc} BluCanc
Rotina ser� chamada por p.e, antes de enviar o cancelamento de cobran�a/fatura, ir� verificar o status,
se status_code atender as possibilidades da BLU o cancelamento � enviado, do contrario retorna .F. para o p.e, para n�o permitir o 
cancelamento da pedido/cobran�a.
@type User Function
@version 2.0
@author Cyberpolos
@since 8/7/2020
@Return lRet, retorna se o cancelamento do pedido/Nf pode ser realizado.

Status de cobran�a Blu : https://integracao.useblu.com.br/sobre-apis
	
	statusCode status message
    1 - Aguardando aprova��o
    2 - Aprovado, aguardando o valor total para pagamento autom�tico
    3 - Pagamento realizado
    4 - Pagamento cancelado
    5 - Pagamento rejeitado
    6 - Agendamento aprovado para o dia AAAA-MM-DD
    7 - Em processamento
    8 - Pagamento aguardando faturamento ou cancelamento de nota
    9 - Devolvido.
/*/
user Function BluCanc(cOpcao,cFil,cNumBlu)

    Local lRet      := .F.
    Local cDocNum   := ''
    Local cStatus   := ''
    Local cMsgInt   := ''
    Local cMsgBlu   := ''
    Local _cEnv     := ''
    Local aArea     := GetArea()
    Local cAmbProd  := ''

    Private aHeader := {}
    Private cToken  := ''
    Private cUrl    := ''
    Private cUuId   := ''
    Private cPath   := ''

    lUseBlu :=  GetMv('CP_BLUUSE')

    If lUseBlu  //Se rotinas API BLU estiver ativada

        _cEnv    := AllTrim(Upper(GetEnvServer())) //Ambiente em execu��o
        cAmbProd := AllTrim(Upper(GetMv('CP_BLUPROD'))) //Nome do ambiente de produ��o
        cUuId    := Alltrim(Posicione("ZBL",1,cFil+cNumBlu,"ZBL_BLUID"))

        //se houver uuid, verIfica o status no portal BLU 
        If !Empty(cUuId)

            cToken  := "Bearer "+ GetMv('CP_BLUTOKE') // Token de integra��o
            //cUrl    :=  GetMv('CP_BLUURL1')  // Url dePrincipal da API BLU
            cUrl    := IIf(_cEnv $(cAmbProd),GetMv('CP_BLUURL1'),GetMv('CP_BLUURL0')) // Url Principal da API BLU | define se � homologa��o ou produ��o

            lRet := zStatus(@cDocNum,@cStatus,@cMsgInt,@cMsgBlu)

            //cOpcao |1 = Cobran�a  2= Fatura 
            //Se o status for igual aos permitidos para cancelamento de cobran�a
            If cStatus $ ('1|2|6') .and. cOpcao == "1"  .and. lRet
                lRet := zCancCob(cFil)           //Rotina para cancelamento de cobran�a 
            ElseIf cStatus $ ('8') .and. cOpcao == "1"  .and. lRet 
                lRet := zDevCob(cFil)            //Devolu��o de cobran�a
            ElseIf cStatus $ ('8') .and. cOpcao == "2"  .and. lRet                                
                lRet := zCancFat(cFil,cNumBlu)    //Rotina para cancelar faturamento            
            ElseIf cStatus $ ('4|5')         //Com esses status significa que ja consta cancelado/rejeitado no portal ent�o permite cancelar cobran�a/fatura no sistema.
                lRet := .T.
            ElseIf Empty(cStatus)            //se vazio n�o conseguiu acessar o portal, a mensagem � exibina na consulta do status.
                lRet := .F.  
            Else
                lRet := .F.
                MsgInfo("Cobran�a com status BLU: "+cStatus + ' - '+cMsgInt+", impossibilitando o processo de cancelamento." ,"Aten��o")
            EndIf
        
        Else

            //valida��o para verIficar se realmente n�o h� integra��o.
            DbSelectArea("ZBL")
            If ZBL->(DbSeek(cFil+cNumBlu))
                //se esses campos estiverem preenchido significa que houve integra��o
                If !Empty(ZBL->ZBL_INTEGR) .or. !Empty(ZBL->ZBL_STATUS) 
                    lRet := .F.
                    MsgInfo("N�o ser� poss�vel seguir o processo, pois n�o foi localizado o BLUID [ZBL_BLUID.] ")   
                Else  //sen�o realmente n�o h� integra��o

                    cMsgLog := alltrim(ZBL_LOGORI) + CRLF 
                    cMsgLog += "Item excluido." +' | '+DTOC(Date())+ " - "+Time() + ' | '+ "User: "+ Alltrim(Substr(cUsername,1,20))

                    RecLock("ZBL",.F.)
                    
                        ZBL_INTEGR := '4'              //Status da integra��o interna
                        ZBL_STATUS := '4'              //Status Blu
                        ZBL_MSGINT := "Item excluido"  //Mensagem de integra��o                  
                        ZBL_LOGORI := cMsgLog          //Mensagem Log

                    ZBL->(MsunLock())

                    lRet := .T.

                EndIf           
            Else           
                lRet := .T.
            EndIf

        EndIf   

    Else
        lRet := .T.    
    EndIf

    RestArea(aArea)
    
Return lRet

/*/{Protheus.doc} zStatus
description
@type Function
@version 
@author ataki
@since 7/9/2020
@param cDocNum, character, Numero do documento Blu
@param cStatus, character, Status no portal Blu
@param cMsgInt, character, Mensagem de integra��o do portal
@param cMsgBlu, character, mensagem da tag "message"
@Return lCont, se pode seguir com o processo
/*/
Static Function zStatus(cDocNum,cStatus,cMsgInt,cMsgBlu)

    Local cPathId := ""
    Local lCont   := .F.
    Local oJson   := Nil
    Local oRest   := Nil
       
    cPathId :=  GetMv('CP_BLUURL3')
    
    //Header para validar acesso ao portal  
    aHeader := {}  //limpo o array        
    Aadd(aHeader,"uuid:"+cUuId)
    Aadd(aHeader,"Authorization:"+ cToken)
    
    cPath := StrTran(cPathId,'{uuid}',cUuId)  //add o uuid na URL de consulta

    oRest := FwRest():New(cUrl)       //acesso ao portal
    oRest:setPath(cPath) 

    If oRest:Get(aHeader)  // valida��es para conclus�o do envio	
            
        //Variavel contendo dados para o Json
        cJson := DecodeUTF8(oRest:GetResult(), "cp1252") // '{'    

        //Objeto Json   
        oJson := JsonObject():new() 
        oJson:fromJson(cJson)  
        
        cDocNum := Alltrim(oJson:GetJsonText("document_number"))
        cStatus := Alltrim(oJson:GetJsonText("status_code"))
        cMsgInt := Alltrim(oJson:GetJsonText("status"))
        cMsgBlu := Alltrim(oJson:GetJsonText("message"))        

        FreeObj(oJson)

        lCont := IIf(!Empty(cStatus),.T.,.F.)
    
    Else

        lCont := .F.
        MsgInfo("Erro: "+oRest:GetLastError()+" ao tentar consultar status no Portal BLU.","Aten��o")

    EndIf     

Return lCont 

/*/{Protheus.doc} zCancCob
Realiza o cancelamento de uma cobran�a no portal BLU
@type Static Function
@version 2.0 
@author Cyberpolos
@since 9/7/2020
@Return lRet, retorna se conseguiu realizar o cancelamento.
/*/
Static Function zCancCob(cFil)

    Local lRet := .F.
    Local cPathId := ''
    Local cDocNum := ''
    Local cStatus := ''
    Local cMsgInt := ''
    Local cMsgBlu := ''
    Local cIdBlu  := ''
    Local cJson   := ''
    
    //Local oJson
    Local oJson
    Local oRest 

    cPathId :=  GetMv('CP_BLUURL3')

    //Header para validar acesso ao portal  
    aHeader := {}  //limpo o array     
    Aadd(aHeader,"uuid:"+cUuId)
    Aadd(aHeader,"Authorization:"+ cToken)

    cPath := StrTran(cPathId,'{uuid}',cUuId)  //add o uuid na URL de consulta

    oRest := FwRest():New(cUrl)       //acesso ao portal
    oRest:setPath(cPath) 

    If oRest:Delete(aHeader)  // valida��es para conclus�o do envio	

        //Variavel contendo dados para o Json
        cJson := DecodeUTF8(oRest:GetResult(), "cp1252") // '{'    

        //Objeto Json   
        oJson := JsonObject():new() 
        oJson:fromJson(cJson)  
        
        cIdBlu  := Alltrim(oJson:GetJsonText("uuid"))
        cDocNum := Alltrim(oJson:GetJsonText("document_number"))
        cMsgBlu := Alltrim(oJson:GetJsonText("message"))

        //Se o status for igual aos permitidos para cancelamento de cobran�a/fatura
        If lRet .and. cStatus == '4' //!Empty(cDocCanc) 

            DbSelectArea("ZBL")
            DbSetOrder(1)

            If DbSeek(cFil+cDocNum)

                cMsgLog := alltrim(ZBL_LOGORI) + CRLF 
                cMsgLog += cStatus + ' - '+ cMsgInt + ' | '+DTOC(Date())+ " - "+Time() + ' | '+ "User: "+ Alltrim(Substr(cUsername,1,20))
            
                RecLock("ZBL",.F.)
                    
                    ZBL_INTEGR := '4'      //Status da integra��o interna
                    ZBL_STATUS := cStatus  //Status Blu
                    ZBL_MSGINT := cMsgInt  //Mensagem de integra��o                  
                    ZBL_LOGORI := cMsgLog  //Mensagem Log

                ZBL->(MsunLock())

                MsgInfo("Cancelamento da cobran�a n� "+cDocNum+", realizada com sucesso no portal BLU.","Aten��o")

            Else

                MsgInfo("N�o foi poss�vel localizar a cobran�a n� "+cDocNum+", para altera��o de status.","Aten��o")

            EndIf                     

        Else

            lRet := .F.
            MsgInfo("Status BLU: "+cStatus + ' - '+cMsgInt+ " | "+ cMsgBlu +", impossibilitando o processo." ,"Aten��o")

        EndIf
    
    Else

        lRet := .F.
        MsgInfo("Erro: "+oRest:GetLastError()+" Cancelar cobran�a no Portal BLU.","Aten��o")

    EndIf        
    
Return lRet

/*/{Protheus.doc} zCancFat
Realiza o cancelamento de um faturamento junto ao portal Blu.
@type Function
@version 
@author ataki
@since 7/13/2020
@Return lRet, retorna se o cancelamento foi realizado.
/*/
Static Function zCancFat(cFil,cNumBlu)

    Local cDocNum  := ""
    Local cMsgBlu  := ""
    Local cMsgInt  := ""
    Local cPathId  := ""
    Local cStatus  := ""
    Local cUuIdPag := ""
    Local lRet     := .F.
    Local nIdPaga  := 0
    Local oRest    := ""

    cPathId  :=  GetMv('CP_BLUURL5')
    nIdPaga  :=  Posicione("ZBL",1,cFil+cNumBlu,"ZBL_IDPAGA")
    cUuIdPag :=  Alltrim(Posicione("ZBL",1,cFil+cNumBlu,"ZBL_UUIDPG"))

    If !Empty(cUuIdPag) .And. nIdPaga > 0  //Neste caso h� registro da integra��o do faturamento
        //Header para validar acesso ao portal  
        aHeader := {}  //limpo o array     
        Aadd(aHeader,"Authorization:"+ cToken)

        cPathId := StrTran(cPathId,'{uuid}',cUuId)  //add o uuid na URL de cancelamento
        cPath   := StrTran(cPathId,'{invoice-uuid}',cUuIdPag) //add o uuid de pagamento na URL de de cancelamento

        oRest := FwRest():New(cUrl)       //acesso ao portal
        oRest:setPath(cPath) 

        If oRest:Delete(aHeader)  // valida��es para conclus�o do envio	

            //Variavel contendo dados para o Json
            cJson := DecodeUTF8(oRest:GetResult(), "cp1252") // '{'    

            //Objeto Json   
            oJson := JsonObject():new() 
            oJson:fromJson(cJson)  
            
            cIdBlu  := Alltrim(oJson:GetJsonText("uuid"))
            cDocNum := Alltrim(oJson:GetJsonText("document_number"))
            cMsgBlu := Alltrim(oJson:GetJsonText("message"))

            
            //Se o status for igual aos permitidos para cancelamento de Fatura
            If cUuIdPag $(cMsgBlu) //significa que foi cancelado.

                DbSelectArea("ZBL")
                DbSetOrder(1)
    
                If DbSeek(cFil+cNumBlu)

                    cMsgLog := alltrim(ZBL_LOGORI) + CRLF 
                    cMsgLog += cMsgBlu + ' | '+DTOC(Date())+ " - "+Time() + ' | '+ "User: "+ Alltrim(Substr(cUsername,1,20))
                
                    RecLock("ZBL",.F.)
                        
                        ZBL_INTEGR := '4'      //Status da integra��o interna
                        ZBL_STATUS := '4'      //Status Blu
                        ZBL_TPMAIL := '4'      //Tipo de e-mail
                        ZBL_MAILST := 'N'      //Email enviado
                        ZBL_MSGINT := cMsgBlu  //Mensagem de integra��o                  
                        ZBL_LOGORI := cMsgLog  //Mensagem Log

                    ZBL->(MsunLock())
                    lRet := .T.
                    MsgInfo("Cancelamento da cobran�a n� "+cDocNum+", realizada com sucesso no portal BLU.","Aten��o")

                Else

                    MsgInfo("N�o foi poss�vel localizar a cobran�a n� "+cDocNum+", para altera��o de status.","Aten��o")

                EndIf                     

            Else

                lRet := .F.
                MsgInfo("Status BLU: "+cStatus + ' - '+cMsgInt+ " | "+ cMsgBlu +", impossibilitando o processo." ,"Aten��o")

            EndIf
        
        Else

            lRet := .F.
            MsgInfo("Erro: "+oRest:GetLastError()+" Cancelar cobran�a no Portal BLU.","Aten��o")

        EndIf

    Else

        DbSelectArea("ZBL")
        DbSetOrder(1)

        If DbSeek(cFil+cNumBlu)

            cMsgBlu := "Faturamento cancelado "
            cMsgLog := alltrim(ZBL_LOGORI) + CRLF 
            cMsgLog += cMsgBlu + ' | '+DTOC(Date())+ " - "+Time() + ' | '+ "User: "+ Alltrim(Substr(cUsername,1,20))
        
            RecLock("ZBL",.F.)
                
                ZBL_INTEGR := '4'      //Status da integra��o interna
                ZBL_STATUS := '4'      //Status Blu
                ZBL_TPMAIL := '4'      //Tipo de e-mail
                ZBL_MAILST := 'N'      //Email enviado
                ZBL_MSGINT := cMsgBlu  //Mensagem de integra��o                  
                ZBL_LOGORI := cMsgLog  //Mensagem Log

            ZBL->(MsunLock())

        EndIf

        lRet := .T.

    EndIf        
    
Return lRet

/*/{Protheus.doc} zDevCob
Usada para realizar a devolu��o de uma cobran�a, ap�s essa ter sido autorizada no portal BLU
@type Static Function
@version 
@author Cyberpolos
@since 23/07/2020
@return lRet, logico, se conseguiu realizar a devolu��o.
/*/
Static Function zDevCob(cFil)

    Local cDocNum := ""
    Local cIdBlu  := ""
    Local cJson   := ""
    Local cMsgBlu := ""
    Local cMsgInt := ""
    Local cPathId := ""
    Local cStatus := ""
    Local lRet    := .F.
    Local oJson   := ""
    Local oRest   := ""

    cPathId :=  GetMv('CP_BLUURL6')  //Url de post de devolu��o do portal Blu

    //Header para validar acesso ao portal  
    aHeader := {}  //limpo o array     
    Aadd(aHeader,"uuid:"+cUuId)
    Aadd(aHeader,"Authorization:"+ cToken)

    cPath := StrTran(cPathId,'{uuid}',cUuId)  //add o uuid na URL de consulta

    oRest := FwRest():New(cUrl)       //acesso ao portal
    oRest:setPath(cPath) 

    If oRest:Post(aHeader)  // valida��es para conclus�o do envio	

        //Variavel contendo dados para o Json
        cJson := DecodeUTF8(oRest:GetResult(), "cp1252")

        //Objeto Json   
        oJson := JsonObject():new() 
        oJson:fromJson(cJson)  
        
        cIdBlu  := Alltrim(oJson:GetJsonText("uuid"))
        cDocNum := Alltrim(oJson:GetJsonText("document_number"))
        cMsgBlu := Alltrim(oJson:GetJsonText("message"))

        //Se n�o vazio signIfica que teve devolu��o
        If !Empty(cIdBlu) 

            DbSelectArea("ZBL")
            DbSetOrder(1)

            If DbSeek(cFil+cDocNum)

                cMsgLog := alltrim(ZBL_LOGORI) + CRLF 
                cMsgLog += 'Devolu��o - '+ cMsgBlu + ' | '+DTOC(Date())+ " - "+Time() + ' | '+ "User: "+ Alltrim(Substr(cUsername,1,20))
            
                RecLock("ZBL",.F.)
                    
                    ZBL_INTEGR := '3'      //Status da integra��o interna
                    ZBL_STATUS := '3'      //Status Blu
                    ZBL_MSGINT := cMsgBlu  //Mensagem de integra��o                  
                    ZBL_LOGORI := cMsgBlu  //Mensagem Log

                ZBL->(MsunLock())

                lRet := .T.                
                MsgInfo("Devolu��o da cobran�a n� "+cDocNum+", realizada com sucesso no portal BLU.","Aten��o")

            Else

                MsgInfo("N�o foi poss�vel localizar a cobran�a n� "+cDocNum+", para altera��o de status.","Aten��o")

            EndIf                     

        Else

            lRet := .F.
            MsgInfo("Status BLU: "+cStatus + ' - '+cMsgInt+ " | "+ cMsgBlu +", impossibilitando o processo." ,"Aten��o")

        EndIf
    
    Else

        lRet := .F.
        MsgInfo("Erro: "+oRest:GetLastError()+" Cancelar cobran�a no Portal BLU.","Aten��o")

    EndIf  

Return lRet
