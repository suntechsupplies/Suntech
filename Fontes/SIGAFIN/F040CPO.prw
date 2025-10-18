#Include "protheus.ch"

User Function F040CPO()
	
    Local aCampos := paramixb
	
    AAdd(aCampos,"E1_NATUREZ")

Return aCampos

/*
Exemplo para bloquear campo:
#Include 'Protheus.ch'
User Function F040CPO()
	LOCAL  aBlock := {}
	LOCAL  NSCAN :=0
	aIto := paramixb
	NSCAN := Ascan(aBlock,"E1_CAMPO")
	IF NSCAN > 0
		ADEL(aIto,NSCAN)
		ASIZE(aBlock,Len(aBlock)-1)
	ENDIF
Return aBlock
*/
