#INCLUDE 'PROTHEUS.CH'
#Include 'Totvs.ch'
#Include 'APWIZARD.CH'
#include "parmtype.ch"
#include "RwMake.ch"


User Function AtuCampoCSV()
	Local cModo := ""
	Local cTabela := ""
	Local cCampo := ""
	Local cArquivo := ""
	Local cLeitura := ""
	Local cIndice := ""
	Local cConflito := ""
	Local aTabelas := {}
	Local aIndices := {}
	Local aCampos := {}
	Local nIndice := 0
	Local aChave := {}
	Local aLinhas := {}
	Local cErro := ""
	Local nCampo := 0
	Local nPosicao := 0
	Local nAtualizados := 0
	Local nIncluidos := 0
	Local nIgnorados := 0

	If !ACVEscolher("Selecione a operacao", "Funcionalidade", {"Atualizar campo", "Importar registros"}, @cModo)
		Return
	EndIf

	aTabelas := ACVTabelas()
	If Len(aTabelas) == 0
		MsgStop("Nenhuma tabela cadastrada no SX2.", "Atualizacao")
		Return
	EndIf
	If !ACVEscolher("Selecione a tabela", "Tabela (SX2)", aTabelas, @cTabela)
		Return
	EndIf
	ACVOpcTabela(cTabela, @aIndices, @aCampos)
	If Len(aIndices) == 0 .Or. Len(aCampos) == 0
		MsgStop("Tabela sem indices no SIX ou sem campos no SX3.", "Atualizacao")
		Return
	EndIf
	If !ACVEscolher("Indice da tabela " + cTabela, "Indice (SIX)", aIndices, @cIndice)
		Return
	EndIf
	If cModo == "Atualizar campo"
		If !ACVEscolher("Campo da tabela " + cTabela, "Campo (SX3)", aCampos, @cCampo)
			Return
		EndIf
	Else
		If !ACVEscolher("Tratamento para chave existente", "Ao encontrar registro", ;
			{"Ignorar linha", "Atualizar registro existente", "Cancelar importacao"}, @cConflito)
			Return
		EndIf
	EndIf
	nIndice := Val(cIndice)
	If !ACVConfig(cTabela, nIndice, cCampo, @aChave, @nCampo, @nPosicao, @cErro)
		MsgStop(cErro, "Atualizacao CSV")
		Return
	EndIf
	If !ACVSelecionarArquivo(@cArquivo)
		Return
	EndIf
	If !File(cArquivo) .Or. !(Upper(Right(cArquivo, 4)) == ".XLS" .Or. ;
		Upper(Right(cArquivo, 5)) == ".XLSX" .Or. Upper(Right(cArquivo, 4)) == ".CSV")
		MsgStop("Arquivo inexistente no AppServer ou formato invalido. Use XLS, XLSX ou CSV em pasta acessivel ao servidor.", "Validacao do arquivo")
		Return
	EndIf
	cLeitura := cArquivo
	If Upper(Right(cArquivo, 4)) == ".XLS" .Or. Upper(Right(cArquivo, 5)) == ".XLSX"
		Processa({|| ACVConverter(cArquivo, @cLeitura, @cErro)}, "Preparando planilha", "Convertendo Excel...", .F.)
		If !Empty(cErro)
			MsgStop(cErro, "Atualizacao")
			Return
		EndIf
	EndIf
	If cModo == "Atualizar campo"
		Processa({|| ACVLer(cLeitura, cTabela, cCampo, aChave, nCampo, .F., @aLinhas, @cErro)}, ;
			"Validando arquivo", "Conferindo registros...", .F.)
	Else
		Processa({|| ACVLerImportacao(cLeitura, cTabela, aChave, .F., @aLinhas, @cErro)}, ;
			"Validando arquivo", "Conferindo registros...", .F.)
	EndIf
	If !Empty(cErro)
		If cLeitura != cArquivo
			FErase(cLeitura)
		EndIf
		MsgStop(cErro, "Atualizacao")
		Return
	EndIf
	If cLeitura != cArquivo
		FErase(cLeitura)
	EndIf
	If cModo == "Atualizar campo"
		If !MsgYesNo("Arquivo validado: " + cArquivo + CRLF + ;
			"Tabela: " + cTabela + " | indice: " + AllTrim(Str(nIndice)) + ;
			" | campo: " + cCampo + CRLF + "Registros conferidos: " + AllTrim(Str(Len(aLinhas))) + ;
			CRLF + "Gravacao direta, sem validacoes da rotina padrao. Confirma?", "Atualizacao CSV")
			Return
		EndIf
		Processa({|| ACVGravar(cTabela, nIndice, nCampo, aChave, aLinhas, @nAtualizados, @cErro)}, ;
			"Atualizando registros", "Gravando dados...", .F.)
		If Empty(cErro)
			MsgInfo(AllTrim(Str(nAtualizados)) + " registros atualizados.", "Atualizacao CSV")
		Else
			MsgStop(cErro + ". Transacao cancelada.", "Atualizacao CSV")
		EndIf
	Else
		If !MsgYesNo("Arquivo validado: " + cArquivo + CRLF + ;
			"Tabela: " + cTabela + " | indice: " + AllTrim(Str(nIndice)) + CRLF + ;
			"Registros conferidos: " + AllTrim(Str(Len(aLinhas))) + CRLF + ;
			"Duplicidade: " + cConflito + CRLF + ;
			"Importacao direta, sem validacoes da rotina padrao. Confirma?", "Importacao CSV")
			Return
		EndIf
		Processa({|| ACVGravarImportacao(cTabela, nIndice, aChave, aLinhas, cConflito, ;
			@nIncluidos, @nAtualizados, @nIgnorados, @cErro)}, ;
			"Importando registros", "Gravando dados...", .F.)
		If Empty(cErro)
			MsgInfo(AllTrim(Str(nIncluidos)) + " incluidos, " + AllTrim(Str(nAtualizados)) + ;
				" atualizados e " + AllTrim(Str(nIgnorados)) + " ignorados.", "Importacao CSV")
		Else
			MsgStop(cErro + ". Transacao cancelada.", "Importacao CSV")
		EndIf
	EndIf

