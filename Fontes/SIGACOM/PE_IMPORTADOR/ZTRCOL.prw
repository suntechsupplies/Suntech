#Include 'Protheus.ch'

User Function MT103FIM()

	Local aArea     := GetArea()
	Local aResultado := {}
	Local lAtivo    := SuperGetMV("MV_ZTREND", .F., .F.)
	Local bError    := Nil
	Local oError    := Nil
	Local cErro     := ""

	If ValType(lAtivo) != "L"
		RestArea(aArea)
		Return Nil
	EndIf
	If !lAtivo .Or. ValType(ParamIxb) != "A"
		RestArea(aArea)
		Return Nil
	EndIf
	If Len(ParamIxb) < 2
		RestArea(aArea)
		Return Nil
	EndIf
	If ParamIxb[1] != 3 .Or. ParamIxb[2] != 1 .Or. Select("SF1") == 0
		RestArea(aArea)
		Return Nil
	EndIf
	If AllTrim(xFilial("SF1")) != "03" .Or. SF1->(Eof()) .Or. SF1->(Deleted())
		RestArea(aArea)
		Return Nil
	EndIf
	If SF1->F1_FILIAL != xFilial("SF1") .Or. Empty(SF1->F1_DOC)
		RestArea(aArea)
		Return Nil
	EndIf
	ConOut("[ZTREND][MT103FIM] Inclusao confirmada ; doc=" + AllTrim(SF1->F1_DOC) + "/" + AllTrim(SF1->F1_SERIE))
	bError := ErrorBlock({|oErr| Break(oErr)})
	Begin Sequence
		aResultado := U_ZTREND(SF1->F1_DOC, SF1->F1_SERIE, SF1->F1_FORNECE, SF1->F1_LOJA, .T.)
		If !aResultado[1]
			cErro := aResultado[2]
		EndIf
	Recover Using oError
		If ValType(oError) == "O"
			cErro := cValToChar(oError:Description)
		Else
			cErro := cValToChar(oError)
		EndIf
	End Sequence
	ErrorBlock(bError)
	If !Empty(cErro)
		ConOut("[ZTREND][MT103FIM] Entrada fiscal mantida; conferir enderecamento: " + cErro)
	EndIf
	RestArea(aArea)

Return Nil

User Function COMCOL2()

	Local aArea    := GetArea()
	Local aAreaSA2 := SA2->(GetArea())
	Local aCabec   := {}
	Local aItens   := {}
	Local nPosFor  := 0
	Local nPosLoj  := 0
	Local cTesTrf  := ""
	Local lRet     := .F.

	If AllTrim(xFilial("SF1")) != "03" .Or. ValType(ParamIxb) != "A" .Or. Len(ParamIxb) < 2
		RestArea(aAreaSA2)
		RestArea(aArea)
		Return .F.
	EndIf

	aCabec := ParamIxb[1]
	If ValType(aCabec) != "A"
		RestArea(aAreaSA2)
		RestArea(aArea)
		Return .F.
	EndIf
	aItens := ParamIxb[2]
	If ValType(aItens) != "A" .Or. Len(aItens) == 0
		RestArea(aAreaSA2)
		RestArea(aArea)
		Return .F.
	EndIf

	nPosFor := AScan(aCabec, {|aCampo| AllTrim(aCampo[1]) == "F1_FORNECE"})
	nPosLoj := AScan(aCabec, {|aCampo| AllTrim(aCampo[1]) == "F1_LOJA"})
	If nPosFor == 0 .Or. nPosLoj == 0
		RestArea(aAreaSA2)
		RestArea(aArea)
		Return .F.
	EndIf

	DbSelectArea("SA2")
	DbSetOrder(1)
	If DbSeek(xFilial("SA2") + aCabec[nPosFor, 2] + aCabec[nPosLoj, 2])
		If !SA2->(Deleted()) .And. AllTrim(SA2->A2_FILTRF) == "02"
			cTesTrf := AllTrim(SuperGetMV("MV_ZTRTES", .F., ""))
			If !Empty(cTesTrf)
				lRet := .T.
				ConOut("[ZTRCOL][COMCOL2] Transferencia filial 03/02; TES=" + cTesTrf + ;
					"; itens=" + cValToChar(Len(aItens)))
			EndIf
		EndIf
	EndIf

	RestArea(aAreaSA2)
	RestArea(aArea)

