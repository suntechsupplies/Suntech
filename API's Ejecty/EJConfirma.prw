#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"
#Include "Totvs.ch"

/**********************************************************************************************
* Ejecty - Rest - Cliente
**********************************************************************************************/

#Define Desc_Rest 	"Serviço REST para Confirmar a gravaçao de dados em tabela de terceiros"
//#Define Desc_Get  	"Retorna o cliente informado de acordo com data de atualizaçao do cadastro" 
#Define Desc_Post	"Confirma que uma determinada tabela teve seus registros gravados na tabela de terceiros"

User Function EJConfirma()

Return(.T.)

WSRESTFUL EJConfirma DESCRIPTION Desc_Rest

WSDATA nPag		As Integer
WSDATA cTipo	As String

	WSMETHOD GET  DESCRIPTION Desc_Get  WSSYNTAX "/EJConfirma || /EJConfirma/{}"
	WSMETHOD POST DESCRIPTION Desc_Post WSSYNTAX "/EJConfirma/{Dados}"	

END WSRESTFUL


/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Antonio Ricardo de Araujo                                                           *  
* Apos a gravaçao dos dados na base da Ejecty, um POST é enviado para o banco Suntech para    *
* Confirmaçao de que os dados foram gravados no banco de destino, qualquer modificaçao deve   *
* ser confirmada atraves dessa API	                                                          *
* @since 	20/01/2023                                                                        *
* @version undefined                                                                          *
* @param oSelf, object, Objeto contendo dados da requisiçao efetuada pelo cliente, tais como: *
*    - Parâmetros querystring (parâmetros informado via URL)                                  *
*    - Objeto JSON caso o requisiçao seja efetuada via Request Post                           *
*    - Header da requisiçao                                                                   *
*    - entre outras ...                                                                       *
* @type Method                                                                                *
**********************************************************************************************/

WSMETHOD GET WSRECEIVE nPag, cTipo WSSERVICE EJconfirma

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

	//Verifica se há conexao em aberto, caso haja feche.
	IF Select(cAliasTmp)>0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf

	If cTipo == "D"
		//Select de cadastro de Clientes conforme data de alteraçao
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
				cSetResp  += '","EMAIL":"'					+ FwNoAccent(TRIM((cAliasTmp)->A1_ZZMAIL2)) 
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
				SA1->(dbGoTop())
				If SA1->(dbSeek((cAliasTmp)->(A1_FILIAL + A1_COD + A1_LOJA)))
					
					RECLOCK("SA1",.F.)
						A1_ZSTATUS := '9'
					SA1->(MsUnlock()) 
					
				Endif

				(cAliasTmp)->(dbSkip())
				nX++
				
			Else
				(cAliasTmp)->(dbSkip())
			Endif
		EndDo

		// Caso nao esteja em EOF()
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
	//Envia o JSON Gerado para a aplicaçao Cliente
	//-------------------------------------------------------------------	
	::SetResponse( cSetResp ) 		
	
	//-------------------------------------------------------------------
	// Efetuo o fechamento da Tabela SA1
	//-------------------------------------------------------------------
	//SA1->(dbCloseArea())
	
	//-------------------------------------------------------------------
	// Restauro a area de trabalho
	//-------------------------------------------------------------------
	RestArea(aArea)		

Return(.T.)

