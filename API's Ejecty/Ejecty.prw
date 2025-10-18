#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "Totvs.ch"

#Define Desc_Rest 	"Serviço REST para Disponibilizar métodos para serviços da Ejecty"

/*--------------------------------------------------------------------------------------------------------------
{Protheus.doc} 	WsRestFul Ejecty
TODO 			Metodo WSRestFul Ejecty
@since 			19/08/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			WsMethod Rest
--------------------------------------------------------------------------------------------------------------*/
WSRESTFUL ejecty DESCRIPTION Desc_Rest

	//--------------------------------------------------------------------------------------------------------------
    //{protocolo}://{host}/{api}/{agrupador}/{dominio}/{versao}/{recurso}". 
    //Ex: https://fluig.totvs.com/api/ecm/security/v1/users.
    //--------------------------------------------------------------------------------------------------------------
	WSMETHOD POST invoice										;
	DESCRIPTION "Inclusão de Pedido de Vendas Ejecty"   		;
	WSSYNTAX    "api/fat/ejecty/v2.0/invoice"					;
	PATH        "api/fat/ejecty/v2.0/invoice"		

END WSRESTFUL

/*------------------------------------------------------------------
{Protheus.doc} 	Método Post Invoice
TODO 			Inclui Pedido de Vendas
@since 			29/10/2021
@version 		1.0
@type 			WsMethod Rest
------------------------------------------------------------------*/
WSMETHOD POST invoice WSRECEIVE  WSSERVICE ejecty

	Local oResponse 				as object
	Local oContent   				as object
	Local _nW, _nX, _nY, _nZ 		as numeric
	Local aArea						:= {}
	Local aDadosC5					:= {}
	Local aDadosC6					:= {}
	Local aLin						:= {}
	Local aLogAuto					:= {}
	Local cArqLog					:= ''
	Local cError					:= ''
 	Local nError					:= 0
 	Local _nOpc						:= 3
 	Local _cPedB2B					:= ''
 	Local _cNumPed					:= ''
 	Local _aErro					:= {}
 	Local _lSegue					:= .F.
	Local _cEmpresa					:= "01"
	Local _cFilial					:= "01"
	Local aTabs						:= {}

 	Private lMsErroAuto			:= .F.
 	Private lMsHelpAuto			:= .T.
 	Private lAutoErrNoFile		:= .T.



	If FindFunction("WfPrepEnv")

		//*****************************************************************
		// Cofigura empresa/filial
		//*****************************************************************
		RpcSetEnv( _cEmpresa,_cFilial,,, "POST", "METHOD", aTabs,,,,)
		cEmpant := _cEmpresa
		cFilant := _cFilial
		cNumEmp	:= _cEmpresa + _cFilial 

		//*****************************************************************
		// Enquanto nao configura empresa e filial fica dentro
		// do "laco" verificando
		//*****************************************************************
		While ! _lSegue
			If _cEmpresa + _cFilial == cNumEmp
				_lSegue := .T.
			Endif
		End
	Endif

	//Cria o diretório para salvar os arquivos de log
	If !ExistDir("\log_B2B")
		MakeDir("\log_B2B")
	EndIf

	Self:SetContentType("application/json")


	//******************************************************************************
	// Verifica se o body veio no formato JSon.
	//******************************************************************************
	If lower(Self:GetHeader("Content-Type", .F.)) == "application/json"

		oContent := JsonObject():New()
		oContent:FromJson(Self:GetContent())  // Transforma o JSON do body em um objeto JSON Protheus.


		//******************************************************************************
		// Se tudo certo, grava o arquivo no servidor e seus registros correspondentes.
		//******************************************************************************
		If ValType(oContent) == "J"


			Begin Transaction

				//**********************************************************************************
				// Efetua o travamento do registro no Licence Server
				//**********************************************************************************
				If !LockByName("EjPVPost",.F.,.F.)
					Conout( '[EjPVPost - Post Json] Thread ['+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] ['+_cProcesso+'] - está em execução por outro processamento.')
				endif

				//**********************************************************************************
				// Cria o Objeto de Retorno das informacoes
				//**********************************************************************************
				oResponse := JsonObject():New()
				//oResponse["Data"] 		:= oContent["CABECALHO"][1]["C5_ZZDTEMI"]
				oResponse["Resultados"]	:= {}

				//**********************************************************************************
				// Preenche o Array do Cabecalho do Pedido de Vendas
				//**********************************************************************************
				For _nZ := 1 To Len(oContent["CABECALHO"])

					//**********************************************************************************
					// Popula a Tag de Data do Pedido 
					//**********************************************************************************
					oResponse["Data"] 		:= oContent["CABECALHO"][_nZ]["C5_ZZDTEMI"]					
					
					//***************************************************************************************
					// Guardo empresa e filial para passar para Prepare Environment e Consultar Pedido AFV
					//***************************************************************************************
					_cEmpresa 	:= oContent["CABECALHO"][_nZ]["EMPRESA"]
					_cFilial	:= oContent["CABECALHO"][_nZ]["C5_FILIAL"]
					_cPedB2B	:= oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]

					//**********************************************************************************
					// Salva a area atual
					//**********************************************************************************
					aArea := GetArea()

					//**********************************************************************************
					// Efetua a preparação do ambiente e a inclusao do Pedido de Vendas via MsExecAuto
					//**********************************************************************************
					If isBlind() .And. _cEmpresa + _cFilial <> cNumemp
						
						wFPrepEnv(_cEmpresa,_cFilial,,{"SM0","SC5","SC6","SA1","SA2","SB1","SB2","SE4","SF4"})
						cEmpant := _cEmpresa
						cFilant := _cFilial
						Sleep(2000)

						While ! _lSegue
							If _cEmpresa + _cFilial == cNumEmp
								_lSegue := .T.
							Endif
						End
					Endif

					conout("Empresa : " + cEmpant + " Filial : " + cFilant + " Numero da Empresa : " +cNumemp + " conectada com sucesso !!! " )

					//**********************************************************************************
					// Preparo a Variavel _lSegue para o proximo registro
					//**********************************************************************************
					_lSegue := .F.
					
					//**********************************************************************************
					// Preenche o Array do Cabecalho do Pedido de Vendas
					//**********************************************************************************
					aAdd(aDadosC5, {"C5_TIPO"	 		,oContent["CABECALHO"][_nZ]["C5_TIPO"]	 				, Nil})
					aAdd(aDadosC5, {"C5_CLIENTE" 		,oContent["CABECALHO"][_nZ]["C5_CLIENTE"]				, Nil})
					aAdd(aDadosC5, {"C5_LOJACLI" 		,oContent["CABECALHO"][_nZ]["C5_LOJACLI"]				, Nil})
					aAdd(aDadosC5, {"C5_EMISSAO" 		,StoD(oContent["CABECALHO"][_nZ]["C5_EMISSAO"])			, Nil})
					aAdd(aDadosC5, {"C5_CONDPAG" 		,oContent["CABECALHO"][_nZ]["C5_CONDPAG"]				, Nil})
					aAdd(aDadosC5, {"C5_TPFRETE" 		,oContent["CABECALHO"][_nZ]["C5_TPFRETE"] 				, Nil})
					aAdd(aDadosC5, {"C5_MENNOTA" 		,oContent["CABECALHO"][_nZ]["C5_MENNOTA"] 				, Nil})
					aAdd(aDadosC5, {"C5_ZZOBS" 			,oContent["CABECALHO"][_nZ]["C5_ZZOBS"] 				, Nil})
					aAdd(aDadosC5, {"C5_VEND1" 			,oContent["CABECALHO"][_nZ]["C5_VEND1"]					, Nil})
					aAdd(aDadosC5, {"C5_DESC1" 			,oContent["CABECALHO"][_nZ]["C5_DESC1"]					, Nil})
					aAdd(aDadosC5, {"C5_TABELA" 		,oContent["CABECALHO"][_nZ]["C5_TABELA"]				, Nil})
					aAdd(aDadosC5, {"C5_ZZNPEXT" 		,oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]				, Nil})
					aAdd(aDadosC5, {"C5_ZZTPPED" 		,oContent["CABECALHO"][_nZ]["C5_ZZTPPED"]				, Nil})
					aAdd(aDadosC5, {"C5_ZZDTEMI" 		,Stod(oContent["CABECALHO"][_nZ]["C5_ZZDTEMI"])			, Nil})
					aAdd(aDadosC5, {"C5_ZZCUPOM" 		,oContent["CABECALHO"][_nZ]["C5_ZZCUPOM"]				, Nil})
					aAdd(aDadosC5, {"C5_ZZORIGE" 		,"B2B"													, Nil})
					aAdd(aDadosC5, {"C5_MOEDA" 			,oContent["CABECALHO"][_nZ]["C5_MOEDA"]					, Nil})		// Incluido em 06/08/2021 por erro na API
					aAdd(aDadosC5, {"C5_FRETE" 			,oContent["CABECALHO"][_nZ]["C5_FRETE"]					, Nil})		// Incluido em 31/08/2020 a pedido do Marcos/Michael

					FWVetByDic( aDadosC5, 'SC5' )

					//**********************************************************************************
					// Preenche o Array dos Itens do Pedido de Vendas
					//**********************************************************************************
					For _nX := 1 to Len(oContent["CABECALHO"][_nZ]["ITENS"])

						aLin := {}
						aAdd(aLin, {"C6_ITEM"		,oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_ITEM"]	, Nil})
						aAdd(aLin, {"C6_PRODUTO" 	,oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_PRODUTO"]	, Nil})
						aAdd(aLin, {"C6_QTDVEN" 	,oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_QTDVEN"]	, Nil})
						aAdd(aLin, {"C6_PRCVEN" 	,oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_PRCVEN"]	, Nil})
						aAdd(aLin, {"C6_OPER" 		,oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_OPER"] 	, Nil})
						aAdd(aLin, {"C6_DESCONT" 	,oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_DESCONT"]	, Nil})

						FWVetByDic( aLin, 'SC6' )	
						aAdd(aLin, {"AUTDELETA"	,"N"														, Nil})
						aAdd(aDadosC6,aLin)

					Next _nX



					//**********************************************************************************
					// Efetua o posicionamento das tabelas para  a inclusao do Pedido de Vendas
					//**********************************************************************************
					SC6->(dbSelectArea("SC6"))
					SC6->(dbSetOrder(1))
					SC6->(dbGoTop())
					SA1->(dbSelectArea("SA1"))
					SA1->(dbSetOrder(1))
					SA1->(dbGoTop())
					SA2->(dbSelectArea("SA2"))
					SA2->(dbSetOrder(1))
					SA2->(dbGoTop())
					SB1->(dbSelectArea("SB1"))
					SB1->(dbSetOrder(1))
					SB1->(dbGoTop())
					SB2->(dbSelectArea("SB2"))
					SB2->(dbSetOrder(1))
					SB2->(dbGoTop())
					SE4->(dbSelectArea("SE4"))
					SE4->(dbSetOrder(1))
					SE4->(dbGoTop())
					SF4->(dbSelectArea("SF4"))
					SF4->(dbSetOrder(1))
					SF4->(dbGoTop())
					SC5->(dbSelectArea("SC5"))
					SC5->(dbSetOrder(10))
					SC5->(dbGoTop())
					
					//**********************************************************************************
					// Pesquiso o Pedido AFV para identificar se e inclusão ou alteracao
					//**********************************************************************************
					If SC5->(dbSeek( FwFilial("SC5") + PADR(_cPedB2B,10)))
						_nOpc 	:= 4				// Altera
						_cNumPed:= SC5->C5_NUM
					Else
						_nOpc := 3					// Inclui
					Endif

					//**********************************************************************************
					// Restauro o indice da Tabela SC5
					//**********************************************************************************
					SC5->(dbSetOrder(1))
					SC5->(dbGoTop())

					//**********************************************************************************
					// Efetua a inclusao do Pedido de Vendas via MsExecAuto
					//**********************************************************************************
					MSExecAuto({| w, x, y, z|MATA410(w,x,y,z)}, aDadosC5, aDadosC6 ,_nOpc, .F. )

					//******************************************************************************
					// Em caso de erro de ExecAuto
					//******************************************************************************
					If lMsErroAuto

						//******************************************************************************
						// Efetua o Rollback do Numero do Pedido
						//******************************************************************************
						DisarmTransaction()

						//******************************************************************************
						// Grava o Error.log na pasta System\log_ped
						//******************************************************************************
						aLogAuto:= GetAutoGrLog()

						//******************************************************************************
						// Efetua o tratamento da mensagem de erro, retirando CLRF
						//******************************************************************************
						For _nY := 1 to Len(aLogAuto)
							cError 	+= aLogAuto[_nY] + CHR(13)+CHR(10)
						Next _nY

						cArqLog	:= "\log_B2B\" + oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"] + " - " +Time()+ ".log"
						MemoWrite(cArqLog, cError)

						//******************************************************************************
						// Monta o Json de Retorno com erro
						//******************************************************************************
						oJsonRet := JsonObject():New()

						oJsonRet["SUCESSMESSAGE"]	:= EncodeUTF8(IIF(_nOpc == 3 ,"Pedido de Vendas não Incluído","Pedido de Vendas não Alterado"))
						oJsonRet["LOJA"]			:= oContent["CABECALHO"][_nZ]["C5_LOJACLI"]
						oJsonRet["EMPRESA"]			:= oContent["CABECALHO"][_nZ]["EMPRESA"]
						oJsonRet["PEDIDOB2B"]		:= oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]
						oJsonRet["PEDIDOPROTHEUS"]	:= _cNumPed
						oJsonRet["FILIAL"]         	:= oContent["CABECALHO"][_nZ]["C5_FILIAL"]
						oJsonRet["CLIENTE"]			:= oContent["CABECALHO"][_nZ]["C5_CLIENTE"]
						oJsonRet["OPCAO"]			:= EncodeUTF8(IIF(_nOpc == 3, "3 - Inclusão", "4 - Alteração"))
						oJsonRet["SUCESSCODE"]     	:= 202  // 202 - Código padrão HTML de POST recebido, porem nao processado
						//oJsonRet["ARQLOG"]			:= StrTran(EncodeUTF8(cError),'\r\n',CHR(13)+CHR(10))
						For _nW :=1 to Len(aLogAuto)
							Aadd(_aErro,JsonObject():new())
							_aErro[_nW]['LINHA_'+ StrTran(Str(_nW),' ','')] := StrTran(EncodeUTF8(aLogAuto[_nW]),'\r\n','')
						Next
						oJsonRet["ARQLOG"]			:= _aErro
						aAdd(oResponse["Resultados"], oJsonRet)

					Else

						//******************************************************************************
						// Confirma o Numero do Pedido de Vendas em caso de inclusão
						//******************************************************************************
						If _nOpc = 3
							ConfirmSX8()
						Endif

						//******************************************************************************
						// Posiciona em cima do Cabec. do Pedido de Vendas e recupero o Num. do mesmo
						//******************************************************************************
						SC5->(dbSelectArea("SC5"))
						SC5->(dbSetOrder(10))
						SC5->(dbGoTop())
						If SC5->( dbSeek( PADR(_cFilial,2) + PADR(_cPedB2B,10)) )
							_cNumPed:= SC5->C5_NUM
						Endif

						//******************************************************************************
						// Monta o Json de Retorno realizado com sucesso
						//******************************************************************************
						oJsonRet := JsonObject():New()
						oJsonRet["SUCESSMESSAGE"]  	:= EncodeUTF8(IIF(_nOpc == 3 ,"Pedido de Vendas B2B incluído com sucesso","Pedido de Vendas B2B alterado com sucesso" ))
						oJsonRet["LOJA"]			:= SC5->C5_LOJACLI
						oJsonRet["EMPRESA"]			:= cEmpant
						oJsonRet["PEDIDOB2B"]		:= _cPedB2B
						oJsonRet["PEDIDOPROTHEUS"]	:= _cNumPed
						oJsonRet["FILIAL"]         	:= SC5->C5_FILIAL
						oJsonRet["CLIENTE"]			:= SC5->C5_CLIENTE
						oJsonRet["OPCAO"]			:= EncodeUTF8(IIF(_nOpc == 3, "3 - Inclusão", "4 - Alteração"))
						oJsonRet["SUCESSCODE"]     	:= 201  				// 201 - Código padrão HTML de POST realizado com sucesso.
						aAdd(oResponse["Resultados"], oJsonRet)

					Endif

					//******************************************************************************
					// Apago os valores dos Arrays para o proximo Post/Pedido de Vendas
					//******************************************************************************
					aDadosC5 	:= {}
					aLin		:= {}
					aDadosC6	:= {}

				Next _nZ

				//******************************************************************************
				// Destrava a funcao no Licence Server
				//******************************************************************************
				UnlockByName("EjPVPost",.F.,.F.)

			End Transaction
		Endif
	Else

		nError := 400
		cError := 'Body esperado no formato "application/json".'

	Endif

	//**********************************************************************************
	// Efetua o fechamento das tabelas
	//**********************************************************************************
	SC5->(dbCloseArea())
	SC6->(dbCloseArea())
	SA1->(dbCloseArea())
	SA2->(dbCloseArea())
	SB1->(dbCloseArea())
	SB2->(dbCloseArea())
	SE4->(dbCloseArea())
	SF4->(dbCloseArea())

	//**********************************************************************************
	// Efetua o reset no ambiente
	//**********************************************************************************
	RpcClearEnv()

	//**********************************************************************************
	// Restaura a area de trabalho original
	//**********************************************************************************
	RestArea(aArea)

	If nError = 0
		Self:SetResponse(oResponse:toJson())
	Else
		SetRestFault(nError, EncodeUTF8(cError))
	Endif

Return(.T.)