Return lRet

User Function COMCOLF4()

	Local aArea    := GetArea()
	Local aAreaSA2 := SA2->(GetArea())
	Local cForn    := ""
	Local cLoja    := ""
	Local cProd    := ""
	Local cTes     := ""
	Local cTesTrf  := ""
	Local cMotivo  := ""

	If ValType(ParamIxb) != "A" .Or. Len(ParamIxb) < 4
		ConOut("[ZTRCOL][COMCOLF4] ParamIXB invalido; filial=" + AllTrim(xFilial("SF1")) + "; TES sem alteracao.")
		RestArea(aAreaSA2)
		RestArea(aArea)
		Return ""
	EndIf

	cForn := AllTrim(cValToChar(ParamIxb[1]))
	cLoja := AllTrim(cValToChar(ParamIxb[2]))
	cProd := AllTrim(cValToChar(ParamIxb[3]))
	cTes  := AllTrim(cValToChar(ParamIxb[4]))
	ConOut("[ZTRCOL][COMCOLF4] Entrada; filial=" + AllTrim(xFilial("SF1")) + "; fornecedor=" + cForn + "; loja=" + cLoja + ;
		"; produto=" + cProd + "; TES original=" + cTes)
	If Empty(cForn) .Or. Empty(cLoja) .Or. AllTrim(xFilial("SF1")) != "03"
		cMotivo := IIf(AllTrim(xFilial("SF1")) != "03", "filial diferente de 03", "fornecedor ou loja vazios")
		ConOut("[ZTRCOL][COMCOLF4] Retorno; motivo=" + cMotivo + "; TES=" + cTes)
		RestArea(aAreaSA2)
		RestArea(aArea)
		Return cTes
	EndIf

	DbSelectArea("SA2")
	DbSetOrder(1)
	If DbSeek(xFilial("SA2") + cForn + cLoja)
		If SA2->(Deleted())
			cMotivo := "fornecedor excluido"
		ElseIf AllTrim(SA2->A2_FILTRF) != "02"
			cMotivo := "A2_FILTRF diferente de 02: " + AllTrim(SA2->A2_FILTRF)
		Else
			cTesTrf := AllTrim(SuperGetMV("MV_ZTRTES", .F., ""))
			If Empty(cTesTrf)
				cMotivo := "MV_ZTRTES vazio"
			Else
				cTes := cTesTrf
			EndIf
		EndIf
	Else
		cMotivo := "fornecedor nao encontrado em SA2"
	EndIf
	ConOut("[ZTRCOL][COMCOLF4] Retorno; motivo=" + IIf(Empty(cMotivo), "transferencia elegivel", cMotivo) + ;
		"; TES=" + cTes)

	RestArea(aAreaSA2)
	RestArea(aArea)

Return cTes

