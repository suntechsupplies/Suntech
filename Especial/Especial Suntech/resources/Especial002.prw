#Include "Totvs.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"
#include 'parmtype.ch'
#include 'Json.ch'

/*----------------------------------------------------------------------
{Protheus.doc} 	Especial02
TODO 			Consumo de API
@author 		carlos.saturnino@atlantanconsulting.com.br
@since 			17/08/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			Static Function
----------------------------------------------------------------------*/
user function Especial02(cAuth)

	Processa({|| Especial03(cAuth)}, "Consumindo Serviços...")

Return(_lAut)
/*----------------------------------------------------------------------
{Protheus.doc} 	Especial03
TODO 			Autentica API Invoice
@author 		carlos.saturnino@atlantanconsulting.com.br
@since 			17/08/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			Static Function
----------------------------------------------------------------------*/
Static function Especial03(cAuth)

	Local 	cPath		:= GETMV("HB_PATHINV")				//"api/fat/special/v1.0/invoice"
	Local   oJson 		:= Nil

	Private cUrl        := GETMV("HB_URLESPE")				//'http://suntechsupplies105137.protheus.cloudtotvs.com.br:8400/rest/especial001/'
	Private	_cAuth		:= Encode64(cAuth)
	Private aHeader		:= {}

	Public	_lAut		:= .F.
	
	//**********************************************************
	// Monta o Header para o consumo do Serviço
	//**********************************************************
	aAdd(aHeader, "Content-Type: application/json")	
	aAdd(aHeader, "cache-control: no-cache")
	Aadd(aHeader, "Authorization: Basic " + _cAuth) 
	
	//**********************************************************
	// Aponta para o Serviço Get desejado
	//**********************************************************
	oJson:= FWRest():New(cUrl)
	oJson:setPath(cPath)

	If oJson:Get(aHeader)
		_laut := .T.
		Especial04(oJson)
	Endif

Return()

