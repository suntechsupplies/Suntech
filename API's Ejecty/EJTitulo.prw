#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"

/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Douglas.Silva Feat Carlos Eduardo Saturnino and Antonio Ricardo de Araujo           *  
* Processa as informações e retorna o json                                                    *
* @since 	05/08/2019                                                                        *
* @version undefined                                                                          *
* @param oSelf, object, Objeto contendo dados da requisição efetuada pelo cliente, tais como: *
*    - Parâmetros querystring (parâmetros informado via URL)                                  *
*    - Objeto JSON caso o requisição seja efetuada via Request Post                           *
*    - Header da requisição                                                                   *
*    - entre outras ...                                                                       *
* @type Method                                                                                *
**********************************************************************************************/
#Define _Function	"Titulos"
#Define _DescFun	"RTitulo"
#Define Desc_Rest 	"Serviço REST para Disponibilizar  dados de Titulos" 
#Define Desc_Get  	"Retorna o cadastro de Titulos informado de acordo com os parametros passados" 
#Define Desc_Post	"Cria o cadastro de Titulos informado de acordo com data de atualização do cadastro"
#Define Desc_Put	"Baixa título que não está em borderô"

User function EJ_Titulo()

Return

WSRESTFUL EJTitulo DESCRIPTION Desc_Rest

	WSDATA nPag		As Integer
    WSDATA TENANTID AS String
	WSDATA cPrefixo AS String
	WSDATA cNumero  AS String    
	WSDATA cParcela AS String
	WSDATA cTipo    AS String
	
	WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/EJTitulo || /EJTitulo/{}"
	WSMETHOD PUT DESCRIPTION Desc_Put WSSYNTAX "/EJTitulo"	

END WSRESTFUL

