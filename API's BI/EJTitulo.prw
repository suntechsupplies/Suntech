#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"

/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Douglas.Silva Feat Carlos Eduardo Saturnino and Antonio Ricardo de Araujo           *  
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
#Define _Function	"Titulos"
#Define _DescFun	"RTitulo"
#Define Desc_Rest 	"Serviço REST para Disponibilizar  dados de Titulos" 
#Define Desc_Get  	"Retorna o cadastro de Titulos informado de acordo com os parametros passados" 
#Define Desc_Post	"Cria o cadastro de Titulos informado de acordo com data de atualização do cadastro"


User function EJ_Titulo()

Return

WSRESTFUL EJTitulo DESCRIPTION Desc_Rest

	WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING    
	
	WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/EJTitulo || /EJTitulo/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE nPag HEADERPARAM TENANTID WSSERVICE EJTitulo
	
	Local aArea		:= GetArea()
	Local cAliasTMP	:= GetNextAlias()
	Local cSetResp	:= ''
	Local nPag		:= Self:nPag
	Local lRet		:= .T.
	Local nPagFim
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
 	IF Select(cAliasTmp)>0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf

	//Select de cadastro 
	BeginSQL Alias cAliasTmp

		SELECT 		((ROW_NUMBER() OVER (ORDER BY T.R_E_C_N_O_)) /100)+1	AS PAG,
					T.E1_FILIAL         			            	        AS CodFilial,
					T.E1_CLIENTE+T.E1_LOJA         			            	AS CodigoCliente,
					T.E1_PREFIXO											AS Prefixo,	
					T.E1_NUM					        				    AS NroDocumento,
					T.E1_PARCELA                                			AS NroParcela,
					T.E1_TIPO                                   			AS CodigoTipoDocumento,
					T.E1_EMISSAO                                			AS DataEmissao,
					T.E1_VENCREA                                			AS DataVencimento,
					T.E1_NUMBCO                                  			AS NroBoleto,
					T.E1_VALOR                                  			AS ValorOriginal,
					T.E1_SALDO                                  			AS SaldoTitulo,
					NULL                                        			AS NroNotaFiscal,
					E1_PORCJUR                                  			AS TaxaJuros,
					0	                                        			AS ValorPago,
					T.E1_NUMNOTA + T.E1_SERIE                      			AS CodigoEmpresaEsp,
					CASE WHEN COALESCE((T.E1_BAIXA), '        ') <> '        ' 
						THEN T.E1_BAIXA 
						ELSE NULL 
					END  													AS DataPago,
					T.E1_VEND1                                  			AS CodigoVendedorEsp
		FROM 		%Table:SE1% T
		//WHERE		COALESCE((T.E1_BAIXA), '        ') = '        '
		WHERE 		T.%NotDel%
		AND         T.E1_ZSTATUS <> '9' 
		ORDER BY	T.R_E_C_N_O_

	EndSql

	dbSelectArea(cAliasTmp)
	(cAliasTmp)->( DbGoTop() )

	While (cAliasTmp)->( !Eof() )
		nPagFim := (cAliasTmp)->PAG
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->( DbGoTop() )

	If (cAliasTmp)->( Eof() )

		cSetResp := '{"TE_TITULO": [ "Retorno":"Nao Existe Itens Nessa Pagina" ] } '
		lRet	 := .F.

	Else

		(cAliasTMP)->( DbGoTop() )  
		nX		:= 1
		
		//Inicio do retorno em JSON
		cSetResp  := '{ "TE_TITULO":[ ' 
		
		While (cAliasTMP)->( !Eof() )
			
			If (cAliasTMP)->PAG == nPag
			
				If nX > 1
					cSetResp  +=' , '
				EndIf
				cSetResp  += '{'
				cSetResp  += ' "CodFilial":"'		    + ALLTRIM((cAliasTMP)->CodFilial)
				cSetResp  += '","CodigoCliente":"'		+ ALLTRIM((cAliasTMP)->CodigoCliente)
				cSetResp  += '","Prefixo":"'		    + (cAliasTMP)->Prefixo
				cSetResp  += '","NroDocumento":"'		+ (cAliasTMP)->NroDocumento		
				cSetResp  += '","NroParcela":"'			+ (cAliasTMP)->NroParcela
				cSetResp  += '","CodigoTipoDocumento":"'+ ALLTRIM((cAliasTMP)->CodigoTipoDocumento)		
				cSetResp  += '","DataEmissao":"'		+ ALLTRIM((cAliasTMP)->DataEmissao)		
				cSetResp  += '","DataVencimento":"'		+ ALLTRIM((cAliasTMP)->DataVencimento)		
				cSetResp  += '","ValorOriginal":'		+ ALLTRIM(cValToChar((cAliasTMP)->ValorOriginal))		
				cSetResp  += ',"SaldoTitulo":'			+ ALLTRIM(cValToChar((cAliasTMP)->SaldoTitulo))		
				cSetResp  += ',"NroNotaFiscal":"'		+ ALLTRIM((cAliasTMP)->NroNotaFiscal)		
				cSetResp  += '","TaxaJuros":'			+ ALLTRIM(cValToChar((cAliasTMP)->TaxaJuros))
				cSetResp  += ',"NroBoleto":'			+ ALLTRIM(cValToChar((cAliasTMP)->NroBoleto))
				cSetResp  += ',"ValorPago":'			+ ALLTRIM(cValToChar((cAliasTMP)->ValorPago))		
				cSetResp  += ',"CodigoEmpresaEsp":"'	+ ALLTRIM((cAliasTMP)->CodigoEmpresaEsp)		
				cSetResp  += '","DataPago":"'			+ ALLTRIM((cAliasTMP)->DataPago)		
				cSetResp  += '","CodigoVendedorEsp":"'	+ ALLTRIM((cAliasTMP)->CodigoVendedorEsp)		
				cSetResp  += '"}'
				(cAliasTmp)->(dbSkip())
				nX++
			Else
				(cAliasTmp)->(dbSkip())
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
	(cAliasTMP)->(DbCloseArea())

	//Envia o JSON Gerado para a aplicação
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)
