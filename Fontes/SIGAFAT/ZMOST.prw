#Include "Protheus.ch"
#Include "TopConn.ch"
#Include "prtopdef.ch"

#Define ZM_STATUS  1
#Define ZM_MSG     2
#Define ZM_CLIENT  3
#Define ZM_LOJA    4
#Define ZM_NOME    5
#Define ZM_REP     6
#Define ZM_REPNOM  7
#Define ZM_DOC     8
#Define ZM_SERIE   9
#Define ZM_ITEM   10
#Define ZM_PROD   11
#Define ZM_DESC   12
#Define ZM_UM     13
#Define ZM_SALDO  14
#Define ZM_ARMAZ  15
#Define ZM_QUANT  16
#Define ZM_DTDES  17
#Define ZM_CLASSE 18
#Define ZM_TES    19
#Define ZM_RETOR  20
#Define ZM_IDENT  21
#Define ZM_LOCAL  22
#Define ZM_LOTE   23
#Define ZM_PRECO  24
#Define ZM_RECNO  25
#Define ZM_MARCA  26
#Define ZM_QTSEL  27
#Define ZM_DEST   28
#Define ZM_EMIS   29
#Define ZM_INI    30
#Define ZM_FIM    31
#Define ZM_SA2COD 32
#Define ZM_SA2LOJA 33
#Define ZM_SA2MSG 34
#Define ZM_ORIGPED 35
#Define ZM_ORIGITEM 36
#Define ZM_G_DOC 1
#Define ZM_G_SERIE 2
#Define ZM_G_CLIENT 3
#Define ZM_G_LOJA 4
#Define ZM_G_FORNEC 5
#Define ZM_G_LOJAFOR 6
#Define ZM_G_PEDIDO 7
#Define ZM_G_ROWS 8
#Define ZM_G_DESCONT 9
#Define ZM_G_RENOVA 10
#Define ZM_LIMIT 20000
#Define ZM_INV_DOC 1
#Define ZM_INV_SERIE 2
#Define ZM_INV_EMIS 3
#Define ZM_INV_CLIENT 4
#Define ZM_INV_LOJA 5
#Define ZM_INV_NOME 6
#Define ZM_INV_REP 7
#Define ZM_INV_ITEMS 8
#Define ZM_INV_DESCONT 9
#Define ZM_INV_PENDING 10
#Define ZM_INV_SELECTED 11
#Define ZM_INV_ELIGIBLE 12
#Define ZM_INV_ROWS 13

User Function ZMOST()

	Local aArea     := GetArea()
	Local aSize     := {}
	Local oDlg      := Nil
	Local oLayer    := Nil
	Local cErro     := ""
	Local cEtapa    := "INICIO"
	Local bError    := ErrorBlock({|oErr| Break(oErr)})
	Local oError    := Nil

	Begin Sequence
		ConOut("[ZMOST][TELA] Inicio U_ZMOST; revisao=20261110-13")
		cEtapa := "DIMENSIONAR"
		aSize := MsAdvSize()
		If ValType(aSize) != "A"
			Break("MsAdvSize nao retornou as dimensoes da janela.")
		EndIf
		If Len(aSize) < 6
			Break("MsAdvSize retornou dimensoes incompletas.")
		EndIf
		If aSize[5] <= 0 .Or. aSize[6] <= 0
			Break("Area util da janela invalida.")
		EndIf
		ConOut("[ZMOST][TELA] Area util=" + cValToChar(aSize[5]) + "x" + cValToChar(aSize[6]))
		cEtapa := "CRIAR_JANELA"
		ConOut("[ZMOST][TELA] Etapa=" + cEtapa)
		Define MsDialog oDlg Title "Renovacao de Mostruarios" From 0, 0 To aSize[6], aSize[5] Pixel
		cEtapa := "ATIVAR_JANELA"
		ConOut("[ZMOST][TELA] Ativando janela")
		Activate MsDialog oDlg Centered On Init ZMBuild(oDlg, aSize, @oLayer)
	Recover Using oError
		cErro := "Etapa " + cEtapa + ": " + ZMError(oError)
		ConOut("[ZMOST][TELA] Falha: " + cErro)
	End Sequence
	RestArea(aArea)
	ErrorBlock(bError)
	If !Empty(cErro)
		MsgStop(cErro, "Renovacao de Mostruarios")
	EndIf

Return Nil

Static Function ZMBuild(oDlg, aSize, oLayer)

	Local aFiltro   := {}
	Local aState    := {{}, {}, .F., "Nenhuma consulta realizada.", {}, ""}
	Local aGets     := {}
	Local oTop      := Nil
	Local oBody     := Nil
	Local oBrowse   := Nil
	Local oResumo   := Nil
	Local oGet      := Nil
	Local oButton   := Nil
	Local oCheck    := LoadBitmap(Nil, "LBOK")
	Local oUncheck  := LoadBitmap(Nil, "LBNO")
	Local cContexto := ""
	Local cErro     := ""
	Local cEtapa    := "PREPARAR_FILTROS"
	Local nFiltros  := Min(70, Max(30, 30000 / aSize[6]))
	Local bError    := ErrorBlock({|oErr| Break(oErr)})
	Local oError    := Nil

	Begin Sequence
		ConOut("[ZMOST][TELA] Janela ativada; revisao=20261110-13")
		ConOut("[ZMOST][TELA] Etapa=" + cEtapa)
		aFiltro := ZMFilters()
		cContexto := "Empresa " + cEmpAnt + " | Filial " + cFilAnt + " | SIMULACAO"
		cEtapa := "CRIAR_LAYER"
		ConOut("[ZMOST][TELA] Etapa=" + cEtapa)
		oLayer := FWLayer():New()
		oLayer:Init(oDlg, .F.)
		ConOut("[ZMOST][TELA] FWLayer inicializado")
		oLayer:AddLine("FILTROS", nFiltros, .T.)
		oLayer:AddLine("ORIGENS", 100 - nFiltros, .F.)
		oLayer:AddCollumn("TOPO", 100, .T., "FILTROS")
		oLayer:AddCollumn("GRADE", 100, .F., "ORIGENS")
		oLayer:AddWindow("TOPO", "FILTRO", "Selecao", 100, .F., .F., , "FILTROS")
		oLayer:AddWindow("GRADE", "SALDOS", "Notas fiscais", 100, .F., .F., , "ORIGENS")
		oTop := oLayer:GetWinPanel("TOPO", "FILTRO", "FILTROS")
		oBody := oLayer:GetWinPanel("GRADE", "SALDOS", "ORIGENS")

		cEtapa := "CRIAR_CONTROLES"
		ConOut("[ZMOST][TELA] Etapa=" + cEtapa)
		@ 3, 6 Say cContexto Size 460, 9 Of oTop Pixel
		@ 19, 6 Say "Cliente" Size 40, 9 Of oTop Pixel
		@ 17, 47 MsGet oGet Var aFiltro[1] Picture "@!" Size 72, 12 Of oTop Pixel F3 "SA1"
		aAdd(aGets, oGet)
		@ 19, 125 Say "Loja" Size 28, 9 Of oTop Pixel
		@ 17, 155 MsGet oGet Var aFiltro[2] Picture "@!" Size 30, 12 Of oTop Pixel
		aAdd(aGets, oGet)
		@ 19, 215 Say "Representante" Size 65, 9 Of oTop Pixel
		@ 17, 285 MsGet oGet Var aFiltro[3] Picture "@!" Size 90, 12 Of oTop Pixel F3 "SA3"
		aAdd(aGets, oGet)
		@ 39, 6 Say "Nota" Size 40, 9 Of oTop Pixel
		@ 37, 47 MsGet oGet Var aFiltro[4] Picture "@!" Size 72, 12 Of oTop Pixel
		aAdd(aGets, oGet)
		@ 39, 125 Say "Serie" Size 28, 9 Of oTop Pixel
		@ 37, 155 MsGet oGet Var aFiltro[5] Picture "@!" Size 30, 12 Of oTop Pixel
		aAdd(aGets, oGet)
		@ 39, 215 Say "Produto" Size 65, 9 Of oTop Pixel
		@ 37, 285 MsGet oGet Var aFiltro[6] Picture "@!" Size 145, 12 Of oTop Pixel F3 "SB1"
		aAdd(aGets, oGet)
		@ 59, 6 Say "Inicio" Size 40, 9 Of oTop Pixel
		@ 57, 47 MsGet oGet Var aFiltro[7] Size 72, 12 Of oTop Pixel
		aAdd(aGets, oGet)
		@ 59, 125 Say "Referencia" Size 50, 9 Of oTop Pixel
		@ 57, 177 MsGet oGet Var aFiltro[8] Size 72, 12 Of oTop Pixel
		aAdd(aGets, oGet)
		@ 59, 263 Say "TES" Size 20, 9 Of oTop Pixel
		@ 57, 285 MsGet oGet Var aFiltro[9] Picture "@!" Size 30, 12 Of oTop Pixel F3 "SF4"
		aAdd(aGets, oGet)
		@ 57, 327 ComboBox oGet Var aFiltro[10] Items {"Todos", "Ativos", "Descontinuados"} Size 112, 12 Of oTop Pixel
		aAdd(aGets, oGet)
		@ 80, 6 Button oButton Prompt "Consultar" Size 65, 15 Of oTop Pixel Action ZMLoad(aFiltro, aState, oBrowse, oResumo) When !aState[3]
		@ 80, 77 Button oButton Prompt "Limpar" Size 55, 15 Of oTop Pixel Action ZMClear(aFiltro, aState, aGets, oBrowse, oResumo) When !aState[3]
		@ 80, 138 Button oButton Prompt "Detalhar" Size 65, 15 Of oTop Pixel Action ZMInvDtl(aState, oBrowse, oResumo, .F.) When !aState[3]
		@ 80, 209 Button oButton Prompt "Selecionar" Size 65, 15 Of oTop Pixel Action ZMInvDtl(aState, oBrowse, oResumo, .T.) When !aState[3]
		@ 80, 280 Button oButton Prompt "Renovar" Size 72, 15 Of oTop Pixel Action ZMProcess(aState, oBrowse, oResumo) When !aState[3]
		@ 105, 6 Say oResumo Prompt aState[4] Size 460, 10 Of oTop Pixel

		cEtapa := "CRIAR_GRADE"
		ConOut("[ZMOST][TELA] Etapa=" + cEtapa)
		cEtapa := "CRIAR_TCBROWSE"
		ConOut("[ZMOST][TELA] Etapa=" + cEtapa)
		oBrowse := TCBrowse():New(1, 1, aSize[5] - 25, Max(80, (aSize[6] * (100 - nFiltros) / 100) - 25),,,,oBody,,,,,,,,,,,,,,.T.)
		oBrowse:Align := 5
		oBrowse:SetArray(ZMInvData(aState))
		ZMInvCols(oBrowse, aState, oCheck, oUncheck)
		oBrowse:lAdjustColSize := .T.
		oBrowse:bHeaderClick := {|oObj, nCol| ZMInvHeader(aState, oBrowse, oResumo, nCol)}
		oBrowse:bLDblClick := {|| ZMInvBrowseDblClick(aState, oBrowse, oResumo)}
		ConOut("[ZMOST][TELA] TCBrowse configurado com colunas explicitas")
		oBrowse:lVScroll := .T.
		oBrowse:lHScroll := .T.
		cEtapa := "GRADE_PRONTA"
		ConOut("[ZMOST][TELA] Etapa=" + cEtapa)
		ConOut("[ZMOST][TELA] Cockpit pronto; revisao=20261110-13")
		ConOut("[ZMOST][CONSULTA] Carga inicial ao abrir")
		ZMLoad(aFiltro, aState, oBrowse, oResumo)
	Recover Using oError
		cErro := "Etapa " + cEtapa + ": " + ZMError(oError)
		ConOut("[ZMOST][TELA] Falha: " + cErro)
	End Sequence
	ErrorBlock(bError)
	If !Empty(cErro)
		MsgStop(cErro, "Renovacao de Mostruarios")
		oDlg:End()
	EndIf

Return Empty(cErro)

Static Function ZMInvData(aState)
Return IIf(Len(aState[5]) == 0, {ZMInvEmpty()}, aState[5])

Static Function ZMInvEmpty()
Return {"", "", StoD(""), "", "", "", "", 0, 0, 0, 0, 0, {}}

Static Function ZMInvVal(aState, nPos, nField)

	Local aInvoice := ZMInvEmpty()

	If nPos >= 1 .And. nPos <= Len(aState[5])
		aInvoice := aState[5, nPos]
	EndIf

Return aInvoice[nField]

Static Function ZMInvBuild(aState)

	Local aInvoices := {}
	Local aLine := {}
	Local aInvoice := {}
	Local aIndexes := {}
	Local nLine := 0
	Local nPos := 0

	For nLine := 1 To Len(aState[1])
		aLine := aState[1, nLine]
		nPos := AScan(aInvoices, {|aGroup| aGroup[ZM_INV_CLIENT] == aLine[ZM_CLIENT] .And. aGroup[ZM_INV_LOJA] == aLine[ZM_LOJA] .And. aGroup[ZM_INV_DOC] == aLine[ZM_DOC] .And. aGroup[ZM_INV_SERIE] == aLine[ZM_SERIE]})
		If nPos == 0
			aInvoice := {aLine[ZM_DOC], aLine[ZM_SERIE], aLine[ZM_EMIS], aLine[ZM_CLIENT], aLine[ZM_LOJA], aLine[ZM_NOME], aLine[ZM_REP], 0, 0, 0, 0, 0, {}}
			aAdd(aInvoices, aInvoice)
			nPos := Len(aInvoices)
		EndIf
		aInvoices[nPos, ZM_INV_ITEMS]++
		If aLine[ZM_CLASSE] == "DESCONTINUADO"
			aInvoices[nPos, ZM_INV_DESCONT]++
		EndIf
		If aLine[ZM_STATUS] == "PENDENTE"
			aInvoices[nPos, ZM_INV_PENDING]++
		Else
			aInvoices[nPos, ZM_INV_ELIGIBLE]++
		EndIf
		If aLine[ZM_MARCA]
			aInvoices[nPos, ZM_INV_SELECTED]++
		EndIf
		aIndexes := aInvoices[nPos, ZM_INV_ROWS]
		aAdd(aIndexes, nLine)
		aInvoices[nPos, ZM_INV_ROWS] := aIndexes
	Next nLine

Return aInvoices

Static Function ZMInvChecked(aState, nInvoicePos)

	Local aInvoice := ZMInvEmpty()

	If nInvoicePos < 1 .Or. nInvoicePos > Len(aState[5])
		Return .F.
	EndIf
	aInvoice := aState[5, nInvoicePos]

Return aInvoice[ZM_INV_ELIGIBLE] > 0 .And. aInvoice[ZM_INV_SELECTED] == aInvoice[ZM_INV_ELIGIBLE]

Static Function ZMInvSetLine(aState, nLine, lSelect)

	If nLine < 1 .Or. nLine > Len(aState[1]) .Or. aState[1, nLine, ZM_STATUS] == "PENDENTE"
		Return Nil
	EndIf
	If lSelect
		aState[1, nLine, ZM_MARCA] := .T.
		aState[1, nLine, ZM_QTSEL] := aState[1, nLine, ZM_SALDO]
		aState[1, nLine, ZM_DEST] := IIf(aState[1, nLine, ZM_CLASSE] == "DESCONTINUADO", "", "RENOVAR")
	Else
		aState[1, nLine, ZM_MARCA] := .F.
		aState[1, nLine, ZM_QTSEL] := 0
		aState[1, nLine, ZM_DEST] := ""
	EndIf

Return Nil

Static Function ZMInvSetInvoice(aState, nInvoicePos, lSelect)

	Local aRows := {}
	Local nRow := 0

	If nInvoicePos < 1 .Or. nInvoicePos > Len(aState[5])
		Return Nil
	EndIf
	aRows := aState[5, nInvoicePos, ZM_INV_ROWS]
	For nRow := 1 To Len(aRows)
		ZMInvSetLine(aState, aRows[nRow], lSelect)
	Next nRow

Return Nil

Static Function ZMInvAllChecked(aState)

	Local nInvoice := 0
	Local lFound := .F.

	For nInvoice := 1 To Len(aState[5])
		If aState[5, nInvoice, ZM_INV_ELIGIBLE] > 0
			lFound := .T.
			If !ZMInvChecked(aState, nInvoice)
				Return .F.
			EndIf
		EndIf
	Next nInvoice

Return lFound

Static Function ZMInvSetAll(aState, lSelect)

	Local nLine := 0

	For nLine := 1 To Len(aState[1])
		ZMInvSetLine(aState, nLine, lSelect)
	Next nLine

Return Nil

Static Function ZMInvRefresh(aState, oBrowse, oResumo)

	aState[5] := ZMInvBuild(aState)
	oBrowse:SetArray(ZMInvData(aState))
	oBrowse:Refresh()
	ZMResumo(aState, oResumo)

Return Nil

Static Function ZMInvFlip(aState, oBrowse, oResumo, nInvoicePos)

	ZMInvSetInvoice(aState, nInvoicePos, !ZMInvChecked(aState, nInvoicePos))
	ZMInvRefresh(aState, oBrowse, oResumo)

Return Nil

Static Function ZMInvToggleAll(aState, oBrowse, oResumo)

	Local lSelect := !ZMInvAllChecked(aState)

	ZMInvSetAll(aState, lSelect)
	ZMInvRefresh(aState, oBrowse, oResumo)

Return Nil

Static Function ZMInvHeader(aState, oBrowse, oResumo, nCol)

	ZMInvToggleAll(aState, oBrowse, oResumo)

Return Nil

Static Function ZMInvBrowseDblClick(aState, oBrowse, oResumo)

	If oBrowse:nColPos == 1
		ZMInvFlip(aState, oBrowse, oResumo, oBrowse:nAt)
	Else
		ZMInvDtl(aState, oBrowse, oResumo, .F.)
	EndIf

Return Nil

Static Function ZMTxtWid(xValue)

	Local cValue := ""

	If ValType(xValue) == "D"
		cValue := DtoC(xValue)
	Else
		cValue := AllTrim(cValToChar(xValue))
	EndIf

Return Len(cValue)

Static Function ZMColWid(cField, cHeader, nMinWidth)

	Local nWidth := nMinWidth

	If !Empty(cField)
		nWidth := Max(nWidth, TamSX3(cField)[1])
	EndIf

Return Max(nWidth, Len(cHeader))

Static Function ZMDataWid(aState, aMap, nField, cHeader)

	Local nWidth := Len(cHeader)
	Local nItem := 0
	Local nLine := 0

	For nItem := 1 To Len(aMap)
		nLine := aMap[nItem, 1]
		If nLine >= 1 .And. nLine <= Len(aState[1])
			nWidth := Max(nWidth, ZMTxtWid(aState[1, nLine, nField]))
		EndIf
	Next nItem

Return nWidth