/*----------------------------------------------------------------------
{Protheus.doc} 	Especial04
TODO 			Consumo de API
@author 		carlos.saturino@atlantanconsulting.com.br
@since 			17/08/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			Static Function
----------------------------------------------------------------------*/
Static Function Especial04(oJson)

	Local   _oJson 		:= oJson
	Local	aDadosC5	:= {}
	Local 	aDadosC6	:= {}
	Local 	_cFilial	:= ""
	Local 	_cCliente	:= ""
	Local 	_cLoja		:= ""
	Local	_cTipo		:= ""
	Local 	oCont 		:= JsonObject():New()
	Local 	_cRet		:= ""
	Local	_cReq		:= ""
	Local	lRet		:= .F.
	Local 	_cTES		:= SuperGetMV("HB_TESVDA",,"599")
	Local 	_cOper		:= SuperGetMV("HB_OPERVDA",,"01")	

	Local	_nY,_nX,_nZ
	Private 	lMsErroAuto	:= .F.

	//**********************************************************
	// Verifica se a conexao foi efetuada com sucesso
	//**********************************************************
	If ! _oJson:Get(aHeader)
		Aviso("Erro na Conexão com API Invoice", _oJson:GetLastError())
	Else

		lRet := .T.

		//**********************************************************
		// Efetua a Deserialização do conteúdo da API
		//**********************************************************
		oContent := JsonObject():New()
		FwJsonDeserialize(_oJson:getResult(), @oContent)
		
		_cRet	:= _oJson:GetResult()
		_cReq 	:= oCont:FromJson(_cRet)
		
		If ValType(_cReq) == "U"
	
				//**********************************************************************************
				// Efetua o travamento do registro no Licence Server 
				//**********************************************************************************
				If !LockByName("Especial002",.F.,.F.)
					Conout( '[Especial002 - Get] Thread ['+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] ['+_cProcesso+'] - está em execução por outro processamento.')
				endif
				//**********************************************************************************
				// Preenche o Array do Cabecalho do Pedido de Vendas
				//**********************************************************************************
				nTotal := Len(oCont)
				ProcRegua(nTotal)
				For _nZ := 1 To Len(oCont)
					
					IncProc("Integrando registro " + cValToChar(_nZ) + " de " + cValToChar(nTotal) + "...")

					//***************************************************************************************
					// Guardo numero do Pedido Pedido AFV
					//***************************************************************************************
					_cPedAFV	:= oCont[_nZ]:GetJsonText(Lower("C5_ZZNPEXT"))
					_cTipo		:= oCont[_nZ]:GetJsonText(Lower("C5_TIPO"))
					_cFilial	:= "01"//oCont[_nZ]:GetJsonText(Lower("C5_FILIAL"))
					_cCliente	:= oCont[_nZ]:GetJsonText(Lower("C5_CLIENTE"))
					_cLoja		:= oCont[_nZ]:GetJsonText(Lower("C5_LOJACLI"))
					
					DbSelectArea("ZA1")
					DbSetOrder(2)
					If !ZA1->(DbSeek(xFilial("ZA1")+oCont[_nZ]:GetJsonText(Lower("EMPRESA"))+oCont[_nZ]:GetJsonText(Lower("C5_FILIAL"))+_cPedAFV +oCont[_nZ]:GetJsonText(Lower("C5_NUM"))))
						RecLock("ZA1", .T.)
						ZA1->ZA1_FILIAL := xFilial("ZA1")
						ZA1->ZA1_EMPRES := oCont[_nZ]:GetJsonText(Lower("EMPRESA"))
						ZA1->ZA1_FILORI := oCont[_nZ]:GetJsonText(Lower("C5_FILIAL"))
						ZA1->ZA1_PEDAFV := _cPedAFV
						ZA1->ZA1_NUM	:= oCont[_nZ]:GetJsonText(Lower("C5_NUM"))
						ZA1->ZA1_INTEGR := .F.
						ZA1->ZA1_EXCLUI := .F.
						MsUnLock()
					EndIf

					//**********************************************************************************
					// Pesquiso o Pedido AFV para identificar se e inclusão ou alteracao 
					//**********************************************************************************
					DbSelectArea("SC5")
					DbSetOrder(11)
					If SC5->(dbSeek(_cFilial + _cPedAFV + oCont[_nZ]:GetJsonText(Lower("C5_NUM"))))
						_nOpc 	:= 4				// Altera
						_cNumPed:= SC5->C5_NUM
					Else
						_nOpc := 3					// Inclui
						_cNumPed := GetSxeNum("SC5", "C5_NUM")
					Endif

					//**********************************************************************************
					// Salva a area atual 
					//**********************************************************************************
					aArea := GetArea()					
	
					//**********************************************************************************
					// Efetua a Consulta do Cliente na base, se não achar inclui
					//**********************************************************************************
					If _cTipo == "N"
						dbSelectArea("SA1")
						dbSetOrder(1)
						If ! dbSeek(FwFilial("SA1") + _cCliente + _cLoja )
							Esp002Cli( _cTipo, _cCliente, _cLoja )
						Endif
					Else
						dbSelectArea("SA2")
						dbSetOrder(1)
						If ! dbSeek(FwFilial("SA2") + _cCliente + _cLoja )
							Esp002Cli( _cTipo, _cCliente, _cLoja )
						Endif
					Endif

					//**********************************************************************************
					// Efetua a Consulta da condição de pagamento na base, se não achar inclui
					//**********************************************************************************
					cCondPag := oCont[_nZ]:GetJsonText(Lower("C5_CONDPAG"))
					DbSelectArea("SE4")
					DbSetOrder(1)
					If !DbSeek(FwFilial("SE4")+cCondPag)
						Esp002CPag(cCondPag)
					EndIf

					//**********************************************************************************
					// Efetua a Consulta do vendedor na base, se não achar inclui
					//**********************************************************************************
					cVendedor := oCont[_nZ]:GetJsonText(Lower("C5_VEND1"))
					DbSelectArea("SA3")
					DbSetOrder(1)
					If !DbSeek(FwFilial("SA3")+cVendedor)
						Esp002Vend(cVendedor)
					EndIf

					//**********************************************************************************
					// Preenche o Array do Cabecalho do Pedido de Vendas 
					//**********************************************************************************
					aAdd(aDadosC5, {"C5_NUM"	 		,_cNumPed	 		, Nil})
					aAdd(aDadosC5, {"C5_TIPO"	 		,oCont[_nZ]:GetJsonText(Lower("C5_TIPO"))	 		, Nil})
					aAdd(aDadosC5, {"C5_CLIENTE" 		,oCont[_nZ]:GetJsonText(Lower("C5_CLIENTE"))		, Nil})
					aAdd(aDadosC5, {"C5_LOJACLI" 		,oCont[_nZ]:GetJsonText(Lower("C5_LOJACLI"))		, Nil})
					aAdd(aDadosC5, {"C5_LOJAENT" 		,oCont[_nZ]:GetJsonText(Lower("C5_LOJACLI"))		, Nil})
					aAdd(aDadosC5, {"C5_CONDPAG" 		,oCont[_nZ]:GetJsonText(Lower("C5_CONDPAG"))		, Nil})
					aAdd(aDadosC5, {"C5_TIPOCLI" 		,SA1->A1_TIPO										, Nil})
					aAdd(aDadosC5, {"C5_NATUREZ" 		,"001"												, Nil})
					aAdd(aDadosC5, {"C5_TPFRETE" 		,oCont[_nZ]:GetJsonText(Lower("C5_TPFRETE")) 		, Nil})
					aAdd(aDadosC5, {"C5_MENNOTA" 		,oCont[_nZ]:GetJsonText(Lower("C5_MENNOTA")) 		, Nil})
					aAdd(aDadosC5, {"C5_ZZOBS" 			,oCont[_nZ]:GetJsonText(Lower("C5_ZZOBS")) 			, Nil})
					aAdd(aDadosC5, {"C5_VEND1" 			,oCont[_nZ]:GetJsonText(Lower("C5_VEND1"))			, Nil})
					aAdd(aDadosC5, {"C5_DESC1" 			,Val(oCont[_nZ]:GetJsonText(Lower("C5_DESC1")))		, Nil})
					aAdd(aDadosC5, {"C5_ZZNPEXT" 		,oCont[_nZ]:GetJsonText(Lower("C5_ZZNPEXT"))		, Nil})
					aAdd(aDadosC5, {"C5_ZZPROD" 		,oCont[_nZ]:GetJsonText(Lower("C5_NUM"))			, Nil})					
					aAdd(aDadosC5, {"C5_ZZTPPED" 		,oCont[_nZ]:GetJsonText(Lower("C5_ZZTPPED"))		, Nil})
					aAdd(aDadosC5, {"C5_ZZDTEMI" 		,Stod(oCont[_nZ]:GetJsonText(Lower("C5_ZZDTEMI")))	, Nil})
					aAdd(aDadosC5, {"C5_ZZORIGE" 		,oCont[_nZ]:GetJsonText(Lower("C5_ZZORIGE"))		, Nil})					

					//**********************************************************************************
					// Muda a dimensão do Objeto
					//**********************************************************************************
					_nZ++
					
					//**********************************************************************************
					// Preenche o Array dos Itens do Pedido de Vendas
					//**********************************************************************************
					For _nX := 1 to Len(oCont[_nZ])
						
						//**********************************************************************************
						// Efetua a Consulta dos produtos na base, se não achar inclui
						//**********************************************************************************
						cProduto := oCont[_nZ][_nX]:GetJsonText(Lower("C6_PRODUTO")) 
						dbSelectArea("SB1")
						dbSetOrder(1)
						If ! dbSeek(FwFilial("SB1") + cProduto)
							Esp002Pro( cProduto )
						Endif

						aLin := {}
						aAdd(aLin, {"C6_ITEM"		,oCont[_nZ][_nX]:GetJsonText(Lower("C6_ITEM"))			, Nil})
						aAdd(aLin, {"C6_PRODUTO" 	,oCont[_nZ][_nX]:GetJsonText(Lower("C6_PRODUTO"))		, Nil})
						aAdd(aLin, {"C6_QTDVEN" 	,Val(oCont[_nZ][_nX]:GetJsonText(Lower("C6_QTDVEN")))	, Nil})
						aAdd(aLin, {"C6_PRCVEN" 	,Val(oCont[_nZ][_nX]:GetJsonText(Lower("C6_PRCVEN")))	, Nil})
						aAdd(aLin, {"C6_PRUNIT" 	,Val(oCont[_nZ][_nX]:GetJsonText(Lower("C6_PRCVEN")))	, Nil})
						aAdd(aLin, {"C6_TES" 		,_cTES													, Nil}) 
						aAdd(aLin,	{"AUTDELETA"	,"N"													, Nil})
						aAdd(aDadosC6,aLin)
					
					Next _nX
					
					//**********************************************************************************
					// Efetua o posicionamento das tabelas para  a inclusao do Pedido de Vendas 
					//**********************************************************************************
					SC6->(dbSetOrder(1))
					SC6->(dbGoTop())
					SA1->(dbSetOrder(1))
					SA1->(dbGoTop())
					SA2->(dbSetOrder(1))
					SA2->(dbGoTop())
					SB1->(dbSetOrder(1))
					SB1->(dbGoTop())
					SB2->(dbSetOrder(1))
					SB2->(dbGoTop())
					SE4->(dbSetOrder(1))
					SE4->(dbGoTop())
					SF4->(dbSetOrder(1))
					SF4->(dbGoTop())
					SC5->(dbSetOrder(10))
					SC5->(dbGoTop())
	
	
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
						// Efetua o Rollback da numeração da SC5
						//******************************************************************************
						RollBackSX8()
						
						cError := mostraerro()	
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
							cError 	+= aLogAuto[_nY]  
						Next _nY
						
						cArqLog	:= "\log_ped\" + AllTrim(_cPedAFV) + " - " +Time()+ ".log"
						MemoWrite(cArqLog, cError)

						RecLock("ZA1", .F.)
						ZA1->ZA1_LOGERR := cError
						MsUnLock()
	
					Else

						//******************************************************************************
						// Confirma a utilização da Numeração do Pedido de Vendas
						//******************************************************************************
						ConfirmSX8()

						//******************************************************************************
						// Posiciona em cima do Cabec. do Pedido de Vendas e recupero o Num. do mesmo 
						//******************************************************************************
						SC5->(dbSelectArea("SC5"))
						SC5->(dbSetOrder(10))
						SC5->(dbGoTop())
						If SC5->(dbSeek(_cFilial + _cPedAFV))
							_cNumPed:= SC5->C5_NUM
						Endif

						RecLock("ZA1", .F.)
						ZA1->ZA1_INTEGR := .T.
						ZA1->ZA1_LOGERR := ""
						MsUnLock()
	
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
				UnlockByName("RPedGetPos",.F.,.F.)

		Else
			Aviso("Arquivo Json Inválido",Str(_cReq))
			Return(lRet)
		Endif

	EndIf

