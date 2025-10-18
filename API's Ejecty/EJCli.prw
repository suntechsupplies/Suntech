#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"
#Include "Totvs.ch"

/**********************************************************************************************
* Ejecty - Rest - Cliente
**********************************************************************************************/

#Define Desc_Rest 	"Serviço REST para Disponibilizar cadastro de Clientes"
#Define Desc_Get  	"Retorna o cliente informado de acordo com data de atualização do cadastro" 
#Define Desc_Post	"Cria o cadastro de cliente informado de acordo com data de atualização do Cadastro"
#Define Desc_Put	"Altera o cadastro de cliente informado de acordo com data de atualização do Cadastro"

User Function EJCli()

Return(.T.)

WSRESTFUL EJcliGP DESCRIPTION Desc_Rest

WSDATA nPag	 As Integer
WSDATA cTipo As String
WSDATA CGC	 As String

	WSMETHOD GET  DESCRIPTION Desc_Get  WSSYNTAX "/EJcliGP || /EJcliGP/{Clientes}"
	WSMETHOD POST DESCRIPTION Desc_Post WSSYNTAX "/EJcliGP/{Clientes}"
	WSMETHOD PUT  DESCRIPTION Desc_Put  WSSYNTAX "/EJcliGP"	

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

WSMETHOD GET WSRECEIVE nPag, cTipo WSSERVICE EJcliGP

	Local aArea		:= GetArea()
	Local cAliasTmp	:= GetNextAlias()
	Local cSetResp
	Local nX
	Local nPagFim
	Local nPag		:= Self:nPag
	Local cTipo		:= Self:cTipo
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

	If cTipo == "D"
		//Select de cadastro de Clientes conforme data de alteração
		BeginSql Alias cAliasTmp
		
			SELECT		 ROW_NUMBER() OVER(ORDER BY A.R_E_C_N_O_ ) 				AS CONT 
						,((ROW_NUMBER() OVER (ORDER BY A.R_E_C_N_O_)) /10)+1	AS PAG
						,B.DUY_DESCRI
						,CASE A.A1_CONTATO	WHEN ''
							THEN 'SEM DADOS'
							ELSE A.A1_CONTATO
						END A1_CONTATO
						,A.*
						,A.D_E_L_E_T_ 											AS DEL
						,C.* 		
			FROM  		%Table:SA1% A  
			LEFT JOIN 	%Table:DUY% B 
			ON 			B.DUY_GRPVEN	= A.A1_CDRDES
			AND			B.DUY_FILIAL	= A.A1_FILIAL
			AND			B.%NotDel%
			LEFT JOIN 	%Table:SA3% C 
			ON  		C.A3_COD 		= A.A1_VEND
			AND			C.A3_FILIAL		= A.A1_FILIAL
			AND			C.%NotDel%
			WHERE 		A.A1_ZSTATUS 	<> '9'
			AND         A.%NotDel%
			ORDER BY PAG	
		EndSQL

	Elseif cTipo == "C"

		//Select de cadastro de Clientes completo
		BeginSql Alias cAliasTmp
		
			SELECT		 ROW_NUMBER() OVER(ORDER BY A.R_E_C_N_O_ ) 				AS CONT 
						,((ROW_NUMBER() OVER (ORDER BY A.R_E_C_N_O_)) /10)+1	AS PAG
						,B.DUY_DESCRI
						,CASE A.A1_CONTATO	WHEN ''
							THEN 'SEM DADOS'
							ELSE A.A1_CONTATO
						END A1_CONTATO
						,A.*
						,A.D_E_L_E_T_ 											AS DEL
						,C.* 		
			FROM  		%Table:SA1% A  
			LEFT JOIN 	%Table:DUY% B 
			ON 			B.DUY_GRPVEN	= A.A1_CDRDES
			AND			B.DUY_FILIAL	= A.A1_FILIAL
			AND			B.%NotDel%
			LEFT JOIN 	%Table:SA3% C 
			ON  		C.A3_COD 		= A.A1_VEND
			AND			C.A3_FILIAL		= A.A1_FILIAL
			AND			C.%NotDel%
			WHERE 		A.A1_ZSTATUS 	<> '9'
			AND         A.%NotDel%
			ORDER BY PAG
		EndSQL

	Endif

	dbSelectArea(cAliasTmp)
	(cAliasTmp)->( DBGoTop() )

	While (cAliasTmp)->( !Eof() )
		nPagFim		:= (cAliasTmp)->PAG
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->( DbGoTop() )

	If (cAliasTmp)->( Eof() )

		cSetResp 	:= '{ "clientes":[ "Retorno":"Nao Existe Itens Nessa Pagina"] } '
		lRet 		:= .F.

	Else

		(cAliasTmp)->( DbGoTop() )
		nX	:= 1
		cSetResp  := '{ "clientes":[ '

		//------------------------------------------------------------------------
		// Seleciono a Tabela SA1 para efetuar a gravacao do Status de importado
		// campo A1_ZSTATUS
		//------------------------------------------------------------------------
		SA1->(dbSelectArea("SA1"))
		SA1->(dbSetOrder(1))
		While (cAliasTmp)->( !Eof() )
			If nPag == (cAliasTmp)->PAG

				If nX > 1
					cSetResp  +=' , '
				EndIf
				cSetResp  += '{'
				cSetResp  += '"REGISTRO":'					+ ALLTRIM(STR((cAliasTmp)->CONT))
				cSetResp  += ',"CODIGOCLIENTE":"'			+ TRIM((cAliasTmp)->A1_FILIAL) + TRIM((cAliasTmp)->A1_COD +(cAliasTmp)->A1_LOJA)
				cSetResp  += '","CODIGOCANALCLIENTE":"'		+ TRIM((cAliasTmp)->A1_GRPVEN)
				cSetResp  += '","RAZAOSOCIAL":"'			+ FwNoAccent(TRIM((cAliasTmp)->A1_NOME))
				cSetResp  += '","CGCCPF":"'					+ TRIM(((cAliasTmp)->A1_CGC ))
				cSetResp  += '","INSCRESTADUAL":"'			+ TRIM((cAliasTmp)->A1_INSCR)
				cSetResp  += '","INSCRMUNICIPAL":"'			+ TRIM((cAliasTmp)->A1_INSCRM)
				cSetResp  += '","ENDERECO":"'				+ FwNoAccent(STRTran(STRTran(STRTran( TRIM((cAliasTmp)->A1_END)	, '"', ''),'\','-'),'/','-'))
				cSetResp  += '","ENDERECOENTREGA":"'		+ STRTran(STRTran(STRTran( TRIM((cAliasTmp)->A1_ENDENT)	, '"', ''),'\','-'),'/','-')
				cSetResp  += '","CODIGOENDERECO":"'			+ '01'
				cSetResp  += '","ESTADO":"' 				+ TRIM((cAliasTmp)->A1_EST)
				cSetResp  += '","BAIRRO":"'					+ FwNoAccent(TRIM((cAliasTmp)->A1_BAIRRO))
				cSetResp  += '","TELEFONE":"'				+ TRIM(((cAliasTmp)->A1_TEL))
				cSetResp  += '","FAX":"'					+ TRIM(((cAliasTmp)->A1_FAX))
				cSetResp  += '","CEP":"'					+ TRIM(((cAliasTmp)->A1_CEP))
				cSetResp  += '","CODIGOSTATUSCLI":"'		+ TRIM(IIF((cAliasTmp)->A1_MSBLQL == "1" ,'B','A'))
				cSetResp  += '","CODIGONOMECIDADE":"' 		+ TRIM((ALLTRIM((cAliasTmp)->A1_EST))) + TRIM((ALLTRIM((cAliasTmp)->A1_COD_MUN)))
				cSetResp  += '","PAIS":"' 					+ FwNoAccent(TRIM((cAliasTmp)->A1_PAIS))
				cSetResp  += '","CODPAIS":"' 				+ TRIM((cAliasTmp)->A1_CODPAIS)
				cSetResp  += '","MUNICIPIO":"'				+ FwNoAccent(TRIM((cAliasTmp)->A1_MUN))
				cSetResp  += '","DDDW":"'					+ ALLTRIM(STR((cAliasTmp)->A1_ZZDDDW))
				cSetResp  += '","TELW":"'					+ TRIM(((cAliasTmp)->A1_TELW))
				cSetResp  += '","COMPLEMENTO":"'			+ FwNoAccent(STRTran(STRTran(STRTran( TRIM((cAliasTmp)->A1_COMPLEM), '"', ''),'\','-'),'/','-'))
				cSetResp  += '","NOMEFANTASIA":"'			+ FwNoAccent(TRIM((cAliasTmp)->A1_NREDUZ ))
				cSetResp  += '","DATACADASTRO":"'			+ TRIM(((cAliasTmp)->A1_PRICOM))
				cSetResp  += '","CODIGOREGIAO":"' 			+ TRIM(((cAliasTmp)->A1_REGIAO))
				cSetResp  += '","DESCRICAODIGOREGIAO":"' 	+ FwNoAccent(TRIM((cAliasTmp)->DUY_DESCRI))
				cSetResp  += '","FORMADEPAGAMENTO":"'		+ TRIM((cAliasTmp)->A1_TPFRET)
				cSetResp  += '","CODIGOTABPRECO":"'			+ TRIM((cAliasTmp)->A1_TABELA)
				cSetResp  += '","OBSCLIENTE":"' 			+ FwNoAccent(STRTran(STRTran(STRTran( TRIM((cAliasTmp)->A1_OBSERV), '"', ''),'\','-'),'/','-'))
				cSetResp  += '","CODIGOCONDPAGTO":"' 		+ TRIM((cAliasTmp)->A1_COND)
				cSetResp  += '","CODIGOCLIENTEPAI":"'		+ TRIM((cAliasTmp)->A1_COD)
				cSetResp  += '","EMAILCOPIAPEDIDO":"'		+ FwNoAccent(TRIM((cAliasTmp)->A1_ZZMAIL2))
				cSetResp  += '","CODIGOVENDEDORESP":"'		+ TRIM((cAliasTmp)->A1_VEND)
				cSetResp  += '","NOMEVENDEDORESP":"'		+ TRIM((cAliasTmp)->A3_NOME)
				cSetResp  += '","EMAILVENDEDORESP":"'		+ TRIM((cAliasTmp)->A3_EMAIL)
				cSetResp  += '","CODIGOVENDEDORESP2":"'		+ TRIM((cAliasTmp)->A1_ZZVEND2)
				cSetResp  += '","NOMEVENDEDORESP2":"'		+ TRIM(Posicione("SA3",1,FwFilial("SA3")+(cAliasTmp)->A1_ZZVEND2,"A3_NOME"))
				cSetResp  += '","EMAILVENDEDORESP2":"'		+ TRIM(Posicione("SA3",1,FwFilial("SA3")+(cAliasTmp)->A1_ZZVEND2,"A3_EMAIL"))
				cSetResp  += '","ATIVIDADE":"'				+ TRIM((cAliasTmp)->A1_ATIVIDA)
				cSetResp  += '","SUFRAMA":"'				+ IIF(!EMPTY(TRIM((cAliasTmp)->A1_SUFRAMA)) ,'1','2')
				cSetResp  += '","CONTRIBICMS":"'			+ TRIM((cAliasTmp)->A1_CONTRIB)
				cSetResp  += '","DESCONTOSUF":"'			+ TRIM((cAliasTmp)->A1_CALCSUF)
				cSetResp  += '","CODIGOGRUPOTRIB":"'		+ TRIM((cAliasTmp)->A1_GRPTRIB)
				cSetResp  += '","EXPORTACAO":"'				+ IIF(TRIM((cAliasTmp)->A1_EST)= 'EX','1','2')
				cSetResp  += '","FORMAPGTO":"'				+ TRIM("")
				cSetResp  += '","LIMITECREDITO":'			+ ALLTRIM(STR((cAliasTmp)->A1_LC))
				cSetResp  += ',"LIMITEDISPONIVEL":'			+ ALLTRIM(STR(((cAliasTmp)->A1_LC - (cAliasTmp)->A1_SALDUP)))
				cSetResp  += ',"CODIGOEMPRESAESP":"'		+ TRIM("")
				cSetResp  += '","NOMECONTATO":"'			+ FwNoAccent(STRTran(STRTran(STRTran( TRIM((cAliasTmp)->A1_CONTATO), '"', ''),'\','-'),'/','-'))
				cSetResp  += '","CARGO":"'					+ FwNoAccent(TRIM((cAliasTmp)->A1_CARGO1))
				cSetResp  += '","EMAIL":"'					+ FwNoAccent(TRIM((cAliasTmp)->A1_EMAIL))
				cSetResp  += '","TRANSP":"'					+ TRIM((cAliasTmp)->A1_TRANSP)
				cSetResp  += '","ULTCOMPRA":"'				+ TRIM((cAliasTmp)->A1_ULTCOM)
				cSetResp  += '","DESCONTOCLIENTE":'			+ TRIM(cValToChar((cAliasTmp)->A1_DESC))
				cSetResp  += ',"LIBERADOB2B":"'				+ TRIM((cAliasTmp)->A1_ZZLB2B)
				cSetResp  += '","GRUPOVENDAS":"'            + TRIM(Posicione("ACY",1,FwFilial("ACY")+(cAliasTmp)->A1_GRPVEN,"ACY_DESCRI"))
				cSetResp  += '","STATUS":"'					+ TRIM((cAliasTmp)->A1_ZSTATUS)
				cSetResp  += '","DELETEDPROTHEUS":"'		+ IIF((cAliasTmp)->DEL = "*", "DELETADO","ATIVO")
				cSetResp  += '","NOMEDAREDE":"'				+ TRIM((cAliasTmp)->A1_ZZREDE)
				cSetResp  += '"}'

				//-------------------------------------------------------------------
				// Efetuo a gravacao do campo A1_ZSTATUS com Status '9' = Importado
				//-------------------------------------------------------------------
				//SA1->(dbGoTop())
				//If SA1->(dbSeek((cAliasTmp)->(A1_FILIAL + A1_COD + A1_LOJA)))
				//
				//	RECLOCK("SA1",.F.)
				//		A1_ZSTATUS := '9'
				//	SA1->(MsUnlock())
				//
				//Endif

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
	SA1->(dbCloseArea())

	//-------------------------------------------------------------------
	// Restauro a area de trabalho
	//-------------------------------------------------------------------
	RestArea(aArea)

Return(.T.)

WSMETHOD POST WSSERVICE EJcliGP

	Local aArea		:= GetArea()
	//Local cSetResp  := ""
	Local oObj 		:= NIL
	Local cJSON 	:= Self:GetContent() 	// Pega a string do JSON que está sendo enviada
	Local aDadosCli := {} 					// Array para ExecAuto do MATA030
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

	For i:=1 to Len(oObj:CLIENTE)

		cCGC   := oObj:CLIENTE[i]:A1_CGC
		dbSelectArea("SA1")
		dbSetOrder(3)
		lAchou := (SA1->(DbSeek( xFilial("SA1") + cCGC )))

		If !lAchou

			//----------------------------------
			// Dados do Cliente
			//----------------------------------
			aAdd(aDadosCli,{"A1_FILIAL" 	, xFilial("SA1")					   	,Nil})
			aAdd(aDadosCli,{"A1_COD" 		, GetSxeNum("SA1","A1_COD")				,Nil})
			aAdd(aDadosCli,{"A1_LOJA" 		, oObj:CLIENTE[i]:A1_LOJA				,Nil})
			aAdd(aDadosCli,{"A1_NOME" 		, oObj:CLIENTE[i]:A1_NOME				,Nil})
			aAdd(aDadosCli,{"A1_PESSOA" 	, oObj:CLIENTE[i]:A1_PESSOA				,Nil})
			aAdd(aDadosCli,{"A1_END" 		, oObj:CLIENTE[i]:A1_END				,Nil})
			aAdd(aDadosCli,{"A1_COMPLEM"	, oObj:CLIENTE[i]:A1_COMPLEM			,Nil})
			aAdd(aDadosCli,{"A1_NREDUZ" 	, oObj:CLIENTE[i]:A1_NREDUZ				,Nil})
			aAdd(aDadosCli,{"A1_TIPO" 		, oObj:CLIENTE[i]:A1_TIPO				,Nil})
			aAdd(aDadosCli,{"A1_EST" 		, oObj:CLIENTE[i]:A1_EST				,Nil})
			aAdd(aDadosCli,{"A1_MUN" 		, oObj:CLIENTE[i]:A1_MUN				,Nil})
			aAdd(aDadosCli,{"A1_CGC" 		, cCGC     								,Nil})
			aAdd(aDadosCli,{"A1_INSCR"		, oObj:CLIENTE[i]:A1_INSCR   			,Nil})
			aAdd(aDadosCli,{"A1_INSCRM"		, oObj:CLIENTE[i]:A1_INSCRM	   			,Nil})
			aAdd(aDadosCli,{"A1_COD_MUN"	, oObj:CLIENTE[i]:A1_COD_MUN	        ,Nil})
			aAdd(aDadosCli,{"A1_BAIRRO" 	, oObj:CLIENTE[i]:A1_BAIRRO			   	,Nil})
			aAdd(aDadosCli,{"A1_DDD" 		, oObj:CLIENTE[i]:A1_DDD	   			,Nil})
			aAdd(aDadosCli,{"A1_TEL" 		, oObj:CLIENTE[i]:A1_TEL	   			,Nil})
			aAdd(aDadosCli,{"A1_ZZDDDW"		, VAL(oObj:CLIENTE[i]:A1_ZZDDDW)		,Nil})
			aAdd(aDadosCli,{"A1_TELW" 		, oObj:CLIENTE[i]:A1_TELW	   			,Nil})
			aAdd(aDadosCli,{"A1_FAX" 		, oObj:CLIENTE[i]:A1_FAX			   	,Nil})
			aAdd(aDadosCli,{"A1_CEP" 		, oObj:CLIENTE[i]:A1_CEP			   	,Nil})
			aAdd(aDadosCli,{"A1_HRCAD" 	    , SubStr(Time(), 1, 5)      			,Nil})
			aAdd(aDadosCli,{"A1_DTCAD" 	    , dDatabase	 							,Nil})
			aAdd(aDadosCli,{"A1_REGIAO" 	, oObj:CLIENTE[i]:A1_REGIAO   			,Nil})
			aAdd(aDadosCli,{"A1_TABELA" 	, oObj:CLIENTE[i]:A1_TABELA   			,Nil})
			aAdd(aDadosCli,{"A1_OBS" 		, oObj:CLIENTE[i]:A1_OBS	   			,Nil})
			aAdd(aDadosCli,{"A1_COND"		, oObj:CLIENTE[i]:A1_COND 				,Nil})
			aAdd(aDadosCli,{"A1_EMAIL" 		, oObj:CLIENTE[i]:A1_EMAIL 				,Nil})
			aAdd(aDadosCli,{"A1_PAIS"   	, oObj:CLIENTE[i]:A1_PAIS				,Nil})
			aAdd(aDadosCli,{"A1_CODPAIS"	, oObj:CLIENTE[i]:A1_CODPAIS			,Nil})
			aAdd(aDadosCli,{"A1_VEND"   	, oObj:CLIENTE[i]:A1_VEND        		,Nil})
			aAdd(aDadosCli,{"A1_GRPTRIB"   	, oObj:CLIENTE[i]:A1_GRPTRIB       		,Nil})
			aAdd(aDadosCli,{"A1_CONTRIB"   	, oObj:CLIENTE[i]:A1_CONTRIB       		,Nil})
			aAdd(aDadosCli,{"A1_GRPVEN"   	, oObj:CLIENTE[i]:A1_GRPVEN       		,Nil})
			aAdd(aDadosCli,{"A1_CONTATO"   	, oObj:CLIENTE[i]:A1_CONTATO       		,Nil})
			aAdd(aDadosCli,{"A1_ZZLB2B"		, oObj:CLIENTE[i]:A1_ZZLB2B	  			,Nil})		// 1=SIM ; 2=NAO

			//MsExecAuto({|x,y| MATA030(x,y)}, aDadosCli, 3)
			MSExecAuto({|a,b,c| CRMA980(a,b,c)},aDadosCli,3)

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

				If  i < Len(oObj:CLIENTE)
					cJSONRet += ','
				EndIF
			Else

				dbSelectArea("SA1")
				dbSetOrder(3)
				(SA1->(DbSeek( xFilial("SA1") + cCGC )))

				cJSONRet += '{'
				cJSONRet += '"Cadastro": "' + StrZero(i,3) + '",'
				cJSONRet += '"Status": "SUCESSO",'
				cJSONRet += '"Mensagem": "Cliente com CPF/CNPJ ' + cCGC + ' Cadastrado com Sucesso!",'
				cJSONRet += '"Codigo": "' + SA1->A1_COD + '",'
				cJSONRet += '"Loja": "' + SA1->A1_LOJA + '"
				cJSONRet += '}'

				If  i < Len(oObj:CLIENTE)
					cJSONRet += ','
				EndIF

				ConfirmSX8()

			EndIf

		Else

			cJSONRet += '{'
			cJSONRet += '"Cadastro": "' + StrZero(i,3) + '",'
			cJSONRet += '"Status": "Falha",'
			cJSONRet += '"Mensagem": "Cliente com CPF/CNPJ ' + cCGC + ' Ja cadastrado",'
			cJSONRet += '"Codigo": "' + SA1->A1_COD + '",'
			cJSONRet += '"Loja": "' + SA1->A1_LOJA + '"
			cJSONRet += '}'

			If  i < Len(oObj:CLIENTE)
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
	SA1->(dbCloseArea())

	//-------------------------------------------------------------------
	// Restauro a area de trabalho
	//-------------------------------------------------------------------
	RestArea(aArea)

Return(.T.)

WSMETHOD PUT WSRECEIVE RECEIVE WSSERVICE EJcliGP

	Local cJSON      := Self:GetContent() // –> Pega a string do JSON
	Local cCGC       := Self:CGC // –> Pega o parâmetro recebido pela URL
	Local lRet       := .T.
	Local oObj 		 := Nil
	Local aDadosCli  := {} //–> Array para ExecAuto do MATA030
	Local cJsonRet   := ""
	Local cErro      := ""
	Local cArqLog 	 := ""
	Local nX		 := 0
	Local aArea 	 := GetArea()

	Private lMsErroAuto := .F.

	If !ExistDir("\log_cli")
		MakeDir("\log_cli")
	EndIf

	::SetContentType("application/json")

	// –> Deserializa a string JSON
	FWJsonDeserialize(cJson, @oObj)

	dbSelectArea("SA1")
	dbSetOrder(3)
	lAchou := SA1->(DbSeek( xFilial("SA1") + cCGC ))

	If lAchou

		aAdd(aDadosCli,{"A1_COD"      , SA1->A1_COD                 ,Nil}) // Codigo
		aAdd(aDadosCli,{"A1_LOJA"     , SA1->A1_LOJA                ,Nil}) // Loja
		aAdd(aDadosCli,{"A1_CGC" 	  , cCGC						,Nil})
		aAdd(aDadosCli,{"A1_NOME" 	  , oObj:CLIENTE:A1_NOME		,Nil})
		aAdd(aDadosCli,{"A1_NREDUZ"   , oObj:CLIENTE:A1_NREDUZ		,Nil})
		aAdd(aDadosCli,{"A1_EMAIL" 	  , oObj:CLIENTE:A1_EMAIL 		,Nil})
		aAdd(aDadosCli,{"A1_DDD" 	  , oObj:CLIENTE:A1_DDD	   		,Nil})
		aAdd(aDadosCli,{"A1_TEL" 	  , oObj:CLIENTE:A1_TEL	   		,Nil})
		aAdd(aDadosCli,{"A1_ZZDDDW"	  , VAL(oObj:CLIENTE:A1_ZZDDDW)	,Nil})
		aAdd(aDadosCli,{"A1_TELW" 	  , oObj:CLIENTE:A1_TELW	   	,Nil})
		aAdd(aDadosCli,{"A1_CEP" 	  , oObj:CLIENTE:A1_CEP			,Nil})
		aAdd(aDadosCli,{"A1_END" 	  , oObj:CLIENTE:A1_END			,Nil})
		aAdd(aDadosCli,{"A1_BAIRRO"   , oObj:CLIENTE:A1_BAIRRO		,Nil})
		aAdd(aDadosCli,{"A1_COMPLEM"  , oObj:CLIENTE:A1_COMPLEM		,Nil})
		aAdd(aDadosCli,{"A1_COD_MUN"  , oObj:CLIENTE:A1_COD_MUN		,Nil})
		aAdd(aDadosCli,{"A1_MUN" 	  , oObj:CLIENTE:A1_MUN			,Nil})
		aAdd(aDadosCli,{"A1_EST" 	  , oObj:CLIENTE:A1_EST			,Nil})
		aAdd(aDadosCli,{"A1_CONTATO"  , oObj:CLIENTE:A1_CONTATO   	,Nil})
		aAdd(aDadosCli,{"A1_ZZLB2B"   , oObj:CLIENTE:A1_ZZLB2B   	,Nil})
		aAdd(aDadosCli,{"A1_HRCAD" 	  , SubStr(Time(), 1, 5)      	,Nil})
		aAdd(aDadosCli,{"A1_DTCAD" 	  , dDatabase	 	    		,Nil})

		//MsExecAuto({|x,y| MATA030(x,y)}, aDadosCli, 4)
		MSExecAuto({|a,b,c| CRMA980(a,b,c)},aDadosCli,4)

		If lMsErroAuto

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
			cJSONRet += '"Status": "FALHA",'
			cJSONRet += '"Mensagem": "' + cErro + '"'
			cJSONRet += '}'

			SetRestFault(400, cErro)

			lRet := .F.

		Else

			cJSONRet += '{'
			cJSONRet += '"Status": "SUCESSO",'
			cJSONRet += '"Mensagem": "Cliente com CPF/CNPJ ' + cCGC + ' Alterado com Sucesso!",'
			cJSONRet += '"Codigo": "' + SA1->A1_COD + '",'
			cJSONRet += '"Loja": "' + SA1->A1_LOJA + '"
			cJSONRet += '}'

			::SetResponse( cJSONRet )

			lRet := .T.

		EndIf

	Else

		SetRestFault(400, "Cliente não encontrado.")

		lRet := .F.

	EndIf

	//-------------------------------------------------------------------
	// Efetuo o fechamento da Tabela SA1
	//-------------------------------------------------------------------
	SA1->(dbCloseArea())

	//-------------------------------------------------------------------
	// Restauro a area de trabalho
	//-------------------------------------------------------------------
	RestArea(aArea)

Return(lRet)

Static Function TrataErro(cErroAuto)

	Local nLines   := MLCount(cErroAuto)
	Local cNewErro := ""
	Local nErr     := 0

	For nErr := 1 To nLines
		cNewErro += AllTrim( MemoLine( cErroAuto, , nErr ) ) + " - "
	Next nErr

Return(cNewErro)
