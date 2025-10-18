#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"

/**********************************************************************************************
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
**********************************************************************************************/

#Define _Function "rMoeda"
#Define _DescFun  "Cadastro de Moedas"
#Define Desc_Rest "Serviço REST para Disponibilizar dados de Cadastro de Moedas"
#Define Desc_Get  "Retorna o cadastro de Cadastro de Moedas informado de acordo com os parametros passados" 

user function R_Moeda()

return

WSRESTFUL rMoeda DESCRIPTION Desc_Rest

    WSDATA cDataDe 	As String
    WSDATA cDataAte	As String
    WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING

    WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/rMoeda || /rMoeda/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE cDataDe, cDataAte,  nPag HEADERPARAM TENANTID WSSERVICE rMoeda
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

	cRet		:= ""
	aArea     	:= GetArea()
	cAliasTMP 	:= GetNextAlias()



	//Select de cadastro 
	cQuery := "	SELECT (ROW_NUMBER() OVER (ORDER BY SM2.R_E_C_N_O_)) AS CONT,  "

	cQuery += " SM2.* "
	cQuery += " FROM       " + RetSqlName("SM2") + "   SM2"
	cQuery += " WHERE      SM2.D_E_L_E_T_ <> '*'"
	cQuery += " AND SM2.R_E_C_N_O_ = (SELECT  MAX(R_E_C_N_O_) FROM " + RetSqlName("SM2") + " WHERE  D_E_L_E_T_ <> '*') "
	

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
		(cAliasTmp)->( DbGoTop() )  
		nX	:= 1
		cSetResp  := '{ "JSON":[ ' 
		While (cAliasTmp)->( !Eof() )
			IF (cAliasTmp)->cont >= nPagIni .And. (cAliasTmp)->cont <= nPagFim
				If nX > 1
					cSetResp  +=' , '
				EndIf				
				cSetResp  += '{'
				cSetResp  += '"DATA":"'			+ TRIM((cAliasTmp)->M2_DATA)
				cSetResp  += '","MOEDA1":'		+ TRIM(STR((cAliasTmp)->M2_MOEDA1))
				cSetResp  += ',"MOEDA2":'		+ TRIM(STR((cAliasTmp)->M2_MOEDA2))
				cSetResp  += ',"MOEDA3":'		+ TRIM(STR((cAliasTmp)->M2_MOEDA3))
				cSetResp  += ',"MOEDA4":'		+ TRIM(STR((cAliasTmp)->M2_MOEDA4))
				cSetResp  += ',"MOEDA5":'		+ TRIM(STR((cAliasTmp)->M2_MOEDA5))
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
	(cAliasTmp)->(DbCloseArea())

	//verifica se houve dados 
	If Len(cSetResp) == Len('{ "JSON":[ ]}')
		cSetResp := '{ "Retorno":"Nao Existe Dados Nessa Pagina"} '
	EndIF

	//Envia o JSON Gerado para a aplicação
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)

