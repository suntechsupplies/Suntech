#Include "Protheus.ch"
#Include "TopConn.ch"
#Include 'TBICONN.CH'

User Function ProcessaCashback()
    Local aArea         as array
    Private oNewProess as object
 
    aArea := GetArea()

	If Parametros()
		Processa({||  GeraCashback()}, "Filtrando...", , , , )
 		RestArea(aArea)
	Else
		RestArea(aArea)
		Alert('Processo cancelado pelo usuário!')
		Return Nil
	EndIf

Return

Static Function Parametros()

	Local cClienteDe  := Space(TamSX3("A1_COD")[01])
	Local cClienteAte := Space(TamSX3("A1_COD")[01])
	Local cLojaDe     := Space(TamSX3("A1_LOJA")[01])
	Local cLojaAte    := Space(TamSX3("A1_LOJA")[01])
	Local lRet        := .T.
	Local aPergs      := {}
	
	aAdd(aPergs, {1, "Cliente De",  cClienteDe,  "", ".T.", "SA1", ".T.", 50, .F.})
	aAdd(aPergs, {1, "Cliente Até", cClienteAte, "", ".T.", "SA1", ".T.", 50, .F.})
	aAdd(aPergs, {1, "Loja De",     cLojaDe,     "", ".T.", "",    ".T.", 10, .F.})
	aAdd(aPergs, {1, "Loja Até",    cLojaAte,    "", ".T.", "",    ".T.", 10, .F.})
	
	If ParamBox(aPergs, "Informe os parâmetros", /*aRet*/, /*bOk*/, /*aButtons*/, /*lCentered*/, /*nPosx*/, /*nPosy*/, /*oDlgWizard*/, /*cLoad*/, .T., .F.)
		lRet := .T.
	Else
		lRet := .F.
	EndIf

Return lRet

