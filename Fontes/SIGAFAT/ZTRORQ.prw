#Include 'Protheus.ch'
#Include 'TopConn.ch'

User Function ZTRORQ(cEmpresa, cModelo, cSerie, lEfetiva, nLimite)

	Local aRetorno := {.F., "Job nao confirmou a execucao.", {}}
	Local bError   := ErrorBlock({|oErr| Break(oErr)})
	Local oError   := Nil

	If ValType(cEmpresa) != "C"
		If Type("cEmpAnt") == "C"
			cEmpresa := cEmpAnt
		Else
			ErrorBlock(bError)
			Return {.F., "Informe a empresa para executar pelo Schedule.", {}}
		EndIf
	EndIf
	If ValType(lEfetiva) != "L"
		lEfetiva := .F.
	EndIf
	If ValType(nLimite) != "N"
		nLimite := 20
	EndIf
	If Empty(AllTrim(cEmpresa)) .Or. nLimite < 1 .Or. nLimite > 100 .Or. nLimite != Int(nLimite)
		ErrorBlock(bError)
		Return {.F., "Empresa obrigatoria e limite inteiro entre 1 e 100.", {}}
	EndIf
	Begin Sequence
		aRetorno := StartJob("U_ZORUN", GetEnvServer(), .T., AllTrim(cEmpresa), cModelo, cSerie, lEfetiva, nLimite)
		If ValType(aRetorno) != "A"
			aRetorno := {.F., "Job sem retorno valido; conferir logs ZTRORQ.", {}}
		ElseIf Len(aRetorno) != 3
			aRetorno := {.F., "Job com retorno incompleto; conferir logs ZTRORQ.", {}}
		EndIf
	Recover Using oError
		aRetorno := {.F., ZORErr(oError), {}}
	End Sequence
	ErrorBlock(bError)
	ConOut("[ZTRORQ] " + aRetorno[2])

Return aRetorno

User Function ZORUN(cEmpresa, cModelo, cSerie, lEfetiva, nLimite)

	Local aFila      := {}
	Local aResultados := {}
	Local aEtapa     := {}
	Local cErro      := ""
	Local cMensagem  := ""
	Local cQuery     := ""
	Local cMutex     := "ZTRORQ_" + cEmpresa
	Local nPedido    := 0
	Local nFalhas    := 0
	Local nMaximo    := 0
	Local lAmbiente  := .F.
	Local lMutex     := .F.
	Local lTerminou  := .F.
	Local lFatura    := .F.
	Local xAtivo     := Nil
	Local bError     := ErrorBlock({|oErr| Break(oErr)})
	Local oError     := Nil

	Begin Sequence
		If Select("SX6") > 0
			Break("Execute pelo U_ZTRORQ, em job isolado.")
		EndIf
		RpcSetType(3)
		ZORCtx(cEmpresa, "03", @lAmbiente)
		xAtivo := SuperGetMV("MV_ZTRAUT", .F., .F.)
		If lEfetiva
			If ValType(xAtivo) != "L"
				Break("MV_ZTRAUT deve ser logico.")
			EndIf
			If !xAtivo
				Break("Efetivacao desabilitada: configure MV_ZTRAUT na filial 03.")
			EndIf
		EndIf
		If ValType(cModelo) != "C"
			cModelo := AllTrim(SuperGetMV("MV_ZTRMOD", .F., ""))
		EndIf
		If ValType(cSerie) != "C"
			cSerie := AllTrim(SuperGetMV("MV_ZTRSER", .F., ""))
		EndIf
		xAtivo := SuperGetMV("MV_ZTRFAT", .F., .F.)
		If ValType(xAtivo) == "L"
			lFatura := xAtivo
		EndIf
		nMaximo := SuperGetMV("MV_ZTRMAX", .F., 5)
		If ValType(nMaximo) != "N"
			Break("MV_ZTRMAX deve ser numerico.")
		EndIf
		If nMaximo < 1 .Or. nMaximo != Int(nMaximo)
			Break("MV_ZTRMAX deve ser inteiro positivo.")
		EndIf
		lMutex := LockByName(cMutex, .T., .F.)
		If !lMutex
			Break("Outra rodada do orquestrador esta em andamento.")
		EndIf
		cQuery := " SELECT TOP " + AllTrim(Str(nLimite)) + " ZTR_PEDORI FROM " + RetSqlName("ZTR")
		cQuery += " WHERE ZTR_FILORI = '03' AND ZTR_FDEST = '02' AND D_E_L_E_T_ = ' ' "
		cQuery += " AND ZTR_STATUS IN ('AG_PGTO','AG_LIB','PRONTO','CRIADO') "
		cQuery += " AND ZTR_MSGERR NOT LIKE 'ZOR:CONCLUIDO %' "
		cQuery += " AND ZTR_TENTAT < " + AllTrim(Str(nMaximo))
		cQuery += " ORDER BY ZTR_DTATU, ZTR_HRATU, R_E_C_N_O_ "
		aFila := ZORQuery(cQuery)
		For nPedido := 1 To Len(aFila)
			aEtapa := ZOROne(cEmpresa, AllTrim(aFila[nPedido, 1]), cModelo, cSerie, lEfetiva, lFatura, nMaximo)
			aAdd(aResultados, {AllTrim(aFila[nPedido, 1]), aEtapa[1], aEtapa[2], aEtapa[3]})
			If !aEtapa[1]
				nFalhas++
			EndIf
		Next nPedido
		lTerminou := .T.
	Recover Using oError
		cErro := ZORErr(oError)
	End Sequence
	If lMutex
		UnLockByName(cMutex, .T., .F.)
	EndIf
	If lAmbiente .And. Select("SX6") > 0
		RpcClearEnv()
	EndIf
	ErrorBlock(bError)
	If !lTerminou .And. Empty(cErro)
		cErro := "Rodada interrompida sem confirmacao."
	EndIf
	cMensagem := "efetivar=" + cValToChar(lEfetiva) + "; processados=" + cValToChar(Len(aResultados)) + ;
		"; falhas=" + cValToChar(nFalhas)
	If !Empty(cErro)
		cMensagem += "; " + cErro
	EndIf
	ConOut("[ZTRORQ] " + cMensagem)

