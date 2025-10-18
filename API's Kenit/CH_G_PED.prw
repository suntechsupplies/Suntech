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

	Local cTes 		:= ""
	Local cModal	:= ""
	Local nPosCli   := aScan(aCabec,{|x| Alltrim(x[1]) == "C5_CLIENTE"})
	Local nPosLoja  := aScan(aCabec,{|x| Alltrim(x[1]) == "C5_LOJACLI"})
	Local nPosTes	:= 0
	Local i

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

	If (Valtype(oPedido['parceiro']) == "J" .and. Valtype(oPedido['parceiro']['sysparceiro']) == "J" .and. Valtype(oPedido['parceiro']['sysparceiro']['tipo']) == 'C')
		If oPedido['parceiro']['sysparceiro']['tipo'] == 'shopify'
			aAdd(aCabec,{"C5_ZZTPPED",PADR("HB",FWSX3Util():GetFieldStruct("C5_ZZTPPED")[3]),NIL})
		elseIf oPedido['parceiro']['sysparceiro']['tipo'] == 'meli'
			aAdd(aCabec,{"C5_ZZTPPED",PADR("ML",FWSX3Util():GetFieldStruct("C5_ZZTPPED")[3]),NIL})
		endif		
	EndIf

	aAdd(aCabec,{"C5_ZZSITCO"   , PADR("1",FWSX3Util():GetFieldStruct("C5_ZZSITCO")[3]),NIL})
	aAdd(aCabec,{"C5_ZZORIGE"   , PADR("B2C",FWSX3Util():GetFieldStruct("C5_ZZORIGE")[3]),NIL})
	aAdd(aCabec,{"C5_ZZDTEMI"   , dDatabase,NIL})
	aAdd(aCabec,{"C5_NATUREZ"   , PADR("10116",FWSX3Util():GetFieldStruct("C5_NATUREZ")[3]),NIL})
	aAdd(aCabec,{"C5_TABELA"    , Padr("MKP",FWSX3Util():GetFieldStruct("C5_TABELA")[3]),Nil})

	//tratamento de TES
	If Valtype(oPedido['cupom']) == "C" .and. !Empty(oPedido['cupom'])

		SA1->(dbSetOrder(1))
		SA1->(dbSeek(xFilial("SA1")+aCabec[nPosCli][2]+aCabec[nPosLoja][2]))

		If SA1->A1_PESSOA == "F"

			If Substring(oPedido['cupom'],1,1) == "A"
				cTes := "5T3"
			EndIf


			If Substring(oPedido['cupom'],1,1) == "F"
				cTes := "6C5"
			EndIf

		EndIf
	
		If SA1->A1_PESSOA == "J"

			If Substring(oPedido['cupom'],1,1) == "A"
				cTes := "5S8"
			EndIf


			If Substring(oPedido['cupom'],1,1) == "F"

			EndIf

		EndIf

	EndIf

	If !Empty(cTes)
		For i := 1 to Len(aItens)
			aItens[i][aScan(aItens[i],{|x| Alltrim(x[1]) == "C6_TES"})][2] := cTes
		Next
	EndIf

	//tratametno frete
	If (Valtype(oPedido['entrega']) == "J" .And. Valtype(oPedido['entrega']['modalidade']) == "C")

		If "PAC" $ Upper(oPedido['entrega']['modalidade'])
			cModal := "PAC"
		EndIf
	
		If "SEDEX" $ Upper(oPedido['entrega']['modalidade'])
			cModal := "SEDEX"
		EndIf

	EndIf

	If !Empty(cModal)
		aAdd(aCabec,{"C5_ZZFENTR",PADR(Upper(cModal),FWSX3Util():GetFieldStruct("C5_ZZFENTR")[3]),NIL})
	EndIf

Return {aCabec,aItens,aErros}