Static Function GeraCashback()

	Local cQuery        := ""
	Local aArea  	    := GetArea()
	Local QrySE1     	:= "QrySE1"
	Local nAtual        := 0
	Local nTotal	    := 0
    Local cTabela       := "ZB8"
    Local aDados        := {}
	Local aDatas		:= {}
    Local cTudoOk       := ""
    Local cTransact     := ""
    Local nRetorno      := 0
    Private lMsErroAuto := .F.
	Private nLimiteDesc := GetMV("HB_VLMDPCB")
	Private nDiasPrazo  := GetMV("HB_DIASPCB")

	aDatas := GetCalendar()

	cQuery += "SELECT E1_FILIAL, E1_NUM, E1_PARCELA, E1_PORTADO, E1_PREFIXO, E1_TIPO, E1_CLIENTE, E1_NOMCLI, E1_LOJA, "
	cQuery += "A1_ZZCASHB, E1_VALOR, E1_SALDO, E1_BASCOM1, A1_ZZCASHB, E1_EMISSAO, E1_VENCREA, E1_BAIXA, DATEDIFF(DAY, E1_VENCREA, E1_BAIXA) AS E1_DDBAIXA, E1_VEND1 "
	cQuery += "FROM " + Retsqlname("SE1") + " SE1010 "
	cQuery += "INNER JOIN " + Retsqlname("SA1") + " SA1010 "
	cQuery += "ON SA1010.A1_COD = SE1010.E1_CLIENTE "
	cQuery += "AND SA1010.A1_LOJA = SE1010.E1_LOJA "
	cQuery += "AND SA1010.A1_ZZCASHB <> 0 "
	cQuery += "AND SA1010.A1_PESSOA = 'J' "
	cQuery += "AND SA1010.A1_COD BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "' "
	cQuery += "AND SA1010.A1_LOJA BETWEEN '" + MV_PAR03 + "' AND '" + MV_PAR04 + "' "
	cQuery += "AND SA1010.A1_ZZDESC < '" + Str(nLimiteDesc) + "' "
	cQuery += "AND SA1010.A1_ZZCASHB <> 0 "
	cQuery += "AND SA1010.D_E_L_E_T_ = '' "
	cQuery += "WHERE E1_BAIXA BETWEEN '" + aDatas[1] + "' AND '" + aDatas[2] + "' "
	cQuery += "AND DATEDIFF(DAY, E1_VENCREA, E1_BAIXA) < " + Str(nDiasPrazo) + " "
	cQuery += "AND SE1010.E1_TIPO = 'NF' "
	cQuery += "AND SE1010.E1_ZZCASHB <> 'S' "
	cQuery += "AND SE1010.D_E_L_E_T_ = ''"

	//Executa a consulta
    TCQuery cQuery New Alias "QrySE1"
        
    //Conta quantos registros existem, e seta no tamanho da régua
    Count To nTotal
    ProcRegua(nTotal)

	//Percorre todos os registros da query
    QrySE1->(DbGoTop())

	While !QrySE1->(Eof())

		aAdd(aDados, {"ZB8_FILIAL", QrySE1->E1_FILIAL,        Nil})
		aAdd(aDados, {"ZB8_NUM",    QrySE1->E1_NUM,           Nil})
		aAdd(aDados, {"ZB8_PREFIX", QrySE1->E1_PREFIXO,       Nil})
		aAdd(aDados, {"ZB8_PARCEL", QrySE1->E1_PARCELA,       Nil})
		aAdd(aDados, {"ZB8_TIPO",   QrySE1->E1_TIPO,          Nil})
		aAdd(aDados, {"ZB8_PORTAD", QrySE1->E1_PORTADO,       Nil})
		aAdd(aDados, {"ZB8_CLIENT", QrySE1->E1_CLIENTE,       Nil})
		aAdd(aDados, {"ZB8_LOJA",   QrySE1->E1_LOJA,          Nil})
		aAdd(aDados, {"ZB8_NOMCLI", QrySE1->E1_NOMCLI,        Nil})
		aAdd(aDados, {"ZB8_EMISSA", sToD(QrySE1->E1_EMISSAO), Nil})
		aAdd(aDados, {"ZB8_VENCTO", sToD(QrySE1->E1_VENCREA), Nil})
		aAdd(aDados, {"ZB8_VALOR",  QrySE1->E1_VALOR * (QrySE1->A1_ZZCASHB/100),   Nil})
		aAdd(aDados, {"ZB8_SALDO",  QrySE1->E1_SALDO,         Nil})
		aAdd(aDados, {"ZB8_BASCOM", QrySE1->E1_VALOR,  		  Nil})
		aAdd(aDados, {"ZB8_VEND1",  QrySE1->E1_VEND1,   	  Nil})
		aAdd(aDados, {"ZB8_EMAIL",  '1',                   	  Nil})

				//Inicializa a transação
		Begin Transaction
			//Joga a tabela para a memória (M->)
			RegToMemory(;
				cTabela,; // cAlias - Alias da Tabela
				.T.,;     // lInc   - Define se é uma operação de inclusão ou atualização
				.F.;      // lDic   - Define se irá inicilizar os campos conforme o dicionário
			)
	
			//Se conseguir fazer a execução automática
			If EnchAuto(;
				cTabela,; // cAlias  - Alias da Tabela
				aDados,;  // aField  - Array com os campos e valores
				cTudoOk,; // uTUDOOK - Validação do botão confirmar
				3;        // nOPC    - Operação do Menu (3=inclusão, 4=alteração, 5=exclusão)
			)
	
				//Aciona a efetivação da gravação
				nRetorno := AxIncluiAuto(;
					cTabela,;   // cAlias     - Alias da Tabela
					,;          // cTudoOk    - Operação do TudoOk (se usado no EnchAuto não precisa usar aqui)
					cTransact,; // cTransact  - Operação acionada após a gravação mas dentro da transação
					3;          // nOpcaoAuto - Operação do Menu (3=inclusão, 4=alteração, 5=exclusão)
				)

				SE1->(dbGoTop())
				SE1->(dbSetOrder(1))
				If SE1->(dbSeek(xFilial("SE1")+QrySE1->E1_PREFIXO+QrySE1->E1_NUM+QrySE1->E1_PARCELA+QrySE1->E1_TIPO))
					RecLock("SE1",.F.)
							E1_ZZCASHB := 'S'
					SE1->(MsUnlock())
				Endif

				SA1->(dbGoTop())
				SA1->(dbSetOrder(1))
				If SA1->(dbSeek(xFilial("SA1")+QrySE1->E1_CLIENTE+QrySE1->E1_LOJA))
					RecLock("SA1",.F.)
						A1_ZZVLCSB += (QrySE1->E1_VALOR * (QrySE1->A1_ZZCASHB/100))
					SA1->(MsUnlock()) 
				Endif

			Else
				AutoGrLog("Falha na inclusão do registro")
				MostraErro()
				DisarmTransaction()
			EndIf
		End Transaction

		nAtual ++
		IncProc("Analisando registro " + cValToChar(nAtual) + " de " + cValToChar(nTotal) + "...")
		QrySE1->(DbSkip())

	EndDo

	If !Empty(cQuery)
		dbSelectArea(QrySE1)
		QrySE1->(DbCloseArea())
	EndIf
	
	RestArea(aArea)

	MsgInfo(cValToChar(nAtual) + " registros incluidos com Sucesso!")

Return


Static Function GetCalendar()

	Local cQuery := ""
	Local aArea  := GetArea()
	Local aDatas := {}
	Local QryZB7 := "QryZB7"

	cQuery += "SELECT DISTINCT ZB7_DTINI, ZB7_DTFIM, ZB7_DESCR, ZB7_STATUS "
	cQuery += "FROM " + Retsqlname("ZB7") + " ZB710 "
	cQuery += "WHERE ZB710.ZB7_STATUS = '1' "
	cQuery += "AND ZB710.D_E_L_E_T_ = '' "

	//Executa a consulta
	TCQuery cQuery New Alias "QryZB7"

	QryZB7->(DbGoTop())

	While !QryZB7->(Eof())

		aDatas := {QryZB7->ZB7_DTINI, QryZB7->ZB7_DTFIM}

		QryZB7->(DbSkip())	
	
	EndDo

	If !Empty(cQuery)
		dbSelectArea(QryZB7)
		QryZB7->(DbCloseArea())
	EndIf

	RestArea(aArea)

Return aDatas
