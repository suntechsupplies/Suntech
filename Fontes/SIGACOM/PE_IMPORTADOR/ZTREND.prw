#Include 'Protheus.ch'
#Include 'TopConn.ch'

User Function ZTRENSIM()

	Local aArea      := GetArea()
	Local aPerguntas := {}
	Local aResposta  := {}
	Local aResultado := {}
	Local cResumo    := ""
	Local nItem      := 0
	Local nEndereco  := 0
	Local aMovimento := {}

	If AllTrim(xFilial("SF1")) != "03"
		FWAlertInfo("Execute na filial 03.", "Simulacao de enderecamento")
		RestArea(aArea)
		Return
	EndIf
	aAdd(aPerguntas, {1, "Documento", Space(9), "@!", "", "", "", 80, .T.})
	aAdd(aPerguntas, {1, "Serie", Space(3), "@!", "", "", "", 40, .T.})
	aAdd(aPerguntas, {1, "Fornecedor", Space(6), "@!", "", "", "", 60, .T.})
	aAdd(aPerguntas, {1, "Loja", Space(2), "@!", "", "", "", 40, .T.})
	If !ParamBox(aPerguntas, "Simulacao de enderecamento", @aResposta)
		RestArea(aArea)
		Return
	EndIf
	If Len(aResposta) < 4
		RestArea(aArea)
		Return
	EndIf
	aResultado := U_ZTREND(AllTrim(aResposta[1]), AllTrim(aResposta[2]), ;
		AllTrim(aResposta[3]), AllTrim(aResposta[4]), .F.)
	If !aResultado[1]
		FWAlertError(aResultado[2], "Simulacao de enderecamento")
	Else
		For nItem := 1 To Len(aResultado[3])
			cResumo += "Item " + AllTrim(aResultado[3, nItem, 1]) + ;
				"; armazem " + AllTrim(aResultado[3, nItem, 3]) + ;
				"; saldo " + cValToChar(aResultado[3, nItem, 5]) + CRLF
			For nEndereco := 1 To Len(aResultado[3, nItem, 8])
				aMovimento := aResultado[3, nItem, 8, nEndereco]
				cResumo += "Endereco " + AllTrim(aMovimento[3, 2]) + ;
					"; quantidade " + cValToChar(aMovimento[5, 2]) + CRLF
			Next nEndereco
		Next nItem
		FWAlertInfo(cResumo + CRLF + "Simulacao concluida. Nenhum estoque foi movimentado.", ;
			"Simulacao de enderecamento")
	EndIf
	RestArea(aArea)

Return