Return

Static Function ACVGravar(cTabela, nIndice, nCampo, aChave, aLinhas, nAtualizados, cErro)
	Local nPosicao := 0

	DbSelectArea(cTabela)
	DbSetOrder(nIndice)
	ProcRegua(Len(aLinhas))
	Begin Transaction
		For nPosicao := 1 To Len(aLinhas)
			If ACVBuscaStatus(aLinhas[nPosicao, 1], aChave) != 1
				cErro := "Chave ausente ou duplicada na linha " + AllTrim(Str(nPosicao + 1))
				DisarmTransaction()
				Exit
			EndIf
			If !RecLock(cTabela, .F.)
				cErro := "Falha ao bloquear a linha " + AllTrim(Str(nPosicao + 1))
				DisarmTransaction()
				Exit
			EndIf
			FieldPut(nCampo, aLinhas[nPosicao, 2])
			MsUnlock()
			nAtualizados++
			IncProc("Gravando registro " + AllTrim(Str(nPosicao)) + " de " + AllTrim(Str(Len(aLinhas))))
		Next
	End Transaction
	Return

Static Function ACVGravarImportacao(cTabela, nIndice, aChave, aLinhas, cConflito, ;
	nIncluidos, nAtualizados, nIgnorados, cErro)
	Local nPosicao := 0
	Local nStatus := 0
	Local nValor := 0
	Local nCampo := 0
	Local aValores := {}

	DbSelectArea(cTabela)
	DbSetOrder(nIndice)
	ProcRegua(Len(aLinhas))
	Begin Transaction
		For nPosicao := 1 To Len(aLinhas)
			nStatus := ACVBuscaStatus(aLinhas[nPosicao, 1], aChave)
			If nStatus == 2
				cErro := "Chave duplicada na tabela na linha " + AllTrim(Str(nPosicao + 1))
				DisarmTransaction()
				Exit
			EndIf
			If nStatus == 1 .And. cConflito == "Cancelar importacao"
				cErro := "Registro ja existente na linha " + AllTrim(Str(nPosicao + 1))
				DisarmTransaction()
				Exit
			EndIf
			If nStatus == 1 .And. cConflito == "Ignorar linha"
				nIgnorados++
			Else
				If nStatus == 1
					If !RecLock(cTabela, .F.)
						cErro := "Falha ao bloquear o registro da linha " + AllTrim(Str(nPosicao + 1))
						DisarmTransaction()
						Exit
					EndIf
				Else
					If !RecLock(cTabela, .T.)
						cErro := "Falha ao incluir o registro da linha " + AllTrim(Str(nPosicao + 1))
						DisarmTransaction()
						Exit
					EndIf
				EndIf
				aValores := aLinhas[nPosicao, 2]
				For nValor := 1 To Len(aValores)
					nCampo := aValores[nValor, 1]
					If nStatus == 0 .Or. AScan(aChave, FieldName(nCampo)) == 0
						FieldPut(nCampo, aValores[nValor, 2])
					EndIf
				Next
				MsUnlock()
				If nStatus == 1
					nAtualizados++
				Else
					nIncluidos++
				EndIf
			EndIf
			IncProc("Importando registro " + AllTrim(Str(nPosicao)) + " de " + AllTrim(Str(Len(aLinhas))))
		Next
	End Transaction
	Return

