#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "TopConn.ch"
#Include "FWMVCDef.ch"
#Include "Totvs.ch"

//=============================================================
// API: Customers - Customer Management REST API
// Version: 2.0
// Author: Suntech
// Description: REST API for customer CRUD operations
//=============================================================

#Define API_VERSION         "2.0"
#Define DEFAULT_PAGE_SIZE   100

//=============================================================
// REST Service Definition
//=============================================================
WSRESTFUL Customers DESCRIPTION "Customer Management REST API v2.0"

    WSDATA page       As Integer Optional
    WSDATA pageSize   As Integer Optional
    WSDATA code       As String  Optional  // A1_COD + A1_LOJA concatenated (e.g. "00000101")
    WSDATA taxId      As String  Optional

    WSMETHOD GET    DESCRIPTION "Retrieve customers"        WSSYNTAX "/customers"
    WSMETHOD POST   DESCRIPTION "Create new customer"       WSSYNTAX "/customers"
    WSMETHOD PUT    DESCRIPTION "Update existing customer"  WSSYNTAX "/customers"

END WSRESTFUL

//=============================================================
// User Function - Entry Point
//=============================================================
User Function Customers()
Return .T.

//=============================================================
// GET Method - Retrieve Customers
//=============================================================
WSMETHOD GET WSRECEIVE page, pageSize, code, taxId WSSERVICE Customers

    Local lRet       := .T.
    Local aTabs      := {}
    Local _cEmpresa  := "01"
    Local _cFilial   := "01"
    Local _lSegue    := .F.
    
    ::SetContentType("application/json")
    
    // Setup Environment (igual EJCli.prw)
    If FindFunction("WfPrepEnv")
        RpcSetEnv(_cEmpresa, _cFilial,,,"GET", "METHOD", aTabs,,,,)
        cEmpAnt := _cEmpresa
        cFilAnt := _cFilial
        
        While !_lSegue
            If _cEmpresa + _cFilial == cNumEmp
                _lSegue := .T.
            EndIf
        EndDo
    EndIf
    
    // Execute Query
    If !Empty(Self:code) .Or. !Empty(Self:taxId)
        lRet := GetSingleCustomer(Self)
    Else
        lRet := GetCustomerList(Self)
    EndIf

Return lRet

//=============================================================
// POST Method - Create Customer
//=============================================================
WSMETHOD POST WSSERVICE Customers

    Local lRet       := .T.
    Local oResponse  := Nil
    Local cJson      := Self:GetContent()
    Local oObj       := Nil
    Local aTabs      := {}
    Local _cEmpresa  := "01"
    Local _cFilial   := "01"
    Local _lSegue    := .F.
    
    ::SetContentType("application/json")
    
    // Setup Environment (igual EJCli.prw)
    If FindFunction("WfPrepEnv")
        RpcSetEnv(_cEmpresa, _cFilial,,,"POST", "METHOD", aTabs,,,,)
        cEmpAnt := _cEmpresa
        cFilAnt := _cFilial
        
        While !_lSegue
            If _cEmpresa + _cFilial == cNumEmp
                _lSegue := .T.
            EndIf
        EndDo
    EndIf
    
    // Deserialize JSON
    FWJsonDeserialize(cJson, @oObj)
    
    If oObj == Nil
        oResponse := BuildResponse(.F., "Invalid JSON format", Nil, Nil)
        ::SetStatus(400)
        ::SetResponse(oResponse)
        Return .F.
    EndIf
    
    // Create Customer
    lRet := CreateCustomer(Self, oObj)

Return lRet

//=============================================================
// PUT Method - Update Customer
//=============================================================
WSMETHOD PUT WSSERVICE Customers

    Local lRet       := .T.
    Local oResponse  := Nil
    Local cJson      := Self:GetContent()
    Local oObj       := Nil
    Local aTabs      := {}
    Local _cEmpresa  := "01"
    Local _cFilial   := "01"
    Local _lSegue    := .F.
    
    ::SetContentType("application/json")
    
    // Setup Environment (igual EJCli.prw)
    If FindFunction("WfPrepEnv")
        RpcSetEnv(_cEmpresa, _cFilial,,,"PUT", "METHOD", aTabs,,,,)
        cEmpAnt := _cEmpresa
        cFilAnt := _cFilial
        
        While !_lSegue
            If _cEmpresa + _cFilial == cNumEmp
                _lSegue := .T.
            EndIf
        EndDo
    EndIf
    
    // Deserialize JSON
    FWJsonDeserialize(cJson, @oObj)
    
    If oObj == Nil
        oResponse := BuildResponse(.F., "Invalid JSON format", Nil, Nil)
        ::SetStatus(400)
        ::SetResponse(oResponse)
        Return .F.
    EndIf
    
    // Update Customer
    lRet := UpdateCustomer(Self, oObj)

