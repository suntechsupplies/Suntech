#include 'protheus.ch'
#include 'parmtype.ch'

User Function FISVALNFE()

	Local aArea   := GetArea()
	Local aNota   := ParamIxb
	Local cAlias  := GetNextAlias()
	Local cQuery  := ""
	Local cPedido := ""
	Local cErro   := ""
	Local nCampo  := 0
	Local lEnvia  := .F.
	Local bError  := Nil
	Local oError  := Nil

	If AllTrim(cFilAnt) != "02"
		Return .T.
	EndIf
	If !IsInCallStack("AUTONFETRANS")
		Return .T.
	EndIf
	If ValType(aNota) != "A"
		Return .F.
	EndIf
	If Len(aNota) < 9
		Return .F.
	EndIf
	For nCampo := 1 To 7
		If nCampo != 3
			If ValType(aNota[nCampo]) != "C"
				Return .F.
			EndIf
		EndIf
	Next nCampo
	If AllTrim(aNota[1]) != "S" .Or. AllTrim(aNota[2]) != "02" .Or. ;
	   Empty(aNota[4]) .Or. Empty(aNota[5]) .Or. ;
	   AllTrim(aNota[6]) != "S00003" .Or. AllTrim(aNota[7]) != "01"
		Return .F.
	EndIf

	bError := ErrorBlock({|oErr| Break(oErr)})
	Begin Sequence
		cQuery := "SELECT D2.D2_PEDIDO, CASE WHEN EXISTS (SELECT 1 FROM " + RetSqlName("ZTR") + " ZTR " + ;
			"INNER JOIN " + RetSqlName("SC5") + " C5 ON C5.C5_FILIAL = ZTR.ZTR_FDEST " + ;
			"AND C5.C5_NUM = ZTR.ZTR_PEDTRF AND C5.D_E_L_E_T_ = ' ' " + ;
			"WHERE ZTR.D_E_L_E_T_ = ' ' AND ZTR.ZTR_FILORI = '03' AND ZTR.ZTR_FDEST = '02' " + ;
			"AND ZTR.ZTR_STATUS = 'CRIADO' AND ZTR.ZTR_PEDTRF = D2.D2_PEDIDO " + ;
			"AND C5.C5_CLIENTE = D2.D2_CLIENTE AND C5.C5_LOJACLI = D2.D2_LOJA " + ;
			"AND C5.C5_TABELA = 'TTR' AND C5.C5_ZZORIGE = 'INT' AND C5.C5_ZZTPPED = 'TR') " + ;
			"THEN 1 ELSE 0 END AS VINCULADO FROM " + RetSqlName("SD2") + " D2 " + ;
			"WHERE D2.D_E_L_E_T_ = ' ' AND D2.D2_FILIAL = '02' " + ;
			"AND D2.D2_DOC = '" + StrTran(aNota[4], "'", "''") + "' " + ;
			"AND D2.D2_SERIE = '" + StrTran(aNota[5], "'", "''") + "' " + ;
			"AND D2.D2_CLIENTE = 'S00003' AND D2.D2_LOJA = '01' " + ;
			"AND EXISTS (SELECT 1 FROM " + RetSqlName("SF2") + " F2 WHERE F2.D_E_L_E_T_ = ' ' " + ;
			"AND F2.F2_FILIAL = D2.D2_FILIAL AND F2.F2_DOC = D2.D2_DOC AND F2.F2_SERIE = D2.D2_SERIE " + ;
			"AND F2.F2_CLIENTE = D2.D2_CLIENTE AND F2.F2_LOJA = D2.D2_LOJA)"
		DbUseArea(.T., "TOPCONN", TcGenQry(,,ChangeQuery(cQuery)), cAlias, .F., .T.)
		lEnvia := !(cAlias)->(Eof())
		While !(cAlias)->(Eof())
			If Empty(cPedido)
				cPedido := AllTrim((cAlias)->D2_PEDIDO)
			EndIf
			If (cAlias)->VINCULADO != 1 .Or. Empty(cPedido) .Or. AllTrim((cAlias)->D2_PEDIDO) != cPedido
				lEnvia := .F.
				Exit
			EndIf
			(cAlias)->(DbSkip())
		EndDo
	Recover Using oError
		lEnvia := .F.
		If ValType(oError) == "O"
			cErro := cValToChar(oError:Description)
		Else
			cErro := cValToChar(oError)
		EndIf
		ConOut("[ZTR NF-e] Transmissao bloqueada por falha na verificacao: " + cErro)
	End Sequence
	If Select(cAlias) > 0
		(cAlias)->(DbCloseArea())
	EndIf
	RestArea(aArea)
	ErrorBlock(bError)
	ConOut("[ZTR NF-e] AutoNFe 02/" + AllTrim(aNota[4]) + "/" + AllTrim(aNota[5]) + ;
		" espelho=" + cPedido + " permitido=" + cValToChar(lEnvia))

Return lEnvia

User Function ZTRVALID(lGrava)

	Local aArea       := GetArea()
	Local aAreas      := {}
	Local aAliases    := {"SC5", "SC6", "SC9", "ZTR"}
	Local aPendentes  := {}
	Local aResultado  := {}
	Local aAvaliacao  := {}
	Local aStatus     := {"AG_PGTO", "AG_LIB", "PRONTO"}
	Local cOrigem     := ""
	Local cPedido     := ""
	Local cErro       := ""
	Local nAlias      := 0
	Local nPedido     := 0
	Local lLocked     := .F.
	Local bError      := Nil
	Local oError      := Nil

	Default lGrava := .F.

	If ValType(lGrava) != "L"
		ConOut("[ZTR] Informe .T. para atualizar a fila ou .F. para consultar.")
		Return aResultado
	EndIf
	If AllTrim(xFilial("SC5")) != "03"
		ConOut("[ZTR] Execute U_ZTRVALID na filial 03.")
		Return aResultado
	EndIf

	For nAlias := 1 To Len(aAliases)
		If Select(aAliases[nAlias]) > 0
			aAdd(aAreas, (aAliases[nAlias])->(GetArea()))
		EndIf
	Next nAlias

	bError := ErrorBlock({|oErr| Break(oErr)})
	Begin Sequence
		cOrigem := Upper(AllTrim(SuperGetMV("MV_PEDTRAN", .F., "")))
		If Empty(cOrigem)
			Break("Parametro MV_PEDTRAN nao configurado; fila nao processada.")
		EndIf

		For nAlias := 1 To Len(aAliases)
			DbSelectArea(aAliases[nAlias])
			DbSetOrder(1)
		Next nAlias

		ZTR->(DbGoTop())
		While !ZTR->(Eof())
			If !ZTR->(Deleted()) .And. AllTrim(ZTR->ZTR_FILORI) == "03" .And. ;
			   AllTrim(ZTR->ZTR_FDEST) == "02" .And. Empty(ZTR->ZTR_PEDTRF) .And. ;
			   AScan(aStatus, AllTrim(ZTR->ZTR_STATUS)) > 0
				aAdd(aPendentes, ZTR->(RecNo()))
			EndIf
			ZTR->(DbSkip())
		EndDo

		For nPedido := 1 To Len(aPendentes)
			DbSelectArea("ZTR")
			DbGoTo(aPendentes[nPedido])
			If lGrava
				lLocked := RecLock("ZTR", .F.)
				If !lLocked
					ConOut("[ZTR] Solicitacao ocupada: " + AllTrim(ZTR->ZTR_PEDORI))
					Loop
				EndIf
			EndIf

			If ZTR->(Deleted()) .Or. !Empty(ZTR->ZTR_PEDTRF) .Or. ;
			   AScan(aStatus, AllTrim(ZTR->ZTR_STATUS)) == 0
				If lLocked
					ZTR->(MsUnlock())
					lLocked := .F.
				EndIf
				Loop
			EndIf

			cPedido := AllTrim(ZTR->ZTR_PEDORI)
			aAvaliacao := ZTVCheck(cPedido, cOrigem)
			If lGrava
				ZTR->ZTR_STATUS := aAvaliacao[1]
				ZTR->ZTR_SITFIN := aAvaliacao[2]
				ZTR->ZTR_SITCOM := aAvaliacao[3]
				ZTR->ZTR_LIBOK  := aAvaliacao[4]
				ZTR->ZTR_MSGERR := Left(aAvaliacao[5], TamSX3("ZTR_MSGERR")[1])
				ZTR->ZTR_DTATU  := Date()
				ZTR->ZTR_HRATU  := StrTran(Time(), ":", "")
				ZTR->(MsUnlock())
				lLocked := .F.
			EndIf
			aAdd(aResultado, {cPedido, aAvaliacao[1], aAvaliacao[5]})
			ConOut("[ZTR] " + cPedido + " - " + aAvaliacao[1] + " - " + aAvaliacao[5])
		Next nPedido
	Recover Using oError
		If ValType(oError) == "O"
			cErro := cValToChar(oError:Description)
		Else
			cErro := cValToChar(oError)
		EndIf
	End Sequence
	ErrorBlock(bError)

	If lLocked
		ZTR->(MsUnlock())
	EndIf
	For nAlias := Len(aAreas) To 1 Step -1
		RestArea(aAreas[nAlias])
	Next nAlias
	RestArea(aArea)

	If !Empty(cErro)
		ConOut("[ZTR] Validacao interrompida: " + cErro)
	ElseIf lGrava
		ConOut("[ZTR] Validacao concluida; somente a fila ZTR foi atualizada.")
	Else
		ConOut("[ZTR] Simulacao concluida; nenhum registro foi alterado.")
	EndIf

Return aResultado

