#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "Totvs.ch"

#Define Desc_Rest 	"Serviço REST para Disponibilizar Cadastros"
/********************************************************************
{Protheus.doc} 	WsRestFul Especial001
TODO 			Metodo WSRestFul para Get de Cadastros
@since 			19/08/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			WsMethod Rest
********************************************************************/
WSRESTFUL Especial001 DESCRIPTION Desc_Rest

	WSDATA cCliente		As String
	WSDATA cLoja		As String
	WSDATA cProduto		As String
	WSDATA cCondicao	As String
	WSDATA cVendedor	As String
	
	//--------------------------------------------------------------------------------------------------------------
    //{protocolo}://{host}/{api}/{agrupador}/{dominio}/{versao}/{recurso}". 
    //Ex: https://fluig.totvs.com/api/ecm/security/v1/users.
    //--------------------------------------------------------------------------------------------------------------
	WSMETHOD GET invoice										;
	DESCRIPTION "Retorna Pedido de Vendas "						;
	WSSYNTAX "api/fat/special/v1.0/invoice"						;
	PATH 	"api/fat/special/v1.0/invoice"		

	WSMETHOD GET customer										;
	DESCRIPTION "Retorna o cliente solicitado "					;
	WSSYNTAX "api/fat/special/v1.0/customer"					;
	PATH "api/fat/special/v1.0/customer"		

    WSMETHOD GET product 										;
    DESCRIPTION "Retorna Produto solicitado" 					;
    WSSYNTAX "api/fat/special/v1.0/product"						;
    PATH "api/fat/special/v1.0/product"
    
    WSMETHOD GET paymentcondition 								;
    DESCRIPTION "Retorna Condicao de Pagamento solicitada" 		;
    WSSYNTAX "api/fat/special/v1.0/paymentcondition"			;
    PATH "api/fat/special/v1.0/paymentcondition"
    
	WSMETHOD GET vendor		 									;
    DESCRIPTION "Retorna dados do vendedor solicitado"			;
    WSSYNTAX "api/fat/special/v1.0/vendor"						;
    PATH "api/fat/special/v1.0/vendor"


END WSRESTFUL

/********************************************************************
{Protheus.doc} 	GET customer
TODO 			Retorna cadastro do cliente
@since 			19/08/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			WsMethod Rest
********************************************************************/
WSMETHOD GET customer WSRECEIVE cCliente, cLoja WSSERVICE Especial001

	Local _cCliente		:= Self:cCliente
	Local _cLoja		:= Self:cLoja
	Local cAuth 		:= Iif(!Empty(::GetHeader('Authorization')),::GetHeader('Authorization'),Nil)
	Local lAuthorized	:= .F.
	Local aTabs			:= {'SA1'}
	Local _cEmpresa		:= "01"
	Local _cFilial		:= "01"
	Local _lSegue		:= .F.
	Local aArea			:= GetArea()
	Local nError		:= 0
	Local cError		:= ""
	Local aStruct		:= {}
	Local aItemSA1		:= {}
	Local aDadosSA1		:= {}
	Local nFor,nFor1
	Local oCliente, oResponse

	//--------------------------------------------------------
	// Efetua a autenticacao do usuario
	//--------------------------------------------------------
	If cAuth <> Nil 
		If Substr(cAuth,1,6) == "Basic "
			cAuth := substr(cAuth, 7)
			lAuthorized := u_basicAuth(cAuth)
		Endif
	Endif

	If !lAuthorized
		oResponse := JsonObject():New()
		oResponse["Cliente"]:= {}
		oCliente := JsonObject():New()
		oCliente["errorCode"] 	 := 401
		oCliente["errorMessage"] := EncodeUTF8("Acesso não autorizado ou tipo de Autorizaçaõ inválido")
		aAdd(oResponse["Cliente"], oCliente)
		Self:SetResponse(oResponse:toJson())
		Return(.T.)
	EndIf
	
	If FindFunction("WfPrepEnv")

		//*****************************************************************
		// Cofigura empresa/filial
		//*****************************************************************
		RpcSetEnv( _cEmpresa,_cFilial,,, "GET", "METHOD", aTabs,,,,)
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
	
	//*****************************************************************
	// Posiciona no cadastro de clientes
	//*****************************************************************
	dbSelectArea("SA1")
	dbSetOrder(1)
	dbGoTop()
	
	If ! dbSeek (FwFilial("SA1") + _cCliente + _cLoja)

		nError := 513
		cError := 'Cliente e Loja não encontrados'

	Else

		aStruct := {}
		aStruct := SA1->(DBSTRUCT())
		aStruct	:= FWVetByDic(aStruct,"SA1")		// Carlos Eduardo Saturnino em 11/10/2021

		For nFor := 1 to len(aStruct)

			aAdd(aDadosSA1, 'oCliente["'+aStruct[nFor][1]+'"] := '+ iif(aStruct[nFor][2]=='C','"'+Alltrim(&('SA1->'+aStruct[nFor][1]))+'"',iif(aStruct[nFor][2]=='N',CVALTOCHAR(&('SA1->'+aStruct[nFor][1])),iif(aStruct[nFor][2]=='D','"'+ Alltrim(dtos(&('SA1->'+aStruct[nFor][1])))+'"','""'))))	

		Next nFor

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ coloca no Array para apresentar corretamente no metodo       ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aadd(aItemSA1,aclone(aDadosSA1))

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Retorno do processo criado ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Endif

	oResponse := JsonObject():New()
	oResponse["Cliente"]:= {}
	oCliente := JsonObject():New()
	If nError == 0

		For nFor := 1 to len(aItemSA1)
			For nFor1 := 1 to len(aItemSA1[nFor])
				&(aItemSA1[nFor][nFor1])
			next nFor1
		Next nFor
		aAdd(oResponse["Cliente"], oCliente)
		Self:SetResponse(oResponse:toJson())

	Else
		oCliente["errorCode"] 	 := nError
		oCliente["errorMessage"] := EncodeUTF8(cError)
		aAdd(oResponse["Cliente"], oCliente)
		Self:SetResponse(oResponse:toJson())

	Endif

	//-------------------------------------------------------------------
	// Restauro a area de trabalho
	//-------------------------------------------------------------------
	RestArea(aArea)		

	RpcClearEnv()
	