Return lRet

//=============================================================
// GetCustomerList - Retrieve paginated customer list
//=============================================================
Static Function GetCustomerList(oSelf)

    Local lRet       := .T.
    Local cAliasTmp  := GetNextAlias()
    Local nPage      := IIf(oSelf:page == Nil, 1, oSelf:page)
    Local nPageSize  := IIf(oSelf:pageSize == Nil, DEFAULT_PAGE_SIZE, oSelf:pageSize)
    Local nOffset    := (nPage - 1) * nPageSize
    Local nTotal     := 0
    Local nTotalPags := 0
    Local oResponse  := Nil
    Local aCustomers := {}
    Local oCustomer  := Nil
    Local oPagination:= Nil
    Local cQuery     := ""
    
    // Build optimized query with OFFSET/FETCH
    cQuery := " SELECT "
    cQuery += "     A.R_E_C_N_O_ AS RECNO, "
    cQuery += "     A.A1_FILIAL, A.A1_COD, A.A1_LOJA, A.A1_NOME, A.A1_NREDUZ, "
    cQuery += "     A.A1_CGC, A.A1_INSCR, A.A1_INSCRM, A.A1_END, A.A1_COMPLEM, "
    cQuery += "     A.A1_BAIRRO, A.A1_MUN, A.A1_EST, A.A1_CEP, A.A1_COD_MUN, "
    cQuery += "     A.A1_PAIS, A.A1_CODPAIS, A.A1_DDD, A.A1_TEL, A.A1_FAX, "
    cQuery += "     A.A1_ZZDDDW, A.A1_TELW, A.A1_EMAIL, A.A1_CONTATO, "
    cQuery += "     A.A1_PESSOA, A.A1_TIPO, A.A1_MSBLQL, A.A1_VEND, "
    cQuery += "     A.A1_COND, A.A1_TABELA, A.A1_REGIAO, A.A1_GRPVEN, "
    cQuery += "     A.A1_GRPTRIB, A.A1_CONTRIB, A.A1_LC, A.A1_SALDUP, "
    cQuery += "     A.A1_TRANSP, A.A1_ZZLB2B, A.A1_OBS, A.A1_DTCAD, A.A1_HRCAD "
    cQuery += " FROM " + RetSqlName("SA1") + " A "
    cQuery += " WHERE A.D_E_L_E_T_ = ' ' "
    cQuery += "     AND A.A1_FILIAL = '" + xFilial("SA1") + "' "
    cQuery += " ORDER BY A.A1_COD, A.A1_LOJA "
    cQuery += " OFFSET " + cValToChar(nOffset) + " ROWS "
    cQuery += " FETCH NEXT " + cValToChar(nPageSize) + " ROWS ONLY "
    
    // Close alias if already open
    If Select(cAliasTmp) > 0
        (cAliasTmp)->(DbCloseArea())
    EndIf
    
    // Execute query
    TCQuery cQuery New Alias (cAliasTmp)
    
    If (cAliasTmp)->(Eof())
        oResponse := BuildResponse(.T., "No customers found", {}, Nil)
        oSelf:SetContentType("application/json")
        oSelf:SetResponse(oResponse)
        (cAliasTmp)->(DbCloseArea())
        Return .T.
    EndIf
    
    // Build response array
    (cAliasTmp)->(DbGoTop())
    While !(cAliasTmp)->(Eof())
        oCustomer := BuildCustomerObject(cAliasTmp)
        aAdd(aCustomers, oCustomer)
        (cAliasTmp)->(DbSkip())
    EndDo
    
    (cAliasTmp)->(DbCloseArea())
    
    // Get total records for pagination
    nTotal := GetTotalCustomers()
    nTotalPags := Ceiling(nTotal / nPageSize)
    
    // Build pagination object
    oPagination := JsonObject():New()
    oPagination['page']         := nPage
    oPagination['pageSize']     := nPageSize
    oPagination['totalPages']   := nTotalPags
    oPagination['totalRecords'] := nTotal
    
    // Build final response
    oResponse := BuildResponse(.T., "Customers retrieved successfully", aCustomers, oPagination)
    oSelf:SetContentType("application/json")
    oSelf:SetResponse(oResponse)

