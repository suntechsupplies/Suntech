#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"
/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Douglas.Silva Feat Carlos Eduardo Saturnino                                         *  
* Processa as informações e retorna o json                                                    *
* @since 	05/08/2019                                                                        *
* @version undefined                                                                          *
* @param oSelf, object, Objeto contendo dados da requisição efetuada pelo cliente, tais como: *
*    - Parâmetros querystring (parâmetros informado via URL)                                  *
*    - Objeto JSON caso o requisição seja efetuada via Request Post                           *
*    - Header da requisição                                                                   *
*    - entre outras ...                                                                       *
* @type Method                                                                                *
**********************************************************************************************/
#Define _Function	"Tabela de Preco Itens"
#Define _DescFun	"RTabPreItens"
#Define Desc_Rest 	"Serviço REST para Disponibilizar / Inserir dados de regiao" 
#Define Desc_Get  	"Retorna o cadastro de Tabela de Preco Itens informado de acordo com os parametros passados" 

user function R_TbPrIt()

return

WSRESTFUL rTabPreItens DESCRIPTION Desc_Rest

	WSDATA 	nPag 	As Integer
    WSDATA TENANTID AS STRING

	WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/RTabPreItens || /RTabPreItens/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE nPag HEADERPARAM TENANTID WSSERVICE RTabPreItens
	Local aArea		:= GetArea()
	Local cAliasTMP	:= GetNextAlias()
	Local nPag		:= Self:nPag
	Local nPagFim
	Local cSetResp	:= ''
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

	//Verifica se há conexão em aberto, caso haja feche.
	IF Select(cAliasTmp) > 0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf

	//Select de cadastro 
	BeginSQL Alias cAliasTmp
		
		SELECT 		( (DENSE_RANK() OVER (ORDER BY A.DA0_CODTAB))/2) + 1 AS PAG 
					, A.DA0_FILIAL   AS FILIAL
					, A.DA0_CODTAB   AS CODIGO
					, B.DA1_CODPRO   AS CODIGOPRODUTO
					, B.DA1_PRCVEN   AS PRECO
					, B.DA1_PRCMAX   AS PRECOMAXIMO
					, A.DA0_DATDE    AS DTAINICIAL
					, A.DA0_DATATE   AS DTAFINAL
		FROM   		%Table:DA0% A 
		INNER JOIN 	%Table:DA1% B
		ON 			A.DA0_CODTAB 	= B.DA1_CODTAB 
		AND 		B.DA1_FILIAL 	= A.DA0_FILIAL		
		INNER JOIN	%Table:SB1% C
		ON 			C.B1_COD 		= B.DA1_CODPRO 	
		WHERE  		A.%NotDel%
		AND			B.%NotDel%
		AND			C.%NotDel%
		AND    		A.DA0_ATIVO  	= 1
		AND			C.B1_TIPO IN ('PA','ME')
		AND			C.B1_MSBLQL = '2'
		ORDER BY 	A.DA0_CODTAB, B.DA1_CODPRO 
	
	EndSql
	
	dbSelectArea(cAliasTmp)
	(cAliasTmp)->( DbGoTop() )

	While (cAliasTmp)->( !Eof() )
		nPagFim := (cAliasTmp)->PAG
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->( DbGoTop() )
	
	If (cAliasTmp)->( Eof() )

		cSetResp := '{ "TE_TABELAPRECO":"Nao Existe Dados Nessa Pagina"} '

	Else
		
		(cAliasTMP)->( DbGoTop() )  
		nX		:= 1
		
		//Inicio do retorno em JSON
		cSetResp  := '{ "TE_TABELAPRECO":[ ' 
		
		While (cAliasTMP)->( !Eof() )
			
			If (cAliasTMP)->PAG == nPag 
				If nX > 1
					cSetResp  +=' , '
				EndIf

				cSetResp  += '{'
				cSetResp  += '"FILIAL":"'			+ TRIM((cAliasTMP)->FILIAL)					
				cSetResp  += '","CODIGO":"'			+ TRIM((cAliasTMP)->CODIGO)		
				cSetResp  += '","CODIGOPRODUTO":"'	+ TRIM((cAliasTMP)->CODIGOPRODUTO)		
				cSetResp  += '","PRECO":'			+ TRIM(STR((cAliasTMP)->PRECO))		
				cSetResp  += ',"DTAINICIAL":"'		+ TRIM((cAliasTMP)->DTAINICIAL)		
				cSetResp  += '","DTAFINAL":"'		+ TRIM((cAliasTMP)->DTAFINAL)		
				cSetResp  += '"}'

				(cAliasTmp)->(dbSkip())
				nX++
			Else
				(cAliasTmp)->(dbSkip())
				LOOP
			Endif
		EndDo
		
		cSetResp  += ']'	
		cSetResp  += ',"PaginalAtual":'				+ cValToChar(Self:nPag)			
		cSetResp  += ',"TotalDePaginas":'			+ cValToChar(nPagFim)
		cSetResp  += '}'

	EndIf
	
	//Fecha a tabela
	(cAliasTMP)->(DbCloseArea())

	//Envia o JSON Gerado para a aplicação
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)
