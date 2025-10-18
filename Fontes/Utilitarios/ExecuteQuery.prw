#Include "Protheus.ch"
#Include 'topconn.ch'

User Function ExecuteQuery()

	Local cQuery     := ""
	Local aArea      := GetArea()
	Local nAtual     := 0
	Local cFilialx   := ""
	Local cNota      := ""
	Local cItem      := ""
	Local cProduto   := ""
	Local cTimeStamp := ""
	Local cInsertData := ""
    Local cAliasSC6  := ""

	cAliasSC6:= GetNextAlias()

	cQuery += "SELECT C6_FILIAL, C6_NUM, C6_PRODUTO, C6_ITEM, C6_QTDVEN, C6_QTDENT, C6_QTDEMP, C6_NOTA, I_N_S_D_T_, S_T_A_M_P_, "
	cQuery += "CONVERT(VARCHAR(19), I_N_S_D_T_ AT TIME ZONE 'UTC' AT TIME ZONE 'E. South America Standard Time', 120) AS C6_INSDT, "
	cQuery += "CONVERT(VARCHAR(19), S_T_A_M_P_ AT TIME ZONE 'UTC' AT TIME ZONE 'E. South America Standard Time', 120) AS C6_STAMP FROM "
	cQuery += Retsqlname("SC6") + " SC6010, "
	cQuery += "WHERE 0=0 "
	cQuery += "AND SC6010.D_E_L_E_T_ = '' "
	cQuery += "AND SC6010.C6_NUM  = '" + '246723' + "' "
	cQuery += "ORDER BY SC6010.C6_NUM" 

    cQuery := ChangeQuery(cQuery)

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSC6,.T.,.T.)
    dbSelectArea(cAliasSC6)

	While !Eof()

		dbSelectArea("SC6")
		dbSetOrder(1)

		cFilialx    := (cAliasSC6)->C6_FILIAL
		cNota       := (cAliasSC6)->C6_NUM
		cItem       := (cAliasSC6)->C6_ITEM
		cProduto    := (cAliasSC6)->C6_PRODUTO
		cTimeStamp  := (cAliasSC6)->C6_STAMP
		cInsertData := (cAliasSC6)->C6_INSDT

		(cAliasSC6)->(DbSkip())

	EndDo

	(cAliasSC6)->(DbCloseArea())
	RestArea(aArea)

	MsgInfo(cValToChar(nAtual) + " registros corrigidos com Sucesso!")

Return
