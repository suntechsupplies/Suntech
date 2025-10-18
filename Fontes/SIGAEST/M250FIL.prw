#include 'protheus.ch'
#include 'parmtype.ch'

/*
M250FIL - Inclus�o de filtro de usu�rio no browse da tela de apontamento de produ��o simples

Descri��o
 O ponto de entrada M250FIL inclui filtro de usu�rio no browse da tela de apontamento de produ��o simples. O filtro � feito a partir da tabela SD3.
Localiza��o
Executado na fun��o MATA250.PRW, respons�vel pelos apontamentos de produ��o.
*/

user function M250FIL()
	
	Local cFiltro := "D3_OP <> ''"
	
return cFiltro