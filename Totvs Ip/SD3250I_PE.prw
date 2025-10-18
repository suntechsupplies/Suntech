#include 'protheus.ch'
#include 'parmtype.ch'

user function SD3250I()

	local aArea := getArea()
	local xBkpMV01 := MV_PAR01
	local xBkpMV02 := MV_PAR02

	MV_PAR01 := SD3->D3_COD
	MV_PAR02 := SD3->D3_QUANT

	u_ImpProd(.T.)

	MV_PAR01 := xBkpMV01
	MV_PAR02 := xBkpMV02

	RestArea(aArea)

return