Return {Empty(cErro) .And. nFalhas == 0, cMensagem, aResultados}

Static Function ZOROne(cEmpresa, cPedido, cModelo, cSerie, lEfetiva, lFatura, nMaximo)

	Local aRet      := {.F., "ERRO", "Etapa nao confirmou resultado."}
	Local aExec     := {}
	Local aNotas    := {}
	Local cMutex    := "ZTRORQ_" + cEmpresa + "_03_" + cPedido
	Local cChave    := ""
	Local cEspelho  := ""
	Local cStatus   := ""
	Local cEtapa    := "CONSULTA"
	Local lMutex    := .F.
	Local lAmbiente := .T.
	Local bError    := ErrorBlock({|oErr| Break(oErr)})
	Local oError    := Nil

	Begin Sequence
		ZORCtx(cEmpresa, "03", @lAmbiente)
		lMutex := LockByName(cMutex, .T., .F.)
		If !lMutex
			Break("Solicitacao ocupada por outra rodada.")
		EndIf
		cChave := PadR("03", TamSX3("ZTR_FILORI")[1]) + PadR(cPedido, TamSX3("ZTR_PEDORI")[1])
		ZTR->(DbSetOrder(1))
		If !ZTR->(DbSeek(cChave))
			Break("Solicitacao nao localizada.")
		EndIf
		If ZTR->(Deleted()) .Or. AllTrim(ZTR->ZTR_FDEST) != "02" .Or. ZTR->ZTR_TENTAT >= nMaximo
			Break("Solicitacao excluida, com destino divergente ou limite de tentativas atingido.")
		EndIf
		cStatus := AllTrim(ZTR->ZTR_STATUS)
		cEspelho := AllTrim(ZTR->ZTR_PEDTRF)
		If Empty(cEspelho)
			cEtapa := "CRIAR"
			aExec := U_ZTRVALID(lEfetiva, cPedido)
			If Empty(aExec)
				Break("Validacao nao confirmou solicitacao elegivel; recuperar CRIANDO/ERRO_REP manualmente.")
			EndIf
			If aExec[1, 2] != "PRONTO"
				aRet := {.T., aExec[1, 2], aExec[1, 3]}
			Else
				If Empty(AllTrim(cModelo))
					Break("Configure MV_ZTRMOD com o pedido modelo TTR da filial 02.")
				EndIf
				aExec := StartJob("U_ZTRJOB", GetEnvServer(), .T., cEmpresa, cPedido, AllTrim(cModelo), lEfetiva)
				If ValType(aExec) != "A"
					Break("Criacao sem retorno; conferir ZTR e identificador ZR03 antes de repetir.")
				EndIf
				If Len(aExec) != 4
					Break("Criacao com retorno incompleto.")
				EndIf
				aRet := {aExec[1], aExec[2], aExec[4]}
			EndIf
		Else
			If cStatus != "CRIADO"
				Break("Vinculo existente sem status CRIADO; conferir manualmente.")
			EndIf
			ZORCtx(cEmpresa, "02", @lAmbiente)
			ZOROpen({"SA1", "SA2", "SB1", "SB2", "SF4", "SE4", "SED", "SE1", "SF2", "SD2", "SF3"})
			aNotas := U_ZTRNFC(cPedido)
			If !aNotas[1]
				Break(aNotas[3])
			EndIf
			If aNotas[2] == "AG_FAT"
				cEtapa := "LIBERAR"
				aExec := U_ZTRLIB(cPedido, lEfetiva)
				If !aExec[1]
					Break(aExec[2])
				EndIf
				If !aExec[3]
					aRet := {.T., "AG_LIB02", aExec[2]}
				ElseIf !lFatura
					aRet := {.T., "AG_FAT", "Espelho liberado; faturamento automatico desabilitado em MV_ZTRFAT."}
				ElseIf lEfetiva
					aRet := {.T., "LIBERADO", "Liberacao conferida; faturamento sera avaliado na proxima rodada."}
					If Left(AllTrim(ZTR->ZTR_MSGERR), 13) == "ZOR:LIBERADO "
						cEtapa := "FATURAR"
						aExec := U_ZTRFAT(cPedido, cSerie, Date(), .T.)
						aRet := {aExec[1], "AG_NFE", aExec[2]}
					EndIf
				Else
					cEtapa := "FATURAR"
					aExec := U_ZTRFAT(cPedido, cSerie, Date(), .F.)
					aRet := {aExec[1], "AG_FAT", aExec[2]}
				EndIf
			Else
				cEtapa := "NOTA"
				aRet := ZORAfter(cEmpresa, cPedido, aNotas, lEfetiva, @lAmbiente)
			EndIf
		EndIf
	Recover Using oError
		aRet := {.F., "ERRO_" + cEtapa, ZORErr(oError)}
	End Sequence
	If lMutex
		Begin Sequence
			ZORCtx(cEmpresa, "03", @lAmbiente)
			If lEfetiva
				ZORSave(cPedido, aRet, cEtapa)
			EndIf
		Recover Using oError
			aRet := {.F., "ERRO_FILA", ZORErr(oError)}
		End Sequence
		UnLockByName(cMutex, .T., .F.)
	EndIf
	ErrorBlock(bError)
	ConOut("[ZTRORQ] pedido=03/" + cPedido + "; etapa=" + aRet[2] + "; " + aRet[3])

