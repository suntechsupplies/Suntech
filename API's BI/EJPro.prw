#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"

/**********************************************************************************************
* {Protheus.doc}  Produtos                                                                    *
* @author Douglas.Silva Feat Carlos Eduardo Saturnino                                         *  
* Processa as informa็๕es e retorna o json                                                    *
* @since 	05/08/2019                                                                        *
* @version undefined                                                                          *
* @param oSelf, object, Objeto contendo dados da requisi็ใo efetuada pelo cliente, tais como: *
*    - Parโmetros querystring (parโmetros informado via URL)                                  *
*    - Objeto JSON caso o requisi็ใo seja efetuada via Request Post                           *
*    - Header da requisi็ใo                                                                   *
*    - entre outras ...                                                                       *
* @type Method                                                                                *
**********************************************************************************************/
#Define _Function 	"Produtos - Ejecty"
#Define _DescFun  	"Ejecty - Cadastro de Produtos"
#Define Desc_Rest	"Servi็o REST para Disponibilizar dados de Cadastro de Produtos - Integra็ใo Ejecty"
#Define Desc_Get  	"Retorna o Produto informado de acordo com data de atualiza็ใo do cadastro - Integra็ใo Ejecty" 
#Define Desc_Pos	"Cria o Cadastro de Produtos de acordo com as informacoes passadas"


user function EjProGet()

return

WSRESTFUL EjProGet DESCRIPTION Desc_Rest

	WSDATA nPag		As Integer
	WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/EjProGet || /EjProGet/{}"

END WSRESTFUL

/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Douglas.Silva Feat Carlos Eduardo Saturnino                                         *  
* Processa as informa็๕es e retorna o json                                                    *
* @since 	05/08/2019                                                                        *
* @version undefined                                                                          *
* @param oSelf, object, Objeto contendo dados da requisi็ใo efetuada pelo cliente, tais como: *
*    - Parโmetros querystring (parโmetros informado via URL)                                  *
*    - Objeto JSON caso o requisi็ใo seja efetuada via Request Post                           *
*    - Header da requisi็ใo                                                                   *
*    - entre outras ...                                                                       *
* @type Method                                                                                *
**********************************************************************************************/

