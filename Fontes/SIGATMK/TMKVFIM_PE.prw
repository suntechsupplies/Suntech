#Include "Protheus.ch"
#Include "Rwmake.ch"
#Include "Topconn.ch"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³TMKVFIM   ºGustavo Buson ³             º Data ³  29/03/2021 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³Ponto de entrada para gravação de dados do Atendimento no   º±±
±±º          ³Pedido de venda. Disparado pela rotina TMK271               º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Especifico HB-Suntech                                      º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

User Function TMKVFIM()

	Local _aArea := GetARea()
	Local _aAreaSUA := SUA->(GetARea())
	Local _aAReaSUB := SUB->(GetARea())
	Local _aAreaSC5 := SC5->(GetARea())
	Local _aAReaSC6 := SC6->(GetARea())
	Local _nPosItem := aScan(aHeader,{|X|upper(alltrim(x[2]))=="UB_ITEM"})
	Local _nPosDel  := Len(aHeader)+1
	Local _cAtendi  := _cNumPed  := " "
	Local cProduto := IIf(ReadVar()=="M->UA_PRODUTO",M->UA_PRODUTO,GdFieldGet("UA_PRODUTO"))
	//Local cFamilia := RetField("SBM",1,xFilial("SBM")+RetField("SB1",1,xFilial("SB1")+cProduto,"B1_GRUPO"),"BM_ZZFAM")

	// Gravação do Cabeçalho do Pedido de Venda

	dbSelectArea("SC5")
	dbSetOrder(1)
	dbSeek(xFilial("SC5")+SUA->UA_NUMSC5)

	// Localização da Transportadora

	dbSelectArea("SA4")
	dbSetOrder(1)
	dbSeek(xFilial()+SUA->UA_TRANSP)

	If Found()
		RecLock("SC5",.F.)

		SC5->C5_ZZTPPED		:= SUA->UA_ZZTPPED   // Tipo Venda HB
		SC5->C5_NATUREZ 	:= SUA->UA_ZZNATUR   // Natureza Financeira
		//SC5->C5_ZZNOME	:= SUA->UA_ZZNOME 	//Razão Social do Cliente
		//SC5->C5_ZZNOME  := If(!INCLUI,Posicione("SA1",1,xFilial("SA1")+SUA->UA_CLIENTE+SUA->UA_LOJA,"A1_NOME"),"")
		//SC5->C5_ZZNREDU	:= SUA->UA_ZZNREDU  //Nome Reduzido do Cliente
		//SC5->C5_ZZNREDU	:= If(!INCLUI,Posicione("SA1",1,xFilial("SA1")+SUA->UA_CLIENTE+SUA->UA_LOJA,"A1_NREDUZ"),"")
		//SC5->C5_ZZPDCLI	:= SUA->UA_ZZPDCLI  //Número do Pedido do Cliente
		//SC5->C5_ZZNTRAN := SA4->A4_NREDUZ   // Nome Reduzido da Transportadora
		//SC5->C5_ZZNVD1	:= SUA->UA_ZZNVD1   //Nome Reduzido do Vendedor 1
		//SC5->C5_VEND2	:= SUA->UA_ZZVEND2	//Código do Vendedor 2 (Gerente)
		//SC5->C5_ZZNVD2	:= SUA->UA_ZZNVD2	//Nome Reduzido do Vendedor 2 (Gerente)
		//SC5->C5_COMIS2	:= SUA->UA_ZZCOMS2	//Comissão do Vendedor 2 (Gerente)
		//SC5->C5_PARC1	:= SUA->UA_ZZPARC1	//Valor da Parcela 1
		//SC5->C5_DATA1	:= SUA->UA_ZZDATA1	//Data de Vencimento da Parcela 1
		//SC5->C5_PARC2	:= SUA->UA_ZZPARC2	//Valor da Parcela 2
		//SC5->C5_DATA2	:= SUA->UA_ZZDATA2	//Data de Vencimento da Parcela 2
		//SC5->C5_PARC3	:= SUA->UA_ZZPARC3	//Valor da Parcela 3
		//SC5->C5_DATA3	:= SUA->UA_ZZDATA3	//Data de Vencimento da Parcela 3
		//SC5->C5_PARC4	:= SUA->UA_ZZPARC1	//Valor da Parcela 4
		//SC5->C5_DATA4	:= SUA->UA_ZZDATA1	//Data de Vencimento da Parcela 4
		//SC5->C5_PARC5	:= SUA->UA_ZZPARC1	//Valor da Parcela 5
		//SC5->C5_DATA5	:= SUA->UA_ZZDATA1	//Data de Vencimento da Parcela 5
		//SC5->C5_PARC6	:= SUA->UA_ZZPARC1	//Valor da Parcela 6
		//SC5->C5_DATA6	:= SUA->UA_ZZDATA1	//Data de Vencimento da Parcela 6
		//SC5->C5_MENNOTA	:= SUA->UA_ZZMNOTA	//Mensagem para Nota Fiscal
		//SC5->C5_MENPAD	:= SUA->UA_ZZMNPAD	//Mensagem Padrão para Nota Fiscal
		_cAtendi        := SUA->UA_NUM		//Número do Atendimento
		_cNumPed        := SC5->C5_NUM      //Número do Pedido de Venda

		MsUnlock()

		// Gravação do(s) item(ns) do Pedido de Vendas
		/*
	dbSelectArea("SUB")
	dbSetOrder(1)
	dbSeek(xFilial()+SUA->UA_NUM)

	While !Eof() .and. UB_FILIAL == SUA->UA_FILIAL .and. UB_NUM == SUA->UA_NUM

	dbSelectArea("SC6")
	dbSetOrder(1)
	dbSeek(xFilial()+_cNumPed+SUB->UB_ITEM+SUB->UB_PRODUTO)

		If Found()

		RecLock("SC6")

		SC6->C6_COMIS1  := SUB->UB_ZZCOM1 	//% Comissão 1 (Vendedor)
		SC6->C6_COMIS2  := SUB->UB_ZZCOM2 	//% Comissão 2 (Gerente)
		SC6->C6_ZZFAMIL := SUB->UB_ZZFAMIL 	//Família do Produto

		MsUnlock()

		EndIf

	dbSelectArea("SUB")
	dbSkip()

	EndDo
		*/
	Endif

	RestArea(_aAreaSC5)
	RestArea(_aAreaSC6)
	RestArea(_aAreaSUA)
	RestArea(_aAreaSUB)
	RestArea(_aArea)

Return()
/*
	&& Executa somente sobre Orçamentos Faturados
	If !Empty(cNumPed)
		&& Grava preço promocional e informações adicionais no SC6, caso necessário
		U_GrvPromo(cAtendimento, cNumPed)

		&& Libera Pedido de Venda
		U_LiberaPV(cNumPed)

		&& Simulação do Cáculo do Frete no Televendas
		U_ComplSC5(cNumPed)

		&& Orçamento
		U_SlvHist(cNumPed)

		&& SE GEROU O PEDIDO LIBERADO, o sistema já reservou o estoque para o PV, então deletamos
		&& as reservas do orçamento em questão, caso elas existam.
		U_DelReserv(cAtendimento)
	else
		&& Rotina de alocação de estoque
		U_AlocReserva()
	EndIf
Return
