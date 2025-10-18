#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} BLUMENU
MBrowse para exibição da tabela ZBL, onde consta as integrações realizadas na API BLU.
@type user function
@version 
@author Cyberpolos
@since 7/2/2020
/*/

User Function BLUMENU()

	Private aCores    := {}
	Private aRotina   := {}
	Private cCadastro := "Integrações PORTAL - BLU"

	aRotina := {{ "Pesquisa" 	     ,	"AxPesqui"					, 0 	, 1},;
				{ "Visualizar"       ,	"AxVisual"					, 0 	, 4},;
				{ "Libera Reenvio"   ,	"StaticCall(BLUMENU,zLib)"	, 0 	, 6},;
				{ "Legenda"		     ,	"StaticCall(BLUMENU,zLeg)"	, 0 	, 6}}

	aCores  := {{'ZBL->ZBL_INTEGR == " " .and. ZBL->ZBL_STATUS == " " ',"BR_BRANCO"},;
				{'ZBL->ZBL_INTEGR == "0" .and. ZBL->ZBL_STATUS $("0| ")',"BR_VERMELHO"},;
				{'ZBL->ZBL_INTEGR == "1" .and. ZBL->ZBL_STATUS == "1" ',"BR_AZUL"},;
				{'ZBL->ZBL_INTEGR == "7" .and. ZBL->ZBL_STATUS == "7" ',"BR_AZUL_CLARO"},;
				{'ZBL->ZBL_INTEGR == "2" .and. ZBL->ZBL_STATUS == "2" ',"BR_LARANJA"},;
				{'ZBL->ZBL_INTEGR == "3" .and. ZBL->ZBL_STATUS == "3" ',"BR_VERDE"},;				
				{'ZBL->ZBL_INTEGR == "3" .and. ZBL->ZBL_STATUS $("8| ") ',"BR_AMARELO"},;				
				{'ZBL->ZBL_INTEGR $ ("4|9") .and. ZBL->ZBL_STATUS $ ("4|9") ',"BR_PRETO"},;				
				{'ZBL->ZBL_INTEGR == "5" .and. ZBL->ZBL_STATUS == "5" ',"BR_CANCEL"}}

 	MBrowse(06,01,22,75,"ZBL",,,,,,aCores)		 			
	
Return

/*/{Protheus.doc} zLib
Limpa o campo ZBL_INTEGR do item com erro na integração, para que possa ser reenviado.
@type static function
@version 
@author Cyberpolos
@since 2/7/2020
/*/
Static Function zLib()

	Local cStatus := ""

	cStatus := ZBL->ZBL_INTEGR

	If cStatus == "0"

		 RecLock("ZBL",.F.)

		 	ZBL->ZBL_INTEGR := " "

		 ZBL->(MsunLock())
	
	Else

		MsgInfo("Somente itens com o campo Stat. Contr (ZBL_INTEGR) = 0, podem ser liberados para reenvio.","Atenção")

	EndIf

Return

/*/{Protheus.doc} zLeg
Legenda utilizada na mbrowse da rotina de integrações BLU
@type static function
@version 
@author Cyberpolos
@since 7/2/2020
@return return_type, return_description
/*/
Static Function zLeg()

	Local oLegenda := FWLegend():New() // Objeto FwLegend. 

	oLegenda:Add("","BR_BRANCO","Aguardando integração") 
	oLegenda:Add("","BR_VERMELHO","Erro na integração")  
	oLegenda:Add("","BR_AZUL","Aguardando Aprovação") 	
	oLegenda:Add("","BR_AZUL_CLARO","Em processamento") 
	oLegenda:Add("","BR_VERDE","Aprovada pelo Cliente")
	oLegenda:Add("","BR_AMARELO","Aprovado aguardando fatura") 
	oLegenda:Add("","BR_LARANJA","Aprovado aguardando o valor total.") 
	oLegenda:Add("","BR_PRETO","Devolvido/Cancelado")
	oLegenda:Add("","BR_CANCEL","Rejeitada pelo Cliente")	

	oLegenda:Activate() 
	oLegenda:View() 
	oLegenda:DeActivate() 

Return