Return(lRet)

/*----------------------------------------------------------------------
{Protheus.doc} 	Esp002Cli
TODO 			Consome serviço para recuperar dados do Cliente/Fornecedor
@author 		Carlos Eduardo Saturnino - Atlanta Consulting
@since 			17/08/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			Static Function
----------------------------------------------------------------------*/
Static Function Esp002Cli( _cTipo, _cCliente, _cLoja )

	Local cPath			:= GETMV("HB_PATHCUS")					//'api/fat/special/v1.0/customer'
	Local cParam		:= '?ccliente='+ _cCliente +'&cloja='+_cLoja	
	Local oRestSA1 		:= FWRest():New(cUrl)
	Local aHeader     	:= {}
	Local lRet      	:= .T.
	Local aError		:= {}
	Local oModel		:= Nil
	Local oContentSA1
	
	aAdd(aHeader, "Content-Type: application/json")	
	aAdd(aHeader, "cache-control: no-cache")
	Aadd(aHeader, "Authorization: Basic " + _cAuth) 
	
	//**********************************************************
	// Aponta para o Serviço Get desejado
	//**********************************************************
	oRestSA1:setPath(cPath+cParam)

	//**********************************************************
	// Monta o Header para consumir o serviço
	//**********************************************************
	If ! oRestSA1:Get(aHeader)
		Aviso("Erro na Conexao com API Cadastros de Clientes", oRestSA1:GetLastError())
	Else
		//**********************************************************
		// Efetua a De-serialização do Conteúdo Json
		//**********************************************************
		FwJsonDeserialize(oRestSA1:getResult(), @oContentSA1)
		
		//**********************************************************
		// Instancia o Modelo
		//**********************************************************
		oModel	:= FWLoadModel("MATA030")			
		
		//**********************************************************
		// Define o tipo de operação (inclusão ou alteração)
		//**********************************************************
		dbSelectArea("SA1")
		dbSetOrder(1)
		If ! SA1->(dbSeek( &('oContentSA1:CLIENTE[1]:A1_FILIAL') + &('oContentSA1:CLIENTE[1]:A1_COD')))
			oModel:SetOperation(MODEL_OPERATION_INSERT)
		Else
			oModel:SetOperation(MODEL_OPERATION_UPDATE)
		Endif

		//**********************************************************
		//Ativa o Modelo
		//**********************************************************
		oModel:Activate()
		oSA1Mod:= oModel:GetModel('MATA030_SA1')
	
		//**********************************************************
		// Preenche o Modelo com dados do cliente
		//**********************************************************
		oSA1Mod:SetValue("A1_FILIAL" ,cFilant							)
		oSA1Mod:SetValue("A1_COD"    ,oContentSA1:CLIENTE[1]:A1_COD		)
        oSA1Mod:SetValue("A1_LOJA"   ,oContentSA1:CLIENTE[1]:A1_LOJA	)
		oSA1Mod:SetValue("A1_TIPO"   ,oContentSA1:CLIENTE[1]:A1_TIPO	)
        oSA1Mod:SetValue("A1_NOME"   ,oContentSA1:CLIENTE[1]:A1_NOME	)
        oSA1Mod:SetValue("A1_NREDUZ" ,oContentSA1:CLIENTE[1]:A1_NREDUZ	)
        oSA1Mod:SetValue("A1_END"    ,oContentSA1:CLIENTE[1]:A1_END		)
        oSA1Mod:SetValue("A1_BAIRRO" ,oContentSA1:CLIENTE[1]:A1_BAIRRO	)
        oSA1Mod:SetValue("A1_MUN"    ,oContentSA1:CLIENTE[1]:A1_MUN		)
        oSA1Mod:SetValue("A1_EST"    ,oContentSA1:CLIENTE[1]:A1_EST		)
        oSA1Mod:SetValue("A1_COD_MUN",oContentSA1:CLIENTE[1]:A1_COD_MUN	)
		oSA1Mod:SetValue("A1_CEP"    ,oContentSA1:CLIENTE[1]:A1_CEP	    )
		oSA1Mod:SetValue("A1_PESSOA" ,oContentSA1:CLIENTE[1]:A1_PESSOA	)
		oSA1Mod:SetValue("A1_CGC"    ,oContentSA1:CLIENTE[1]:A1_CGC	    )
		oSA1Mod:SetValue("A1_INCISS" ,oContentSA1:CLIENTE[1]:A1_INCISS	)
		oSA1Mod:SetValue("A1_GRPVEN" ,oContentSA1:CLIENTE[1]:A1_GRPVEN	)
		oSA1Mod:setValue("A1_INSCR"  ,oContentSA1:CLIENTE[1]:A1_INSCR   )
		oSA1Mod:setValue("A1_PAIS"   ,oContentSA1:CLIENTE[1]:A1_PAIS    )
		oSA1Mod:setValue("A1_EMAIL"  ,oContentSA1:CLIENTE[1]:A1_EMAIL   )
		oSA1Mod:setValue("A1_DDD"    ,oContentSA1:CLIENTE[1]:A1_DDD     )
		oSA1Mod:setValue("A1_TEL"    ,oContentSA1:CLIENTE[1]:A1_TEL     )
		oSA1Mod:setValue("A1_NATUREZ","001"							    )
		
		/**************************************************************************
		// solicitação do Michael Oliveira em 07/01/2021
		/**************************************************************************
		Complemento - Não trouxe (tem que trazer)    A1_COMPLEM
		Região - Não trouxe (tem que trazer) A1_REGIAO
		Descr.Região - Não Trouxe (tem que trazer) (gatilho do nome da região)
		Vendedor - Não trouxe (tem que ter para referência) A1_VEND
		C. Contabil - Não trouxe (precisa para usar o financeiro?) A1_CONTA
		**************************************************************************/
		oSA1Mod:setValue("A1_COMPLEM",oContentSA1:CLIENTE[1]:A1_COMPLEM )
		oSA1Mod:setValue("A1_REGIAO" ,oContentSA1:CLIENTE[1]:A1_REGIAO  )
		oSA1Mod:setValue("A1_VEND"   ,oContentSA1:CLIENTE[1]:A1_VEND    )
		oSA1Mod:setValue("A1_CONTA"  ,oContentSA1:CLIENTE[1]:A1_CONTA 	)

		//**********************************************************
		// Valida o modelo e inclui o cliente
		//**********************************************************
        If oModel:VldData()
		    If oModel:CommitData()
				lRet := .T.
				ConfirmSX8()
			Else
				Aviso("Cadastros de Clientes",  "Erro ao cadastrar o cliente "+oContentSA1:CLIENTE[1]:A1_COD) 
				RollbackSX8()
				lRet := .F.       
			EndIf
        Else
            aError := oModel:GetErrorMessage()
            Aviso("Cadastros de Clientes", "Erro : " + aError[5] + aError[6] + " - " + aError[7])
			lRet := .F.
        EndIf

		If !lRet
			//Busca o Erro do Modelo de Dados
			aErro := oModel:GetErrorMessage()
			
			//Monta o Texto que será mostrado na tela
			AutoGrLog("Id do formulário de origem:"  + ' [' + AllToChar(aErro[01]) + ']')
			AutoGrLog("Id do campo de origem: "      + ' [' + AllToChar(aErro[02]) + ']')
			AutoGrLog("Id do formulário de erro: "   + ' [' + AllToChar(aErro[03]) + ']')
			AutoGrLog("Id do campo de erro: "        + ' [' + AllToChar(aErro[04]) + ']')
			AutoGrLog("Id do erro: "                 + ' [' + AllToChar(aErro[05]) + ']')
			AutoGrLog("Mensagem do erro: "           + ' [' + AllToChar(aErro[06]) + ']')
			AutoGrLog("Mensagem da solução: "        + ' [' + AllToChar(aErro[07]) + ']')
			AutoGrLog("Valor atribuído: "            + ' [' + AllToChar(aErro[08]) + ']')
			AutoGrLog("Valor anterior: "             + ' [' + AllToChar(aErro[09]) + ']')
			
			//Mostra a mensagem de Erro
			MostraErro()
		EndIf

	Endif

	//**********************************************************
	// Desativa o modelo
	//**********************************************************
	If ValType(oModel) == "O"
		oModel:DeActivate()
	endif

