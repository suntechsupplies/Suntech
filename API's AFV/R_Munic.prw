#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"

/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Douglas.Silva                                                                       *  
* Processa as informações e retorna o json                                                    *
* @since 	04/08/2019                                                                        *
* @version undefined                                                                          *
* @param oSelf, object, Objeto contendo dados da requisição efetuada pelo cliente, tais como: *
*    - Parâmetros querystring (parâmetros informado via URL)                                  *
*    - Objeto JSON caso o requisição seja efetuada via Request Post                           *
*    - Header da requisição                                                                   *
*    - entre outras ...                                                                       *
* @type Method                                                                                *
**********************************************************************************************/

#Define _Function	"Munic"
#Define _DescFun  	"Cadastro de Municipios"
#Define Desc_Rest 	"Serviço REST para Disponibilizar dados de Cadastro de Municipios"
#Define Desc_Get  	"Retorna o cadastro de Cadastro de Municipios informado de acordo com os parametros passados" 

user function R_Munic()
	Aviso("DEBUG","Debug em andamento",{"OK"},3)  
return

WSRESTFUL rMunic DESCRIPTION Desc_Rest

	WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING    
	
	WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/rMunic || /rMunic/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE nPag HEADERPARAM TENANTID WSSERVICE rMunic
	Local aArea		:= GetArea()
	Local cAliasTMP
	Local cRet		
	Local cSetResp
	Local nX
	Local nPagFim	
	Local nPag		:= Self:nPag 
	Local nRegFinal

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

	//Verifica se há conexão em aberto, caso haja feche.
	IF Select(cAliasTmp)>0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf


	//Select de cadastro
	BeginSql Alias cAliasTmp 
		
		SELECT (ROW_NUMBER() OVER (ORDER BY CC2.R_E_C_N_O_)) 				AS CONT
				,((ROW_NUMBER() OVER (ORDER BY CC2.R_E_C_N_O_)) /1000)+1	AS PAG
				,CC2_CODMUN    												AS CODIGO
				,CC2_MUN 													AS NOME
				,CC2_EST                 									AS ESTADO
		FROM   %Table:CC2% CC2
		WHERE 	CC2.%NotDel%
		
	EndSql

	dbSelectArea(cAliasTmp)
	(cAliasTmp)->( DbGoTop() )

	While (cAliasTmp)->( !Eof() )
		nRegFinal 	:= (cAliasTmp)->CONT
		nPagFim		:= (cAliasTmp)->PAG
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->( DbGoTop() )

	If (cAliasTmp)->( Eof() )

		cSetResp := '{    "T_MUNICIPIO": [],    "PaginalAtual": 1,    "TotalDePaginas": 1}'

	Else
		(cAliasTmp)->( DbGoTop() )  
		nX	:= 1
		cSetResp  := '{ "T_MUNICIPIO":[ '
		If Empty(nPag) 
			While (cAliasTmp)->( !Eof() )			
					If nX > 1
						cSetResp  +=' , '
					EndIf				
					cSetResp  += '{'
					cSetResp  += '"REGISTRO":'		+ TRIM(cValToChar((cAliasTmp)->CONT))
					cSetResp  += ',"CODIGO":"'		+ TRIM((cAliasTmp)->ESTADO) + TRIM((cAliasTmp)->CODIGO)
					cSetResp  += '","ESTADO":"'		+ TRIM((cAliasTmp)->ESTADO)
					cSetResp  += '","NOME":"'		+ TRIM((cAliasTmp)->NOME)
					cSetResp  += '"}'
	
					(cAliasTmp)->(dbSkip())
					nX:= nX+1
			EndDo
		Else
			While (cAliasTmp)->( !Eof() ) 
				If nPag == (cAliasTmp)->PAG 			
					If nX > 1
						cSetResp  +=' , '
					EndIf				
					cSetResp  += '{'
					cSetResp  += '"REGISTRO":'		+ TRIM(cValToChar((cAliasTmp)->CONT))
					cSetResp  += ',"CODIGO":"'		+ TRIM((cAliasTmp)->ESTADO) + TRIM((cAliasTmp)->CODIGO)
					cSetResp  += '","ESTADO":"'		+ TRIM((cAliasTmp)->ESTADO)
					cSetResp  += '","NOME":"'		+ TRIM((cAliasTmp)->NOME)
					cSetResp  += '"}'
	
					(cAliasTmp)->(dbSkip())
					nX:= nX+1
				Else
					(cAliasTmp)->(dbSkip())
				Endif
			EndDo
		Endif		
		cSetResp  += ']'
		cSetResp  += ',"PaginalAtual":'				+ cValToChar(Self:nPag)			
		cSetResp  += ',"TotalDePaginas":'			+ cValToChar(nPagFim)
		cSetResp  += '}'

	EndIf
	//Fecha a tabela
	(cAliasTmp)->(DbCloseArea())

	//verifica se houve dados 
	If Len(cSetResp) == Len('{ "T_MUNICIPIO":[ ]}')
		cSetResp := '{ "Retorno":"Nao Existe Dados Nessa Pagina"} '
	EndIF

	//Envia o JSON Gerado para a aplicação
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)
