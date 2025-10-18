#include 'protheus.ch'
#include 'parmtype.ch'


/*
	{Protheus.doc} G1DESC
	Função feita para atualizar campos personalizados G1_ZZPROD e G1_ZZCOMP para serem utilizados nos indices de busca pela descrição na estrutura de produtos.
	@author Dione Oliveira
	@since 31/07/2019
	@version undefined
	@type function
	@example Inserir "U_G1DESC()" no X2_ROTINA da tabela SG1010
*/

User Function G1DESC()
Local aArea := GetArea()
Local aAreaG1 := SG1->(GetArea())
    
	cQuery  := ""
	cQuery  := " UPDATE " + RETSQLNAME("SG1") + " SET G1_ZZPROD = B1_DESC "
	cQuery 	+= " FROM " + RETSQLNAME("SG1") + " G1, " + RETSQLNAME("SB1") + " B1 "   
	cQuery 	+= " WHERE G1.D_E_L_E_T_ = ' ' " 
	cQuery 	+= " AND B1.D_E_L_E_T_ = ' ' "     
	cQuery 	+= " AND G1_COD = B1_COD " 
	cQuery 	+= " AND G1_ZZPROD <> B1_DESC " 
	TcSqlExec(cQuery)    

	cQuery2 := ""
	cQuery2 := " UPDATE " + RETSQLNAME("SG1") + " SET G1_ZZCOMP = B1_DESC "
	cQuery2	+= " FROM " + RETSQLNAME("SG1") + " G1, " + RETSQLNAME("SB1") + " B1 "   
	cQuery2 += " WHERE G1.D_E_L_E_T_ = ' ' " 
	cQuery2 += " AND B1.D_E_L_E_T_ = ' ' "     
	cQuery2	+= " AND G1_COMP = B1_COD " 
	cQuery2 += " AND G1_ZZCOMP <> B1_DESC " 
	TcSqlExec(cQuery2) 

RestArea(aAreaG1)
RestArea(aArea)
Return


