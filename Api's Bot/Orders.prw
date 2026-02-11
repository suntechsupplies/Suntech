#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "TopConn.ch"
#Include "FWMVCDef.ch"
#Include "Totvs.ch"

//=============================================================
// API: Orders - Sales Order Management REST API
// Version: 2.0
// Author: Suntech
// Description: REST API for sales order CRUD operations
//=============================================================

#Define API_VERSION         "2.0"
#Define DEFAULT_PAGE_SIZE   100

//=============================================================
// REST Service Definition
//=============================================================
WSRESTFUL Orders DESCRIPTION "Sales Order Management REST API v2.0"

	WSDATA page        As Integer Optional
	WSDATA pageSize    As Integer Optional
	WSDATA orderNumber As String Optional  // C5_NUM
	WSDATA externalId  As String Optional   // C5_ZZNPEXT
	WSDATA pending     As Integer Optional  // 1 = sem nota fiscal
	WSDATA branch      As String Optional   // Filial (default "01")

	WSMETHOD GET    DESCRIPTION "Retrieve sales orders"     WSSYNTAX "/orders"
	WSMETHOD POST   DESCRIPTION "Create new sales order"    WSSYNTAX "/orders"
	WSMETHOD PUT    DESCRIPTION "Update existing order"     WSSYNTAX "/orders"

END WSRESTFUL

//=============================================================
// User Function - Entry Point
//=============================================================
User Function Orders()
Return .T.

//=============================================================
// GET Method - Retrieve Orders
//=============================================================
WSMETHOD GET WSRECEIVE page, pageSize, orderNumber, externalId, pending, branch WSSERVICE Orders

	Local lRet       := .T.
	Local aTabs      := {}
	Local _cEmpresa  := "01"
	Local _cFilial   := "01"

	::SetContentType("application/json")

	// Get branch from query parameter
	If !Empty(Self:branch)
		_cFilial := Self:branch
	EndIf

	// Setup Environment
	aTabs := {"SC5", "SC6", "SA1", "SA2", "SA3", "SA4", "SB1", "SB2", "SE4", "SF4", "DA0", "DA1"}
	RpcSetEnv(_cEmpresa, _cFilial,,,,GetEnvServer(),aTabs)
	// Forca filial apos RpcSetEnv (seguindo padrao EJPedVen)
	cEmpAnt := _cEmpresa
	cFilAnt := _cFilial
	cNumEmp := _cEmpresa + _cFilial

	// Execute Query
	If !Empty(Self:orderNumber) .Or. !Empty(Self:externalId)
		lRet := GetSingleOrder(Self)
	Else
		lRet := GetOrderList(Self)
	EndIf

Return lRet

//=============================================================
// POST Method - Create Order (single or batch)
//=============================================================
WSMETHOD POST WSSERVICE Orders

	Local lRet       := .T.
	Local oResponse  := Nil
	Local cJson      := Self:GetContent()
	Local oObj       := Nil
	Local aTabs      := {}
	Local _cEmpresa  := "01"
	Local _cFilial   := "01"
	Local aOrders    := {}
	Local aResults   := {}
	Local nI         := 0
	Local oOrderObj  := Nil
	Local oResItem   := Nil
	Local lBatch     := .F.
	Local lAllOk     := .T.
	Local cBranch    := ""

	::SetContentType("application/json")

	// Deserialize JSON using JsonObject (native class with safe property access)
	oObj := JsonObject():New()
	If oObj:FromJson(cJson) != Nil
		oResponse := BuildResponse(.F., "Invalid JSON format", Nil, Nil)
		::SetStatus(400)
		::SetResponse(oResponse)
		Return .F.
	EndIf

	// Get branch from query parameter
	If !Empty(Self:branch)
		_cFilial := Self:branch
	EndIf

	// Detect batch mode: {"orders": [...]}
	// Check raw JSON for "orders" key to avoid invalid property error
	lBatch := ('"orders"' $ cJson)
	If lBatch
		aOrders := GetJsonArray(oObj, "orders")
		lBatch  := (Len(aOrders) > 0)
	EndIf

	If !lBatch
		// Single order mode (backward compatible)
		// Read branch from JSON body if not in query parameter
		If Empty(Self:branch)
			cBranch := GetJsonString(oObj, "branch", _cFilial)
			If !Empty(cBranch)
				_cFilial := cBranch
			EndIf
		EndIf

		// Setup Environment
		aTabs := {"SC5", "SC6", "SA1", "SA2", "SA3", "SA4", "SB1", "SB2", "SE4", "SF4", "DA0", "DA1"}
		RpcSetEnv(_cEmpresa, _cFilial,,,,GetEnvServer(),aTabs)
		cEmpAnt := _cEmpresa
		cFilAnt := _cFilial
		cNumEmp := _cEmpresa + _cFilial

		ConOut("[ORDERS API] Environment setup - Empresa: " + cEmpAnt + " Filial: " + cFilAnt + " cNumEmp: " + cNumEmp)
		lRet := CreateOrder(Self, oObj)
	Else
		// Batch mode
		ConOut("[ORDERS API] BATCH mode - " + cValToChar(Len(aOrders)) + " orders")
		aResults := {}

		For nI := 1 To Len(aOrders)
			oOrderObj := aOrders[nI]

			// Each order can have its own branch, fallback to query param
			cBranch := GetJsonString(oOrderObj, "branch", _cFilial)
			If Empty(cBranch)
				cBranch := _cFilial
			EndIf

			ConOut("[ORDERS API] BATCH order " + cValToChar(nI) + "/" + cValToChar(Len(aOrders)) + " - Branch: " + cBranch)

			// Setup environment for each order (required for proper filial context)
			aTabs := {"SC5", "SC6", "SA1", "SA2", "SA3", "SA4", "SB1", "SB2", "SE4", "SF4", "DA0", "DA1"}
			RpcSetEnv(_cEmpresa, cBranch,,,,GetEnvServer(),aTabs)
			cEmpAnt := _cEmpresa
			cFilAnt := cBranch
			cNumEmp := _cEmpresa + cBranch

			ConOut("[ORDERS API] xFilial SC5: [" + xFilial("SC5") + "] SF4: [" + xFilial("SF4") + "]")

			// Create order using internal batch function
			oResItem := CrtOrdBatch(oOrderObj, nI)
			aAdd(aResults, oResItem)

			If oResItem['success'] == .F.
				lAllOk := .F.
			EndIf
		Next nI

		// Build batch response
		oResponse := JsonObject():New()
		oResponse['success']      := lAllOk
		oResponse['message']      := IIf(lAllOk, "All orders created successfully", "Some orders failed")
		oResponse['totalOrders']  := Len(aOrders)
		oResponse['results']      := aResults

		::SetStatus(IIf(lAllOk, 201, 207)) // 207 = Multi-Status
		::SetResponse(FWJsonSerialize(oResponse, .T.))
		lRet := lAllOk
	EndIf

Return lRet

//=============================================================
// PUT Method - Update Order
//=============================================================
WSMETHOD PUT WSSERVICE Orders

	Local lRet       := .T.
	Local oResponse  := Nil
	Local cJson      := Self:GetContent()
	Local oObj       := Nil
	Local aTabs      := {}
	Local _cEmpresa  := "01"
	Local _cFilial   := "01"

	::SetContentType("application/json")

	// Deserialize JSON using JsonObject (same pattern as POST/EJPedVen)
	oObj := JsonObject():New()
	If oObj:FromJson(cJson) != Nil
		oResponse := BuildResponse(.F., "Invalid JSON format", Nil, Nil)
		::SetStatus(400)
		::SetResponse(oResponse)
		Return .F.
	EndIf

	// Get branch from query parameter
	If !Empty(Self:branch)
		_cFilial := Self:branch
	EndIf

	// Setup Environment
	aTabs := {"SC5", "SC6", "SA1", "SA2", "SA3", "SA4", "SB1", "SB2", "SE4", "SF4", "DA0", "DA1"}
	RpcSetEnv(_cEmpresa, _cFilial,,,,GetEnvServer(),aTabs)
	// Forca filial apos RpcSetEnv (seguindo padrao EJPedVen)
	cEmpAnt := _cEmpresa
	cFilAnt := _cFilial
	cNumEmp := _cEmpresa + _cFilial

	// Update Order
	lRet := UpdateOrder(Self, oObj)

Return lRet

