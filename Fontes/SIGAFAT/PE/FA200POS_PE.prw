#Include "PROTHEUS.CH"

/*/{Protheus.doc} FA200POS
O ponto de entrada FA200POS é inserido após o posicionamento do SEB (Ocorrências bancárias),
chamado no processamento de todas as linhas do arquivo de retorno, antes da execução das ações
correspondentes à ocorrência e da localização / posicionamento do título correspondente no SE1.

Para a localização do Título correspondente no SE1, foram disponibilizadas as seguintes variáveis:
cNumTit: Contém o Prefixo + Número + Parcela do título;
cEspecie: Contém o Tipo do Título

@author Victor Freidinger
@since 20/08/2019
@type function
/*/

User Function FA200POS()

	VldRet()

Return

static Function VldRet()

	Local aArea    	:= GetArea()
	Local aAreaSE1 	:= SE1->(GetArea())
	Local aAreaSE5 	:= SE5->(GetArea())
	Local aAreaSEA 	:= SEA->(GetArea())
	//Local cNatureza	:= Alltrim(Substr(&(GetMv("MV_NATDESC")),1,10))
	Local cBordero	:= ""
	Local cSituAnt	:= ""
	//Local cSequencia:= ""
	//Local aSE5	  	:= {}

	Private lMsErroAuto := .F.

	// Colocado para reprocessar Santander e Itaú
	If (cBanco == "033" .and. Alltrim(cOcorr) == "02") .or. (cBanco == "341" .and. Alltrim(cOcorr) == "04")

		dbselectarea("SE1")
		SE1->(dbSetOrder(19)) // Filial+IdCnab
		If SE1->(DbSeek(Substr(cNumTit,1,10))) //IdCnab

			cBordero := SE1->E1_NUMBOR 	// Gravo o numero do bordero antes de apagar
			//cSituAnt := SE1->E1_SITUACA // Gravo a situacao de cobranca antes de alterar e para gravar no bordero situacao anterior

			Conout("Alterar a situacao do Titulo para cobrança descontada (SE1) - PE: FA200POS")
			Reclock("SE1",.F.)
			SE1->E1_SITUACA := "1"
			//SE1->E1_PORTADO := cBanco
			SE1->E1_AGEDEP  := cAgencia
			SE1->E1_CONTA   := cConta
			//SE1->E1_NUMBOR := " "
			SE1->(MsUnLock())

			Conout("Deletar Titulo do Bordero se existir (SEA) - PE: FA200POS")
			dbSelectArea("SEA")
			dbSetOrder(1)
			If dbSeek(xFilial("SEA")+cBordero+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO)
				Reclock( "SEA" , .F. , .T.)
				SEA->(dbDelete())
				SEA->(MsUnlock())
			EndIf

			Conout("Inclusao de um novo titulo no bordero referente a cobrança descontada (SEA) - PE: FA200POS")
			Reclock("SEA",.T.)
			SEA->EA_FILIAL  := xFilial("SE1")
			SEA->EA_PREFIXO := SE1->E1_PREFIXO
			SEA->EA_NUM	    := SE1->E1_NUM
			SEA->EA_PARCELA := SE1->E1_PARCELA
			SEA->EA_TIPO    := SE1->E1_TIPO
			SEA->EA_PORTADO := cBanco
			SEA->EA_AGEDEP  := cAgencia 
			SEA->EA_NUMCON  := cConta   
			SEA->EA_DATABOR	:= dBaixa
			SEA->EA_CART  	:= "R"
			SEA->EA_SITUACA := "1"      
			SEA->EA_SITUANT := cSituAnt
			SEA->EA_FILORIG := SE1->E1_FILORIG
			SEA->EA_ORIGEM  := "FA200POS"
			SEA->(MsUnLock())
		EndIf
		//EndIf
	EndIf

	RestArea(aAreaSEA)
	RestArea(aAreaSE5)
	RestArea(aAreaSE1)
	RestArea(aArea)

Return .T.