Static Function ZMInvCols(oBrowse, aState, oCheck, oUncheck)

	oBrowse:AddColumn(TCColumn():New("Sel.", {|| IIf(ZMInvChecked(aState, oBrowse:nAt), oCheck, oUncheck)},,,,"CENTER", 16, .T., .F.))
	oBrowse:AddColumn(TCColumn():New("Nota", {|| ZMInvVal(aState, oBrowse:nAt, ZM_INV_DOC)},,,,"LEFT", ZMColWid("B6_DOC", "Nota", 0)))
	oBrowse:AddColumn(TCColumn():New("Serie", {|| ZMInvVal(aState, oBrowse:nAt, ZM_INV_SERIE)},,,,"LEFT", ZMColWid("B6_SERIE", "Serie", 0)))
	oBrowse:AddColumn(TCColumn():New("Emissao", {|| ZMInvVal(aState, oBrowse:nAt, ZM_INV_EMIS)},,,,"LEFT", ZMColWid("B6_EMISSAO", "Emissao", 10)))
	oBrowse:AddColumn(TCColumn():New("Cliente", {|| ZMInvVal(aState, oBrowse:nAt, ZM_INV_CLIENT)},,,,"LEFT", ZMColWid("B6_CLIFOR", "Cliente", 0)))
	oBrowse:AddColumn(TCColumn():New("Loja", {|| ZMInvVal(aState, oBrowse:nAt, ZM_INV_LOJA)},,,,"LEFT", ZMColWid("B6_LOJA", "Loja", 0)))
	oBrowse:AddColumn(TCColumn():New("Nome do cliente", {|| ZMInvVal(aState, oBrowse:nAt, ZM_INV_NOME)},,,,"LEFT", ZMColWid("A1_NOME", "Nome do cliente", 0)))
	oBrowse:AddColumn(TCColumn():New("Representante", {|| ZMInvVal(aState, oBrowse:nAt, ZM_INV_REP)},,,,"LEFT", ZMColWid("A3_COD", "Representante", 0)))
	oBrowse:AddColumn(TCColumn():New("Itens", {|| ZMInvVal(aState, oBrowse:nAt, ZM_INV_ITEMS)},,,,"RIGHT", ZMColWid("", "Itens", Len(cValToChar(ZM_LIMIT)))))
	oBrowse:AddColumn(TCColumn():New("Descontinuados", {|| ZMInvVal(aState, oBrowse:nAt, ZM_INV_DESCONT)},,,,"RIGHT", ZMColWid("", "Descontinuados", Len(cValToChar(ZM_LIMIT)))))
	oBrowse:AddColumn(TCColumn():New("Pendencias", {|| ZMInvVal(aState, oBrowse:nAt, ZM_INV_PENDING)},,,,"RIGHT", ZMColWid("", "Pendencias", Len(cValToChar(ZM_LIMIT)))))
	oBrowse:AddColumn(TCColumn():New("Selecionados", {|| ZMInvVal(aState, oBrowse:nAt, ZM_INV_SELECTED)},,,,"RIGHT", ZMColWid("", "Selecionados", Len(cValToChar(ZM_LIMIT)))))

Return Nil

Static Function ZMItemMap(aState, nInvoicePos)

	Local aMap := {}
	Local aIndexes := {}
	Local nIndex := 0

	If nInvoicePos < 1 .Or. nInvoicePos > Len(aState[5])
		Return aMap
	EndIf
	aIndexes := aState[5, nInvoicePos, ZM_INV_ROWS]
	For nIndex := 1 To Len(aIndexes)
		aAdd(aMap, {aIndexes[nIndex]})
	Next nIndex

Return aMap

Static Function ZMItemVal(aState, aMap, nPos, nField)

	Local aLine := ZMEmpty()
	Local nLine := 0

	If nPos >= 1 .And. nPos <= Len(aMap)
		nLine := aMap[nPos, 1]
		If nLine >= 1 .And. nLine <= Len(aState[1])
			aLine := aState[1, nLine]
		EndIf
	EndIf

Return aLine[nField]

Static Function ZMItemCols(oBrowse, aState, aMap)

	oBrowse:AddColumn(TCColumn():New("Item", {|| ZMItemVal(aState, aMap, oBrowse:nAt, ZM_ITEM)},,,,"LEFT", ZMColWid("D2_ITEM", "Item", 0)))
	oBrowse:AddColumn(TCColumn():New("Produto", {|| ZMItemVal(aState, aMap, oBrowse:nAt, ZM_PROD)},,,,"LEFT", ZMColWid("B1_COD", "Produto", 0)))
	oBrowse:AddColumn(TCColumn():New("Descricao", {|| ZMItemVal(aState, aMap, oBrowse:nAt, ZM_DESC)},,,,"LEFT", ZMColWid("B1_DESC", "Descricao", 0)))
	oBrowse:AddColumn(TCColumn():New("UM", {|| ZMItemVal(aState, aMap, oBrowse:nAt, ZM_UM)},,,,"LEFT", ZMColWid("B6_UM", "UM", 0)))
	oBrowse:AddColumn(TCColumn():New("Saldo", {|| ZMItemVal(aState, aMap, oBrowse:nAt, ZM_SALDO)},,,,"RIGHT", ZMColWid("B6_SALDO", "Saldo", 0)))
	oBrowse:AddColumn(TCColumn():New("Selecionada", {|| ZMItemVal(aState, aMap, oBrowse:nAt, ZM_QTSEL)},,,,"RIGHT", ZMColWid("B6_QUANT", "Selecionada", 0)))
	oBrowse:AddColumn(TCColumn():New("Classe", {|| ZMItemVal(aState, aMap, oBrowse:nAt, ZM_CLASSE)},,,,"LEFT", ZMColWid("", "Classe", Len("DESCONTINUADO"))))
	oBrowse:AddColumn(TCColumn():New("Situacao", {|| ZMItemVal(aState, aMap, oBrowse:nAt, ZM_STATUS)},,,,"LEFT", ZMColWid("", "Situacao", Len("PENDENTE"))))
	oBrowse:AddColumn(TCColumn():New("TES retorno", {|| ZMItemVal(aState, aMap, oBrowse:nAt, ZM_RETOR)},,,,"LEFT", ZMColWid("F4_CODIGO", "TES retorno", 0)))
	oBrowse:AddColumn(TCColumn():New("Destinacao", {|| ZMItemVal(aState, aMap, oBrowse:nAt, ZM_DEST)},,,,"LEFT", ZMColWid("", "Destinacao", Len("PENDENTE"))))
	oBrowse:AddColumn(TCColumn():New("Pendencias", {|| ZMItemVal(aState, aMap, oBrowse:nAt, ZM_MSG)},,,,"LEFT", ZMDataWid(aState, aMap, ZM_MSG, "Pendencias")))

Return Nil

Static Function ZMInvDtl(aState, oMainBrowse, oResumo, lAllowSelect)

	Local nInvoicePos := oMainBrowse:nAt
	Local aInvoice := {}
	Local aMap := {}
	Local oDlg := Nil
	Local oItems := Nil
	Local oButton := Nil
	Local cTitulo := ""
	Local nDlgW := 1120
	Local nDlgH := 440
	Local nW := 0
	Local nH := 0
	Local nBtnTop := 0
	Local nGridH := 0
	Local nCol := 0

	If aState[3] .Or. nInvoicePos < 1 .Or. nInvoicePos > Len(aState[5])
		Return Nil
	EndIf
	aInvoice := aState[5, nInvoicePos]
	aMap := ZMItemMap(aState, nInvoicePos)
	If Len(aMap) == 0
		Return Nil
	EndIf
	cTitulo := "Nota " + AllTrim(aInvoice[ZM_INV_DOC]) + "/" + AllTrim(aInvoice[ZM_INV_SERIE])
	nW := Int(nDlgW / 2)
	nH := Int((nDlgH - 30) / 2)
	nBtnTop := nH - 21
	nGridH := nBtnTop - 36
	Define MsDialog oDlg Title cTitulo From 0, 0 To nDlgH, nDlgW Pixel
	@ 4, 4 Say ("Cliente: " + AllTrim(aInvoice[ZM_INV_CLIENT]) + "/" + AllTrim(aInvoice[ZM_INV_LOJA]) + " - " + AllTrim(aInvoice[ZM_INV_NOME])) Size 540, 10 Of oDlg Pixel
	@ 16, 4 Say ("Emissao: " + DtoC(aInvoice[ZM_INV_EMIS]) + " | Representante: " + AllTrim(aInvoice[ZM_INV_REP])) Size 540, 10 Of oDlg Pixel
	oItems := TCBrowse():New(30, 4, nW - 12, nGridH,,,,oDlg,,,,,,,,,,,,,,.T.)
	oItems:lHScroll := .T.
	oItems:lVScroll := .T.
	oItems:SetArray(aMap)
	ZMItemCols(oItems, aState, aMap)
	oItems:lAdjustColSize := .T.
	oItems:bLDblClick := {|| ZMDetRow(aState, aMap[oItems:nAt, 1])}
	nCol := nW - 59
	@ nBtnTop, nCol Button oButton Prompt "Fechar" Size 55, 15 Of oDlg Pixel Action oDlg:End()
	If lAllowSelect
		nCol -= 80
		@ nBtnTop, nCol Button oButton Prompt "Selecionar item" Size 75, 15 Of oDlg Pixel Action ZMSelect(aState, aMap[oItems:nAt, 1], oResumo, oItems, oMainBrowse)
	EndIf
	nCol -= 70
	@ nBtnTop, nCol Button oButton Prompt "Detalhar item" Size 65, 15 Of oDlg Pixel Action ZMDetRow(aState, aMap[oItems:nAt, 1])
	Activate MsDialog oDlg Centered

Return Nil

Static Function ZMFilters()
Return {Space(TamSX3("A1_COD")[1]), Space(TamSX3("A1_LOJA")[1]), Space(TamSX3("A3_COD")[1]), Space(TamSX3("B6_DOC")[1]), Space(TamSX3("B6_SERIE")[1]), Space(TamSX3("B1_COD")[1]), StoD("19000101"), Date(), Space(TamSX3("F4_CODIGO")[1]), 1}

Static Function ZMB6Mode(dInicio, dFim)
Return dInicio == StoD("19000101") .And. dFim == Date()

Static Function ZMEmpty()
Return {"SEM DADOS", "", "", "", "", "", "", "", "", "", "", "", "", 0, 0, 0, StoD(""), "", "", "", "", "", "", 0, 0, .F., 0, "", StoD(""), StoD(""), StoD(""), "", "", "", "", ""}

Static Function ZMLoad(aFiltro, aState, oBrowse, oResumo)

	Local aResultado := {}
	Local cErro := ""
	Local cFiltros := ""
	Local cComparacao := ""
	Local bError := Nil
	Local oError := Nil

	If aState[3]
		Return Nil
	EndIf
	aState[3] := .T.
	aState[1] := {}
	aState[2] := {}
	aState[5] := {}
	oBrowse:SetArray(ZMInvData(aState))
	oBrowse:nAt := 1
	oBrowse:Refresh()
	oResumo:SetText("Apurando saldos...")
	cFiltros := "cliente=" + IIf(Empty(aFiltro[1]), "vazio", "preenchido")
	cFiltros += "; representante=" + IIf(Empty(aFiltro[3]), "vazio", "preenchido")
	cFiltros += "; nota=" + IIf(Empty(aFiltro[4]), "vazio", "preenchido")
	cFiltros += "; produto=" + IIf(Empty(aFiltro[6]), "vazio", "preenchido")
	cFiltros += "; TES=" + IIf(Empty(aFiltro[9]), "TODAS", AllTrim(aFiltro[9])) + "; periodo=" + DtoS(aFiltro[7]) + "-" + DtoS(aFiltro[8])
	cFiltros += "; modoSaldo=" + IIf(ZMB6Mode(aFiltro[7], aFiltro[8]), "B6_SALDO", "ESTCalcTerc")
	ConOut("[ZMOST][CONSULTA] Inicio; " + cFiltros)
	bError := ErrorBlock({|oErr| Break(oErr)})
	Begin Sequence
		MsAguarde({|| aResultado := ZMOSCON(AClone(aFiltro))}, "Apurando saldos em terceiros")
		If !aResultado[1]
			Break(aResultado[3])
		EndIf
		aState[1] := aResultado[2]
		aState[2] := AClone(aFiltro)
		aState[5] := ZMInvBuild(aState)
		aState[6] := aResultado[8]
	Recover Using oError
		cErro := ZMError(oError)
	End Sequence
	ErrorBlock(bError)
	aState[3] := .F.
	If !Empty(cErro)
		ConOut("[ZMOST][CONSULTA] Falha; " + cErro)
		aState[1] := {}
		aState[2] := {}
		aState[5] := {}
		aState[6] := ""
		oResumo:SetText("Consulta nao concluida. Nenhum resultado parcial aceito.")
		FWAlertError(cErro, "Consulta de mostruarios")
		Return Nil
	EndIf
	cComparacao := "ESTCalcTerc_pos=N/A; divergencias=N/A"
	If aResultado[8] == "ESTCalcTerc"
		cComparacao := "ESTCalcTerc_pos=" + cValToChar(aResultado[6]) + "; divergencias=" + cValToChar(aResultado[7])
	EndIf
	ConOut("[ZMOST][CONSULTA] Resultado; modoSaldo=" + aResultado[8] + "; candidatos=" + cValToChar(aResultado[4]) + "; B6_SALDO_pos=" + cValToChar(aResultado[5]) + "; " + cComparacao + "; itens=" + cValToChar(Len(aState[1])) + "; notas=" + cValToChar(Len(aState[5])))
	oBrowse:SetArray(ZMInvData(aState))
	oBrowse:nAt := 1
	oBrowse:Refresh()
	ZMResumo(aState, oResumo)

Return Nil

Static Function ZMClear(aFiltro, aState, aGets, oBrowse, oResumo)

	Local aNovo := ZMFilters()
	Local nCampo := 0

	If aState[3]
		Return Nil
	EndIf
	For nCampo := 1 To Len(aFiltro)
		aFiltro[nCampo] := aNovo[nCampo]
		aGets[nCampo]:Refresh()
	Next nCampo
	ZMLoad(aFiltro, aState, oBrowse, oResumo)

Return Nil

Static Function ZMResumo(aState, oResumo)

	Local nLinha := 0
	Local nPend := 0
	Local nDescont := 0
	Local nMarcados := 0
	Local cResumo := ""

	For nLinha := 1 To Len(aState[1])
		If aState[1, nLinha, ZM_STATUS] == "PENDENTE"
			nPend++
		EndIf
		If aState[1, nLinha, ZM_CLASSE] == "DESCONTINUADO"
			nDescont++
		EndIf
		If aState[1, nLinha, ZM_MARCA]
			nMarcados++
		EndIf
	Next nLinha
	cResumo := "Notas: " + cValToChar(Len(aState[5])) + " | Itens: " + cValToChar(Len(aState[1])) + " | Descontinuados: " + cValToChar(nDescont)
	cResumo += " | Pendencias: " + cValToChar(nPend) + " | Selecionados: " + cValToChar(nMarcados)
	If !Empty(aState[6])
		cResumo += " | Saldo: " + aState[6]
	EndIf
	If Len(aState[2]) > 0
		cResumo += " | Ref.: " + DtoC(aState[2, 8])
	EndIf
	aState[4] := cResumo
	oResumo:SetText(cResumo)

Return Nil

Static Function ZMSelect(aState, nPos, oResumo, oItemBrowse, oMainBrowse)

	Local oDlg := Nil
	Local oGet := Nil
	Local oButton := Nil
	Local nQtd := 0
	Local nDest := 1
	Local aOpcoes := {"Renovar"}
	Local lSeleciona := .T.
	Local lConfirma := .F.
	Local cErro := ""

	If aState[3] .Or. nPos < 1 .Or. nPos > Len(aState[1])
		Return Nil
	EndIf
	If aState[1, nPos, ZM_STATUS] == "PENDENTE"
		FWAlertInfo(aState[1, nPos, ZM_MSG], "Origem com pendencias")
		Return Nil
	EndIf
	nQtd := aState[1, nPos, ZM_SALDO]
	If aState[1, nPos, ZM_MARCA]
		nQtd := aState[1, nPos, ZM_QTSEL]
	EndIf
	If aState[1, nPos, ZM_CLASSE] == "DESCONTINUADO"
		aOpcoes := {"Pendente", "Renovar", "Faturar"}
		nDest := AScan({"", "RENOVAR", "FATURAR"}, aState[1, nPos, ZM_DEST])
		If nDest == 0
			nDest := 1
		EndIf
	EndIf
	Define MsDialog oDlg Title "Selecao do item" From 0, 0 To 260, 650 Pixel
	@ 8, 8 Say (AllTrim(aState[1, nPos, ZM_PROD]) + " - " + Left(aState[1, nPos, ZM_DESC], 34)) Size 305, 10 Of oDlg Pixel
	@ 25, 8 CheckBox oGet Var lSeleciona Prompt "Selecionado" Size 100, 12 Of oDlg Pixel
	@ 45, 8 Say "Quantidade" Size 65, 10 Of oDlg Pixel
	@ 43, 80 MsGet oGet Var nQtd Picture PesqPict("SB6", "B6_QUANT") Size 100, 12 Of oDlg Pixel
	@ 65, 8 Say "Destinacao" Size 65, 10 Of oDlg Pixel
	@ 63, 80 ComboBox oGet Var nDest Items aOpcoes Size 120, 12 Of oDlg Pixel
	@ 94, 175 Button oButton Prompt "Confirmar" Size 65, 15 Of oDlg Pixel Action (lConfirma := .T., oDlg:End())
	@ 94, 245 Button oButton Prompt "Cancelar" Size 65, 15 Of oDlg Pixel Action oDlg:End()
	Activate MsDialog oDlg Centered
	If !lConfirma
		Return Nil
	EndIf
	If lSeleciona
		cErro := ZMQty(nQtd, aState[1, nPos, ZM_SALDO], TamSX3("B6_QUANT")[2])
		If !Empty(cErro)
			FWAlertError(cErro, "Quantidade invalida")
			Return Nil
		EndIf
	EndIf
	aState[1, nPos, ZM_MARCA] := lSeleciona
	aState[1, nPos, ZM_QTSEL] := IIf(lSeleciona, nQtd, 0)
	aState[1, nPos, ZM_DEST] := ""
	If lSeleciona
		If aState[1, nPos, ZM_CLASSE] == "DESCONTINUADO"
			If nDest > 1
				aState[1, nPos, ZM_DEST] := Upper(aOpcoes[nDest])
			EndIf
		Else
			aState[1, nPos, ZM_DEST] := "RENOVAR"
		EndIf
	EndIf
	oItemBrowse:Refresh()
	aState[5] := ZMInvBuild(aState)
	oMainBrowse:SetArray(ZMInvData(aState))
	oMainBrowse:Refresh()
	ZMResumo(aState, oResumo)

Return Nil

Static Function ZMQty(nQtd, nSaldo, nDec)

	If ValType(nQtd) != "N" .Or. ValType(nSaldo) != "N" .Or. ValType(nDec) != "N"
		Return "Quantidade, saldo e casas decimais devem ser numericos."
	EndIf
	If nQtd <= 0 .Or. nQtd > nSaldo
		Return "A quantidade deve ser positiva e nao pode exceder o saldo calculado."
	EndIf
	If Abs(nQtd - Round(nQtd, nDec)) > 0.0000001
		Return "Quantidade com mais casas decimais que o dicionario permite."
	EndIf

Return ""