//=============================================================
// GetOrderList - Retrieve paginated order list
//=============================================================
Static Function GetOrderList(oSelf)

	Local lRet       := .T.
	Local cAliasTmp  := GetNextAlias()
	Local nPage      := IIf(oSelf:page == Nil, 1, oSelf:page)
	Local nPageSize  := IIf(oSelf:pageSize == Nil, DEFAULT_PAGE_SIZE, oSelf:pageSize)
	Local nPending   := IIf(oSelf:pending == Nil, 0, oSelf:pending)
	Local nOffset    := (nPage - 1) * nPageSize
	Local nTotal     := 0
	Local nTotalPags := 0
	Local oResponse  := Nil
	Local aOrders    := {}
	Local oOrder     := Nil
	Local oPagination:= Nil
	Local cQuery     := ""

	// Build query
	cQuery := " SELECT "
	cQuery += "     C5.R_E_C_N_O_ AS RECNO, "
	cQuery += "     C5.C5_FILIAL, C5.C5_NUM, C5.C5_EMISSAO, C5.C5_CLIENTE, C5.C5_LOJACLI, "
	cQuery += "     C5.C5_CONDPAG, C5.C5_TABELA, C5.C5_TIPO, C5.C5_VEND1, C5.C5_TRANSP, "
	cQuery += "     C5.C5_TPFRETE, C5.C5_FRETE, C5.C5_MENNOTA, C5.C5_MOEDA, C5.C5_ZZNPEXT, "
	cQuery += "     C5.C5_ZZTPPED, C5.C5_ZZDTEMI, C5.C5_ZZORIGE, C5.C5_ZZOBS, C5.C5_ZZCUPOM, "
	cQuery += "     C5.C5_NOTA, C5.C5_SERIE, C5.C5_DESC1, "
	cQuery += "     A1.A1_NOME, A1.A1_CGC "
	cQuery += " FROM " + RetSqlName("SC5") + " C5 "
	cQuery += " LEFT JOIN " + RetSqlName("SA1") + " A1 ON A1.A1_COD = C5.C5_CLIENTE AND A1.A1_LOJA = C5.C5_LOJACLI AND A1.D_E_L_E_T_ = ' ' "
	cQuery += " WHERE C5.C5_FILIAL = '" + xFilial("SC5") + "' "
	cQuery += "   AND C5.D_E_L_E_T_ = ' ' "

	If nPending == 1
		cQuery += "   AND C5.C5_NOTA = '' "
	EndIf

	cQuery += " ORDER BY C5.C5_NUM DESC "
	cQuery += " OFFSET " + cValToChar(nOffset) + " ROWS "
	cQuery += " FETCH NEXT " + cValToChar(nPageSize) + " ROWS ONLY "

	// Close alias if already open
	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	// Execute query
	TCQuery cQuery New Alias (cAliasTmp)

	If (cAliasTmp)->(Eof())
		oResponse := BuildResponse(.T., "No orders found", {}, Nil)
		oSelf:SetContentType("application/json")
		oSelf:SetResponse(oResponse)
		(cAliasTmp)->(DbCloseArea())
		Return .T.
	EndIf

	// Build response array
	(cAliasTmp)->(DbGoTop())
	While !(cAliasTmp)->(Eof())
		oOrder := BuildOrderHeader(cAliasTmp)
		// Get items for this order
		oOrder['items'] := GetOrderItems((cAliasTmp)->C5_NUM)
		aAdd(aOrders, oOrder)
		(cAliasTmp)->(DbSkip())
	EndDo

	(cAliasTmp)->(DbCloseArea())

	// Get total records for pagination
	nTotal := GetTotalOrders(nPending)
	nTotalPags := Ceiling(nTotal / nPageSize)

	// Build pagination object
	oPagination := JsonObject():New()
	oPagination['page']         := nPage
	oPagination['pageSize']     := nPageSize
	oPagination['totalPages']   := nTotalPags
	oPagination['totalRecords'] := nTotal

	// Build final response
	oResponse := BuildResponse(.T., "Orders retrieved successfully", aOrders, oPagination)
	oSelf:SetContentType("application/json")
	oSelf:SetResponse(oResponse)

Return lRet

//=============================================================
// GetSingleOrder - Retrieve single order by number or externalId
//=============================================================
Static Function GetSingleOrder(oSelf)

	Local lRet        := .T.
	Local cOrderNum   := IIf(oSelf:orderNumber == Nil, "", oSelf:orderNumber)
	Local cExternalId := IIf(oSelf:externalId == Nil, "", oSelf:externalId)
	Local oResponse   := Nil
	Local oOrder      := Nil
	Local lFound      := .F.

	DbSelectArea("SC5")

	If !Empty(cOrderNum)
		DbSetOrder(1) // C5_FILIAL + C5_NUM
		lFound := DbSeek(xFilial("SC5") + PadR(cOrderNum, TamSX3("C5_NUM")[1]))
	ElseIf !Empty(cExternalId)
		DbSetOrder(12) // C5_FILIAL + C5_ZZNPEXT
		lFound := DbSeek(xFilial("SC5") + PadR(cExternalId, TamSX3("C5_ZZNPEXT")[1]))
	EndIf

	If !lFound
		oResponse := BuildResponse(.F., "Order not found", Nil, Nil)
		oSelf:SetContentType("application/json")
		oSelf:SetStatus(404)
		oSelf:SetResponse(oResponse)
		Return .F.
	EndIf

	// Build order object
	oOrder := BuildOrderHeader("SC5")
	oOrder['items'] := GetOrderItems(SC5->C5_NUM)

	oResponse := BuildResponse(.T., "Order found", oOrder, Nil)
	oSelf:SetContentType("application/json")
	oSelf:SetResponse(oResponse)

Return lRet

//=============================================================
// CrtOrdBatch - Create a single order in batch mode (returns JSON object)
//=============================================================
Static Function CrtOrdBatch(oObj, nSeqOrder)

	Local oResItem   := JsonObject():New()
	Local aDadosC5   := {}
	Local aDadosC6   := {}
	Local aLin       := {}
	Local cExternalId:= ""
	Local cNumPed    := ""
	Local cError     := ""
	Local oResult    := Nil
	Local oError     := Nil
	Local bOldErr    := Nil
	Local aItems     := {}
	Local nX         := 0
	Local oItem      := Nil
	Local aLogAuto   := {}
	Local lOrderCreated := .F.

	Private lMsErroAuto    := .F.
	Private lMsHelpAuto    := .T.
	Private lAutoErrNoFile := .T.
	Private _lAprov        := .F.  // Suprime Alcadas de Aprovacao (AO4) - necessario em batch/API
	Private lAlcada        := .F.  // Suprime Alcadas de Aprovacao (AO4) - necessario em batch/API

	oResItem['order']   := nSeqOrder
	oResItem['success'] := .F.

	bOldErr := ErrorBlock({|e| oError := e, Break(e)})

	Begin Sequence

		// Validate
		If !ValidateOrderData(oObj, @cError, .T.)
			oResItem['message'] := cError
			ErrorBlock(bOldErr)
			Return oResItem
		EndIf

		// ExternalId duplicate check
		cExternalId := GetJsonString(oObj, "externalId", "")
		If !Empty(cExternalId)
			DbSelectArea("SC5")
			DbSetOrder(12)
			If DbSeek(xFilial("SC5") + PadR(cExternalId, TamSX3("C5_ZZNPEXT")[1]))
				oResItem['message']     := "Order with this externalId already exists"
				oResItem['orderNumber'] := AllTrim(SC5->C5_NUM)
				oResItem['externalId']  := AllTrim(SC5->C5_ZZNPEXT)
				ErrorBlock(bOldErr)
				Return oResItem
			EndIf
		EndIf

		// Build header
		aDadosC5 := MakeOrderHeaderArray(oObj)

		// Build items
		aItems := GetJsonArray(oObj, "items")
		If Len(aItems) == 0
			oResItem['message'] := "At least one item is required"
			ErrorBlock(bOldErr)
			Return oResItem
		EndIf

		For nX := 1 To Len(aItems)
			oItem := aItems[nX]
			aLin := MakeOrderItemArray(oItem, nX)
			aAdd(aDadosC6, aLin)
		Next nX

		// Position tables
		PositionTables()

		// Limpa log anterior
		If FindFunction("MsUnlockAll")
			MsUnlockAll()
		EndIf

		// Execute MATA410
		ConOut("[ORDERS API] BATCH #" + cValToChar(nSeqOrder) + " - Executing MATA410...")
		lMsErroAuto := .F.
		MsExecAuto({|w,x,y,z| MATA410(w,x,y,z)}, aDadosC5, aDadosC6, 3, .F.)

		If lMsErroAuto
			// Verifica se o pedido foi criado mesmo com erro (ex: erro AO4 pos-commit)
			lOrderCreated := .F.
			If !Empty(cExternalId)
				DbSelectArea("SC5")
				DbSetOrder(12)
				If DbSeek(xFilial("SC5") + PadR(cExternalId, TamSX3("C5_ZZNPEXT")[1]))
					lOrderCreated := .T.
					cNumPed := SC5->C5_NUM
				EndIf
			EndIf

			If lOrderCreated
				// Pedido criado OK, erro AO4/pos-commit nao afetou o pedido
				ConOut("[ORDERS API] BATCH #" + cValToChar(nSeqOrder) + " - Order created despite post-commit error. Num: " + AllTrim(cNumPed))
			Else
				If FindFunction("DisarmTransaction")
					DisarmTransaction()
				EndIf

				aLogAuto := GetAutoGrLog()
				ParseAutoErrors(aLogAuto, @cError, @oResult)
				FillSentData(oResult, aDadosC5, aDadosC6)

				If Empty(cError)
					cError := "Erro no MsExecAuto MATA410"
				EndIf

				oResItem['message'] := cError
				oResItem['data']    := oResult
				ErrorBlock(bOldErr)
				Return oResItem
			EndIf
		EndIf

		// Success - posiciona no pedido criado
		If Empty(cNumPed)
			// Se nao veio do fallback AO4, pega direto do SC5 posicionado
			DbSelectArea("SC5")
			If !Empty(cExternalId)
				DbSetOrder(12)
				DbSeek(xFilial("SC5") + PadR(cExternalId, TamSX3("C5_ZZNPEXT")[1]))
			EndIf
			cNumPed := SC5->C5_NUM
		EndIf

		oResItem['success']       := .T.
		oResItem['message']       := "Order created successfully"
		oResItem['orderNumber']   := AllTrim(cNumPed)
		oResItem['externalId']    := AllTrim(cExternalId)
		oResItem['branch']        := AllTrim(SC5->C5_FILIAL)
		oResItem['customerCode']  := AllTrim(SC5->C5_CLIENTE)
		oResItem['customerStore'] := AllTrim(SC5->C5_LOJACLI)
		oResItem['recno']         := SC5->(RecNo())

		Recover Using oError
		oResItem['message'] := "Unexpected error: " + oError:Description
	End

	ErrorBlock(bOldErr)

