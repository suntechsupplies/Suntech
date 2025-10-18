#include 'protheus.ch'
#include 'parmtype.ch'

/*
	Rotina		:	OM010MNU
	Autor		:	Dione Oliveira
	Data		:	07/08/2019
	Descricao	:	Este ponto de entrada pode ser utilizado para inserir novas opções no array a Rotina.
	Obs	 		:	Utilizado para inserir a função U_AtuPrec no browse da rotina de tabelas de preço 
*/

User Function OM010MNU()

	aadd(aRotina,{'Importar Preços','U_AtuPrec' , 0 , 3,0,NIL})   

Return