Return(.T.)

/********************************************************************
{Protheus.doc} 	GET product
TODO 			Retorna cadastro de produto
@since 			04/09/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			WsMethod Rest
********************************************************************/
WSMETHOD GET product WSRECEIVE cProduto WSSERVICE Especial001

	Local _cProduto		:= Self:cProduto
	Local cAuth 		:= Iif(!Empty(::GetHeader('Authorization')),::GetHeader('Authorization'),Nil)
	Local lAuthorized	:= .F.
	Local aTabs			:= {'SB1'}
	Local _cEmpresa		:= "01"
	Local _cFilial		:= "01"
	Local _lSegue		:= .F.
	Local aArea			:= GetArea()
	Local nError		:= 0
	Local cError		:= ""
	Local aStruct		:= {}
	Local aItemSB1		:= {}
	Local aDadosSB1		:= {}
	Local nFor,nFor1
	Local oProduto, oResponse

	//--------------------------------------------------------
	// Efetua a autenticacao do usuario
	//--------------------------------------------------------
	If cAuth <> Nil 
		If Substr(cAuth,1,6) == "Basic "
			cAuth := substr(cAuth, 7)
			lAuthorized := u_basicAuth(cAuth)
		Endif
	Endif
	
	If !lAuthorized 
		oResponse := JsonObject():New()
		oResponse["Produto"]:= {}
		oProduto := JsonObject():New()
		oProduto["errorCode"] 	 := 401
		oProduto["errorMessage"] := EncodeUTF8("Acesso não autorizado ou tipo de autorização inválido")
		aAdd(oResponse["Produto"], oProduto)
		Self:SetResponse(oResponse:toJson())
		Return(.T.)
	EndIf
	
	If FindFunction("WfPrepEnv")

		//*****************************************************************
		// Cofigura empresa/filial
		//*****************************************************************
		RpcSetEnv( _cEmpresa,_cFilial,,, "GET", "METHOD", aTabs,,,,)
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
	
	//*****************************************************************
	// Posiciona no cadastro de clientes
	//*****************************************************************
	dbSelectArea("SB1")
	dbSetOrder(1)
	dbGoTop()
	
	If !dbSeek(FwFilial("SB1") + _cProduto)

		nError := 513
		cError := 'Produto não encontrados'

	Else

		aStruct := {}
		aStruct := SB1->(DBSTRUCT())
		aStruct	:= FWVetByDic(aStruct,"SB1")		// Carlos Eduardo Saturnino em 11/10/2021

		For nFor := 1 to len(aStruct)

			aAdd(aDadosSB1, 'oProduto["'+aStruct[nFor][1]+'"] := '+ iif(aStruct[nFor][2]=='C','"'+Alltrim(&('SB1->'+aStruct[nFor][1]))+'"',iif(aStruct[nFor][2]=='N',CVALTOCHAR(&('SB1->'+aStruct[nFor][1])),iif(aStruct[nFor][2]=='D','"'+ Alltrim(dtos(&('SB1->'+aStruct[nFor][1])))+'"','""'))))	

		Next nFor

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ coloca no Array para apresentar corretamente no metodo       ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aadd(aItemSB1,aclone(aDadosSB1))

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Retorno do processo criado ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Endif

	oResponse := JsonObject():New()
	oResponse["Produto"]:= {}
	oProduto  := JsonObject():New()
	If nError == 0

		For nFor := 1 to len(aItemSB1)
			For nFor1 := 1 to len(aItemSB1[nFor])
				&(aItemSB1[nFor][nFor1])
			next nFor1
		Next nFor
		aAdd(oResponse["Produto"], oProduto)
		Self:SetResponse(oResponse:toJson())

	Else
		oProduto["errorCode"] 	 := nError
		oProduto["errorMessage"] := EncodeUTF8(cError)
		aAdd(oResponse["Produto"], oProduto)
		Self:SetResponse(oResponse:toJson())

	Endif

	//-------------------------------------------------------------------
	// Restauro a area de trabalho
	//-------------------------------------------------------------------
	RestArea(aArea)		

	RpcClearEnv()
	