return(lRet)

/*----------------------------------------------------------------------
{Protheus.doc} 	Esp002Pro
TODO 			Consome serviço para recuperar dados do Produto
@author 		Carlos Eduardo Saturnino - Atlanta Consulting
@since 			17/08/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			Static Function
----------------------------------------------------------------------*/

Static Function Esp002Pro( cProduto )
						   
	Local cPath			:= GETMV("HB_PATHPRO")					//'api/fat/special/v1.0/product'
	Local cParam		:= '?cproduto='+ Alltrim(cProduto)	
	Local oRestSB1 		:= FWRest():New(cUrl)
	Local aHeader     	:= {}
	Local lRet      	:= .T.
	Local oContentSB1
	Local oModel
	Local oSB1Mod

	aAdd(aHeader, "Content-Type: application/json")	
	aAdd(aHeader, "cache-control: no-cache")
	Aadd(aHeader, "Authorization: Basic " + _cAuth) 

	//**********************************************************
	// Aponta para o Serviço Get desejado
	//**********************************************************
	oRestSB1:setPath(cPath+cParam)

	//**********************************************************
	// Monta o Header para consumir o serviço
	//**********************************************************
	If ! oRestSB1:Get(aHeader)
		Aviso("Erro na Conexao com API Cadastros de Produtos", oRestSB1:GetLastError())
	Else
		//**********************************************************
		// Efetua a De-serialização do Conteúdo Json
		//**********************************************************
		
		FwJsonDeserialize(oRestSB1:getResult(), @oContentSB1)
		
		oModel := FWLoadModel("MATA010")		
		
		//**********************************************************
		// Pesquiso se é inclusão ou alteração
		//**********************************************************
		dbSelectArea("SB1")
		dbSetOrder(1)

		If !SB1->(dbSeek(FwFilial("SB1")+cProduto))
			oModel:SetOperation(MODEL_OPERATION_INSERT)
		Else
			oModel:SetOperation(MODEL_OPERATION_UPDATE)
		Endif

		oModel:Activate()
		
		oSB1Mod := oModel:GetModel("SB1MASTER")
		oSB1Mod:SetValue("B1_COD" 	, oContentSB1:PRODUTO[1]:B1_COD      			) 
		oSB1Mod:SetValue("B1_DESC"	, SubStr(oContentSB1:PRODUTO[1]:B1_DESC,1,30)  	) 
		oSB1Mod:SetValue("B1_TIPO" 	, oContentSB1:PRODUTO[1]:B1_TIPO     			) 
		oSB1Mod:SetValue("B1_UM"   	, oContentSB1:PRODUTO[1]:B1_UM      			) 
		oSB1Mod:SetValue("B1_LOCPAD", "01"                               			) 
		oSB1Mod:SetValue("B1_PICM" 	, oContentSB1:PRODUTO[1]:B1_PICM     			) 
		oSB1Mod:SetValue("B1_IPI"	, oContentSB1:PRODUTO[1]:B1_IPI     			) 

		//Se conseguir validar as informações
		If oModel:VldData()
			If oModel:CommitData()
				lRet := .T.
				ConfirmSX8()
			Else
				lRet := .F.
				RollBackSX8()
			EndIf
		Else
			lRet := .F.
		EndIf
		
		If ! lRet
			aErro := oModel:GetErrorMessage()
			
			//Monta o Texto que será mostrado na tela
			cMessage := "Id do formulário de origem:"  + ' [' + cValToChar(aErro[01]) + '], '
			cMessage += "Id do campo de origem: "      + ' [' + cValToChar(aErro[02]) + '], '
			cMessage += "Id do formulário de erro: "   + ' [' + cValToChar(aErro[03]) + '], '
			cMessage += "Id do campo de erro: "        + ' [' + cValToChar(aErro[04]) + '], '
			cMessage += "Id do erro: "                 + ' [' + cValToChar(aErro[05]) + '], '
			cMessage += "Mensagem do erro: "           + ' [' + cValToChar(aErro[06]) + '], '
			cMessage += "Mensagem da solução: "        + ' [' + cValToChar(aErro[07]) + '], '
			cMessage += "Valor atribuído: "            + ' [' + cValToChar(aErro[08]) + '], '
			cMessage += "Valor anterior: "             + ' [' + cValToChar(aErro[09]) + ']'
			
			lRet := .F.
			ConOut("Erro: " + cMessage)
			Aviso("Cadastro de Produtos", cMessage)
			RollBackSX8()
		Else
			lRet := .T.
			ConfirmSX8()
		EndIf
		
		//Desativa o modelo de dados
		oModel:DeActivate()
	EndIf