Static Function ACVTabelas()
	Local aTabelas := {}
	Local aAreaSX2 := SX2->(GetArea())

	SX2->(DbSetOrder(1))
	SX2->(DbGoTop())
	While !SX2->(Eof())
		If Len(AllTrim(SX2->X2_CHAVE)) == 3
			AAdd(aTabelas, AllTrim(SX2->X2_CHAVE))
		EndIf
		SX2->(DbSkip())
	EndDo
	SX2->(RestArea(aAreaSX2))
	Return aTabelas

Static Function ACVOpcTabela(cTabela, aIndices, aCampos)
	Local aAreaSIX := SIX->(GetArea())
	Local aAreaSX3 := SX3->(GetArea())

	aIndices := {}
	aCampos := {}
	SIX->(DbSetOrder(1))
	If SIX->(DbSeek(cTabela))
		While !SIX->(Eof()) .And. SIX->INDICE == cTabela
			AAdd(aIndices, AllTrim(SIX->ORDEM) + " - " + AllTrim(SIX->CHAVE))
			SIX->(DbSkip())
		EndDo
	EndIf
	SX3->(DbSetOrder(1))
	If SX3->(DbSeek(cTabela))
		While !SX3->(Eof()) .And. SX3->X3_ARQUIVO == cTabela
			AAdd(aCampos, AllTrim(SX3->X3_CAMPO))
			SX3->(DbSkip())
		EndDo
	EndIf
	SIX->(RestArea(aAreaSIX))
	SX3->(RestArea(aAreaSX3))
	Return

Static Function ACVEscolher(cTitulo, cRotulo, aOpcoes, cEscolha)
	Local oDlg := Nil
	Local oCombo := Nil
	Local lConfirmado := .F.

	cEscolha := aOpcoes[1]
	Define MsDialog oDlg From 0, 0 To 180, 650 Title cTitulo Pixel
	@ 010, 010 Say cRotulo Of oDlg Pixel
	@ 025, 010 MsComboBox oCombo Var cEscolha Items aOpcoes Size 285, 010 Of oDlg Pixel
	@ 058, 075 Button "Confirmar" Size 65, 14 Of oDlg Pixel Action (lConfirmado := .T., oDlg:End())
	@ 058, 160 Button "Cancelar" Size 65, 14 Of oDlg Pixel Action oDlg:End()
	Activate MsDialog oDlg Centered
	Return lConfirmado

Static Function ACVSelecionarArquivo(cArquivo)
	Local oWizard := Nil
	Local oGetArquivo := Nil
	Local lConfirmado := .F.
	Local cHeader := "Selecao da planilha"
	Local cMessage := "Selecione o arquivo para atualizacao/importacao."
	Local cText := "Informe um arquivo XLS, XLSX ou CSV acessivel ao AppServer."
	Private cACVFileImp := Space(255)

	Define Wizard oWizard ;
		Title "Selecione a planilha" ;
		Header cHeader ;
		Message cMessage ;
		Text cText ;
		Next {|| .T.} ;
		Finish {|| .F.}

	Create Panel oWizard ;
		Header cHeader ;
		Message cMessage ;
		Back {|| .F.} ;
		Next {|| !Empty(AllTrim(cACVFileImp)) .And. File(AllTrim(cACVFileImp))} ;
		Finish {|| .F.}

	@ 085, 005 Group To 113, 245 Prompt "Arquivo XLS, XLSX ou CSV:" Of oWizard:oMPanel[2] Pixel
	@ 095, 020 MsGet oGetArquivo Var cACVFileImp ;
		Valid(If(File(AllTrim(cACVFileImp)), .T., ;
			(Alert("O arquivo informado nao existe no AppServer."), .F.))) ;
		Size 212, 010 Of oWizard:oMPanel[2] F3 "DIR" Pixel

	Create Panel oWizard ;
		Header cHeader ;
		Message "Confirme o arquivo selecionado." ;
		Back {|| .T.} ;
		Next {|| .F.} ;
		Finish {|| lConfirmado := .T.}

	@ 020, 010 Say "Arquivo selecionado. Clique em Concluir." Of oWizard:oMPanel[3] Pixel

	Activate Wizard oWizard Centered
	cArquivo := AllTrim(cACVFileImp)
	Return lConfirmado .And. !Empty(cArquivo)