Static Function ZMProcess(aState, oBrowse, oResumo)

	Local aAgrupamento := {}
	Local aGrupos := {}
	Local aGrupo := {}
	Local aSelecionados := {}
	Local aEtapas := {}
	Local aPerguntas := {}
	Local aResposta := {}
	Local aResultado := {.F., "Nenhuma etapa executada.", "", "", .F., ""}
	Local oDlg := Nil
	Local oSay := Nil
	Local oButton := Nil
	Local cErro := ""
	Local cSerieSaida := ""
	Local cModo := ""
	Local dEntrega := Date()
	Local nGrupo := 0
	Local nItens := 0
	Local lVendaPendente := .F.
	Local lConsolidado := .F.
	Local bError := ErrorBlock({|oErr| Break(oErr)})

	If aState[3] .Or. Len(aState[2]) != 10
		Return Nil
	EndIf
	If aState[6] != "B6_SALDO"
		FWAlertError("A efetivacao exige consulta de saldo atual B6_SALDO, nao um periodo historico ESTCalcTerc.", "Renovacao")
		Return Nil
	EndIf
	aAgrupamento := ZMGrpSel(aState, .F.)
	If !aAgrupamento[1]
		ErrorBlock(bError)
		FWAlertError(aAgrupamento[3], "Renovacao nao iniciada")
		Return Nil
	EndIf
	aGrupos := aAgrupamento[2]
	If Len(aGrupos) > 1
		aPerguntas := {}
		aResposta := {}
		aAdd(aPerguntas, {2, "Processamento", 1, {"Individual (nota a nota)", "Consolidado"}, 90, "", .T.})
		If !ParamBox(aPerguntas, "Modo de processamento", @aResposta)
			ErrorBlock(bError)
			Return Nil
		EndIf
		cModo := Upper(AllTrim(cValToChar(aResposta[1])))
		ConOut("[ZMOST][PROCESSO] ParamBox modo; tipo=" + ValType(aResposta[1]) + "; valor=" + cModo)
		If cModo == "1" .Or. cModo == "INDIVIDUAL (NOTA A NOTA)"
			lConsolidado := .F.
		ElseIf cModo == "2" .Or. cModo == "CONSOLIDADO"
			lConsolidado := .T.
		Else
			ErrorBlock(bError)
			FWAlertError("Modo de processamento invalido.", "Renovacao")
			Return Nil
		EndIf
		If lConsolidado
			aAgrupamento := ZMGrpSel(aState, .T.)
			If !aAgrupamento[1]
				ErrorBlock(bError)
				FWAlertError(aAgrupamento[3], "Consolidacao nao iniciada")
				Return Nil
			EndIf
			aGrupos := aAgrupamento[2]
		EndIf
	EndIf
	For nGrupo := 1 To Len(aGrupos)
		aGrupo := aGrupos[nGrupo]
		aGrupo[ZM_G_RENOVA] := .T.
		If aGrupo[ZM_G_DESCONT]
			ConOut("[ZMOST][PROCESSO] Confirmacao de descontinuados antes; nota=" + AllTrim(aGrupo[ZM_G_DOC]) + "/" + AllTrim(aGrupo[ZM_G_SERIE]))
			aGrupo[ZM_G_RENOVA] := FWAlertYesNo("Nota " + AllTrim(aGrupo[ZM_G_DOC]) + "/" + AllTrim(aGrupo[ZM_G_SERIE]) + " contem itens descontinuados." + CRLF + ;
				"Sim: renovar a nota inteira, inclusive os descontinuados." + CRLF + ;
				"Nao: vender os descontinuados e renovar os itens liberados.", "Destino dos descontinuados")
			ConOut("[ZMOST][PROCESSO] Confirmacao de descontinuados depois; renovar=" + cValToChar(aGrupo[ZM_G_RENOVA]))
		EndIf
		If !aGrupo[ZM_G_RENOVA]
			lVendaPendente := .T.
		EndIf
		aGrupos[nGrupo] := aGrupo
	Next nGrupo
	If lVendaPendente
		ErrorBlock(bError)
		FWAlertInfo("O lote inclui venda de itens descontinuados. TES comercial, preco e condicao devem ser homologados antes; nenhum documento foi criado.", "Configuracao comercial pendente")
		Return Nil
	EndIf
	If !("TEST" $ Upper(GetEnvServer())) .And. !("HOMOLOG" $ Upper(GetEnvServer()))
		ErrorBlock(bError)
		FWAlertError("A emissao fiscal do ZMOST esta restrita a ambiente de teste/homologacao.", "Renovacao")
		Return Nil
	EndIf
	aPerguntas := {}
	aResposta := {}
	aAdd(aPerguntas, {1, "Serie da NF de saida", Space(TamSX3("F2_SERIE")[1]), "@!", "", "", "", 60, .T.})
	aAdd(aPerguntas, {1, "Data prevista de entrega", Date(), "", "", "", "", 70, .T.})
	ConOut("[ZMOST][PROCESSO] ParamBox de faturamento antes")
	If !ParamBox(aPerguntas, "Parametros do faturamento", @aResposta)
		ConOut("[ZMOST][PROCESSO] ParamBox de faturamento cancelado")
		ErrorBlock(bError)
		Return Nil
	EndIf
	cSerieSaida := Upper(AllTrim(aResposta[1]))
	dEntrega := aResposta[2]
	ConOut("[ZMOST][PROCESSO] ParamBox de faturamento depois; serie=" + cSerieSaida + "; tipoEntrega=" + ValType(dEntrega))
	If Empty(cSerieSaida) .Or. Len(cSerieSaida) > TamSX3("F2_SERIE")[1] .Or. ValType(dEntrega) != "D" .Or. Empty(dEntrega)
		ErrorBlock(bError)
		FWAlertError("Informe uma serie fiscal valida e uma data prevista de entrega.", "Renovacao")
		Return Nil
	EndIf
	ConOut("[ZMOST][PROCESSO] Pergunte MT460A antes")
	If !Pergunte("MT460A", .T.)
		ConOut("[ZMOST][PROCESSO] Pergunte MT460A cancelado")
		ErrorBlock(bError)
		FWAlertInfo("Parametros de faturamento cancelados. Nenhum documento foi criado.", "Renovacao")
		Return Nil
	EndIf
	ConOut("[ZMOST][PROCESSO] Pergunte MT460A depois")
	For nGrupo := 1 To Len(aGrupos)
		aGrupo := aGrupos[nGrupo]
		aSelecionados := aGrupo[ZM_G_ROWS]
		For nItens := 1 To Len(aSelecionados)
			aState[1, aSelecionados[nItens], ZM_DEST] := ZMModeDest(aState[1, aSelecionados[nItens], ZM_CLASSE], aGrupo[ZM_G_RENOVA])
		Next nItens
	Next nGrupo
	nItens := 0
	For nGrupo := 1 To Len(aGrupos)
		nItens += Len(aGrupos[nGrupo, ZM_G_ROWS])
	Next nGrupo
	ConOut("[ZMOST][PROCESSO] Confirmacao final antes")
	If !FWAlertYesNo("Processamento " + IIf(lConsolidado, "consolidado", "individual nota a nota") + ": " + cValToChar(Len(aGrupos)) + " documento(s), " + cValToChar(nItens) + " item(ns), liberar pedidos e emitir as notas de saida na serie " + cSerieSaida + "?" + CRLF + ;
		"A autorizacao/transmissao da NF-e continua no AUTONFE padrao.", "Confirmar renovacao")
		ConOut("[ZMOST][PROCESSO] Confirmacao final recusada")
		ErrorBlock(bError)
		Return Nil
	EndIf
	ConOut("[ZMOST][PROCESSO] Confirmacao final aceita; abrindo acompanhamento")

	Define MsDialog oDlg Title "Acompanhamento da renovacao" From 0, 0 To 265, 660 Pixel
	ConOut("[ZMOST][PROCESSO] Acompanhamento aberto; lote iniciara automaticamente")
	@ 6, 8 Say oSay Prompt "1. Validacao: aguardando" Size 620, 12 Of oDlg Pixel
	aAdd(aEtapas, oSay)
	@ 18, 8 Say oSay Prompt "2. Entrada MATA103: aguardando" Size 620, 12 Of oDlg Pixel
	aAdd(aEtapas, oSay)
	@ 30, 8 Say oSay Prompt "3. Conferencia SF1/SD1: aguardando" Size 620, 12 Of oDlg Pixel
	aAdd(aEtapas, oSay)
	@ 42, 8 Say oSay Prompt "4. Pedido MATA410: aguardando" Size 620, 12 Of oDlg Pixel
	aAdd(aEtapas, oSay)
	@ 54, 8 Say oSay Prompt "5. Conferencia SC5/SC6: aguardando" Size 620, 12 Of oDlg Pixel
	aAdd(aEtapas, oSay)
	@ 66, 8 Say oSay Prompt "6. Liberacao MaLibDoFat/SC9: aguardando" Size 620, 12 Of oDlg Pixel
	aAdd(aEtapas, oSay)
	@ 78, 8 Say oSay Prompt "7. Faturamento MATA461: aguardando" Size 620, 12 Of oDlg Pixel
	aAdd(aEtapas, oSay)
	@ 90, 8 Say oSay Prompt "8. Conferencia SF2/SD2: aguardando" Size 620, 12 Of oDlg Pixel
	aAdd(aEtapas, oSay)
	@ 104, 8 Say oSay Prompt "Transmissao NF-e pelo AUTONFE padrao." Size 450, 16 Of oDlg Pixel
	aAdd(aEtapas, oSay)
	@ 104, 565 Button oButton Prompt "Fechar" Size 65, 15 Of oDlg Pixel Action oDlg:End() When !aState[3]
	ConOut("[ZMOST][PROCESSO] Controles do acompanhamento criados")
	aState[3] := .T.
	Activate MsDialog oDlg Centered On Init ZMRunBatch(aState, aGrupos, aEtapas, oDlg, @aResultado, cSerieSaida, dEntrega)
	ConOut("[ZMOST][PROCESSO] Acompanhamento fechado")
	aState[3] := .F.
	If aResultado[5] .And. Len(aState[2]) == 10
		ZMLoad(AClone(aState[2]), aState, oBrowse, oResumo)
	EndIf
	If !Empty(cErro)
		ConOut("[ZMOST][PROCESSO] Falha no acionamento: " + cErro)
	EndIf

Return Nil

Static Function ZMGrpSel(aState, lConsolidado)

	Local aGrupos := {}
	Local aGrupo := {}
	Local aLinha := {}
	Local aRows := {}
	Local aVistas := {}
	Local aObs := {}
	Local nLinha := 0
	Local nItem := 0
	Local nGrupo := 0
	Local nOrigem := 0
	Local nSelOrigem := 0
	Local cErro := ""
	Local lVista := .F.

	Default lConsolidado := .F.

	For nLinha := 1 To Len(aState[1])
		aLinha := aState[1, nLinha]
		If !aLinha[ZM_MARCA]
			Loop
		EndIf
		If aLinha[ZM_STATUS] != "CONFERIR" .Or. !Empty(aLinha[ZM_SA2MSG])
			Return {.F., {}, "Selecione somente itens sem pendencias e com fornecedor SA2 ativo."}
		EndIf
		If !Empty(ZMQty(aLinha[ZM_QTSEL], aLinha[ZM_SALDO], TamSX3("B6_QUANT")[2]))
			Return {.F., {}, "Ha quantidade selecionada invalida."}
		EndIf
		If Abs(aLinha[ZM_QTSEL] - aLinha[ZM_ARMAZ]) > 0.000001
			Return {.F., {}, "A primeira renovacao exige saldo atual integral em cada item; atualize a consulta."}
		EndIf
		If Empty(aLinha[ZM_ORIGPED]) .Or. Empty(aLinha[ZM_ORIGITEM]) .Or. Empty(aLinha[ZM_ITEM]) .Or. Empty(aLinha[ZM_IDENT]) .Or. aLinha[ZM_PRECO] <= 0
			Return {.F., {}, "Origem sem pedido, item, identificador ou preco validos."}
		EndIf
		If lConsolidado
			nGrupo := IIf(Len(aGrupos) > 0, 1, 0)
		Else
			nGrupo := AScan(aGrupos, {|aItem| aItem[ZM_G_DOC] == aLinha[ZM_DOC] .And. aItem[ZM_G_SERIE] == aLinha[ZM_SERIE] .And. aItem[ZM_G_CLIENT] == aLinha[ZM_CLIENT] .And. aItem[ZM_G_LOJA] == aLinha[ZM_LOJA]})
		EndIf
		If nGrupo == 0
			aGrupo := {aLinha[ZM_DOC], aLinha[ZM_SERIE], aLinha[ZM_CLIENT], aLinha[ZM_LOJA], aLinha[ZM_SA2COD], aLinha[ZM_SA2LOJA], aLinha[ZM_ORIGPED], {}, .F., .T.}
			aAdd(aGrupos, aGrupo)
			nGrupo := Len(aGrupos)
		Else
			aGrupo := aGrupos[nGrupo]
			If aLinha[ZM_CLIENT] != aGrupo[ZM_G_CLIENT] .Or. aLinha[ZM_LOJA] != aGrupo[ZM_G_LOJA] .Or. ;
				aLinha[ZM_SA2COD] != aGrupo[ZM_G_FORNEC] .Or. aLinha[ZM_SA2LOJA] != aGrupo[ZM_G_LOJAFOR]
				Return {.F., {}, "As origens selecionadas possuem cliente/loja ou fornecedor/loja incompatíveis; processe nota a nota."}
			EndIf
			If !ZMSeriesOK(aLinha[ZM_SERIE], aGrupo[ZM_G_SERIE], lConsolidado)
				Return {.F., {}, "As origens selecionadas possuem series diferentes; processe nota a nota."}
			EndIf
			If !lConsolidado .And. aLinha[ZM_ORIGPED] != aGrupo[ZM_G_PEDIDO]
				Return {.F., {}, "Uma nota de origem aponta para mais de um pedido original; separar para analise fiscal."}
			EndIf
		EndIf
		If aLinha[ZM_CLASSE] == "DESCONTINUADO"
			aGrupo[ZM_G_DESCONT] := .T.
		EndIf
		aRows := aGrupo[ZM_G_ROWS]
		aAdd(aRows, nLinha)
		aGrupo[ZM_G_ROWS] := aRows
		aGrupos[nGrupo] := aGrupo
	Next nLinha
	If Len(aGrupos) == 0
		Return {.F., {}, "Nenhum item selecionado para renovacao."}
	EndIf
	For nGrupo := 1 To Len(aGrupos)
		aGrupo := aGrupos[nGrupo]
		aVistas := {}
		For nItem := 1 To Len(aGrupo[ZM_G_ROWS])
			aLinha := aState[1, aGrupo[ZM_G_ROWS, nItem]]
			lVista := AScan(aVistas, {|aOrigem| aOrigem[1] == aLinha[ZM_DOC] .And. aOrigem[2] == aLinha[ZM_SERIE]}) > 0
			If lVista
				Loop
			EndIf
			aAdd(aVistas, {aLinha[ZM_DOC], aLinha[ZM_SERIE]})
			nOrigem := 0
			nSelOrigem := 0
			For nLinha := 1 To Len(aState[1])
				aLinha := aState[1, nLinha]
				If aLinha[ZM_DOC] == aVistas[Len(aVistas), 1] .And. aLinha[ZM_SERIE] == aVistas[Len(aVistas), 2] .And. ;
					aLinha[ZM_CLIENT] == aGrupo[ZM_G_CLIENT] .And. aLinha[ZM_LOJA] == aGrupo[ZM_G_LOJA]
					nOrigem++
					If !aLinha[ZM_MARCA] .Or. aLinha[ZM_STATUS] != "CONFERIR"
						cErro := "Nota " + AllTrim(aLinha[ZM_DOC]) + "/" + AllTrim(aLinha[ZM_SERIE]) + " incompleta ou com pendencias; nenhum documento foi criado."
						Return {.F., {}, cErro}
					EndIf
					nSelOrigem++
				EndIf
			Next nLinha
			If nOrigem == 0 .Or. nOrigem != nSelOrigem
				Return {.F., {}, "Selecione todos os itens de cada nota de origem antes de processar."}
			EndIf
		Next nItem
		If lConsolidado
			cErro := ZMOrdComp(aState, aGrupo[ZM_G_ROWS])
			If !Empty(cErro)
				Return {.F., {}, cErro}
			EndIf
		EndIf
		aObs := ZMOrigObs(aState, aGrupo[ZM_G_ROWS])
		If !Empty(aObs[2])
			Return {.F., {}, aObs[2]}
		EndIf
	Next nGrupo

Return {.T., aGrupos, ""}

Static Function ZMOrdComp(aState, aSelecionados)

	Local aPedidos := {}
	Local aCabBase := {}
	Local aCamposComp := {"C5_CLIENTE", "C5_LOJACLI", "C5_LOJAENT", "C5_CONDPAG", "C5_TPFRETE", "C5_MOEDA", "C5_TABELA"}
	Local aRows := {}
	Local aLinha := {}
	Local cQuery := ""
	Local cPedido := ""
	Local nItem := 0
	Local nCampo := 0

	ConOut("[ZMOST][PROCESSO] ZMOrdComp; C5_VEND1/C5_TRANSP nao bloqueiam consolidacao; cabecalho mantem valores do primeiro pedido.")
	For nItem := 1 To Len(aSelecionados)
		aLinha := aState[1, aSelecionados[nItem]]
		cPedido := AllTrim(aLinha[ZM_ORIGPED])
		If AScan(aPedidos, {|cOrigem| cOrigem == cPedido}) > 0
			Loop
		EndIf
		cQuery := "SELECT C5_CLIENTE, C5_LOJACLI, C5_LOJAENT, C5_CONDPAG, C5_TPFRETE, C5_MOEDA, C5_TABELA FROM " + RetSqlName("SC5")
		cQuery += " WHERE C5_FILIAL = " + ZMSql(xFilial("SC5")) + " AND C5_NUM = " + ZMSql(cPedido) + " AND D_E_L_E_T_ = ' '
		ConOut("[ZMOST][PROCESSO] ZMOrdComp consulta; pedido=" + cPedido)
		aRows := ZMRows(cQuery)
		ConOut("[ZMOST][PROCESSO] ZMOrdComp retorno; pedido=" + cPedido + "; linhas=" + cValToChar(Len(aRows)))
		If Len(aRows) != 1
			Return "Pedido original inexistente ou ambiguo: " + cPedido
		EndIf
		If Empty(aCabBase)
			aCabBase := AClone(aRows[1])
		Else
			For nCampo := 1 To Len(aCabBase)
				If AllTrim(cValToChar(aCabBase[nCampo])) != AllTrim(cValToChar(aRows[1, nCampo]))
					ConOut("[ZMOST][PROCESSO] ZMOrdComp divergencia; pedido=" + cPedido + "; campo=" + aCamposComp[nCampo] + "; base=" + AllTrim(cValToChar(aCabBase[nCampo])) + "; atual=" + AllTrim(cValToChar(aRows[1, nCampo])))
					Return "Pedidos originais com condicoes comerciais diferentes; consolide nota a nota."
				EndIf
			Next nCampo
		EndIf
		aAdd(aPedidos, cPedido)
	Next nItem

Return ""

