#Include "Totvs.CH"
#Include 'RWMake.ch'
#include 'FileIO.ch'
#Include 'RptDef.ch'
#Include "TOPCONN.CH"
#Include "Protheus.ch"
#Include "Tbiconn.ch"

//---------------------------------------------------------------------------------------------------------------------------------------------//
//---------------------------------------------------------------------------------------------------------------------------------------------//
//  Funcao : CPHBCOR0()            Autor : Cyberpolos                        Data : 27/08/2020     								   //
//  Uso :  ROTINA SCHEDULES			           //
//      																																	   //
// 																						                                                       //
//---------------------------------------------------------------------------------------------------------------------------------------------//
//---------------------------------------------------------------------------------------------------------------------------------------------// 

User Function CPHBCR0(_aEmp)	
	
	Private lSchedule   := .F. 

 // Inicializa ambiente pelo schedule
	If Select("SX6") == 0
		RPCSetType(3)  		//| Nao utilizar licenca	
		RpcSetEnv(_aEmp[1] ,_aEmp[2])
		lSchedule := .T.		
	Endif    
	//+-------------------------------------------------------
	// tratamento para nao haver execucao concorrente
	//+-------------------------------------------------------
	if !(LockByName('CPHBCR0', .T., .F.))
        ConOut("CPHBCR0 ja esta em execucao")
        if lSchedule
            RpcClearEnv()
        Endif
        Return
	Endif   

	//ENVIA EMAIL DE RASTREIO POR TRANSPORTADORA APÓS 48H DA NF AUTORIZADA
	If ExistBlock("CPMAILTR",.F.,.T.) 

       ExecBlock("CPMAILTR",.F.,.T.,{_aEmp})

	Endif	

// Gera arquivo de POST do AR com informações da Tabela ZAG   
	If ExistBlock("CPARPOST",.F.,.T.) 

       ExecBlock("CPARPOST",.F.,.T.,{_aEmp})

	Endif	


	If lSchedule
        RpcClearEnv()
    Endif



Return
