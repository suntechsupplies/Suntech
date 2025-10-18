#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.CH"
#Include "TopConn.ch"
 
/*/{Protheus.doc} WSRESTFUL products
Exemplo de Webservice usando REST
@author Atilio
@since 07/04/2022
@version 1.0
@see https://tdn.totvs.com/display/public/framework/WSRESTFUL
@obs 
 
    **** Apoie nosso projeto, se inscreva em https://www.youtube.com/TerminalDeInformacao ****
/*/
 
WSRESTFUL products DESCRIPTION 'WebService Cadastro de Produtos'
    //Atributos
    WSDATA id         AS STRING
    WSDATA updated_at AS STRING
    WSDATA limit      AS INTEGER
    WSDATA page       AS INTEGER
  
    //M�todos
    WSMETHOD GET  ID  DESCRIPTION 'Retorna o registro pesquisado' WSSYNTAX '/products/get_id?{id}'                       PATH 'get_id'        PRODUCES APPLICATION_JSON
    WSMETHOD GET  ALL DESCRIPTION 'Retorna todos os registros'    WSSYNTAX '/products/get_all?{updated_at, limit, page}' PATH 'get_all'       PRODUCES APPLICATION_JSON
    WSMETHOD POST NEW DESCRIPTION 'Inclus�o de registro'          WSSYNTAX '/products/new'                               PATH 'new'           PRODUCES APPLICATION_JSON
END WSRESTFUL
 
/*/{Protheus.doc} WSMETHOD GET ID
Busca registro via ID
@author Atilio
@since 07/04/2022
@version 1.0
@param id, Caractere, String que ser� pesquisada atrav�s do MsSeek
@obs Codigo gerado automaticamente pelo Autumn Code Maker
@see http://autumncodemaker.com
/*/
 
WSMETHOD GET ID WSRECEIVE id WSSERVICE products
    Local lRet       := .T.
    Local jResponse  := JsonObject():New()
    Local cAliasWS   := 'SB1'
 
    //Se o id estiver vazio
    If Empty(::id)
        //SetRestFault(500, 'Falha ao consultar o registro') //caso queira usar esse comando, voc� n�o poder� usar outros retornos, como os abaixo
        Self:setStatus(500) 
        jResponse['errorId']  := 'ID001'
        jResponse['error']    := 'ID vazio'
        jResponse['solution'] := 'Informe o ID'
    Else
        DbSelectArea(cAliasWS)
        (cAliasWS)->(DbSetOrder(1))
 
        //Se n�o encontrar o registro
        If ! (cAliasWS)->(MsSeek(FWxFilial(cAliasWS) + ::id))
            //SetRestFault(500, 'Falha ao consultar ID') //caso queira usar esse comando, voc� n�o poder� usar outros retornos, como os abaixo
            Self:setStatus(500) 
            jResponse['errorId']  := 'ID002'
            jResponse['error']    := 'ID n�o encontrado'
            jResponse['solution'] := 'C�digo ID n�o encontrado na tabela ' + cAliasWS
        Else
            //Define o retorno
            jResponse['cod']      := (cAliasWS)->B1_COD 
            jResponse['desc']     := (cAliasWS)->B1_DESC 
            jResponse['tipo']     := (cAliasWS)->B1_TIPO 
            jResponse['um']       := (cAliasWS)->B1_UM 
            jResponse['locpad']   := (cAliasWS)->B1_LOCPAD 
            jResponse['grupo']    := (cAliasWS)->B1_GRUPO 
        EndIf
    EndIf
 
    //Define o retorno
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())
Return lRet
 
/*/{Protheus.doc} WSMETHOD GET ALL
Busca todos os registros atrav�s de pagina��o
@author Atilio
@since 07/04/2022
@version 1.0
@param updated_at, Caractere, Data de altera��o no formato string 'YYYY-MM-DD' (somente se tiver o campo USERLGA / USERGA na tabela)
@param limit, Num�rico, Limite de registros que ir� vir (por exemplo trazer apenas 100 registros)
@param page, Num�rico, N�mero da p�gina que ir� buscar (se existir 1000 registros dividido por 100 ter� 10 p�ginas de pesquisa)
@obs Codigo gerado automaticamente pelo Autumn Code Maker
 
    Poderia ser usado o FWAdapterBaseV2(), mas em algumas vers�es antigas n�o existe essa funcionalidade
    ent�o a pagina��o foi feita manualmente
 
@see http://autumncodemaker.com
/*/
 
