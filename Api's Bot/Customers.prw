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
// CreateCustomer - Insert new customer with error handling
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
    Local oError     := Nil
    Local bOldErr    := Nil
    
    Private lMsErroAuto := .F.
    Private lMsHelpAuto := .F.
    
    // Set up error handler
    bOldErr := ErrorBlock({|e| oError := e, Break(e)})
    
    Begin Sequence
    
        // Validate required fields
        If !ValidateCustomerData(oObj, @cError, .T.)
            oResponse := BuildResponse(.F., cError, Nil, Nil)
            oSelf:SetContentType("application/json")
            oSelf:SetStatus(400)
            oSelf:SetResponse(oResponse)
            ErrorBlock(bOldErr)
            Return .F.
        EndIf
        
        // Get taxId using safe getter
        cTaxId := GetJsonString(oObj, "taxId", "")
        
        // Check if customer already exists (by CNPJ/CPF)
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
            ErrorBlock(bOldErr)
            Return .F.
        EndIf
        
        // Build data array for MsExecAuto
        aData := MakeDataArray(oObj, .T.)
        
        // Get next code
        cCode := GetSxeNum("SA1", "A1_COD")
        cStore := GetJsonString(oObj, "store", "01")
        If Empty(cStore)
            cStore := "01"
        EndIf
        
        aAdd(aData, {"A1_FILIAL", xFilial("SA1"), Nil})
        aAdd(aData, {"A1_COD", cCode, Nil})
        aAdd(aData, {"A1_LOJA", cStore, Nil})
        
        // Execute MATA030 (Include = 3)
        MsExecAuto({|x,y| MATA030(x,y)}, aData, 3)
        
        If lMsErroAuto
            RollBackSx8()
            cError := GetAutoError()
            ConOut("[CUSTOMERS API] MsExecAuto Error (CREATE): " + cError)
            oResponse := BuildResponse(.F., "Error creating customer: " + cError, Nil, Nil)
            oSelf:SetContentType("application/json")
            oSelf:SetStatus(422) // Unprocessable Entity - business validation error
            oSelf:SetResponse(oResponse)
            ErrorBlock(bOldErr)
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
        
    Recover Using oError
        
        // Handle unexpected errors - log to server console
        cError := "Unexpected error: " + oError:Description + " at " + oError:Operation
        If !Empty(oError:ErrorStack)
            cError += " | Stack: " + oError:ErrorStack
        EndIf
        
        ConOut("[CUSTOMERS API] Unexpected Error (CREATE): " + cError)
        ConOut("[CUSTOMERS API] ErrorStack: " + oError:ErrorStack)
        
        oResponse := BuildResponse(.F., FwNoAccent(cError), Nil, Nil)
        oSelf:SetContentType("application/json")
        oSelf:SetStatus(520) // Custom error code to differentiate from system 500
        oSelf:SetResponse(oResponse)
        lRet := .F.
        
    End Sequence
    
    ErrorBlock(bOldErr)

Return lRet

//=============================================================
// UpdateCustomer - Update existing customer with error handling
//=============================================================
Static Function UpdateCustomer(oSelf, oObj)

    Local lRet       := .T.
    Local oResponse  := Nil
    Local aData      := {}
    Local cCode      := ""
    Local cStore     := ""
    Local cError     := ""
    Local oResult    := Nil
    Local oError     := Nil
    Local bOldErr    := Nil
    
    Private lMsErroAuto := .F.
    Private lMsHelpAuto := .F.
    
    // Set up error handler
    bOldErr := ErrorBlock({|e| oError := e, Break(e)})
    
    Begin Sequence
    
        // Validate required fields for update
        If !ValidateCustomerData(oObj, @cError, .F.)
            oResponse := BuildResponse(.F., cError, Nil, Nil)
            oSelf:SetContentType("application/json")
            oSelf:SetStatus(400)
            oSelf:SetResponse(oResponse)
            ErrorBlock(bOldErr)
            Return .F.
        EndIf
        
        // Get customer code and store using safe getters
        cCode  := GetJsonString(oObj, "code", "")
        cStore := GetJsonString(oObj, "store", "01")
        If Empty(cStore)
            cStore := "01"
        EndIf
        
        If Empty(cCode)
            oResponse := BuildResponse(.F., "Customer code is required for update", Nil, Nil)
            oSelf:SetContentType("application/json")
            oSelf:SetStatus(400)
            oSelf:SetResponse(oResponse)
            ErrorBlock(bOldErr)
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
            ErrorBlock(bOldErr)
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
            ConOut("[CUSTOMERS API] MsExecAuto Error (UPDATE): " + cError)
            oResponse := BuildResponse(.F., "Error updating customer: " + cError, Nil, Nil)
            oSelf:SetContentType("application/json")
            oSelf:SetStatus(422) // Unprocessable Entity - business validation error
            oSelf:SetResponse(oResponse)
            ErrorBlock(bOldErr)
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
        
    Recover Using oError
        
        // Handle unexpected errors - log to server console
        cError := "Unexpected error: " + oError:Description + " at " + oError:Operation
        If !Empty(oError:ErrorStack)
            cError += " | Stack: " + oError:ErrorStack
        EndIf
        
        ConOut("[CUSTOMERS API] Unexpected Error (UPDATE): " + cError)
        ConOut("[CUSTOMERS API] ErrorStack: " + oError:ErrorStack)
        
        oResponse := BuildResponse(.F., FwNoAccent(cError), Nil, Nil)
        oSelf:SetContentType("application/json")
        oSelf:SetStatus(520) // Custom error code to differentiate from system 500
        oSelf:SetResponse(oResponse)
        lRet := .F.
        
    End Sequence
    
    ErrorBlock(bOldErr)

