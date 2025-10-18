#include "protheus.ch"
#INCLUDE 'APWIZARD.CH'

/*---------------------------------------------------------------------
TODO 			Descrição auto-gerada.
@author 		Carlos Eduardo Saturnino
@since 			17/12/2019
@version 		1.0
---------------------------------------------------------------------*/
User Function fImpCSV()

	Local oWizard    := NIL
	Local lFinish    := .F.
	Local cHeader    := ''
	Local cMessage   := ''
	Local cText      := ''
	Local cTitleProg := 'TOTVS ImportCSV 1.1'

	Local oFileCSV   := Nil
	Local cTextP2    := '' 
	Local oTextP2    := Nil 

	Local cNameFunc  := "MATA240" + Space(100)
	Local oNameFunc  := Nil
	Local cTextP3    := ''
	Local oTextP3    := Nil

	Local nTipoData  := 1
	Local lNoAcento  := .T.
	Local oNoAcento  := Nil
	Local lOrdVetX3  := .T.
	Local oOrdVetX3  := .T.

	Local cFileLog   := ''
	Private cFileImp   := Space(100)

	DEFINE FONT oArial10	NAME 'Arial'       WEIGHT 10
	DEFINE FONT oCouri11	NAME 'Courier New' WEIGHT 11

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³PAINEL PRINCIPAL     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cHeader  := 'ImportCSV - Importação de dados.'
	cMessage := 'Assistente para processamento'
	cText    := 'Este assistente irá auxiliá-lo na configuração dos parâmetros para realização da importação '
	cText    += 'dos dados a partir de um arquivo (.CSV). O objetivo desta aplicação é efetuar a importação '
	cText    += 'consistindo todas as validações existentes no sistema para o cadastramento da tabela.' + Chr(10)+Chr(13)
	cText    += 'Para a realização das validações o programa utilizará o recurso de rotina automática (MSExecAuto).'
	cText    += Chr(10)+Chr(13)
	cText    += Chr(10)+Chr(13)
	cText    += Chr(10)+Chr(13)
	cText    += 'Clique em "Avançar" para continuar...'

	DEFINE	WIZARD	oWizard ;
	TITLE	'ImportCSV v1.1';
	HEADER	cHeader;
	MESSAGE	cMessage;
	TEXT	cText;
	NEXT 	{|| .T.};
	FINISH 	{|| .F.}

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³PAINEL 02            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cMessage := 'Informe o local e o arquivo (.CSV) para importação dos dados...'
	CREATE	PANEL 	oWizard  ;
	HEADER 	cHeader;
	MESSAGE	cMessage;
	BACK	{|| .T.} ;
	NEXT	{|| !Empty(cFileImp) }; 
	FINISH	{|| .F.}

	cTextP2	:= 'Restrições do arquivo:' + Chr(10)+Chr(13)
	cTextP2	+= Chr(10)+Chr(13)
	cTextP2	+= 'a.) A 1a. linha deve conter o cabeçalho do arquivo, com os nomes exatos de cada campo da tabela, exemplo: D3_COD;D3_LOCAL;D3_CUSTO1' + Chr(10)+Chr(13)
	cTextP2	+= Chr(10)+Chr(13)
	cTextP2	+= 'b.) No conteúdo dos campos não pode haver caracteres especiais como aspas simples ou duplas ' + "(')" + '(")' + ' e ponto e vírgula (;). Isso ira ocasionar em erro na montagem do arquivo.'
	cTextP2	+= Chr(10)+Chr(13)
	cTextP2	+= 'c.) A última linha do arquivo deve conter apenas um asterisco "*"'

	@ 012, 010 Say oTextP2 PROMPT cTextP2 Size 228, 094 Of oWizard:oMPanel[2] FONT oArial10 Pixel
	@ 085, 005 GROUP To 113, 245 PROMPT "Local e nome do arquivo:" OF oWizard:oMPanel[2] Pixel
	@ 095, 020 MsGet oFileCSV Var cFileImp Valid( If( File(cFileImp), .T., ( Alert("O arquivo informado para importação não existe!") ,.F.) ) .Or. Empty(cFileImp) ) Size 212, 010 Of oWizard:oMPanel[2] F3 "DIR" Pixel

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³PAINEL 03            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cMessage := 'Função para importação dos dados...'
	CREATE	PANEL 	oWizard  ;
	HEADER 	cHeader;
	MESSAGE	cMessage;
	BACK	{|| .T.} ;
	NEXT	{|| !Empty(cNameFunc) }; 
	FINISH	{|| .F.}

	/*
	cTextP3	:= 'Restrições da funcao:' + Chr(10)+Chr(13)
	cTextP3	+= Chr(10)+Chr(13)
	cTextP3	+= 'a.) A função a ser informada deve conter o recurso de rotina automática (MsExecAuto).' + Chr(10)+Chr(13)
	cTextP3	+= Chr(10)+Chr(13)
	cTextP3	+= 'b.) Informe apenas o nome da função, sem o parêntese, exemplo: MATA010' + Chr(10)+Chr(13)
	cTextP3	+= Chr(10)+Chr(13)
	cTextP3	+= 'c.) Utilize somente funções de cadastros ou movimentações simples, que requer apenas uma única tabela. Funções que requerem mais de uma tabela, como Nota Fiscal de Entrada, Pedido de Venda e etc, não podem ser importadas por esse programa.'
	*/

	cTextP3 :=  "Rotina Utilizada para esta manutenção"

	@ 012, 010 Say oTextP3  PROMPT cTextP3 Size 228, 094 Of oWizard:oMPanel[3] FONT oArial10 Pixel
	@ 085, 005 GROUP To 113, 245 PROMPT "Digite o nome da função:" OF oWizard:oMPanel[3] PIXEL
	@ 095, 020 MsGet oNameFunc Var cNameFunc When .f. Valid( If( FindFunction(cNameFunc), .T., ( Alert("Função inválida!") ,.F.) ) .Or. Empty(cNameFunc) ) Size 212, 010 Of oWizard:oMPanel[3] Pixel
	

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³PAINEL 04            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cMessage := 'Parâmetros para processamento...'
	CREATE	PANEL 	oWizard  ;
	HEADER 	cHeader;
	MESSAGE	cMessage;
	BACK	{|| .T.} ;
	NEXT	{|| .T. }; 
	FINISH	{|| .F.}

	@ 010, 005 GROUP To 055, 200 PROMPT 'formatado da data utilizada no arquivo CSV:' Of oWizard:oMPanel[4] Pixel
	@ 020, 010 Radio oTipoDia VAR nTipoData When .f. Items "1 = AAAAMMDD","2 = DD/MM/AA","3 = DD/MM/AAAA" SIZE 064, 026 Of oWizard:oMPanel[4] Color CLR_BLUE PIXEL

	@ 060, 005 GROUP To 090, 200 PROMPT 'Retira acentuação:' Of oWizard:oMPanel[4] Pixel
	@ 070, 010 CheckBox oNoAcento Var lNoAcento When .f. Prompt "Retira os acentos dos textos a serem importados" Size 140, 010 Of oWizard:oMPanel[4] Color CLR_BLUE Pixel

	@ 095, 005 GROUP To 125, 200 PROMPT 'Ordenação dos campos:' Of oWizard:oMPanel[4] Pixel
	@ 105, 010 CheckBox oOrdVetX3 Var lOrdVetX3 When .f.  Prompt "Ordena os campos conforme o dicionários de dados" Size 140, 010 Of oWizard:oMPanel[4] Color CLR_BLUE Pixel

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³PAINEL 05            ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cMessage := 'Iniciar o processamento...'
	CREATE	PANEL 	oWizard  ;
	HEADER 	cHeader;
	MESSAGE	cMessage;
	BACK	{|| .T.} ;
	NEXT	{|| .F.}; 
	FINISH	{|| lFinish := .T.}

	cFileLog := SubStr(AllTrim(cFileImp), 1, At('.', AllTrim(cFileImp)) - 1) + '.LOG'

	TSay():New(010, 005, {|| 'Ao término do processo será criado o arquivo de log no mesmo diretório do arquivo a ser importado. ' },;
	oWizard:oMPanel[5],, oCouri11,,,, .T.,,, 200, 50)

	TSay():New(045, 005, {|| 'Clique em "Finalizar" para encerrar o assistente e inicar o processamento...' },;
	oWizard:oMPanel[5],, oCouri11,,,, .T.,,, 200, 50)

	ACTIVATE WIZARD oWizard Center

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³INICIO DO PROCESSO DE VERIFICACAO³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lFinish
		//--PROCESSA A IMPORTACAO:
		Processa({||  ProcImp(Alltrim(cFileImp), cFileLog, Alltrim(cNameFunc),nTipoData,lNoAcento, lOrdVetX3) }, cTitleProg, 'Processando importação...')
	EndIf

