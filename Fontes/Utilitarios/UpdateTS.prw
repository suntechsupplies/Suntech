#Include "Protheus.ch"

User Function UpdateTS()

	Local aArea    := GetArea() //Salvando a área atual
	Local cTimeStamp as char
	Local nDate as numeric
	Local nTime as numeric
	Local nHour as numeric
	Local nMin as numeric
	Local nSec as numeric
	Local dDate as date
	Local cTime as char
	Local cPedido := '246723'
	
    cTimeStamp := FWTimeStamp(1)

    nDate := Val(cTimeStamp) / 60 / 60 / 24
	nTime := nDate - Int(nDate)
	nDate := Int(nDate)
	nHour := nTime * 24
	nMin := (nHour - Int(nHour)) * 60
	nHour := Int(nHour) -3 //TIMEZONE, pode verificar esse cálculo de outra forma...
	nSec := Int((nMin - Int(nMin)) * 60) //Pode ser usado o Ceiling...
	nMin := Int(nMin)

	dDate := CtoD("01/01/1970") + nDate
	cTime := StrZero(nHour, 2) + ":" + StrZero(nMin, 2) + ":" + StrZero(nMin, 2)

	ConOut(dDate, cTime)

	//Seleciona a tabela SA2 como a área ativa
    DBSelectArea("SC6")
    //Seleciona o 1 índice de SA2 -> A2_FILIAL+A2_COD+A2_LOJA
    SC6->(DBSetOrder(1))
 
    //Fazendo a busca exata do registro
    If(SC6->(DBSeek(FWxFilial("SC6")+cPedido)))        
		RecLock('SC6', .F.)
        	SC6->I_N_S_D_T_ := cTimeStamp
			SC6->S_T_A_M_P_ := cTimeStamp
    	SC6->(MsUnlock())
    EndIf

	//cQuery := "UPDATE SC5010 SET S_T_A_M_P_ = '" + cTimeStamp + "', I_N_S_D_T_ = '" + cTimeStamp + "' WHERE C6_NUM = '246723'"

	//Executa a instrução SQL de cQuery
	//nRet := TCSQLExec(cQuery)

	//If(nRet < 0 )
	//	MsgStop("Erro na execução da query:"+TcSqlError(), "Atenção")
	//Else
	//	MsgAlert("O UPDATE da query " + cQuery + " foi executado com sucesso!")
	//EndIf
	
	//Restaurando o ambiente salvo
    RestArea(aArea)

RETURN
