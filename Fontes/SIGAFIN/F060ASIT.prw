/*/{Protheus.doc} F060ASIT

    Ponto de entrada da rotina FINA060 (Bordero de Contas a Receber), chamado
    pela funcao FA060AGE2(). Permite desconsiderar a trava de transferencia de
    agencia/conta para titulos a receber vinculados a um bordero.

    Retorna .T. para desconsiderar a trava ou .F. para mante-la.

@type function
@see FINA060, FA060AGE2
/*/

User Function F060ASIT()
    Local lRet := .T. // .T. para invalidar a trava, .F. para manter
    
    // Suas regras de negócio aqui
    
Return lRet