Return Nil

/*---------------------------------------------------------------------
TODO 			Descrição auto-gerada.
@author 		Carlos Eduardo Saturnino
@since 			17/12/2019
@version 		1.0
---------------------------------------------------------------------*/
Static Function ProcImp(cFileImp, cFileLog, cNameRot, nTipoData, lNoAcento, lOrdVetX3)

	Local nHdlLog     	:= 0
	Local nLinha      	:= 0
	Local aDataCab    	:= ''
	Local aDataIte    	:= {}
	Local aMsExcAuto  	:= {}
	Local bBlockAuto  	:= {}
	Local cErrAuto    	:= ''
	Local aTamSX3     	:= {}
	Local xConteudo   	:= Nil 
	Local nCntFor
	Local _nCustoSD3	as numeric 

	Private lMsHelpAuto	:= .T.    // força a gravação das informações de erro em array para manipulação da gravação ao invés de gravar direto no arquivo temporário
	Private lMsErroAuto	:= .F.

	//---------------------------------------------------------------------
	//³CRIA ARQUIVO DE LOG³
	//---------------------------------------------------------------------
	cFileLog := SubStr(AllTrim(cFileImp), 1, At('.', AllTrim(cFileImp)) - 1) + '.LOG'
	nHdlLog  := MSFCreate(cFileLog,0)

	If nHdlLog < 0

		Aviso('ATENÇÃO', 'PROBLEMAS NA CRIAÇÃO DO ARQUIVO DE LOG DE INCONSISTÊNCIAS!' + Chr(10) + Chr(13) + 'Código do erro: ' + StrZero(FError(),10), {'OK'}, 3)

	Else
		//---------------------------------------------------------------------
		//--Atualiza arquivo de LOG:
		//---------------------------------------------------------------------
		UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] INICIANDO PROCESSO DE IMPORTAÇÃO' + Chr(13) + Chr(10))

		//---------------------------------------------------------------------
		//--Abre o arquivo e inicia a importacao:
		//---------------------------------------------------------------------
		FT_FUSE(cFileImp)
		ProcRegua(5000)

		//---------------------------------------------------------------------
		//--Atualiza arquivo de LOG:
		//---------------------------------------------------------------------
		UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] INICIANDO IMPORTAÇÃO DOS DADOS ' + Chr(13) + Chr(10))

		If File(cFileImp)
			While !FT_FEOF()

				xBuffer	:= UPPER(FT_FREADLN())

				nLinha++
				If nLinha == 1 
					//---------------------------------------------------------------------
					//-- Armazena em memoria a 1a. linha (Cabecalho).
					//---------------------------------------------------------------------
					aDataCab := aBIToken(xBuffer, ';',.F.)
				Else		

					If !EMPTY(STRTRAN(xBuffer, ";", ""))
						aDataIte := aBIToken(xBuffer, ';',.F.)
					EndIf

					If Len(aDataIte) > 0
						If Alltrim( aDataIte[1] ) <> "*"
							If Len(aDataIte) == Len(aDataCab)

								aMsExcAuto := {}
								cSituaca := ""
								
								//---------------------------------------------------------------------
								//--Compatibiliza os campos conforme dicionario de dados:
								//---------------------------------------------------------------------
								For nCntFor := 1 To Len(aDataCab)

									aTamSX3 := TamSX3(aDataCab[nCntFor])
									If Len(aTamSX3) > 0
										If aTamSX3[3] == 'N'
											xConteudo := Val( StrTran(aDataIte[nCntFor],",",".") )
										ElseIf aTamSX3[3] == 'D'
											If nTipoData == 1 					//-- AAAAMMDD
												xConteudo := StoD( aDataIte[nCntFor] )
											Else  								//-- DD/MM/AA ou DD/MM/AAAA
												xConteudo := CtoD( aDataIte[nCntFor] )
											EndIf
										ElseIf aTamSX3[3] == 'L'
											xConteudo := AllTrim(aDataIte[nCntFor]) == 'T' .Or. AllTrim(aDataIte[nCntFor]) == '.T.'
										ElseIf aTamSX3[3] == 'C'
											If lNoAcento
												xConteudo := NoAcento( PadR( AllTrim( StrTran(aDataIte[nCntFor],"|",";") ), aTamSX3[1] ) )
											Else
												xConteudo := PadR( AllTrim( StrTran(aDataIte[nCntFor],"|",";") ), aTamSX3[1] )
											EndIf
										ElseIf aTamSX3[3] == 'M'
											If lNoAcento
												xConteudo := NoAcento( AllTrim( aDataIte[nCntFor] ) )
											Else
												xConteudo := AllTrim( aDataIte[nCntFor] )
											EndIf							
										EndIf
									Else
										UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] Campo indicado no cabeçalho do arquivo CSV não conforme' + Chr(13) + Chr(10) + "Obrigatório que o cabeçalho do arquivo seja - D3_COD;D3_LOCAL;D3_CUSTO1" + Chr(13) + Chr(10) )
										UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] FIM DO PROCESSO DE IMPORTACAO' + Chr(13) + Chr(10))
										Return(.f.)
									Endif

									AAdd(aMsExcAuto, {aDataCab[nCntFor]	,xConteudo,NIL})

								Next

								//---------------------------------------------------------------------
								//-- Ordena os campos do vetor conforme ordem do SX3
								//---------------------------------------------------------------------
								If lOrdVetX3
									aMsExcAuto := OrdVetX3(aMsExcAuto)
								EndIf

								//---------------------------------------------------------------------
								//--Monta instrucao para processamento da rotina automatica:
								//---------------------------------------------------------------------
								bBlockAuto := {|X,Y| &(cNameRot)(X,Y)}

								//---------------------------------------------------------------------
								//--Realiza o processamento da rotina Automatica:
								//---------------------------------------------------------------------
								lMsErroAuto := .F.

								If UPPER(cNameRot) == "MATA240"		// Movimentos Internos Simples

									//---------------------------------------------------------------------
									//	Estrutura do arquivo:
									//	codigo de produto,local,custo unitario, centro de custo
									//	Busca o custo standard do produto
									//---------------------------------------------------------------------
									DbSelectArea("SB2")
									SB2->(DbSetOrder(1)) //FILIAL+CODIGO+LOCAL
									If SB2->(DbSeek(xFilial("SB2")+PadR(aMsExcAuto[1][2],15)+aMsExcAuto[2][2]))
										

										_nCustoSD3	:= 0			
										//							PRODUTO							,LOCAL				,@ArqLog	,@LinhaProc)
										_nCustoSD3	:=	fwMatr420( PadR( aMsExcAuto[1,2]	,15 )	,aMsExcAuto[2,2]	,@nHdlLog	,@nLinha )

										
				
										//---------------------------------------------------------------------
										//	Calculo do valor a ajustar
										//---------------------------------------------------------------------

										nVAtu1new	:=  _nCustoSD3  -  aMsExcAuto[3,2] 

										//-------------------------------------------------

										if nVAtu1new <> 0	//Valor do CSV = Valor das Movimentações da SD3
											/*
											If (_nCustoSD3 < nVAtu1new)
												cCodMov := "100" 				//Aumenta o custo no sistema. Movimento de entrada valorizado com quantidade 0
											Else
												cCodMov := "600" 				//Diminui o custo no sistema. Movimento de entrada valorizado com quantidade 0
											EndIf
											*/

											If (_nCustoSD3 < nVAtu1new)
												If SB1->B1_APROPRI == "D"
													cCodMov := "100" 				//Aumenta o custo no sistema. Produtos com Apropriação Direta
												Else
													cCodMov := "099" 				//Aumenta o custo no sistema. Produtos com Apropriação Indireta
												Endif
											Else
												If SB1->B1_APROPRI == "D"
													cCodMov := "600" 				//Diminui o custo no sistema. Produtos com Apropriação Direta
												Else
													cCodMov := "599" 				//Diminui o custo no sistema. Produtos com Apropriação Indireta
												Endif
											EndIf



											SB1->( DbSetOrder(1) )	//B1_FILIAL + B1_COD
											If SB1->( DbSeek( FWxFilial("SB1") + avKey( aMsExcAuto[01][02]	,"B1_COD") ) )
												If ALLTRIM(aMsExcAuto[1][2]) <> "*"
													ExpA1 := {}
													aadd(ExpA1,{"D3_TM"			,cCodMov					,Nil})
													aadd(ExpA1,{"D3_COD"		,SB1->B1_COD				,Nil})
													aadd(ExpA1,{"D3_UM"			,SB1->B1_UM					,Nil})
													aadd(ExpA1,{"D3_LOCAL"		,AllTrim(aMsExcAuto[02][02]),Nil})
													aadd(ExpA1,{"D3_QUANT"		,0							,Nil})
													aadd(ExpA1,{"D3_CUSTO1"		,nVAtu1new					,Nil})
													aadd(ExpA1,{"D3_EMISSAO"	,dDataBase					,Nil})
													aadd(ExpA1,{"D3_GRUPO"		,SB1->B1_GRUPO				,Nil})
													aadd(ExpA1,{"D3_CONTA"		,SB1->B1_CONTA				,Nil})

													MSExecAuto({|x,y| mata240(x,y)},ExpA1,3)

													If lMsErroAuto 													
														DisarmTransaction()													
														cErrAuto := MostraErro(cFileLog)													
														UpdFileLog(nHdlLog, Chr(13) + Chr(10) + '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Produto: ' +  Alltrim(aMsExcAuto[1][2]) + ' | Local: ' +  aMsExcAuto[2][2] + '] Inconsistência na atualização dos dados. Detalhe do Erro: ' + cErrAuto  + Chr(13) + Chr(10))
													Else
														//******************************************************************************
														// Grava o log de inclusão realizada com sucesso
														//******************************************************************************
														UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Produto: ' +  Alltrim(aMsExcAuto[1][2]) + ' | Local: ' +  Alltrim(aMsExcAuto[2][2]) + '] Atualizado com Sucesso !' + Chr(13) + Chr(10))
													EndIf
												Endif
											Else
												UpdFileLog(nHdlLog, Chr(13) + Chr(10) + '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Inconsistência na importação dos dados. Detalhe do Erro: Não foi encontrado o produto no local especificado: ' + aMsExcAuto[2][2] + " | Produto : " + Alltrim(aMsExcAuto[1][2]) + Chr(13) + Chr(10))
											Endif
										Else
											UpdFileLog(nHdlLog, Chr(13) + Chr(10) + '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Inconsistência na Leitura dos dados. Detalhe do Erro : Custo do Produto : ' + Alltrim(aMsExcAuto[1][2]) + " | Local : " + Alltrim(aMsExcAuto[2][2]) + " | Custo Atual do Produto Igual ao calculado pela rotina " + Chr(13) + Chr(10))
										Endif										
									Else
										//******************************************************************************
										// Grava o log do Erro para conferência posterior
										//******************************************************************************
										UpdFileLog(nHdlLog, Chr(13) + Chr(10) + '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Inconsistência na Leitura dos dados. Detalhe do Erro : Não foi encontrado o produto no local especificado: ' +aMsExcAuto[2][2]+" | Produto : "+aMsExcAuto[1][2] + Chr(13) + Chr(10))	    					
									EndIf
								Endif
							Else
								UpdFileLog(nHdlLog, Chr(13) + Chr(10) + '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Produto: ' +  aMsExcAuto[1][2] + ' | Local: ' +  aMsExcAuto[2][2] + ' Inconsistência na Leitura dos dados. Verifique o nome dos campos no header (linha 1) do arquivo !!!' + Chr(13) + Chr(10))
							EndIf
						Endif
					EndIf		
				EndIf

				IncProc()
				FT_FSKIP() //Pula para o próximo registro		
			EndDo

		EndIf

		FT_FUSE()

		//--Atualiza arquivo de LOG:
		UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] FIM DO PROCESSO DE IMPORTACAO' + Chr(13) + Chr(10))

		//--Exibe LOG de processamento:
		FClose(nHdlLog)		
		ShowLog(cFileLog)
	EndIf