Static Function ZTVCheck(cPedido, cOrigem)

	Local aRetorno    := {"ERRO_MAN", "", "", "N", "Pedido de origem nao encontrado."}
	Local cChaveC6    := ""
	Local cChaveC9    := ""
	Local nPendente   := 0
	Local nLiberado   := 0
	Local nItens      := 0

	If !SC5->(DbSeek(xFilial("SC5") + PadR(cPedido, TamSX3("C5_NUM")[1])))
		Return aRetorno
	EndIf
	If SC5->(Deleted())
		Return aRetorno
	EndIf

	aRetorno[2] := AllTrim(SC5->C5_ZZSITFI)
	aRetorno[3] := AllTrim(SC5->C5_ZZSITCO)
	If AllTrim(SC5->C5_FILIAL) != "03" .Or. ;
	   Upper(AllTrim(SC5->C5_ZZORIGE)) != cOrigem .Or. ;
	   Upper(AllTrim(SC5->C5_TABELA)) != "MKP" .Or. Empty(SC5->C5_PEDECOM) .Or. ;
	   AllTrim(SC5->C5_PEDECOM) != AllTrim(ZTR->ZTR_PEDEXT) .Or. ;
	   AllTrim(SC5->C5_ZZNPEXT) != AllTrim(ZTR->ZTR_APIID)
		aRetorno[5] := "Origem ou identificadores do pedido divergem da solicitacao."
		Return aRetorno
	EndIf
	If !Empty(SC5->C5_NOTA)
		aRetorno[5] := "Pedido com nota fiscal; conferir manualmente antes de reabastecer."
		Return aRetorno
	EndIf
	If aRetorno[2] != "7"
		aRetorno[1] := "AG_PGTO"
		aRetorno[5] := "Aguardando pagamento integral (C5_ZZSITFI = 7)."
		Return aRetorno
	EndIf

	aRetorno[1] := "AG_LIB"
	If aRetorno[3] != "1"
		aRetorno[5] := "Aguardando aprovacao comercial (C5_ZZSITCO = 1)."
		Return aRetorno
	EndIf
	If Upper(AllTrim(SC5->C5_LIBEROK)) != "S"
		aRetorno[5] := "Aguardando liberacao do cabecalho (C5_LIBEROK = S)."
		Return aRetorno
	EndIf

	cChaveC6 := xFilial("SC6") + SC5->C5_NUM
	SC6->(DbSeek(cChaveC6))
	While !SC6->(Eof()) .And. SC6->(C6_FILIAL + C6_NUM) == cChaveC6
		If !SC6->(Deleted())
			nPendente := SC6->C6_QTDVEN - SC6->C6_QTDENT
			If nPendente > 0
				nItens += 1
				If !Empty(SC6->C6_BLQ)
					aRetorno[5] := "Item bloqueado na SC6: " + SC6->C6_ITEM
					Return aRetorno
				EndIf
				nLiberado := 0
				cChaveC9 := xFilial("SC9") + SC6->C6_NUM + SC6->C6_ITEM
				SC9->(DbSeek(cChaveC9))
				While !SC9->(Eof()) .And. SC9->(C9_FILIAL + C9_PEDIDO + C9_ITEM) == cChaveC9
					If !SC9->(Deleted()) .And. SC9->C9_PRODUTO == SC6->C6_PRODUTO .And. ;
					   Empty(SC9->C9_BLCRED) .And. Empty(SC9->C9_NFISCAL) .And. ;
					   (Empty(SC9->C9_BLEST) .Or. AllTrim(SC9->C9_BLEST) == "02")
						nLiberado += SC9->C9_QTDLIB
					EndIf
					SC9->(DbSkip())
				EndDo
				If nLiberado + 0.000001 < nPendente
					aRetorno[5] := "Liberacao insuficiente ou bloqueio impeditivo na SC9: item " + SC6->C6_ITEM
					Return aRetorno
				EndIf
			EndIf
		EndIf
		SC6->(DbSkip())
	EndDo

	If nItens == 0
		aRetorno[1] := "ERRO_MAN"
		aRetorno[5] := "Pedido sem itens pendentes; conferir manualmente."
		Return aRetorno
	EndIf

	aRetorno[1] := "PRONTO"
	aRetorno[4] := "S"
	aRetorno[5] := ""

Return aRetorno

User Function ZTRPROC()

	Local aPerguntas := {}
	Local aResposta  := {}
	Local cEmpresa   := cEmpAnt
	Local xResultado := Nil
	Local cModo      := ""
	Local cErroJob   := ""
	Local lEfetiva   := .F.
	Local bError     := Nil
	Local oError     := Nil

	If AllTrim(xFilial("SC5")) != "03"
		FWAlertInfo("Execute na filial 03.", "Reposicao Marketplace")
		Return
	EndIf
	aAdd(aPerguntas, {1, "Pedido origem (03)", Space(6), "@!", "", "", "", 60, .T.})
	aAdd(aPerguntas, {1, "Pedido modelo TTR (02)", Space(6), "@!", "", "", "", 60, .T.})
	aAdd(aPerguntas, {2, "Modo", 1, {"Simular", "Efetivar"}, 90, "", .T.})
	If !ParamBox(aPerguntas, "Reposicao Marketplace", @aResposta)
		Return
	EndIf
	If Len(aResposta) < 3
		FWAlertError("Parametros incompletos; nenhuma operacao iniciada.", "Reposicao Marketplace")
		Return
	EndIf
	If Empty(aResposta[1]) .Or. Empty(aResposta[2])
		FWAlertInfo("Informe os dois pedidos.", "Reposicao Marketplace")
		Return
	EndIf
	cModo := Upper(AllTrim(cValToChar(aResposta[3])))
	ConOut("[ZTR] Modo recebido: tipo=" + ValType(aResposta[3]) + ", valor=" + cModo)
	If AScan({"1", "SIMULAR", "2", "EFETIVAR"}, cModo) == 0
		FWAlertError("Modo nao reconhecido: " + cModo + ". Nenhuma operacao iniciada.", "Reposicao Marketplace")
		Return
	EndIf
	lEfetiva := AScan({"2", "EFETIVAR"}, cModo) > 0
	If lEfetiva
		If !FWAlertYesNo("Criar reposicao na filial 02 para o pedido " + AllTrim(aResposta[1]) + "?", "Confirmar reposicao")
			ConOut("[ZTR] Efetivacao cancelada na confirmacao: " + AllTrim(aResposta[1]))
			FWAlertInfo("Criacao cancelada na confirmacao. Nenhum job iniciado.", "Reposicao Marketplace")
			Return
		EndIf
	EndIf
	ConOut("[ZTR] Iniciando job: origem=03/" + AllTrim(aResposta[1]) + ", modelo=02/" + AllTrim(aResposta[2]) + ", efetivar=" + cValToChar(lEfetiva))
	bError := ErrorBlock({|oErr| Break(oErr)})
	Begin Sequence
		xResultado := StartJob("U_ZTRJOB", GetEnvServer(), .T., cEmpresa, AllTrim(aResposta[1]), AllTrim(aResposta[2]), lEfetiva)
	Recover Using oError
		If ValType(oError) == "O"
			cErroJob := cValToChar(oError:Description)
		Else
			cErroJob := cValToChar(oError)
		EndIf
	End Sequence
	ErrorBlock(bError)
	If !Empty(cErroJob)
		ConOut("[ZTR] Falha na chamada do job: " + cErroJob)
		FWAlertError("Falha na chamada do job: " + cErroJob + CRLF + "Confira a ZTR antes de repetir a efetivacao.", "Reposicao Marketplace")
		Return
	EndIf
	ConOut("[ZTR] Retorno do job: tipo=" + ValType(xResultado))
	If ValType(xResultado) != "A"
		FWAlertError("O job nao devolveu um resultado valido. Nao foi possivel confirmar a operacao. Confira a ZTR antes de repetir uma efetivacao.", "Reposicao Marketplace")
		Return
	EndIf
	If Len(xResultado) != 4
		FWAlertError("Retorno do job incompleto. Compile o fonte atualizado no mesmo ambiente e confira a ZTR antes de repetir uma efetivacao.", "Reposicao Marketplace")
		Return
	EndIf
	If ValType(xResultado[1]) != "L" .Or. ValType(xResultado[4]) != "C"
		FWAlertError("Formato de retorno do job invalido. Confira a ZTR antes de repetir uma efetivacao.", "Reposicao Marketplace")
		Return
	EndIf
	If xResultado[1]
		ConOut("[ZTR] " + xResultado[4])
		FWAlertSuccess(xResultado[4], "Reposicao Marketplace")
	Else
		ConOut("[ZTR] " + xResultado[4])
		FWAlertError(xResultado[4], "Reposicao Marketplace")
	EndIf

Return

