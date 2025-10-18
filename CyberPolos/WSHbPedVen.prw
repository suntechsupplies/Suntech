#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"
#Include "Totvs.ch"
#Include "topconn.ch"

/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Cyberpolos								                                          *  
* Processa as informações e retorna o json                                                    *
* @since 	01/12/2022                                                                        *
* @version undefined                                                                          *
* @param oSelf, object, Objeto contendo dados da requisição efetuada pelo cliente, tais como: *
*    - Parâmetros querystring (parâmetros informado via URL)                                  *
*    - Objeto JSON caso o requisição seja efetuada via Request Post                           *
*    - Header da requisição                                                                   *
*    - entre outras ...                                                                       *
* @type Method                                                                                *
**********************************************************************************************/

#Define _Function 	"WSHbPedVen"
#Define _DescFun  	"Pedidos de venda"
#Define Desc_Rest	"Serviço REST para Disponibilizar dados de Pedidos de venda"
#Define Desc_Get  	"Retorna Pedidos de venda informado de acordo com parametro de data" 
#Define Desc_Post	"Cria o Pedidos de venda de acordo com as informacoes passadas"
/*
user function WSPedVen()

return
*/
WSRESTFUL wsPVGetPos DESCRIPTION Desc_Rest

	WSDATA nPag			As Integer		
	WSDATA nFlagCab		As Integer		// 1 = SIM 		/ 2 = NÃO
	WSDATA nFlagIt		As Integer		// 1 = SIM 		/ 2 = NÃO
	WSDATA cTipo		As String		// C = COMPLETO / D = DIFERENCIAL
    WSDATA TENANTID     AS STRING

	WSMETHOD GET  DESCRIPTION Desc_Get  WSSYNTAX "/wsPVGetPos || /wsPVGetPos/{}"
	WSMETHOD POST DESCRIPTION Desc_Post WSSYNTAX "/wsPVGetPos/{Pedido}"

END WSRESTFUL

/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @Cyberpolos										                                          *  
* Processa as informações e retorna o json                                                    *
* @since 	01/12/2022                                                                        *
* @version undefined                                                                          *
* @param oSelf, object, Objeto contendo dados da requisição efetuada pelo cliente, tais como: *
*    - Parâmetros querystring (parâmetros informado via URL)                                  *
*    - Objeto JSON caso o requisição seja efetuada via Request Post                           *
*    - Header da requisição                                                                   *
*    - entre outras ...                                                                       *
* @type Method                                                                                *
**********************************************************************************************/

