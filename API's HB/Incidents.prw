#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "TopConn.ch"

WSRESTFUL Incidents DESCRIPTION "Delivery financial events API"

	WSDATA company As String Optional
	WSDATA branch As String Optional

	WSMETHOD POST DESCRIPTION "Create a pending bank instruction" WSSYNTAX "/incidents"

END WSRESTFUL

User Function Incidents()
Return .T.

WSMETHOD POST WSRECEIVE company, branch WSSERVICE Incidents

	Local cBody       := Self:GetContent()
	Local oRequest    := JsonObject():New()
	Local oInvoice    := Nil
	Local oBank       := Nil
	Local cEventId    := ""
	Local cEventType  := ""
	Local cOccurredAt := ""
	Local cReason     := ""
	Local cDoc        := ""
	Local cSeries     := ""
	Local cAccessKey  := ""
	Local cBank       := ""
	Local cAgency     := ""
	Local cAccount    := ""
	Local cEmpresa    := Self:company
	Local cFilNota    := Self:branch
	Local dNewDue     := Ctod("")
	Local dBaseDue    := Ctod("")
	Local dTitleDue   := Ctod("")
	Local dEventDate  := Ctod("")
	Local nDueShift   := 0
	Local cError      := ""
	Local oError      := Nil
	Local bOldErr     := Nil
	Local nStatus     := 400
	Local nCreated    := 0
	Local lRet        := .F.
	Local lException  := .F.
	Local aTitles     := {}
	Local nIndex      := 0
	Local cOccur      := ""
	Local cOccDesc    := ""
	Local cOperation  := ""

	::SetContentType("application/json")

	If Empty(cBody)
		Return DfeReply(Self, 400, .F., "Corpo JSON obrigatorio.", "", 0)
	EndIf

	If oRequest:FromJson(cBody) != Nil
		Return DfeReply(Self, 400, .F., "JSON invalido.", "", 0)
	EndIf

	If !(ValType(oRequest["invoice"]) $ "OJ") .Or. !(ValType(oRequest["bankAccount"]) $ "OJ")
		Return DfeReply(Self, 400, .F., "Informe os objetos invoice e bankAccount.", "", 0)
	EndIf

	oInvoice   := oRequest["invoice"]
	oBank      := oRequest["bankAccount"]
	cEventId   := DfeGetStr(oRequest, "eventId")
	cEventType := Upper(DfeGetStr(oRequest, "eventType"))
	cOccurredAt := DfeGetStr(oRequest, "occurredAt")
	cReason    := DfeGetStr(oRequest, "reason")
	cDoc       := DfeGetStr(oInvoice, "number")
	cSeries    := DfeGetStr(oInvoice, "series")
	cAccessKey := DfeGetStr(oInvoice, "accessKey")
	cBank      := DfeGetStr(oBank, "bankCode")
	cAgency    := DfeGetStr(oBank, "agency")
	cAccount   := DfeGetStr(oBank, "account")

	If Empty(cEventId) .Or. Len(cEventId) > 60 .Or. !DfeEvtId(cEventId)
		Return DfeReply(Self, 400, .F., "eventId obrigatorio; use ate 60 caracteres alfanumericos, hifen ou sublinhado.", cEventId, 0)
	EndIf
	If Len(cOccurredAt) < 10 .Or. SubStr(cOccurredAt, 11, 1) != "T"
		Return DfeReply(Self, 400, .F., "occurredAt obrigatorio no formato ISO-8601.", cEventId, 0)
	EndIf
	dEventDate := DfeDate(Left(cOccurredAt, 10))
	If Empty(dEventDate)
		Return DfeReply(Self, 400, .F., "Data de occurredAt invalida.", cEventId, 0)
	EndIf

	Do Case
	Case cEventType == "DO_NOT_PROTEST"
		cOccur     := "10"
		cOperation := "N"
	Case cEventType == "EXTEND_DUE_DATE"
		cOccur     := "06"
		cOperation := "P"
	Case cEventType == "REQUEST_BANK_WRITE_OFF"
		cOccur     := "02"
		cOperation := "B"
	Otherwise
		Return DfeReply(Self, 400, .F., "eventType deve ser DO_NOT_PROTEST, EXTEND_DUE_DATE ou REQUEST_BANK_WRITE_OFF.", cEventId, 0)
	EndCase

	If Empty(cDoc) .Or. Empty(cSeries) .Or. Empty(cAccessKey)
		Return DfeReply(Self, 400, .F., "Informe invoice.number, invoice.series e invoice.accessKey.", cEventId, 0)
	EndIf

	If Empty(cBank) .Or. cBank != "341" .Or. Empty(cAgency) .Or. Empty(cAccount)
		Return DfeReply(Self, 400, .F., "bankAccount deve informar banco 341, agencia e conta.", cEventId, 0)
	EndIf

	If cEventType == "EXTEND_DUE_DATE"
		If ValType(oRequest["newDueDate"]) != "C"
			Return DfeReply(Self, 400, .F., "newDueDate e obrigatorio para EXTEND_DUE_DATE (AAAA-MM-DD).", cEventId, 0)
		EndIf
		dNewDue := DfeDate(AllTrim(oRequest["newDueDate"]))
		If Empty(dNewDue)
			Return DfeReply(Self, 400, .F., "newDueDate invalido; use AAAA-MM-DD.", cEventId, 0)
		EndIf
	EndIf

	If !DfeFindTit(cDoc, cSeries, cAccessKey, cAgency, cAccount, @aTitles, @cError)
		Return DfeReply(Self, 422, .F., cError, cEventId, 0)
	EndIf
	If Len(aTitles) == 0
		Return DfeReply(Self, 404, .F., "Nota sem titulo elegivel para esta ocorrencia: verifique vinculo NF/titulo, conta, saldo, E1_IDCNAB e vencimento.", cEventId, 0)
	EndIf

	If Empty(cFilNota)
		cFilNota := aTitles[1][10]
	EndIf
	ConOut("[INCIDENTS][ENV][BEFORE_SET] company=[" + cValToChar(cEmpresa) + "] branch=[" + cValToChar(cFilNota) + "]")
	If FindFunction("WfPrepEnv") .And. !Empty(cFilNota)
		If Empty(cEmpresa)
			cEmpresa := "01"
		EndIf
		cEmpAnt := cEmpresa
		cFilAnt := cFilNota
		cNumEmp := cEmpresa + cFilNota
		ConOut("[INCIDENTS][ENV][AFTER_SET] cEmpAnt=[" + cEmpAnt + "] cFilAnt=[" + cFilAnt + "] cNumEmp=[" + cNumEmp + "]")
	Else
		ConOut("[INCIDENTS][ENV][AFTER_SET] WfPrepEnv indisponivel ou filial vazia; globais nao foram atribuidos")
	EndIf
	ConOut("[INCIDENTS][ENV][ALIASES_BEFORE_OPEN] selectSE1=[" + cValToChar(Select("SE1")) + "] selectFI2=[" + cValToChar(Select("FI2")) + "] selectSEB=[" + cValToChar(Select("SEB")) + "]")
	DbSelectArea("SEB")
	DbSelectArea("SE1")
	DbSelectArea("FI2")
	ConOut("[INCIDENTS][ENV][ALIASES_AFTER_OPEN] xFilialSE1=[" + xFilial("SE1") + "] xFilialFI2=[" + xFilial("FI2") + "] xFilialSEB=[" + xFilial("SEB") + "] selectSE1=[" + cValToChar(Select("SE1")) + "] selectFI2=[" + cValToChar(Select("FI2")) + "] selectSEB=[" + cValToChar(Select("SEB")) + "]")
	If Select("SE1") <= 0 .Or. Select("FI2") <= 0 .Or. Select("SEB") <= 0
		Return DfeReply(Self, 500, .F., "Aliases SE1, FI2 ou SEB nao estao abertos no contexto REST da filial " + cFilNota + ".", cEventId, 0)
	EndIf

	If !DfeGetOcc(cOccur, @cError, @cOccDesc)
		Return DfeReply(Self, 422, .F., cError, cEventId, 0)
	EndIf

	If cEventType == "EXTEND_DUE_DATE"
		If Len(aTitles) > 0
			dBaseDue := aTitles[1][9]
			For nIndex := 2 To Len(aTitles)
				If aTitles[nIndex][9] < dBaseDue
					dBaseDue := aTitles[nIndex][9]
				EndIf
			Next nIndex
			If dNewDue <= dBaseDue
				// Reenvio de evento ja aplicado: vencimentos ja deslocados, segue para a checagem de idempotencia.
				If !DfeEvtDone(aTitles[1], cOccur, cEventId)
					Return DfeReply(Self, 422, .F., "newDueDate deve ser posterior ao vencimento mais antigo da nota.", cEventId, 0)
				EndIf
			Else
				nDueShift := dNewDue - dBaseDue
			EndIf
		EndIf
	EndIf

	If !DfeHasFld()
		Return DfeReply(Self, 500, .F., "Campos de controle API ausentes na FI2.", cEventId, 0)
	EndIf
	// Cada parcela recebe sua propria ocorrencia; eventos repetidos sao ignorados por titulo.
	For nIndex := 1 To Len(aTitles)
		oError := Nil
		lException := .F.
		bOldErr := ErrorBlock({|e| oError := e, Break(e)})
		dTitleDue := Ctod("")
		If cEventType == "EXTEND_DUE_DATE"
			dTitleDue := aTitles[nIndex][9] + nDueShift
		EndIf
		Begin Sequence
			lRet := DfeProcTit(aTitles[nIndex], cEventId, cEventType, cOperation, cOccur, cDoc, cSeries, cReason, cOccurredAt, cOccDesc, dTitleDue, @cError)
		Recover Using oError
			DfeRestore(bOldErr)
			cError := "Erro ao processar parcela de indice " + cValToChar(nIndex)
			If ValType(oError) == "O"
				cError += ": " + oError:Description + " at " + oError:Operation
				If ValType(oError:ErrorStack) == "C" .And. !Empty(oError:ErrorStack)
					cError += " | Stack: " + oError:ErrorStack
				EndIf
			EndIf
			ConOut("[INCIDENTS] " + cError)
			lException := .T.
		End Sequence
		DfeRestore(bOldErr)
		If lException
			::SetStatus(500)
			::SetResponse(DfeResp(.F., cError, cEventId, nCreated, "REJECTED"))
			Return .F.
		EndIf
		If !lRet
			nStatus := IIf(nCreated > 0, 207, 422)
			Return DfeReply(Self, nStatus, .F., cError, cEventId, nCreated)
		EndIf
		If !aTitles[nIndex][8]
			nCreated++
		EndIf
	Next nIndex

	::SetStatus(IIf(nCreated == 0, 200, 201))
	::SetResponse(DfeResp(.T., IIf(nCreated == 0, "Evento ja processado.", "Instrucao(oes) criada(s) como pendente(s)."), cEventId, nCreated, "PENDING"))
	Return .T.