Return lRet

//=============================================================
// GetSingleCustomer - Retrieve single customer by code or taxId
// Parameter code = A1_COD + A1_LOJA concatenated (e.g. "00000101")
//=============================================================
Static Function GetSingleCustomer(oSelf)

    Local lRet       := .T.
    Local cCodeFull  := IIf(oSelf:code == Nil, "", oSelf:code)
    Local cTaxId     := IIf(oSelf:taxId == Nil, "", oSelf:taxId)
    Local oResponse  := Nil
    Local oCustomer  := Nil
    Local lFound     := .F.
    Local nTamCod    := TamSX3("A1_COD")[1]
    Local nTamLoja   := TamSX3("A1_LOJA")[1]
    Local cCode      := ""
    Local cStore     := ""
    
    DbSelectArea("SA1")
    
    If !Empty(cCodeFull)
        // Extract A1_COD and A1_LOJA from concatenated code
        cCode  := Left(cCodeFull, nTamCod)
        cStore := SubStr(cCodeFull, nTamCod + 1, nTamLoja)
        
        // If store not provided, default to "01"
        If Empty(cStore)
            cStore := "01"
        EndIf
        
        // Search by code + store
        DbSetOrder(1) // A1_FILIAL + A1_COD + A1_LOJA
        lFound := DbSeek(xFilial("SA1") + PadR(cCode, nTamCod) + PadR(cStore, nTamLoja))
    ElseIf !Empty(cTaxId)
        // Search by CNPJ/CPF
        DbSetOrder(3) // A1_FILIAL + A1_CGC
        lFound := DbSeek(xFilial("SA1") + PadR(cTaxId, TamSX3("A1_CGC")[1]))
    EndIf
    
    If !lFound
        oResponse := BuildResponse(.F., "Customer not found", Nil, Nil)
        oSelf:SetContentType("application/json")
        oSelf:SetStatus(404)
        oSelf:SetResponse(oResponse)
        Return .F.
    EndIf
    
    // Build customer object
    oCustomer := BuildCustomerObject("SA1")
    
    oResponse := BuildResponse(.T., "Customer found", oCustomer, Nil)
    oSelf:SetContentType("application/json")
    oSelf:SetResponse(oResponse)

Return lRet

