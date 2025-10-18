#include 'protheus.ch'
#include 'parmtype.ch'

/*---------------------------------------------------------------
{Protheus.doc} 	ACD100RE
TODO 			PE para substituir a impressão padrão por um 
				relatorio personalizado desenvolvido pelo cliente 
@author 		Carlos Eduardo Saturnino
@since 			29/10/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			User Function
----------------------------------------------------------------*/
user function ACD100RE()
	
	Local cRet	:= "U_ACDX100"
	//-----------------------------------------------
	// Realiza a chamamada do relatorio customizado
	//-----------------------------------------------
	U_ACDX100()
	
Return(cRet)