WSMETHOD GET WSRECEIVE nPag, nFlagCab, nFlagIt, cTipo HEADERPARAM TENANTID WSSERVICE wsPVGetPos

	Local nPag		:= Self:nPag
	Local nFlagCab	:= Self:nFlagCab		// 1 = Sim / 2 = Nao
	Local nFlagIt	:= Self:nFlagIt
	Local cTipo		:= Upper(Self:cTipo)	// C = Completo / D = Diferencial
	Local aArea		:= GetArea()
	Local cAliasTmp	:= GetNextAlias()
	Local cNumero	:= ''
	Local cPed		:= ''
	Local cSetResp	:= ''
	Local cPedCli	:= ''
	Local nGetDate	:= 0					//SuperGetMV("MV_AFVDIAS",,90)
	Local _cEmpresa	:= "01"
	Local _cFilial	:= "01"
	Local aDebug	:= {}
	Local nX
	Local nZ
	Local nPagFim

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
		_cFilial  := Substr(Upper(SELF:TENANTID), At(",",Upper(SELF:TENANTID))+1)

        CONOUT("[GET] [wsPVGetPos ] TENANTID : " + SELF:TENANTID + "[cEmpant] : " + cEmpant + "[cFilant] : " + cFilant)
	EndIf

	cEmpAnt := _cEmpresa
	cFilAnt := _cFilial

    // < Fim > -------------------------------------------------------------------------

	nGetDate := SuperGetMV("MV_AFVDIAS",,90)

	// define o tipo de retorno do método
	::SetContentType("application/json")
	
	//Verifica se há conexão em aberto, caso haja fecha.
	IF Select(cAliasTmp) > 0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf
	
	/********************************************************
	* Verifico o Tipo de Pedidos a Serem retornados			*
	* cTipo = "C", todos os pedidos							*
	* cTipo = "D", somente os pedidos com os códigos abaixo	*
	* 3 - Incluido											*
	* 4 - Alterado											*
	* 5 - Excluido											*
	* 6 - Copia												*
	* 7 - Devolução de Compras								*
	/*******************************************************/	

	If cTipo = "C"				// Completo
		
		// Efetua a consulta conforme os parâmetros passados				
		BeginSql Alias cAliasTmp
	
			SELECT 	 	(( DENSE_RANK() OVER ( ORDER BY C6.C6_NUM) ) / 10 ) + 1			AS PAG 
				      	,(	SELECT 		SUM(C.C6_VALOR) 
				       		FROM 		%Table:SC6% C
					        INNER JOIN	%Table:SB1% B
				        	ON 			B.B1_COD		= C.C6_PRODUTO 
				        	WHERE  		C6.C6_FILIAL 	= C.C6_FILIAL 
				         	AND 		C6.C6_NUM 		= C.C6_NUM 
				          	AND 		C6.C6_CLI 		= C.C6_CLI 
				          	AND 		C6.C6_LOJA		= C.C6_LOJA 
				          	AND 		B.B1_TIPO 		IN ( 'MP', 'PA' )
				          	AND			C5.%NotDel%	       
				          	AND			C.%NotDel% 		
				          	GROUP BY 	C.C6_NUM 						)		AS VALORPEDIDO 
				        ,(	SELECT		SUM(D2_TOTAL) 
							FROM		%Table:SD2% D
							INNER JOIN 	%Table:SC6% E
							ON 			D.D2_FILIAL 	= E.C6_FILIAL
							AND			D.D2_PEDIDO 	= E.C6_NUM
			      			AND			D.D2_CLIENTE	= E.C6_CLI
			      			AND			D.D2_LOJA		= E.C6_LOJA 
			     			AND			D.D2_COD		= E.C6_PRODUTO 
			     			AND			D.D2_ITEM		= E.C6_ITEM
			      			WHERE		D.D2_PEDIDO 	= C6.C6_NUM
			      			AND 		D.D2_TP 		IN ( 'MP', 'PA' ) 		      			
			      			AND			D.%NotDel%
			      			AND			E.%NotDel%
			      			AND			C6.%NotDel%						)		AS VALORFATURADO 
			      		, CASE C5.C5_ZZSITFI 
			      			WHEN ' ' THEN 'Em Estudo'
			      			WHEN '1' THEN 'Em Estudo'
			      			WHEN '2' THEN 'Liberado'
			      			WHEN '3' THEN 'Bloqueado'
			      		  END													AS  CESP_SITUACAOFINAN
			      		, CASE C5.C5_STATU1
			      			WHEN '3' THEN 'Incluido'
			      			WHEN '4' THEN 'Alterado'
			      			WHEN '5' THEN 'Excluido'
			      			WHEN '6' THEN 'Copiado'
			      			WHEN '7' THEN 'Devolucao Compras'
			      			WHEN '9' THEN 'Importado'
			      		  END													AS STATU1
			      		, C5.* 
			      		, C6.*
			      		, B1.B1_PESO 
			FROM		%Table:SC6% C6 
			INNER JOIN	%Table:SC5% C5 
			ON 			C5.C5_FILIAL	= C6.C6_FILIAL 
			AND 		C5.C5_NUM 		= C6.C6_NUM 
			AND 		C5.C5_CLIENTE 	= C6.C6_CLI 
			AND 		C5.C5_LOJACLI 	= C6.C6_LOJA 
			INNER JOIN 	%Table:SB1% B1 
			ON 			B1.B1_COD 		= C6.C6_PRODUTO 
			WHERE  		C5.C5_EMISSAO 	>= Getdate() - %Exp:nGetDate%
			AND 		C5.%NotDel%
			AND 		C6.%NotDel%
			AND 		B1.B1_TIPO 		IN ( 'MP', 'PA' ) 
			ORDER  BY 	C6.C6_FILIAL, C6.C6_NUM, C6.C6_ITEM
		
		EndSql
	
	ElseIf cTipo == "D"				// Diferencial 
	
		BeginSql Alias cAliasTmp
	
			SELECT 	 	(( DENSE_RANK() OVER ( ORDER BY C6.C6_NUM) ) / 10 ) + 1			AS PAG 
				      	,(	SELECT 		SUM(C.C6_VALOR) 
				       		FROM 		%Table:SC6% C
					        INNER JOIN	%Table:SB1% B
				        	ON 			B.B1_COD		= C.C6_PRODUTO 
				        	WHERE  		C6.C6_FILIAL 	= C.C6_FILIAL 
				         	AND 		C6.C6_NUM 		= C.C6_NUM 
				          	AND 		C6.C6_CLI 		= C.C6_CLI 
				          	AND 		C6.C6_LOJA		= C.C6_LOJA 
				          	AND 		B.B1_TIPO 		IN ( 'MP', 'PA' )
				          	AND			C5.%NotDel%	       
				          	AND			C.%NotDel% 		
				          	GROUP BY 	C.C6_NUM 						)		AS VALORPEDIDO 
				        ,(	SELECT		SUM(D2_TOTAL) 
							FROM		%Table:SD2% D
							INNER JOIN 	%Table:SC6% E
							ON 			D.D2_FILIAL 	= E.C6_FILIAL
							AND			D.D2_PEDIDO 	= E.C6_NUM
			      			AND			D.D2_CLIENTE	= E.C6_CLI
			      			AND			D.D2_LOJA		= E.C6_LOJA 
			     			AND			D.D2_COD		= E.C6_PRODUTO 
			     			AND			D.D2_ITEM		= E.C6_ITEM
			      			WHERE		D.D2_PEDIDO 	= C6.C6_NUM
			      			AND 		D.D2_TP 		IN ( 'MP', 'PA' ) 		      			
			      			AND			D.%NotDel%
			      			AND			E.%NotDel%
			      			AND			C6.%NotDel%						)		AS VALORFATURADO 
			      		, CASE C5.C5_ZZSITFI 
			      			WHEN ' ' THEN 'Em Estudo'
			      			WHEN '1' THEN 'Em Estudo'
			      			WHEN '2' THEN 'Liberado'
			      			WHEN '3' THEN 'Bloqueado'
			      		  END													AS  CESP_SITUACAOFINAN
			      		, CASE C5.C5_STATU1
			      			WHEN '3' THEN 'Incluido'
			      			WHEN '4' THEN 'Alterado'
			      			WHEN '5' THEN 'Excluido'
			      			WHEN '6' THEN 'Copiado'
			      			WHEN '7' THEN 'Devolucao Compras'
			      			WHEN '9' THEN 'Importado'
			      		  END													AS STATU1
			      		, C5.* 
			      		, C6.*
			      		, B1.B1_PESO 
			FROM		%Table:SC6% C6 
			INNER JOIN	%Table:SC5% C5 
			ON 			C5.C5_FILIAL	= C6.C6_FILIAL 
			AND 		C5.C5_NUM 		= C6.C6_NUM 
			AND 		C5.C5_CLIENTE 	= C6.C6_CLI 
			AND 		C5.C5_LOJACLI 	= C6.C6_LOJA 
			INNER JOIN 	%Table:SB1% B1 
			ON 			B1.B1_COD 		= C6.C6_PRODUTO 
			WHERE  		C5.C5_EMISSAO 	>= Getdate() - %Exp:nGetDate%
			AND 		C5.%NotDel%
			AND 		C6.%NotDel%
			AND 		B1.B1_TIPO 		IN ( 'MP', 'PA' ) 
			AND			C5.C5_STATU1	<> '9'
			AND			C6.C6_STATU1	<> '9'
			ORDER  BY 	C6.C6_FILIAL, C6.C6_NUM, C6.C6_ITEM
		
		EndSql
	
	Else

		cSetResp := '{"TE_HISTPEDIDO":'
		cSetResp += '["Retorno":"Nao Existe Itens Nessa Pagina, reveja os parametros !!!"'
		cSetResp += ',"cTipo":"'	+ TRIM(cTipo)
		cSetResp += '","Erro": "O Tipo solicitado nao existe para a consulta !!!. Tipos validos C(Completo) ou D(Diferencial)"'
		cSetResp += ']}'

		//--------------------------------------------------------------------------
		//Envia o JSON Gerado para a aplicação Cliente
		//--------------------------------------------------------------------------
		::SetResponse( cSetResp ) 
		RestArea(aArea)
		Return(.T.)

	Endif
	
	aDebug := GetLastQuery()

	(cAliasTmp)->( DbGoTop() )

	While (cAliasTmp)->( !Eof() )
		nPagFim		:= (cAliasTmp)->PAG
		(cAliasTmp)->(dbSkip())
	EndDo

	SC5->(dbSelectArea("SC5"))
	SC6->(dbSetOrder(1))
	SC6->(dbSelectArea("SC6"))
	SC6->(dbSetOrder(1))

	//--------------------------------------------------------------------------
	// Posiciona no primeiro registro da Query
	//--------------------------------------------------------------------------
	(cAliasTmp)->( DbGoTop() )

	If  (cAliasTmp)->( Eof() ) 					;		// Final de Arquivo
		.Or. ( nFlagIt = 2 .And. nFlagCab = 2 ) ;		// Cabecalho e item como nao
		.Or. Empty(nFlagIt) 					;		// Variavel Item vazio
		.Or. Empty(nFlagCab) 					;		// Variavel Cabecalho vazio
		.Or. (nFlagCab + nFlagIt) > 3 					// Quando a soma de cabecalho e item for maior que 3 

		cSetResp := '{"TE_HISTPEDIDO":'
		cSetResp += '["Retorno":"Nao Existe Itens Nessa Pagina, reveja os parametros !!!"'
		cSetResp += ']'
		cSetResp += '}'
	Else
		//--------------------------------------------------------------------------
		// Emite Json Cabecalho e Itens Pedido de Vendas
		//--------------------------------------------------------------------------
		If nFlagIt == 1 .And. nFlagCab == 1

			(cAliasTmp)->( DbGoTop() )  
			nX			:= 1
			nZ			:= 1
			cSetResp	:= '{ "TE_HISTPEDIDO":[ ' 
			While (cAliasTmp)->( !Eof() )
				
				IF (cAliasTmp)->PAG = nPag
				
					If nX > 1
						cSetResp  +=' , '
					EndIf
	
					If TRIM( (cAliasTmp)->C5_FILIAL + (cAliasTmp)->C5_NUM ) <>  cPed
						cSetResp  += '{'
						cSetResp  += '"NUMPEDIDOEMP":"'			+ TRIM( (cAliasTmp)->C5_FILIAL + (cAliasTmp)->C5_NUM )	
						cSetResp  += '","NUMPEDIDOAFV":"'		+ TRIM((cAliasTmp)->C5_ZZNPEXT)	
						cSetResp  += '","CODIGOCLIENTE":"'		+ TRIM((cAliasTmp)->C5_CLIENTE + (cAliasTmp)->C5_LOJACLI)					
						cSetResp  += '","STATUSPEDIDO":"'		+ TRIM(IIF ( EMPTY( TRIM( (cAliasTmp)->C5_NOTA ) ), "EM ABERTO", "FATURADO" ))
						cSetResp  += '","VALORPEDIDO":'			+ TRIM(cValToChar((cAliasTmp)->VALORPEDIDO))
						cSetResp  += ',"VALORFATURADO":' 		+ TRIM(cValToChar((cAliasTmp)->VALORFATURADO))
						cSetResp  += ',"DATAPEDIDO":"' 			+ TRIM((cAliasTmp)->C5_EMISSAO)
						cSetResp  += '","ORIGEMPEDIDO":"' 		+ IIF(!Empty((cAliasTmp)->C5_ZZORIGE), TRIM((cAliasTmp)->C5_ZZORIGE), "ERP")				
						cSetResp  += '","TIPOPEDIDO":"'			+ TRIM((cAliasTmp)->C5_ZZTPPED)
						cSetResp  += '","CODIGOCONDPAGTO":"'	+ TRIM((cAliasTmp)->C5_CONDPAG)
						cSetResp  += '","DESCRICAOFRETE":"'		+ TRIM((cAliasTmp)->C5_TPFRETE)
						cSetResp  += '","VENDEDOR1":"'	    	+ TRIM((cAliasTmp)->C5_VEND1)
						cSetResp  += '","CESP_SITUACAOFINAN":"'	+ TRIM((cAliasTmp)->CESP_SITUACAOFINAN)
						cSetResp  += '","STATUS":"'				+ TRIM((cAliasTmp)->STATU1)
						cSetResp  += '","TE_HISTPEDIDOITEM": ['
						cPed	:= TRIM( (cAliasTmp)->C5_FILIAL + (cAliasTmp)->C5_NUM )
						cPedCli	:= TRIM( (cAliasTmp)->C5_FILIAL + (cAliasTmp)->C5_NUM )
						nZ :=  1
					EndIf	
							
					While TRIM( (cAliasTmp)->C5_FILIAL + (cAliasTmp)->C5_NUM ) ==  cPedCli .And.  (cAliasTmp)->( !Eof() ) 
						If nZ > 1
							cSetResp  +=' , '
						EndIf
						cSetResp  += '{'
						cSetResp  += '"CODIGOPRODUTO":"'		+ TRIM((cAliasTmp)->C6_PRODUTO)
						cSetResp  += '","DESCRICAOPRODUTO":"'  	+ StrTran(StrTran(TRIM((cAliasTmp)->C6_DESCRI),'"',''),"'","")
						cSetResp  += '","QTDEVENDA":'		   	+ TRIM(cValToChar((cAliasTmp)->C6_QTDVEN))
						cSetResp  += ',"SALDOQTDEVENDA":'	   	+ TRIM(cValToChar((cAliasTmp)->C6_QTDVEN - (cAliasTmp)->C6_QTDENT))
						cSetResp  += ',"DESCONTO":'				+ TRIM(cValToChar((cAliasTmp)->C6_DESCONT))
						cSetResp  += ',"VALORVENDA":' 	       	+ TRIM(cValToChar((cAliasTmp)->C6_VALOR))
						cSetResp  += ',"PESOLIQUIDO":' 			+ TRIM(cValToChar((cAliasTmp)->B1_PESO))	
						cSetResp  += ',"ITEMPRODUTO":"' 	   	+ TRIM((cAliasTmp)->C6_ITEM)
						cSetResp  += '"}'											

						//--------------------------------------------------------------------------
						// Posiciona no registro do cabecalho do Pedidos de Vendas para update
						//--------------------------------------------------------------------------
						If (cAliasTMP)->C5_STATU1 <> '9'
							SC5->(dbSetOrder(1))
							SC5->(dbGoTop())
							If SC5->(MsSeek(cPed))
								RecLock("SC5",.F.)
								SC5->C5_STATU1 := '9'
								SC5->(MsUnlock())
							Endif
						Endif

						(cAliasTmp)->(dbSkip())
						nZ++

					EndDo
					cSetResp  += ']}'
					cPedCli	:= TRIM( (cAliasTmp)->C5_FILIAL + (cAliasTmp)->C5_NUM )
					nX++
				Else
					(cAliasTMP)->(dbSkip())
					LOOP	
				EndIf
			EndDo
	
			cSetResp  += ']'	
			cSetResp  += ',"PaginalAtual":'				+ cValToChar(Self:nPag)			
			cSetResp  += ',"TotalDePaginas":'			+ cValToChar(nPagFim)
			cSetResp  += '}'
		
		//--------------------------------------------------------------------------
		// Emite apenas Json apenas do Cabecalho
		//--------------------------------------------------------------------------
		ElseIf nFlagIt = 2 .And. nFlagCab = 1 
			
			(cAliasTmp)->( DbGoTop() )  

			nX			:= 1
			cSetResp	:= '{ "TE_HISTPEDIDO":[ ' 
			
			While (cAliasTmp)->( !Eof() )
				
				IF (cAliasTmp)->PAG = nPag

					If nX > 1
						cSetResp  +=' , '
					EndIf
	
					cSetResp  += '{'
					cSetResp  += '"NUMPEDIDOEMP":"'			+ TRIM( (cAliasTmp)->C5_FILIAL + (cAliasTmp)->C5_NUM )	
					cSetResp  += '","NUMPEDIDOAFV":"'		+ TRIM((cAliasTmp)->C5_ZZNPEXT)	
					cSetResp  += '","CODIGOCLIENTE":"'		+ TRIM((cAliasTmp)->C5_CLIENTE + (cAliasTmp)->C5_LOJACLI)					
					cSetResp  += '","STATUSPEDIDO":"'		+ TRIM(IIF ( EMPTY( TRIM( (cAliasTmp)->C5_NOTA ) ), "EM ABERTO", "FATURADO" ))
					cSetResp  += '","VALORPEDIDO":'			+ TRIM(cValToChar((cAliasTmp)->VALORPEDIDO))
					cSetResp  += ',"VALORFATURADO":' 		+ TRIM(cValToChar((cAliasTmp)->VALORFATURADO))
					cSetResp  += ',"DATAPEDIDO":"' 			+ TRIM((cAliasTmp)->C5_EMISSAO)
					cSetResp  += '","ORIGEMPEDIDO":"' 		+ IIF(!Empty((cAliasTmp)->C5_ZZORIGE), TRIM((cAliasTmp)->C5_ZZORIGE), "ERP")
					cSetResp  += '","TIPOPEDIDO":"'			+ TRIM((cAliasTmp)->C5_ZZTPPED)
					cSetResp  += '","CODIGOCONDPAGTO":"'	+ TRIM((cAliasTmp)->C5_CONDPAG)
					cSetResp  += '","DESCRICAOFRETE":"'		+ TRIM((cAliasTmp)->C5_TPFRETE)
					cSetResp  += '","VENDEDOR1":"'	    	+ TRIM((cAliasTmp)->C5_VEND1)
					cSetResp  += '","CESP_SITUACAOFINAN":"'	+ TRIM((cAliasTmp)->CESP_SITUACAOFINAN)
					cSetResp  += '","STATUS":"'				+ TRIM((cAliasTmp)->STATU1)
					cSetResp  += '"}'
					nX++
					
					cNumero := TRIM( (cAliasTmp)->C5_FILIAL + (cAliasTmp)->C5_NUM )
					
					//--------------------------------------------------------------------------
					// Posiciona no registro do cabecalho do Pedidos de Vendas para update
					//--------------------------------------------------------------------------
					If (cAliasTMP)->C5_STATU1 <> '9'
						SC5->(dbSetOrder(1))
						SC5->(dbGoTop())
						If SC5->(MsSeek((cAliasTMP)->(C5_FILIAL + C5_NUM)))
							RecLock("SC5",.F.)
							SC5->C5_STATU1 := '9'
							SC5->(MsUnlock())
						Endif
					Endif

					//-----------------------------------------------------------------------
					// Incluido para nao repetir os dados de cabecalho a cada
					// item do pedido de Vendas para solicitacoes de cabecalho apenas
					//-----------------------------------------------------------------------
					While TRIM((cAliasTmp)->C5_FILIAL + (cAliasTmp)->C5_NUM ) == cNumero .And. (cAliasTmp)->(!Eof())
						(cAliasTMP)->(dbSkip())
					End
				Else
					(cAliasTMP)->(dbSkip())
					LOOP	
				EndIf
			EndDo
	
			cSetResp  += ']'	
			cSetResp  += ',"PaginalAtual":'				+ cValToChar(Self:nPag)			
			cSetResp  += ',"TotalDePaginas":'			+ cValToChar(nPagFim)
			cSetResp  += '}'
		
		//--------------------------------------------------------------------------
		// Emite apenas Json apenas dos Itens
		//--------------------------------------------------------------------------
		ElseIf nFlagIt = 1 .And. nFlagCab = 2
		
			(cAliasTmp)->( DbGoTop() )  
			nZ			:= 1
			cSetResp  += '{"TE_HISTPEDIDOITEM": ['

			While (cAliasTmp)->( !Eof() )
				
				IF (cAliasTmp)->PAG = nPag
				
							
					If nZ > 1
						cSetResp  +=' , '
					EndIf

					cSetResp  += '{'
					cSetResp  += '"NUMPEDIDOEMP":"'			+ TRIM((cAliasTmp)->C5_FILIAL + (cAliasTmp)->C5_NUM )					
					cSetResp  += '","CODIGOPRODUTO":"'		+ TRIM((cAliasTmp)->C6_PRODUTO)
					cSetResp  += '","DESCRICAOPRODUTO":"'  	+ StrTran(StrTran(TRIM((cAliasTmp)->C6_DESCRI),'"',''),"'","")
					cSetResp  += '","QTDEVENDA":'		   	+ TRIM(cValToChar((cAliasTmp)->C6_QTDVEN))
					cSetResp  += ',"SALDOQTDEVENDA":'	   	+ TRIM(cValToChar((cAliasTmp)->C6_QTDVEN - (cAliasTmp)->C6_QTDENT))
					cSetResp  += ',"DESCONTO":'				+ TRIM(cValToChar((cAliasTmp)->C6_DESCONT))
					cSetResp  += ',"VALORVENDA":' 	       	+ TRIM(cValToChar((cAliasTmp)->C6_VALOR))
					cSetResp  += ',"PESOLIQUIDO":' 			+ TRIM(cValToChar((cAliasTmp)->B1_PESO))	
					cSetResp  += ',"ITEMPRODUTO":"' 	   	+ TRIM((cAliasTmp)->C6_ITEM)
					cSetResp  += '"}'											

					//--------------------------------------------------------------------------
					// Posiciona no registro do cabecalho do Pedidos de Vendas para update
					//--------------------------------------------------------------------------
					If (cAliasTMP)->C6_STATU1 <> '9'
						SC6->(dbSetOrder(1))
						SC6->(dbGoTop())
						If SC6->(MsSeek((cAliasTMP)->(C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO)))
							RecLock("SC6",.F.)
							SC6->C6_STATU1 := '9'
							SC6->(MsUnlock())
						Endif
					Endif
					(cAliasTmp)->(dbSkip())
					nZ++

				Else
					(cAliasTMP)->(dbSkip())
					LOOP	
				EndIf
			EndDo
	
			cSetResp  += ']'	
			cSetResp  += ',"PaginalAtual":'				+ cValToChar(Self:nPag)			
			cSetResp  += ',"TotalDePaginas":'			+ cValToChar(nPagFim)
			cSetResp  += '}'
	
		Endif
	EndIf
	//--------------------------------------------------------------------------
	//Fecha a tabela
	//--------------------------------------------------------------------------
	(cAliasTmp)->(DbCloseArea())

	//--------------------------------------------------------------------------
	//Envia o JSON Gerado para a aplicação Cliente
	//--------------------------------------------------------------------------
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)

