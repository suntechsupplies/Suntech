#Include 'Protheus.ch'
#Include 'Topconn.ch'


/**********************************************************************************************
***********************************************************************************************
//Funçõ: AIC060VPR() - Ponto de Entrada para guardar Produto Lido no Endereçamento           //
***********************************************************************************************
**********************************************************************************************/
User Function AIC060VPR()

	Local aArea		:= GetArea()
	Local aAreaZZ2	:= ZZ2->(GetArea())
	Local cCodBar	:= ParamIXB[1]
	Local lRet		:= .F.
	Local cAlias	:= GetNextAlias()

	
	if POSICIONE("ZZ2", 1, xFilial("ZZ2")+AllTrim(cCodBar), "!eof()")

		cQuery	:=	"SELECT DA_DOC "														+ CRLF
		cQuery	+=	"FROM "																	+ CRLF
		cQuery	+=	"	"					+ RetSQLName("SDA")					+ " SDA "	+ CRLF
		cQuery	+=	"WHERE "																+ CRLF
		cQuery	+=	"	DA_FILIAL	 	= '"	+ xFilial("SDA")				+ "' AND "	+ CRLF
		cQuery  +=	"	DA_PRODUTO   	= '" + ZZ2->ZZ2_PRODUT					+ "' AND "	+ CRLF
		cQuery  +=	"	DA_SALDO 		> 	0 										 AND "	+ CRLF
		cQuery	+=	"	SDA.D_E_L_E_T_ 	= ' ' "												+ CRLF

		TcQuery cQuery New Alias &cAlias 
		(cAlias)->(dbGotop())
		if !(cAlias)->(Eof())
			if ZZ2->ZZ2_DOCENT <> (cAlias)->DA_DOC
				RecLock("ZZ2", .f.)
				ZZ2->ZZ2_DOCENT := (cAlias)->DA_DOC
				ZZ2->(MsUnlock())
				lRet := .t.

				Aadd(aZZ2Aux, { ZZ2->(Recno()) }) 
			else
				VtBeep(3)
				VTALERT("Produto já foi lido! - AIC060VPR.PRW", "Aviso", .T., 4000, 3)
			endif
		Else
			VtBeep(3)
			VTALERT("Etiqueta Inválida! - AIC060VPR.PRW", "Aviso", .T., 4000, 3)
		endif

		(cAlias)->(dbCloseArea())
	endif

	RestArea(aAreaZZ2)
	RestArea(aArea)
Return(lRet)