WSMETHOD POST WSSERVICE EJConfirma
	
	Local aArea	   := GetArea()
	Local oObj 	   := NIL	
	Local cJSON    := Self:GetContent() 	// Pega a string do JSON que está sendo enviada
	Local _cFilial := ""	
	Local cCliente := ""
	Local cLoja    := ""    				// Array para ExecAuto do MATA030	
	Local cPrefixo := ""
	Local cNum     := ""
	Local cParcela := ""
	Local cTipo    := ""
	Local cDoc     := ""
	Local cSerie   := ""
	Local cEspecie := ""
	Local cJsonRet := ""
	Local cProduto := ""	
	Local i        := 0

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

	If oObj:CONFIRMACAO[1]:TABELA == 'SA1'

		dbSelectArea("SA1")
		dbSetOrder(1)

		For i:=1 To Len(oObj:CONFIRMACAO[1]:DADOS)		

			cCliente := oObj:CONFIRMACAO[1]:DADOS[i]:A1_COD
			cLoja    := oObj:CONFIRMACAO[1]:DADOS[i]:A1_LOJA

			If MsSeek(xFilial("SA1") + cCliente + cLoja )

				//Gravo informações na SA1
				SA1->(Reclock("SA1", .F.))
					SA1->A1_ZSTATUS := oObj:CONFIRMACAO[1]:DADOS[i]:A1_ZSTATUS //Integrado
				SA1->(MsUnlock())
				SA1->(Dbskip())

				cJSONRet += '{'
				cJSONRet += '"Item": "' + StrZero(i,3) + '",'
				cJSONRet += '"Status": "200",'
				cJSONRet += '"Mensagem": "Cadastro atualizado com sucesso!",'
				cJSONRet += '"Codigo": "' + cCliente + '",' 
				cJSONRet += '"Loja": "'   + cLoja    + '"
				cJSONRet += '}'

			Else
				
				cJSONRet += '{'
				cJSONRet += '"Item": "' + StrZero(i,3) + '",'
				cJSONRet += '"Status": "404",'
				cJSONRet += '"Mensagem": "Chave nao encontrada!",'
				cJSONRet += '"Codigo": "' + cCliente + '",' 
				cJSONRet += '"Loja": "'   + cLoja    + '"
				cJSONRet += '}'

			EndIf

			If  i < Len(oObj:CONFIRMACAO[1]:DADOS)
				cJSONRet += ','
			EndIF

		Next
	ElseIf oObj:CONFIRMACAO[1]:TABELA == 'SA3'

		dbSelectArea("SA3")
		dbSetOrder(3)

		For i:=1 To Len(oObj:CONFIRMACAO[1]:DADOS)		

			cCNPJRepresentante := oObj:CONFIRMACAO[1]:DADOS[i]:A3_CGC
			
			If MsSeek(xFilial("SA3") + cCNPJRepresentante )

				//Gravo informações na SA1
				SA3->(Reclock("SA3", .F.))
					SA3->A3_ZSTATUS := oObj:CONFIRMACAO[1]:DADOS[i]:A3_ZSTATUS //Integrado
				SA3->(MsUnlock())
				SA3->(Dbskip())

				cJSONRet += '{'
				cJSONRet += '"Item": "' + StrZero(i,3) + '",'
				cJSONRet += '"Status": "200",'
				cJSONRet += '"Mensagem": "Cadastro atualizado com sucesso!",'
				cJSONRet += '"CNPJ": "' + cCNPJRepresentante + '"' 
				cJSONRet += '}'

			Else
				
				cJSONRet += '{'
				cJSONRet += '"Item": "' + StrZero(i,3) + '",'
				cJSONRet += '"Status": "404",'
				cJSONRet += '"Mensagem": "Chave nao encontrada!",'
				cJSONRet += '"Codigo": "' + cCNPJRepresentante + '"' 
				cJSONRet += '}'

			EndIf

			If  i < Len(oObj:CONFIRMACAO[1]:DADOS)
				cJSONRet += ','
			EndIF

		Next

	ElseIf oObj:CONFIRMACAO[1]:TABELA == 'SE1'

		dbSelectArea("SE1")
		dbSetOrder(1)

		For i:=1 To Len(oObj:CONFIRMACAO[1]:DADOS)

			_cFilial := padr(oObj:CONFIRMACAO[1]:DADOS[i]:E1_FILIAL,GetSX3Cache("E1_FILIAL", "X3_TAMANHO")) //oObj:CONFIRMACAO[1]:DADOS[i]:E1_FILIAL 
			cPrefixo := padr(oObj:CONFIRMACAO[1]:DADOS[i]:E1_PREFIXO,GetSX3Cache("E1_PREFIXO", "X3_TAMANHO")) //oObj:CONFIRMACAO[1]:DADOS[i]:E1_PREFIXO
			cNum     := padr(oObj:CONFIRMACAO[1]:DADOS[i]:E1_NUM,GetSX3Cache("E1_NUM", "X3_TAMANHO")) //oObj:CONFIRMACAO[1]:DADOS[i]:E1_NUM
			cParcela := padr(oObj:CONFIRMACAO[1]:DADOS[i]:E1_PARCELA,GetSX3Cache("E1_PARCELA", "X3_TAMANHO")) //oObj:CONFIRMACAO[1]:DADOS[i]:E1_PARCELA
			cTipo    := padr(oObj:CONFIRMACAO[1]:DADOS[i]:E1_TIPO,GetSX3Cache("E1_TIPO", "X3_TAMANHO")) //oObj:CONFIRMACAO[1]:DADOS[i]:E1_TIPO

			If MsSeek(_cFilial + cPrefixo + cNum + cParcela + cTipo)

				//Gravo informações na SA1
				SE1->(Reclock("SE1", .F.))
					SE1->E1_ZSTATUS := oObj:CONFIRMACAO[1]:DADOS[i]:E1_ZSTATUS //Integrado
				SE1->(MsUnlock())
				SE1->(Dbskip())

				cJSONRet += '{'
				cJSONRet += '"Item": "' + StrZero(i,3) + '",'
				cJSONRet += '"Status": "200",'
				cJSONRet += '"Mensagem": "Cadastro atualizado com sucesso!",'
				cJSONRet += '"Filial": "'  + _cFilial + '",'
				cJSONRet += '"Prefixo": "' + cPrefixo + '",'
				cJSONRet += '"Num": "'     + cNum     + '",'
				cJSONRet += '"Parcela": "' + cParcela + '",' 
				cJSONRet += '"Tipo": "'    + cTipo    + '"
				cJSONRet += '}'

			Else
				
				cJSONRet += '{'
				cJSONRet += '"Item": "' + StrZero(i,3) + '",'
				cJSONRet += '"Status": "404",'
				cJSONRet += '"Mensagem": "Chave nao encontrada!",'
				cJSONRet += '"Filial": "'  + _cFilial + '",'
				cJSONRet += '"Prefixo": "' + cPrefixo + '",'
				cJSONRet += '"Num": "'     + cNum     + '",'
				cJSONRet += '"Parcela": "' + cParcela + '",' 
				cJSONRet += '"Tipo": "'    + cTipo    + '"
				cJSONRet += '}'

			EndIf

			If  i < Len(oObj:CONFIRMACAO[1]:DADOS)
				cJSONRet += ','
			EndIF

		Next

	ElseIf oObj:CONFIRMACAO[1]:TABELA == 'SF2'

		dbSelectArea("SF2")
		dbSetOrder(2)

		For i:=1 To Len(oObj:CONFIRMACAO[1]:DADOS)

			_cFilial := oObj:CONFIRMACAO[1]:DADOS[i]:F2_FILIAL 
			cCliente := oObj:CONFIRMACAO[1]:DADOS[i]:F2_CLIENTE
			cLoja    := oObj:CONFIRMACAO[1]:DADOS[i]:F2_LOJA
			cDoc     := oObj:CONFIRMACAO[1]:DADOS[i]:F2_DOC
			cSerie   := oObj:CONFIRMACAO[1]:DADOS[i]:F2_SERIE
			cTipo    := oObj:CONFIRMACAO[1]:DADOS[i]:F2_TIPO
			cEspecie := oObj:CONFIRMACAO[1]:DADOS[i]:F2_ESPECIE

			If MsSeek(_cFilial + cCliente + cLoja + cDoc + cSerie + cTipo + cEspecie)

				//Gravo informações na SA1
				SF2->(Reclock("SF2", .F.))
					SF2->F2_ZSTATUS := oObj:CONFIRMACAO[1]:DADOS[i]:F2_ZSTATUS //Integrado
				SF2->(MsUnlock())
				SF2->(Dbskip())

				cJSONRet += '{'
				cJSONRet += '"Item": "' + StrZero(i,3) + '",'
				cJSONRet += '"Status": "200",'
				cJSONRet += '"Mensagem": "Cadastro atualizado com sucesso!",'
				cJSONRet += '"Filial": "'  + _cFilial + '",'
				cJSONRet += '"Cliente": "' + cCliente + '",'
				cJSONRet += '"Loja": "'    + cLoja    + '",'
				cJSONRet += '"Doc": "'     + cDoc     + '",'
				cJSONRet += '"Serie": "'   + cSerie   + '",' 
				cJSONRet += '"Tipo": "'    + cTipo    + '",'
				cJSONRet += '"Espécie": "' + cEspecie + '"
				cJSONRet += '}'

			Else
				
				cJSONRet += '{'
				cJSONRet += '"Item": "' + StrZero(i,3) + '",'
				cJSONRet += '"Status": "404",'
				cJSONRet += '"Mensagem": "Chave nao encontrada!",'
				cJSONRet += '"Filial": "'  + _cFilial + '",'
				cJSONRet += '"Cliente": "' + cCliente + '",'
				cJSONRet += '"Loja": "'    + cLoja    + '",'
				cJSONRet += '"Doc": "'     + cDoc     + '",'
				cJSONRet += '"Serie": "'   + cSerie   + '",' 
				cJSONRet += '"Tipo": "'    + cTipo    + '",'
				cJSONRet += '"Espécie": "' + cEspecie + '"
				cJSONRet += '}'

			EndIf

			If  i < Len(oObj:CONFIRMACAO[1]:DADOS)
				cJSONRet += ','
			EndIF

		Next
	
	ElseIf oObj:CONFIRMACAO[1]:TABELA == 'SC5'

		dbSelectArea("SC5")
		dbSetOrder(1)

		For i:=1 To Len(oObj:CONFIRMACAO[1]:DADOS)

			_cFilial := oObj:CONFIRMACAO[1]:DADOS[i]:C5_FILIAL
			cNum     := oObj:CONFIRMACAO[1]:DADOS[i]:C5_NUM

			If MsSeek(_cFilial + cNum )

				//Gravo informações na SA1
				SC5->(Reclock("SC5", .F.))
					SC5->C5_ZSTATUS := oObj:CONFIRMACAO[1]:DADOS[i]:C5_ZSTATUS //Integrado
				SC5->(MsUnlock())
				SC5->(Dbskip())

				cJSONRet += '{'
				cJSONRet += '"Item": "' + StrZero(i,3) + '",'
				cJSONRet += '"Status": "200",'
				cJSONRet += '"Mensagem": "Cadastro atualizado com sucesso!",'
				cJSONRet += '"Filial": "' + _cFilial + '",' 
				cJSONRet += '"Num": "'    + cNum     + '"
				cJSONRet += '}'

			Else
				
				cJSONRet += '{'
				cJSONRet += '"Item": "' + StrZero(i,3) + '",'
				cJSONRet += '"Status": "404",'
				cJSONRet += '"Mensagem": "Chave nao encontrada!",'
				cJSONRet += '"Filial": "' + _cFilial + '",' 
				cJSONRet += '"Num": "'    + cNum     + '"
				cJSONRet += '}'

			EndIf

			If  i < Len(oObj:CONFIRMACAO[1]:DADOS)
				cJSONRet += ','
			EndIF

		Next
		
	ElseIf oObj:CONFIRMACAO[1]:TABELA == 'SC6'

		dbSelectArea("SC6")
		dbSetOrder(1)

		For i:=1 To Len(oObj:CONFIRMACAO[1]:DADOS)

			_cFilial := oObj:CONFIRMACAO[1]:DADOS[i]:C6_FILIAL
			cNum     := oObj:CONFIRMACAO[1]:DADOS[i]:C6_NUM

			SC6->(dbSetOrder(1))
			SC6->(dbGoTop())
			
			If SC6->(MsSeek(_cFilial + cNum ))

				While (SC6->(!Eof()) .AND. SC6->C6_NUM = cNum)
					RecLock("SC6",.F.)
						SC6->C6_ZSTATUS := oObj:CONFIRMACAO[1]:DADOS[i]:C6_ZSTATUS
					SC6->(MsUnlock())
					SC6->(dbSkip())
				EndDo

				cJSONRet += '{'
				cJSONRet += '"Item": "' + StrZero(i,3) + '",'
				cJSONRet += '"Status": "200",'
				cJSONRet += '"Mensagem": "Cadastro atualizado com sucesso!",'
				cJSONRet += '"Filial": "' + _cFilial + '",' 
				cJSONRet += '"Num": "'    + cNum     + '"
				cJSONRet += '}'

			Else
				
				cJSONRet += '{'
				cJSONRet += '"Item": "' + StrZero(i,3) + '",'
				cJSONRet += '"Status": "404",'
				cJSONRet += '"Mensagem": "Chave nao encontrada!",'
				cJSONRet += '"Filial": "' + _cFilial + '",' 
				cJSONRet += '"Num": "'    + cNum     + '"
				cJSONRet += '}'

			EndIf

			If  i < Len(oObj:CONFIRMACAO[1]:DADOS)
				cJSONRet += ','
			EndIF

		Next
	
	ElseIf oObj:CONFIRMACAO[1]:TABELA == 'SB1'

		dbSelectArea("SB1")
		dbSetOrder(1)

		For i:=1 To Len(oObj:CONFIRMACAO[1]:DADOS)

			cProduto := oObj:CONFIRMACAO[1]:DADOS[i]:B1_COD
			
			SB1->(dbSetOrder(1))
			SB1->(dbGoTop())
			
			If SB1->(DbSeek(XFilial("SB1") + cProduto))

				While (SB1->(!Eof()) .AND. SB1->B1_COD = cProduto)
					RecLock("SB1",.F.)
						SB1->B1_ZSTATUS := oObj:CONFIRMACAO[1]:DADOS[i]:B1_ZSTATUS
					SB1->(MsUnlock())
					SB1->(dbSkip())
				EndDo

				cJSONRet += '{'
				cJSONRet += '"Item": "' + StrZero(i,3) + '",'
				cJSONRet += '"Status": "200",'
				cJSONRet += '"Mensagem": "Cadastro atualizado com sucesso!",'
				cJSONRet += '"Codigo": "' + cProduto + '"
				cJSONRet += '}'

			Else
				
				cJSONRet += '{'
				cJSONRet += '"Item": "' + StrZero(i,3) + '",'
				cJSONRet += '"Status": "404",'
				cJSONRet += '"Mensagem": "Chave nao encontrada!",'
				cJSONRet += '"Codigo": "' + cProduto + '"
				cJSONRet += '}'

			EndIf

			If  i < Len(oObj:CONFIRMACAO[1]:DADOS)
				cJSONRet += ','
			EndIF

		Next
	EndIf
	
	cJSONRet += ']'
	//-------------------------------------------------------------------
	//Envia o JSON Gerado para a aplicaçao Cliente
	//-------------------------------------------------------------------	
	::SetResponse( cJSONRet ) 		
	
	//-------------------------------------------------------------------
	// Efetuo o fechamento da Tabela SA1
	//-------------------------------------------------------------------
	SA1->(dbCloseArea())
	SE1->(dbCloseArea())
	SC5->(dbCloseArea())
	SC6->(dbCloseArea())
	SF2->(dbCloseArea())

	//-------------------------------------------------------------------
	// Restauro a area de trabalho
	//-------------------------------------------------------------------
	RestArea(aArea)		

Return(.T.)

		