Static Function DfeGetStr(oObject, cKey)
	Local cValue := ""
		If ValType(oObject[cKey]) == "C"
		cValue := AllTrim(oObject[cKey])
	ElseIf ValType(oObject[cKey]) == "N"
		cValue := AllTrim(cValToChar(oObject[cKey]))
	EndIf
Return cValue

Static Function DfeEvtId(cEventId)
	Local nPos := 0
	Local cChar := ""
	For nPos := 1 To Len(cEventId)
		cChar := SubStr(cEventId, nPos, 1)
		If !(cChar $ "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")
			Return .F.
		EndIf
	Next nPos
Return .T.

Static Function DfeDate(cDate)
	Local dDate := Ctod("")
	If Len(cDate) == 10 .And. SubStr(cDate, 5, 1) == "-" .And. SubStr(cDate, 8, 1) == "-"
		dDate := StoD(SubStr(cDate, 1, 4) + SubStr(cDate, 6, 2) + SubStr(cDate, 9, 2))
		If DToS(dDate) != SubStr(cDate, 1, 4) + SubStr(cDate, 6, 2) + SubStr(cDate, 9, 2)
			dDate := Ctod("")
		EndIf
	EndIf
Return dDate

Static Function DfeReply(oSelf, nStatus, lSuccess, cMessage, cEventId, nCount)
	oSelf:SetStatus(nStatus)
	oSelf:SetResponse(DfeResp(lSuccess, cMessage, cEventId, nCount, IIf(lSuccess, "PENDING", "REJECTED")))
