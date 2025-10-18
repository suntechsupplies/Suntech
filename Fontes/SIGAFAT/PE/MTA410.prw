#INCLUDE "totvs.ch"
#INCLUDE "parmtype.ch"

/*---------------------------------------------------------------------------------------------
{Protheus.doc}  MTA410
                Validação da tela toda no Pedido de Venda
@type           function
@version        1.1
@author         Antonio Ricardo de Araujo - Suntech Supplies
@since          05/07/2023
-----------------------------------------------------------------------------------------------*/

User Function MTA410()

	Local aArea          := GetArea()
	Local aAreaSA1   	 := SA1->(GetArea())
	Local aAreaSC5   	 := SC5->(GetArea())
	Local aAreaSC6   	 := SC6->(GetArea())
	Local aAreaZB8   	 := ZB8->(GetArea())
	Local nPosItem    	 := GDFIELDPOS("C6_ITEM")
	Local nSaldoCashback := 0
	Local nDescCashback  := 0
	Local nTotalPedido   := 0
	Local nValorCashBack := 0
	Local nSaldo 		 := 0
	Local nx 			 := 0
	Local lRet		     := .T.
	Local cTabela        := "ZB8"
	Local aDados		 := {}
	Local cTudoOk        := ""
	Local cTransact      := ""
	Local nRetorno       := 0
	Private aTipoPedido  := StrTokArr(GetMV("HB_TPPCB"),",")
	Private nValorLimiteDesc  := GetMV("HB_VLMDPCB")	

	IF ALTERA //.OR. INCLUI
		For nx := 1 To Len(aCols)
			If !aCols[nx,Len(aHeader)+1]
				
				cItem := aCols[nx,nPosITEM]

				If nx == 1
					cItemAnt := "00"
				else
					cItemAnt := aCols[nx-1,nPosITEM]
				EndIf

				If cItem == cItemAnt
					MsgStop("Existem ao menos uma duplicidade de sequencial de item no pedido. Favor exclua a duplicidade do pedido, e integre novamente.")
					Return(.F.)
				EndIf

			Endif
		Next

		SA1->(DBSetOrder(1))
		SA1->(DbGoTop())
		If SA1->(dbSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI))
			nSaldoCashback := SA1->A1_ZZVLCSB
		Endif
		
		if nSaldoCashback > 0
			M->C5_DESC2 := 0
			A410RECALC()
		Endif

		For nx := 1 To Len(aCols)
			If !aCols[nx,Len(aHeader)+1]
				nTotalPedido += aCols[nx][8]
			Endif
		Next

		nPos := aScan(aTipoPedido, {|x| AllTrim(Upper(x)) == C5_ZZTPPED}) // Verifica se o tipo de pedido é cashback

		nDescCashback  := (nSaldoCashback / nTotalPedido) * 100
		nValorCashBack := (nTotalPedido * nDescCashback / 100)

		If (nPos > 0) .AND. (nSaldoCashback > 0)
			
			If nDescCashback > 10 
				MsgStop("O percentual de cashback não pode ser maior que 10% do valor do pedido.")
			Endif

			If MsgYesNo("Cliente com cashback de R$ " + AllTrim(Str(nSaldoCashback)) + " e o valor do pedido é R$ " + AllTrim(Str(nTotalPedido)) + " sendo um percentual de " + AllTrim(Str(Round(nDescCashback, 2))) + "%. Deseja aplicar o valor máximo de R$ " +  AllTrim(Str(Round(nValorCashBack, 2))) + " e eliminar o saldo restante?", "Confirma?")
				
				IF nDescCashback > SA1->A1_ZZCASHB
					M->C5_DESC2 := SA1->A1_ZZCASHB
				Else	
					M->C5_DESC2 := nDescCashback	
				Endif			
				
				A410RECALC()

				aAdd(aDados, {"ZB8_FILIAL", M->C5_FILIAL,    		    Nil})
				aAdd(aDados, {"ZB8_NUM",    StrZero(Val(M->C5_NUM), 9), Nil})
				aAdd(aDados, {"ZB8_PREFIX", "1",             		    Nil})
				aAdd(aDados, {"ZB8_PARCEL", "01",            		    Nil})
				aAdd(aDados, {"ZB8_TIPO",   "CB",            		    Nil})
				aAdd(aDados, {"ZB8_PORTAD", "",            		        Nil})
				aAdd(aDados, {"ZB8_CLIENT", M->C5_CLIENTE,   		    Nil})
				aAdd(aDados, {"ZB8_LOJA",   M->C5_LOJACLI,              Nil})
				aAdd(aDados, {"ZB8_NOMCLI", SA1->A1_NOME,    		    Nil})
				aAdd(aDados, {"ZB8_EMISSA", M->C5_EMISSAO,   		    Nil})
				aAdd(aDados, {"ZB8_VENCTO", M->C5_EMISSAO,   		    Nil})
				aAdd(aDados, {"ZB8_VALOR",  nValorCashBack, 		    Nil})
				aAdd(aDados, {"ZB8_SALDO",  0,               		    Nil})
				aAdd(aDados, {"ZB8_BASCOM", nTotalPedido,    		    Nil})
				aAdd(aDados, {"ZB8_VEND1",  M->C5_VEND1,     		    Nil})
				aAdd(aDados, {"ZB8_EMAIL",  '1',             		    Nil})

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
						
						If SA1->(dbSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI))
							RecLock("SA1",.F.)
								A1_ZZVLCSB -= nValorCashBack
							SA1->(MsUnlock())
						Endif

						lRet := .T.

						nSaldo := nSaldoCashback - nValorCashBack
						
						If nSaldo > 0
							//Chama a função para eliminar o saldo restante
							//Elimina o saldo restante do cliente na tabela SA1
							//e faz um lock na tabela ZB8 para não permitir que o mesmo saldo seja utilizado em outro pedido
							EliminarSaldo(nSaldo, nTotalPedido)
						EndIf

					Else
						AutoGrLog("Falha na inclusão do registro")
						MostraErro()
						DisarmTransaction()
						lRet := .F.
					EndIf
				End Transaction
			Else
				M->C5_DESC2 := 0
				A410RECALC()
			EndIf
			
		Endif	

	Endif

	RestArea(aAreaSA1)
	RestArea(aAreaSC5)
	RestArea(aAreaSC6)
	RestArea(aAreaZB8)
	RestArea(aArea)

