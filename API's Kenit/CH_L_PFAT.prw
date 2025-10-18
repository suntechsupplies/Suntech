#Include "Totvs.ch"

/*/{Protheus.doc} CH_L_PFAT
@author Ihorran Milholi
@since 17/05/2021
@version 1.0
/*/

/*
CAMPOS PARA RETORNO DA QUERY
RASTREAMENTO
TRANSPORTADORA_CNPJ
TRANSPORRADORA_NOME
NUMERO
SERIE
*/
    
User Function CH_L_PFAT(nParamDias,cCodigoErp)

Local cQuery := ""
//valores default
Default cCodigoErp := ""

cQuery += " SELECT  SF2.F2_DOC      DOCUMENTO_NUMERO," 
cQuery += "         SF2.F2_SERIE    DOCUMENTO_SERIE," 
cQuery += "         SF2.F2_CHVNFE   DOCUMENTO_CHAVE," 
cQuery += "         SF2.F2_VALBRUT  DOCUMENTO_VALORTOTAL,"
cQuery += "         MIN(SD2.D2_CF)  DOCUMENTO_CFOP,"
cQuery += "         SUBSTRING(SF2.F2_EMISSAO,1,4)+'-'+SUBSTRING(SF2.F2_EMISSAO,5,2)+'-'+SUBSTRING(SF2.F2_EMISSAO,7,2)+'T00:00:00.000-03:00'  DOCUMENTO_DATAEMISSAO,"
cQuery += "         '/pedido/xml?chavexml='+RTRIM(SF2.F2_CHVNFE) DOCUMENTO_URLXML,"
cQuery += "         row_number() over (order by SF2.F2_FILIAL, SF2.F2_DOC, SF2.F2_SERIE) linha_tabela"

cQuery += " FROM    "+RetSqlName("SD2")+" SD2"

cQuery += "         INNER JOIN "+RetSqlName("SF2")+" SF2 ON SF2.F2_FILIAL   = SD2.D2_FILIAL"
cQuery += "                                             AND SF2.F2_DOC      = SD2.D2_DOC" 
cQuery += "                                             AND SF2.F2_SERIE    = SD2.D2_SERIE" 
cQuery += "                                             AND SF2.F2_CHVNFE   <> ' '"
cQuery += "                                             AND SF2.F2_EMISSAO >= '"+dtos(DaySub(dDatabase,nParamDias))+"'"
cQuery += "                                             AND SF2.D_E_L_E_T_  = ''"

cQuery += " WHERE   SD2.D_E_L_E_T_  = ''"

//verifica se existe filtro de codigo do pedido
if (!Empty(cCodigoErp))
    cQuery += " AND SD2.D2_PEDIDO = '"+AllTrim(cCodigoErp)+"'"
endif

cQuery += " GROUP BY    SF2.F2_FILIAL," 
cQuery += "             SF2.F2_DOC," 
cQuery += "             SF2.F2_SERIE," 
cQuery += "             SF2.F2_CHVNFE," 
cQuery += "             SF2.F2_EMISSAO,"
cQuery += "             SF2.F2_VALBRUT"

Return cQuery
