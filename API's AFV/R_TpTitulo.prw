#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"

/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Carlos Eduardo Saturnino                                                            *  
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
#Define _Function	"Tipo de Títulos"
#Define _DescFun  	"Cadastro de Tipo de Títulos"
#Define Desc_Rest 	"Serviço REST para Disponibilizar dados de Cadastro de Tipo de Títulos"
#Define Desc_Get  	"Retorna o cadastro de Cadastro de Municipios informado de acordo com os parametros passados" 

user function R_TpTitulo()

return

WSRESTFUL rTpTitulo DESCRIPTION Desc_Rest

    WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING
    
    WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/rTpTitulo || /rTpTitulo/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE nPag HEADERPARAM TENANTID WSSERVICE rTpTitulo
	Local aArea		:= GetArea()
	Local cAliasTMP	:= GetNextAlias()
	Local nPag		:= Self:nPag
	Local lRet		:= .T.
	Local cSetResp
	Local nX
	Local nPagFim	

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


	IF Select(cAliasTmp)>0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf

	//Select de cadastro 
	BeginSQL Alias cAliasTmp

		SELECT 		((ROW_NUMBER() OVER (ORDER BY X.R_E_C_N_O_)) /1000)+1	AS PAG
					,X.X5_CHAVE												AS Codigo
					,X.X5_DESCRI											AS Descricao
		FROM		%Table:SX5% X
		WHERE		X5_TABELA 	= '05'
		AND			X.%NotDel%

	EndSql

	dbSelectArea(cAliasTmp)
	(cAliasTmp)->( DbGoTop() )

	While (cAliasTmp)->( !Eof() )
		nPagFim		:= (cAliasTmp)->PAG
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->( DbGoTop() )

	If (cAliasTMP)->( Eof() )

		cSetResp := '{"TE_TIPODOCUMENTO": [ "Retorno":"Nao Existe Itens Nessa Pagina"] } '
		lRet 	 := .F. 

	Else
		(cAliasTMP)->( DbGoTop() )  
		nX		:= 1

		//Inicio do retorno em JSON
		cSetResp  := '{ "TE_TIPODOCUMENTO":[ ' 
		While (cAliasTMP)->( !Eof() )

			IF (cAliasTMP)->PAG == nPag
				If nX > 1
					cSetResp  +=' , '
				EndIf
				cSetResp  += '{'
				cSetResp  += '"CODIGO":"'				+ TRIM((cAliasTMP)->Codigo)					
				cSetResp  += '","DESCRICAO":"'			+ TRIM((cAliasTMP)->Descricao)																				
				cSetResp  += '"}'
				(cAliasTMP)->(dbSkip())
				nX++
			Else
				(cAliasTMP)->(dbSkip())
				LOOP	
			EndIf
		EndDo

		If lRet
			cSetResp  += ']'	
			cSetResp  += ',"PaginalAtual":'				+ STR(Self:nPag)			
			cSetResp  += ',"TotalDePaginas":'			+ STR(nPagFim)
			cSetResp  += '}'
		Endif


	EndIf
	//Fecha a tabela
	(cAliasTmp)->(DbCloseArea())

	//Envia o JSON Gerado para a aplicação
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)
