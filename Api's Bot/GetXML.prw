#Include "Protheus.ch"
#Include "APWIZARD.ch"
#Include "FileIO.ch"
#Include "RPTDEF.ch"
#Include "FWPrintSetup.ch"
#Include "TOTVS.ch"
#Include "PARMTYPE.ch"
#Include "TbIconn.ch"
#Include "Topconn.ch"
#Include "RESTFUL.ch"

//=============================================================
// Utility: UF_GERXML - XML Generation from TSS
// Version: 2.0 (standardized copy)
// Author: Suntech
// Description: Generates NF-e XML from SF2 recno via TSS service
//=============================================================

#Define UF_GERXML_FILE_PREFIX "arquivo_"
#Define UF_GERXML_TSS_PATH    "/NFeSBRA.apw"

//=============================================================
// REST Service: GetXmlNf - XML extraction by invoice keys
//=============================================================
WSRESTFUL GetXmlNf DESCRIPTION "NF XML extraction API"

	WSMETHOD POST DESCRIPTION "Extract NF XML by document keys" WSSYNTAX "/getxml"

END WSRESTFUL

User Function GetXmlNf()
Return .T.

WSMETHOD POST WSSERVICE GetXmlNf

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
	Local lSanitize := .F.
	Local cMsg      := ""
	Local nRecnoSF2 := 0
	Local aRet      := {}
	Local aTabs     := {"SF2", "SA1"}

	::SetContentType("application/json")

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
	lSanitize := _ToLogical(IIf(ValType(oReq['sanitize']) == 'U', .F., oReq['sanitize']), .F.)

	If Empty(cDoc) .Or. Empty(cSerie) .Or. Empty(cCliente) .Or. Empty(cLoja)
		SetRestFault(400, "Campos obrigatorios: doc, serie, cliente, loja")
		Return .F.
	EndIf

	// Setup environment (igual Orders.prw)
	RpcSetEnv(_cEmpresa, _cFilial,,,,GetEnvServer(), aTabs)
	cEmpAnt := _cEmpresa
	cFilAnt := _cFilial
	cNumEmp := _cEmpresa + _cFilial

	// Obter idEnt apos RpcSetEnv para ter contexto correto
	_cIdEnt := IIf(ValType(oReq['idEnt']) == 'U', SuperGetMv("UF_ENTTSS", .F., , _cFilial), AllTrim(cValToChar(oReq['idEnt'])))

	ConOut("[GETXML] Buscando: Doc=[" + cDoc + "] Serie=[" + cSerie + "] Cli=[" + cCliente + "] Loja=[" + cLoja + "] Filial=[" + _cFilial + "]")

	nRecnoSF2 := _QrySf2RecXml(cDoc, cSerie, cCliente, cLoja, _cFilial, @cMsg)

	ConOut("[GETXML] Recno encontrado: " + cValToChar(nRecnoSF2))

	If nRecnoSF2 <= 0
		SetRestFault(404, cMsg)
		Return .F.
	EndIf

	aRet := _UF_GERXML_LOCAL(nRecnoSF2, "", _cIdEnt, .T.)

	If !aRet[1]
		SetRestFault(422, aRet[2])
		Return .F.
	EndIf

	// Sanitizacao opcional para pre-validacao de schema.
	// Nao habilitar em fluxo produtivo, pois altera o XML assinado.
	If lSanitize
		aRet[2] := _SxInfCplXml(aRet[2])
	EndIf

	::SetStatus(200)
	::SetContentType("application/xml")
	::SetResponse(aRet[2])

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} UF_GERXML
	Standardized copy of XML generation utility.

	Reads one record in SF2 by recno, calls TSS (RetornaNotas) and:
	- returns XML in memory when lRetXml = .T.
	- writes XML file to cDirDest when lRetXml = .F.

	@type  User Function
	@author Suntech
	@since 02/05/2026
	@param nRecnoSF2, Numeric, RecNo da tabela SF2
	@param cDirDest, Character, Diretorio destino para salvar XML
	@param cIdEnt, Character, Identificador da entidade no TSS
	@param lRetXml, Logical, .T. retorna XML em memoria
	@return Array, { lSucesso, cRetornoOuMensagem }
