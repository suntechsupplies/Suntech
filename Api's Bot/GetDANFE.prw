#Include "Protheus.ch"
#Include "FileIO.ch"
#Include "RPTDEF.ch"
#Include "FWPrintSetup.ch"
#Include "TOTVS.ch"
#Include "TbIconn.ch"
#Include "Topconn.ch"
#Include "RESTFUL.ch"

//=============================================================
// REST Service: GetDanfe - DANFE extraction by invoice keys
//=============================================================
WSRESTFUL GetDanfe DESCRIPTION "NF DANFE extraction API"

	WSMETHOD POST DESCRIPTION "Extract DANFE PDF by document keys" WSSYNTAX "/getdanfe"

END WSRESTFUL

User Function GetDanfe()
Return .T.

WSMETHOD POST WSSERVICE GetDanfe

	Local lRet      := .T.
	Local cJson     := Self:GetContent()
	Local oReq      := JsonObject():New()
	Local cDoc      := ""
	Local cSerie    := ""
	Local cCliente  := ""
	Local cLoja     := ""
	Local _cFilial  := "01"
	Local _cEmpresa := "01"
	Local _cIdEnt   := ""
	Local cMsg      := ""
	Local nRecnoSF2 := 0
	Local cPdf64    := ""
	Local oRet      := JsonObject():New()
	Local oItem     := JsonObject():New()
	Local aRetornos := {}
	Local aTabs     := {"SF2", "SA1"}
	Local cErrMsg   := ""

	::SetContentType("application/json")

	Begin Sequence

	If Empty(cJson)
		SetRestFault(400, "Body JSON nao informado")
		Return .F.
	EndIf

	If oReq:FromJson(cJson) != Nil
		SetRestFault(400, "JSON invalido")
		Return .F.
	EndIf

	cDoc     := IIf(ValType(oReq['doc'])     == 'U', "", AllTrim(cValToChar(oReq['doc'])))
	cSerie   := IIf(ValType(oReq['serie'])   == 'U', "", AllTrim(cValToChar(oReq['serie'])))
	cCliente := IIf(ValType(oReq['cliente']) == 'U', "", AllTrim(cValToChar(oReq['cliente'])))
	cLoja    := IIf(ValType(oReq['loja'])    == 'U', "", AllTrim(cValToChar(oReq['loja'])))
	_cFilial := IIf(ValType(oReq['filial'])  == 'U', "01", AllTrim(cValToChar(oReq['filial'])))

	If Empty(cDoc) .Or. Empty(cSerie) .Or. Empty(cCliente) .Or. Empty(cLoja)
		SetRestFault(400, "Campos obrigatorios: doc, serie, cliente, loja")
		Return .F.
	EndIf

	ConOut("[GETDANFE] Inicio - Doc=[" + cDoc + "] Serie=[" + cSerie + "] Cli=[" + cCliente + "] Loja=[" + cLoja + "] Filial=[" + _cFilial + "]")

	RpcSetEnv(_cEmpresa, _cFilial,,,,GetEnvServer(), aTabs)

	_cIdEnt := IIf(ValType(oReq['idEnt']) == 'U', SuperGetMv("UF_ENTTSS", .F., , _cFilial), AllTrim(cValToChar(oReq['idEnt'])))
	ConOut("[GETDANFE] idEnt=[" + _cIdEnt + "]")

	nRecnoSF2 := _GdQrySf2Rec(cDoc, cSerie, cCliente, cLoja, _cFilial, @cMsg)
	If nRecnoSF2 <= 0
		SetRestFault(404, cMsg)
		Return .F.
	EndIf
	ConOut("[GETDANFE] Recno SF2=[" + cValToChar(nRecnoSF2) + "]")

	cPdf64 := _GdPdf64(nRecnoSF2, _cIdEnt, @cMsg)
	If Empty(cPdf64)
		SetRestFault(422, cMsg)
		Return .F.
	EndIf

	oItem['base64_arquivo'] := "data:application/pdf;base64," + cPdf64
	aAdd(aRetornos, oItem)

	oRet['TOTAL']     := 1
	oRet['PAGINA']    := 1
	oRet['PORPAGINA'] := 1
	oRet['PROXIMO']   := .F.
	oRet['RETORNOS']  := aRetornos

	::SetStatus(200)
	::SetResponse(EncodeUTF8(oRet:ToJson()))
	ConOut("[GETDANFE] Sucesso - DANFE em base64 gerado")

	Recover Using oErr
		cErrMsg := "Falha interna no endpoint GetDanfe"
		If ValType(oErr) == "O"
			cErrMsg += ": " + oErr:Description
		EndIf
		ConOut("[GETDANFE] Excecao: " + cErrMsg)
		SetRestFault(500, cErrMsg)
		Return .F.
	End Sequence