Return oResItem

//=============================================================
// CreateOrder - Insert new order with error handling
//=============================================================
Static Function CreateOrder(oSelf, oObj)

	Local lRet       := .T.
	Local oResponse  := Nil
	Local aDadosC5   := {}
	Local aDadosC6   := {}
	Local aLin       := {}
	Local cExternalId:= ""
	Local cNumPed    := ""
	Local cError     := ""
	Local oResult    := Nil
	Local oError     := Nil
	Local bOldErr    := Nil
	Local aItems     := {}
	Local nX         := 0
	Local oItem      := Nil
	Local aLogAuto   := {}
	Local nY         := 0
	Local cCustomer  := ""
	Local cStore     := ""
	Local cVendor    := ""
	Local cProduct   := ""

	Private lMsErroAuto    := .F.
	Private lMsHelpAuto    := .T.  // Ativa captura de help
	Private lAutoErrNoFile := .T.  // Mantem erros em memoria (GetAutoGrLog)
	Private _lAprov        := .F.  // Suprime Alcadas de Aprovacao (AO4) - necessario em API
	Private lAlcada        := .F.  // Suprime Alcadas de Aprovacao (AO4) - necessario em API

	// Set up error handler
	bOldErr := ErrorBlock({|e| oError := e, Break(e)})

	Begin Sequence

		// Validate required fields
		If !ValidateOrderData(oObj, @cError, .T.)
			oResponse := BuildResponse(.F., cError, Nil, Nil)
			oSelf:SetContentType("application/json")
			oSelf:SetStatus(400)
			oSelf:SetResponse(oResponse)
			ErrorBlock(bOldErr)
			Return .F.
		EndIf

		// Get externalId
		cExternalId := GetJsonString(oObj, "externalId", "")

		// Check if order already exists (by externalId)
		If !Empty(cExternalId)
			DbSelectArea("SC5")
			DbSetOrder(12) // C5_FILIAL + C5_ZZNPEXT
			If DbSeek(xFilial("SC5") + PadR(cExternalId, TamSX3("C5_ZZNPEXT")[1]))
				oResult := JsonObject():New()
				oResult['orderNumber'] := AllTrim(SC5->C5_NUM)
				oResult['externalId']  := AllTrim(SC5->C5_ZZNPEXT)
				oResult['branch']      := AllTrim(SC5->C5_FILIAL)
				oResult['recno']       := SC5->(RecNo())
				oResponse := BuildResponse(.F., "Order with this externalId already exists", oResult, Nil)
				oSelf:SetContentType("application/json")
				oSelf:SetStatus(409) // Conflict
				oSelf:SetResponse(oResponse)
				ErrorBlock(bOldErr)
				Return .F.
			EndIf
		EndIf

		// Build header array (SC5)
		aDadosC5 := MakeOrderHeaderArray(oObj)

		// Build items array (SC6)
		aItems := GetJsonArray(oObj, "items")
		If Len(aItems) == 0
			oResponse := BuildResponse(.F., "At least one item is required", Nil, Nil)
			oSelf:SetContentType("application/json")
			oSelf:SetStatus(400)
			oSelf:SetResponse(oResponse)
			ErrorBlock(bOldErr)
			Return .F.
		EndIf

		For nX := 1 To Len(aItems)
			oItem := aItems[nX]
			aLin := MakeOrderItemArray(oItem, nX)
			aAdd(aDadosC6, aLin)
		Next nX

		// Position tables
		PositionTables()

		// Log the data being sent (for debugging)
		ConOut("[ORDERS API] Creating order - Branch: " + cFilAnt)
		ConOut("[ORDERS API] xFilial SC5: [" + xFilial("SC5") + "]")
		ConOut("[ORDERS API] xFilial SA1: [" + xFilial("SA1") + "]")
		ConOut("[ORDERS API] xFilial SB1: [" + xFilial("SB1") + "]")

		// Verify if customer exists in filial
		cCustomer := GetJsonString(oObj, "customerCode", "")
		cStore := GetJsonString(oObj, "customerStore", "01")
		DbSelectArea("SA1")
		DbSetOrder(1)
		If DbSeek(xFilial("SA1") + PadR(cCustomer, TamSX3("A1_COD")[1]) + PadR(cStore, TamSX3("A1_LOJA")[1]))
			ConOut("[ORDERS API] Customer " + cCustomer + "/" + cStore + " FOUND in filial [" + xFilial("SA1") + "]")
		Else
			ConOut("[ORDERS API] Customer " + cCustomer + "/" + cStore + " NOT FOUND in filial [" + xFilial("SA1") + "]")
		EndIf

		// Verify if vendor exists
		cVendor := GetJsonString(oObj, "vendorCode", "")
		If !Empty(cVendor)
			DbSelectArea("SA3")
			DbSetOrder(1)
			If DbSeek(xFilial("SA3") + PadR(cVendor, TamSX3("A3_COD")[1]))
				ConOut("[ORDERS API] Vendor " + cVendor + " FOUND in filial [" + xFilial("SA3") + "]")
			Else
				ConOut("[ORDERS API] Vendor " + cVendor + " NOT FOUND in filial [" + xFilial("SA3") + "]")
			EndIf
		EndIf

		// Verify first product
		If Len(aItems) > 0
			cProduct := GetJsonString(aItems[1], "productCode", "")
			DbSelectArea("SB1")
			DbSetOrder(1)
			If DbSeek(xFilial("SB1") + PadR(cProduct, TamSX3("B1_COD")[1]))
				ConOut("[ORDERS API] Product " + cProduct + " FOUND in filial [" + xFilial("SB1") + "]")
			Else
				ConOut("[ORDERS API] Product " + cProduct + " NOT FOUND in filial [" + xFilial("SB1") + "]")
			EndIf
		EndIf

		ConOut("[ORDERS API] Header fields: " + cValToChar(Len(aDadosC5)))
		ConOut("[ORDERS API] Item lines: " + cValToChar(Len(aDadosC6)))

		// Log header fields for debugging
		For nY := 1 To Len(aDadosC5)
			ConOut("[ORDERS API] SC5 - " + aDadosC5[nY][1] + ": " + cValToChar(aDadosC5[nY][2]))
		Next nY

		// Log item fields for debugging
		If Len(aDadosC6) > 0
			For nY := 1 To Len(aDadosC6[1])
				ConOut("[ORDERS API] SC6 Item 1 - " + aDadosC6[1][nY][1] + ": " + cValToChar(aDadosC6[1][nY][2]))
			Next nY
		EndIf

		// Limpa log anterior do MsExecAuto
		If FindFunction("MsUnlockAll")
			MsUnlockAll()
		EndIf

		// Execute MATA410 (Include = 3)
		ConOut("[ORDERS API] Executing MsExecAuto MATA410...")
		lMsErroAuto := .F.
		MsExecAuto({|w,x,y,z| MATA410(w,x,y,z)}, aDadosC5, aDadosC6, 3, .F.)
		ConOut("[ORDERS API] MsExecAuto finished - lMsErroAuto: " + cValToChar(lMsErroAuto))

		If lMsErroAuto
			// Verifica se o pedido foi criado mesmo com erro (ex: erro AO4 pos-commit)
			cExternalId := GetJsonString(oObj, "externalId", "")
			If !Empty(cExternalId)
				DbSelectArea("SC5")
				DbSetOrder(12)
				If DbSeek(xFilial("SC5") + PadR(cExternalId, TamSX3("C5_ZZNPEXT")[1]))
					// Pedido criado OK, erro AO4/pos-commit nao afetou o pedido
					cNumPed := SC5->C5_NUM
					ConOut("[ORDERS API] Order created despite post-commit error. Num: " + AllTrim(cNumPed))

					oResult := JsonObject():New()
					oResult['orderNumber'] := AllTrim(cNumPed)
					oResult['externalId']  := AllTrim(cExternalId)
					oResult['branch']      := AllTrim(SC5->C5_FILIAL)
					oResult['customerCode']:= AllTrim(SC5->C5_CLIENTE)
					oResult['customerStore']:= AllTrim(SC5->C5_LOJACLI)
					oResult['recno']       := SC5->(RecNo())
					oResult['warning']     := "Order created but approval module reported a warning"

					oResponse := BuildResponse(.T., "Order created successfully", oResult, Nil)
					oSelf:SetContentType("application/json")
					oSelf:SetStatus(201)
					oSelf:SetResponse(oResponse)
					ErrorBlock(bOldErr)
					Return .T.
				EndIf
			EndIf

			// Descarta transacao pendente
			If FindFunction("DisarmTransaction")
				DisarmTransaction()
			EndIf

			// === Captura e parse de erros do MsExecAuto ===
			aLogAuto := GetAutoGrLog()
			ParseAutoErrors(aLogAuto, @cError, @oResult)

			// Se ParseAutoErrors nao extraiu campos, inclui os dados enviados
			FillSentData(oResult, aDadosC5, aDadosC6)

			// Fallback
			If Empty(cError)
				cError := "Erro no MsExecAuto MATA410 sem detalhes capturados"
			EndIf

			ConOut("[ORDERS API] MsExecAuto Error (CREATE): " + cError)
			oResponse := BuildErrorResponse(cError, oResult)
			oSelf:SetContentType("application/json")
			oSelf:SetStatus(422) // Unprocessable Entity
			oSelf:SetResponse(oResponse)
			ErrorBlock(bOldErr)
			Return .F.
		EndIf

		// SC5 is already positioned at the created record after MsExecAuto
		DbSelectArea("SC5")
		cNumPed := SC5->C5_NUM

		// Return created order data
		oResult := JsonObject():New()
		oResult['orderNumber'] := AllTrim(cNumPed)
		oResult['externalId']  := AllTrim(cExternalId)
		oResult['branch']      := AllTrim(SC5->C5_FILIAL)
		oResult['customerCode']:= AllTrim(SC5->C5_CLIENTE)
		oResult['customerStore']:= AllTrim(SC5->C5_LOJACLI)
		oResult['recno']       := SC5->(RecNo())

		oResponse := BuildResponse(.T., "Order created successfully", oResult, Nil)
		oSelf:SetContentType("application/json")
		oSelf:SetStatus(201) // Created
		oSelf:SetResponse(oResponse)

		Recover Using oError

		cError := "Unexpected error: " + oError:Description + " at " + oError:Operation
		If !Empty(oError:ErrorStack)
			cError += " | Stack: " + oError:ErrorStack
		EndIf

		ConOut("[ORDERS API] Unexpected Error (CREATE): " + cError)

		oResponse := BuildResponse(.F., FwNoAccent(cError), Nil, Nil)
		oSelf:SetContentType("application/json")
		oSelf:SetStatus(520)
		oSelf:SetResponse(oResponse)
		lRet := .F.

	End

	ErrorBlock(bOldErr)

