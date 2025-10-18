#Include 'Totvs.ch'

/*/{Protheus.doc} IMPXML21
		Executado para cada item do XML, permitindo que seja modificado o Array do Registro dos Itens sendo Carregado
		Executado após o De-Para de Código de Produto e conversões de Unidades de Medidas
		Usado para alterações específicas após a carga e conversões de dados

		@type 		Function
		@author 	Cassandra J. Silva
		@since 		07/01/2019
		@version 	1.0
/*/
//------------------------------------------------------------------------------------------------------------------------------------------------------
User Function IMPXML21()
//------------------------------------------------------------------------------------------------------------------------------------------------------
	Local aClassImpXML	:= Paramixb[01]	//--- Objeto da Classe do Importador de XML
	Local aRecord		:= Paramixb[02]	//--- Registro sendo Incluído em aItens, na carga de dados dos Itens do XML
	Local nRecord		:= Paramixb[03]	//--- Indica o Nº do Registro sendo percorrido
	Local cAviso		:= ""
	Local cErro			:= ""
	Private cXML		:= ""


	cXML := aClassImpXML:cXML
	oXML := XmlParser(cXML,"_",@cAviso,@cErro)	

	//--- Executa somente se for CT-e
	If Type("oXML:_CTEPROC") == "O"
	
		aRecord[18] := "004" //--- TES
	
	Endif

	aAdd(aRecord, .F.)					//--- Acrescenta a última posicao lógica (controle deletado)
			
Return aRecord