User Function ZTRLIB()

	Local aArea      := GetArea()
	Local aAreas     := {}
	Local aAliases   := {"SC5", "SC6", "SC9", "SA1", "SB1", "SB2", "SF4", "ZTR"}
	Local aPerguntas := {}
	Local aResposta  := {}
	Local aItens     := {}
	Local cOrigem    := ""
	Local cEspelho   := ""
	Local cChave     := ""
	Local cMutex     := ""
	Local cModo      := ""
	Local cErro      := ""
	Local cSituacao  := ""
	Local nAlias     := 0
	Local nSC9       := 0
	Local lEfetiva   := .F.
	Local lMutex     := .F.
	Local lLocked    := .F.
	Local lExecutou  := .F.
	Local bError     := Nil
	Local oError     := Nil

	If AllTrim(cFilAnt) != "02" .Or. AllTrim(xFilial("SC5")) != "02"
		FWAlertError("Execute U_ZTRLIB na filial 02. Esta etapa nao cria pedidos.", "Liberar reposicao")
		Return
	EndIf
	aAdd(aPerguntas, {1, "Pedido origem (03)", Space(6), "@!", "", "", "", 60, .T.})
	aAdd(aPerguntas, {2, "Modo", 1, {"Consultar", "Liberar"}, 90, "", .T.})
	If !ParamBox(aPerguntas, "Liberar reposicao", @aResposta)
		Return
	EndIf
	cOrigem := AllTrim(aResposta[1])
	If Len(cOrigem) != 6 .Or. cOrigem != StrZero(Val(cOrigem), 6)
		FWAlertError("Informe o pedido de origem com seis digitos.", "Liberar reposicao")
		Return
	EndIf
	cModo := Upper(AllTrim(cValToChar(aResposta[2])))
	If AScan({"1", "CONSULTAR", "2", "LIBERAR"}, cModo) == 0
		FWAlertError("Modo nao reconhecido; nenhuma operacao iniciada.", "Liberar reposicao")
		Return
	EndIf
	lEfetiva := AScan({"2", "LIBERAR"}, cModo) > 0
	For nAlias := 1 To Len(aAliases)
		If Select(aAliases[nAlias]) > 0
			aAdd(aAreas, (aAliases[nAlias])->(GetArea()))
		EndIf
	Next nAlias
	cMutex := "ZTR_" + cEmpAnt + "_03_" + cOrigem
	bError := ErrorBlock({|oErr| Break(oErr)})
	Begin Sequence
		For nAlias := 1 To Len(aAliases)
			DbSelectArea(aAliases[nAlias])
			DbSetOrder(1)
		Next nAlias
		lMutex := LockByName(cMutex, .T., .F.)
		If !lMutex
			Break("Solicitacao em processamento por outra execucao.")
		EndIf
		cChave := PadR("03", TamSX3("ZTR_FILORI")[1]) + PadR(cOrigem, TamSX3("ZTR_PEDORI")[1])
		If !ZTR->(DbSeek(cChave))
			Break("Solicitacao nao encontrada na ZTR.")
		EndIf
		If ZTR->(Deleted()) .Or. AllTrim(ZTR->ZTR_STATUS) != "CRIADO" .Or. ;
		   AllTrim(ZTR->ZTR_FDEST) != "02" .Or. Empty(ZTR->ZTR_PEDTRF)
			Break("A solicitacao deve estar em CRIADO, com espelho vinculado na filial 02.")
		EndIf
		cEspelho := AllTrim(ZTR->ZTR_PEDTRF)
		If !SC5->(DbSeek(PadR("03", TamSX3("C5_FILIAL")[1]) + PadR(cOrigem, TamSX3("C5_NUM")[1])))
			Break("Pedido de origem nao encontrado na filial 03.")
		EndIf
		If SC5->(Deleted()) .Or. AllTrim(SC5->C5_ZZSITFI) != "7" .Or. ;
		   AllTrim(SC5->C5_ZZSITCO) != "1" .Or. !Empty(SC5->C5_NOTA)
			Break("Origem excluida, nao paga/aprovada ou ja faturada; conferir manualmente.")
		EndIf
		If AllTrim(SC5->C5_ZZNPEXT) != AllTrim(ZTR->ZTR_APIID) .Or. ;
		   AllTrim(SC5->C5_PEDECOM) != AllTrim(ZTR->ZTR_PEDEXT)
			Break("Identificadores da origem divergem da solicitacao.")
		EndIf
		SC6->(DbSeek(PadR("03", TamSX3("C6_FILIAL")[1]) + PadR(cOrigem, TamSX3("C6_NUM")[1])))
		While !SC6->(Eof()) .And. AllTrim(SC6->C6_FILIAL) == "03" .And. AllTrim(SC6->C6_NUM) == cOrigem
			If !SC6->(Deleted())
				aAdd(aItens, {SC6->C6_ITEM, SC6->C6_PRODUTO, SC6->C6_QTDVEN})
			EndIf
			SC6->(DbSkip())
		EndDo
		If !ZTRSaved(cEspelho, "ZR03" + cOrigem, aItens)
			Break("Cabecalho ou itens do espelho divergem da origem; liberacao nao iniciada.")
		EndIf
		If !Empty(SC5->C5_NOTA)
			Break("Espelho ja possui nota fiscal. Nenhuma liberacao iniciada.")
		EndIf
		cSituacao := ZTLCheck(cEspelho, @nSC9)
		If lEfetiva .And. !Empty(cSituacao)
			If nSC9 > 0
				Break(cSituacao + CRLF + "Ja existe SC9 parcial ou bloqueada. Reavalie pela rotina padrao; nao sera feito estorno automatico.")
			EndIf
			If !FWAlertYesNo("Solicitar liberacao do espelho 02/" + cEspelho + ", avaliando credito e estoque, sem faturar?", "Confirmar liberacao")
				Break("Liberacao cancelada. Nenhum registro alterado.")
			EndIf
			Begin Transaction
				Begin Sequence
					DbSelectArea("SC5")
					DbSetOrder(1)
					If !DbSeek(xFilial("SC5") + PadR(cEspelho, TamSX3("C5_NUM")[1]))
						Break("Espelho nao localizado antes da liberacao.")
					EndIf
					lLocked := RecLock("SC5", .F.)
					If !lLocked
						Break("Nao foi possivel bloquear o cabecalho do espelho.")
					EndIf
					If Deleted() .Or. !Empty(SC5->C5_NOTA)
						Break("Espelho excluido ou faturado durante a verificacao.")
					EndIf
					SC5->C5_LIBEROK := "S"
					SC5->(MsUnlock())
					lLocked := .F.
					SC6->(DbSeek(xFilial("SC6") + PadR(cEspelho, TamSX3("C6_NUM")[1])))
					While !SC6->(Eof()) .And. SC6->C6_FILIAL == xFilial("SC6") .And. AllTrim(SC6->C6_NUM) == cEspelho
						If !SC6->(Deleted())
							If SC6->C6_QTDENT != 0 .Or. !Empty(SC6->C6_BLQ) .Or. !Empty(SC6->C6_NOTA)
								Break("Item atendido, bloqueado ou faturado no espelho: " + SC6->C6_ITEM)
							EndIf
							MaLibDoFat(SC6->(RecNo()), SC6->C6_QTDVEN, , , .T., .T., .F., .F.)
						EndIf
						SC6->(DbSkip())
					EndDo
					cSituacao := ZTLCheck(cEspelho, @nSC9)
					If !Empty(cSituacao)
						Break(cSituacao)
					EndIf
					If !ZTRSaved(cEspelho, "ZR03" + cOrigem, aItens)
						Break("Espelho mudou durante a liberacao. Conferir cabecalho e itens.")
					EndIf
					lExecutou := .T.
				Recover Using oError
					If ValType(oError) == "O"
						cErro := cValToChar(oError:Description)
					Else
						cErro := cValToChar(oError)
					EndIf
					If Empty(cErro)
						cErro := "Liberacao interrompida sem descricao."
					EndIf
					DisarmTransaction()
					Break
				End Sequence
			End Transaction
		EndIf
	Recover Using oError
		If ValType(oError) == "O"
			cErro := cValToChar(oError:Description)
		Else
			cErro := cValToChar(oError)
		EndIf
		If Empty(cErro)
			cErro := "Verificacao da liberacao interrompida sem descricao."
		EndIf
	End Sequence
	If lLocked
		SC5->(MsUnlock())
	EndIf
	If lMutex
		UnLockByName(cMutex, .T., .F.)
	EndIf
	ErrorBlock(bError)
	For nAlias := Len(aAreas) To 1 Step -1
		RestArea(aAreas[nAlias])
	Next nAlias
	RestArea(aArea)
	If !Empty(cErro)
		FWAlertError(cErro + CRLF + "Nenhuma nota fiscal foi gerada. Confira o estado da liberacao antes de repetir.", "Liberar reposicao")
	ElseIf lExecutou
		FWAlertSuccess("Espelho 02/" + cEspelho + " liberado integralmente, com credito e estoque sem bloqueio na SC9. Nenhum faturamento executado.", "Liberar reposicao")
	ElseIf Empty(cSituacao)
		FWAlertInfo("Espelho 02/" + cEspelho + " ja esta integralmente liberado. Nenhum registro alterado.", "Liberar reposicao")
	Else
		FWAlertInfo("Espelho 02/" + cEspelho + ": " + cSituacao + CRLF + "Consulta concluida; nenhum registro alterado.", "Liberar reposicao")
	EndIf

Return

Static Function ZTLCheck(cPedido, nSC9)

	Local cErro      := ""
	Local cChave     := xFilial("SC6") + PadR(cPedido, TamSX3("C6_NUM")[1])
	Local cChaveC9   := ""
	Local nItens     := 0
	Local nLiberado  := 0

	nSC9 := 0
	If !SC5->(DbSeek(xFilial("SC5") + PadR(cPedido, TamSX3("C5_NUM")[1])))
		Return "Espelho nao encontrado."
	EndIf
	If SC5->(Deleted()) .Or. !Empty(SC5->C5_NOTA)
		Return "Espelho excluido ou ja faturado."
	EndIf
	If AllTrim(SC5->C5_LIBEROK) != "S"
		cErro := "Cabecalho ainda sem liberacao."
	EndIf
	SC6->(DbSeek(cChave))
	While !SC6->(Eof()) .And. SC6->(C6_FILIAL + C6_NUM) == cChave
		If !SC6->(Deleted())
			nItens += 1
			If SC6->C6_QTDENT != 0 .Or. !Empty(SC6->C6_BLQ) .Or. !Empty(SC6->C6_NOTA)
				cErro := "Item atendido, bloqueado ou faturado: " + SC6->C6_ITEM
			EndIf
			nLiberado := 0
			cChaveC9 := xFilial("SC9") + SC6->C6_NUM + SC6->C6_ITEM
			SC9->(DbSeek(cChaveC9))
			While !SC9->(Eof()) .And. SC9->(C9_FILIAL + C9_PEDIDO + C9_ITEM) == cChaveC9
				If !SC9->(Deleted())
					nSC9 += 1
					If SC9->C9_PRODUTO == SC6->C6_PRODUTO .And. Empty(SC9->C9_BLCRED) .And. ;
					   Empty(SC9->C9_BLEST) .And. Empty(SC9->C9_NFISCAL)
						nLiberado += SC9->C9_QTDLIB
					Else
						cErro := "SC9 com bloqueio ou nota no item " + SC6->C6_ITEM + ;
							": credito=" + AllTrim(SC9->C9_BLCRED) + ", estoque=" + AllTrim(SC9->C9_BLEST)
					EndIf
				EndIf
				SC9->(DbSkip())
			EndDo
			If nLiberado + 0.000001 < SC6->C6_QTDVEN .And. Empty(cErro)
				cErro := "Quantidade nao liberada integralmente na SC9: item " + SC6->C6_ITEM
			EndIf
		EndIf
		SC6->(DbSkip())
	EndDo
	If nItens == 0
		cErro := "Espelho sem itens."
	EndIf

Return cErro

