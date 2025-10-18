#include "protheus.ch"

/*/{protheus.doc} ACD060CA
exclusão dos produtos lidos

Retorno: nil

@since 30/01/19
/*/

user function ACD060CA()
	
	For x:= 1 to Len(aZZ2Aux)
	
		dbSelectArea("ZZ2")             
		dbGoto(aZZ2Aux[x,1])
		RecLock( "ZZ2" , .F. )
		ZZ2->ZZ2_DOCENT := ""
		ZZ2->( MsUnLock() )

	Next x

return