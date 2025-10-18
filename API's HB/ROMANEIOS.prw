#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.CH"

WSRESTFUL romaneios DESCRIPTION "Lista e Inclui romaneios no ERP Protheus "

	WSDATA page      AS Integer OPTIONAL
	WSDATA pageSize  AS Integer OPTIONAL
	WSDATA searchKey AS String  OPTIONAL
	WSDATA days      AS Integer OPTIONAL
	WSDATA endDate   AS Integer OPTIONAL
	WSDATA startDate AS Integer OPTIONAL

	WSMETHOD GET    DESCRIPTION 'Retorna lista de Romaneios' WSSYNTAX '/romaneios' /*PATH 'romaneios'*/ PRODUCES APPLICATION_JSON
	WSMETHOD POST   DESCRIPTION 'Inclusão de registro'       WSSYNTAX '/romaneios' /*PATH 'romaneios'*/ PRODUCES APPLICATION_JSON
	WSMETHOD PUT    DESCRIPTION 'Exclusão de registro'       WSSYNTAX '/romaneios' /*PATH 'romaneios'*/ PRODUCES APPLICATION_JSON

END WSRESTFUL

//-------------------------------------------------------------------
/*/{Protheus.doc} GET / romaneios
Retorna a lista de Romaneios.

@param SearchKey , caracter, chave de pesquisa utilizada em diversos campos
 Page , numerico, numero da pagina 
 PageSize , numerico, quantidade de registros por pagina

@return cResponse , caracter, JSON contendo a lista de clientes
/*/
//-------------------------------------------------------------------