User Function ZTRFAT()

	Local aArea      := GetArea()
	Local aAreas     := {}
	Local aAliases   := {"SC5", "SC6", "SC9", "SA1", "SA2", "SB1", "SB2", "SF4", "SE4", "SED", "SE1", "SF2", "SD2", "ZTR"}
	Local aPerguntas := {}
	Local aResposta  := {}
	Local aItens     := {}
	Local aPvl       := {}
	Local aDocs      := {}
	Local aLocksC9   := {}
	Local cOrigem    := ""
	Local cEspelho   := ""
	Local cSerie     := ""
	Local cDoc       := ""
	Local cChave     := ""
	Local cMutex     := ""
	Local cModo      := ""
	Local cErro      := ""
	Local cSituacao  := ""
	Local cFuncao    := FunName()
	Local dEntrega   := Date()
	Local nAlias     := 0
	Local nSC9       := 0
	Local nLinha     := 0
	Local lEfetiva   := .F.
	Local lMutex     := .F.
	Local lLockC5    := .F.
	Local lExecutou  := .F.
	Local bError     := Nil
	Local oError     := Nil

	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.
	Private lAutoErrNoFile := .T.

	If AllTrim(cFilAnt) != "02" .Or. AllTrim(xFilial("SC5")) != "02"
		FWAlertError("Execute U_ZTRFAT na filial 02.", "Documento de saida da reposicao")
		Return
	EndIf
	aAdd(aPerguntas, {1, "Pedido origem (03)", Space(6), "@!", "", "", "", 60, .T.})
	aAdd(aPerguntas, {1, "Serie da nota (02)", Space(TamSX3("F2_SERIE")[1]), "@!", "", "", "", 60, .T.})
	aAdd(aPerguntas, {1, "Data prevista entrega", Date(), "", "", "", "", 70, .T.})
	aAdd(aPerguntas, {2, "Modo", 1, {"Conferir", "Faturar"}, 90, "", .T.})
	If !ParamBox(aPerguntas, "Documento de saida da reposicao", @aResposta)
		Return
	EndIf
	cOrigem := AllTrim(aResposta[1])
	cSerie := Upper(AllTrim(aResposta[2]))
	dEntrega := aResposta[3]
	cModo := Upper(AllTrim(cValToChar(aResposta[4])))
	If Len(cOrigem) != 6 .Or. cOrigem != StrZero(Val(cOrigem), 6) .Or. Empty(cSerie)
		FWAlertError("Informe a origem com seis digitos e a serie fiscal aprovada para a filial 02.", "Documento de saida da reposicao")
		Return
	EndIf
	If ValType(dEntrega) != "D"
		FWAlertError("Data prevista de entrega invalida.", "Documento de saida da reposicao")
		Return
	EndIf
	If Empty(dEntrega) .Or. AScan({"1", "CONFERIR", "2", "FATURAR"}, cModo) == 0
		FWAlertError("Informe uma data de entrega e um modo valido.", "Documento de saida da reposicao")
		Return
	EndIf
	lEfetiva := AScan({"2", "FATURAR"}, cModo) > 0
	If lEfetiva .And. !("TEST" $ Upper(GetEnvServer())) .And. !("HOMOLOG" $ Upper(GetEnvServer()))
		FWAlertError("A emissao desta etapa esta restrita a ambiente de teste/homologacao.", "Documento de saida da reposicao")
		Return
	EndIf
	For nAlias := 1 To Len(aAliases)
		If Select(aAliases[nAlias]) > 0
			aAdd(aAreas, (aAliases[nAlias])->(GetArea()))
		EndIf
	Next nAlias
	cMutex := "ZTR_" + cEmpAnt + "_03_" + cOrigem
	bError := ErrorBlock({|oErr| Break(oErr)})
	Begin Sequence
		For nAlias := 1 To Len(aAliases)
			DbSelectArea(aAliases[nAlias])
			DbSetOrder(1)
		Next nAlias
		lMutex := LockByName(cMutex, .T., .F.)
		If !lMutex
			Break("Solicitacao em processamento por outra execucao.")
		EndIf
		cChave := PadR("03", TamSX3("ZTR_FILORI")[1]) + PadR(cOrigem, TamSX3("ZTR_PEDORI")[1])
		If !ZTR->(DbSeek(cChave))
			Break("Solicitacao nao encontrada na ZTR.")
		EndIf
		If ZTR->(Deleted()) .Or. AllTrim(ZTR->ZTR_STATUS) != "CRIADO" .Or. ;
		   AllTrim(ZTR->ZTR_FDEST) != "02" .Or. Empty(ZTR->ZTR_PEDTRF)
			Break("Solicitacao sem espelho confirmado na filial 02.")
		EndIf
		cEspelho := AllTrim(ZTR->ZTR_PEDTRF)
		If !SC5->(DbSeek(PadR("03", TamSX3("C5_FILIAL")[1]) + PadR(cOrigem, TamSX3("C5_NUM")[1])))
			Break("Pedido de origem nao encontrado.")
		EndIf
		If SC5->(Deleted()) .Or. AllTrim(SC5->C5_ZZSITFI) != "7" .Or. ;
		   AllTrim(SC5->C5_ZZSITCO) != "1" .Or. !Empty(SC5->C5_NOTA)
			Break("Origem excluida, nao paga/aprovada ou ja faturada.")
		EndIf
		If AllTrim(SC5->C5_ZZNPEXT) != AllTrim(ZTR->ZTR_APIID) .Or. ;
		   AllTrim(SC5->C5_PEDECOM) != AllTrim(ZTR->ZTR_PEDEXT)
			Break("Identificadores da origem divergem da ZTR.")
		EndIf
		SC6->(DbSeek(PadR("03", TamSX3("C6_FILIAL")[1]) + PadR(cOrigem, TamSX3("C6_NUM")[1])))
		While !SC6->(Eof()) .And. AllTrim(SC6->C6_FILIAL) == "03" .And. AllTrim(SC6->C6_NUM) == cOrigem
			If !SC6->(Deleted())
				aAdd(aItens, {SC6->C6_ITEM, SC6->C6_PRODUTO, SC6->C6_QTDVEN})
			EndIf
			SC6->(DbSkip())
		EndDo
		If !ZTRSaved(cEspelho, "ZR03" + cOrigem, aItens)
			Break("Espelho divergente da origem. Nenhum documento gerado.")
		EndIf
		aDocs := ZTFDocs(cEspelho)
		If Len(aDocs) > 0
			Break("Ja existe documento SD2 para o espelho: " + aDocs[1, 1] + "/" + aDocs[1, 2] + ". Conferir SF2/SD2 antes de qualquer nova emissao.")
		EndIf
		cSituacao := ZTLCheck(cEspelho, @nSC9)
		If !Empty(cSituacao)
			Break(cSituacao)
		EndIf
		aPvl := ZTFPvl(cEspelho)
		If Len(aPvl) == 0
			Break("Nenhuma liberacao apta para faturar.")
		EndIf
		If lEfetiva
			If !Pergunte("MT460A", .T.)
				Break("Parametros de faturamento cancelados. Nenhuma emissao iniciada.")
			EndIf
			If !FWAlertYesNo("Gerar documento fiscal para 02/" + cEspelho + ", serie " + cSerie + "?" + CRLF + "Esta acao movimenta o ERP. Confira parametros fiscais e automatismos do ambiente. Nao registra entrada na filial 03.", "Confirmar faturamento")
				Break("Faturamento cancelado. Nenhuma emissao iniciada.")
			EndIf
			Begin Transaction
				Begin Sequence
					DbSelectArea("SC5")
					DbSetOrder(1)
					If !DbSeek(xFilial("SC5") + PadR(cEspelho, TamSX3("C5_NUM")[1]))
						Break("Espelho nao encontrado antes do faturamento.")
					EndIf
					lLockC5 := RecLock("SC5", .F.)
					If !lLockC5
						Break("Espelho ocupado por outra execucao. Nenhuma emissao iniciada.")
					EndIf
					If SC5->(Deleted()) .Or. !Empty(SC5->C5_NOTA) .Or. ;
					   AllTrim(SC5->C5_ZZNPEXT) != "ZR03" + cOrigem .Or. ;
					   AllTrim(SC5->C5_CLIENTE) != "S00003" .Or. AllTrim(SC5->C5_LOJACLI) != "01"
						Break("Espelho mudou ou foi faturado antes da emissao.")
					EndIf
					aDocs := ZTFDocs(cEspelho)
					If Len(aDocs) > 0
						Break("Documento identificado apos a confirmacao; emissao interrompida.")
					EndIf
					cSituacao := ZTLCheck(cEspelho, @nSC9)
					If !Empty(cSituacao)
						Break(cSituacao)
					EndIf
					aPvl := ZTFPvl(cEspelho)
					If Len(aPvl) == 0
						Break("Liberacoes alteradas antes do faturamento.")
					EndIf
					For nLinha := 1 To Len(aPvl)
						SC9->(DbGoTo(aPvl[nLinha, 8]))
						If !SC9->(RecLock("SC9", .F.))
							Break("Liberacao SC9 ocupada por outra execucao.")
						EndIf
						aAdd(aLocksC9, aPvl[nLinha, 8])
						If SC9->(Deleted()) .Or. !Empty(SC9->C9_BLCRED) .Or. ;
						   !Empty(SC9->C9_BLEST) .Or. !Empty(SC9->C9_NFISCAL) .Or. ;
						   SC9->C9_PEDIDO != aPvl[nLinha, 1] .Or. SC9->C9_ITEM != aPvl[nLinha, 2] .Or. ;
						   SC9->C9_SEQUEN != aPvl[nLinha, 3] .Or. SC9->C9_PRODUTO != aPvl[nLinha, 6] .Or. ;
						   Abs(SC9->C9_QTDLIB - aPvl[nLinha, 4]) > 0.000001 .Or. ;
						   Abs(SC9->C9_PRCVEN - aPvl[nLinha, 5]) > 0.000001
							Break("Liberacao SC9 mudou apos a selecao; emissao interrompida.")
						EndIf
					Next nLinha
					SetFunName("MATA461")
					cDoc := MaPvlNfs(aPvl, cSerie, .F., .F., .F., .T., .F., 0, 0, .T., .F., "", {||}, {||}, {||}, {|| .T.}, dDataBase, .F., , dEntrega)
					SetFunName(cFuncao)
					If ValType(cDoc) != "C"
						Break("MaPvlNfs nao devolveu um numero de documento valido.")
					EndIf
					cDoc := AllTrim(cDoc)
					If Empty(cDoc) .Or. lMsErroAuto
						Break("MaPvlNfs nao confirmou a geracao do documento; conferir log fiscal antes de repetir.")
					EndIf
					If !ZTFProof(cEspelho, cDoc, cSerie, aItens)
						Break("Documento retornado sem comprovacao integral na SF2/SD2. Conferir o documento " + cDoc + "/" + cSerie + " antes de repetir.")
					EndIf
					lExecutou := .T.
				Recover Using oError
					If ValType(oError) == "O"
						cErro := cValToChar(oError:Description)
					Else
						cErro := cValToChar(oError)
					EndIf
					If Empty(cErro)
						cErro := "Faturamento interrompido sem descricao."
					EndIf
					DisarmTransaction()
					Break
				End Sequence
			End Transaction
		EndIf
	Recover Using oError
		If ValType(oError) == "O"
			cErro := cValToChar(oError:Description)
		Else
			cErro := cValToChar(oError)
		EndIf
		If Empty(cErro)
			cErro := "Conferencia fiscal interrompida sem descricao."
		EndIf
	End Sequence
	SetFunName(cFuncao)
	For nLinha := 1 To Len(aLocksC9)
		SC9->(DbGoTo(aLocksC9[nLinha]))
		SC9->(MsUnlock())
	Next nLinha
	If lLockC5
		SC5->(MsUnlock())
	EndIf
	If lMutex
		UnLockByName(cMutex, .T., .F.)
	EndIf
	ErrorBlock(bError)
	For nAlias := Len(aAreas) To 1 Step -1
		RestArea(aAreas[nAlias])
	Next nAlias
	RestArea(aArea)
	If !Empty(cErro)
		FWAlertError(cErro + CRLF + "Nao repita o faturamento sem conferir a SF2/SD2. Nenhuma entrada foi executada.", "Documento de saida da reposicao")
	ElseIf lExecutou
		FWAlertSuccess("Documento de saida " + cDoc + "/" + cSerie + " confirmado na SF2/SD2 para 02/" + cEspelho + "." + CRLF + "Isso nao confirma autorizacao da NF-e. Nenhuma entrada foi registrada na filial 03.", "Documento de saida da reposicao")
	Else
		FWAlertInfo("Conferencia aprovada para 02/" + cEspelho + ", serie " + cSerie + "." + CRLF + "Liberacoes selecionadas: " + cValToChar(Len(aPvl)) + ". Nenhum documento criado e nenhum registro alterado." + CRLF + "Valide a serie e os parametros MT460A com o responsavel fiscal antes de faturar.", "Documento de saida da reposicao")
	EndIf

Return