Static Function ZMOrigObs(aState, aSelecionados)

	Local aOrigens := {}
	Local aLinha := {}
	Local cObs := "RENOVACAO MOSTRUARIO - "
	Local nItem := 0

	For nItem := 1 To Len(aSelecionados)
		aLinha := aState[1, aSelecionados[nItem]]
		If AScan(aOrigens, {|aOrigem| aOrigem[1] == aLinha[ZM_DOC] .And. aOrigem[2] == aLinha[ZM_SERIE]}) == 0
			aAdd(aOrigens, {aLinha[ZM_DOC], aLinha[ZM_SERIE]})
		EndIf
	Next nItem
	If Len(aOrigens) == 0
		Return {"", "Nenhuma nota de origem para registrar no pedido."}
	EndIf
	If Len(aOrigens) == 1
		cObs += "NF ORIGEM "
	Else
		cObs += "NFs ORIGEM "
	EndIf
	For nItem := 1 To Len(aOrigens)
		If nItem > 1
			cObs += ", "
		EndIf
		cObs += AllTrim(aOrigens[nItem, 1]) + "/" + AllTrim(aOrigens[nItem, 2])
	Next nItem
	If Len(cObs) > TamSX3("C5_ZZOBS")[1]
		Return {"", "As referencias de origem excedem o limite de C5_ZZOBS; processe nota a nota."}
	EndIf

Return {cObs, ""}

Static Function ZMRunBatch(aState, aGrupos, aEtapas, oDlg, aResultado, cSerieSaida, dEntrega)

	Local aGrupo := {}
	Local aLinhas := {}
	Local aEtapa := {.F., "", "", "", .F.}
	Local cResumo := ""
	Local cErro := ""
	Local nGrupo := 0
	Local nConcluidos := 0
	Local lAtualiza := .F.

	For nGrupo := 1 To Len(aGrupos)
		aGrupo := aGrupos[nGrupo]
		aLinhas := aGrupo[ZM_G_ROWS]
		cResumo := "Lote " + cValToChar(nGrupo) + "/" + cValToChar(Len(aGrupos)) + ": " + AllTrim(aGrupo[ZM_G_DOC]) + "/" + AllTrim(aGrupo[ZM_G_SERIE])
		ZMStage(aEtapas, 1, "[EM ANDAMENTO] " + cResumo, oDlg)
		aEtapa := {.F., "Etapa sem retorno.", "", "", .F.}
		ZMRunDocs(aState, aLinhas, aEtapas, oDlg, @aEtapa, cSerieSaida, dEntrega)
		lAtualiza := lAtualiza .Or. aEtapa[5]
		If !aEtapa[1]
			cErro := cResumo + " falhou: " + aEtapa[2]
			ZMStage(aEtapas, 1, "[FALHA] " + cResumo, oDlg)
			Exit
		EndIf
		nConcluidos++
	Next nGrupo
	If Empty(cErro)
		aResultado[1] := .T.
		aResultado[2] := "Concluidos " + cValToChar(nConcluidos) + " lote(s). " + AllTrim(aEtapa[2])
	Else
		aResultado[1] := .F.
		aResultado[2] := "Concluidos " + cValToChar(nConcluidos) + " de " + cValToChar(Len(aGrupos)) + " lote(s). " + cErro
	EndIf
	aResultado[5] := lAtualiza
	ZMStage(aEtapas, 9, aResultado[2], oDlg)
	aState[3] := .F.
	oDlg:Refresh()
	ConOut("[ZMOST][PROCESSO] Lote finalizado; fechamento habilitado")

Return Nil

Static Function ZMRunDocs(aState, aSelecionados, aEtapas, oDlg, aResultado, cSerieSaida, dEntrega)

	Local aArea := GetArea()
	Local aPedidoCab := {}
	Local aItensPed := {}
	Local aItemPed := {}
	Local aRows := {}
	Local aOperResult := {{}, ""}
	Local aNumero := {}
	Local aLog := {}
	Local aFaturamento := {}
	Local aOrigens := {}
	Local aOrigem := {}
	Local aDocsRet := {}
	Local aMutexes := {}
	Local aObs := {}
	Local aLinha := {}
	Local cDoc := aState[1, aSelecionados[1], ZM_DOC]
	Local cSerie := aState[1, aSelecionados[1], ZM_SERIE]
	Local cCliente := aState[1, aSelecionados[1], ZM_CLIENT]
	Local cLoja := aState[1, aSelecionados[1], ZM_LOJA]
	Local cFornecedor := aState[1, aSelecionados[1], ZM_SA2COD]
	Local cLojaFor := aState[1, aSelecionados[1], ZM_SA2LOJA]
	Local cPedidoOrig := aState[1, aSelecionados[1], ZM_ORIGPED]
	Local cDocRet := ""
	Local cPedidoNovo := ""
	Local cDocSaida := ""
	Local cQuery := ""
	Local cMutex := ""
	Local cErro := ""
	Local cSerieDoc := ""
	Local lReservaPendente := .F.
	Local lAutoInvocado := .F.
	Local lPedidoOK := .F.
	Local cClientePedido := ""
	Local cLojaPedido := ""
	Local cRepPedido := ""
	Local nItem := 0
	Local nLinha := 0
	Local nLock := 0
	Local lRetornoCriado := .F.
	Local lClienteOK := .F.
	Local lLojaOK := .F.
	Local bError := ErrorBlock({|oErr| Break(oErr)})
	Local oError := Nil

	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.
	Private lAutoErrNoFile := .T.
	Private _lAprov := .F.
	Private lAlcada := .F.

	Begin Sequence
		ZMStage(aEtapas, 1, "[EM ANDAMENTO] Conferindo locks, origens e saldo atual.", oDlg)
		ConOut("[ZMOST][PROCESSO] Inicio; origem=" + AllTrim(cDoc) + "/" + AllTrim(cSerie) + "; pedido=" + AllTrim(cPedidoOrig))
		aOrigens := ZMOrigins(aState, aSelecionados)
		If Len(aOrigens) == 0
			Break("Nao foi possivel identificar as notas de origem selecionadas.")
		EndIf
		For nItem := 1 To Len(aOrigens)
			aOrigem := aOrigens[nItem]
			cMutex := "ZMOST_" + cEmpAnt + "_" + cFilAnt + "_" + AllTrim(aOrigem[1]) + "_" + AllTrim(aOrigem[2])
			ConOut("[ZMOST][PROCESSO] Lock origem antes; nota=" + AllTrim(aOrigem[1]) + "/" + AllTrim(aOrigem[2]))
			If !LockByName(cMutex, .T., .F.)
				Break("Nota " + AllTrim(aOrigem[1]) + "/" + AllTrim(aOrigem[2]) + " ja esta sendo processada por outra sessao.")
			EndIf
			aAdd(aMutexes, cMutex)
			If !ZMSourceOK(aOrigem[1], aOrigem[2], aOrigem[3], aOrigem[4], @cErro)
				Break(cErro)
			EndIf
			cQuery := "SELECT COUNT(*) AS QTD FROM " + RetSqlName("SD2") + " WHERE D2_FILIAL = " + ZMSql(xFilial("SD2"))
			cQuery += " AND D2_DOC = " + ZMSql(aOrigem[1]) + " AND D2_SERIE = " + ZMSql(aOrigem[2])
			cQuery += " AND D2_CLIENTE = " + ZMSql(aOrigem[3]) + " AND D2_LOJA = " + ZMSql(aOrigem[4]) + " AND D_E_L_E_T_ = ' '
			aRows := ZMRows(cQuery)
			If Len(aRows) != 1
				Break("Nao foi possivel contar os itens da nota " + AllTrim(aOrigem[1]) + "/" + AllTrim(aOrigem[2]) + ".")
			EndIf
			If ValType(aRows[1, 1]) != "N" .Or. aRows[1, 1] != aOrigem[5]
				Break("A selecao nao contem todos os itens SD2 da nota " + AllTrim(aOrigem[1]) + "/" + AllTrim(aOrigem[2]) + ".")
			EndIf
		Next nItem
		For nLinha := 1 To Len(aSelecionados)
			aLinha := aState[1, aSelecionados[nLinha]]
			ConOut("[ZMOST][PROCESSO] Checkpoint SB6 antes; item=" + AllTrim(aLinha[ZM_ITEM]))
			DbSelectArea("SB6")
			DbGoTo(aLinha[ZM_RECNO])
			If Eof() .Or. Deleted() .Or. B6_SALDO != aLinha[ZM_QTSEL]
				Break("Saldo SB6 mudou desde a consulta; consulte novamente antes de processar.")
			EndIf
			ConOut("[ZMOST][PROCESSO] Checkpoint SB6 depois; item=" + AllTrim(aLinha[ZM_ITEM]))
		Next nLinha
		cErro := ZMOrdComp(aState, aSelecionados)
		If !Empty(cErro)
			Break(cErro)
		EndIf
		cQuery := "SELECT C5_CLIENTE, C5_LOJACLI, C5_LOJAENT, C5_CONDPAG, C5_VEND1, C5_TRANSP, C5_TPFRETE, C5_MOEDA, C5_TABELA FROM " + RetSqlName("SC5")
		cQuery += " WHERE C5_FILIAL = " + ZMSql(xFilial("SC5")) + " AND C5_NUM = " + ZMSql(cPedidoOrig) + " AND D_E_L_E_T_ = ' '
		ConOut("[ZMOST][PROCESSO] Checkpoint SC5 antes")
		aRows := ZMRows(cQuery)
		ConOut("[ZMOST][PROCESSO] Checkpoint SC5 depois; registros=" + cValToChar(Len(aRows)))
		If Len(aRows) != 1
			Break("Pedido original inexistente ou ambiguo em SC5: " + AllTrim(cPedidoOrig))
		EndIf
		ConOut("[ZMOST][PROCESSO] Checkpoint SC5 cardinalidade OK")
		ConOut("[ZMOST][PROCESSO] Checkpoint SC5 comparacao antes")
		cClientePedido := AllTrim(cValToChar(aRows[1, 1]))
		cLojaPedido := AllTrim(cValToChar(aRows[1, 2]))
		cRepPedido := AllTrim(cValToChar(aRows[1, 5]))
		lClienteOK := cClientePedido == AllTrim(cValToChar(cCliente))
		lLojaOK := cLojaPedido == AllTrim(cValToChar(cLoja))
		ConOut("[ZMOST][PROCESSO] Checkpoint SC5 comparacao depois; cliente=" + cValToChar(lClienteOK) + "; loja=" + cValToChar(lLojaOK))
		If !lClienteOK .Or. !lLojaOK
			Break("Cliente ou loja do pedido original diverge da origem selecionada.")
		EndIf
		ConOut("[ZMOST][PROCESSO] Checkpoint SC5 cliente/loja OK; representante do pedido original sera mantido.")
		aObs := ZMOrigObs(aState, aSelecionados)
		If !Empty(aObs[2])
			Break(aObs[2])
		EndIf
		ConOut("[ZMOST][PROCESSO] Checkpoint SC6 operacoes antes")
		aOperResult := ZMOrigOper(aState, aSelecionados)
		If !Empty(aOperResult[2])
			Break(aOperResult[2])
		EndIf
		ConOut("[ZMOST][PROCESSO] Checkpoint SC6 operacoes depois; itens=" + cValToChar(Len(aOperResult[1])))

		ConOut("[ZMOST][PROCESSO] Preparando pedido consolidado; entradas MATA103 serao executadas por nota.")
		For nItem := 1 To Len(aSelecionados)
			aLinha := aState[1, aSelecionados[nItem]]
			aItemPed := {}
			aAdd(aItemPed, {"C6_ITEM", StrZero(nItem, TamSX3("C6_ITEM")[1]), Nil})
			aAdd(aItemPed, {"C6_PRODUTO", aLinha[ZM_PROD], Nil})
			aAdd(aItemPed, {"C6_UM", aLinha[ZM_UM], Nil})
			aAdd(aItemPed, {"C6_QTDVEN", aLinha[ZM_QTSEL], Nil})
			aAdd(aItemPed, {"C6_PRUNIT", aLinha[ZM_PRECO], Nil})
			aAdd(aItemPed, {"C6_PRCVEN", aLinha[ZM_PRECO], Nil})
			aAdd(aItemPed, {"C6_OPER", aOperResult[1, nItem], Nil})
			aAdd(aItemPed, {"C6_TES", aLinha[ZM_TES], Nil})
			aAdd(aItemPed, {"C6_LOCAL", aLinha[ZM_LOCAL], Nil})
			ConOut("[ZMOST][PROCESSO] Montagem item MATA410; indice=" + cValToChar(nItem) + "; selecionados=" + cValToChar(Len(aSelecionados)) + "; fiscal=" + AllTrim(aLinha[ZM_ITEM]) + "; pedidoOrigem=" + AllTrim(aLinha[ZM_ORIGITEM]) + "; linhasAntes=" + cValToChar(Len(aItensPed)))
			aAdd(aItensPed, aItemPed)
			ConOut("[ZMOST][PROCESSO] Montagem item MATA410 concluida; indice=" + cValToChar(nItem) + "; linhasDepois=" + cValToChar(Len(aItensPed)))
		Next nItem
		ConOut("[ZMOST][PROCESSO] Conferencia previa MATA410; selecionados=" + cValToChar(Len(aSelecionados)) + "; preparados=" + cValToChar(Len(aItensPed)))
		If Len(aItensPed) != Len(aSelecionados)
			Break("MATA410 nao iniciada: quantidade de itens preparados diverge da selecao (" + cValToChar(Len(aItensPed)) + "/" + cValToChar(Len(aSelecionados)) + "). Nenhuma entrada foi criada.")
		EndIf
		ZMStage(aEtapas, 1, "[OK] Origem autorizada, fornecedor e saldo atual conferidos.", oDlg)
		cErro := ZMEntryDocs(aState, aSelecionados, aOrigens, cFornecedor, cLojaFor, aEtapas, oDlg, @aDocsRet, @lReservaPendente, @lAutoInvocado, @cDocRet, @cSerieDoc)
		If !Empty(cErro)
			Break(cErro)
		EndIf
		lRetornoCriado := Len(aDocsRet) > 0
		aResultado[3] := ZMEntryRefs(aDocsRet)
		aResultado[5] := lRetornoCriado
		ZMStage(aEtapas, 4, "[EM ANDAMENTO] Reservando numeracao do pedido SC5.", oDlg)
		ConOut("[ZMOST][PROCESSO] Checkpoint ZMReserve SC5 antes; limite=100")
		aNumero := ZMReserve("SC5", "C5_NUM")
		ConOut("[ZMOST][PROCESSO] Checkpoint ZMReserve SC5 depois; numero=" + AllTrim(aNumero[1]) + "; erro=" + AllTrim(aNumero[2]))
		If !Empty(aNumero[2])
			Break("Entradas " + ZMEntryRefs(aDocsRet) + " confirmadas; pedido nao iniciado: " + aNumero[2])
		EndIf
		lReservaPendente := .T.
		lAutoInvocado := .F.
		cPedidoNovo := aNumero[1]
		aAdd(aPedidoCab, {"C5_NUM", cPedidoNovo, Nil})
		aAdd(aPedidoCab, {"C5_TIPO", "N", Nil})
		aAdd(aPedidoCab, {"C5_EMISSAO", Date(), Nil})
		aAdd(aPedidoCab, {"C5_CLIENTE", aRows[1, 1], Nil})
		aAdd(aPedidoCab, {"C5_LOJACLI", aRows[1, 2], Nil})
		aAdd(aPedidoCab, {"C5_LOJAENT", aRows[1, 3], Nil})
		aAdd(aPedidoCab, {"C5_CONDPAG", aRows[1, 4], Nil})
		aAdd(aPedidoCab, {"C5_VEND1", aRows[1, 5], Nil})
		aAdd(aPedidoCab, {"C5_TRANSP", aRows[1, 6], Nil})
		aAdd(aPedidoCab, {"C5_TPFRETE", aRows[1, 7], Nil})
		aAdd(aPedidoCab, {"C5_MOEDA", aRows[1, 8], Nil})
		aAdd(aPedidoCab, {"C5_TABELA", aRows[1, 9], Nil})
		aAdd(aPedidoCab, {"C5_ZZORIGE", "TRA", Nil})
		aAdd(aPedidoCab, {"C5_ZZTPPED", "TR", Nil})
		aAdd(aPedidoCab, {"C5_ZZOBS", aObs[1], Nil})
		aResultado[4] := cPedidoNovo
		ZMStage(aEtapas, 4, "[EM ANDAMENTO] Criando pedido MATA410 " + AllTrim(cPedidoNovo) + ".", oDlg)
		ConOut("[ZMOST][PROCESSO] MATA410 antes; pedido=" + AllTrim(cPedidoNovo) + "; itens=" + cValToChar(Len(aItensPed)))
		Begin Transaction
			Begin Sequence
				lPedidoOK := .F.
				lMsErroAuto := .F.
				lAutoInvocado := .T.
				MsExecAuto({|aHeader, aLines, nOption, lShow| MATA410(aHeader, aLines, nOption, lShow)}, aPedidoCab, aItensPed, 3, .F.)
				ConOut("[ZMOST][PROCESSO] MATA410 retornou; pedido=" + AllTrim(cPedidoNovo) + "; erroAuto=" + cValToChar(lMsErroAuto))
				If lMsErroAuto
					aLog := GetAutoGrLog()
					Break("Entradas " + ZMEntryRefs(aDocsRet) + " confirmadas; MATA410: " + ZMLogAuto(aLog))
				EndIf
				ZMStage(aEtapas, 5, "[EM ANDAMENTO] Conferindo cabecalho e itens do pedido.", oDlg)
				If !ZMOrderOK(cPedidoNovo, cCliente, cLoja, cRepPedido, aState, aSelecionados, aOperResult[1])
					Break("MATA410 nao confirmou integralmente SC5/SC6 do pedido " + AllTrim(cPedidoNovo) + ".")
				EndIf
				lPedidoOK := .T.
			Recover Using oError
				cErro := ZMError(oError)
				If Empty(cErro)
					cErro := "Falha sem descricao durante MATA410 ou conferencia SC5/SC6."
				EndIf
				ConOut("[ZMOST][PROCESSO] Falha MATA410/conferencia; pedido=" + AllTrim(cPedidoNovo) + "; " + cErro)
				DisarmTransaction()
			End Sequence
		End Transaction
		If !lPedidoOK
			lAutoInvocado := .F.
			If Empty(cErro)
				cErro := "MATA410 ou a conferencia SC5/SC6 nao confirmou o pedido " + AllTrim(cPedidoNovo) + "."
			EndIf
			Break(cErro)
		EndIf
		ConfirmSX8()
		lReservaPendente := .F.
		lAutoInvocado := .F.
		aResultado[5] := .T.
		ConOut("[ZMOST][PROCESSO] MATA410 confirmada; pedido=" + AllTrim(cPedidoNovo))

		ZMStage(aEtapas, 4, "[OK] Pedido criado: " + AllTrim(cPedidoNovo), oDlg)
		ZMStage(aEtapas, 5, "[OK] Cabecalho e itens do pedido conferidos.", oDlg)
		ZMStage(aEtapas, 6, "[EM ANDAMENTO] Liberando integralmente o pedido pela MaLibDoFat.", oDlg)
		cErro := ZMRelOrder(cPedidoNovo)
		If !Empty(cErro)
			Break("Entradas " + ZMEntryRefs(aDocsRet) + " e pedido " + AllTrim(cPedidoNovo) + " criados; liberacao nao confirmada: " + cErro)
		EndIf
		ZMStage(aEtapas, 6, "[OK] Pedido liberado; SC9 conferida integralmente.", oDlg)
		ZMStage(aEtapas, 7, "[EM ANDAMENTO] Faturando pedido pela MATA461.", oDlg)
		aFaturamento := ZMInvoice(cPedidoNovo, cSerieSaida, dEntrega)
		cDocSaida := aFaturamento[1]
		If !Empty(aFaturamento[2])
			Break("Entradas " + ZMEntryRefs(aDocsRet) + " e pedido " + AllTrim(cPedidoNovo) + " liberados; MATA461: " + aFaturamento[2])
		EndIf
		ZMStage(aEtapas, 7, "[OK] MATA461 retornou o documento " + AllTrim(cDocSaida) + "/" + AllTrim(cSerieSaida) + ".", oDlg)
		ZMStage(aEtapas, 8, "[EM ANDAMENTO] Conferindo SF2/SD2.", oDlg)
		If !ZMInvOK(cPedidoNovo, cDocSaida, cSerieSaida, cCliente, cLoja, aState, aSelecionados, aEtapas, oDlg)
			Break("Entradas " + ZMEntryRefs(aDocsRet) + " e pedido " + AllTrim(cPedidoNovo) + " faturados, mas SF2/SD2 nao confirmaram a saida " + AllTrim(cDocSaida) + "/" + AllTrim(cSerieSaida) + ". Nao repita antes de reconciliar.")
		EndIf
		ConOut("[ZMOST][PROCESSO] ZMInvOK retornou sucesso; pedido=" + AllTrim(cPedidoNovo) + "; documento=" + AllTrim(cDocSaida) + "/" + AllTrim(cSerieSaida))
		aResultado[6] := cDocSaida
		ZMStage(aEtapas, 8, "[OK] SF2/SD2 confirmadas para " + AllTrim(cDocSaida) + "/" + AllTrim(cSerieSaida) + ".", oDlg)
		aResultado[1] := .T.
		aResultado[2] := "Concluido. Entradas " + ZMEntryRefs(aDocsRet) + "; pedido unico " + AllTrim(cPedidoNovo) + "; saida unica " + AllTrim(cDocSaida) + "/" + AllTrim(cSerieSaida) + ". Autorizacao/transmissao pelo AUTONFE padrao."
		ZMStage(aEtapas, 9, aResultado[2], oDlg)
	Recover Using oError
		cErro := ZMError(oError)
		lRetornoCriado := lRetornoCriado .Or. Len(aDocsRet) > 0
		aResultado[3] := ZMEntryRefs(aDocsRet)
		aResultado[5] := aResultado[5] .Or. lRetornoCriado
		If Empty(cErro)
			cErro := "Falha sem descricao durante o processamento."
		EndIf
		aResultado[1] := .F.
		If lRetornoCriado
			If !Empty(cDocSaida)
				aResultado[2] := "Entradas " + ZMEntryRefs(aDocsRet) + " e pedido " + AllTrim(cPedidoNovo) + " criados; confira saida " + AllTrim(cDocSaida) + "/" + AllTrim(cSerieSaida) + " antes de repetir. " + cErro
			ElseIf lPedidoOK
				aResultado[2] := "Entradas " + ZMEntryRefs(aDocsRet) + " e pedido " + AllTrim(cPedidoNovo) + " criados; confira liberacao/faturamento antes de repetir. " + cErro
			Else
				aResultado[2] := "Entradas " + ZMEntryRefs(aDocsRet) + " confirmadas; consolidacao interrompida. Reconcilie SF1/SD1 e SC5/SC6 antes de repetir. " + cErro
			EndIf
		ElseIf !Empty(cDocRet)
			aResultado[2] := "MATA103 tentou o documento " + AllTrim(cDocRet) + "; confira SF1/SD1 antes de repetir. " + cErro
		Else
			aResultado[2] := cErro
		EndIf
		ZMStage(aEtapas, 9, "[FALHA] " + aResultado[2], oDlg)
		ConOut("[ZMOST][PROCESSO] Falha; etapa atual registrada na tela. " + aResultado[2])
	End Sequence
	If lReservaPendente
		If lAutoInvocado
			ConfirmSX8()
		Else
			RollBackSX8()
		EndIf
	EndIf
	For nLock := Len(aMutexes) To 1 Step -1
		UnLockByName(aMutexes[nLock], .T., .F.)
	Next nLock
	aState[3] := .F.
	If lRetornoCriado
		ConOut("[ZMOST][PROCESSO] Origem renovada; atualize o saldo antes de nova acao.")
	EndIf
	RestArea(aArea)
	ErrorBlock(bError)