WSMETHOD POST HEADERPARAM TENANTID WSSERVICE wsPVGetPos

	Local oResponse 			as object
	Local oContent   			as object
	Local _nY, _nX, _nZ	 		as numeric
	Local aArea					:= {}
	Local aDadosC5				:= {}
	Local aDadosC6				:= {}
	Local aLin					:= {}
	Local aLogAuto				:= {}
	Local cArqLog				:= ''
	Local cError				:= ''
 	Local nError				:= 0
 	Local _cEmpresa				:= '01'
 	Local _cFilial				:= '02'
 	Local _nOpc					:= 3
 	Local _cPedAFV				:= ''
 	Local _cNumPed				:= ''
	Local cAliasTMP             := GetNextAlias()
	Local lRet  := .T.
    
 	
	Private lMsErroAuto			:= .F.
 	Private lMsHelpAuto			:= .T.
 	Private lAutoErrNoFile		:= .T. 	
	

	If !Empty(SELF:TENANTID) .Or. ! ValType(self:tenantid) == "U"

		_cEmpresa := Left(Upper(SELF:TENANTID), At(",",Upper(SELF:TENANTID))-1)
		_cFilial  := Substr(Upper(SELF:TENANTID), At(",",Upper(SELF:TENANTID))+1)
        cEmpAnt := _cEmpresa
        cFilAnt := _cFilial
        cNumemp := _cEmpresa + _cFilial
        CONOUT("[POST] [wsPVGetPos] [ TENANTID : " + iif(ValType(SELF:TENANTID)=="U","Indefined", SELF:TENANTID) + " ][cEmpant : " + cEmpant + " ][cFilant : " + cFilant +" ][ cNumemp : " + cNumemp )
    Else
        CONOUT("[POST] [wsPVGetPos] [ TENANTID : " + iif(ValType(SELF:TENANTID)=="U","Indefined", SELF:TENANTID) + " ][cEmpant : " + cEmpant + " ][cFilant : " + cFilant +" ][ cNumemp : " + cNumemp )
	EndIf

	aArea := GetArea()

	//Cria o diretório para salvar os arquivos de log
	If !ExistDir("\log_Ped")
		MakeDir("\log_Ped")
	EndIf

	//******************************************************************************
	// Verifica se o body veio no formato JSon.
	//******************************************************************************
	If lower(Self:GetHeader("Content-Type", .F.)) == "application/json"

        Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Content-Type : '+ Self:GetHeader("Content-Type", .F.) + ']')

		oContent := JsonObject():New()
		oContent:FromJson(::GetContent())  // Transforma o JSON do body em um objeto JSON Protheus.

		//******************************************************************************
		// Se tudo certo, grava o arquivo no servidor e seus registros correspondentes.
		//******************************************************************************
		If ValType(oContent) == "J"

            //**********************************************************************************
            // Cria o Objeto de Retorno das informacoes
            //**********************************************************************************
            oResponse := JsonObject():New()
            oResponse["Data"] 		:= oContent["CABECALHO"][1]["C5_ZZDTEMI"]
            oResponse["Resultados"]	:= {}


            //**********************************************************************************
            // Preenche o Array do Cabecalho do Pedido de Vendas
            //**********************************************************************************
            For _nZ := 1 To Len(oContent["CABECALHO"])


                Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] - [Quantidade de Pedidos no Consumo : ' + Alltrim(cValToChar(Len(oContent["CABECALHO"]))) + " ] Importação Iniciada ......")            

                //***************************************************************************************
                // Guardo empresa e filial para passar para Prepare Environment e Consultar Pedido AFV
                //***************************************************************************************
                _cEmpresa 	:= oContent["CABECALHO"][_nZ]["EMPRESA"]
                _cFilial	:= oContent["CABECALHO"][_nZ]["C5_FILIAL"]
                _cPedAFV	:= oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]
                
                //**********************************************************************************
                // Salva a area atual 
                //**********************************************************************************
                aArea := GetArea()					

                //**********************************************************************************
                // Efetua a preparação do ambiente 
                //**********************************************************************************

                If !Empty(SELF:TENANTID)
                    _cEmpresa := Left(Upper(SELF:TENANTID), At(",",Upper(SELF:TENANTID))-1)
                    _cFilial  := Substr(Upper(SELF:TENANTID), At(",",Upper(SELF:TENANTID))+1)
                    
                    CONOUT("[POST] [wsPVGetPos] [ TENANTID : " + SELF:TENANTID + "[cEmpant] : " + cEmpant + "[cFilant] : " + cFilant)
                Else
                    CONOUT("[POST] [wsPVGetPos] [ TENANTID : Sem conteúdo ] [cEmpant] : " + cEmpant + "[cFilant] : " + cFilant)
                EndIf

                cEmpAnt := _cEmpresa
                cFilAnt := _cFilial

                // < Fim > -------------------------------------------------------------------------


				SC5->(dbSetOrder(12))           // índice customizado, conferir sempre que tiver atualização de release
                SC5->(dbGoTop())

                //**********************************************************************************
                // Caso o Pedido ja tenha sido incluído, inicia a importação do próximo pedido
                //**********************************************************************************
                if SC5->(MsSeek( PADR(_cFilial,2) + PADR(_cPedAFV,10)) )
                    //LOOP
					oJsonRet := JsonObject():New()						
					oJsonRet["SUCESSMESSAGE"]	:= EncodeUTF8(IIF(_nOpc == 3 ,"Pedido de Vendas não Incluído","Pedido de Vendas não Alterado"))

					oJsonRet["PEDIDOAFV"]		:= oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"] + " - Pedido ja importado anteriormente."
					Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : pedidoAFV ] ' + oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"])

					aAdd(oResponse["Resultados"], oJsonRet)

				else
                

					// Limpo as variaveis 
					aDadosC5 := {}
					aDadosC6 := {}

					//**********************************************************************************
					// Preenche o Array do Cabecalho do Pedido de Vendas 
					//**********************************************************************************
					aAdd(aDadosC5, {"C5_TIPO"	 		,oContent["CABECALHO"][_nZ]["C5_TIPO"]	 				, Nil})
					aAdd(aDadosC5, {"C5_CLIENTE" 		,oContent["CABECALHO"][_nZ]["C5_CLIENTE"]				, Nil})
					aAdd(aDadosC5, {"C5_LOJACLI" 		,oContent["CABECALHO"][_nZ]["C5_LOJACLI"]				, Nil})
					aAdd(aDadosC5, {"C5_EMISSAO" 		,Stod(oContent["CABECALHO"][_nZ]["C5_ZZDTEMI"])			, Nil})
					aAdd(aDadosC5, {"C5_CONDPAG" 		,oContent["CABECALHO"][_nZ]["C5_CONDPAG"]				, Nil})
					aAdd(aDadosC5, {"C5_TPFRETE" 		,oContent["CABECALHO"][_nZ]["C5_TPFRETE"] 				, Nil})
					aAdd(aDadosC5, {"C5_FRETE" 			,oContent["CABECALHO"][_nZ]["C5_FRETE"] 				, Nil})
					aAdd(aDadosC5, {"C5_MENNOTA" 		,oContent["CABECALHO"][_nZ]["C5_MENNOTA"] 				, Nil})
					aAdd(aDadosC5, {"C5_ZZOBS" 			,oContent["CABECALHO"][_nZ]["C5_ZZOBS"] 				, Nil})
					aAdd(aDadosC5, {"C5_VEND1" 			,oContent["CABECALHO"][_nZ]["C5_VEND1"]					, Nil})
					aAdd(aDadosC5, {"C5_DESC1" 			,oContent["CABECALHO"][_nZ]["C5_DESC1"]					, Nil})
					aAdd(aDadosC5, {"C5_TABELA" 		,oContent["CABECALHO"][_nZ]["C5_TABELA"]				, Nil})
					aAdd(aDadosC5, {"C5_ZZNPEXT" 		,oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]				, Nil})
					aAdd(aDadosC5, {"C5_ZZTPPED" 		,oContent["CABECALHO"][_nZ]["C5_ZZTPPED"]				, Nil})
					aAdd(aDadosC5, {"C5_MOEDA" 			,oContent["CABECALHO"][_nZ]["C5_MOEDA"] 				, Nil})
					aAdd(aDadosC5, {"C5_XIDIUGU" 		,oContent["CABECALHO"][_nZ]["C5_XIDIUGU"]				, Nil})
					aAdd(aDadosC5, {"C5_ZZORIGE" 		,oContent["CABECALHO"][_nZ]["C5_ZZORIGE"]				, Nil})
					aAdd(aDadosC5, {"C5_TRANSP" 		,oContent["CABECALHO"][_nZ]["C5_TRANSP"]				, Nil})				
					
					FWVetByDic( aDadosC5, 'SC5' )
					
					CONOUT("[POST] [wsPVGetPos] [ Array de Cabecalho do Pedido de Vendas preenchido com sucesso ]")

					//**********************************************************************************
					// Preenche o Array dos Itens do Pedido de Vendas
					//**********************************************************************************
					For _nX := 1 to Len(oContent["CABECALHO"][_nZ]["ITENS"])
						
						aLin := {}
						aAdd(aLin, {"C6_ITEM"		,RetAsc(StrZero(_nX),2,.T.)								, Nil})
						aAdd(aLin, {"C6_PRODUTO" 	,oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_PRODUTO"]	, Nil})
						aAdd(aLin, {"C6_QTDVEN" 	,oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_QTDVEN"]	, Nil})
						aAdd(aLin, {"C6_PRCVEN" 	,oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_PRCVEN"]	, Nil})
						aAdd(aLin, {"C6_OPER" 		,oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_OPER"] 	, Nil})
						
						aAdd(aLin,	{"AUTDELETA"	,"N"													, Nil})
						aAdd(aDadosC6,aLin)
					
					Next _nX

					CONOUT("[POST] [wsPVGetPos] [ " + Alltrim(Str(Len(oContent["CABECALHO"][_nZ]["ITENS"]))) + " ítens Array dos Itens do Pedido de Vendas preenchido com sucesso ]")

					//**********************************************************************************
					// Efetua o posicionamento das tabelas para  a inclusao do Pedido de Vendas 
					//**********************************************************************************
					SC6->(dbSetOrder(1))
					SC6->(dbGoTop())
					SA1->(dbSetOrder(1))
					SA1->(dbGoTop())
					SA2->(dbSetOrder(1))
					SA2->(dbGoTop())
					SB1->(dbSetOrder(1))
					SB1->(dbGoTop())
					SB2->(dbSetOrder(1))
					SB2->(dbGoTop())
					SE4->(dbSetOrder(1))
					SE4->(dbGoTop())
					SF4->(dbSetOrder(1))
					SF4->(dbGoTop())               

					//**********************************************************************************
					// Restauro o indice da Tabela SC5 
					//**********************************************************************************
					SC5->(dbSetOrder(1))
					SC5->(dbGoTop())

					//**********************************************************************************
					// Efetua a inclusao do Pedido de Vendas via MsExecAuto 
					//**********************************************************************************
					MSExecAuto({| w, x, y, z|MATA410(w,x,y,z)}, aDadosC5, aDadosC6 ,_nOpc, .F. )
				
					//******************************************************************************
					// Em caso de erro de ExecAuto 
					//******************************************************************************
					If lMsErroAuto	

						//******************************************************************************
						// Efetua o Rollback do Numero do Pedido 
						//******************************************************************************
						DisarmTransaction() 

						//******************************************************************************
						// Grava o Error.log na pasta System\log_ped 
						//******************************************************************************
						aLogAuto:= GetAutoGrLog()

						//******************************************************************************
						// Efetua o tratamento da mensagem de erro, retirando CLRF 
						//******************************************************************************
						For _nY := 1 to Len(aLogAuto) 
							cError 	+= aLogAuto[_nY]  
						Next _nY
						
						cArqLog	:= "\log_ped\" + oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"] + " - " +Time()+ ".log"
						MemoWrite(cArqLog, cError)

						//------------------------------------------------------------------------------
						// 
						//------------------------------------------------------------------------------
						If Select(cAliasTMP) > 0
							(cAliasTMP)->(dbCloseArea())
						Endif
						
						//******************************************************************************
						// Monta o Json de Retorno com erro 
						//******************************************************************************
						oJsonRet := JsonObject():New()
						
						oJsonRet["SUCESSMESSAGE"]	:= EncodeUTF8(IIF(_nOpc == 3 ,"Pedido de Vendas não Incluído","Pedido de Vendas não Alterado"))
						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : sucessMessage ] ' + EncodeUTF8(IIF(_nOpc == 3 ,"Pedido de Vendas não Incluído","Pedido de Vendas não Alterado")) )
						
						oJsonRet["LOJA"]			:= oContent["CABECALHO"][_nZ]["C5_LOJACLI"]
						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : loja ] ' + oContent["CABECALHO"][_nZ]["C5_LOJACLI"] )

						oJsonRet["EMPRESA"]			:= oContent["CABECALHO"][_nZ]["EMPRESA"]
						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : empresa ] ' +  oContent["CABECALHO"][_nZ]["EMPRESA"])
						
						oJsonRet["PEDIDOAFV"]		:= oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]
						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : pedidoAFV ] ' + oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"])

						oJsonRet["PEDIDOPROTHEUS"]	:= _cNumPed 
						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : pedidoProtheus ] ' + _cNumPed)

						oJsonRet["ARQLOG"]			:= StrTran(EncodeUTF8(cError),'\r\n','')
						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : arqLog ] ' + StrTran(EncodeUTF8(cError),'\r\n',''))

						oJsonRet["FILIAL"]         	:= oContent["CABECALHO"][_nZ]["C5_FILIAL"]
						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : filial ] ' + oContent["CABECALHO"][_nZ]["C5_FILIAL"])

						oJsonRet["CLIENTE"]			:= oContent["CABECALHO"][_nZ]["C5_CLIENTE"]
						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : cliente ] ' + oContent["CABECALHO"][_nZ]["C5_CLIENTE"])
						
						oJsonRet["OPCAO"]			:= EncodeUTF8(IIF(_nOpc == 3, "3 - Inclusão", "4 - Alteração"))
						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : opcao ] ' + EncodeUTF8(IIF(_nOpc == 3, "3 - Inclusão", "4 - Alteração")))

						oJsonRet["SUCESSCODE"]     	:= 202  // 202 - Código padrão HTML de POST recebido, porem nao processado
						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : opcao ] 202' )

						aAdd(oResponse["Resultados"], oJsonRet)
				
					Else

						//******************************************************************************
						// CONFIRMA A GRAVAÇÃO DAS TABELAS PARA EVITAR CASOS DE DUPLICIDADE DE REGISTROS
						//******************************************************************************
						SC5->(DBCOMMIT())
						SC6->(DBCOMMIT())

						//------------------------------------------------------------------------------
						// fecha o alias caso esteja em uso
						//------------------------------------------------------------------------------
						If Select(cAliasTMP) > 0
							(cAliasTMP)->(dbCloseArea())
							cAliasTMP := GetNextAlias()
						Endif
						
						BeginSql Alias cAliasTMP

							SELECT		C5_FILIAL, C5_NUM, C5_CLIENTE, C5_LOJACLI
							FROM 		%Table:SC5% SC5
							WHERE		C5_ZZNPEXT = %exp:_cPedAFV%
								AND         C5_FILIAL = %exp:cFilant%
								AND 		SC5.%NotDel%
							ORDER BY 	C5_NUM

						EndSql

						dbSelectArea(cAliasTMP)
						(caliasTMP)->(dbGoTop())

						//******************************************************************************
						// Monta o Json de Retorno realizado com sucesso
						//******************************************************************************
						oJsonRet := JsonObject():New()						
						oJsonRet["SUCESSMESSAGE"]  	:= EncodeUTF8(IIF(_nOpc == 3 ,"Pedido de Vendas AFV incluído com sucesso","Pedido de Vendas AFV alterado com sucesso" ))
						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : sucessMessage ] ' + EncodeUTF8(IIF(_nOpc == 3 ,"Pedido de Vendas AFV incluído com sucesso","Pedido de Vendas AFV alterado com sucesso" )) )
						
						oJsonRet["LOJA"]			:= (cAliasTMP)->C5_LOJACLI							
						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : loja ] ' + IIF(ValType((cAliasTMP)->C5_LOJACLI) == "U", "",(cAliasTMP)->C5_LOJACLI))
						
						oJsonRet["EMPRESA"]			:= cEmpant									
						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : empresa ] '+ cEmpant )
						
						oJsonRet["PEDIDOAFV"]		:= _cPedAFV
						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : pedidoAFV ] '+ _cPedAFV)
						
						oJsonRet["PEDIDOPROTHEUS"]	:= (cAliasTMP)->C5_NUM 
						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : pedidoProtheus] '+ IIF(ValType((cAliasTMP)->C5_NUM) == "U", "",(cAliasTMP)->C5_NUM))
						
						oJsonRet["FILIAL"]         	:= (cAliasTMP)->C5_FILIAL								
						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : filial ] '+ IIF(ValType((cAliasTMP)->C5_FILIAL) == "U", "",(cAliasTMP)->C5_FILIAL))
						
						oJsonRet["CLIENTE"]			:= (cAliasTMP)->C5_CLIENTE								
						Conout( '[v - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : cliente ] '+ IIF(ValType((cAliasTMP)->C5_CLIENTE) == "U", "",(cAliasTMP)->C5_CLIENTE))
						
						oJsonRet["OPCAO"]			:= EncodeUTF8(IIF(_nOpc == 3, "3 - Inclusão", "4 - Alteração"))
						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : opcao ] '+ EncodeUTF8(IIF(_nOpc == 3, "3 - Inclusão", "4 - Alteração")))
						
						oJsonRet["SUCESSCODE"]     	:= 201  				                        
						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : sucessCode] 201' ) 
						
						aAdd(oResponse["Resultados"], oJsonRet)

						Conout( '[wsPVGetPos - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Pedido Protheus : ]' + _cNumPed +' - Importação Finalizada. ' + iif(_nOpc == 3, "Pedido Incluido com sucesso !!!", "Pedido Alterado com sucesso !!!"))

					Endif
				
				Endif
                
					//******************************************************************************
					// Apago os valores dos Arrays para o proximo Post/Pedido de Vendas
					//******************************************************************************
					aDadosC5 	:= {}
					aLin		:= {}
					aDadosC6	:= {}					

            Next _nZ
		Endif
    Else

		nError := 400
		cError := 'Body esperado no formato "application/json".'
		lRet  := .F.

	Endif

    DBCLOSEALL()

	If nError = 0
		Self:SetResponse(oResponse:toJson())
        FreeObj(oResponse)
        FreeObj(oJsonRet)
        FreeObj(oContent)
	Else
		SetRestFault(nError, EncodeUTF8(cError))
        FreeObj(oResponse)
        FreeObj(oJsonRet)
        FreeObj(oContent)
	Endif
	
    //**********************************************************************************
	// Restaura a area de trabalho original
	//**********************************************************************************
	RestArea(aArea)	

Return lRet