Return Nil

/*---------------------------------------------------------------------

TODO 			Descrição auto-gerada.
@author 		Carlos Eduardo Saturnino
@since 			17/12/2019
@version 		1.0
---------------------------------------------------------------------*/
Static Function UpdFileLog(nHdlLog, cMsg)

	FWrite(nHdlLog, cMsg)

Return Nil

/*---------------------------------------------------------------------

TODO 			Descrição auto-gerada.
@author 		Carlos Eduardo Saturnino
@since 			17/12/2019
@version 		1.0
---------------------------------------------------------------------*/
Static Function ShowLog(cFileLog)
	Local oDlg     := NIL
	Local oFont    := NIL
	Local cMemo    := ''
	Local oMemo    := NIL

	cMemo := MemoRead(cFileLog)
	DEFINE FONT oFont NAME "Courier New" SIZE 5,0
	DEFINE MSDIALOG oDlg TITLE 'LOG' From 3,0 to 340,617 PIXEL
	@ 5,5 GET oMemo  VAR cMemo MEMO SIZE 300,145 OF oDlg PIXEL 
	oMemo:bRClicked := {|| AllwaysTrue()}
	oMemo:oFont:=oFont
	DEFINE SBUTTON  FROM 153,280 TYPE 1 ACTION oDlg:End() ENABLE OF oDlg PIXEL //Apaga
	ACTIVATE MSDIALOG oDlg CENTER