Static Function ZTFPvl(cPedido)

	Local aRetorno := {}
	Local cChave   := xFilial("SC6") + PadR(cPedido, TamSX3("C6_NUM")[1])
	Local cChaveC9 := ""
	Local nPreco   := 0

	If !SC5->(DbSeek(xFilial("SC5") + PadR(cPedido, TamSX3("C5_NUM")[1])))
		Break("Espelho nao localizado para selecionar o faturamento.")
	EndIf
	If SC5->(Deleted()) .Or. !Empty(SC5->C5_NOTA) .Or. SC5->C5_MOEDA != 1
		Break("Espelho excluido, faturado ou com moeda diferente de 1.")
	EndIf
	If !SE4->(DbSeek(xFilial("SE4") + SC5->C5_CONDPAG))
		Break("Condicao de pagamento nao encontrada.")
	EndIf
	SC6->(DbSeek(cChave))
	While !SC6->(Eof()) .And. SC6->(C6_FILIAL + C6_NUM) == cChave
		If !SC6->(Deleted())
			If !SB1->(DbSeek(xFilial("SB1") + SC6->C6_PRODUTO))
				Break("Produto nao encontrado para faturamento: " + AllTrim(SC6->C6_PRODUTO))
			EndIf
			If !SB2->(DbSeek(xFilial("SB2") + SC6->C6_PRODUTO + SC6->C6_LOCAL))
				Break("Saldo/armazem nao encontrado para faturamento.")
			EndIf
			If !SF4->(DbSeek(xFilial("SF4") + SC6->C6_TES))
				Break("TES nao encontrada para faturamento.")
			EndIf
			cChaveC9 := xFilial("SC9") + SC6->C6_NUM + SC6->C6_ITEM
			SC9->(DbSeek(cChaveC9))
			While !SC9->(Eof()) .And. SC9->(C9_FILIAL + C9_PEDIDO + C9_ITEM) == cChaveC9
				If !SC9->(Deleted())
					If !Empty(SC9->C9_BLCRED) .Or. !Empty(SC9->C9_BLEST) .Or. ;
					   !Empty(SC9->C9_NFISCAL) .Or. SC9->C9_PRODUTO != SC6->C6_PRODUTO .Or. SC9->C9_QTDLIB <= 0
						Break("Liberacao SC9 bloqueada, faturada ou divergente: " + SC6->C6_ITEM)
					EndIf
					nPreco := SC9->C9_PRCVEN
					If nPreco <= 0 .Or. Abs(nPreco - SC6->C6_PRCVEN) > 0.000001
						Break("Preco da SC9 diverge do espelho: item " + SC6->C6_ITEM)
					EndIf
					aAdd(aRetorno, {SC9->C9_PEDIDO, SC9->C9_ITEM, SC9->C9_SEQUEN, SC9->C9_QTDLIB, nPreco, SC9->C9_PRODUTO, .F., SC9->(RecNo()), SC5->(RecNo()), SC6->(RecNo()), SE4->(RecNo()), SB1->(RecNo()), SB2->(RecNo()), SF4->(RecNo())})
				EndIf
				SC9->(DbSkip())
			EndDo
		EndIf
		SC6->(DbSkip())
	EndDo

Return aRetorno

Static Function ZTFDocs(cPedido)

	Local aRetorno := {}
	Local cAlias   := GetNextAlias()
	Local cQuery   := ""

	cQuery := "SELECT D2.D2_DOC,D2.D2_SERIE,D2.D2_ITEMPV,D2.D2_COD,D2.D2_QUANT, " + ;
		"COALESCE(F2.F2_DOC, ' ') AS SF2DOC, COALESCE(F2.F2_CLIENTE, ' ') AS CLIENTE, COALESCE(F2.F2_LOJA, ' ') AS LOJA " + ;
		"FROM " + RetSqlName("SD2") + " D2 LEFT JOIN " + RetSqlName("SF2") + " F2 ON " + ;
		"F2.F2_FILIAL = D2.D2_FILIAL AND F2.F2_DOC = D2.D2_DOC AND F2.F2_SERIE = D2.D2_SERIE " + ;
		"AND F2.F2_CLIENTE = D2.D2_CLIENTE AND F2.F2_LOJA = D2.D2_LOJA AND F2.D_E_L_E_T_ = ' ' " + ;
		"WHERE D2.D_E_L_E_T_ = ' ' AND D2.D2_FILIAL = '" + xFilial("SD2") + "' " + ;
		"AND D2.D2_PEDIDO = '" + StrTran(cPedido, "'", "''") + "'"
	DbUseArea(.T., "TOPCONN", TcGenQry(,,ChangeQuery(cQuery)), cAlias, .F., .T.)
	While !(cAlias)->(Eof())
		aAdd(aRetorno, {AllTrim((cAlias)->D2_DOC), AllTrim((cAlias)->D2_SERIE), AllTrim((cAlias)->D2_ITEMPV), AllTrim((cAlias)->D2_COD), (cAlias)->D2_QUANT, AllTrim((cAlias)->SF2DOC), AllTrim((cAlias)->CLIENTE), AllTrim((cAlias)->LOJA)})
		(cAlias)->(DbSkip())
	EndDo
	(cAlias)->(DbCloseArea())

Return aRetorno

Static Function ZTFProof(cPedido, cDoc, cSerie, aItens)

	Local aDocs := ZTFDocs(cPedido)
	Local aQtd  := Array(Len(aItens))
	Local nItem := 0
	Local nPos  := 0

	If Empty(cDoc) .Or. Empty(cSerie) .Or. Len(aItens) == 0 .Or. Len(aDocs) == 0
		Return .F.
	EndIf
	AFill(aQtd, 0)
	For nItem := 1 To Len(aDocs)
		If aDocs[nItem, 1] != cDoc .Or. aDocs[nItem, 2] != cSerie .Or. aDocs[nItem, 6] != cDoc .Or. ;
		   aDocs[nItem, 7] != "S00003" .Or. aDocs[nItem, 8] != "01"
			Return .F.
		EndIf
		nPos := AScan(aItens, {|aItem| AllTrim(aItem[1]) == aDocs[nItem, 3] .And. AllTrim(aItem[2]) == aDocs[nItem, 4]})
		If nPos == 0
			Return .F.
		EndIf
		aQtd[nPos] += aDocs[nItem, 5]
	Next nItem
	For nItem := 1 To Len(aItens)
		If Abs(aQtd[nItem] - aItens[nItem, 3]) > 0.000001
			Return .F.
		EndIf
	Next nItem

Return .T.

User Function ZTRREC()

	Local aArea      := GetArea()
	Local aAreaC5    := {}
	Local aAreaZtr   := {}
	Local aPerguntas := {}
	Local aResposta  := {}
	Local cPedido    := ""
	Local cChave     := ""
	Local cId        := ""
	Local cMutex     := ""
	Local cAlias     := GetNextAlias()
	Local cQuery     := ""
	Local cErro      := ""
	Local lMutex     := .F.
	Local lLocked    := .F.
	Local bError     := Nil
	Local oError     := Nil

	If AllTrim(xFilial("SC5")) != "03"
		FWAlertError("Execute a recuperacao na filial 03.", "Recuperar solicitacao ZTR")
		Return
	EndIf
	aAdd(aPerguntas, {1, "Pedido origem (03)", Space(6), "@!", "", "", "", 60, .T.})
	If !ParamBox(aPerguntas, "Recuperar solicitacao ZTR", @aResposta)
		Return
	EndIf
	cPedido := AllTrim(aResposta[1])
	If Len(cPedido) != 6 .Or. cPedido != StrZero(Val(cPedido), 6)
		FWAlertError("Informe o numero do pedido com seis digitos.", "Recuperar solicitacao ZTR")
		Return
	EndIf
	If !FWAlertYesNo("Conferir o pedido " + cPedido + " e recuperar somente o status vazio da ZTR para ERRO_REP, sem criar reposicao?", "Confirmar recuperacao")
		Return
	EndIf
	If Select("SC5") > 0
		aAreaC5 := SC5->(GetArea())
	EndIf
	If Select("ZTR") > 0
		aAreaZtr := ZTR->(GetArea())
	EndIf
	cId := "ZR03" + cPedido
	cMutex := "ZTR_" + cEmpAnt + "_03_" + cPedido
	bError := ErrorBlock({|oErr| Break(oErr)})
	Begin Sequence
		lMutex := LockByName(cMutex, .T., .F.)
		If !lMutex
			cErro := "Solicitacao em processamento. Nenhum registro alterado."
		EndIf
		If Empty(cErro)
			DbSelectArea("SC5")
			DbSetOrder(1)
			If !DbSeek(xFilial("SC5") + PadR(cPedido, TamSX3("C5_NUM")[1]))
				cErro := "Pedido de origem nao encontrado na filial 03."
			ElseIf SC5->(Deleted())
				cErro := "Pedido de origem excluido."
			EndIf
		EndIf
		If Empty(cErro)
			cQuery := "SELECT C5_NUM FROM " + RetSqlName("SC5") + ;
				" WHERE C5_FILIAL = '02' AND C5_ZZNPEXT = '" + cId + "'"
			DbUseArea(.T., "TOPCONN", TcGenQry(,,ChangeQuery(cQuery)), cAlias, .F., .T.)
			If !(cAlias)->(Eof())
				cErro := "Existe pedido 02/" + AllTrim((cAlias)->C5_NUM) + " com o identificador " + cId + ". Conferir o vinculo manualmente; fila preservada."
			EndIf
			(cAlias)->(DbCloseArea())
		EndIf
		If Empty(cErro)
			DbSelectArea("ZTR")
			DbSetOrder(1)
			cChave := PadR("03", TamSX3("ZTR_FILORI")[1]) + PadR(cPedido, TamSX3("ZTR_PEDORI")[1])
			If !DbSeek(cChave)
				cErro := "Solicitacao nao encontrada na ZTR."
			Else
				lLocked := RecLock("ZTR", .F.)
				If !lLocked
					cErro := "Nao foi possivel bloquear a solicitacao."
				ElseIf ZTR->(Deleted()) .Or. !Empty(ZTR->ZTR_STATUS) .Or. !Empty(ZTR->ZTR_PEDTRF)
					cErro := "Recuperacao permitida apenas para status vazio, sem espelho vinculado."
				ElseIf AllTrim(ZTR->ZTR_FILORI) != "03" .Or. AllTrim(ZTR->ZTR_FDEST) != "02"
					cErro := "Filiais da solicitacao divergem do fluxo 03 para 02."
				ElseIf AllTrim(ZTR->ZTR_APIID) != AllTrim(SC5->C5_ZZNPEXT) .Or. ;
				       AllTrim(ZTR->ZTR_PEDEXT) != AllTrim(SC5->C5_PEDECOM)
					cErro := "Identificadores da origem divergem da solicitacao."
				Else
					ZTR->ZTR_STATUS := "ERRO_REP"
					ZTR->ZTR_MSGERR := "Status vazio recuperado manualmente; sem espelho localizado. Revalidar antes de nova tentativa."
					ZTR->ZTR_DTATU := Date()
					ZTR->ZTR_HRATU := StrTran(Time(), ":", "")
				EndIf
			EndIf
		EndIf
	Recover Using oError
		If ValType(oError) == "O"
			cErro := cValToChar(oError:Description)
		Else
			cErro := cValToChar(oError)
		EndIf
		If Empty(cErro)
			cErro := "Recuperacao interrompida sem descricao. Confira a ZTR."
		EndIf
	End Sequence
	If Select(cAlias) > 0
		(cAlias)->(DbCloseArea())
	EndIf
	If lLocked
		ZTR->(MsUnlock())
	EndIf
	If lMutex
		UnLockByName(cMutex, .T., .F.)
	EndIf
	ErrorBlock(bError)
	If Len(aAreaZtr) > 0
		RestArea(aAreaZtr)
	EndIf
	If Len(aAreaC5) > 0
		RestArea(aAreaC5)
	EndIf
	RestArea(aArea)
	If Empty(cErro)
		FWAlertSuccess("Solicitacao " + cPedido + " recuperada para ERRO_REP. Tentativas preservadas. Nenhum pedido criado." + CRLF + "Execute U_ZTRPROC em Simular; nao efetive antes de conferir o resultado.", "Recuperar solicitacao ZTR")
	Else
		FWAlertError(cErro, "Recuperar solicitacao ZTR")
	EndIf

