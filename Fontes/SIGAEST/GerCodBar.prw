#include 'protheus.ch'
#include 'parmtype.ch'
#include "TopConn.ch"

/*
Rotina		:	GerCodBar
Autor		:	Dione Oliveira
Data		:	07/08/2019
Descricao	:	Rotina para gerar o B1_CODBAR automaticamente
Obs	 		:	


** Criação de Gatilhos

Campo Origem: B1_GRUPO
Sequencia: 014
Campo Destino: B1_CODBAR
Regra: U_GerCodBar()
Condição: INCLUI e COPIA (07/02/2020)
*/


User Function GerCodBar()

	local aArea	:= GetArea()
	local cRet 	:= ""
	Local cQRY	:= GetNextAlias()


	IF ( INCLUI .and. (M->B1_TIPO = 'PA' .Or. M->B1_TIPO = 'ME') ) 
		
		BeginSQL Alias cQRY

			SELECT 	MAX(SUBSTRING(B1_CODBAR,1,12)) MAXCOD
			FROM 	%Table:SB1% A
			WHERE 	A.%NotDel%
			AND 	A.B1_FILIAL = %Exp:FwFilial("SB1")%

		EndSql

		IF ! Empty((cQRY)->MAXCOD)
			cRet := "7909306" + Soma1(substr((cQRY)->MAXCOD,8,12))
			cRet += EanDigito(trim(cRet))
		ELSE
			cRet := cPrefCod + "7909306" + "000001"
		ENDIF

		(cQRY)->(DbSelectArea(cQRY))
		(cQRY)->(DbCloseArea())

	ENDIF

	RestArea(aArea)

Return(cRet)
