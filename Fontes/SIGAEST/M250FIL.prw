#include 'protheus.ch'
#include 'parmtype.ch'

/*
M250FIL - Inclusão de filtro de usuário no browse da tela de apontamento de produção simples

Descrição
 O ponto de entrada M250FIL inclui filtro de usuário no browse da tela de apontamento de produção simples. O filtro é feito a partir da tabela SD3.
Localização
Executado na função MATA250.PRW, responsável pelos apontamentos de produção.
*/

user function M250FIL()
	
	Local cFiltro := "D3_OP <> ''"
	
return cFiltro