Return .F.

Static Function DfeResp(lSuccess, cMessage, cEventId, nCount, cStatus)
	Local oResponse := JsonObject():New()
	oResponse["success"] := lSuccess
	oResponse["message"] := cMessage
	oResponse["eventId"] := cEventId
	oResponse["status"] := cStatus
	oResponse["instructionsCreated"] := nCount
Return oResponse:ToJson()

Static Function DfeRestore(bOldErr)
	If ValType(bOldErr) == "B"
		ErrorBlock(bOldErr)
	Else
		ErrorBlock({|e| Break(e)})
	EndIf
Return Nil

Static Function DfeGetOcc(cOccurrence, cError, cDescription)
	Local cAlias := GetNextAlias()
	Local cQuery := ""
	Local lFound := .F.
	Local oError := Nil
	Local bOldErr := Nil

	cQuery := "SELECT EB_REFBAN, EB_DESCRI FROM " + RetSqlName("SEB")
	cQuery += " WHERE D_E_L_E_T_ = ' ' AND EB_FILIAL = '" + xFilial("SEB") + "'"
	cQuery += " AND EB_BANCO = '341' AND EB_TIPO = 'E' AND EB_REFBAN = '" + cOccurrence + "'"
	bOldErr := ErrorBlock({|e| oError := e, Break(e)})
	Begin Sequence
	TcQuery cQuery New Alias (cAlias)
	If !(cAlias)->(Eof())
		lFound := .T.
		cDescription := AllTrim((cAlias)->EB_DESCRI)
	EndIf
	(cAlias)->(DbCloseArea())
	Recover Using oError
		DfeRestore(bOldErr)
		cError := "Consulta SEB: " + oError:Description + " at " + oError:Operation
		ConOut("[INCIDENTS] " + cError)
		Return .F.
	End Sequence
	DfeRestore(bOldErr)

	If !lFound
		cError := "Ocorrencia " + cOccurrence + " nao esta cadastrada como saida na SEB do Itau (341)."
	EndIf
