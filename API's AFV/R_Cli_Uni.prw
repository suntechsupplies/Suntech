#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"
#Include "Totvs.ch"

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
**********************************************************************************************/

#Define Desc_Rest 	"Serviço REST para Disponibilizar cadastro de Clientes"
#Define Desc_Get  	"Retorna o cliente informado de acordo com data de atualização do cadastro" 
#Define Desc_Post	"Cria o cadastro de cliente informado de acordo com data de atualização do cadastro"

user function r_Cli_Uni()

return

WSRESTFUL rcliGetPos DESCRIPTION Desc_Rest

	WSDATA nPag		As Integer
	WSDATA cTipo	As String
    WSDATA TENANTID AS STRING

	WSMETHOD GET  DESCRIPTION Desc_Get  WSSYNTAX "/rcliGetPos || /rcliGetPos/{}"
	WSMETHOD POST DESCRIPTION Desc_Post WSSYNTAX "/rcliGetPos/{Clientes}"	

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

WSMETHOD GET WSRECEIVE nPag, cTipo HEADERPARAM TENANTID WSSERVICE rCliGetPos

	Local aArea		:= GetArea()
	Local cAliasTmp	:= GetNextAlias()
	Local cSetResp
	Local nX
	Local nPagFim
	Local nPag		:= Self:nPag
	Local cTipo		:= Self:cTipo
	Local lRet		:= .T. 
	Local _cEmpresa	:= ""
	Local _cFilial	:= ""

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


	//*****************************************************************
	// Verifica se o parametro cTipo foi preenchido corretamente, e 
	// Caso nao tenha sido retorna erro
	//*****************************************************************
	If ! cTipo $ ("C|D")
	
		cSetResp 	:= '{ "TE_CLIENTE":[ "Retorno":"Reveja o conteudo do parametro cTipo !!!"] } '
		::SetResponse( cSetResp )
		RestArea(aArea) 		
		return(.t.)

	Endif
	
	//*****************************************************************
	//Verifica se há conexão em aberto, caso haja feche.
	//*****************************************************************
	IF Select(cAliasTmp) > 0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf

	
	If cTipo == "C"
		
		//************************************************************************
		//Select de cadastro de Clientes Completo
		//************************************************************************
		
		BeginSql Alias cAliasTmp 
		
			SELECT		ROW_NUMBER() OVER(ORDER BY A.R_E_C_N_O_ ) 				AS CONT 
						,((ROW_NUMBER() OVER (ORDER BY A.R_E_C_N_O_)) /10)+1	AS PAG
						,B.DUY_DESCRI
						,CASE A.A1_CONTATO	
							WHEN ''	THEN 'SEM DADOS'
							ELSE A.A1_CONTATO
						END AS A1_CONTATO
						,CASE A.A1_ZSTATU1	
							WHEN ' ' THEN 'SEM STATUS'
							WHEN '3' THEN 'INCLUSAO'
							WHEN '4' THEN 'ALTERACAO'
							WHEN '5' THEN 'EXCLUSAO'
							WHEN '9' THEN 'IMPORTADO'						
						END AS A1_ZSTATU1
						,A.* 		
			FROM  		%Table:SA1% A  
			LEFT JOIN 	%Table:DUY% B 
			ON 			A.A1_CDRDES 	= B.DUY_GRPVEN
			LEFT JOIN 	%Table:SA3% C 
			ON  		C.A3_COD 		= A.A1_VEND
			WHERE		A.%NotDel%
			AND			C.%NotDel%
				
		EndSQL
	
	Else

		//************************************************************************
		//Select de cadastro de Clientes Diferencial
		//************************************************************************
		BeginSql Alias cAliasTmp 
		
			SELECT		ROW_NUMBER() OVER(ORDER BY A.R_E_C_N_O_ ) 				AS CONT 
						,((ROW_NUMBER() OVER (ORDER BY A.R_E_C_N_O_)) /10)+1	AS PAG
						,B.DUY_DESCRI
						,CASE A.A1_CONTATO	
							WHEN ''	THEN 'SEM DADOS'
							ELSE A.A1_CONTATO
						END AS A1_CONTATO
						,CASE A.A1_ZSTATU1	
							WHEN ' ' THEN 'SEM STATUS'
							WHEN '3' THEN 'INCLUSAO'
							WHEN '4' THEN 'ALTERACAO'
							WHEN '5' THEN 'EXCLUSAO'
							WHEN '9' THEN 'IMPORTADO'						
						END AS A1_ZSTATU1
						,A.* 		
			FROM  		%Table:SA1% A  
			LEFT JOIN 	%Table:DUY% B 
			ON 			A.A1_CDRDES 	= B.DUY_GRPVEN
			LEFT JOIN 	%Table:SA3% C 
			ON  		C.A3_COD 		= A.A1_VEND
			WHERE		A.A1_ZSTATU1	<> '9'
			AND			A.%NotDel%
			AND			C.%NotDel%
				
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

		cSetResp 	:= '{ "TE_CLIENTE":[ "Retorno":"Nao Existe Itens Nessa Pagina"] } '
		lRet 		:= .F.

	Else

		//*************************************************************************
		// Seleciono a Tabela SA1 para efetuar a gravacao do Status de importado
		// campo A1_ZSTATU1
		//*************************************************************************
		SA1->(dbSelectArea("SA1"))
		SA1->(dbSetOrder(1))


		(cAliasTmp)->( DbGoTop() )  
		nX	:= 1
		cSetResp  := '{ "TE_CLIENTE":[ ' 
						
		While (cAliasTmp)->( !Eof() ) 
			
			//*************************************************************************
			// Efetua o preenchimento da resposta de acordo com o parametro cTipo
			//*************************************************************************
			If nPag == (cAliasTmp)->PAG  //.And. IIF(cTipo == "C",.T.,(cAliasTmp)->A1_ZSTATU1 <> '9') 
 			
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
				cSetResp  += '","EMAILCOPIAPEDIDO":"'		+ FwNoAccent(TRIM((cAliasTmp)->A1_EMAIL))
				cSetResp  += '","CODIGOVENDEDORESP":"'		+ TRIM((cAliasTmp)->A1_VEND)
				cSetResp  += '","CODIGOVENDEDORESP2":"'		+ TRIM((cAliasTmp)->A1_ZZVEND2)	
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
				cSetResp  += ',"STATUSREGISTRO":"'			+ TRIM((cAliasTmp)->A1_ZSTATU1)
				cSetResp  += '"}'

				//-------------------------------------------------------------------
				// Efetuo a gravacao do campo A1_ZSTATU1 com Status '9' = Importado
				//-------------------------------------------------------------------
				SA1->(dbGoTop())
				SA1->(dbSetOrder(1))
				If SA1->(dbSeek((cAliasTmp)->(A1_FILIAL + A1_COD + A1_LOJA)))
					
					RECLOCK("SA1",.F.)
					A1_ZSTATU1 := '9'
					SA1->(MsUnlock()) 
					
				Endif

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

	//*************************************************************************
	//Fecha a tabela
	//*************************************************************************
	(cAliasTmp)->(DbCloseArea())
	
	//*************************************************************************
	// Formata a String substituindo a / 
	//*************************************************************************
	cSetResp := UNESCAPE(cSetResp)
	While At('%2F',cSetResp) > 1
		cSetResp := strTran(cSetResp, "%2F", "/")
	EndDo
	
	//*************************************************************************
	//Envia o JSON Gerado para a aplicação Cliente	
	//*************************************************************************
	::SetResponse( cSetResp ) 		

	RestArea(aArea)		

