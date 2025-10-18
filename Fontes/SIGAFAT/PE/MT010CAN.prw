#Include 'Totvs.ch'

/*----------------------------------------------------------------------
{Protheus.doc}  MT010CAN
                Gravar campo de controle para Integração via API (Suntech)
                LOCALIZAÇÃO: Este ponto está localizado nas funções  A010Inclui (Inclusão do Produto), 
                A010Altera (Alteração do Produto) e A010Deleta (Deleção do Produto).
                EM QUE PONTO: No final das funções citadas, após  atualizar ou não os dados do Produto; 
                Pode ser utilizado para executar customizações conforme o tipo de retorno: 
                Execução OK ou Execução Cancelada.
Eventos 
@type           function
@version        
@author         Antonio Ricardo de Araujo (Suntech)
@since          17/01/2023
@return         nil
---------------------------------------------------------------------*/

User Function MT010CAN()

Local aArea := GetArea()
Local nOpc  := ParamIxb[1]

    If nOpc == 1 .AND. ALTERA
        
        Reclock("SB1",.F.)	    
            SB1->B1_ZSTATUS := "4"		
        SB1->(MsUnLock())

    ElseIf nOpc == 2 .AND. !ALTERA .AND. !INCLUI
        
        Reclock("SB1",.F.)	    
            SB1->B1_ZSTATUS := "5"		
        SB1->(MsUnLock())

    EndIf

RestArea(aArea)	

Return Nil
