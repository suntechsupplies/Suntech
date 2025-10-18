#INCLUDE "totvs.ch"
#INCLUDE "parmtype.ch"
#Include 'TBICONN.CH'

/*/{Protheus.doc} F200TIT()
   
    O ponto de entrada F200TIT do CNAB a receber, será executado após o Sistema ler a linha de detalhe e gravar todos os dados.

@type function
@author Antonio Ricardo de Araujo		
@since 16/01/2023

@see F200TIT	
/*/
User Function F200TIT()

	Local aAreaSE1      := GetArea()
	Local lRet          := .T.
	Local cTabela       := "ZB8"
	Local aDados        := {}
	Local cTudoOk       := ""
	Local cTransact     := ""
	Local nRetorno      := 0
	Private nLimiteDesc := GetMV("HB_VLMDPCB")
	Private nDiasPrazo  := GetMV("HB_DIASPCB")

	DBSelectArea("SA1")
	SA1->(DBSetOrder(1))
	SA1->(DbGoTop())
	SA1->(dbSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA))

	aAdd(aDados, {"ZB8_FILIAL", SE1->E1_FILIAL,  Nil})
	aAdd(aDados, {"ZB8_NUM",    SE1->E1_NUM,     Nil})
	aAdd(aDados, {"ZB8_PREFIX", SE1->E1_PREFIXO, Nil})
	aAdd(aDados, {"ZB8_PARCEL", SE1->E1_PARCELA, Nil})
	aAdd(aDados, {"ZB8_TIPO",   SE1->E1_TIPO,    Nil})
	aAdd(aDados, {"ZB8_PORTAD", SE1->E1_PORTADO, Nil})
	aAdd(aDados, {"ZB8_CLIENT", SE1->E1_CLIENTE, Nil})
	aAdd(aDados, {"ZB8_LOJA",   SE1->E1_LOJA,    Nil})
	aAdd(aDados, {"ZB8_NOMCLI", SE1->E1_NOMCLI,  Nil})
	aAdd(aDados, {"ZB8_EMISSA", SE1->E1_EMISSAO, Nil})
	aAdd(aDados, {"ZB8_VENCTO", SE1->E1_VENCREA, Nil})
	aAdd(aDados, {"ZB8_VALOR",  SE1->E1_VALOR * (SA1->A1_ZZCASHB/100),   Nil})
	aAdd(aDados, {"ZB8_SALDO",  SE1->E1_SALDO,   Nil})
	aAdd(aDados, {"ZB8_BASCOM", SE1->E1_VALOR,   Nil})
	aAdd(aDados, {"ZB8_VEND1",  SE1->E1_VEND1,   Nil})
	aAdd(aDados, {"ZB8_EMAIL",  '1',             Nil})

	If SA1->A1_ZZDESC < nLimiteDesc .AND. (SE1->E1_VENCREA - SE1->E1_BAIXA) < nDiasPrazo .AND.SA1->A1_ZZCASHB <> 0
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
				
				//Suntech (Ricardo Araujo) - Gravar campo de controle para Integração via API 17/01/2023
				SE1->(dbSetOrder(1))
				If SE1->(dbSeek(xFilial("SE1")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO))
					RecLock("SE1",.F.)
						E1_ZZCASHB := 'S'
						E1_ZSTATUS := '4'
					SE1->(MsUnlock())
				Endif

				If SA1->(dbSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA))
					RecLock("SA1",.F.)
						A1_ZZVLCSB += (SE1->E1_VALOR * (SA1->A1_ZZCASHB/100))
					SA1->(MsUnlock())
				Endif

			Else
				AutoGrLog("Falha na inclusão do registro")
				MostraErro()
				DisarmTransaction()
			EndIf
			
			lRet := .T.

		End Transaction
	Else
		//Suntech (Ricardo Araujo) - Gravar campo de controle para Integração via API 17/01/2023
		SE1->(dbSetOrder(1))
		If SE1->(dbSeek(xFilial("SE1")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO))
			RecLock("SE1",.F.)
				E1_ZSTATUS := '4'
			SE1->(MsUnlock())
		Endif
		
		lRet := .F.

	EndIf

	RestArea(aAreaSE1)

Return lRet
