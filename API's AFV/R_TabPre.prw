#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"
/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Douglas.Silva Feat Carlos Eduardo Saturnino                                         *  
* Processa as informa��es e retorna o json                                                    *
* @since 	05/08/2019                                                                        *
* @version undefined                                                                          *
* @param oSelf, object, Objeto contendo dados da requisi��o efetuada pelo cliente, tais como: *
*    - Par�metros querystring (par�metros informado via URL)                                  *
*    - Objeto JSON caso o requisi��o seja efetuada via Request Post                           *
*    - Header da requisi��o                                                                   *
*    - entre outras ...                                                                       *
* @type Method                                                                                *
**********************************************************************************************/
#Define _Function	"Tabela de Preco"
#Define _DescFun	"RTabPre"
#Define Desc_Rest 	"Servi�o REST para Disponibilizar / Inserir dados de regiao" 
#Define Desc_Get  	"Retorna o cadastro de Regiao informado de acordo com os parametros passados" 
#Define Desc_Post	"Cria o cadastro de Regiao informado de acordo com data de atualiza��o do cadastro"


user function R_TabPre()

return

WSRESTFUL rTabPre DESCRIPTION Desc_Rest

	WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING    
	
	WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/RTabPre || /RTabPre/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE nPag HEADERPARAM TENANTID WSSERVICE RTabPre
	Local aArea		:= GetArea()
	Local cAliasTMP	:= GetNextAlias()
	Local nPag		:= Self:nPag
	Local cSetResp	:= ''
	Local nX
	Local nPagFim



	// define o tipo de retorno do m�todo
	::SetContentType("application/json")
	//**********************************************************************************
	// Efetua a prepara��o do ambiente 
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

	//Verifica se h� conex�o em aberto, caso haja feche.
	IF Select(cAliasTmp)>0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf

	//Select de cadastro 
	BeginSQL Alias cAliasTmp
	
		SELECT		((ROW_NUMBER() OVER (ORDER BY A.R_E_C_N_O_)) /1000)+1	AS PAG
					, A.DA0_FILIAL	AS FILIAL
					, A.DA0_CODTAB 	AS CODIGO
					, A.DA0_DESCRI 	AS DESCRI
					, A.DA0_DATDE 	AS DTAINICIAL
					, A.DA0_DATATE	AS DTAFINAL
					, A.DA0_ZZEAFV	AS FLAGUSO
		FROM   		%Table:DA0% A 
		WHERE  		A.%NotDel%
		AND    		A.DA0_ATIVO  = 1
		ORDER BY 	A.DA0_CODTAB 
	
	EndSql

	dbSelectArea(cAliasTmp)
	(cAliasTmp)->( DbGoTop() )

	While (cAliasTmp)->( !Eof() )
		nPagFim := (cAliasTmp)->PAG
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->( DbGoTop() )

	If (cAliasTmp)->( Eof() )

		cSetResp := '{ "TE_CABTABPRECO":"Nao Existe Dados Nessa Pagina"} '

	Else

		(cAliasTMP)->( DbGoTop() )  
		nX		:= 1
		
		//Inicio do retorno em JSON
		cSetResp  := '{ "TE_CABTABPRECO":[ ' 
		
		While (cAliasTMP)->( !Eof() )
		
			If (cAliasTmp)->PAG == nPag
		
				If nX > 1
					cSetResp  +=' , '
				EndIf
		
				cSetResp  += '{'
				cSetResp  += '"FILIAL":"'		+ TRIM((cAliasTMP)->FILIAL)					
				cSetResp  += '","CODIGO":"'		+ TRIM((cAliasTMP)->CODIGO)		
				cSetResp  += '","DESCRI":"'		+ TRIM((cAliasTMP)->DESCRI)		
				cSetResp  += '","DTAINICIAL":"'	+ TRIM((cAliasTMP)->DTAINICIAL)		
				cSetResp  += '","DTAFINAL":"'	+ TRIM((cAliasTMP)->DTAFINAL)
				cSetResp  += '","FLAGUSO":"'	+ TRIM((cAliasTMP)->FLAGUSO)		
				cSetResp  += '"}'

				(cAliasTmp)->(dbSkip())
				nX:= nX+1
			Else
				(cAliasTmp)->(dbSkip())
				Loop
			Endif
		EndDo
		cSetResp  += ']'	
		cSetResp  += ',"PaginalAtual":'				+ cValToChar(Self:nPag)			
		cSetResp  += ',"TotalDePaginas":'			+ cValToChar(nPagFim)
		cSetResp  += '}'

	EndIf
	//Fecha a tabela
	(cAliasTMP)->(DbCloseArea())

	//Envia o JSON Gerado para a aplica��o
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)
