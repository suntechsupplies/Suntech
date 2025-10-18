#include "protheus.ch"
#include "parmtype.ch"
/*----------------------------------------------------------------------------
{Protheus.doc} 	MyCRMA980
				PE para gravacao de Status do Cliente para API EjCli.prw
@param      	Nenhum
@return 		Nenhum
@author     	Carlos Eduardo Saturnino	
@version    	P12
@since      	21/07/2020
----------------------------------------------------------------------------*/
User Function CRMA980()

	Local aArea		:= GetArea()
	Local aParam 	:= PARAMIXB
	Local cIdPonto 	:= ""
	Local cIdModel 	:= ""
	Local lIsGrid 	:= .F.

	If aParam <> NIL

		cIdPonto 	:= aParam[2]
		cIdModel 	:= aParam[3]
		lIsGrid 	:= (Len(aParam) > 3)

		If cIdPonto == "MODELCOMMITTTS"
			
			Do Case

				Case aParam[1]["NOPERATION"] == 3		// Inclusao

					SA1->(Reclock("SA1", .F.))
						SA1->A1_ZSTATUS	:= "3" 			// Campo de Controle Ejecty
						SA1->A1_ZSTATU1	:= "3"			// Campo de Controle Acacias
					SA1->(MsUnlock())									
				
				Case aParam[1]["NOPERATION"] == 4		// Alteracao
				
					SA1->(Reclock("SA1", .F.))
						SA1->A1_ZSTATUS	:= "4" 			// Campo de Controle Ejecty
						SA1->A1_ZSTATU1	:= "4"			// Campo de Controle Acacias
					SA1->(MsUnlock())
				
				Case aParam[1]["NOPERATION"] == 5		// Exclusao
				
					SA1->(Reclock("SA1", .F.))
						SA1->A1_ZSTATUS	:= "5" 			// Campo de Controle Ejecty
						SA1->A1_ZSTATU1	:= "5"			// Campo de Controle Acacias
					SA1->(MsUnlock())

			End Case
			
		EndIf
	
	EndIf
	
	RestArea(aArea)

Return (.T.)