Return Nil

/*---------------------------------------------------------------------

TODO 			Descrição auto-gerada.
@author 		Carlos Eduardo Saturnino
@since 			17/12/2019
@version 		1.0
---------------------------------------------------------------------*/
Static Function NoAcento(cString)

	Local cChar  := ""
	Local nX     := 0 
	Local nY     := 0
	Local cVogal := "aeiouAEIOU"
	Local cAgudo := "áéíóú"+"ÁÉÍÓÚ"
	Local cCircu := "âêîôû"+"ÂÊÎÔÛ"
	Local cTrema := "äëïöü"+"ÄËÏÖÜ"
	Local cCrase := "àèìòù"+"ÀÈÌÒÙ" 
	Local cTio   := "ãõ"
	Local cCecid := "çÇ"

	For nX:= 1 To Len(cString)
		cChar:=SubStr(cString, nX, 1)
		IF cChar$cAgudo+cCircu+cTrema+cCecid+cTio+cCrase
			nY:= At(cChar,cAgudo)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCircu)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTrema)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCrase)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf		
			nY:= At(cChar,cTio)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr("ao",nY,1))
			EndIf		
			nY:= At(cChar,cCecid)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr("cC",nY,1))
			EndIf
		Endif
	Next                                                                                                                                                      
	For nX:=1 To Len(cString)
		cChar:=SubStr(cString, nX, 1)
		If Asc(cChar) < 32 .Or. Asc(cChar) > 123 .Or. cChar $ '&'
			cString:=StrTran(cString,cChar,".")
		Endif
	Next nX
	cString := _NoTags(cString)
Return cString

