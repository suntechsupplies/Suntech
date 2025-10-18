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
	Local cQuery        := ''
	Local cAliasSD3     := GetNextAlias()
	Local aTamSX3     	:= {}
	Local xConteudo   	:= Nil 
	Local nCntFor       := 0
	Local _nAjuste		:= 0
	Local _nQmov  		:= 0
	Local _nVmov 		:= 0
	Local _nQini		:= 0
	Local _nVini		:= 0
	Local _nQatu        := 0
	Local _nVatu        := 0
	local _nVAtuNew     := 0
	Local dUltFech	    := GetMV("MV_ULMES")
											 

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

				_nAjuste := 0
				_nQmov   := 0
				_nVmov 	 := 0
				_nQini	 := 0
				_nVini	 := 0
				_nQatu   := 0
				_nVatu   := 0
				cQuery   := ''
				_nVAtuNew:= 0

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
									
									//Verifica se há conexão em aberto, caso haja feche.
									IF Select(cAliasSD3) > 0
										dbSelectArea(cAliasSD3)
										(cAliasSD3)->(dbCloseArea())
									EndIf

									//Verifica o Saldo Inicial do Produto										
									DbSelectArea("SB9")
									SB9->(DbSetOrder(1)) //FILIAL+CODIGO+LOCAL
									If SB9->(DbSeek(xFilial("SB9")+PadR(aMsExcAuto[1][2],15)+aMsExcAuto[2][2]+DTOS(dUltFech)))

										_nQini := SB9->B9_QINI
										_nVini := SB9->B9_VINI1

									EndIf

									//Verifica a movimentação do Produto
									cQuery += "SELECT D3_FILIAL, D3_TM, D3_COD, D3_QUANT, D3_CUSTO1, D3_CF, D3_LOCAL, D3_DOC, D3_EMISSAO "
									cQuery += "FROM " + RetSQLName( 'SD3' ) + " SD3010 "
									cQuery += "WHERE D3_COD    = '" + PadR(aMsExcAuto[1][2],15) + "' "
									cQuery += "AND D3_FILIAL   = '" + xFilial("SD3")            + "' "
									cQuery += "AND D3_LOCAL    = '" + aMsExcAuto[2][2]          + "' " 
									cQuery += "AND D3_EMISSAO  > '" + DTOS(dUltFech)            + "' "
									cQuery += "AND D3_EMISSAO  <='" + DTOS(dDataBase)           + "' "
									cQuery += "AND D3_ESTORNO  <>'S' "                          
									cQuery += "AND D_E_L_E_T_ <> '*' "                           
									cQuery += "UNION All "
									cQuery += "SELECT D1_FILIAL, D1_TES, D1_COD, D1_QUANT, D1_CUSTO, D1_CF, D1_LOCAL, D1_DOC, D1_EMISSAO "
									cQuery += "FROM " + RetSQLName( 'SD1' ) + " SD1010 "
									cQuery += "WHERE D1_COD    = '" + PadR(aMsExcAuto[1][2],15) + "' "
									cQuery += "AND D1_FILIAL   = '" + xFilial("SD1")            + "' "
									cQuery += "AND D1_LOCAL    = '" + aMsExcAuto[2][2]          + "' "
									cQuery += "AND D1_TES IN (SELECT F4_CODIGO FROM SF4010 WHERE F4_ESTOQUE = 'S' AND D_E_L_E_T_ <> '*') "
									cQuery += "AND ((D1_EMISSAO > '"  + DTOS(dUltFech)          + "' AND D1_DTDIGIT = '') OR  D1_DTDIGIT >  '" + DTOS(dUltFech)  + "')"
									cQuery += "AND ((D1_EMISSAO <= '" + DTOS(dDataBase)         + "' AND D1_DTDIGIT = '') OR (D1_DTDIGIT <= '" + DTOS(dDataBase) + "' AND D1_DTDIGIT <> ''))"
									cQuery += "AND D_E_L_E_T_ <> '*' "
									cQuery += "UNION All "
									cQuery += "SELECT D2_FILIAL, D2_TES, D2_COD, D2_QUANT, D2_CUSTO1, D2_CF, D2_LOCAL, D2_DOC, D2_EMISSAO "
									cQuery += "FROM " + RetSQLName( 'SD2' ) + " SD2010 "
									cQuery += "WHERE D2_COD    = '" + PadR(aMsExcAuto[1][2],15) + "' "
									cQuery += "AND D2_FILIAL   = '" + xFilial("SD2")            + "' "
									cQuery += "AND D2_LOCAL    = '" + aMsExcAuto[2][2]          + "' "
									cQuery += "AND D2_TES IN (SELECT F4_CODIGO FROM SF4010 WHERE F4_ESTOQUE = 'S' AND D_E_L_E_T_ <> '*') "
									cQuery += "AND ((D2_EMISSAO > '"  + DTOS(dUltFech)          + "' AND D2_DTDIGIT = '') OR  D2_DTDIGIT >  '" + DTOS(dUltFech)  + "')"
									cQuery += "AND ((D2_EMISSAO <= '" + DTOS(dDataBase)         + "' AND D2_DTDIGIT = '') OR (D2_DTDIGIT <= '" + DTOS(dDataBase) + "' AND D2_DTDIGIT <> ''))"
									cQuery += "AND D_E_L_E_T_ <> '*'                                 "

									cQuery := ChangeQuery( cQuery )
									dbUseArea( .T., "TOPCONN", TcGenQry( ,, cQuery ), cAliasSD3, .T., .T. )

									DbSelectArea(cAliasSD3)

									If !(cAliasSD3)->(EoF())

										While !Eof()

											_nQmov := _nQmov + IIF((SUBSTR((cAliasSD3)->D3_CF, 1, 2) =='RE' .OR. VAL(SUBSTR((cAliasSD3)->D3_CF, 1, 1)) >= 5), (cAliasSD3)->D3_QUANT  * -1, (cAliasSD3)->D3_QUANT) 
											_nVmov := _nVmov + IIF((SUBSTR((cAliasSD3)->D3_CF, 1, 2) =='RE' .OR. VAL(SUBSTR((cAliasSD3)->D3_CF, 1, 1)) >= 5), (cAliasSD3)->D3_CUSTO1 * -1, (cAliasSD3)->D3_CUSTO1)

											dbSkip()
										End

									EndIf

									//---------------------------------------------------------------------
									//	Calculo do valor e quantidades atuais para o período
									//---------------------------------------------------------------------

									_nQatu = _nQini + _nQmov
									_nVatu = _nVini + _nVmov

									//---------------------------------------------------------------------
									//	Calculo do valor a ajustar no período
									//---------------------------------------------------------------------

									_nVAtuNew := aMsExcAuto[3,2] * _nQatu 										
									_nAjuste  := _nVAtuNew - _nVatu

									//-------------------------------------------------
								
									If _nVatu <> _nVAtuNew
											If _nAjuste <> 0 .AND. _nQatu > 0		//Valor do CSV = Valor das Movimentações da SD3

											If (_nVAtuNew > _nVatu)
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
													aadd(ExpA1,{"D3_TM"			,cCodMov									,Nil})
													aadd(ExpA1,{"D3_COD"		,SB1->B1_COD								,Nil})
													aadd(ExpA1,{"D3_UM"			,SB1->B1_UM									,Nil})
													aadd(ExpA1,{"D3_LOCAL"		,AllTrim(aMsExcAuto[02][02])				,Nil})
													aadd(ExpA1,{"D3_QUANT"		,0							                ,Nil})
													aadd(ExpA1,{"D3_CUSTO1"		,IIF(_nAjuste < 0, _nAjuste * -1, _nAjuste) ,Nil})
													aadd(ExpA1,{"D3_EMISSAO"	,dDataBase									,Nil})
													aadd(ExpA1,{"D3_GRUPO"		,SB1->B1_GRUPO								,Nil})
													aadd(ExpA1,{"D3_CONTA"		,SB1->B1_CONTA								,Nil})

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
										ElseIf _nQatu == 0
											UpdFileLog(nHdlLog, Chr(13) + Chr(10) + '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Saldo Atual do Produto : ' + Alltrim(aMsExcAuto[1][2]) + " | Local : " + Alltrim(aMsExcAuto[2][2]) + " | Saldo Atual do Produto Igual a Zero  " + Chr(13) + Chr(10))
										Endif										
									Else
										UpdFileLog(nHdlLog, Chr(13) + Chr(10) + '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Inconsistência na Leitura dos dados. Detalhe do Erro : Custo do Produto : ' + Alltrim(aMsExcAuto[1][2]) + " | Local : " + Alltrim(aMsExcAuto[2][2]) + " | Custo Atual do Produto Igual ao calculado pela rotina  " + Chr(13) + Chr(10))
									Endif
								EndIf
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