WSMETHOD GET WSRECEIVE nPag HEADERPARAM TENANTID WSSERVICE EJTitulo
	
	Local aArea		:= GetArea()
	Local cAliasTMP	:= GetNextAlias()
	Local cSetResp	:= ''
	Local nPag		:= Self:nPag
	Local lRet		:= .T.
	Local nPagFim
	Local nX		

	// define o tipo de retorno do método
	::SetContentType("application/json")

    //**********************************************************************************
	// Efetua a preparação do ambiente 
	//**********************************************************************************
	/*
    If FindFunction("WfPrepEnv") //.And. cNumemp <> _cEmpresa + _cFilial 
		WfPrepEnv(_cEmpresa,_cFilial)
		cEmpant := _cEmpresa
		cFilant := _cFilial
		cNumEmp	:= _cEmpresa + _cFilial 
		Sleep(5000)
	Endif
    */

	If !Empty(SELF:TENANTID)
		_cEmpresa := Left(Upper(SELF:TENANTID), At(",",Upper(SELF:TENANTID))-1)
		_cFilial := Substr(Upper(SELF:TENANTID), At(",",Upper(SELF:TENANTID))+1)
	EndIf

	cEmpAnt := _cEmpresa
	cFilAnt := _cFilial

	// < Fim > -------------------------------------------------------------------------

	//Verifica se há conexão em aberto, caso haja feche.
	IF Select(cAliasTmp)>0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf

	//Select de cadastro
	BeginSQL Alias cAliasTmp

				SELECT 		((ROW_NUMBER() OVER (ORDER BY T.R_E_C_N_O_)) /100)+1	AS PAG,
							T.E1_FILIAL         			            	        AS CodFilial,
							T.E1_CLIENTE+T.E1_LOJA         			            	AS CodigoCliente,
							T.E1_PREFIXO											AS Prefixo,	
							T.E1_NUM					        				    AS NroDocumento,
							T.E1_PARCELA                                			AS NroParcela,
							T.E1_TIPO                                   			AS CodigoTipoDocumento,
							T.E1_EMISSAO                                			AS DataEmissao,
							T.E1_VENCREA                                			AS DataVencimento,
							T.E1_NUMBCO                                  			AS NroBoleto,
							T.E1_VALOR                                  			AS ValorOriginal,
							T.E1_SALDO                                  			AS SaldoTitulo,
							NULL                                        			AS NroNotaFiscal,
							E1_PORCJUR                                  			AS TaxaJuros,
							0	                                        			AS ValorPago,
							T.E1_NUMNOTA + T.E1_SERIE                      			AS CodigoEmpresaEsp,
							CASE WHEN COALESCE((T.E1_BAIXA), '        ') <> '        ' 
								THEN T.E1_BAIXA 
								ELSE NULL 
							END  													AS DataPago,
							T.E1_VEND1                                  			AS CodigoVendedorEsp,
							CASE WHEN D_E_L_E_T_ =  '* ' 
								THEN '*'
								ELSE NULL 
							END AS DELETED
				FROM 		%Table:SE1% T
				WHERE 		T.E1_ZSTATUS <> '9' 
				ORDER BY	T.R_E_C_N_O_

	EndSql

	dbSelectArea(cAliasTmp)
	(cAliasTmp)->( DbGoTop() )

	While (cAliasTmp)->( !Eof() )
		nPagFim := (cAliasTmp)->PAG
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->( DbGoTop() )

	If (cAliasTmp)->( Eof() )

		cSetResp := '{"TE_TITULO": [ "Retorno":"Nao Existe Itens Nessa Pagina" ] } '
		lRet	 := .F.

	Else

		(cAliasTMP)->( DbGoTop() )
		nX		:= 1

		//Inicio do retorno em JSON
		cSetResp  := '{ "TE_TITULO":[ '

		While (cAliasTMP)->( !Eof() )

			If (cAliasTMP)->PAG == nPag

				If nX > 1
					cSetResp  +=' , '
				EndIf
				cSetResp  += '{'
				cSetResp  += ' "CodFilial":"'		    + ALLTRIM((cAliasTMP)->CodFilial)
				cSetResp  += '","CodigoCliente":"'		+ ALLTRIM((cAliasTMP)->CodigoCliente)
				cSetResp  += '","Prefixo":"'		    + (cAliasTMP)->Prefixo
				cSetResp  += '","NroDocumento":"'		+ (cAliasTMP)->NroDocumento
				cSetResp  += '","NroParcela":"'			+ (cAliasTMP)->NroParcela
				cSetResp  += '","CodigoTipoDocumento":"'+ ALLTRIM((cAliasTMP)->CodigoTipoDocumento)
				cSetResp  += '","DataEmissao":"'		+ ALLTRIM((cAliasTMP)->DataEmissao)
				cSetResp  += '","DataVencimento":"'		+ ALLTRIM((cAliasTMP)->DataVencimento)
				cSetResp  += '","ValorOriginal":'		+ ALLTRIM(cValToChar((cAliasTMP)->ValorOriginal))
				cSetResp  += ',"SaldoTitulo":'			+ ALLTRIM(cValToChar((cAliasTMP)->SaldoTitulo))
				cSetResp  += ',"NroNotaFiscal":"'		+ ALLTRIM((cAliasTMP)->NroNotaFiscal)
				cSetResp  += '","TaxaJuros":'			+ ALLTRIM(cValToChar((cAliasTMP)->TaxaJuros))
				cSetResp  += ',"NroBoleto":"'			+ ALLTRIM(cValToChar((cAliasTMP)->NroBoleto))
				cSetResp  += '","ValorPago":'			+ ALLTRIM(cValToChar((cAliasTMP)->ValorPago))
				cSetResp  += ',"CodigoEmpresaEsp":"'	+ ALLTRIM((cAliasTMP)->CodigoEmpresaEsp)
				cSetResp  += '","DataPago":"'			+ ALLTRIM((cAliasTMP)->DataPago)
				cSetResp  += '","CodigoVendedorEsp":"'	+ ALLTRIM((cAliasTMP)->CodigoVendedorEsp)
				cSetResp  += '","DELETED":"'	        + ALLTRIM((cAliasTMP)->DELETED)
				cSetResp  += '"}'
				(cAliasTmp)->(dbSkip())
				nX++
			Else
				(cAliasTmp)->(dbSkip())
				LOOP
			Endif
		EndDo

		If lRet
			cSetResp  += ']'
			cSetResp  += ',"PaginalAtual":'				+ STR(Self:nPag)
			cSetResp  += ',"TotalDePaginas":'			+ STR(nPagFim)
			cSetResp  += '}'
		Endif

	EndIf

	//Fecha a tabela
	(cAliasTMP)->(DbCloseArea())

	//Envia o JSON Gerado para a aplicação
	::SetResponse( cSetResp )

	RestArea(aArea)