Return(lRet)


/*----------------------------------------------------------------------
{Protheus.doc} 	Esp002CPag
TODO 			Consome serviço para recuperar dados da Condição de Pagto
@author 		Carlos Eduardo Saturnino - Atlanta Consulting
@since 			17/08/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			Static Function
----------------------------------------------------------------------*/

Static Function Esp002CPag(cCondPag)

	Local cPath			:= GETMV("HB_PATHPAY")						//'api/fat/special/v1.0/paymentcondition'
	Local cParam		:= '?cCondicao='+ Alltrim(cCondPag)	
	Local oRestSE4 		:= FWRest():New(cUrl)
	Local aHeader     	:= {}
	Local lRet      	:= .T.
	Local oContentSE4
	Local oModel
	Local oSE4Mod

	aAdd(aHeader, "Content-Type: application/json")	
	aAdd(aHeader, "cache-control: no-cache")
	Aadd(aHeader, "Authorization: Basic " + _cAuth) 

	//**********************************************************
	// Aponta para o Serviço Get desejado
	//**********************************************************
	oRestSE4:setPath(cPath+cParam)

	//**********************************************************
	// Monta o Header para consumir o serviço
	//**********************************************************
	If ! oRestSE4:Get(aHeader)
		Aviso("Erro na Conexao com API Cadastros de Condiçoes de pagamento: ", oRestSE4:GetLastError())
	Else
		//**********************************************************
		// Efetua a De-serialização do Conteúdo Json
		//**********************************************************
		
		FwJsonDeserialize(oRestSE4:getResult(), @oContentSE4)
		
		oModel := FWLoadModel("MATA360")		
		
		//**********************************************************
		// Pesquiso se é inclusão ou alteração
		//**********************************************************
		dbSelectArea("SE4")
		dbSetOrder(1)

		If !SE4->(dbSeek(FwFilial("SE4")+cCondPag))
			oModel:SetOperation(MODEL_OPERATION_INSERT)
		Else
			oModel:SetOperation(MODEL_OPERATION_UPDATE)
		Endif
		
		oModel:Activate()
		oSE4Mod := oModel:GetModel("SE4MASTER")
		oSE4Mod:SetValue("E4_CODIGO"    , oContentSE4:CONDICAO[1]:E4_CODIGO   ) 
		oSE4Mod:SetValue("E4_TIPO"      , oContentSE4:CONDICAO[1]:E4_TIPO     ) 
		oSE4Mod:SetValue("E4_COND"      , oContentSE4:CONDICAO[1]:E4_COND     ) 
		oSE4Mod:SetValue("E4_DESCRI"    , oContentSE4:CONDICAO[1]:E4_DESCRI   ) 
		oSE4Mod:SetValue("E4_DDD"       , oContentSE4:CONDICAO[1]:E4_DDD      ) 
		oSE4Mod:SetValue("E4_AGRACRS"   , oContentSE4:CONDICAO[1]:E4_AGRACRS  ) 
		oSE4Mod:SetValue("E4_ACRES"     , oContentSE4:CONDICAO[1]:E4_ACRES    )
		oSE4Mod:SetValue("E4_DIADESC"   , oContentSE4:CONDICAO[1]:E4_DIADESC  ) 
		oSE4Mod:SetValue("E4_IPI"       , oContentSE4:CONDICAO[1]:E4_IPI      ) 

		If oModel:VldData()
			If oModel:CommitData()
				lRet := .T.
				ConfirmSX8()
			Else
				lRet := .F.
				RollBackSX8()
			EndIf
		Else
			lRet := .F.
		EndIf
		
		If ! lRet
			aErro := oModel:GetErrorMessage()
			
			//Monta o Texto que será mostrado na tela
			cMessage := "Id do formulário de origem:"  + ' [' + cValToChar(aErro[01]) + '], '
			cMessage += "Id do campo de origem: "      + ' [' + cValToChar(aErro[02]) + '], '
			cMessage += "Id do formulário de erro: "   + ' [' + cValToChar(aErro[03]) + '], '
			cMessage += "Id do campo de erro: "        + ' [' + cValToChar(aErro[04]) + '], '
			cMessage += "Id do erro: "                 + ' [' + cValToChar(aErro[05]) + '], '
			cMessage += "Mensagem do erro: "           + ' [' + cValToChar(aErro[06]) + '], '
			cMessage += "Mensagem da solução: "        + ' [' + cValToChar(aErro[07]) + '], '
			cMessage += "Valor atribuído: "            + ' [' + cValToChar(aErro[08]) + '], '
			cMessage += "Valor anterior: "             + ' [' + cValToChar(aErro[09]) + ']'
			
			lRet := .F.
			ConOut("Erro: " + cMessage)
			Aviso("Cadastro de Condições de pagamento", cMessage)
		Else
			lRet := .T.
			ConOut("Condição de pagamento incluida!")
			//Aviso("Cadastro de Condições de pagamento",  "Condição Cadastrada com Sucesso !!!")
		EndIf

		//Desativa o modelo de dados
		oModel:DeActivate()

	EndIf