WSMETHOD GET WSRECEIVE searchKey, page, pageSize, endDate, startDate, days WSSERVICE taxinvoices

	Local aDados := {}

	Local cAliasWS  := GetNextAlias()
	Local cJson      := ''
	Local cSearchKey := self:searchKey
	Local nRecord    := 0
	Local nPage      := self:page
	Local nPageSize  := self:pageSize
	Local dEndDate   := self:endDate
	Local dStartDate := self:startDate
	Local cSearch    := ''
	Local nDays      := self:days
	Local cWhereSF2  := "AND SA1.A1_FILIAL = '"+xFilial('SA1')+"'"
	Local cWhereSUA  := ""
	Local cEmailEmp  := alltrim(GetMV("MV_RELACNT"))
	Local aEmpresa   := {}
	Local lRet       := .T.
	Local nCount     := 0
	Local nAtuPage   := 0
	Local nStart     := 1
	Local nReg       := 0
	Local nAux       := 0

	Local oJson := JsonObject():New()

	Default cSearchKey := ''
	Default nPage      := 1
	Default nPageSize  := 10
	Default nDays      := 30

	//-------------------------------------------------------------------
	// Tratativas para a chave de busca
	//-------------------------------------------------------------------
	If !Empty(cSearchKey)
		cSearch := AllTrim(Upper(cSearchKey))
		cWhereSF2  += " AND ( SA1.A1_COD LIKE '%" + cSearch + "%' OR "
		cWhereSF2  += " SA1.A1_LOJA LIKE '%" + cSearch + "%' OR "
		cWhereSF2  += " SA1.A1_NOME LIKE '%" + FwNoAccent(cSearch) + "%' OR "
		cWhereSF2  += " SA1.A1_NOME LIKE '%" + cSearch + "%' OR "
		cWhereSF2  += " SF2.F2_DOC LIKE '%" + zTiraZeros(cSearch) + "%' ) "

		cWhereSUA  += " AND ( SA1.A1_COD LIKE '%" + cSearch + "%' OR "
		cWhereSUA  += " SA1.A1_LOJA LIKE '%" + cSearch + "%' OR "
		cWhereSUA  += " SA1.A1_NOME LIKE '%" + FwNoAccent(cSearch) + "%' OR "
		cWhereSUA  += " SA1.A1_NOME LIKE '%" + cSearch + "%' OR "
		cWhereSUA  += " SUA.UA_DOC LIKE '%" + zTiraZeros(cSearch) + "%' OR "
		cWhereSUA  += " SUA.UA_NUM LIKE '%" + zTiraZeros(cSearch) + "%' ) "

	EndIf

	cWhereSUA := '%'+cWhereSUA+'%'
	cWhereSF2 := '%'+cWhereSF2+'%'

	//-------------------------------------------------------------------
	// Query para selecionar clientes
	//-------------------------------------------------------------------
	BEGINSQL Alias cAliasWS

        SELECT 
            SF2.F2_FILIAL,    
            SF2.F2_DOC, 
            SF2.F2_SERIE, 
            SF2.F2_CLIENTE, 
            SF2.F2_LOJA,
            SF2.F2_EMISSAO, 
            SA1.A1_NOME, 
            SA1.A1_END,
            SA1.A1_COMPLEM,
            SA1.A1_EST,
            SA1.A1_MUN,
            SA1.A1_CGC,
            SA1.A1_PESSOA,  
            SA1.A1_INSCRM, 
            SA1.A1_COD_MUN,
            SA1.A1_BAIRRO,
            SA1.A1_CEP,
            SA1.A1_ENDENT,
            SA1.A1_COMPENT,
            SA1.A1_ESTE,
            SA1.A1_MUNE,
            SA1.A1_CODMUNE,
            SA1.A1_BAIRROE,
            SA1.A1_CEPE,
            SA1.A1_EMAIL,
            SC5.C5_NUM, 
            SF2.F2_VEND1, 
            SF2.F2_TRANSP, 
            SC5.C5_NOTA, 
            SC5.C5_SERIE,
            SF3.F3_CFO AS F2_CFOP,
            SF3.F3_ESPECIE AS F2_ESPECIE,
            SF2.F2_MENNOTA,
            SC5.C5_CLIENT, 
            SC5.C5_LOJAENT,
            SA1_ENT.A1_NOME AS A1_NOMENT,
            SA1_ENT.A1_PESSOA AS A1_PESENT,
            SF2.F2_ESPECI1, 
            SF2.F2_VOLUME1, 
            SF2.F2_PBRUTO, 
            SF2.F2_VALBRUT, 
            SF2.F2_CHVNFE, 
            SF2.F2_UFDEST, 
            SF2.F2_UFORIG,
            SF2.F2_XOBJECT, 
            SF2.F2_ZZSTREM, 
            'SF2' AS ORIGEM 
        FROM %table:SF2% SF2
        INNER JOIN %table:SA1% SA1 
            ON SF2.F2_CLIENTE = SA1.A1_COD
            AND SF2.F2_LOJA = SA1.A1_LOJA
            AND SA1.%NotDel%
        INNER JOIN %table:SC5% SC5 
            ON SF2.F2_CLIENTE = SC5.C5_CLIENTE
            AND SF2.F2_LOJA = SC5.C5_LOJACLI
            AND SF2.F2_DOC = SC5.C5_NOTA
            AND SF2.F2_SERIE = SC5.C5_SERIE
            AND SC5.%NotDel%
        LEFT JOIN %table:SF3% SF3
            ON SF2.F2_FILIAL = SF3.F3_FILIAL 
            AND SF2.F2_DOC = SF3.F3_NFISCAL 
            AND SF2.F2_SERIE = SF3.F3_SERIE 
            AND SF2.F2_CLIENTE = SF3.F3_CLIEFOR 
            AND SF2.F2_LOJA = SF3.F3_LOJA
            AND SF3.%NotDel%
        LEFT JOIN %table:SA1% SA1_ENT
            ON SC5.C5_CLIENT = SA1_ENT.A1_COD 
            AND SC5.C5_LOJAENT = SA1_ENT.A1_LOJA
            AND SA1_ENT.%NotDel%
        WHERE SF2.F2_EMISSAO BETWEEN %exp:dStartDate% AND %exp:dEndDate%
            AND SF2.%NotDel%
            %exp:cWhereSF2%

        UNION ALL

        SELECT
            ISNULL(SUA.UA_FILIAL, '') AS F2_FILIAL,  
            SUA.UA_NUM AS F2_DOC, 
            '' AS F2_SERIE, 
            SUA.UA_CLIENTE, 
            SUA.UA_LOJA,
            SUA.UA_EMISSAO, 
            SA1.A1_NOME, 
            SA1.A1_END, 
            SA1.A1_COMPLEM, 
            SA1.A1_EST, 
            SA1.A1_MUN, 
            SA1.A1_CGC,
            SA1.A1_PESSOA, 
            SA1.A1_INSCRM, 
            SA1.A1_COD_MUN, 
            SA1.A1_BAIRRO, 
            SA1.A1_CEP, 
            SA1.A1_ENDENT, 
            SA1.A1_COMPENT, 
            SA1.A1_ESTE, 
            SA1.A1_MUNE,
            SA1.A1_CODMUNE, 
            SA1.A1_BAIRROE, 
            SA1.A1_CEPE,
            SA1.A1_EMAIL,
            SUA.UA_NUMSC5 AS C5_NUM,
            SUA.UA_VEND AS F2_VEND1, 
            SUA.UA_TRANSP AS F2_TRANSP,
            SUA.UA_DOC AS C5_NOTA, 
            SUA.UA_SERIE AS C5_SERIE,
            '' AS F2_CFOP,
            'DLC' AS F2_ESPECIE,
            ISNULL(SYP.YP_TEXTO, '') AS F2_MENNOTA,
            SUA.UA_CLIENT AS C5_CLIENT,
            SUA.UA_LOJAENT AS C5_LOJAENT,
            SA1_ENT.A1_NOME AS A1_NOMENT,
            SA1_ENT.A1_PESSOA AS A1_PESENT,
            '' AS F2_ESPECI1, 
            0 AS F2_VOLUME1, 
            0 AS F2_PBRUTO, 
            0 AS F2_VALBRUT, 
            '' AS F2_CHVNFE, 
            '' AS F2_UFDEST, 
            '' AS F2_UFORIG,
            SUA.UA_ZZRAST AS F2_XOBJECT,
            SUA.UA_ZZSTREM AS F2_ZZSTREM,
            'SUA' AS ORIGEM 
        FROM %table:SUA% SUA
        INNER JOIN %table:SA1% SA1 
            ON SA1.A1_COD = SUA.UA_CLIENTE
            AND SA1.A1_LOJA = SUA.UA_LOJA
            AND SA1.%NotDel%
        LEFT JOIN %table:SA1% SA1_ENT
            ON SUA.UA_CLIENT = SA1_ENT.A1_COD 
            AND SUA.UA_LOJAENT = SA1_ENT.A1_LOJA
            AND SA1_ENT.%NotDel%
        LEFT JOIN (
            SELECT YP_CHAVE, 
                MAX(CASE WHEN YP_SEQ = 1 THEN RTRIM(YP_TEXTO) END) AS YP_TEXTO
            FROM %table:SYP% 
            WHERE YP_CAMPO = 'UA_CODOBS' 
                AND %NotDel%
            GROUP BY YP_CHAVE
        ) SYP ON SYP.YP_CHAVE = SUA.UA_CODOBS
        WHERE SUA.UA_EMISSAO BETWEEN %exp:dStartDate% AND %exp:dEndDate%
            AND SUA.%NotDel%
            %exp:cWhereSUA%

        ORDER BY F2_EMISSAO DESC, F2_DOC DESC, F2_SERIE DESC, F2_CLIENTE DESC, F2_LOJA DESC, ORIGEM DESC
	ENDSQL

	If (cAliasWS)->(!Eof())

		//-------------------------------------------------------------------
		// Identifica a quantidade de registro no alias temporário
		//-------------------------------------------------------------------
		COUNT TO nRecord

		//-------------------------------------------------------------------
		// nStart -> primeiro registro da pagina
		// nReg -> numero de registros do inicio da pagina ao fim do arquivo
		//-------------------------------------------------------------------
		nStart   := (( nPage - 1 ) * nPageSize ) + 1
		nAtuPage := (nStart + nPageSize - 1) / nPageSize

		If nPage > 1			
			nReg     := nRecord
			nTotPage := Ceiling( nRecord / nPageSize )
		Else
			nReg     := nRecord
			nTotPage := Ceiling( nRecord / nPageSize )
		EndIf

		//-------------------------------------------------------------------
		// Posiciona no primeiro registro.
		//-------------------------------------------------------------------
		(cAliasWS)->(DBGoTop())

		//-------------------------------------------------------------------
		// Valida a exitencia de mais paginas
		//-------------------------------------------------------------------
		If  nTotPage > nAtuPage
			oJson['hasNext'] := .T.
		Else
			oJson['hasNext'] := .F.
		EndIf
	Else
		//-------------------------------------------------------------------
		// Nao encontrou registros
		//-------------------------------------------------------------------

		lRet := .F.

		Self:setStatus(404)
		oJson['hasNext']  := .F.
		oJson['nTotPage'] := 0
		oJson['nReg']     := 0
		oJson['nStart']   := 0
		oJson['clients']  := {}
		oJson['error']  := 'Nenhum cliente encontrado.'

		Self:SetContentType('application/json')
		Self:SetResponse( FwJsonSerialize(oJson) ) //-- Seta resposta
		Return(lRet)
	EndIf

	//-------------------------------------------------------------------
	// Alimenta array de clientes
	//-------------------------------------------------------------------
	While ( cAliasWS )->( ! Eof() )

		nCount++
		aEmpresa := {}

		If nCount >= nStart

			nAux++
			aAdd( aDados , JsonObject():New() )

			if (( cAliasWS )->F2_FILIAL ) == " " .OR. Empty( ( cAliasWS )->F2_FILIAL )
				aDados[nAux]['filial']          := '01'
			Else
				aDados[nAux]['filial']          := ( cAliasWS )->F2_FILIAL
			EndIf

			aEmpresa := zEmpresa( aDados[nAux]['filial'] )

			aDados[nAux]['codEmpresa']          := AllTrim( EncodeUTF8(aEmpresa[1][2]) )
			aDados[nAux]['codFilEmpresa']       := AllTrim( EncodeUTF8(aEmpresa[2][2]) )
			aDados[nAux]['nomeEmpresa']         := AllTrim( EncodeUTF8(aEmpresa[3][2]) )
			aDados[nAux]['cnpjEmpresa']         := AllTrim( EncodeUTF8(aEmpresa[4][2]) )
			aDados[nAux]['inscEmpresa']         := AllTrim( EncodeUTF8(aEmpresa[5][2]) )
			aDados[nAux]['cidadeEmpresa']       := AllTrim( EncodeUTF8(aEmpresa[6][2]) )
			aDados[nAux]['estEmpresa']          := AllTrim( EncodeUTF8(aEmpresa[7][2]) )
			aDados[nAux]['endEmpresa']          := AllTrim( EncodeUTF8(aEmpresa[8][2]) )
			aDados[nAux]['bairroEmpresa']       := AllTrim( EncodeUTF8(aEmpresa[9][2]) )
			aDados[nAux]['cepEmpresa']          := AllTrim( EncodeUTF8(aEmpresa[10][2]) )
			aDados[nAux]['complEmpresa']        := AllTrim( EncodeUTF8(aEmpresa[11][2]) )
			aDados[nAux]['telEmpresa']          := AllTrim( EncodeUTF8(aEmpresa[12][2]) )
			aDados[nAux]['emailEmpresa']        := cEmailEmp
			aDados[nAux]['doc']                 := ( cAliasWS )->F2_DOC
			aDados[nAux]['serie']               := ( cAliasWS )->F2_SERIE
			aDados[nAux]['cliente']             := ( cAliasWS )->F2_CLIENTE
			aDados[nAux]['loja']                := ( cAliasWS )->F2_LOJA
			aDados[nAux]['emissao']             := ( cAliasWS )->F2_EMISSAO
			aDados[nAux]['nome']                := AllTrim( EncodeUTF8( ( cAliasWS )->A1_NOME ) )
			aDados[nAux]['endereco']            := AllTrim( EncodeUTF8( ( cAliasWS )->A1_END ) )
			aDados[nAux]['complemento']         := AllTrim( EncodeUTF8( ( cAliasWS )->A1_COMPLEM ) )
			aDados[nAux]['estado']              := AllTrim( EncodeUTF8( ( cAliasWS )->A1_EST ) )
			aDados[nAux]['municipio']           := AllTrim( EncodeUTF8( ( cAliasWS )->A1_MUN ) )
			aDados[nAux]['cnpjCPF']             := AllTrim( ( cAliasWS )->A1_CGC )
			aDados[nAux]['tipoPessoa']          := AllTrim( ( cAliasWS )->A1_PESSOA )
			aDados[nAux]['inscricao']           := AllTrim( ( cAliasWS )->A1_INSCRM )
			aDados[nAux]['codMunicipio']        := AllTrim( ( cAliasWS )->A1_COD_MUN )
			aDados[nAux]['bairro']              := AllTrim( EncodeUTF8( ( cAliasWS )->A1_BAIRRO ) )
			aDados[nAux]['cep']                 := AllTrim( ( cAliasWS )->A1_CEP )
			aDados[nAux]['enderecoEntrega']     := AllTrim( EncodeUTF8( ( cAliasWS )->A1_ENDENT ) )
			aDados[nAux]['complementoEntrega']  := AllTrim( EncodeUTF8( ( cAliasWS )->A1_COMPENT ) )
			aDados[nAux]['estadoEntrega']       := AllTrim( EncodeUTF8( ( cAliasWS )->A1_ESTE ) )
			aDados[nAux]['municipioEntrega']    := AllTrim( EncodeUTF8( ( cAliasWS )->A1_MUNE ) )
			aDados[nAux]['codMunicipioEntrega'] := AllTrim( ( cAliasWS )->A1_CODMUNE )
			aDados[nAux]['bairroEntrega']       := AllTrim( EncodeUTF8( ( cAliasWS )->A1_BAIRROE ) )
			aDados[nAux]['cepEntrega']          := AllTrim( ( cAliasWS )->A1_CEPE )
			aDados[nAux]['email']               := Lower(AllTrim( EncodeUTF8( ( cAliasWS )->A1_EMAIL ) ) )
			aDados[nAux]['num']                 := AllTrim( EncodeUTF8( ( cAliasWS )->C5_NUM ) )
			aDados[nAux]['vendedor']            := AllTrim( EncodeUTF8( ( cAliasWS )->F2_VEND1 ) )
			aDados[nAux]['transp']              := AllTrim( EncodeUTF8( ( cAliasWS )->F2_TRANSP ) )
			aDados[nAux]['nota']                := AllTrim( EncodeUTF8( ( cAliasWS )->C5_NOTA ) )
			aDados[nAux]['serieSC5']            := AllTrim( EncodeUTF8( ( cAliasWS )->C5_SERIE ) )
			aDados[nAux]['cfop']                := AllTrim( EncodeUTF8( ( cAliasWS )->F2_CFOP ) )
			aDados[nAux]['especie']             := AllTrim( EncodeUTF8( ( cAliasWS )->F2_ESPECIE ) )
			aDados[nAux]['observacao']          := AllTrim( EncodeUTF8( ( cAliasWS )->F2_MENNOTA ) )
			aDados[nAux]['cliSC5']              := AllTrim( EncodeUTF8( ( cAliasWS )->C5_CLIENT ) )
			aDados[nAux]['lojaSC5']             := AllTrim( EncodeUTF8( ( cAliasWS )->C5_LOJAENT ) )
			aDados[nAux]['nomeSC5']             := AllTrim( EncodeUTF8( ( cAliasWS )->A1_NOMENT ) )
			aDados[nAux]['pessoaSC5']           := AllTrim( EncodeUTF8( ( cAliasWS )->A1_PESENT ) )
			aDados[nAux]['especieEmb']          := AllTrim( EncodeUTF8( ( cAliasWS )->F2_ESPECI1 ) )
			aDados[nAux]['volume']              := ( cAliasWS )->F2_VOLUME1
			aDados[nAux]['pesoBruto']           := ( cAliasWS )->F2_PBRUTO
			aDados[nAux]['valorBruto']          := ( cAliasWS )->F2_VALBRUT
			aDados[nAux]['chaveNfe']            := AllTrim( EncodeUTF8( ( cAliasWS )->F2_CHVNFE ) )
			aDados[nAux]['ufDestino']           := AllTrim( EncodeUTF8( ( cAliasWS )->F2_UFDEST ) )
			aDados[nAux]['ufOrigem']            := AllTrim( EncodeUTF8( ( cAliasWS )->F2_UFORIG ) )
			aDados[nAux]['objeto']              := AllTrim( ( cAliasWS )->F2_XOBJECT )
			aDados[nAux]['status']              := AllTrim( ( cAliasWS )->F2_ZZSTREM )
			aDados[nAux]['origem']              := ( cAliasWS )->ORIGEM

			If Len(aDados) >= nPageSize
				Exit
			EndIf

		EndIf

		(cAliasWS)->(DBSkip())

	EndDo

	(cAliasWS)->(DBCloseArea())

	oJson['nTotPage'] := nTotPage
	oJson['nReg']     := nReg
	oJson['nStart']   := nStart
	oJson['nAtuPage'] := nAtuPage
	oJson['clients']  := aDados

	//-------------------------------------------------------------------
	// Serializa objeto Json
	//-------------------------------------------------------------------
	cJson:= FwJsonSerialize(oJson)

	//-------------------------------------------------------------------
	// Elimina objeto da memoria
	//-------------------------------------------------------------------
	FreeObj(oJson)

	Self:SetContentType('application/json')
	Self:SetResponse( cJson ) //-- Seta resposta

