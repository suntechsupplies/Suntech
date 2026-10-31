#include "protheus.ch"
#INCLUDE 'APWIZARD.CH'

/*---------------------------------------------------------------------
{Protheus.doc} MovInterno
@type User Function
@description Importa quantidades e custos por CSV e ajusta o estoque via MATA240.
---------------------------------------------------------------------*/
User Function MovInterno()

	Local oWizard    := NIL
	Local lFinish    := .F.
	Local cHeader    := ''
	Local cMessage   := ''
	Local cText      := ''
	Local cTitleProg := 'Atualização de quantidade e custo por CSV'

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

	// -----------------------------------------------------------------------------
	// Painel principal
	// -----------------------------------------------------------------------------
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
	cHeader  := 'Atualização de estoque por CSV'
	cMessage := 'Assistente de importação de quantidade e custo'
	cText    := 'Esta rotina ajusta a quantidade e o custo unitário dos produtos/locais informados no CSV, usando '
	cText    += 'movimentos internos da MATA240. A quantidade e o custo informados na planilha serão os alvos.' + Chr(10)+Chr(13)
	cText    += 'O arquivo será validado antes do início dos movimentos. Confira o ambiente, a filial e os dados '
	cText    += 'do CSV antes de confirmar o processamento.'

	DEFINE	WIZARD	oWizard ;
	TITLE	'Movimentação interna por CSV';
	HEADER	cHeader;
	MESSAGE	cMessage;
	TEXT	cText;
	NEXT 	{|| .T.};
	FINISH 	{|| .F.}

	// -----------------------------------------------------------------------------
	// Selecao do arquivo CSV
	// -----------------------------------------------------------------------------
	cMessage := 'Selecione o arquivo CSV com as quantidades e os custos desejados.'
	CREATE	PANEL 	oWizard  ;
	HEADER 	cHeader;
	MESSAGE	cMessage;
	BACK	{|| .T.} ;
	NEXT	{|| !Empty(cFileImp) }; 
	FINISH	{|| .F.}

	cTextP2	:= 'Restrições do arquivo:' + Chr(10)+Chr(13)
	cTextP2	+= Chr(10)+Chr(13)
	cTextP2	+= 'A primeira linha deve conter uma vez cada campo: D3_COD;D3_LOCAL;D3_QUANT;D3_CUSTO1. A ordem pode variar.' + Chr(10)+Chr(13)
	cTextP2	+= Chr(10)+Chr(13)
	cTextP2	+= 'Use ponto e vírgula como separador e vírgula ou ponto nos decimais. Não use aspas nem ponto e vírgula dentro dos valores.' + Chr(10)+Chr(13)
	cTextP2	+= Chr(10)+Chr(13)
	cTextP2	+= 'Informe quantidade e custo unitário não negativos. A última linha deve conter apenas *. Chaves repetidas com dados diferentes serão rejeitadas.'

	@ 012, 010 Say oTextP2 PROMPT cTextP2 Size 228, 094 Of oWizard:oMPanel[2] FONT oArial10 Pixel
	@ 085, 005 GROUP To 113, 245 PROMPT "Local e nome do arquivo:" OF oWizard:oMPanel[2] Pixel
	@ 095, 020 MsGet oFileCSV Var cFileImp Valid( If( File(cFileImp), .T., ( Alert("O arquivo informado para importação não existe!") ,.F.) ) .Or. Empty(cFileImp) ) Size 212, 010 Of oWizard:oMPanel[2] F3 "DIR" Pixel

	// -----------------------------------------------------------------------------
	// Rotina de processamento
	// -----------------------------------------------------------------------------
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

cTextP3 :=  'Rotina fixa: MATA240 - movimentos internos simples.' + Chr(10)+Chr(13)
cTextP3 +=  'O CSV define a quantidade final e o custo unitário final. A rotina calcula as diferenças e registra os movimentos necessários.'

@ 012, 010 Say oTextP3  PROMPT cTextP3 Size 228, 094 Of oWizard:oMPanel[3] FONT oArial10 Pixel
@ 085, 005 GROUP To 113, 245 PROMPT "Rotina de processamento" OF oWizard:oMPanel[3] PIXEL
@ 095, 020 MsGet oNameFunc Var cNameFunc When .f. Size 212, 010 Of oWizard:oMPanel[3] Pixel