Return

User Function ZTRDIAG()

	Local cEmpresa := cEmpAnt
	Local cResumo  := ""
	Local xSimples := Nil
	Local xArray   := Nil
	Local xEnv     := Nil
	Local lOk      := .F.
	Local bError   := ErrorBlock({|oErr| Break(oErr)})
	Local oError   := Nil

	Begin Sequence
		xSimples := StartJob("U_ZTRPING", GetEnvServer(), .T., .F.)
		cResumo := "Retorno simples: tipo " + ValType(xSimples) + CRLF
		If ValType(xSimples) != "C"
			Break("O teste sem banco nao devolveu texto. A falha antecede a reposicao e a abertura de ambiente.")
		EndIf
		If xSimples != "ZTR_PING_OK"
			Break("O teste sem banco devolveu texto inesperado: " + xSimples)
		EndIf
		xArray := StartJob("U_ZTRPING", GetEnvServer(), .T., .T.)
		cResumo += "Retorno array: tipo " + ValType(xArray) + CRLF
		If ValType(xArray) != "A"
			Break("O StartJob devolve texto, mas nao devolveu o array de teste. Nenhum pedido foi processado.")
		EndIf
		If Len(xArray) != 4
			Break("O array de teste chegou incompleto.")
		EndIf
		xEnv := StartJob("U_ZTRENV", GetEnvServer(), .T., cEmpresa)
		cResumo += "Abertura filial 03: tipo " + ValType(xEnv) + CRLF
		If ValType(xEnv) != "C"
			Break("Os retornos sem banco funcionaram, mas o teste de RpcSetEnv/RpcClearEnv terminou sem retorno.")
		EndIf
		cResumo += xEnv
		lOk := xEnv == "AMBIENTE_03_OK"
	Recover Using oError
		If ValType(oError) == "O"
			cResumo += cValToChar(oError:Description)
		Else
			cResumo += cValToChar(oError)
		EndIf
	End Sequence
	ErrorBlock(bError)
	ConOut("[ZTR] DIAGNOSTICO: " + cResumo)
	If lOk
		FWAlertSuccess(cResumo + CRLF + "Nenhum pedido ou registro ZTR alterado.", "Diagnostico ZTR")
	Else
		FWAlertError(cResumo + CRLF + "Nenhum pedido ou registro ZTR alterado.", "Diagnostico ZTR")
	EndIf

Return

User Function ZTRPING(lArray)

	Default lArray := .F.

	ConOut("[ZTR] PING sem abertura de ambiente; array=" + cValToChar(lArray))
	If lArray
		Return {.T., "PING", "", "ZTR_PING_OK"}
	EndIf

Return "ZTR_PING_OK"

User Function ZTRENV(cEmpresa)

	Local cResultado := "ABERTURA_03_NAO_CONFIRMADA"
	Local lAmbiente  := .F.
	Local bError     := ErrorBlock({|oErr| Break(oErr)})
	Local oError     := Nil

	Begin Sequence
		If Select("SX6") > 0
			Break("O diagnostico de ambiente exige job isolado.")
		EndIf
		RpcSetType(3)
		ConOut("[ZTR] DIAG_ENV: antes de RpcSetEnv; empresa=" + cEmpresa + ", filial=03")
		lAmbiente := RpcSetEnv(cEmpresa, "03")
		ConOut("[ZTR] DIAG_ENV: depois de RpcSetEnv; retorno=" + cValToChar(lAmbiente))
		If lAmbiente
			cResultado := "AMBIENTE_03_OK"
		Else
			cResultado := "RpcSetEnv retornou falso para a filial 03."
		EndIf
	Recover Using oError
		If ValType(oError) == "O"
			cResultado := "Falha na abertura: " + cValToChar(oError:Description)
		Else
			cResultado := "Falha na abertura: " + cValToChar(oError)
		EndIf
	End Sequence
	Begin Sequence
		If lAmbiente
			ConOut("[ZTR] DIAG_ENV: antes de RpcClearEnv")
			RpcClearEnv()
			ConOut("[ZTR] DIAG_ENV: depois de RpcClearEnv")
		EndIf
	Recover Using oError
		If ValType(oError) == "O"
			cResultado := "Falha no fechamento: " + cValToChar(oError:Description)
		Else
			cResultado := "Falha no fechamento: " + cValToChar(oError)
		EndIf
	End Sequence
	ErrorBlock(bError)

Return cResultado

User Function ZTRJOB(cEmpresa, cPedido, cModelo, lGrava)

	Local aResultado := {.F., "ERRO_JOB", "", "O processamento terminou sem resultado confirmado."}
	Local bError     := ErrorBlock({|oErr| Break(oErr)})
	Local oError     := Nil
	Local cErro      := ""

	Default lGrava := .F.

	Begin Sequence
		ConOut("[ZTR] Entrada no job: origem=03/" + cPedido + ", efetivar=" + cValToChar(lGrava))
		aResultado := ZTRRun(cEmpresa, cPedido, cModelo, lGrava)
		If ValType(aResultado) != "A"
			Break("O processamento interno terminou sem devolver o resultado.")
		EndIf
		If Len(aResultado) != 4
			Break("O processamento interno devolveu resultado incompleto.")
		EndIf
		If ValType(aResultado[1]) != "L" .Or. ValType(aResultado[4]) != "C"
			Break("O processamento interno devolveu formato de resultado invalido.")
		EndIf
	Recover Using oError
		If ValType(oError) == "O"
			cErro := cValToChar(oError:Description)
		Else
			cErro := cValToChar(oError)
		EndIf
		If Empty(AllTrim(cErro))
			cErro := "Interrupcao do job sem descricao; tipo de erro " + ValType(oError)
		EndIf
		cErro := "Falha no job da origem 03/" + cPedido + ": " + cErro + CRLF + ;
			"A operacao pode ter sido interrompida apos uma gravacao. Confira a ZTR e o identificador ZR03" + cPedido + " na filial 02 antes de repetir."
		aResultado := {.F., "ERRO_JOB", "", cErro}
	End Sequence
	ErrorBlock(bError)
	ConOut("[ZTR] Saida do job: " + aResultado[4])

Return aResultado

