#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"

/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Douglas.Silva                                                                       *  
* Processa as informações e retorna o json                                                    *
* @since 	28/07/2019                                                                        *
* @version undefined                                                                          *
* @param oSelf, object, Objeto contendo dados da requisição efetuada pelo cliente, tais como: *
*    - Parâmetros querystring (parâmetros informado via URL)                                  *
*    - Objeto JSON caso o requisição seja efetuada via Request Post                           *
*    - Header da requisição                                                                   *
*    - entre outras ...                                                                       *
* @type Method                                                                                *
***********************************************************************************************
*/
#Define _Function "rOrig"
#Define _DescFun  "Unidades de Faturamento"
#Define Desc_Rest "Serviço REST para Disponibilizar dados de Unidades de Faturamento"
#Define Desc_Get  "Retorna o cadastro de Unidades de Faturamento de acordo com os parametros passados" 

user function R_Origem()

return

WSRESTFUL rOrig DESCRIPTION Desc_Rest

	WSDATA cDataDe 	As String
	WSDATA cDataAte	As String
	WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING    

WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/rOrig || /rOrig/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE cDataDe, cDataAte,  nPag HEADERPARAM TENANTID WSSERVICE rOrig
	Local aArea		:= GetArea()
	Local cAliasTMP
	Local aArea
	Local cRet		
	Local cSetResp
	Local nX
	LOCAL cDtaDe
	Local cDtaAte
	LOCAL nPagIni
	Local nPagFim
	Local nRegFinal
	Local _aAux			:= FWEmpLoad(.F.)
	Local nReg			:= Len(_aAux)

	cDtaDe 	:= Self:cDataDe
	cDtaAte	:= Self:cDataAte

	cSetResp:= ""

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
	cAliasTmp 	:= GetNextAlias()
	nReg		:= 0

	// define o tipo de retorno do método
	::SetContentType("application/json")

	cRet		:= ""
	aArea     	:= GetArea()
	cAliasTMP 	:= GetNextAlias()

	//--------------------------------------------------------------------------------------------------
	// Bloco comentado por Carlos Eduardo Saturnino em 16/12/2019 
	//----------------------------------------------------------------------------> Inicio do comentario
	/* 
	//Select de cadastro 
	cQuery := "	SELECT (ROW_NUMBER() OVER (ORDER BY R_E_C_N_O_)) AS CONT,  "
	cQuery += " A.X5_CHAVE  	  AS CODIGO,"
	cQuery += " A.X5_DESCRI AS DESCRICAO"
	cQuery += " FROM   " + RetSqlName("SX5") + " A " 
	cQuery += " WHERE  A.X5_TABELA = 'A2'"
	cQuery += " AND A.D_E_L_E_T_ <> '*'"

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
	cSetResp  += '"CODIGO":"'				+ ALLTRIM((cAliasTMP)->CODIGO)					
	cSetResp  += '","DESCRICAO":"'			+ ALLTRIM((cAliasTMP)->DESCRICAO)											
	cSetResp  += '"}'

	(cAliasTmp)->(dbSkip())
	nX:= nX+1
	EndDo
	cSetResp  += ']'	
	//cSetResp  += ',"PaginalAtual":'				+ cValToChar(Self:nPag)			
	cSetResp  += ',"TotalDePaginas":'				+ cValToChar(nRegFinal)
	cSetResp  += '}'

	EndIf
	//Fecha a tabela
	(cAliasTMP)->(DbCloseArea())
	*/
	// Fim do Comentario <------------------------------------------------------------------------------

	//-------------------------------------------------------------------------------------------------
	// Incluido por Carlos Eduardo Saturnino em 16/12/2019
	//----------------------------------------------------------------------------> Inicio da alteracao

	//Verifica se há conexão em aberto, caso haja feche.
	IF Select(cAliasTmp)>0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf


	//Select de cadastro 
	BeginSql Alias cAliasTmp
	
	SELECT (ROW_NUMBER() OVER (ORDER BY R_E_C_N_O_)) 	AS CONT
			,A.X5_CHAVE  	  							AS CODIGO
			,A.X5_DESCRI 								AS DESCRICAO
	FROM   %Table:SX5%  A  
	WHERE  A.X5_TABELA = 'A2'
	AND 	A.%NotDel%

	EndSQL


	If nReg <= 1000 
		nRegFinal := 1
	Else
		nRegFinal := Int(nReg/1000)+1 
	EndIf 



	If Len(_aAux) == 0
		cSetResp := '{    "JSON": [],    "PaginalAtual": 1,    "TotalDePaginas": 1}'
	Else
		nX		:= 1

		//Inicio do retorno em JSON
		cSetResp  := '{ "JSON":[ ' 
		For nX := 1 to Len(_aAux)			
			If nX > 1
				cSetResp  +=' , '
			EndIf
			cSetResp  += '{'
			cSetResp  += '"CODIGO":"'				+ _aAux[nX][1] + _aAux[nX][3]				
			cSetResp  += '","DESCRICAO":"'			+ Alltrim(_aAux[nX][2]) + "-" + Alltrim(_aAux[nX][4])											
			cSetResp  += '"}'

		Next nX

		cSetResp  += ']'	
		//cSetResp  += ',"PaginalAtual":'				+ cValToChar(Self:nPag)			
		cSetResp  += ',"TotalDePaginas":'			+ cValToChar(nRegFinal)
		cSetResp  += '}'

	EndIf

	//Fim da alteracao <-------------------------------------------------------------------------------	

	//verifica se houve dados 
	If Len(cSetResp) == Len('{ "JSON":[ ]}')
		cSetResp := '{ "Retorno":"Nao Existe Dados Nessa Pagina"} '
	EndIF

	//Envia o JSON Gerado para a aplicação
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)