User Function ZTREND(cDoc, cSerie, cFornec, cLoja, lEfetiva)

	Local aArea     := GetArea()
	Local aAreas    := {}
	Local aAliases  := {"SA2", "SF1", "SF2", "SD1", "SD2", "SDA", "SDB", "SBE", "SB1", "SB2", "SB8", "SBF", "SF4", "SX3"}
	Local nAlias    := 0
	Local aPlano    := {}
	Local cAlias    := GetNextAlias()
	Local cQuery    := ""
	Local cTes      := ""
	Local cErro     := ""
	Local aItem     := {}
	Local aRetorno  := {}
	Local bError    := Nil
	Local oError    := Nil

	If ValType(lEfetiva) != "L"
		lEfetiva := .F.
	EndIf
	ConOut("[ZTREND] Inicio; filial=" + AllTrim(xFilial("SF1")) + ;
		"; doc=" + cValToChar(cDoc) + "/" + cValToChar(cSerie) + ;
		"; efetivar=" + cValToChar(lEfetiva))
	If ValType(cDoc) != "C" .Or. ValType(cSerie) != "C" .Or. ;
		ValType(cFornec) != "C" .Or. ValType(cLoja) != "C"
		ConOut("[ZTREND] Recusado: informe documento, serie, fornecedor e loja como caracteres.")
		RestArea(aArea)
		Return {.F., "Informe documento, serie, fornecedor e loja.", aPlano}
	EndIf
	cTes := AllTrim(SuperGetMV("MV_ZTRTES", .F., ""))
	If AllTrim(xFilial("SF1")) != "03" .Or. Empty(cTes)
		ConOut("[ZTREND] Recusado: execute na filial 03 com MV_ZTRTES configurado; TES=" + cTes)
		RestArea(aArea)
		Return {.F., "Execute na filial 03 com MV_ZTRTES configurado.", aPlano}
	EndIf
	For nAlias := 1 To Len(aAliases)
		If Select(aAliases[nAlias]) > 0
			aAdd(aAreas, (aAliases[nAlias])->(GetArea()))
		EndIf
	Next nAlias
	cQuery := " SELECT D1.D1_ITEM, D1.D1_COD, D1.D1_LOCAL, D1.D1_NUMSEQ, D1.D1_QUANT, "
	cQuery += " D1.D1_DOC, D1.D1_SERIE, D1.D1_FORNECE, D1.D1_LOJA, D1.D1_LOTECTL, D1.D1_NUMLOTE, "
	cQuery += " F2.F2_DOC, F2.F2_SERIE "
	cQuery += " FROM " + RetSqlName("SD1") + " D1 "
	cQuery += " INNER JOIN " + RetSqlName("SF1") + " F1 ON F1.F1_FILIAL = D1.D1_FILIAL "
	cQuery += " AND F1.F1_DOC = D1.D1_DOC AND F1.F1_SERIE = D1.D1_SERIE "
	cQuery += " AND F1.F1_FORNECE = D1.D1_FORNECE AND F1.F1_LOJA = D1.D1_LOJA "
	cQuery += " AND F1.D_E_L_E_T_ = ' ' "
	cQuery += " INNER JOIN " + RetSqlName("SA2") + " A2 ON A2.A2_FILIAL = '" + xFilial("SA2") + "' "
	cQuery += " AND A2.A2_COD = F1.F1_FORNECE AND A2.A2_LOJA = F1.F1_LOJA "
	cQuery += " AND A2.A2_FILTRF = '02' AND A2.D_E_L_E_T_ = ' ' "
	cQuery += " INNER JOIN " + RetSqlName("SF2") + " F2 ON F2.F2_FILIAL = '02' "
	cQuery += " AND F2.F2_CHVNFE = F1.F1_CHVNFE AND F2.D_E_L_E_T_ = ' ' "
	cQuery += " AND F1.F1_CHVNFE <> ' ' "
	cQuery += " WHERE D1.D1_FILIAL = '" + xFilial("SD1") + "' "
	cQuery += " AND D1.D1_DOC = '" + StrTran(cDoc, "'", "''") + "' "
	cQuery += " AND D1.D1_SERIE = '" + StrTran(cSerie, "'", "''") + "' "
	cQuery += " AND D1.D1_FORNECE = '" + StrTran(cFornec, "'", "''") + "' "
	cQuery += " AND D1.D1_LOJA = '" + StrTran(cLoja, "'", "''") + "' "
	cQuery += " AND D1.D1_TES = '" + StrTran(cTes, "'", "''") + "' "
	cQuery += " AND D1.D_E_L_E_T_ = ' ' ORDER BY D1.D1_ITEM "
	bError := ErrorBlock({|oErr| Break(oErr)})
	Begin Sequence
		TCQuery ChangeQuery(cQuery) New Alias (cAlias)
		While !(cAlias)->(Eof())
			If AScan(aPlano, {|aLinha| aLinha[4] == (cAlias)->D1_NUMSEQ}) > 0
				Break("Sequencial de entrada ou chave fiscal ambiguos.")
			EndIf
			aItem := ZTEPlan(cAlias)
			If !aItem[1]
				Break("Item " + AllTrim((cAlias)->D1_ITEM) + ": " + aItem[2])
			EndIf
			aAdd(aPlano, aItem[3])
			(cAlias)->(DbSkip())
		EndDo
		(cAlias)->(DbCloseArea())
		If Empty(aPlano)
			Break("Entrada ativa de transferencia 02/03 nao encontrada pela chave fiscal e TES.")
		EndIf
		If lEfetiva
			aRetorno := ZTEExec(aPlano)
			If !aRetorno[1]
				cErro := aRetorno[2]
				If Empty(cErro)
					cErro := "Efetivacao recusada sem mensagem de erro."
				EndIf
			EndIf
		EndIf
	Recover Using oError
		If ValType(oError) == "O"
			cErro := cValToChar(oError:Description)
		ElseIf ValType(oError) == "C"
			cErro := oError
		EndIf
		If Empty(cErro)
			cErro := "Execucao interrompida sem descricao de erro."
		EndIf
	End Sequence
	ErrorBlock(bError)
	If Select(cAlias) > 0
		(cAlias)->(DbCloseArea())
	EndIf
	ConOut("[ZTREND] doc=" + AllTrim(cDoc) + "/" + AllTrim(cSerie) + ;
		"; efetivar=" + cValToChar(lEfetiva) + "; itens=" + cValToChar(Len(aPlano)) + ;
		"; resultado=" + IIf(Empty(cErro), "OK", cErro))
	For nAlias := Len(aAreas) To 1 Step -1
		RestArea(aAreas[nAlias])
	Next nAlias
	RestArea(aArea)

