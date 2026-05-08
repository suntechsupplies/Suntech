#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "TopConn.ch"

//=============================================================
// API: CallCenter - REST API para Atendimentos do Call Center
// Modulo: SIGATMK
// Version: 1.2
// Author: Suntech
// Description: API REST para inclusao e alteracao de atendimentos
//              no modulo Call Center via ExecAuto TMKA271.
//
// Rotinas suportadas:
//   1 - Faturamento  (TMKA271 cRotina='2', UA_OPER='1', SUA+SUB+SC5+SC6)
//   2 - Orcamento    (TMKA271 cRotina='2', UA_OPER='2', SUA+SUB, sem SC5/SC6)
//   3 - Atendimento  (TMKA271 cRotina='2', UA_OPER='3', somente SUA, sem itens)
//
// Todas as rotinas usam TMKA271 internamente com cRotina='2' (MA410).
// O PE A410VZ deve existir no RPO para pular validacao de itens quando UA_OPER='3'.
//
// Metodos:
//   POST /callcenter - Inclui atendimento  (TMKA271 opcao 3)
//   PUT  /callcenter - Altera atendimento  (TMKA271 opcao 4)
//
//-------------------------------------------------------------
// Correcoes v1.1:
//   - Inicializacao explicita de todas as PRIVATEs do ExecAuto
//     (lMsErroAuto, lMsHelpAuto, lAutoErrNoFile, aMSMensagens,
//      aAutoErro, __cAutoHelp, cMSMensagem) antes de TMKA271
//   - CCGetAutoErr captura tambem aMSMensagens
//   - Tabela SX5 adicionada ao RpcSetEnv
//   - isProspect tratado como booleano JSON nativo via CCGetBool
//   - Logs expandidos para facilitar diagnostico
//=============================================================

WSRESTFUL CallCenter DESCRIPTION "Call Center Atendimento REST API v1.1"

    WSDATA empresa As String Optional
    WSDATA branch  As String Optional

    WSMETHOD POST DESCRIPTION "Inclui atendimento no Call Center (TMKA271 opcao 3)" WSSYNTAX "/callcenter"
    WSMETHOD PUT  DESCRIPTION "Altera atendimento no Call Center (TMKA271 opcao 4)" WSSYNTAX "/callcenter"

END WSRESTFUL

User Function CallCenter()
Return .T.

//-------------------------------------------------------------
// POST /callcenter
//-------------------------------------------------------------
WSMETHOD POST WSSERVICE CallCenter

    Local lRet      := .T.
    Local cJson     := Self:GetContent()
    Local oObj      := Nil
    Local oResponse := Nil
    Local _cEmpresa := "01"
    Local _cFilial  := "01"

    ::SetContentType("application/json")

    If Empty(cJson)
        oResponse := CCBuildResp(.F., "Corpo da requisicao vazio.", Nil)
        ::SetStatus(400)
        ::SetResponse(oResponse)
        Return .F.
    EndIf

    oObj := JsonObject():New()
    If ValType(oObj:FromJson(cJson)) != "U"
        oResponse := CCBuildResp(.F., "Formato JSON invalido.", Nil)
        ::SetStatus(400)
        ::SetResponse(oResponse)
        Return .F.
    EndIf

    // JSON body tem prioridade; Self:empresa/branch (WSDATA) podem ser pre-populados
    // pelo framework REST com o valor padrao do servidor, por isso consultamos o body primeiro
    _cEmpresa := CCGetStr(oObj, "empresa", "")
    If Empty(_cEmpresa)
        _cEmpresa := IIf(ValType(Self:empresa) == "C" .And. !Empty(Self:empresa), Self:empresa, "01")
    EndIf

    _cFilial := CCGetStr(oObj, "branch", "")
    If Empty(_cFilial)
        _cFilial := IIf(ValType(Self:branch) == "C" .And. !Empty(Self:branch), Self:branch, "01")
    EndIf

    ConOut("[CALLCENTER API] POST Self:empresa=[" + cValToChar(Self:empresa) + "] Self:branch=[" + cValToChar(Self:branch) + "]")
    ConOut("[CALLCENTER API] POST _cEmpresa=[" + _cEmpresa + "] _cFilial=[" + _cFilial + "]")

    lRet := CCProcessRequest(Self, oObj, _cEmpresa, _cFilial, 3)

Return lRet

//-------------------------------------------------------------
// PUT /callcenter
//-------------------------------------------------------------
WSMETHOD PUT WSSERVICE CallCenter

    Local lRet      := .T.
    Local cJson     := Self:GetContent()
    Local oObj      := Nil
    Local oResponse := Nil
    Local _cEmpresa := "01"
    Local _cFilial  := "01"

    ::SetContentType("application/json")

    If Empty(cJson)
        oResponse := CCBuildResp(.F., "Corpo da requisicao vazio.", Nil)
        ::SetStatus(400)
        ::SetResponse(oResponse)
        Return .F.
    EndIf

    oObj := JsonObject():New()
    If ValType(oObj:FromJson(cJson)) != "U"
        oResponse := CCBuildResp(.F., "Formato JSON invalido.", Nil)
        ::SetStatus(400)
        ::SetResponse(oResponse)
        Return .F.
    EndIf

    // JSON body tem prioridade; Self:empresa/branch (WSDATA) podem ser pre-populados
    // pelo framework REST com o valor padrao do servidor, por isso consultamos o body primeiro
    _cEmpresa := CCGetStr(oObj, "empresa", "")
    If Empty(_cEmpresa)
        _cEmpresa := IIf(ValType(Self:empresa) == "C" .And. !Empty(Self:empresa), Self:empresa, "01")
    EndIf

    _cFilial := CCGetStr(oObj, "branch", "")
    If Empty(_cFilial)
        _cFilial := IIf(ValType(Self:branch) == "C" .And. !Empty(Self:branch), Self:branch, "01")
    EndIf

    ConOut("[CALLCENTER API] PUT Self:empresa=[" + cValToChar(Self:empresa) + "] Self:branch=[" + cValToChar(Self:branch) + "]")
    ConOut("[CALLCENTER API] PUT _cEmpresa=[" + _cEmpresa + "] _cFilial=[" + _cFilial + "]")

    lRet := CCProcessRequest(Self, oObj, _cEmpresa, _cFilial, 4)

Return lRet