Return Nil

Static Function ZMOrigOper(aState, aSelecionados)

	Local aOperacoes := {}
	Local aPedidos := {}
	Local aCache := {}
	Local aRows := {}
	Local aLinha := {}
	Local cQuery := ""
	Local cOper := ""
	Local cPedido := ""
	Local nItem := 0
	Local nPedido := 0
	Local nPos := 0
	Local nBusca := 0

	For nItem := 1 To Len(aSelecionados)
		aLinha := aState[1, aSelecionados[nItem]]
		cPedido := AllTrim(aLinha[ZM_ORIGPED])
		nPedido := AScan(aPedidos, {|cOrigem| cOrigem == cPedido})
		If nPedido == 0
			cQuery := "SELECT C6_ITEM, C6_PRODUTO, C6_OPER FROM " + RetSqlName("SC6")
			cQuery += " WHERE C6_FILIAL = " + ZMSql(xFilial("SC6")) + " AND C6_NUM = " + ZMSql(cPedido)
			cQuery += " AND D_E_L_E_T_ = ' '
			ConOut("[ZMOST][PROCESSO] ZMOrigOper consulta antes; pedido=" + cPedido)
			aRows := ZMRows(cQuery)
			ConOut("[ZMOST][PROCESSO] ZMOrigOper consulta depois; pedido=" + cPedido + "; registros=" + cValToChar(Len(aRows)))
			If Len(aRows) == 0
				Return {{}, "Pedido original sem itens ativos em SC6: " + cPedido + "."}
			EndIf
			aAdd(aPedidos, cPedido)
			aAdd(aCache, aRows)
			nPedido := Len(aPedidos)
		Else
			aRows := aCache[nPedido]
		EndIf
			ConOut("[ZMOST][PROCESSO] ZMOrigOper buscando item; pedido=" + cPedido + "; itemPedido=" + AllTrim(aLinha[ZM_ORIGITEM]) + "; itemFiscal=" + AllTrim(aLinha[ZM_ITEM]) + "; linhas=" + cValToChar(Len(aRows)))
			nPos := 0
			For nBusca := 1 To Len(aRows)
				If AllTrim(cValToChar(aRows[nBusca, 1])) == AllTrim(aLinha[ZM_ORIGITEM])
					nPos := nBusca
					Exit
				EndIf
			Next nBusca
			ConOut("[ZMOST][PROCESSO] ZMOrigOper busca concluida; pedido=" + cPedido + "; itemPedido=" + AllTrim(aLinha[ZM_ORIGITEM]) + "; posicao=" + cValToChar(nPos))
		If nPos == 0
				Return {{}, "Item do pedido " + AllTrim(aLinha[ZM_ORIGITEM]) + " nao localizado no pedido original " + cPedido + " (item fiscal " + AllTrim(aLinha[ZM_ITEM]) + ")."}
		EndIf
			ConOut("[ZMOST][PROCESSO] ZMOrigOper conferindo produto; pedido=" + cPedido + "; itemPedido=" + AllTrim(aLinha[ZM_ORIGITEM]))
		If AllTrim(cValToChar(aRows[nPos, 2])) != AllTrim(aLinha[ZM_PROD])
			Return {{}, "Produto do SC6 original diverge da origem; item=" + AllTrim(aLinha[ZM_ITEM]) + "."}
		EndIf
			ConOut("[ZMOST][PROCESSO] ZMOrigOper produto OK; pedido=" + cPedido + "; itemPedido=" + AllTrim(aLinha[ZM_ORIGITEM]))
		cOper := AllTrim(cValToChar(aRows[nPos, 3]))
		aAdd(aOperacoes, cOper)
		ConOut("[ZMOST][PROCESSO] ZMOrigOper item OK; pedido=" + cPedido + "; itemPedido=" + AllTrim(aLinha[ZM_ORIGITEM]))
	Next nItem

Return {aOperacoes, ""}

Static Function ZMOrigins(aState, aSelecionados)

	Local aOrigens := {}
	Local aLinha := {}
	Local nItem := 0
	Local nPos := 0

	For nItem := 1 To Len(aSelecionados)
		aLinha := aState[1, aSelecionados[nItem]]
		nPos := AScan(aOrigens, {|aOrigem| aOrigem[1] == aLinha[ZM_DOC] .And. aOrigem[2] == aLinha[ZM_SERIE]})
		If nPos == 0
			aAdd(aOrigens, {aLinha[ZM_DOC], aLinha[ZM_SERIE], aLinha[ZM_CLIENT], aLinha[ZM_LOJA], 0})
			nPos := Len(aOrigens)
		EndIf
		aOrigens[nPos, 5]++
	Next nItem

Return aOrigens

Static Function ZMEntrySel(aState, aSelecionados, cDoc, cSerie)

	Local aEntrySel := {}
	Local aLinha := {}
	Local nItem := 0

	For nItem := 1 To Len(aSelecionados)
		aLinha := aState[1, aSelecionados[nItem]]
		If aLinha[ZM_DOC] == cDoc .And. aLinha[ZM_SERIE] == cSerie
			aAdd(aEntrySel, aSelecionados[nItem])
		EndIf
	Next nItem

Return aEntrySel

Static Function ZMSeriesOK(cSerie, cSerieGrupo, lConsolidado)
Return lConsolidado .Or. cSerie == cSerieGrupo

Static Function ZMEntryRefs(aDocsRet)

	Local cRefs := ""
	Local nItem := 0

	For nItem := 1 To Len(aDocsRet)
		If nItem > 1
			cRefs += ", "
		EndIf
		cRefs += AllTrim(aDocsRet[nItem, 1]) + "/" + AllTrim(aDocsRet[nItem, 2])
	Next nItem

Return cRefs

Static Function ZMEntryDocs(aState, aSelecionados, aOrigens, cFornecedor, cLojaFor, aEtapas, oDlg, aDocsRet, lReservaPendente, lAutoInvocado, cDocRet, cSerieDoc)

	Local aCab := {}
	Local aItens := {}
	Local aItem := {}
	Local aEntradaSel := {}
	Local aNumero := {}
	Local aLog := {}
	Local aOrigem := {}
	Local aLinha := {}
	Local nOrigem := 0
	Local nItem := 0

	For nOrigem := 1 To Len(aOrigens)
		aOrigem := aOrigens[nOrigem]
		aEntradaSel := ZMEntrySel(aState, aSelecionados, aOrigem[1], aOrigem[2])
		If Len(aEntradaSel) == 0 .Or. Len(aEntradaSel) != aOrigem[5]
			Return "Selecao inconsistente para entrada da nota " + AllTrim(aOrigem[1]) + "/" + AllTrim(aOrigem[2]) + "."
		EndIf
		aCab := {}
		aItens := {}
		ZMStage(aEtapas, 2, "[EM ANDAMENTO] MATA103 da nota " + AllTrim(aOrigem[1]) + "/" + AllTrim(aOrigem[2]) + " (" + cValToChar(nOrigem) + "/" + cValToChar(Len(aOrigens)) + ").", oDlg)
		aNumero := ZMReserve("SF1", "F1_DOC")
		If !Empty(aNumero[2])
			Return "MATA103 da nota " + AllTrim(aOrigem[1]) + "/" + AllTrim(aOrigem[2]) + ": " + aNumero[2]
		EndIf
		lReservaPendente := .T.
		lAutoInvocado := .F.
		cDocRet := aNumero[1]
		cSerieDoc := PadR(AllTrim(aOrigem[2]), TamSX3("F1_SERIE")[1])
		aAdd(aCab, {"F1_DOC", cDocRet, Nil})
		aAdd(aCab, {"F1_SERIE", cSerieDoc, Nil})
		aAdd(aCab, {"F1_TIPO", "B", Nil})
		aAdd(aCab, {"F1_FORMUL", "S", Nil})
		aAdd(aCab, {"F1_FORNECE", PadR(AllTrim(cFornecedor), TamSX3("F1_FORNECE")[1]), Nil})
		aAdd(aCab, {"F1_LOJA", PadR(AllTrim(cLojaFor), TamSX3("F1_LOJA")[1]), Nil})
		aAdd(aCab, {"F1_EMISSAO", Date(), Nil})
		aAdd(aCab, {"F1_DTDIGIT", Date(), Nil})
		aAdd(aCab, {"F1_ESPECIE", "SPED", Nil})
		aAdd(aCab, {"F1_COND", "030", Nil})
		aAdd(aCab, {"F1_MOEDA", 1, Nil})
		aAdd(aCab, {"F1_TXMOEDA", 1, Nil})
		For nItem := 1 To Len(aEntradaSel)
			aLinha := aState[1, aEntradaSel[nItem]]
			aItem := {}
			aAdd(aItem, {"D1_ITEM", StrZero(nItem, TamSX3("D1_ITEM")[1]), Nil})
			aAdd(aItem, {"D1_DOC", cDocRet, Nil})
			aAdd(aItem, {"D1_SERIE", cSerieDoc, Nil})
			aAdd(aItem, {"D1_COD", aLinha[ZM_PROD], Nil})
			aAdd(aItem, {"D1_UM", aLinha[ZM_UM], Nil})
			aAdd(aItem, {"D1_LOCAL", aLinha[ZM_LOCAL], Nil})
			aAdd(aItem, {"D1_QUANT", aLinha[ZM_QTSEL], Nil})
			aAdd(aItem, {"D1_VUNIT", aLinha[ZM_PRECO], Nil})
			aAdd(aItem, {"D1_TOTAL", aLinha[ZM_QTSEL] * aLinha[ZM_PRECO], Nil})
			aAdd(aItem, {"D1_TES", aLinha[ZM_RETOR], Nil})
			aAdd(aItem, {"D1_NFORI", aLinha[ZM_DOC], Nil})
			aAdd(aItem, {"D1_SERIORI", aLinha[ZM_SERIE], Nil})
			aAdd(aItem, {"D1_ITEMORI", aLinha[ZM_ITEM], Nil})
			aAdd(aItem, {"D1_IDENTB6", aLinha[ZM_IDENT], Nil})
			aAdd(aItens, aItem)
		Next nItem
		lMsErroAuto := .F.
		ConOut("[ZMOST][PROCESSO] MATA103 antes; origem=" + AllTrim(aOrigem[1]) + "/" + AllTrim(aOrigem[2]) + "; documento=" + AllTrim(cDocRet) + "; itens=" + cValToChar(Len(aItens)))
		lAutoInvocado := .T.
		MsExecAuto({|aHeader, aLines, nOption, lShow| MATA103(aHeader, aLines, nOption, lShow)}, aCab, aItens, 3, .F.)
		ConfirmSX8()
		lReservaPendente := .F.
		lAutoInvocado := .F.
		If lMsErroAuto
			aLog := GetAutoGrLog()
			Return "MATA103 da nota " + AllTrim(aOrigem[1]) + "/" + AllTrim(aOrigem[2]) + ": " + ZMLogAuto(aLog)
		EndIf
		ConOut("[ZMOST][PROCESSO] MATA103 retornou; origem=" + AllTrim(aOrigem[1]) + "/" + AllTrim(aOrigem[2]) + "; documento=" + AllTrim(cDocRet))
		ZMStage(aEtapas, 3, "[EM ANDAMENTO] Conferindo entrada " + AllTrim(cDocRet) + "/" + AllTrim(cSerieDoc) + ".", oDlg)
		If !ZMEntryOK(cDocRet, cSerieDoc, cFornecedor, cLojaFor, aState, aEntradaSel)
			Return "MATA103 retornou, mas SF1/SD1 nao confirmaram a nota " + AllTrim(aOrigem[1]) + "/" + AllTrim(aOrigem[2]) + " no documento " + AllTrim(cDocRet) + ". Nao repita antes de reconciliar."
		EndIf
		aAdd(aDocsRet, {cDocRet, cSerieDoc})
		ZMStage(aEtapas, 2, "[OK] Entrada " + AllTrim(cDocRet) + "/" + AllTrim(cSerieDoc) + " confirmada.", oDlg)
	Next nOrigem

Return ""

Static Function ZMStage(aEtapas, nEtapa, cTexto, oDlg)

	Local oSay := Nil

	If nEtapa >= 1 .And. nEtapa <= Len(aEtapas)
		oSay := aEtapas[nEtapa]
		oSay:SetText(cTexto)
	EndIf
	ConOut("[ZMOST][PROCESSO] " + cTexto)
	oDlg:Refresh()

Return Nil

Static Function ZMReserve(cTable, cField)

	Local cNumero := ""
	Local cAnterior := ""
	Local cBusca := ""
	Local nTentativa := 0

	If Select(cTable) == 0
		ChkFile(cTable)
	EndIf
	If Select(cTable) == 0
		Return {"", "Alias indisponivel: " + cTable}
	EndIf
	DbSelectArea(cTable)
	DbSetOrder(1)
	For nTentativa := 1 To 100
		cNumero := GetSxeNum(cTable, cField)
		If ValType(cNumero) != "C" .Or. Empty(AllTrim(cNumero))
			Return {"", "Numeracao vazia em " + cTable + "/" + cField}
		EndIf
		cNumero := AllTrim(cNumero)
		cBusca := PadR(cNumero, TamSX3(cField)[1])
		If ZMDoc(cNumero) == cNumero
			cBusca := StrZero(Val(cNumero), TamSX3(cField)[1])
		EndIf
		If !(cTable)->(DbSeek(xFilial(cTable) + cBusca))
			Return {cNumero, ""}
		EndIf
		ConOut("[ZMOST][RESERVA] Numero ocupado em " + cTable + "/" + cField + ": " + cNumero + "; tentativa=" + cValToChar(nTentativa) + "/100")
		ConfirmSX8()
		If cNumero == cAnterior
			Return {"", "Numeracao repetida em " + cTable + "/" + cField + ": " + cNumero}
		EndIf
		cAnterior := cNumero
	Next nTentativa

Return {"", "Limite de 100 reservas de numeracao atingido em " + cTable + "/" + cField}

Static Function ZMRows(cQuery)

	Local aArea := GetArea()
	Local aRows := {}
	Local aRow := {}
	Local cAlias := GetNextAlias()
	Local cErro := ""
	Local nCampo := 0
	Local bError := ErrorBlock({|oErr| Break(oErr)})
	Local oError := Nil

	Begin Sequence
		TCQuery ChangeQuery(cQuery) New Alias (cAlias)
		While !(cAlias)->(Eof())
			aRow := {}
			For nCampo := 1 To (cAlias)->(FCount())
				aAdd(aRow, (cAlias)->(FieldGet(nCampo)))
			Next nCampo
			aAdd(aRows, aRow)
			(cAlias)->(DbSkip())
		EndDo
	Recover Using oError
		cErro := ZMError(oError)
	End Sequence
	If Select(cAlias) > 0
		(cAlias)->(DbCloseArea())
	EndIf
	RestArea(aArea)
	ErrorBlock(bError)
	If !Empty(cErro)
		Break(cErro)
	EndIf

Return aRows