Return lRet

//=============================================================
// _GdQrySf2Rec - Finds SF2 recno by doc/serie/client/store/branch
//=============================================================
Static Function _GdQrySf2Rec(cDoc, cSerie, cCliente, cLoja, cFilialReq, cMsg)

	Local nRecno    := 0
	Local cAliasTmp := GetNextAlias()
	Local cQuery    := ""
	Local cTabSF2   := RetSqlName("SF2")
	Local cDocPad   := PadR(_GdSafeSql(AllTrim(cDoc)), 9)
	Local cSerieVal := _GdSafeSql(AllTrim(cSerie))
	Local cCliPad   := PadR(_GdSafeSql(AllTrim(cCliente)), 6)
	Local cLojaPad  := PadR(_GdSafeSql(AllTrim(cLoja)), 2)
	Local cFilPad   := PadR(_GdSafeSql(AllTrim(cFilialReq)), 2)
	Local cErr      := ""

	cMsg := ""

	Begin Sequence

	cQuery := " SELECT TOP 1 F2.R_E_C_N_O_ AS RECNO "
	cQuery += " FROM " + cTabSF2 + " F2 "
	cQuery += " WHERE F2.D_E_L_E_T_ = ' ' "
	cQuery += "   AND F2.F2_FILIAL = '" + cFilPad + "' "
	cQuery += "   AND F2.F2_DOC = '" + cDocPad + "' "
	cQuery += "   AND RTRIM(F2.F2_SERIE) = '" + cSerieVal + "' "
	cQuery += "   AND F2.F2_CLIENTE = '" + cCliPad + "' "
	cQuery += "   AND F2.F2_LOJA = '" + cLojaPad + "' "
	cQuery += " ORDER BY F2.R_E_C_N_O_ DESC "

	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	TCQuery cQuery New Alias (cAliasTmp)

	If (cAliasTmp)->(Eof())
		(cAliasTmp)->(DbCloseArea())
		cQuery := " SELECT TOP 1 F2.R_E_C_N_O_ AS RECNO "
		cQuery += " FROM " + cTabSF2 + " F2 "
		cQuery += " WHERE F2.D_E_L_E_T_ = ' ' "
		cQuery += "   AND F2.F2_FILIAL = '" + cFilPad + "' "
		cQuery += "   AND F2.F2_DOC = '" + cDocPad + "' "
		cQuery += "   AND RTRIM(F2.F2_SERIE) = '" + cSerieVal + "' "
		cQuery += " ORDER BY F2.R_E_C_N_O_ DESC "

		TCQuery cQuery New Alias (cAliasTmp)

		If (cAliasTmp)->(Eof())
			(cAliasTmp)->(DbCloseArea())
			cMsg := "NF nao localizada com os dados informados"
			Return 0
		EndIf
	EndIf

	nRecno := (cAliasTmp)->RECNO
	(cAliasTmp)->(DbCloseArea())

	Recover Using oErr
		cErr := "Falha ao consultar SF2"
		If ValType(oErr) == "O"
			cErr += ": " + oErr:Description
		EndIf
		If Select(cAliasTmp) > 0
			(cAliasTmp)->(DbCloseArea())
		EndIf
		cMsg := cErr
		Return 0
	End Sequence

Return nRecno

