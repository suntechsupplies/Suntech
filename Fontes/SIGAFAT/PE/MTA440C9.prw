#INCLUDE "PROTHEUS.CH"           

/**
 * Rotina		:	MTA440C9 
 * Autor		:	Dione Oliveira - Totvs JundiaÃ­
 * Data			:	04/11/2019
 * Descricao	:	Ponto de entrada para todos os itens do pedido. Usado para liberar os pedidos de credito.
 * Cliente		:	Suntech HB
 * Modulo		:  	SIGAFAT
 */      

User Function MTA440C9() 

Local AreaATU := GetArea()
Local AreaSC5 := SC5->(GetArea()) 
Local AreaSC9 := SC9->(GetArea())                                

/*
//- Caso o pedido jÃ¡ tenha sido liberado no CrÃ©dito o mesmo nÃ£o necessitarÃ¡ de nova liberação
	If (SC5->C5_ZZSITFI $ '12')
		DbSelectArea("SC9")
		RecLock("SC9",.F.)  
		SC9->C9_BLCRED := ""
		MsUnlock()
	EndIf
*/
//- Verificação/Atualização de status no pedido de venda
	DbSelectArea("SC5")
	RecLock("SC5",.F.)  

	If Empty(SC9->C9_BLCRED) .And. SC9->C9_BLEST == "02" // 01- INDICA BLOQUEIO POR ESTOQUE
			SC5->C5_ZZSITFI := "2"		
		ElseIf SC9->C9_BLCRED >= "01" .And. SC9->C9_BLCRED <= "06" .AND. SC9->C9_BLEST == "02" // 01- INDICA BLOQUEIO POR CREDITO E ESTOQUE
			SC5->C5_ZZSITFI := "3"	
		ElseIf Empty(SC9->C9_BLCRED) .And. Empty(SC9->C9_BLEST) // 01- INDICA LIBERADO CRÃ‰DITO E ESTOQUE
			SC5->C5_ZZSITFI := '1'	
	EndIf

	MsUnlock()
     
RestArea(AreaSC9) 
RestArea(AreaSC5)
RestArea(AreaATU)

Return ()         