//=============================================================
// CreateCustomer - Insert new customer
//=============================================================
Static Function CreateCustomer(oSelf, oObj)

    Local lRet       := .T.
    Local oResponse  := Nil
    Local aData      := {}
    Local cTaxId     := ""
    Local cCode      := ""
    Local cStore     := ""
    Local cError     := ""
    Local oResult    := Nil
    
    Private lMsErroAuto := .F.
    Private lMsHelpAuto := .F.
    
    // Validate required fields
    If !ValidateCustomerData(oObj, @cError, .T.)
        oResponse := BuildResponse(.F., cError, Nil, Nil)
        oSelf:SetContentType("application/json")
        oSelf:SetStatus(400)
        oSelf:SetResponse(oResponse)
        Return .F.
    EndIf
    
    // Check if customer already exists (by CNPJ/CPF)
    cTaxId := oObj:taxId
    DbSelectArea("SA1")
    DbSetOrder(3)
    If DbSeek(xFilial("SA1") + PadR(cTaxId, TamSX3("A1_CGC")[1]))
        oResult := JsonObject():New()
        oResult['code']  := AllTrim(SA1->A1_COD)
        oResult['store'] := AllTrim(SA1->A1_LOJA)
        oResponse := BuildResponse(.F., "Customer with this CNPJ/CPF already exists", oResult, Nil)
        oSelf:SetContentType("application/json")
        oSelf:SetStatus(409) // Conflict
        oSelf:SetResponse(oResponse)
        Return .F.
    EndIf
    
    // Build data array for MsExecAuto
    aData := MakeDataArray(oObj, .T.)
    
    // Get next code
    cCode := GetSxeNum("SA1", "A1_COD")
    cStore := IIf(ValType(oObj:store) == "C" .And. !Empty(oObj:store), oObj:store, "01")
    
    aAdd(aData, {"A1_FILIAL", xFilial("SA1"), Nil})
    aAdd(aData, {"A1_COD", cCode, Nil})
    aAdd(aData, {"A1_LOJA", cStore, Nil})
    
    // Execute MATA030 (Include = 3)
    MsExecAuto({|x,y| MATA030(x,y)}, aData, 3)
    
    If lMsErroAuto
        RollBackSx8()
        cError := GetAutoError()
        oResponse := BuildResponse(.F., "Error creating customer: " + cError, Nil, Nil)
        oSelf:SetContentType("application/json")
        oSelf:SetStatus(500)
        oSelf:SetResponse(oResponse)
        Return .F.
    EndIf
    
    ConfirmSx8()
    
    // Get the created record
    DbSelectArea("SA1")
    DbSetOrder(1)
    DbSeek(xFilial("SA1") + PadR(cCode, TamSX3("A1_COD")[1]) + PadR(cStore, TamSX3("A1_LOJA")[1]))
    
    // Return created customer data
    oResult := JsonObject():New()
    oResult['code']   := AllTrim(cCode)
    oResult['store']  := AllTrim(cStore)
    oResult['taxId']  := AllTrim(cTaxId)
    oResult['recno']  := SA1->(RecNo())
    
    oResponse := BuildResponse(.T., "Customer created successfully", oResult, Nil)
    oSelf:SetContentType("application/json")
    oSelf:SetStatus(201) // Created
    oSelf:SetResponse(oResponse)

Return lRet

//=============================================================
// UpdateCustomer - Update existing customer
//=============================================================
Static Function UpdateCustomer(oSelf, oObj)

    Local lRet       := .T.
    Local oResponse  := Nil
    Local aData      := {}
    Local cCode      := ""
    Local cStore     := ""
    Local cError     := ""
    Local oResult    := Nil
    
    Private lMsErroAuto := .F.
    Private lMsHelpAuto := .F.
    
    // Validate required fields for update
    If !ValidateCustomerData(oObj, @cError, .F.)
        oResponse := BuildResponse(.F., cError, Nil, Nil)
        oSelf:SetContentType("application/json")
        oSelf:SetStatus(400)
        oSelf:SetResponse(oResponse)
        Return .F.
    EndIf
    
    // Get customer code and store
    cCode  := IIf(ValType(oObj:code) == "C", oObj:code, "")
    cStore := IIf(ValType(oObj:store) == "C", oObj:store, "01")
    
    If Empty(cCode)
        oResponse := BuildResponse(.F., "Customer code is required for update", Nil, Nil)
        oSelf:SetContentType("application/json")
        oSelf:SetStatus(400)
        oSelf:SetResponse(oResponse)
        Return .F.
    EndIf
    
    // Check if customer exists
    DbSelectArea("SA1")
    DbSetOrder(1)
    If !DbSeek(xFilial("SA1") + PadR(cCode, TamSX3("A1_COD")[1]) + PadR(cStore, TamSX3("A1_LOJA")[1]))
        oResponse := BuildResponse(.F., "Customer not found", Nil, Nil)
        oSelf:SetContentType("application/json")
        oSelf:SetStatus(404)
        oSelf:SetResponse(oResponse)
        Return .F.
    EndIf
    
    // Build data array for MsExecAuto
    aData := MakeDataArray(oObj, .F.)
    
    aAdd(aData, {"A1_FILIAL", xFilial("SA1"), Nil})
    aAdd(aData, {"A1_COD", PadR(cCode, TamSX3("A1_COD")[1]), Nil})
    aAdd(aData, {"A1_LOJA", PadR(cStore, TamSX3("A1_LOJA")[1]), Nil})
    
    // Execute MATA030 (Update = 4)
    MsExecAuto({|x,y| MATA030(x,y)}, aData, 4)
    
    If lMsErroAuto
        cError := GetAutoError()
        oResponse := BuildResponse(.F., "Error updating customer: " + cError, Nil, Nil)
        oSelf:SetContentType("application/json")
        oSelf:SetStatus(500)
        oSelf:SetResponse(oResponse)
        Return .F.
    EndIf
    
    // Reposition to get RECNO
    DbSelectArea("SA1")
    DbSetOrder(1)
    DbSeek(xFilial("SA1") + PadR(cCode, TamSX3("A1_COD")[1]) + PadR(cStore, TamSX3("A1_LOJA")[1]))
    
    // Return updated customer data
    oResult := JsonObject():New()
    oResult['code']  := AllTrim(cCode)
    oResult['store'] := AllTrim(cStore)
    oResult['recno'] := SA1->(RecNo())
    
    oResponse := BuildResponse(.T., "Customer updated successfully", oResult, Nil)
    oSelf:SetContentType("application/json")
    oSelf:SetResponse(oResponse)