//=============================================================
// _GdPdf64 - Generates DANFE PDF and returns Base64 content
//=============================================================
Static Function _GdPdf64(nRecnoSF2, cIdEnt, cMsg)

	Local oDanfe    := Nil
	Local lEnd      := .F.
	Local lExistNFe := .T.
	Local lIsLoja   := .F.
	Local cPath     := "ufdanfes"
	Local cArquivo  := ""
	Local cBarra    := "\\"
	Local cBasePath := ""
	Local cNFEID    := ""
	Local cOpenMsg  := ""
	Local cRet      := ""
	Local cErr      := ""
	Local lPreview  := .F.
	Local cPdfFile  := ""
	Local cDocKey   := ""

	cMsg := ""

	Begin Sequence

	If !_GdOpenSf2(@cOpenMsg)
		cMsg := cOpenMsg
		Return ""
	EndIf

	DbSelectArea("SF2")
	SF2->(DbGoTo(nRecnoSF2))

	If SF2->(Eof())
		cMsg := "NF nao localizada"
		Return ""
	EndIf

	If Empty(AllTrim(cIdEnt))
		cMsg := "Entidade TSS nao informada"
		Return ""
	EndIf

	If IsSrvUnix()
		cBarra := "/"
	EndIf

	cBasePath := cPath
	If !_GdEnsureDir(cBasePath, cBarra)
		cMsg := "Nao foi possivel criar pasta base DANFE no servidor: " + cBasePath
		Return ""
	EndIf

	cPath := cBasePath + cBarra + cIdEnt
	If !_GdEnsureDir(cPath, cBarra)
		cMsg := "Nao foi possivel criar pasta DANFE no servidor: " + cPath
		Return ""
	EndIf

	cPath    += cBarra
	cNFEID   := AllTrim(SF2->F2_DOC) + "_" + StrTran(Time(), ":", "_")
	cDocKey  := AllTrim(SF2->F2_DOC)
	cArquivo := cPath + cNFEID + ".pdf"

	FERASE(cArquivo)

	oDanfe := FWMSPrinter():New(cNFEID, IMP_PDF, .F., cPath, .T., , , , , , , .F.)
	oDanfe:SetResolution(78)
	oDanfe:SetPortrait()
	oDanfe:SetPaperSize(DMPAPER_A4)
	oDanfe:SetMargin(60, 60, 60, 60)
	oDanfe:lServer := .T.
	oDanfe:nDevice := IMP_PDF
	oDanfe:cPathPDF := cPath
	oDanfe:SetCopies(1)
	oDanfe:lInJob := .T.

	MV_PAR01 := PadR(SF2->F2_DOC, Len(SF2->F2_DOC))
	MV_PAR02 := PadR(SF2->F2_DOC, Len(SF2->F2_DOC))
	MV_PAR03 := PadR(SF2->F2_SERIE, Len(SF2->F2_SERIE))
	MV_PAR04 := 0
	MV_PAR05 := 2
	MV_PAR06 := 2

	If !FindFunction("U_DANFEProc")
		cMsg := "Rotina U_DANFEProc nao encontrada no RPO"
		Return ""
	EndIf

	U_DANFEProc(@oDanfe, @lEnd, cIdEnt, Nil, Nil, @lExistNFe, lIsLoja)
	ConOut("[GETDANFE] U_DANFEProc -> lExistNFe=[" + IIf(lExistNFe, "T", "F") + "] lEnd=[" + IIf(lEnd, "T", "F") + "] arquivo=[" + cArquivo + "]")

	lPreview := oDanfe:Preview()
	ConOut("[GETDANFE] Preview=[" + IIf(lPreview, "T", "F") + "] file=[" + IIf(File(cArquivo), "T", "F") + "]")

	If !lExistNFe
		cMsg := "U_DANFEProc nao localizou NFe no TSS para a entidade informada"
		Return ""
	EndIf

	If !lPreview
		cMsg := "Preview da DANFE retornou falso"
		Return ""
	EndIf

	cPdfFile := _GdPdfById(cPath, cNFEID)
	If Empty(cPdfFile)
		cPdfFile := _GdDocLookup(cDocKey, cPath, cBarra)
	EndIf
	If Empty(cPdfFile) .Or. !File(cPdfFile)
		cMsg := "PDF da DANFE nao foi gerado no servidor: " + cArquivo
		Return ""
	EndIf

	cRet := _GdEnc64(cPdfFile)
	FERASE(cPdfFile)

	If Empty(cRet)
		cMsg := "Nao foi possivel converter DANFE para base64"
	EndIf

	Recover Using oErr
		cErr := "Falha ao gerar DANFE"
		If ValType(oErr) == "O"
			cErr += ": " + oErr:Description
		EndIf
		cMsg := cErr
		Return ""
	End Sequence

Return cRet

//=============================================================
// _GdEnc64 - Converts a file to Base64 string
//=============================================================
Static Function _GdEnc64(cFile)

	Local cTexto  := ""
	Local aFiles  := {}
	Local aSizes  := {}
	Local nHandle := -1
	Local cString := ""
	Local cErr    := ""

	Begin Sequence

	ADir(cFile, aFiles, aSizes)

	If Len(aSizes) <= 0
		Return ""
	EndIf

	nHandle := FOpen(cFile, FO_READWRITE + FO_SHARED)
	If nHandle < 0
		Return ""
	EndIf

	FRead(nHandle, cString, aSizes[1])
	cTexto := Encode64(cString)
	FClose(nHandle)

	Recover Using oErr
		cErr := ""
		If ValType(oErr) == "O"
			cErr := oErr:Description
		EndIf
		ConOut("[GETDANFE] Erro no encode base64: " + cErr)
		If nHandle >= 0
			FClose(nHandle)
		EndIf
		Return ""
	End Sequence