Static Function ZTRRun(cEmpresa, cPedido, cModelo, lGrava)

	Local aAvaliacao  := {}
	Local aItens     := {}
	Local cChave     := ""
	Local cId        := ""
	Local cNovo      := ""
	Local cErro      := ""
	Local cStatus    := ""
	Local cMensagem  := ""
	Local cOrigem    := ""
	Local cEtapa     := "ABERTURA_ORIGEM"
	Local cLock      := "ZTR_" + cEmpresa + "_03_" + cPedido
	Local lAmbiente  := .F.
	Local lMutex     := .F.
	Local lClaim     := .F.
	Local lLocked    := .F.
	Local bError     := ErrorBlock({|oErr| Break(oErr)})
	Local oError     := Nil

	Default lGrava := .F.

	Begin Sequence
		If Select("SX6") > 0
			Break("U_ZTRJOB deve executar em job isolado, pelo U_ZTRPROC.")
		EndIf
		RpcSetType(3)
		ConOut("[ZTR] ABERTURA_ORIGEM: iniciando RpcSetEnv para empresa " + cEmpresa + ", filial 03.")
		lAmbiente := RpcSetEnv(cEmpresa, "03")
		ConOut("[ZTR] ABERTURA_ORIGEM: retorno=" + cValToChar(lAmbiente))
		If !lAmbiente
			Break("Nao foi possivel abrir a filial 03.")
		EndIf
		lMutex := LockByName(cLock, .T., .F.)
		If !lMutex
			Break("Solicitacao ja esta sendo processada.")
		EndIf
		DbSelectArea("ZTR")
		DbSetOrder(1)
		cChave := PadR("03", TamSX3("ZTR_FILORI")[1]) + PadR(cPedido, TamSX3("ZTR_PEDORI")[1])
		If !DbSeek(cChave) .Or. ZTR->(Deleted())
			Break("Solicitacao nao encontrada na ZTR.")
		EndIf
		ConOut("[ZTR] Solicitacao localizada: " + cPedido + ", status=" + AllTrim(ZTR->ZTR_STATUS))
		If Empty(AllTrim(ZTR->ZTR_STATUS))
			cMensagem := "A solicitacao do pedido 03/" + cPedido + " esta com status vazio na ZTR." + CRLF + ;
				"A tentativa anterior deixou a fila inconsistente. Nenhuma reposicao foi executada nesta chamada." + CRLF + ;
				"Conferir a SC5 da filial 02 pelo identificador ZR03" + cPedido + " antes de recuperar a solicitacao."
			ConOut("[ZTR] VALIDACAO_FILA: " + cMensagem)
			If lMutex
				UnLockByName(cLock, .T., .F.)
				lMutex := .F.
			EndIf
			If lAmbiente
				RpcClearEnv()
				lAmbiente := .F.
			EndIf
			ErrorBlock(bError)
			Return {.F., "ERRO_MAN", "", cMensagem}
		EndIf
		If !Empty(ZTR->ZTR_PEDTRF) .Or. AllTrim(ZTR->ZTR_STATUS) == "CRIADO"
			Break("Solicitacao ja vinculada ao espelho " + AllTrim(ZTR->ZTR_PEDTRF))
		EndIf
		If AScan({"AG_PGTO", "AG_LIB", "PRONTO", "CRIANDO", "ERRO_REP"}, AllTrim(ZTR->ZTR_STATUS)) == 0
			Break("Status exige verificacao manual: " + AllTrim(ZTR->ZTR_STATUS))
		EndIf
		If AllTrim(ZTR->ZTR_FDEST) != "02"
			Break("Destino da solicitacao diferente de 02.")
		EndIf
		cOrigem := Upper(AllTrim(SuperGetMV("MV_PEDTRAN", .F., "")))
		If Empty(cOrigem)
			Break("Parametro MV_PEDTRAN nao configurado.")
		EndIf
		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSelectArea("SC6")
		DbSetOrder(1)
		DbSelectArea("SC9")
		DbSetOrder(1)
		cEtapa := "VALIDACAO_ORIGEM"
		aAvaliacao := ZTVCheck(cPedido, cOrigem)
		If aAvaliacao[1] != "PRONTO"
			Break(aAvaliacao[1] + ": " + aAvaliacao[5])
		EndIf
		SC6->(DbSeek(xFilial("SC6") + PadR(cPedido, TamSX3("C6_NUM")[1])))
		While !SC6->(Eof()) .And. SC6->C6_FILIAL == xFilial("SC6") .And. AllTrim(SC6->C6_NUM) == cPedido
			If !SC6->(Deleted())
				If SC6->C6_QTDENT != 0
					Break("Pedido parcialmente atendido; conferir manualmente antes de espelhar.")
				EndIf
				If SC6->C6_QTDVEN > 0
					aAdd(aItens, {SC6->C6_ITEM, SC6->C6_PRODUTO, SC6->C6_QTDVEN})
				EndIf
			EndIf
			SC6->(DbSkip())
		EndDo
		If Len(aItens) == 0
			Break("Pedido sem itens para reposicao.")
		EndIf
		cId := "ZR03" + cPedido
		If Len(cId) > TamSX3("C5_ZZNPEXT")[1]
			Break("Identificador de rastreio excede C5_ZZNPEXT.")
		EndIf
		If lGrava
			cEtapa := "MARCA_CRIANDO"
			DbSelectArea("ZTR")
			If !RecLock("ZTR", .F.)
				Break("Nao foi possivel bloquear a solicitacao.")
			EndIf
			lLocked := .T.
			If !Empty(ZTR->ZTR_PEDTRF) .Or. AllTrim(ZTR->ZTR_STATUS) == "CRIADO"
				Break("Solicitacao vinculada por outra execucao.")
			EndIf
			If Deleted() .Or. AllTrim(ZTR->ZTR_FDEST) != "02" .Or. ;
			   AScan({"AG_PGTO", "AG_LIB", "PRONTO", "CRIANDO", "ERRO_REP"}, AllTrim(ZTR->ZTR_STATUS)) == 0
				Break("Solicitacao mudou antes do inicio do processamento.")
			EndIf
			ZTR->ZTR_STATUS := "CRIANDO"
			ZTR->ZTR_TENTAT += 1
			ZTR->ZTR_MSGERR := ""
			ZTR->ZTR_DTATU := Date()
			ZTR->ZTR_HRATU := StrTran(Time(), ":", "")
			ZTR->(MsUnlock())
			lLocked := .F.
			lClaim := .T.
		EndIf

		cEtapa := "ABERTURA_DESTINO"
		ConOut("[ZTR] ABERTURA_DESTINO: fechando ambiente da filial 03.")
		RpcClearEnv()
		lAmbiente := .F.
		ConOut("[ZTR] ABERTURA_DESTINO: iniciando RpcSetEnv para filial 02.")
		lAmbiente := RpcSetEnv(cEmpresa, "02")
		ConOut("[ZTR] ABERTURA_DESTINO: retorno=" + cValToChar(lAmbiente))
		If !lAmbiente
			Break("Nao foi possivel abrir a filial 02.")
		EndIf
		cEtapa := "CRIACAO_ESPELHO"
		cNovo := ZTRMake(cModelo, cId, aItens, lGrava)
		If lGrava
			If ValType(cNovo) != "C"
				cNovo := ""
				Break("A criacao nao devolveu um numero de espelho valido. Confira o identificador " + cId + " na filial 02 antes de repetir.")
			EndIf
			cNovo := AllTrim(cNovo)
			If Empty(cNovo)
				Break("A criacao devolveu numero de espelho vazio. Nenhum sucesso foi confirmado. Confira o identificador " + cId + " na filial 02 antes de repetir.")
			EndIf
			If !ZTRSaved(cNovo, cId, aItens)
				Break("Espelho " + cNovo + " nao foi confirmado apos a criacao; conferir cabecalho e itens na filial 02.")
			EndIf
			cStatus := "CRIADO"
		Else
			cStatus := "SIMULADO"
			ConOut("[ZTR] SIMULACAO " + cPedido + ": validacoes aprovadas; nenhum pedido criado.")
		EndIf
	Recover Using oError
		If ValType(oError) == "O"
			cErro := cValToChar(oError:Description)
		Else
			cErro := cValToChar(oError)
		EndIf
		If Empty(AllTrim(cErro))
			cErro := "Falha sem descricao; retorno de erro do tipo " + ValType(oError)
		EndIf
		cErro := cEtapa + ": " + cErro
		cStatus := "ERRO_REP"
	End Sequence

	If Empty(cErro) .And. lGrava
		If cStatus != "CRIADO" .Or. Empty(cNovo)
			cErro := "Efetivacao sem confirmacao de espelho. Confira o identificador " + cId + " na filial 02 antes de repetir."
			cStatus := "ERRO_REP"
		EndIf
	EndIf
	If lLocked
		ZTR->(MsUnlock())
	EndIf
	If lClaim
		Begin Sequence
			If lAmbiente
				RpcClearEnv()
				lAmbiente := .F.
			EndIf
			lAmbiente := RpcSetEnv(cEmpresa, "03")
			If !lAmbiente
				Break("Nao foi possivel atualizar o resultado na filial 03.")
			EndIf
			DbSelectArea("ZTR")
			DbSetOrder(1)
			If !DbSeek(cChave)
				Break("Solicitacao nao encontrada ao registrar o resultado.")
			EndIf
			If !RecLock("ZTR", .F.)
				Break("Nao foi possivel bloquear a fila para registrar o resultado.")
			EndIf
			lLocked := .T.
			If AllTrim(ZTR->ZTR_STATUS) != "CRIANDO" .Or. !Empty(ZTR->ZTR_PEDTRF)
				Break("Solicitacao mudou durante a execucao; conferir o identificador " + cId)
			EndIf
			If cStatus == "CRIADO" .And. Empty(cNovo)
				Break("Estado inconsistente: nao e permitido gravar CRIADO sem numero de espelho.")
			EndIf
			ZTR->ZTR_STATUS := cStatus
			ZTR->ZTR_PEDTRF := cNovo
			ZTR->ZTR_SITFIN := aAvaliacao[2]
			ZTR->ZTR_SITCOM := aAvaliacao[3]
			ZTR->ZTR_LIBOK := aAvaliacao[4]
			ZTR->ZTR_MSGERR := Left(cErro, TamSX3("ZTR_MSGERR")[1])
			ZTR->ZTR_DTATU := Date()
			ZTR->ZTR_HRATU := StrTran(Time(), ":", "")
			ZTR->(MsUnlock())
			lLocked := .F.
		Recover Using oError
			cStatus := "ERRO_FILA"
			If ValType(oError) == "O"
				cErro += " Falha ao salvar resultado na ZTR: " + cValToChar(oError:Description)
			Else
				cErro += " Falha ao salvar resultado na ZTR: " + cValToChar(oError)
			EndIf
			If lLocked
				ZTR->(MsUnlock())
				lLocked := .F.
			EndIf
		End Sequence
	EndIf
	If !Empty(cErro)
		ConOut("[ZTR] " + cPedido + " - " + cErro)
	ElseIf lGrava
		ConOut("[ZTR] " + cPedido + " - " + cStatus + " - Espelho 02/" + cNovo)
	EndIf
	If lMutex
		ConOut("[ZTR] FINALIZACAO: liberando mutex da solicitacao.")
		UnLockByName(cLock, .T., .F.)
	EndIf
	If lAmbiente
		ConOut("[ZTR] FINALIZACAO: fechando ambiente do job.")
		RpcClearEnv()
	EndIf
	ErrorBlock(bError)

	If !Empty(cErro)
		cMensagem := "Pedido origem 03/" + cPedido + ":" + CRLF + AllTrim(cErro)
		If !Empty(cNovo)
			cMensagem += CRLF + "Espelho identificado: 02/" + cNovo + ". Confira o vinculo na ZTR antes de repetir."
		EndIf
	ElseIf lGrava
		cMensagem := "Reposicao criada e vinculada na ZTR." + CRLF + ;
			"Origem: 03/" + cPedido + CRLF + "Espelho: 02/" + cNovo + CRLF + "Status: CRIADO."
	ElseIf !Empty(cNovo)
		cMensagem := "Espelho existente conferido: 02/" + cNovo + CRLF + ;
			"Origem: 03/" + cPedido + CRLF + "Simulacao: nenhum pedido criado e nenhum registro alterado."
	Else
		cMensagem := "Simulacao aprovada para o pedido 03/" + cPedido + "." + CRLF + ;
			"Nenhum pedido criado e nenhum registro alterado." + CRLF + ;
			"Para criar a reposicao na filial 02, execute novamente no modo Efetivar."
	EndIf

Return {Empty(cErro), cStatus, cNovo, cMensagem}

