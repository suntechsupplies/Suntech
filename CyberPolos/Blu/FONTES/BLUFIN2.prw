#include 'protheus.ch'
#include 'parmtype.ch'
#include 'totvs.ch'
#Include "Rwmake.ch"
#Include 'tbiconn.ch'
#Include 'topconn.ch'
#Include 'FINA280.CH'

/*/{Protheus.doc} BluFin2
Utilizada para realizar baixa dos títulos a baixa ocorre no momento da conciliação junto ao portal BLU,
@type Function
@version 2.0
@author Cyberpolos
@since 25/06/2020
/*/
User Function BluFin2(_aEmp)

    Local aHeader    := {}
    Local cAmbProd   := ""
    Local _cEnv 	 := ""
    Local cPath      := ""
    Local cPathDt    := ""
    Local cToken     := ""
    Local cUrl       := ""
    Local cDtOri     := ""
    Local cData      := ""
    Local cFatura    := ""
    Local lRet       := .F.
    Local lUseBlu    := .F.
    Local nX         := 0
    Local nY         := 0
    Local nPos       := 0
    Local nDevol     := 0
    Local oJson      := Nil
    Local oRest      := Nil
    Local lSchedule  := .F.
    Private aSel     := {}
    Private cAliasBl := ""
    Private cLog     := "|" + Replicate('-',62) +"|"+ CRLF

    // Inicializa ambiente pelo schedule
	If Select("SX6") == 0
		RPCSetType(3)  		//| Nao utilizar licenca	
		RpcSetEnv(_aEmp[1],_aEmp[2])
		lSchedule := .T.		
	Endif    
	//+-------------------------------------------------------
	// tratamento para nao haver execucao concorrente
	//+-------------------------------------------------------
	if !(LockByName('BluFin2', .T., .F.))
        ConOut("BluFin2 ja esta em execucao")
        if lSchedule
            RpcClearEnv()
        Endif
        Return
	Endif    
    
    lUseBlu :=  GetMv('CP_BLUUSE')  //| Parametro para verIficar se as rotina BLU está ativa
    lDevSal :=  GetMv('CP_BLUDEVP') //| Se devolve saldo em pedidos parciais.

    If lUseBlu  //| Se rotinas API BLU estiver ativada
       
        cLog += "[BluFin2] | INICIO: " +DTOC(date())+ " - "+Time() + CRLF 

        _cEnv 	:= AllTrim(Upper(GetEnvServer())) //Ambiente em execução
        cAmbProd := AllTrim(Upper(GetMv('CP_BLUPROD')))  //Nome do ambiente de produção
      
        lRet := zGetZBL()
        
        If lRet

            cToken   := "Bearer "+ GetMv('CP_BLUTOKE') //| Token de integração
            cUrl     := IIf(_cEnv $(cAmbProd),GetMv('CP_BLUURL1'),GetMv('CP_BLUURL0')) // Url Principal da API BLU | define se é homologação ou produção
            cPathDt  := GetMv('CP_BLUURL7')            //| Parte da URL de GET de consulta conciliação financeira na API BLU

            (cAliasBl)->(DBGoTop())

            While (cAliasBl)->(!EOF())          

                cDtOri :=  (cAliasBl)->DTPAGA     
                cData  := SubStr(cDtOri,1,4)+"-"+ SubStr(cDtOri,5,2)+"-"+SubStr(cDtOri,7,2)  //formato para XXXX-XX-XX

                cPath := cPathDt+cData
                
                aHeader := {}  //| limpo o array    
                Aadd(aHeader,"Authorization:"+ cToken)

                For nX:= 1 To 5
                
                    oRest := FwRest():New(cUrl)       //| acesso ao portal
                    oRest:setPath(cPath)              //| parte de envio de cobrança no portal                    
                
                    If oRest:Get(aHeader)

                        strJson := DecodeUTF8(oRest:GetResult(), "cp1252") //| resposta do Get
                    
                        oJson := JSonObject():New()  //| Cria o objeto JSON e popula ele a partir da string
                        cErro  := oJSon:fromJson(strJson)

                        If !empty(cErro)

                                cLog += "JSON PARSE ERROR: " + cErro + CRLF    
                                cLog += "[BluFin2] | FIM: " +DTOC(date())+ " - "+time() + CRLF
                                cLog += "|" + Replicate('-',62) +"|"+ CRLF

                                ConOut(cLog)                   
                            
                        Else

                            aSel := {}

                            For nY:= 1 To len(oJson)
                            
                                nId      := oJson[nY]['payment_id']
                                cFatBlu  := oJson[nY]['invoice_number']                
                                cCnpj    := StrTran(oJson[nY]['charged'],".","")   
                                cCnpj    := StrTran(cCnpj,"/","")
                                cCnpj    := IIf("-" $(cCnpj),StrTran(cCnpj,"-",""),cCnpj)                                        
                                nValPg   := Val(oJson[nY]['value'])                          

                                aAdd(aSel,{nId,cFatBlu,cCnpj,nValPg})          

                            Next nY                          

                        EndIf

                        nX := 5 //como teve resposta do Get, sai do For

                    Else

                        cLog += "ERRO ao obter informações da API BLU: "+ oRest:GetLastError() + CRLF     
                        Sleep(2000) //Aguardo 2 segundos para tentar novo GET   
                    
                    EndIf
                
                Next nX

                If Len(aSel) > 0

                    While (cAliasBl)->(!EOF()) .And. (cAliasBl)->DTPAGA == cDtOri

                        cFatura := Alltrim((cAliasBl)->NUM) + Alltrim((cAliasBl)->PREFIXO)
                        
                        If (cAliasBl)->ORIGEM <> 'SE1'

                            //Se a Cobrança não foi gerada de título em atraso, há faturamento enviado para BLU 
                            nPos := AScan(  aSel, { |x| x[1] == (cAliasBl)->IDFAT .And. ;
                                                Alltrim(x[2]) == cFatura .And. ;
                                                Alltrim(x[3]) == Alltrim((cAliasBl)->CNPJ)})

                        Else

                            //Senao a Cobrança foi gerada de título em atraso, não há faturamento enviado para BLU 
                            nPos := AScan(  aSel, { |x| x[1] == (cAliasBl)->IDFAT .And. ;
                                                Alltrim(x[3]) == Alltrim((cAliasBl)->CNPJ)})

                        EndIf


                        If nPos > 0 //Se localizou o pagamento faz a baixa

                            lRet :=  zBaixa()
                                                     
                            /* Devolução passa a ser realizada na rotina BLUFAT1
                            //Trativa para Devolução de saldo
                            nDevol := (cAliasBl)->DEVOLUCAO

                            If   nDevol > 0 .And. lRet  .And. lDevSal  //Se existir valor de devolução e houve baixa e empresa devolve saldo em pedidos parciais

                                lRet := U_BLUCANC("1",(cAliasBl)->FILIAL,(cAliasBl)->NUMBLU)                                    

                            EndIf    
                            */
                        EndIf               
                        
                        (cAliasBl)->(DbSkip())

                    EndDo
                
                EndIf
                
            EndDo
        
        EndIf
             
        Conout(cLog)

        cLog := "[BluFin2] | FIM: " +DTOC(date())+ " - "+time() + CRLF
        cLog += "|" + Replicate('-',62) +"|"+ CRLF
        Conout(cLog)
    
    EndIf    

    If lSchedule
        RpcClearEnv()
    Endif

