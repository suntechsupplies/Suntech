#include 'protheus.ch'
#include 'parmtype.ch'

user function callFunction()

	local cEmp		:= "01"
	local cFil		:= "01"
	
	local lStatus := rpcSetEnv(cEmp, cFil)
	
	//X31UPDTABLE("SCY")
	
	u_STAFAT01("00000000000000")
	

return