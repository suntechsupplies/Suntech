#Include "Protheus.ch"
 
/*/{Protheus.doc} ExecFonte
Função Mini Fórmulas, para executar fórmulas
@author Atilio
@since 17/12/2017
@version 1.0
@type function
@obs Assim como o fórmulas foi bloqueado no Protheus 12, cuidado ao deixar exposto no menu o Mini Fórmulas
/*/
 
User Function ExecFonte()

    Local aArea := GetArea()
    //Variáveis da tela
    Private oDlgForm
    Private oGrpForm
    Private oGetForm
    Private cGetForm := Space(250)
    Private oGrpAco
    Private oBtnExec
    //Tamanho da Janela
    Private nJanLarg := 500
    Private nJanAltu := 120
    Private nJanMeio := ((nJanLarg)/2)/2
    Private nTamBtn  := 048
     
    //Criando a janela
    DEFINE MSDIALOG oDlgForm TITLE "ExecFonte - Execução de Fontes" FROM 000, 000  TO nJanAltu, nJanLarg COLORS 0, 16777215 PIXEL
        //Grupo Fórmula com o Get
        @ 003, 003  GROUP oGrpForm TO 30, (nJanLarg/2)-1        PROMPT "Fonte: " OF oDlgForm COLOR 0, 16777215 PIXEL
            @ 010, 006  MSGET oGetForm VAR cGetForm SIZE (nJanLarg/2)-9, 013 OF oDlgForm COLORS 0, 16777215 PIXEL
         
        //Grupo Ações com o Botão
        @ (nJanAltu/2)-30, 003 GROUP oGrpAco TO (nJanAltu/2)-3, (nJanLarg/2)-1 PROMPT "Ações: " OF oDlgForm COLOR 0, 16777215 PIXEL
            @ (nJanAltu/2)-24, nJanMeio - (nTamBtn/2) BUTTON oBtnExec PROMPT "Executar" SIZE nTamBtn, 018 OF oDlgForm ACTION(fExecuta()) PIXEL
         
    //Ativando a janela
    ACTIVATE MSDIALOG oDlgForm CENTERED
     
    RestArea(aArea)
Return
 
/*---------------------------------------*
 | Func.: fExecuta                       |
 | Desc.: Executa a fórmula digitada     |
 *---------------------------------------*/
 
Static Function fExecuta()
    Local aArea    := GetArea()
    Local cFormula := AllTrim(cGetForm)
    Local cFuncao  := ""
    Local cArgs    := "()"
    Local nAbre    := 0
    Local nCaract  := 0
    Local xRetorno := Nil
    Local cError   := ""
    Local bError   := Nil
    Local oExecError := Nil
     
    //Se tiver conteúdo digitado
    If ! Empty(cFormula)

        nAbre := At("(", cFormula)
        If nAbre > 0
            cFuncao := Upper(AllTrim(Left(cFormula, nAbre - 1)))
            cArgs := SubStr(cFormula, nAbre)
            If Right(cArgs, 1) != ")"
                MsgAlert("Chamada invalida: feche os parenteses da funcao.", "ExecFonte")
                RestArea(aArea)
                Return
            EndIf
        Else
            cFuncao := Upper(cFormula)
        EndIf

        If Empty(cFuncao)
            MsgAlert("Informe o nome da funcao.", "ExecFonte")
            RestArea(aArea)
            Return
        EndIf
        For nCaract := 1 To Len(cFuncao)
            If !(SubStr(cFuncao, nCaract, 1) $ "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
                MsgAlert("Nome de funcao invalido: " + cFuncao, "ExecFonte")
                RestArea(aArea)
                Return
            EndIf
        Next nCaract
        If Left(cFuncao, 2) != "U_"
            cFuncao := "U_" + cFuncao
        EndIf

        If !FindFunction(cFuncao)
            MsgAlert("Funcao nao encontrada no RPO: " + cFuncao, "ExecFonte")
            RestArea(aArea)
            Return
        EndIf

        cFormula := cFuncao + cArgs
        bError := ErrorBlock({|oError| Break(oError)})

        //Inicio a utilização da tentativa
        Begin Sequence
            xRetorno := &(cFormula)
            If ValType(xRetorno) == "L"
                If !xRetorno
                    cError := "A funcao retornou .F.; confira o resultado da operacao."
                EndIf
            ElseIf ValType(xRetorno) == "A"
                If Len(xRetorno) >= 2
                    If ValType(xRetorno[1]) == "L" .And. ValType(xRetorno[2]) == "C"
                        If !xRetorno[1]
                            cError := xRetorno[2]
                            If Empty(cError)
                                cError := "A funcao informou falha sem mensagem."
                            EndIf
                        EndIf
                    EndIf
                EndIf
            EndIf
        Recover Using oExecError
            If ValType(oExecError) == "O"
                cError := cValToChar(oExecError:Description)
            Else
                cError := cValToChar(oExecError)
            EndIf
        End Sequence
         
        //Restaurando bloco de erro do sistema
        ErrorBlock(bError)
         
        //Se houve erro, será mostrado ao usuário
        If ! Empty(cError)
            MsgStop("Houve um erro na fórmula digitada: "+CRLF+CRLF+cError, "Atenção")
        else
            FWAlertSuccess("Programa Executado com Sucesso!", "ExecFonte")
        EndIf
    EndIf
     
    RestArea(aArea)
Return
