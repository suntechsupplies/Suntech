#Include 'Protheus.ch'
#Include 'Topconn.ch'


/**********************************************************************************************
***********************************************************************************************
//Funcao: AIC060VPR() - Ponto de Entrada para guardar Produto Lido no Endereçamento          //
***********************************************************************************************
**********************************************************************************************/
User Function AIC060VPR()

	Local aArea		:= GetArea()
	Local aAreaZZ2	:= ZZ2->(GetArea())
	Local aAreaSDA	:= SDA->(GetArea())
	Local cCodBar	:= ParamIXB[1]
	Local lRet		:= .F.
	Local cAlias	:= GetNextAlias()
	Local cAliasSDA	:= cNota//SDA->DA_DOC -> Variavel Private cNota em memória - Suntech Ricardo Araujo

	if Empty(SDA->DA_NUMLOTE)
		//ZZ2->(dbSetOrder(1))

		//if ZZ2->(dbSeek(xFilial("ZZ2")+cCodBar))
		if POSICIONE("ZZ2", 1, xFilial("ZZ2")+AllTrim(cCodBar), "!eof()")
			cQuery	:=	"SELECT "																+ CRLF
			cQuery	+=	"	COUNT(*) TOTREG "													+ CRLF
			cQuery	+=	"FROM "																	+ CRLF
			cQuery	+=	"	"					+ RetSQLName("SDA")					+ " SDA "	+ CRLF
			cQuery	+=	"WHERE "																+ CRLF
			cQuery	+=	"	DA_FILIAL	 	= '"	+ xFilial("SDA")				+ "' AND "	+ CRLF
			cQuery  +=	"	DA_PRODUTO   	= '" + ZZ2->ZZ2_PRODUT					+ "' AND "	+ CRLF
			cQuery  +=	"	DA_DOC		 	= '" + cAliasSDA						+ "' AND "	+ CRLF
			cQuery  +=	"	DA_LOTECTL	 	= '" + ZZ2->ZZ2_LOTE					+ "' AND "	+ CRLF
			cQuery	+=	"	DA_LOCAL	 	= '" + SDA->DA_LOCAL					+ "' AND "	+ CRLF
			cQuery  +=	"	DA_SALDO 		>= 	" + cValtoChar(ZZ2->ZZ2_QUANT)		+ " AND "	+ CRLF
			cQuery	+=	"	SDA.D_E_L_E_T_ 	= ' ' "												+ CRLF

			TcQuery cQuery New Alias &cAlias 

			if (cAlias)->TOTREG > 0
				if ZZ2->ZZ2_DOCENT <> cAliasSDA //SDA->DA_DOC -  Suntech Ricardo Araujo
					RecLock("ZZ2", .F.)
					ZZ2->ZZ2_DOCENT := cAliasSDA //SDA->DA_DOC -  Suntech Ricardo Araujo
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
		lRet := .T.
	endif

	RestArea(aAreaZZ2)
	RestArea(aAreaSDA)
	RestArea(aArea)
Return(lRet)