Return {Empty(cErro), cErro, aPlano}

Static Function ZTEPlan(cEntrada)

	Local cAlias    := GetNextAlias()
	Local cQuery    := ""
	Local cSeqSai   := ""
	Local cLocalSai := ""
	Local cErro     := ""
	Local nFontes   := 0
	Local nRecSDA   := 0
	Local nSaldo    := 0
	Local nTotal    := 0
	Local nSegunda  := 0
	Local nSegOrig  := 0
	Local aCab      := {}
	Local aItens    := {}
	Local aLinha    := {}
	Local aPlano    := {}
	Local bError    := ErrorBlock({|oErr| Break(oErr)})
	Local oError    := Nil

	Begin Sequence
		cQuery := " SELECT R_E_C_N_O_ AS RECNO, DA_SALDO, DA_QTDORI, DA_QTDORI2, DA_REGWMS "
		cQuery += " FROM " + RetSqlName("SDA") + " WHERE DA_FILIAL = " + ZTEQuote(xFilial("SDA"))
		cQuery += " AND DA_PRODUTO = " + ZTEQuote((cEntrada)->D1_COD)
		cQuery += " AND DA_LOCAL = " + ZTEQuote((cEntrada)->D1_LOCAL)
		cQuery += " AND DA_NUMSEQ = " + ZTEQuote((cEntrada)->D1_NUMSEQ)
		cQuery += " AND DA_DOC = " + ZTEQuote((cEntrada)->D1_DOC)
		cQuery += " AND DA_SERIE = " + ZTEQuote((cEntrada)->D1_SERIE)
		cQuery += " AND DA_CLIFOR = " + ZTEQuote((cEntrada)->D1_FORNECE)
		cQuery += " AND DA_LOJA = " + ZTEQuote((cEntrada)->D1_LOJA)
		cQuery += " AND DA_ORIGEM = 'SD1' AND D_E_L_E_T_ = ' ' "
		TCQuery ChangeQuery(cQuery) New Alias (cAlias)
		If (cAlias)->(Eof())
			Break("Saldo SDA da entrada nao encontrado.")
		EndIf
		nRecSDA  := (cAlias)->RECNO
		nSaldo   := (cAlias)->DA_SALDO
		nSegOrig := (cAlias)->DA_QTDORI2
		If !Empty((cAlias)->DA_REGWMS)
			Break("Entrada integrada ao WMS; enderecamento automatico nao suportado.")
		EndIf
		If Abs((cAlias)->DA_QTDORI - (cEntrada)->D1_QUANT) > 0.000001
			Break("Quantidade original da SDA diverge da SD1.")
		EndIf
		(cAlias)->(DbSkip())
		If !(cAlias)->(Eof())
			Break("Mais de um saldo SDA para o item.")
		EndIf
		(cAlias)->(DbCloseArea())
		If nSaldo < 0 .Or. (nSaldo > 0 .And. Abs(nSaldo - (cEntrada)->D1_QUANT) > 0.000001)
			Break("Distribuicao parcial existente; conferir manualmente.")
		EndIf
		If nSaldo > 0
			cQuery := " SELECT COUNT(*) AS QTD FROM " + RetSqlName("SDB")
			cQuery += " WHERE DB_FILIAL = " + ZTEQuote(xFilial("SDB"))
			cQuery += " AND DB_NUMSEQ = " + ZTEQuote((cEntrada)->D1_NUMSEQ)
			cQuery += " AND DB_PRODUTO = " + ZTEQuote((cEntrada)->D1_COD)
			cQuery += " AND DB_LOCAL = " + ZTEQuote((cEntrada)->D1_LOCAL)
			cQuery += " AND DB_ESTORNO = ' ' AND D_E_L_E_T_ = ' ' "
			TCQuery ChangeQuery(cQuery) New Alias (cAlias)
			If (cAlias)->QTD > 0
				Break("Movimento SDB existente com saldo SDA pendente; conferir manualmente.")
			EndIf
			(cAlias)->(DbCloseArea())
			cQuery := " SELECT D2_ITEM, D2_NUMSEQ, D2_LOCAL, D2_QUANT FROM " + RetSqlName("SD2")
			cQuery += " WHERE D2_FILIAL = '02' AND D2_DOC = " + ZTEQuote((cEntrada)->F2_DOC)
			cQuery += " AND D2_SERIE = " + ZTEQuote((cEntrada)->F2_SERIE)
			cQuery += " AND D2_COD = " + ZTEQuote((cEntrada)->D1_COD)
			cQuery += " AND D2_LOTECTL = " + ZTEQuote((cEntrada)->D1_LOTECTL)
			cQuery += " AND D2_NUMLOTE = " + ZTEQuote((cEntrada)->D1_NUMLOTE)
			cQuery += " AND D_E_L_E_T_ = ' ' "
			TCQuery ChangeQuery(cQuery) New Alias (cAlias)
			While !(cAlias)->(Eof())
				If Val((cAlias)->D2_ITEM) == Val((cEntrada)->D1_ITEM)
					nFontes++
					cSeqSai := (cAlias)->D2_NUMSEQ
					cLocalSai := (cAlias)->D2_LOCAL
					If Abs((cAlias)->D2_QUANT - nSaldo) > 0.000001
						Break("Quantidade da saida diverge da entrada.")
					EndIf
				EndIf
				(cAlias)->(DbSkip())
			EndDo
			(cAlias)->(DbCloseArea())
			If nFontes != 1 .Or. Empty(cSeqSai)
				Break("Item de saida nao encontrado ou ambiguo na filial 02.")
			EndIf
			cQuery := " SELECT DB.DB_LOCALIZ, DB.DB_QUANT, DB.DB_QTSEGUM, DB.DB_NUMSERI, DB.DB_REGWMS, "
			cQuery += " BE.R_E_C_N_O_ AS ENDREC FROM " + RetSqlName("SDB") + " DB "
			cQuery += " LEFT JOIN " + RetSqlName("SBE") + " BE ON BE.BE_FILIAL = " + ZTEQuote(xFilial("SBE"))
			cQuery += " AND BE.BE_LOCAL = " + ZTEQuote((cEntrada)->D1_LOCAL)
			cQuery += " AND BE.BE_LOCALIZ = DB.DB_LOCALIZ AND BE.D_E_L_E_T_ = ' ' "
			cQuery += " WHERE DB.DB_FILIAL = '02' AND DB.DB_NUMSEQ = " + ZTEQuote(cSeqSai)
			cQuery += " AND DB.DB_PRODUTO = " + ZTEQuote((cEntrada)->D1_COD)
			cQuery += " AND DB.DB_LOCAL = " + ZTEQuote(cLocalSai)
			cQuery += " AND DB.DB_DOC = " + ZTEQuote((cEntrada)->F2_DOC)
			cQuery += " AND DB.DB_SERIE = " + ZTEQuote((cEntrada)->F2_SERIE)
			cQuery += " AND DB.DB_LOTECTL = " + ZTEQuote((cEntrada)->D1_LOTECTL)
			cQuery += " AND DB.DB_NUMLOTE = " + ZTEQuote((cEntrada)->D1_NUMLOTE)
			cQuery += " AND DB.DB_ESTORNO = ' ' AND DB.D_E_L_E_T_ = ' ' ORDER BY DB.DB_ITEM "
			TCQuery ChangeQuery(cQuery) New Alias (cAlias)
			While !(cAlias)->(Eof())
				If Empty((cAlias)->DB_LOCALIZ) .Or. Empty((cAlias)->ENDREC)
					Break("Endereco da saida inexistente no armazem da filial 03.")
				EndIf
				If (cAlias)->DB_QUANT <= 0 .Or. !Empty((cAlias)->DB_REGWMS)
					Break("Movimento de saida invalido ou integrado ao WMS.")
				EndIf
				aLinha := {{"DB_ITEM", StrZero(Len(aItens) + 1, TamSX3("DB_ITEM")[1]), Nil}}
				aAdd(aLinha, {"DB_ESTORNO", " ", Nil})
				aAdd(aLinha, {"DB_LOCALIZ", (cAlias)->DB_LOCALIZ, Nil})
				aAdd(aLinha, {"DB_DATA", dDataBase, Nil})
				aAdd(aLinha, {"DB_QUANT", (cAlias)->DB_QUANT, Nil})
				aAdd(aLinha, {"DB_QTSEGUM", (cAlias)->DB_QTSEGUM, Nil})
				If !Empty((cAlias)->DB_NUMSERI)
					aAdd(aLinha, {"DB_NUMSERI", (cAlias)->DB_NUMSERI, Nil})
				EndIf
				aAdd(aItens, aLinha)
				nTotal += (cAlias)->DB_QUANT
				nSegunda += (cAlias)->DB_QTSEGUM
				ConOut("[ZTREND] item=" + AllTrim((cEntrada)->D1_ITEM) + ;
					"; origem=02/" + AllTrim(cLocalSai) + "; destino=03/" + AllTrim((cEntrada)->D1_LOCAL) + ;
					"; endereco=" + AllTrim((cAlias)->DB_LOCALIZ) + "; quantidade=" + cValToChar((cAlias)->DB_QUANT))
				(cAlias)->(DbSkip())
			EndDo
			(cAlias)->(DbCloseArea())
			If Empty(aItens) .Or. Abs(nTotal - nSaldo) > 0.000001 .Or. Abs(nSegunda - nSegOrig) > 0.000001
				Break("Quantidades por endereco da saida divergem do saldo da entrada.")
			EndIf
		Else
			ConOut("[ZTREND] item=" + AllTrim((cEntrada)->D1_ITEM) + "; sem saldo pendente; nenhuma movimentacao.")
		EndIf
		aCab := {{"DA_PRODUTO", (cEntrada)->D1_COD, Nil}}
		aAdd(aCab, {"DA_LOCAL", (cEntrada)->D1_LOCAL, Nil})
		aAdd(aCab, {"DA_NUMSEQ", (cEntrada)->D1_NUMSEQ, Nil})
		aAdd(aCab, {"DA_DOC", (cEntrada)->D1_DOC, Nil})
		aPlano := {(cEntrada)->D1_ITEM, (cEntrada)->D1_COD, (cEntrada)->D1_LOCAL, ;
			(cEntrada)->D1_NUMSEQ, nSaldo, nRecSDA, aCab, aItens}
	Recover Using oError
		If ValType(oError) == "O"
			cErro := cValToChar(oError:Description)
		ElseIf ValType(oError) == "C"
			cErro := oError
		EndIf
		If Empty(cErro)
			cErro := "Planejamento interrompido sem descricao de erro."
		EndIf
	End Sequence
	ErrorBlock(bError)
	If Select(cAlias) > 0
		(cAlias)->(DbCloseArea())
	EndIf

