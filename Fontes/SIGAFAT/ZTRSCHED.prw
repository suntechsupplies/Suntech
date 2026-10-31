#Include 'Protheus.ch'

User Function ZTRSCHED()

	Local aRetorno := {.F., "Execucao do Schedule nao confirmada.", {}}
	Local aControle := Nil
	Local cEmpresa := ""
	Local cFilExec := ""
	Local cErro    := ""
	Local xAtivo   := Nil
	Local lTerminou := .F.
	Local bError   := Nil
	Local oError   := Nil

	If Type("cEmpAnt") == "C"
		cEmpresa := AllTrim(cEmpAnt)
	EndIf
	If Type("cFilAnt") == "C"
		cFilExec := AllTrim(cFilAnt)
	EndIf
	ConOut("[ZTRSCHED] Recebido; ambiente=" + GetEnvServer() + "; empresa=" + cEmpresa + ;
		"; filial=" + cFilExec + "; SX6=" + cValToChar(Select("SX6")))
	If Select("SX6") == 0 .Or. Empty(cEmpresa) .Or. Empty(cFilExec)
		Return ZSClose({.F., "Ambiente nao inicializado. Confira SchedDef no RPO do Agent e a empresa/filial do agendamento.", {}})
	EndIf
	If cFilExec != "03"
		Return ZSClose({.F., "Filial recebida=" + cFilExec + ". Cadastre somente a filial 03 no agendamento.", {}})
	EndIf
	bError := ErrorBlock({|oErr| Break(oErr)})
	Begin Sequence
		xAtivo := SuperGetMV("MV_ZTRAUT", .F., .F.)
		ConOut("[ZTRSCHED] Parametro MV_ZTRAUT; tipo=" + ValType(xAtivo))
		If ValType(xAtivo) != "L"
			aRetorno := {.F., "MV_ZTRAUT deve ser logico; nenhuma operacao iniciada.", {}}
		Else
			ConOut("[ZTRSCHED] Inicio; empresa=" + cEmpresa + "; filial=03; efetivar=" + cValToChar(xAtivo))
			aControle := U_ZTRORQ(cEmpresa, Nil, Nil, xAtivo, 20)
			If ValType(aControle) != "A"
				aRetorno := {.F., "Controlador sem retorno valido; confira logs ZTRORQ antes de repetir.", {}}
			ElseIf Len(aControle) != 3
				aRetorno := {.F., "Controlador devolveu retorno incompleto.", {}}
			ElseIf ValType(aControle[1]) != "L" .Or. ValType(aControle[2]) != "C"
				aRetorno := {.F., "Controlador devolveu formato de retorno invalido.", {}}
			ElseIf ValType(aControle[3]) != "A"
				aRetorno := {.F., "Controlador nao devolveu a lista de resultados.", {}}
			Else
				aRetorno := aControle
			EndIf
		EndIf
		lTerminou := .T.
	Recover Using oError
		If ValType(oError) == "O"
			cErro := cValToChar(oError:Description)
		ElseIf ValType(oError) == "C"
			cErro := oError
		EndIf
		If Empty(cErro)
			cErro := "Execucao interrompida sem descricao."
		EndIf
		aRetorno := {.F., cErro, {}}
	End Sequence
	ErrorBlock(bError)
	If !lTerminou .And. Empty(cErro)
		aRetorno := {.F., "Execucao interrompida antes de concluir a leitura do parametro ou a chamada do controlador.", {}}
	EndIf

Return ZSClose(aRetorno)

Static Function ZSClose(aRetorno)

	ConOut("[ZTRSCHED] Finalizado; sucesso=" + cValToChar(aRetorno[1]) + "; " + aRetorno[2])

Return aRetorno

Static Function SchedDef()

	Local aDefinicao := {"P", "", "", {}, "", "", .F., .T.}

Return aDefinicao
