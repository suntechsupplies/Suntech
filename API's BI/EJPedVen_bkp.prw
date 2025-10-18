#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"
#Include "Totvs.ch"
#Include "topconn.ch"

#Define Desc_Rest_	"Serviço REST para Disponibilizar dados de Pedidos de venda - Ejecty"
#Define Desc_Get_  	"Retorna Pedidos de venda informado de acordo com parametro de data"
#Define Desc_Post_	"Cria o Pedidos de venda de acordo com as informacoes passadas"

User Function EjPedVen()

Return(.T.)

WSRESTFUL EjPedGP DESCRIPTION Desc_Rest_

	WSDATA nPag			As Integer
	WSDATA nFlagCab		As Integer
	WSDATA nFlagIt		As Integer
	WSDATA TENANTID     AS STRING

	WSMETHOD GET  DESCRIPTION Desc_Get_ 	WSSYNTAX "/EjPedGP||/EjPedGP/{}"
	WSMETHOD POST DESCRIPTION Desc_Post_ 	WSSYNTAX "/EjPedGP/{Pedido}"

END WSRESTFUL

WSMETHOD GET WSRECEIVE nPag, nFlagCab, nFlagIt, TenantId WSSERVICE EjPedGP

	LOCAL nPag		:= Self:nPag
	Local nFlagCab	:= Self:nFlagCab		// 1 = Sim / 2 = Nao
	Local nFlagIt	:= Self:nFlagIt
	Local aArea		:= GetArea()
	Local cAliasTmp	:= GetNextAlias()
	Local aDebug	:= {}
	Local cPed		:= ''
	Local cSetResp	:= ''
	Local cPedCli	:= ''
	//Local nGetDate	:= SuperGetMV("MV_B2BDIAS",,90)
	Local _cEmpresa	:= ""
	Local _cFilial	:= ""
	Local nX
	Local nZ
	Local nPagFim

	If FindFunction("WfPrepEnv")


		If !Empty(SELF:TENANTID)
			_cEmpresa := Left(Upper(SELF:TENANTID), At(",",Upper(SELF:TENANTID))-1)
			_cFilial  := Substr(Upper(SELF:TENANTID), At(",",Upper(SELF:TENANTID))+1)

			cEmpAnt := _cEmpresa
			cFilAnt := _cFilial
			cNumemp := _cFilial + _cEmpresa

			CONOUT("[GET] [RPEDGETPOSEJPEDGP - MÉTODO GET] TENANTID : " + SELF:TENANTID + "[cEmpant] : " + cEmpant + "[cFilant] : " + cFilant + " Empresa conectada !!! ")

		Else

			CONOUT("[GET] [RPEDGETPOSEJPEDGP - MÉTODO GET] TENANTID : " + SELF:TENANTID + "[cEmpant] : " + cEmpant + "[cFilant] : " + cFilant + " Empresa não conectada. Verificar header TenantId !!! ")
			SetRestFault(501, EncodeUTF8("Empresa não conectada. Verificar parametro TenantId do Header da requisicao "))

			Return()

		EndIf

		// define o tipo de retorno do método
		::SetContentType("application/json")

		//Verifica se há conexão em aberto, caso haja fecha.
		IF Select(cAliasTmp) > 0
			dbSelectArea(cAliasTmp)
			(cAliasTmp)->(dbCloseArea())
		EndIf

		// Efetua a consulta conforme os parâmetros passados
		BeginSql Alias cAliasTmp

			SELECT *, (( DENSE_RANK() OVER ( ORDER BY C5_NUM) ) / 10 ) + 1 AS PAG, '0' AS VALORPEDIDO, '0' AS VALORFATURADO,
			C5_FILIAL, C5_ZZNPEXT, C5_CLIENTE, C5_NOTA, C5_EMISSAO, C5_ZZORIGE, C5_ZZTPPED, C5_CONDPAG, C5_TPFRETE, C5_VEND1, 
			C5_ZZCUPOM, C5_NUM, C6_PRODUTO, C6_DESCRI, C6_QTDVEN, C6_QTDVEN, C6_QTDENT, C6_DESCONT, C6_VALOR, B1_PESO, C6_ITEM
			FROM SC5010, SC6010, SB1010
			WHERE 0=0
			AND SC5010.C5_FILIAL  = SC6010.C6_FILIAL
			AND SC5010.C5_NUM     = SC6010.C6_NUM
			AND SC5010.C5_CLIENTE = SC6010.C6_CLI
			AND SC5010.C5_LOJACLI = SC6010.C6_LOJA
			AND SC6010.C6_PRODUTO = SB1010.B1_COD
			AND SC5010.D_E_L_E_T_ = ''
			AND SC6010.D_E_L_E_T_ = ''
			AND SB1010.D_E_L_E_T_ = ''
			AND SC5010.C5_EMISSAO BETWEEN '20221101' AND '20221231'

		EndSql

		//{ Fim }-----------------------------------------------------------------------------------

		aDebug := GetLastQuery()

		dbSelectArea(cAliasTmp)
		(cAliasTmp)->( DbGoTop() )

		While (cAliasTmp)->( !Eof() )
			nPagFim		:= (cAliasTmp)->PAG
			(cAliasTmp)->(dbSkip())
		EndDo

		// Posiciona no primeiro registro
		(cAliasTmp)->( DbGoTop() )

		If (cAliasTmp)->( Eof() ) .Or. ( nFlagIt = 2 .And. nFlagCab = 2 ) .Or. Empty(nFlagIt) .Or. Empty(nFlagCab) .Or. (nFlagCab + nFlagIt) > 4

			cSetResp := '{"Pedido": [{"Retorno":"Nao Existe Itens Nessa Pagina, reveja os parametros " }]}'

		ElseIf Empty(_cEmpresa) .Or. Empty(_cFilial)

			cSetResp := '{"Pedido": [{ "Retorno":"Nao passado o parametro TenantId no Header da Requisição, reveja os parametros " }]}'

		Else

			// Emite Json Cabecalho e Itens Pedido de Vendas
			If nFlagIt == 1 .And. nFlagCab == 1

				(cAliasTmp)->( DbGoTop() )
				nX			:= 1
				nZ			:= 1
				cSetResp	:= '{ "Cabecalho":[ '
				While (cAliasTmp)->( !Eof() )

					IF (cAliasTmp)->PAG = nPag

						If nX > 1
							cSetResp  +=' , '
						EndIf

						If TRIM( (cAliasTmp)->C5_FILIAL + (cAliasTmp)->C5_NUM ) <>  cPed
							cSetResp  += '{'
							cSetResp  += '"NUMPEDIDOEMP":"'			+ TRIM( (cAliasTmp)->C5_FILIAL + (cAliasTmp)->C5_NUM )
							cSetResp  += '","NUMPEDIDOB2B":"'		+ TRIM((cAliasTmp)->C5_ZZNPEXT)
							cSetResp  += '","CODIGOCLIENTE":"'		+ TRIM((cAliasTmp)->C5_CLIENTE + (cAliasTmp)->C5_LOJACLI)
							cSetResp  += '","STATUSPEDIDO":"'		+ TRIM(IIF ( EMPTY( TRIM( (cAliasTmp)->C5_NOTA ) ), "EM ABERTO", "FATURADO" ))
							cSetResp  += '","VALORPEDIDO":'			+ TRIM(cValToChar((cAliasTmp)->VALORPEDIDO))
							cSetResp  += ',"VALORFATURADO":' 		+ TRIM(cValToChar((cAliasTmp)->VALORFATURADO))
							cSetResp  += ',"DATAPEDIDO":"' 			+ TRIM((cAliasTmp)->C5_EMISSAO)
							cSetResp  += '","ORIGEMPEDIDO":"' 		+ TRIM((cAliasTmp)->C5_ZZORIGE)
							cSetResp  += '","TIPOPEDIDO":"'			+ TRIM((cAliasTmp)->C5_ZZTPPED)
							cSetResp  += '","CODIGOCONDPAGTO":"'	+ TRIM((cAliasTmp)->C5_CONDPAG)
							cSetResp  += '","DESCRICAOFRETE":"'		+ TRIM((cAliasTmp)->C5_TPFRETE)
							cSetResp  += '","VENDEDOR1":"'	    	+ TRIM((cAliasTmp)->C5_VEND1)
							cSetResp  += '","CUPOM":"'		    	+ TRIM((cAliasTmp)->C5_ZZCUPOM)
							cSetResp  += '","Itens": ['
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

				// Emite apenas Json apenas do Cabecalho
			ElseIf nFlagIt = 2 .And. nFlagCab = 1

				(cAliasTmp)->( DbGoTop() )

				nX			:= 1
				cSetResp	:= '{ "Cabecalho":[ '

				While (cAliasTmp)->( !Eof() )

					IF (cAliasTmp)->PAG = nPag

						If nX > 1
							cSetResp  +=' , '
						EndIf

						cSetResp  += '{'
						cSetResp  += '"NUMPEDIDOEMP":"'			+ TRIM( (cAliasTmp)->C5_FILIAL + (cAliasTmp)->C5_NUM )
						cSetResp  += '","NUMPEDIDOB2B":"'		+ TRIM((cAliasTmp)->C5_ZZNPEXT)
						cSetResp  += '","CODIGOCLIENTE":"'		+ TRIM((cAliasTmp)->C5_CLIENTE + (cAliasTmp)->C5_LOJACLI)
						cSetResp  += '","STATUSPEDIDO":"'		+ TRIM(IIF ( EMPTY( TRIM( (cAliasTmp)->C5_NOTA ) ), "EM ABERTO", "FATURADO" ))
						cSetResp  += '","VALORPEDIDO":'			+ TRIM(cValToChar((cAliasTmp)->VALORPEDIDO))
						cSetResp  += ',"VALORFATURADO":' 		+ TRIM(cValToChar((cAliasTmp)->VALORFATURADO))
						cSetResp  += ',"DATAPEDIDO":"' 			+ TRIM((cAliasTmp)->C5_EMISSAO)
						cSetResp  += '","ORIGEMPEDIDO":"' 		+ TRIM((cAliasTmp)->C5_ZZORIGE)
						cSetResp  += '","TIPOPEDIDO":"'			+ TRIM((cAliasTmp)->C5_ZZTPPED)
						cSetResp  += '","CODIGOCONDPAGTO":"'	+ TRIM((cAliasTmp)->C5_CONDPAG)
						cSetResp  += '","DESCRICAOFRETE":"'		+ TRIM((cAliasTmp)->C5_TPFRETE)
						cSetResp  += '","VENDEDOR1":"'	    	+ TRIM((cAliasTmp)->C5_VEND1)
						cSetResp  += '","CUPOM":"'		    	+ TRIM((cAliasTmp)->C5_ZZCUPOM)
						cSetResp  += '"}'
						nX++
						(cAliasTMP)->(dbSkip())
					Else
						(cAliasTMP)->(dbSkip())
						LOOP
					EndIf
				EndDo

				cSetResp  += ']'
				cSetResp  += ',"PaginalAtual":'				+ cValToChar(Self:nPag)
				cSetResp  += ',"TotalDePaginas":'			+ cValToChar(nPagFim)
				cSetResp  += '}'

				// Emite apenas Json apenas dos Itens
			ElseIf nFlagIt = 1 .And. nFlagCab = 2

				(cAliasTmp)->( DbGoTop() )
				nZ			:= 1
				cSetResp  += '{"Itens": ['

				While (cAliasTmp)->( !Eof() )

					IF (cAliasTmp)->PAG = nPag


						If nZ > 1
							cSetResp  +=' , '
						EndIf

						cSetResp  += '{'
						cSetResp  += '"NUMPEDIDOEMP":"'			+ TRIM( (cAliasTmp)->C5_FILIAL + (cAliasTmp)->C5_NUM )
						cSetResp  += '","CODIGOPRODUTO":"'		+ TRIM((cAliasTmp)->C6_PRODUTO)
						cSetResp  += '","DESCRICAOPRODUTO":"'  	+ StrTran(StrTran(TRIM((cAliasTmp)->C6_DESCRI),'"',''),"'","")
						cSetResp  += '","QTDEVENDA":'		   	+ TRIM(cValToChar((cAliasTmp)->C6_QTDVEN))
						cSetResp  += ',"SALDOQTDEVENDA":'	   	+ TRIM(cValToChar((cAliasTmp)->C6_QTDVEN - (cAliasTmp)->C6_QTDENT))
						cSetResp  += ',"DESCONTO":'				+ TRIM(cValToChar((cAliasTmp)->C6_DESCONT))
						cSetResp  += ',"VALORVENDA":' 	       	+ TRIM(cValToChar((cAliasTmp)->C6_VALOR))
						cSetResp  += ',"PESOLIQUIDO":' 			+ TRIM(cValToChar((cAliasTmp)->B1_PESO))
						cSetResp  += ',"ITEMPRODUTO":"' 	   	+ TRIM((cAliasTmp)->C6_ITEM)
						cSetResp  += '"}'
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
		Endif
	EndIf
	//Fecha a tabela
	(cAliasTmp)->(DbCloseArea())

	//Envia o JSON Gerado para a aplicação Cliente
	::SetResponse( cSetResp )

	RestArea(aArea)

