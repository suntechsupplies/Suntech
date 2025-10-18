#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'tbiconn.ch'
#Include 'topconn.ch'   

/**
 * Rotina		:	MTA440C9 
 * Autor		:	Dione Oliveira - Totvs JundiaÃ­
 * Data			:	04/11/2019
 * Descricao	:	Ponto de entrada para todos os itens do pedido. Usado para liberar os pedidos de credito.
 * Cliente		:	Suntech HB
 * Modulo		:  	SIGAFAT
 ------------------------------------------------------------------------------------------------------------
 * Alteração    :	26/08/2020 
   Descricao 	:	Adicionado trecho para tratar da customização junto ao portal da Blu.
   Autor        :	Cyberpolos
 */      

User Function MTA440C9() 

	Local AreaATU := GetArea()
	Local AreaSC5 := SC5->(GetArea()) 
	Local AreaSC9 := SC9->(GetArea()) 
	Local aRet    := {}     
	Local cItem   := ""      
	Local lUseBlu := .T.
	Local lLibPed := .F.
		
    //Parametro para verIficar se as rotina BLU está ativa
    lUseBlu :=  GetMv('CP_BLUUSE')                 


//- Caso o pedido já tenha sido liberado no Crédito o mesmo não necessitará de nova liberação
	If (SC5->C5_ZZSITFI $ '12')
		DbSelectArea("SC9")
		RecLock("SC9",.F.)  
		SC9->C9_BLCRED := ""
		MsUnlock()
	EndIf
/*
//- Verificação/Atualização de status no pedido de venda
	DbSelectArea("SC5")
	RecLock("SC5",.F.)  

	If Empty(SC9->C9_BLCRED) .And. SC9->C9_BLEST == "02" // 01- INDICA BLOQUEIO POR ESTOQUE
			SC5->C5_ZZSITFI := "2"		
		ElseIf SC9->C9_BLCRED >= "01" .And. SC9->C9_BLCRED <= "06" .AND. SC9->C9_BLEST == "02" // 01- INDICA BLOQUEIO POR CREDITO E ESTOQUE
			SC5->C5_ZZSITFI := "3"	
		ElseIf Empty(SC9->C9_BLCRED) .And. Empty(SC9->C9_BLEST) // 01- INDICA LIBERADO CREDITO E ESTOQUE
			SC5->C5_ZZSITFI := '1'	
	EndIf

	MsUnlock()
*/
	

	//Add por Cyberpolos, tratativa para customização da integração BLU. 26/08/2020
	If Alltrim(SC5->C5_CONDPAG) $ Alltrim(Getmv("CP_BLUCOND")) .And. lUseBlu		

		If Getmv("CP_BLULBCR") .And. SC9->C9_BLCRED == "01"
			a450Grava(1,.T.,.F.)  //Realiza a Liberação de Credito Manual rotina padrao do sistema.
		Endif

		lLibPed := IIf(Alltrim(FunName()) $("MATA440"),.T.,.F.)  //| Liberação de pedido de venda
		
		If lLibPed
			cItem := GetSc6(SC9->C9_FILIAL,SC9->C9_PEDIDO)
		
			If Alltrim(SC5->C5_XNUMBLU) = "" .And.  SC9->C9_ITEM == cItem

				aRet := U_BLUPPED(SC9->C9_FILIAL,SC9->C9_PEDIDO)

				DbSelectArea("SC5")

				RecLock("SC5",.F.)
					SC5->C5_XLOGLIB := aRet[1][2]
				MsUnlock()	

				If aRet[1][1]
					U_BLUINT('1',SC9->C9_PEDIDO)
				EndIf

			EndIf
			
		EndIf
		
		DbSelectArea("SC9")
		
		RecLock("SC9",.F.)
			SC9->C9_XBLULIB := "N"		
		MsUnlock()	   

	EndIf	
	     
RestArea(AreaSC9) 
RestArea(AreaSC5)
RestArea(AreaATU)

Return ()    

/*/{Protheus.doc} GetSc6
Busca o ultimo item do pedido.
@type Static Function
@version 2.0
@author Cyberpolos
@since 26/08/2020
@param _cFil, character, filial
@param cPedido, character, numero do pedido
@return cItem, character, ultimo item do pedido
/*/
Static Function GetSc6(_cFil,cPedido)

	Local cAlias  := ""
	Local cItem   := ""
	Local cQuery  := ""
    
    cAlias  := GetNextAlias()
    
    cQuery+=" SELECT " 
    cQuery+=" MAX(C6_ITEM) AS ITEM" 
    cQuery+=" FROM" 
    cQuery+="	"+Retsqlname("SC6") + " A (NOLOCK)"
    cQuery+=" WHERE" 
    cQuery+="	A.D_E_L_E_T_ = ' ' " 
    cQuery+="	AND A.C6_FILIAL = '"+ _cFil + "'"
    cQuery+="	AND A.C6_NUM  = '"+  cPedido + "'"
        
    TCQuery cQuery NEW ALIAS (cAlias)

    (cAlias)->(DbGoTop())
	
	cItem := (cAlias)->ITEM	

    (cAlias)->(DbCloseArea())

Return cItem


