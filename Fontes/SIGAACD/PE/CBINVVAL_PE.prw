#include "totvs.ch"
#include "Apvt100.ch"

/*/{Protheus.doc} User Function CBINVVAL
      Ponto de entrada executado dentro da valida��o da etiqueta de produtos,retornando um valor l�gico .T. para 
      continuar a valida��o padr�o ou .F. para abortar a valida��o.
      @type  Function
      @author Diogo Mesquita
      @since 16/11/2020
      @return lRet, L�gico, .T. continua o processo padr�o .F. aborta o processo.
      /*/
User Function CBINVVAL()
	
	local lRet 		:= .T.				
	local cCodBar 	:= allTrim(cEtiqProd) // Vari�vel private dispon�vel no ACDV035
	
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
