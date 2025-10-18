//Bibliotecas
#Include "TOTVS.ch"
#Include "TopConn.ch"
 
/*/{Protheus.doc} User Function zExecQry
Fun��o que executa uma query e j� exibe um log em tela em caso de falha
@type  Function
@author Atilio
@since 27/01/2023
@param cQuery, Caractere, Query SQL que ser� executada no banco
@param lFinal, L�gico, Define se ir� encerrar o sistema em caso de falha
@return lDeuCerto, L�gico, .T. se a query foi executada com sucesso ou .F. se n�o
@example
    u_zExecQry("UPDATE TABELA SET CAMPO = 'AAAA'")
/*/

User Function UpdateZB8()
 
    Local aArea     := FWGetArea()
    Local lDeuCerto := .F.
    Local cQuery    := ""
 
    //Executa a query de atualiza��o do saldo de cashback
    cQuery += "UPDATE ZB8010 SET ZB8_PORTAD = 'X' WHERE ZB8_CLIENT+ZB8_LOJA IN (SELECT A1_COD+A1_LOJA FROM SA1010 WHERE D_E_L_E_T_ =  '' AND A1_GRPVEN <> '000005')"
 
    //Executa a query e verifica se deu certo
    lDeuCerto := zExecQry(cQuery, .T.)
 
    //Se n�o deu certo, aborta o sistema
    If ! lDeuCerto
        Final("UpdateZB8: Falha na opera��o. Contate o Administrador.")
    EndIf
 
    //Restaura a �rea original
    FWRestArea(aArea)

Return


Static Function zExecQry(cQuery, lFinal)
    Local aArea     := FWGetArea()
    Local lDeuCerto := .F.
    Local cMensagem := ""
    Default cQuery  := ""
    Default lFinal  := .F.
 
    //Executa a clausula SQL
    If TCSqlExec(cQuery) < 0
         
        //Caso n�o esteja rodando via job / ws, monta a mensagem e exibe
        If ! IsBlind()
            cMensagem := "Falha na atualiza��o do Banco de Dados!" + CRLF + CRLF
            cMensagem += "/* ==== Query: ===== */" + CRLF
            cMensagem += cQuery + CRLF + CRLF
            cMensagem += "/* ==== Mensagem: ===== */" + CRLF
            cMensagem += TCSQLError()
            ShowLog(cMensagem)
        EndIf
 
        //Se for para abortar o sistema, ser� exibido uma mensagem
        If lFinal
            Final("zExecQry: Falha na opera��o. Contate o Administrador.")
        EndIf
 
    //Se deu tudo certo, altera a flag de retorno
    Else
        lDeuCerto := .T.
    EndIf
 
    FWRestArea(aArea)    
Return lDeuCerto
