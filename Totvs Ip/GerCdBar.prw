#include 'protheus.ch'
#include 'parmtype.ch'
#include "TopConn.ch"

/*
Rotina		:	GerCdBar
Autor		:	Dione Oliveira
Data		:	07/08/2019
Descricao	:	Rotina para gerar o B1_CODBAR automaticamente
Obs	 		:

** Criação de Gatilhos

Campo Origem: B1_GRUPO
Sequencia: 014
Campo Destino: B1_CODBAR
Regra: U_GerCodBar()
Condição: INCLUI
*/

User Function GerCdBar()

	local aArea	:= GetArea()
	local cSql	:= ""
	local cRet 	:= ""

	IF INCLUI .and. (M->B1_TIPO == 'PA' .OR. M->B1_TIPO == 'ME')

		cSQL := "SELECT MAX(B1_CODBAR) MAXCOD "
		cSQL += " FROM " + RetSqlName("SB1")
		cSQL += " WHERE D_E_L_E_T_ = ' '"
		cSQL += " AND B1_FILIAL = '" + xFilial("SB1") + "'"

		cSQL :=  ChangeQuery(cSQL)
		TCQUERY cSQL NEW ALIAS "QRY"

		IF !empty(QRY->MAXCOD)
			cRet := "7909306" + Soma1(substr(QRY->MAXCOD,8,5))
			cRet :=  cRet + buscaDig(cRet)
		ELSE
			cRet := cPrefCod + "7909306" + "00001"
		ENDIF

		DbSelectArea("QRY")
		DbCloseArea()
	ELSE
		cRet := " "
	ENDIF

	RestArea(aArea)

Return(cRet)

Static Function buscaDig( cCodigo )
	Local j
	Local nMultiplicador
	Local nSoma := 0
	Local nResultado := 0
	Local nDigito
	Local nTam := 0

	cCodigo := AllTrim( cCodigo )
	nTam := len(cCodigo)
	
	For j:= 1 To nTam    // Somatoria do conteudo do campo
		nMultiplicador := Iif( ( j % 2) == 0 , 1, 3 ) // varia entre 3 e 1
		nSoma += Int(Val(SubStr(cCodigo,(nTam+1)-j,1))) * nMultiplicador
	Next j

	nResultado := Int(nSoma / 10 ) + Iif(( nSoma % 10 ) > 0, 1 , 0 )  // Prox Multiplo 10
	nDigito   := nResultado * 10 - nSoma
Return Str( nDigito , 1 )