#include 'totvs.ch'
 
/*/{Protheus.doc} User Function genToken
    get Bearer Token using /token endpoint
    @type  Function
    @author Alison Kaique
    @since Feb|2022
    @version 1.0
     
    @return cToken, character, Bearer Token
/*/
User Function genToken()
    Local cToken     As Character // Bearer Token
    Local cBaseURL   As Character // Base URL
    Local cPath      As Character // endpoint path
    Local cGrantType As Character // grant type
    Local cUserName  As Character // user name
    Local cPassword  As Character // password
    Local cResponse  As Character // response
    Local cStatus    As Character // status code
    Local cError     As Character // error message
    Local oRest      As Object // FWRest() object
    Local jResponse  As Json // response JsonObject
    Local aHeader    As Array // request header
 
    // set values
    cGrantType := "password" // type here grant type to request
    cUserName  := "admin" // type here user name
    cPassword  := "1234" // type here user password
    cBaseURL   := "localhost:9090" // type here your base URL
    cPath      := "/api/oauth2/v1/token?grant_type=" + cGrantType + "&username=" + cUserName + "&password=" + cPassword // type here token endpoint
    aHeader    := {}
 
    Aadd(aHeader, "Authorization: Basic " + Encode64(cUserName + ":" + cPassword))
    Aadd(aHeader, "Content-Type: application/json")
 
    // FWRest() object
    oRest := FWRest():New(cBaseURL)
    oRest:setPath(cPath)
 
    // request
    If (oRest:Post(aHeader))
        cResponse := oRest:GetResult()
        jResponse := JsonObject():New()
 
        // is possible access this properties in response
        /**
            expires_in
            token_type
            scope
            access_token
            refresh_token
        **/
 
        If (ValType(jResponse:fromJson(cResponse)) == 'U')
            cToken := jResponse['access_token']
        EndIf
    Else
        cError  := oRest:GetLastError()
        cStatus := oRest:GetHTTPCode()
    EndIf
Return cToken
 
/*/{Protheus.doc} User Function tstToken
    just to test genToken() function
    @type  Function
    @author Alison Kaique
    @since Feb|2022
    @version 1.0
/*/
User Function tstToken(param_name)
    Local cToken As Character // bearer token
 
    cToken := u_getToken()
Return