Return

/*/{Protheus.doc} zGetZBL
Select para buscar títulos a serem baixados quando a cobrança For autotizada no portal BLU.  
@type Static Function
@version 2.0
@author Cyberpolos
@since 6/7/2020
@Return lRet, retorna se há títulos a serem baixados
/*/
Static Function zGetZBL()
   
    Local cQuery := ""
    Local lRet   := .F.
    Local nTotal := 0
    Local nHoras := GetMv('CP_BLUHRBT')  
    Local nDias  := 0
    Local dData  := Nil

    nDias  := IIf(Int(nHoras / 24) < 0, 0,Int(nHoras / 24))
    dData  := DaySub( Date() , nDias )
    cAliasBl := GetNextAlias()
    
    cQuery+=" SELECT " 
    cQuery+=" ZBL_FILIAL AS FILIAL," 
    cQuery+=" ZBL_NUMBLU AS NUMBLU," 
    cQuery+=" ZBL_CODCLI AS CLIENTE," 
    cQuery+=" ZBL_LOJA AS LOJA,"
    cQuery+=" ZBL_NOME AS NOME,"
    cQuery+=" ZBL_INTEGR AS STATUS,"
    cQuery+=" ZBL_ORIGEM AS ORIGEM,"
    cQuery+=" ZBL_VALFAT AS VALFAT,"
    cQuery+=" ZBL_VLPORT AS VLPORT,"
    cQuery+=" ZBL_RATEPG AS RATEPG,"
    cQuery+=" ZBL_TIPOPG AS TIPOPG,"
    cQuery+=" IIF(ZBL_ORIGEM = 'SF2', (ZBL_VALPG - ZBL_VALFAT),0) AS DEVOLUCAO,"
    cQuery+=" ZBL_DEVSAL AS DEVSAL,"
    cQuery+=" ZBL_DTPAGA AS DTPAGA,"
    cQuery+=" ZBL_CGC AS CNPJ,"
    cQuery+=" E1_PREFIXO AS PREFIXO,"
    cQuery+=" E1_NUM AS NUM,"
    cQuery+=" E1_VALOR AS VALOR,"
    cQuery+=" E1_TIPO AS TIPO,"
    cQuery+=" E1_NATUREZ AS NATUREZA,"
    cQuery+=" E1_PARCELA AS PARCELA,"
    cQuery+=" E1_PORTADO AS BANCO,"
    cQuery+=" E1_AGEDEP AS AGENCIA,"
    cQuery+=" E1_CONTA AS CONTA,"
    cQuery+=" E1_XIDFAT AS IDFAT,"
    cQuery+=" E1_XUUIDFT AS UUIDFT "
    cQuery+=" FROM" 
    cQuery+="	"+Retsqlname("ZBL") + " A (NOLOCK)"
    cQuery+=" INNER JOIN "+Retsqlname("SE1") + " B (NOLOCK) ON B.E1_FILIAL = A.ZBL_FILIAL AND B.E1_XNUMBLU = A.ZBL_NUMBLU"
    cQuery+=" AND B.E1_CLIENTE = A.ZBL_CODCLI AND B.E1_LOJA = A.ZBL_LOJA AND B.D_E_L_E_T_= ' ' " 
    cQuery+=" WHERE" 
    cQuery+="	A.D_E_L_E_T_ = ' ' " 
    cQuery+="	AND ZBL_INTEGR = '3'"
    cQuery+="	AND ZBL_STATUS IN ('3','8')" 
    cQuery+="	AND ZBL_ORIGEM <> 'SC5'"
    cQuery+="	AND ZBL_BAIXAT = 'N' 
    cQuery+="	AND ZBL_DTPAGA  <= '" + DTos(dData) + "' 
    cQuery+="	ORDER BY ZBL_DTPAGA, ZBL_CODCLI"

    TCQuery cQuery NEW ALIAS (cAliasBl)

    count To nTotal

    If nTotal = 0

        (cAliasBl)->(DbCloseArea())
            cLog+= "Não há registros de Títulos a serem baixados."   + CRLF        
        lRet := .F.
    
    Else
        
       lRet := .T.

    EndIf

