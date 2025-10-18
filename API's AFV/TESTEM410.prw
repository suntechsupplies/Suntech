#include 'protheus.ch'
#include 'parmtype.ch'

user function TESTEM410()

	Local aDadosC5 	:= {}
	Local aDadosC6	:= {}
	Local aLin		:= {}
	Local _nX
	
	Private lMsErroAuto as Logical
 	Private lMsHelpAuto:= .T. 	
	

	Begin Transaction
		//******************************************************************************
		// Faz a gravação dos Arrays para o ExecAuto do Pedido de Vendas
		//******************************************************************************

		aDadosC5 := {}
		aAdd(aDadosC5, {"C5_TIPO"	 		,"N"	 			, Nil})
		aAdd(aDadosC5, {"C5_CLIENTE" 		,"C01521"			, Nil})
		aAdd(aDadosC5, {"C5_LOJACLI" 		,"01"				, Nil})
		aAdd(aDadosC5, {"C5_CONDPAG" 		,"030"				, Nil})
		aAdd(aDadosC5, {"C5_TPFRETE" 		,"C" 				, Nil})
		aAdd(aDadosC5, {"C5_MENNOTA" 		,"teste" 			, Nil})
		aAdd(aDadosC5, {"C5_ZZOBS" 			,"TESTE" 			, Nil})
		aAdd(aDadosC5, {"C5_VEND1" 			,"R00003"			, Nil})
		aAdd(aDadosC5, {"C5_TABELA" 		,"TDI"				, Nil})
		aAdd(aDadosC5, {"C5_ZZNPEXT" 		,"A3"				, Nil})
		aAdd(aDadosC5, {"C5_ZZTPPED" 		,"VS"				, Nil})
		aAdd(aDadosC5, {"C5_ZZORIGE" 		,"AFV"				, Nil})
		aAdd(aDadosC5, {"C5_ZZDTEMI" 		,StoD('20200130')	, Nil})
							

		//**********************************************************************************
		// Guardo empresa e filial para passar para Prepare Environment
		//**********************************************************************************

		aLin := {}

		For _nX := 1 to 125
			aLin := {}
			aAdd(aLin	, {"C6_ITEM"		, RetAsc(StrZero(_nX),2,.T.), Nil			})
			aAdd(aLin	, {"C6_PRODUTO" 	, "10100030031024"			, Nil			})
			aAdd(aLin	, {"C6_QTDVEN" 		, 1.00						, Nil			})
			aAdd(aLin	, {"C6_PRCVEN" 		, 47.02						, Nil			})
			aAdd(aLin	, {"C6_OPER" 		, "50" 						, Nil			})
			aAdd(aLin	, {"AUTDELETA"		, "N"						, Nil			})
			aAdd(aDadosC6,aLin)
		Next _nX


		//**********************************************************************************
		// Efetua a inclusao do Pedido de Vendas via MsExecAuto 
		//**********************************************************************************
		MSExecAuto({|w,x,y,z|MATA410(w,x,y,z)}, aDadosC5, aDadosC6 ,3,.F.)

		If lMsErroAuto
			RollBackSx8()
			MostraErro()   
		Endif

	End Transaction

	If !lMsErroAuto
		Aviso( "Ok", "Pedido de Vendas incluido com sucesso", { "Ok" }, 2 )
	Endif

return