//-------------------------------------------------------------
// CCProcessRequest - Nucleo do processamento
//-------------------------------------------------------------
Static Function CCProcessRequest(oSelf, oObj, _cEmpresa, _cFilial, nOpcao)

    Local lRet      := .T.
    Local oResponse := Nil
    Local oData     := Nil
    Local cRotina   := ""
    Local cRotinaTMK := ""
    Local aCabec    := {}
    Local aItens    := {}
    Local aTabs     := {}
    Local cMsg      := ""
    Local oErr      := Nil
    Local bOldErr   := Nil
    Local nDbg      := 0
    Local nEr       := 0
    Local cMsgReal  := ""
    Local cAliasChk := ""
    Local nRecBefore := 0
    Local nRecAfter  := 0
    Local lGravou   := .F.

    // --- PRIVATEs obrigatorias para ExecAuto ---
    PRIVATE lMsErroAuto    := .F.
    PRIVATE lMsHelpAuto    := .T.
    PRIVATE lAutoErrNoFile := .T.
    PRIVATE aMSMensagens   := {}   // Fix: garante existencia antes do TMKA271
    PRIVATE aAutoErro      := {}   // Fix: garante existencia antes do TMKA271
    PRIVATE __cAutoHelp    := ""   // Fix: garante existencia antes do TMKA271
    PRIVATE cMSMensagem    := ""   // Fix: garante existencia antes do TMKA271
    // GrLog persistido como PRIVATE: GetAutoGrLog em alguns cenarios so devolve
    // o conteudo na primeira chamada, retornando vazio nas seguintes. Capturamos
    // uma vez logo apos o ExecAuto e reusamos em CCGetAutoErr.
    PRIVATE aCCGrLog       := {}

    // Validacao empresa + branch
    If Empty(_cEmpresa)
        _cEmpresa := "01"
        ConOut("[CALLCENTER API] AVISO: 'empresa' ausente no payload - usando padrao '01'")
    EndIf
    If Empty(_cFilial)
        _cFilial := "01"
        ConOut("[CALLCENTER API] AVISO: 'branch' ausente no payload - usando padrao '01'")
    EndIf

    cRotina := CCGetStr(oObj, "rotina", "")
    If Empty(cRotina) .Or. !(cRotina $ "1/2/3")
        oResponse := CCBuildResp(.F., "Campo 'rotina' obrigatorio. Valores aceitos: 1=Faturamento, 2=Orcamento, 3=Atendimento.", Nil)
        oSelf:SetStatus(400)
        oSelf:SetResponse(oResponse)
        Return .F.
    EndIf

    // Todas as rotinas usam TMKA271 cRotina='2' (MA410 -> SUA/SUB).
    // UA_OPER diferencia o comportamento: '3'=Atendimento, '2'=Orcamento, '1'=Faturamento.
    cRotinaTMK := "2"

    If ValType(CCGetObj(oObj, "cabecalho")) == "U"
        oResponse := CCBuildResp(.F., "Campo 'cabecalho' obrigatorio.", Nil)
        oSelf:SetStatus(400)
        oSelf:SetResponse(oResponse)
        Return .F.
    EndIf

    bOldErr := ErrorBlock({|e| oErr := e, Break(e)})

    Begin Sequence

        // SUA/SUB para Atendimento/Orcamento/Faturamento.
        // SC5/SC6 necessarios para Faturamento (rotina='1', UA_OPER='1').
        aTabs := {"SUA","SUB","SB1","SA1","SUS","SU5","SU6","SE4","AC8","SA4","SU7","SF4","SK1","SC5","SC6","SX5"}

        ConOut("[CALLCENTER API] ============================================")
        ConOut("[CALLCENTER API] ANTES RpcSetEnv: _cEmpresa=[" + _cEmpresa + "] _cFilial=[" + _cFilial + "]")
        ConOut("[CALLCENTER API] ANTES RpcSetEnv: cEmpAnt=[" + IIf(Type("cEmpAnt")=="C", cEmpAnt, "N/A") + "] cFilAnt=[" + IIf(Type("cFilAnt")=="C", cFilAnt, "N/A") + "]")

        // Em WSRESTFUL o ambiente ja esta aberto na empresa configurada no APPSERVER.INI
        // (geralmente "01"). Para trocar de empresa em runtime, precisamos primeiro fechar
        // o ambiente atual com RESET ENVIRONMENT antes do RpcSetEnv.
        // Variaveis publicas corretas no Protheus: cEmpAnt, cFilAnt.
        If (Type("cEmpAnt") == "C" .And. !Empty(cEmpAnt) .And. cEmpAnt != _cEmpresa) .Or. ;
           (Type("cFilAnt") == "C" .And. !Empty(cFilAnt) .And. cFilAnt != _cFilial)
            ConOut("[CALLCENTER API] Trocando ambiente: " + ;
                   IIf(Type("cEmpAnt")=="C", cEmpAnt, "?") + "/" + ;
                   IIf(Type("cFilAnt")=="C", cFilAnt, "?") + " -> " + _cEmpresa + "/" + _cFilial)
            RESET ENVIRONMENT
        EndIf

        RpcSetEnv(_cEmpresa, _cFilial,,,,GetEnvServer(), aTabs)

        ConOut("[CALLCENTER API] APOS  RpcSetEnv: cEmpAnt=[" + IIf(Type("cEmpAnt")=="C", cEmpAnt, "N/A") + "] cFilAnt=[" + IIf(Type("cFilAnt")=="C", cFilAnt, "N/A") + "]")
        ConOut("[CALLCENTER API] Empresa: " + _cEmpresa + " Filial: " + _cFilial + ;
               " Opcao: " + cValToChar(nOpcao) + " Rotina: " + cRotina)

        Do Case
            Case cRotina == "1"
                // Faturamento: UA_OPER='1' forcado, com itens, gera SC5/SC6
                CCBuildVend(oObj, nOpcao, @aCabec, @aItens, "1")
            Case cRotina == "2"
                // Orcamento: UA_OPER='2' forcado, com itens, sem SC5/SC6
                CCBuildVend(oObj, nOpcao, @aCabec, @aItens, "2")
            Case cRotina == "3"
                // Atendimento: UA_OPER='3', sem itens
                CCBuildAtend(oObj, nOpcao, @aCabec, @aItens)
        EndCase

        ConOut("[CALLCENTER API] Campos cabecalho: " + cValToChar(Len(aCabec)))
        ConOut("[CALLCENTER API] Itens: " + cValToChar(Len(aItens)))

        For nDbg := 1 To Len(aCabec)
            If ValType(aCabec[nDbg][2]) == "C"
                ConOut("[CALLCENTER API] CAB[" + cValToChar(nDbg) + "] " + aCabec[nDbg][1] + "=[" + aCabec[nDbg][2] + "]")
            ElseIf ValType(aCabec[nDbg][2]) == "N"
                ConOut("[CALLCENTER API] CAB[" + cValToChar(nDbg) + "] " + aCabec[nDbg][1] + "=[" + cValToChar(aCabec[nDbg][2]) + "]")
            ElseIf ValType(aCabec[nDbg][2]) == "D"
                ConOut("[CALLCENTER API] CAB[" + cValToChar(nDbg) + "] " + aCabec[nDbg][1] + "=[" + DToS(aCabec[nDbg][2]) + "]")
            ElseIf ValType(aCabec[nDbg][2]) == "L"
                ConOut("[CALLCENTER API] CAB[" + cValToChar(nDbg) + "] " + aCabec[nDbg][1] + "=[" + IIf(aCabec[nDbg][2], "T", "F") + "]")
            EndIf
        Next nDbg

        // Rotinas 1 e 2 (Faturamento/Orcamento) com inclusao exigem pelo menos 1 item.
        // Rotina 3 (Atendimento) nao usa itens - A410VZ PE garante skip da validacao.
        If nOpcao == 3 .And. (cRotina == "1" .Or. cRotina == "2") .And. Len(aItens) == 0
            Do Case
                Case cRotina == "1"
                    cMsg := "Para rotina 1 (Faturamento), 'itens' nao pode ser vazio. " + ;
                            "Informe ao menos 1 item com 'productCode', 'quantity', 'unitPrice' e 'tes'."
                Case cRotina == "2"
                    cMsg := "Para rotina 2 (Orcamento), 'itens' nao pode ser vazio. " + ;
                            "Informe ao menos 1 item com 'productCode', 'quantity', 'unitPrice' e 'tes'."
            EndCase
            oResponse := CCBuildResp(.F., cMsg, Nil)
            oSelf:SetStatus(400)
            oSelf:SetResponse(oResponse)
            ErrorBlock(bOldErr)
            Return .F.
        EndIf

        // Garantia: rotina 3 sempre sem itens
        If cRotina == "3"
            ASize(aItens, 0)
        EndIf

        If cRotina == "3"
            cMsg := CCValAtend(oObj)
            If !Empty(cMsg)
                oResponse := CCBuildResp(.F., cMsg, Nil)
                oSelf:SetStatus(400)
                oSelf:SetResponse(oResponse)
                ErrorBlock(bOldErr)
                Return .F.
            EndIf
        EndIf

        If cRotina == "1" .Or. cRotina == "2"
            cMsg := CCPreValidateVend(aItens)
            If !Empty(cMsg)
                oResponse := CCBuildResp(.F., cMsg, Nil)
                oSelf:SetStatus(CCGetAutoStatus(cMsg))
                oSelf:SetResponse(oResponse)
                ErrorBlock(bOldErr)
                Return .F.
            EndIf
        EndIf

        lMsErroAuto := .F.

        // Captura LastRec da tabela alvo ANTES do MsExecAuto para detectar gravacao real.
        // Necessario porque TMKA271 em alguns cenarios retorna lMsErroAuto = .F. mesmo
        // sem gravar nada (ex: validacao interna falha apos a primeira fase, transacao
        // revertida silenciosamente).
        // Todas as rotinas gravam em SUA (TMKA271 cRotina='2').
        // IMPORTANTE: forcar a abertura/posicionamento da SUA antes de ler LastRec.
        // Em chamadas frescas a area pode nao ter sido aberta ainda pelo RpcSetEnv
        // (Select retorna 0 -> nRecBefore=0 -> falso positivo de gravacao).
        cAliasChk := "SUA"
        DbSelectArea(cAliasChk)
        (cAliasChk)->(DbGoTop())
        nRecBefore := (cAliasChk)->(LastRec())
        ConOut("[CALLCENTER API] " + cAliasChk + "->LastRec ANTES MsExecAuto: " + cValToChar(nRecBefore))
        ConOut("[CALLCENTER API] Chamando TMKA271 cRotinaTMK=[" + cRotinaTMK + "] rotina=[" + cRotina + "] UA_OPER=[" + cValToChar(CCGetAutoField(aCabec, "UA_OPER", "?")) + "] itens=[" + cValToChar(Len(aItens)) + "]")
        ConOut("[CALLCENTER API] FindFunction(A410VZ)=[" + IIf(FindFunction("A410VZ"), "T", "F") + "]")

        // PRIVATE lCCApiMode: sinaliza ao PE A410VZ que a chamada vem da API.
        // A410VZ deve retornar .F. (pular validacao) quando lCCApiMode = .T.
        // Convencao MA410: ExecBlock("A410VZ") retorna .T. = validar itens, .F. = pular.
        PRIVATE lCCApiMode := .T.

        // FALLBACK rotina 3 sem PE: se U_A410VZ nao esta no RPO ativo,
        // o MA410 padrao SEMPRE aborta a inclusao do Atendimento (UA_OPER=3)
        // por exigir itens. Nesse caso fazemos a gravacao direta na SUA,
        // pulando MsExecAuto/TMKA271. Compatibiliza a API enquanto o PE
        // nao foi compilado no environment.
        If cRotina == "3" .And. nOpcao == 3 .And. !FindFunction("A410VZ")
            ConOut("[CALLCENTER API] FALLBACK ATIVO: A410VZ ausente no RPO. Gravando SUA diretamente para rotina 3.")
            cMsg := CCDirectInsertSUA(aCabec, @oData, cRotina)
            lCCApiMode := .F.
            If Empty(cMsg)
                ConOut("[CALLCENTER API] FALLBACK: Atendimento incluido com sucesso (recno=" + ;
                       cValToChar(IIf(oData != Nil .And. ValType(oData) == "J", oData['recno'], 0)) + ")")
                oResponse := CCBuildResp(.T., "Atendimento incluido com sucesso.", oData)
                oSelf:SetStatus(200)
                ErrorBlock(bOldErr)
                oSelf:SetResponse(oResponse)
                Return .T.
            Else
                ConOut("[CALLCENTER API] FALLBACK FALHOU: " + cMsg)
                oResponse := CCBuildResp(.F., cMsg, Nil)
                oSelf:SetStatus(422)
                ErrorBlock(bOldErr)
                oSelf:SetResponse(oResponse)
                Return .F.
            EndIf
        EndIf

        MsExecAuto({|| TMKA271(aCabec, aItens, nOpcao, cRotinaTMK)}, aCabec, aItens, nOpcao, cRotinaTMK)
        lCCApiMode := .F.  // Limpa flag apos ExecAuto
        ConOut("[CALLCENTER API] lMsErroAuto apos TMKA271: " + IIf(lMsErroAuto, "T", "F"))

        nRecAfter := IIf(Select(cAliasChk) > 0, (cAliasChk)->(LastRec()), nRecBefore)
        lGravou   := (nRecAfter > nRecBefore)
        ConOut("[CALLCENTER API] " + cAliasChk + "->LastRec APOS  MsExecAuto: " + cValToChar(nRecAfter) + " (gravou=" + IIf(lGravou,"T","F") + ")")

        // Em opcao = 3 (inclusao), se nao houve crescimento do LastRec, NAO gravou nada
        // mesmo que lMsErroAuto seja .F. - tratamos como erro forcado.
        If nOpcao == 3 .And. !lGravou .And. !lMsErroAuto
            ConOut("[CALLCENTER API] FALSO POSITIVO: lMsErroAuto=F mas " + cAliasChk + " nao cresceu. Forcando erro.")
            lMsErroAuto := .T.
        EndIf

        // Dump bruto de GetAutoGrLog para diagnostico (independente de lMsErroAuto).
        // Protegido por sub-sequence porque em alguns cenarios GetAutoGrLog pode
        // lancar "array out of bounds" quando o log interno do framework esta
        // corrompido/incompleto, mascarando o erro real do TMKA271.
        ConOut("[CALLCENTER API] --> antes GetAutoGrLog dump")
        Begin Sequence
            If FindFunction("GetAutoGrLog")
                aCCGrLog := GetAutoGrLog()
                If ValType(aCCGrLog) == "A"
                    ConOut("[CALLCENTER API] GrLog total linhas: " + cValToChar(Len(aCCGrLog)))
                    For nEr := 1 To Len(aCCGrLog)
                        If ValType(aCCGrLog[nEr]) == "C"
                            ConOut("[CALLCENTER API] GrLog[" + cValToChar(nEr) + "]=" + aCCGrLog[nEr])
                        Else
                            ConOut("[CALLCENTER API] GrLog[" + cValToChar(nEr) + "] tipo=" + ValType(aCCGrLog[nEr]))
                        EndIf
                    Next nEr
                Else
                    aCCGrLog := {}
                EndIf
            EndIf
        Recover
            ConOut("[CALLCENTER API] EXCECAO no GetAutoGrLog dump (ignorada)")
            aCCGrLog := {}
        End Sequence
        ConOut("[CALLCENTER API] <-- apos GetAutoGrLog dump")

        // CCGetProcessData tambem protegido: se TMKA271 falhou, tabelas SUA/ACF
        // podem estar em estado inconsistente e a leitura do registro gerado
        // parcialmente pode disparar excecao.
        oData := Nil
        ConOut("[CALLCENTER API] --> antes CCGetProcessData")
        Begin Sequence
            oData := CCGetProcessData(cRotina, oObj, aCabec, aItens)
        Recover
            ConOut("[CALLCENTER API] EXCECAO em CCGetProcessData (ignorada)")
            oData := Nil
        End Sequence
        ConOut("[CALLCENTER API] <-- apos CCGetProcessData")

        // Fallback rotina 3 (Atendimento): quando o U_A410VZ customizado nao esta
        // carregado no RPO, o MA410 padrao dispara "AJUDA:A410VZ - Os campos
        // Quantidade, Preco de Venda, preco unitario ou TES estao em Branco" mesmo
        // para UA_OPER=3 (que nao tem itens). Se o registro SUA foi gravado
        // (lGravou=T), trate como SUCESSO ja que Atendimento nao precisa de itens.
        If lMsErroAuto .And. cRotina == "3" .And. lGravou
            Begin Sequence
                cMsgReal := Upper(CCFormatAutoErr(CCGetAutoErr()))
                If "A410VZ" $ cMsgReal .Or. "INCONSISTENCIA NOS ITENS" $ cMsgReal .Or. ;
                   ("QUANTIDADE" $ cMsgReal .And. "BRANCO" $ cMsgReal)
                    ConOut("[CALLCENTER API] Rotina 3 + gravou=T + erro A410VZ ignorado (Atendimento nao requer itens).")
                    lMsErroAuto := .F.
                EndIf
                cMsgReal := ""
            Recover
                cMsgReal := ""
            End Sequence
        EndIf

        If lMsErroAuto
            If FindFunction("DisarmTransaction")
                DisarmTransaction()
            EndIf

            // Log diagnostico expandido
            ConOut("[CALLCENTER API] --- Diagnostico de erro ---")
            ConOut("[CALLCENTER API] FindFunction(GetAutoGrLog)=" + IIf(FindFunction("GetAutoGrLog"), "T", "F"))
            ConOut("[CALLCENTER API] Type(aAutoErro)="    + Type("aAutoErro"))
            ConOut("[CALLCENTER API] Type(aMSMensagens)=" + Type("aMSMensagens"))
            ConOut("[CALLCENTER API] Type(__cAutoHelp)="  + Type("__cAutoHelp"))
            ConOut("[CALLCENTER API] Type(cMSMensagem)="  + Type("cMSMensagem"))

            // Loga CONTEUDO das strings (nao apenas o tipo) - critico para capturar Help() interno
            If Type("__cAutoHelp") == "C"
                ConOut("[CALLCENTER API] __cAutoHelp=[" + __cAutoHelp + "]")
            EndIf
            If Type("cMSMensagem") == "C"
                ConOut("[CALLCENTER API] cMSMensagem=[" + cMSMensagem + "]")
            EndIf

            If Type("aAutoErro") == "A"
                For nEr := 1 To Len(aAutoErro)
                    ConOut("[CALLCENTER API] aAutoErro[" + cValToChar(nEr) + "]=" + cValToChar(aAutoErro[nEr]))
                Next nEr
            EndIf

            If Type("aMSMensagens") == "A"
                For nEr := 1 To Len(aMSMensagens)
                    ConOut("[CALLCENTER API] aMSMensagens[" + cValToChar(nEr) + "]=" + cValToChar(aMSMensagens[nEr]))
                Next nEr
            EndIf

            cMsg := CCFormatAutoErr(CCGetAutoErr())
            // Caso a deteccao de falso positivo via LastRec tenha forcado o erro
            // (sem mensagens reais do auto-erro), informa um diagnostico claro.
            If Empty(AllTrim(cMsg)) .And. !lGravou
                cMsg := "TMKA271 nao gravou registro em " + cAliasChk + " (rotina API=" + cRotina + "). " + ;
                        "Verifique campos obrigatorios: entidade (UC_ENTIDAD/UC_CHAVE), operador (UC_OPERADO), " + ;
                        "ligacao (UC_CODLIG). Para rotina 2: produto (UB_PRODUTO), TES (UB_TES), quantidade."
            EndIf
            // Quando nao houve gravacao real (lGravou=F), qualquer oData obtido via
            // fallback do CCGetProcessData aponta para registro EXISTENTE anterior,
            // nao para um registro novo. Descartamos para nao relatar dado falso.
            If !lGravou
                oData := Nil
            EndIf
            // Somente relata "parcialmente" se houve gravacao real (lGravou=T)
            // e o recno do novo registro foi encontrado.
            If lGravou .And. oData != Nil .And. ValType(oData) == "J"
                Begin Sequence
                    If ValType(oData['recno']) != "N" .Or. oData['recno'] <= 0
                        oData := Nil
                    Else
                        cMsg += " Atendimento gerado parcialmente."
                    EndIf
                Recover
                    oData := Nil
                End Sequence
            EndIf
            ConOut("[CALLCENTER API] Erro TMKA271: " + cMsg)
            oResponse := CCBuildResp(.F., cMsg, oData)
            oSelf:SetStatus(CCGetAutoStatus(cMsg))
            lRet := .F.
        Else
            // lMsErroAuto = .F. significa que o TMKA271 gravou com sucesso.
            // Se oData = Nil, CCGetProcessData nao localizou o registro (problema de leitura),
            // mas a gravacao ocorreu � registramos o aviso e retornamos sucesso normalmente.
            If oData == Nil
                ConOut("[CALLCENTER API] AVISO: lMsErroAuto=F mas CCGetProcessData retornou Nil (rotina=" + cRotina + "). Registro gravado mas nao recuperado.")
            EndIf
            cMsg := IIf(nOpcao == 3, "Atendimento incluido com sucesso.", "Atendimento alterado com sucesso.")
            oResponse := CCBuildResp(.T., cMsg, oData)
            oSelf:SetStatus(200)
        EndIf

    Recover

        If FindFunction("DisarmTransaction")
            DisarmTransaction()
        EndIf
        cMsg := CCGetErrMsg(oErr)
        ConOut("[CALLCENTER API] EXCECAO CAPTURADA: " + cMsg)
        ConOut("[CALLCENTER API] lMsErroAuto=" + IIf(lMsErroAuto, "T", "F"))
        If ValType(oErr) != "U"
            ConOut("[CALLCENTER API] Classe erro: " + CCGetErrInfo(oErr, "ClassName"))
            ConOut("[CALLCENTER API] Operacao: "   + CCGetErrInfo(oErr, "Operation"))
            ConOut("[CALLCENTER API] SubCode: "    + CCGetErrInfo(oErr, "SubCode"))
        EndIf

        // Se o TMKA271 ja sinalizou erro (lMsErroAuto = .T.), a causa real esta
        // em aMSMensagens/aAutoErro/GetAutoGrLog. Qualquer excecao posterior
        // (ex: "array out of bounds" no GetAutoGrLog/CCGetProcessData, ou EOF/lock
        // em SC5 lancado por Pontos de Entrada como M410STTS) e secundaria.
        // Priorizamos sempre a mensagem real do ExecAuto.
        If lMsErroAuto
            cMsgReal := CCFormatAutoErr(CCGetAutoErr())
            If !Empty(AllTrim(cMsgReal))
                cMsg := cMsgReal
            EndIf
        EndIf

        oResponse := CCBuildResp(.F., cMsg, Nil)
        oSelf:SetStatus(422)
        lRet := .F.

    End Sequence

    ErrorBlock(bOldErr)
    oSelf:SetResponse(oResponse)

