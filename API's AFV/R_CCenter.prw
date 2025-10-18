#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"
//#Include "aarray.ch"
//#Include "json.ch"



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
#Define _Function	"Call Center"
#Define _DescFun    "Call Center"
#Define Desc_Rest 	"Serviço REST para Disponibilizar dados de Call Center"
#Define Desc_Get  	"Retorna o cadastro de Call Center informado de acordo com os parametros passados" 

user function R_CCenter()

return

WSRESTFUL rCallCenter DESCRIPTION Desc_Rest

    WSDATA cDataDe 	As String
    WSDATA cDataAte	As String
    WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING

    WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/rCallCenter || /rCallCenter/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE cDataDe, cDataAte,  nPag HEADERPARAM TENANTID WSSERVICE rCallCenter
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
	cQuery := "SELECT U6_CODENT                     AS CODIGOCLIENTE,"
	cQuery += "       U5_CONTAT                     AS CONTATOORIGEM,"
	cQuery += "       U7_NOME                       AS CONTATOEMPRESA,"
	cQuery += "       U5_FONE                       AS TELEFONEORIGEM,"
	cQuery += "       UC_DATA                       AS DATAOCORRENCIA,"
	cQuery += "       CAST(UC_INICIO AS VARCHAR(5)) AS HORA,"
	cQuery += "       UD_OBS                        AS DESCRICAO"
	cQuery += " FROM  " + RetSqlName("SUD") + " UD,"
	cQuery += "       " + RetSqlName("SUC") + " UC,"
	cQuery += "       " + RetSqlName("SU6") + " U6,"
	cQuery += "       " + RetSqlName("SU5") + " U5,"
	cQuery += "       " + RetSqlName("SU7") + " U7"
	cQuery += "WHERE  UC_ENTIDAD = 'SA1'"
	cQuery += "   AND UC_OPERADO = U7_COD"
	cQuery += "   AND U6_CONTATO = U5_CODCONT"
	cQuery += "   AND UC_CODIGO = UD_CODIGO"
	cQuery += "   AND UC_CODIGO = U6_CODLIG"
	cQuery += "   AND UD_OBS <> ''"
	cQuery += "   AND U7.D_E_L_E_T_ <> '*'"
	cQuery += "   AND U5.D_E_L_E_T_ <> '*'"
	cQuery += "   AND U6.D_E_L_E_T_ <> '*'"
	cQuery += "   AND UC.D_E_L_E_T_ <> '*'"
	cQuery += "   AND UD.D_E_L_E_T_ <> '*'"
	cQuery += "   AND UC_DATA >= '20150101'"
	cQuery += "    AND	Convert(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(UD_USERLGA,12,1)) - 50)) +	 "
	cQuery += "         Convert(nvarchar(50),(ASCII(SUBSTRING(UD_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),112)	END >= "+ cDtaDe +"   "
	cQuery += "    AND CASE WHEN A1_USERLGA <> '' THEN "	
	cQuery += " 	    Convert(VARCHAR(10), CAST(DATEADD(DAY,CONVERT(INT,Convert(nvarchar(50),(ASCII(SUBSTRING(UD_USERLGA,12,1)) - 50)) +	 "	
	cQuery += "         Convert(nvarchar(50),(ASCII(SUBSTRING(UD_USERLGA,16,1)) - 50))), '1996-01-01') AS DATETIME),112)	END <= "+ cDtaAte +"   "	
	cQuery +=  "GROUP  BY U6_CODENT, U5_CONTAT, U7_NOME, U5_FONE, UC_DATA, UC_INICIO, UD_OBS, UD_VEND"

	cQuery := ChangeQuery(cQuery)

	//Verifica se há conexão em aberto, caso haja feche.
	IF Select(cAliasTMP)>0
		dbSelectArea(cAliasTMP)
		(cAliasTMP)->(dbCloseArea())
	EndIf

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),(cAliasTMP),.T.,.T.)

	dbSelectArea(cAliasTMP)

	(cAliasTMP)->( DbGoTop() )   

	If (cAliasTMP)->( Eof() )

		cSetResp := '{"ERRO": "Cadstros nao encontrados nesse periodo!"}' 

	Else
		(cAliasTMP)->( DbGoTop() )  
		nX		:= 1
		//Inicio do retorno em JSON
		cSetResp  := '{ "Call Center":[ ' 
		While (cAliasTMP)->( !Eof() )
			IF (cAliasTMP)->cont >= nPagIni .And. (cAliasTMP)->cont <= nPagFim
				If nX > 1
					cSetResp  +=' , '
				EndIf
				cSetResp  += '{'
				cSetResp  += '"CODIGOCLIENTE":"'   	+ (cAliasTMP)->CODIGOCLIENTE					
				cSetResp  += '","CONTATOORIGEM":"'	+ (cAliasTMP)->CONTATOORIGEM											
				cSetResp  += '","CONTATOEMPRESA":"'	+ (cAliasTMP)->CONTATOEMPRESA											
				cSetResp  += '","TELEFONEORIGEM":"'	+ (cAliasTMP)->TELEFONEORIGEM											
				cSetResp  += '","DATAOCORRENCIA":"'	+ (cAliasTMP)->DATAOCORRENCIA											
				cSetResp  += '","HORA":"'			+ (cAliasTMP)->HORA											
				cSetResp  += '","DESCRICAO":"'		+ (cAliasTMP)->DESCRICAO											
				cSetResp  += '"}'
				nX:= nX+1
			Else
				(cAliasTMP)->(dbSkip())
				LOOP	
			EndIf
		EndDo
		cSetResp  += ']}'	

	EndIf
	//Fecha a tabela
	(cAliasTMP)->(DbCloseArea())

	//verifica se houve dados 
	If Len(cSetResp) == Len('{ "Call Center":[ ]}')
		cSetResp := '{ "Retorno":"Nao Existe Dados Nessa Pagina"} '
	EndIF

	//Envia o JSON Gerado para a aplicação Cliente
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)
