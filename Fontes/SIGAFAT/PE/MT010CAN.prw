#Include 'Totvs.ch'

/*----------------------------------------------------------------------
{Protheus.doc}  MT010CAN
                Gravar campo de controle para Integra��o via API (Suntech)
                LOCALIZA��O: Este ponto est� localizado nas fun��es  A010Inclui (Inclus�o do Produto), 
                A010Altera (Altera��o do Produto) e A010Deleta (Dele��o do Produto).
                EM QUE PONTO: No final das fun��es citadas, ap�s  atualizar ou n�o os dados do Produto; 
                Pode ser utilizado para executar customiza��es conforme o tipo de retorno: 
                Execu��o OK ou Execu��o Cancelada.
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