Return lRet

//=============================================================
// ValidateCustomerData - Validate required fields
//=============================================================
Static Function ValidateCustomerData(oObj, cError, lInsert)

    Local lRet := .T.
    
    cError := ""
    
    // For insert, taxId and name are required
    If lInsert
        If ValType(oObj:taxId) != "C" .Or. Empty(oObj:taxId)
            cError := "CNPJ/CPF (taxId) is required"
            Return .F.
        EndIf
        
        If ValType(oObj:name) != "C" .Or. Empty(oObj:name)
            cError := "Customer name is required"
            Return .F.
        EndIf
    EndIf
    
    // For update, code is required
    If !lInsert
        If ValType(oObj:code) != "C" .Or. Empty(oObj:code)
            cError := "Customer code is required for update"
            Return .F.
        EndIf
    EndIf

Return lRet

//=============================================================
// MakeDataArray - Build array for MsExecAuto
//=============================================================
Static Function MakeDataArray(oObj, lInsert)

    Local aData := {}
    
    // Auto-fill registration date/time for new customers
    If lInsert
        aAdd(aData, {"A1_DTCAD", dDatabase, Nil})
        aAdd(aData, {"A1_HRCAD", SubStr(Time(), 1, 5), Nil})
    EndIf
    
    // Basic identification
    If ValType(oObj:name) == "C"
        aAdd(aData, {"A1_NOME", oObj:name, Nil})
    EndIf
    
    If ValType(oObj:shortName) == "C"
        aAdd(aData, {"A1_NREDUZ", oObj:shortName, Nil})
    EndIf
    
    If ValType(oObj:taxId) == "C"
        aAdd(aData, {"A1_CGC", oObj:taxId, Nil})
    EndIf
    
    If ValType(oObj:stateRegistration) == "C"
        aAdd(aData, {"A1_INSCR", oObj:stateRegistration, Nil})
    EndIf
    
    If ValType(oObj:municipalRegistration) == "C"
        aAdd(aData, {"A1_INSCRM", oObj:municipalRegistration, Nil})
    EndIf
    
    If ValType(oObj:personType) == "C"
        aAdd(aData, {"A1_PESSOA", oObj:personType, Nil})
    EndIf
    
    If ValType(oObj:customerType) == "C"
        aAdd(aData, {"A1_TIPO", oObj:customerType, Nil})
    EndIf
    
    // Address
    If ValType(oObj:address) == "C"
        aAdd(aData, {"A1_END", oObj:address, Nil})
    EndIf
    
    If ValType(oObj:complement) == "C"
        aAdd(aData, {"A1_COMPLEM", oObj:complement, Nil})
    EndIf
    
    If ValType(oObj:neighborhood) == "C"
        aAdd(aData, {"A1_BAIRRO", oObj:neighborhood, Nil})
    EndIf
    
    If ValType(oObj:city) == "C"
        aAdd(aData, {"A1_MUN", oObj:city, Nil})
    EndIf
    
    If ValType(oObj:state) == "C"
        aAdd(aData, {"A1_EST", oObj:state, Nil})
    EndIf
    
    If ValType(oObj:zipCode) == "C"
        aAdd(aData, {"A1_CEP", oObj:zipCode, Nil})
    EndIf
    
    If ValType(oObj:cityCode) == "C"
        aAdd(aData, {"A1_COD_MUN", oObj:cityCode, Nil})
    EndIf
    
    If ValType(oObj:country) == "C"
        aAdd(aData, {"A1_PAIS", oObj:country, Nil})
    EndIf
    
    If ValType(oObj:countryCode) == "C"
        aAdd(aData, {"A1_CODPAIS", oObj:countryCode, Nil})
    EndIf
    
    // Contact - Phone
    If ValType(oObj:areaCode) == "C"
        aAdd(aData, {"A1_DDD", oObj:areaCode, Nil})
    EndIf
    
    If ValType(oObj:phone) == "C"
        aAdd(aData, {"A1_TEL", oObj:phone, Nil})
    EndIf
    
    If ValType(oObj:fax) == "C"
        aAdd(aData, {"A1_FAX", oObj:fax, Nil})
    EndIf
    
    // Contact - WhatsApp
    If ValType(oObj:whatsappAreaCode) == "C" .Or. ValType(oObj:whatsappAreaCode) == "N"
        aAdd(aData, {"A1_ZZDDDW", Val(cValToChar(oObj:whatsappAreaCode)), Nil})
    EndIf
    
    If ValType(oObj:whatsappPhone) == "C"
        aAdd(aData, {"A1_TELW", oObj:whatsappPhone, Nil})
    EndIf
    
    // Contact - Email
    If ValType(oObj:email) == "C"
        aAdd(aData, {"A1_EMAIL", oObj:email, Nil})
    EndIf
    
    If ValType(oObj:contact) == "C"
        aAdd(aData, {"A1_CONTATO", oObj:contact, Nil})
    EndIf
    
    // Sales
    If ValType(oObj:salespersonCode) == "C"
        aAdd(aData, {"A1_VEND", oObj:salespersonCode, Nil})
    EndIf
    
    If ValType(oObj:paymentCondition) == "C"
        aAdd(aData, {"A1_COND", oObj:paymentCondition, Nil})
    EndIf
    
    If ValType(oObj:priceTable) == "C"
        aAdd(aData, {"A1_TABELA", oObj:priceTable, Nil})
    EndIf
    
    If ValType(oObj:region) == "C"
        aAdd(aData, {"A1_REGIAO", oObj:region, Nil})
    EndIf
    
    If ValType(oObj:salesGroup) == "C"
        aAdd(aData, {"A1_GRPVEN", oObj:salesGroup, Nil})
    EndIf
    
    // Tax
    If ValType(oObj:taxGroup) == "C"
        aAdd(aData, {"A1_GRPTRIB", oObj:taxGroup, Nil})
    EndIf
    
    If ValType(oObj:icmsContributor) == "C"
        aAdd(aData, {"A1_CONTRIB", oObj:icmsContributor, Nil})
    EndIf
    
    // Financial
    If ValType(oObj:creditLimit) == "N"
        aAdd(aData, {"A1_LC", oObj:creditLimit, Nil})
    EndIf
    
    // Logistics
    If ValType(oObj:carrierCode) == "C"
        aAdd(aData, {"A1_TRANSP", oObj:carrierCode, Nil})
    EndIf
    
    // B2B
    If ValType(oObj:enabledB2B) == "C"
        aAdd(aData, {"A1_ZZLB2B", oObj:enabledB2B, Nil})
    EndIf
    
    // Observation
    If ValType(oObj:observation) == "C"
        aAdd(aData, {"A1_OBS", oObj:observation, Nil})
    EndIf