/*---------------------------------------------------------------------
TODO 			Descrição auto-gerada.
@author 		Carlos Eduardo Saturnino
@since 			17/12/2019
---------------------------------------------------------------------*/
Static Function OrdVetX3( aVetor, cTabela )

	Local aRet     := {}
	Local aAux     := {}
	Local nCt      := 1
	Local aArea    := GetArea()
	Local aAreaSX3 := SX3->( GetArea() )

	SX3->( dbSetOrder( 1 ) ) //-- X3_ARQUIVO + X3_ORDEM

	If cTabela == NIL
		cTabela := SubStr( aVetor[1][1], 1, At( '_', aVetor[1][1] ) - 1 )
		cTabela := IIf( Len( cTabela ) == 2, 'S' + cTabela, cTabela )
	EndIf

	SX3->( dbSeek( cTabela ) )

	While !SX3->( Eof () ) .AND. SX3->X3_ARQUIVO == cTabela
		If  ( nPos := aScan( aVetor, { |x| RTrim( SX3->X3_CAMPO ) $ RTrim( x[1] ) } ) ) <> 0
			aAdd( aAux, { StrZero( nCt, 4), aVetor[nPos] } )
			nCt++
		EndIf
		SX3->( dbSkip() )
	End

	aSort( aAux,,, { | x, y | x[1] < y[1] } )
	aEval( aAux, { | x, y | aAdd( aRet, aAux[y][2] ) } )

	RestArea( aAreaSX3 )
	RestArea( aArea )
Return aRet


/*---------------------------------------------------------------------
TODO 			Descrição Executa calculo de custo baseado nas movimentações da SD3
@author 		Alexandre Caetano - ACSJ
@since 			14-04-2021
---------------------------------------------------------------------*/
Static Function fwMatr420( _cProduto	,_cLocal	,nHdlLog	,nLinha)
	Local _nRetSD3		as array

	_nRetSD3	:= CalcCustSD3( @_cProduto	,@_cLocal	,@nHdlLog	,@nLinha )
	