Return aRet

Static Function ZORAfter(cEmpresa, cPedido, aNota, lEfetiva, lAmbiente)

	Local aRows   := {}
	Local aExec   := {}
	Local aItem   := {}
	Local cQuery  := ""
	Local cDoc    := aNota[4]
	Local cSerie  := aNota[5]
	Local cNFe    := aNota[6]

	cQuery := " SELECT F3_NFISCAL FROM " + RetSqlName("SF3")
	cQuery += " WHERE F3_FILIAL = '02' AND F3_NFISCAL = " + ZORQuote(cDoc)
	cQuery += " AND F3_SERIE = " + ZORQuote(cSerie)
	cQuery += " AND F3_CLIEFOR = 'S00003' AND F3_LOJA = '01' "
	cQuery += " AND F3_CODRSEF = '100' AND F3_DTCANC = ' ' AND D_E_L_E_T_ = ' ' "
	aRows := ZORQuery(cQuery)
	If Empty(aRows) .Or. Len(cNFe) != 44
		Return {.T., "AG_NFE", "Aguardar autorizacao 100, chave valida e ausencia de cancelamento: " + cDoc + "/" + cSerie}
	EndIf
	ZORCtx(cEmpresa, "03", @lAmbiente)
	cQuery := " SELECT F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA FROM " + RetSqlName("SF1")
	cQuery += " WHERE F1_FILIAL = '03' AND F1_CHVNFE = " + ZORQuote(cNFe)
	cQuery += " AND F1_FORNECE = 'F02283' AND F1_LOJA = '01' AND D_E_L_E_T_ = ' ' "
	aRows := ZORQuery(cQuery)
	If Len(aRows) > 1
		Return {.F., "ERRO_ENTRADA", "Mais de uma entrada ativa para a chave fiscal."}
	EndIf
	If Empty(aRows)
		If !lEfetiva
			Return {.T., "AG_XML", "NF autorizada; publicaria XML e aguardaria Monitor/SCHEDCOMCOL."}
		EndIf
		ZORCtx(cEmpresa, "02", @lAmbiente)
		aExec := U_ZTRXML(cPedido, .T.)
		If !aExec[1]
			Return {.F., "ERRO_XML", aExec[2]}
		EndIf
		Return {.T., "AG_ENTRADA", "Publicador: " + aExec[2] + " Aguardar Monitor/SCHEDCOMCOL; XML nao comprova entrada."}
	EndIf
	aItem := aRows[1]
	ZOROpen({"SA2", "SF1", "SF2", "SD1", "SD2", "SB1", "SB2", "SB8", "SBF", "SDA", "SDB", "SBE", "SF4", "SX3"})
	If !ZORItems(cNFe, aItem[1], aItem[2], aItem[3], aItem[4])
		Return {.F., "ERRO_ENTRADA", "SD1 nao corresponde integralmente aos produtos/lotes/quantidades da saida."}
	EndIf
	aExec := U_ZTREND(aItem[1], aItem[2], aItem[3], aItem[4], .F.)
	If !aExec[1]
		Return {.F., "ERRO_ENDER", aExec[2]}
	EndIf
	If ZORProof(aExec[3], cNFe)
		Return {.T., "CONCLUIDO", "Entrada e enderecamento conferidos no banco: " + cDoc + "/" + cSerie}
	EndIf
	If !lEfetiva
		Return {.T., "AG_ENDER", "Simulacao: enderecaria entrada " + aItem[1] + "/" + aItem[2]}
	EndIf
	aExec := U_ZTREND(aItem[1], aItem[2], aItem[3], aItem[4], .T.)
	If !aExec[1]
		Return {.F., "ERRO_ENDER", aExec[2]}
	EndIf
	If !ZORProof(aExec[3], cNFe)
		Return {.F., "ERRO_ENDER", "Enderecamento nao confirmado no banco; nao marcar como concluido."}
	EndIf

