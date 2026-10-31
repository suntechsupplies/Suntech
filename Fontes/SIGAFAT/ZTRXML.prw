#Include 'Protheus.ch'

User Function ZTRXML(cPedido, lDetalhe)

	Local aArea       := GetArea()
	Local aAreaSF2    := {}
	Local cAlias      := GetNextAlias()
	Local cQuery      := ""
	Local cDoc        := ""
	Local cSerie      := ""
	Local cNomeArq    := ""
	Local cDirIn      := AllTrim(SuperGetMV("MV_NGINN", .F., ""))
	Local cDirLidos   := AllTrim(SuperGetMV("MV_NGLIDOS", .F., ""))
	Local cIdEnt      := SuperGetMV("UF_ENTTSS", .F., "", "02")
	Local cRet        := ""
	Local cMsgFinal   := ""
	Local cMutex      := "ZTRXML_" + cEmpAnt + "_02"
	Local nPublicados := 0
	Local nIgnorados  := 0
	Local nFalhas     := 0
	Local aXml        := {}
	Local lMutex      := .F.
	Local lTinhaSF2   := Select("SF2") > 0
	Local bError      := Nil
	Local oError      := Nil

	Default lDetalhe := .F.

	If AllTrim(xFilial("SF2")) != "02"
		ConOut("[ZTRXML] Execute a rotina na filial 02; nenhum XML foi publicado.")
		ZTXAlerta("E", "Execute U_ZTRXML na filial 02. Nenhum XML foi publicado.")
		If lDetalhe
			Return {.F., "Execute U_ZTRXML na filial 02.", 0, 0, 0}
		EndIf
		Return 0
	EndIf

	If Empty(cDirIn) .Or. Empty(cDirLidos) .Or. Empty(cIdEnt)
		ConOut("[ZTRXML] Configure MV_NGINN, MV_NGLIDOS e UF_ENTTSS antes de executar.")
		ZTXAlerta("E", "Configure MV_NGINN, MV_NGLIDOS e UF_ENTTSS. Nenhum XML foi publicado.")
		If lDetalhe
			Return {.F., "Parametros do publicador XML incompletos.", 0, 0, 0}
		EndIf
		Return 0
	EndIf

	If !LockByName(cMutex, .T., .F.)
		ConOut("[ZTRXML] Outra execucao esta publicando XMLs; esta rodada foi ignorada.")
		ZTXAlerta("I", "Outra execucao de U_ZTRXML esta em andamento. Esta rodada foi ignorada.")
		If lDetalhe
			Return {.T., "Publicador ocupado; aguardar proxima rodada.", 0, 0, 0}
		EndIf
		Return 0
	EndIf
	lMutex := .T.
	If lTinhaSF2
		aAreaSF2 := SF2->(GetArea())
	EndIf
	bError := ErrorBlock({|oErr| Break(oErr)})
	Begin Sequence

	cDirIn    := ZTXDir(cDirIn)
	cDirLidos := ZTXDir(cDirLidos)

	cQuery := "SELECT DISTINCT F2.F2_DOC, F2.F2_SERIE " + ;
		"FROM " + RetSqlName("ZTR") + " ZTR " + ;
		"INNER JOIN " + RetSqlName("SC5") + " C5 ON C5.C5_FILIAL = ZTR.ZTR_FDEST " + ;
		"AND C5.C5_NUM = ZTR.ZTR_PEDTRF AND C5.D_E_L_E_T_ = ' ' " + ;
		"INNER JOIN " + RetSqlName("SD2") + " D2 ON D2.D2_FILIAL = C5.C5_FILIAL " + ;
		"AND D2.D2_PEDIDO = C5.C5_NUM AND D2.D2_CLIENTE = C5.C5_CLIENTE " + ;
		"AND D2.D2_LOJA = C5.C5_LOJACLI AND D2.D_E_L_E_T_ = ' ' " + ;
		"INNER JOIN " + RetSqlName("SF2") + " F2 ON F2.F2_FILIAL = D2.D2_FILIAL " + ;
		"AND F2.F2_DOC = D2.D2_DOC AND F2.F2_SERIE = D2.D2_SERIE " + ;
		"AND F2.F2_CLIENTE = D2.D2_CLIENTE AND F2.F2_LOJA = D2.D2_LOJA " + ;
		"AND F2.D_E_L_E_T_ = ' ' " + ;
		"INNER JOIN " + RetSqlName("SF3") + " F3 ON F3.F3_FILIAL = F2.F2_FILIAL " + ;
		"AND F3.F3_NFISCAL = F2.F2_DOC AND F3.F3_SERIE = F2.F2_SERIE " + ;
		"AND F3.F3_CLIEFOR = F2.F2_CLIENTE AND F3.F3_LOJA = F2.F2_LOJA " + ;
		"AND F3.F3_CODRSEF = '100' " + ;
		"AND F3.D_E_L_E_T_ = ' ' " + ;
		"WHERE ZTR.D_E_L_E_T_ = ' ' AND ZTR.ZTR_FILORI = '03' " + ;
		"AND ZTR.ZTR_FDEST = '02' AND ZTR.ZTR_STATUS = 'CRIADO' " + ;
		"AND ZTR.ZTR_PEDTRF <> '' " + ;
		"AND C5.C5_ZZNPEXT = 'ZR03' + ZTR.ZTR_PEDORI " + ;
		"AND C5.C5_TABELA = 'TTR' AND C5.C5_ZZORIGE = 'INT' " + ;
		"AND C5.C5_ZZTPPED = 'TR' " + ;
		"AND C5.C5_CLIENTE = 'S00003' AND C5.C5_LOJACLI = '01' " + ;
		"AND F2.F2_FILIAL = '02' AND F2.F2_CLIENTE = 'S00003' " + ;
		"AND F2.F2_LOJA = '01' AND D2.D2_PEDIDO = ZTR.ZTR_PEDTRF"
	If ValType(cPedido) == "C"
		cQuery += " AND ZTR.ZTR_PEDORI = '" + StrTran(AllTrim(cPedido), "'", "''") + "'"
	EndIf

	DbUseArea(.T., "TOPCONN", TcGenQry(,,ChangeQuery(cQuery)), cAlias, .F., .T.)
	While !(cAlias)->(Eof())
		cDoc      := AllTrim((cAlias)->F2_DOC)
		cSerie    := AllTrim((cAlias)->F2_SERIE)
		cNomeArq  := "arquivo_" + cSerie + cDoc + ".xml"

		If ZTXEntradaExiste(cDoc, cSerie) .Or. ;
		   File(cDirIn + cNomeArq) .Or. File(cDirLidos + cNomeArq)
			nIgnorados++
		Else
			If Select("SF2") <= 0
				ConOut("[ZTRXML] SF2 ausente; abrindo pelo dicionario; tabela=" + RetSqlName("SF2") + ;
					", filial=" + xFilial("SF2") + ", nota=" + cDoc + "/" + cSerie)
				ChkFile("SF2")
				ConOut("[ZTRXML] Select(SF2) apos abertura=" + cValToChar(Select("SF2")))
			EndIf
			If Select("SF2") <= 0
				nFalhas++
				cRet := "SF2 indisponivel apos ChkFile; GETXML nao executado para " + cDoc + "/" + cSerie
				ConOut("[ZTRXML] " + cRet)
				(cAlias)->(DbSkip())
				Loop
			EndIf

			ConOut("[ZTRXML] Chamando GETXML: doc=" + cDoc + ", serie=" + cSerie + ;
				", entidade=" + cIdEnt + ", destino=" + cDirIn + cNomeArq)
			aXml := U_GETXML(cDoc, cSerie, cDirIn, cIdEnt, .F.)
			If ValType(aXml) == "A" .And. Len(aXml) >= 2 .And. aXml[1]
				nPublicados++
				ConOut("[ZTRXML] XML publicado em IN: " + cDoc + "/" + cSerie)
			Else
				nFalhas++
				cRet := IIf(ValType(aXml) == "A" .And. Len(aXml) >= 2, cValToChar(aXml[2]), "Retorno invalido de GETXML.")
				ConOut("[ZTRXML] Falha ao publicar " + cDoc + "/" + cSerie + ": " + cRet)
			EndIf
		EndIf

		(cAlias)->(DbSkip())
	EndDo
	(cAlias)->(DbCloseArea())
	Recover Using oError
		nFalhas++
		If ValType(oError) == "O"
			cRet := cValToChar(oError:Description)
		ElseIf ValType(oError) == "C"
			cRet := oError
		Else
			cRet := "Publicacao XML interrompida sem descricao."
		EndIf
		ConOut("[ZTRXML] Falha: " + cRet)
	End Sequence
	ErrorBlock(bError)
	If Select(cAlias) > 0
		(cAlias)->(DbCloseArea())
	EndIf
	If Select("SF2") > 0
		If lTinhaSF2
			RestArea(aAreaSF2)
		Else
			SF2->(DbCloseArea())
		EndIf
	EndIf
	If lMutex
		UnLockByName(cMutex, .T., .F.)
	EndIf
	RestArea(aArea)

	cMsgFinal := "Publicados=" + cValToChar(nPublicados) + "; ignorados=" + ;
		cValToChar(nIgnorados) + "; falhas=" + cValToChar(nFalhas) + "."
	If nFalhas > 0 .And. !Empty(cRet)
		cMsgFinal += " Motivo: " + cRet
	EndIf
	ConOut("[ZTRXML] Concluido. " + cMsgFinal)

	If nFalhas > 0
		ZTXAlerta("E", "U_ZTRXML terminou com falhas. " + cMsgFinal + " Consulte o console do AppServer.")
	ElseIf nPublicados > 0
		ZTXAlerta("S", "XML publicado na pasta IN. Isso ainda nao confirma a leitura pelo Importador nem a entrada na filial 03. " + cMsgFinal)
	ElseIf nIgnorados > 0
		ZTXAlerta("I", "Nenhum XML novo foi publicado; os documentos encontrados ja existem na pasta ou na entrada. " + cMsgFinal)
	Else
		ZTXAlerta("I", "Nenhuma NF-e autorizada elegivel foi encontrada para o fluxo ZTR. " + cMsgFinal)
	EndIf
	If lDetalhe
		Return {nFalhas == 0, cMsgFinal, nPublicados, nIgnorados, nFalhas}
	EndIf

