#include 'protheus.ch'
#include 'parmtype.ch'
/*---------------------------------------------------------------------------------------------
{Protheus.doc}  M410STTS
                Este ponto de entrada pertence à rotina de pedidos de venda, MATA410().
                Está em todas as rotinas de inclusão, alteração, exclusão, cópia e devolução 
                de compras.
                Executado após todas as alterações no arquivo de pedidos terem sido feitas
@type           function
@version        1.1
@author         Carlos Eduardo Saturnino - Atlanta Consulting
@since          07/04/2022
-----------------------------------------------------------------------------------------------
@version        1.2
@author         Cyberpolos
@since          18/01/2023
                Adicionado trecho para tratar da liberação automaticas de pedidos de venda na 
                inclusão, esses pedidos devem ter o campo SC5->C5_ZZTPPED == 'PE'.
---------------------------------------------------------------------------------------------*/
user function M410STTS()

	Local _nOper 		 := PARAMIXB[1]
	Local _cFilial		 := ""
	Local _cPedido		 := ""
    Local oQueueError   := Nil
    Local aArea     	 := GetArea()
    Local aAreaC5   	 := SC5->(GetArea())
    Local aAreaC6   	 := SC6->(GetArea())
    Local aAreaC9   	 := SC9->(GetArea())

	/*******************************************
	3 - Inclusão
	4 - Alteração
	5 - Exclusão
	6 - Copia
	7 - Devolução de Compras
	/*******************************************/

	//---------------------------------------------------------
	// Suntech 06/05/2026 - Protecao contra SC5 em EOF/BOF
	// Quando o TMKA271 (Televendas) chama MATA410 internamente
	// e ocorre rollback/cleanup, o SC5 pode nao estar posicionado.
	// O RecLock direto causava: "Falha na tentativa de bloquear
	// alias SC5, no registro no final do arquivo (EOF)".
	//---------------------------------------------------------
	If Select("SC5") == 0 .Or. SC5->(Eof()) .Or. SC5->(Bof()) .Or. SC5->(Recno()) == 0
		RestArea(aAreaC9)
		RestArea(aAreaC6)
		RestArea(aAreaC5)
		RestArea(aArea)
		Return
	EndIf

	_cFilial := SC5->C5_FILIAL
	_cPedido := SC5->C5_NUM

	If !Empty(_cPedido) .And. SC5->(RecLock("SC5", .F.))
		SC5->C5_STATU1  := cValtoChar(_nOper) // Campo de Controle do Acacias
		SC5->C5_ZSTATUS := cValtoChar(_nOper) // Suntech (Ricardo Araujo) - Gravar campo de controle para Integracao via API 17/01/2023
		SC5->(MsUnlock())
	Endif
	
	//---------------------------------------------------------
	// Posiciona nos itens do pedido de vendas
	//---------------------------------------------------------

	DBSelectArea("SC6")
	dbSetOrder(1)
	dbGoTop()
	If dbSeek(SC6->(C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO))
		While ! SC6->(Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == _cFilial + _cPedido .And. SC6->D_E_L_E_T_ <> '*'
			//---------------------------------------------------------
			// Efetua a gravação dos itens do pedido de Vendas
			//---------------------------------------------------------
			If SC6->(Reclock("SC6", .F.))
				SC6->C6_STATU1  := cValtoChar(_nOper) // Campo de Controle do Acacias
				SC6->C6_ZSTATUS := cValtoChar(_nOper) // Suntech (Ricardo Araujo) - Gravar campo de controle para Integracao via API 17/01/2023
			Endif
			SC6->(MsUnlock())
			SC6->(Dbskip())
		EndDo
	Endif

    //Cyberpolos 18/01/2023 (Inicio)
    //| Trecho add para realizar a liberação automatica de pedidos de vendas do tipo SC5->C5_ZZTPPED == 'PE'

    if _nOper = 3 .and. Alltrim(SC5->C5_ZZTPPED) == 'PE'

		//Gravo informações na SC5
		SC5->(reclock("SC5", .F.))
			SC5->C5_ZZSITFI := '2' //Liberado
			SC5->C5_ZZSITCO := '1' //Comercial Ok
		SC5->(MsUnlock())

        DbSelectArea("SC6")
		DbSetOrder(1)			
        SC6->(dbGotop())
				
		//posiciono na sc6 e realizo a liberaçção item a item
		if MsSeek(xFilial("SC6")+SC5->C5_NUM)
            while SC6->(!EOF()) .and. SC5->C5_NUM == SC6->C6_NUM
                MaLibDoFat(SC6->(RecNo()),(SC6->C6_QTDVEN-SC6->C6_QTDENT),.F.,.F.,.T.,.T.) 
                SC6->(MaLiberOk({SC6->C6_NUM},.T.))
                SC6->(Dbskip())
            enddo
        endif
    endif

	// ZTR: registra pedidos Marketplace elegiveis para o job de reabastecimento.
	// O pedido espelho nao e criado aqui: Orders.prw aplica a liberacao apos o ExecAuto.
	If _nOper == 3 .Or. _nOper == 4 .Or. _nOper == 5
		Begin Sequence
			If _nOper == 5
				ZTRDEL(_cFilial, _cPedido)
			Else
				ZTRQUEUE()
			EndIf
		Recover Using oQueueError
			ConOut("[ZTR] Falha isolada na atualizacao da fila do pedido.")
			If ValType(oQueueError) == "O"
				ConOut(cValToChar(oQueueError:Description))
			Else
				ConOut(cValToChar(oQueueError))
			EndIf
		End Sequence
	EndIf

    RestArea(aAreaC9)
    RestArea(aAreaC6)
    RestArea(aAreaC5)
    RestArea(aArea)
    //Cyberpolos 18/01/2023 (Fim)

return

Static Function ZTRDEL(_cFilial, _cPedido)

	Local aArea      := GetArea()
	Local aAreaZtr   := {}
	Local cChave     := ""
	Local cMutex     := "ZTR_" + cEmpAnt + "_03_" + AllTrim(_cPedido)
	Local lMutex     := .F.
	Local lLocked    := .F.
	Local oError     := Nil

	If AllTrim(_cFilial) != "03" .Or. Empty(_cPedido)
		Return
	EndIf
	If Select("ZTR") > 0
		aAreaZtr := ZTR->(GetArea())
	EndIf

	Begin Sequence
		lMutex := LockByName(cMutex, .T., .F.)
		If !lMutex
			ConOut("[ZTR] Exclusao da origem durante processamento; fila preservada: " + _cPedido)
		Else
			DbSelectArea("ZTR")
			DbSetOrder(1)
			cChave := PadR(AllTrim(_cFilial), TamSX3("ZTR_FILORI")[1]) + ;
					  PadR(AllTrim(_cPedido), TamSX3("ZTR_PEDORI")[1])
			If DbSeek(cChave)
				lLocked := RecLock("ZTR", .F.)
				If lLocked
					If Empty(ZTR->ZTR_PEDTRF) .And. ZTR->ZTR_TENTAT == 0 .And. ;
					   AScan({"AG_PGTO", "AG_LIB", "PRONTO"}, AllTrim(ZTR->ZTR_STATUS)) > 0
						ZTR->(DbDelete())
						ConOut("[ZTR] Solicitacao excluida com o pedido de origem: " + _cPedido)
					Else
						ZTR->ZTR_MSGERR := "Pedido de origem excluido; conferir manualmente a reposicao."
						ZTR->ZTR_DTATU := Date()
						ZTR->ZTR_HRATU := StrTran(Time(), ":", "")
						ConOut("[ZTR] Origem excluida; historico de reposicao preservado: " + _cPedido)
					EndIf
					ZTR->(MsUnlock())
					lLocked := .F.
				Else
					ConOut("[ZTR] Falha ao bloquear a fila na exclusao: " + _cPedido)
				EndIf
			EndIf
		EndIf
	Recover Using oError
		If ValType(oError) == "O"
			ConOut("[ZTR] Falha na exclusao da fila: " + cValToChar(oError:Description))
		Else
			ConOut("[ZTR] Falha na exclusao da fila: " + cValToChar(oError))
		EndIf
	End Sequence

	If lLocked
		ZTR->(MsUnlock())
	EndIf
	If lMutex
		UnLockByName(cMutex, .T., .F.)
	EndIf
	If Len(aAreaZtr) > 0
		RestArea(aAreaZtr)
	EndIf
	RestArea(aArea)

Return

/*/{Protheus.doc} ZTRQUEUE
Registra ou atualiza a solicitacao de reabastecimento na ZTR. Executada pelo
M410STTS somente para pedidos B2C da tabela MKP com ID Marketplace. A criacao
do pedido espelho sera responsabilidade de um processador posterior, apos
validacao de pagamento e liberacao integral dos itens.
/*/
Static Function ZTRQUEUE()

	Local aArea       := GetArea()
	Local lNew        := .F.
	Local lLocked     := .F.
	Local lSkipWrite  := .F.
	Local cParamOrig  := Upper(AllTrim(SuperGetMV("MV_PEDTRAN", .F., "")))
	Local cFilOrig    := ""
	Local cPedOrig    := ""
	Local cPedExt     := ""
	Local cApiId      := ""
	Local cSitFin     := ""
	Local cSitCom     := ""
	Local cLibOk      := "N"
	Local cStatus     := "AG_PGTO"
	Local cKey        := ""
	Local cStep       := ""
	Local oError      := Nil

	If Select("SC5") == 0 .Or. SC5->(Eof()) .Or. SC5->(Bof())
		RestArea(aArea)
		Return
	EndIf

	cFilOrig := AllTrim(SC5->C5_FILIAL)
	cPedOrig := AllTrim(SC5->C5_NUM)
	cPedExt  := AllTrim(SC5->C5_PEDECOM)
	cApiId   := AllTrim(SC5->C5_ZZNPEXT)
	cSitFin  := AllTrim(SC5->C5_ZZSITFI)
	cSitCom  := AllTrim(SC5->C5_ZZSITCO)

	If Empty(cParamOrig) .Or. cFilOrig != "03" .Or. Empty(cPedOrig) .Or. ;
	   Upper(AllTrim(SC5->C5_ZZORIGE)) != cParamOrig .Or. ;
	   Upper(AllTrim(SC5->C5_TABELA)) != "MKP" .Or. Empty(cPedExt)
		RestArea(aArea)
		Return
	EndIf

	// DbUseArea direto abre sem indices (Order 0); DbSelectArea abre pelo dicionario.
	If Select("ZTR") == 0
		Begin Sequence
			DbSelectArea("ZTR")
		Recover Using oError
			ConOut("[ZTR] Falha ao abrir a tabela de solicitacoes.")
			If ValType(oError) == "O"
				ConOut(cValToChar(oError:Description))
			Else
				ConOut(cValToChar(oError))
			EndIf
		End Sequence
	EndIf

	If Select("ZTR") == 0
		ConOut("[ZTR] Alias indisponivel; solicitacao nao enfileirada.")
		RestArea(aArea)
		Return
	EndIf

	Begin Sequence
		cStep := "ORDEM"
		DbSelectArea("ZTR")
		DbSetOrder(1)
		If ZTR->(IndexOrd()) != 1
			ConOut("[ZTR] Indice 1 indisponivel; solicitacao nao enfileirada.")
			lSkipWrite := .T.
		EndIf

		If !lSkipWrite
			cStep := "CHAVE"
			cKey := PadR(cFilOrig, TamSX3("ZTR_FILORI")[1]) + ;
					PadR(cPedOrig, TamSX3("ZTR_PEDORI")[1])
			lNew := !DbSeek(cKey)
		EndIf

		If !lSkipWrite .And. !lNew .And. (AllTrim(ZTR->ZTR_STATUS) == "CRIADO" .Or. ;
						AllTrim(ZTR->ZTR_STATUS) == "CRIANDO" .Or. ;
						AllTrim(ZTR->ZTR_STATUS) == "ERRO_REP" .Or. ;
						!Empty(ZTR->ZTR_PEDTRF) .Or. ;
						AllTrim(ZTR->ZTR_STATUS) == "CANCELADO" .Or. ;
						AllTrim(ZTR->ZTR_STATUS) == "ERRO_MAN")
			lSkipWrite := .T.
		EndIf

		If !lSkipWrite
			cStep := "LOCK"
			lLocked := RecLock("ZTR", lNew)
			If !lLocked
				ConOut("[ZTR] Falha ao bloquear a solicitacao " + cPedOrig)
				lSkipWrite := .T.
			EndIf
		EndIf

		If lLocked .And. !lNew
			If !Empty(ZTR->ZTR_PEDTRF) .Or. ;
			   AScan({"CRIADO", "CRIANDO", "ERRO_REP", "CANCELADO", "ERRO_MAN"}, AllTrim(ZTR->ZTR_STATUS)) > 0
				lSkipWrite := .T.
			EndIf
		EndIf

		If !lSkipWrite
			cStep := "GRAVA_CHAVE"
			If lNew
				ZTR->ZTR_FILIAL := xFilial("ZTR")
				ZTR->ZTR_FILORI := PadR(cFilOrig, TamSX3("ZTR_FILORI")[1])
				ZTR->ZTR_PEDORI := PadR(cPedOrig, TamSX3("ZTR_PEDORI")[1])
				ZTR->ZTR_TENTAT := 0
				ZTR->ZTR_DTCRI  := Date()
				ZTR->ZTR_HRCRI  := StrTran(Time(), ":", "")
			EndIf

			If cSitFin == "7"
				cStatus := "AG_LIB"
			EndIf
			// A liberacao total sera confirmada pelo processador, validando cada item na SC9.

			cStep := "GRAVA_DADOS"
			ZTR->ZTR_PEDEXT := PadR(cPedExt, TamSX3("ZTR_PEDEXT")[1])
			ZTR->ZTR_APIID  := PadR(cApiId, TamSX3("ZTR_APIID")[1])
			ZTR->ZTR_FDEST  := "02"
			ZTR->ZTR_SITFIN := PadR(cSitFin, TamSX3("ZTR_SITFIN")[1])
			ZTR->ZTR_SITCOM := PadR(cSitCom, TamSX3("ZTR_SITCOM")[1])
			ZTR->ZTR_LIBOK  := cLibOk
			ZTR->ZTR_STATUS := cStatus
			ZTR->ZTR_DTATU  := Date()
			ZTR->ZTR_HRATU  := StrTran(Time(), ":", "")
			ZTR->ZTR_MSGERR := ""
			ZTR->(MsUnlock())
			lLocked := .F.
		EndIf
	Recover Using oError
		ConOut("[ZTR] Erro ao enfileirar a solicitacao.")
		ConOut("Etapa: " + cStep)
		If ValType(oError) == "O"
			ConOut("Pedido: " + cPedOrig)
			ConOut(cValToChar(oError:Description))
			ConOut(cValToChar(oError:ErrorStack))
		Else
			ConOut(cValToChar(oError))
		EndIf
	End Sequence

	If lLocked .And. Select("ZTR") > 0
		ZTR->(MsUnlock())
	EndIf
	RestArea(aArea)

Return

User Function ZTRREQUE()

	Local aArea      := GetArea()
	Local aPedidos   := {"005941", "005942", "005943", "005944"}
	Local cPedido    := ""
	Local cChave     := ""
	Local cOrigem    := Upper(AllTrim(SuperGetMV("MV_PEDTRAN", .F., "")))
	Local nI         := 0

	If AllTrim(xFilial("SC5")) != "03"
		ConOut("[ZTR] Execute U_ZTRREQUE na filial 03.")
		RestArea(aArea)
		Return
	EndIf

	DbSelectArea("SC5")
	DbSetOrder(1)
	DbSelectArea("ZTR")
	DbSetOrder(1)

	If ZTR->(IndexOrd()) != 1
		ConOut("[ZTR] Indice unico da tabela nao esta disponivel.")
		RestArea(aArea)
		Return
	EndIf

	For nI := 1 To Len(aPedidos)
		cPedido := aPedidos[nI]
		cChave := PadR("03", TamSX3("ZTR_FILORI")[1]) + ;
				  PadR(cPedido, TamSX3("ZTR_PEDORI")[1])

		DbSelectArea("ZTR")
		If DbSeek(cChave)
			ConOut("[ZTR] Pedido ja possui solicitacao: " + cPedido)
			Loop
		EndIf

		DbSelectArea("SC5")
		If !DbSeek(xFilial("SC5") + PadR(cPedido, TamSX3("C5_NUM")[1]))
			ConOut("[ZTR] Pedido nao localizado na SC5: " + cPedido)
			Loop
		EndIf

		If AllTrim(SC5->C5_FILIAL) != "03" .Or. ;
		   Upper(AllTrim(SC5->C5_ZZORIGE)) != cOrigem .Or. ;
		   Upper(AllTrim(SC5->C5_TABELA)) != "MKP" .Or. ;
		   Empty(AllTrim(SC5->C5_PEDECOM))
			ConOut("[ZTR] Pedido nao atende aos criterios da fila: " + cPedido)
			Loop
		EndIf

		ZTRQUEUE()

		DbSelectArea("ZTR")
		If DbSeek(cChave)
			ConOut("[ZTR] Solicitacao enfileirada: " + cPedido + " - " + AllTrim(ZTR->ZTR_STATUS))
		Else
			ConOut("[ZTR] Solicitacao nao gravada; verifique o log do PE: " + cPedido)
		EndIf
	Next nI

	RestArea(aArea)

Return
