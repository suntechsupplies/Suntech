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
***********************************************************************************************
*/
#Define _Function	"rRegiao"
#Define _DescFun	"Regiao"
#Define Desc_Rest 	"Serviço REST para Disponibilizar / Inserir dados de regiao" 
#Define Desc_Get  	"Retorna o cadastro de Regiao informado de acordo com os parametros passados" 
#Define Desc_Post	"Cria o cadastro de Regiao informado de acordo com data de atualização do cadastro"


user function R_Regiao()

return

WSRESTFUL rRegiao DESCRIPTION Desc_Rest

	WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING    
	
	WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/rRegiao || /rRegiao/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE nPag HEADERPARAM TENANTID WSSERVICE rRegiao
	Local aArea		:= GetArea()
	Local cAliasTMP	:= GetNextAlias() 
	Local cSetResp	:= ''
	Local nPag 		:= Self:nPag
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
	IF Select(cAliasTMP)>0
		dbSelectArea(cAliasTMP)
		(cAliasTMP)->(dbCloseArea())
	EndIf

	//Select de cadastro 
	BeginSql Alias cAliasTmp
	
		SELECT	(ROW_NUMBER() OVER (ORDER BY D.R_E_C_N_O_)/1000)+1 	AS PAG
				,D.X5_CHAVE  										AS CODIGO
				,D.X5_DESCRI 										AS DESCRICAO
		FROM  	%Table:SX5% D
		WHERE 	D.X5_TABELA = 'A2'
		AND 	D.%NotDel%	

	EndSQL

	dbSelectArea(cAliasTmp)
	(cAliasTMP)->( DbGoTop() )

	While (cAliasTmp)->( !Eof() )
		nPagFim		:= (cAliasTmp)->PAG
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->( DbGoTop() )   
	If (cAliasTMP)->( Eof() )

		cSetResp := '{"TE_REGIAO": [ "Retorno":"Nao Existe Itens Nessa Pagina"] } ' 

	Else
		(cAliasTmp)->( DbGoTop() )  
		nX		:= 1
		
		//Inicio do retorno em JSON
		cSetResp  := '{ "TE_REGIAO":[ ' 
		While (cAliasTmp)->( !Eof() )
			
			IF (cAliasTmp)->PAG == nPag
				
				If nX > 1
					cSetResp  +=' , '
				EndIf
				cSetResp  += '{'
				cSetResp  += '"CODIGO":"'				+ Trim((cAliasTMP)->CODIGO)					
				cSetResp  += '","DESCRICAO":"'			+ Trim((cAliasTMP)->DESCRICAO)																				
				cSetResp  += '"}'
				nX++
				(cAliasTmp)->(dbSkip())
			Else
				(cAliasTmp)->(dbSkip())
				LOOP	
			EndIf
		EndDo
	If cSetResp <> '{"TE_REGIAO": [ "Retorno":"Nao Existe Itens Nessa Pagina"] } '
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