WSMETHOD GET ALL WSRECEIVE updated_at, limit, page WSSERVICE products
    Local lRet       := .T.
    Local jResponse  := JsonObject():New()
    Local cQueryTab  := ''
    Local nTamanho   := 10
    Local nTotal     := 0
    Local nPags      := 0
    Local nPagina    := 0
    Local nAtual     := 0
    Local oRegistro
    Local cAliasWS   := 'SB1'
 
    //Efetua a busca dos registros
    cQueryTab := " SELECT " + CRLF
    cQueryTab += "     TAB.R_E_C_N_O_ AS TABREC " + CRLF
    cQueryTab += " FROM " + CRLF
    cQueryTab += "     " + RetSQLName(cAliasWS) + " TAB " + CRLF
    cQueryTab += " WHERE " + CRLF
    cQueryTab += "     TAB.D_E_L_E_T_ = '' " + CRLF
    If ! Empty(::updated_at)
        cQueryTab += "     AND ((CASE WHEN SUBSTRING(B1_USERLGA, 03, 1) != ' ' THEN " + CRLF
        cQueryTab += "        CONVERT(VARCHAR,DATEADD(DAY,((ASCII(SUBSTRING(B1_USERLGA,12,1)) - 50) * 100 + (ASCII(SUBSTRING(B1_USERLGA,16,1)) - 50)),'19960101'),112) " + CRLF
        cQueryTab += "        ELSE '' " + CRLF
        cQueryTab += "     END) >= '" + StrTran(::updated_at, '-', '') + "') " + CRLF
    EndIf
    cQueryTab += " ORDER BY " + CRLF
    cQueryTab += "     TABREC " + CRLF
    TCQuery cQueryTab New Alias 'QRY_TAB'
 
    //Se n�o encontrar registros
    If QRY_TAB->(EoF())
        //SetRestFault(500, 'Falha ao consultar registros') //caso queira usar esse comando, voc� n�o poder� usar outros retornos, como os abaixo
        Self:setStatus(500) 
        jResponse['errorId']  := 'ALL003'
        jResponse['error']    := 'Registro(s) n�o encontrado(s)'
        jResponse['solution'] := 'A consulta de registros n�o retornou nenhuma informa��o'
    Else
        jResponse['objects'] := {}
 
        //Conta o total de registros
        Count To nTotal
        QRY_TAB->(DbGoTop())
 
        //O tamanho do retorno, ser� o limit, se ele estiver definido
        If ! Empty(::limit)
            nTamanho := ::limit
        EndIf
 
        //Pegando total de p�ginas
        nPags := NoRound(nTotal / nTamanho, 0)
        nPags += Iif(nTotal % nTamanho != 0, 1, 0)
         
        //Se vier p�gina
        If ! Empty(::page)
            nPagina := ::page
        EndIf
 
        //Se a p�gina vier zerada ou negativa ou for maior que o m�ximo, ser� 1 
        If nPagina <= 0 .Or. nPagina > nPags
            nPagina := 1
        EndIf
 
        //Se a p�gina for diferente de 1, pula os registros
        If nPagina != 1
            QRY_TAB->(DbSkip((nPagina-1) * nTamanho))
        EndIf
 
        //Adiciona os dados para a meta
        jJsonMeta := JsonObject():New()
        jJsonMeta['total']         := nTotal
        jJsonMeta['current_page']  := nPagina
        jJsonMeta['total_page']    := nPags
        jJsonMeta['total_items']   := nTamanho
        jResponse['meta'] := jJsonMeta
 
        //Percorre os registros
        While ! QRY_TAB->(EoF())
            nAtual++
             
            //Se ultrapassar o limite, encerra o la�o
            If nAtual > nTamanho
                Exit
            EndIf
 
            //Posiciona o registro e adiciona no retorno
            DbSelectArea(cAliasWS)
            (cAliasWS)->(DbGoTo(QRY_TAB->TABREC))
             
            oRegistro := JsonObject():New()
            oRegistro['cod'] := (cAliasWS)->B1_COD 
            oRegistro['desc'] := (cAliasWS)->B1_DESC 
            oRegistro['tipo'] := (cAliasWS)->B1_TIPO 
            oRegistro['um'] := (cAliasWS)->B1_UM 
            oRegistro['locpad'] := (cAliasWS)->B1_LOCPAD 
            oRegistro['grupo'] := (cAliasWS)->B1_GRUPO 
            aAdd(jResponse['objects'], oRegistro)
 
            QRY_TAB->(DbSkip())
        EndDo
    EndIf
    QRY_TAB->(DbCloseArea())
 
    //Define o retorno
    Self:SetContentType('application/json')
    Self:SetResponse(jResponse:toJSON())
Return lRet
 
