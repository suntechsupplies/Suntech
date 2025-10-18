#include 'protheus.ch'
#include 'parmtype.ch'

/**
	Rotina		:	MAAVCRPR - Avalização de crédito de clientes
	Autor		:	Dione Oliveira - Totvs Jundiaí
	Data		:	04/11/2019
	Modulo		: 	SIGAFAT
	Descrição	: 	Este ponto de entrada pertence à rotina de avaliação de crédito de clientes, 				MaAvalCred() – FATXFUN(). 
					Ele permite que, após a avaliação padrão do sistema, o usuário possa fazer a sua própria.
	PARAMIXB 
		ParamIxb[1] = Código do cliente
		ParamIxb[2] = Código da filial
		ParamIxb[3] = Valor da venda
		ParamIxb[4] = Moeda da venda
		ParamIxb[5] = Considera acumulados de Pedido de Venda do SA1
		ParamIxb[6] = Tipo de crédito ("L"	Código cliente + Filial; "C" código do cliente)
		ParamIxb[7] = Indica se o credito será liberado ( Lógico )
		ParamIxb[8] = Indica o código de bloqueio do credito ( Caracter )

		Retorno lRet(logico)
		.T. - crédito aprovado
		.F. - crédito não aprovado.
*/

User function MAAVCRPR()

	local aArea	 :=	GetArea()
	Local lRet	 := ParamIxb[7]

	If lRet == .F. .AND. Alltrim(SC5->C5_ZZSITFI) $ "2"
		   lRet := .T.
	endIf

	RestArea(aArea)	

Return (lRet)