Return aData

//=============================================================
// BuildCustomerObject - Build JSON object from alias/table
//=============================================================
Static Function BuildCustomerObject(cAlias)

    Local oCustomer := JsonObject():New()
    Local lHasRecno := .F.
    
    Default cAlias := "SA1"
    
    // Check if RECNO field exists (from SQL query)
    lHasRecno := ((cAlias)->(FieldPos("RECNO")) > 0)
    
    // Identification
    oCustomer['code']              := AllTrim((cAlias)->A1_COD)
    oCustomer['store']             := AllTrim((cAlias)->A1_LOJA)
    oCustomer['branch']            := AllTrim((cAlias)->A1_FILIAL)
    oCustomer['name']              := FwNoAccent(AllTrim((cAlias)->A1_NOME))
    oCustomer['shortName']         := FwNoAccent(AllTrim((cAlias)->A1_NREDUZ))
    oCustomer['taxId']             := AllTrim((cAlias)->A1_CGC)
    oCustomer['stateRegistration'] := AllTrim((cAlias)->A1_INSCR)
    oCustomer['municipalRegistration'] := AllTrim((cAlias)->A1_INSCRM)
    oCustomer['personType']        := AllTrim((cAlias)->A1_PESSOA)
    oCustomer['customerType']      := AllTrim((cAlias)->A1_TIPO)
    oCustomer['blocked']           := ((cAlias)->A1_MSBLQL == "1")
    
    // Address
    oCustomer['address']           := FwNoAccent(AllTrim((cAlias)->A1_END))
    oCustomer['complement']        := FwNoAccent(AllTrim((cAlias)->A1_COMPLEM))
    oCustomer['neighborhood']      := FwNoAccent(AllTrim((cAlias)->A1_BAIRRO))
    oCustomer['city']              := FwNoAccent(AllTrim((cAlias)->A1_MUN))
    oCustomer['state']             := AllTrim((cAlias)->A1_EST)
    oCustomer['zipCode']           := AllTrim((cAlias)->A1_CEP)
    oCustomer['cityCode']          := AllTrim((cAlias)->A1_COD_MUN)
    oCustomer['country']           := FwNoAccent(AllTrim((cAlias)->A1_PAIS))
    oCustomer['countryCode']       := AllTrim((cAlias)->A1_CODPAIS)
    
    // Contact - Phone
    oCustomer['areaCode']          := AllTrim((cAlias)->A1_DDD)
    oCustomer['phone']             := AllTrim((cAlias)->A1_TEL)
    oCustomer['fax']               := AllTrim((cAlias)->A1_FAX)
    
    // Contact - WhatsApp
    oCustomer['whatsappAreaCode']  := (cAlias)->A1_ZZDDDW
    oCustomer['whatsappPhone']     := AllTrim((cAlias)->A1_TELW)
    
    // Contact - Email
    oCustomer['email']             := AllTrim((cAlias)->A1_EMAIL)
    oCustomer['contact']           := FwNoAccent(AllTrim((cAlias)->A1_CONTATO))
    
    // Sales
    oCustomer['salespersonCode']   := AllTrim((cAlias)->A1_VEND)
    oCustomer['paymentCondition']  := AllTrim((cAlias)->A1_COND)
    oCustomer['priceTable']        := AllTrim((cAlias)->A1_TABELA)
    oCustomer['region']            := AllTrim((cAlias)->A1_REGIAO)
    oCustomer['salesGroup']        := AllTrim((cAlias)->A1_GRPVEN)
    
    // Tax
    oCustomer['taxGroup']          := AllTrim((cAlias)->A1_GRPTRIB)
    oCustomer['icmsContributor']   := AllTrim((cAlias)->A1_CONTRIB)
    
    // Financial
    oCustomer['creditLimit']       := (cAlias)->A1_LC
    oCustomer['availableCredit']   := (cAlias)->A1_LC - (cAlias)->A1_SALDUP
    
    // Logistics
    oCustomer['carrierCode']       := AllTrim((cAlias)->A1_TRANSP)
    
    // B2B
    oCustomer['enabledB2B']        := AllTrim((cAlias)->A1_ZZLB2B)
    
    // Observation
    oCustomer['observation']       := FwNoAccent(AllTrim((cAlias)->A1_OBS))
    
    // Registration - Trata se vem como Date ou String (da query SQL)
    If ValType((cAlias)->A1_DTCAD) == "D"
        oCustomer['registrationDate'] := DToC((cAlias)->A1_DTCAD)
    Else
        oCustomer['registrationDate'] := AllTrim(cValToChar((cAlias)->A1_DTCAD))
    EndIf
    oCustomer['registrationTime']  := AllTrim((cAlias)->A1_HRCAD)
    
    // Record number (from SQL RECNO field or table RecNo())
    oCustomer['recno']             := IIf(lHasRecno, (cAlias)->RECNO, (cAlias)->(RecNo()))