Return(.T.)

/**********************************************************************************************
* {Protheus.doc} 	POST EjPedGP                                                             *
**********************************************************************************************/

WSMETHOD POST WSRECEIVE tenantId WSSERVICE EjPedGP

	Local oResponse 			as object
	Local oContent   			as object
	Local _nW, _nX, _nY, _nZ 	as numeric
	Local aArea					:= {}
	Local aDadosC5				:= {}
	Local aDadosC6				:= {}
	Local aLin					:= {}
	Local aLogAuto				:= {}
	Local cArqLog				:= ''
	Local cError				:= ''
 	Local nError				:= 0
 	Local _nOpc					:= 3
 	Local _cPedB2B				:= ''
 	Local _cNumPed				:= ''
 	Local _aErro				:= {}
 	Local _lSegue				:= .F.
	Local _cEmpresa				:= "01"
	Local _cFilial				:= "02"
    Local _cDataEmi             := ""

 	Private lMsErroAuto			:= .F.
 	Private lMsHelpAuto			:= .T.
 	Private lAutoErrNoFile		:= .T.



    If !Empty(SELF:TENANTID)
        
        _cEmpresa := Left(Upper(SELF:TENANTID), At(",",Upper(SELF:TENANTID))-1)
        _cFilial  := Substr(Upper(SELF:TENANTID), At(",",Upper(SELF:TENANTID))+1)

        cEmpAnt := _cEmpresa
        cFilAnt := _cFilial
        cNumemp := _cEmpresa + _cFilial
        conout("Empresa : " + cEmpant + " Filial : " + cFilant + " Numero da Empresa : " +cNumemp + " Conectada com sucesso !!! " )

        //---------------------------------------------------------
        // Usado para não dar erro de Alias does not exist
        //---------------------------------------------------------
        Sleep(2000)
    Else 

        CONOUT("[GET] [RPEDGETPOSEJPEDGP - MÉTODO POST] [cEmpant] : " + cEmpant + "[cFilant] : " + cFilant + " Empresa não conectada. Verificar header TenantId !!! ")
        SetRestFault(501, EncodeUTF8("Preencher o parametro TenantId no header da requisição. Consumo abortado por erro ou falta de parâmetros"))
        Return()

    EndIf


    //Cria o diretório para salvar os arquivos de log
    If !ExistDir("\log_B2B")
        MakeDir("\log_B2B")
    EndIf

	//******************************************************************************
	// Verifica se o body veio no formato JSon.
	//******************************************************************************
	If lower(Self:GetHeader("Content-Type", .F.)) == "application/json"

		oContent := JsonObject():New()
		oContent:FromJson(Self:GetContent())  // Transforma o JSON do body em um objeto JSON Protheus.


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

				//**********************************************************************************
				// Popula a Tag de Data do Pedido
				//**********************************************************************************
				oResponse["Data"] 		:= oContent["CABECALHO"][_nZ]["C5_ZZDTEMI"]

				//***************************************************************************************
				// Guardo empresa e filial para passar para Prepare Environment e Consultar Pedido AFV
				//***************************************************************************************
				_cEmpresa 	:= oContent["CABECALHO"][_nZ]["EMPRESA"]
				_cFilial	:= oContent["CABECALHO"][_nZ]["C5_FILIAL"]
				_cPedB2B	:= oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]
				_cDataEmi   := oContent["CABECALHO"][_nZ]["C5_ZZDTEMI"]

				//**********************************************************************************
				// Salva a area atual
				//**********************************************************************************
				aArea := GetArea()

				//**********************************************************************************
				// Preparo a Variavel _lSegue para o proximo registro
				//**********************************************************************************
				_lSegue := .F.

				//----------------------------------------------------------------------------------------
				// Alterado por Carlos Eduardo Saturnino para tratar os valores enviados como Null
				//----------------------------------------------------------------------------------------
				aAdd(aDadosC5, {"C5_TIPO"	 		,Iif(ValType(oContent["CABECALHO"][_nZ]["C5_TIPO"])     =="U","",oContent["CABECALHO"][_nZ]["C5_TIPO"])	 				, Nil})
				aAdd(aDadosC5, {"C5_CLIENTE" 		,Iif(ValType(oContent["CABECALHO"][_nZ]["C5_CLIENTE"])  =="U","",Substr(oContent["CABECALHO"][_nZ]["C5_CLIENTE"],1,6))  , Nil})
				aAdd(aDadosC5, {"C5_LOJACLI" 		,Iif(ValType(oContent["CABECALHO"][_nZ]["C5_CLIENTE"])  =="U","",Substr(oContent["CABECALHO"][_nZ]["C5_CLIENTE"],7,2))	, Nil})
				aAdd(aDadosC5, {"C5_LOJAENT" 		,iif(ValType(oContent["CABECALHO"][_nZ]["C5_LOJACLI"])  =="U","",oContent["CABECALHO"][_nZ]["C5_LOJACLI"])				, Nil})
				aAdd(aDadosC5, {"C5_EMISSAO" 		,Iif(ValType(oContent["CABECALHO"][_nZ]["C5_EMISSAO"])  =="U","",StoD(oContent["CABECALHO"][_nZ]["C5_EMISSAO"])	)       , Nil})
				aAdd(aDadosC5, {"C5_CONDPAG" 		,Iif(ValType(oContent["CABECALHO"][_nZ]["C5_CONDPAG"])  =="U","",oContent["CABECALHO"][_nZ]["C5_CONDPAG"])				, Nil})
				aAdd(aDadosC5, {"C5_TPFRETE" 		,Iif(ValType(oContent["CABECALHO"][_nZ]["C5_TPFRETE"])  =="U","",oContent["CABECALHO"][_nZ]["C5_TPFRETE"]) 			    , Nil})
				aAdd(aDadosC5, {"C5_FRETE" 			,Iif(ValType(oContent["CABECALHO"][_nZ]["C5_FRETE"])    =="U","",oContent["CABECALHO"][_nZ]["C5_FRETE"]) 				, Nil})
				aAdd(aDadosC5, {"C5_MENNOTA" 		,Iif(ValType(oContent["CABECALHO"][_nZ]["C5_MENNOTA"])  =="U","",oContent["CABECALHO"][_nZ]["C5_MENNOTA"]) 				, Nil})
				aAdd(aDadosC5, {"C5_ZZOBS" 			,Iif(ValType(oContent["CABECALHO"][_nZ]["C5_ZZOBS"])    =="U","",oContent["CABECALHO"][_nZ]["C5_ZZOBS"]) 				, Nil})
				aAdd(aDadosC5, {"C5_VEND1" 			,Iif(ValType(oContent["CABECALHO"][_nZ]["C5_VEND1"])    =="U","",oContent["CABECALHO"][_nZ]["C5_VEND1"])				, Nil})
				aAdd(aDadosC5, {"C5_DESC1" 			,Iif(ValType(oContent["CABECALHO"][_nZ]["C5_DESC1"])    =="U","",oContent["CABECALHO"][_nZ]["C5_DESC1"])				, Nil})
				aAdd(aDadosC5, {"C5_TABELA" 		,Iif(ValType(oContent["CABECALHO"][_nZ]["C5_TABELA"])   =="U","",oContent["CABECALHO"][_nZ]["C5_TABELA"])				, Nil})
				aAdd(aDadosC5, {"C5_ZZNPEXT" 		,Iif(ValType(oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"])	=="U","",Alltrim(oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]))	    , Nil})
				aAdd(aDadosC5, {"C5_ZZTPPED" 		,Iif(ValType(oContent["CABECALHO"][_nZ]["C5_ZZTPPED"])	=="U","",oContent["CABECALHO"][_nZ]["C5_ZZTPPED"])			    , Nil})
				aAdd(aDadosC5, {"C5_ZZDTEMI" 		,Iif(ValType(oContent["CABECALHO"][_nZ]["C5_ZZDTEMI"])  =="U","",Stod(oContent["CABECALHO"][_nZ]["C5_ZZDTEMI"]))		, Nil})
				aAdd(aDadosC5, {"C5_ZZCUPOM" 		,Iif(ValType(oContent["CABECALHO"][_nZ]["C5_ZZCUPOM"])  =="U","",oContent["CABECALHO"][_nZ]["C5_ZZCUPOM"])				, Nil})
				aAdd(aDadosC5, {"C5_ZZORIGE" 		,"B2B"													                                                                , Nil})
				aAdd(aDadosC5, {"C5_MOEDA" 			,Iif(ValType(oContent["CABECALHO"][_nZ]["C5_MOEDA"])    =="U","",oContent["CABECALHO"][_nZ]["C5_MOEDA"])				, Nil})		// Incluido em 06/08/2021 por erro na API
				aAdd(aDadosC5, {"C5_FRETE" 			,Iif(ValType(oContent["CABECALHO"][_nZ]["C5_FRETE"])    =="U","",oContent["CABECALHO"][_nZ]["C5_FRETE"])				, Nil})		// Incluido em 31/08/2020 a pedido do Marcos/Michael


				FWVetByDic( aDadosC5, 'SC5' )

				//**********************************************************************************
				// Preenche o Array dos Itens do Pedido de Vendas
				//**********************************************************************************
				For _nX := 1 to Len(oContent["CABECALHO"][_nZ]["ITENS"])

					//----------------------------------------------------------------------------------------
					// Alterado por Carlos Eduardo Saturnino para tratar os valores enviados como Null
					//----------------------------------------------------------------------------------------
					aLin := {}
					aAdd(aLin, {"C6_ITEM"		,Iif(ValType(oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_ITEM"])       =="U","",oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_ITEM"])	, Nil})
					aAdd(aLin, {"C6_PRODUTO" 	,Iif(ValType(oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_PRODUTO"])  	=="U","",oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_PRODUTO"]), Nil})
					aAdd(aLin, {"C6_QTDVEN" 	,Iif(ValType(oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_QTDVEN"])     =="U","",oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_QTDVEN"])	, Nil})
					aAdd(aLin, {"C6_PRCVEN" 	,Iif(ValType(oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_PRCVEN"])     =="U","",oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_PRCVEN"])	, Nil})
					aAdd(aLin, {"C6_OPER" 		,Iif(ValType(oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_OPER"])       =="U","",oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_OPER"]) 	, Nil})
					aAdd(aLin, {"C6_DESCONT" 	,Iif(ValType(oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_DESCONT"])    =="U","",oContent["CABECALHO"][_nZ]["ITENS"][_nX]["C6_DESCONT"]), Nil})

					FWVetByDic( aLin, 'SC6' )
					aAdd(aLin, {"AUTDELETA"	,"N"														, Nil})
					aAdd(aDadosC6,aLin)


				Next _nX

				//**********************************************************************************
				// Efetua o posicionamento das tabelas para  a inclusao do Pedido de Vendas
				//**********************************************************************************
				SC6->(dbSelectArea("SC6"))
				SC6->(dbSetOrder(1))
				SC6->(dbGoTop())
				SA1->(dbSelectArea("SA1"))
				SA1->(dbSetOrder(1))
				SA1->(dbGoTop())
				SA2->(dbSelectArea("SA2"))
				SA2->(dbSetOrder(1))
				SA2->(dbGoTop())
				SB1->(dbSelectArea("SB1"))
				SB1->(dbSetOrder(1))
				SB1->(dbGoTop())
				SB2->(dbSelectArea("SB2"))
				SB2->(dbSetOrder(1))
				SB2->(dbGoTop())
				SE4->(dbSelectArea("SE4"))
				SE4->(dbSetOrder(1))
				SE4->(dbGoTop())
				SF4->(dbSelectArea("SF4"))
				SF4->(dbSetOrder(1))
				SF4->(dbGoTop())
				SC5->(dbSelectArea("SC5"))
				SC5->(dbSetOrder(1))
				SC5->(dbGoTop())

				dbSelectArea("SC5")
				SC5->(dbSetOrder(12))
				SC5->(dbGoTop())

				//**********************************************************************************
				// Pesquiso o Pedido para identificar se e inclusão ou alteracao
				//**********************************************************************************
				If ! SC5->(dbSeek( FwFilial("SC5") + padr(_cPedB2B,GetSX3Cache("C5_ZZNPEXT", "X3_TAMANHO"))))
					_nOpc   := 3				// Inclui
				Else
					_nOpc 	:= 4				// Altera
					_cNumPed:= SC5->C5_NUM
				Endif

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
						cError 	+= aLogAuto[_nY] + CHR(13)+CHR(10)
					Next _nY

					cArqLog	:= "\log_B2B\" + oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"] + " - " +Time()+ ".log"
					MemoWrite(cArqLog, cError)

					//******************************************************************************
					// Monta o Json de Retorno com erro
					//******************************************************************************
					oJsonRet := JsonObject():New()

					oJsonRet["SUCESSMESSAGE"]	:= EncodeUTF8(IIF(_nOpc == 3 ,"Pedido de Vendas nao Incluído","Pedido de Vendas nao Alterado"))
					Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : sucessMessage ] ' + EncodeUTF8(IIF(_nOpc == 3 ,"Pedido de Vendas não Incluído","Pedido de Vendas não Alterado")) )

					oJsonRet["loja"]			:= oContent["CABECALHO"][_nZ]["C5_LOJACLI"]
					Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : loja ] ' + oContent["CABECALHO"][_nZ]["C5_LOJACLI"] )

					oJsonRet["empresa"]			:= cEmpant
					Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : empresa ] ' + cEmpant )

					oJsonRet["pedidoB2B"]		:= Alltrim(oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"])
					Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : pedidoB2b ] ' + oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"] )

					oJsonRet["pedidoProtheus"]	:= _cNumPed
					Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : pedidoProtheus ] ' + _cNumPed )

					oJsonRet["filial"]         	:= oContent["CABECALHO"][_nZ]["C5_FILIAL"]
					Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : filial ] ' + oContent["CABECALHO"][_nZ]["C5_FILIAL"] )

					oJsonRet["cliente"]			:= oContent["CABECALHO"][_nZ]["C5_CLIENTE"]
					Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : cliente ] ' + oContent["CABECALHO"][_nZ]["C5_CLIENTE"] )

					oJsonRet["opcao"]			:= EncodeUTF8(IIF(_nOpc == 3, "3 - Inclusao", "4 - Alteracao"))
					Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : opcao ] ' + EncodeUTF8(IIF(_nOpc == 3, "3 - Inclusao", "4 - Alteracao")) )

					oJsonRet["SUCESSCODE"]     	:= 202  // 202 - Código padrão HTML de POST recebido, porem nao processado
					Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"]+'] [ Log de retorno AFV : sucessCode ] 202')

					For _nW :=1 to Len(aLogAuto)
						Aadd(_aErro,JsonObject():new())
						_aErro[_nW]['LINHA_'+ StrTran(Str(_nW),' ','')] := StrTran(EncodeUTF8(aLogAuto[_nW]),'\r\n','')
					Next

					oJsonRet["ARQLOG"]			:= _aErro
					Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : ' + oContent["CABECALHO"][_nZ]["C5_ZZNPEXT"] +'] [ Log de retorno AFV : arqLog ]' + ArrTokStr(aLogAuto) )

					//aAdd(oResponse["Resultados"], oJsonRet)

				Else

					//******************************************************************************
					// Posiciona em cima do Cabec. do Pedido de Vendas e recupero o Num. do mesmo
					//******************************************************************************
					SC5->(dbSelectArea("SC5"))
					SC5->(dbSetOrder(12))
					SC5->(dbGoTop())
					If SC5->( dbSeek( PADR(_cFilial,2) + PADR(_cPedB2B,10)) )


						//******************************************************************************
						// Monta o Json de Retorno realizado com sucesso
						//******************************************************************************
						oJsonRet := JsonObject():New()
						oJsonRet["sucessMessage"]  	:= EncodeUTF8(IIF(_nOpc == 3 ,"Pedido de Vendas B2B incluido com sucesso","Pedido de Vendas B2B alterado com sucesso" ))
						Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+SC5->C5_NUM+'] [ Log de retorno AFV : sucessMessage ]' + EncodeUTF8(IIF(_nOpc == 3 ,"Pedido de Vendas B2B incluido com sucesso","Pedido de Vendas B2B alterado com sucesso" )) )

						oJsonRet["loja"]			:= SC5->C5_LOJACLI
						Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+SC5->C5_NUM+'] [ Log de retorno AFV : loja ]' + SC5->C5_LOJACLI )

						oJsonRet["empresa"]			:= cEmpant
						Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+SC5->C5_NUM+'] [ Log de retorno AFV : empresa ]' + cEmpant )

						oJsonRet["pedidoB2B"]		:= Alltrim(SC5->C5_ZZNPEXT)
						Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+SC5->C5_NUM+'] [ Log de retorno AFV : pedidoB2b ]' + SC5->C5_ZZNPEXT )

						oJsonRet["pedidoProtheus"]	:= SC5->C5_NUM
						Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+SC5->C5_NUM+'] [ Log de retorno AFV : pedidoProtheus ]' + SC5->C5_NUM )

						oJsonRet["filial"]         	:= SC5->C5_FILIAL
						Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+SC5->C5_NUM+'] [ Log de retorno AFV : filial ]' + SC5->C5_FILIAL )

						oJsonRet["cliente"]			:= SC5->C5_CLIENTE
						Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+SC5->C5_NUM+'] [ Log de retorno AFV : cliente ]' + SC5->C5_CLIENTE )

						oJsonRet["opcao"]			:= EncodeUTF8(IIF(_nOpc == 3, "3 - Inclusao", "4 - Alteracao"))
						Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+SC5->C5_NUM+'] [ Log de retorno AFV : opcao ]' + EncodeUTF8(IIF(_nOpc == 3, "3 - Inclusao", "4 - Alteracao")) )

						oJsonRet["sucessCode"]     	:= 201  				// 201 - Código padrão HTML de POST realizado com sucesso.
						Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+SC5->C5_NUM+'] [ Log de retorno AFV : sucessCode ] 201' )

						//aAdd(oResponse["resultados"], oJsonRet)

					Else

						Conout( '[EjPedGP - Post] [Thread '+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [Pedido Externo : '+SC5->C5_NUM+'] [ Log de retorno AFV : Pedido não Posicionado na tabela SC5 ] Pedido foi integrado, porém não gerou log ' )

					Endif
				Endif

				//******************************************************************************
				// Apago os valores dos Arrays para o proximo Post/Pedido de Vendas
				//******************************************************************************
				aDadosC5 	:= {}
				aLin		:= {}
				aDadosC6	:= {}

			Next _nZ

			//******************************************************************************
			// Destrava a funcao no Licence Server
			//******************************************************************************
			//UnlockByName("EjPVPost",.F.,.F.)

			//End Transaction
		Endif
	Else

		nError := 400
		cError := 'Body esperado no formato "application/json".'

	Endif

	//**********************************************************************************
	// Efetua o fechamento das tabelas
	//**********************************************************************************
	SC5->(dbCloseArea())
	SC6->(dbCloseArea())
	SA1->(dbCloseArea())
	SA2->(dbCloseArea())
	SB1->(dbCloseArea())
	SB2->(dbCloseArea())
	SE4->(dbCloseArea())
	SF4->(dbCloseArea())

	//**********************************************************************************
	// Efetua o reset no ambiente
	//**********************************************************************************
	//RpcClearEnv()

	//**********************************************************************************
	// Restaura a area de trabalho original
	//**********************************************************************************
	RestArea(aArea)

	If nError = 0
		Self:SetResponse(oJsonRet:toJson())
        FreeObj(oJsonRet)
        FreeObj(oContent)
        FreeObj(oResponse)
	Else
		SetRestFault(nError, EncodeUTF8(cError))
        FreeObj(oJsonRet)
        FreeObj(oContent)
        FreeObj(oResponse)
	Endif

    dbCloseAll()

    //----------------------------------------------------------------------------------
    // Derruba a thread para não travar o webservice
    //----------------------------------------------------------------------------------
    //__Quit()

Return(.T.)