Static Function ZMSourceOK(cDoc, cSerie, cCliente, cLoja, cErro)

	Local aRows := {}
	Local cQuery := ""
	Local cChave := ""

	cQuery := "SELECT F2_CHVNFE FROM " + RetSqlName("SF2") + " WHERE F2_FILIAL = " + ZMSql(xFilial("SF2"))
	cQuery += " AND F2_DOC = " + ZMSql(cDoc) + " AND F2_SERIE = " + ZMSql(cSerie)
	cQuery += " AND F2_CLIENTE = " + ZMSql(cCliente) + " AND F2_LOJA = " + ZMSql(cLoja) + " AND D_E_L_E_T_ = ' '
	ConOut("[ZMOST][PROCESSO] ZMSourceOK SF2 antes")
	aRows := ZMRows(cQuery)
	ConOut("[ZMOST][PROCESSO] ZMSourceOK SF2 depois; registros=" + cValToChar(Len(aRows)))
	If Len(aRows) != 1
		cErro := "Nota de origem SF2 inexistente ou ambigua."
		Return .F.
	EndIf
	cChave := AllTrim(aRows[1, 1])
	If Len(cChave) != 44
		cErro := "Chave da NF-e de origem ausente ou invalida."
		Return .F.
	EndIf
	cQuery := "SELECT F3_NFISCAL FROM " + RetSqlName("SF3") + " WHERE F3_FILIAL = " + ZMSql(xFilial("SF3"))
	cQuery += " AND F3_NFISCAL = " + ZMSql(cDoc) + " AND F3_SERIE = " + ZMSql(cSerie)
	cQuery += " AND F3_CLIEFOR = " + ZMSql(cCliente) + " AND F3_LOJA = " + ZMSql(cLoja)
	cQuery += " AND F3_CODRSEF = '100' AND F3_DTCANC = ' ' AND D_E_L_E_T_ = ' '
	ConOut("[ZMOST][PROCESSO] ZMSourceOK SF3 antes")
	aRows := ZMRows(cQuery)
	ConOut("[ZMOST][PROCESSO] ZMSourceOK SF3 depois; registros=" + cValToChar(Len(aRows)))
	If Len(aRows) != 1
		cErro := "NF-e de origem sem autorizacao 100 unica ou com evento de cancelamento."
		Return .F.
	EndIf

Return .T.

Static Function ZMEntryOK(cDoc, cSerie, cFornecedor, cLojaFor, aState, aSelecionados)

	Local cQuery := ""
	Local cDocSql := AllTrim(cDoc)
	Local aRows := {}
	Local aSeen := {}
	Local aLinha := {}
	Local nSaved := 0
	Local nSelect := 0
	Local nMatch := 0

	If ZMDoc(cDocSql) == cDocSql
		cDocSql := StrZero(Val(cDocSql), TamSX3("F1_DOC")[1])
	EndIf
	cQuery := "SELECT F1_FORNECE, F1_LOJA, F1_TIPO, F1_FORMUL, F1_ESPECIE FROM " + RetSqlName("SF1")
	cQuery += " WHERE F1_FILIAL = " + ZMSql(xFilial("SF1")) + " AND F1_DOC = " + ZMSql(cDocSql)
	cQuery += " AND F1_FORNECE = " + ZMSql(cFornecedor) + " AND F1_LOJA = " + ZMSql(cLojaFor)
	cQuery += " AND F1_SERIE = " + ZMSql(cSerie) + " AND D_E_L_E_T_ = ' '
	ConOut("[ZMOST][PROCESSO] ZMEntryOK SF1 antes; doc=" + AllTrim(cDocSql) + "/" + AllTrim(cSerie))
	aRows := ZMRows(cQuery)
	ConOut("[ZMOST][PROCESSO] ZMEntryOK SF1 depois; registros=" + cValToChar(Len(aRows)))
	If Len(aRows) != 1
		ConOut("[ZMOST][PROCESSO] ZMEntryOK SF1 cardinalidade divergente")
		Return .F.
	EndIf
	If AllTrim(aRows[1, 1]) != AllTrim(cFornecedor) .Or. AllTrim(aRows[1, 2]) != AllTrim(cLojaFor) .Or. ;
		AllTrim(aRows[1, 3]) != "B" .Or. AllTrim(aRows[1, 4]) != "S" .Or. AllTrim(aRows[1, 5]) != "SPED"
		ConOut("[ZMOST][PROCESSO] ZMEntryOK SF1 campos divergentes")
		Return .F.
	EndIf
	ConOut("[ZMOST][PROCESSO] ZMEntryOK SF1 cabecalho OK")
	cQuery := "SELECT D1_IDENTB6, D1_COD, D1_QUANT, D1_UM, D1_TES, D1_NFORI, D1_SERIORI, D1_ITEMORI FROM " + RetSqlName("SD1")
	cQuery += " WHERE D1_FILIAL = " + ZMSql(xFilial("SD1")) + " AND D1_DOC = " + ZMSql(cDocSql)
	cQuery += " AND D1_SERIE = " + ZMSql(cSerie) + " AND D1_FORNECE = " + ZMSql(cFornecedor)
	cQuery += " AND D1_LOJA = " + ZMSql(cLojaFor) + " AND D_E_L_E_T_ = ' '
	ConOut("[ZMOST][PROCESSO] ZMEntryOK SD1 antes; doc=" + AllTrim(cDoc) + "/" + AllTrim(cSerie) + "; esperado=" + cValToChar(Len(aSelecionados)))
	aRows := ZMRows(cQuery)
	ConOut("[ZMOST][PROCESSO] ZMEntryOK SD1 depois; registros=" + cValToChar(Len(aRows)))
	If Len(aRows) != Len(aSelecionados)
		ConOut("[ZMOST][PROCESSO] ZMEntryOK SD1 quantidade divergente")
		Return .F.
	EndIf
	For nSelect := 1 To Len(aSelecionados)
		aAdd(aSeen, .F.)
	Next nSelect
	For nSaved := 1 To Len(aRows)
		nMatch := 0
		For nSelect := 1 To Len(aSelecionados)
			aLinha := aState[1, aSelecionados[nSelect]]
			If AllTrim(aRows[nSaved, 1]) == AllTrim(aLinha[ZM_IDENT]) .And. ;
				AllTrim(aRows[nSaved, 2]) == AllTrim(aLinha[ZM_PROD]) .And. ;
				Abs(aRows[nSaved, 3] - aLinha[ZM_QTSEL]) <= 0.000001 .And. ;
				AllTrim(aRows[nSaved, 4]) == AllTrim(aLinha[ZM_UM]) .And. ;
				AllTrim(aRows[nSaved, 5]) == AllTrim(aLinha[ZM_RETOR]) .And. ;
				AllTrim(aRows[nSaved, 6]) == AllTrim(aLinha[ZM_DOC]) .And. ;
				AllTrim(aRows[nSaved, 7]) == AllTrim(aLinha[ZM_SERIE]) .And. ;
				AllTrim(aRows[nSaved, 8]) == AllTrim(aLinha[ZM_ITEM])
				nMatch := nSelect
				Exit
			EndIf
		Next nSelect
		If nMatch == 0 .Or. aSeen[nMatch]
			ConOut("[ZMOST][PROCESSO] ZMEntryOK SD1 item/identificador divergente; linha=" + cValToChar(nSaved))
			Return .F.
		EndIf
		aSeen[nMatch] := .T.
	Next nSaved
	For nSelect := 1 To Len(aSeen)
		If !aSeen[nSelect]
			Return .F.
		EndIf
	Next nSelect

Return .T.

Static Function ZMOrderOK(cPedido, cCliente, cLoja, cRep, aState, aSelecionados, aOperacoes)

	Local cQuery := ""
	Local aRows := {}
	Local aObs := {}
	Local aLinha := {}
	Local nItem := 0

	aObs := ZMOrigObs(aState, aSelecionados)
	If !Empty(aObs[2])
		Return .F.
	EndIf
	cQuery := "SELECT C5_CLIENTE, C5_LOJACLI, C5_VEND1, C5_NOTA, C5_ZZORIGE, C5_ZZTPPED, C5_ZZOBS FROM " + RetSqlName("SC5")
	cQuery += " WHERE C5_FILIAL = " + ZMSql(xFilial("SC5")) + " AND C5_NUM = " + ZMSql(cPedido) + " AND D_E_L_E_T_ = ' '
	aRows := ZMRows(cQuery)
	If Len(aRows) != 1
		Return .F.
	EndIf
	If AllTrim(aRows[1, 1]) != AllTrim(cCliente) .Or. AllTrim(aRows[1, 2]) != AllTrim(cLoja) .Or. ;
		AllTrim(aRows[1, 3]) != AllTrim(cRep) .Or. !Empty(aRows[1, 4]) .Or. ;
		AllTrim(aRows[1, 5]) != "TRA" .Or. AllTrim(aRows[1, 6]) != "TR" .Or. AllTrim(aRows[1, 7]) != AllTrim(aObs[1])
		Return .F.
	EndIf
	cQuery := "SELECT C6_PRODUTO, C6_QTDVEN, C6_UM, C6_PRCVEN, C6_TES, C6_LOCAL, C6_OPER FROM " + RetSqlName("SC6")
	cQuery += " WHERE C6_FILIAL = " + ZMSql(xFilial("SC6")) + " AND C6_NUM = " + ZMSql(cPedido) + " AND D_E_L_E_T_ = ' ' ORDER BY C6_ITEM"
	aRows := ZMRows(cQuery)
	If Len(aRows) != Len(aSelecionados)
		Return .F.
	EndIf
	For nItem := 1 To Len(aRows)
		aLinha := aState[1, aSelecionados[nItem]]
		If AllTrim(aRows[nItem, 1]) != AllTrim(aLinha[ZM_PROD]) .Or. ;
			Abs(aRows[nItem, 2] - aLinha[ZM_QTSEL]) > 0.000001 .Or. ;
			AllTrim(aRows[nItem, 3]) != AllTrim(aLinha[ZM_UM]) .Or. ;
			Abs(aRows[nItem, 4] - aLinha[ZM_PRECO]) > 0.000001 .Or. ;
			AllTrim(aRows[nItem, 5]) != AllTrim(aLinha[ZM_TES]) .Or. ;
			AllTrim(aRows[nItem, 6]) != AllTrim(aLinha[ZM_LOCAL]) .Or. ;
			AllTrim(aRows[nItem, 7]) != AllTrim(aOperacoes[nItem])
			Return .F.
		EndIf
	Next nItem

Return .T.

Static Function ZMRelOrder(cPedido)

	Local aArea := GetArea()
	Local cErro := ""
	Local cChave := ""
	Local nItens := 0
	Local nRecno := 0
	Local lOk := .F.
	Local lLockC5 := .F.
	Local bError := ErrorBlock({|oErr| Break(oErr)})
	Local oError := Nil

	Begin Sequence
		ChkFile("SC5")
		ChkFile("SC6")
		ChkFile("SC9")
		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSelectArea("SC6")
		DbSetOrder(1)
		DbSelectArea("SC9")
		DbSetOrder(1)
		Begin Transaction
			Begin Sequence
				If !SC5->(DbSeek(xFilial("SC5") + PadR(cPedido, TamSX3("C5_NUM")[1])))
					Break("Pedido nao localizado para liberacao.")
				EndIf
				If SC5->(Deleted()) .Or. !Empty(SC5->C5_NOTA)
					Break("Pedido excluido ou ja faturado antes da liberacao.")
				EndIf
				If AllTrim(SC5->C5_LIBEROK) != "S"
					lLockC5 := RecLock("SC5", .F.)
					If !lLockC5
						Break("Nao foi possivel bloquear o cabecalho para liberacao.")
					EndIf
					If SC5->(Deleted()) .Or. !Empty(SC5->C5_NOTA)
						Break("Pedido alterado ou faturado durante a liberacao.")
					EndIf
					SC5->C5_LIBEROK := "S"
					SC5->(MsUnlock())
					lLockC5 := .F.
				EndIf
				cChave := xFilial("SC6") + PadR(cPedido, TamSX3("C6_NUM")[1])
				SC6->(DbSeek(cChave))
				While !SC6->(Eof()) .And. (SC6->C6_FILIAL + SC6->C6_NUM) == cChave
					If !SC6->(Deleted())
						nItens++
						If SC6->C6_QTDENT != 0 .Or. !Empty(SC6->C6_BLQ) .Or. !Empty(SC6->C6_NOTA)
							Break("Item atendido, bloqueado ou faturado antes da liberacao: " + AllTrim(SC6->C6_ITEM))
						EndIf
						nRecno := SC6->(RecNo())
						ConOut("[ZMOST][LIBERACAO] MaLibDoFat antes; pedido=" + AllTrim(cPedido) + "; item=" + AllTrim(SC6->C6_ITEM) + "; recno=" + cValToChar(nRecno) + "; qtd=" + cValToChar(SC6->C6_QTDVEN))
						MaLibDoFat(SC6->(RecNo()), SC6->C6_QTDVEN, , , .T., .T., .F., .F.)
						ConOut("[ZMOST][LIBERACAO] MaLibDoFat depois; pedido=" + AllTrim(cPedido) + "; item=" + AllTrim(SC6->C6_ITEM) + "; recno=" + cValToChar(nRecno))
					EndIf
					SC6->(DbSkip())
				EndDo
				If nItens == 0
					Break("Pedido sem itens ativos para liberar.")
				EndIf
				ConOut("[ZMOST][LIBERACAO] Conferencia SC9 antes; pedido=" + AllTrim(cPedido) + "; itens=" + cValToChar(nItens))
				If !ZMRelOK(cPedido, @cErro)
					Break(cErro)
				EndIf
				ConOut("[ZMOST][LIBERACAO] Conferencia SC9 depois; pedido=" + AllTrim(cPedido) + "; liberacao integral confirmada")
				lOk := .T.
			Recover Using oError
				cErro := ZMError(oError)
				If Empty(cErro)
					cErro := "Falha sem descricao durante a liberacao MaLibDoFat."
				EndIf
				DisarmTransaction()
			End Sequence
		End Transaction
	Recover Using oError
		cErro := ZMError(oError)
	End Sequence
	If lLockC5
		DbSelectArea("SC5")
		SC5->(MsUnlock())
	EndIf
	RestArea(aArea)
	ErrorBlock(bError)
	If !lOk .And. Empty(cErro)
		cErro := "Liberacao nao confirmada integralmente em SC9."
	EndIf

Return cErro

Static Function ZMRelOK(cPedido, cErro)

	Local cChave := ""
	Local cChaveC9 := ""
	Local nItens := 0
	Local nLiberado := 0

	cErro := ""
	DbSelectArea("SC5")
	DbSetOrder(1)
	If !SC5->(DbSeek(xFilial("SC5") + PadR(cPedido, TamSX3("C5_NUM")[1])))
		cErro := "Pedido nao localizado apos MaLibDoFat."
		Return .F.
	EndIf
	If SC5->(Deleted()) .Or. !Empty(SC5->C5_NOTA) .Or. AllTrim(SC5->C5_LIBEROK) != "S"
		cErro := "Cabecalho excluido, faturado ou sem liberacao confirmada."
		Return .F.
	EndIf
	cChave := xFilial("SC6") + PadR(cPedido, TamSX3("C6_NUM")[1])
	DbSelectArea("SC6")
	DbSetOrder(1)
	If !SC6->(DbSeek(cChave))
		cErro := "Itens do pedido nao localizados apos MaLibDoFat."
		Return .F.
	EndIf
	While !SC6->(Eof()) .And. (SC6->C6_FILIAL + SC6->C6_NUM) == cChave
		If !SC6->(Deleted())
			nItens++
			If SC6->C6_QTDENT != 0 .Or. !Empty(SC6->C6_BLQ) .Or. !Empty(SC6->C6_NOTA)
				cErro := "Item atendido, bloqueado ou faturado apos liberacao: " + AllTrim(SC6->C6_ITEM)
				Return .F.
			EndIf
			cChaveC9 := xFilial("SC9") + SC6->C6_NUM + SC6->C6_ITEM
			DbSelectArea("SC9")
			DbSetOrder(1)
			SC9->(DbSeek(cChaveC9))
			nLiberado := 0
			While !SC9->(Eof()) .And. (SC9->C9_FILIAL + SC9->C9_PEDIDO + SC9->C9_ITEM) == cChaveC9
				If !SC9->(Deleted())
					If SC9->C9_PRODUTO != SC6->C6_PRODUTO .Or. !Empty(SC9->C9_BLCRED) .Or. ;
						!Empty(SC9->C9_BLEST) .Or. !Empty(SC9->C9_NFISCAL) .Or. SC9->C9_QTDLIB <= 0
						cErro := "SC9 bloqueada, faturada ou divergente no item " + AllTrim(SC6->C6_ITEM)
						Return .F.
					EndIf
					nLiberado += SC9->C9_QTDLIB
				EndIf
				SC9->(DbSkip())
			EndDo
			If Abs(nLiberado - SC6->C6_QTDVEN) > 0.000001
				cErro := "Quantidade liberada em SC9 diverge do pedido no item " + AllTrim(SC6->C6_ITEM)
				Return .F.
			EndIf
		EndIf
		DbSelectArea("SC6")
		SC6->(DbSkip())
	EndDo
	If nItens == 0
		cErro := "Pedido sem itens ativos apos liberacao."
		Return .F.
	EndIf

Return .T.

