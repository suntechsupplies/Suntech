#INCLUDE "totvs.ch"
#include "PROTHEUS.CH"
#Include 'TBICONN.CH'

/*/{Protheus.doc} FA070CA4()
   
    O ponto de entrada FA070CA4 sera executado apos confirmacao do cancelamento da baixa do contas a receber.

@type function
@author Antonio Ricardo de Araujo		
@since 16/01/2023

@see FA070CA4	
/*/
User Function FA070CA4()

	Local aAreaSE1 := GetArea()
	Local lRet     := .T.

	DbSelectArea('ZB8')
	ZB8->(DbSetOrder(1)) //A1_FILIAL + A1_COD + A1_LOJA
	ZB8->(DbGoTop())

	//Iniciando o controle de transações
	Begin Transaction

		//Se conseguir posicionar no cliente, apaga o registro
		If ZB8->(MsSeek(SE1->E1_FILIAL + SE1->E1_NUM + SE1->E1_PREFIXO + SE1->E1_PARCELA))

            SA1->(dbGoTop())
            SA1->(dbSetOrder(1))
            If SA1->(dbSeek(xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA))
                RecLock("SA1",.F.)
                    A1_ZZVLCSB -= ZB8->ZB8_VALOR
                SA1->(MsUnlock())
            Endif

			RecLock('ZB8', .F.)
			DbDelete()
			ZB8->(MsUnlock())
			ZB8->(DbCommit())

		EndIf

		If SE1->(dbSeek(xFilial("SE1")+SE1->E1_PREFIXO+SE1->E1_NUM+SE1->E1_PARCELA+SE1->E1_TIPO))
			RecLock("SE1",.F.)
			    E1_ZZCASHB := 'N'
			SE1->(MsUnlock())
		Endif

	End Transaction

	RestArea(aAreaSE1)

Return lRet
