#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"

/**********************************************************************************************
* {Protheus.doc}  Produtos                                                                    *
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
#Define _Function 	"Produtos"
#Define _DescFun  	"Cadastro de Produtos"
#Define Desc_Rest	"Serviço REST para Disponibilizar dados de Cadastro de Produtos"
#Define Desc_Get  	"Retorna o Produto informado de acordo com data de atualização do cadastro" 
#Define Desc_Pos	"Cria o Cadastro de Produtos de acordo com as informacoes passadas"


user function r_ProGet()

return

WSRESTFUL rProGet DESCRIPTION Desc_Rest

    WSDATA TENANTID AS STRING
	WSDATA nPag		As Integer
	
	WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/rProGet || /rProGet/{}"

END WSRESTFUL

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

WSMETHOD GET WSRECEIVE nPag HEADERPARAM TENANTID WSSERVICE rProGet

	Local aArea			:= GetArea()
	Local cAliasTMP 	:= GetNextAlias()
	Local lRet			:= .T.
	Local nPag			:= Self:nPag
	Local cSetResp
	Local nPagFim

	//Verifica se há conexão em aberto, caso haja feche.
	IF Select(cAliasTMP)>0
		dbSelectArea(cAliasTMP)
		(cAliasTMP)->(dbCloseArea())
	EndIf

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

	//Select de cadastro de Produtos
	BeginSQL Alias cAliasTmp

		SELECT	((ROW_NUMBER() OVER (ORDER BY A.R_E_C_N_O_)) /1000)+1	AS PAG 
				,B1_COD
				,B1_GRUPO
				,B1_DESC
				,B1_MSBLQL
				,B1_CODBAR
				,B1_PESBRU
				,B1_QE
				,B1_UM
				,B1_PESO
				,B1_POSIPI
				,B1_PESO
				,B1_CLASFIS
				,B1_GRTRIB
				,B1_PICM
				,B1_PICMRET
				,B1_VLR_PIS
				,B1_PESO
				,B1_PPIS
				,B1_PCOFINS
				,B1_CUSTD
				,B1_ZZLIBVE	
				,CASE B1_ZZLIBVE	WHEN 'S'
					THEN 	'1'
					ELSE 	'2'
				 END B1_ZZLIBVE
				,B1_ZZCODAN
				,B1_ZZCOLEC
				,B1_IPI
		FROM 	%Table:SB1% A  
		WHERE 	D_E_L_E_T_ <> '*' 
		AND		B1_MSBLQL = '2' 
		AND		B1_TIPO IN ('PA','ME') 
	
	EndSql
	
	
	dbSelectArea(cAliasTMP)
	(cAliasTMP)->( DbGoTop() )

	// Guarda a ultima pagina
	While (cAliasTmp)->( !Eof() )
		nPagFim		:= (cAliasTmp)->PAG
		(cAliasTmp)->(dbSkip())
	EndDo
	
	// Posiciona novamente no primeiro registro
	(cAliasTmp)->( DbGoTop() )

	If (cAliasTMP)->( Eof() ) 							// Sem Dados

		cSetResp 	:= '{ "TE_PRODUTO":[ "Retorno":"Nao Existe Itens Nessa Pagina"] } '
		lRet 		:= .F.
	
	ElseIf !Empty(nPag)								// Parametro QueryString nPag Preenchida
	
		nX		  := 1
		cSetResp  := '{"TE_PRODUTO":['
		
		While !(cAliasTMP)->( Eof() )

			If nPag == (cAliasTMP)->PAG
				
				If nX > 1
					cSetResp  +=' , '
				EndIf

				cSetResp  += '{'
				cSetResp  += '"CODIGO":"'  				+ TRIM((cAliasTMP)->B1_COD )	
				cSetResp  += '","CODIGOCATEGORIA":"' 	+ TRIM((cAliasTMP)->B1_ZZCOLEC)
				cSetResp  += '","CODIGOSTATUS":"'	 	+ TRIM(cValToChar((cAliasTMP)->B1_ZZLIBVE))				// Ruberlei em 23/01/2020
				cSetResp  += '","DESCRICAO":"'          + strTran(TRIM((cAliasTMP)->B1_DESC ), '"', '\"')	
				cSetResp  += '","FLAGBLOQUEIO":"'   	+ TRIM((cAliasTMP)->B1_MSBLQL) 
				cSetResp  += '","EAN13":"'				+ TRIM((cAliasTMP)->B1_CODBAR)
				cSetResp  += '","PESOBRUTO":'    		+ TRIM(STR((cAliasTMP)->B1_PESBRU)) 
				cSetResp  += ',"QTDEEMBALAGEM":' 		+ TRIM(STR((cAliasTMP)->B1_QE) )	
				cSetResp  += ',"UNIDPRODUTO":"'			+ TRIM((cAliasTMP)->B1_UM)	
				cSetResp  += '","PESOLIQUIDO":' 		+ TRIM(STR((cAliasTMP)->B1_PESO))
				cSetResp  += ',"NCM":"'                	+ TRIM(((cAliasTMP)->B1_POSIPI))
				cSetResp  += '","AMOGRATIS":"'          + ALLTRIM(STR((cAliasTMP)->B1_PESO))
				cSetResp  += '","CLASSFISCAL":"'        + TRIM(((cAliasTMP)->B1_CLASFIS))
				cSetResp  += '","CODGRPTRIB":"'         + TRIM(((cAliasTMP)->B1_GRTRIB))
				cSetResp  += '","ICMSINT":'            	+ TRIM(STR((cAliasTMP)->B1_PICM))
				cSetResp  += ',"ICMSEXT":'            	+ TRIM(STR(0))
				cSetResp  += ',"MVA":'                	+ TRIM(STR((cAliasTMP)->B1_PICMRET))
				cSetResp  += ',"PISPAUTA":'           	+ TRIM(STR((cAliasTMP)->B1_VLR_PIS))
				cSetResp  += ',"COFINSPAUTA":'        	+ TRIM(STR((cAliasTMP)->B1_PESO))
				cSetResp  += ',"ALIQPIS":'             	+ TRIM(STR((cAliasTMP)->B1_PPIS))
				cSetResp  += ',"ALIQCOFINS":'          	+ TRIM(STR((cAliasTMP)->B1_PCOFINS))
				cSetResp  += ',"ALIQIPI":'      		+ TRIM(STR((cAliasTMP)->B1_IPI))		// Ruberlei em 23/01/2020
				cSetResp  += ',"CUSTOSECO":'           	+ TRIM(STR((cAliasTMP)->B1_CUSTD))
				cSetResp  += ',"CODIGOANTERIOR":"'      + TRIM((cAliasTMP)->B1_ZZCODAN )
				cSetResp  += '"}'	
				nX:= nX+1
			Endif
			(cAliasTMP)->(dbSkip())
		EndDo
	
	Else												// Nenhuma QueryString passada por parametro

		nX			:= 1
		cSetResp  := '{"TE_PRODUTO":['
		While !(cAliasTMP)->( Eof() )				
	
			If nX > 1
				cSetResp  +=' , '
			EndIf

			cSetResp  += '{'
			cSetResp  += '"CODIGO":"'  				+ TRIM((cAliasTMP)->B1_COD )	
			cSetResp  += '","CODIGOCATEGORIA":"' 	+ TRIM((cAliasTMP)->B1_ZZCOLEC)
			cSetResp  += '","CODIGOSTATUS":"'	 	+ TRIM((cAliasTMP)->B1_ZZLIBVE)				// Ruberlei em 23/01/2020
			cSetResp  += '","DESCRICAO":"'          + strTran(TRIM((cAliasTMP)->B1_DESC ), '"', '\"')	
			cSetResp  += '","FLAGBLOQUEIO":"'   	+ TRIM((cAliasTMP)->B1_MSBLQL) 
			cSetResp  += '","DUN14":"'				+ TRIM((cAliasTMP)->B1_CODBAR)
			cSetResp  += '","PESOBRUTO":'    		+ TRIM(STR((cAliasTMP)->B1_PESBRU)) 
			cSetResp  += ',"QTDEEMBALAGEM":' 		+ TRIM(STR((cAliasTMP)->B1_QE) )	
			cSetResp  += ',"UNIDPRODUTO":"'			+ TRIM((cAliasTMP)->B1_UM)	
			cSetResp  += '","PESOLIQUIDO":' 		+ TRIM(STR((cAliasTMP)->B1_PESO))
			cSetResp  += ',"NCM":"'                	+ TRIM(((cAliasTMP)->B1_POSIPI))
			cSetResp  += '","AMOGRATIS":"'          + ALLTRIM(STR((cAliasTMP)->B1_PESO))
			cSetResp  += '","CLASSFISCAL":"'        + TRIM(((cAliasTMP)->B1_CLASFIS))
			cSetResp  += '","CODGRPTRIB":"'         + TRIM(((cAliasTMP)->B1_GRTRIB))
			cSetResp  += '","ICMSINT":'            	+ TRIM(STR((cAliasTMP)->B1_PICM))
			cSetResp  += ',"ICMSEXT":'            	+ TRIM(STR(0))
			cSetResp  += ',"MVA":'                	+ TRIM(STR((cAliasTMP)->B1_PICMRET))
			cSetResp  += ',"PISPAUTA":'           	+ TRIM(STR((cAliasTMP)->B1_VLR_PIS))
			cSetResp  += ',"COFINSPAUTA":'        	+ TRIM(STR((cAliasTMP)->B1_PESO))
			cSetResp  += ',"ALIQPIS":'             	+ TRIM(STR((cAliasTMP)->B1_PPIS))
			cSetResp  += ',"ALIQCOFINS":'          	+ TRIM(STR((cAliasTMP)->B1_PCOFINS))
			cSetResp  += ',"ALIQIPI":'      		+ TRIM(STR((cAliasTMP)->B1_IPI))		// Ruberlei em 23/01/2020
			cSetResp  += ',"CUSTOSECO":'           	+ TRIM(STR((cAliasTMP)->B1_CUSTD))
			cSetResp  += ',"CODIGOANTERIOR":"'      + TRIM((cAliasTMP)->B1_ZZCODAN )
			cSetResp  += '"}'	
			nX:= nX+1
			(cAliasTMP)->(dbSkip())
		EndDo

	EndIf

	If lRet
		cSetResp  += ']'	
		cSetResp  += ',"PaginalAtual":'				+ STR(Self:nPag)			
		cSetResp  += ',"TotalDePaginas":'			+ STR(nPagFim)
		cSetResp  += '}'
	Endif
		
	//Fecha a tabela
	(cAliasTMP)->(DbCloseArea())

	//Envia o JSON Gerado para a aplicação Cliente
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)