Return cTexto

//=============================================================
// _GdEnsureDir - Ensures a directory exists
//=============================================================
Static Function _GdEnsureDir(cDir, cBarra)

	Local cPath := AllTrim(cDir)

	Default cBarra := "\\"

	If Empty(cPath)
		Return .F.
	EndIf

	If Right(cPath, 1) != cBarra
		cPath += cBarra
	EndIf

	If ExistDir(cPath)
		Return .T.
	EndIf

	If MakeDir(cPath) <> 0 .And. !ExistDir(cPath)
		Return .F.
	EndIf

Return .T.

//=============================================================
// _GdPdfById - Finds generated PDF file in output folder
//=============================================================
Static Function _GdPdfById(cPath, cNFEID)

	Local aFiles := {}
	Local aSizes := {}
	Local nI     := 0
	Local cFile  := ""
	Local cName  := ""
	Local cId    := Upper(AllTrim(cNFEID))

	ADir(cPath + "*.*", aFiles, aSizes)

	If Len(aFiles) <= 0
		Return ""
	EndIf

	// Primeiro tenta achar por prefixo do ID da NF.
	For nI := 1 To Len(aFiles)
		cName := aFiles[nI]
		If Right(Lower(cName), 4) == ".pdf" .And. Left(Upper(cName), Len(cId)) == cId
			Return cPath + cName
		EndIf
	Next nI

	// Fallback: pega o ultimo PDF encontrado na pasta.
	For nI := Len(aFiles) To 1 Step -1
		cName := aFiles[nI]
		If Right(Lower(cName), 4) == ".pdf"
			cFile := cPath + cName
			Exit
		EndIf
	Next nI

Return cFile

//=============================================================
// _GdDocLookup - Fallback search for generated PDF in common dirs
//=============================================================
Static Function _GdDocLookup(cDoc, cPath, cBarra)

	Local cFound := ""
	Local cCurr  := CurDir()

	Default cBarra := "\\"

	// 1) Pasta esperada
	cFound := _GdDocInDir(cPath, cDoc)
	If !Empty(cFound)
		Return cFound
	EndIf

	// 2) Diretorio corrente do AppServer
	If !Empty(cCurr)
		If Right(cCurr, 1) != cBarra
			cCurr += cBarra
		EndIf
		cFound := _GdDocInDir(cCurr, cDoc)
		If !Empty(cFound)
			Return cFound
		EndIf
	EndIf

	// 3) Subpasta spool comum em alguns ambientes
	If !Empty(cCurr)
		cFound := _GdDocInDir(cCurr + "spool" + cBarra, cDoc)
		If !Empty(cFound)
			Return cFound
		EndIf
	EndIf

Return ""

//=============================================================
// _GdDocInDir - Finds PDF in folder by invoice number in filename
//=============================================================
Static Function _GdDocInDir(cDir, cDoc)

	Local aFiles := {}
	Local aSizes := {}
	Local nI     := 0
	Local cName  := ""
	Local cDocUp := Upper(AllTrim(cDoc))
	Local cDirOk := AllTrim(cDir)

	If Empty(cDirOk) .Or. !ExistDir(cDirOk)
		Return ""
	EndIf

	ADir(cDirOk + "*.*", aFiles, aSizes)

	For nI := Len(aFiles) To 1 Step -1
		cName := aFiles[nI]
		If Right(Lower(cName), 4) == ".pdf" .And. cDocUp $ Upper(cName)
			Return cDirOk + cName
		EndIf
	Next nI

Return ""

//=============================================================
// _GdOpenSf2 - Ensures SF2 alias is available in current context
//=============================================================
Static Function _GdOpenSf2(cMsg)

	Local cTab := RetSqlName("SF2")

	cMsg := ""

	If Select("SF2") > 0
		Return .T.
	EndIf

	Begin Sequence
		DbUseArea(.T., "TOPCONN", cTab, "SF2", .F., .F.)
	Recover
		cMsg := "Alias SF2 nao esta aberto no ambiente"
		Return .F.
	End Sequence

	If Select("SF2") <= 0
		cMsg := "Alias SF2 nao esta aberto no ambiente"
		Return .F.
	EndIf

Return .T.

//=============================================================
// _GdSafeSql - Basic single quote neutralization for SQL literals
//=============================================================
Static Function _GdSafeSql(cText)
Return StrTran(cText, "'", "")
