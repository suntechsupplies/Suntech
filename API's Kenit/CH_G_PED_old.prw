#Include "Totvs.ch"

/*/{Protheus.doc} CH_G_PED
@author Ihorran Milholi
@since 17/05/2021
@version 1.0
/*/

/*
aCabec = Vetor com cabeçalho do execauto
aItens = Vetor com item do execauto
aErros = Vetor para incluir erros de validação
*/

User Function CH_G_PED(oPedido,aCabec,aItens,aErros)

	If Alltrim(oPedido['status']) == "pago"

		aAdd(aCabec,{"C5_ZZSITFI",PADR("2", FWSX3Util():GetFieldStruct("C5_ZZSITFI")[3]),NIL})

	Else

		aAdd(aCabec,{"C5_ZZSITFI",PADR("3", FWSX3Util():GetFieldStruct("C5_ZZSITFI")[3]),NIL})

	EndIf

	If Valtype(oPedido['canal']) == "C"  
		if Alltrim(oPedido['canal']) == "SHOPIFY"
			aAdd(aCabec,{"C5_ZZTPPED",PADR("HB",FWSX3Util():GetFieldStruct("C5_ZZTPPED")[3]),NIL})
		elseif Alltrim(oPedido['canal']) == "MERCADO_LIVRE"
			aAdd(aCabec,{"C5_ZZTPPED",PADR("ML",FWSX3Util():GetFieldStruct("C5_ZZTPPED")[3]),NIL})
		endif
	EndIf

	aAdd(aCabec,{"C5_ZZSITCO"   , PADR("1",FWSX3Util():GetFieldStruct("C5_ZZSITCO")[3]),NIL})
	aAdd(aCabec,{"C5_ZZORIGE"   , PADR("B2C",FWSX3Util():GetFieldStruct("C5_ZZORIGE")[3]),NIL})
	aAdd(aCabec,{"C5_ZZDTEMI"   , dDatabase,NIL})
	aAdd(aCabec,{"C5_NATUREZ"   , PADR("10116",FWSX3Util():GetFieldStruct("C5_NATUREZ")[3]),NIL})
	aAdd(aCabec,{"C5_TABELA"    , Padr("MKP",FWSX3Util():GetFieldStruct("C5_TABELA")[3]),Nil})

Return {aCabec,aItens,aErros}
