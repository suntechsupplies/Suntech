#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'

USER FUNCTION SUESTA01()
	PROCESSA({|| PROCZST() })
RETURN

STATIC FUNCTION PROCZST()
	Local cQuery := ""
	Local nRegua := 0
	
	//Query de processamento
	cQuery := " SELECT "
	cQuery += "   ZST_COD , ZST_VUNIT "
	cQuery += " FROM "
	cQuery += "   "+ ZST->(RetSQLName("ZST"))
	cQuery += " WHERE "
	cQuery += "   ZST_FILIAL = '"+ ZST->(xFILIAL("ZST")) +"' AND D_E_L_E_T_ = ' ' "
	cQuery += " ORDER BY "
	cQuery += "   ZST_COD ""
	TcQuery cQuery Alias TZST New
	
	//Contador da regua
	TZST->(dbGoTop())
	While !TZST->(EOF())
		nRegua++
		TZST->(dbSkip())
	Enddo
	ProcRegua(nRegua)
	
	//Processamento
	TZST->(dbGoTop())
	While !TZST->(EOF())
		INCPROC()
	
		//Caso encontre o SB1, atualiza o último preço de compra.
		SB1->(dbSetOrder(1))
		SB1->(dbSeek(xFILIAL("SB1")+TZST->COD))
		If SB1->(Found())
			SB1->(RecLock("SB1" , .F.))
			SB1->B1_UPRC := TZST->ZST_VUNIT
			SB1->(MsUnLock())
		Else
			Alert("Produto: "+ TZST->COD +" não encontrado.")
		Endif
	
		TZST->(dbSkip())
	Enddo
	TZST->(dbCloseArea())
RETURN