Return(lRet)

WSMETHOD POST WSRECEIVE WSSERVICE taxinvoices

	Local lRet              := .T.
	Local aDados            := {}
	Local oJson             := Nil
	Local cJson             := Self:GetContent()
	Local cError            := ''
	Local cDirLog           := '\x_logs\'
	Local cArqLog           := ''
	Local cErrorLog         := ''
	Local cFilialx          := ''
	Local cDocumento        := ''
	Local cSerie            := ''
	Local cCliente          := ''
	Local cLoja             := ''
	Local nReg              := 0
	Local nI                := 0
	Local jResponse         := JsonObject():New()

	Private lMsErroAuto     := .F.
	Private lMsHelpAuto     := .T.
	Private lAutoErrNoFile  := .T.

	//Se não existir a pasta de logs, cria
	IF ! ExistDir(cDirLog)
		MakeDir(cDirLog)
	EndIF

	//Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
	Self:SetContentType('application/json')
	oJson  := JsonObject():New()
	cError := oJson:FromJson(cJson)

	nReg := Len(oJson['objetos'])

	For nI := 1 To nReg

		cFilialx   := oJson['objetos'][nI]:GetJsonObject('filial')
		cDocumento := PADR(oJson['objetos'][nI]:GetJsonObject('documento') , TAMSX3("F2_DOC")[1])
		cSerie     := PADR(oJson['objetos'][nI]:GetJsonObject('serie') , TAMSX3("F2_SERIE")[1])
		cCliente   := oJson['objetos'][nI]:GetJsonObject('cliente')
		cLoja      := oJson['objetos'][nI]:GetJsonObject('loja')

		//Se tiver algum erro no Parse, encerra a execução
		If ! Empty(cError)

			//Define o retorno para o WebService
			//SetRestFault(500, 'Falha ao obter JSON') //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
			Self:setStatus(500)
			oObjeto := JsonObject():New()
			oObjeto['errorId']   := 'NEW004'
			oObjeto['error']     := 'Parse do JSON'
			oObjeto['solution']  := 'Erro ao fazer o Parse do JSON'
			aAdd(aDados, oObjeto)

		ElseIf oJson['objetos'][nI]:GetJsonObject('tabela') == 'SF2'

			DbSelectArea("SF2")
			SF2->(DbSetOrder(1)) // F2_FILIAL + F2_DOC + F2_SERIE + F2_CLIENTE + F2_LOJA + F2_FORMUL + F2_TIPO

			//Se conseguir posicionar na Nota Fiscal
			If SF2->(MsSeek(cFilialx + cDocumento + cSerie + cCliente + cLoja))

				//Grava numero de Objeto de rastreio
				RecLock("SF2", .F.)
				SF2->F2_XOBJECT := oJson['objetos'][nI]:GetJsonObject('idObjeto')
				SF2->F2_ZZIDREM := oJson['objetos'][nI]:GetJsonObject('idRemessa')
				SF2->(MsUnlock())

				Self:setStatus(200)
				oObjeto := JsonObject():New()
				oObjeto['message']  := oJson['objetos'][nI]:GetJsonObject('idObjeto') + " - Gravado com sucesso"
				aAdd(aDados, oObjeto)

				lRet := .F.
			Else
				//Grava o arquivo de log
				cErrorLog := 'Registro não encontrado na tabela SF2: ' + cFilialx + cDocumento + cSerie + cCliente + cLoja
				cArqLog := 'zWSProdutos_New_' + dToS(Date()) + '_' + StrTran(Time(), ':', '-') + '.log'
				MemoWrite(cDirLog + cArqLog, cErrorLog)

				//Define o retorno para o WebService
				//SetRestFault(404, cErrorLog) //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
				Self:setStatus(404)
				oObjeto := JsonObject():New()
				oObjeto['errorId']   := 'NEW006'
				oObjeto['error']     := EncodeUTF8('Registro não encontrado na tabela SF2')
				oObjeto['solution']  := EncodeUTF8('Não foi possível localizar o registro na tabela SF2, verifique os dados informados')
				aAdd(aDados, oObjeto)

				lRet := .F.
			EndIf

		Elseif oJson['objetos'][nI]:GetJsonObject('tabela') == 'SUA'

			DbSelectArea("SUA")
			SUA->(DbSetOrder(1)) // UA_FILIAL + UA_NUM

			cFilialx := "  "

			//Se conseguir posicionar no Atendimento
			If SUA->(MsSeek(cFilialx + cDocumento))

				//Grava numero de Objeto de rastreio
				RecLock("SUA", .F.)
				SUA->UA_ZZRAST  := oJson['objetos'][nI]:GetJsonObject('idObjeto')
				SUA->UA_ZZIDREM := oJson['objetos'][nI]:GetJsonObject('idRemessa')
				SUA->(MsUnlock())

				Self:setStatus(200)
				oObjeto := JsonObject():New()
				oObjeto['message']   := oJson['objetos'][nI]:GetJsonObject('idObjeto') + " - Gravado com sucesso"
				aAdd(aDados, oObjeto)

				lRet := .T.

			Else
				//Grava o arquivo de log
				cErrorLog := EncodeUTF8('Registro não encontrado na tabela SUA: ' + cFilialx + cDocumento)
				cArqLog := 'zWSProdutos_New_' + dToS(Date()) + '_' + StrTran(Time(), ':', '-') + '.log'
				MemoWrite(cDirLog + cArqLog, cErrorLog)

				//Define o retorno para o WebService
				//SetRestFault(404, cErrorLog) //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
				Self:setStatus(404)
				oObjeto := JsonObject():New()
				oObjeto['errorId']   := 'NEW007'
				oObjeto['error']     := EncodeUTF8('Registro não encontrado na tabela SUA')
				oObjeto['solution']  := EncodeUTF8('Não foi possível localizar o registro na tabela SUA, verifique os dados informados')
				aAdd(aDados, oObjeto)

				lRet := .F.

			EndIf

		Else

			//Grava o arquivo de log
			cArqLog := 'zWSProdutos_New_' + dToS(Date()) + '_' + StrTran(Time(), ':', '-') + '.log'
			MemoWrite(cDirLog + cArqLog, cErrorLog)

			//Define o retorno para o WebService
			//SetRestFault(500, cErrorLog) //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
			Self:setStatus(500)
			oObjeto := JsonObject():New()
			oObjeto['errorId']   := 'NEW005'
			oObjeto['error']     := EncodeUTF8('Erro na inclusão do registro' + ' - ' + oJson['objetos'][nI]:GetJsonObject('idObjeto'))
			oObjeto['solution']  := EncodeUTF8('Não foi possivel incluir o registro, foi gerado um arquivo de log em ' + cDirLog + cArqLog)
			aAdd(aDados, oObjeto)

			lRet := .F.

		EndIf

	Next

	//Define o retorno
	jResponse['objects'] := aDados
	Self:SetResponse(jResponse:toJSON())

