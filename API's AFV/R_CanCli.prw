
#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"
/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Douglas.Silva Feat Carlos Eduardo Saturnino                                         *  
* Processa as informações e retorna o json                                                    *
* @since 	28/07/2019                                                                        *
* @version undefined                                                                          *
* @param oSelf, object, Objeto contendo dados da requisição efetuada pelo cliente, tais como: *
*    - Parâmetros querystring (parâmetros informado via URL)                                  *
*    - Objeto JSON caso o requisição seja efetuada via Request Post                           *
*    - Header da requisição                                                                   *
*    - entre outras ...                                                                       *
* @type Method                                                                                *
**********************************************************************************************/
#Define _Function "RestCanalCli"
#Define _DescFun  "Canal do Cliente"
#Define Desc_Rest "Serviço REST para Disponibilizar dados de Canal de Cliente"
#Define Desc_Get  "Retorna o cadastro de Canal de Cliente informado de acordo com os parametros passados" 

user function R_CanCli()
//Local cTeste	:= ""
//alert("rest R_CanCli_")
return

WSRESTFUL rCanCliGet DESCRIPTION Desc_Rest

	WSDATA cDataDe 	As String
	WSDATA cDataAte	As String
	WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING    

WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/rCanCliGet || /rCanCliGet/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE cDataDe, cDataAte,  nPag HEADERPARAM TENANTID WSSERVICE rCanCliGet

	Local aArea		:= GetArea()
	Local cAliasTMP
	Local aArea
	Local cRet		
	Local cSetResp
	Local nX
	Local cDtaDe
	Local cDtaAte
	Local nPagIni
	Local nPagFim
	Local nReg
	//teste autitincacao
	Local cAuth := "" 
	Local lAuthorized := .F.

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

	cRet		:= ""
	aArea     	:= GetArea()
	cAliasTMP 	:= GetNextAlias()
	nReg		:= 0


	//Verifica se há conexão em aberto, caso haja feche.
	IF Select(cAliasTmp)>0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf

	cQuery := "SELECT ROW_NUMBER() OVER(ORDER BY A.R_E_C_N_O_ ) AS CONT,A.* "
	cQuery += " FROM   " + RetSqlName("ACY") + " A  "
	cQuery += "	WHERE D_E_L_E_T_ <> '*'"


	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),(cAliasTMP),.T.,.T.)

	dbSelectArea(cAliasTMP)

	(cAliasTMP)->( DbGoTop() ) 

	While (cAliasTmp)->( !Eof() )
		nReg := (cAliasTmp)->CONT
		(cAliasTmp)->(dbSkip())
	EndDo  

	(cAliasTmp)->( DbGoTop() )

	If nReg <= 1000 
		nRegFinal := 1
	Else
		nRegFinal := Int(nReg/1000)+1 
	EndIf 

	If (cAliasTMP)->( Eof() )

		cSetResp := '{    "JSON": [],    "PaginalAtual": 1,    "TotalDePaginas": 1}'

	Else
		(cAliasTmp)->( DbGoTop() )  
		nX	:= 1
		cSetResp  := '{ "JSON":[ ' 				
		While (cAliasTmp)->( !Eof() )
			//IF (cAliasTmp)->cont >= nPagIni .And. (cAliasTmp)->cont <= nPagFim
			If nX > 1
				cSetResp  +=' , '
			EndIf				
			cSetResp  += '{'
			cSetResp  += '"CODIGO":"'		+ TRIM((cAliasTMP)->ACY_GRPVEN)					
			cSetResp  += '","DESCRICAO":"'	+ TRIM((cAliasTMP)->ACY_DESCRI)											
			cSetResp  += '"}'
			(cAliasTmp)->(dbSkip())
			nX:= nX+1
			/*	Else
			(cAliasTMP)->(dbSkip())
			LOOP	
			EndIf
			*/	
		EndDo
		cSetResp  += ']'	
		//cSetResp  += ',"PaginalAtual":'				+ cValToChar(Self:nPag)			
		cSetResp  += ',"TotalDePaginas":'			+ cValToChar(nRegFinal)
		cSetResp  += '}'	

	EndIf
	//Fecha a tabela
	(cAliasTmp)->(DbCloseArea())

	//verifica se houve dados
	If Len(cSetResp) == Len('{ "AtividadesCli":[ ]}')
		cSetResp := '{ "Retorno":"Nao Existe Itens Nessa Pagina"} '
	EndIF


	//Envia o JSON Gerado para a aplicação Cliente

	cSetResp := UNESCAPE(cSetResp)	

	While At('%2F',cSetResp) > 1
		cSetResp := strTran(cSetResp, "%2F", "/")
	EndDo

	::SetResponse( cSetResp ) 		

	RestArea(aArea)		

Return(.T.)
