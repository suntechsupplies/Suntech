#include 'protheus.ch'
#include 'parmtype.ch'

/*
	Rotina		:	OM010MNU
	Autor		:	Dione Oliveira
	Data		:	07/08/2019
	Descricao	:	Este ponto de entrada pode ser utilizado para inserir novas op��es no array a Rotina.
	Obs	 		:	Utilizado para inserir a fun��o U_AtuPrec no browse da rotina de tabelas de pre�o 
*/

User Function OM010MNU()

	aadd(aRotina,{'Importar Pre�os','U_AtuPrec' , 0 , 3,0,NIL})   

Return