Return lRet

Static Function CCGetProcessData(cRotina, oObj, aCabec, aItens)

    Local aArea    := GetArea()
    Local oData    := Nil
    Local oCab     := CCGetObj(oObj, "cabecalho")
    Local cNumAuto := ""
    Local cCli     := ""
    Local cLoja    := ""
    Local cOper    := ""
    Local cCodLig  := ""

    cCli    := CCGetStr(oCab, "customerCode", "")
    cLoja   := CCGetStr(oCab, "customerStore", "")
    cOper   := CCGetStr(oCab, "operatorCode", "")
    cCodLig := CCGetStr(oCab, "callCode", "")

    Begin Sequence
        // Todas as rotinas (1=Atendimento, 2=Orcamento, 3=Faturamento) gravam em SUA.
        If Select("SUA") > 0
            cNumAuto := CCGetAutoField(aCabec, "UA_NUM", "")
            ConOut("[CALLCENTER API] CCGetProcessData rotina=[" + cRotina + "] SUA cNumAuto=[" + cNumAuto + "]")

            dbSelectArea("SUA")
            SUA->(dbSetOrder(1))

            If !Empty(cNumAuto) .And. SUA->(dbSeek(xFilial("SUA") + PadR(cNumAuto, TamSX3("UA_NUM")[1])))
                oData := JsonObject():New()
                oData['routine']          := cRotina
                oData['recno']            := SUA->(Recno())
                oData['attendanceNumber'] := AllTrim(SUA->UA_NUM)
                oData['salesOrderNumber'] := AllTrim(SUA->UA_NUMSC5)
                oData['customerCode']     := AllTrim(SUA->UA_CLIENTE)
                oData['customerStore']    := AllTrim(SUA->UA_LOJA)
                oData['operatorCode']     := AllTrim(SUA->UA_OPERADO)
                oData['attendanceType']   := AllTrim(SUA->UA_OPER)
            Else
                // Fallback: busca pelo ultimo registro do cliente/operador/ligacao
                SUA->(dbGoBottom())
                While !SUA->(Bof())
                    If (Empty(cCli)   .Or. AllTrim(SUA->UA_CLIENTE) == cCli)   .And. ;
                       (Empty(cLoja)  .Or. AllTrim(SUA->UA_LOJA)    == cLoja)  .And. ;
                       (Empty(cOper)  .Or. AllTrim(SUA->UA_OPERADO) == cOper)  .And. ;
                       (Empty(cCodLig).Or. AllTrim(SUA->UA_CODLIG)  == cCodLig)
                        Exit
                    EndIf
                    SUA->(dbSkip(-1))
                EndDo
                If !SUA->(Bof()) .And. !SUA->(Eof())
                    oData := JsonObject():New()
                    oData['routine']          := cRotina
                    oData['recno']            := SUA->(Recno())
                    oData['attendanceNumber'] := AllTrim(SUA->UA_NUM)
                    oData['salesOrderNumber'] := AllTrim(SUA->UA_NUMSC5)
                    oData['customerCode']     := AllTrim(SUA->UA_CLIENTE)
                    oData['customerStore']    := AllTrim(SUA->UA_LOJA)
                    oData['operatorCode']     := AllTrim(SUA->UA_OPERADO)
                    oData['attendanceType']   := AllTrim(SUA->UA_OPER)
                EndIf
            EndIf
        EndIf
    Recover
        oData := Nil
    End Sequence

    RestArea(aArea)