Return(.T.)

WSMETHOD PUT WSRECEIVE cPrefixo, cNumero, cParcela, cTipo HEADERPARAM TENANTID WSSERVICE EJTitulo

	Local cMessage   := ''
	Local cFullMessage := ''
	Local cArqLog 	 := ''
	Local cError     := ''
	Local cJSON      := Self:GetContent() 							   // –> Pega a string do JSON
	Local cPrefixo   := PAD(Self:cPrefixo,TAMSX3('E1_PREFIXO')[1])     // –> Pega o parâmetro recebido pela URL
	Local cNumero    := PAD(Self:cNumero ,TAMSX3('E1_NUM')[1])         // –> Pega o parâmetro recebido pela URL
	Local cParcela   := PAD(Self:cParcela,TAMSX3('E1_PARCELA')[1])     // –> Pega o parâmetro recebido pela URL
	Local cTipo      := PAD(Self:cTipo   ,TAMSX3('E1_TIPO')[1])        // –> Pega o parâmetro recebido pela URL
	Local cCliFor	 := ''
	Local cLoja	     := ''
	Local cBanco	 := '323'
	Local cAgencia	 := '00001'
	Local cConta	 := '1234567   '
	Local cNatureza  := ''
	Local cId   	 := ''
	Local cIdTrans   := ''
	Local cStatus    := ''
	Local dDataBaixa := Date()
	Local aBaixa     := {}
	Local aTables    := {"SC5","SE1","SE5"}
	Local aFINA100   := {}
	Local nOpc 		 := 0 
	Local lRet       := .T.
	Local oTitulo	 := Nil
	Local nValor     := 0
	Local nShippingCost := 0
	Local nDescont   := 0
	Local nTarifa    := 0
	Local nTarifaAcum:= 0
	Local cMotBx     := ''
	Local cBenef     := ''
	Local cHistor    := ''
	Local nVlSaldo   := 0
	Local nPercentual:= 0     							                //–> Array para ExecAuto do MATA030
	Local nX		 := 0
	Local nY		 := 0
	Local nZ         := 0
	Local aArea 	 := GetArea()

	Private lMsErroAuto := .F.

	If !Empty(SELF:TENANTID)
		_cEmpresa := Left(Upper(SELF:TENANTID), At(",",Upper(SELF:TENANTID))-1)
		_cFilial := Substr(Upper(SELF:TENANTID), At(",",Upper(SELF:TENANTID))+1)
	EndIf

	cEmpAnt := _cEmpresa
	cFilAnt := _cFilial	

	//PREPARE ENVIRONMENT EMPRESA '01' FILIAL cEmpresa TABLES 'SE1,SE5' MODULO 'FIN'
	RpcSetEnv(cEmpAnt, cFilAnt,,,,GetEnvServer(),aTables)

	If !ExistDir("\log_api")
		MakeDir("\log_api")
	EndIf

	::SetContentType("application/json")

	// –> Deserializa a string JSON
	FWJsonDeserialize(cJson, @oTitulo)

	For nZ :=1 to Len(oTitulo)

		dbSelectArea("SE1")
		SE1->(DbSetOrder(1))
		lAchou := SE1->(DbSeek(cFilAnt+cPrefixo+cNumero+cParcela+cTipo))

		nValor  := oTitulo[nZ]:results[1]:transaction_amount
		cStatus := oTitulo[nZ]:results[1]:money_release_status
		cIdTrans:= cValToChar(oTitulo[nZ]:results[1]:id)
		
		cCliFor := SE1->E1_CLIENTE
		cLoja   := SE1->E1_LOJA

		dbSelectArea("SC5") 
		SC5->(DbSetOrder(1))

		If SC5->(DbSeek(cFilAnt+SE1->E1_PEDIDO)) .AND. TRIM(SE1->E1_PEDECOM) == ''
			Reclock("SE1",.F.)
				SE1->E1_PEDECOM := SC5->C5_PEDECOM
				SE1->E1_ZZPAYID := cIdTrans
				SE1->E1_ZZSTPAY := cStatus				
				SE1->E1_VENCREA := FwDateTimeToLocal(oTitulo[nZ]:results[1]:money_release_date)[1]
				SE1->E1_VENCTO  := FwDateTimeToLocal(oTitulo[nZ]:results[1]:money_release_date)[1]  

				If SE1->E1_EMISSAO > FwDateTimeToLocal(oTitulo[nZ]:results[1]:money_release_date)[1]
					SE1->E1_EMISSAO := FwDateTimeToLocal(oTitulo[nZ]:results[1]:money_release_date)[1] 
				EndIf

			SE1->(MsUnlock()) 
		Endif

		If lAchou .AND. SE1->E1_SALDO > 0		

			If cStatus  = 'released'

				If len(oTitulo[nZ]:results[1]:charges_details) == 0
					nValor := oTitulo[nZ]:results[1]:transaction_details:total_paid_amount	
				Elseif oTitulo[nZ]:results[1]:charges_details[1]:accounts:from == 'ml' .AND. oTitulo[nZ]:results[1]:charges_details[1]:accounts:to == 'payer'
					nValor := nValor - oTitulo[nZ]:results[1]:charges_details[1]:amounts:original
				EndIf

				dDataBaixa := FwDateTimeToLocal(oTitulo[nZ]:results[1]:money_release_date)[1]

				aBaixa := { {"E1_FILIAL"   , cFilAnt            ,Nil    },;
							{"E1_PREFIXO"  , cPrefixo           ,Nil    },;
							{"E1_NUM"      , cNumero            ,Nil    },;
							{"E1_TIPO"     , cTipo              ,Nil    },;
							{"E1_NATUREZ"  , cNatureza          ,Nil    },;
							{"AUTMOTBX"    ,"NOR"               ,Nil    },;
							{"AUTBANCO"    , cBanco             ,Nil    },;
							{"AUTAGENCIA"  , cAgencia           ,Nil    },;
							{"AUTCONTA"    , cConta             ,Nil    },;
							{"AUTDTBAIXA"  , dDataBaixa         ,Nil    },;
							{"AUTDTCREDITO", dDataBaixa         ,Nil    },;
							{"AUTHIST"     ,"VENDA B2C"         ,Nil    },;
							{"AUTDESCONT"  , nDescont           ,Nil,.T.},;
							{"AUTJUROS"    , 0                  ,Nil,.T.},;
							{"AUTVALREC"   , nValor             ,Nil    }}

				MSExecAuto({|x,y| Fina070(x,y)},aBaixa,3)  // rotina padrão de baixa de títulos.

				DbSelectArea("SE5") 
				SE5->(DbSetOrder (7))

				If SE5->(DbSeek(xFilial("SE5")+cPrefixo+cNumero+cParcela+cTipo+cCliFor+cLoja))
					RecLock("SE5", .F. )
						SE5->E5_DOCUMEN := cIdTrans
					SE5->(MsUnlock()) 
				EndIf

				If SE1->E1_BAIXA <> Nil
					Reclock("SE1",.F.)
						SE1->E1_ZZSTPAY := 'released' 
					SE1->(MsUnlock()) 
				Endif

				If lMsErroAuto

					cError := FwNoAccent(MostraErro("\api_log", cArqLog))
					cBuffer  := ""
					nErrLin  := 1

					For nX := 1 To mlcount(cError)
						cBuffer := RTrim(MemoLine(cError,, nX,, .F.))

						If AllTrim(UPPER(SUBSTR(cBuffer, 1, 17))) == "MENSAGEM DO ERRO:"
							cError := StrTran(SubStr(cBuffer, AT("[",cBuffer)+1, 100),"]","")							
						ElseIf "< -- Invalido" $ cBuffer
							cError := ALLTRIM(StrTran(StrTran(StrTran(StrTran(StrTran(StrTran(cBuffer,CHR(10)," "),"     ", " " ),CHR(13), ""), " < -- ", " "),"   :=", " "), "/",""))
						ElseIf AllTrim(UPPER(SUBSTR(cBuffer, 1, 6))) == "AJUDA:"
							cError := StrTran(StrTran(cBuffer, CHR(10), ""), "     "," ")
						EndIf

					Next nX

					cMessage := '{ "code": 400, '
					cMessage += ' "message" : "' + cError + '",'
					cMessage += ' "filial" : "' + cFilAnt + '"'
					lRet := .F.

				Else

					cMessage := '{ "code": 200, '
					cMessage += ' "message": "Titulo ' + _cFilial + cPrefixo + cNumero + cParcela + cTipo + ' baixado com sucesso!",'
					cMessage += ' "filial" : "' + cFilAnt + '"'
					lRet := .T.

				EndIf 

			Else

				cMessage := '{ "code": 401, '
				cMessage += ' "message": "Valor do titulo ainda nao esta disponivel.",'
				cMessage += ' "filial" : "' + cFilAnt + '"'				
				lRet := .F.

			Endif

		Else

			cMessage := '{ "code" : 402, '
			cMessage += ' "message" : "Titulo ' + _cFilial + cPrefixo + cNumero + cParcela + cTipo + ' nao encontrado ou ja baixado.",'
			cMessage += ' "filial" : "' + cFilAnt + '"'	
			lRet := .F.

		EndIf	

		If lRet

			//nCustoEnvio := nValor - oTitulo:results[1]:transaction_details:net_received_amount

			cMessage += ' ,"details": [ '

			For nY := 1 To (Len(oTitulo[nZ]:results[1]:charges_details))

				aFINA100   := {}
					
				If oTitulo[nZ]:results[1]:charges_details[nY]:accounts:from == 'collector'
					
					if oTitulo[nZ]:results[1]:charges_details[nY]:type == 'shipping' .AND. AttIsMemberOf(oTitulo[nZ]:results[1] , 'shipping_cost') .AND. ValType(oTitulo[nZ]:results[1]:shipping_cost) == 'N'

						nShippingCost := oTitulo[nZ]:results[1]:shipping_cost
						nTarifa       := oTitulo[nZ]:results[1]:charges_details[nY]:amounts:original - nShippingCost
							
					else

						nShippingCost := 0
						nTarifa       := oTitulo[nZ]:results[1]:charges_details[nY]:amounts:original
					EndIf

					nOpc     := 3
					cMotBx   := 'DEB' 
					cBenef   := 'TARIFA MP'
					cHistor  := 'TARIFA MP' 				

				ElseIf oTitulo[nZ]:results[1]:charges_details[nY]:accounts:from == 'ml' .AND. oTitulo[nZ]:results[1]:charges_details[nY]:type == 'coupon'

					nOpc     := 4
					cMotBx   := 'NOR'
					cBenef   := 'REC DESC CONTRAPARTE ML'
					cHistor  := 'REC DESC CONTRAPARTE ML'
					nTarifa  := oTitulo[nZ]:results[1]:charges_details[nY]:amounts:original 				
				
				ElseIf oTitulo[nZ]:results[1]:charges_details[nY]:accounts:from == 'payer' .AND. oTitulo[nZ]:results[1]:charges_details[nY]:type == 'fee'

					nOpc     := 4
					cMotBx   := 'NOR'
					cBenef   := 'ACRESCIMO NO PREÇO ML'
					cHistor  := 'ACRESCIMO NO PREÇO ML'
					nTarifa  := oTitulo[nZ]:results[1]:charges_details[nY]:amounts:original 				

				Else
					cMessage += '{"code" : 401, ' 
					cMessage += ' "filial" : "' + cFilAnt + '",'
					cMessage += '"message": "Tarifa por conta do comprador."},'
					lRet     := .F.
					nOpc     := 0

				EndIf

				nTarifaAcum := nTarifaAcum + nTarifa
				nVlSaldo    := nValor - nTarifaAcum
				nPercentual := (nTarifa/nValor)*100

				If nOpc <> 0
					cNatureza := GetNatureza(oTitulo[nZ]:results[1]:charges_details[nY]:name)
					cId       := oTitulo[nZ]:results[1]:charges_details[nY]:id
					lAchou    := GetTarifas(cId)
				EndIf


				If (nOpc == 3 .OR. nOpc == 4) .AND. !lAchou

				dDataBaixa := FwDateTimeToLocal(oTitulo[nZ]:results[1]:money_release_date)[1]

					BEGIN TRANSACTION

						aAdd(aFINA100, {"E5_NUMERO"      , cNumero      , Nil})
						aAdd(aFINA100, {"E5_PREFIXO"     , cPrefixo     , Nil})
						aAdd(aFINA100, {"E5_PARCELA"     , cParcela     , Nil})
						aAdd(aFINA100, {"E5_TIPO"        , cTipo        , Nil})
						aAdd(aFINA100, {"E5_DATA"        , dDataBaixa   , Nil})
						aAdd(aFINA100, {"E5_MOTBX"       , cMotBx       , Nil})
						aAdd(aFINA100, {"E5_MOEDA"       , "M1"         , Nil})
						aAdd(aFINA100, {"E5_VALOR"       , nTarifa      , Nil})
						aAdd(aFINA100, {"E5_NATUREZ"     , cNatureza    , Nil})
						aAdd(aFINA100, {"E5_BANCO"       , cBanco       , Nil})
						aAdd(aFINA100, {"E5_AGENCIA"     , cAgencia     , Nil})
						aAdd(aFINA100, {"E5_CONTA"       , cConta       , Nil})
						aAdd(aFINA100, {"E5_VENCTO"      , dDataBaixa   , Nil})
						aAdd(aFINA100, {"E5_BENEF"       , cBenef       , Nil})
						aAdd(aFINA100, {"E5_HISTOR"      , cHistor      , Nil})
						aAdd(aFINA100, {"E5_DOCUMEN"     , cId          , Nil})
						aAdd(aFINA100, {"NCTBONLINE"     , 2            , Nil})
									
						MSExecAuto({|x,y,z| FinA100(x,y,z)},0,aFINA100,nOpc)
						
						If lMsErroAuto

							DisarmTransaction()

							cError := FwNoAccent(MostraErro("\api_log", cArqLog))
							cBuffer  := ""
							nErrLin  := 1

							For nX := 1 To mlcount(cError)
								cBuffer := RTrim(MemoLine(cError,, nX,, .F.))

								If AllTrim(UPPER(SUBSTR(cBuffer, 1, 17))) == "MENSAGEM DO ERRO:"
									cError := STRTRAN(SUBSTR(cBuffer, AT("[",cBuffer)+1, 100),"]","")
								ElseIf "< -- Invalido" $ cBuffer
									cError := ALLTRIM(StrTran(StrTran(StrTran(StrTran(StrTran(StrTran(cBuffer,CHR(10)," "),"     ", " " ),CHR(13), ""), " < -- ", " "),"   :=", " "), "/",""))	
								EndIf

							Next nX

							cMessage += '{"code": 400, ' 
							cMessage += ' "filial" : "' + cFilAnt + '",'
							cMessage += '"message": "' + cError + '"}'
								

							lRet     := .F.

						Else

							cMessage += '{"code": 200, ' 
							cMessage += ' "filial" : "' + cFilAnt + '",'
							cMessage += '"message": "Tarifa ' + cId + ' lancada com sucesso!"}'
							lRet     := .F.

						EndIf

					END TRANSACTION      
					
				Else
					cMessage += '{"code" : 402, ' 
					cMessage += ' "filial" : "' + cFilAnt + '",'
					cMessage += '"message": "Tarifa ' + cId + ' ja lancada."}'
					lRet     := .F.		
				Endif
			
				If nY < (Len(oTitulo[nZ]:results[1]:charges_details))
					cMessage += ','
				Endif

			Next nY 

			cMessage += ']}'
		Else

			cMessage += '}'

		EndIf

		If nZ < Len(oTitulo)
			cMessage += ','
		Endif
		
		cFullMessage +=	cMessage

	Next nZ
	
	cFullMessage :=	'[' + cFullMessage + ']'

	::SetResponse(cFullMessage) 

	//-------------------------------------------------------------------
	// Restauro a area de trabalho
	//-------------------------------------------------------------------
	SC5->(DBCloseArea())
	SE5->(DBCloseArea())
	SE1->(DBCloseArea())
	RpcClearEnv() //Encerra o ambiente, fechando as devidas conexões	
	//RESET ENVIRONMENT
	RestArea(aArea)