// -----------------------------------------------------------------------------
// Conferencia e impacto
// -----------------------------------------------------------------------------
cMessage := 'Parâmetros para processamento...'
CREATE	PANEL 	oWizard  ;
	HEADER 	cHeader;
	MESSAGE	cMessage;
	BACK	{|| .T.} ;
	NEXT	{|| .T. };
	FINISH	{|| .F.}

@ 010, 005 GROUP To 055, 200 PROMPT 'Conferência antes de processar' Of oWizard:oMPanel[4] Pixel
@ 020, 010 Say 'A rotina valida cabeçalho, colunas, valores e duplicidades antes de gerar qualquer movimento.' Size 190, 030 Of oWizard:oMPanel[4] Pixel
@ 060, 005 GROUP To 105, 200 PROMPT 'Impacto da importação' Of oWizard:oMPanel[4] Pixel
@ 070, 010 Say 'Cada linha pode gerar movimento de quantidade e ajuste de valor na filial ativa.' Size 190, 030 Of oWizard:oMPanel[4] Pixel

// -----------------------------------------------------------------------------
// Confirmacao do processamento
// -----------------------------------------------------------------------------
cMessage := 'Iniciar o processamento...'
CREATE	PANEL 	oWizard  ;
	HEADER 	cHeader;
	MESSAGE	cMessage;
	BACK	{|| .T.} ;
	NEXT	{|| .F.};
	FINISH	{|| lFinish := .T.}

cFileLog := CsvLogPath(cFileImp)

TSay():New(010, 005, {|| 'Será criado um LOG ao lado do CSV com o resultado de cada produto/local processado.' },;
	oWizard:oMPanel[5],, oCouri11,,,, .T.,,, 200, 50)

TSay():New(045, 005, {|| 'Clique em "Finalizar" para validar o CSV e iniciar a atualização dos custos.' },;
	oWizard:oMPanel[5],, oCouri11,,,, .T.,,, 200, 50)

ACTIVATE WIZARD oWizard Center