Return(.T.)

/********************************************************************
{Protheus.doc} 	GET product
TODO 			Retorna Condicao de Pagamento
@since 			04/09/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			WsMethod Rest
********************************************************************/
WSMETHOD GET paymentcondition WSRECEIVE cCondicao WSSERVICE Especial001

	Local _cCondicao	:= Self:cCondicao
	Local cAuth 		:= Iif(!Empty(::GetHeader('Authorization')),::GetHeader('Authorization'),Nil)
	Local lAuthorized	:= .F.	
	Local aTabs			:= {'SE4'}
	Local _cEmpresa		:= "01"
	Local _cFilial		:= "01"
	Local _lSegue		:= .F.
	Local aArea			:= GetArea()
	Local nError		:= 0
	Local cError		:= ""
	Local aStruct		:= {}
	Local aItemSE4		:= {}
	Local aDadosSE4		:= {}
	Local nFor,nFor1
	Local oCondicao, oResponse

	//--------------------------------------------------------
	// Efetua a autenticacao do usuario
	//--------------------------------------------------------
	If cAuth <> Nil 
		If Substr(cAuth,1,6) == "Basic "
			cAuth := substr(cAuth, 7)
			lAuthorized := u_basicAuth(cAuth)
		Endif
	Endif

	If !lAuthorized
		oResponse := JsonObject():New()
		oResponse["Condicao"]:= {}
		oCondicao := JsonObject():New()
		oCondicao["errorCode"] 	 := 401
		oCondicao["errorMessage"] := EncodeUTF8("Acesso não autorizado ou tipo de Autorizaçaõ inválido")
		aAdd(oResponse["Condicao"], oCondicao)
		Self:SetResponse(oResponse:toJson())
		Return(.T.)
	EndIf

	If FindFunction("WfPrepEnv")

		//*****************************************************************
		// Cofigura empresa/filial
		//*****************************************************************
		RpcSetEnv( _cEmpresa,_cFilial,,, "GET", "METHOD", aTabs,,,,)
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
	
	//*****************************************************************
	// Posiciona no cadastro de clientes
	//*****************************************************************
	dbSelectArea("SE4")
	dbSetOrder(1)		// E4_FILIAL+E4_CODIGO
	dbGoTop()
	
	If ! dbSeek (FwFilial("SE4") + _cCondicao)

		nError := 513
		cError := 'Condição de Pagamento não encontrada'

	Else

		aStruct := {}
		aStruct := SE4->(DBSTRUCT())
		aStruct	:= FWVetByDic(aStruct,"SE4")		// Carlos Eduardo Saturnino em 11/10/2021

		For nFor := 1 to len(aStruct)

			aAdd(aDadosSE4, 'oCondicao["'+aStruct[nFor][1]+'"] := '+ iif(aStruct[nFor][2]=='C','"'+Alltrim(&('SE4->'+aStruct[nFor][1]))+'"',iif(aStruct[nFor][2]=='N',CVALTOCHAR(&('SE4->'+aStruct[nFor][1])),iif(aStruct[nFor][2]=='D','"'+ Alltrim(dtos(&('SE4->'+aStruct[nFor][1])))+'"','""'))))	

		Next nFor

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ coloca no Array para apresentar corretamente no metodo       ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aadd(aItemSE4,aclone(aDadosSE4))

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Retorno do processo criado ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Endif

	oResponse := JsonObject():New()
	oResponse["Condicao"]:= {}
	oCondicao  := JsonObject():New()
	If nError == 0

		For nFor := 1 to len(aItemSE4)
			For nFor1 := 1 to len(aItemSE4[nFor])
				&(aItemSE4[nFor][nFor1])
			next nFor1
		Next nFor
		aAdd(oResponse["Condicao"], oCondicao)
		Self:SetResponse(oResponse:toJson())

	Else
		oCondicao["errorCode"] 	 := nError
		oCondicao["errorMessage"] := EncodeUTF8(cError)
		aAdd(oResponse["Condicao"], oCondicao)
		Self:SetResponse(oResponse:toJson())

	Endif

	//-------------------------------------------------------------------
	// Restauro a area de trabalho
	//-------------------------------------------------------------------
	RestArea(aArea)		

	RpcClearEnv()
	
