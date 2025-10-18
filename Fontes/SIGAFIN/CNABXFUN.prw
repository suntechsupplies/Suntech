#include 'protheus.ch'
#include 'parmtype.ch'

/*---------------------------------------------------------
{Protheus.doc} 	CNABXFUN
TODO 			Funcoes aplicadas ao Cnab
@author 		
@since 			28/10/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			User Function
---------------------------------------------------------*/
User Function CNABXFUN(cBanco, cTipo, cSeg)

	Local	 _nRet	:= 0
	
	Private _cBanco	:= cBanco
	Private _cTipo	:= cTipo
	Private _cSeg	:= cSeg
	
	If _cBanco == "033"				// Santander
		_nRet := CNABXSANT()
	ElseIf _cBanco == "237"			// Bradesco
		_nRet := CNABXBRAD()
	ElseIf _cBanco == "341"			// Itau
		_nRet := CNABXITAU()
	Endif
	
Return(_nRet)

/*---------------------------------------------------------
{Protheus.doc} 	CNABXSANT
TODO 			Funcoes aplicadas ao Cnab Banco Santander
@author 		
@since 			28/10/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			User Function
---------------------------------------------------------*/
Static Function CNABXSANT()

	Local nRet := 0
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Santander Carteira a Receber				   ³ 
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If _cTipo == "R"
		If _cSeg == "1271392" 		// Vlr. do Titulo
			nRet := STRZERO(INT(SE1->(E1_SALDO-E1_IRRF-E1_COFINS-E1_CSLL-E1_PIS-E1_DESCONT+E1_ACRESC)*100),13)
		Endif
	Endif

Return(nRet)
/*---------------------------------------------------------
{Protheus.doc} 	CNABXSANT
TODO 			Funcoes aplicadas ao Cnab Banco Bradesco
@author 		
@since 			28/10/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			User Function
---------------------------------------------------------*/
Static Function CNABXBRAD()

	Local nRet := 0

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Bradesco Carteira a Receber				       ³ 
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If _cTipo == "R"
		If _cSeg == "1271392" 		// Vlr. do Titulo
			nRet := STRZERO(INT(SE1->(E1_SALDO-E1_IRRF-E1_COFINS-E1_CSLL-E1_PIS-E1_DESCONT+E1_ACRESC)*100),13)              
		Endif
	Endif

Return(nRet)
/*---------------------------------------------------------
{Protheus.doc} 	CNABXSANT
TODO 			Funcoes aplicadas ao Cnab Banco Itau
@author 		
@since 			28/10/2020
@version 		1.0
@return 		${return}, ${return_description}
@type 			User Function
---------------------------------------------------------*/
Static Function CNABXITAU()

	Local nRet := 0

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Itau Carteira a Receber				           ³ 
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If _cTipo == "R"
		If _cSeg == "1271392" 		// Vlr. do Titulo
			nRet := STRZERO(INT(SE1->(E1_SALDO-E1_IRRF-E1_COFINS-E1_CSLL-E1_PIS-E1_DESCONT+E1_ACRESC)*100),13)              
		Endif
	Endif

Return(nRet)
