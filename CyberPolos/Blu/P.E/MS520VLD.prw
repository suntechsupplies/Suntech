#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MS520VLD
Ponto de entrada usado para validar se a NF pode ser excluida, chama rotina de cancelamento de fatura no portal BLU,
se conseguir é permitido cancelar a NF.
@type user function
@version 2.0
@author Cyberpolos 
@since 17/07/2020
@return lRet, retorno logico se pode ou não prosseguir com o cancelamento do documento.
/*/
User Function MS520VLD()

    Local aArea := GetArea()
    Local lRet  := .T.
    Local lUseBlu  := .T.

    //Parametro para verIficar se as rotina BLU está ativa
    lUseBlu :=  GetMv('CP_BLUUSE')

    If Alltrim(SF2->F2_COND) $ Alltrim(Getmv("CP_BLUCOND")) .And. lUseBlu
    
        //Chamada da rotina de cancelamento/devolução de cobrança BLU, passando no paramentro (2= Fatura,numero BLU na tabela ZBL)
        lRet := U_BLUCANC("2",SF2->F2_FILIAL,SF2->F2_XNUMBLU)  

    EndIf

    RestArea(aArea)

Return lRet