User Function A140IGRV()

	Local aArea       := GetArea()
	Local aAreaSA2    := {}
	Local aAreaSDT    := {}
	Local cDoc        := ""
	Local cSerie      := ""
	Local cCod        := ""
	Local cLoja       := ""
	Local cCnpj       := ""
	Local cTesTrf     := ""
	Local cChave      := ""
	Local nAtualizados := 0
	Local nEncontrados := 0

	If ValType(ParamIxb) != "A" .Or. Len(ParamIxb) < 4
		ConOut("[ZTRCOL][A140IGRV] ParamIXB invalido; nenhuma TES atualizada.")
		RestArea(aArea)
		Return
	EndIf

	If AllTrim(xFilial("SDT")) != "03" .Or. Select("SA2") == 0 .Or. Select("SDT") == 0
		ConOut("[ZTRCOL][A140IGRV] Fora da filial 03 ou aliases SA2/SDT indisponiveis.")
		RestArea(aArea)
		Return
	EndIf

	cDoc    := AllTrim(cValToChar(ParamIxb[1]))
	cSerie  := AllTrim(cValToChar(ParamIxb[2]))
	cCod    := AllTrim(cValToChar(ParamIxb[3]))
	cLoja   := AllTrim(cValToChar(ParamIxb[4]))
	cTesTrf := AllTrim(SuperGetMV("MV_ZTRTES", .F., ""))

	If Empty(cDoc) .Or. Empty(cSerie) .Or. Empty(cCod) .Or. Empty(cLoja) .Or. Empty(cTesTrf)
		ConOut("[ZTRCOL][A140IGRV] Documento, fornecedor, loja, serie ou MV_ZTRTES vazio; doc=" + cDoc)
		RestArea(aArea)
		Return
	EndIf

	aAreaSA2 := SA2->(GetArea())
	aAreaSDT := SDT->(GetArea())
	DbSelectArea("SA2")
	DbSetOrder(1)
	If !DbSeek(xFilial("SA2") + PadR(cCod, TamSX3("A2_COD")[1]) + PadR(cLoja, TamSX3("A2_LOJA")[1]))
		ConOut("[ZTRCOL][A140IGRV] Fornecedor nao encontrado; doc=" + cDoc + "; fornecedor=" + cCod + "; loja=" + cLoja)
		RestArea(aAreaSDT)
		RestArea(aAreaSA2)
		RestArea(aArea)
		Return
	EndIf
	If SA2->(Deleted()) .Or. AllTrim(SA2->A2_FILTRF) != "02"
		ConOut("[ZTRCOL][A140IGRV] Fornecedor nao elegivel para transferencia 03/02; doc=" + cDoc)
		RestArea(aAreaSDT)
		RestArea(aAreaSA2)
		RestArea(aArea)
		Return
	EndIf
	cCnpj := SA2->A2_CGC

	DbSelectArea("SDT")
	DbSetOrder(1)
	cChave := xFilial("SDT") + PadR(cCnpj, TamSX3("DT_CNPJ")[1]) + ;
		PadR(cCod, TamSX3("DT_FORNEC")[1]) + PadR(cLoja, TamSX3("DT_LOJA")[1]) + ;
		PadR(cDoc, TamSX3("DT_DOC")[1]) + PadR(cSerie, TamSX3("DT_SERIE")[1])
	If SDT->(DbSeek(cChave))
		While !SDT->(Eof()) .And. SDT->DT_CNPJ == PadR(cCnpj, TamSX3("DT_CNPJ")[1]) .And. ;
			SDT->DT_FORNEC == PadR(cCod, TamSX3("DT_FORNEC")[1]) .And. ;
			SDT->DT_LOJA == PadR(cLoja, TamSX3("DT_LOJA")[1]) .And. ;
			SDT->DT_DOC == PadR(cDoc, TamSX3("DT_DOC")[1]) .And. ;
			SDT->DT_SERIE == PadR(cSerie, TamSX3("DT_SERIE")[1])
			If !SDT->(Deleted())
				nEncontrados++
				If AllTrim(SDT->DT_TES) != cTesTrf
					If RecLock("SDT", .F.)
						SDT->DT_TES := PadR(cTesTrf, TamSX3("DT_TES")[1])
						SDT->(MsUnlock())
						nAtualizados++
					Else
						ConOut("[ZTRCOL][A140IGRV] SDT ocupado; doc=" + cDoc + "; item=" + AllTrim(SDT->DT_ITEM))
					EndIf
				EndIf
			EndIf
			SDT->(DbSkip())
		EndDo
	EndIf

	ConOut("[ZTRCOL][A140IGRV] doc=" + cDoc + "/" + cSerie + "; encontrados=" + ;
		cValToChar(nEncontrados) + "; atualizados=" + cValToChar(nAtualizados) + "; TES=" + cTesTrf)
	RestArea(aAreaSDT)
	RestArea(aAreaSA2)
	RestArea(aArea)

Return
