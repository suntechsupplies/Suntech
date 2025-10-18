#include "totvs.ch"
#include "Apvt100.ch"

/*/{Protheus.doc} User Function CBINVVAL
      Ponto de entrada executado dentro da validação da etiqueta de produtos,retornando um valor lógico .T. para 
      continuar a validação padrão ou .F. para abortar a validação.
      @type  Function
      @author Diogo Mesquita
      @since 16/11/2020
      @return lRet, Lógico, .T. continua o processo padrão .F. aborta o processo.
      /*/
User Function CBINVVAL()
	
	local lRet 		:= .T.				
	local cCodBar 	:= allTrim(cEtiqProd) // Variável private disponível no ACDV035
	
	if type("_aEtiq035") == "U"
		public _aEtiq035 := {}
	endIf
	
	if len(cCodBar) == 12 // Etiqueta ZZ2_CODBAR
		if type("_aEtiq035") <> "U"
			if aScan(_aEtiq035,cCodBar) > 0
				VTAlert("Etiqueta ja lida!","AVISO", .T., 4000, 3)
				VTKeyBoard(chr(20))
				lRet := .F.
			else		
				aAdd(_aEtiq035,cCodBar)
			endIf
		endIf
	endIf

Return lRet