Return lRet

/*/{Protheus.doc} zBaixa
Realiza a baixa detítulos que foram aprovados, seja por aprovação no "motor" (ZBL) ou
por meio da conciliação financeira obtida.
@type Static Function
@version 2.0
@author Cyberpolos
@since 6/7/2020
/*/
Static Function zBaixa()

    Local aBaixa      := {}
    Local cAgencia    := ""
    Local cBanco      := ""
    Local _cFil       := ""
    Local cNum        := ""
    Local cPrefixo    := ""
    Local cTipo       := ""
    Local cConta      := ""
    Local cNumBlu     := ""
    Local cNatureza   := ""
    Local cNtMovBan   := ""
    Local cTipoPg     := ""
    Local nValor      := 0
    Local nVlPort     := 0
    Local nDescont    := 0
    Local nBluTaxa    := 0
    Local nVlTaxa     := 0
    Local lMsErroAuto := .F.
    Local lRet        := .T.
    Local aArea       := GetArea()        
    
    _cFil     := (cAliasBl)->FILIAL
    cNumBlu   := (cAliasBl)->NUMBLU
    cPrefixo  := (cAliasBl)->PREFIXO
    cNum      := (cAliasBl)->NUM
    cTipo     := (cAliasBl)->TIPO
    nValor    := (cAliasBl)->VALOR
    nVlPort   := (cAliasBl)->VLPORT
    cTipoPg   := (cAliasBl)->TIPOPG
    cNatureza := (cAliasBl)->NATUREZA
    cBanco    := PADR(GetMV('CP_BLUFBCO'),TAMSX3("A6_COD")[1])
    cAgencia  := PADR(GetMV('CP_BLUFAGE'),TAMSX3("A6_AGENCIA")[1])
    cConta    := PADR(GetMV('CP_BLUFCTA'),TAMSX3("A6_NUMCON")[1])
    cNtMovBan := GetMV('CP_BLUNTMB')
    nBluTaxa  := GetMV('CP_BLUTAXA')

    //Se o pagamento foi realizado a vista é lançado o desconto
    //nDescont  := IIF(cTipoPg == "1", (((cAliasBl)->VALFAT * (cAliasBl)->RATEPG) / 100), 0)

    DbSelectArea("SE1")
    
    aBaixa := {{"E1_PREFIXO"   , cPrefixo          ,Nil    },;
               {"E1_NUM"      , cNum               ,Nil    },;
               {"E1_TIPO"     , cTipo              ,Nil    },;
               {"AUTMOTBX"    ,"NOR"               ,Nil    },;
               {"AUTBANCO"    , cBanco             ,Nil    },;
               {"AUTAGENCIA"  , cAgencia           ,Nil    },;
               {"AUTCONTA"    , cConta             ,Nil    },;
               {"AUTDTBAIXA"  , dDataBase          ,Nil    },;
               {"AUTDTCREDITO", dDataBase          ,Nil    },;
               {"AUTHIST"     ,"BAIXA BLU"         ,Nil    },;
               {"AUTDESCONT"  ,nDescont            ,Nil,.T.},;
               {"AUTJUROS"    ,0                   ,Nil,.T.},;
               {"AUTVALREC"   ,nValor              ,Nil    }}

    MSExecAuto({|x,y| Fina070(x,y)},aBaixa,3,.F.)  //| rotina padrão de baixa de títulos.

    If lMsErroAuto
        
        cLog+= "ERRO AO BAIXAR O TÍTULO: " +aBaixa[2][2]+" | " + MostraErro() + CRLF  
        lRet := .F.

    Else       

        //Realiza Movimentação bancaria se o pagamento não foi a Vista
        If cTipoPg <> "1"   
           
            nVlTaxa := ((nVlPort * nBluTaxa) / 100)

            //Movimentação Bancaria a receber
            aFINA100 := {{"E5_DATA"       ,dDataBase                          ,Nil},;
                        {"E5_MOEDA"       ,"M1"                               ,Nil},;
                        {"E5_VALOR"       ,nVlTaxa                            ,Nil},;
                        {"E5_NATUREZ"     ,cNtMovBan                          ,Nil},;
                        {"E5_BANCO"       ,cBanco                             ,Nil},;
                        {"E5_AGENCIA"     ,cAgencia                           ,Nil},;
                        {"E5_CONTA"       ,cConta                             ,Nil},;
                        {"E5_HISTOR"      ,"Bx.Emis. NF - "+ cNum + " | BLU"  ,Nil}}
            
            MSExecAuto({|x,y,z| FinA100(x,y,z)},0,aFINA100,3)
            
            If lMsErroAuto      
                cLog+= "ERRO Movto. Bancario Receber TÍTULO: " +aBaixa[2][2]+" | " + MostraErro() + CRLF            
                lRet := .F.
            Else
                conout("Movto. Bancario Receber incluido com sucesso !!!")
            EndIf 
                  
        EndIf

        DbSelectArea("ZBL")

        If DbSeek(_cFil+cNumBlu)

            Begin Transaction
                RecLock("ZBL",.F.)                    
                    ZBL_BAIXAT := "S"
                ZBL->(MsunLock())
            End Transaction
        
        EndIf

        cLog+= "TÍTULO: " +aBaixa[2][2]+" BAIXADO COM SUCESSO."   + CRLF                

    EndIf

    RestArea(aArea)

