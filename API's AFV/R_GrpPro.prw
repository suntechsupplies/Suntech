#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"

/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Douglas.Silva                                                                       *  
* Processa as informações e retorna o json                                                    *
* @since 	03/08/2019                                                                        *
* @version undefined                                                                          *
* @param oSelf, object, Objeto contendo dados da requisição efetuada pelo cliente, tais como: *
*    - Parâmetros querystring (parâmetros informado via URL)                                  *
*    - Objeto JSON caso o requisição seja efetuada via Request Post                           *
*    - Header da requisição                                                                   *
*    - entre outras ...                                                                       *
* @type Method                                                                                *
**********************************************************************************************/

#Define _Function	"GrpPro"
#Define _DescFun   "Grupo de Produto"
#Define Desc_Rest 	"Serviço REST para Disponibilizar / Inserir dados de Grupo de Produto"
#Define Desc_Get  	"Retorna o cadastro de Grupo de Produto informado de acordo com os parametros passados" 

user function R_GrpPro()

return

WSRESTFUL rGrpPro DESCRIPTION Desc_Rest

	WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING    

	WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/rGrpPro || /rGrpPro/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE nPag HEADERPARAM TENANTID WSSERVICE rGrpPro
	Local aArea		:= GetArea()
	Local cAliasTMP
	Local cRet		
	Local cSetResp
	Local _cEmpresa := "01"
	Local _cFilial	:= "01"
	Local aTabs		:= {"SX5"}
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

	cRet		:= ""
	aArea     	:= GetArea()
	cAliasTMP 	:= GetNextAlias()
	nReg		:= 0

	//*****************************************************************
	// Cofigura empresa/filial
	//*****************************************************************
	RpcSetEnv( _cEmpresa,_cFilial,,, "GET", "METHOD", aTabs,,,,)
	cEmpant := _cEmpresa
	cFilant := _cFilial
	cNumEmp	:= _cEmpresa + _cFilial 

	//Verifica se há conexão em aberto, caso haja feche.
	IF Select(cAliasTmp)>0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf


	//Select de cadastro 
	cQuery := "	SELECT (ROW_NUMBER() OVER (ORDER BY A.R_E_C_N_O_)) AS CONT,  "
	cQuery += " A.X5_CHAVE AS CHAVE, A.X5_DESCRI AS DESCRI "
	cQuery += " FROM   " + RetSqlName("SX5") + " A  "
	cQuery += " WHERE D_E_L_E_T_ <>'*' AND X5_TABELA = 'Z2' " 


	cQuery := ChangeQuery(cQuery)

	//Verifica se há conexão em aberto, caso haja feche.

	IF Select(cAliasTmp)>0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),(cAliasTmp),.T.,.T.)
	dbSelectArea(cAliasTmp)
	(cAliasTmp)->( DbGoTop() )

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


	If (cAliasTmp)->( Eof() )

		cSetResp := '{    "JSON": [],    "PaginalAtual": 1,    "TotalDePaginas": 1}'

	Else

		(cAliasTMP)->( DbGoTop() )  
		nX		:= 1
		//Inicio do retorno em JSON
		cSetResp  := '{ "JSON":[ ' 
		While (cAliasTMP)->( !Eof() )
			If nX > 1
				cSetResp  +=' , '
			EndIf
			cSetResp  += '{'
			cSetResp  += '"CODIGO":"'				+ (cAliasTMP)->CHAVE					
			cSetResp  += '","DESCRICAO":"'			+ (cAliasTMP)->DESCRI											
			cSetResp  += '"}'

			(cAliasTmp)->(dbSkip())
				nX:= nX+1
		EndDo
		cSetResp  += ']'	
		//cSetResp  += ',"PaginalAtual":'				+ cValToChar(Self:nPag)			
		cSetResp  += ',"TotalDePaginas":'			+ cValToChar(nRegFinal)
		cSetResp  += '}'

	EndIf

	//verifica se houve dados 
	If Len(cSetResp) == Len('{ "JSON":[ ]}')
		cSetResp := '{ "Retorno":"Nao Existe Dados Nessa Pagina"} '
	EndIF

	//Envia o JSON Gerado para a aplicação
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)