Return(.T.)

/********************************************************************
{Protheus.doc} 	GET invoice
TODO 			Retorna pedidos de vendas especiais
@since 			19/08/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			WsMethod Rest
********************************************************************/
WSMETHOD GET invoice WSRECEIVE  WSSERVICE Especial001

	Local aArea			:= GetArea()
	Local cAuth 		:= Iif(!Empty(::GetHeader('Authorization')),::GetHeader('Authorization'),Nil)
	Local lAuthorized	:= .F.
	Local cAliasTmp		:= GetNextAlias()
	Local aDebug		:= {}
	Local cSetResp		:= ''
	Local cPedido		:= ''
	Local nX			:= 1
	Local nZ			:= 1
	Local _cEmpresa		:= "01"
	Local _cFilial		:= "01"
	Local aTabs			:= {'SC5','SC6'}
	Local _lSegue		:= .F.
	Local oCabecalho, oResponse
	//--------------------------------------------------------
	// Efetua a autenticacao do usuario
	//--------------------------------------------------------
	If cAuth <> Nil 
		If Substr(cAuth,1,6) == "Basic "
			cAuth := substr(cAuth, 7)
			lAuthorized := u_basicAuth(cAuth)
		Endif
	Endif

	If !lAuthorized
		oResponse := JsonObject():New()
		oResponse["cabecalho"]:= {}
		oCabecalho := JsonObject():New()
		oCabecalho["errorCode"] 	 := 401
		oCabecalho["errorMessage"] := EncodeUTF8("Acesso não autorizado ou tipo de Autorizaçaõ inválido")
		aAdd(oResponse["cabecalho"], oCabecalho)
		Self:SetResponse(oResponse:toJson())
		Return(.T.)
	EndIf

	If FindFunction("WfPrepEnv")

		//*****************************************************************
		// Cofigura empresa/filial
		//*****************************************************************
		RpcSetEnv( _cEmpresa,_cFilial,,, "GET", "METHOD", aTabs,,,,)
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

	//---------------------------------------------------------
	//Verifica se há conexão em aberto, caso haja fecha.
	//---------------------------------------------------------
	IF Select(cAliasTmp) > 0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf

	//---------------------------------------------------------
	// Efetua a consulta conforme os parametros passados
	//---------------------------------------------------------
	BeginSql Alias cAliasTmp

		SELECT		*
		FROM 		%Table:SC6% C6
		INNER JOIN	%Table:SC5% C5
		ON 			C5.C5_FILIAL 	=  C6.C6_FILIAL
		AND			C5.C5_NUM 		=  C6.C6_NUM
		AND			C5.C5_CLIENTE	=  C6.C6_CLI
		AND			C5.C5_LOJACLI	=  C6.C6_LOJA
		WHERE		C5.C5_ZZTPPED 	=  'VE'
		AND			C5.C5_NOTA 		=  ''
		AND			C5.%NotDel%
		AND			C6.%NotDel%
		ORDER BY	C5.C5_NUM, C6.C6_ITEM

	EndSql

	//---------------------------------------------------------
	// Guarda a Query efetuada para consulta
	//---------------------------------------------------------
	aDebug := GetLastQuery()

	//---------------------------------------------------------
	// Posiciona no primeiro registro da Query
	//---------------------------------------------------------
	dbSelectArea(cAliasTmp)
	(cAliasTmp)->( DbGoTop() )

	If (cAliasTmp)->( Eof() ) 

		cSetResp := '[{"retorno":"Nao existe itens nessa consulta !! " }]'

	Else

		cSetResp	:= '['

		While (cAliasTmp)->( !Eof() )

			If nX > 1
				cSetResp  +=', '
			EndIf

			cPedido   :=  (cAliasTmp)->C5_NUM

			cSetResp  += '{'
			cSetResp  += Lower('"EMPRESA":"')		+ FWCodEmp()
			cSetResp  += Lower('","C5_FILIAL":"')	+ TRIM((cAliasTmp)->C5_FILIAL)
			cSetResp  += Lower('","C5_TIPO":"')		+ TRIM((cAliasTmp)->C5_TIPO)
			cSetResp  += Lower('","C5_NUM":"')		+ TRIM((cAliasTmp)->C5_NUM)			
			cSetResp  += Lower('","C5_CLIENTE":"')	+ TRIM((cAliasTmp)->C5_CLIENTE)
			cSetResp  += Lower('","C5_LOJACLI":"')	+ TRIM((cAliasTmp)->C5_LOJACLI)
			cSetResp  += Lower('","C5_EMISSAO":"')	+ TRIM((cAliasTmp)->C5_EMISSAO)
			cSetResp  += Lower('","C5_CONDPAG":"')	+ TRIM((cAliasTmp)->C5_CONDPAG)
			cSetResp  += Lower('","C5_TPFRETE":"')	+ TRIM((cAliasTmp)->C5_TPFRETE)
			cSetResp  += Lower('","C5_MENNOTA":"')	+ TRIM((cAliasTmp)->C5_MENNOTA)
			cSetResp  += Lower('","C5_ZZOBS":"') 	+ TRIM((cAliasTmp)->C5_ZZOBS)
			cSetResp  += Lower('","C5_VEND1":"') 	+ TRIM((cAliasTmp)->C5_VEND1)
			cSetResp  += Lower('","C5_DESC1":') 	+ cValToChar((cAliasTmp)->C5_DESC1)
			cSetResp  += Lower(',"C5_TABELA":"') 	+ TRIM((cAliasTmp)->C5_TABELA)
			cSetResp  += Lower('","C5_ZZNPEXT":"')	+ TRIM((cAliasTmp)->C5_ZZNPEXT)
			cSetResp  += Lower('","C5_ZZTPPED":"')	+ TRIM((cAliasTmp)->C5_ZZTPPED)
			cSetResp  += Lower('","C5_ZZDTEMI":"')	+ TRIM((cAliasTmp)->C5_ZZDTEMI)
			cSetResp  += Lower('","C5_ZZORIGE":"')	+ TRIM((cAliasTmp)->C5_ZZORIGE)
			cSetResp  += '"},'
			cSetResp  += '['

			nX++
			
			While (cAliasTmp)->( !Eof() ) .And. (cAliasTmp)->C6_NUM   ==  cPedido

				If nZ > 1
					cSetResp  +=', '
				EndIf

				cSetResp  += '{'
				cSetResp  += Lower('"C6_ITEM":"')		+ TRIM((cAliasTmp)->C6_ITEM)
				cSetResp  += Lower('","C6_PRODUTO":"')	+ TRIM((cAliasTmp)->C6_PRODUTO)
				cSetResp  += Lower('","C6_QTDVEN":') 	+ cValToChar((cAliasTmp)->C6_QTDVEN)
				cSetResp  += Lower(',"C6_PRCVEN":') 	+ cValToChar((cAliasTmp)->C6_PRCVEN)
				cSetResp  += Lower(',"C6_OPER":"') 		+ TRIM((cAliasTmp)->C6_OPER)
				cSetResp  += Lower('","C6_DESCONT":')	+ cValToChar((cAliasTmp)->C6_DESCONT) 
				cSetResp  += '}'

				(cAliasTmp)->(dbSkip())
				
				nZ++
				
			EndDo

			cSetResp  += ']'
			
			nZ := 1
			
		EndDo

		cSetResp  += ']'

	EndIf

	//---------------------------------------------------------
	// Fecha a tabela
	//---------------------------------------------------------
	(cAliasTmp)->(DbCloseArea())

	//---------------------------------------------------------
	// Envia o JSON Gerado para a aplicação Cliente
	//---------------------------------------------------------
	::SetResponse( cSetResp )

	//---------------------------------------------------------
	// Restaura area
	//---------------------------------------------------------
	RestArea(aArea)