Return oData

//-------------------------------------------------------------
// CCDirectInsertSUA - Fallback: insere registro SUA diretamente
// quando o PE U_A410VZ nao esta carregado no RPO. So roda para
// rotina 3 (Atendimento, UA_OPER=3, sem itens SUB).
//
// Retorna "" em sucesso ou mensagem de erro em falha.
// Popula oData (passado por referencia) com a estrutura padrao
// de resposta (recno, attendanceNumber, etc).
//-------------------------------------------------------------
Static Function CCDirectInsertSUA(aCabec, oData, cRotina)

    Local aArea     := GetArea()
    Local aSUAArea  := SUA->(GetArea())
    Local cErr      := ""
    Local cNumNovo  := ""
    Local nPos      := 0
    Local cCampo    := ""
    Local xValor    := Nil
    Local lOk       := .F.
    Local oErr      := Nil
    Local bOldErr   := ErrorBlock({|e| oErr := e, Break(e)})

    Begin Sequence

        DbSelectArea("SUA")
        SUA->(DbSetOrder(1))

        // Gera numero do atendimento via SXE/SXF (semaforo)
        cNumNovo := GetSXENum("SUA", "UA_NUM")
        If Empty(cNumNovo)
            cErr := "Falha ao gerar numero do atendimento (GetSXENum vazio)."
            Break
        EndIf
        ConOut("[CALLCENTER API] FALLBACK: UA_NUM gerado=[" + cNumNovo + "]")

        // Garante unicidade (loop defensivo caso SXE esteja desincronizado)
        While SUA->(DbSeek(xFilial("SUA") + cNumNovo))
            ConfirmSX8()
            cNumNovo := GetSXENum("SUA", "UA_NUM")
            If Empty(cNumNovo)
                cErr := "Falha ao gerar numero unico do atendimento."
                Break
            EndIf
        EndDo
        If !Empty(cErr)
            Break
        EndIf

        // Append + Replace
        RecLock("SUA", .T.)
        SUA->UA_FILIAL := xFilial("SUA")
        SUA->UA_NUM    := cNumNovo

        // Aplica todos os campos do aCabec, ignorando UA_NUM (ja setado)
        For nPos := 1 To Len(aCabec)
            If ValType(aCabec[nPos]) == "A" .And. Len(aCabec[nPos]) >= 2
                cCampo := Upper(AllTrim(cValToChar(aCabec[nPos][1])))
                xValor := aCabec[nPos][2]
                If cCampo == "UA_NUM" .Or. cCampo == "UA_FILIAL"
                    Loop
                EndIf
                // Verifica se o campo existe na SUA via FieldPos
                If SUA->(FieldPos(cCampo)) > 0
                    FieldPut(SUA->(FieldPos(cCampo)), xValor)
                EndIf
            EndIf
        Next nPos

        // Default UA_EMISSAO se nao veio
        If SUA->(FieldPos("UA_EMISSAO")) > 0 .And. Empty(SUA->UA_EMISSAO)
            SUA->UA_EMISSAO := dDataBase
        EndIf

        SUA->(MsUnLock())
        ConfirmSX8()
        lOk := .T.

        // Monta resposta
        oData := JsonObject():New()
        oData['routine']          := cRotina
        oData['recno']            := SUA->(Recno())
        oData['attendanceNumber'] := AllTrim(SUA->UA_NUM)
        oData['salesOrderNumber'] := IIf(SUA->(FieldPos("UA_NUMSC5")) > 0, AllTrim(SUA->UA_NUMSC5), "")
        oData['customerCode']     := AllTrim(SUA->UA_CLIENTE)
        oData['customerStore']    := AllTrim(SUA->UA_LOJA)
        oData['operatorCode']     := AllTrim(SUA->UA_OPERADO)
        oData['attendanceType']   := AllTrim(SUA->UA_OPER)

    Recover

        If !lOk
            // Se ja chamou GetSXENum sem ConfirmSX8, libera o numero gerado
            If !Empty(cNumNovo)
                RollBackSX8()
            EndIf
            If Empty(cErr)
                If ValType(oErr) != "U"
                    cErr := "Falha gravando SUA: " + CCGetErrMsg(oErr)
                Else
                    cErr := "Falha desconhecida gravando SUA diretamente."
                EndIf
            EndIf
        EndIf

    End Sequence

    ErrorBlock(bOldErr)
    SUA->(RestArea(aSUAArea))
    RestArea(aArea)

Return cErr

//-------------------------------------------------------------
// CCGetAutoField - Extrai valor de um campo em array ExecAuto
//-------------------------------------------------------------
Static Function CCGetAutoField(aData, cField, xDefault)

    Local nPos := 0

    Default xDefault := ""

    If ValType(aData) != "A"
        Return xDefault
    EndIf

    For nPos := 1 To Len(aData)
        If ValType(aData[nPos]) == "A" .And. Len(aData[nPos]) >= 2 .And. ;
           ValType(aData[nPos][1]) == "C" .And. Upper(AllTrim(aData[nPos][1])) == Upper(AllTrim(cField))
            Return aData[nPos][2]
        EndIf
    Next nPos

Return xDefault

//-------------------------------------------------------------
// CCPreValidateVend - Valida TES/SF4 antes da rotina 2
//-------------------------------------------------------------
Static Function CCPreValidateVend(aItens)

    Local aChecked := {}
    Local cTes     := ""
    Local nItem    := 0
    Local nPos     := 0
    Local nTamTes  := 0

    If Select("SF4") <= 0
        Return ""
    EndIf

    nTamTes := TamSX3("F4_CODIGO")[1]
    dbSelectArea("SF4")
    SF4->(dbSetOrder(1))

    For nItem := 1 To Len(aItens)
        cTes := AllTrim(CCGetAutoField(aItens[nItem], "UB_TES", ""))
        If Empty(cTes)
            Loop
        EndIf

        nPos := AScan(aChecked, {|cCod| cCod == cTes})
        If nPos > 0
            Loop
        EndIf
        AAdd(aChecked, cTes)

        If !SF4->(dbSeek(xFilial("SF4") + PadR(cTes, nTamTes)))
            Return "TES " + cTes + " nao encontrada na tabela SF4."
        EndIf

        If !RecLock("SF4", .F.)
            Return "Registro bloqueado para uso. Tabela SF4-Tipos de Entrada e Saida (TES " + cTes + ")."
        EndIf
        SF4->(MsUnlock())
    Next nItem

Return ""