Return lRet

//=============================================================
// UpdateOrder - Update existing order with error handling
//=============================================================
Static Function UpdateOrder(oSelf, oObj)

	Local lRet       := .T.
	Local oResponse  := Nil
	Local aDadosC5   := {}
	Local aDadosC6   := {}
	Local aLin       := {}
	Local cOrderNum  := ""
	Local cExternalId:= ""
	Local cError     := ""
	Local oResult    := Nil
	Local oError     := Nil
	Local bOldErr    := Nil
	Local aItems     := {}
	Local nX         := 0
	Local oItem      := Nil
	Local aLogAuto   := {}

	Private lMsErroAuto    := .F.
	Private lMsHelpAuto    := .T.  // Ativa captura de help
	Private lAutoErrNoFile := .T.  // Mantem erros em memoria (GetAutoGrLog)
	Private _lAprov        := .F.  // Suprime Alcadas de Aprovacao (AO4) - necessario em API
	Private lAlcada        := .F.  // Suprime Alcadas de Aprovacao (AO4) - necessario em API

	// Set up error handler
	bOldErr := ErrorBlock({|e| oError := e, Break(e)})

	Begin Sequence

		// Validate required fields for update
		If !ValidateOrderData(oObj, @cError, .F.)
			oResponse := BuildResponse(.F., cError, Nil, Nil)
			oSelf:SetContentType("application/json")
			oSelf:SetStatus(400)
			oSelf:SetResponse(oResponse)
			ErrorBlock(bOldErr)
			Return .F.
		EndIf

		// Get order identification
		cOrderNum   := GetJsonString(oObj, "orderNumber", "")
		cExternalId := GetJsonString(oObj, "externalId", "")

		If Empty(cOrderNum) .And. Empty(cExternalId)
			oResponse := BuildResponse(.F., "orderNumber or externalId is required for update", Nil, Nil)
			oSelf:SetContentType("application/json")
			oSelf:SetStatus(400)
			oSelf:SetResponse(oResponse)
			ErrorBlock(bOldErr)
			Return .F.
		EndIf

		// Check if order exists
		DbSelectArea("SC5")
		If !Empty(cOrderNum)
			DbSetOrder(1)
			If !DbSeek(xFilial("SC5") + PadR(cOrderNum, TamSX3("C5_NUM")[1]))
				oResponse := BuildResponse(.F., "Order not found", Nil, Nil)
				oSelf:SetContentType("application/json")
				oSelf:SetStatus(404)
				oSelf:SetResponse(oResponse)
				ErrorBlock(bOldErr)
				Return .F.
			EndIf
		Else
			DbSetOrder(12)
			If !DbSeek(xFilial("SC5") + PadR(cExternalId, TamSX3("C5_ZZNPEXT")[1]))
				oResponse := BuildResponse(.F., "Order not found", Nil, Nil)
				oSelf:SetContentType("application/json")
				oSelf:SetStatus(404)
				oSelf:SetResponse(oResponse)
				ErrorBlock(bOldErr)
				Return .F.
			EndIf
			cOrderNum := SC5->C5_NUM
		EndIf

		// Build header array (SC5)
		aDadosC5 := MakeOrderHeaderArray(oObj)
		aAdd(aDadosC5, {"C5_NUM", PadR(cOrderNum, TamSX3("C5_NUM")[1]), Nil})

		// Build items array (SC6)
		aItems := GetJsonArray(oObj, "items")
		If Len(aItems) > 0
			For nX := 1 To Len(aItems)
				oItem := aItems[nX]
				aLin := MakeOrderItemArray(oItem, nX)
				aAdd(aDadosC6, aLin)
			Next nX
		EndIf

		// Position tables
		PositionTables()

		// Execute MATA410 (Update = 4)
		lMsErroAuto := .F.
		MsExecAuto({|w,x,y,z| MATA410(w,x,y,z)}, aDadosC5, aDadosC6, 4, .F.)

		If lMsErroAuto
			// Descarta transacao pendente
			If FindFunction("DisarmTransaction")
				DisarmTransaction()
			EndIf

			aLogAuto := GetAutoGrLog()
			cError := ""
			ParseAutoErrors(aLogAuto, @cError, @oResult)

			// Se ParseAutoErrors nao extraiu campos, inclui os dados enviados
			FillSentData(oResult, aDadosC5, aDadosC6)

			If Empty(cError)
				cError := "Erro no MsExecAuto MATA410 UPDATE - Pedido: " + cOrderNum
			EndIf

			ConOut("[ORDERS API] MsExecAuto Error (UPDATE): " + cError)
			oResponse := BuildErrorResponse(cError, oResult)
			oSelf:SetContentType("application/json")
			oSelf:SetStatus(422)
			oSelf:SetResponse(oResponse)
			ErrorBlock(bOldErr)
			Return .F.
		EndIf

		// Reposition to get data
		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSeek(xFilial("SC5") + PadR(cOrderNum, TamSX3("C5_NUM")[1]))

		// Return updated order data
		oResult := JsonObject():New()
		oResult['orderNumber'] := AllTrim(cOrderNum)
		oResult['externalId']  := AllTrim(SC5->C5_ZZNPEXT)
		oResult['branch']      := AllTrim(SC5->C5_FILIAL)
		oResult['recno']       := SC5->(RecNo())

		oResponse := BuildResponse(.T., "Order updated successfully", oResult, Nil)
		oSelf:SetContentType("application/json")
		oSelf:SetResponse(oResponse)

		Recover Using oError

		cError := "Unexpected error: " + oError:Description + " at " + oError:Operation
		If !Empty(oError:ErrorStack)
			cError += " | Stack: " + oError:ErrorStack
		EndIf

		ConOut("[ORDERS API] Unexpected Error (UPDATE): " + cError)

		oResponse := BuildResponse(.F., FwNoAccent(cError), Nil, Nil)
		oSelf:SetContentType("application/json")
		oSelf:SetStatus(520)
		oSelf:SetResponse(oResponse)
		lRet := .F.

	End

	ErrorBlock(bOldErr)

Return lRet

