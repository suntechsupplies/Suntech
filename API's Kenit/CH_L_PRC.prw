#Include "Totvs.ch"

/*/{Protheus.doc} CH_L_PRC
@author Ihorran Milholi
@since 17/05/2021
@version 1.0
/*/

/*
CAMPOS PARA RETORNO DA QUERY
CODIGO
NOME
*/
    
User Function CH_L_PRC(nParamDias)

Local cQuery := ""

cQuery += " SELECT"   
cQuery += " 	SB1.B1_COD                  PRODUTO,"
cQuery += " 	'0103'                      EMPRESA_SIGLA,"
cQuery += "		DA1.DA1_CODTAB              TABELAPRECO,"
cQuery += "		CASE WHEN ISNULL(DA1.DA1_PRCMAX,0) > 0 THEN ISNULL(DA1.DA1_PRCMAX,0) ELSE ISNULL(DA1.DA1_PRCVEN,0) END PRECO,"
cQuery += "		CASE WHEN ISNULL(DA1.DA1_PRCMAX,0) > 0 THEN ISNULL(DA1.DA1_PRCVEN,0) ELSE 0 END PRECOPROMOCIONAL,"
cQuery += "		row_number() over (order by SB1.B1_FILIAL, SB1.B1_COD, DA1.DA1_CODTAB) linha_tabela"

cQuery += " FROM "+RetSqlName("SB1")+" SB1"

cQuery += " INNER JOIN "+RetSqlName("DA1")+" DA1 ON "
cQuery += "     DA1.DA1_FILIAL  = '"+xFilial("DA1")+"'"
cQuery += " AND DA1.DA1_CODPRO  = SB1.B1_COD"
cQuery += " AND DA1.DA1_CODTAB  = 'MKP' "
cQuery += " AND DA1.D_E_L_E_T_  = ''"

cQuery += " INNER JOIN "+RetSqlName("ACV")+" ACV ON "
cQuery += "     ACV.ACV_FILIAL  = '"+xFilial("ACV")+"'"
cQuery += " AND ACV.ACV_GRUPO   = SB1.B1_GRUPO"
cQuery += " AND ACV.D_E_L_E_T_  = ''"

cQuery += " INNER JOIN "+RetSqlName("ACU")+" ACU ON "
cQuery += "     ACU.ACU_FILIAL  = '"+xFilial("ACU")+"'"
cQuery += " AND ACU.ACU_COD     = ACV.ACV_CATEGO "
cQuery += " AND ACU.D_E_L_E_T_  = ''"

cQuery += " WHERE"
cQuery += "     SB1.B1_FILIAL   = '"+xFilial("SB1")+"'"
cQuery += " AND SB1.D_E_L_E_T_  = ''"

Return cQuery
