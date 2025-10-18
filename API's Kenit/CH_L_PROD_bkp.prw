#Include "Totvs.ch"

/*/{Protheus.doc} CH_L_PROD
@author Ihorran Milholi
@since 17/05/2021
@version 1.0
/*/


//SB1.B1_ZZDTPLE      ATRIBUTO_LENTE,
//SB1.B1_ZZDMATE      ATRIBUTO_MATERIAL,

User Function CH_L_PROD(nParamDias)

Local cQuery := ""

cQuery += " SELECT"
cQuery += "     SB1.B1_COD          CODIGO," 
cQuery += "     SB1.B1_COD          CODIGOERP," 
cQuery += "     CASE WHEN ISNULL(SB5.B5_ECTITU,'') = '' THEN SB1.B1_DESC ELSE SB5.B5_ECTITU END NOME,"
cQuery += "     'HB'                MARCA,"
cQuery += "     SB1.B1_POSIPI       NCM,"
cQuery += "     SB1.B1_CODBAR       CODIGOUNIVERSAL,"   
cQuery += "     SB1.B1_ORIGEM       ORIGEM,"
cQuery += "     ACU.ACU_COD         CATEGORIA,"

cQuery += "     ISNULL(SB1.B1_ZZALTCX,0)    LARGURA,"
cQuery += "     ISNULL(SB1.B1_ZZLARCX,0)    PROFUNDIDADE,"
cQuery += "     ISNULL(SB1.B1_ZZPROCX,0)    ALTURA,"
cQuery += "     ISNULL(SB1.B1_PESBRU,0)     PESO,"
cQuery += "     CASE WHEN SB1.B1_MSBLQL = '2' THEN 'ativo' ELSE 'inativo' END STATUS,"

cQuery += "     ISNULL(CONVERT(VARCHAR(8000),CONVERT(VARBINARY(8000),SB1.B1_ZZDESCP)),'') DESCRICAO,"

cQuery += "     CASE WHEN SB1.B1_ZZDTLAN = '' THEN '' ELSE SUBSTRING(SB1.B1_ZZDTLAN,5,2)+'/'+SUBSTRING(SB1.B1_ZZDTLAN,7,2)+'/'+SUBSTRING(SB1.B1_ZZDTLAN,1,4) END ATRIBUTO_DATALANCAMENTO,"

cQuery += "     SB1.B1_ZZTMPGR      GARANTIA,
cQuery += "     SB1.B1_ZZCNDGR      TEXTOGARANTIA,

cQuery += "     CASE "
cQuery += "     WHEN SB1.B1_ZZGENER = 'M' THEN 'Masculino' "
cQuery += "     WHEN SB1.B1_ZZGENER = 'F' THEN 'Feminino' "
cQuery += "     WHEN SB1.B1_ZZGENER = 'U' THEN 'Unissex' "
cQuery += "     ELSE SB1.B1_ZZGENER "
cQuery += "     END GENERO,"

cQuery += "     SX51.X5_DESCRI      ATRIBUTO_COR,"
cQuery += "     SX52.X5_DESCRI      ATRIBUTO_COLECAO,"
cQuery += "     SX55.X5_DESCRI      MODELO,"
cQuery += "     SX56.X5_DESCRI      ATRIBUTO_ESTILO,"

cQuery += "     SB1.B1_ZZTAMHA      ATRIBUTO_ASTE,"
cQuery += "     SB1.B1_ZZTAMPO      ATRIBUTO_PONTE,"
cQuery += "     SB1.B1_ZZTAMCL      ATRIBUTO_CAIXADALENTE,"

cQuery += "     SB1.B1_ZZARO        ATRIBUTO_ARO,"
cQuery += "     SB1.B1_ZZTMARM      ATRIBUTO_ARMACAO,"
cQuery += "     SB1.B1_ZZALTCX      ATRIBUTO_ALTURAEMB,"
cQuery += "     SB1.B1_ZZLARCX      ATRIBUTO_LARGURAEMB,"
cQuery += "     SB1.B1_ZZPROCX      ATRIBUTO_PROFUNDIDADEEMB,"

cQuery += "     row_number() over (order by SB1.B1_FILIAL, SB1.B1_COD) linha_tabela"

cQuery += " FROM "+RetSqlName("SB1")+" SB1 "

cQuery += " LEFT JOIN "+RetSqlName("SX5")+" SX51 ON "
cQuery += "     SX51.X5_FILIAL  = '"+xFilial("SX5")+"'"
cQuery += " AND SX51.X5_TABELA  = 'Z1'"
cQuery += " AND SX51.X5_CHAVE   = SB1.B1_ZZCORPR"
cQuery += " AND SX51.D_E_L_E_T_ = ''"

cQuery += " LEFT JOIN "+RetSqlName("SX5")+" SX52 ON "
cQuery += "     SX52.X5_FILIAL  = '"+xFilial("SX5")+"'"
cQuery += " AND SX52.X5_TABELA  = 'Z2'"
cQuery += " AND SX52.X5_CHAVE   = SB1.B1_ZZCOLEC"
cQuery += " AND SX52.D_E_L_E_T_ = ''"

cQuery += " LEFT JOIN "+RetSqlName("SX5")+" SX55 ON "
cQuery += "     SX55.X5_FILIAL  = '"+xFilial("SX5")+"'"
cQuery += " AND SX55.X5_TABELA  = 'Z5'"
cQuery += " AND SX55.X5_CHAVE   = SB1.B1_ZZLINHA"
cQuery += " AND SX55.D_E_L_E_T_ = ''"

cQuery += " LEFT JOIN "+RetSqlName("SX5")+" SX56 ON "
cQuery += "     SX56.X5_FILIAL  = '"+xFilial("SX5")+"'"
cQuery += " AND SX56.X5_TABELA  = 'Z6'"
cQuery += " AND SX56.X5_CHAVE   = SB1.B1_ZZESTIL"
cQuery += " AND SX56.D_E_L_E_T_ = ''"

cQuery += " LEFT JOIN "+RetSqlName("SB5")+" SB5 ON "
cQuery += "     SB5.B5_FILIAL   = '"+xFilial("SB5")+"'"
cQuery += " AND SB5.B5_COD      = SB1.B1_COD"
cQuery += " AND SB5.D_E_L_E_T_  = ''"

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
cQuery += " AND REPLACE(CONVERT(VARCHAR(10),SB1.S_T_A_M_P_ AT TIME ZONE 'UTC' AT TIME ZONE 'E. South America Standard Time', 120),'-','') >= '"+dtos(DaySub(dDatabase,nParamDias))+"'""

Return cQuery