Return lRet

//=============================================================
// ValidateCustomerData - Validate required fields with detailed errors
//=============================================================
Static Function ValidateCustomerData(oObj, cError, lInsert)

    Local lRet         := .T.
    Local aErrors      := {}
    Local cName        := ""
    Local cTaxId       := ""
    Local cCode        := ""
    Local cPersonType  := ""
    Local cCustomerType:= ""
    Local cState       := ""
    Local cIcms        := ""
    Local cB2B         := ""
    Local cEmail       := ""
    Local cZip         := ""
    
    cError := ""
    
    // Validate object
    If oObj == Nil .Or. ValType(oObj) != "O"
        cError := "Invalid request body: JSON object expected"
        Return .F.
    EndIf
    
    // For insert, validate required fields
    If lInsert
        // taxId (CNPJ/CPF) - Required and sanitized
        cTaxId := SanitizeTaxId(GetJsonString(oObj, "taxId", ""))
        If Empty(cTaxId)
            aAdd(aErrors, "taxId (CNPJ/CPF) is required")
        ElseIf Len(cTaxId) < 11
            aAdd(aErrors, "taxId must have at least 11 digits (CPF) or 14 (CNPJ) after removing formatting")
        ElseIf Len(cTaxId) != 11 .And. Len(cTaxId) != 14
            aAdd(aErrors, "taxId must have exactly 11 digits (CPF) or 14 digits (CNPJ)")
        EndIf
        
        // name - Required
        cName := GetJsonString(oObj, "name", "")
        If Empty(cName)
            aAdd(aErrors, "name (Customer name) is required")
        ElseIf Len(AllTrim(cName)) < 3
            aAdd(aErrors, "name must have at least 3 characters")
        EndIf
    EndIf
    
    // For update, code is required
    If !lInsert
        cCode := GetJsonString(oObj, "code", "")
        If Empty(cCode)
            aAdd(aErrors, "code (Customer code) is required for update")
        EndIf
    EndIf
    
    // Optional field validations (validate type if provided)
    cPersonType := GetJsonString(oObj, "personType", "")
    If !Empty(cPersonType) .And. !(cPersonType $ "J|F")
        aAdd(aErrors, "personType must be 'J' (Juridica) or 'F' (Fisica)")
    EndIf
    
    cCustomerType := GetJsonString(oObj, "customerType", "")
    If !Empty(cCustomerType) .And. !(cCustomerType $ "R|L|F|S|X")
        aAdd(aErrors, "customerType must be: R (Revendedor), L (Solidario), F (Consumidor Final), S (Produtor Rural), X (Exportacao)")
    EndIf
    
    cState := GetJsonString(oObj, "state", "")
    If !Empty(cState) .And. Len(AllTrim(cState)) != 2
        aAdd(aErrors, "state must be 2 characters (e.g. SP, RJ, MG)")
    EndIf
    
    // Validate icmsContributor
    If HasJsonProperty(oObj, "icmsContributor")
        cIcms := GetJsonString(oObj, "icmsContributor", "")
        If !Empty(cIcms) .And. !(cIcms $ "1|2|9")
            aAdd(aErrors, "icmsContributor must be: 1 (Contribuinte), 2 (Isento), 9 (Nao Contribuinte)")
        EndIf
    EndIf
    
    // Validate enabledB2B
    If HasJsonProperty(oObj, "enabledB2B")
        cB2B := GetJsonString(oObj, "enabledB2B", "")
        If !Empty(cB2B) .And. !(cB2B $ "1|2")
            aAdd(aErrors, "enabledB2B must be: 1 (Sim) or 2 (Nao)")
        EndIf
    EndIf
    
    // Validate email format
    If HasJsonProperty(oObj, "email")
        cEmail := GetJsonString(oObj, "email", "")
        If !Empty(cEmail)
            cEmail := AllTrim(cEmail)
            If At("@", cEmail) == 0 .Or. At(".", cEmail) == 0
                aAdd(aErrors, "email format is invalid (must contain @ and .)")
            EndIf
        EndIf
    EndIf
    
    // Validate zipCode format
    If HasJsonProperty(oObj, "zipCode")
        cZip := SanitizeZipCode(GetJsonString(oObj, "zipCode", ""))
        If !Empty(cZip) .And. Len(cZip) != 8
            aAdd(aErrors, "zipCode must have 8 digits after removing formatting")
        EndIf
    EndIf
    
    // Validate foreign key references (only for insert or if provided)
    // Vendedor (SA3)
    If lInsert .Or. HasJsonProperty(oObj, "salespersonCode")
        If !ValidateForeignKey(oObj, "salespersonCode", "SA3", "A3_COD", @aErrors)
        EndIf
    EndIf
    
    // Condição de Pagamento (SE4)
    If lInsert .Or. HasJsonProperty(oObj, "paymentCondition")
        If !ValidateForeignKey(oObj, "paymentCondition", "SE4", "E4_CODIGO", @aErrors)
        EndIf
    EndIf
    
    // Tabela de Preço (DA0)
    If lInsert .Or. HasJsonProperty(oObj, "priceTable")
        If !ValidateForeignKey(oObj, "priceTable", "DA0", "DA0_CODTAB", @aErrors)
        EndIf
    EndIf
    
    // Transportadora (SA4)
    If lInsert .Or. HasJsonProperty(oObj, "carrierCode")
        If !ValidateForeignKey(oObj, "carrierCode", "SA4", "A4_COD", @aErrors)
        EndIf
    EndIf
    
    // Região (ACJ)
    If lInsert .Or. HasJsonProperty(oObj, "region")
        If !ValidateForeignKey(oObj, "region", "ACJ", "ACJ_REGIAO", @aErrors)
        EndIf
    EndIf
    
    // Grupo de Venda (ACY)
    If lInsert .Or. HasJsonProperty(oObj, "salesGroup")
        If !ValidateForeignKey(oObj, "salesGroup", "ACY", "ACY_GRPVEN", @aErrors)
        EndIf
    EndIf
    
    // Grupo Tributário (SX5 - tabela C1) - Temporarily disabled
    //If lInsert .Or. HasJsonProperty(oObj, "taxGroup")
    //    If !ValidFKX5(oObj, "taxGroup", "C1", @aErrors)
    //    EndIf
    //EndIf
    
    // Build error message if there are any errors
    If Len(aErrors) > 0
        cError := "Validation errors: " + ArrayToStr(aErrors, "; ")
        Return .F.
    EndIf

