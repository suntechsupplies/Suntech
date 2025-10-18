#Include 'Protheus.ch'
#Include 'Topconn.ch'

/*
Funcao		:	V166VLD
Autor		:	Gerson
Data		:	18/11/2013
Descricao	:	PE na Ordem de Separação ACD para guardar o Numero da Separação e Pedido na Tabela ZZ2
*/
User Function V166VLD()
	Local aArea		:= GetArea()
	Local aAreaZZ2	:= ZZ2->(GetArea())
	Local cCodBar	:= ParamIXB[1]
	Local lRet		:= .f.
	Local cAlias	:= GetNextAlias()
	Local cOrdSep	:= CB8->CB8_ORDSEP

	if Empty(CB7->CB7_OP)
		//ZZ2->(dbSetOrder(1))

		//if ZZ2->(dbSeek(xFilial("ZZ2")+cCodBar))
		if POSICIONE("ZZ2", 1, xFilial("ZZ2")+AllTrim(cCodBar)+CB8->CB8_PROD, "!eof()")
			cQuery	:=	"SELECT "														+ CRLF
			cQuery	+=	"	COUNT(*) TOTREG "											+ CRLF
			cQuery	+=	"FROM "															+ CRLF
			cQuery	+=	"	"				+ RetSQLName("CB8") 			+ " CB8 "	+ CRLF
			cQuery	+=	"WHERE "														+ CRLF
			cQuery	+=	"	CB8_FILIAL = '"	+ xFilial("CB8")				+ "' AND "	+ CRLF
			cQuery  +=	"	CB8_PROD   = '" + ZZ2->ZZ2_PRODUT				+ "' AND "	+ CRLF
			cQuery  +=	"	CB8_ORDSEP = '" + cOrdSep						+ "' AND "	+ CRLF
			cQuery  +=	"	CB8_LOTECT = '" + ZZ2->ZZ2_LOTE					+ "' AND "	+ CRLF
			cQuery	+=	"	CB8_LCALIZ = '" + CB8->CB8_LCALIZ				+ "' AND "	+ CRLF
			cQuery  +=	"	CB8_SALDOS >= " + cValtoChar(ZZ2->ZZ2_QUANT)	+ " AND "	+ CRLF
			cQuery	+=	"	CB8.D_E_L_E_T_ = ' ' "										+ CRLF

			TcQuery cQuery New Alias &cAlias

			if (cAlias)->TOTREG > 0
				if ZZ2->ZZ2_ORDSEP <> CB8->CB8_ORDSEP .AND. ZZ2->ZZ2_PEDIDO <> CB8->CB8_PEDIDO
					RecLock("ZZ2", .f.)
					ZZ2->ZZ2_ORDSEP := CB8->CB8_ORDSEP
					ZZ2->ZZ2_PEDIDO := CB8->CB8_PEDIDO
					ZZ2->(MsUnlock())
					lRet := .t.
				else
					VtBeep(3)
					VTALERT("Produto já foi lido!", "Aviso", .T., 4000, 3)
				endif
			Else
				VtBeep(3)
				VTALERT("Etiqueta Inválida!", "Aviso", .T., 4000, 3)
			endif

			(cAlias)->(dbCloseArea())
		endif
	Else
		lRet := .t.
	endif

	RestArea(aAreaZZ2)
	RestArea(aArea)
Return(lRet)