Static Function ACVConverter(cArquivo, cCSV, cErro)
	Local cDrive := ""
	Local cPasta := ""
	Local cNome := ""
	Local cExt := ""
	Local cPrefixo := ""
	Local cScript := ""
	Local cVBS := ""
	Local nRetorno := 0

	If !File(cArquivo)
		cErro := "Planilha nao acessivel ao AppServer. Use um caminho compartilhado com o SmartClient."
		Return .F.
	EndIf
	SplitPath(cArquivo, @cDrive, @cPasta, @cNome, @cExt)
	cPrefixo := cDrive + cPasta + "acv_" + DtoS(Date()) + StrTran(Time(), ":", "") + "_" + GetNextAlias()
	cVBS := cPrefixo + ".vbs"
	cCSV := cPrefixo + ".csv"
	If File(cVBS) .Or. File(cCSV)
		cErro := "Arquivo temporario ja existe; tente novamente."
		Return .F.
	EndIf
	cScript := 'On Error Resume Next' + CRLF
	cScript += 'Set excel = CreateObject("Excel.Application")' + CRLF
	cScript += 'If Err.Number <> 0 Then WScript.Quit 1' + CRLF
	cScript += 'excel.DisplayAlerts = False' + CRLF
	cScript += 'excel.AutomationSecurity = 3' + CRLF
	cScript += 'Err.Clear' + CRLF
	cScript += 'Set book = excel.Workbooks.Open(WScript.Arguments(0), 0, True)' + CRLF
	cScript += 'If Err.Number <> 0 Then excel.Quit: WScript.Quit 2' + CRLF
	cScript += 'Set sheet = book.Worksheets(1)' + CRLF
	cScript += 'Set output = CreateObject("ADODB.Stream")' + CRLF
	cScript += 'output.Type = 2: output.Charset = "windows-1252": output.Open' + CRLF
	cScript += 'lastRow = sheet.UsedRange.Row + sheet.UsedRange.Rows.Count - 1' + CRLF
	cScript += 'lastCol = sheet.UsedRange.Column + sheet.UsedRange.Columns.Count - 1' + CRLF
	cScript += 'Do While lastCol > 0' + CRLF
	cScript += '  If Len(Trim(sheet.Cells(1, lastCol).Text)) > 0 Then Exit Do' + CRLF
	cScript += '  lastCol = lastCol - 1' + CRLF
	cScript += 'Loop' + CRLF
	cScript += 'If lastCol = 0 Then book.Close False: excel.Quit: WScript.Quit 5' + CRLF
	cScript += 'For row = 1 To lastRow' + CRLF
	cScript += '  line = ""' + CRLF
	cScript += '  For col = 1 To lastCol' + CRLF
	cScript += '    value = sheet.Cells(row, col).Text' + CRLF
	cScript += '    If Err.Number <> 0 Or InStr(value, "###") > 0 Then book.Close False: excel.Quit: WScript.Quit 3' + CRLF
	cScript += '    value = Replace(Replace(value, vbCr, " "), vbLf, " ")' + CRLF
	cScript += '    If col > 1 Then line = line & ";"' + CRLF
	cScript += '    line = line & Chr(34) & Replace(value, Chr(34), Chr(34) & Chr(34)) & Chr(34)' + CRLF
	cScript += '  Next' + CRLF
	cScript += '  output.WriteText line & vbCrLf' + CRLF
	cScript += 'Next' + CRLF
	cScript += 'Err.Clear' + CRLF
	cScript += 'output.SaveToFile WScript.Arguments(1), 2' + CRLF
	cScript += 'If Err.Number <> 0 Then book.Close False: excel.Quit: WScript.Quit 4' + CRLF
	cScript += 'output.Close: book.Close False: excel.Quit' + CRLF
	If !MemoWrite(cVBS, cScript)
		cErro := "Sem permissao para criar temporarios na pasta da planilha."
		Return .F.
	EndIf
	nRetorno := WaitRun('cscript.exe //nologo "' + cVBS + '" "' + cArquivo + '" "' + cCSV + '"', 0)
	FErase(cVBS)
	If nRetorno != 0 .Or. !File(cCSV)
		If File(cCSV)
			FErase(cCSV)
		EndIf
		cErro := "Conversao falhou (" + AllTrim(Str(nRetorno)) + "). Exige Windows, Excel no SmartClient e pasta compartilhada gravavel."
		Return .F.
	EndIf
	Return .T.

