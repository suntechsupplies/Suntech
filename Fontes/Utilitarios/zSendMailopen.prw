#Include 'TOTVS.CH'
#Include 'Protheus.ch'
#Include "TopConn.ch"
#Include 'TBICONN.CH'

User Function zSendMailopen()
	
	Local cDe            := "suntechsupplies.danfe@hb.com.br"
	Local cPara          := ""
	Local cCC            := "ricardo.araujo@hb.com.br,larissa.menegao@hb.com.br"
	Local cCorpo         := ""
	Local cAssunto       := "Atualização de saldo Cashback"
	Local aAnexos        := {}
	Local lMostraLog     := .F.
	Local lUsaTLS        := .T.
	Local cNomeCliente   := ""
	Local cCNPJCliente   := ""
	Local cNumTitulo	 := ""
	Local cValorCashback := ""
	Local cValorTitulo   := ""
	Local cDataValidade  := ""
	Local cSaldoCashback := ""
	Local cDataPagamento := ""	
	Local cQuery         := ""
	Local QrySA1      	 := "QrySA1"
	Local nAtual		 := 0

	cQuery += "SELECT A1_COD, A1_LOJA, A1_CGC, A1_NOME, A1_ZZVLCSB, A1_EMAIL, A1_ZZMAIL2 "
	cQuery += "FROM SA1010 "
	cQuery += "WHERE A1_ZZVLCSB  > 0 "
	cQuery += "AND D_E_L_E_T_ =  ''"

	TCQuery cQuery New Alias "QrySA1"

	//Percorre todos os registros da query
	QrySA1->(DbGoTop())

	While !QrySA1->(Eof())

		cNomeCliente   := QrySA1->A1_NOME
		cCNPJCliente   := QrySA1->A1_CGC
		//cNumTitulo     := QrySA1->ZB8_PREFIX+QrySA1->ZB8_NUM+QrySA1->ZB8_PARCEL
		//cDataPagamento := DTOC(SToD(QrySA1->ZB8_VENCTO))
		//cValorTitulo   := cValToChar(QrySA1->ZB8_BASCOM)
		//cValorCashback := cValToChar(QrySA1->ZB8_VALOR)
		cSaldoCashback := cValToChar(QrySA1->A1_ZZVLCSB)
		cDataValidade  := DTOC(Date())

		cPara := AllTrim(QrySA1->A1_EMAIL) // + ',' + AllTrim(QrySA1->A1_ZZMAIL2)

		//Definindo o arquivo a ser lido
		oFile := FWFileReader():New("\boletos\mailopen.html")	

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

		nAtual ++
		QrySA1->(DbSkip())

  	EndDo

	If !Empty(cQuery)
		dbSelectArea(QrySA1)
		QrySA1->(DbCloseArea())
	EndIf

Return

