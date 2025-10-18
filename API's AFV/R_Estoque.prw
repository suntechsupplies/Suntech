#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"

/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* Carlos Eduardo Saturnino                                                                    *  
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

#Define _Function	"Estoque"
#Define _DescFun  	"Cadastro de Produtos em Estoque"
#Define Desc_Rest 	"Serviço REST para Disponibilizar dados de Produtos em Estoque"
#Define Desc_Get  	"Retorna o cadastro de Cadastro de Municipios informado de acordo com os parametros passados" 

user function R_Estoque()
	  
return

WSRESTFUL rEstoque DESCRIPTION Desc_Rest

	WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING    
	
	WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/rEstoque || /rEstoque/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE nPag HEADERPARAM TENANTID WSSERVICE rEstoque
	Local aArea		:= GetArea()
	Local cAliasTMP
	Local cRet		
	Local cSetResp
	Local nX
	Local nPagFim	
	Local nPag		:= Self:nPag 

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

	//------------------------------------------------------------------------------------------
	//  Carlos Eduardo Saturnino em 23/09/2021
	//------------------------------------------------------------------------------------------
	/*
		SELECT		((ROW_NUMBER() OVER (ORDER BY A.R_E_C_N_O_)) /1000)+1	AS PAG  
					, B2_COD												AS CodigoProduto
					, ('01' + B2_FILIAL) 									AS CodigoUnidFat
					, (	B2_QATU - B2_RESERVA - B2_QEMP - B2_QACLASS -
					 	B2_QEMPSA - B2_QEMPPRJ - B2_QEMPPRE	) 				AS QtdeEstoque
		FROM		%Table:SB2% A
		INNER JOIN 	%Table:SB1% B
		ON 			B1_COD = B2_COD
		WHERE		B1_MSBLQL = '2' 
		AND			B1_TIPO IN ('PA','ME')
		AND			A.%NotDel%
		AND			B.%NotDel%
		ORDER BY 	A.R_E_C_N_O_
	*/

	//Select de cadastro 
	BeginSQL Alias cAliasTMP
	
		SELECT		((ROW_NUMBER() OVER (ORDER BY A.R_E_C_N_O_)) /1000)+1	AS PAG  
					, B2_COD												AS CodigoProduto
					, ('01' + B2_FILIAL) 									AS CodigoUnidFat
					, (	B2_QATU - B2_RESERVA - B2_QEMP - B2_QACLASS -
					 	B2_QEMPSA - B2_QEMPPRJ - B2_QEMPPRE	) 				AS QtdeEstoque
		FROM		%Table:SB2% A
		INNER JOIN 	%Table:SB1% B
		ON 			B1_COD = B2_COD
		WHERE		B1_MSBLQL = '2' 
		AND			B2_LOCAL  = '02'
		AND			B2_FILIAL = '02'
		AND			B1_TIPO IN ('PA','ME')
		AND			A.%NotDel%
		AND			B.%NotDel%
		ORDER BY 	A.R_E_C_N_O_
		
	EndSql

	// Guarda a ultima pagina
	dbSelectArea(cAliasTmp)
	(cAliasTmp)->( DbGoTop() )
	While (cAliasTmp)->( !Eof() )
		nPagFim		:= (cAliasTmp)->PAG
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->( DbGoTop() )

	If (cAliasTmp)->( Eof() )
		cSetResp := '{    "TE_PRODUTOUNIDFAT":[ "Retorno":"Nao Existe Itens Nessa Pagina"] }'
	Else
		(cAliasTmp)->( DbGoTop() )  
		nX	:= 1
		cSetResp  := '{ "TE_PRODUTOUNIDFAT":[ '
		While (cAliasTmp)->( !Eof() ) 
			If nPag == (cAliasTmp)->PAG 			
				If nX > 1
					cSetResp  +=' , '
				EndIf				
				cSetResp  += '{'
				cSetResp  += '"CODIGOPRODUTO":"'		+ TRIM((cAliasTmp)->CodigoProduto)
				cSetResp  += '","CODIGOUNIDFAT":"'		+ TRIM((cAliasTmp)->CodigoUnidFat)
				cSetResp  += '","QTDEESTOQUE":'			+ TRIM(cValToChar((cAliasTmp)->QtdeEstoque))
				cSetResp  += '}'

				(cAliasTmp)->(dbSkip())
				nX:= nX+1
			Else
				(cAliasTmp)->(dbSkip())
			Endif
		EndDo
		cSetResp  += ']'
		cSetResp  += ',"PaginalAtual":'				+ cValToChar(Self:nPag)			
		cSetResp  += ',"TotalDePaginas":'			+ cValToChar(nPagFim)
		cSetResp  += '}'

	EndIf
	//Fecha a tabela
	(cAliasTmp)->(DbCloseArea())

	//Envia o JSON Gerado para a aplicação
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)