Return {.T., "CONCLUIDO", "Entrada e enderecamento confirmados: " + cDoc + "/" + cSerie}

Static Function ZORItems(cNFe, cDoc, cSerie, cFornec, cLoja)

	Local cQuery := ""
	Local aSaida := {}
	Local aEntrada := {}
	Local nLinha := 0
	Local nPos := 0

	cQuery := " SELECT D1_ITEM FROM " + RetSqlName("SD1") + " WHERE D1_FILIAL = '03' "
	cQuery += " AND D1_DOC = " + ZORQuote(cDoc) + " AND D1_SERIE = " + ZORQuote(cSerie)
	cQuery += " AND D1_FORNECE = " + ZORQuote(cFornec) + " AND D1_LOJA = " + ZORQuote(cLoja)
	cQuery += " AND D1_TES <> " + ZORQuote(AllTrim(SuperGetMV("MV_ZTRTES", .F., "")))
	cQuery += " AND D_E_L_E_T_ = ' ' "
	aEntrada := ZORQuery(cQuery)
	If !Empty(aEntrada)
		Return .F.
	EndIf
	cQuery := " SELECT D2.D2_COD, D2.D2_LOTECTL, D2.D2_NUMLOTE, SUM(D2.D2_QUANT) AS QUANT "
	cQuery += " FROM " + RetSqlName("SD2") + " D2 INNER JOIN " + RetSqlName("SF2") + " F2 "
	cQuery += " ON F2.F2_FILIAL = D2.D2_FILIAL AND F2.F2_DOC = D2.D2_DOC AND F2.F2_SERIE = D2.D2_SERIE "
	cQuery += " AND F2.F2_CLIENTE = D2.D2_CLIENTE AND F2.F2_LOJA = D2.D2_LOJA AND F2.D_E_L_E_T_ = ' ' "
	cQuery += " WHERE D2.D2_FILIAL = '02' AND F2.F2_CHVNFE = " + ZORQuote(cNFe)
	cQuery += " AND D2.D_E_L_E_T_ = ' ' GROUP BY D2.D2_COD, D2.D2_LOTECTL, D2.D2_NUMLOTE "
	aSaida := ZORQuery(cQuery)
	cQuery := " SELECT D1_COD, D1_LOTECTL, D1_NUMLOTE, SUM(D1_QUANT) AS QUANT FROM " + RetSqlName("SD1")
	cQuery += " WHERE D1_FILIAL = '03' AND D1_DOC = " + ZORQuote(cDoc) + " AND D1_SERIE = " + ZORQuote(cSerie)
	cQuery += " AND D1_FORNECE = " + ZORQuote(cFornec) + " AND D1_LOJA = " + ZORQuote(cLoja)
	cQuery += " AND D_E_L_E_T_ = ' ' GROUP BY D1_COD, D1_LOTECTL, D1_NUMLOTE "
	aEntrada := ZORQuery(cQuery)
	If Empty(aSaida) .Or. Len(aSaida) != Len(aEntrada)
		Return .F.
	EndIf
	For nLinha := 1 To Len(aSaida)
		nPos := AScan(aEntrada, {|aLinha| aLinha[1] == aSaida[nLinha, 1] .And. ;
			aLinha[2] == aSaida[nLinha, 2] .And. aLinha[3] == aSaida[nLinha, 3]})
		If nPos == 0
			Return .F.
		EndIf
		If Abs(aEntrada[nPos, 4] - aSaida[nLinha, 4]) > 0.000001
			Return .F.
		EndIf
	Next nLinha