Return(.T.)

/********************************************************************
{Protheus.doc} 	GET vendor
TODO 			Retorna Vendedor
@since 			18/09/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			WsMethod Rest
********************************************************************/
WSMETHOD GET vendor WSRECEIVE cVendedor WSSERVICE Especial001

	Local _cVendedor	:= Self:cVendedor
	Local cAuth 		:= Iif(!Empty(::GetHeader('Authorization')),::GetHeader('Authorization'),Nil)
	Local lAuthorized	:= .F.	
	Local aTabs			:= {'SA3'}
	Local _cEmpresa		:= "01"
	Local _cFilial		:= "01"
	Local _lSegue		:= .F.
	Local aArea			:= GetArea()
	Local nError		:= 0
	Local cError		:= ""
	Local aStruct		:= {}
	Local aItemSA3		:= {}
	Local aDadosSA3		:= {}
	Local nFor,nFor1
	Local oVendedor, oResponse

	//--------------------------------------------------------
	// Efetua a autenticacao do usuario
	//--------------------------------------------------------
	If cAuth <> Nil 
		If Substr(cAuth,1,6) == "Basic "
			cAuth := substr(cAuth, 7)
			lAuthorized := u_basicAuth(cAuth)
		Endif
	Endif

	If !lAuthorized
		oResponse 					:= JsonObject():New()
		oResponse["Vendedor"]		:= {}
		oVendedor 					:= JsonObject():New()
		oVendedor["errorCode"] 		:= 401
		oVendedor["errorMessage"] 	:= EncodeUTF8("Acesso não autorizado ou tipo de Autorizaçaõ inválido")
		aAdd(oResponse["Vendedor"], oVendedor)
		Self:SetResponse(oResponse:toJson())
		Return(.T.)
	EndIf

	If FindFunction("WfPrepEnv")

		//*****************************************************************
		// Cofigura empresa/filial
		//*****************************************************************
		RpcSetEnv( _cEmpresa,_cFilial,,, "GET", "METHOD", aTabs,,,,)
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
	
	//*****************************************************************
	// Posiciona no cadastro de vendedores
	//*****************************************************************
	dbSelectArea("SA3")
	dbSetOrder(1)		// A3_FILIAL+A3_COD
	dbGoTop()
	
	If ! dbSeek (FwFilial("SA3") + _cVendedor)

		nError := 513
		cError := 'Vendedor não encontrada'

	Else

		aStruct := {}
		aStruct := SA3->(DBSTRUCT())
		aStruct	:= FWVetByDic(aStruct,"SA3")		// Carlos Eduardo Saturnino em 11/10/2021		

		For nFor := 1 to len(aStruct)

			aAdd(aDadosSA3, 'oVendedor["'+aStruct[nFor][1]+'"] := '+ iif(aStruct[nFor][2]=='C','"'+Alltrim(&('SA3->'+aStruct[nFor][1]))+'"',iif(aStruct[nFor][2]=='N',CVALTOCHAR(&('SA3->'+aStruct[nFor][1])),iif(aStruct[nFor][2]=='D','"'+ Alltrim(dtos(&('SA3->'+aStruct[nFor][1])))+'"','""'))))	

		Next nFor

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ coloca no Array para apresentar corretamente no metodo       ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aadd(aItemSA3,aclone(aDadosSA3))

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Retorno do processo criado ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

	Endif

	oResponse := JsonObject():New()
	oResponse["Vendedor"]:= {}
	oVendedor  := JsonObject():New()
	If nError == 0

		For nFor := 1 to len(aItemSA3)
			For nFor1 := 1 to len(aItemSA3[nFor])
				&(aItemSA3[nFor][nFor1])
			next nFor1
		Next nFor
		aAdd(oResponse["Vendedor"], oVendedor)
		Self:SetResponse(oResponse:toJson())

	Else
		oVendedor["errorCode"] 	 := nError
		oVendedor["errorMessage"] := EncodeUTF8(cError)
		aAdd(oResponse["Vendedor"], oVendedor)
		Self:SetResponse(oResponse:toJson())

	Endif

	//-------------------------------------------------------------------
	// Restauro a area de trabalho
	//-------------------------------------------------------------------
	RestArea(aArea)		

	RpcClearEnv()
	
Return(.T.)
