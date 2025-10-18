#include  "protheus.ch"
#INCLUDE "TOPCONN.CH" 




user function getTotalPed()

local cAlias := getNextAlias()
local cQuery := "select sum(C6_QTDVEN * C6_PRCVEN) AS TOTAL from SC6010 where D_E_L_E_T_ != '*' and C6_NUM = '"+SC5->C5_NUM+"' and C6_FILIAL = '"+xFilial("SC6")+"' "
local nValor := 0

TcQuery cQuery new alias  (cAlias)

if (cAlias)->(!eof())
    nValor := (cAlias)->TOTAL
endIf
(cAlias)->(dbCloseArea())


return nValor

user function getQtdPed()

local cAlias := getNextAlias()
local cQuery := "select sum(C6_QTDVEN) AS TOTAL from SC6010 where D_E_L_E_T_ != '*' and C6_NUM = '"+SC5->C5_NUM+"' and C6_FILIAL = '"+xFilial("SC6")+"' "
local nValor := 0

TcQuery cQuery new alias  (cAlias)

if (cAlias)->(!eof())
    nValor := (cAlias)->TOTAL
endIf
(cAlias)->(dbCloseArea())


return nValor

return