//-------------------------------------------------------------
// CCPreValidateAtend - Pre-valida cliente (SA1) e operador (SU7) para rotina 1
//-------------------------------------------------------------
Static Function CCValAtend(oObj)

    Local oCab     := CCGetObj(oObj, "cabecalho")
    Local cCod     := AllTrim(CCGetStr(oCab, "customerCode", ""))
    Local cLoja    := AllTrim(CCGetStr(oCab, "customerStore", ""))
    Local cOper    := AllTrim(CCGetStr(oCab, "operatorCode", ""))
    Local cCodLig  := AllTrim(CCGetStr(oCab, "callCode", ""))
    Local nTamCod  := 6
    Local nTamLoja := 2
    Local nTamOper := 6
    Local nTamLig  := 6

    // Rotina 1 (Teleatendimento) NAO exige itens. Itens sao ignorados.

    // Valida cliente em SA1
    If !Empty(cCod)
        If Select("SA1") > 0
            Begin Sequence
                nTamCod  := TamSX3("A1_COD")[1]
                nTamLoja := TamSX3("A1_LOJA")[1]
            Recover
                nTamCod  := 6
                nTamLoja := 2
            End Sequence
            dbSelectArea("SA1")
            SA1->(dbSetOrder(1))
            If !SA1->(dbSeek(xFilial("SA1") + PadR(cCod, nTamCod) + PadR(cLoja, nTamLoja)))
                Return "Cliente " + cCod + "/" + cLoja + " nao encontrado na tabela SA1."
            EndIf
        EndIf
    EndIf

    // Valida operador em SU7
    If !Empty(cOper)
        If Select("SU7") > 0
            Begin Sequence
                nTamOper := TamSX3("U7_COD")[1]
            Recover
                nTamOper := 6
            End Sequence
            dbSelectArea("SU7")
            SU7->(dbSetOrder(1))
            If !SU7->(dbSeek(xFilial("SU7") + PadR(cOper, nTamOper)))
                Return "Operador " + cOper + " nao encontrado na tabela SU7."
            EndIf
        EndIf
    EndIf

    // Valida codigo da ligacao em SU6
    If !Empty(cCodLig)
        If Select("SU6") > 0
            Begin Sequence
                nTamLig := TamSX3("U6_CODLIG")[1]
            Recover
                nTamLig := 6
            End Sequence
            dbSelectArea("SU6")
            SU6->(dbSetOrder(1))
            If !SU6->(dbSeek(xFilial("SU6") + PadR(cCodLig, nTamLig)))
                Return "Codigo de ligacao " + cCodLig + " nao encontrado na tabela SU6 (callCode)."
            EndIf
        EndIf
    EndIf

Return ""