Return lRet

/*/{Protheus.doc} zGeraTit
Gera título do tipo RA, para devoluções em que o cliente não aceita a devolução dos Creditos.
@type Static Function
@version 2.0
@author Cyberpolos
@since 6/7/2020
/*/
Static Function zGeraTit(_nValor)

    Local _cAgencia   := PADR(GetMV('CP_BLUFAGE'),TAMSX3("A6_AGENCIA")[1])
    Local _cBanco     := PADR(GetMV('CP_BLUFBCO'),TAMSX3("A6_COD")[1])
    Local _cConta     := PADR(GetMV('CP_BLUFCTA'),TAMSX3("A6_NUMCON")[1])
    Local _Cliente    := (cAliasBl)->CLIENTE
    Local _cLoja      := (cAliasBl)->LOJA
    Local _cFil       := (cAliasBl)->FILIAL
    Local _cNatureza  := (cAliasBl)->NATUREZA
    Local _cOrigem    := 'BLU'
    Local _cPrefixo   := 'RAB'
    Local _cTitulo    := (cAliasBl)->NUMBLU
    Local _dVencto    := DaySum(dDataBase,30) //soma 30 dias na data atual
    Local _nMoeda     := 1
    Local aFlagCTB    := {}
    Local aRastroDes  := {}
    Local aRastroOri  := {}
    Local aTitInc     := {}
    Local cArquivo    := Nil
    Local cLote       := Nil
    Local cPadrao     := "595"
    Local lMsErroAuto := .F.
    Local lPadrao     := VerPadrao(cPadrao)
    Local lRastro     := If(FindFunction("FVerRstFin"),FVerRstFin(),.F.)
    Local lRet        := .T.
    Local lRmClass    := GetNewPar("MV_RMCLASS",.F.)
    Local lUsaFlag    := SuperGetMV( "MV_CTBFLAG" , .T. /*lHelp*/, .F. /*cPadrao*/)
    Local nHdlPrv     := 0
    Local nValProces  := 0
    Local nX          := 0

    aTit := {}
    AADD(aTit , {"E1_FILIAL"	, _cFil             					, NIL})
    AADD(aTit , {"E1_PREFIXO"	, _cPrefixo								, NIL})
    AADD(aTit , {"E1_NUM"    	, _cTitulo								, NIL})
    AADD(aTit , {"E1_PARCELA"	, '01'									, NIL})
    AADD(aTit , {"E1_TIPO"   	, 'RA'									, NIL})
    AADD(aTit , {"E1_NATUREZ"	, _cNatureza							, NIL})
    AADD(aTit , {"E1_PORTADO"	, _cBanco								, NIL})
    AADD(aTit , {"E1_AGEDEP"	, _cAgencia								, NIL})
    AADD(aTit , {"E1_CONTA"		, _cConta								, NIL})
    AADD(aTit , {"E1_CLIENTE"	, _Cliente			                    , NIL})
    AADD(aTit , {"E1_LOJA"   	, _cLoja				                , NIL})
    AADD(aTit , {"E1_NOMCLI" 	, (cAliasBl)->NOME  					, NIL})
    AADD(aTit , {"E1_VENCTO" 	, _dVencto								, NIL})
    AADD(aTit , {"E1_VENCREA"	, DataValida(_dVencto,.T.)				, NIL})
    AADD(aTit , {"E1_VENCORI"	, DataValida(_dVencto,.T.)				, NIL})
    AADD(aTit , {"E1_EMISSAO"	, dDataBase								, NIL})
    AADD(aTit , {"E1_EMIS1"		, dDataBase								, NIL})
    AADD(aTit , {"E1_VALOR"  	, _nValor								, NIL})
    AADD(aTit , {"E1_HIST"  	, 'Titulo RA gerado por saldo da BLU'	, NIL})
    AADD(aTit , {"E1_SITUACA"	, "0"									, NIL})
    AADD(aTit , {"E1_SALDO"  	, _nValor								, NIL})
    AADD(aTit , {"E1_MOEDA"  	, _nMoeda								, NIL})
    AADD(aTit , {"E1_OCORREN"  	, '01'									, NIL})
    AADD(aTit , {"E1_VLCRUZ" 	, xMoeda(_nValor,_nMoeda,1)				, NIL})
    AADD(aTit , {"E1_STATUS" 	, "A"									, NIL})
    AADD(aTit , {"E1_OCORREN"	, "01"									, NIL})
    AADD(aTit , {"E1_ORIGEM" 	, _cOrigem								, NIL})
    AADD(aTit , {"E1_FATURA"	, "NOTFAT"								, NIL})
    AADD(aTit , {"E1_FLUXO"		, "S"									, NIL})
    AADD(aTit , {"E1_FILORIG"	, xFilial("SE1")						, NIL})

    //Inicia o controle de transação
    Begin Transaction

        //Chama a rotina automática
        lMsErroAuto := .F.                            
                                
        MSExecAuto({|x, y| FINA040(x, y)}, aTit, 3)

        //Se houve erro, mostra o erro ao usuário e desarma a transação
        If lMsErroAuto
            MostraErro()
            DisarmTransaction()
            lRet := .F.

        Else

            If ExistBlock("FA280")
                ExecBlock("FA280",.f.,.f.,nRegE1)
            Endif
            
            IF lPadrao
                If nHdlPrv <= 0
                    nHdlPrv:=HeadProva(cLote,"FINA280",Substr(cUsuario,7,6),@cArquivo)
                    lHead := .T.
                Endif

                If lUsaFlag  // Armazena em aFlagCTB para atualizar no modulo Contabil 
                    aAdd( aFlagCTB, {"E1_LA", "S", "SE1", SE1->( Recno() ), 0, 0, 0} )
                Else
                    RecLock("SE1")
                    SE1->E1_LA := "S"
                    MsUnlock()
                Endif
               // nTotal += DetProva( nHdlPrv, cPadrao, "FINA280", cLote, /*nLinha*/, /*lExecuta*/,;
               //                     /*cCriterio*/, /*lRateio*/, /*cChaveBusca*/, /*aCT5*/,;
               //                     /*lPosiciona*/, @aFlagCTB, /*aTabRecOri*/, /*aDadosProva*/ )
            Endif
            //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
            //³ Grava os lancamentos nas contas orcamentarias SIGAPCO    ³
            //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
            PcoDetLan("000014","01","FINA280")

            //Rastreamento - Gerados
            If lRastro
                aadd(aRastroDes,{	SE1->E1_FILIAL,;
                                        SE1->E1_PREFIXO,;
                                        SE1->E1_NUM,;
                                        SE1->E1_PARCELA,;
                                        SE1->E1_TIPO,;
                                        SE1->E1_CLIENTE,;
                                        SE1->E1_LOJA,;
                                        SE1->E1_VALOR } )
            Endif			

            
            //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
            //³Adiciona o titulo na aTitInc - Int. Protheus x Classis³
            //ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
            aAdd(aTitInc,SE1->(Recno()))

            //ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Se possui integração Protheus x Classis                ³
			//³replica os titulos criados para as tabelas do CorporeRm³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			If lRmClass .and. !lMsErroAuto
				For nX := 1 to len(aTitInc)		
					MsgRun(STR0078,,{||  ClsF280Inc(aTitInc[nX])}) //Replicando dados da integracao Protheus x Corpore
				Next Nx	
			Endif

            //Gravacao do rastreamento
            If lRastro
                FINRSTGRV(2,"SE1",aRastroOri,aRastroDes,nValProces) 
            Endif


        EndIf

    //Finaliza a transação
    End Transaction

Return lRet
