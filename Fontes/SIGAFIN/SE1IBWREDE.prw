#include 'protheus.ch'
#include 'parmtype.ch'

/*-----------------------------------------------------------------------
{Protheus.doc} 	SE1IBWREDE
TODO 			Inicializador do Browser da SE1 para retornar o Nome da
				Rede dos Clientes
@author			Antonio Ricardo de Araujo
@since 			30/06/2023
@version 		1.0
@return 		${_cRet}
@type 			User Function
-----------------------------------------------------------------------*/
User Function SE1IBWREDE()

    Local aAreaSE1  := SE1->(GetArea())
    Local aArea     := GetArea()
	Local cCodRede  := Posicione("SA1",1,FWxFilial("SA1")+SE1->(E1_CLIENTE+E1_LOJA),"A1_ZZREDE")
	Local _cDesRede := Posicione("SX5",1,FWxFilial("SX5")+"Z9"+cCodRede,"X5_DESCRI")	        
	
	RestArea(aAreaSE1)
	RestArea(aArea)

Return (_cDesRede)

