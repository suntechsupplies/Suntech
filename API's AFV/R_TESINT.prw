#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"

/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Douglas.Silva                                                                       *  
* Processa as informações e retorna o json                                                    *
* @since 	05/08/2019                                                                        *
* @version undefined                                                                          *
* @param oSelf, object, Objeto contendo dados da requisição efetuada pelo cliente, tais como: *
*    - Parâmetros querystring (parâmetros informado via URL)                                  *
*    - Objeto JSON caso o requisição seja efetuada via Request Post                           *
*    - Header da requisição                                                                   *
*    - entre outras ...                                                                       *
* @type Method                                                                                *
***********************************************************************************************
*/
#Define _Function	"TES	"
#Define _DescFun	"RTESINT"
#Define Desc_Rest 	"Serviço REST para Disponibilizar / Inserir dados de TES " 
#Define Desc_Get  	"Retorna o cadastro de TES  informado de acordo com os parametros passados" 
#Define Desc_Post	"Cria o cadastro de TES  informado de acordo com data de atualização do cadastro"


user function R_TESINT()

return

WSRESTFUL rTESINT DESCRIPTION Desc_Rest

	WSDATA nPag     As Integer
    WSDATA TENANTID AS STRING

    WSMETHOD 	GET DESCRIPTION Desc_Get WSSYNTAX "/RTESINT || /RTESINT/{}"


END WSRESTFUL


WSMETHOD GET WSRECEIVE nPag HEADERPARAM TENANTID WSSERVICE RTESINT
	Local aArea		:= GetArea()
	Local cAliasTMP	:= GetNextAlias()
	Local nPag 		:= Self:nPag
	Local cSetResp	:= ''
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
	
		SELECT		((ROW_NUMBER() OVER (ORDER BY SFM.R_E_C_N_O_)) /500)+1	AS PAG 
					, SFM.FM_TS        										AS TS
					, SFM.FM_TIPO      										AS TIPO
					, SFM.FM_DESCR											AS DESCRICAO
					, SFM.FM_CLIENTE   										AS CLIENTE
					, SFM.FM_LOJACLI   										AS LOJACLI
					, SFM.FM_PRODUTO   										AS PRODUTO
					, SFM.FM_EST   											AS ESTADO
					, SFM.FM_GRTRIB    										AS GRTRIB
					, SFM.FM_GRPROD    										AS GRPROD
					, SFM.FM_TIPOMOV   										AS TIPOMV
		FROM 		%Table:SFM%  SFM
		WHERE		SFM.%NotDel%
		GROUP BY 	SFM.R_E_C_N_O_
					, SFM.FM_TS
					, SFM.FM_TIPO
					, SFM.FM_DESCR
					, SFM.FM_CLIENTE   											
					, SFM.FM_LOJACLI   								
					, SFM.FM_PRODUTO   								
					, SFM.FM_EST       					
					, SFM.FM_GRTRIB    								
					, SFM.FM_GRPROD    							
					, SFM.FM_TIPOMOV   
		ORDER BY 	SFM.FM_TS
					, SFM.FM_TIPO
					, SFM.FM_DESCR
					, SFM.FM_CLIENTE   											
					, SFM.FM_LOJACLI   								
					, SFM.FM_PRODUTO   								
					, SFM.FM_EST       					
					, SFM.FM_GRTRIB    								
					, SFM.FM_GRPROD    							
					, SFM.FM_TIPOMOV   
					, SFM.R_E_C_N_O_	
	EndSQL

	dbSelectArea(cAliasTmp)
	(cAliasTmp)->( DbGoTop() )

	While (cAliasTmp)->( !Eof() )
		nPagFim := (cAliasTmp)->PAG
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->( DbGoTop() )

	If (cAliasTmp)->( Eof() )

		cSetResp := '{"JSON":[ "Retorno":"Nao Existe Dados Nessa Pagina" ] } '

	Else
		(cAliasTMP)->( DbGoTop() )  
		nX		:= 1
		
		//Inicio do retorno em JSON
		cSetResp  := '{ "JSON":[ ' 
		While (cAliasTMP)->( !Eof() )
		
			If nPag == (cAliasTMP)->PAG
			
				If nX > 1
					cSetResp  +=' , '
				EndIf
				
				cSetResp  += '{'
				cSetResp  += '"TPOPER":"'		+ ALLTRIM((cAliasTMP)->TIPO)
				cSetResp  += '","DESCRICAO":"'	+ ALLTRIM((cAliasTMP)->DESCRICAO)
				cSetResp  += '","TIPOMV":"'		+ ALLTRIM((cAliasTMP)->TIPOMV)
				cSetResp  += '","CLIENTE":"'	+ ALLTRIM((cAliasTMP)->CLIENTE)
				cSetResp  += '","LOJACLI":"'	+ ALLTRIM((cAliasTMP)->LOJACLI)
				cSetResp  += '","PRODUTO":"'	+ ALLTRIM((cAliasTMP)->PRODUTO)
				cSetResp  += '","ESTADO":"'		+ ALLTRIM((cAliasTMP)->ESTADO)
				cSetResp  += '","GRTRIB":"'		+ ALLTRIM((cAliasTMP)->GRTRIB)
				cSetResp  += '","GRPROD":"'		+ ALLTRIM((cAliasTMP)->GRPROD)
				cSetResp  += '","TS":"'			+ ALLTRIM((cAliasTMP)->TS)																							
				cSetResp  += '"}'		
				
				(cAliasTmp)->(dbSkip())
				nX:= nX+1
			Else
				(cAliasTmp)->(dbSkip())
				loop
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