Return oCustomer

//=============================================================
// GetTotalCustomers - Count total customers for pagination
//=============================================================
Static Function GetTotalCustomers()

    Local nTotal    := 0
    Local cAliasTmp := GetNextAlias()
    Local cQuery    := ""
    
    cQuery := " SELECT COUNT(*) AS TOTAL "
    cQuery += " FROM " + RetSqlName("SA1") + " "
    cQuery += " WHERE D_E_L_E_T_ = ' ' "
    cQuery += "   AND A1_FILIAL = '" + xFilial("SA1") + "' "
    
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
// BuildResponse - Build standardized JSON response (string manual)
//=============================================================
Static Function BuildResponse(lSuccess, cMessage, oData, oPagination)

    Local cResponse := ""
    Local cDataJson := ""
    Local cPagJson  := ""
    
    // Converte data para JSON string
    If oData != Nil
        If ValType(oData) == "A"
            cDataJson := ArrayToJsonStr(oData)
        ElseIf ValType(oData) == "O"
            cDataJson := oData:ToJson()
        Else
            cDataJson := '"' + cValToChar(oData) + '"'
        EndIf
    EndIf
    
    // Converte pagination para JSON string
    If oPagination != Nil .And. ValType(oPagination) == "O"
        cPagJson := oPagination:ToJson()
    EndIf
    
    // Constroi JSON manualmente como no EJCli.prw
    cResponse := '{'
    cResponse += '"success":' + IIf(lSuccess, 'true', 'false')
    cResponse += ',"message":"' + FwNoAccent(AllTrim(cMessage)) + '"'
    cResponse += ',"timestamp":"' + DToS(Date()) + 'T' + Time() + '"'
    cResponse += ',"version":"' + API_VERSION + '"'
    
    If !Empty(cDataJson)
        cResponse += ',"data":' + cDataJson
    EndIf
    
    If !Empty(cPagJson)
        cResponse += ',"pagination":' + cPagJson
    EndIf
    
    cResponse += '}'
    
    // Aplica UNESCAPE e EncodeUTF8 como no EJCli.prw
    cResponse := UNESCAPE(cResponse)
    cResponse := EncodeUTF8(cResponse)
    
    // Remove barras escapadas
    While At('%2F', cResponse) > 1
        cResponse := StrTran(cResponse, "%2F", "/")
    EndDo