Static Function ACVConfig(cTabela, nIndice, cCampo, aChave, nCampo, nPosicao, cErro)
	Local cExpressao := ""
	Local cCampoFilial := cTabela + "_FILIAL"
	Local nParte := 0
	Local aEstrutura := {}

	SX2->(DbSetOrder(1))
	If !SX2->(DbSeek(cTabela)) .Or. SX2->X2_CHAVE != cTabela
		cErro := "Tabela nao cadastrada no SX2."
		Return .F.
	EndIf
	If Select(cTabela) == 0
		ChkFile(cTabela, .F.)
	EndIf
	If Select(cTabela) == 0
		cErro := "Nao foi possivel abrir a tabela."
		Return .F.
	EndIf
	DbSelectArea(cTabela)
	aEstrutura := DbStruct()
	DbSetOrder(nIndice)
	cExpressao := Upper(StrTran(AllTrim(IndexKey()), " ", ""))
	If Empty(cExpressao)
		cErro := "Indice inexistente."
		Return .F.
	EndIf
	aChave := Separa(cExpressao, "+", .T.)
	If Len(aChave) < 2
		cErro := "Indice deve iniciar com " + cCampoFilial + " e conter campos de chave."
		Return .F.
	EndIf
	If aChave[1] != cCampoFilial .And. aChave[1] != SubStr(cTabela, 2, 2) + "_FILIAL"
		cErro := "Indice deve iniciar com o campo FILIAL da tabela."
		Return .F.
	EndIf
	For nParte := 1 To Len(aChave)
		nPosicao := FieldPos(aChave[nParte])
		If nPosicao == 0
			cErro := "Indice calculado ou nao textual nao suportado: " + aChave[nParte]
			Return .F.
		EndIf
		If aEstrutura[nPosicao, 2] != "C"
			cErro := "Indice calculado ou nao textual nao suportado: " + aChave[nParte]
			Return .F.
		EndIf
	Next
	If Empty(cCampo)
		Return .T.
	EndIf
	nCampo := FieldPos(cCampo)
	If nCampo == 0
		cErro := "Campo de destino nao encontrado na tabela."
		Return .F.
	EndIf
	If AScan(aChave, cCampo) > 0 .Or. cCampo == "D_E_L_E_T_"
		cErro := "Nao e permitido alterar a chave do indice ou campo de controle."
		Return .F.
	EndIf
	If !(aEstrutura[nCampo, 2] $ "CNDL")
		cErro := "Tipo de campo nao suportado (use C, N, D ou L)."
		Return .F.
	EndIf
	Return .T.