Return {Empty(cErro), cErro, aPlano}

Static Function ZTEExec(aPlano)

	Local aAreaSDA  := {}
	Local aLogs     := {}
	Local cErro     := ""
	Local nItem     := 0
	Local nLog      := 0
	Local nPendentes := 0
	Local nExecutados := 0
	Local nModuloAnt := nModulo
	Local lConcluiu := .F.
	Local lLocked   := .F.
	Local lAbriuSDA := .F.
	Local bError    := Nil
	Local oError    := Nil
	Private lMsErroAuto    := .F.
	Private lMsHelpAuto    := .T.
	Private lAutoErrNoFile := .T.
	Private lItIguais      := .F.
	Private aPrDup         := {}

	If Select("SDA") == 0
		ConOut("[ZTREND][EXEC] Abrindo alias SDA pelo dicionario.")
		ChkFile("SDA")
		lAbriuSDA := Select("SDA") > 0
	EndIf
	If Select("SDA") == 0
		ConOut("[ZTREND][EXEC] Alias SDA indisponivel; MATA265 nao executada.")
		Return {.F., "Alias SDA indisponivel para efetivar."}
	EndIf
	For nItem := 1 To Len(aPlano)
		If aPlano[nItem, 5] > 0
			nPendentes++
		EndIf
	Next nItem
	ConOut("[ZTREND][EXEC] Iniciando; pendentes=" + cValToChar(nPendentes) + ;
		"; transacao anterior=" + cValToChar(InTransact()) + "; modulo anterior=" + cValToChar(nModuloAnt))
	aAreaSDA := SDA->(GetArea())
	bError := ErrorBlock({|oErr| Break(oErr)})
	nModulo := 4
	Begin Transaction
		Begin Sequence
			ConOut("[ZTREND][EXEC] Bloco transacional iniciado.")
			For nItem := 1 To Len(aPlano)
				If aPlano[nItem, 5] == 0
					Loop
				EndIf
				SDA->(DbGoTo(aPlano[nItem, 6]))
				lLocked := RecLock("SDA", .F.)
				If !lLocked
					Break("Saldo SDA ocupado; nenhuma distribuicao confirmada.")
				EndIf
				If SDA->(Deleted()) .Or. SDA->DA_NUMSEQ != aPlano[nItem, 4] .Or. ;
					SDA->DA_PRODUTO != aPlano[nItem, 2] .Or. SDA->DA_LOCAL != aPlano[nItem, 3] .Or. ;
					Abs(SDA->DA_SALDO - aPlano[nItem, 5]) > 0.000001
					Break("Saldo SDA alterado apos a validacao; execute novamente.")
				EndIf
				lMsErroAuto := .F.
				ConOut("[ZTREND][MATA265] Iniciando; seq=" + AllTrim(aPlano[nItem, 4]) + ;
					"; saldo=" + cValToChar(aPlano[nItem, 5]) + ;
					"; enderecos=" + cValToChar(Len(aPlano[nItem, 8])))
				MSExecAuto({|aCab, aItens, nOpcao| MATA265(aCab, aItens, nOpcao)}, ;
					aPlano[nItem, 7], aPlano[nItem, 8], 3)
				ConOut("[ZTREND][MATA265] Retornou; erroauto=" + cValToChar(lMsErroAuto))
				If lMsErroAuto
					aLogs := GetAutoGRLog()
					For nLog := 1 To Len(aLogs)
						ConOut("[ZTREND][MATA265] " + cValToChar(aLogs[nLog]))
					Next nLog
					Break("MATA265 recusou o enderecamento; transacao desfeita.")
				EndIf
				SDA->(DbGoTo(aPlano[nItem, 6]))
				If Abs(SDA->DA_SALDO) > 0.000001
					Break("MATA265 nao consumiu todo o saldo SDA; transacao desfeita.")
				EndIf
				cErro := ZTEConf(aPlano[nItem])
				If !Empty(cErro)
					Break(cErro)
				EndIf
				SDA->(MsUnlock())
				lLocked := .F.
				nExecutados++
			Next nItem
			lConcluiu := .T.
		Recover Using oError
			If ValType(oError) == "O"
				cErro := cValToChar(oError:Description)
			ElseIf ValType(oError) == "C"
				cErro := oError
			EndIf
			If Empty(cErro)
				cErro := "Efetivacao interrompida sem descricao de erro."
			EndIf
			DisarmTransaction()
		End Sequence
	End Transaction
	nModulo := nModuloAnt
	ErrorBlock(bError)
	If lLocked
		SDA->(DbGoTo(aPlano[nItem, 6]))
		SDA->(MsUnlock())
	EndIf
	If Empty(cErro) .And. (!lConcluiu .Or. nExecutados != nPendentes)
		cErro := "Bloco transacional interrompido; MATA265 nao confirmou todos os itens."
	EndIf
	If Empty(cErro)
		For nItem := 1 To Len(aPlano)
			If aPlano[nItem, 5] > 0
				cErro := ZTEConf(aPlano[nItem])
				If !Empty(cErro)
					Exit
				EndIf
			EndIf
		Next nItem
	EndIf
	ConOut("[ZTREND][EXEC] Finalizado; executados=" + cValToChar(nExecutados) + ;
		"; pendentes=" + cValToChar(nPendentes) + "; resultado=" + IIf(Empty(cErro), "VALIDADO SDA/SDB", cErro))
	If lAbriuSDA
		SDA->(DbCloseArea())
	Else
		RestArea(aAreaSDA)
	EndIf

