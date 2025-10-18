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
#Define _Function	"Excecao Fiscal	"
#Define _DescFun	"RExcFis"
#Define Desc_Rest 	"Serviço REST para Disponibilizar / Inserir dados de Excecao Fiscal " 
#Define Desc_Get  	"Retorna o cadastro de TES  informado de acordo com os parametros passados" 
#Define Desc_Post	"Cria o cadastro de TES  informado de acordo com data de atualização do cadastro"


user function R_ExcFis()

return

WSRESTFUL RExcFis DESCRIPTION Desc_Rest

    WSDATA cDataDe 	As String
    WSDATA cDataAte	As String
    WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING

    WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/RExcFis || /RExcFis/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE cDataDe, cDataAte,  nPag HEADERPARAM TENANTID WSSERVICE RExcFis
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

	If Self:nPag == 1
		nPagIni		:= Self:nPag
		nPagFim		:= (Self:nPag*1000)
	Else
		nPagIni		:= (Self:nPag*1000)-999
		nPagFim		:= (Self:nPag*1000)
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

	//If Len(::aURLParms) > 0
	cRet		:= ""
	aArea     	:= GetArea()
	cAliasTmp 	:= GetNextAlias()
	nReg		:= 0


	//Select de cadastro 
	cQuery := "	SELECT (ROW_NUMBER() OVER (ORDER BY SF7.R_E_C_N_O_)) AS CONT,  "
	
	cQuery += "	SF7.F7_EST        	EST,"
	cQuery += "	SF7.F7_SITTRIB    	SITTRIB,"
	cQuery += "	SF7.F7_GRTRIB   	GRTRIB,"
	cQuery += "	SF7.F7_GRPCLI     	GRPCLI,"
	cQuery += "	SF7.F7_ALIQINT    	ALIQINT,"
	cQuery += "	SF7.F7_ALIQEXT    	ALIQEXT,"
	cQuery += "	SF7.F7_MARGEM     	MARGEM,"
	cQuery += "	SF7.F7_VLR_PIS    	VLRPIS,"
	cQuery += "	SF7.F7_VLR_COF    	VLRCOF,"
	cQuery += "	SF7.F7_ALIQPIS    	ALIQPIS,"
	cQuery += "	SF7.F7_ALIQCOF    	ALIQCOF"
	cQuery += "	FROM " + RetSqlName("SF7") + "  SF7"
	cQuery += "	WHERE SF7.D_E_L_E_T_ <> '*'"

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
			IF (cAliasTMP)->cont >= nPagIni .And. (cAliasTMP)->cont <= nPagFim
				If nX > 1
					cSetResp  +=' , '
				EndIf
				cSetResp  += '{'
				cSetResp  += '"EST":"'			+ TRIM((cAliasTMP)->EST)					
				cSetResp  += '","SITTRIB":"'	+ TRIM((cAliasTMP)->SITTRIB)																				
				cSetResp  += '","GRTRIB":"'		+ TRIM((cAliasTMP)->GRTRIB)																				
				cSetResp  += '","GRPCLI":"'		+ TRIM((cAliasTMP)->GRPCLI)																				
				cSetResp  += '","ALIQINT":'		+ TRIM(STR((cAliasTMP)->ALIQINT))																			
				cSetResp  += ',"ALIQEXT":'		+ TRIM(STR((cAliasTMP)->ALIQEXT))																				
				cSetResp  += ',"MARGEM":'		+ TRIM(STR((cAliasTMP)->MARGEM))																				
				cSetResp  += ',"VLRPIS":'		+ TRIM(STR((cAliasTMP)->VLRPIS))																				
				cSetResp  += ',"VLRCOF":'		+ TRIM(STR((cAliasTMP)->VLRCOF))																				
				cSetResp  += ',"ALIQPIS":'		+ TRIM(STR((cAliasTMP)->ALIQPIS))																				
				cSetResp  += ',"ALIQCOF":'		+ TRIM(STR((cAliasTMP)->ALIQCOF))																				
				cSetResp  += '}'

				(cAliasTmp)->(dbSkip())
				nX:= nX+1
			Else
				(cAliasTmp)->(dbSkip())
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

	//Envia o JSON Gerado para a aplicação
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)