//-------------------------------------------------------------
// CCBuildAtend - Monta arrays para Teleatendimento (rotina=1)
//-------------------------------------------------------------
// CCBuildAtend - Monta arrays para Atendimento (rotina API=1)
//
// UA_OPER='3' = Atendimento puro (sem pedido, sem itens SUB).
// TMKA271 cRotina='2' -> MA410 -> SUA.
// PE A410VZ deve retornar .T. quando UA_OPER='3'.
//-------------------------------------------------------------
Static Function CCBuildAtend(oObj, nOpcao, aCabec, aItens)

    Local oCab     := CCGetObj(oObj, "cabecalho")
    Local cVal     := ""

    // Atendimento nao tem itens SUB - garante array vazio
    ASize(aItens, 0)

    If nOpcao == 4
        cVal := CCGetStr(oCab, "attendanceNumber", "")
        If !Empty(cVal)
            CCAddField(aCabec, "UA_NUM", cVal)
        EndIf
    EndIf

    cVal := CCGetStr(oCab, "customerCode", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_CLIENTE", cVal)
    EndIf

    cVal := CCGetStr(oCab, "customerStore", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_LOJA", cVal)
    EndIf

    cVal := CCGetStr(oCab, "operatorCode", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_OPERADO", cVal)
    EndIf

    // UA_OPER='3' fixo para Atendimento (nao gera pedido SC5/SC6)
    CCAddField(aCabec, "UA_OPER", "3")

    // UA_TMK: 1=Receptivo 2=Ativo
    cVal := CCGetStr(oCab, "callType", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_TMK", cVal)
    EndIf

    // UA_CODLIG: codigo da ligacao (SU6)
    cVal := CCGetStr(oCab, "callCode", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_CODLIG", cVal)
    EndIf

    cVal := CCGetStr(oCab, "contactCode", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_CODCONT", cVal)
    EndIf

    cVal := CCGetStr(oCab, "attendanceDate", "")
    If !Empty(cVal)
        If Len(AllTrim(cVal)) == 8 .And. IsDigit(SubStr(cVal, 1, 1))
            CCAddField(aCabec, "UA_EMISSAO", SToD(cVal))
        Else
            CCAddField(aCabec, "UA_EMISSAO", CToD(cVal))
        EndIf
    Else
        CCAddField(aCabec, "UA_EMISSAO", dDataBase)
    EndIf

    cVal := CCGetStr(oCab, "processStatusCode", "")
    If Empty(cVal)
        cVal := CCGetStr(oCab, "status", "")
    EndIf
    If !Empty(cVal)
        CCAddField(aCabec, "UA_ZZSTATU", cVal)
    EndIf

    cVal := CCGetStr(oCab, "responseCode", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_ZZRESP", cVal)
    EndIf

    cVal := CCGetStr(oCab, "responseName", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_ZZNRESP", cVal)
    EndIf

    cVal := CCGetStr(oCab, "observation", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_ZZOBS", cVal)
    EndIf

    // Enderecos de cobranca e entrega (iguais a rotina 2/3)
    cVal := CCGetStr(oCab, "billingAddress", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_ENDCOB", cVal)
    EndIf

    cVal := CCGetStr(oCab, "billingComplement", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_COMPC", cVal)
    EndIf

    cVal := CCGetStr(oCab, "billingNeighborhood", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_BAIRROC", cVal)
    EndIf

    cVal := CCGetStr(oCab, "billingCity", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_MUNC", cVal)
    EndIf

    cVal := CCGetStr(oCab, "billingZipCode", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_CEPC", cVal)
    EndIf

    cVal := CCGetStr(oCab, "billingState", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_ESTC", cVal)
    EndIf

    cVal := CCGetStr(oCab, "deliveryAddress", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_ENDENT", cVal)
    EndIf

    cVal := CCGetStr(oCab, "deliveryComplement", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_COMPE", cVal)
    EndIf

    cVal := CCGetStr(oCab, "deliveryNeighborhood", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_BAIRROE", cVal)
    EndIf

    cVal := CCGetStr(oCab, "deliveryCity", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_MUNE", cVal)
    EndIf

    cVal := CCGetStr(oCab, "deliveryZipCode", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_CEPE", cVal)
    EndIf

    cVal := CCGetStr(oCab, "deliveryState", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_ESTE", cVal)
    EndIf

Return Nil

//-------------------------------------------------------------
// CCBuildVend - Monta arrays para Orcamento (rotina=2) e Faturamento (rotina=3)
//
// cForceOper: '2'=Orcamento (sem SC5/SC6), '1'=Faturamento (gera SC5/SC6)
//-------------------------------------------------------------
Static Function CCBuildVend(oObj, nOpcao, aCabec, aItens, cForceOper)

    Local oCab     := CCGetObj(oObj, "cabecalho")
    Local aIt      := CCGetArr(oObj, "itens")
    Local aLinha   := {}
    Local oItem    := Nil
    Local nI       := 0
    Local cVal     := ""
    Local nVal     := 0
    Local dDtlim   := CToD("")
    Local dDtentre := CToD("")

    Default cForceOper := ""

    If nOpcao == 4
        cVal := CCGetStr(oCab, "attendanceNumber", "")
        If !Empty(cVal)
            CCAddField(aCabec, "UA_NUM", cVal)
        EndIf
    EndIf

    cVal := CCGetStr(oCab, "customerCode", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_CLIENTE", cVal)
    EndIf

    cVal := CCGetStr(oCab, "customerStore", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_LOJA", cVal)
    EndIf

    cVal := CCGetStr(oCab, "operatorCode", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_OPERADO", cVal)
    EndIf

    // UA_OPER: forcado pelo parametro cForceOper (rotina API define o tipo)
    // '1'=Faturamento (gera SC5/SC6), '2'=Orcamento (sem SC5/SC6), '3'=Atendimento
    If !Empty(cForceOper)
        CCAddField(aCabec, "UA_OPER", cForceOper)
    Else
        cVal := CCGetStr(oCab, "attendanceType", "")
        If !Empty(cVal)
            CCAddField(aCabec, "UA_OPER", cVal)
        EndIf
    EndIf

    cVal := CCGetStr(oCab, "callType", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_TMK", cVal)
    EndIf

    cVal := CCGetStr(oCab, "paymentCondition", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_CONDPG", cVal)
    EndIf

    cVal := CCGetStr(oCab, "priceTable", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_TABELA", cVal)
    EndIf

    cVal := CCGetStr(oCab, "carrierCode", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_TRANSP", cVal)
    EndIf

    cVal := CCGetStr(oCab, "callCode", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_CODLIG", cVal)
    EndIf

    cVal := CCGetStr(oCab, "processStatusCode", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_ZZSTATU", cVal)
    EndIf

    cVal := CCGetStr(oCab, "responseCode", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_ZZRESP", cVal)
    EndIf

    cVal := CCGetStr(oCab, "responseName", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_ZZNRESP", cVal)
    EndIf

    cVal := CCGetStr(oCab, "vendorCode", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_VEND", cVal)
    EndIf

    cVal := CCGetStr(oCab, "paymentMethod", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_FORMPG", cVal)
    EndIf

    cVal := CCGetStr(oCab, "currencyCode", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_MOEDA", cVal)
    EndIf

    cVal := CCGetStr(oCab, "financialNature", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_ZZNATUR", cVal)
    EndIf

    cVal := CCGetStr(oCab, "orderType", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_ZZTPPED", cVal)
    EndIf

    cVal := CCGetStr(oCab, "deliveryStore", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_LOJAENT", cVal)
    EndIf

    cVal := CCGetStr(oCab, "billingAddress", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_ENDCOB", cVal)
    EndIf

    cVal := CCGetStr(oCab, "billingComplement", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_COMPC", cVal)
    EndIf

    cVal := CCGetStr(oCab, "billingNeighborhood", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_BAIRROC", cVal)
    EndIf

    cVal := CCGetStr(oCab, "billingCity", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_MUNC", cVal)
    EndIf

    cVal := CCGetStr(oCab, "billingZipCode", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_CEPC", cVal)
    EndIf

    cVal := CCGetStr(oCab, "billingState", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_ESTC", cVal)
    EndIf

    cVal := CCGetStr(oCab, "deliveryAddress", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_ENDENT", cVal)
    EndIf

    cVal := CCGetStr(oCab, "deliveryComplement", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_COMPE", cVal)
    EndIf

    cVal := CCGetStr(oCab, "deliveryNeighborhood", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_BAIRROE", cVal)
    EndIf

    cVal := CCGetStr(oCab, "deliveryCity", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_MUNE", cVal)
    EndIf

    cVal := CCGetStr(oCab, "deliveryZipCode", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_CEPE", cVal)
    EndIf

    cVal := CCGetStr(oCab, "deliveryState", "")
    If !Empty(cVal)
        CCAddField(aCabec, "UA_ESTE", cVal)
    EndIf

    cVal := CCGetStr(oCab, "limitDate", "")
    If !Empty(cVal)
        dDtlim := CToD("")
        If Len(AllTrim(cVal)) == 8 .And. IsDigit(SubStr(cVal, 1, 1))
            dDtlim := SToD(cVal)
        Else
            dDtlim := CToD(cVal)
        EndIf
        If dDtlim != CToD("")
            CCAddField(aCabec, "UA_DTLIM", dDtlim)
        EndIf
    EndIf

    // Fix: isProspect tratado corretamente como booleano JSON nativo
    CCAddField(aCabec, "UA_PROSPEC", CCGetBool(oCab, "isProspect", .F.))

    nVal := CCGetNum(oCab, "discountPercent", 0)
    If nVal > 0
        CCAddField(aCabec, "UA_DESCONT", nVal)
    EndIf

    nVal := CCGetNum(oCab, "freightValue", 0)
    If nVal > 0
        CCAddField(aCabec, "UA_FRETE", nVal)
    EndIf

    nVal := CCGetNum(oCab, "expenseValue", 0)
    If nVal > 0
        CCAddField(aCabec, "UA_DESPESA", nVal)
    EndIf

    For nI := 1 To Len(aIt)
        oItem  := aIt[nI]
        aLinha := {}

        cVal := CCGetStr(oItem, "itemNumber", "")
        If !Empty(cVal)
            CCAddField(aLinha, "UB_ITEM", cVal)
        EndIf

        If nOpcao == 4
            If !Empty(cVal)
                AADD(aLinha, {"LINPOS", "UB_ITEM", cVal})
            EndIf

            cVal := CCGetStr(oItem, "deleteItem", "")
            If !Empty(cVal)
                AADD(aLinha, {"AUTDELETA", cVal, Nil})
            EndIf
        EndIf

        cVal := CCGetStr(oItem, "productCode", "")
        If !Empty(cVal)
            CCAddField(aLinha, "UB_PRODUTO", cVal)
        EndIf

        nVal := CCGetNum(oItem, "quantity", 0)
        If nVal > 0
            CCAddField(aLinha, "UB_QUANT", nVal)
        EndIf

        nVal := CCGetNum(oItem, "unitPrice", 0)
        If nVal > 0
            CCAddField(aLinha, "UB_VRUNIT", nVal)
        EndIf

        cVal := CCGetStr(oItem, "itemOperation", "")
        If !Empty(cVal)
            CCAddField(aLinha, "UB_OPER", cVal)
        EndIf

        cVal := CCGetStr(oItem, "operationCode", "")
        If !Empty(cVal)
            CCAddField(aLinha, "UB_TES", cVal)
        EndIf

        cVal := CCGetStr(oItem, "cfopCode", "")
        If !Empty(cVal)
            CCAddField(aLinha, "UB_CF", cVal)
        EndIf

        cVal := CCGetStr(oItem, "warehouse", "")
        If !Empty(cVal)
            CCAddField(aLinha, "UB_LOCAL", cVal)
        EndIf

        cVal := CCGetStr(oItem, "defectCode", "")
        If !Empty(cVal)
            CCAddField(aLinha, "UB_ZZTPDEF", cVal)
        EndIf

        cVal := CCGetStr(oItem, "deliveryDate", "")
        If !Empty(cVal)
            dDtentre := CToD("")
            If Len(AllTrim(cVal)) == 8 .And. IsDigit(SubStr(cVal, 1, 1))
                dDtentre := SToD(cVal)
            Else
                dDtentre := CToD(cVal)
            EndIf
            If dDtentre != CToD("")
                CCAddField(aLinha, "UB_DTENTRE", dDtentre)
            EndIf
        EndIf

        If Len(aLinha) > 0
            AADD(aItens, aLinha)
        EndIf
    Next nI

Return Nil

//-------------------------------------------------------------
// CCBuildCob - Monta arrays para Telecobranca (rotina=3)
//-------------------------------------------------------------
Static Function CCBuildCob(oObj, nOpcao, aCabec, aItens)

    Local oCab   := CCGetObj(oObj, "cabecalho")
    Local aIt    := CCGetArr(oObj, "itens")
    Local aLinha := {}
    Local oItem  := Nil
    Local nI     := 0
    Local cVal   := ""
    Local dPend  := CToD("")

    If nOpcao == 4
        cVal := CCGetStr(oCab, "attendanceCode", "")
        If !Empty(cVal)
            AADD(aCabec, {"ACF_CODIGO", cVal, Nil})
        EndIf
    EndIf

    cVal := CCGetStr(oCab, "customerCode", "")
    If !Empty(cVal)
        AADD(aCabec, {"ACF_CLIENT", cVal, Nil})
    EndIf

    cVal := CCGetStr(oCab, "customerStore", "")
    If !Empty(cVal)
        AADD(aCabec, {"ACF_LOJA", cVal, Nil})
    EndIf

    cVal := CCGetStr(oCab, "operatorCode", "")
    If !Empty(cVal)
        AADD(aCabec, {"ACF_OPERAD", cVal, Nil})
    EndIf

    cVal := CCGetStr(oCab, "callType", "")
    If !Empty(cVal)
        AADD(aCabec, {"ACF_OPERA", cVal, Nil})
    EndIf

    cVal := CCGetStr(oCab, "contactCode", "")
    If !Empty(cVal)
        AADD(aCabec, {"ACF_CODCON", cVal, Nil})
    EndIf

    cVal := CCGetStr(oCab, "status", "")
    If !Empty(cVal)
        AADD(aCabec, {"ACF_STATUS", cVal, Nil})
    EndIf

    cVal := CCGetStr(oCab, "occurrenceCode", "")
    If !Empty(cVal)
        AADD(aCabec, {"ACF_MOTIVO", cVal, Nil})
    EndIf

    cVal := CCGetStr(oCab, "returnTime", "")
    If !Empty(cVal)
        AADD(aCabec, {"ACF_HRPEND", cVal, Nil})
    EndIf

    // Fix: campo "ACF_OBS" sem espacos (bug presente no exemplo do TDN)
    cVal := CCGetStr(oCab, "observation", "")
    If !Empty(cVal)
        AADD(aCabec, {"ACF_OBS", cVal, Nil})
    EndIf

    cVal := CCGetStr(oCab, "paymentCondition", "")
    If !Empty(cVal)
        AADD(aCabec, {"ACF_CONDPG", cVal, Nil})
    EndIf

    cVal := CCGetStr(oCab, "returnDate", "")
    If !Empty(cVal)
        If Len(AllTrim(cVal)) == 8 .And. IsDigit(SubStr(cVal, 1, 1))
            dPend := SToD(cVal)
        Else
            dPend := CToD(cVal)
        EndIf
        If dPend != CToD("")
            AADD(aCabec, {"ACF_PENDEN", dPend, Nil})
        EndIf
    EndIf

    If nOpcao == 4
        cVal := CCGetStr(oCab, "closingCode", "")
        If !Empty(cVal)
            AADD(aCabec, {"ACF_CODENC", cVal, Nil})
        EndIf

        cVal := CCGetStr(oCab, "closingObservation", "")
        If !Empty(cVal)
            AADD(aCabec, {"ACF_OBSMOT", cVal, Nil})
        EndIf
    EndIf

    For nI := 1 To Len(aIt)
        oItem  := aIt[nI]
        aLinha := {}

        If nOpcao == 4
            cVal := CCGetStr(oItem, "deleteItem", "")
            If !Empty(cVal)
                AADD(aLinha, {"AUTDELETA", cVal, Nil})
            EndIf
        EndIf

        cVal := CCGetStr(oItem, "titlePrefix", "")
        If !Empty(cVal)
            AADD(aLinha, {"ACG_PREFIX", cVal, Nil})
        EndIf

        cVal := CCGetStr(oItem, "titleInstallment", "")
        If !Empty(cVal)
            AADD(aLinha, {"ACG_PARCEL", cVal, Nil})
        EndIf

        // Fix: "ACG_TIPO" sem espacos (bug presente no exemplo do TDN: "ACG_TIPO  ")
        cVal := CCGetStr(oItem, "titleType", "")
        If !Empty(cVal)
            AADD(aLinha, {"ACG_TIPO", cVal, Nil})
        EndIf

        cVal := CCGetStr(oItem, "originBranch", "")
        If !Empty(cVal)
            AADD(aLinha, {"ACG_FILORI", cVal, Nil})
        EndIf

        cVal := CCGetStr(oItem, "titleNumber", "")
        If !Empty(cVal)
            AADD(aLinha, {"ACG_TITULO", cVal, Nil})
        EndIf

        cVal := CCGetStr(oItem, "titleStatus", "")
        If !Empty(cVal)
            AADD(aLinha, {"ACG_STATUS", cVal, Nil})
        EndIf

        If Len(aLinha) > 0
            AADD(aItens, aLinha)
        EndIf
    Next nI

Return Nil

//-------------------------------------------------------------
// CCAddField - Adiciona campo ao array normalizando o valor
//-------------------------------------------------------------
Static Function CCAddField(aTarget, cField, xValue)

    Local xNorm := CCNormalizeField(cField, xValue)

    If ValType(xNorm) != "U"
        AADD(aTarget, {cField, xNorm, Nil})
    EndIf

Return Nil

//-------------------------------------------------------------
// CCNormalizeField - Converte xValue para o tipo do campo no SX3
//-------------------------------------------------------------
Static Function CCNormalizeField(cField, xValue)

    Local aTam     := {}
    Local cFldType := ""
    Local cWork    := ""
    Local xRet     := xValue
    Local bOldErr  := Nil
    Local oErr     := Nil

    If Empty(cField)
        Return xValue
    EndIf

    bOldErr := ErrorBlock({|e| oErr := e, Break(e)})

    Begin Sequence
        aTam := TamSX3(cField)
    Recover
        aTam := {}
    End Sequence

    ErrorBlock(bOldErr)

    If ValType(aTam) == "A" .And. Len(aTam) >= 3 .And. ValType(aTam[3]) == "C"
        cFldType := Upper(AllTrim(aTam[3]))
    Else
        Return xValue
    EndIf

    Do Case
        Case cFldType == "C"
            If ValType(xValue) == "C"
                xRet := AllTrim(xValue)
            ElseIf ValType(xValue) == "N"
                xRet := AllTrim(cValToChar(xValue))
            ElseIf ValType(xValue) == "L"
                xRet := IIf(xValue, "T", "F")
            ElseIf ValType(xValue) == "D"
                xRet := DToS(xValue)
            EndIf

        Case cFldType == "N"
            If ValType(xValue) == "C"
                cWork := AllTrim(xValue)
                cWork := StrTran(cWork, ".", "")
                cWork := StrTran(cWork, ",", ".")
                xRet  := Val(cWork)
            ElseIf ValType(xValue) == "L"
                xRet := IIf(xValue, 1, 0)
            EndIf

        Case cFldType == "D"
            If ValType(xValue) == "C"
                cWork := AllTrim(xValue)
                If Len(cWork) == 8 .And. IsDigit(SubStr(cWork, 1, 1))
                    xRet := SToD(cWork)
                Else
                    xRet := CToD(cWork)
                EndIf
            EndIf

        Case cFldType == "L"
            If ValType(xValue) == "C"
                cWork := Upper(AllTrim(xValue))
                xRet := (cWork == "TRUE" .Or. cWork == "T" .Or. cWork == "1" .Or. ;
                          cWork == "S"    .Or. cWork == "Y" .Or. cWork == "YES")
            ElseIf ValType(xValue) == "N"
                xRet := (xValue <> 0)
            EndIf
    EndCase

Return xRet

//-------------------------------------------------------------
// CCBuildResp - Monta JSON de resposta padrao
//-------------------------------------------------------------
Static Function CCBuildResp(lOk, cMsg, oData)

    Local cResponse := ""
    Local cType     := ""

    cResponse := '{"success":' + IIf(lOk, "true", "false")
    cResponse += ',"message":"' + FwNoAccent(cMsg) + '"'

    If ValType(oData) != "U"
        cType := ValType(oData)
        If cType == "A"
            cResponse += ',"data":' + ArrayToJson(oData)
        ElseIf cType $ "OJ"
            cResponse += ',"data":' + oData:ToJson()
        EndIf
    Else
        cResponse += ',"data":null'
    EndIf

    cResponse += "}"

Return cResponse

//-------------------------------------------------------------
// CCGetStr - Extrai campo como String do JsonObject
//-------------------------------------------------------------
Static Function CCGetStr(oObj, cKey, cDefault)

    Local xVal := Nil
    Local lOk  := .T.

    Default cDefault := ""

    If ValType(oObj) == "U" .Or. !(ValType(oObj) $ "OJ")
        Return cDefault
    EndIf

    Begin Sequence
        xVal := oObj[cKey]
    Recover
        lOk := .F.
    End Sequence

    If !lOk
        Return cDefault
    EndIf

    If ValType(xVal) == "C"
        // Aplica substituicao explicita e converte para Maiusculo
        Return CCSanitizeStr(xVal)
    ElseIf ValType(xVal) == "N"
        // Sanitiza para garantir que a string fique maiuscula
        Return Upper(cValToChar(xVal))
    ElseIf ValType(xVal) == "L"
        Return IIf(xVal, "true", "false")
    EndIf

Return cDefault

//-------------------------------------------------------------
// CCSanitizeStr - Substitui sujeiras de UTF-8 e remove acentos
//-------------------------------------------------------------
Static Function CCSanitizeStr(cStr)
    Local cRet := cStr

    If ValType(cRet) != "C"
        Return ""
    EndIf

    // Substituicoes de UTF-8 quebrado (Ex: SAo Paulo) para letras normais
    cRet := StrTran(cRet, "ã", "A") // a til
    cRet := StrTran(cRet, "ç", "C") // c cedilha
    cRet := StrTran(cRet, "á", "A") // a agudo
    cRet := StrTran(cRet, "â", "A") // a circunflexo
    cRet := StrTran(cRet, "é", "E") // e agudo
    cRet := StrTran(cRet, "ê", "E") // e circunflexo
    cRet := StrTran(cRet, "�", "I") // i agudo
    cRet := StrTran(cRet, "ó", "O") // o agudo
    cRet := StrTran(cRet, "ô", "O") // o circunflexo
    cRet := StrTran(cRet, "õ", "O") // o til
    cRet := StrTran(cRet, "ú", "U") // u agudo

    cRet := StrTran(cRet, "Ã", "A") // A til
    cRet := StrTran(cRet, "Ç", "C") // C cedilha
    cRet := StrTran(cRet, "�", "A") // A agudo
    cRet := StrTran(cRet, "Â", "A") // A circunflexo
    cRet := StrTran(cRet, "É", "E") // E agudo
    cRet := StrTran(cRet, "Ê", "E") // E circunflexo
    cRet := StrTran(cRet, "Ó", "O") // O agudo
    cRet := StrTran(cRet, "Ô", "O") // O circunflexo
    cRet := StrTran(cRet, "Õ", "O") // O til
    cRet := StrTran(cRet, "Ú", "U") // U agudo

    // Limpa espacos e passa para maiusculo removendo acentos remanescentes
    cRet := Upper(FwNoAccent(AllTrim(cRet)))

Return cRet

//-------------------------------------------------------------
// CCGetNum - Extrai campo como Numerico do JsonObject
//-------------------------------------------------------------
Static Function CCGetNum(oObj, cKey, nDefault)

    Local xVal := Nil
    Local lOk  := .T.

    Default nDefault := 0

    If ValType(oObj) == "U" .Or. !(ValType(oObj) $ "OJ")
        Return nDefault
    EndIf

    Begin Sequence
        xVal := oObj[cKey]
    Recover
        lOk := .F.
    End Sequence

    If !lOk
        Return nDefault
    EndIf

    If ValType(xVal) == "N"
        Return xVal
    ElseIf ValType(xVal) == "C"
        Return Val(xVal)
    EndIf

Return nDefault

//-------------------------------------------------------------
// CCGetBool - Extrai campo como Logico do JsonObject
//             Suporta: booleano JSON nativo, "true"/"false",
//             "S"/"N", "T"/"F", "Y"/"N", 1/0
//-------------------------------------------------------------
Static Function CCGetBool(oObj, cKey, lDefault)

    Local xVal  := Nil
    Local lOk   := .T.
    Local cWork := ""

    Default lDefault := .F.

    If ValType(oObj) == "U" .Or. !(ValType(oObj) $ "OJ")
        Return lDefault
    EndIf

    Begin Sequence
        xVal := oObj[cKey]
    Recover
        lOk := .F.
    End Sequence

    If !lOk
        Return lDefault
    EndIf

    If ValType(xVal) == "L"
        Return xVal
    ElseIf ValType(xVal) == "N"
        Return (xVal <> 0)
    ElseIf ValType(xVal) == "C"
        cWork := Upper(AllTrim(xVal))
        Return (cWork == "TRUE" .Or. cWork == "T" .Or. cWork == "1" .Or. ;
                cWork == "S"    .Or. cWork == "Y" .Or. cWork == "YES")
    EndIf

Return lDefault

//-------------------------------------------------------------
// CCGetObj - Extrai campo como Objeto do JsonObject
//-------------------------------------------------------------
Static Function CCGetObj(oObj, cKey)

    Local xVal := Nil
    Local lOk  := .T.

    If ValType(oObj) == "U" .Or. !(ValType(oObj) $ "OJ")
        Return Nil
    EndIf

    Begin Sequence
        xVal := oObj[cKey]
    Recover
        lOk := .F.
    End Sequence

    If !lOk
        Return Nil
    EndIf

    If ValType(xVal) $ "OJ"
        Return xVal
    EndIf

Return Nil

//-------------------------------------------------------------
// CCGetArr - Extrai campo como Array do JsonObject
//-------------------------------------------------------------
Static Function CCGetArr(oObj, cKey)

    Local xVal := Nil
    Local lOk  := .T.

    If ValType(oObj) == "U" .Or. !(ValType(oObj) $ "OJ")
        Return {}
    EndIf

    Begin Sequence
        xVal := oObj[cKey]
    Recover
        lOk := .F.
    End Sequence

    If !lOk
        Return {}
    EndIf

    If ValType(xVal) == "A"
        Return xVal
    EndIf

Return {}

//-------------------------------------------------------------
// CCGetAutoErr - Captura mensagem de erro do ExecAuto
//               Ordem de prioridade:
//               1. GetAutoGrLog()
//               2. aMSMensagens  (Fix v1.1)
//               3. aAutoErro
//               4. __cAutoHelp
//               5. cMSMensagem
//-------------------------------------------------------------
Static Function CCGetAutoErr()

    Local cError := ""
    Local aLog   := {}
    Local oDummy := Nil

    // Preferimos o GrLog ja capturado (PRIVATE aCCGrLog) porque GetAutoGrLog
    // pode retornar vazio nas chamadas subsequentes a primeira.
    If Type("aCCGrLog") == "A" .And. Len(aCCGrLog) > 0
        aLog := aCCGrLog
    ElseIf FindFunction("GetAutoGrLog")
        aLog := GetAutoGrLog()
    EndIf

    CCParseAutoErr(aLog, @cError, @oDummy)

    If Empty(cError) .And. Type("aMSMensagens") == "A" .And. Len(aMSMensagens) > 0
        CCParseAutoErr(aMSMensagens, @cError, @oDummy)
    EndIf

    If Empty(cError) .And. Type("aAutoErro") == "A" .And. Len(aAutoErro) > 0
        CCParseAutoErr(aAutoErro, @cError, @oDummy)
    EndIf

    If Empty(cError) .And. Type("__cAutoHelp") == "C" .And. !Empty(__cAutoHelp)
        cError := AllTrim(__cAutoHelp)
    EndIf

    If Empty(cError) .And. Type("cMSMensagem") == "C" .And. !Empty(AllTrim(cMSMensagem))
        cError := AllTrim(cMSMensagem)
    EndIf

    If Empty(cError)
        cError := CCGetMostraErro()
    EndIf

    ConOut("[CALLCENTER API] Erro capturado: [" + cError + "]")

    If !Empty(cError)
        cError := FwNoAccent(cError)
        cError := StrTran(cError, Chr(13), " ")
        cError := StrTran(cError, Chr(10), " ")
        cError := AllTrim(cError)
    EndIf

    If Empty(cError)
        cError := "Erro no ExecAuto TMKA271. Verifique o log do servidor."
    EndIf

Return cError

Static Function CCFormatAutoErr(cMsg)

    Local cRet := AllTrim(cMsg)
    Local nPos := 0

    If "AJUDA:REGBLOQ" $ Upper(cRet)
        nPos := At("SF4-", Upper(cRet))
        If nPos > 0
            cRet := "Registro bloqueado para uso. Tabela " + AllTrim(SubStr(cRet, nPos, Len(cRet) - nPos + 1))
        Else
            cRet := "Registro bloqueado para uso. Tente novamente em instantes."
        EndIf
    EndIf

Return cRet

Static Function CCGetAutoStatus(cMsg)

    If "AJUDA:REGBLOQ" $ Upper(AllTrim(cMsg)) .Or. "REGISTRO BLOQUEADO" $ Upper(AllTrim(cMsg))
        Return 409
    EndIf

Return 422

Static Function CCParseAutoErr(aLogAuto, cError, oDetails)

    Local nY        := 0
    Local cLine     := ""
    Local cHelp     := ""
    Local cMsgErro  := ""
    Local aErros    := {}
    Local nPos      := 0
    Local nPos2     := 0
    Local cItemErr  := ""
    Local cCampo    := ""
    Local cValor    := ""
    Local cMotivo   := ""

    cError := ""
    oDetails := Nil

    If ValType(aLogAuto) != "A" .Or. Len(aLogAuto) == 0
        Return
    EndIf

    ConOut("[CALLCENTER API] ParseAutoErr linhas: " + cValToChar(Len(aLogAuto)))

    For nY := 1 To Len(aLogAuto)
        If ValType(aLogAuto[nY]) != "C"
            Loop
        EndIf

        cLine := AllTrim(aLogAuto[nY])

        // "Erro no Item N" marca inicio de bloco com campo invalido
        If "Erro no Item" $ cLine
            cItemErr := cLine
            Loop
        EndIf

        // Campo marcado como invalido: "Descricao - CAMPO := VALOR < -- Invalido"
        // Padrao do TOTVS para sinalizar valor rejeitado pelo ExecAuto.
        If "<-- Invalido" $ StrTran(Upper(cLine), " ", "") .Or. ;
           "<--INVALIDO"  $ StrTran(Upper(cLine), " ", "")
            // Extrai nome do campo entre " - " e " := "
            nPos  := At(" - ", cLine)
            nPos2 := At(":=", cLine)
            If nPos > 0 .And. nPos2 > nPos
                cCampo := AllTrim(SubStr(cLine, nPos + 3, nPos2 - nPos - 3))
                cValor := AllTrim(SubStr(cLine, nPos2 + 2))
                // remove o sufixo "< -- Invalido" do valor
                If At("<", cValor) > 0
                    cValor := AllTrim(SubStr(cValor, 1, At("<", cValor) - 1))
                EndIf
                cMotivo := "Campo invalido: " + cCampo + " = [" + cValor + "]"
            Else
                cMotivo := AllTrim(cLine)
            EndIf
            If !Empty(cItemErr)
                cMotivo := cItemErr + " - " + cMotivo
                cItemErr := ""
            EndIf
            aAdd(aErros, cMotivo)
            Loop
        EndIf

        If Empty(cLine) .Or. Left(cLine, 5) == "-----" .Or. Left(cLine, 6) == "Tabela"
            Loop
        EndIf

        If "AJUDA:" $ cLine .Or. "HELP:" $ cLine
            cHelp := cLine
            Loop
        EndIf

        If "Mensagem do erro:" $ cLine .Or. "MENSAGEM DO ERRO:" $ Upper(cLine)
            nPos := At("[", cLine)
            nPos2 := At("]", cLine)
            If nPos > 0 .And. nPos2 > nPos
                cMsgErro := AllTrim(SubStr(cLine, nPos + 1, nPos2 - nPos - 1))
            ElseIf At(":", cLine) > 0
                cMsgErro := AllTrim(SubStr(cLine, At(":", cLine) + 1))
            EndIf
            Loop
        EndIf

        If "Erro -->" $ cLine
            nPos := At("-->", cLine)
            If nPos > 0
                aAdd(aErros, AllTrim(SubStr(cLine, nPos + 3)))
            EndIf
            Loop
        EndIf

        If "AUTDELETA" $ cLine
            Loop
        EndIf

        If Empty(cHelp) .And. !(":=" $ cLine) .And. !("Erro no Item" $ cLine) .And. !("Erro -->" $ cLine)
            If Empty(cError) .And. !("Item" $ Left(cLine, 4))
                cError := cLine
            EndIf
            Loop
        EndIf

        If !Empty(cHelp) .And. Empty(cError) .And. !(":=" $ cLine) .And. !("Erro" $ cLine)
            cError := cLine
            Loop
        EndIf
    Next nY

    If !Empty(cMsgErro)
        cError := cMsgErro
    EndIf

    If !Empty(cHelp) .And. !Empty(cError)
        cError := cHelp + " - " + cError
    ElseIf !Empty(cHelp) .And. Empty(cError)
        cError := cHelp
    EndIf

    If Len(aErros) > 0
        For nY := 1 To Len(aErros)
            If !Empty(cError)
                cError += " | " + aErros[nY]
            Else
                cError := aErros[nY]
            EndIf
        Next nY
    EndIf

    If !Empty(cError)
        cError := FwNoAccent(cError)
    EndIf

Return

Static Function CCGetMostraErro()

    Local cError   := ""
    Local cArqLog  := ""
    Local cBuffer  := ""
    Local nX       := 0
    Local cLogPath := "\logs\"
    Local bOldErr  := Nil

    bOldErr := ErrorBlock({|e| Break(e)})

    Begin Sequence
        If !ExistDir(cLogPath)
            MakeDir(cLogPath)
        EndIf

        cError := MostraErro(cLogPath, cArqLog)
    Recover
        cError := ""
    End Sequence

    ErrorBlock(bOldErr)

    If Empty(cError)
        Return ""
    EndIf

    For nX := 1 To MlCount(cError)
        cBuffer := RTrim(MemoLine(cError,, nX,, .F.))
        If AllTrim(Upper(SubStr(cBuffer, 1, 17))) == "MENSAGEM DO ERRO:"
            cError := StrTran(SubStr(cBuffer, At("[", cBuffer) + 1, 250), "]", "")
            Exit
        EndIf
    Next nX

    cError := FwNoAccent(cError)
    cError := StrTran(cError, Chr(13), " ")
    cError := StrTran(cError, Chr(10), " ")
    cError := AllTrim(cError)

Return cError

//-------------------------------------------------------------
// CCGetErrMsg - Extrai descricao de objeto de erro
//-------------------------------------------------------------
Static Function CCGetErrMsg(oErr)

    Local cMsg := "Erro interno desconhecido."

    Begin Sequence
        If ValType(oErr) != "U" .And. ValType(oErr:Description) == "C" .And. !Empty(AllTrim(oErr:Description))
            cMsg := FwNoAccent(AllTrim(oErr:Description))
        EndIf
    Recover
        cMsg := "Erro interno desconhecido."
    End Sequence

Return cMsg

//-------------------------------------------------------------
// CCGetErrInfo - Extrai propriedade de objeto de erro como String
//-------------------------------------------------------------
Static Function CCGetErrInfo(oErr, cProp)

    Local xVal := Nil
    Local cVal := ""

    Begin Sequence
        xVal := oErr[cProp]
    Recover
        xVal := Nil
    End Sequence

    Do Case
        Case ValType(xVal) == "C"
            cVal := AllTrim(xVal)
        Case ValType(xVal) == "N"
            cVal := cValToChar(xVal)
        Case ValType(xVal) == "L"
            cVal := IIf(xVal, "T", "F")
        Otherwise
            cVal := ""
    EndCase

Return cVal
