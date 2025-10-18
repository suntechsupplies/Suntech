#INCLUDE "protheus.ch"
#INCLUDE "topconn.ch"

#DEFINE cEOL CHR(13) + CHR(10)

/*
	Funcao		:	ACD167FI
	Autor		:	Ademar Pereira da Silva Junior
	Data		:	23/10/2012
	Descricao	:	PE finaliza processo de embalagem
*/
User Function ACD167FI()
	
	Local aArea := GetArea()	&& Salvar area
	
		RepData(CB7_ORDSEP)
	
	RestArea(aArea)				&& Restaurar area
	
	VTAlert("ENTREI")
	
Return


Static Function RepData(cAuxOS)
Local cQry 		:= ""	&& Variavel query
Local cAuxCmp   := ""	&& Variavel auxiliar campo

	&& Desenvolvimento da query
	cQry	:=	"SELECT " + cEOL
	//cQry	+= 		"TOP 1 " + cEOL
	cQry	+= 		"* " + cEOL

	cQry	+= 	"FROM " + cEOL
	cQry	+= 		RetSQLName("CB9") + " CB9 " + cEOL

	cQry	+= 	"WHERE " + cEOL
	cQry	+= 		"CB9_FILIAL = '" + xFilial("CB9") + "' AND " + cEOL
	cQry	+= 		"CB9_ORDSEP = '" + cAuxOS + "' AND " + cEOL
	cQry	+= 		"ROWNUM = 1 AND " + cEOL
	cQry	+= 		"D_E_L_E_T_ = '' " + cEOL

	cQry	+= 	"ORDER BY " + cEOL
	cQry	+= 		"R_E_C_N_O_ DESC "
	
	If Select("TCB9") <> 0
		TCB9->(dbCloseArea())
	Endif
	
	&& Execucao da query
	TcQuery cQry Alias TCB9 New

	&& Verificar se foi encontrado registro
	If TCB9->(!EOF())
		&& Selecionar area SX3
		DbSelectArea("SX3")
		&& Posicionar registro CB9
		If SX3->(DbSeek("CB9"))
			&& Selecionar area CB9
			DbSelectArea("CB9")
			&& Incluir registro
			CB9->(RecLock("CB9",.T.))
				While CB9->(!EOF()) .And. SX3->X3_ARQUIVO == "CB9"
					cAuxCmp1 := "CB9->" + SX3->X3_CAMPO
					cAuxCmp2 := "TCB9->" + SX3->X3_CAMPO

				    If SX3->X3_TIPO != "D"
						&cAuxCmp1 := &cAuxCmp2
					Else
						&cAuxCmp1 := StoD(&cAuxCmp2)
					EndIf

					SX3->(DbSkip())
				EndDo
			CB9->(MsUnlock())
		EndIf
	EndIf
	
	TCB9->(dbCloseArea())

Return