//=============================================================
// ValidateOrderData - Validate required fields with detailed errors
//=============================================================
Static Function ValidateOrderData(oObj, cError, lInsert)

	Local lRet       := .T.
	Local aErrors    := {}
	Local cCustomer  := ""
	Local cCondPag   := ""
	Local aItems     := {}
	Local nX         := 0
	Local oItem      := Nil
	Local cProduto   := ""
	Local nQtd       := 0

	cError := ""

	// Validate object (JsonObject returns ValType "J", FWJsonDeserialize returns "O")
	If oObj == Nil .Or. !(ValType(oObj) $ "OJ")
		cError := "Invalid request body: JSON object expected"
		Return .F.
	EndIf

	// For insert, validate required fields
	If lInsert
		// customerCode - Required
		cCustomer := GetJsonString(oObj, "customerCode", "")
		If Empty(cCustomer)
			aAdd(aErrors, "customerCode is required")
		Else
			// Validate customer exists (SA1)
			If !ValidateForeignKey(oObj, "customerCode", "SA1", "A1_COD", @aErrors)
			EndIf
		EndIf

		// paymentCondition - Required
		cCondPag := GetJsonString(oObj, "paymentCondition", "")
		If Empty(cCondPag)
			aAdd(aErrors, "paymentCondition is required")
		Else
			If !ValidateForeignKey(oObj, "paymentCondition", "SE4", "E4_CODIGO", @aErrors)
			EndIf
		EndIf

		// items - Required
		aItems := GetJsonArray(oObj, "items")
		If Len(aItems) == 0
			aAdd(aErrors, "At least one item is required")
		Else
			For nX := 1 To Len(aItems)
				oItem := aItems[nX]

				cProduto := GetJsonString(oItem, "productCode", "")
				If Empty(cProduto)
					aAdd(aErrors, "Item " + cValToChar(nX) + ": productCode is required")
				Else
					// Validate product exists (SB1)
					DbSelectArea("SB1")
					DbSetOrder(1)
					If !DbSeek(xFilial("SB1") + PadR(cProduto, TamSX3("B1_COD")[1]))
						aAdd(aErrors, "Item " + cValToChar(nX) + ": productCode '" + cProduto + "' not found")
					EndIf
				EndIf

				nQtd := GetJsonNumber(oItem, "quantity", 0)
				If nQtd <= 0
					aAdd(aErrors, "Item " + cValToChar(nX) + ": quantity must be greater than 0")
				EndIf
			Next nX
		EndIf
	EndIf

	// For update, orderNumber or externalId is required
	If !lInsert
		If Empty(GetJsonString(oObj, "orderNumber", "")) .And. Empty(GetJsonString(oObj, "externalId", ""))
			aAdd(aErrors, "orderNumber or externalId is required for update")
		EndIf
	EndIf

	// Optional FK validations
	If !Empty(GetJsonString(oObj, "salespersonCode", ""))
		If !ValidateForeignKey(oObj, "salespersonCode", "SA3", "A3_COD", @aErrors)
		EndIf
	EndIf

	If !Empty(GetJsonString(oObj, "priceTable", ""))
		If !ValidateForeignKey(oObj, "priceTable", "DA0", "DA0_CODTAB", @aErrors)
		EndIf
	EndIf

	If !Empty(GetJsonString(oObj, "carrierCode", ""))
		If !ValidateForeignKey(oObj, "carrierCode", "SA4", "A4_COD", @aErrors)
		EndIf
	EndIf

	// Build error message
	If Len(aErrors) > 0
		cError := "Validation errors: " + ArrayToStr(aErrors, "; ")
		Return .F.
	EndIf

Return lRet

//=============================================================
// MakeOrderHeaderArray - Build SC5 array for MsExecAuto
//=============================================================
Static Function MakeOrderHeaderArray(oObj)

	Local aData      := {}
	Local cValue     := ""
	Local nValue     := 0
	Local cCustomer  := ""
	Local cStore     := ""

	// Customer (extract code and store)
	cCustomer := SanitizeCode(GetJsonString(oObj, "customerCode", ""), "A1_COD")
	cStore    := SanitizeCode(GetJsonString(oObj, "customerStore", "01"), "A1_LOJA")
	If Empty(cStore)
		cStore := "01"
	EndIf

	If !Empty(cCustomer)
		aAdd(aData, {"C5_CLIENTE", PadR(cCustomer, TamSX3("C5_CLIENTE")[1]), Nil})
		aAdd(aData, {"C5_LOJACLI", PadR(cStore, TamSX3("C5_LOJACLI")[1]), Nil})
		aAdd(aData, {"C5_LOJAENT", PadR(cStore, TamSX3("C5_LOJAENT")[1]), Nil})
	EndIf

	// Order type
	cValue := Upper(AllTrim(GetJsonString(oObj, "orderType", "N")))
	aAdd(aData, {"C5_TIPO", cValue, Nil})

	// Issue date
	cValue := GetJsonString(oObj, "issueDate", "")
	If !Empty(cValue)
		aAdd(aData, {"C5_EMISSAO", SToD(OnlyNumbers(cValue)), Nil})
	Else
		aAdd(aData, {"C5_EMISSAO", Date(), Nil})
	EndIf

	// Payment condition
	cValue := SanitizeCode(GetJsonString(oObj, "paymentCondition", ""), "E4_CODIGO")
	If !Empty(cValue)
		aAdd(aData, {"C5_CONDPAG", cValue, Nil})
	EndIf

	// Salesperson
	cValue := SanitizeCode(GetJsonString(oObj, "salespersonCode", ""), "A3_COD")
	If !Empty(cValue)
		aAdd(aData, {"C5_VEND1", cValue, Nil})
	EndIf

	// Price table
	cValue := SanitizeCode(GetJsonString(oObj, "priceTable", ""), "DA0_CODTAB")
	If !Empty(cValue)
		aAdd(aData, {"C5_TABELA", cValue, Nil})
	EndIf

	// Carrier
	cValue := SanitizeCode(GetJsonString(oObj, "carrierCode", ""), "A4_COD")
	If !Empty(cValue)
		aAdd(aData, {"C5_TRANSP", cValue, Nil})
	EndIf

	// Freight type (C=CIF, F=FOB)
	cValue := Upper(AllTrim(GetJsonString(oObj, "freightType", "C")))
	aAdd(aData, {"C5_TPFRETE", cValue, Nil})

	// Freight value
	nValue := GetJsonNumber(oObj, "freightValue", 0)
	If nValue > 0
		aAdd(aData, {"C5_FRETE", nValue, Nil})
	EndIf

	// Discount percentage
	nValue := GetJsonNumber(oObj, "discountPercent", 0)
	If nValue > 0
		aAdd(aData, {"C5_DESC1", nValue, Nil})
	EndIf

	// Currency
	nValue := GetJsonNumber(oObj, "currency", 1)
	aAdd(aData, {"C5_MOEDA", nValue, Nil})

	// Invoice message
	cValue := SanitizeString(GetJsonString(oObj, "invoiceMessage", ""), "C5_MENNOTA", .T.)
	If !Empty(cValue)
		aAdd(aData, {"C5_MENNOTA", cValue, Nil})
	EndIf

	// Internal observation
	cValue := SanitizeString(GetJsonString(oObj, "observation", ""), "C5_ZZOBS", .F.)
	If !Empty(cValue)
		aAdd(aData, {"C5_ZZOBS", cValue, Nil})
	EndIf

	// External ID (B2B order number)
	cValue := SanitizeCode(GetJsonString(oObj, "externalId", ""), "C5_ZZNPEXT")
	If !Empty(cValue)
		aAdd(aData, {"C5_ZZNPEXT", cValue, Nil})
	EndIf

	// External date
	cValue := GetJsonString(oObj, "externalDate", "")
	If !Empty(cValue)
		aAdd(aData, {"C5_ZZDTEMI", SToD(OnlyNumbers(cValue)), Nil})
	EndIf

	// Order source (B2B, AFV, etc)
	cValue := Upper(AllTrim(GetJsonString(oObj, "orderSource", "API")))
	aAdd(aData, {"C5_ZZORIGE", cValue, Nil})

	// Order subtype
	cValue := SanitizeCode(GetJsonString(oObj, "orderSubtype", ""), "C5_ZZTPPED")
	If !Empty(cValue)
		aAdd(aData, {"C5_ZZTPPED", cValue, Nil})
	EndIf

	// Coupon code
	cValue := SanitizeCode(GetJsonString(oObj, "couponCode", ""), "C5_ZZCUPOM")
	If !Empty(cValue)
		aAdd(aData, {"C5_ZZCUPOM", cValue, Nil})
	EndIf

	// Financial status
	cValue := SanitizeCode(GetJsonString(oObj, "financialStatus", ""), "C5_ZZSITFI")
	If !Empty(cValue)
		aAdd(aData, {"C5_ZZSITFI", cValue, Nil})
	EndIf

	// Commercial status
	cValue := SanitizeCode(GetJsonString(oObj, "commercialStatus", ""), "C5_ZZSITCO")
	If !Empty(cValue)
		aAdd(aData, {"C5_ZZSITCO", cValue, Nil})
	EndIf

	// Customer type (F=Fisica, J=Juridica, R=Rural, etc)
	cValue := Upper(AllTrim(GetJsonString(oObj, "customerType", "")))
	If !Empty(cValue)
		aAdd(aData, {"C5_TIPOCLI", cValue, Nil})
	EndIf

	FWVetByDic(aData, "SC5")

Return aData