Return lFound

Static Function DfeFindTit(cDoc, cSeries, cAccessKey, cAgency, cAccount, aTitles, cError)
	Local cAlias := GetNextAlias()
	Local cQuery := ""
	Local xDueValue := Nil
	Local dDueDate := Ctod("")
	Local cDueValue := ""
	Local nInvoiceRec := 0
	Local nCurrentInvoice := 0
	Local lUniqueInvoice := .T.
	Local lInvalidDue := .F.
	Local oError := Nil
	Local bOldErr := Nil

	cQuery := "SELECT SF2.R_E_C_N_O_ AS F2REC, SF2.F2_DOC, SF2.F2_SERIE, SF2.F2_FILIAL AS F2FILIAL, "
	cQuery += "SE1.R_E_C_N_O_ AS E1REC, SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, "
	cQuery += "SE1.E1_TIPO, SE1.E1_CLIENTE, SE1.E1_LOJA, SE1.E1_VENCTO "
	cQuery += "FROM " + RetSqlName("SF2") + " SF2 INNER JOIN " + RetSqlName("SE1") + " SE1 "
	cQuery += "ON SE1.E1_FILIAL = SF2.F2_FILIAL AND SE1.E1_PREFIXO = SF2.F2_SERIE "
	cQuery += "AND SE1.E1_NUM = SF2.F2_DOC AND SE1.E1_CLIENTE = SF2.F2_CLIENTE AND SE1.E1_LOJA = SF2.F2_LOJA "
	cQuery += "WHERE SF2.D_E_L_E_T_ = ' ' AND SE1.D_E_L_E_T_ = ' ' "
	cQuery += "AND SF2.F2_DOC = '" + StrTran(cDoc, "'", "''") + "' "
	cQuery += "AND SF2.F2_SERIE = '" + StrTran(cSeries, "'", "''") + "' "
	If !Empty(cAccessKey)
		cQuery += "AND SF2.F2_CHVNFE = '" + StrTran(cAccessKey, "'", "''") + "' "
	EndIf
	cQuery += "AND SE1.E1_PORTADO = '341' AND RTRIM(SE1.E1_AGEDEP) = '" + StrTran(cAgency, "'", "''") + "' "
	cQuery += "AND RTRIM(SE1.E1_CONTA) = '" + StrTran(cAccount, "'", "''") + "' "
	cQuery += "AND RTRIM(SE1.E1_IDCNAB) <> '' AND RTRIM(SE1.E1_NUMBOR) <> '' "
	cQuery += "AND ISNULL(SE1.E1_BAIXA, '') = '' AND SE1.E1_SALDO > 0 "
	cQuery += "ORDER BY SE1.E1_PREFIXO, SE1.E1_NUM, SE1.E1_PARCELA, SE1.E1_TIPO"

	bOldErr := ErrorBlock({|e| oError := e, Break(e)})
	Begin Sequence
	TcQuery cQuery New Alias (cAlias)
	While !(cAlias)->(Eof())
		nCurrentInvoice := (cAlias)->F2REC
		If nInvoiceRec == 0
			nInvoiceRec := nCurrentInvoice
		ElseIf nInvoiceRec != nCurrentInvoice
			lUniqueInvoice := .F.
			Exit
		EndIf
		xDueValue := (cAlias)->E1_VENCTO
		If ValType(xDueValue) == "D"
			dDueDate := xDueValue
		ElseIf ValType(xDueValue) == "C"
			cDueValue := AllTrim(xDueValue)
			If Len(cDueValue) == 8
				dDueDate := StoD(cDueValue)
			ElseIf Len(cDueValue) == 10
				dDueDate := DfeDate(cDueValue)
			Else
				dDueDate := Ctod("")
			EndIf
		Else
			dDueDate := Ctod("")
		EndIf
		If Empty(dDueDate)
			cError := "Vencimento invalido retornado para a parcela " + AllTrim((cAlias)->E1_PARCELA) + "."
			lInvalidDue := .T.
			Exit
		EndIf
		AAdd(aTitles, {(cAlias)->E1REC, (cAlias)->E1_PREFIXO, (cAlias)->E1_NUM, (cAlias)->E1_PARCELA, (cAlias)->E1_TIPO, (cAlias)->E1_CLIENTE, (cAlias)->E1_LOJA, .F., dDueDate, (cAlias)->F2FILIAL})
		(cAlias)->(DbSkip())
	EndDo
	(cAlias)->(DbCloseArea())
	Recover Using oError
		DfeRestore(bOldErr)
		cError := "Consulta NF/titulos: " + oError:Description + " at " + oError:Operation
		ConOut("[INCIDENTS] " + cError)
		Return .F.
	End Sequence
	DfeRestore(bOldErr)

	If !lUniqueInvoice
		cError := "Numero e serie identificam mais de uma nota; informe accessKey para desambiguar."
		Return .F.
	EndIf
	If lInvalidDue
		Return .F.
	EndIf