Return(lRet)



/*----------------------------------------------------------------------
{Protheus.doc} 	Esp002Vend
TODO 			Consome serviço para recuperar dados do Vendedor
@author 		Carlos Eduardo Saturnino - Atlanta Consulting
@since 			17/08/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			Static Function
----------------------------------------------------------------------*/

Static Function Esp002Vend(cVendedor)

	Local aDados := {}
	Local cPath			:= GETMV("HB_PATHVEN")				//'api/fat/special/v1.0/vendor'
	Local cParam		:= '?cVendedor='+ Alltrim(cVendedor)	
	Local oRestSA3 		:= FWRest():New(cUrl)
	Local aHeader     	:= {}
	Local oContentSA3
	Local nOpc
	Private lMsErroAuto

	aAdd(aHeader, "Content-Type: application/json")	
	aAdd(aHeader, "cache-control: no-cache")
	Aadd(aHeader, "Authorization: Basic " + _cAuth) 

	//**********************************************************
	// Aponta para o Serviço Get desejado
	//**********************************************************
	oRestSA3:setPath(cPath+cParam)

	//**********************************************************
	// Monta o Header para consumir o serviço
	//**********************************************************
	If ! oRestSA3:Get(aHeader)
		Aviso("Erro na Conexao com API Cadastros de Produtos", oRestSA3:GetLastError())
	Else
		//**********************************************************
		// Efetua a De-serialização do Conteúdo Json
		//**********************************************************
		
		FwJsonDeserialize(oRestSA3:getResult(), @oContentSA3)
		
		//**********************************************************
		// Pesquiso se é inclusão ou alteração
		//**********************************************************
		dbSelectArea("SA3")
		dbSetOrder(1)

		If !SA3->(dbSeek(FwFilial("SA3")+cVendedor))
			nOpc := 3
		Else
			nOpc := 4
		Endif

		aAdd(aDados, {"A3_FILIAL"   , xFilial("SA3")			    	, nil})
		aAdd(aDados, {"A3_COD"   	, oContentSA3:VENDEDOR[1]:A3_COD	    , nil})
		aAdd(aDados, {"A3_NOME"  	, oContentSA3:VENDEDOR[1]:A3_NOME		, nil})
		MSExecAuto({|x,y|mata040(x,y)},aDados,nOpc)

		If lMsErroAuto
			MsgStop("Erro na gravação do vendedor")
			MostraErro()
			RollBackSX8()
		Else
			ConOut('Vendedor incluido com sucesso.')	
			ConfirmSX8()
		EndIf
	EndIf

Return ()


User Function Esp002Vend()

	Private cUrl        := 'http://suntechsupplies105137.protheus.cloudtotvs.com.br:8400/rest/especial001/'
	Private	_cAuth		:= Encode64("administrador:agis9")
	Private aHeader		:= {}
	Private 	lMsErroAuto	:= .F.

	Public	_lAut		:= .F.

	RpcSetType( 3 )
	RpcSetEnv( "99","01","admin","",'FAT' )

	Esp002CPag('038')

Return()