Return lRet

WSMETHOD PUT WSRECEIVE WSSERVICE taxinvoices

	Local lRet              := .T.
	Local aDados            := {}
	Local oJson             := Nil
	Local cJson             := Self:GetContent()
	Local cError            := ''
	Local cDirLog           := '\x_logs\'
	Local cArqLog           := ''
	Local cErrorLog         := ''
	Local cFilialx          := ''
	Local cDocumento        := ''
	Local cSerie            := ''
	Local cCliente          := ''
	Local cLoja             := ''
	Local nReg              := 0
	Local nI                := 0
	Local jResponse         := JsonObject():New()

	Private lMsErroAuto     := .F.
	Private lMsHelpAuto     := .T.
	Private lAutoErrNoFile  := .T.

	//Se não existir a pasta de logs, cria
	IF ! ExistDir(cDirLog)
		MakeDir(cDirLog)
	EndIF

	//Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
	Self:SetContentType('application/json')
	oJson  := JsonObject():New()
	cError := oJson:FromJson(cJson)

	nReg := Len(oJson['objetos'])

	For nI := 1 To nReg

		cFilialx   := oJson['objetos'][nI]:GetJsonObject('filial')
		cDocumento := PADR(oJson['objetos'][nI]:GetJsonObject('documento') , TAMSX3("F2_DOC")[1])
		cSerie     := PADR(oJson['objetos'][nI]:GetJsonObject('serie') , TAMSX3("F2_SERIE")[1])
		cCliente   := oJson['objetos'][nI]:GetJsonObject('cliente')
		cLoja      := oJson['objetos'][nI]:GetJsonObject('loja')

		//Se tiver algum erro no Parse, encerra a execução
		If !Empty(cError)

			//Define o retorno para o WebService
			//SetRestFault(404, cErrorLog) //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
			Self:setStatus(500)
			oObjeto := JsonObject():New()
			oObjeto['errorId']   := 'NEW004'
			oObjeto['error']     := 'Parse do JSON'
			oObjeto['solution']  := 'Erro ao fazer o Parse do JSON'
			aAdd(aDados, oObjeto)

			lRet := .F.

		ElseIf oJson['objetos'][nI]:GetJsonObject('tabela') == 'SF2'

			DbSelectArea("SF2")
			SF2->(DbSetOrder(1)) // F2_FILIAL + F2_DOC + F2_SERIE + F2_CLIENTE + F2_LOJA + F2_FORMUL + F2_TIPO

			//Se conseguir posicionar na Nota Fiscal
			If SF2->(MsSeek(cFilialx + cDocumento + cSerie + cCliente + cLoja))

				//Grava numero de Objeto de rastreio
				RecLock("SF2", .F.)
                    SF2->F2_XOBJECT := ""
                    SF2->F2_ZZIDREM := ""
				SF2->(MsUnlock())

				Self:setStatus(200)
				oObjeto := JsonObject():New()
				oObjeto['message']   := oJson['objetos'][nI]:GetJsonObject('idObjeto') + " - Deletado com sucesso"
				aAdd(aDados, oObjeto)

				lRet := .T.

			Else
				//Grava o arquivo de log
				cErrorLog := EncodeUTF8('Registro não encontrado na tabela SF2: ' + cFilialx + cDocumento + cSerie + cCliente + cLoja)
				cArqLog := 'zWSProdutos_New_' + dToS(Date()) + '_' + StrTran(Time(), ':', '-') + '.log'
				MemoWrite(cDirLog + cArqLog, cErrorLog)

				//Define o retorno para o WebService
				//SetRestFault(404, cErrorLog) //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
				Self:setStatus(404)
				oObjeto := JsonObject():New()
				oObjeto['errorId']   := 'NEW006'
				oObjeto['error']     := EncodeUTF8('Registro não encontrado na tabela SF2')
				oObjeto['solution']  := EncodeUTF8('Não foi possível localizar o registro na tabela SF2, verifique os dados informados')
				aAdd(aDados, oObjeto)

				lRet := .F.

			EndIf

		Elseif oJson['objetos'][nI]:GetJsonObject('tabela') == 'SUA'

			DbSelectArea("SUA")
			SUA->(DbSetOrder(1)) // UA_FILIAL + UA_NUM

			cFilialx := "  "

			//Se conseguir posicionar no Atendimento
			If SUA->(MsSeek(cFilialx + cDocumento))

				//Grava numero de Objeto de rastreio
				RecLock("SUA", .F.)
                    SUA->UA_ZZRAST  := ""
                    SUA->UA_ZZIDREM := ""
				SUA->(MsUnlock())

				Self:setStatus(201)
				oObjeto := JsonObject():New()
				oObjeto['message']   := oJson['objetos'][nI]:GetJsonObject('idObjeto') + " - Deletado com sucesso"
				aAdd(aDados, oObjeto)

				lRet := .T.

			Else
				//Grava o arquivo de log
				cErrorLog := EncodeUTF8('Registro não encontrado na tabela SUA: ' + cFilialx + cDocumento)
				cArqLog := 'zWSProdutos_New_' + dToS(Date()) + '_' + StrTran(Time(), ':', '-') + '.log'
				MemoWrite(cDirLog + cArqLog, cErrorLog)

				//Define o retorno para o WebService
				//SetRestFault(404, cErrorLog) //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
				Self:setStatus(404)
				oObjeto := JsonObject():New()
				oObjeto['errorId']   := 'NEW007'
				oObjeto['error']     := EncodeUTF8('Registro não encontrado na tabela SUA')
				oObjeto['solution']  := EncodeUTF8('Não foi possível localizar o registro na tabela SUA, verifique os dados informados')
				aAdd(aDados, oObjeto)

				lRet := .F.

			EndIf

		Else

			//Grava o arquivo de log
			cArqLog := 'zWSProdutos_New_' + dToS(Date()) + '_' + StrTran(Time(), ':', '-') + '.log'
			MemoWrite(cDirLog + cArqLog, cErrorLog)

			//Define o retorno para o WebService
			//SetRestFault(500, cErrorLog) //caso queira usar esse comando, você não poderá usar outros retornos, como os abaixo
			Self:setStatus(500)
			oObjeto := JsonObject():New()
			oObjeto['errorId']   := 'NEW005'
			oObjeto['error']     := EncodeUTF8('Erro na inclusão do registro' + ' - ' + oJson['objetos'][nI]:GetJsonObject('idObjeto'))
			oObjeto['solution']  := EncodeUTF8('Não foi possivel incluir o registro, foi gerado um arquivo de log em ' + cDirLog + cArqLog)
			aAdd(aDados, oObjeto)

			lRet := .F.

		EndIf

	Next

	//Define o retorno
	jResponse['objects'] := aDados
	Self:SetResponse(jResponse:toJSON())

