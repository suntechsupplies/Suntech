#include 'protheus.ch'
#include 'parmtype.ch'

/**
	Rotina		:	MAAVCRPR - Avaliza��o de cr�dito de clientes
	Autor		:	Dione Oliveira - Totvs Jundia�
	Data		:	04/11/2019
	Modulo		: 	SIGAFAT
	Descri��o	: 	Este ponto de entrada pertence � rotina de avalia��o de cr�dito de clientes, 				MaAvalCred() � FATXFUN(). 
					Ele permite que, ap�s a avalia��o padr�o do sistema, o usu�rio possa fazer a sua pr�pria.
	PARAMIXB 
		ParamIxb[1] = C�digo do cliente
		ParamIxb[2] = C�digo da filial
		ParamIxb[3] = Valor da venda
		ParamIxb[4] = Moeda da venda
		ParamIxb[5] = Considera acumulados de Pedido de Venda do SA1
		ParamIxb[6] = Tipo de cr�dito ("L"	C�digo cliente + Filial; "C" c�digo do cliente)
		ParamIxb[7] = Indica se o credito ser� liberado ( L�gico )
		ParamIxb[8] = Indica o c�digo de bloqueio do credito ( Caracter )

		Retorno lRet(logico)
		.T. - cr�dito aprovado
		.F. - cr�dito n�o aprovado.
*/

User function MAAVCRPR()

	local aArea	 :=	GetArea()
	Local lRet	 := ParamIxb[7]

	If lRet == .F. .AND. Alltrim(SC5->C5_ZZSITFI) $ "2"
		   lRet := .T.
	endIf

	RestArea(aArea)	

Return (lRet)