Return(.T.)



WSMETHOD POST WSSERVICE rCliGetPos
	Local oObj 
	Local cJSON 		
	Local aDadosCli 	
	Local cFileLog 		
	Local cJsonRet 		
	Local cArqLog 		
	Local cErro 		
	Local cCodSA1 		
	Local lRet 			
	Local cTipo
	Local cAliasTmp
	Local cBuffer
	Local nX



	Private lMsErroAuto 
	Private lMsHelpAuto 

	cAliasTmp 	:= GetNextAlias()
	cJSON 		:= Self:GetContent() // Pega a string do JSON que está sendo enviada
	aDadosCli 	:= {} //Array para ExecAuto do MATA030
	cFileLog 	:= ""
	cJsonRet 	:= ""
	cArqLog 	:= ""
	cErro 		:= ""
	cCodSA1 	:= ""
	lRet 		:= .T.
	cTipo		:= ""
	oObj		:= NIL	 

	Conout("string do JSON -> " + cValToChar(cJSON))

	lMsErroAuto := .F.
	lMsHelpAuto := .F.
	//Cria o diretório para salvar os arquivos de log
	If !ExistDir("\log_cli")
		MakeDir("\log_cli")
	EndIf

	::SetContentType("application/json")

	//Deserializa a string JSON
	FWJsonDeserialize(cJson, @oObj)

	cCodSA1	:= GetSxeNum("SA1","A1_COD")
	dbSelectArea("SA1")
	dbSetOrder(3)
	//lAchou 		:= ( SA1->( DbSeek( xFilial("SA1") + oObj:CGCCPF ) ) )
	lAchou := .F.
	//cCodSA1 	:= GetSxeNum("SA1","A1_COD")	
	Conout("GetSxeNum -> " + cValToChar(cCodSA1))
	If !lAchou
		aDadosCli := {}

		//----------------------------------
		// Dados do Cliente
		//----------------------------------

		Conout("oObj -> " + cValToChar(oObj:RAZAOSOCIAL))

		aAdd(aDadosCli,{"A1_FILIAL" 	, xFilial("SA1")					   	,Nil})
		aAdd(aDadosCli,{"A1_COD" 		, cCodSA1								,Nil})
		aAdd(aDadosCli,{"A1_LOJA" 		, "01"									,Nil})
		aAdd(aDadosCli,{"A1_NOME" 		, oObj:RAZAOSOCIAL						,Nil})	
		aAdd(aDadosCli,{"A1_PESSOA" 	, "F"									,Nil})	
		aAdd(aDadosCli,{"A1_END" 		, oObj:ENDERECO							,Nil})
		aAdd(aDadosCli,{"A1_NREDUZ" 	, oObj:NOMEFANTASIA						,Nil})
		aAdd(aDadosCli,{"A1_TIPO" 		, "F" 			   						,Nil})
		aAdd(aDadosCli,{"A1_EST" 		, oObj:ESTADO							,Nil})
		aAdd(aDadosCli,{"A1_MUN" 		, oObj:MUNICIPIO						,Nil})
		//aAdd(aDadosCli,{"A1_XTIP" 	, oObj:CODIGOCANALCLIENTE				,Nil})
		aAdd(aDadosCli,{"A1_CGC" 		, oObj:CGCCPF		   					,Nil})
		aAdd(aDadosCli,{"A1_INSCRM"		, oObj:INSCRESTADUAL	   				,Nil})		
		aAdd(aDadosCli,{"A1_COD_MUN"	, SubStr(oObj:CODIGONOMECIDADE, 1,5 )	,Nil})		
		aAdd(aDadosCli,{"A1_BAIRRO" 	, oObj:BAIRRO			   				,Nil})
		aAdd(aDadosCli,{"A1_TEL" 		, oObj:TELEFONE		   					,Nil})
		aAdd(aDadosCli,{"A1_FAX" 		, oObj:FAX			   					,Nil})
		aAdd(aDadosCli,{"A1_CEP" 		, oObj:CEP			   					,Nil})
		aAdd(aDadosCli,{"A1_DTACAD" 	, oObj:DATACADASTRO	   					,Nil})
		aAdd(aDadosCli,{"A1_REGIAO" 	, oObj:CODIGOREGIAO	   					,Nil})
		aAdd(aDadosCli,{"A1_TABELA" 	, oObj:CODIGOTABPRECO   				,Nil})
		aAdd(aDadosCli,{"A1_OBS" 		, oObj:OBSCLIENTE	   					,Nil})
		aAdd(aDadosCli,{"A1_COND"		, oObj:CODIGOCONDPAGTO  				,Nil})
		aAdd(aDadosCli,{"A1_EMAIL" 		, oObj:EMAILCOPIAPEDIDO 				,Nil})
		aAdd(aDadosCli,{"A1_PAIS"   	, oObj:PAIS								,Nil})
		aAdd(aDadosCli,{"A1_CODPAIS"	, oObj:CODPAIS							,Nil})
		//aAdd(aDadosCli,{"A1_XSEGM"	, oObj:SEGUIMAFA						,Nil})
		aAdd(aDadosCli,{"A1_VEND"   	, oObj:CODIGOVENDEDORESP        		,Nil})
		//aAdd(aDadosCli,{"A1_AUTORIZ", oObj:AUTORIZ			        		,Nil})
		//aAdd(aDadosCli,{"A1_STATUS"	,oObj:CODIGOSTATUSCLI  					,Nil})
		aAdd(aDadosCli,{"A1_CONDENT"	,oObj:CONDICAOENTREGA  					,Nil})
		//aAdd(aDadosCli,{"" 			,oObj:CODIGOCLIENTEPAI 					,Nil})


		Conout("aDadosCli -> " + cValToChar(aDadosCli[4][2]))
		Conout("oObj -> " + cValToChar(oObj:RAZAOSOCIAL))

		MsExecAuto({|x,y| MATA030(x,y)}, aDadosCli, 3)

		If lMsErroAuto
			Conout("lMsErroAuto -> " + cValToChar(aDadosCli))
			RollBackSx8()
			cArqLog := oObj:RAZAOSOCIAL + " - " +Time()+ ".log"
			cErro   := FwNoAccent(MostraErro("\log_cli", cArqLog))

			cBuffer  := "" 
			nErrLin  := 1 
			cJSONRet := '{"status": "Falha","mensagem":'  

			For nX := 1 To mlcount(cErro)
				cBuffer := RTrim( MemoLine(cErro,, nX,, .F. )) 
				ConOut("erro antes do while " + cBuffer)
			Next nX

			While nErrLin <= mlcount(cErro)

				cBuffer := RTrim( MemoLine(cErro,, nErrLin,, .F. )) 
				IF cBuffer == "AJUDA:OBRIGAT"
					For nX := 1 To mlcount(cErro)

						ConOut("erro dentro do while " +cBuffer)

						If nX == 4

							cJSONRet +='"Campo obrigatorio nao foi preenchido ' + cBuffer + '"' // SubStr(cBuffer,1 ,At(".", cBuffer)) + '"'

						EndIf

						nErrLin++

						cBuffer := RTrim( MemoLine(cErro,, nErrLin,, .F. )) 	
					Next nX
				ElseIF cBuffer == "AJUDA:REGNOIS" //.And. (nErrLin == 1 .Or. nErrLin == 2 .Or. nErrLin == 4 )	

					For nX := 1 To mlcount(cErro)

						ConOut(cBuffer)

						If AllTrim(UPPER(SUBSTR(cBuffer, AT("<", cBuffer) + 4, 9))) == "INVALIDO"

							cJSONRet +='"Nao Existe Registro Relacionado a esse codigo, Campo ' + SUBSTR(cBuffer, 1, AT("-", cBuffer)-1 ) + '"' // SubStr(cBuffer,1 ,At(".", cBuffer)) + '"'

						EndIf

						nErrLin++

						cBuffer := RTrim( MemoLine(cErro,, nErrLin,, .F. )) 	
					Next nX
				ElseIF cBuffer == "AJUDA:REGBLOQ"
					For nX := 1 To mlcount(cErro)

						ConOut(cBuffer)

						If AllTrim(UPPER(SUBSTR(cBuffer, AT("<", cBuffer) + 4, 9))) == "INVALIDO"

							cJSONRet +='"Registro bloqueado para uso, Campo ' + SUBSTR(cBuffer, 1, AT("-", cBuffer)-1 ) + '"' // SubStr(cBuffer,1 ,At(".", cBuffer)) + '"'

						EndIf

						nErrLin++

						cBuffer := RTrim( MemoLine(cErro,, nErrLin,, .F. )) 	
					Next nX
				EndIF
				nErrLin++
			EndDo
			cJSONRet += ',"numeroIndetificador": "' + oObj:RAZAOSOCIAL + '"}'

			::SetResponse( cJSONRet )
			Return(.T.)
		Else
			//dbSelectArea("SA1")
			//dbSetOrder(3)
			//SA1->( DbSeek( xFilial("SA1") + oObj:CGCCPF ) )
			//Reclock("SA1",.F.)
			//SA1->A1_USERLGA := SA1->A1_USERLGI
			//MsUnlock()

			//cJSONRet := '{"status": "SUCESSO","mensagem": "Cliente Cadastrado","numeroIndetificador": "' + oObj:CGCCPF +'"}'
			cJSONRet := '{"status": "SUCESSO","mensagem": "Cliente Cadastrado","numeroIndetificador": "oObj:CGCCPF"}'
			ConfirmSX8() 
			::SetResponse( cJSONRet )
			Return(.T.)
		EndIf
	Else
		//cJSONRet := '{"status": "Falha","mensagem": "CPF/CNPJ Ja cadastrado","numeroIndetificador": "' + oObj:CGCCPF + '"}'
		cJSONRet := '{"status": "Falha","mensagem": "CPF/CNPJ Ja cadastrado","numeroIndetificador": "oObj:CGCCPF"}'
		::SetResponse( cJSONRet )
		Return(.T.)
	EndIf
	//	Next nZ
	::SetResponse( cJSONRet )
Return(.T.)

