#INCLUDE "totvs.ch"
#INCLUDE "parmtype.ch"

/*/{Protheus.doc} M460FIM

Ponto de entrada no final da geracao da NF Saida, utilizado
para gravacao de dados adicionais.

@type function
@author Deivid A. C. de Lima
@since 19/04/2010

@see MSGNF02

-------------------------------------------------------------------------------------------
Alteração   :   28/08/2020
@Descricao  :	Adicionado trecho para tratar da customização junto ao portal da Blu.
@Autor      :	Cyberpolos

/*/
User Function M460FIM()

    Local AreaSF2 := SF2->(GetArea())
	Local AreaSC5 := SC5->(GetArea())
	Local AreaSUA := SUA->(GetArea())
	Local AreaSE1 := SE1->(GetArea())
    Local aArea   := GetArea()
	Local lUseBlu  := .T. 

	//Parametro para verIficar se as rotina BLU está ativa
    lUseBlu :=  GetMv('CP_BLUUSE')

	//Cyberpolos| Suntech Supplies Se tiver condição de pagamento Blu
	If Alltrim(SF2->F2_COND) $ Alltrim(Getmv("CP_BLUCOND")) .And. lUseBlu

		//Chamada da rotina para gravar integração BLU na tabela ZBL, passando (2= Fatura, NF, Serie )
		U_BLUINT("2",SF2->F2_DOC,SF2->F2_SERIE,SF2->F2_FILIAL) 

	EndIf

	//Cyberpolos | Suntech Supplies Se tiver natureza na condição de pagamento, os titulos serão gerados para ela
	If !Empty(Posicione("SE4",1,xFilial("SE4")+SF2->F2_COND,"E4_XNATURE"))
		DbSelectArea("SE1")
		V_OrdSE1 := IndexOrd()
		V_RecSE1 := Recno()

		DbSetOrder(2)
		If dbSeek(Xfilial("SE1")+SF2->F2_CLIENTE+SF2->F2_LOJA+SF2->F2_SERIE+SF2->F2_DOC)
			While !EOF() .AND. SE1->E1_CLIENTE+SE1->E1_LOJA+SE1->E1_PREFIXO+SE1->E1_NUM==SF2->F2_CLIENTE+SF2->F2_LOJA+SF2->F2_SERIE+SF2->F2_DOC
				RECLOCK("SE1",.F.)
					SE1->E1_NATUREZ	:= Posicione("SE4",1,xFilial("SE4")+SF2->F2_COND,"E4_XNATURE")
					SE1->E1_ZSTATUS := "3" //Suntech (Ricardo Araujo) - Gravar campo de controle para Integração via API 08/02/2023
				MSUNLOCK()
				DBSELECTAREA("SE1")
				DBSKIP()
			EndDo
		Endif

	Endif
	//Fim cyberpolos   
	
	//Cyberpolos  add por Anderson  | Suntech Supplies - 16-12-2020
	//GRAVAR LINK EM F2_XTRACKI 
	If ExistBlock("CPTRASF2",.F.,.T.) 
        ExecBlock("CPTRASF2",.F.,.T.,{SF2->F2_DOC,SF2->F2_SERIE})
	Endif

	//Suntech (Ricardo Araujo) - Fechar Atendimento no Call Center após a emissão da Nota
	DbSelectArea("SUA")
	DbSetOrder(8)
	If dbSeek("  "+SC5->C5_NUM)
		RECLOCK("SUA",.F.)
			SUA->UA_ZZSTATU := "000014"
			SUA->UA_ZZDSTAT := "FATURADO"
		MSUNLOCK()
	Endif
	//Fim -- Suntech

	//Suntech (Ricardo Araujo) - Gravar campo de controle para Integração via API 17/01/2023
	Reclock("SF2",.F.)
		SF2->F2_ZSTATUS	:= "3"
	MsUnlock()

	Reclock("SC5",.F.)
		SC5->C5_ZSTATUS	:= "4"
	MsUnlock()
	//Fim -- Suntech

	//Suntech (Ricardo Araujo) - Gravação da informação no cabeçalho do pedido de venda e através do Ponto de Entrada M460FIM o valor é gravado no Título. 10/10/2022
	// Campos Criados: E1_ZZRESCR, C5_ZZRESCR
	DbSelectArea("SE1")	
	DbSetOrder(2)
	
	If dbSeek(Xfilial("SE1")+SF2->F2_CLIENTE+SF2->F2_LOJA+SF2->F2_SERIE+SF2->F2_DOC)
		While !EOF() .AND. SE1->E1_CLIENTE+SE1->E1_LOJA+SE1->E1_PREFIXO+SE1->E1_NUM==SF2->F2_CLIENTE+SF2->F2_LOJA+SF2->F2_SERIE+SF2->F2_DOC
			RECLOCK("SE1",.F.)
				SE1->E1_ZZRESCR	:= SC5->C5_ZZRESCR
				SE1->E1_ZSTATUS	:= "3" //Suntech (Ricardo Araujo) - Gravar campo de controle para Integração via API 17/01/2023
			MSUNLOCK()
			DBSELECTAREA("SE1")
			DBSKIP()
		EndDo
	Endif
	//Fim -- Suntech

	/*
	//Executa o Wizard do Acelerador de Mensagens da NF no final da geração da NF de Saída
	If ExistBlock("MSGNF02",.F.,.T.)
		ExecBlock("MSGNF02",.F.,.T.,{})
	Endif	
	*/

    RestArea(AreaSF2)
	RestArea(AreaSC5)
	RestArea(AreaSE1)
	RestArea(AreaSUA)
    RestArea(aArea)
	
Return
