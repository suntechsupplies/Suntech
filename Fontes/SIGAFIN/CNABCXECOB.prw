#include 'protheus.ch'
#include 'parmtype.ch'

/*-----------------------------------------------------------------------
{Protheus.doc} 	CNBCXECB
TODO 			ExecBlock para geracao do Cnab Cobranca da Cx. Economica
				Federal
@author			Suntech Supplyes 		
@since 			28/03/2020
@version 		1.0
@return 		${_cRet}
@type 			User Function
-----------------------------------------------------------------------*/
User Function CNBCXECB(cId)

	Local _cId		:= cId  
	Local _cRet		:= ''
	Local _cTipo	:= ''
	
	
	//-------------------------------------------------------------------
	// Identifica se trata-se de retorno do grupo de campos de Endereco 
	// do Cliente
	//-------------------------------------------------------------------
	If _cId $ ("D2753140|D3153260|D3273340|D3353490|D3503510")
		
		
		//-------------------------------------------------------------------
		// Identifica se o Endereco a ser usado Cobranca ou Comercial 
		// COBRANCA = Endereco de Cobranca , COMERCIAL = Endereco Comercial
		//------------------------------------------------------------------- 
		_cTipo := TpEnd()
		
				
		//-------------------------------------------------------------------
		// Endereco do Pagador - 40 Posicoes
		//-------------------------------------------------------------------
		If _cId == "D2753140"

			If _cTipo == "COBRANCA"
				_cRet := PadR(FwNoAccent(Alltrim(SA1->A1_ENDCOB)),40)
			Else
				_cRet := PadR(FwNoAccent(Alltrim(SA1->A1_END)),40)
			Endif

		//-------------------------------------------------------------------
		// Bairro do Pagador - 12 Posicoes
		//-------------------------------------------------------------------
		ElseIf _cId == "D3153260"

			If _cTipo == "COBRANCA"
				_cRet := PadR(FwNoAccent(Alltrim(SA1->A1_BAIRROC)),12)
			Else
				_cRet := PadR(FwNoAccent(Alltrim(SA1->A1_BAIRRO)),12)
			Endif

		//-------------------------------------------------------------------
		// CEP do Pagador - 8 Posicoes
		//-------------------------------------------------------------------
		ElseIf _cId == "D3273340"

			If _cTipo == "COBRANCA"
				_cRet := cValtoChar(SA1->A1_CEPC)
			Else
				_cRet := cValtoChar(SA1->A1_CEP)
			Endif

		//-------------------------------------------------------------------
		// Cidade do Pagador - 15 Posicoes
		//-------------------------------------------------------------------
		ElseIf _cId == "D3353490"

			If _cTipo == "COBRANCA"
				_cRet := PadR(FwNoAccent(Alltrim(SA1->A1_MUNC)),15)
			Else
				_cRet := PadR(FwNoAccent(Alltrim(SA1->A1_MUN)),15)
			Endif
			
		//-------------------------------------------------------------------
		// UF do Pagador - 2 Posicoes
		//-------------------------------------------------------------------
		ElseIf _cId == "D3503510"
			
			If _cTipo == "COBRANCA"
				_cRet := A1_ESTC
			Else
				_cRet := A1_EST
			Endif
			
		Endif
	
	ElseIf _cId =="D0590730"

		//-------------------------------------------------------------------
		// Nosso Numero Bancario
		//-------------------------------------------------------------------
		IIF(Empty(SE1->E1_NUMBCO),Repl("0",15),SE1->E1_NUMBCO)

	Endif
	
return(_cRet)

/*-----------------------------------------------------------------------	
{Protheus.doc} 	TpEnd
TODO 			Tipo do Endereco (Comercial ou Cobranca)
@author 		Suntech Supplyes
@since 			28/03/2020
@version 		1.0
@return 		${"COBRANCA","COMERCIAL"}, 
				${"Retorna End. Cobranca", "Retorna End. Comercial"}
@type 			Static Function
-----------------------------------------------------------------------*/
Static Function TpEnd()

	Private _cRet := '' 

		//--------------------------------------------------------------------------
		// Identifica se o Endereco a ser usado Cobranca ou Endereco Comercial. Se 
		// TODOS os campos do Endereco de Cobranca estiverem preenchidos indentifica
		// que devera retornar o Endereco de Cobranca, senao o Endereco Comercial
		//-------------------------------------------------------------------------- 
	If !Empty(SA1->A1_ENDCOB) .And. !Empty(SA1->A1_BAIRROC) .And. !Empty(SA1->A1_CEPC) .And. !Empty(SA1->A1_MUNC) .And. !Empty(SA1->A1_ESTC)
			_cRet := "COBRANCA"
	Else
			_cRet := "COMERCIAL"
	Endif

Return (_cRet)