Static Function ACVLerImportacao(cArquivo, cTabela, aChave, lUTF8, aLinhas, cErro)
	Local aCabecalho := {}
	Local aMapeamento := {}
	Local aColunas := {}
	Local aValores := {}
	Local aVistas := {}
	Local aEstrutura := {}
	Local cLinha := ""
	Local cChave := ""
	Local cTexto := ""
	Local nLinha := 0
	Local nColuna := 0
	Local nParte := 0
	Local nCampo := 0
	Local nFilial := 0
	Local nColFilial := 0
	Local xValor := Nil

	If !File(cArquivo) .Or. Upper(Right(cArquivo, 4)) != ".CSV"
		cErro := "Selecione um arquivo CSV acessivel pelo AppServer."
		Return .F.
	EndIf
	If FT_FUSE(cArquivo) < 0
		cErro := "Nao foi possivel abrir o CSV."
		Return .F.
	EndIf
	FT_FGOTOP()
	DbSelectArea(cTabela)
	aEstrutura := DbStruct()
	nFilial := FieldPos(aChave[1])
	ProcRegua(FT_FLASTREC())
	While !FT_FEOF()
		nLinha++
		IncProc("Validando linha " + AllTrim(Str(nLinha)))
		cLinha := FT_FREADLN()
		If Len(cLinha) >= 1022
			cErro := "Linha excede o limite do leitor de texto: " + AllTrim(Str(nLinha))
			Exit
		EndIf
		If nLinha == 1 .And. Left(cLinha, 3) == Chr(239) + Chr(187) + Chr(191)
			cLinha := SubStr(cLinha, 4)
			lUTF8 := .T.
		EndIf
		If lUTF8
			cLinha := StrIConv(cLinha, "UTF-8", "CP1252")
			If ValType(cLinha) != "C" .Or. Empty(cLinha)
				cErro := "Falha ao converter UTF-8 na linha " + AllTrim(Str(nLinha))
				Exit
			EndIf
		EndIf
		aColunas := ACVColunas(cLinha)
		If Len(aColunas) == 0
			cErro := "CSV invalido na linha " + AllTrim(Str(nLinha))
			Exit
		EndIf
		If nLinha == 1
			For nColuna := 1 To Len(aColunas)
				AAdd(aCabecalho, Upper(AllTrim(aColunas[nColuna])))
			Next
			For nColuna := 1 To Len(aCabecalho)
				nCampo := FieldPos(aCabecalho[nColuna])
				If nCampo == 0 .Or. AScan(aCabecalho, aCabecalho[nColuna]) < nColuna .Or. ;
					aCabecalho[nColuna] == "D_E_L_E_T_" .Or. aCabecalho[nColuna] == "R_E_C_N_O_" .Or. ;
					aCabecalho[nColuna] == "R_E_C_D_E_L_"
					cErro := "Campo invalido ou repetido no cabecalho: " + aCabecalho[nColuna]
					Exit
				EndIf
				If !(aEstrutura[nCampo, 2] $ "CNDL")
					cErro := "Tipo nao suportado para importacao: " + aCabecalho[nColuna]
					Exit
				EndIf
				AAdd(aMapeamento, nCampo)
			Next
			If !Empty(cErro)
				Exit
			EndIf
			nColFilial := AScan(aCabecalho, aChave[1])
			For nParte := 2 To Len(aChave)
				If AScan(aCabecalho, aChave[nParte]) == 0
					cErro := "Coluna de chave ausente: " + aChave[nParte]
					Exit
				EndIf
			Next
			If !Empty(cErro)
				Exit
			EndIf
		Else
			If Len(aColunas) != Len(aCabecalho)
				cErro := "Numero de colunas incorreto na linha " + AllTrim(Str(nLinha))
				Exit
			EndIf
			aValores := {}
			For nColuna := 1 To Len(aColunas)
				nCampo := aMapeamento[nColuna]
				cTexto := aColunas[nColuna]
				If nCampo == nFilial
					cTexto := StrTran(cTexto, Chr(160), " ")
					If !Empty(AllTrim(xFilial(cTabela))) .And. !Empty(AllTrim(cTexto)) .And. ;
						AllTrim(cTexto) != AllTrim(xFilial(cTabela))
						cErro := "Filial diferente da filial atual na linha " + AllTrim(Str(nLinha))
						Exit
					EndIf
					cTexto := xFilial(cTabela)
				ElseIf AScan(aChave, aCabecalho[nColuna]) > 0
					cTexto := StrTran(cTexto, Chr(160), " ")
				EndIf
				If !ACVValor(cTexto, aEstrutura[nCampo], @xValor)
					cErro := "Valor invalido para " + aCabecalho[nColuna] + " na linha " + AllTrim(Str(nLinha))
					Exit
				EndIf
			AAdd(aValores, {nCampo, xValor})
			Next
			If !Empty(cErro)
				Exit
			EndIf
			If nColFilial == 0
				AAdd(aValores, {nFilial, xFilial(cTabela)})
			EndIf
			cChave := xFilial(cTabela)
			For nParte := 2 To Len(aChave)
				nColuna := AScan(aCabecalho, aChave[nParte])
				nCampo := FieldPos(aChave[nParte])
				cTexto := AllTrim(StrTran(aColunas[nColuna], Chr(160), " "))
				If Empty(cTexto) .Or. Len(cTexto) > aEstrutura[nCampo, 3]
					cErro := "Chave vazia ou longa na linha " + AllTrim(Str(nLinha))
					Exit
				EndIf
				cChave += PadR(cTexto, aEstrutura[nCampo, 3])
			Next
			If !Empty(cErro)
				Exit
			EndIf
			If AScan(aVistas, cChave) > 0
				cErro := "Chave repetida no CSV na linha " + AllTrim(Str(nLinha))
				Exit
			EndIf
			AAdd(aVistas, cChave)
			AAdd(aLinhas, {cChave, aValores})
		EndIf
		FT_FSKIP()
	EndDo
	FT_FUSE()
	If Empty(cErro) .And. Len(aLinhas) == 0
		cErro := "CSV sem registros para importar."
	EndIf
	Return Empty(cErro)