Return .T.

Static Function ZORProof(aPlano, cNFe)

	Local cQuery := ""
	Local aRows := {}
	Local aOrigem := {}
	Local aDestino := {}
	Local nItem := 0
	Local nPos := 0

	If Empty(aPlano)
		Return .F.
	EndIf
	For nItem := 1 To Len(aPlano)
		cQuery := " SELECT COALESCE(SUM(DA_SALDO),0) AS SALDO FROM " + RetSqlName("SDA")
		cQuery += " WHERE DA_FILIAL = '03' AND DA_PRODUTO = " + ZORQuote(aPlano[nItem, 2])
		cQuery += " AND DA_LOCAL = " + ZORQuote(aPlano[nItem, 3]) + " AND DA_NUMSEQ = " + ZORQuote(aPlano[nItem, 4])
		cQuery += " AND D_E_L_E_T_ = ' ' "
		aRows := ZORQuery(cQuery)
		If Abs(aRows[1, 1]) > 0.000001
			Return .F.
		EndIf
		cQuery := " SELECT COALESCE(SUM(DB_QUANT),0) AS QUANT FROM " + RetSqlName("SDB")
		cQuery += " WHERE DB_FILIAL = '03' AND DB_PRODUTO = " + ZORQuote(aPlano[nItem, 2])
		cQuery += " AND DB_LOCAL = " + ZORQuote(aPlano[nItem, 3]) + " AND DB_NUMSEQ = " + ZORQuote(aPlano[nItem, 4])
		cQuery += " AND DB_ESTORNO = ' ' AND D_E_L_E_T_ = ' ' "
		aRows := ZORQuery(cQuery)
		If Abs(aRows[1, 1] - ZORQty(aPlano[nItem, 4], aPlano[nItem, 2])) > 0.000001 .Or. aRows[1, 1] <= 0
			Return .F.
		EndIf
	Next nItem
	aOrigem := ZORAddr(cNFe, .T.)
	aDestino := ZORAddr(cNFe, .F.)
	If Empty(aOrigem) .Or. Len(aOrigem) != Len(aDestino)
		Return .F.
	EndIf
	For nItem := 1 To Len(aOrigem)
		nPos := AScan(aDestino, {|aLinha| aLinha[1] == aOrigem[nItem, 1] .And. ;
			aLinha[2] == aOrigem[nItem, 2] .And. aLinha[3] == aOrigem[nItem, 3] .And. ;
			aLinha[4] == aOrigem[nItem, 4]})
		If nPos == 0
			Return .F.
		EndIf
		If Abs(aDestino[nPos, 5] - aOrigem[nItem, 5]) > 0.000001 .Or. ;
			Abs(aDestino[nPos, 6] - aOrigem[nItem, 6]) > 0.000001
			Return .F.
		EndIf
	Next nItem

