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
#Define _Function	"Cliente X Vendedor"
#Define _DescFun  	"Cadastro de Clientes X Vendedores"
#Define Desc_Rest 	"Serviço REST para Disponibilizar dados de Cadastro de Clientes X Vendedores"
#Define Desc_Get  	"Retorna o cadastro de Cadastro de Municipios informado de acordo com os parametros passados" 

user function R_CliXVend()

return

WSRESTFUL rClixVend DESCRIPTION Desc_Rest

	WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING

	WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/rCliXVend || /rCliXVend/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE nPag HEADERPARAM TENANTID WSSERVICE rCliXVend
	
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

		SELECT		( (DENSE_RANK() OVER (ORDER BY A.A1_COD || A.A1_LOJA ))/10000) + 1	AS PAG
					,A1_COD + A1_LOJA													AS CodigoCliente
					,A1_VEND															AS CodigoVendedorEsp
		FROM		%Table:SA1% A
		RIGHT JOIN	%Table:SA3% B
		ON			A1_VEND 	= A3_COD
		WHERE		A1_VEND <> ''
		AND			A.%NotDel%
		AND			B.%NotDel%
		
		UNION ALL	
		
		SELECT		( (DENSE_RANK() OVER (ORDER BY C.A1_COD || C.A1_LOJA))/10000) + 1		AS PAG
					,A1_COD + A1_LOJA													AS CodigoCliente
					,A1_ZZVEND2															AS CodigoVendedorEsp
		FROM		%Table:SA1% C
		RIGHT JOIN	%Table:SA3% D
		ON			A1_ZZVEND2 	= A3_COD
		WHERE		A1_ZZVEND2  <> ''
		AND			C.%NotDel%
		AND			D.%NotDel% 	
		ORDER BY	A1_COD || A1_LOJA
	
	EndSql

	dbSelectArea(cAliasTmp)
	(cAliasTmp)->( DbGoTop() )

	While (cAliasTmp)->( !Eof() )
		nPagFim		:= (cAliasTmp)->PAG
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->( DbGoTop() )

	If (cAliasTMP)->( Eof() )

		cSetResp := '{"TR_CLIENTEVENDEDOR": [ "Retorno":"Nao Existe Itens Nessa Pagina"] } '
		lRet 	 := .F. 

	Else
		
		(cAliasTMP)->( DbGoTop() )  
		nX		:= 1

		//Inicio do retorno em JSON
		cSetResp  := '{ "TR_CLIENTEVENDEDOR":[ ' 
		
		While (cAliasTMP)->( !Eof() )
			IF (cAliasTMP)->PAG == nPag
				If nX > 1
					cSetResp  +=' , '
				EndIf
		
				cSetResp  += '{'
				cSetResp  += '"CodigoCliente":"'		+ TRIM((cAliasTMP)->CodigoCliente)					
				cSetResp  += '","CodigoVendedorEsp":"'	+ TRIM((cAliasTMP)->CodigoVendedorEsp)																				
				cSetResp  += '"}'
				nX++
				(cAliasTMP)->(dbSkip())
				LOOP	
			Else
				(cAliasTMP)->(dbSkip())
				LOOP	
			Endif

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