Return(_nRetSD3)
/*---------------------------------------------------------------------
TODO 			Descrição Processa o calculo do custo médio baseado nas movimentações da SD3
@author 		Alexandre Caetano - ACSJ
@since 			14-04-2021
---------------------------------------------------------------------*/
Static Function CalcCustSD3(_cProduto	,_cLocal	,nHdlLog	,nLinha	)

	Local lVeiculo := Upper(GetMV("MV_VEICULO")) == "S"
	Local aFilsCalc  := {}
	Local cTrbSD1    := ""
	Local cTrbSD2    := ""
	Local cTrbSD3    := ""
	Local cFilBack   := cFilAnt
	Local cProdMNT   := GetMv("MV_PRODMNT")
	Local cProdTER   := GetMv("MV_PRODTER")
	Local aProdsMNT  := {}
	Local nForFilial := 0
	Local lLocProc   := mv_par08 == GetMvNNR('MV_LOCPROC','99')
	Local lRemInt    := SuperGetMv("MV_REMINT",.F.,.F.)
	Local aSalAlmox	:={},aArea:={}
	Local cSeek		:=""
	Local i			:=0
	Local cRemito   := ""
	Local cAliasRel := ""

	Local _cQry		as char
	Local _cArqSQL	as char
	Local _lGo		as logical


	_cArqSQL		:= GetNextAlias()

	PRIVATE aSalAtu    := {}
	PRIVATE nEntPriUM  := 0
	PRIVATE nSaiPriUM  := 0
	PRIVATE nEntraVal  := 0
	PRIVATE nSaidaVal  := 0
	PRIVATE dCntData

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Variaveis utilizadas para parametros                         ³
	//³ mv_par01        // Do produto                                ³
	//³ mv_par02        // Ate o produto                             ³
	//³ mv_par03        // Do tipo                                   ³
	//³ mv_par04        // Ate o tipo                                ³
	//³ mv_par05        // Da data                                   ³
	//³ mv_par06        // Ate a data                                ³
	//³ mv_par07        // Lista produtos s/movimento                ³
	//³ mv_par08        // Qual Local (almoxarifado)                 ³
	//³ mv_par09        // Saldo a considerar : Atual / Fechamento   ³
	//³ mv_par10        // Moeda selecionada (1 a 5)                 ³
	//³ mv_par11        // Imprime descricao do armazem Por Empresa? ³
	//³ mv_par12        // Seleciona Filial?                         ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	
	Pergunte("MTR420",.F.)

	mv_par01 := _cProduto       							// Do produto                                
	mv_par02 := _cProduto   								// Ate o produto                             
	mv_par03 := Replicate(" ",2)        					// Do tipo                                   
	mv_par04 := Replicate("Z",2)        					// Ate o tipo                                
	mv_par05 := StoD("19900101")		        			// Da data                                   
	mv_par06 := dDataBase			    					// Ate a data                                
	mv_par07 := "N"  				    					// Lista produtos s/movimento                
	mv_par08 := _cLocal       								// Qual Local (almoxarifado)                 
	mv_par09 := 1       									// Saldo a considerar : Atual / Fechamento   
	mv_par10 := 1      										// Moeda selecionada (1 a 5)                 
	mv_par11 := 2      										// Imprime descricao do armazem Por Empresa? 
	mv_par12 := 2       									// Seleciona Filial?                         

	cProdMNT := cProdMNT + Space(15-Len(cProdMNT))
	cProdTER := cProdTER + Space(15-Len(cProdTER))

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ MatFilCalc() - Funcao para selecao de Filiais                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	aFilsCalc := MatFilCalc((mv_par12 == 1))

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se utiliza custo unificado por Empresa/Filial       ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Private lCusUnif := A330CusFil()

	lCusUnif:=lCusUnif .And. Trim(mv_par08) == "**"

	If Empty(aFilsCalc)
		Return
	EndIf

	aSalAtu  := { 0,0,0,0,0,0,0 }	// Criando neste momento em caso de incosistência retorna 0

	For nForFilial := 1 To Len( aFilsCalc )

		If aFilsCalc[ nForFilial, 1 ]

			cFilAnt := aFilsCalc[ nForFilial, 2 ]

			//ACSJ - 14-04-2021 - Para a lógica criada será calculado sempre produto a produto 
			//                    Não será necessário a criação de um filtro por dbSetFilter
			_lGo	:= .f.
			If lVeiculo

				If Select(_cArqSQL) > 0
                	dbSelectArea(_cArqSQL)	
                	DbCloseArea()
            	EndIf 

				_cQry	:= " SELECT R_E_C_N_O_ AS RECSB1 " + CRLF
				_cQry	+= " FROM "	+ RetSQLName("SB1") + " SB1 " + CRLF
				_cQry	+= " WHERE SB1.B1_FILIAL  = '" + FWxFilial("SB1") + "' " + CRLF
				_cQry	+= "   AND SB1.B1_CODITE  = '" + mv_par01         + "' " + CRLF
				_cQry	+= "   AND SB1.B1_TIPO   >= '" + mv_par03		 + "' " + CRLF
				_cQry	+= "   AND SB1.B1_TIPO   <= '" + mv_par04		 + "' " + CRLF
				_cQry	+= "   AND SB1.D_E_L_E_T_ = '' " + CRLF

				MPSysOpenQuery( _cQry, _cArqSQL,)

				If (_cArqSQL)->(!Eof())
					UpdFileLog(nHdlLog, Chr(13) + Chr(10) + '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] INCONSISTENCIA NA IMPORTACAO DOS DADOS. DETALHE DO ERRO: ' + "Não foi encontrado o produto " +_cProduto+" / "+_cLocal + Chr(13) + Chr(10))	
				Else
					SB1->( dbGoTo( (_cArqSQL)->RECSB1 ) )
					_lGo	:= .t.
				Endif

				If Select(_cArqSQL) > 0
                	dbSelectArea(_cArqSQL)	
                	DbCloseArea()
            	EndIf 

			Else
				SB1->( dbSetOrder(1) )	// B1_FILIAL + B1_COD
				If !SB1->( msSeek( FWxFilial("SB1") + avKey( _cProduto	,"B1_COD") ) )
					UpdFileLog(nHdlLog, Chr(13) + Chr(10) + '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] INCONSISTENCIA NA IMPORTACAO DOS DADOS. DETALHE DO ERRO: ' + "Não foi encontrado o produto " + _cProduto + " / " + _cLocal + Chr(13) + Chr(10))	
				Else
					If SB1->B1_TIPO >= mv_par03 .and. SB1->B1_TIPO <= mv_par04
						_lGo	:= .t.
					Else
						UpdFileLog(nHdlLog, Chr(13) + Chr(10) + '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] INCONSISTENCIA NA IMPORTACAO DOS DADOS. DETALHE DO ERRO: ' + "Não foi encontrado o produto " + _cProduto + " / " + _cLocal + Chr(13) + Chr(10))	
					Endif
				Endif
			EndIf

			

			if _lGo

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Não imprimir o produto MANUTENCAO (MV_PRDMNT) qdo integrado com MNT.       ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If MTR420IsMNT()
					aProdsMNT := aClone(NGProdMNT())
					If aScan(aProdsMNT, {|x| AllTrim(x) == AllTrim(SB1->B1_COD) }) > 0
						UpdFileLog(nHdlLog, Chr(13) + Chr(10) + '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] INCONSISTENCIA NA IMPORTACAO DOS DADOS. DETALHE DO ERRO: ' + "Produto / Local " + _cProduto + " / " + _cLocal + "não localizado na manutenção de ativo" + Chr(13) + Chr(10))	
						dbSelectArea("SB1")
						_lGo	:= .f.
					EndIf
				EndIf

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Se nao encontrar no arquivo de saldos ,nao lista ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				dbSelectArea("SB2")
				If !dbSeek(xFilial("SB2")+SB1->B1_COD+If(lCusUnif,"",mv_par08)) .and. _lGo
						If _lGo
							UpdFileLog(nHdlLog, Chr(13) + Chr(10) + '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] INCONSISTENCIA NA IMPORTACAO DOS DADOS. DETALHE DO ERRO: ' + "Produto / Local " +_cProduto + " / " + _cLocal + " não localizado na tabela SB2 " + Chr(13) + Chr(10))	
						Endif
					dbSelectArea("SB1")
					_lGo	:= .f.
				EndIf

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Calcula o Saldo Inicial do Produto             ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				If lCusUnif	.and. _lGo
					aArea:=GetArea()
					aSalAtu  := { 0,0,0,0,0,0,0 }
					dbSelectArea("SB2")
					dbSetOrder(1)
					dbSeek(cSeek:=xFilial("SB2") + (SB1->B1_COD))
					While !Eof() .And. B2_FILIAL+B2_COD == cSeek
						aSalAlmox := CalcEst(SB1->B1_COD,SB2->B2_LOCAL,mv_par05)
						For i:=1 to Len(aSalAtu)
							aSalAtu[i] += aSalAlmox[i]
						Next i
						dbSkip()
					End
					RestArea(aArea)
				Elseif _lGo
					aSalAtu := CalcEst(SB1->B1_COD,mv_par08,mv_par05)
				EndIf

				if _lGo

					cQuery:= "SELECT SUM(CASE SD1.D1_TIPO WHEN 'D' THEN 0 ELSE SD1.D1_QUANT END) AS ENTQTD,"
					cQuery+= "SUM(CASE SD1.D1_TIPO WHEN 'D' THEN -SD1.D1_QUANT ELSE 0 END) AS SDAQTD,"
					cQuery+= "SUM(CASE SD1.D1_TIPO WHEN 'D' THEN 0 ELSE SD1.D1_QTSEGUM END) AS ENTQTS,"
					cQuery+= "SUM(CASE SD1.D1_TIPO WHEN 'D' THEN -SD1.D1_QTSEGUM ELSE 0 END) AS SDAQTS,"
					cQuery+= "SUM(CASE SD1.D1_TIPO WHEN 'D' THEN 0 ELSE SD1.D1_CUSTO"+Iif(mv_par10==1," ",alltrim(Str(mv_par10)))+" END) AS ENTCUST,"
					cQuery+= "SUM(CASE SD1.D1_TIPO WHEN 'D' THEN -SD1.D1_CUSTO"+Iif(mv_par10==1," ",alltrim(Str(mv_par10)))+" ELSE 0 END) AS SDACUST,"
					cQuery+= "SD1.D1_DTDIGIT AS DATA "
					cQuery+= " FROM "+RetSqlName("SD1")+" SD1 JOIN "+RetSqlName("SF4")+" SF4 ON "
					cQuery+= "SF4.D_E_L_E_T_ <> '*' AND "
					cQuery+= "SF4.F4_FILIAL = '"+xFilial("SF4")+"' AND "
					cQuery+= "SF4.F4_CODIGO = SD1.D1_TES AND "
					cQuery+= "SF4.F4_ESTOQUE = 'S' "
					cQuery+= "WHERE SD1.D_E_L_E_T_ <> '*' AND "
					cQuery+= "SD1.D1_FILIAL = '"+xFilial("SD1")+"'"
					cQuery+= " AND SD1.D1_COD = '"+SB1->B1_COD+"' "
					cQuery+= " AND SD1.D1_DTDIGIT >= '"+Dtos(mv_par05)+"' AND SD1.D1_DTDIGIT <= '"+dtos(mv_par06)+"'"
					cQuery+= " AND SD1.D1_ORIGLAN != 'LF'"
					If !lCusUnif
						cQuery += " AND SD1.D1_LOCAL = '"+MV_PAR08+"'"
					EndIf
					If cPaisLoc != "BRA"
						cRemito:= CriaVar("D1_REMITO")
						cConhec:= CriaVar("D1_CONHEC")
						cQuery += " AND D1_REMITO = '"+cRemito+"'"
						cQuery += " AND SD1.D1_TIPO_NF NOT IN('6','7','8','9','A','B')"
						If lRemInt
							cQuery += " AND SD1.D1_CONHEC = '"+cConhec+"' AND SD1.D1_TIPO_NF NOT IN ('5') AND SD1.D1_TIPODOC NOT IN '10'"
						EndIf
					EndIf
					cQuery+= " GROUP BY D1_DTDIGIT"

					cQuery+= " UNION ALL "
					cQuery+= "SELECT SUM(CASE WHEN SD3.D3_TM > '500' THEN 0 ELSE SD3.D3_QUANT END) AS ENTQTD,
					cQuery+= "SUM(CASE WHEN SD3.D3_TM > '500' THEN SD3.D3_QUANT ELSE 0 END) AS SDAQTD,"
					cQuery+= "SUM(CASE WHEN SD3.D3_TM > '500' THEN 0 ELSE SD3.D3_QTSEGUM END) AS ENTQTS,"
					cQuery+= "SUM(CASE WHEN SD3.D3_TM > '500' THEN SD3.D3_QTSEGUM ELSE 0 END) AS SDAQTS,"
					cQuery+= "SUM(CASE WHEN SD3.D3_TM > '500' THEN 0 ELSE SD3.D3_CUSTO"+Alltrim(Str(mv_par10))+" END) AS ENTCUST,"
					cQuery+= "SUM(CASE WHEN SD3.D3_TM > '500' THEN SD3.D3_CUSTO"+AllTrim(Str(mv_par10))+" ELSE 0 END) AS SDACUST, "
					cQuery+= "SD3.D3_EMISSAO AS DATA "
					cQuery+= "FROM "+RetSqlName("SD3")+" SD3 "
					cQuery+= "WHERE SD3.D_E_L_E_T_ <> '*' AND "
					cQuery+= "SD3.D3_FILIAL = '"+xFilial("SD3")+"'"
					cQuery+= " AND SD3.D3_COD = '"+SB1->B1_COD+"' "
					cQuery+= " AND SD3.D3_EMISSAO >= '"+Dtos(mv_par05)+"' AND SD3.D3_EMISSAO <= '"+dtos(mv_par06)+"'"
					cQuery+= " AND SD3.D3_ESTORNO <> 'S'"
					If !lCusUnif
						cQuery += " AND SD3.D3_LOCAL = '"+MV_PAR08+"'"
					EndIf
					cQuery+= " GROUP BY D3_EMISSAO

					If lLocProc .Or. lCusUnif
						cQuery+= " UNION ALL "
						cQuery+= "SELECT SUM(CASE WHEN SD3.D3_TM < '501' THEN 0 ELSE SD3.D3_QUANT END) AS ENTQTD,
						cQuery+= "SUM(CASE WHEN SD3.D3_TM < '501' THEN SD3.D3_QUANT ELSE 0 END) AS SDAQTD,"
						cQuery+= "SUM(CASE WHEN SD3.D3_TM < '501' THEN 0 ELSE SD3.D3_QTSEGUM END) AS ENTQTS,"
						cQuery+= "SUM(CASE WHEN SD3.D3_TM < '501' THEN SD3.D3_QTSEGUM ELSE 0 END) AS SDAQTS,"
						cQuery+= "SUM(CASE WHEN SD3.D3_TM < '501' THEN 0 ELSE SD3.D3_CUSTO"+Alltrim(Str(mv_par10))+" END) AS ENTCUST,"
						cQuery+= "SUM(CASE WHEN SD3.D3_TM < '501' THEN SD3.D3_CUSTO"+AllTrim(Str(mv_par10))+" ELSE 0 END) AS SDACUST, "
						cQuery+= "SD3.D3_EMISSAO AS DATA "
						cQuery+= "FROM "+RetSqlName("SD3")+" SD3 "
						cQuery+= "WHERE SD3.D_E_L_E_T_ <> '*' AND "
						cQuery+= "SD3.D3_FILIAL = '"+xFilial("SD3")+"'"
						cQuery+= " AND SD3.D3_COD = '"+SB1->B1_COD+"' "
						cQuery+= " AND SD3.D3_EMISSAO >= '"+Dtos(mv_par05)+"' AND SD3.D3_EMISSAO <= '"+dtos(mv_par06)+"'"
						cQuery+= " AND SD3.D3_ESTORNO <> 'S'"
						cQuery+= " AND SUBSTRING(SD3.D3_CF,3,1) = '3'"
						cQuery+= " GROUP BY D3_EMISSAO
					EndIf

					cQuery+= " UNION ALL "
					cQuery+= "SELECT SUM(CASE SD2.D2_TIPO WHEN 'D' THEN -SD2.D2_QUANT ELSE 0 END) AS ENTQTD,"
					cQuery+= "SUM(CASE SD2.D2_TIPO WHEN 'D' THEN 0 ELSE SD2.D2_QUANT END) AS SDAQTD,"
					cQuery+= "SUM(CASE SD2.D2_TIPO WHEN 'D' THEN -SD2.D2_QTSEGUM ELSE 0 END) AS ENTQTS,"
					cQuery+= "SUM(CASE SD2.D2_TIPO WHEN 'D' THEN 0 ELSE SD2.D2_QTSEGUM END) AS SDAQTS,"
					cQuery+= "SUM(CASE SD2.D2_TIPO WHEN 'D' THEN -SD2.D2_CUSTO"+Alltrim(Str(mv_par10))+" ELSE 0 END) AS ENTCUST,"
					cQuery+= "SUM(CASE SD2.D2_TIPO WHEN 'D' THEN 0 ELSE SD2.D2_CUSTO"+Alltrim(Str(mv_par10))+" END) AS SDACUST,"
					cQuery+= "SD2.D2_EMISSAO AS DATA "
					cQuery+= " FROM "+RetSqlName("SD2")+" SD2 JOIN "+RetSqlName("SF4")+" SF4 ON "
					cQuery+= "SF4.D_E_L_E_T_ <> '*' AND "
					cQuery+= "SF4.F4_FILIAL = '"+xFilial("SF4")+"' AND "
					cQuery+= "SF4.F4_CODIGO = SD2.D2_TES AND "
					cQuery+= "SF4.F4_ESTOQUE = 'S' "
					cQuery+= "WHERE SD2.D_E_L_E_T_ <> '*' AND "
					cQuery+= "SD2.D2_FILIAL = '"+xFilial("SD2")+"'"
					cQuery+= " AND SD2.D2_COD = '"+SB1->B1_COD+"' "
					cQuery+= " AND SD2.D2_EMISSAO >= '"+Dtos(mv_par05)+"' AND SD2.D2_EMISSAO <= '"+dtos(mv_par06)+"'"
					cQuery+= " AND SD2.D2_ORIGLAN <> 'LF'"
					If !lCusUnif
						cQuery += " AND SD2.D2_LOCAL = '"+MV_PAR08+"'"
					EndIf
					If !(cPaisLoc $ "BRA|CHI")
						cRemito:= CriaVar("D2_REMITO")
						cQuery += " AND D2_REMITO = '"+cRemito+"'"
						cQuery += " AND SD2.D2_TPDCENV IN('1','A')"
					EndIf
					cQuery+= " GROUP BY D2_EMISSAO"
					cQuery+= " ORDER BY DATA"
					cQuery:= ChangeQuery(cQuery)
					cAliasRel := GetNextAlias()
					dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasRel,.T.,.T.)

					TCSetField(cAliasRel, "DATA", "D")

					(cAliasRel)->(DbGoTop())
					If (cAliasRel)->(Eof())
						UpdFileLog(nHdlLog, Chr(13) + Chr(10) + '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Não existe movimentação para este produto: ' +  _cProduto + " / " + _cLocal + Chr(13) + Chr(10))	    					
					EndIf

					While !(cAliasRel)->(Eof())

						dCntData  := (cAliasRel)->DATA
						nEntPriUM += (cAliasRel)->ENTQTD
						nEntraVal += (cAliasRel)->ENTCUST
						nSaiPriUM += (cAliasRel)->SDAQTD
						nSaidaVal += (cAliasRel)->SDACUST

						//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
						//³ Subtrai as saidas porque vem sempre com valor positivo da query  ³
						//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

						aSalAtu[1]:= aSalAtu[1] + (cAliasRel)->ENTQTD - (cAliasRel)->SDAQTD
						aSalAtu[mv_par10+1] := aSalAtu[mv_par10+1] + (cAliasRel)->ENTCUST - (cAliasRel)->SDACUST
						aSalAtu[7]          := aSalAtu[7] + (cAliasRel)->ENTQTS - (cAliasRel)->SDAQTS

						(cAliasRel)->(DbSkip())

						If dCntData <> (cAliasRel)->DATA
							nEntPriUM := 0
							nEntraVal := 0
							nSaiPriUM := 0
							nSaidaVal := 0
						EndIf
					End

					(cAliasRel)->(DbCloseArea())
				Endif

				dbSelectArea("SB1")
			EndIf
		EndIf
	Next nForFilial

	cFilAnt := cFilBack

	dbSelectArea("SB1")
	dbSetOrder(1)

	dbSelectArea("SB2")
	dbSetOrder(1)

	dbSelectArea("SD1")
	If lCusUnif
		dbClearFilter()
		RetIndex("SD1")
		If File(cTrbSD1+OrdBagExt())
			Ferase(cTrbSD1+OrdBagExt())
		EndIf
	EndIf
	dbSetOrder(1)

	dbSelectArea("SD2")
	If lCusUnif
		dbClearFilter()
		RetIndex("SD2")
		If File(cTrbSD2+OrdBagExt())
			Ferase(cTrbSD2+OrdBagExt())
		EndIf
	EndIf
	dbSetOrder(1)

	dbSelectArea("SD3")
	If lLocProc .Or. lCusUnif
		dbClearFilter()
		RetIndex("SD3")
		If File(cTrbSD3+OrdBagExt())
			Ferase(cTrbSD3+OrdBagExt())
		EndIf
	EndIf
	dbSetOrder(1)

