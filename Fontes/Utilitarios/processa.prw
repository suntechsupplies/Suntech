#Include "Protheus.ch"
#Include "TopConn.ch"
 
/*/{Protheus.doc} incproctst
Função de exemplo de barras de processamento em AdvPL
@author Bruno Pirolo
@since 28/10/2018
@version 1.0
@type function
/*/ 
User Function incproctst()
    Local aArea         as array
    Private oNewProess as object
 
    aArea := GetArea()
 
    Processa({|| fExemplo5()}, "Filtrando...", , , , )
 
    RestArea(aArea)
    Conout("*********incproctst finalizada pelo scheduller***********")
Return
    
/*-----------------------------------------------------------*
 | Func.: fExemplo5                                          |
 | Desc.: Exemplo utilizando Processa                        |
 *-----------------------------------------------------------*/
Static Function fExemplo5()
    Local aArea     as array
    Local nAtual    as numeric
    Local nTotal    as numeric
    Local cQryAux   as character
     
    aArea  := GetArea()
    nAtual := 0
    nTotal := 0
     
    //Monta a consulta de grupo de produtos
    cQryAux := " SELECT * FROM "+RetSqlName("SB1") + "  SB1 "+ CRLF
    cQryAux += " WHERE  SB1.D_E_L_E_T_ = ' ' "
        
    //Executa a consulta
    TCQuery cQryAux New Alias "QRY_AUX"
        
    //Conta quantos registros existem, e seta no tamanho da régua
    Count To nTotal
    ProcRegua(nTotal)
        
    //Percorre todos os registros da query
    QRY_AUX->(DbGoTop())
    While ! QRY_AUX->(EoF())
            
        //Incrementa a mensagem na régua
        nAtual++
        IncProc("Analisando registro " + cValToChar(nAtual) + " de " + cValToChar(nTotal) + "...")
 
        QRY_AUX->(DbSkip())
    EndDo
    QRY_AUX->(DbCloseArea())
    RestArea(aArea)
Return