/*/
//-------------------------------------------------------------------
Static Function _UF_GERXML_LOCAL(nRecnoSF2, cDirDest, cIdEnt, lRetXml)

	Local lRet      := .F.
	Local cRet      := ""
	Local cXml      := ""
	Local cFilePath := ""
	Local cAliasSf2 := ""
	Local cQrySf2   := ""
	Local cF2Serie  := ""
	Local cF2Doc    := ""

	Default cDirDest := ""
	Default cIdEnt   := SuperGetMv("UF_ENTTSS", .F., , "01")
	Default lRetXml  := .F.

	// Basic input validation to avoid ambiguous runtime errors.
	If ValType(nRecnoSF2) != "N" .Or. nRecnoSF2 <= 0
		Return { .F., "Parametro nRecnoSF2 invalido" }
	EndIf

	If ValType(cDirDest) != "C"
		Return { .F., "Parametro cDirDest invalido" }
	EndIf

	If !_GetXmlFromTss(nRecnoSF2, cIdEnt, @cXml, @cRet)
		Return { .F., cRet }
	EndIf

	If lRetXml
		Return { .T., cXml }
	EndIf

	// Busca serie e doc via SQL para montar o nome do arquivo de destino
	cAliasSf2 := GetNextAlias()
	cQrySf2   := "SELECT F2_SERIE, F2_DOC FROM " + RetSqlName("SF2") + " WHERE R_E_C_N_O_ = " + cValToChar(nRecnoSF2)
	If Select(cAliasSf2) > 0
		(cAliasSf2)->(DbCloseArea())
	EndIf
	TCQuery cQrySf2 New Alias (cAliasSf2)
	If !(cAliasSf2)->(Eof())
		cF2Serie := AllTrim((cAliasSf2)->F2_SERIE)
		cF2Doc   := AllTrim((cAliasSf2)->F2_DOC)
	EndIf
	(cAliasSf2)->(DbCloseArea())

	cFilePath := _BuildXmlFilePath(cDirDest, cF2Serie, cF2Doc)

	If Empty(cFilePath)
		Return { .F., "Diretorio de destino invalido" }
	EndIf

	If !MemoWrite(cFilePath, cXml)
		lRet := .F.
		cRet := "Erro na gravacao do arquivo"
	Else
		lRet := .T.
		cRet := cFilePath
	EndIf

Return { lRet, cRet }

//=============================================================
// _GetXmlFromTss - Retrieves XML from TSS for one SF2 recno
//=============================================================
Static Function _GetXmlFromTss(nRecnoSF2, cIdEnt, cXml, cRet)

	Local lOk       := .F.
	Local cUrlTss   := PadR(GetNewPar("MV_SPEDURL", "http://"), 250)
	Local oTss      := Nil
	Local oNfeId    := Nil
	Local cAliasSf2 := GetNextAlias()
	Local cQrySf2   := ""
	Local cF2Serie  := ""
	Local cF2Doc    := ""

	cXml := ""
	cRet := ""

	// Busca F2_SERIE e F2_DOC via SQL para nao depender de area aberta
	cQrySf2 := "SELECT F2_SERIE, F2_DOC FROM " + RetSqlName("SF2") + " WHERE R_E_C_N_O_ = " + cValToChar(nRecnoSF2)

	If Select(cAliasSf2) > 0
		(cAliasSf2)->(DbCloseArea())
	EndIf

	TCQuery cQrySf2 New Alias (cAliasSf2)

	If (cAliasSf2)->(Eof())
		(cAliasSf2)->(DbCloseArea())
		cRet := "NF nao localizada"
		Return .F.
	EndIf

	cF2Serie := AllTrim((cAliasSf2)->F2_SERIE)
	cF2Doc   := AllTrim((cAliasSf2)->F2_DOC)
	(cAliasSf2)->(DbCloseArea())

	// TSS WebService payload for one NF identified by serie+documento.
	oTss := WSNFeSBRA():New()
	oTss:cUSERTOKEN        := "TOTVS"
	oTss:cID_ENT           := cIdEnt
	oTss:oWSNFEID          := NFESBRA_NFES2():New()
	oTss:oWSNFEID:oWSNotas := NFESBRA_ARRAYOFNFESID2():New()
	aAdd(oTss:oWSNFEID:oWSNotas:oWSNFESID2, NFESBRA_NFESID2():New())
	oNfeId := aTail(oTss:oWSNFEID:oWSNotas:oWSNFESID2)
	oNfeId:cID := cF2Serie + cF2Doc
	oTss:nDIASPARAEXCLUSAO := 0
	oTss:_URL              := AllTrim(cUrlTss) + UF_GERXML_TSS_PATH

	If !oTss:RetornaNotas()
		cRet := IIf(Empty(GetWscError(3)), GetWscError(1), GetWscError(3))
		Return .F.
	EndIf

	If Len(oTss:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3) <= 0
		cRet := "NF nao localizada"
		Return .F.
	EndIf

	If oTss:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFECANCELADA != Nil
		cXml := oTss:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFECANCELADA:cXML
	Else
		// cXML contem apenas <NFe> e cXMLPROT contem <protNFe> (com nProt).
		// E necessario montar o envelope nfeProc para o XML ficar completo.
		cXml := '<?xml version="1.0" encoding="UTF-8"?>'
		cXml += '<nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">'
		cXml += oTss:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFE:cXML
		cXml += oTss:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFE:cXMLPROT
		cXml += '</nfeProc>'
	EndIf

	lOk := !Empty(cXml)

	If !lOk
		cRet := "XML retornado vazio pelo TSS"
	EndIf

Return lOk

//=============================================================
// _BuildXmlFilePath - Assembles destination path for XML file
//=============================================================
Static Function _BuildXmlFilePath(cDirDest, cSerie, cDoc)

	Local cDir  := AllTrim(cDirDest)
	Local cPath := ""

	If Empty(cDir)
		Return ""
	EndIf

	If Right(cDir, 1) $ "\\/"
		cPath := cDir
	Else
		cPath := cDir + "\\"
	EndIf

	cPath += UF_GERXML_FILE_PREFIX + cSerie + cDoc + ".xml"

Return cPath

//-------------------------------------------------------------------
/*/{Protheus.doc} GETXML
	Consulta NF na SF2 por numero/serie e extrai o XML via UF_GERXML.

	@type  User Function
	@author Suntech
	@since 02/05/2026
	@param cDoc, Character, Numero da NF (ex.: "000198786")
	@param cSerie, Character, Serie da NF (opcional)
	@param cDirDest, Character, Diretorio destino (quando lRetXml=.F.)
	@param cIdEnt, Character, Entidade TSS (opcional)
	@param lRetXml, Logical, .T. retorna XML em memoria
	@return Array, { lSucesso, cRetornoOuMensagem }