WSMETHOD GET WSRECEIVE nPag WSSERVICE EjProGet

	Local aArea			:= GetArea()
	Local cAliasTMP 	:= GetNextAlias()
	Local lRet			:= .T.
	Local nPag			:= Self:nPag
	Local cSetResp
	Local nPagFim
	Local aTabs		:= {}
	Local _cEmpresa	:= "01"
	Local _cFilial	:= "01"
	Local _lSegue	:= .F.
	Local nY

	If FindFunction("WfPrepEnv")

		//*****************************************************************
		// Cofigura empresa/filial
		//*****************************************************************
		RpcSetEnv( _cEmpresa,_cFilial,,, "GET", "METHOD", aTabs,,,,)
		cEmpant := _cEmpresa
		cFilant := _cFilial
	
		//*****************************************************************
		// Enquanto nao configura empresa e filial fica dentro
		// do "laco" verificando
		//*****************************************************************
		While ! _lSegue
			If _cEmpresa + _cFilial == cNumEmp
				_lSegue := .T.
			Endif
		End
	Endif

	//Verifica se hแ conexใo em aberto, caso haja feche.
	IF Select(cAliasTMP)>0
		dbSelectArea(cAliasTMP)
		(cAliasTMP)->(dbCloseArea())
	EndIf

	//Select de cadastro de Produtos
	BeginSQL Alias cAliasTmp

		SELECT		((ROW_NUMBER() OVER (ORDER BY A.R_E_C_N_O_)) /500)+1	AS PAG 
					,A.R_E_C_N_O_
					,A.B1_FILIAL
					,A.B1_COD
					,A.B1_GRUPO
					,A.B1_DESC
					,A.B1_MSBLQL
					,A.B1_CODBAR
					,A.B1_PESBRU
					,A.B1_QE
					,A.B1_UM
					,A.B1_PESO
					,A.B1_POSIPI
					,A.B1_PESO
					,A.B1_CLASFIS
					,A.B1_GRTRIB
					,A.B1_PICM
					,A.B1_PICMRET
					,A.B1_VLR_PIS
					,A.B1_PESO
					,A.B1_PPIS
					,A.B1_PCOFINS
					,A.B1_CUSTD
					,TRIM(REPLACE(REPLACE(REPLACE(ISNULL(CONVERT(VARCHAR(2047), CONVERT(VARBINARY(2047), A.B1_ZZDESCP)),'') , CHAR(13), ''), CHAR(10), ''), CHAR(9),'')) AS B1_ZZDESCP 	 
					,A.B1_ZZLIBVE
					,A.B1_ZZLIBB2
					,A.B1_ZZCODAN
					,A.B1_ZZCOLEC
					,A.B1_IPI
					,A.B1_ZZLINHA
					,A.B1_ZZLANC
					,A.B1_ZZTAMHA
					,A.B1_ZZBASE
					,A.B1_ZZTAMPO
					,A.B1_ZZTAMCL
					,A.B1_ZZGENER
					,A.B1_ZZARO
					,A.B1_ZZTMARM
					,A.B1_ZZTPLEN
					,A.B1_ZZMATER
					,A.B1_ZZESTIL
					,A.B1_ZZCORPR
					,A.B1_ZZMCLIP
		FROM 		%Table:SB1% A  
		WHERE 		A.%NotDel% 
		AND			A.B1_MSBLQL = '2' 
		AND			A.B1_TIPO IN ('PA','ME')
		AND 		A.B1_ZSTATUS <> '9'
		ORDER BY 	A.R_E_C_N_O_

	EndSql

	dbSelectArea(cAliasTMP)
	(cAliasTMP)->( DbGoTop() )

	// Guarda a ultima pagina
	While (cAliasTmp)->( !Eof() )
		nPagFim		:= (cAliasTmp)->PAG
		(cAliasTmp)->(dbSkip())
	EndDo
	// Seleciona a Tabela SB1 para recuperar o conteudo do campo memo
	dbSelectArea("SB1")

	// Posiciona novamente no primeiro registro
	(cAliasTmp)->( DbGoTop() )

	If (cAliasTMP)->( Eof() ) 							// Sem Dados

		cSetResp 	:= '{ "produto":[ "Retorno":"Nao Existe Itens Nessa Pagina"] } '
		lRet 		:= .F.
	
	ElseIf !Empty(nPag)								// Parametro QueryString nPag Preenchida
	
		nX		  := 1
		cSetResp  := '{"produto":['
		
		While !(cAliasTMP)->( Eof() )

			If nPag == (cAliasTMP)->PAG
				
				If nX > 1
					cSetResp  +=' , '
				EndIf

				cSetResp  += '{'
				cSetResp  += '"CODIGO":"'  				+ TRIM((cAliasTMP)->B1_COD )	
				cSetResp  += '","CODIGOCATEGORIA":"' 	+ TRIM((cAliasTMP)->B1_ZZCOLEC)
				cSetResp  += '","LIBERAB2B":"'	 	    + TRIM(cValToChar((cAliasTMP)->B1_ZZLIBVE))
				cSetResp  += '","LIBERAREP":"'	 	    + TRIM(cValToChar((cAliasTMP)->B1_ZZLIBB2))
				cSetResp  += '","DESCRICAO":"'          + ALLTRIM((cAliasTMP)->B1_DESC )	
				cSetResp  += '","FLAGBLOQUEIO":"'   	+ TRIM((cAliasTMP)->B1_MSBLQL) 
				cSetResp  += '","EAN13":"'				+ TRIM((cAliasTMP)->B1_CODBAR)
				cSetResp  += '","PESOBRUTO":'    		+ TRIM(STR((cAliasTMP)->B1_PESBRU)) 
				cSetResp  += ',"QTDEEMBALAGEM":' 		+ TRIM(STR((cAliasTMP)->B1_QE) )	
				cSetResp  += ',"UNIDPRODUTO":"'			+ TRIM((cAliasTMP)->B1_UM)	
				cSetResp  += '","PESOLIQUIDO":' 		+ TRIM(STR((cAliasTMP)->B1_PESO))
				cSetResp  += ',"NCM":"'                	+ TRIM(((cAliasTMP)->B1_POSIPI))
				cSetResp  += '","AMOGRATIS":"'          + ALLTRIM(STR((cAliasTMP)->B1_PESO))
				cSetResp  += '","CLASSFISCAL":"'        + TRIM(((cAliasTMP)->B1_CLASFIS))
				cSetResp  += '","CODGRPTRIB":"'         + TRIM(((cAliasTMP)->B1_GRTRIB))
				cSetResp  += '","ICMSINT":'            	+ TRIM(STR((cAliasTMP)->B1_PICM))
				cSetResp  += ',"ICMSEXT":'            	+ TRIM(STR(0))
				cSetResp  += ',"MVA":'                	+ TRIM(STR((cAliasTMP)->B1_PICMRET))
				cSetResp  += ',"PISPAUTA":'           	+ TRIM(STR((cAliasTMP)->B1_VLR_PIS))
				cSetResp  += ',"COFINSPAUTA":'        	+ TRIM(STR((cAliasTMP)->B1_PESO))
				cSetResp  += ',"ALIQPIS":'             	+ TRIM(STR((cAliasTMP)->B1_PPIS))
				cSetResp  += ',"ALIQCOFINS":'          	+ TRIM(STR((cAliasTMP)->B1_PCOFINS))
				cSetResp  += ',"ALIQIPI":'      		+ TRIM(STR((cAliasTMP)->B1_IPI))		
				cSetResp  += ',"CUSTOSECO":'           	+ TRIM(STR((cAliasTMP)->B1_CUSTD))
				cSetResp  += ',"CODIGOANTERIOR":"'      + TRIM((cAliasTMP)->B1_ZZCODAN )
				
				//********************************************************************************
				cSetResp  += '","LINHA":"' 			    + TRIM((cAliasTMP)->B1_ZZLINHA )
				cSetResp  += '","LANCAMENTO":"'      	+ TRIM((cAliasTMP)->B1_ZZLANC )
				//********************************************************************************
				
				//********************************************************************************
				// Incluido em 12/08/20 por solicitacao do Marcos Soares - Ejecty
				//********************************************************************************
				cSetResp  += '","tamanhoHaste":'      	+ cValToChar((cAliasTMP)->B1_ZZTAMHA)
				cSetResp  += ' ,"baseLente":"'     		+ TRIM((cAliasTMP)->B1_ZZBASE)
				cSetResp  += '","tamanhoPonte":'     	+ cValToChar((cAliasTMP)->B1_ZZTAMPO)
				cSetResp  += ' ,"tamanhoCxLente":"'    	+ TRIM((cAliasTMP)->B1_ZZTAMCL)

				//********************************************************************************
				// Posiciono na Tabela SB1 para passar para o Body como array com uma 
				// dimensใo para cada linha
				//********************************************************************************
				cSetResp  += '","informacaoProduto":'
				
				//********************************************************************************
				// Abre o Array
				//********************************************************************************
				cSetResp  += '{'
				
				//********************************************************************************
				// Posiciona no Registro da SB1
				//********************************************************************************
				SB1->(dbGoTo((cAliasTMP)->R_E_C_N_O_))
				
				//********************************************************************************
				// Faz um For com a quantidade de linhas do campo (Fun็ใo MlCount)
				//********************************************************************************
				For nY := 1 to MlCount((cAliasTMP)->B1_ZZDESCP)
					
					//********************************************************************************
					// Insere a virgula a partir do segundo elemento do array, caso nใo seja vazio
				   	//********************************************************************************
					If !Empty(MEMOLINE((cAliasTMP)->B1_ZZDESCP,,nY,,.T.)) .AND. nY > 1
						cSetResp += ','
					Endif

					//********************************************************************************
					// Preenche o Array caso a linha nใo seja em branco
				   	//********************************************************************************
					//If ! Empty(Alltrim(MEMOLINE(FwCutOff(EncodeUTF8(SB1->B1_ZZDESCP)),,nY,,.T.)))
					If ! Empty(MEMOLINE((cAliasTMP)->B1_ZZDESCP,,nY,,.T.))
						//cSetResp += '"' + Alltrim(MEMOLINE(EncodeUTF8(SB1->B1_ZZDESCP),,nY,,.T.)) + '"'
						//cSetResp += '"Linha' + Alltrim(Str(nY)) + '":"' + Alltrim(MEMOLINE(EncodeUTF8(SB1->B1_ZZDESCP),,nY,,.T.)) + '"'
						//cSetResp += '"Linha' + Alltrim(Str(nY)) + '":"' + OemToAnsi(FwCutOff(Alltrim(MEMOLINE(RemovChar(EncodeUTF8(SB1->B1_ZZDESCP)),,nY,,.T.)), .T.)) + '"'
						cSetResp += '"Linha' + Alltrim(Str(nY)) + '":"' + EncodeUtf8(OemToAnsi(ALLTRIM(MEMOLINE((cAliasTMP)->B1_ZZDESCP,,nY,,.T.)))) + '"'

					Endif
				
				Next nY

				//********************************************************************************
				// Abre o Array
				//********************************************************************************
				cSetResp += '}'

				//********************************************************************************
				// Incluido em 26/02/21 por solicitacao do Marcos Soares - Ejecty
				//********************************************************************************
				cSetResp  += ',"descColecao":"' + ALLTRIM(Posicione("SBM",1,FwFilial("SBM")+(cAliasTMP)->B1_GRUPO,"BM_DESC"))

				//********************************************************************************
				// Incluido em 27/05/2021 por solicitacao do Michael - Suntech Supplyes
				//********************************************************************************
				cSetResp  += '","genero":"'    				+ TRIM((cAliasTMP)->B1_ZZGENER)
				cSetResp  += '","aroOculos":"'    			+ TRIM((cAliasTMP)->B1_ZZARO)
				cSetResp  += '","tamanhoOculos":"'    		+ TRIM((cAliasTMP)->B1_ZZTMARM)
				cSetResp  += '","descricaoTipoLente":"'    	+ TRIM(POSICIONE("SX5",1,fwFilial("SX5")+"Z7"+(cAliasTMP)->B1_ZZTPLEN,"X5_DESCRI"))
				cSetResp  += '","descricaoMaterialOculos":"'+ TRIM(POSICIONE("SX5",1,fwFilial("SX5")+"Z8"+(cAliasTMP)->B1_ZZMATER,"X5_DESCRI"))
				cSetResp  += '","descricaoEstiloOculos":"' 	+ TRIM(POSICIONE("SX5",1,fwFilial("SX5")+"Z6"+(cAliasTMP)->B1_ZZESTIL,"X5_DESCRI"))
				cSetResp  += '","descricaoCor":"'	    	+ TRIM(POSICIONE("SX5",1,fwFilial("SX5")+"Z1"+(cAliasTMP)->B1_ZZCORPR,"X5_DESCRI"))

				//********************************************************************************
				// Incluido em 04/06/2021 por solicitacao do Marcos Soares - Ejecty
				//********************************************************************************
				cSetResp  += '","modeloClipon":"' + TRIM((cAliasTMP)->B1_ZZMCLIP)


				cSetResp  += '"}'	
				nX:= nX+1
			Endif 
			(cAliasTMP)->(dbSkip())
		EndDo
	
	Else												// Nenhuma QueryString passada por parametro

		lRet 		:= .F.
		nX			:= 1
		cSetResp  	:= '{"produto":['

		While !(cAliasTMP)->( Eof() )				
	
			If nX > 1
				cSetResp  +=' , '
			EndIf

			cSetResp  += '{'
			cSetResp  += '"CODIGO":"'  				+ TRIM((cAliasTMP)->B1_COD )	
			cSetResp  += '","CODIGOCATEGORIA":"' 	+ TRIM((cAliasTMP)->B1_ZZCOLEC)
			cSetResp  += '","CODIGOSTATUS":"'	 	+ TRIM((cAliasTMP)->B1_ZZLIBVE)				// Ruberlei em 23/01/2020
			cSetResp  += '","DESCRICAO":"'          + strTran(TRIM((cAliasTMP)->B1_DESC ), '"', '\"')	
			cSetResp  += '","FLAGBLOQUEIO":"'   	+ TRIM((cAliasTMP)->B1_MSBLQL) 
			cSetResp  += '","DUN14":"'				+ TRIM((cAliasTMP)->B1_CODBAR)
			cSetResp  += '","PESOBRUTO":'    		+ TRIM(STR((cAliasTMP)->B1_PESBRU)) 
			cSetResp  += ',"QTDEEMBALAGEM":' 		+ TRIM(STR((cAliasTMP)->B1_QE) )	
			cSetResp  += ',"UNIDPRODUTO":"'			+ TRIM((cAliasTMP)->B1_UM)	
			cSetResp  += '","PESOLIQUIDO":' 		+ TRIM(STR((cAliasTMP)->B1_PESO))
			cSetResp  += ',"NCM":"'                	+ TRIM(((cAliasTMP)->B1_POSIPI))
			cSetResp  += '","AMOGRATIS":"'          + ALLTRIM(STR((cAliasTMP)->B1_PESO))
			cSetResp  += '","CLASSFISCAL":"'        + TRIM(((cAliasTMP)->B1_CLASFIS))
			cSetResp  += '","CODGRPTRIB":"'         + TRIM(((cAliasTMP)->B1_GRTRIB))
			cSetResp  += '","ICMSINT":'            	+ TRIM(STR((cAliasTMP)->B1_PICM))
			cSetResp  += ',"ICMSEXT":'            	+ TRIM(STR(0))
			cSetResp  += ',"MVA":'                	+ TRIM(STR((cAliasTMP)->B1_PICMRET))
			cSetResp  += ',"PISPAUTA":'           	+ TRIM(STR((cAliasTMP)->B1_VLR_PIS))
			cSetResp  += ',"COFINSPAUTA":'        	+ TRIM(STR((cAliasTMP)->B1_PESO))
			cSetResp  += ',"ALIQPIS":'             	+ TRIM(STR((cAliasTMP)->B1_PPIS))
			cSetResp  += ',"ALIQCOFINS":'          	+ TRIM(STR((cAliasTMP)->B1_PCOFINS))
			cSetResp  += ',"ALIQIPI":'      		+ TRIM(STR((cAliasTMP)->B1_IPI))		
			cSetResp  += ',"CUSTOSECO":'           	+ TRIM(STR((cAliasTMP)->B1_CUSTD))
			cSetResp  += ',"CODIGOANTERIOR":"'      + TRIM((cAliasTMP)->B1_ZZCODAN )
			//********************************************************************************
			cSetResp  += '","LINHA":"' 			    + TRIM((cAliasTMP)->B1_ZZLINHA )
			cSetResp  += '","LANCAMENTO":"'      	+ TRIM((cAliasTMP)->B1_ZZLANC )

			//********************************************************************************
			// Incluido em 12/08/20 por solicitacao do Marcos Soares - Ejecty
			//********************************************************************************
			cSetResp  += '","tamanhoHaste":'      	+ cValToChar((cAliasTMP)->B1_ZZTAMHA)
			cSetResp  += ' ,"baseLente":"'     		+ TRIM((cAliasTMP)->B1_ZZBASE)
			cSetResp  += '","tamanhoPonte":'     	+ cValToChar((cAliasTMP)->B1_ZZTAMPO)
			cSetResp  += ' ,"tamanhoCxLente":"'    	+ TRIM((cAliasTMP)->B1_ZZTAMCL)
			
			//********************************************************************************
			// Posiciono na Tabela SB1 para passar para o Body como array com uma 
			// dimensใo para cada linha
			//********************************************************************************
			cSetResp  += '","informacaoProduto":'
			
			//********************************************************************************
			// Abre o Array
			//********************************************************************************
			cSetResp  += '{'
			
			//********************************************************************************
			// Posiciona no Registro da SB1
			//********************************************************************************
			SB1->(dbGoTo((cAliasTMP)->R_E_C_N_O_))
			
			//********************************************************************************
			// Faz um For com a quantidade de linhas do campo (Fun็ใo MlCount)
			//********************************************************************************
			For nY := 1 to MlCount((cAliasTMP)->B1_ZZDESCP)

				//********************************************************************************
				// Insere a virgula a partir do segundo elemento do array, caso nใo seja vazio
				//********************************************************************************
				If !Empty(MEMOLINE((cAliasTMP)->B1_ZZDESCP,,nY,,.T.)) .AND. nY > 1
					cSetResp += ','
				Endif
				
				//********************************************************************************
				// Preenche o Array caso a linha nใo seja em branco
				//********************************************************************************
				If !Empty(MEMOLINE((cAliasTMP)->B1_ZZDESCP,,nY,,.T.))
					//cSetResp += '"' + Alltrim(MEMOLINE(EncodeUTF8(SB1->B1_ZZDESCP),,nY,,.T.)) + '"'
					//cSetResp += '"Linha' + Alltrim(Str(nY)) + '":"' + Alltrim(MEMOLINE(EncodeUTF8(SB1->B1_ZZDESCP),,nY,,.T.)) + '"'
					//cSetResp += '"Linha' + Alltrim(Str(nY)) + '":"' + OemToAnsi(FwCutOff(Alltrim(MEMOLINE(RemovChar(EncodeUTF8(SB1->B1_ZZDESCP)),,nY,,.T.)), .T.)) + '"'
					cSetResp += '"Linha' + Alltrim(Str(nY)) + '":"' + EncodeUtf8(OemToAnsi(ALLTRIM(MEMOLINE((cAliasTMP)->B1_ZZDESCP,,nY,,.T.)))) + '"'
				
					//RemovChar(cRet)
				Endif

			Next nY

			//********************************************************************************
			// Abre o Array
			//********************************************************************************
			cSetResp += '}'

			//********************************************************************************
			// Incluido em 26/02/21 por solicitacao do Marcos Soares - Ejecty
			//********************************************************************************
			cSetResp  += ',"descColecao":"' + ALLTRIM(Posicione("SBM",1,FwFilial("SBM")+(cAliasTMP)->B1_GRUPO,"BM_DESC"))
			cSetResp  += '"}'	
			nX:= nX+1
			(cAliasTMP)->(dbSkip())
		EndDo

	EndIf

	cSetResp  += ']'	
	
	If lRet
		cSetResp  += ',"PaginalAtual":'				+ STR(Self:nPag)			
		cSetResp  += ',"TotalDePaginas":'			+ STR(nPagFim)
	Else
		cSetResp  += ',"PaginalAtual": 1'
		cSetResp  += ',"TotalDePaginas": 1'
	Endif

	cSetResp  += '}'		

	//Fecha a tabela
	(cAliasTMP)->(DbCloseArea())

	//Envia o JSON Gerado para a aplica็ใo Cliente
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)


/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณ RemovCharบAutor  ณ Augusto Ribeiro	 บ Data ณ  08/06/2011 บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Remove caracter especial                                   ฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿*/
STATIC Function RemovChar(cRet)
	
	Local cRet

	cRet	:= STRTRAN(cRet,"'","")
	cRet	:= STRTRAN(cRet,'"',"")

Return(cRet)
