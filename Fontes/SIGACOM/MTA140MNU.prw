#Include "TOTVS.CH"

/*/{Protheus.doc} MTA140MNU

Ponto de Entrada para adicionar Rotinas no Menu da Rotina Padrão de Pré-Nota (MATA140)  

@type function
@author Dione Oliveira
@since 20/05/2019


/*/
User Function MTA140MNU()

	//Adiciona no Menu a Rotina de Importação de XML do Gestor de XML da TOTVS IP
	aAdd(aRotina,{"Importar XML","IPImpXML()" ,0,3,0,.F.})
	aAdd(aRotina,{"Validador conf. Xml","IPVldImpXML()" ,0,3,0,.F.})
	
Return