Static Function ZMInvoice(cPedido, cSerie, dEntrega)

	Local aArea := GetArea()
	Local aPvl := {}
	Local aLocks := {}
	Local aLog := {}
	Local cDoc := ""
	Local cErro := ""
	Local cChave := ""
	Local cChaveC9 := ""
	Local cFuncao := FunName()
	Local nRecno := 0
	Local nLiberado := 0
	Local nPreco := 0
	Local lLockC5 := .F.
	Local bError := ErrorBlock({|oErr| Break(oErr)})
	Local oError := Nil

	Begin Sequence
		ChkFile("SC5")
		ChkFile("SC6")
		ChkFile("SC9")
		ChkFile("SE4")
		ChkFile("SB1")
		ChkFile("SB2")
		ChkFile("SF4")
		DbSelectArea("SC5")
		DbSetOrder(1)
		DbSelectArea("SC6")
		DbSetOrder(1)
		DbSelectArea("SC9")
		DbSetOrder(1)
		DbSelectArea("SE4")
		DbSetOrder(1)
		DbSelectArea("SB1")
		DbSetOrder(1)
		DbSelectArea("SB2")
		DbSetOrder(1)
		DbSelectArea("SF4")
		DbSetOrder(1)
		Begin Transaction
			Begin Sequence
				DbSelectArea("SC5")
				If !SC5->(DbSeek(xFilial("SC5") + PadR(cPedido, TamSX3("C5_NUM")[1])))
					Break("Pedido nao encontrado para faturamento.")
				EndIf
				If SC5->(Deleted()) .Or. !Empty(SC5->C5_NOTA) .Or. AllTrim(SC5->C5_LIBEROK) != "S"
					Break("Pedido excluido, faturado ou sem liberacao integral.")
				EndIf
				lLockC5 := RecLock("SC5", .F.)
				If !lLockC5
					Break("Pedido ocupado por outra execucao. Faturamento interrompido.")
				EndIf
				If SC5->(Deleted()) .Or. !Empty(SC5->C5_NOTA) .Or. AllTrim(SC5->C5_LIBEROK) != "S"
					Break("Pedido alterado ou faturado antes do MATA461.")
				EndIf
				If !SE4->(DbSeek(xFilial("SE4") + SC5->C5_CONDPAG))
					Break("Condicao de pagamento do pedido nao encontrada.")
				EndIf
				cChave := xFilial("SC6") + PadR(cPedido, TamSX3("C6_NUM")[1])
				DbSelectArea("SC6")
				SC6->(DbSeek(cChave))
				While !SC6->(Eof()) .And. (SC6->C6_FILIAL + SC6->C6_NUM) == cChave
					If !SC6->(Deleted())
						If SC6->C6_QTDENT != 0 .Or. !Empty(SC6->C6_BLQ) .Or. !Empty(SC6->C6_NOTA)
							Break("Item atendido, bloqueado ou faturado antes do MATA461: " + AllTrim(SC6->C6_ITEM))
						EndIf
						If !SB1->(DbSeek(xFilial("SB1") + SC6->C6_PRODUTO)) .Or. ;
							!SB2->(DbSeek(xFilial("SB2") + SC6->C6_PRODUTO + SC6->C6_LOCAL)) .Or. ;
							!SF4->(DbSeek(xFilial("SF4") + SC6->C6_TES))
							Break("Produto, armazem ou TES nao localizado no item " + AllTrim(SC6->C6_ITEM))
						EndIf
						cChaveC9 := xFilial("SC9") + SC6->C6_NUM + SC6->C6_ITEM
						DbSelectArea("SC9")
						SC9->(DbSeek(cChaveC9))
						nLiberado := 0
						While !SC9->(Eof()) .And. (SC9->C9_FILIAL + SC9->C9_PEDIDO + SC9->C9_ITEM) == cChaveC9
							If !SC9->(Deleted())
								If !Empty(SC9->C9_BLCRED) .Or. !Empty(SC9->C9_BLEST) .Or. ;
									!Empty(SC9->C9_NFISCAL) .Or. SC9->C9_PRODUTO != SC6->C6_PRODUTO .Or. SC9->C9_QTDLIB <= 0
									Break("Liberacao SC9 bloqueada, faturada ou divergente no item " + AllTrim(SC6->C6_ITEM))
								EndIf
								nPreco := SC9->C9_PRCVEN
								If nPreco <= 0 .Or. Abs(nPreco - SC6->C6_PRCVEN) > 0.000001
									Break("Preco da SC9 diverge do pedido no item " + AllTrim(SC6->C6_ITEM))
								EndIf
								nRecno := SC9->(RecNo())
								If !RecLock("SC9", .F.)
									Break("Liberacao SC9 ocupada por outra execucao.")
								EndIf
								aAdd(aLocks, nRecno)
								aAdd(aPvl, {SC9->C9_PEDIDO, SC9->C9_ITEM, SC9->C9_SEQUEN, SC9->C9_QTDLIB, nPreco, SC9->C9_PRODUTO, .F., nRecno, SC5->(RecNo()), SC6->(RecNo()), SE4->(RecNo()), SB1->(RecNo()), SB2->(RecNo()), SF4->(RecNo())})
								nLiberado += SC9->C9_QTDLIB
							EndIf
							SC9->(DbSkip())
						EndDo
						If Abs(nLiberado - SC6->C6_QTDVEN) > 0.000001
							Break("SC9 nao cobre integralmente a quantidade do item " + AllTrim(SC6->C6_ITEM))
						EndIf
					EndIf
					DbSelectArea("SC6")
					SC6->(DbSkip())
				EndDo
				If Len(aPvl) == 0
					Break("Nenhuma liberacao valida para faturar.")
				EndIf
				lMsErroAuto := .F.
				SetFunName("MATA461")
				cDoc := MaPvlNfs(aPvl, cSerie, .F., .F., .F., .T., .F., 0, 0, .T., .F., "", {||}, {||}, {||}, {|| .T.}, dDataBase, .F., , dEntrega)
				SetFunName(cFuncao)
				If ValType(cDoc) != "C" .Or. Empty(AllTrim(cDoc)) .Or. lMsErroAuto
					aLog := GetAutoGrLog()
					Break("MaPvlNfs nao confirmou a emissao: " + ZMLogAuto(aLog))
				EndIf
				cDoc := AllTrim(cDoc)
			Recover Using oError
				cErro := ZMError(oError)
				If Empty(cErro)
					cErro := "Falha sem descricao durante MATA461."
				EndIf
				DisarmTransaction()
			End Sequence
		End Transaction
	Recover Using oError
		cErro := ZMError(oError)
	End Sequence
	SetFunName(cFuncao)
	For nRecno := 1 To Len(aLocks)
		DbSelectArea("SC9")
		SC9->(DbGoTo(aLocks[nRecno]))
		SC9->(MsUnlock())
	Next nRecno
	If lLockC5
		DbSelectArea("SC5")
		SC5->(MsUnlock())
	EndIf
	RestArea(aArea)
	ErrorBlock(bError)

Return {cDoc, cErro}

Static Function ZMInvOK(cPedido, cDoc, cSerie, cCliente, cLoja, aState, aSelecionados, aEtapas, oDlg)

	Local aRows := {}
	Local aOrder := {}
	Local aQuant := {}
	Local aLinha := {}
	Local cQuery := ""
	Local nItem := 0
	Local nPos := 0

	If Empty(cDoc) .Or. Empty(cSerie) .Or. Len(aSelecionados) == 0
		ConOut("[ZMOST][PROCESSO] ZMInvOK entrada invalida")
		Return .F.
	EndIf
	ZMStage(aEtapas, 8, "[EM ANDAMENTO] Conferindo cabecalho SF2.", oDlg)
	cQuery := "SELECT F2_CLIENTE, F2_LOJA FROM " + RetSqlName("SF2")
	cQuery += " WHERE F2_FILIAL = " + ZMSql(xFilial("SF2")) + " AND F2_DOC = " + ZMSql(cDoc)
	cQuery += " AND F2_SERIE = " + ZMSql(cSerie) + " AND F2_CLIENTE = " + ZMSql(cCliente)
	cQuery += " AND F2_LOJA = " + ZMSql(cLoja) + " AND D_E_L_E_T_ = ' '
	ConOut("[ZMOST][PROCESSO] ZMInvOK SF2 antes; doc=" + AllTrim(cDoc) + "/" + AllTrim(cSerie))
	aRows := ZMRows(cQuery)
	ConOut("[ZMOST][PROCESSO] ZMInvOK SF2 depois; registros=" + cValToChar(Len(aRows)))
	If Len(aRows) != 1
		ConOut("[ZMOST][PROCESSO] ZMInvOK SF2 cardinalidade divergente")
		Return .F.
	EndIf
	If AllTrim(aRows[1, 1]) != AllTrim(cCliente) .Or. AllTrim(aRows[1, 2]) != AllTrim(cLoja)
		ConOut("[ZMOST][PROCESSO] ZMInvOK SF2 cliente/loja divergente")
		Return .F.
	EndIf
	ZMStage(aEtapas, 8, "[EM ANDAMENTO] Conferindo vinculo do pedido SC5.", oDlg)
	cQuery := "SELECT C5_NOTA FROM " + RetSqlName("SC5") + " WHERE C5_FILIAL = " + ZMSql(xFilial("SC5"))
	cQuery += " AND C5_NUM = " + ZMSql(cPedido) + " AND D_E_L_E_T_ = ' '
	ConOut("[ZMOST][PROCESSO] ZMInvOK SC5 antes; pedido=" + AllTrim(cPedido))
	aRows := ZMRows(cQuery)
	ConOut("[ZMOST][PROCESSO] ZMInvOK SC5 depois; registros=" + cValToChar(Len(aRows)))
	If Len(aRows) != 1
		ConOut("[ZMOST][PROCESSO] ZMInvOK SC5 cardinalidade divergente")
		Return .F.
	EndIf
	If AllTrim(aRows[1, 1]) != AllTrim(cDoc)
		ConOut("[ZMOST][PROCESSO] ZMInvOK SC5 nota divergente; nota=" + AllTrim(aRows[1, 1]))
		Return .F.
	EndIf
	ZMStage(aEtapas, 8, "[EM ANDAMENTO] Conferindo itens do pedido SC6.", oDlg)
	cQuery := "SELECT C6_ITEM, C6_PRODUTO, C6_QTDVEN FROM " + RetSqlName("SC6")
	cQuery += " WHERE C6_FILIAL = " + ZMSql(xFilial("SC6")) + " AND C6_NUM = " + ZMSql(cPedido)
	cQuery += " AND D_E_L_E_T_ = ' ' ORDER BY C6_ITEM"
	ConOut("[ZMOST][PROCESSO] ZMInvOK SC6 antes; pedido=" + AllTrim(cPedido))
	aOrder := ZMRows(cQuery)
	ConOut("[ZMOST][PROCESSO] ZMInvOK SC6 depois; registros=" + cValToChar(Len(aOrder)) + "; esperado=" + cValToChar(Len(aSelecionados)))
	If Len(aOrder) != Len(aSelecionados)
		ConOut("[ZMOST][PROCESSO] ZMInvOK SC6 quantidade divergente")
		Return .F.
	EndIf
	ZMStage(aEtapas, 8, "[EM ANDAMENTO] Conferindo itens faturados SD2.", oDlg)
	cQuery := "SELECT D2_ITEMPV, D2_COD, D2_QUANT FROM " + RetSqlName("SD2")
	cQuery += " WHERE D2_FILIAL = " + ZMSql(xFilial("SD2")) + " AND D2_DOC = " + ZMSql(cDoc)
	cQuery += " AND D2_SERIE = " + ZMSql(cSerie) + " AND D2_CLIENTE = " + ZMSql(cCliente)
	cQuery += " AND D2_LOJA = " + ZMSql(cLoja) + " AND D2_PEDIDO = " + ZMSql(cPedido) + " AND D_E_L_E_T_ = ' '
	ConOut("[ZMOST][PROCESSO] ZMInvOK SD2 antes; doc=" + AllTrim(cDoc) + "/" + AllTrim(cSerie) + "; pedido=" + AllTrim(cPedido))
	aRows := ZMRows(cQuery)
	ConOut("[ZMOST][PROCESSO] ZMInvOK SD2 depois; registros=" + cValToChar(Len(aRows)))
	If Len(aRows) == 0
		ConOut("[ZMOST][PROCESSO] ZMInvOK SD2 sem itens")
		Return .F.
	EndIf
	AFill(aQuant, 0)
	For nItem := 1 To Len(aOrder)
		aAdd(aQuant, 0)
	Next nItem
	For nItem := 1 To Len(aRows)
		nPos := AScan(aOrder, {|aItem| AllTrim(aItem[1]) == AllTrim(aRows[nItem, 1]) .And. AllTrim(aItem[2]) == AllTrim(aRows[nItem, 2])})
		If nPos == 0
			ConOut("[ZMOST][PROCESSO] ZMInvOK SD2 item sem SC6 correspondente; itemPedido=" + AllTrim(aRows[nItem, 1]) + "; produto=" + AllTrim(aRows[nItem, 2]))
			Return .F.
		EndIf
		aQuant[nPos] += aRows[nItem, 3]
	Next nItem
	ZMStage(aEtapas, 8, "[EM ANDAMENTO] Conciliando quantidades e produtos SC6/SD2.", oDlg)
	For nItem := 1 To Len(aOrder)
		aLinha := aState[1, aSelecionados[nItem]]
		If AllTrim(aOrder[nItem, 2]) != AllTrim(aLinha[ZM_PROD]) .Or. ;
			Abs(aOrder[nItem, 3] - aLinha[ZM_QTSEL]) > 0.000001 .Or. ;
			Abs(aQuant[nItem] - aOrder[nItem, 3]) > 0.000001
			ConOut("[ZMOST][PROCESSO] ZMInvOK SC6/SD2 divergente; item=" + AllTrim(aOrder[nItem, 1]) + "; produto=" + AllTrim(aOrder[nItem, 2]) + "; qtdPedido=" + cValToChar(aOrder[nItem, 3]) + "; qtdSelecionada=" + cValToChar(aLinha[ZM_QTSEL]) + "; qtdFaturada=" + cValToChar(aQuant[nItem]))
			Return .F.
		EndIf
	Next nItem
	ConOut("[ZMOST][PROCESSO] ZMInvOK validacao concluida; pedido=" + AllTrim(cPedido) + "; documento=" + AllTrim(cDoc) + "; itens=" + cValToChar(Len(aSelecionados)))

Return .T.

Static Function ZMLogAuto(aLog)

	Local cTexto := ""
	Local nItem := 0

	For nItem := 1 To Len(aLog)
		cTexto += cValToChar(aLog[nItem]) + " "
		ConOut("[ZMOST][AUTO] " + cValToChar(aLog[nItem]))
	Next nItem

Return AllTrim(cTexto)

Static Function ZMDetRow(aState, nPos)

	Local aLinha := {}
	Local cTexto := ""

	If aState[3] .Or. nPos < 1 .Or. nPos > Len(aState[1])
		Return Nil
	EndIf
	aLinha := aState[1, nPos]
	cTexto := "Cliente: " + AllTrim(aLinha[ZM_CLIENT]) + "/" + AllTrim(aLinha[ZM_LOJA]) + " - " + AllTrim(aLinha[ZM_NOME]) + CRLF
	cTexto += "Representante: " + AllTrim(aLinha[ZM_REP]) + " - " + AllTrim(aLinha[ZM_REPNOM]) + CRLF
	cTexto += "Nota: " + AllTrim(aLinha[ZM_DOC]) + "/" + AllTrim(aLinha[ZM_SERIE]) + " | Item: " + AllTrim(aLinha[ZM_ITEM]) + " | Emissao: " + DtoC(aLinha[ZM_EMIS]) + CRLF
	cTexto += "Produto: " + AllTrim(aLinha[ZM_PROD]) + " - " + AllTrim(aLinha[ZM_DESC]) + CRLF
	cTexto += "Identificador: " + AllTrim(aLinha[ZM_IDENT]) + " | Recno SB6: " + cValToChar(aLinha[ZM_RECNO]) + CRLF
	cTexto += "Periodo: " + DtoC(aLinha[ZM_INI]) + " a " + DtoC(aLinha[ZM_FIM]) + CRLF
	cTexto += "Saldo usado (" + aState[6] + "): " + cValToChar(aLinha[ZM_SALDO]) + " | Armazenado atual: " + cValToChar(aLinha[ZM_ARMAZ]) + " | Original: " + cValToChar(aLinha[ZM_QUANT]) + " " + AllTrim(aLinha[ZM_UM]) + CRLF
	cTexto += "TES saida/retorno: " + AllTrim(aLinha[ZM_TES]) + "/" + AllTrim(aLinha[ZM_RETOR]) + CRLF
	cTexto += "Fornecedor MATA103 (SA2): " + AllTrim(aLinha[ZM_SA2COD]) + "/" + AllTrim(aLinha[ZM_SA2LOJA]) + CRLF
	If !Empty(aLinha[ZM_SA2MSG])
		cTexto += "Pendencia do fornecedor: " + aLinha[ZM_SA2MSG] + CRLF
	EndIf
	cTexto += "Armazem: " + AllTrim(aLinha[ZM_LOCAL]) + " | Lote: " + AllTrim(aLinha[ZM_LOTE]) + " | Preco original: " + cValToChar(aLinha[ZM_PRECO]) + CRLF
	cTexto += "Produto: " + aLinha[ZM_CLASSE] + " | Data descontinuacao: " + DtoC(aLinha[ZM_DTDES]) + CRLF
	cTexto += "Situacao: " + aLinha[ZM_STATUS] + " | " + aLinha[ZM_MSG] + CRLF
	cTexto += "Situacao fiscal: nao validada. Vinculo documental por CPF/CNPJ, sem validar digitos verificadores." + CRLF
	cTexto += ZMReturns(aLinha)
	FWAlertInfo(cTexto, "Detalhes da origem")

Return Nil

Static Function ZMReturns(aLinha)

	Local aArea := GetArea()
	Local cAlias := GetNextAlias()
	Local cQuery := ""
	Local cTexto := CRLF + "Retornos no periodo:" + CRLF
	Local nRetornos := 0
	Local bError := ErrorBlock({|oErr| Break(oErr)})
	Local oError := Nil

	Begin Sequence
		cQuery := "SELECT B6_DOC, B6_SERIE, B6_QUANT, B6_DTDIGIT FROM " + RetSqlName("SB6")
		cQuery += " WHERE B6_FILIAL = " + ZMSql(xFilial("SB6")) + " AND D_E_L_E_T_ = ' '"
		cQuery += " AND B6_IDENT = " + ZMSql(aLinha[ZM_IDENT]) + " AND B6_PRODUTO = " + ZMSql(aLinha[ZM_PROD])
		cQuery += " AND B6_CLIFOR = " + ZMSql(aLinha[ZM_CLIENT]) + " AND B6_LOJA = " + ZMSql(aLinha[ZM_LOJA])
		cQuery += " AND B6_TPCF = 'C' AND B6_PODER3 = 'D'"
		cQuery += " AND B6_DTDIGIT >= " + ZMSql(DtoS(aLinha[ZM_INI])) + " AND B6_DTDIGIT <= " + ZMSql(DtoS(aLinha[ZM_FIM]))
		cQuery += " ORDER BY B6_DTDIGIT, B6_DOC, B6_SERIE"
		DbUseArea(.T., "TOPCONN", TcGenQry(,,ChangeQuery(cQuery)), cAlias, .F., .T.)
		While !(cAlias)->(Eof())
			nRetornos++
			If nRetornos <= 10
				cTexto += AllTrim((cAlias)->B6_DOC) + "/" + AllTrim((cAlias)->B6_SERIE) + " | " + DtoC(StoD((cAlias)->B6_DTDIGIT)) + " | Qtd.: " + cValToChar((cAlias)->B6_QUANT) + CRLF
			EndIf
			(cAlias)->(DbSkip())
		EndDo
		If nRetornos == 0
			cTexto += "Nenhum retorno localizado no recorte."
		ElseIf nRetornos > 10
			cTexto += "Mais " + cValToChar(nRetornos - 10) + " registros; consultar MATR480 para listagem integral."
		EndIf
	Recover Using oError
		cTexto := CRLF + "Consulta de retornos nao concluida: " + ZMError(oError)
	End Sequence
	If Select(cAlias) > 0
		(cAlias)->(DbCloseArea())
	EndIf
	RestArea(aArea)
	ErrorBlock(bError)

Return cTexto