Static Function ACVLer(cArquivo, cTabela, cCampo, aChave, nCampo, lUTF8, aLinhas, cErro)
	Local aCabecalho := {}
	Local aColunas := {}
	Local aVistas := {}
	Local aEstrutura := {}
	Local cLinha := ""
	Local cChave := ""
	Local cParteChave := ""
	Local nLinha := 0
	Local nParte := 0
	Local nColuna := 0
	Local nColFilial := 0
	Local xValor := Nil

	If !File(cArquivo) .Or. Upper(Right(cArquivo, 4)) != ".CSV"
		cErro := "Selecione um arquivo CSV acessivel pelo AppServer."
		Return .F.
	EndIf
	If FT_FUSE(cArquivo) < 0
		cErro := "Nao foi possivel abrir o CSV."
		Return .F.
	EndIf
	FT_FGOTOP()
	DbSelectArea(cTabela)
	aEstrutura := DbStruct()
	ProcRegua(FT_FLASTREC())
	While !FT_FEOF()
		nLinha++
		IncProc("Validando linha " + AllTrim(Str(nLinha)))
		cLinha := FT_FREADLN()
		If Len(cLinha) >= 1022
			cErro := "Linha excede o limite do leitor de texto: " + AllTrim(Str(nLinha))
			Exit
		EndIf
		If nLinha == 1 .And. Left(cLinha, 3) == Chr(239) + Chr(187) + Chr(191)
			cLinha := SubStr(cLinha, 4)
			lUTF8 := .T.
		EndIf
		If lUTF8
			cLinha := StrIConv(cLinha, "UTF-8", "CP1252")
			If ValType(cLinha) != "C" .Or. Empty(cLinha)
				cErro := "Falha ao converter UTF-8 na linha " + AllTrim(Str(nLinha))
				Exit
			EndIf
		EndIf
		aColunas := ACVColunas(cLinha)
		If Len(aColunas) == 0
			cErro := "CSV invalido na linha " + AllTrim(Str(nLinha))
			Exit
		EndIf
		If nLinha == 1
			For nParte := 1 To Len(aColunas)
				AAdd(aCabecalho, Upper(AllTrim(aColunas[nParte])))
			Next
			nColFilial := AScan(aCabecalho, aChave[1])
			If Len(aCabecalho) != Len(aChave) + IIf(nColFilial > 0, 1, 0) .Or. ;
				AScan(aCabecalho, cCampo) == 0
				cErro := "Cabecalho: informe os campos do indice (filial opcional) e " + cCampo
				Exit
			EndIf
			For nParte := 2 To Len(aChave)
				If AScan(aCabecalho, aChave[nParte]) == 0
					cErro := "Coluna ausente: " + aChave[nParte]
					Exit
				EndIf
			Next
		Else
			If Len(aColunas) != Len(aCabecalho)
				cErro := "Numero de colunas incorreto na linha " + AllTrim(Str(nLinha))
				Exit
			EndIf
			If nColFilial > 0 .And. !Empty(AllTrim(xFilial(cTabela))) .And. ;
				!Empty(AllTrim(aColunas[nColFilial]))
				If AllTrim(StrTran(aColunas[nColFilial], Chr(160), " ")) != AllTrim(xFilial(cTabela))
					cErro := "Filial diferente da filial atual na linha " + AllTrim(Str(nLinha))
					Exit
				EndIf
			EndIf
			cChave := xFilial(cTabela)
			For nParte := 2 To Len(aChave)
				nColuna := AScan(aCabecalho, aChave[nParte])
				cParteChave := AllTrim(StrTran(aColunas[nColuna], Chr(160), " "))
				If Empty(cParteChave) .Or. Len(cParteChave) > aEstrutura[FieldPos(aChave[nParte]), 3]
					cErro := "Chave vazia ou longa na linha " + AllTrim(Str(nLinha))
					Exit
				EndIf
				cChave += PadR(cParteChave, aEstrutura[FieldPos(aChave[nParte]), 3])
			Next
			If !Empty(cErro)
				Exit
			EndIf
			If AScan(aVistas, cChave) > 0
				cErro := "Chave repetida no CSV na linha " + AllTrim(Str(nLinha))
				Exit
			EndIf
			If !ACVBuscaUnica(cChave, aChave)
				cErro := "Chave ausente ou duplicada na linha " + AllTrim(Str(nLinha))
				Exit
			EndIf
			nColuna := AScan(aCabecalho, cCampo)
			If aEstrutura[nCampo, 2] == "C" .And. Len(aColunas[nColuna]) > aEstrutura[nCampo, 3]
				cErro := cCampo + " na linha " + AllTrim(Str(nLinha)) + ": valor com " + ;
					AllTrim(Str(Len(aColunas[nColuna]))) + " caracteres; campo aceita " + ;
					AllTrim(Str(aEstrutura[nCampo, 3])) + "."
				Exit
			EndIf
			If !ACVValor(aColunas[nColuna], aEstrutura[nCampo], @xValor)
				cErro := "Valor invalido para " + cCampo + " (tipo " + ;
					aEstrutura[nCampo, 2] + ") na linha " + AllTrim(Str(nLinha))
				Exit
			EndIf
			AAdd(aVistas, cChave)
			AAdd(aLinhas, {cChave, xValor})
		EndIf
		FT_FSKIP()
	EndDo
	FT_FUSE()
	If Empty(cErro) .And. Len(aLinhas) == 0
		cErro := "CSV sem registros para atualizar."
	EndIf
	Return Empty(cErro)

