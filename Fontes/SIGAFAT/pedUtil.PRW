#include  "protheus.ch"
#INCLUDE "TOPCONN.CH"


/*/{Protheus.doc} pedUtil.prw

Função para colocar a soma dos itens e valor no Browse da Consulta de Pedido
Obs: Criar o campo virtual/Alterar e colocar a função no brower pedUtil()

@type function
@author Daniel Braga
@since 06/05/2021 */


user function getTotalPed()

	local cAlias 	:= getNextAlias()
	//local cQuery 	:= "select sum(C6_QTDVEN * C6_PRCVEN) AS TOTAL from SC6010 where D_E_L_E_T_ != '*' and C6_NUM = '"+SC5->C5_NUM+"' and C6_FILIAL = '" + SC5->C5_FILIAL +"' "
	local nValor 	:= 0
	Local aArea		:= GetArea()

	BeginSql Alias cAlias
		
		SELECT 	SUM(C6_QTDVEN * C6_PRCVEN) AS TOTAL
		FROM 	%Table:SC6% SC6
		WHERE	SC6.C6_FILIAL	= %Exp:SC5->C5_FILIAL%
		AND		SC6.C6_NUM 		= %Exp:SC5->C5_NUM%
		AND		SC6.%NotDel%
		
	EndSql
	    
        
    if (cAlias)->(!eof())
        nValor := (cAlias)->TOTAL
    endIf
    
	(cAlias)->(dbCloseArea())

	restArea(aArea)

return nValor

user function getQtdPed()

	local cAlias := getNextAlias()
	//local cQuery := "select sum(C6_QTDVEN) AS TOTAL from SC6010 where D_E_L_E_T_ != '*' and C6_NUM = '"+SC5->C5_NUM+"' and C6_FILIAL = '" + SC5->C5_FILIAL +"' "
	local nValor := 0
	Local aArea		:= GetArea()

	BeginSQL Alias cAlias

		Select 	sum(C6_QTDVEN) AS TOTAL 
		from 	%Table:SC6% SC6
		where 	SC6.C6_NUM 		= %Exp:SC5->C5_NUM%
		and 	SC6.C6_FILIAL 	= %Exp:SC5->C5_FILIAL%
		and   	SC6.%NotDel%

	EndSQL


	if (cAlias)->(!eof())
	    nValor := (cAlias)->TOTAL
	endIf
	(cAlias)->(dbCloseArea())

	restArea(aArea)

return nValor
