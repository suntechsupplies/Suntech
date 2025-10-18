#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"
//#Include "aarray.ch"
//#Include "json.ch"

/*
***********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Douglas.Silva                                                                       *  
* Processa as informa��es e retorna o json                                                    *
* @since 	28/07/2019                                                                        *
* @version undefined                                                                          *
* @param oSelf, object, Objeto contendo dados da requisi��o efetuada pelo cliente, tais como: *
*    - Par�metros querystring (par�metros informado via URL)                                  *
*    - Objeto JSON caso o requisi��o seja efetuada via Request Post                           *
*    - Header da requisi��o                                                                   *
*    - entre outras ...                                                                       *
* @type Method                                                                                *
***********************************************************************************************
*/
#Define _Function "ForPgto"
#Define _DescFun  "Forma de Pagamento"
#Define Desc_Rest "Servi�o REST para Disponibilizar / Inserir dados de forma de pagamento"
#Define Desc_Get  "Retorna o cadastro de Forma de Pagamento informado de acordo com os parametros passados"

user function R_ForPgt()

return

WSRESTFUL rForPgt DESCRIPTION Desc_Rest

    WSDATA cDataDe 	As String
    WSDATA cDataAte	As String
    WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING

    WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/rForPgt || /rForPgt/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE cDataDe, cDataAte,  nPag HEADERPARAM TENANTID WSSERVICE rForPgt
	Local aArea		:= GetArea()
	Local cAliasTMP
	Local aArea
	Local cRet		
	Local cSetResp
	Local nX
	Local nZ
	LOCAL cDtaDe
	Local cDtaAte
	LOCAL nPagIni
	Local nPagFim
	Local nReg
	Local nRegFinal

	cDtaDe 	:= Self:cDataDe
	cDtaAte	:= Self:cDataAte

	If Self:nPag == 1
		nPagIni		:= Self:nPag
		nPagFim		:= (Self:nPag*1000)
	Else
		nPagIni		:= (Self:nPag*1000)-999
		nPagFim		:= (Self:nPag*1000)
	EndIf

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


	cRet		:= ""
	aArea     	:= GetArea()
	cAliasTMP 	:= GetNextAlias()


	//Select de cadastro 
	cQuery := "	SELECT (ROW_NUMBER() OVER (ORDER BY D.R_E_C_N_O_)) CONT  "

	cQuery += " , D.X5_CHAVE CODIGO"
	cQuery += " , D.X5_DESCRI 	DESCRICAO"
	cQuery += " FROM " + RetSqlName("SX5") + " D " 
	cQuery += " WHERE D.D_E_L_E_T_ <> '*' AND TRIM(X5_TABELA) = '24'"
	cQuery += " ORDER BY D.R_E_C_N_O_ "

	cQuery := ChangeQuery(cQuery)

	//Verifica se h� conex�o em aberto, caso haja feche.
	IF Select(cAliasTMP)>0
		dbSelectArea(cAliasTMP)
		(cAliasTMP)->(dbCloseArea())
	EndIf

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),(cAliasTMP),.T.,.T.)

	dbSelectArea(cAliasTMP)
	dbSelectArea(cAliasTmp)

	(cAliasTmp)->( DbGoTop() )

	While (cAliasTmp)->( !Eof() )
		nReg := (cAliasTmp)->CONT
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->( DbGoTop() )

	If nReg <= 1000 
		nRegFinal := 1
	Else
		nRegFinal := Int(nReg/1000)+1 
	EndIf 


	If (cAliasTmp)->( Eof() )

		cSetResp := '{    "JSON": [],    "PaginalAtual": 1,    "TotalDePaginas": 1}'

	Else


		(cAliasTmp)->( DbGoTop() )  
		nX	:= 1
		cSetResp  := '{ "JSON":[ ' 
		While (cAliasTmp)->( !Eof() )
			IF (cAliasTmp)->cont >= nPagIni .And. (cAliasTmp)->cont <= nPagFim
				If nX > 1
					cSetResp  +=' , '
				EndIf				
				cSetResp  += '{'
				cSetResp  += '"CODIGO":"'				+ TRIM((cAliasTMP)->CODIGO)					
				cSetResp  += '","DESCRICAO":"'			+ TRIM((cAliasTMP)->DESCRICAO)											
				cSetResp  += '"}'
				(cAliasTMP)->(dbSkip())
				nX:= nX+1
			Else
				(cAliasTMP)->(dbSkip())
				LOOP	
			EndIf
		EndDo
		cSetResp  += ']'	
		cSetResp  += ',"PaginalAtual":'				+ STR(Self:nPag)			
		cSetResp  += ',"TotalDePaginas":'			+ STR(nRegFinal)
		cSetResp  += '}'

	EndIf
	//Fecha a tabela
	(cAliasTMP)->(DbCloseArea())

	//verifica se houve dados 
	If Len(cSetResp) == Len('{ "JSON":[ ]}')
		cSetResp := '{ "Retorno":"Nao Existe Dados Nessa Pagina"} '
	EndIF

	//Envia o JSON Gerado para a aplica��o
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)
