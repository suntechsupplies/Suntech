#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "topconn.ch"

#Define _Function 	"PreNota"
#Define _DescFun  	"Pr�-Nota de Entrada"
#Define Desc_Rest	"Servi�o REST para inclus�o de Pr�-Nota de Entrada"
#Define Desc_Post	"Cria a Pr�-Nota de Entrada de acordo com as informacoes passadas"

/*-------------------------------------------------------------------------
{Protheus.doc} 	Declara��o de M�todo
				M�todo de Inclus�o de Pre Documento de Entrada
@type       	User function
@version    	12.1.25
@author     	Carlos Eduardo Saturnino
@since      	21/04/2021
-------------------------------------------------------------------------*/

WSRESTFUL PreNota DESCRIPTION Desc_Rest

	WSMETHOD POST DESCRIPTION Desc_Post WSSYNTAX "/api/Com/v1.0/PreNota/"

END WSRESTFUL

/*-------------------------------------------------------------------------
{Protheus.doc} 	PreNota
				M�todo de Inclus�o de Pre Documento de Entrada
@type       	User function
@version    	12.1.25
@author     	Carlos Eduardo Saturnino
@since      	21/04/2021
-------------------------------------------------------------------------*/
WSMETHOD POST  WSSERVICE PreNota

	Local oResponse 		as Object
	Local oContent   		as Object
	Local oJsonRet			as Object
	Local _nY, _nX, _nZ	 	
	Local aArea				:= {}
	Local aLogAuto			:= {}
	Local aDadosF1			:= {}
	Local aDadosD1			:= {}
	Local aLin				:= {}
	Local cArqLog			:= ""
	Local cError			:= ""
 	Local nError			:= 0
 	Local _nOpc				:= 0
    Local cIndexSF1         := ""
 	Local _cEmpresa			:= ""
 	Local _cFilial			:= ""
	Local aTabs				:= {"SF1","SD1","SA1","SA2","SB1","SB2","SF4"}

 	Private lMsErroAuto		:= .F.
 	Private lMsHelpAuto		:= .F.
 	Private lAutoErrNoFile	:= .F.

	//******************************************************************************
	//Cria o diret�rio para salvar os arquivos de log
	//******************************************************************************    
	If !ExistDir("\LOG_WS")
		MakeDir("\LOG_WS")
	EndIf

	//******************************************************************************
	// Verifica se o body veio no formato JSon.
	//******************************************************************************
	If lower(Self:GetHeader("Content-Type", .F.)) == "application/json"

		oContent := JsonObject():New()
		oContent:FromJson(Self:GetContent())  // Transforma o JSON do body em um objeto JSON Protheus.

		If ValType(oContent) == "J"
			
			//**********************************************************************************
			// Efetua o travamento do registro no Licence Server
			// Caso a fun��o esteja em execu��o grava Log e retorna erro no retorno do M�todo 
			//**********************************************************************************
			If !LockByName("PreNota",.F.,.F.)
				
				//**********************************************************************************
				// Efetua a grava��o em console.log
				//**********************************************************************************
				Conout( '[PreNota - Post] Thread ['+cValToChar(ThreadID())+ '] ['+ FWTimeStamp(2) +'] [MATA140] - Fun��o em execu��o por outra inst�ncia. Processo abortado !!!')

				//**********************************************************************************
				// Retorna erro
				//**********************************************************************************
				nError := 400
				cError := 'Fun��o em execu��o por outra inst�ncia. Processo abortado'
				SetRestFault(nError, EncodeUTF8(cError))
				Return()

			endif
			
			//**********************************************************************************
			// Preenche o Array do Cabe�alho da Pre Nota
			//**********************************************************************************
			For _nZ := 1 To Len(oContent["cabecalho"])

				//**********************************************************************************
				// Identifica a Empresa e Filial para iniciar o PrepareEnv
				//**********************************************************************************
				_cEmpresa   := oContent["cabecalho"][_nZ]["EMPRESA"]
				_cFilial    := oContent["cabecalho"][_nZ]["F1_FILIAL"]

				//**********************************************************************************
				// Salva a area atual 
				//**********************************************************************************
				aArea := GetArea()					

				//**********************************************************************************
				// Efetua a prepara��o do ambiente para acesso via Web Service
				//**********************************************************************************
				If FindFunction("WfPrepEnv") .And. isBlind()  
					RpcSetType(3)
					RpcSetEnv( _cEmpresa,_cFilial,,, "POST", "METHOD", aTabs,,,,)
					cEmpant := _cEmpresa
					cFilant := _cFilial
					cNumEmp	:= _cEmpresa + _cFilial 
				Endif

				aArea := GetArea()

				//**********************************************************************************
				// Preenche o Array do Cabecalho da Pr� Nota de Entrada
				//**********************************************************************************
				aAdd(aDadosF1, {"F1_TIPO"           ,oContent["cabecalho"][_nZ]["F1_TIPO"]               ,NIL})
				aAdd(aDadosF1, {"F1_FORMUL"         ,oContent["cabecalho"][_nZ]["F1_FORMUL"]             ,NIL})
				aAdd(aDadosF1, {"F1_DOC"            ,oContent["cabecalho"][_nZ]["F1_DOC"]                ,NIL})
				aAdd(aDadosF1, {"F1_SERIE"          ,oContent["cabecalho"][_nZ]["F1_SERIE"]              ,NIL})
				aAdd(aDadosF1, {"F1_EMISSAO"        ,CTOD(oContent["cabecalho"][_nZ]["F1_EMISSAO"])		 ,NIL})                    
				aAdd(aDadosF1, {"F1_FORNECE"        ,oContent["cabecalho"][_nZ]["F1_FORNECE"]            ,NIL})
				aAdd(aDadosF1, {"F1_LOJA"           ,oContent["cabecalho"][_nZ]["F1_LOJA"]               ,NIL})
				aAdd(aDadosF1, {"F1_ESPECIE"        ,oContent["cabecalho"][_nZ]["F1_ESPECIE"]            ,NIL})
				aAdd(aDadosF1, {"F1_COND"           ,oContent["cabecalho"][_nZ]["F1_COND"]               ,NIL})
				aAdd(aDadosF1, {"F1_STATUS"         ,oContent["cabecalho"][_nZ]["F1_STATUS"]             ,NIL})
				aAdd(aDadosF1, {"F1_CHVNFE"         ,oContent["cabecalho"][_nZ]["F1_CHVNFE"]             ,NIL})

				//**********************************************************************************
				// Gravo o �ndice de Pesquisa na tabela SF1 para definir se � inclus�o ou altera��o
				// F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
				//**********************************************************************************
				cIndexSF1 :=    AVKey(_cFilial                      			 , "F1_FILIAL"	)
				cIndexSF1 +=    AVKey(oContent["cabecalho"][_nZ]["F1_DOC"]       , "F1_DOC"		)
				cIndexSF1 +=    AVKey(oContent["cabecalho"][_nZ]["F1_SERIE"]     , "F1_SERIE"	)
				cIndexSF1 +=    AVKey(oContent["cabecalho"][_nZ]["F1_FORNECE"]   , "F1_FORNECE"	)
				cIndexSF1 +=    AVKey(oContent["cabecalho"][_nZ]["F1_LOJA"]      , "F1_LOJA"	)
				cIndexSF1 +=    AVKey(oContent["cabecalho"][_nZ]["F1_TIPO"]      , "F1_TIPO"	)

				//**********************************************************************************
				// Preenche o Array dos Itens da Pr� Nota
				//**********************************************************************************
				For _nX := 1 to Len(oContent["cabecalho"][_nZ]["itens"])
					
					aLin := {}
					
					aAdd(aLin,  {"D1_COD"	,oContent["cabecalho"][_nZ]["itens"][_nX]["D1_COD"]		, Nil})
					aAdd(aLin,  {"D1_QUANT" ,oContent["cabecalho"][_nZ]["itens"][_nX]["D1_QUANT"]	, Nil})
					aAdd(aLin,  {"D1_VUNIT" ,oContent["cabecalho"][_nZ]["itens"][_nX]["D1_VUNIT"]	, Nil})
					aAdd(aLin,  {"D1_TOTAL" ,oContent["cabecalho"][_nZ]["itens"][_nX]["D1_TOTAL"]	, Nil})
					aAdd(aLin,  {"D1_DESC"  ,oContent["cabecalho"][_nZ]["itens"][_nX]["D1_DESC"]	, Nil})
					aAdd(aDadosD1,aLin)
				
				Next _nX

				//**********************************************************************************
				// Efetua o posicionamento das tabelas para  a inclusao da Pre Nota
				//**********************************************************************************
				SF1->(dbSelectArea("SF1"))
				SF1->(dbSetOrder(1))    // F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA+F1_TIPO
				SF1->(dbGoTop())

				//**********************************************************************************
				// Pesquiso o n�mero do Docto de Entrada para identificar se e inclus�o ou alteracao 
				//**********************************************************************************
				If SF1->(dbSeek( cIndexSF1 ))
					_nOpc := 4		    		// Altera
				Else
					_nOpc := 3					// Inclui
				Endif

				//**********************************************************************************
				// Poiciono no promeiro registro para a pr�xima consulta
				//**********************************************************************************
				SF1->(dbGoTop())

				//**********************************************************************************
				// Efetua a inclusao da Pr� Nota de entrada via MsExecAuto 
				//**********************************************************************************
				MSExecAuto({|x,y,z| MATA140(x,y,z)},aDadosF1, aDadosD1 , _nOpc,,)

				//**********************************************************************************
				// Cria o Objeto de Retorno das informacoes
				//**********************************************************************************
				oJsonRet  := JsonObject():New()
				oResponse := JsonObject():New()
				oResponse["data"] 		:= dDataBase
				oResponse["resultados"]	:= {}

				//******************************************************************************
				// Em caso de erro de ExecAuto 
				//******************************************************************************
				If lMsErroAuto	

					//******************************************************************************
					// Grava o Error.log na pasta System\log_ped 
					//******************************************************************************
					aLogAuto:= GetAutoGrLog()

					//******************************************************************************
					// Efetua o tratamento da mensagem de erro, retirando CLRF 
					//******************************************************************************
					For _nY := 1 to Len(aLogAuto) 
						cError 	+= aLogAuto[_nY]  
					Next _nY
					
					//******************************************************************************
					// Efetua a grava��o do erro na pasta de Log
					//******************************************************************************
					MemoWrite(cArqLog, cError)

					oJsonRet["sucessMessage"]	:= EncodeUTF8(IIF(_nOpc == 3 ,"Pr� Nota de Entrada n�o Inclu�da","Pr� Nota de Entrada n�o Alterada"))
					oJsonRet["filial"]         	:= oContent["cabecalho"][_nZ]["F1_FILIAL"]
					oJsonRet["documento"]  		:= oContent["cabecalho"][_nZ]["F1_DOC"]
					oJsonRet["tipo"]			:= oContent["cabecalho"][_nZ]["F1_TIPO"]
					oJsonRet["fornecedor"]		:= oContent["cabecalho"][_nZ]["F1_FORNECE"]
					oJsonRet["loja"]			:= oContent["cabecalho"][_nZ]["F1_LOJA"]
					oJsonRet["log"]	    		:= StrTran(EncodeUTF8(cError),'\r\n','')
					oJsonRet["opcao"]			:= EncodeUTF8(IIF(_nOpc == 3, "3 - Inclus�o", "4 - Altera��o"))
					oJsonRet["sucesscode"]     	:= 202  // 202 - C�digo padr�o HTML de POST recebido, porem nao processado
					aAdd(oResponse["resultados"], oJsonRet)
			
				Else

					//******************************************************************************
					// Monta o Json de Retorno realizado com sucesso
					//******************************************************************************
					oJsonRet["sucessMessage"]	:= EncodeUTF8(IIF(_nOpc == 3 ,"Pr� Nota de Entrada Inclu�da com sucesso !!!","Pr� Nota de Entrada Alterada com sucesso !!!"))
					oJsonRet["filial"]         	:= oContent["cabecalho"][_nZ]["F1_FILIAL"]
					oJsonRet["documento"]  		:= oContent["cabecalho"][_nZ]["F1_DOC"]
					oJsonRet["tipo"]			:= oContent["cabecalho"][_nZ]["F1_TIPO"]
					oJsonRet["fornecedor"]		:= oContent["cabecalho"][_nZ]["F1_FORNECE"]
					oJsonRet["loja"]			:= oContent["cabecalho"][_nZ]["F1_LOJA"]
					oJsonRet["opcao"]			:= EncodeUTF8(IIF(_nOpc == 3, "3 - Inclus�o", "4 - Altera��o"))
					oJsonRet["sucesscode"]     	:= 201  // 201 - C�digo padr�o HTML de POST recebido e processado
					aAdd(oResponse["resultados"], oJsonRet)

				Endif

				//******************************************************************************
				// Reinicio valores dos Arrays para o proximo Post de Pr� Nota de Entrada
				//******************************************************************************
				aDadosF1 	:= {}
				aDadosD1	:= {}
				aLin		:= {}

			Next _nZ

			//******************************************************************************
			// Destrava a funcao no Licence Server
			//******************************************************************************
			UnlockByName("PreNota",.F.,.F.)

		Endif
	Else

		nError := 400
		cError := 'Body esperado no formato "application/json".'

	Endif

	//**********************************************************************************
	// Efetua o fechamento das tabelas 
	//**********************************************************************************
	SF1->(dbCloseArea())
	SF1->(dbCloseArea())
	SD1->(dbCloseArea())
	SA1->(dbCloseArea())
	SA2->(dbCloseArea())
	SB1->(dbCloseArea())
	SB2->(dbCloseArea())
	SF4->(dbCloseArea())

	//**********************************************************************************
	// Efetua o reset no ambiente
	//**********************************************************************************
	RpcClearEnv()

	If nError = 0
		Self:SetResponse(oResponse:toJson())
	Else
		SetRestFault(nError, EncodeUTF8(cError))
	Endif

	//**********************************************************************************
	// Restaura a area de trabalho original
	//**********************************************************************************
	RestArea(aArea)	

Return (.T.)
