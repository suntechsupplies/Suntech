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
#Define _DescFun	"RTES"
#Define Desc_Rest 	"Serviço REST para Disponibilizar / Inserir dados de TES " 
#Define Desc_Get  	"Retorna o cadastro de TES  informado de acordo com os parametros passados" 
#Define Desc_Post	"Cria o cadastro de TES  informado de acordo com data de atualização do cadastro"


user function R_TES()

return

WSRESTFUL rTES DESCRIPTION Desc_Rest

    WSDATA cDataDe 	As String
    WSDATA cDataAte	As String
    WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING

    WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/RTES || /RTES/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE cDataDe, cDataAte,  nPag HEADERPARAM TENANTID WSSERVICE RTES
	Local aArea		:= GetArea()
	Local cAliasTMP
	Local aArea
	Local cRet		
	Local cSetResp
	Local nX
	LOCAL cDtaDe
	Local cDtaAte
	LOCAL nPagIni
	Local nPagFim
	Local nReg
	Local nRegFinal

	cDtaDe 	:= Self:cDataDe
	cDtaAte	:= Self:cDataAte

	cSetResp:= ""

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


	//If Len(::aURLParms) > 0
	cRet		:= ""
	aArea     	:= GetArea()
	cAliasTmp 	:= GetNextAlias()
	nReg		:= 0


	//Select de cadastro 
	cQuery := "	SELECT (ROW_NUMBER() OVER (ORDER BY SF4.R_E_C_N_O_)) AS CONT,  "

	cQuery += "	SF4.F4_CODIGO    AS CODIGO," 
	cQuery += "	SF4.F4_ICM       AS ICMS," 
	cQuery += "	SF4.F4_IPI       AS IPI," 
	cQuery += "	SF4.F4_INCIDE    AS CALCIPIBSICM,"
	cQuery += "	SF4.F4_BASEICM   AS BASEICM, "
	cQuery += "	SF4.F4_BASEIPI   AS BASEIPI, "
	cQuery += "	SF4.F4_ICMSST    AS ICMSST,"
	cQuery += "	SF4.F4_TPIPI     AS TPIPI, "
	cQuery += "	SF4.F4_STDESC    AS STDESC, "
	cQuery += "	SF4.F4_BSICMST   AS BSICMST, "
	cQuery += "	SF4.F4_PISCOF    AS PISCOF"
	cQuery += "	FROM " + RetSqlName("SF4") + "  SF4"
	cQuery += "	WHERE SF4.D_E_L_E_T_ <> '*'"
	cQuery += " AND SF4.F4_CODIGO >= '500'	"
	cQuery := ChangeQuery(cQuery)

	//Verifica se há conexão em aberto, caso haja feche.

	IF Select(cAliasTmp)>0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),(cAliasTmp),.T.,.T.)

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
		(cAliasTMP)->( DbGoTop() )  
		nX		:= 1
		//Inicio do retorno em JSON
		cSetResp  := '{ "JSON":[ ' 
		While (cAliasTMP)->( !Eof() )
				If nX > 1
					cSetResp  +=' , '
				EndIf
				cSetResp  += '{'
				cSetResp  += '"CODIGO":"'			+ ALLTRIM((cAliasTMP)->CODIGO)					
				cSetResp  += '","ICMS":"'			+ ALLTRIM((cAliasTMP)->ICMS)																				
				cSetResp  += '","IPI":"'			+ ALLTRIM((cAliasTMP)->IPI)																				
				cSetResp  += '","CALCIPIBSICM":"'	+ ALLTRIM((cAliasTMP)->CALCIPIBSICM)																				
				cSetResp  += '","BASEICM":'			+ ALLTRIM(cValToChar((cAliasTMP)->BASEIPI))																				
				cSetResp  += ',"BASEIPI":'			+ ALLTRIM(cValToChar((cAliasTMP)->BASEIPI))																				
				cSetResp  += ',"ICMSST":"'			+ ALLTRIM((cAliasTMP)->ICMSST)																				
				cSetResp  += '","TPIPI":"'			+ ALLTRIM((cAliasTMP)->TPIPI)																				
				cSetResp  += '","STDESC":"'			+ ALLTRIM((cAliasTMP)->STDESC)																				
				cSetResp  += '","BSICMST":'			+ ALLTRIM(cValToChar((cAliasTMP)->BSICMST))																				
				cSetResp  += ',"PISCOF":"'			+ ALLTRIM((cAliasTMP)->PISCOF)																				
				cSetResp  += '"}'

				(cAliasTmp)->(dbSkip())
				nX:= nX+1
		EndDo
		cSetResp  += ']'	
		//cSetResp  += ',"PaginalAtual":'				+ cValToChar(Self:nPag)			
		cSetResp  += ',"TotalDePaginas":'			+ cValToChar(nRegFinal)
		cSetResp  += '}'

	EndIf
	//Fecha a tabela
	(cAliasTMP)->(DbCloseArea())

	//verifica se houve dados 
	If Len(cSetResp) == Len('{ "JSON":[ ]}')
		cSetResp := '{ "Retorno":"Nao Existe Dados Nessa Pagina"} '
	EndIF

	//Envia o JSON Gerado para a aplicação
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)