// -----------------------------------------------------------------------------
// Inicio do processamento
// -----------------------------------------------------------------------------
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
	Local nPosCod      	:= 0
	Local nPosLocal    	:= 0
	Local nPosQtd      	:= 0
	Local nPosCusto    	:= 0
	Local cApropri     	:= ""
	Local nQtdDesejada := 0
	Local nAjusteQtd   := 0
	Local lErroProc    := .F.
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
	Private lAutoErrNoFile := .T.

	//---------------------------------------------------------------------
	// Cria o arquivo de log
	//---------------------------------------------------------------------
	cFileLog := CsvLogPath(cFileImp)
	nHdlLog  := MSFCreate(cFileLog,0)

	If nHdlLog < 0

		Aviso('ATENÇÃO', 'PROBLEMAS NA CRIAÇÃO DO ARQUIVO DE LOG DE INCONSISTÊNCIAS!' + Chr(10) + Chr(13) + 'Código do erro: ' + StrZero(FError(),10), {'OK'}, 3)

	Else
		//---------------------------------------------------------------------
		//--Atualiza arquivo de LOG:
		//---------------------------------------------------------------------
		UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] INICIANDO PROCESSO DE IMPORTAÇÃO' + Chr(13) + Chr(10))

		If !ValidaCsvCustos(cFileImp, nHdlLog)
			UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] PROCESSAMENTO CANCELADO: corrija o CSV antes de tentar novamente.' + Chr(13) + Chr(10))
			FClose(nHdlLog)
			ShowLog(cFileLog)
			Return .F.
		EndIf

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

				xBuffer	:= FT_FREADLN()

				_nAjuste := 0
				_nQmov   := 0
				_nVmov 	 := 0
				_nQini	 := 0
				_nVini	 := 0
				_nQatu   := 0
				_nVatu   := 0
				nQtdDesejada := 0
				nAjusteQtd := 0
				lErroProc := .F.
				cQuery   := ''
				_nVAtuNew:= 0

				nLinha++
				aDataIte := {}
				If nLinha == 1 
					//---------------------------------------------------------------------
					//-- Armazena em memoria a 1a. linha (Cabecalho).
					//---------------------------------------------------------------------
					aDataCab := aBIToken(Upper(AllTrim(xBuffer)), ';',.F.)
				Else		

					If !EMPTY(STRTRAN(xBuffer, ";", ""))
						aDataIte := aBIToken(xBuffer, ';',.F.)
					EndIf

					If Len(aDataIte) > 0
						If Upper(Alltrim(aDataIte[1])) <> "*"
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
										UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] Campo indicado no cabeçalho do arquivo CSV não conforme' + Chr(13) + Chr(10) + "Obrigatório: D3_COD;D3_LOCAL;D3_QUANT;D3_CUSTO1" + Chr(13) + Chr(10) )
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

								nPosCod   := aScan(aMsExcAuto, {|aCampo| Upper(AllTrim(aCampo[1])) == "D3_COD"})
								nPosLocal := aScan(aMsExcAuto, {|aCampo| Upper(AllTrim(aCampo[1])) == "D3_LOCAL"})
								nPosQtd   := aScan(aMsExcAuto, {|aCampo| Upper(AllTrim(aCampo[1])) == "D3_QUANT"})
								nPosCusto := aScan(aMsExcAuto, {|aCampo| Upper(AllTrim(aCampo[1])) == "D3_CUSTO1"})
								nQtdDesejada := aMsExcAuto[nPosQtd][2]

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
									If SB9->(DbSeek(xFilial("SB9")+PadR(aMsExcAuto[nPosCod][2],15)+aMsExcAuto[nPosLocal][2]+DTOS(dUltFech)))

										_nQini := SB9->B9_QINI
										_nVini := SB9->B9_VINI1
									Else
										UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Saldo de fechamento não encontrado na SB9 para produto ' + AllTrim(aMsExcAuto[nPosCod][2]) + ' | Local: ' + AllTrim(aMsExcAuto[nPosLocal][2]) + '. Linha ignorada.' + Chr(13) + Chr(10))
										IncProc()
										FT_FSKIP()
										Loop

									EndIf

									//Verifica a movimentação do Produto
									cQuery += "SELECT D3_FILIAL, D3_TM, D3_COD, D3_QUANT, D3_CUSTO1, D3_CF, D3_LOCAL, D3_DOC, D3_EMISSAO "
									cQuery += "FROM " + RetSQLName( 'SD3' ) + " SD3010 "
									cQuery += "WHERE D3_COD    = '" + PadR(aMsExcAuto[nPosCod][2],15) + "' "
									cQuery += "AND D3_FILIAL   = '" + xFilial("SD3")            + "' "
									cQuery += "AND D3_LOCAL    = '" + aMsExcAuto[nPosLocal][2]  + "' " 
									cQuery += "AND D3_EMISSAO  > '" + DTOS(dUltFech)            + "' "
									cQuery += "AND D3_EMISSAO  <='" + DTOS(dDataBase)           + "' "
									cQuery += "AND D3_ESTORNO  <>'S' "                          
									cQuery += "AND D_E_L_E_T_ <> '*' "                           
									cQuery += "UNION All "
									cQuery += "SELECT D1_FILIAL, D1_TES, D1_COD, D1_QUANT, D1_CUSTO, D1_CF, D1_LOCAL, D1_DOC, D1_EMISSAO "
									cQuery += "FROM " + RetSQLName( 'SD1' ) + " SD1010 "
									cQuery += "WHERE D1_COD    = '" + PadR(aMsExcAuto[nPosCod][2],15) + "' "
									cQuery += "AND D1_FILIAL   = '" + xFilial("SD1")            + "' "
									cQuery += "AND D1_LOCAL    = '" + aMsExcAuto[nPosLocal][2]  + "' "
									cQuery += "AND D1_TES IN (SELECT F4_CODIGO FROM SF4010 WHERE F4_ESTOQUE = 'S' AND D_E_L_E_T_ <> '*') "
									cQuery += "AND ((D1_EMISSAO > '"  + DTOS(dUltFech)          + "' AND D1_DTDIGIT = '') OR  D1_DTDIGIT >  '" + DTOS(dUltFech)  + "')"
									cQuery += "AND ((D1_EMISSAO <= '" + DTOS(dDataBase)         + "' AND D1_DTDIGIT = '') OR (D1_DTDIGIT <= '" + DTOS(dDataBase) + "' AND D1_DTDIGIT <> ''))"
									cQuery += "AND D_E_L_E_T_ <> '*' "
									cQuery += "UNION All "
									cQuery += "SELECT D2_FILIAL, D2_TES, D2_COD, D2_QUANT, D2_CUSTO1, D2_CF, D2_LOCAL, D2_DOC, D2_EMISSAO "
									cQuery += "FROM " + RetSQLName( 'SD2' ) + " SD2010 "
									cQuery += "WHERE D2_COD    = '" + PadR(aMsExcAuto[nPosCod][2],15) + "' "
									cQuery += "AND D2_FILIAL   = '" + xFilial("SD2")            + "' "
									cQuery += "AND D2_LOCAL    = '" + aMsExcAuto[nPosLocal][2]  + "' "
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

									_nVAtuNew := aMsExcAuto[nPosCusto][2] * _nQatu 									
									_nAjuste  := _nVAtuNew - _nVatu

									//-------------------------------------------------
								
										If _nVatu <> _nVAtuNew
											If _nAjuste <> 0		//Valor do CSV = Valor das Movimentações da SD3
											SB1->(DbSetOrder(1))
											cApropri := ""
											If SB1->(DbSeek(FWxFilial("SB1") + avKey(aMsExcAuto[nPosCod][2], "B1_COD")))
												cApropri := SB1->B1_APROPRI
											Else
												lErroProc := .T.
											EndIf

											If (_nVAtuNew > _nVatu)
												If cApropri == "D"
													cCodMov := "100" 				//Aumenta o custo no sistema. Produtos com Apropriação Direta
												Else
													cCodMov := "099" 				//Aumenta o custo no sistema. Produtos com Apropriação Indireta
												Endif
											Else
												If cApropri == "D"
													cCodMov := "600" 				//Diminui o custo no sistema. Produtos com Apropriação Direta
												Else
													cCodMov := "599" 				//Diminui o custo no sistema. Produtos com Apropriação Indireta
												Endif
											EndIf

											SB1->( DbSetOrder(1) )	//B1_FILIAL + B1_COD
											If SB1->( DbSeek( FWxFilial("SB1") + avKey(aMsExcAuto[nPosCod][2], "B1_COD") ) )
												If ALLTRIM(aMsExcAuto[nPosCod][2]) <> "*"
													ExpA1 := {}
													aadd(ExpA1,{"D3_TM"			,cCodMov									,Nil})
													aadd(ExpA1,{"D3_COD"		,SB1->B1_COD								,Nil})
													aadd(ExpA1,{"D3_UM"			,SB1->B1_UM									,Nil})
														aadd(ExpA1,{"D3_LOCAL"		,AllTrim(aMsExcAuto[nPosLocal][2])				,Nil})
													aadd(ExpA1,{"D3_QUANT"		,0							                ,Nil})
													aadd(ExpA1,{"D3_CUSTO1"		,IIF(_nAjuste < 0, _nAjuste * -1, _nAjuste) ,Nil})
													aadd(ExpA1,{"D3_EMISSAO"	,dDataBase									,Nil})
													aadd(ExpA1,{"D3_GRUPO"		,SB1->B1_GRUPO								,Nil})
													aadd(ExpA1,{"D3_CONTA"		,SB1->B1_CONTA								,Nil})

													MSExecAuto({|x,y| mata240(x,y)},ExpA1,3)

													If lMsErroAuto 													
														DisarmTransaction()													
															lErroProc := .T.
														cErrAuto := CsvLogAuto()
													UpdFileLog(nHdlLog, Chr(13) + Chr(10) + '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Produto: ' + AllTrim(aMsExcAuto[nPosCod][2]) + ' | Local: ' + AllTrim(aMsExcAuto[nPosLocal][2]) + '] Inconsistência na atualização dos dados. Detalhe do Erro: ' + cErrAuto + Chr(13) + Chr(10))
													Else
														//******************************************************************************
														// Grava o log de inclusão realizada com sucesso
														//******************************************************************************
														UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Produto: ' + AllTrim(aMsExcAuto[nPosCod][2]) + ' | Local: ' + AllTrim(aMsExcAuto[nPosLocal][2]) + '] Atualizado com sucesso.' + Chr(13) + Chr(10))
													EndIf
												Endif
													Else
														lErroProc := .T.
												UpdFileLog(nHdlLog, Chr(13) + Chr(10) + '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Produto não encontrado: ' + AllTrim(aMsExcAuto[nPosCod][2]) + ' | Local: ' + AllTrim(aMsExcAuto[nPosLocal][2]) + Chr(13) + Chr(10))
											Endif
										ElseIf _nQatu == 0
											UpdFileLog(nHdlLog, Chr(13) + Chr(10) + '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Saldo atual igual a zero para produto ' + AllTrim(aMsExcAuto[nPosCod][2]) + ' | Local: ' + AllTrim(aMsExcAuto[nPosLocal][2]) + Chr(13) + Chr(10))
										ElseIf _nQatu < 0
											UpdFileLog(nHdlLog, Chr(13) + Chr(10) + '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Saldo atual negativo para produto ' + AllTrim(aMsExcAuto[nPosCod][2]) + ' | Local: ' + AllTrim(aMsExcAuto[nPosLocal][2]) + '. Ajuste de custo não aplicado.' + Chr(13) + Chr(10))
										Endif										
									Else
									UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Valor do estoque já corresponde ao custo unitário desejado.' + Chr(13) + Chr(10))
									Endif

									nAjusteQtd := nQtdDesejada - _nQatu
									If lErroProc .And. nAjusteQtd <> 0
										UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Ajuste de quantidade não executado porque houve falha na etapa de valor.' + Chr(13) + Chr(10))
									ElseIf _nQatu < 0
										UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Saldo atual negativo; ajuste de quantidade não executado.' + Chr(13) + Chr(10))
									ElseIf nAjusteQtd <> 0
										SB1->(DbSetOrder(1))
										If SB1->(DbSeek(FWxFilial("SB1") + avKey(aMsExcAuto[nPosCod][2], "B1_COD")))
											ExpA1 := {}
											cCodMov := IIf(nAjusteQtd > 0, "103", "503")
											AAdd(ExpA1, {"D3_TM", cCodMov, Nil})
											AAdd(ExpA1, {"D3_COD", SB1->B1_COD, Nil})
											AAdd(ExpA1, {"D3_UM", SB1->B1_UM, Nil})
											AAdd(ExpA1, {"D3_LOCAL", AllTrim(aMsExcAuto[nPosLocal][2]), Nil})
											AAdd(ExpA1, {"D3_QUANT", Abs(nAjusteQtd), Nil})
											AAdd(ExpA1, {"D3_CUSTO1", Abs(nAjusteQtd) * aMsExcAuto[nPosCusto][2], Nil})
											AAdd(ExpA1, {"D3_EMISSAO", dDataBase, Nil})
											AAdd(ExpA1, {"D3_GRUPO", SB1->B1_GRUPO, Nil})
											AAdd(ExpA1, {"D3_CONTA", SB1->B1_CONTA, Nil})

											lMsErroAuto := .F.
											MSExecAuto({|x,y| mata240(x,y)}, ExpA1, 3)

											If lMsErroAuto
												DisarmTransaction()
												cErrAuto := CsvLogAuto()
												UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Erro ao ajustar quantidade para produto ' + AllTrim(aMsExcAuto[nPosCod][2]) + ' | Local: ' + AllTrim(aMsExcAuto[nPosLocal][2]) + '. Detalhe: ' + cErrAuto + Chr(13) + Chr(10))
											Else
											UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Quantidade ajustada para ' + cValToChar(nQtdDesejada) + ' em produto ' + AllTrim(aMsExcAuto[nPosCod][2]) + ' | Local: ' + AllTrim(aMsExcAuto[nPosLocal][2]) + Chr(13) + Chr(10))
											EndIf
										Else
											UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Produto não encontrado para ajuste de quantidade: ' + AllTrim(aMsExcAuto[nPosCod][2]) + Chr(13) + Chr(10))
										EndIf
									Else
										UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Quantidade já corresponde ao valor informado.' + Chr(13) + Chr(10))
									EndIf
								EndIf
							Else
								UpdFileLog(nHdlLog, Chr(13) + Chr(10) + '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Quantidade de colunas diferente do cabeçalho.' + Chr(13) + Chr(10))
							EndIf
						Endif
					EndIf		
				EndIf

				IncProc()
				FT_FSKIP() //Pula para o próximo registro		
			EndDo
		EndIf

		If Select(cAliasSD3) > 0
			dbSelectArea(cAliasSD3)
			(cAliasSD3)->(dbCloseArea())
		EndIf

		FT_FUSE()

		//--Atualiza arquivo de LOG:
		UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] FIM DO PROCESSO DE IMPORTACAO' + Chr(13) + Chr(10))

		//--Exibe LOG de processamento:
		FClose(nHdlLog)		
		ShowLog(cFileLog)
	EndIf