Return {Empty(cErro), cErro}

Static Function ZTEConf(aItem)

	Local aArea     := GetArea()
	Local cAlias    := GetNextAlias()
	Local cQuery    := ""
	Local cErro     := ""
	Local cEndereco := ""
	Local nLinha    := 0
	Local nQuant    := 0
	Local nSegunda  := 0
	Local nTotal    := 0
	Local bError    := ErrorBlock({|oErr| Break(oErr)})
	Local oError    := Nil

	Begin Sequence
		cQuery := " SELECT COALESCE(SUM(DA_SALDO), 0) AS SALDO FROM " + RetSqlName("SDA")
		cQuery += " WHERE DA_FILIAL = " + ZTEQuote(xFilial("SDA"))
		cQuery += " AND DA_PRODUTO = " + ZTEQuote(aItem[2])
		cQuery += " AND DA_LOCAL = " + ZTEQuote(aItem[3])
		cQuery += " AND DA_NUMSEQ = " + ZTEQuote(aItem[4])
		cQuery += " AND D_E_L_E_T_ = ' ' "
		TCQuery ChangeQuery(cQuery) New Alias (cAlias)
		If Abs((cAlias)->SALDO) > 0.000001
			Break("Confirmacao SQL: SDA ainda possui saldo pendente; seq=" + AllTrim(aItem[4]))
		EndIf
		(cAlias)->(DbCloseArea())
		cQuery := " SELECT DB_LOCALIZ, SUM(DB_QUANT) AS QUANT, SUM(DB_QTSEGUM) AS SEGUNDA "
		cQuery += " FROM " + RetSqlName("SDB") + " WHERE DB_FILIAL = " + ZTEQuote(xFilial("SDB"))
		cQuery += " AND DB_PRODUTO = " + ZTEQuote(aItem[2])
		cQuery += " AND DB_LOCAL = " + ZTEQuote(aItem[3])
		cQuery += " AND DB_NUMSEQ = " + ZTEQuote(aItem[4])
		cQuery += " AND DB_ESTORNO = ' ' AND D_E_L_E_T_ = ' ' GROUP BY DB_LOCALIZ "
		TCQuery ChangeQuery(cQuery) New Alias (cAlias)
		While !(cAlias)->(Eof())
			cEndereco := AllTrim((cAlias)->DB_LOCALIZ)
			nQuant := 0
			nSegunda := 0
			For nLinha := 1 To Len(aItem[8])
				If AllTrim(aItem[8, nLinha, 3, 2]) == cEndereco
					nQuant += aItem[8, nLinha, 5, 2]
					nSegunda += aItem[8, nLinha, 6, 2]
				EndIf
			Next nLinha
			If nQuant <= 0 .Or. Abs((cAlias)->QUANT - nQuant) > 0.000001 .Or. ;
				Abs((cAlias)->SEGUNDA - nSegunda) > 0.000001
				Break("Confirmacao SQL: SDB diverge do plano; endereco=" + cEndereco)
			EndIf
			nTotal += (cAlias)->QUANT
			(cAlias)->(DbSkip())
		EndDo
		(cAlias)->(DbCloseArea())
		If Abs(nTotal - aItem[5]) > 0.000001
			Break("Confirmacao SQL: quantidade SDB nao gravada integralmente; seq=" + AllTrim(aItem[4]))
		EndIf
		ConOut("[ZTREND][CONFIRMA] seq=" + AllTrim(aItem[4]) + ;
			"; SDA=0; quantidade SDB=" + cValToChar(nTotal))
	Recover Using oError
		If ValType(oError) == "O"
			cErro := cValToChar(oError:Description)
		ElseIf ValType(oError) == "C"
			cErro := oError
		EndIf
		If Empty(cErro)
			cErro := "Confirmacao SQL interrompida sem descricao de erro."
		EndIf
	End Sequence
	ErrorBlock(bError)
	If Select(cAlias) > 0
		(cAlias)->(DbCloseArea())
	EndIf
	RestArea(aArea)

Return cErro

Static Function ZTEQuote(cValor)

Return "'" + StrTran(cValor, "'", "''") + "'"
