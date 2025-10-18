#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"
#Include "Totvs.ch"

/**********************************************************************************************
* Ejecty - Rest - Cliente
**********************************************************************************************/

#Define Desc_Rest 	"Serviço REST para Disponibilizar cadastro de Representantes"
#Define Desc_Get  	"Retorna o Representante informado de acordo com data de atualização do cadastro" 
#Define Desc_Post	"Cadastra um representante informado de acordo com data de atualização do Cadastro"

User Function EJRep()

Return(.T.)

WSRESTFUL EJRep DESCRIPTION Desc_Rest

WSDATA nPag		As Integer
WSDATA cTipo	As String

	WSMETHOD GET  DESCRIPTION Desc_Get  WSSYNTAX "/EJRep || /EJRep/{}"
	WSMETHOD POST DESCRIPTION Desc_Post WSSYNTAX "/EJRep/{Representante}"	

END WSRESTFUL


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

WSMETHOD GET WSRECEIVE nPag, cTipo WSSERVICE EJRep

	Local aArea		:= GetArea()
	Local cAliasTmp	:= GetNextAlias()
	Local cSetResp
	Local nX
	Local nPagFim
	Local nPag		:= Self:nPag
	Local lRet		:= .T.
	Local aTabs		:= {}
	Local _cEmpresa	:= "01"
	Local _cFilial	:= "01"
	Local _lSegue	:= .F.

	If FindFunction("WfPrepEnv")

		//*****************************************************************
		// Cofigura empresa/filial
		//*****************************************************************
		RpcSetEnv( _cEmpresa,_cFilial,,, "GET", "METHOD", aTabs,,,,)
		cEmpant := _cEmpresa
		cFilant := _cFilial

		//*****************************************************************
		// Enquanto nao configura empresa e filial fica dentro
		// do "laco" verificando
		//*****************************************************************
		While ! _lSegue
			If _cEmpresa + _cFilial == cNumEmp
				_lSegue := .T.
			Endif
		End
	Endif

	//Verifica se há conexão em aberto, caso haja feche.
	IF Select(cAliasTmp)>0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf

	BeginSql Alias cAliasTmp		
		SELECT  ROW_NUMBER() OVER(ORDER BY A.R_E_C_N_O_ ) 				AS CONT 
				,((ROW_NUMBER() OVER (ORDER BY A.R_E_C_N_O_)) /10)+1	AS PAG
				,A.*
				,A.D_E_L_E_T_ 											AS DEL
		FROM  	%Table:SA3% A  
		WHERE 	A.A3_ZSTATUS <> '9'
		AND     A.%NotDel%
		ORDER BY PAG	
	EndSQL

	dbSelectArea(cAliasTmp)
	(cAliasTmp)->( DBGoTop() )

	While (cAliasTmp)->( !Eof() )
		nPagFim		:= (cAliasTmp)->PAG
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->( DbGoTop() )

	If (cAliasTmp)->( Eof() )

		cSetResp 	:= '{ "representantes":[ "Retorno":"Nao Existe Itens Nessa Pagina"] } '
		lRet 		:= .F.

	Else

		(cAliasTmp)->( DbGoTop() )
		nX	:= 1
		cSetResp  := '{ "representantes":[ '

		SA1->(dbSelectArea("SA3"))
		SA1->(dbSetOrder(1))
		While (cAliasTmp)->( !Eof() )
			If nPag == (cAliasTmp)->PAG

				If nX > 1
					cSetResp  +=' , '
				EndIf
				cSetResp  += '{'
				cSetResp  += '"REGISTRO":'					+ ALLTRIM(STR((cAliasTmp)->CONT))
				cSetResp  += ',"A3_COD":"'			        + TRIM((cAliasTmp)->A3_COD)
				cSetResp  += '","A3_NOME":"'				+ TRIM((cAliasTmp)->A3_NOME)
				cSetResp  += '","A3_NREDUZ":"'				+ FwNoAccent(TRIM((cAliasTmp)->A3_NREDUZ))
				cSetResp  += '","A3_END":"'					+ TRIM((cAliasTmp)->A3_END )
				cSetResp  += '","A3_ZZCOMP":"'			    + TRIM((cAliasTmp)->A3_ZZCOMP)
				cSetResp  += '","A3_BAIRRO":"'				+ FwNoAccent(STRTran(STRTran(STRTran( TRIM((cAliasTmp)->A3_BAIRRO)	, '"', ''),'\','-'),'/','-'))
				cSetResp  += '","A3_CEP":"' 				+ TRIM((cAliasTmp)->A3_CEP)
				cSetResp  += '","A3_MUN":"'					+ STRTran(STRTran(STRTran( TRIM((cAliasTmp)->A3_MUN)	, '"', ''),'\','-'),'/','-')
				cSetResp  += '","A3_EST":"' 				+ TRIM((cAliasTmp)->A3_EST)
				cSetResp  += '","A3_DDDTEL":"'				+ FwNoAccent(TRIM((cAliasTmp)->A3_DDDTEL))
				cSetResp  += '","A3_DDDCEL":"'				+ ALLTRIM((cAliasTmp)->A3_DDDCEL)
				cSetResp  += '","A3_CEL":"'					+ ALLTRIM((cAliasTmp)->A3_CEL)
				cSetResp  += '","A3_TEL":"'				    + TRIM(((cAliasTmp)->A3_TEL))
				cSetResp  += '","A3_CGC":"'					+ TRIM(((cAliasTmp)->A3_CGC))
				cSetResp  += '","A3_INSCR":"'				+ TRIM(((cAliasTmp)->A3_INSCR))
				cSetResp  += '","A3_MSBLQL":"'		        + TRIM(IIF((cAliasTmp)->A3_MSBLQL == "1" ,'B','A'))
				cSetResp  += '","A3_EMAIL":"' 				+ TRIM((ALLTRIM((cAliasTmp)->A3_EMAIL)))
				cSetResp  += '","A3_PAIS":"' 				+ FwNoAccent(TRIM((cAliasTmp)->A3_PAIS))
				cSetResp  += '","A3_DDI":"' 				+ TRIM((cAliasTmp)->A3_DDI)				
				cSetResp  += '","A3_EMACORP":"'				+ ALLTRIM((cAliasTmp)->A3_EMACORP)
				cSetResp  += '","A3_ZZOBS":"'				+ TRIM(((cAliasTmp)->A3_ZZOBS))
				cSetResp  += '","A3_ZSTATUS":"'				+ FwNoAccent(STRTran(STRTran(STRTran( TRIM((cAliasTmp)->A3_ZSTATUS), '"', ''),'\','-'),'/','-'))
				cSetResp  += '","STATUS":"'		            + IIF((cAliasTmp)->DEL = "*", "DELETADO","ATIVO")
				cSetResp  += '"}'

				(cAliasTmp)->(dbSkip())
				nX++

			Else
				(cAliasTmp)->(dbSkip())
			Endif
		EndDo

		// Caso não esteja em EOF()
		If lRet
			cSetResp  += ']'
			cSetResp  += ',"PaginalAtual":'				+ cValToChar(Self:nPag)
			cSetResp  += ',"TotalDePaginas":'			+ cValToChar(nPagFim)
			cSetResp  += '}'
		Endif

	EndIf

	//Fecha a tabela
	(cAliasTmp)->(DbCloseArea())

	// Formata a String substituindo a /
	cSetResp := UNESCAPE(cSetResp)
	cSetResp := EncodeUTF8(cSetResp)
	While At('%2F',cSetResp) > 1
		cSetResp := strTran(cSetResp, "%2F", "/")
	EndDo

	//-------------------------------------------------------------------
	//Envia o JSON Gerado para a aplicação Cliente
	//-------------------------------------------------------------------
	::SetResponse( cSetResp )

	//-------------------------------------------------------------------
	// Efetuo o fechamento da Tabela SA1
	//-------------------------------------------------------------------
	SA3->(dbCloseArea())

	//-------------------------------------------------------------------
	// Restauro a area de trabalho
	//-------------------------------------------------------------------
	RestArea(aArea)

Return(.T.)

WSMETHOD POST WSSERVICE EJRep


	Local aArea		:= GetArea()
	//Local cSetResp  := ""
	Local oObj 		:= NIL
	Local cJSON 	:= Self:GetContent() 	// Pega a string do JSON que está sendo enviada
	Local aDadosRep := {} 					// Array para ExecAuto do MATA030
	Local cJsonRet 	:= ""
	Local cArqLog 	:= ""
	Local cErro 	:= ""
	Local cBuffer   := ""
	Local nX        := 0
	Local i         := 0

	Private lMsErroAuto
	Private lMsHelpAuto

	Conout("string do JSON -> " + cValToChar(cJSON))

	lMsErroAuto := .F.
	lMsHelpAuto := .F.

	//Cria o diretório para salvar os arquivos de log
	If !ExistDir("\ejecty_log")
		MakeDir("\ejecty_log")
	EndIf

	::SetContentType("application/json")

	//Deserializa a string JSON
	FWJsonDeserialize(cJson, @oObj)

	cJSONRet := '['

	For i:=1 to Len(oObj:REPRESENTANTES)

		cCNPJRepresentante   := oObj:REPRESENTANTES[i]:A3_CGC
		dbSelectArea("SA3")
		dbSetOrder(3)
		lAchou := (SA3->(DbSeek( xFilial("SA3") + cCNPJRepresentante )))

		If !lAchou

			//----------------------------------
			// Dados do Cliente
			//----------------------------------
			aAdd(aDadosRep,{"A3_FILIAL", 	xFilial("SA3")					  ,Nil})
			aAdd(aDadosRep,{"A3_COD", 		GetSxeNum("SA3","A3_COD")		  ,Nil})
			aAdd(aDadosRep,{"A3_NOME", 		oObj:REPRESENTANTES[i]:A3_NOME	  ,Nil})
			aAdd(aDadosRep,{"A3_NREDUZ", 	oObj:REPRESENTANTES[i]:A3_NREDUZ  ,Nil})
			aAdd(aDadosRep,{"A3_END",	 	oObj:REPRESENTANTES[i]:A3_END	  ,Nil})
			aAdd(aDadosRep,{"A3_ZZCOMP", 	oObj:REPRESENTANTES[i]:A3_ZZCOMP  ,Nil})
			aAdd(aDadosRep,{"A3_BAIRRO", 	oObj:REPRESENTANTES[i]:A3_BAIRRO  ,Nil})
			aAdd(aDadosRep,{"A3_MUN", 		oObj:REPRESENTANTES[i]:A3_MUN	  ,Nil})
			aAdd(aDadosRep,{"A3_CEP", 		oObj:REPRESENTANTES[i]:A3_CEP     ,Nil})
			aAdd(aDadosRep,{"A3_EST", 		oObj:REPRESENTANTES[i]:A3_EST	  ,Nil})
			aAdd(aDadosRep,{"A3_DDDTEL", 	oObj:REPRESENTANTES[i]:A3_DDDTEL  ,Nil})
			aAdd(aDadosRep,{"A3_TEL", 		oObj:REPRESENTANTES[i]:A3_TEL	  ,Nil})
			aAdd(aDadosRep,{"A3_CGC", 		oObj:REPRESENTANTES[i]:A3_CGC	  ,Nil})
			aAdd(aDadosRep,{"A3_INSCR", 	oObj:REPRESENTANTES[i]:A3_INSCR	  ,Nil})
			aAdd(aDadosRep,{"A3_EMAIL", 	oObj:REPRESENTANTES[i]:A3_EMAIL	  ,Nil})
			aAdd(aDadosRep,{"A3_PAIS", 		oObj:REPRESENTANTES[i]:A3_PAIS	  ,Nil})
			aAdd(aDadosRep,{"A3_DDI", 		oObj:REPRESENTANTES[i]:A3_DDI	  ,Nil})
			aAdd(aDadosRep,{"A3_DDDCEL", 	oObj:REPRESENTANTES[i]:A3_DDDCEL  ,Nil})
			aAdd(aDadosRep,{"A3_CEL", 		oObj:REPRESENTANTES[i]:A3_CEL	  ,Nil})
			aAdd(aDadosRep,{"A3_EMACORP", 	oObj:REPRESENTANTES[i]:A3_EMACORP ,Nil})
			aAdd(aDadosRep,{"A3_ZZOBS", 	oObj:REPRESENTANTES[i]:A3_ZZOBS	  ,Nil})
			aAdd(aDadosRep,{"A3_ZSTATUS", 	oObj:REPRESENTANTES[i]:A3_ZSTATUS ,Nil})
			aAdd(aDadosRep,{"A3_MSBLQL", 	oObj:REPRESENTANTES[i]:A3_MSBLQL  ,Nil})

			MSExecAuto({|x,y| MATA040(x,y)}, aDadosRep, 3)

			If lMsErroAuto

				RollBackSx8()

				cErro   := FwNoAccent(MostraErro("\ejecty_log", cArqLog))

				cBuffer  := ""
				nErrLin  := 1

				For nX := 1 To mlcount(cErro)

					cBuffer := RTrim(MemoLine(cErro,, nX,, .F.))

					If AllTrim(UPPER(SUBSTR(cBuffer, 1, 17))) == "MENSAGEM DO ERRO:"

						cErro := STRTRAN(SUBSTR(cBuffer, AT("[",cBuffer)+1, 100),"]","")

					EndIf

				Next nX

				cJSONRet += '{'
				cJSONRet += '"Cadastro": "' + StrZero(i,3) + '",'
				cJSONRet += '"Status": "Falha",'
				cJSONRet += '"Mensagem": "' + cErro + '"'
				cJSONRet += '}'

				If  i < Len(oObj:REPRESENTANTES)
					cJSONRet += ','
				EndIF
			Else

				dbSelectArea("SA3")
				dbSetOrder(3)
				(SA3->(DbSeek( xFilial("SA3") + cCNPJRepresentante )))

				cJSONRet += '{'
				cJSONRet += '"Cadastro": "' + StrZero(i,3) + '",'
				cJSONRet += '"Status": "SUCESSO",'
				cJSONRet += '"Mensagem": "Representante com CNPJ ' + cCNPJRepresentante + ' Cadastrado com Sucesso!",'
				cJSONRet += '"Codigo": "' + SA3->A3_COD + '",'
				cJSONRet += '"CNPJ": "' + cCNPJRepresentante + '"
				cJSONRet += '}'

				If  i < Len(oObj:REPRESENTANTES)
					cJSONRet += ','
				EndIF

				ConfirmSX8()

			EndIf

		Else

			cJSONRet += '{'
			cJSONRet += '"Cadastro": "' + StrZero(i,3) + '",'
			cJSONRet += '"Status": "Falha",'
			cJSONRet += '"Mensagem": "Representante com CNPJ ' + cCNPJRepresentante + ' Ja cadastrado",'
			cJSONRet += '"Codigo": "' + SA3->A3_COD + '",'
			cJSONRet += '"CNPJ": "' + cCNPJRepresentante + '"
			cJSONRet += '}'

			If  i < Len(oObj:REPRESENTANTES)
				cJSONRet += ','
			EndIF

		Endif

	Next

	cJSONRet += ']'
	//-------------------------------------------------------------------
	//Envia o JSON Gerado para a aplicação Cliente
	//-------------------------------------------------------------------
	::SetResponse( cJSONRet )

	//-------------------------------------------------------------------
	// Efetuo o fechamento da Tabela SA1
	//-------------------------------------------------------------------
	SA3->(dbCloseArea())

	//-------------------------------------------------------------------
	// Restauro a area de trabalho
	//-------------------------------------------------------------------
	RestArea(aArea)

Return(.T.)