Static Function ZTRMake(cModelo, cId, aItens, lGrava)

	Local aCabecalho := {}
	Local aLinhas    := {}
	Local aLinha     := {}
	Local aLog       := {}
	Local aAliases   := {"SC5", "SC6", "SC9", "SA1", "SA2", "SA3", "SA4", "SB1", "SB2", "SE4", "SF4", "DA0", "DA1"}
	Local cNovo      := ""
	Local cErro      := ""
	Local cTes       := ""
	Local cOper      := ""
	Local cLocal     := ""
	Local cEtapa     := "RESERVA_NUMERO"
	Local cOcupado   := ""
	Local nItem      := 0
	Local nPreco     := 0
	Local nReserva   := 0
	Local lReserva   := .F.
	Local bError     := Nil
	Local oError     := Nil

	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.
	Private lAutoErrNoFile := .T.
	Private _lAprov := .F.
	Private lAlcada := .F.

	For nItem := 1 To Len(aAliases)
		DbSelectArea(aAliases[nItem])
		DbSetOrder(1)
	Next nItem
	DbSelectArea("SC5")
	DbSetOrder(12)
	If DbSeek(xFilial("SC5") + PadR(cId, TamSX3("C5_ZZNPEXT")[1]))
		cNovo := AllTrim(SC5->C5_NUM)
		If !ZTRSaved(cNovo, cId, aItens)
			Break("Espelho existente divergente; nao sera duplicado: " + cNovo)
		EndIf
		ConOut("[ZTR] Espelho existente conferido: 02/" + cNovo)
		Return cNovo
	EndIf
	DbSetOrder(1)
	If !DbSeek(xFilial("SC5") + PadR(cModelo, TamSX3("C5_NUM")[1]))
		Break("Pedido modelo nao encontrado na filial 02.")
	EndIf
	If SC5->(Deleted()) .Or. AllTrim(SC5->C5_TABELA) != "TTR" .Or. ;
	   AllTrim(SC5->C5_CLIENTE) != "S00003" .Or. AllTrim(SC5->C5_LOJACLI) != "01" .Or. ;
	   AllTrim(SC5->C5_ZZORIGE) != "INT" .Or. AllTrim(SC5->C5_ZZTPPED) != "TR"
		Break("Modelo deve ser TTR, cliente S00003/01, origem INT e tipo TR.")
	EndIf
	If SC5->C5_MOEDA != 1
		Break("Esta etapa suporta apenas modelo e precos em moeda 1.")
	EndIf
	aAdd(aCabecalho, {"C5_TIPO", "N", Nil})
	aAdd(aCabecalho, {"C5_EMISSAO", Date(), Nil})
	aAdd(aCabecalho, {"C5_CLIENTE", SC5->C5_CLIENTE, Nil})
	aAdd(aCabecalho, {"C5_LOJACLI", SC5->C5_LOJACLI, Nil})
	aAdd(aCabecalho, {"C5_LOJAENT", SC5->C5_LOJACLI, Nil})
	aAdd(aCabecalho, {"C5_CONDPAG", SC5->C5_CONDPAG, Nil})
	aAdd(aCabecalho, {"C5_VEND1", SC5->C5_VEND1, Nil})
	aAdd(aCabecalho, {"C5_TRANSP", SC5->C5_TRANSP, Nil})
	aAdd(aCabecalho, {"C5_TPFRETE", SC5->C5_TPFRETE, Nil})
	aAdd(aCabecalho, {"C5_MOEDA", SC5->C5_MOEDA, Nil})
	aAdd(aCabecalho, {"C5_TABELA", "TTR", Nil})
	aAdd(aCabecalho, {"C5_ZZORIGE", "INT", Nil})
	aAdd(aCabecalho, {"C5_ZZTPPED", "TR", Nil})
	aAdd(aCabecalho, {"C5_ZZSITFI", "2", Nil})
	aAdd(aCabecalho, {"C5_ZZSITCO", "1", Nil})
	aAdd(aCabecalho, {"C5_ZZNPEXT", cId, Nil})
	aAdd(aCabecalho, {"C5_ZZDTEMI", Date(), Nil})
	aAdd(aCabecalho, {"C5_ZZOBS", "Reposicao Marketplace origem 03/" + SubStr(cId, 5), Nil})
	DbSelectArea("SC6")
	DbSetOrder(1)
	If !DbSeek(xFilial("SC6") + PadR(cModelo, TamSX3("C6_NUM")[1]))
		Break("Pedido modelo sem itens.")
	EndIf
	cTes := SC6->C6_TES
	cOper := SC6->C6_OPER
	cLocal := SC6->C6_LOCAL
	If Empty(cTes) .Or. Empty(cOper) .Or. Empty(cLocal)
		Break("Modelo deve informar TES, operacao e armazem.")
	EndIf
	While !Eof() .And. C6_FILIAL == xFilial("SC6") .And. AllTrim(C6_NUM) == cModelo
		If !Deleted() .And. (C6_TES != cTes .Or. C6_OPER != cOper .Or. C6_LOCAL != cLocal)
			Break("Modelo tem configuracoes fiscais distintas; escolha um modelo uniforme.")
		EndIf
		DbSkip()
	EndDo
	DbSelectArea("DA1")
	DbSetOrder(1)
	For nItem := 1 To Len(aItens)
		nPreco := ZTRPrice(aItens[nItem, 2], aItens[nItem, 3])
		If nPreco <= 0
			Break("Preco TTR ativo/vigente ausente ou ambiguo: " + AllTrim(aItens[nItem, 2]))
		EndIf
		aLinha := {}
		aAdd(aLinha, {"C6_ITEM", aItens[nItem, 1], Nil})
		aAdd(aLinha, {"C6_PRODUTO", aItens[nItem, 2], Nil})
		aAdd(aLinha, {"C6_QTDVEN", aItens[nItem, 3], Nil})
		aAdd(aLinha, {"C6_PRUNIT", nPreco, Nil})
		aAdd(aLinha, {"C6_PRCVEN", nPreco, Nil})
		aAdd(aLinha, {"C6_OPER", cOper, Nil})
		aAdd(aLinha, {"C6_TES", cTes, Nil})
		aAdd(aLinha, {"C6_LOCAL", cLocal, Nil})
		aAdd(aLinhas, aLinha)
	Next nItem
	If !lGrava
		Return ""
	EndIf
	If AllTrim(cFilAnt) != "02" .Or. AllTrim(xFilial("SC5")) != "02"
		Break("Reserva de numeracao permitida somente no ambiente da filial 02.")
	EndIf

	bError := ErrorBlock({|oErr| Break(oErr)})
	Begin Transaction
		Begin Sequence
			For nReserva := 1 To 20
				DbSelectArea("SC5")
				DbSetOrder(1)
				cNovo := GetSxeNum("SC5", "C5_NUM", , 1, cEmpAnt, "02")
				lReserva := .T.
				If ValType(cNovo) != "C"
					Break("Reserva de numeracao nao devolveu um valor caractere.")
				EndIf
				cNovo := AllTrim(cNovo)
				If Empty(cNovo)
					Break("Reserva de numeracao devolveu numero vazio para SC5/C5_NUM.")
				EndIf
				If !SC5->(DbSeek(xFilial("SC5") + PadR(cNovo, TamSX3("C5_NUM")[1])))
					Exit
				EndIf
				ConOut("[ZTR] Numeracao ja ocupada: 02/" + cNovo + "; reserva " + cValToChar(nReserva) + " de 20.")
				ConfirmSX8()
				lReserva := .F.
				If cNovo == cOcupado
					Break("Controle de numeracao repetiu " + cNovo + " apos ConfirmSX8. Conferir SXE/SXF ou servidor de numeracao; nenhum pedido criado.")
				EndIf
				cOcupado := cNovo
			Next nReserva
			If !lReserva
				Break("Limite de 20 reservas atingido, todas ja ocupadas. Ultimo numero: " + cOcupado + ". Conferir controle padrao de numeracao; nenhum pedido criado.")
			EndIf
			aAdd(aCabecalho, {"C5_NUM", cNovo, Nil})
			cEtapa := "MATA410"
			ConOut("[ZTR] Criando espelho 02/" + cNovo + " - identificador " + cId)
			MsExecAuto({|aCab, aDet, nOpc, lMostra| MATA410(aCab, aDet, nOpc, lMostra)}, aCabecalho, aLinhas, 3, .F.)
			If lMsErroAuto
				aLog := GetAutoGrLog()
				cErro := "Falha no MATA410."
				For nItem := 1 To Len(aLog)
					ConOut("[ZTR] " + cValToChar(aLog[nItem]))
					cErro += " " + cValToChar(aLog[nItem])
				Next nItem
				Break(cErro)
			EndIf
			cEtapa := "CONFERE_ITENS"
			If !ZTRSaved(AllTrim(cNovo), cId, aItens)
				Break("MATA410 nao salvou integralmente o cabecalho e os itens do espelho.")
			EndIf
		Recover Using oError
			If ValType(oError) == "O"
				cErro := cValToChar(oError:Description)
			Else
				cErro := cValToChar(oError)
			EndIf
			If Empty(cErro)
				cErro := "Falha sem descricao na etapa " + cEtapa
			Else
				cErro := cEtapa + ": " + cErro
			EndIf
			ConOut("[ZTR] " + cErro)
			DisarmTransaction()
			Break
		End Sequence
	End Transaction
	ErrorBlock(bError)
	If !Empty(cErro)
		If lReserva
			RollBackSX8()
		EndIf
		Break(cErro)
	EndIf
	ConfirmSX8()

Return AllTrim(cNovo)

Static Function ZTRPrice(cProduto, nQuantidade)

	Local cChave := xFilial("DA1") + PadR("TTR", TamSX3("DA1_CODTAB")[1]) + cProduto
	Local dVigencia := StoD("")
	Local nPreco := 0
	Local nValidos := 0

	DA1->(DbSeek(cChave))
	While !DA1->(Eof()) .And. DA1->(DA1_FILIAL + DA1_CODTAB + DA1_CODPRO) == cChave
		If !DA1->(Deleted()) .And. DA1->DA1_ATIVO == "1" .And. DA1->DA1_DATVIG <= Date() .And. ;
		   DA1->DA1_MOEDA == 1 .And. DA1->DA1_QTDLOT >= nQuantidade
			If DA1->DA1_DATVIG > dVigencia
				dVigencia := DA1->DA1_DATVIG
				nValidos := 0
			EndIf
			If DA1->DA1_DATVIG == dVigencia
				nValidos += 1
				nPreco := DA1->DA1_PRCVEN
			EndIf
		EndIf
		DA1->(DbSkip())
	EndDo
	If nValidos != 1
		nPreco := 0
	EndIf

Return nPreco

Static Function ZTRSaved(cPedido, cId, aItens)

	Local nItem := 0
	Local nPos := 0
	Local aVistos := {}
	Local cChave := xFilial("SC6") + PadR(cPedido, TamSX3("C6_NUM")[1])

	If Empty(AllTrim(cPedido)) .Or. Len(aItens) == 0
		Return .F.
	EndIf
	DbSelectArea("SC5")
	DbSetOrder(1)
	If !DbSeek(xFilial("SC5") + PadR(cPedido, TamSX3("C5_NUM")[1]))
		Return .F.
	EndIf
	If Deleted() .Or. AllTrim(C5_ZZNPEXT) != cId .Or. AllTrim(C5_TABELA) != "TTR" .Or. ;
	   AllTrim(C5_CLIENTE) != "S00003" .Or. AllTrim(C5_LOJACLI) != "01" .Or. ;
	   AllTrim(C5_ZZORIGE) != "INT" .Or. AllTrim(C5_ZZTPPED) != "TR"
		Return .F.
	EndIf
	For nItem := 1 To Len(aItens)
		aAdd(aVistos, .F.)
	Next nItem
	SC6->(DbSetOrder(1))
	SC6->(DbSeek(cChave))
	While !SC6->(Eof()) .And. SC6->(C6_FILIAL + C6_NUM) == cChave
		If !SC6->(Deleted())
			nPos := AScan(aItens, {|aItem| aItem[1] == SC6->C6_ITEM})
			If nPos == 0
				Return .F.
			EndIf
			If aVistos[nPos] .Or. SC6->C6_PRODUTO != aItens[nPos, 2] .Or. ;
			   Abs(SC6->C6_QTDVEN - aItens[nPos, 3]) > 0.000001 .Or. SC6->C6_PRCVEN <= 0
				Return .F.
			EndIf
			aVistos[nPos] := .T.
		EndIf
		SC6->(DbSkip())
	EndDo

Return AScan(aVistos, .F.) == 0
