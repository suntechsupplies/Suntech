#Include "Totvs.ch"

/*/{Protheus.doc} CH_L_EST
@author Ihorran Milholi
@since 17/05/2021
@version 1.0
/*/

/*
CAMPOS PARA RETORNO DA QUERY
CODIGO
NOME
*/
    
User Function CH_L_EST(nParamDias)

Local cQuery := ""

cQuery += " SELECT"   
cQuery += " 	SB1.B1_COD      PRODUTO,"
cQuery += " 	'0102'          EMPRESA_SIGLA,"
cQuery += "		SB2.B2_LOCAL    LOCAL,"
cQuery += "		SB2.B2_CM1      CUSTO,"

cQuery += "		SB2.B2_QATU, "
cQuery += "		SB2.B2_RESERVA, "
cQuery += "		SB2.B2_QEMP, "
cQuery += "		SB2.B2_QACLASS, "

cQuery += "		CASE WHEN SB2.B2_QATU-SB2.B2_RESERVA-SB2.B2_QEMP-SB2.B2_QACLASS > 0 THEN SB2.B2_QATU-SB2.B2_RESERVA-SB2.B2_QEMP-SB2.B2_QACLASS ELSE 0 END ESTOQUEATUAL,"
cQuery += "		row_number() over (order by SB2.B2_FILIAL, SB1.B1_COD, SB2.B2_LOCAL) linha_tabela"

cQuery += " FROM "+RetSqlName("SB1")+" SB1"

cQuery += " INNER JOIN "+RetSqlName("SB2")+" SB2 ON "
cQuery += "     SB2.B2_FILIAL   = '02' "
cQuery += " AND SB2.B2_LOCAL    = '02' "
cQuery += " AND SB2.B2_COD      = SB1.B1_COD "
cQuery += " AND SB2.D_E_L_E_T_  = ''"

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