/*/
//-------------------------------------------------------------------
User Function GETXML(cDoc, cSerie, cDirDest, cIdEnt, lRetXml)

	Local nRecnoSF2 := 0
	Local cRet      := ""

	Default cSerie   := ""
	Default cDirDest := ""
	Default cIdEnt   := SuperGetMv("UF_ENTTSS", .F., , xFilial("SF2"))
	Default lRetXml  := .T.

	If Empty(AllTrim(cDoc))
		Return { .F., "Informe o numero da NF em cDoc" }
	EndIf

	nRecnoSF2 := _GetSf2RecnoByDoc(cDoc, cSerie, @cRet)

	If nRecnoSF2 <= 0
		Return { .F., cRet }
	EndIf

Return _UF_GERXML_LOCAL(nRecnoSF2, cDirDest, cIdEnt, lRetXml)

//=============================================================
// _GetSf2RecnoByDoc - Finds SF2 recno by document/series
//=============================================================
Static Function _GetSf2RecnoByDoc(cDoc, cSerie, cMsg)

	Local nRecno    := 0
	Local cAliasTmp := GetNextAlias()
	Local cQuery    := ""
	Local cDocPad   := PadR(AllTrim(cDoc), 9)
	Local cSeriePad := ""

	cMsg := ""

	If Select("SF2") <= 0
		cMsg := "Alias SF2 nao esta aberto no ambiente"
		Return 0
	EndIf

	cSeriePad := IIf(Empty(AllTrim(cSerie)), "", PadR(AllTrim(cSerie), 3))

	cQuery := " SELECT TOP 1 F2.R_E_C_N_O_ AS RECNO "
	cQuery += " FROM " + RetSqlName("SF2") + " F2 "
	cQuery += " WHERE F2.D_E_L_E_T_ = ' ' "
	cQuery += "   AND F2.F2_FILIAL = '" + xFilial("SF2") + "' "
	cQuery += "   AND F2.F2_DOC = '" + cDocPad + "' "

	If !Empty(cSeriePad)
		cQuery += "   AND F2.F2_SERIE = '" + cSeriePad + "' "
	EndIf

	cQuery += " ORDER BY F2.R_E_C_N_O_ DESC "

	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	TCQuery cQuery New Alias (cAliasTmp)

	If (cAliasTmp)->(Eof())
		(cAliasTmp)->(DbCloseArea())
		cMsg := "NF nao localizada na SF2"
		Return 0
	EndIf

	nRecno := (cAliasTmp)->RECNO
	(cAliasTmp)->(DbCloseArea())

Return nRecno

//=============================================================
// _QrySf2RecXml - Finds SF2 recno by doc/serie/client/store/cnpj
//=============================================================
Static Function _QrySf2RecXml(cDoc, cSerie, cCliente, cLoja, cFilialReq, cMsg)

	Local nRecno    := 0
	Local cAliasTmp := GetNextAlias()
	Local cQuery    := ""
	Local cTabSF2   := RetSqlName("SF2")
	Local cDocPad   := PadR(_SafeSql(AllTrim(cDoc)), 9)
	Local cSerieVal := _SafeSql(AllTrim(cSerie))
	Local cCliPad   := PadR(_SafeSql(AllTrim(cCliente)), 6)
	Local cLojaPad  := PadR(_SafeSql(AllTrim(cLoja)), 2)
	Local cFilPad   := PadR(_SafeSql(AllTrim(cFilialReq)), 2)

	cMsg := ""

	ConOut("[GETXML] Tabela SF2: " + cTabSF2 + " Filial: " + cFilPad + " Doc: " + cDocPad + " Serie: " + cSerieVal)

	cQuery := " SELECT TOP 1 F2.R_E_C_N_O_ AS RECNO "
	cQuery += " FROM " + cTabSF2 + " F2 "
	cQuery += " WHERE F2.D_E_L_E_T_ = ' ' "
	cQuery += "   AND F2.F2_FILIAL = '" + cFilPad + "' "
	cQuery += "   AND F2.F2_DOC = '" + cDocPad + "' "
	cQuery += "   AND RTRIM(F2.F2_SERIE) = '" + cSerieVal + "' "
	cQuery += "   AND F2.F2_CLIENTE = '" + cCliPad + "' "
	cQuery += "   AND F2.F2_LOJA = '" + cLojaPad + "' "

	cQuery += " ORDER BY F2.R_E_C_N_O_ DESC "

	ConOut("[GETXML] Query principal: " + cQuery)

	If Select(cAliasTmp) > 0
		(cAliasTmp)->(DbCloseArea())
	EndIf

	TCQuery cQuery New Alias (cAliasTmp)

	If (cAliasTmp)->(Eof())
		(cAliasTmp)->(DbCloseArea())

		// Fallback: busca por numero/serie sem cliente e loja para evitar falso negativo.
		cQuery := " SELECT TOP 1 F2.R_E_C_N_O_ AS RECNO "
		cQuery += " FROM " + cTabSF2 + " F2 "
		cQuery += " WHERE F2.D_E_L_E_T_ = ' ' "
		cQuery += "   AND F2.F2_FILIAL = '" + cFilPad + "' "
		cQuery += "   AND F2.F2_DOC = '" + cDocPad + "' "
		cQuery += "   AND RTRIM(F2.F2_SERIE) = '" + cSerieVal + "' "
		cQuery += " ORDER BY F2.R_E_C_N_O_ DESC "

		ConOut("[GETXML] Query fallback: " + cQuery)

		If Select(cAliasTmp) > 0
			(cAliasTmp)->(DbCloseArea())
		EndIf

		TCQuery cQuery New Alias (cAliasTmp)

		If (cAliasTmp)->(Eof())
			(cAliasTmp)->(DbCloseArea())
			cMsg := "NF nao localizada com os dados informados"
			Return 0
		EndIf
	EndIf

	nRecno := (cAliasTmp)->RECNO
	(cAliasTmp)->(DbCloseArea())

Return nRecno

//=============================================================
// _SafeSql - basic single quote neutralization for SQL literals
//=============================================================
Static Function _SafeSql(cText)
Return StrTran(cText, "'", "")

//=============================================================
// _OpenSf2 - Ensures SF2 alias is available in current context
//=============================================================
Static Function _OpenSf2(cMsg)

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
// _ToLogical - Converts common input values to logical
//=============================================================
Static Function _ToLogical(uValue, lDefault)

	Local cVal := ""

	Default lDefault := .F.

	If ValType(uValue) == "L"
		Return uValue
	EndIf

	If ValType(uValue) == "N"
		Return (uValue <> 0)
	EndIf

	If ValType(uValue) == "C"
		cVal := Upper(AllTrim(uValue))
		If cVal $ "1|T|TRUE|S|SIM|Y|YES"
			Return .T.
		EndIf
		If cVal $ "0|F|FALSE|N|NAO|NO"
			Return .F.
		EndIf
	EndIf

Return lDefault

//=============================================================
// _SxInfCplXml - Sanitizes only infCpl content in XML
//=============================================================
Static Function _SxInfCplXml(cXml)

	Local cTagIni := "<infCpl>"
	Local cTagFim := "</infCpl>"
	Local nIni    := At(cTagIni, cXml)
	Local nFim    := At(cTagFim, cXml)
	Local nTxtIni := 0
	Local cPrefix := ""
	Local cMid    := ""
	Local cSuffix := ""

	If nIni <= 0 .Or. nFim <= 0 .Or. nFim <= nIni
		Return cXml
	EndIf

	nTxtIni := nIni + Len(cTagIni)
	cPrefix := SubStr(cXml, 1, nTxtIni - 1)
	cMid    := SubStr(cXml, nTxtIni, nFim - nTxtIni)
	cSuffix := SubStr(cXml, nFim)

	cMid := _SxInfCplTxt(cMid)

Return cPrefix + cMid + cSuffix

//=============================================================
// _SxInfCplTxt - Normalizes problematic chars for schema
//=============================================================
Static Function _SxInfCplTxt(cText)

	Local cOut := cText
	Local cChr := ""
	Local cRep := Chr(239) + Chr(191) + Chr(189)
	Local nAsc := 0
	Local nI   := 0

	// Common broken patterns for numero marker.
	cOut := StrTran(cOut, "n" + Chr(186), "numero")
	cOut := StrTran(cOut, "N" + Chr(186), "Numero")
	cOut := StrTran(cOut, "n" + Chr(176), "numero")
	cOut := StrTran(cOut, "N" + Chr(176), "Numero")
	cOut := StrTran(cOut, "n" + cRep, "numero")
	cOut := StrTran(cOut, "N" + cRep, "Numero")
	cOut := StrTran(cOut, "n�", "numero")
	cOut := StrTran(cOut, "N�", "Numero")

	// Generic replacement-char cleanup (UTF-8 decoded/broken variants).
	cOut := StrTran(cOut, "�", " ")
	cOut := StrTran(cOut, cRep, " ")

	// Remove control/non-printable chars that break schema pattern.
	For nI := 1 To Len(cOut)
		cChr := SubStr(cOut, nI, 1)
		nAsc := Asc(cChr)

		If nAsc < 32 .Or. (nAsc > 126 .And. nAsc < 160)
			cOut := Stuff(cOut, nI, 1, " ")
		EndIf
	Next nI

	// Normalize spacing.
	Do While "  " $ cOut
		cOut := StrTran(cOut, "  ", " ")
	EndDo

Return AllTrim(cOut)
