#INCLUDE "PROTHEUS.CH"           

/**
 * Rotina	:	MTA440C9 - Liberação de pedido de venda 
 * Autor	:	Dione Oliveira - Totvs Jundiaí
 * Data		:	04/11/2019
 * Descricao:	Ponto de entrada para todos os itens do pedido. Usado para gravar o campo C5_ZZSITFI
				Chamado na gravacao e liberacao do pedido de Venda, apos a atualizacao do acumulados do SA1.
 * Modulo	:  	SIGAFAT
 * 				C5_ZZSITFI : 1=Comercial OK; 2=Liberado; 3=Bloqueado
 */      

User Function MTA440C9() 

	Local AreaATU := GetArea()
	Local AreaSC5 := SC5->(GetArea()) 
	Local AreaSC9 := SC9->(GetArea())                                
	Local nI	  := 0

	If Empty(SC9->C9_BLCRED)		  	// C9_BLCRED  = " " = LIBERADO
		nI++
	ElseIf SC9->C9_BLCRED == "09" 	// C9_BLCRED  = 09 	= REJEITADO
		nI--
	EndIf

	DbSelectArea("SC5")
	RecLock("SC5",.F.) 
	
	If nI = 0
		replace SC5->C5_ZZSITFI with '1' // 1 = Comercial OK
	ElseIf nI > 0
		replace SC5->C5_ZZSITFI with '2' // 2 = Liberado
	ElseIf nI < 0
		replace SC5->C5_ZZSITFI with '3' // 3 = Bloqueado
	EndIf
	
	MsUnlock()
      
	RestArea(AreaSC9) 
	RestArea(AreaSC5)
	RestArea(AreaATU)

Return ()         