Return lRet

//=============================================================
// ValidateForeignKey - Check if code exists in related table
//=============================================================
Static Function ValidateForeignKey(oObj, cProperty, cTable, cField, aErrors)

    Local lValid   := .T.
    Local cValue   := ""
    Local cOldArea := ""
    Local nFieldLen:= 0
    
    cValue := SanitizeCode(GetJsonString(oObj, cProperty, ""), cField)
    
    // Skip if empty (not provided)
    If Empty(cValue)
        Return .T.
    EndIf
    
    // Get field length safely
    nFieldLen := GetFieldLen(cField)
    If nFieldLen == 0
        // Field doesn't exist in dictionary, skip validation
        Return .T.
    EndIf
    
    // Save current area and validate
    cOldArea := Alias()
    
    Begin Sequence
        DbSelectArea(cTable)
        DbSetOrder(1)
        
        If !DbSeek(xFilial(cTable) + PadR(cValue, nFieldLen))
            aAdd(aErrors, cProperty + " '" + AllTrim(cValue) + "' not found in " + cTable)
            lValid := .F.
        EndIf
    Recover
        // Table might not exist or be accessible
        lValid := .T.
    End Sequence
    
    // Restore area
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
// SANITIZATION FUNCTIONS
//=============================================================

//=============================================================
// SanitizeString - Clean and standardize text fields
// Removes dangerous chars, trims, and optionally converts to upper
//=============================================================
Static Function SanitizeString(cValue, cField, lUpper)

    Local cResult := ""
    Local nMaxLen := 0
    
    Default lUpper := .T.
    
    If ValType(cValue) != "C" .Or. Empty(cValue)
        Return ""
    EndIf
    
    cResult := AllTrim(cValue)
    
    // Remove dangerous characters for SQL/JSON
    cResult := StrTran(cResult, "'", "")
    cResult := StrTran(cResult, '"', "")
    cResult := StrTran(cResult, "\", "")
    cResult := StrTran(cResult, Chr(0), "")
    cResult := StrTran(cResult, Chr(9), " ")  // Tab
    cResult := StrTran(cResult, Chr(10), " ") // LF
    cResult := StrTran(cResult, Chr(13), " ") // CR
    
    // Convert to uppercase (Protheus standard)
    If lUpper
        cResult := Upper(cResult)
    EndIf
    
    // Truncate to field max length if field name provided
    If !Empty(cField)
        nMaxLen := GetFieldLen(cField)
        If nMaxLen > 0 .And. Len(cResult) > nMaxLen
            cResult := Left(cResult, nMaxLen)
        EndIf
    EndIf
    
Return cResult

//=============================================================
// SanitizeTaxId - Clean CNPJ/CPF (remove formatting chars)
//=============================================================
Static Function SanitizeTaxId(cValue)

    Local cResult := ""
    
    If ValType(cValue) != "C" .Or. Empty(cValue)
        Return ""
    EndIf
    
    cResult := AllTrim(cValue)
    
    // Remove formatting characters
    cResult := StrTran(cResult, ".", "")
    cResult := StrTran(cResult, "-", "")
    cResult := StrTran(cResult, "/", "")
    cResult := StrTran(cResult, " ", "")
    
    // Keep only digits
    cResult := OnlyNumbers(cResult)
    
Return cResult

//=============================================================
// SanitizePhone - Clean phone numbers (only digits)
//=============================================================
Static Function SanitizePhone(cValue)

    Local cResult := ""
    
    If ValType(cValue) != "C" .Or. Empty(cValue)
        Return ""
    EndIf
    
    cResult := AllTrim(cValue)
    
    // Remove common phone formatting
    cResult := StrTran(cResult, "(", "")
    cResult := StrTran(cResult, ")", "")
    cResult := StrTran(cResult, "-", "")
    cResult := StrTran(cResult, " ", "")
    cResult := StrTran(cResult, "+", "")
    
    // Keep only digits
    cResult := OnlyNumbers(cResult)
    
Return cResult

//=============================================================
// SanitizeZipCode - Clean CEP (only digits)
//=============================================================
Static Function SanitizeZipCode(cValue)

    Local cResult := ""
    
    If ValType(cValue) != "C" .Or. Empty(cValue)
        Return ""
    EndIf
    
    cResult := AllTrim(cValue)
    
    // Remove formatting
    cResult := StrTran(cResult, "-", "")
    cResult := StrTran(cResult, ".", "")
    cResult := StrTran(cResult, " ", "")
    
    // Keep only digits
    cResult := OnlyNumbers(cResult)
    
    // Pad with zeros if needed (CEP has 8 digits)
    If Len(cResult) > 0 .And. Len(cResult) < 8
        cResult := PadL(cResult, 8, "0")
    EndIf
    
Return cResult

//=============================================================
// SanitizeEmail - Clean and validate email format
//=============================================================
Static Function SanitizeEmail(cValue)

    Local cResult := ""
    
    If ValType(cValue) != "C" .Or. Empty(cValue)
        Return ""
    EndIf
    
    cResult := AllTrim(cValue)
    
    // Email should be lowercase
    cResult := Lower(cResult)
    
    // Remove dangerous characters
    cResult := StrTran(cResult, "'", "")
    cResult := StrTran(cResult, '"', "")
    cResult := StrTran(cResult, " ", "")
    cResult := StrTran(cResult, "\", "")
    
    // Basic email validation (must have @ and .)
    If At("@", cResult) == 0 .Or. At(".", cResult) == 0
        Return ""
    EndIf
    
    // Truncate to field max length
    nMaxLen := GetFieldLen("A1_EMAIL")
    If nMaxLen > 0 .And. Len(cResult) > nMaxLen
        cResult := Left(cResult, nMaxLen)
    EndIf
    
Return cResult

//=============================================================
// OnlyNumbers - Extract only numeric digits from string
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
// SanitizeCode - Clean code fields (alphanumeric, no special chars)
//=============================================================
Static Function SanitizeCode(cValue, cField)

    Local cResult := ""
    Local nMaxLen := 0
    
    If ValType(cValue) != "C" .Or. Empty(cValue)
        Return ""
    EndIf
    
    cResult := AllTrim(Upper(cValue))
    
    // Remove dangerous characters
    cResult := StrTran(cResult, "'", "")
    cResult := StrTran(cResult, '"', "")
    cResult := StrTran(cResult, "\", "")
    cResult := StrTran(cResult, " ", "")
    
    // Truncate to field max length
    If !Empty(cField)
        nMaxLen := GetFieldLen(cField)
        If nMaxLen > 0 .And. Len(cResult) > nMaxLen
            cResult := Left(cResult, nMaxLen)
        EndIf
    EndIf
    
Return cResult

//=============================================================
// MakeDataArray - Build array for MsExecAuto with sanitization
//=============================================================
Static Function MakeDataArray(oObj, lInsert)

    Local aData   := {}
    Local cValue  := ""
    Local nValue  := 0
    
    // Auto-fill registration date/time for new customers
    If lInsert
        aAdd(aData, {"A1_DTCAD", dDatabase, Nil})
        aAdd(aData, {"A1_HRCAD", SubStr(Time(), 1, 5), Nil})
    EndIf
    
    // Basic identification - with sanitization
    cValue := SanitizeString(GetJsonString(oObj, "name", ""), "A1_NOME", .T.)
    If !Empty(cValue)
        aAdd(aData, {"A1_NOME", cValue, Nil})
    EndIf
    
    cValue := SanitizeString(GetJsonString(oObj, "shortName", ""), "A1_NREDUZ", .T.)
    If !Empty(cValue)
        aAdd(aData, {"A1_NREDUZ", cValue, Nil})
    EndIf
    
    // CNPJ/CPF - remove formatting
    cValue := SanitizeTaxId(GetJsonString(oObj, "taxId", ""))
    If !Empty(cValue)
        aAdd(aData, {"A1_CGC", cValue, Nil})
    EndIf
    
    cValue := SanitizeString(GetJsonString(oObj, "stateRegistration", ""), "A1_INSCR", .T.)
    If !Empty(cValue)
        aAdd(aData, {"A1_INSCR", cValue, Nil})
    EndIf
    
    cValue := SanitizeString(GetJsonString(oObj, "municipalRegistration", ""), "A1_INSCRM", .T.)
    If !Empty(cValue)
        aAdd(aData, {"A1_INSCRM", cValue, Nil})
    EndIf
    
    cValue := Upper(AllTrim(GetJsonString(oObj, "personType", "")))
    If !Empty(cValue)
        aAdd(aData, {"A1_PESSOA", cValue, Nil})
    EndIf
    
    cValue := Upper(AllTrim(GetJsonString(oObj, "customerType", "")))
    If !Empty(cValue)
        aAdd(aData, {"A1_TIPO", cValue, Nil})
    EndIf
    
    // Address - with sanitization
    cValue := SanitizeString(GetJsonString(oObj, "address", ""), "A1_END", .T.)
    If !Empty(cValue)
        aAdd(aData, {"A1_END", cValue, Nil})
    EndIf
    
    cValue := SanitizeString(GetJsonString(oObj, "complement", ""), "A1_COMPLEM", .T.)
    If !Empty(cValue)
        aAdd(aData, {"A1_COMPLEM", cValue, Nil})
    EndIf
    
    cValue := SanitizeString(GetJsonString(oObj, "neighborhood", ""), "A1_BAIRRO", .T.)
    If !Empty(cValue)
        aAdd(aData, {"A1_BAIRRO", cValue, Nil})
    EndIf
    
    cValue := SanitizeString(GetJsonString(oObj, "city", ""), "A1_MUN", .T.)
    If !Empty(cValue)
        aAdd(aData, {"A1_MUN", cValue, Nil})
    EndIf
    
    cValue := Upper(AllTrim(GetJsonString(oObj, "state", "")))
    If !Empty(cValue) .And. Len(cValue) == 2
        aAdd(aData, {"A1_EST", cValue, Nil})
    EndIf
    
    // CEP - only numbers
    cValue := SanitizeZipCode(GetJsonString(oObj, "zipCode", ""))
    If !Empty(cValue)
        aAdd(aData, {"A1_CEP", cValue, Nil})
    EndIf
    
    cValue := SanitizeCode(GetJsonString(oObj, "cityCode", ""), "A1_COD_MUN")
    If !Empty(cValue)
        aAdd(aData, {"A1_COD_MUN", cValue, Nil})
    EndIf
    
    cValue := SanitizeString(GetJsonString(oObj, "country", ""), "A1_PAIS", .T.)
    If !Empty(cValue)
        aAdd(aData, {"A1_PAIS", cValue, Nil})
    EndIf
    
    cValue := SanitizeCode(GetJsonString(oObj, "countryCode", ""), "A1_CODPAIS")
    If !Empty(cValue)
        aAdd(aData, {"A1_CODPAIS", cValue, Nil})
    EndIf
    
    // Contact - Phone (only numbers)
    cValue := SanitizePhone(GetJsonString(oObj, "areaCode", ""))
    If !Empty(cValue)
        aAdd(aData, {"A1_DDD", cValue, Nil})
    EndIf
    
    cValue := SanitizePhone(GetJsonString(oObj, "phone", ""))
    If !Empty(cValue)
        aAdd(aData, {"A1_TEL", cValue, Nil})
    EndIf
    
    cValue := SanitizePhone(GetJsonString(oObj, "fax", ""))
    If !Empty(cValue)
        aAdd(aData, {"A1_FAX", cValue, Nil})
    EndIf
    
    // Contact - WhatsApp (accepts string or number)
    If HasJsonProperty(oObj, "whatsappAreaCode")
        nValue := GetJsonNumber(oObj, "whatsappAreaCode", 0)
        If nValue > 0
            aAdd(aData, {"A1_ZZDDDW", nValue, Nil})
        EndIf
    EndIf
    
    cValue := SanitizePhone(GetJsonString(oObj, "whatsappPhone", ""))
    If !Empty(cValue)
        aAdd(aData, {"A1_TELW", cValue, Nil})
    EndIf
    
    // Contact - Email (lowercase, validated)
    cValue := SanitizeEmail(GetJsonString(oObj, "email", ""))
    If !Empty(cValue)
        aAdd(aData, {"A1_EMAIL", cValue, Nil})
    EndIf
    
    cValue := SanitizeString(GetJsonString(oObj, "contact", ""), "A1_CONTATO", .T.)
    If !Empty(cValue)
        aAdd(aData, {"A1_CONTATO", cValue, Nil})
    EndIf
    
    // Sales - Code fields
    cValue := SanitizeCode(GetJsonString(oObj, "salespersonCode", ""), "A1_VEND")
    If !Empty(cValue)
        aAdd(aData, {"A1_VEND", cValue, Nil})
    EndIf
    
    cValue := SanitizeCode(GetJsonString(oObj, "paymentCondition", ""), "A1_COND")
    If !Empty(cValue)
        aAdd(aData, {"A1_COND", cValue, Nil})
    EndIf
    
    cValue := SanitizeCode(GetJsonString(oObj, "priceTable", ""), "A1_TABELA")
    If !Empty(cValue)
        aAdd(aData, {"A1_TABELA", cValue, Nil})
    EndIf
    
    cValue := SanitizeCode(GetJsonString(oObj, "region", ""), "A1_REGIAO")
    If !Empty(cValue)
        aAdd(aData, {"A1_REGIAO", cValue, Nil})
    EndIf
    
    cValue := SanitizeCode(GetJsonString(oObj, "salesGroup", ""), "A1_GRPVEN")
    If !Empty(cValue)
        aAdd(aData, {"A1_GRPVEN", cValue, Nil})
    EndIf
    
    // Tax
    cValue := SanitizeCode(GetJsonString(oObj, "taxGroup", ""), "A1_GRPTRIB")
    If !Empty(cValue)
        aAdd(aData, {"A1_GRPTRIB", cValue, Nil})
    EndIf
    
    cValue := AllTrim(GetJsonString(oObj, "icmsContributor", ""))
    If !Empty(cValue) .And. (cValue $ "1|2|9")
        aAdd(aData, {"A1_CONTRIB", cValue, Nil})
    EndIf
    
    // Financial
    If HasJsonProperty(oObj, "creditLimit")
        nValue := GetJsonNumber(oObj, "creditLimit", 0)
        If nValue > 0
            aAdd(aData, {"A1_LC", nValue, Nil})
        EndIf
    EndIf
    
    // Logistics
    cValue := SanitizeCode(GetJsonString(oObj, "carrierCode", ""), "A1_TRANSP")
    If !Empty(cValue)
        aAdd(aData, {"A1_TRANSP", cValue, Nil})
    EndIf
    
    // B2B
    cValue := AllTrim(GetJsonString(oObj, "enabledB2B", ""))
    If !Empty(cValue) .And. (cValue $ "1|2")
        aAdd(aData, {"A1_ZZLB2B", cValue, Nil})
    EndIf
    
    // Observation - allow lowercase for memo field
    cValue := SanitizeString(GetJsonString(oObj, "observation", ""), "A1_OBS", .F.)
    If !Empty(cValue)
        aAdd(aData, {"A1_OBS", cValue, Nil})
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

//=============================================================
// GetJsonValue - Safely get property value from JSON object
// Returns Nil if property does not exist or on error
//=============================================================
Static Function GetJsonValue(oObj, cProperty)

    Local xValue   := Nil
    Local oError   := Nil
    Local bOldErr  := Nil
    
    If oObj == Nil .Or. ValType(oObj) != "O"
        Return Nil
    EndIf
    
    If Empty(cProperty) .Or. ValType(cProperty) != "C"
        Return Nil
    EndIf
    
    // Try to access property safely using ErrorBlock
    bOldErr := ErrorBlock({|e| oError := e, Break(e)})
    
    Begin Sequence
        // Use bracket notation to access property
        xValue := oObj[cProperty]
    Recover
        xValue := Nil
    End Sequence
    
    ErrorBlock(bOldErr)
    
Return xValue

//=============================================================
// HasJsonProperty - Check if property exists in JSON object
//=============================================================
Static Function HasJsonProperty(oObj, cProperty)

    Local xValue := GetJsonValue(oObj, cProperty)
    
Return (xValue != Nil)

//=============================================================
// GetJsonString - Get string property or empty string
//=============================================================
Static Function GetJsonString(oObj, cProperty, cDefault)

    Local xValue := GetJsonValue(oObj, cProperty)
    
    Default cDefault := ""
    
    If xValue == Nil .Or. ValType(xValue) != "C"
        Return cDefault
    EndIf
    
Return xValue

//=============================================================
// GetJsonNumber - Get numeric property or default value
//=============================================================
Static Function GetJsonNumber(oObj, cProperty, nDefault)

    Local xValue := GetJsonValue(oObj, cProperty)
    
    Default nDefault := 0
    
    If xValue == Nil
        Return nDefault
    EndIf
    
    If ValType(xValue) == "N"
        Return xValue
    ElseIf ValType(xValue) == "C"
        Return Val(xValue)
    EndIf
    
Return nDefault

//=============================================================
// GetFieldLen - Safely get field length from SX3 dictionary
// Returns 0 if field doesn't exist or on error
//=============================================================
Static Function GetFieldLen(cField)

    Local aTam     := {}
    Local nLen     := 0
    Local oError   := Nil
    Local bOldErr  := Nil
    
    If Empty(cField) .Or. ValType(cField) != "C"
        Return 0
    EndIf
    
    // Try to get field size safely
    bOldErr := ErrorBlock({|e| oError := e, Break(e)})
    
    Begin Sequence
        aTam := TamSX3(cField)
        If ValType(aTam) == "A" .And. Len(aTam) >= 1
            nLen := aTam[1]
        EndIf
    Recover
        ConOut("[CUSTOMERS API] GetFieldLen error for field: " + cField)
        nLen := 0
    End Sequence
    
    ErrorBlock(bOldErr)
    
Return nLen