Return cResponse

//=============================================================
// ArrayToJsonStr - Converte array de objetos para JSON string
//=============================================================
Static Function ArrayToJsonStr(aData)

    Local cJson := "["
    Local nX    := 0
    
    For nX := 1 To Len(aData)
        If nX > 1
            cJson += ","
        EndIf
        If ValType(aData[nX]) == "O"
            cJson += aData[nX]:ToJson()
        ElseIf ValType(aData[nX]) == "C"
            cJson += '"' + aData[nX] + '"'
        Else
            cJson += cValToChar(aData[nX])
        EndIf
    Next nX
    
    cJson += "]"

Return cJson

//=============================================================
// GetAutoError - Get error message from MsExecAuto
//=============================================================
Static Function GetAutoError()

    Local cError   := ""
    Local cArqLog  := ""
    Local cBuffer  := ""
    Local nX       := 0
    Local cLogPath := "\logs\"
    
    // Create log directory if not exists
    If !ExistDir(cLogPath)
        MakeDir(cLogPath)
    EndIf
    
    cError := FwNoAccent(MostraErro(cLogPath, cArqLog))
    
    // Extract error message
    For nX := 1 To MlCount(cError)
        cBuffer := RTrim(MemoLine(cError,, nX,, .F.))
        If AllTrim(Upper(SubStr(cBuffer, 1, 17))) == "MENSAGEM DO ERRO:"
            cError := StrTran(SubStr(cBuffer, At("[", cBuffer) + 1, 100), "]", "")
            Exit
        EndIf
    Next nX
    
    // Clean error message
    cError := StrTran(cError, Chr(13), " ")
    cError := StrTran(cError, Chr(10), " ")
    cError := AllTrim(cError)

Return cError