//=============================================================
// MakeOrderItemArray - Build SC6 array for MsExecAuto
//=============================================================
Static Function MakeOrderItemArray(oItem, nSeq)

	Local aLin   := {}
	Local cValue := ""
	Local nValue := 0

	// Item sequence
	cValue := GetJsonString(oItem, "itemNumber", StrZero(nSeq, 2))
	aAdd(aLin, {"C6_ITEM", cValue, Nil})

	// Product code
	cValue := SanitizeCode(GetJsonString(oItem, "productCode", ""), "B1_COD")
	aAdd(aLin, {"C6_PRODUTO", cValue, Nil})

	// Quantity
	nValue := GetJsonNumber(oItem, "quantity", 0)
	aAdd(aLin, {"C6_QTDVEN", nValue, Nil})

	// Unit price
	nValue := GetJsonNumber(oItem, "unitPrice", 0)
	If nValue > 0
		aAdd(aLin, {"C6_PRCVEN", nValue, Nil})
	EndIf

	// Total value (C6_VALOR)
	nValue := GetJsonNumber(oItem, "totalValue", 0)
	If nValue > 0
		aAdd(aLin, {"C6_VALOR", nValue, Nil})
	EndIf

	// Discount percentage
	nValue := GetJsonNumber(oItem, "discountPercent", 0)
	If nValue > 0
		aAdd(aLin, {"C6_DESCONT", nValue, Nil})
	EndIf

	// TES operation
	cValue := AllTrim(GetJsonString(oItem, "operationCode", ""))
	If !Empty(cValue)
		aAdd(aLin, {"C6_OPER", PadR(cValue, TamSX3("C6_OPER")[1]), Nil})
	EndIf

	// TES code (explicit)
	cValue := AllTrim(GetJsonString(oItem, "tesCode", ""))
	If !Empty(cValue)
		aAdd(aLin, {"C6_TES", PadR(cValue, TamSX3("C6_TES")[1]), Nil})
	EndIf

	FWVetByDic(aLin, "SC6")
	aAdd(aLin, {"AUTDELETA", "N", Nil})

Return aLin

//=============================================================
// BuildOrderHeader - Build JSON object from order header
//=============================================================
Static Function BuildOrderHeader(cAlias)

	Local oOrder  := JsonObject():New()
	Local lHasRecno := .F.

	Default cAlias := "SC5"

	lHasRecno := ((cAlias)->(FieldPos("RECNO")) > 0)

	// Identification
	oOrder['orderNumber']      := AllTrim((cAlias)->C5_NUM)
	oOrder['branch']           := AllTrim((cAlias)->C5_FILIAL)
	oOrder['externalId']       := AllTrim((cAlias)->C5_ZZNPEXT)
	oOrder['orderType']        := AllTrim((cAlias)->C5_TIPO)

	// Dates
	If ValType((cAlias)->C5_EMISSAO) == "D"
		oOrder['issueDate']    := DToC((cAlias)->C5_EMISSAO)
	Else
		oOrder['issueDate']    := AllTrim(cValToChar((cAlias)->C5_EMISSAO))
	EndIf

	If ValType((cAlias)->C5_ZZDTEMI) == "D"
		oOrder['externalDate'] := DToC((cAlias)->C5_ZZDTEMI)
	Else
		oOrder['externalDate'] := AllTrim(cValToChar((cAlias)->C5_ZZDTEMI))
	EndIf

	// Customer
	oOrder['customerCode']     := AllTrim((cAlias)->C5_CLIENTE)
	oOrder['customerStore']    := AllTrim((cAlias)->C5_LOJACLI)

	// Try to get customer name if available
	If (cAlias)->(FieldPos("A1_NOME")) > 0
		oOrder['customerName'] := FwNoAccent(AllTrim((cAlias)->A1_NOME))
		oOrder['customerTaxId']:= AllTrim((cAlias)->A1_CGC)
	EndIf

	// Sales
	oOrder['paymentCondition'] := AllTrim((cAlias)->C5_CONDPAG)
	oOrder['priceTable']       := AllTrim((cAlias)->C5_TABELA)
	oOrder['salespersonCode']  := AllTrim((cAlias)->C5_VEND1)

	// Logistics
	oOrder['carrierCode']      := AllTrim((cAlias)->C5_TRANSP)
	oOrder['freightType']      := AllTrim((cAlias)->C5_TPFRETE)
	oOrder['freightValue']     := (cAlias)->C5_FRETE

	// Financial
	oOrder['currency']         := (cAlias)->C5_MOEDA
	oOrder['discountPercent']  := (cAlias)->C5_DESC1

	// Invoice
	oOrder['invoiceNumber']    := AllTrim((cAlias)->C5_NOTA)
	oOrder['invoiceSeries']    := AllTrim((cAlias)->C5_SERIE)
	oOrder['invoiceMessage']   := FwNoAccent(AllTrim((cAlias)->C5_MENNOTA))

	// Additional
	oOrder['orderSource']      := AllTrim((cAlias)->C5_ZZORIGE)
	oOrder['orderSubtype']     := AllTrim((cAlias)->C5_ZZTPPED)
	oOrder['couponCode']       := AllTrim((cAlias)->C5_ZZCUPOM)
	oOrder['observation']      := FwNoAccent(AllTrim((cAlias)->C5_ZZOBS))

	// Recno
	oOrder['recno']            := IIf(lHasRecno, (cAlias)->RECNO, (cAlias)->(RecNo()))

Return oOrder

//=============================================================
// GetOrderItems - Get items for an order
//=============================================================
Static Function GetOrderItems(cOrderNum)

	Local aItems    := {}
	Local oItem     := Nil
	Local cAliasTmp := GetNextAlias()
	Local cQuery    := ""

	cQuery := " SELECT "
	cQuery += "     C6.C6_ITEM, C6.C6_PRODUTO, C6.C6_DESCRI, C6.C6_QTDVEN, "
	cQuery += "     C6.C6_PRCVEN, C6.C6_VALOR, C6.C6_OPER, C6.C6_DESCONT, C6.C6_TES "
	cQuery += " FROM " + RetSqlName("SC6") + " C6 "
	cQuery += " WHERE C6.C6_FILIAL = '" + xFilial("SC6") + "' "
	cQuery += "   AND C6.C6_NUM = '" + cOrderNum + "' "
	cQuery += "   AND C6.D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY C6.C6_ITEM "

	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	TCQuery cQuery New Alias (cAliasTmp)

	(cAliasTmp)->(DbGoTop())
	While !(cAliasTmp)->(Eof())
		oItem := JsonObject():New()
		oItem['itemNumber']      := AllTrim((cAliasTmp)->C6_ITEM)
		oItem['productCode']     := AllTrim((cAliasTmp)->C6_PRODUTO)
		oItem['productName']     := FwNoAccent(AllTrim((cAliasTmp)->C6_DESCRI))
		oItem['quantity']        := (cAliasTmp)->C6_QTDVEN
		oItem['unitPrice']       := (cAliasTmp)->C6_PRCVEN
		oItem['totalValue']      := (cAliasTmp)->C6_VALOR
		oItem['operationCode']   := AllTrim((cAliasTmp)->C6_OPER)
		oItem['discountPercent'] := (cAliasTmp)->C6_DESCONT
		oItem['tesCode']         := AllTrim((cAliasTmp)->C6_TES)
		aAdd(aItems, oItem)
		(cAliasTmp)->(DbSkip())
	EndDo

	(cAliasTmp)->(DbCloseArea())

Return aItems

//=============================================================
// GetTotalOrders - Count total orders for pagination
//=============================================================
Static Function GetTotalOrders(nPending)

	Local nTotal    := 0
	Local cAliasTmp := GetNextAlias()
	Local cQuery    := ""

	Default nPending := 0

	cQuery := " SELECT COUNT(*) AS TOTAL "
	cQuery += " FROM " + RetSqlName("SC5") + " "
	cQuery += " WHERE D_E_L_E_T_ = ' ' "
	cQuery += "   AND C5_FILIAL = '" + xFilial("SC5") + "' "

	If nPending == 1
		cQuery += " AND C5_NOTA = '' "
	EndIf

	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	TCQuery cQuery New Alias (cAliasTmp)

	If !(cAliasTmp)->(Eof())
		nTotal := (cAliasTmp)->TOTAL
	EndIf

	(cAliasTmp)->(DbCloseArea())

Return nTotal

//=============================================================
// PositionTables - Position tables for MsExecAuto
//=============================================================
Static Function PositionTables()

	DbSelectArea("SC5")
	SC5->(DbSetOrder(1))
	SC5->(DbGoTop())

	DbSelectArea("SC6")
	SC6->(DbSetOrder(1))
	SC6->(DbGoTop())

	DbSelectArea("SA1")
	SA1->(DbSetOrder(1))
	SA1->(DbGoTop())

	DbSelectArea("SA2")
	SA2->(DbSetOrder(1))
	SA2->(DbGoTop())

	DbSelectArea("SB1")
	SB1->(DbSetOrder(1))
	SB1->(DbGoTop())

	DbSelectArea("SB2")
	SB2->(DbSetOrder(1))
	SB2->(DbGoTop())

	DbSelectArea("SE4")
	SE4->(DbSetOrder(1))
	SE4->(DbGoTop())

	DbSelectArea("SF4")
	SF4->(DbSetOrder(1))
	SF4->(DbGoTop())

Return

//=============================================================
// HELPER FUNCTIONS - JSON ACCESS
//=============================================================

//=============================================================
// GetJsonString - Safe string getter from JSON object
//=============================================================
Static Function GetJsonString(oObj, cProp, cDefault)

	Local cResult := cDefault
	Local xValue  := Nil

	Default cDefault := ""

	If oObj == Nil .Or. !(ValType(oObj) $ "OJ")
		Return cResult
	EndIf

	xValue := oObj[cProp]
	If ValType(xValue) == "C"
		cResult := AllTrim(xValue)
	ElseIf ValType(xValue) == "N"
		cResult := cValToChar(xValue)
	ElseIf ValType(xValue) != "U" .And. xValue != Nil
		cResult := cValToChar(xValue)
	EndIf

Return cResult