Return .T.

Static Function DfeEvtDone(aTitle, cOccurrence, cEventId)
	Local cKeyFI2 := ""
	Local lDone := .F.

	DbSelectArea("SE1")
	SE1->(DbGoTo(aTitle[1]))
	If SE1->(Eof())
		Return .F.
	EndIf
	cKeyFI2 := xFilial("FI2") + "1" + SE1->(E1_NUMBOR + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO + E1_CLIENTE + E1_LOJA) + cOccurrence + "2"
	DbSelectArea("FI2")
	FI2->(DbSetOrder(1))
	If FI2->(DbSeek(cKeyFI2)) .And. FI2->FI2_GERADO == "2"
		lDone := (("eventId=" + cEventId) $ FI2->FI2_APIMSG)
	EndIf
Return lDone

Static Function DfeHasFld()
	Local lHasFields := .T.
	Local aFields := {"FI2_APILOG", "FI2_APIMSG", "FI2_OPEAPI"}
	Local nPos := 0
	For nPos := 1 To Len(aFields)
		If FI2->(FieldPos(aFields[nPos])) <= 0
			lHasFields := .F.
			Exit
		EndIf
	Next nPos
Return lHasFields

Static Function DfeProcTit(aTitle, cEventId, cEventType, cOperation, cOccurrence, cDoc, cSeries, cReason, cOccurredAt, cOccDesc, dNewDue, cError)
	Local aAuto := {}
	Local aFI2Data := {}
	Local cKeyFI2 := ""
	Local cApiLog := ""
	Local cApiMsg := ""
	Local dOldDue := aTitle[9]
	Local nRecno := aTitle[1]
	Local lAlreadyDone := .F.
	Local lDueChanged := .F.
	Local lRet := .T.
	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.
	Private lAutoErrNoFile := .T.

	DbSelectArea("SE1")
	SE1->(DbGoTo(nRecno))
	If SE1->(Eof()) .Or. Empty(SE1->E1_IDCNAB) .Or. Empty(SE1->E1_NUMBOR)
		cError := "O titulo deixou de atender aos pre-requisitos de cobranca bancaria."
		Return .F.
	EndIf

	cKeyFI2 := xFilial("FI2") + "1" + SE1->(E1_NUMBOR + E1_PREFIXO + E1_NUM + E1_PARCELA + E1_TIPO + E1_CLIENTE + E1_LOJA) + cOccurrence + "2"
	DbSelectArea("FI2")
	FI2->(DbSetOrder(1))
	If FI2->(DbSeek(cKeyFI2)) .And. FI2->FI2_GERADO == "2"
		If ("eventId=" + cEventId) $ FI2->FI2_APIMSG
			lAlreadyDone := .T.
		Else
			cError := "Ja existe instrucao pendente para este titulo e ocorrencia, criada por outro evento."
			Return .F.
		EndIf
	EndIf
	If lAlreadyDone
		aTitle[8] := .T.
		Return .T.
	EndIf

	If cEventType == "EXTEND_DUE_DATE" .And. dNewDue <= SE1->E1_VENCTO
		If dNewDue == SE1->E1_VENCTO
			cError := "O titulo ja esta com newDueDate, mas nao ha instrucao pendente para o evento; necessaria conciliacao manual."
		Else
			cError := "newDueDate deve ser posterior ao vencimento atual."
		EndIf
		Return .F.
	EndIf

	If cEventType == "EXTEND_DUE_DATE"
		AAdd(aAuto, {"E1_FILIAL", SE1->E1_FILIAL, Nil})
		AAdd(aAuto, {"E1_PREFIXO", SE1->E1_PREFIXO, Nil})
		AAdd(aAuto, {"E1_NUM", SE1->E1_NUM, Nil})
		AAdd(aAuto, {"E1_PARCELA", SE1->E1_PARCELA, Nil})
		AAdd(aAuto, {"E1_TIPO", SE1->E1_TIPO, Nil})
		AAdd(aAuto, {"E1_CLIENTE", SE1->E1_CLIENTE, Nil})
		AAdd(aAuto, {"E1_LOJA", SE1->E1_LOJA, Nil})
		AAdd(aAuto, {"E1_VENCTO", dNewDue, Nil})
		lMsErroAuto := .F.
		MSExecAuto({|x, y| FINA040(x, y)}, aAuto, 4)
		If lMsErroAuto
			cError := "FINA040 rejeitou a alteracao do vencimento."
			Return .F.
		EndIf
		lDueChanged := .T.
		SE1->(DbGoTo(nRecno))
	EndIf

	Begin Transaction
		cApiLog := Left(cReason, 200)
		cApiMsg := "|eventId=" + cEventId + "|eventType=" + cEventType + "|occurredAt=" + cOccurredAt + "|invoice=" + cDoc + "/" + cSeries + "|"
		If cEventType == "EXTEND_DUE_DATE"
			aFI2Data := {cOccurrence, cOccDesc, DtoC(dOldDue), DtoC(dNewDue), "E1_VENCTO", "D", cApiLog, cApiMsg, cOperation, cKeyFI2}
		Else
			aFI2Data := {cOccurrence, cOccDesc, "", "", "", "", cApiLog, cApiMsg, cOperation, cKeyFI2}
		EndIf

		lMsErroAuto := .F.
		MSExecAuto({|x, y| DfeSaveFI2(x, y)}, aFI2Data, 3)
		If lMsErroAuto
			cError := IIf(lDueChanged, "Vencimento alterado, mas FI2 nao foi confirmada; necessaria conciliacao manual.", "A ocorrencia pendente nao foi confirmada na FI2.")
			lRet := .F.
		Else
			DbSelectArea("FI2")
			If !FI2->(DbSeek(cKeyFI2))
				cError := IIf(lDueChanged, "Vencimento alterado, mas FI2 nao foi confirmada; necessaria conciliacao manual.", "A ocorrencia pendente nao foi confirmada na FI2.")
				lRet := .F.
			ElseIf FI2->FI2_GERADO != "2"
			cError := IIf(lDueChanged, "Vencimento alterado, mas FI2 nao foi confirmada; necessaria conciliacao manual.", "A ocorrencia pendente nao foi confirmada na FI2.")
			lRet := .F.
			EndIf
		EndIf

		If !lRet
			DisarmTransaction()
		EndIf
	End Transaction

	If !lRet
		Return .F.
	EndIf

	aTitle[8] := .F.