Return .T.

Static Function ZORAddr(cNFe, lSaida)

	Local cPrefixo := IIf(lSaida, "2", "1")
	Local cFilBanco := IIf(lSaida, "02", "03")
	Local cPessoa := IIf(lSaida, "CLIENTE", "FORNECE")
	Local cQuery := " SELECT DB.DB_PRODUTO, DB.DB_LOCALIZ, DB.DB_LOTECTL, DB.DB_NUMLOTE, "

	cQuery += " SUM(DB.DB_QUANT) AS QUANT, SUM(DB.DB_QTSEGUM) AS SEGUNDA "
	cQuery += " FROM " + RetSqlName("SDB") + " DB INNER JOIN " + RetSqlName("SD" + cPrefixo) + " D "
	cQuery += " ON D.D" + cPrefixo + "_FILIAL = DB.DB_FILIAL AND D.D" + cPrefixo + "_NUMSEQ = DB.DB_NUMSEQ "
	cQuery += " AND D.D" + cPrefixo + "_COD = DB.DB_PRODUTO AND D.D" + cPrefixo + "_LOCAL = DB.DB_LOCAL "
	cQuery += " AND D.D" + cPrefixo + "_LOTECTL = DB.DB_LOTECTL AND D.D" + cPrefixo + "_NUMLOTE = DB.DB_NUMLOTE "
	cQuery += " AND D.D_E_L_E_T_ = ' ' INNER JOIN " + RetSqlName("SF" + cPrefixo) + " F "
	cQuery += " ON F.F" + cPrefixo + "_FILIAL = D.D" + cPrefixo + "_FILIAL "
	cQuery += " AND F.F" + cPrefixo + "_DOC = D.D" + cPrefixo + "_DOC "
	cQuery += " AND F.F" + cPrefixo + "_SERIE = D.D" + cPrefixo + "_SERIE "
	cQuery += " AND F.F" + cPrefixo + "_" + cPessoa + " = D.D" + cPrefixo + "_" + cPessoa
	cQuery += " AND F.F" + cPrefixo + "_LOJA = D.D" + cPrefixo + "_LOJA AND F.D_E_L_E_T_ = ' ' "
	cQuery += " WHERE DB.DB_FILIAL = " + ZORQuote(cFilBanco) + " AND F.F" + cPrefixo + "_CHVNFE = " + ZORQuote(cNFe)
	If !lSaida
		cQuery += " AND F.F1_FORNECE = 'F02283' AND F.F1_LOJA = '01' "
	EndIf
	cQuery += " AND DB.DB_ESTORNO = ' ' AND DB.D_E_L_E_T_ = ' ' "
	cQuery += " GROUP BY DB.DB_PRODUTO, DB.DB_LOCALIZ, DB.DB_LOTECTL, DB.DB_NUMLOTE "

Return ZORQuery(cQuery)

Static Function ZORQty(cSequencia, cProduto)

	Local cQuery := " SELECT SUM(D1_QUANT) AS QUANT FROM " + RetSqlName("SD1")
	Local aRows := {}

	cQuery += " WHERE D1_FILIAL = '03' AND D1_NUMSEQ = " + ZORQuote(cSequencia)
	cQuery += " AND D1_COD = " + ZORQuote(cProduto) + " AND D_E_L_E_T_ = ' ' "
	aRows := ZORQuery(cQuery)

Return aRows[1, 1]