//=============================================================
// GetJsonNumber - Safe number getter from JSON object
//=============================================================
Static Function GetJsonNumber(oObj, cProp, nDefault)

	Local nResult := nDefault
	Local xValue  := Nil

	Default nDefault := 0

	If oObj == Nil .Or. !(ValType(oObj) $ "OJ")
		Return nResult
	EndIf

	xValue := oObj[cProp]
	If ValType(xValue) == "N"
		nResult := xValue
	ElseIf ValType(xValue) == "C"
		nResult := Val(xValue)
	EndIf

Return nResult

//=============================================================
// GetJsonArray - Safe array getter from JSON object
//=============================================================
Static Function GetJsonArray(oObj, cProp)

	Local aResult := {}
	Local xValue  := Nil

	If oObj == Nil .Or. !(ValType(oObj) $ "OJ")
		Return aResult
	EndIf

	xValue := oObj[cProp]
	If ValType(xValue) == "A"
		aResult := xValue
	EndIf

Return aResult

//=============================================================
// HasJsonProperty - Check if property exists in JSON
//=============================================================
Static Function HasJsonProperty(oObj, cProp)

	Local xValue := Nil

	If oObj == Nil .Or. !(ValType(oObj) $ "OJ")
		Return .F.
	EndIf

	xValue := oObj[cProp]

Return (ValType(xValue) != "U" .And. xValue != Nil)

//=============================================================
// SANITIZATION FUNCTIONS
//=============================================================