Return(lRet)

Static Function EliminarSaldo(nSaldo, nTotalPedido)

	Local lRet		     := .T.
	Local cTabela        := "ZB8"
	Local aDados		 := {}
	Local cTudoOk        := ""
	Local cTransact      := ""
	Local nRetorno       := 0
	Private aTipoPedido  := StrTokArr(GetMV("HB_TPPCB"),",")
	Private nValorLimiteDesc  := GetMV("HB_VLMDPCB")
	
	aAdd(aDados, {"ZB8_FILIAL", M->C5_FILIAL,    		    Nil})
	aAdd(aDados, {"ZB8_NUM",    StrZero(Val(M->C5_NUM), 9), Nil})
	aAdd(aDados, {"ZB8_PREFIX", "1",             		    Nil})
	aAdd(aDados, {"ZB8_PARCEL", "01",            		    Nil})
	aAdd(aDados, {"ZB8_TIPO",   "ER",            		    Nil})
	aAdd(aDados, {"ZB8_PORTAD", "",            		        Nil})
	aAdd(aDados, {"ZB8_CLIENT", M->C5_CLIENTE,   		    Nil})
	aAdd(aDados, {"ZB8_LOJA",   M->C5_LOJACLI,              Nil})
	aAdd(aDados, {"ZB8_NOMCLI", SA1->A1_NOME,    		    Nil})
	aAdd(aDados, {"ZB8_EMISSA", M->C5_EMISSAO,   		    Nil})
	aAdd(aDados, {"ZB8_VENCTO", M->C5_EMISSAO,   		    Nil})
	aAdd(aDados, {"ZB8_VALOR",  nSaldo,  					Nil})
	aAdd(aDados, {"ZB8_SALDO",  0,               		    Nil})
	aAdd(aDados, {"ZB8_BASCOM", nTotalPedido,    		    Nil})
	aAdd(aDados, {"ZB8_VEND1",  M->C5_VEND1,     		    Nil})
	aAdd(aDados, {"ZB8_EMAIL",  '1',             		    Nil})

	// Inicializa a transação
	Begin Transaction
		// Joga a tabela para a memória (M->)
		RegToMemory(;
			cTabela,; // cAlias - Alias da Tabela
			.T.,;     // lInc   - Define se é uma operação de inclusão ou atualização
			.F.;      // lDic   - Define se irá inicializar os campos conforme o dicionário
		)

		// Se conseguir fazer a execução automática
		If EnchAuto(;
			cTabela,; // cAlias  - Alias da Tabela
			aDados,;  // aField  - Array com os campos e valores
			cTudoOk,; // uTUDOOK - Validação do botão confirmar
			3;        // nOPC    - Operação do Menu (3=inclusão, 4=alteração, 5=exclusão)
			)

			// Aciona a efetivação da gravação
			nRetorno := AxIncluiAuto(;
				cTabela,;   // cAlias     - Alias da Tabela
				,;          // cTudoOk    - Operação do TudoOk (se usado no EnchAuto não precisa usar aqui)
				cTransact,; // cTransact  - Operação acionada após a gravação mas dentro da transação
				3;          // nOpcaoAuto - Operação do Menu (3=inclusão, 4=alteração, 5=exclusão)
			)

			If SA1->(dbSeek(xFilial("SA1") + M->C5_CLIENTE + M->C5_LOJACLI))
				RecLock("SA1", .F.)
					A1_ZZVLCSB -= nSaldo
				SA1->(MsUnlock())
			EndIf

			lRet := .T.

		Else
			AutoGrLog("Falha na inclusão do registro")
			lRet := .F.
			MostraErro()
			DisarmTransaction()
		EndIf
	End Transaction

Return(lRet)