Static Function ZORSave(cPedido, aEtapa, cAcao)

	Local cChave := PadR("03", TamSX3("ZTR_FILORI")[1]) + PadR(cPedido, TamSX3("ZTR_PEDORI")[1])
	Local cMutex := "ZTR_" + cEmpAnt + "_03_" + cPedido

	ZTR->(DbSetOrder(1))
	If !ZTR->(DbSeek(cChave))
		Break("Solicitacao nao encontrada ao registrar acompanhamento.")
	EndIf
	If !LockByName(cMutex, .T., .F.)
		Break("Solicitacao em uso; acompanhamento nao gravado.")
	EndIf
	If !RecLock("ZTR", .F.)
		UnLockByName(cMutex, .T., .F.)
		Break("Fila ocupada ao registrar acompanhamento.")
	EndIf
	If ZTR->(Deleted()) .Or. AllTrim(ZTR->ZTR_FDEST) != "02"
		ZTR->(MsUnlock())
		UnLockByName(cMutex, .T., .F.)
		Break("Solicitacao excluida durante o processamento.")
	EndIf
	ZTR->ZTR_MSGERR := Left("ZOR:" + aEtapa[2] + " " + aEtapa[3], TamSX3("ZTR_MSGERR")[1])
	If !aEtapa[1] .And. cAcao != "CRIAR"
		ZTR->ZTR_TENTAT += 1
	EndIf
	ZTR->ZTR_DTATU := Date()
	ZTR->ZTR_HRATU := StrTran(Time(), ":", "")
	ZTR->(MsUnlock())
	UnLockByName(cMutex, .T., .F.)

Return Nil

Static Function ZORCtx(cEmpresa, cDestino, lAberto)

	Local lAtual := Select("SX6") > 0

	If lAtual
		If cEmpAnt == cEmpresa .And. AllTrim(cFilAnt) == cDestino
			ZOROpen({"ZTR", "SC5", "SC6", "SC9"})
			Return .T.
		EndIf
		RpcClearEnv()
	EndIf
	lAberto := .F.
	lAberto := RpcSetEnv(cEmpresa, cDestino)
	If !lAberto
		Break("Nao foi possivel abrir empresa/filial " + cEmpresa + "/" + cDestino)
	EndIf
	ZOROpen({"ZTR", "SC5", "SC6", "SC9"})

Return .T.

Static Function ZOROpen(aAliases)

	Local nAlias := 0

	For nAlias := 1 To Len(aAliases)
		If Select(aAliases[nAlias]) == 0
			ChkFile(aAliases[nAlias])
		EndIf
		If Select(aAliases[nAlias]) == 0
			Break("Alias indisponivel: " + aAliases[nAlias])
		EndIf
		(aAliases[nAlias])->(DbSetOrder(1))
	Next nAlias

Return Nil

Static Function ZORQuery(cQuery)

	Local aArea := GetArea()
	Local aRows := {}
	Local aRow := {}
	Local cAlias := GetNextAlias()
	Local nField := 0
	Local cErro := ""
	Local bError := ErrorBlock({|oErr| Break(oErr)})
	Local oError := Nil

	Begin Sequence
		TCQuery ChangeQuery(cQuery) New Alias (cAlias)
		While !(cAlias)->(Eof())
			aRow := {}
			For nField := 1 To (cAlias)->(FCount())
				aAdd(aRow, (cAlias)->(FieldGet(nField)))
			Next nField
			aAdd(aRows, aRow)
			(cAlias)->(DbSkip())
		EndDo
	Recover Using oError
		cErro := ZORErr(oError)
	End Sequence
	ErrorBlock(bError)
	If Select(cAlias) > 0
		(cAlias)->(DbCloseArea())
	EndIf
	RestArea(aArea)
	If !Empty(cErro)
		Break(cErro)
	EndIf

Return aRows

Static Function ZORErr(xErro)

	If ValType(xErro) == "O"
		Return cValToChar(xErro:Description)
	EndIf
	If ValType(xErro) == "C"
		If !Empty(xErro)
			Return xErro
		EndIf
	EndIf

Return "Execucao interrompida sem descricao."

Static Function ZORQuote(cValor)

Return "'" + StrTran(cValor, "'", "''") + "'"
