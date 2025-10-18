#Include 'TOTVS.CH'
#Include 'Protheus.ch'
#Include "TopConn.ch"
#Include 'TBICONN.CH'

User Function zSendMail()
	
	Local cDe            := "suntechsupplies.danfe@hb.com.br"
	Local cPara          := ""
	Local cCC            := ""
	Local cCorpo         := ""
	Local cAssunto       := "Atualização de saldo Cashback"
	Local aAnexos        := {}
	Local lMostraLog     := .F.
	Local lUsaTLS        := .T.
	Local cNomeCliente   := ""
	Local cCNPJCliente   := ""
	Local cValorCashback := ""
	Local cDataValidade  := ""
	Local cQuery         := ""
	Local cAliasZB8      := "ZB8"
	Local nAtual		 := 0

	cQuery += "SELECT TOP 10 ZB8_FILIAL, ZB8_NUM, ZB8_PARCEL, ZB8_PREFIX, ZB8_CLIENT, ZB8_LOJA, ZB8_EMISSA, ZB8_VENCTO, ZB8_NOMCLI, ZB8_PORTAD, "
	cQuery += "ZB8_SALDO, ZB8_TIPO, ZB8_VALOR, ZB8_BASCOM, ZB8_VEND1, ZB8_EMAIL "
	cQuery += "FROM ZB8010 "
	cQuery += "WHERE ZB8_EMAIL = '1' "
	cQuery += "AND D_E_L_E_T_ =  ''"

	TCQuery cQuery New Alias cAliasZB8

	//Percorre todos os registros da query
	cAliasZB8->(DbGoTop())

	While !cAliasZB8->(Eof())

		SA1->(dbGoTop())
		SA1->(dbSetOrder(1))
		If SA1->(dbSeek(xFilial("SA1")+cAliasZB8->ZB8_CLIENTE+cAliasZB8->ZB8_LOJA))

			cNomeCliente   := SA1->A1_NOME
			cCNPJCliente   := SA1->A1_CGC
			cNumTitulo     := cAliasZB8->ZB8_PREFIX+cAliasZB8->ZB8_NUM+cAliasZB8->ZB8_PARCEL
			cDataPagamento := DTOC(SToD(cAliasZB8->ZB8_VENCTO))
			cValorTitulo   := cValToChar(cAliasZB8->ZB8_BASCOM)
			cValorCashback := cValToChar(cAliasZB8->ZB8_VALOR)
			cSaldoCashback := cValToChar(SA1->A1_ZZVLCSB)
			cDataValidade  := DTOC(Date())

			cPara := AllTrim(SA1->A1_EMAIL) //+ ',' + AllTrim(SA1->A1_ZZMAIL2)

			//cPara := "ricardo.araujo@hb.com.br,aricardo.araujo@gmail.com"

			//Definindo o arquivo a ser lido
			oFile := FWFileReader():New("\boletos\mailbody.html")

			//Se o arquivo pode ser aberto
			If (oFile:Open())

				//Se não for fim do arquivo
				If !(oFile:EoF())
					cCorpo  := oFile:FullRead()
				EndIf

				cCorpo := StrTran(cCorpo, "@cNomeCliente",   cNomeCliente)
				cCorpo := StrTran(cCorpo, "@cCNPJCliente",   cCNPJCliente)
				cCorpo := StrTran(cCorpo, "@cNumTitulo",   	 cNumTitulo)
				cCorpo := StrTran(cCorpo, "@cDataPagamento", cDataPagamento)
				cCorpo := StrTran(cCorpo, "@cValorTitulo",   cValorTitulo)
				cCorpo := StrTran(cCorpo, "@cValorCashback", cValorCashback)
				cCorpo := StrTran(cCorpo, "@cSaldoCashback", cSaldoCashback)
				cCorpo := StrTran(cCorpo, "@cDataValidade",  cDataValidade)

				//Fecha o arquivo e finaliza o processamento
				oFile:Close()
			EndIf

			U_zEnvMail(cDe, cPara, cCC, cAssunto, cCorpo, aAnexos, lMostraLog, lUsaTLS)

			DBSelectArea("ZB8")
			ZB8->(DBSetOrder(1))
			ZB8->(DbGoTop())
			If ZB8->(dbSeek(xFilial("ZB8")+cAliasZB8->ZB8_NUM+cAliasZB8->ZB8_PREFIXO+cAliasZB8->ZB8_PARCELA))
				RecLock("ZB8",.F.)
					ZB8_EMAIL := '9'
				ZB8->(MsUnlock())
			Endif

		Endif

		nAtual ++
		cAliasZB8->(DbSkip())

	EndDo

	If !Empty(cQuery)
		dbSelectArea(cAliasZB8)
		cAliasZB8->(DbCloseArea())
	EndIf

Return

