#Include 'Totvs.ch'

/*/{Protheus.doc} IMPXML12
		PE para complementar informações no array de itens na geração da pré-nota, Nf de Entrada, Nf de Saida via execauto 
		@type 		Function
		@author 	Cassandra J. Silva
		@since 		17/12/2018
		@version 	1.0
/*/
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------
User Function IMPXML12()
//-------------------------------------------------------------------------------------------------------------------------------------------------------------------
	Local aRetorno		:= {}
	Local cCentroCusto	:= ""
	Local cTES			:= ""
	Local cXML			:= ""
	Local cError		:= ""
	Local cWarning  	:= ""	
	Local oClassImpXML	:= Paramixb[01]
	Private oXML		:= Nil

	cXML := oClassImpXML:cXML
	oXML := XmlParser(cXML,"_",@cError,@cWarning)
		
	//--- Executa somente se for CT-e
	If Type("oXML:_CTEPROC") == "O"
	
		cCentroCusto	:= "1004"
		cTes			:= "004"
		
		aAdd(aRetorno, {"D1_TES"		, cTes				, Nil })
		aAdd(aRetorno, {"D1_TESACLA"	, cTes				, Nil })
		aAdd(aRetorno, {"D1_CC"			, cCentroCusto		, Nil })

	Endif
	
	DelClassIntf()

Return aRetorno