Return Nil


Static Function CsvLogPath(cFileCsv)
	Local cArquivo := AllTrim(cFileCsv)
	Local nPonto := RAt(".", cArquivo)
	Local nBarra := Max(RAt("\", cArquivo), RAt("/", cArquivo))

	If nPonto > nBarra
		cArquivo := Left(cArquivo, nPonto - 1)
	EndIf

Return cArquivo + ".LOG"

Static Function ValidaCsvCustos(cFileImp, nHdlLog)
	Local aCabecalho := {}
	Local aCampos := {}
	Local aRegistros := {}
	Local cLinha := ""
	Local cCodigo := ""
	Local cLocal := ""
	Local cCusto := ""
	Local cQuantidade := ""
	Local cCaractere := ""
	Local cNumero := ""
	Local cNumeroQtd := ""
	Local nPosCod := 0
	Local nPosLocal := 0
	Local nPosQtd := 0
	Local nPosCusto := 0
	Local nLinha := 0
	Local nIndice := 0
	Local nCaractere := 0
	Local nSeparadores := 0
	Local nDigitos := 0
	Local nCusto := 0
	Local nQuantidade := 0
	Local nSeparadoresQtd := 0
	Local nDigitosQtd := 0
	Local lNumeroValido := .T.
	Local lQuantidadeValida := .T.
	Local lRodape := .F.
	Local lValido := .T.

	If !File(cFileImp)
		UpdFileLog(nHdlLog, "Arquivo CSV não encontrado: " + cFileImp + Chr(13) + Chr(10))
		Return .F.
	EndIf

	FT_FUSE(cFileImp)
	While !FT_FEOF()
		cLinha := FT_FREADLN()
		nLinha++

		If nLinha == 1
			aCabecalho := aBIToken(Upper(AllTrim(cLinha)), ";", .F.)
			nPosCod   := aScan(aCabecalho, {|cCampo| AllTrim(cCampo) == "D3_COD"})
			nPosLocal := aScan(aCabecalho, {|cCampo| AllTrim(cCampo) == "D3_LOCAL"})
			nPosQtd   := aScan(aCabecalho, {|cCampo| AllTrim(cCampo) == "D3_QUANT"})
			nPosCusto := aScan(aCabecalho, {|cCampo| AllTrim(cCampo) == "D3_CUSTO1"})

			If Len(aCabecalho) <> 4 .Or. nPosCod == 0 .Or. nPosLocal == 0 .Or. nPosQtd == 0 .Or. nPosCusto == 0
				UpdFileLog(nHdlLog, "Cabeçalho inválido. Use uma vez cada campo: D3_COD;D3_LOCAL;D3_QUANT;D3_CUSTO1." + Chr(13) + Chr(10))
				lValido := .F.
			EndIf
		ElseIf !Empty(AllTrim(cLinha))
			If lRodape
				UpdFileLog(nHdlLog, "Linha " + StrZero(nLinha, 5) + ": há conteúdo após o marcador final *." + Chr(13) + Chr(10))
				lValido := .F.
			Else
				aCampos := aBIToken(cLinha, ";", .F.)
				If Len(aCampos) == 1 .And. AllTrim(aCampos[1]) == "*"
					lRodape := .T.
				ElseIf Len(aCampos) <> Len(aCabecalho) .Or. nPosCod == 0 .Or. nPosLocal == 0 .Or. nPosQtd == 0 .Or. nPosCusto == 0
					UpdFileLog(nHdlLog, "Linha " + StrZero(nLinha, 5) + ": quantidade de colunas inválida." + Chr(13) + Chr(10))
					lValido := .F.
				Else
					cCodigo := AllTrim(aCampos[nPosCod])
					cLocal  := AllTrim(aCampos[nPosLocal])
					cQuantidade := AllTrim(aCampos[nPosQtd])
					cCusto  := AllTrim(aCampos[nPosCusto])
					cNumeroQtd := StrTran(cQuantidade, ",", ".")
					cNumero := StrTran(cCusto, ",", ".")
					nSeparadores := 0
					nDigitos := 0
					lNumeroValido := !Empty(cNumero)
					nSeparadoresQtd := 0
					nDigitosQtd := 0
					lQuantidadeValida := !Empty(cNumeroQtd)

					For nCaractere := 1 To Len(cNumero)
						cCaractere := SubStr(cNumero, nCaractere, 1)
						If cCaractere $ "0123456789"
							nDigitos++
						ElseIf cCaractere == "." .And. nSeparadores == 0
							nSeparadores++
						Else
							lNumeroValido := .F.
						EndIf
					Next

					For nCaractere := 1 To Len(cNumeroQtd)
						cCaractere := SubStr(cNumeroQtd, nCaractere, 1)
						If cCaractere $ "0123456789"
							nDigitosQtd++
						ElseIf cCaractere == "." .And. nSeparadoresQtd == 0
							nSeparadoresQtd++
						Else
							lQuantidadeValida := .F.
						EndIf
					Next

					If Empty(cCodigo) .Or. Empty(cLocal) .Or. !lNumeroValido .Or. nDigitos == 0 .Or. !lQuantidadeValida .Or. nDigitosQtd == 0
						UpdFileLog(nHdlLog, "Linha " + StrZero(nLinha, 5) + ": produto, local, quantidade ou custo inválido. Valores negativos não são aceitos." + Chr(13) + Chr(10))
						lValido := .F.
					Else
						nCusto := Val(cNumero)
						nQuantidade := Val(cNumeroQtd)
						AAdd(aRegistros, {cCodigo + Chr(1) + cLocal, nQuantidade, nCusto, nLinha})
					EndIf
				EndIf
			EndIf
		EndIf
	EndDo
	FT_FUSE()

	If nLinha < 2 .Or. !lRodape
		UpdFileLog(nHdlLog, "CSV vazio ou sem o marcador final *." + Chr(13) + Chr(10))
		lValido := .F.
	EndIf

	ASort(aRegistros,,, {|aEsq, aDir| aEsq[1] < aDir[1]})
	For nIndice := 2 To Len(aRegistros)
		If aRegistros[nIndice - 1][1] == aRegistros[nIndice][1] .And. (aRegistros[nIndice - 1][2] <> aRegistros[nIndice][2] .Or. aRegistros[nIndice - 1][3] <> aRegistros[nIndice][3])
			UpdFileLog(nHdlLog, "Linhas " + StrZero(aRegistros[nIndice - 1][4], 5) + " e " + StrZero(aRegistros[nIndice][4], 5) + ": produto/local repetido com quantidade ou custo diferentes." + Chr(13) + Chr(10))
			lValido := .F.
		EndIf
	Next

Return lValido

Static Function CsvLogAuto()
	Local aLogAuto := GetAutoGRLog()
	Local cRetorno := "Falha na rotina automática; consulte as mensagens do Protheus."
	Local nIndice := 0

	If ValType(aLogAuto) == "A" .And. Len(aLogAuto) > 0
		cRetorno := ""
		For nIndice := 1 To Len(aLogAuto)
			cRetorno += cValToChar(aLogAuto[nIndice]) + " "
		Next
	EndIf

Return cRetorno

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