Return nPublicados

Static Function ZTXAlerta(cTipo, cMensagem)

	If IsBlind()
		Return Nil
	EndIf

	Do Case
	Case cTipo == "E"
		FWAlertError(cMensagem, "Transferencia ZTR - XML")
	Case cTipo == "S"
		FWAlertSuccess(cMensagem, "Transferencia ZTR - XML")
	Otherwise
		FWAlertInfo(cMensagem, "Transferencia ZTR - XML")
	EndCase

Return Nil

Static Function ZTXDir(cDiretorio)

	Local cRet := AllTrim(cDiretorio)

	If !Empty(cRet) .And. !(Right(cRet, 1) $ "\/")
		cRet += "\"
	EndIf

Return cRet

Static Function ZTXEntradaExiste(cDoc, cSerie)

	Local cAlias := GetNextAlias()
	Local cQuery := ""
	Local lExiste := .F.

	cQuery := "SELECT TOP 1 F1_DOC FROM " + RetSqlName("SF1") + ;
		" WHERE D_E_L_E_T_ = ' ' AND F1_FILIAL = '03' " + ;
		" AND F1_DOC = '" + StrTran(PadR(AllTrim(cDoc), TamSX3("F1_DOC")[1]), "'", "''") + "' " + ;
		" AND RTRIM(F1_SERIE) = '" + StrTran(AllTrim(cSerie), "'", "''") + "' " + ;
		" AND F1_FORNECE = 'F02283' AND F1_LOJA = '01'"

	DbUseArea(.T., "TOPCONN", TcGenQry(,,ChangeQuery(cQuery)), cAlias, .F., .T.)
	lExiste := !(cAlias)->(Eof())
	(cAlias)->(DbCloseArea())

Return lExiste