/*/{Protheus.doc} WSMETHOD POST NEW
Cria um novo registro na tabela
@author Atilio
@since 07/04/2022
@version 1.0
@obs Codigo gerado automaticamente pelo Autumn Code Maker
 
    Abaixo um exemplo do JSON que dever� vir no body
    * 1: Para campos do tipo Num�rico, informe o valor sem usar as aspas
    * 2: Para campos do tipo Data, informe uma string no padr�o 'YYYY-MM-DD'
 
    {
        "cod": "conteudo",
        "desc": "conteudo",
        "tipo": "conteudo",
        "um": "conteudo",
        "locpad": "conteudo",
        "grupo": "conteudo"
    }
 
@see http://autumncodemaker.com
/*/
 
WSMETHOD POST NEW WSRECEIVE WSSERVICE products
    Local lRet              := .T.
    Local aDados            := {}
    Local jJson             := Nil
    Local cJson             := Self:GetContent()
    Local cError            := ''
    Local nLinha            := 0
    Local cDirLog           := '\x_logs\'
    Local cArqLog           := ''
    Local cErrorLog         := ''
    Local aLogAuto          := {}
    Local nCampo            := 0
    Local jResponse         := JsonObject():New()
    Local cAliasWS          := 'SB1'
    Private lMsErroAuto     := .F.
    Private lMsHelpAuto     := .T.
    Private lAutoErrNoFile  := .T.
  
    //Se n�o existir a pasta de logs, cria
    IF ! ExistDir(cDirLog)
        MakeDir(cDirLog)
    EndIF    
 
    //Definindo o conte�do como JSON, e pegando o content e dando um parse para ver se a estrutura est� ok
    Self:SetContentType('application/json')
    jJson  := JsonObject():New()
    cError := jJson:FromJson(cJson)
  
    //Se tiver algum erro no Parse, encerra a execu��o
    IF ! Empty(cError)
        //SetRestFault(500, 'Falha ao obter JSON') //caso queira usar esse comando, voc� n�o poder� usar outros retornos, como os abaixo
        Self:setStatus(500) 
        jResponse['errorId']  := 'NEW004'
        jResponse['error']    := 'Parse do JSON'
        jResponse['solution'] := 'Erro ao fazer o Parse do JSON'
 
    Else
        DbSelectArea(cAliasWS)
        
        //Adiciona os dados do ExecAuto
        aAdd(aDados, {'B1_COD',    jJson:GetJsonObject('cod'),    Nil})
        aAdd(aDados, {'B1_DESC',   jJson:GetJsonObject('desc'),   Nil})
        aAdd(aDados, {'B1_TIPO',   jJson:GetJsonObject('tipo'),   Nil})
        aAdd(aDados, {'B1_UM',     jJson:GetJsonObject('um'),     Nil})
        aAdd(aDados, {'B1_LOCPAD', jJson:GetJsonObject('locpad'), Nil})
        aAdd(aDados, {'B1_GRUPO',  jJson:GetJsonObject('grupo'),  Nil})
         
        //Percorre os dados do execauto
        For nCampo := 1 To Len(aDados)
            //Se o campo for data, retira os hifens e faz a convers�o
            If GetSX3Cache(aDados[nCampo][1], 'X3_TIPO') == 'D'
                aDados[nCampo][2] := StrTran(aDados[nCampo][2], '-', '')
                aDados[nCampo][2] := sToD(aDados[nCampo][2])
            EndIf
        Next
 
        //Chama a inclus�o autom�tica
        MsExecAuto({|x, y| MATA010(x, y)}, aDados, 3)
 
        //Se houve erro, gera um arquivo de log dentro do diret�rio da protheus data
        If lMsErroAuto
            //Monta o texto do Error Log que ser� salvo
            cErrorLog   := ''
            aLogAuto    := GetAutoGrLog()
            For nLinha := 1 To Len(aLogAuto)
                cErrorLog += aLogAuto[nLinha] + CRLF
            Next nLinha
 
            //Grava o arquivo de log
            cArqLog := 'zWSProdutos_New_' + dToS(Date()) + '_' + StrTran(Time(), ':', '-') + '.log'
            MemoWrite(cDirLog + cArqLog, cErrorLog)
 
            //Define o retorno para o WebService
            //SetRestFault(500, cErrorLog) //caso queira usar esse comando, voc� n�o poder� usar outros retornos, como os abaixo
            Self:setStatus(500) 
            jResponse['errorId']  := 'NEW005'
            jResponse['error']    := 'Erro na inclus�o do registro'
            jResponse['solution'] := 'Nao foi possivel incluir o registro, foi gerado um arquivo de log em ' + cDirLog + cArqLog + ' '
            lRet := .F.
 
        //Sen�o, define o retorno
        Else
            jResponse['note']     := 'Registro incluido com sucesso'
        EndIf
 
    EndIf
 
    //Define o retorno
    Self:SetResponse(jResponse:toJSON())
Return lRet
