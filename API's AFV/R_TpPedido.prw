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
#Define _Function	"Tipo de Pedido"
#Define _DescFun	"RTPNota"
#Define Desc_Rest 	"Serviço REST para Disponibilizar dados de Tipo de Pedido" 
#Define Desc_Get  	"Retorna o cadastro de Tipo de Nota informado de acordo com os parametros passados" 
#Define Desc_Post	"Cria o cadastro de Tipo de Nota informado de acordo com data de atualização do cadastro"


user function R_TpPedido()

return

WSRESTFUL RTpPedido DESCRIPTION Desc_Rest

	WSDATA 	nPag		As Integer
    WSDATA TENANTID AS STRING
        
	WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/RTpPedido || /RTpPedido/{}"

END WSRESTFUL

WSMETHOD GET WSRECEIVE nPag HEADERPARAM TENANTID WSSERVICE RTpPedido

	Local aArea		:= GetArea()
	Local cAliasTMP	:= GetNextAlias()
	Local cSetResp	:= ''
	Local nPag		:= Self:nPag
	Local lRet		:= .T.
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


	//Verifica se há conexão em aberto, caso haja feche.
	IF Select(cAliasTmp)>0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf

	//Select de cadastro 
	BeginSql Alias cAliasTmp

		SELECT		((ROW_NUMBER() OVER (ORDER BY X5.R_E_C_N_O_)) /1000)+1	AS PAG
		  			, X5.X5_CHAVE											AS Codigo
					, X5.X5_DESCRI											AS Descricao
		FROM		SX5010 X5
		WHERE		X5_TABELA = 'Z4'
		AND			X5.%NotDel%

	EndSql

	dbSelectArea(cAliasTmp)
	(cAliasTmp)->( DbGoTop() )

	While (cAliasTmp)->( !Eof() )
		nPagFim := (cAliasTmp)->PAG
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->( DbGoTop() )

	If (cAliasTmp)->( Eof() )

		cSetResp := '{"T_TIPOPEDIDO": [ "Nao Existe Dados Nessa Pagina" ] }'
		lRet	 := .F. 

	Else

		(cAliasTmp)->( DbGoTop() )  
		nX		:= 1

		//Inicio do retorno em JSON
		cSetResp  := '{ "T_TIPOPEDIDO":[ ' 

		While (cAliasTmp)->( !Eof() )

			IF (cAliasTmp)->PAG == nPag

				If nX > 1
					cSetResp  +=' , '
				EndIf

				cSetResp  += '{'
				cSetResp  += '"Codigo":"'			 	+ RTRIM(FwNoAccent((cAliasTMP)->Codigo))					
				cSetResp  += '","Descricao":"'		 	+ RTRIM(FwNoAccent((cAliasTMP)->Descricao))																				
				cSetResp  += '","FlagUso":' 			+ cValToChar(1)
				cSetResp  += '}'

				(cAliasTmp)->(dbSkip())
				nX++
			Else
				(cAliasTmp)->(dbSkip())
				LOOP	
			EndIf
		EndDo
	EndIf

	If lRet
		cSetResp  += ']'	
		cSetResp  += ',"PaginalAtual":'				+ STR(nPag)			
		cSetResp  += ',"TotalDePaginas":'			+ STR(nPagFim)
		cSetResp  += '}'
	Endif

	//Fecha a tabela
	(cAliasTMP)->(DbCloseArea())

	//Envia o JSON Gerado para a aplicação
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)
