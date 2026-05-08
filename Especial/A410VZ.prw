#Include "Protheus.ch"

//-------------------------------------------------------------
// Ponto de Entrada: A410VZ
//
// Chamado pelo MA410 (TMKA271 cRotina='2') durante ExecAuto
// para validar os itens do Call Center.
//
// CONVENCAO MA410:
//   Retorna .F. => PULA a validacao de itens (sem erro)
//   Retorna .T. => EXECUTA a validacao de itens normalmente
//
// Quando chamado pela API CallCenter (lCCApiMode=.T.):
//   - Sempre retorna .F. (pula validacao), pois a API ja
//     pre-valida via CCPreValidateVend, e Atendimento (UA_OPER=3)
//     nao tem itens SUB.
//
// Quando chamado pelo operador na tela (lCCApiMode=.F. ou indefinido):
//   - Retorna .T. (executa validacao normalmente pela tela).
//
// Compilar e aplicar ao RPO antes de usar a API CallCenter.
//-------------------------------------------------------------
User Function A410VZ()

    Local nPos  := 0
    Local cOper := ""

    // Fallback principal: se o proprio cabecalho do ExecAuto veio com UA_OPER=3,
    // trata como Atendimento puro e pula a validacao mesmo sem lCCApiMode.
    If Type("aCabec") == "A" .And. Len(aCabec) > 0
        nPos := AScan(aCabec, {|a| ValType(a) == "A" .And. Len(a) >= 2 .And. ;
                               Upper(AllTrim(cValToChar(a[1]))) == "UA_OPER"})
        If nPos > 0
            cOper := AllTrim(cValToChar(aCabec[nPos][2]))
        EndIf
    EndIf

    If cOper == "3"
        ConOut("[A410VZ] UA_OPER=3 (Atendimento) - pulando validacao de itens.")
        Return .F.
    EndIf

    // lCCApiMode e PRIVATE setado em CCProcessRequest antes do MsExecAuto.
    // Se .T. -> chamada vem da API -> pula validacao retornando .F.
    If Type("lCCApiMode") == "L" .And. lCCApiMode
        ConOut("[A410VZ] lCCApiMode=T (chamada via API) - pulando validacao de itens.")
        Return .F.
    EndIf

    // Chamada pela tela (operador manual) - executa validacao normal do MA410.
    ConOut("[A410VZ] UA_OPER=[" + cOper + "] lCCApiMode=F/indefinido - validacao normal.")

Return .T.