Static Function ACVBuscaUnica(cChave, aChave)
	Return ACVBuscaStatus(cChave, aChave) == 1

Static Function ACVBuscaStatus(cChave, aChave)
	If !DbSeek(cChave)
		Return 0
	EndIf
	If ACVChaveAtual(aChave) != cChave
		Return 0
	EndIf
	DbSkip()
	If !Eof() .And. ACVChaveAtual(aChave) == cChave
		DbSeek(cChave)
		Return 2
	EndIf
	DbSeek(cChave)
	Return 1

Static Function ACVChaveAtual(aChave)
	Local cAtual := ""
	Local nParte := 0

	For nParte := 1 To Len(aChave)
		cAtual += FieldGet(FieldPos(aChave[nParte]))
	Next
	Return cAtual

Static Function ACVValor(cTexto, aCampo, xValor)
	Local cTipo := aCampo[2]
	Local cNumero := StrTran(AllTrim(cTexto), ",", ".")
	Local nIndice := 0
	Local nPontos := 0

	Do Case
	Case cTipo == "C"
		If Len(cTexto) > aCampo[3]
			Return .F.
		EndIf
		xValor := PadR(cTexto, aCampo[3])
	Case cTipo == "N"
		If Empty(cNumero)
			Return .F.
		EndIf
		For nIndice := 1 To Len(cNumero)
			If !(SubStr(cNumero, nIndice, 1) $ "0123456789.-+")
				Return .F.
			EndIf
			If SubStr(cNumero, nIndice, 1) == "."
				nPontos++
			ElseIf SubStr(cNumero, nIndice, 1) $ "+-" .And. nIndice != 1
				Return .F.
			EndIf
		Next
		If nPontos > 1 .Or. !(Right(cNumero, 1) $ "0123456789") .Or. ;
			(At(".", cNumero) > 0 .And. Len(cNumero) - At(".", cNumero) > aCampo[4])
			Return .F.
		EndIf
		xValor := Val(cNumero)
		If "*" $ Str(xValor, aCampo[3], aCampo[4])
			Return .F.
		EndIf
	Case cTipo == "D"
		If Len(AllTrim(cTexto)) != 8
			Return .F.
		EndIf
		xValor := StoD(AllTrim(cTexto))
		If DtoS(xValor) != AllTrim(cTexto)
			Return .F.
		EndIf
	Case cTipo == "L"
		If Upper(AllTrim(cTexto)) != "T" .And. Upper(AllTrim(cTexto)) != "F"
			Return .F.
		EndIf
		xValor := Upper(AllTrim(cTexto)) == "T"
	EndCase
	Return .T.

Static Function ACVColunas(cLinha)
	Local aColunas := {}
	Local cValor := ""
	Local cChar := ""
	Local nPosicao := 0
	Local lAspas := .F.

	For nPosicao := 1 To Len(cLinha)
		cChar := SubStr(cLinha, nPosicao, 1)
		Do Case
		Case cChar == '"' .And. lAspas .And. SubStr(cLinha, nPosicao + 1, 1) == '"'
			cValor += cChar
			nPosicao++
		Case cChar == '"'
			lAspas := !lAspas
		Case cChar == ";" .And. !lAspas
			AAdd(aColunas, cValor)
			cValor := ""
		Otherwise
			cValor += cChar
		EndCase
	Next
	If lAspas
		Return {}
	EndIf
	AAdd(aColunas, cValor)
	Return aColunas
