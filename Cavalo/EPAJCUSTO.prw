user function EPAJCUSTO()
local _aTabelas := {}
local _aSQL := {}
local _nStatus
local _cData := "20191231"
local _cTemp := ""

_cTemp := " UPDATE SD1010 SET D1_CUSTO = D1_QUANT * ZST_VUNIT "
_cTemp += " FROM SD1010 SD1 "
_cTemp += " INNER JOIN ZST010 CUSTO ON ZST_FILIAL = D1_FILIAL AND ZST_LOCAL = D1_LOCAL AND ZST_COD = D1_COD  AND CUSTO.D_E_L_E_T_ = ' ' "
_cTemp += " WHERE SD1.D_E_L_E_T_ = ' ' AND SD1.D1_DTDIGIT <= '" + _cData + "' "
aadd(_aTabelas, "Notas Fiscais de Entrada - Tabela SD1") 
aadd(_aSQL, _cTemp)

_cTemp := " UPDATE SD2010 SET D2_CUSTO1 = D2_QUANT * ZST_VUNIT "
_cTemp += " FROM SD2010 SD2 "
_cTemp += " INNER JOIN ZST010 CUSTO ON ZST_FILIAL = D2_FILIAL AND ZST_LOCAL = D2_LOCAL AND ZST_COD = D2_COD  AND CUSTO.D_E_L_E_T_ = ' ' "
_cTemp += " WHERE SD2.D_E_L_E_T_ = ' ' AND SD2.D2_EMISSAO <= '" + _cData + "' "
aadd(_aTabelas, "Notas Fiscais de Saída - Tabela SD2") 
aadd(_aSQL, _cTemp)

_cTemp := " UPDATE SD3010 SET D3_CUSTO1 = D3_QUANT * ZST_VUNIT "
_cTemp += " FROM SD3010 SD3 "
_cTemp += " INNER JOIN ZST010 CUSTO ON ZST_FILIAL = D3_FILIAL AND ZST_LOCAL = D3_LOCAL AND ZST_COD = D3_COD  AND CUSTO.D_E_L_E_T_ = ' ' "
_cTemp += " WHERE SD3.D_E_L_E_T_ = ' ' AND SD3.D3_EMISSAO <= '" + _cData + "' "
aadd(_aTabelas, "Movimentações Internas - Tabela SD3") 
aadd(_aSQL, _cTemp)

_cTemp := " UPDATE SB9010 SET B9_VINI1 = B9_QINI * ZST_VUNIT, B9_CM1 = ZST_VUNIT "
_cTemp += " FROM SB9010 SB9 "
_cTemp += " INNER JOIN ZST010 CUSTO ON ZST_FILIAL = B9_FILIAL AND ZST_LOCAL = B9_LOCAL AND ZST_COD = B9_COD  AND CUSTO.D_E_L_E_T_ = ' ' "
_cTemp += " WHERE SB9.D_E_L_E_T_ = ' ' AND SB9.B9_DATA <= '" + _cData + "' "
aadd(_aTabelas, "Saldos Iniciais - Tabela SB9") 
aadd(_aSQL, _cTemp)

for _ni := 1 to len(_aSQL)

	//msginfo(_aSQL[_ni],"SQL")
	msginfo("Atualização: " + _aTabelas[_ni],"Atualização")
	
	_nStatus := TCSqlExec(_aSQL[_ni])
	   
	if (_nStatus < 0)
		MsgStop(("TCSQLError() - " + _aTabelas[_ni] + chr(13) + chr(10) + TCSQLError()))
	endif

next _ni

return