Return(lRet)

Static Function GetNatureza(cName)

	Local aArea		:= GetArea()
	Local cAliasTMP	:= GetNextAlias()
	Local cNatureza := "" // Inicializa cNatureza

	//Verifica se há conexão em aberto, caso haja feche.	
	IF Select(cAliasTmp) > 0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf

	cQuery := " SELECT SED.ED_CODIGO, SED.ED_ZZDESGT "
	cQuery += " FROM "+ RetSqlName('SED') + " SED "
	cQuery += " WHERE SED.ED_ZZDESGT <> '' "
	cQuery += " AND SED.ED_ZZDESGT = '" + Upper(cName) + "'"
	cQuery += " AND SED.D_E_L_E_T_ = '' "
	
	dbUseArea(.T.,'TOPCONN',TcGenQry(,,cQuery), cAliasTMP,.T.,.T.)

	dbSelectArea(cAliasTmp)
	(cAliasTmp)->( DbGoTop() )

	While (cAliasTmp)->(!Eof())
		cNatureza := (cAliasTmp)->ED_CODIGO
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->(dbCloseArea())
	RestArea(aArea)

Return(cNatureza)

Static Function GetTarifas(cId)

	Local aArea		:= GetArea()
	Local cAliasTMP	:= GetNextAlias()
	Local lRet      := .F.

	//Verifica se há conexão em aberto, caso haja feche.	
	IF Select(cAliasTmp) > 0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf

	cQuery := " SELECT SE5.E5_FILIAL, SE5.E5_DOCUMEN, SE5.E5_PREFIXO, SE5.E5_NUMERO, SE5.E5_PARCELA, SE5.E5_DTDIGIT, SE5.E5_RECPAG "
	cQuery += " FROM "+ RetSqlName('SE5') + " SE5 "
	cQuery += " WHERE SE5.E5_DOCUMEN = '" + cid + "'"
	cQuery += " AND SE5.E5_SITUACA = ''"
	cQuery += " AND SE5.D_E_L_E_T_ = ''"
	
	dbUseArea(.T.,'TOPCONN',TcGenQry(,,cQuery), cAliasTMP,.T.,.T.)

	dbSelectArea(cAliasTmp)
	(cAliasTmp)->(DbGoTop())

	While (cAliasTmp)->(!Eof())
		lRet := .T.
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->(dbCloseArea())
	RestArea(aArea)

Return(lRet)