Static Function ZMOSCON(aFiltro)

	Local aArea     := GetArea()
	Local aAreas    := {}
	Local aAliases  := {"SB6", "SB1", "SF4", "SA1", "SA2", "SA3", "SD2", "SF2"}
	Local aLinhas   := {}
	Local aReps     := {}
	Local aSuppliers := {}
	Local aRep      := {}
	Local aSupplier := {}
	Local aSaldo    := {}
	Local aLinha    := {}
	Local aEstrut   := {}
	Local cAlias    := GetNextAlias()
	Local cRepAlias := GetNextAlias()
	Local cQuery    := ""
	Local cErro     := ""
	Local cDocRep   := ""
	Local cMensagem := ""
	Local cClasse   := ""
	Local dInicio   := StoD("")
	Local dFim      := StoD("")
	Local dDescont  := StoD("")
	Local lB6Mode   := .F.
	Local cSaldoModo := ""
	Local nAlias    := 0
	Local nCampo    := 0
	Local nLidos    := 0
	Local nB6Pos    := 0
	Local nEstPos   := 0
	Local nDif      := 0
	Local nUltRec   := 0
	Local nUltLinha := 0
	Local nPos      := 0
	Local bError    := ErrorBlock({|oErr| Break(oErr)})
	Local oError    := Nil

	Begin Sequence
		If ValType(aFiltro) != "A"
			Break("Informe um array de filtros.")
		EndIf
		If Len(aFiltro) != 10
			Break("Filtros: cliente, loja, representante, nota, serie, produto, data inicial, data final, TES e classe.")
		EndIf
		For nCampo := 1 To 6
			If ValType(aFiltro[nCampo]) != "C"
				Break("Filtro textual invalido na posicao " + cValToChar(nCampo) + ".")
			EndIf
		Next nCampo
		If ValType(aFiltro[7]) != "D" .Or. ValType(aFiltro[8]) != "D"
			Break("Informe datas validas para o calculo do saldo.")
		EndIf
		dInicio := aFiltro[7]
		dFim := aFiltro[8]
		If Empty(dInicio) .Or. Empty(dFim) .Or. dInicio > dFim .Or. dFim > Date()
			Break("Periodo invalido: informe datas preenchidas, em ordem e sem data final futura.")
		EndIf
		lB6Mode := ZMB6Mode(dInicio, dFim)
		cSaldoModo := IIf(lB6Mode, "B6_SALDO", "ESTCalcTerc")
		If ValType(aFiltro[9]) != "C" .Or. ValType(aFiltro[10]) != "N"
			Break("Informe a TES e a classificacao de produtos.")
		EndIf
		If aFiltro[10] < 1 .Or. aFiltro[10] > 3
			Break("Informe a classe Todos, Ativos ou Descontinuados.")
		EndIf
		If !Empty(aFiltro[2]) .And. Empty(aFiltro[1])
			Break("Informe o cliente para filtrar uma loja.")
		EndIf
		For nAlias := 1 To Len(aAliases)
			If Select(aAliases[nAlias]) == 0
				ChkFile(aAliases[nAlias])
			EndIf
			If Select(aAliases[nAlias]) == 0
				Break("Alias indisponivel: " + aAliases[nAlias])
			EndIf
			aAdd(aAreas, (aAliases[nAlias])->(GetArea()))
		Next nAlias
		If SB1->(FieldPos("B1_ZZDTDES")) == 0
			Break("Campo B1_ZZDTDES ausente no dicionario de produtos.")
		EndIf

		cQuery := "SELECT A3_COD, A3_NOME, A3_CGC, A3_MSBLQL FROM " + RetSqlName("SA3")
		cQuery += " WHERE A3_FILIAL = " + ZMSql(xFilial("SA3")) + " AND D_E_L_E_T_ = ' '"
		DbUseArea(.T., "TOPCONN", TcGenQry(,,ChangeQuery(cQuery)), cRepAlias, .F., .T.)
		While !(cRepAlias)->(Eof())
			aAdd(aReps, {ZMDoc((cRepAlias)->A3_CGC), (cRepAlias)->A3_COD, (cRepAlias)->A3_NOME, (cRepAlias)->A3_MSBLQL})
			(cRepAlias)->(DbSkip())
		EndDo
		(cRepAlias)->(DbCloseArea())
		cQuery := "SELECT A2_COD, A2_LOJA, A2_CGC, A2_MSBLQL FROM " + RetSqlName("SA2")
		cQuery += " WHERE A2_FILIAL = " + ZMSql(xFilial("SA2")) + " AND D_E_L_E_T_ = ' '"
		DbUseArea(.T., "TOPCONN", TcGenQry(,,ChangeQuery(cQuery)), cRepAlias, .F., .T.)
		While !(cRepAlias)->(Eof())
			aAdd(aSuppliers, {ZMDoc((cRepAlias)->A2_CGC), (cRepAlias)->A2_COD, (cRepAlias)->A2_LOJA, (cRepAlias)->A2_MSBLQL})
			(cRepAlias)->(DbSkip())
		EndDo
		(cRepAlias)->(DbCloseArea())
		If !Empty(aFiltro[3])
			nPos := AScan(aReps, {|aRegistro| AllTrim(aRegistro[2]) == AllTrim(aFiltro[3])})
			If nPos == 0
				Break("Representante nao encontrado na filial de cadastro.")
			EndIf
			cDocRep := aReps[nPos, 1]
			If Empty(cDocRep)
				Break("Representante sem documento valido para o vinculo com SA1.")
			EndIf
		EndIf

		cQuery := ZMQuery(aFiltro, cDocRep)
		DbUseArea(.T., "TOPCONN", TcGenQry(,,ChangeQuery(cQuery)), cAlias, .F., .T.)
		aEstrut := SB6->(DbStruct())
		For nCampo := 1 To Len(aEstrut)
			If aEstrut[nCampo, 2] != "C" .And. (cAlias)->(FieldPos(aEstrut[nCampo, 1])) > 0
				TcSetField(cAlias, aEstrut[nCampo, 1], aEstrut[nCampo, 2], aEstrut[nCampo, 3], aEstrut[nCampo, 4])
			EndIf
		Next nCampo
		TcSetField(cAlias, "DTDES", "D", 8, 0)
		While !(cAlias)->(Eof())
			If (cAlias)->ORIGREC == nUltRec
				If nUltLinha > 0
					aLinhas[nUltLinha, ZM_STATUS] := "PENDENTE"
					aLinhas[nUltLinha, ZM_MSG] += " Origem fiscal ambigua em SF2/SD2."
				EndIf
				(cAlias)->(DbSkip())
				Loop
			EndIf
			nUltRec := (cAlias)->ORIGREC
			nUltLinha := 0
			nLidos++
			If nLidos > ZM_LIMIT
				Break("Consulta excede " + cValToChar(ZM_LIMIT) + " origens. Refine os filtros; nenhum resultado parcial foi aceito.")
			EndIf
			If lB6Mode
				aSaldo := {(cAlias)->B6_SALDO}
			Else
				aSaldo := (cAlias)->(ESTCalcTerc(B6_PRODUTO, B6_CLIFOR, B6_LOJA, B6_IDENT, B6_TES, , dInicio, dFim))
			EndIf
			If ValType(aSaldo) != "A"
				Break("ESTCalcTerc nao retornou um array para a origem " + AllTrim((cAlias)->B6_IDENT))
			EndIf
			If Len(aSaldo) == 0
				Break("ESTCalcTerc retornou saldo vazio.")
			EndIf
			If ValType(aSaldo[1]) != "N"
				Break("ESTCalcTerc retornou quantidade invalida.")
			EndIf
			If (cAlias)->B6_SALDO > 0
				nB6Pos++
			EndIf
			If !lB6Mode
				If aSaldo[1] > 0
					nEstPos++
				EndIf
				If Abs(aSaldo[1] - (cAlias)->B6_SALDO) > 0.000001
					nDif++
				EndIf
			EndIf
			If aSaldo[1] <= 0
				(cAlias)->(DbSkip())
				Loop
			EndIf
			dDescont := (cAlias)->DTDES
			cClasse := ZMClass(dDescont, dFim)
			If (aFiltro[10] == 2 .And. cClasse != "ATIVO") .Or. (aFiltro[10] == 3 .And. cClasse != "DESCONTINUADO")
				(cAlias)->(DbSkip())
				Loop
			EndIf
			aRep := ZMRep(aReps, (cAlias)->CGCCLI)
			aSupplier := ZMSupplier(aSuppliers, (cAlias)->CGCCLI)
			cMensagem := aRep[3]
			If Empty((cAlias)->NOMECLI)
				cMensagem += " Cliente inexistente ou excluido."
			EndIf
			If Empty((cAlias)->DESCPRO)
				cMensagem += " Produto inexistente ou excluido."
			EndIf
			If (cAlias)->BLQPRO == "1"
				cMensagem += " Produto bloqueado."
			EndIf
			If (cAlias)->BLQCLI == "1"
				cMensagem += " Cliente bloqueado."
			EndIf
			If Empty((cAlias)->TESRET)
				cMensagem += " TES sem devolucao vinculada."
			EndIf
			If (cAlias)->TESBLQ == "1" .Or. (cAlias)->OUTPODER != "R"
				cMensagem += " TES de saida bloqueada ou sem poder de terceiros R."
			EndIf
			If Empty((cAlias)->RETCOD) .Or. (cAlias)->RETPODER != "D" .Or. (cAlias)->RETBLQ == "1"
				cMensagem += " TES de retorno ausente, bloqueada ou sem poder de terceiros D."
			EndIf
			If Empty((cAlias)->ITEMORI) .Or. Empty((cAlias)->ITEMPED) .Or. Empty((cAlias)->DOCFISC)
				cMensagem += " Origem fiscal nao localizada pelo identificador em SF2/SD2."
			EndIf
			If Empty((cAlias)->B6_IDENT)
				cMensagem += " Identificador de terceiros vazio."
			EndIf
			aLinha := {IIf(Empty(cMensagem), "CONFERIR", "PENDENTE"), AllTrim(cMensagem), (cAlias)->B6_CLIFOR, (cAlias)->B6_LOJA, (cAlias)->NOMECLI, aRep[1], aRep[2], (cAlias)->B6_DOC, (cAlias)->B6_SERIE, (cAlias)->ITEMORI, (cAlias)->B6_PRODUTO, (cAlias)->DESCPRO, (cAlias)->B6_UM, aSaldo[1], (cAlias)->B6_SALDO, (cAlias)->B6_QUANT, dDescont, cClasse, (cAlias)->B6_TES, (cAlias)->TESRET, (cAlias)->B6_IDENT, (cAlias)->B6_LOCAL, (cAlias)->LOTEORI, (cAlias)->PRECOORI, (cAlias)->ORIGREC, .F., 0, "", (cAlias)->B6_EMISSAO, dInicio, dFim, aSupplier[1], aSupplier[2], aSupplier[3], (cAlias)->ORIGPED, (cAlias)->ITEMPED}
			aAdd(aLinhas, aLinha)
			nUltLinha := Len(aLinhas)
			(cAlias)->(DbSkip())
		EndDo
	Recover Using oError
		cErro := ZMError(oError)
		aLinhas := {}
	End Sequence
	If Select(cAlias) > 0
		(cAlias)->(DbCloseArea())
	EndIf
	If Select(cRepAlias) > 0
		(cRepAlias)->(DbCloseArea())
	EndIf
	For nAlias := Len(aAreas) To 1 Step -1
		RestArea(aAreas[nAlias])
	Next nAlias
	RestArea(aArea)
	ErrorBlock(bError)

Return {Empty(cErro), aLinhas, cErro, nLidos, nB6Pos, nEstPos, nDif, cSaldoModo}

Static Function ZMQuery(aFiltro, cDocRep)

	Local cQuery := "SELECT B.*, B.R_E_C_N_O_ AS ORIGREC, A.A1_NOME AS NOMECLI, A.A1_CGC AS CGCCLI, A.A1_MSBLQL AS BLQCLI, "
	Local aCampos := {"B.B6_CLIFOR", "B.B6_LOJA", "", "B.B6_DOC", "B.B6_SERIE", "B.B6_PRODUTO"}
	Local nCampo := 0

	cQuery += "P.B1_DESC AS DESCPRO, P.B1_ZZDTDES AS DTDES, P.B1_MSBLQL AS BLQPRO, T.F4_TESDV AS TESRET, T.F4_MSBLQL AS TESBLQ, T.F4_PODER3 AS OUTPODER, "
	cQuery += "R.F4_CODIGO AS RETCOD, R.F4_PODER3 AS RETPODER, R.F4_MSBLQL AS RETBLQ, "
	cQuery += "D.D2_ITEM AS ITEMORI, D.D2_ITEMPV AS ITEMPED, D.D2_LOTECTL AS LOTEORI, D.D2_PRCVEN AS PRECOORI, D.D2_PEDIDO AS ORIGPED, F.F2_DOC AS DOCFISC "
	cQuery += "FROM " + RetSqlName("SB6") + " B "
	cQuery += "LEFT JOIN " + RetSqlName("SA1") + " A ON A.A1_FILIAL = " + ZMSql(xFilial("SA1"))
	cQuery += " AND A.A1_COD = B.B6_CLIFOR AND A.A1_LOJA = B.B6_LOJA AND A.D_E_L_E_T_ = ' ' "
	cQuery += "LEFT JOIN " + RetSqlName("SB1") + " P ON P.B1_FILIAL = " + ZMSql(xFilial("SB1"))
	cQuery += " AND P.B1_COD = B.B6_PRODUTO AND P.D_E_L_E_T_ = ' ' "
	cQuery += "INNER JOIN " + RetSqlName("SF4") + " T ON T.F4_FILIAL = " + ZMSql(xFilial("SF4"))
	cQuery += " AND T.F4_CODIGO = B.B6_TES AND T.F4_PODER3 <> 'D' AND T.D_E_L_E_T_ = ' ' "
	cQuery += "LEFT JOIN " + RetSqlName("SF4") + " R ON R.F4_FILIAL = " + ZMSql(xFilial("SF4"))
	cQuery += " AND R.F4_CODIGO = T.F4_TESDV AND R.D_E_L_E_T_ = ' ' "
	cQuery += "LEFT JOIN " + RetSqlName("SD2") + " D ON D.D2_FILIAL = " + ZMSql(xFilial("SD2"))
	cQuery += " AND D.D2_DOC = B.B6_DOC AND D.D2_SERIE = B.B6_SERIE AND D.D2_CLIENTE = B.B6_CLIFOR "
	cQuery += " AND D.D2_LOJA = B.B6_LOJA AND D.D2_COD = B.B6_PRODUTO AND D.D2_TES = B.B6_TES "
	cQuery += " AND D.D2_IDENTB6 = B.B6_IDENT AND D.D_E_L_E_T_ = ' ' "
	cQuery += "LEFT JOIN " + RetSqlName("SF2") + " F ON F.F2_FILIAL = " + ZMSql(xFilial("SF2"))
	cQuery += " AND F.F2_DOC = B.B6_DOC AND F.F2_SERIE = B.B6_SERIE AND F.F2_CLIENTE = B.B6_CLIFOR "
	cQuery += " AND F.F2_LOJA = B.B6_LOJA AND F.D_E_L_E_T_ = ' ' "
	cQuery += "WHERE B.B6_FILIAL = " + ZMSql(xFilial("SB6")) + " AND B.D_E_L_E_T_ = ' ' "
	cQuery += "AND B.B6_TIPO = 'E' AND B.B6_TPCF = 'C' AND B.B6_QUANT <> 0 "
	cQuery += " AND B.B6_DTDIGIT >= " + ZMSql(DtoS(aFiltro[7])) + " AND B.B6_DTDIGIT <= " + ZMSql(DtoS(aFiltro[8]))
	If !Empty(aFiltro[9])
		cQuery += " AND B.B6_TES = " + ZMSql(AllTrim(aFiltro[9]))
	EndIf
	For nCampo := 1 To Len(aCampos)
		If !Empty(aCampos[nCampo]) .And. !Empty(aFiltro[nCampo])
			cQuery += " AND " + aCampos[nCampo] + " = " + ZMSql(AllTrim(aFiltro[nCampo]))
		EndIf
	Next nCampo
	If !Empty(cDocRep)
		cQuery += " AND REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(A.A1_CGC)), '.', ''), '/', ''), '-', '') = " + ZMSql(cDocRep)
	EndIf
	cQuery += " ORDER BY B.B6_DOC, B.B6_SERIE, B.B6_CLIFOR, B.B6_LOJA, B.R_E_C_N_O_, D.D2_ITEM"

Return cQuery

Static Function ZMRep(aReps, cDocumento)

	Local cDoc     := ZMDoc(cDocumento)
	Local cCodigo  := ""
	Local cNome    := ""
	Local cStatus  := ""
	Local nRep     := 0
	Local nMatches := 0

	If Len(cDoc) != 11 .And. Len(cDoc) != 14
		Return {"", "", "CPF/CNPJ do cliente ausente ou com tamanho invalido."}
	EndIf
	For nRep := 1 To Len(aReps)
		If aReps[nRep, 1] == cDoc
			nMatches++
			cCodigo := aReps[nRep, 2]
			cNome := aReps[nRep, 3]
			cStatus := aReps[nRep, 4]
		EndIf
	Next nRep
	If nMatches == 0
		Return {"", "", "Sem representante com o mesmo documento."}
	EndIf
	If nMatches > 1
		Return {"", "", "Documento corresponde a mais de um representante."}
	EndIf
	If cStatus != "2"
		Return {cCodigo, cNome, "Representante inativo."}
	EndIf

Return {cCodigo, cNome, ""}

Static Function ZMSupplier(aSuppliers, cDocument)

	Local cDoc := ZMDoc(cDocument)
	Local cCode := ""
	Local cStore := ""
	Local cStatus := ""
	Local nSupplier := 0
	Local nMatches := 0

	If Len(cDoc) != 11 .And. Len(cDoc) != 14
		Return {"", "", "CPF/CNPJ do cliente ausente ou com tamanho invalido para SA2."}
	EndIf
	For nSupplier := 1 To Len(aSuppliers)
		If aSuppliers[nSupplier, 1] == cDoc
			nMatches++
			cCode := aSuppliers[nSupplier, 2]
			cStore := aSuppliers[nSupplier, 3]
			cStatus := aSuppliers[nSupplier, 4]
		EndIf
	Next nSupplier
	If nMatches == 0
		Return {"", "", "Nenhum fornecedor SA2 corresponde ao documento do cliente."}
	EndIf
	If nMatches > 1
		Return {"", "", "Mais de um fornecedor SA2 corresponde ao documento do cliente."}
	EndIf
	If cStatus != "2"
		Return {cCode, cStore, "Fornecedor SA2 correspondente inativo."}
	EndIf

Return {cCode, cStore, ""}

Static Function ZMNeedsSupplier(aLine)
Return aLine[ZM_DEST] == "RENOVAR" .And. !Empty(aLine[ZM_SA2MSG])

Static Function ZMModeDest(cClasse, lRenovaTodos)
Return IIf(cClasse == "DESCONTINUADO" .And. !lRenovaTodos, "FATURAR", "RENOVAR")

Static Function ZMDoc(cDocumento)

	Local cRet := ""
	Local cChar := ""
	Local nChar := 0

	If ValType(cDocumento) != "C"
		Return ""
	EndIf
	For nChar := 1 To Len(cDocumento)
		cChar := SubStr(cDocumento, nChar, 1)
		If cChar $ "0123456789"
			cRet += cChar
		EndIf
	Next nChar

Return cRet

Static Function ZMSql(cValor)
Return "'" + StrTran(cValor, "'", "''") + "'"

Static Function ZMClass(dDescont, dReferencia)
Return IIf(!Empty(dDescont) .And. dDescont <= dReferencia, "DESCONTINUADO", "ATIVO")

Static Function ZMError(oError)

	If ValType(oError) == "O"
		If ValType(oError:Operation) == "C" .And. !Empty(oError:Operation)
			Return cValToChar(oError:Description) + " | Operacao: " + AllTrim(oError:Operation)
		EndIf
		Return cValToChar(oError:Description)
	EndIf

Return cValToChar(oError)