Return .T.

	Static Function DfeSaveFI2(aData, nOption)
		Local lFound := .F.
		Local lLocked := .F.
		Local oError := Nil
		Local bOldErr := Nil

		If nOption != 3 .Or. ValType(aData) != "A" .Or. Len(aData) != 10
			lMsErroAuto := .T.
			Return .F.
		EndIf

		bOldErr := ErrorBlock({|e| oError := e, Break(e)})
		Begin Sequence
			DbSelectArea("FI2")
			FI2->(DbSetOrder(1))
			lFound := FI2->(DbSeek(aData[10]))
			lLocked := RecLock("FI2", !lFound)
			If !lLocked
				lMsErroAuto := .T.
			Else
				FI2->FI2_FILIAL := xFilial("FI2")
				FI2->FI2_CARTEI := "1"
				FI2->FI2_OCORR := aData[1]
				FI2->FI2_GERADO := "2"
				FI2->FI2_NUMBOR := SE1->E1_NUMBOR
				FI2->FI2_PREFIX := SE1->E1_PREFIXO
				FI2->FI2_TITULO := SE1->E1_NUM
				FI2->FI2_PARCEL := SE1->E1_PARCELA
				FI2->FI2_TIPO := SE1->E1_TIPO
				FI2->FI2_CODCLI := SE1->E1_CLIENTE
				FI2->FI2_LOJCLI := SE1->E1_LOJA
				FI2->FI2_DTOCOR := dDataBase
				FI2->FI2_DESCOC := aData[2]
				FI2->FI2_VALANT := aData[3]
				FI2->FI2_VALNOV := aData[4]
				FI2->FI2_CAMPO := aData[5]
				FI2->FI2_TIPCPO := aData[6]
				FI2->FI2_APILOG := aData[7]
				FI2->FI2_APIMSG := aData[8]
				FI2->FI2_OPEAPI := aData[9]
				FI2->(MsUnlock())
			EndIf
		Recover Using oError
			If lLocked .And. Select("FI2") > 0
				FI2->(MsUnlock())
			EndIf
			lMsErroAuto := .T.
			If ValType(oError) == "O"
				ConOut("[INCIDENTS] FI2 ExecAuto: " + oError:Description + " at " + oError:Operation)
			EndIf
		End Sequence
		DfeRestore(bOldErr)
	Return !lMsErroAuto