Return lRet

Static Function zTiraZeros(cTexto)

	Local aArea     := GetArea()
	Local cRetorno  := ""
	Local lContinua := .T.
	Default cTexto  := ""

	//Pegando o texto atual
	cRetorno := Alltrim(cTexto)

	//Enquanto existir zeros a esquerda
	While lContinua
		//Se a priemira posição for diferente de 0 ou não existir mais texto de retorno, encerra o laço
		If SubStr(cRetorno, 1, 1) <> "0" .Or. Len(cRetorno) ==0
			lContinua := .f.
		EndIf

		//Se for continuar o processo, pega da próxima posição até o fim
		If lContinua
			cRetorno := Substr(cRetorno, 2, Len(cRetorno))
		EndIf
	EndDo

	RestArea(aArea)
Return cRetorno

Static Function zEmpresa(cEmpresa)

	Local aArea      := FWGetArea()
	Local cMensagem  := ""
	Local aCampos    := { ;
		"M0_CODIGO",;    //Posição [1]
	"M0_CODFIL",;    //Posição [2]
	"M0_NOMECOM",;   //Posição [3]
	"M0_CGC",;       //Posição [4]
	"M0_INSCM",;     //Posição [5]
	"M0_CIDENT",;    //Posição [6]
	"M0_ESTENT",;    //Posição [7]
	"M0_ENDENT",;    //Posição [8]
	"M0_BAIRENT",;   //Posição [9]
	"M0_CEPENT",;    //Posição [10]
	"M0_COMPENT",;   //Posição [11]
	"M0_TEL";        //Posição [12]
	}

	Local aEmpresa := {}

	//Busca os campos da filial "01"
	aEmpresa := FWSM0Util():GetSM0Data(, cEmpresa, aCampos)

	//Se encontrou, monta uma mensagem e exibe
	If Len(aEmpresa) > 0
		cMensagem += "M0_NOMECOM: " + aEmpresa[3][2] + CRLF
		cMensagem += "M0_CGC: "     + aEmpresa[4][2] + CRLF
		cMensagem += "M0_CIDENT: "  + aEmpresa[6][2] + CRLF
		//FWAlertInfo(cMensagem, "Teste FWSM0Util")
	EndIf

	FWRestArea(aArea)
Return aEmpresa
