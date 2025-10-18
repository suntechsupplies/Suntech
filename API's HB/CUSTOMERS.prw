#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.CH"

WSRESTFUL customers DESCRIPTION "Lista e Inclui clientes no ERP Protheus "
 
    WSDATA page      AS Integer OPTIONAL
    WSDATA pageSize  AS Integer OPTIONAL
    WSDATA searchKey AS String  OPTIONAL
    
    WSMETHOD GET DESCRIPTION "Retorna lista de clientes" WSSYNTAX "/customers" /*PATH 'customers'*/ PRODUCES APPLICATION_JSON

END WSRESTFUL

//-------------------------------------------------------------------
/*/{Protheus.doc} GET / customers
Retorna a lista de clientes.

@param SearchKey , caracter, chave de pesquisa utilizada em diversos campos
 Page , numerico, numero da pagina 
 PageSize , numerico, quantidade de registros por pagina

@return cResponse , caracter, JSON contendo a lista de clientes
/*/
//-------------------------------------------------------------------

WSMETHOD GET WSRECEIVE searchKey, page, pageSize WSSERVICE customers
 
    Local aDados := {}
    
    Local cAliasWS  := GetNextAlias()
    Local cJson      := ''
    Local cSearchKey := self:searchKey
    Local nRecord    := 0
    Local nPage      := self:page
    Local nPageSize  := self:pageSize
    Local cSearch    := ''
    Local cWhere     := "AND SA1.A1_FILIAL = '"+xFilial('SA1')+"'"
    Local lRet       := .T.
    Local nCount     := 0
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
        cSearch := AllTrim( Upper( cSearchKey ) )
        cWhere  += " AND ( SA1.A1_COD LIKE '%" + cSearch + "%' OR "
        cWhere  += " SA1.A1_LOJA LIKE '%" + cSearch + "%' OR "
        cWhere  += " SA1.A1_NOME LIKE '%" + FwNoAccent( cSearch ) + "%' OR "
        cWhere  += " SA1.A1_NOME LIKE '%" + cSearch + "%' ) " 
    EndIf
 
    cWhere := '%'+cWhere+'%'
 
    //-------------------------------------------------------------------
    // Query para selecionar clientes
    //-------------------------------------------------------------------
    BEGINSQL Alias cAliasWS
    
        SELECT SA1.A1_COD, SA1.A1_LOJA, SA1.A1_CGC, SA1.A1_NOME, SA1.A1_NREDUZ, SA1.A1_CONTATO, SA1.A1_INSCR, 
            '' AS A1_INSTAGRAM, '' AS A1_WHATSAPP, SA1.A1_ZZDDDW, SA1.A1_TELW, 
            SA1.A1_DDD, SA1.A1_TEL, SA1.A1_EMAIL, SA1.A1_CEP, 
            SUBSTRING(SA1.A1_END, 1, CASE 
                WHEN CHARINDEX(',', SA1.A1_END) = 0 
                THEN LEN(SA1.A1_END)
                ELSE CHARINDEX(',', SA1.A1_END) - 1
            END) AS A1_END,
            SUBSTRING(SA1.A1_END, CASE 
                WHEN CHARINDEX(',', SA1.A1_END) = 0 
                THEN LEN(SA1.A1_END) + 1
                ELSE CHARINDEX(',', SA1.A1_END) + 1
            END, 1000) AS A1_NUMERO, 
            SA1.A1_BAIRRO, SA1.A1_COMPLEM, SA1.A1_MUN, SA1.A1_EST, 
            '' AS A1_LOGO, ACY.ACY_DESCRI, '' AS A1_PASSWORD
        FROM %table:SA1% SA1
        LEFT JOIN %table:ACY% ACY ON ACY.ACY_FILIAL = %xFilial:ACY%
            AND SA1.A1_GRPVEN = ACY.ACY_GRPVEN
            AND ACY.%NotDel%
        WHERE SA1.%NotDel%
            %exp:cWhere%
        ORDER BY SA1.A1_COD, SA1.A1_LOJA
        
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
        
        If nCount >= nStart
        
            nAux++ 
            aAdd( aDados , JsonObject():New() )
            
            aDados[nAux]['id']         := ( cAliasWS )->A1_COD + ( cAliasWS )->A1_LOJA
            aDados[nAux]['name']       := Alltrim( EncodeUTF8( ( cAliasWS )->A1_NOME ) )
            aDados[nAux]['unit']       := ( cAliasWS )->A1_LOJA
            aDados[nAux]['cnpj']       := ( cAliasWS )->A1_CGC
            aDados[nAux]['fantasia']   := Alltrim( EncodeUTF8( ( cAliasWS )->A1_NREDUZ ) )
            aDados[nAux]['contato']    := Alltrim( EncodeUTF8( ( cAliasWS )->A1_CONTATO ) )
            aDados[nAux]['inscricao']  := ( cAliasWS )->A1_INSCR
            aDados[nAux]['instagram']  := ( cAliasWS )->A1_INSTAGRAM
            aDados[nAux]['whatsapp']   := ( cAliasWS )->A1_WHATSAPP
            aDados[nAux]['dddWhats']   := ( cAliasWS )->A1_ZZDDDW
            aDados[nAux]['telWhats']   := ( cAliasWS )->A1_TELW
            aDados[nAux]['ddd']        := ( cAliasWS )->A1_DDD
            aDados[nAux]['telefone']   := ( cAliasWS )->A1_TEL
            aDados[nAux]['email']      := Alltrim( ( cAliasWS )->A1_EMAIL )
            aDados[nAux]['cep']        := ( cAliasWS )->A1_CEP
            aDados[nAux]['endereco']   := Alltrim( EncodeUTF8( ( cAliasWS )->A1_END ) )
            aDados[nAux]['numero']     := Alltrim( EncodeUTF8( ( cAliasWS )->A1_NUMERO ) )
            aDados[nAux]['bairro']     := Alltrim( EncodeUTF8( ( cAliasWS )->A1_BAIRRO ) )
            aDados[nAux]['complemento']:= Alltrim( EncodeUTF8( ( cAliasWS )->A1_COMPLEM ) )
            aDados[nAux]['cidade']     := Alltrim( EncodeUTF8( ( cAliasWS )->A1_MUN ) )
            aDados[nAux]['estado']     := ( cAliasWS )->A1_EST
            aDados[nAux]['logo']       := ( cAliasWS )->A1_LOGO
            aDados[nAux]['grupoVenda'] := Alltrim( EncodeUTF8( ( cAliasWS )->ACY_DESCRI ) )
            aDados[nAux]['password']   := ( cAliasWS )->A1_PASSWORD
        
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
