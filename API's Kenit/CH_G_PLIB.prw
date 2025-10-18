#Include "Totvs.ch"

/*/{Protheus.doc} CH_G_PLIB
@author Ihorran Milholi
@since 17/05/2021
@version 1.0
/*/

/*
oPedido = JSON do Pedido
*/

User Function CH_G_PLIB(oPedido)

	Local aArea := GetArea()
	Local aErros := {}
	Local cDataLib := SubString(dtos(ddatabase),1,4)+'-'+SubString(dtos(ddatabase),5,2)+'-'+SubString(dtos(ddatabase),7,2)+'T00:00:00.000-03:00'

	If Valtype(oPedido['codigoErp']) == "C"

		SC5->(dbSetOrder(1))

		If SC5->(dbSeek(xFilial("SC5") + Padr(oPedido['codigoErp'], FWSX3Util():GetFieldStruct("C5_NUM")[3])))

			Reclock("SC5", .F.)
			SC5->C5_ZZSITFI := "2"
			SC5->(msUnLock())
			oPedido['dataLiberado'] := cDataLib

		EndIf

	EndIf

	RestArea(aArea)

Return {oPedido,aErros}