Return aSalAtu[mv_par10+1]

/*---------------------------------------------------------------------
TODO 			Descrição Verifica se há integração com o modulo SigaMNT/NG 
@author 		MatR420
@since 			
---------------------------------------------------------------------*/
Static Function MTR420IsMNT()

	Local aArea
	Local aAreaSB1
	Local aProdsMNT := {}
	Local nX := 0
	Local lIntegrMNT := .F.

	//Esta funcao encontra-se no modulo Manutencao de Ativos (NGUTIL05.PRX), e retorna os produtos (pode ser MAIS de UM), dos parametros de
	//Manutencao - "M" (MV_PRODMNT) / Terceiro - "T" (MV_PRODTER) / ou Ambos - "*" ou em branco
	If FindFunction ("NGProdMNT")
		aProdsMNT := aClone(NGProdMNT("M"))
		Endif

	If Len(aProdsMNT) > 0
		aArea	 := GetArea()
		aAreaSB1 := SB1->(GetArea())

		SB1->(dbSelectArea( "SB1" ))
		SB1->(dbSetOrder(1))
		For nX := 1 To Len(aProdsMNT)
			If SB1->(dbSeek( xFilial("SB1") + aProdsMNT[nX] ))
				lIntegrMNT := .T.
				Exit
			EndIf

		Next nX

		RestArea(aAreaSB1)
		RestArea(aArea)
	EndIf

Return( lIntegrMNT )