//=============================================================
// SanitizeString - Clean and standardize text fields
//=============================================================
Static Function SanitizeString(cValue, cField, lUpper)

	Local cResult := ""
	Local nMaxLen := 0

	Default lUpper := .T.

	If ValType(cValue) != "C" .Or. Empty(cValue)
		Return ""
	EndIf

	cResult := AllTrim(cValue)

	// Remove dangerous characters
	cResult := StrTran(cResult, "'", "")
	cResult := StrTran(cResult, '"', "")
	cResult := StrTran(cResult, "\", "")
	cResult := StrTran(cResult, Chr(0), "")
	cResult := StrTran(cResult, Chr(9), " ")
	cResult := StrTran(cResult, Chr(10), " ")
	cResult := StrTran(cResult, Chr(13), " ")

	If lUpper
		cResult := Upper(cResult)
	EndIf

	If !Empty(cField)
		nMaxLen := GetFieldLen(cField)
		If nMaxLen > 0 .And. Len(cResult) > nMaxLen
			cResult := Left(cResult, nMaxLen)
		EndIf
	EndIf

Return cResult

//=============================================================
// SanitizeCode - Clean code fields (alphanumeric)
//=============================================================
Static Function SanitizeCode(cValue, cField)

	Local cResult := ""
	Local nMaxLen := 0

	If ValType(cValue) != "C" .Or. Empty(cValue)
		Return ""
	EndIf

	cResult := AllTrim(Upper(cValue))

	cResult := StrTran(cResult, "'", "")
	cResult := StrTran(cResult, '"', "")
	cResult := StrTran(cResult, "\", "")
	cResult := StrTran(cResult, " ", "")

	If !Empty(cField)
		nMaxLen := GetFieldLen(cField)
		If nMaxLen > 0 .And. Len(cResult) > nMaxLen
			cResult := Left(cResult, nMaxLen)
		EndIf
	EndIf

Return cResult

//=============================================================
// OnlyNumbers - Extract only digits from string
//=============================================================
Static Function OnlyNumbers(cValue)

	Local cResult := ""
	Local nX      := 0
	Local cChar   := ""

	If ValType(cValue) != "C" .Or. Empty(cValue)
		Return ""
	EndIf

	For nX := 1 To Len(cValue)
		cChar := SubStr(cValue, nX, 1)
		If cChar >= "0" .And. cChar <= "9"
			cResult += cChar
		EndIf
	Next nX

Return cResult

//=============================================================
// GetFieldLen - Get field length safely
//=============================================================
Static Function GetFieldLen(cField)

	Local nLen := 0
	Local aTam := {}

	If !Empty(cField)
		aTam := TamSX3(cField)
		If ValType(aTam) == "A" .And. Len(aTam) > 0
			nLen := aTam[1]
		EndIf
	EndIf

	If nLen == 0
		nLen := 10
	EndIf

Return nLen

//=============================================================
// VALIDATION FUNCTIONS
//=============================================================

//=============================================================
// ValidateForeignKey - Check if code exists in related table
//=============================================================
Static Function ValidateForeignKey(oObj, cProperty, cTable, cField, aErrors)
	Local lValid := .T.
	Local cValue := ""
	Local cOldArea := ""
	Local nFieldLen := 0
	cValue := SanitizeCode(GetJsonString(oObj, cProperty, ""), cField)
	If Empty(cValue)
		Return .T.
	EndIf
	nFieldLen := GetFieldLen(cField)
	If nFieldLen == 0
		Return .T.
	EndIf
	cOldArea := Alias()
	DbSelectArea(cTable)
	DbSetOrder(1)
	If !DbSeek(xFilial(cTable) + PadR(cValue, nFieldLen))
		aAdd(aErrors, cProperty + " '" + AllTrim(cValue) + "' not found in " + cTable)
		lValid := .F.
	EndIf
	If !Empty(cOldArea) .And. Select(cOldArea) > 0
		DbSelectArea(cOldArea)
	EndIf
Return lValid

//=============================================================
// ArrayToStr - Convert array to delimited string
//=============================================================
Static Function ArrayToStr(aArray, cDelim)

	Local cResult := ""
	Local nX      := 0

	Default cDelim := ", "

	For nX := 1 To Len(aArray)
		If nX > 1
			cResult += cDelim
		EndIf
		cResult += cValToChar(aArray[nX])
	Next nX

Return cResult

//=============================================================
// BuildResponse - Build standardized JSON response
//=============================================================
Static Function BuildResponse(lSuccess, cMessage, oData, oPagination)

	Local cResponse := ""
	Local cDataJson := ""
	Local cPagJson  := ""
	Local cType     := ""

	cResponse := '{"success":' + IIf(lSuccess, "true", "false")
	cResponse += ',"message":"' + FwNoAccent(cMessage) + '"'

	// Add data
	If oData != Nil
		cType := ValType(oData)
		If cType == "A"
			cDataJson := ArrayToJson(oData)
			cResponse += ',"data":' + cDataJson
		ElseIf cType == "O" .Or. cType == "J"
			// JsonObject returns type "J" in AdvPL
			cDataJson := oData:ToJson()
			cResponse += ',"data":' + cDataJson
		EndIf
	Else
		cResponse += ',"data":null'
	EndIf

	// Add pagination
	If oPagination != Nil
		cPagJson := oPagination:ToJson()
		cResponse += ',"pagination":' + cPagJson
	EndIf

	cResponse += "}"

Return cResponse

//=============================================================
// ArrayToJson - Convert array of objects to JSON string
//=============================================================
Static Function ArrayToJson(aData)

	Local cJson := "["
	Local nX    := 0
	Local oItem := Nil

	For nX := 1 To Len(aData)
		If nX > 1
			cJson += ","
		EndIf
		oItem := aData[nX]
		If ValType(oItem) == "O"
			cJson += oItem:ToJson()
		Else
			cJson += '"' + cValToChar(oItem) + '"'
		EndIf
	Next nX

	cJson += "]"

Return cJson

//=============================================================
// ParseAutoErrors - Parse GetAutoGrLog into clean error + details
//=============================================================
Static Function ParseAutoErrors(aLogAuto, cError, oDetails)

	Local nY       := 0
	Local cLine    := ""
	Local cHelp    := ""
	Local cMsgErro := ""
	Local cMsgSol  := ""
	Local cIdErro  := ""
	Local cFormOri := ""
	Local cCampoOri:= ""
	Local cFormErr := ""
	Local cCampoErr:= ""
	Local aErros   := {}
	Local aFields  := {}
	Local nItemErr := 0
	Local cField   := ""
	Local cValor   := ""
	Local nPos     := 0
	Local nPos2    := 0
	Local oFields  := Nil

	cError   := ""
	oDetails := JsonObject():New()

	// Se nao tem log, tenta outras fontes
	If ValType(aLogAuto) != "A" .Or. Len(aLogAuto) == 0
		// Tenta aAutoErro
		If Type("aAutoErro") == "A" .And. Len(aAutoErro) > 0
			For nY := 1 To Len(aAutoErro)
				If ValType(aAutoErro[nY]) == "C" .And. !Empty(aAutoErro[nY])
					cLine := AllTrim(aAutoErro[nY])
					If !("---------" $ cLine)
						aAdd(aErros, cLine)
					EndIf
				EndIf
			Next nY
		EndIf
		// Tenta help
		If Len(aErros) == 0
			If Type("__cAutoHelp") == "C" .And. !Empty(__cAutoHelp)
				aAdd(aErros, AllTrim(__cAutoHelp))
			EndIf
		EndIf
		If Len(aErros) > 0
			cError := aErros[1]
		EndIf
		Return
	EndIf

	// Percorre o log e separa: HELP, Erros e Campos
	For nY := 1 To Len(aLogAuto)
		If ValType(aLogAuto[nY]) != "C"
			Loop
		EndIf

		cLine := AllTrim(aLogAuto[nY])

		// Ignora linhas vazias e separadores
		If Empty(cLine) .Or. Left(cLine, 5) == "-----" .Or. Left(cLine, 6) == "Tabela"
			Loop
		EndIf

		// Captura HELP (ex: "AJUDA:A410TE")
		If "AJUDA:" $ cLine .Or. "HELP:" $ cLine
			cHelp := cLine
			Loop
		EndIf

		// Captura mensagens do modelo (Especial)
		If "Mensagem do erro:" $ cLine
			nPos := At("[", cLine)
			nPos2 := At("]", cLine)
			If nPos > 0 .And. nPos2 > nPos
				cMsgErro := AllTrim(SubStr(cLine, nPos + 1, nPos2 - nPos - 1))
			Else
				cMsgErro := AllTrim(SubStr(cLine, At(":", cLine) + 1))
			EndIf
			Loop
		EndIf

		If "Mensagem da solucao:" $ cLine
			nPos := At("[", cLine)
			nPos2 := At("]", cLine)
			If nPos > 0 .And. nPos2 > nPos
				cMsgSol := AllTrim(SubStr(cLine, nPos + 1, nPos2 - nPos - 1))
			Else
				cMsgSol := AllTrim(SubStr(cLine, At(":", cLine) + 1))
			EndIf
			Loop
		EndIf

		If "Id do erro:" $ cLine
			nPos := At("[", cLine)
			nPos2 := At("]", cLine)
			If nPos > 0 .And. nPos2 > nPos
				cIdErro := AllTrim(SubStr(cLine, nPos + 1, nPos2 - nPos - 1))
			EndIf
			Loop
		EndIf

		If "Id do formulario de origem:" $ cLine
			nPos := At("[", cLine)
			nPos2 := At("]", cLine)
			If nPos > 0 .And. nPos2 > nPos
				cFormOri := AllTrim(SubStr(cLine, nPos + 1, nPos2 - nPos - 1))
			EndIf
			Loop
		EndIf

		If "Id do campo de origem:" $ cLine
			nPos := At("[", cLine)
			nPos2 := At("]", cLine)
			If nPos > 0 .And. nPos2 > nPos
				cCampoOri := AllTrim(SubStr(cLine, nPos + 1, nPos2 - nPos - 1))
			EndIf
			Loop
		EndIf

		If "Id do formulario de erro:" $ cLine
			nPos := At("[", cLine)
			nPos2 := At("]", cLine)
			If nPos > 0 .And. nPos2 > nPos
				cFormErr := AllTrim(SubStr(cLine, nPos + 1, nPos2 - nPos - 1))
			EndIf
			Loop
		EndIf

		If "Id do campo de erro:" $ cLine
			nPos := At("[", cLine)
			nPos2 := At("]", cLine)
			If nPos > 0 .And. nPos2 > nPos
				cCampoErr := AllTrim(SubStr(cLine, nPos + 1, nPos2 - nPos - 1))
			EndIf
			Loop
		EndIf

		// Captura mensagem de erro principal (ex: "Tipo de Entrada/Saida nao cadastrado.")
		If Empty(cHelp) .And. !( ":=" $ cLine ) .And. !( "Erro no Item" $ cLine ) .And. !( "Erro -->" $ cLine ) .And. !( "AUTDELETA" $ cLine )
			// Linha texto sem := eh descricao do erro
			If Empty(cError) .And. !("Item" $ Left(cLine, 4))
				cError := cLine
			EndIf
			Loop
		EndIf

		// Captura descricao do HELP na linha seguinte
		If !Empty(cHelp) .And. Empty(cError) .And. !( ":=" $ cLine ) .And. !( "Erro" $ cLine )
			cError := cLine
			Loop
		EndIf

		// Captura "Erro no Item N"
		If "Erro no Item" $ cLine
			nPos := At("Item", cLine)
			If nPos > 0
				nItemErr := Val(AllTrim(SubStr(cLine, nPos + 5)))
			EndIf
			Loop
		EndIf

		// Captura "Erro --> mensagem"
		If "Erro -->" $ cLine
			nPos := At("-->", cLine)
			If nPos > 0
				aAdd(aErros, AllTrim(SubStr(cLine, nPos + 3)))
			EndIf
			Loop
		EndIf

		// Ignora AUTDELETA
		If "AUTDELETA" $ cLine
			Loop
		EndIf

		// Captura campos (ex: "Cliente - C5_CLIENTE := C15130")
		If ":=" $ cLine
			nPos := At(":=", cLine)
			cField := AllTrim(Left(cLine, nPos - 1))
			cValor := AllTrim(SubStr(cLine, nPos + 2))
			// Extrai nome curto do campo (ex: "C5_CLIENTE" de "Cliente - C5_CLIENTE")
			If " - " $ cField
				cField := AllTrim(SubStr(cField, RAt(" - ", cField) + 3))
			ElseIf "- " $ cField
				cField := AllTrim(SubStr(cField, RAt("- ", cField) + 2))
			EndIf
			aAdd(aFields, {cField, cValor})
			Loop
		EndIf
	Next nY

	// Monta cError limpo
	If !Empty(cMsgErro)
		cError := cMsgErro
	EndIf

	If !Empty(cHelp) .And. !Empty(cError)
		cError := FwNoAccent(cHelp + " - " + cError)
	ElseIf !Empty(cHelp)
		cError := FwNoAccent(cHelp)
	ElseIf !Empty(cError)
		cError := FwNoAccent(cError)
	EndIf

	// Adiciona erros secundarios
	If Len(aErros) > 0
		For nY := 1 To Len(aErros)
			If !Empty(cError)
				cError += " | " + FwNoAccent(aErros[nY])
			Else
				cError := FwNoAccent(aErros[nY])
			EndIf
		Next nY
	EndIf

	// Monta oDetails
	If !Empty(cHelp)
		oDetails['helpCode'] := FwNoAccent(AllTrim(cHelp))
	EndIf

	If nItemErr > 0
		oDetails['errorItem'] := nItemErr
	EndIf

	If Len(aErros) > 0
		oDetails['errors'] := aErros
	EndIf

	// Campos enviados (para debug do consumidor)
	If Len(aFields) > 0
		oFields := JsonObject():New()
		For nY := 1 To Len(aFields)
			oFields[aFields[nY][1]] := AllTrim(aFields[nY][2])
		Next nY
		oDetails['sentFields'] := oFields
	EndIf

	If !Empty(cMsgErro)
		oDetails['modelErrorMessage'] := FwNoAccent(cMsgErro)
	EndIf

	If !Empty(cMsgSol)
		oDetails['modelErrorSolution'] := FwNoAccent(cMsgSol)
	EndIf

	If !Empty(cIdErro)
		oDetails['modelErrorId'] := cIdErro
	EndIf

	If !Empty(cFormOri)
		oDetails['modelOriginFormId'] := cFormOri
	EndIf

	If !Empty(cCampoOri)
		oDetails['modelOriginFieldId'] := cCampoOri
	EndIf

	If !Empty(cFormErr)
		oDetails['modelErrorFormId'] := cFormErr
	EndIf

	If !Empty(cCampoErr)
		oDetails['modelErrorFieldId'] := cCampoErr
	EndIf

Return

//=============================================================
// FillSentData - Add sent header/item data to error details
//=============================================================
Static Function FillSentData(oDetails, aDadosC5, aDadosC6)

	Local nY      := 0
	Local oHeader := Nil
	Local oItem   := Nil
	Local aItems  := {}
	Local nX      := 0

	If oDetails == Nil
		oDetails := JsonObject():New()
	EndIf

	// Inclui header enviado
	If ValType(aDadosC5) == "A" .And. Len(aDadosC5) > 0
		oHeader := JsonObject():New()
		For nY := 1 To Len(aDadosC5)
			If ValType(aDadosC5[nY]) == "A" .And. Len(aDadosC5[nY]) >= 2
				oHeader[aDadosC5[nY][1]] := cValToChar(aDadosC5[nY][2])
			EndIf
		Next nY
		oDetails['sentHeader'] := oHeader
	EndIf

	// Inclui itens enviados
	If ValType(aDadosC6) == "A" .And. Len(aDadosC6) > 0
		aItems := {}
		For nX := 1 To Len(aDadosC6)
			If ValType(aDadosC6[nX]) == "A" .And. Len(aDadosC6[nX]) > 0
				oItem := JsonObject():New()
				For nY := 1 To Len(aDadosC6[nX])
					If ValType(aDadosC6[nX][nY]) == "A" .And. Len(aDadosC6[nX][nY]) >= 2
						oItem[aDadosC6[nX][nY][1]] := cValToChar(aDadosC6[nX][nY][2])
					EndIf
				Next nY
				aAdd(aItems, oItem)
			EndIf
		Next nX
		oDetails['sentItems'] := aItems
	EndIf

Return

//=============================================================
// BuildErrorResponse - Build structured error JSON response
//=============================================================
Static Function BuildErrorResponse(cError, oDetails)

	Local cResponse := ""

	cResponse := '{"success":false'
	cResponse += ',"message":"' + FwNoAccent(cError) + '"'

	If oDetails != Nil .And. ValType(oDetails) $ "OJ"
		cResponse += ',"data":' + oDetails:ToJson()
	Else
		cResponse += ',"data":null'
	EndIf

	cResponse += "}"

Return cResponse
