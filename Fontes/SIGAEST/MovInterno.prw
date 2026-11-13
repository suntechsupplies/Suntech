#include "protheus.ch"
#Include 'APWIZARD.CH'
#Include "PRTOPDEF.CH"

/*---------------------------------------------------------------------
{Protheus.doc} MovInterno
@type User Function
@description Importa quantidades e custos por CSV e ajusta o estoque via MATA240.
---------------------------------------------------------------------*/
User Function MovInterno()

	Local oWizard    := NIL
	Local lFinish    := .F.
	Local lResultado := .T.
	Local cHeader    := ''
	Local cMessage   := ''
	Local cMensagem  := ''
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
	Local lOrdVetX3  := .T.

	Local cFileLog   := ''
	Local cFileLogCliente := ''
	Local lLogCopiado := .F.
	Local cTmEntrada := "104"
	Local cTmSaida   := "504"
	Local oTmEntrada := Nil
	Local oTmSaida   := Nil
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

	cTextP2	:= 'Campos: D3_COD;D3_LOCAL;D3_QUANT;D3_CUSTO1 (ordem livre).' + Chr(10)+Chr(13)
	cTextP2	+= 'Separe por ;. Decimais com , ou .; sem aspas. Final: *.' + Chr(10)+Chr(13)
	cTextP2	+= 'Quantidade/custo não negativos. FALSO vira zero se quantidade for zero.' + Chr(10)+Chr(13)
	cTextP2	+= 'Duplicidade conflitante de produto/local cancela a importação.'

	@ 012, 010 Say oTextP2 PROMPT cTextP2 Size 228, 070 Of oWizard:oMPanel[2] FONT oArial10 Pixel
	@ 085, 005 GROUP To 113, 245 PROMPT "Arquivo CSV:" OF oWizard:oMPanel[2] Pixel
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
// Configuracao dos tipos de movimento
// -----------------------------------------------------------------------------
cMessage := 'Tipos de movimento para ajuste de quantidade...'
CREATE PANEL oWizard ;
	HEADER cHeader;
	MESSAGE cMessage;
	BACK {|| .T.} ;
	NEXT {|| ValidaTMs(cTmEntrada, cTmSaida)};
	FINISH {|| .F.}

@ 012, 010 Say 'Informe TMs cadastradas no SF5, com atualização de valor habilitada.' Size 228, 025 Of oWizard:oMPanel[4] FONT oArial10 Pixel
@ 045, 010 Say 'Entrada (padrão 104):' Size 095, 012 Of oWizard:oMPanel[4] Pixel
@ 045, 115 MsGet oTmEntrada Var cTmEntrada Size 070, 012 Of oWizard:oMPanel[4] Pixel
@ 070, 010 Say 'Saída (padrão 504):' Size 095, 012 Of oWizard:oMPanel[4] Pixel
@ 070, 115 MsGet oTmSaida Var cTmSaida Size 070, 012 Of oWizard:oMPanel[4] Pixel
@ 095, 010 Say 'Custo zero usa automaticamente TM 103/503 sem valor.' Size 228, 012 Of oWizard:oMPanel[4] Pixel

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

@ 010, 005 GROUP To 055, 200 PROMPT 'Conferência antes de processar' Of oWizard:oMPanel[5] Pixel
@ 020, 010 Say 'A rotina valida cabeçalho, colunas, valores e duplicidades antes de gerar qualquer movimento.' Size 190, 030 Of oWizard:oMPanel[5] Pixel
@ 060, 005 GROUP To 105, 200 PROMPT 'Impacto da importação' Of oWizard:oMPanel[5] Pixel
@ 070, 010 Say 'Cada linha pode gerar movimento de quantidade e ajuste de valor na filial ativa.' Size 190, 030 Of oWizard:oMPanel[5] Pixel

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

cFileLog := CsvLogPath()
cFileLogCliente := CsvLogClientPath(cFileLog)

TSay():New(010, 005, {|| 'O LOG será salvo na pasta temporária do Protheus e terá o caminho exibido ao final.' },;
	oWizard:oMPanel[6],, oCouri11,,,, .T.,,, 200, 50)

TSay():New(045, 005, {|| 'Clique em "Finalizar" para validar o CSV e iniciar a atualização dos custos.' },;
	oWizard:oMPanel[6],, oCouri11,,,, .T.,,, 200, 50)

ACTIVATE WIZARD oWizard Center

// -----------------------------------------------------------------------------
// Inicio do processamento
// -----------------------------------------------------------------------------
If lFinish
	//--PROCESSA A IMPORTACAO:
	lResultado := .F.
	Processa({|| lResultado := ProcImp(AllTrim(cFileImp), cFileLog, AllTrim(cNameFunc), nTipoData, lNoAcento, lOrdVetX3, AllTrim(cTmEntrada), AllTrim(cTmSaida), @cMensagem) }, cTitleProg, 'Validando CSV e processando movimentos...')
	If File(cFileLog)
		lLogCopiado := CpyS2TEx(cFileLog, cFileLogCliente, .F.)
		ShowLog(cFileLog)
	EndIf
	If !lResultado
		If Empty(cMensagem)
			cMensagem := 'Processamento não concluído. Consulte o LOG: ' + cFileLog
		EndIf
		If lLogCopiado
			cMensagem := StrTran(cMensagem, cFileLog, cFileLogCliente)
		Else
			cMensagem += ' O LOG permanece no AppServer: ' + cFileLog
		EndIf
		Return {.F., cMensagem}
	Else
		If lLogCopiado
			cMensagem := 'Processamento encerrado. LOG salvo no computador: ' + cFileLogCliente
		Else
			cMensagem := 'Processamento encerrado. LOG permanece no AppServer: ' + cFileLog
		EndIf
		Aviso(cTitleProg, cMensagem, {'OK'}, 3)
	EndIf
EndIf

Return lResultado

/*---------------------------------------------------------------------
TODO 			Descrição auto-gerada.
@author 		Carlos Eduardo Saturnino
@since 			17/12/2019
@version 		1.0
---------------------------------------------------------------------*/
Static Function ProcImp(cFileImp, cFileLog, cNameRot, nTipoData, lNoAcento, lOrdVetX3, cTmEntrada, cTmSaida, cMensagem)

	Local nHdlLog     	:= 0
	Local nLinha      	:= 0
	Local aDataCab    	:= ''
	Local aDataIte    	:= {}
	Local aMsExcAuto  	:= {}
	Local bBlockAuto  	:= {}
	Local cErrAuto    	:= ''
	Local cQuery        := ''
	Local cAliasSD3     := GetNextAlias()
	Local cAliasSB2     := GetNextAlias()
	Local aTamSX3     	:= {}
	Local xConteudo   	:= Nil 
	Local nCntFor       := 0
	Local nPosCod      	:= 0
	Local nPosLocal    	:= 0
	Local nPosQtd      	:= 0
	Local nPosCusto    	:= 0
	Local cApropri     	:= ""
	Local lMovValor     := .T.
	Local nQtdDesejada := 0
	Local nAjusteQtd   := 0
	Local nSaldoPos    := 0
	Local nLinhasSemSB9 := 0
	Local nFalhasProc := 0
	Local cErroSB9 := ""
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

	cMensagem := ""
											 

	Private lMsHelpAuto	:= .T.    // força a gravação das informações de erro em array para manipulação da gravação ao invés de gravar direto no arquivo temporário
	Private lMsErroAuto	:= .F.
	Private lAutoErrNoFile := .T.

	//---------------------------------------------------------------------
	// Cria o arquivo de log
	//---------------------------------------------------------------------
	nHdlLog  := MSFCreate(cFileLog,0)

	If nHdlLog < 0

		cMensagem := 'Não foi possível criar o LOG: ' + cFileLog + '. Código do erro: ' + StrZero(FError(), 10)
		Return .F.

	Else
		//---------------------------------------------------------------------
		//--Atualiza arquivo de LOG:
		//---------------------------------------------------------------------
		UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] INICIANDO PROCESSO DE IMPORTAÇÃO' + Chr(13) + Chr(10))
		UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] VALIDANDO CSV; nenhum movimento será feito antes da conclusão desta etapa.' + Chr(13) + Chr(10))
		If !ValidaCsvCustos(cFileImp, nHdlLog)
			UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] PROCESSAMENTO CANCELADO: corrija o CSV antes de tentar novamente.' + Chr(13) + Chr(10))
			FClose(nHdlLog)
			cMensagem := 'CSV rejeitado por inconsistências. Consulte o LOG: ' + cFileLog
			Return .F.
		EndIf

		//---------------------------------------------------------------------
		//--Abre o arquivo e inicia a importacao:
		//---------------------------------------------------------------------
		FT_FUSE(cFileImp)

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
										cErroSB9 := ""
										If CriaSB9SaldoZero(aMsExcAuto[nPosCod][2], aMsExcAuto[nPosLocal][2], dUltFech, dDataBase, @cErroSB9)
											If SB9->(DbSeek(xFilial("SB9")+PadR(aMsExcAuto[nPosCod][2],15)+aMsExcAuto[nPosLocal][2]+DTOS(dUltFech)))
												_nQini := SB9->B9_QINI
												_nVini := SB9->B9_VINI1
												UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Saldo SB9 criado automaticamente com abertura zero para produto ' + AllTrim(aMsExcAuto[nPosCod][2]) + ' | Local: ' + AllTrim(aMsExcAuto[nPosLocal][2]) + ' | Data: ' + DtoS(dUltFech) + Chr(13) + Chr(10))
											Else
												cErroSB9 := "A SB9 não foi localizada após a tentativa de criação."
											EndIf
										EndIf

										If !Empty(cErroSB9)
											UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Saldo SB9 ausente; autocorreção não aplicada para produto ' + AllTrim(aMsExcAuto[nPosCod][2]) + ' | Local: ' + AllTrim(aMsExcAuto[nPosLocal][2]) + '. Motivo: ' + cErroSB9 + ' Linha ignorada.' + Chr(13) + Chr(10))
											nLinhasSemSB9++
											IncProc()
											FT_FSKIP()
											Loop
										EndIf

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
									cQuery += "AND D1_TES IN (SELECT SF4.F4_CODIGO FROM " + RetSQLName("SF4") + " SF4 "
									cQuery += "WHERE SF4.F4_FILIAL = '" + xFilial("SF4") + "' AND SF4.F4_CODIGO = SD1010.D1_TES "
									cQuery += "AND SF4.F4_ESTOQUE = 'S' AND SF4.D_E_L_E_T_ <> '*') "
									cQuery += "AND ((D1_EMISSAO > '"  + DTOS(dUltFech)          + "' AND D1_DTDIGIT = '') OR  D1_DTDIGIT >  '" + DTOS(dUltFech)  + "')"
									cQuery += "AND ((D1_EMISSAO <= '" + DTOS(dDataBase)         + "' AND D1_DTDIGIT = '') OR (D1_DTDIGIT <= '" + DTOS(dDataBase) + "' AND D1_DTDIGIT <> ''))"
									cQuery += "AND D_E_L_E_T_ <> '*' "
									cQuery += "UNION All "
									cQuery += "SELECT D2_FILIAL, D2_TES, D2_COD, D2_QUANT, D2_CUSTO1, D2_CF, D2_LOCAL, D2_DOC, D2_EMISSAO "
									cQuery += "FROM " + RetSQLName( 'SD2' ) + " SD2010 "
									cQuery += "WHERE D2_COD    = '" + PadR(aMsExcAuto[nPosCod][2],15) + "' "
									cQuery += "AND D2_FILIAL   = '" + xFilial("SD2")            + "' "
									cQuery += "AND D2_LOCAL    = '" + aMsExcAuto[nPosLocal][2]  + "' "
									cQuery += "AND D2_TES IN (SELECT SF4.F4_CODIGO FROM " + RetSQLName("SF4") + " SF4 "
									cQuery += "WHERE SF4.F4_FILIAL = '" + xFilial("SF4") + "' AND SF4.F4_CODIGO = SD2010.D2_TES "
									cQuery += "AND SF4.F4_ESTOQUE = 'S' AND SF4.D_E_L_E_T_ <> '*') "
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
											lMovValor := aMsExcAuto[nPosCusto][2] <> 0
											If lMovValor
												cCodMov := IIf(nAjusteQtd > 0, cTmEntrada, cTmSaida)
											Else
												cCodMov := IIf(nAjusteQtd > 0, "103", "503")
											EndIf
											AAdd(ExpA1, {"D3_TM", cCodMov, Nil})
											AAdd(ExpA1, {"D3_COD", SB1->B1_COD, Nil})
											AAdd(ExpA1, {"D3_UM", SB1->B1_UM, Nil})
											AAdd(ExpA1, {"D3_LOCAL", AllTrim(aMsExcAuto[nPosLocal][2]), Nil})
											AAdd(ExpA1, {"D3_QUANT", Abs(nAjusteQtd), Nil})
											If lMovValor
												AAdd(ExpA1, {"D3_CUSTO1", Abs(nAjusteQtd) * aMsExcAuto[nPosCusto][2], Nil})
											EndIf
											AAdd(ExpA1, {"D3_EMISSAO", dDataBase, Nil})
											AAdd(ExpA1, {"D3_GRUPO", SB1->B1_GRUPO, Nil})
											AAdd(ExpA1, {"D3_CONTA", SB1->B1_CONTA, Nil})

											lMsErroAuto := .F.
											MSExecAuto({|x,y| mata240(x,y)}, ExpA1, 3)

											If lMsErroAuto
												DisarmTransaction()
												lErroProc := .T.
												cErrAuto := CsvLogAuto()
												UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Erro ao ajustar quantidade para produto ' + AllTrim(aMsExcAuto[nPosCod][2]) + ' | Local: ' + AllTrim(aMsExcAuto[nPosLocal][2]) + ' | TM: ' + cCodMov + '. Detalhe: ' + cErrAuto + Chr(13) + Chr(10))
											Else
											cQuery := "SELECT B2_QATU FROM " + RetSQLName("SB2") + " SB2 "
											cQuery += "WHERE B2_FILIAL = '" + xFilial("SB2") + "' AND B2_COD = '" + PadR(aMsExcAuto[nPosCod][2], 15) + "' "
											cQuery += "AND B2_LOCAL = '" + AllTrim(aMsExcAuto[nPosLocal][2]) + "' AND D_E_L_E_T_ = ' '"
											cQuery := ChangeQuery(cQuery)
											dbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasSB2, .T., .T.)
											dbSelectArea(cAliasSB2)
											If (cAliasSB2)->(EoF())
												lErroProc := .T.
												UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Movimento gravado, mas saldo SB2 não localizado para validação do produto ' + AllTrim(aMsExcAuto[nPosCod][2]) + ' | Local: ' + AllTrim(aMsExcAuto[nPosLocal][2]) + Chr(13) + Chr(10))
											Else
												nSaldoPos := (cAliasSB2)->B2_QATU
												If Round(nSaldoPos, 4) <> Round(nQtdDesejada, 4)
													lErroProc := .T.
													UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Movimento gravado, mas saldo SB2 final ' + cValToChar(nSaldoPos) + ' difere da meta CSV ' + cValToChar(nQtdDesejada) + ' para produto ' + AllTrim(aMsExcAuto[nPosCod][2]) + ' | Local: ' + AllTrim(aMsExcAuto[nPosLocal][2]) + Chr(13) + Chr(10))
												Else
													UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] [LINHA: ' + StrZero(nLinha, 5) + '] Saldo SB2 validado: ' + cValToChar(nSaldoPos) + ' | Meta CSV: ' + cValToChar(nQtdDesejada) + ' | Quantidade movimentada: ' + cValToChar(Abs(nAjusteQtd)) + ' usando TM ' + cCodMov + ' em produto ' + AllTrim(aMsExcAuto[nPosCod][2]) + ' | Local: ' + AllTrim(aMsExcAuto[nPosLocal][2]) + Chr(13) + Chr(10))
												EndIf
											EndIf
											(cAliasSB2)->(dbCloseArea())
											EndIf
										Else
											lErroProc := .T.
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

				If lErroProc
					nFalhasProc++
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

		If nLinhasSemSB9 > 0 .Or. nFalhasProc > 0
			cMensagem := 'Processamento concluído com ' + cValToChar(nFalhasProc) + ' linha(s) com falha no movimento.'
			If nLinhasSemSB9 > 0
				cMensagem += ' ' + cValToChar(nLinhasSemSB9) + ' linha(s) ignorada(s) por saldo de fechamento ausente na SB9.'
			EndIf
			cMensagem += ' Consulte o LOG: ' + cFileLog
			Return .F.
		EndIf
	EndIf

Return .T.

Static Function CriaSB9SaldoZero(cCodigo, cLocal, dUltFech, dDataBase, cErro)
	Local cAliasSB2 := GetNextAlias()
	Local cAliasMov := GetNextAlias()
	Local cCodSql := StrTran(PadR(AllTrim(cCodigo), 15), "'", "''")
	Local cLocalSql := StrTran(AllTrim(cLocal), "'", "''")
	Local cQuery := ""
	Local cCf := ""
	Local nQAtual := 0
	Local nVAtual := 0
	Local nQMov := 0
	Local nVMov := 0
	Local nQIni := 0
	Local nVIni := 0
	Local lRegistro := .F.

	cErro := ""
	cQuery += "SELECT B2_QATU, B2_VATU1 "
	cQuery += "FROM " + RetSQLName("SB2") + " SB2 "
	cQuery += "WHERE B2_FILIAL = '" + xFilial("SB2") + "' "
	cQuery += "AND B2_COD = '" + cCodSql + "' "
	cQuery += "AND B2_LOCAL = '" + cLocalSql + "' "
	cQuery += "AND D_E_L_E_T_ = ' ' "
	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasSB2, .T., .T.)
	dbSelectArea(cAliasSB2)

	If (cAliasSB2)->(EoF())
		(cAliasSB2)->(dbCloseArea())
		cErro := "Não existe saldo atual na SB2 para reconstruir o fechamento."
		Return .F.
	EndIf

	nQAtual := (cAliasSB2)->B2_QATU
	nVAtual := (cAliasSB2)->B2_VATU1
	(cAliasSB2)->(dbCloseArea())

	cQuery := ""
	cQuery += "SELECT D3_CF AS MOV_CF, D3_QUANT AS MOV_QTD, D3_CUSTO1 AS MOV_VAL "
	cQuery += "FROM " + RetSQLName("SD3") + " SD3 "
	cQuery += "WHERE D3_FILIAL = '" + xFilial("SD3") + "' "
	cQuery += "AND D3_COD = '" + cCodSql + "' "
	cQuery += "AND D3_LOCAL = '" + cLocalSql + "' "
	cQuery += "AND D3_EMISSAO > '" + DtoS(dUltFech) + "' "
	cQuery += "AND D3_EMISSAO <= '" + DtoS(dDataBase) + "' "
	cQuery += "AND D3_ESTORNO <> 'S' AND D_E_L_E_T_ <> '*' "
	cQuery += "UNION ALL "
	cQuery += "SELECT D1_CF AS MOV_CF, D1_QUANT AS MOV_QTD, D1_CUSTO AS MOV_VAL "
	cQuery += "FROM " + RetSQLName("SD1") + " SD1 "
	cQuery += "WHERE D1_FILIAL = '" + xFilial("SD1") + "' "
	cQuery += "AND D1_COD = '" + cCodSql + "' "
	cQuery += "AND D1_LOCAL = '" + cLocalSql + "' "
	cQuery += "AND D1_TES IN (SELECT SF4.F4_CODIGO FROM " + RetSQLName("SF4") + " SF4 WHERE SF4.F4_FILIAL = '" + xFilial("SF4") + "' AND SF4.F4_CODIGO = SD1.D1_TES AND SF4.F4_ESTOQUE = 'S' AND SF4.D_E_L_E_T_ <> '*') "
	cQuery += "AND ((D1_EMISSAO > '" + DtoS(dUltFech) + "' AND D1_DTDIGIT = '') OR D1_DTDIGIT > '" + DtoS(dUltFech) + "') "
	cQuery += "AND ((D1_EMISSAO <= '" + DtoS(dDataBase) + "' AND D1_DTDIGIT = '') OR (D1_DTDIGIT <= '" + DtoS(dDataBase) + "' AND D1_DTDIGIT <> '')) AND D_E_L_E_T_ <> '*' "
	cQuery += "UNION ALL "
	cQuery += "SELECT D2_CF AS MOV_CF, D2_QUANT AS MOV_QTD, D2_CUSTO1 AS MOV_VAL "
	cQuery += "FROM " + RetSQLName("SD2") + " SD2 "
	cQuery += "WHERE D2_FILIAL = '" + xFilial("SD2") + "' "
	cQuery += "AND D2_COD = '" + cCodSql + "' "
	cQuery += "AND D2_LOCAL = '" + cLocalSql + "' "
	cQuery += "AND D2_TES IN (SELECT SF4.F4_CODIGO FROM " + RetSQLName("SF4") + " SF4 WHERE SF4.F4_FILIAL = '" + xFilial("SF4") + "' AND SF4.F4_CODIGO = SD2.D2_TES AND SF4.F4_ESTOQUE = 'S' AND SF4.D_E_L_E_T_ <> '*') "
	cQuery += "AND ((D2_EMISSAO > '" + DtoS(dUltFech) + "' AND D2_DTDIGIT = '') OR D2_DTDIGIT > '" + DtoS(dUltFech) + "') "
	cQuery += "AND ((D2_EMISSAO <= '" + DtoS(dDataBase) + "' AND D2_DTDIGIT = '') OR (D2_DTDIGIT <= '" + DtoS(dDataBase) + "' AND D2_DTDIGIT <> '')) AND D_E_L_E_T_ <> '*'"
	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasMov, .T., .T.)
	dbSelectArea(cAliasMov)

	While !(cAliasMov)->(EoF())
		cCf := AllTrim((cAliasMov)->MOV_CF)
		If SubStr(cCf, 1, 2) == "RE" .Or. Val(SubStr(cCf, 1, 1)) >= 5
			nQMov -= (cAliasMov)->MOV_QTD
			nVMov -= (cAliasMov)->MOV_VAL
		Else
			nQMov += (cAliasMov)->MOV_QTD
			nVMov += (cAliasMov)->MOV_VAL
		EndIf
		(cAliasMov)->(dbSkip())
	EndDo
	(cAliasMov)->(dbCloseArea())

	nQIni := Round(nQAtual - nQMov, 4)
	nVIni := Round(nVAtual - nVMov, 5)

	If nQIni <> 0 .Or. nVIni <> 0
		cErro := "A reconstrução não resultou em abertura zero (B9_QINI=" + cValToChar(nQIni) + ", B9_VINI1=" + cValToChar(nVIni) + "); requer revisão do fechamento."
		Return .F.
	EndIf

	DbSelectArea("SB9")
	SB9->(DbSetOrder(1))
	If SB9->(DbSeek(xFilial("SB9") + PadR(cCodigo, 15) + cLocal + DtoS(dUltFech)))
		Return .T.
	EndIf

	If !RecLock("SB9", .T.)
		cErro := "Não foi possível bloquear a SB9 para inclusão."
		Return .F.
	EndIf

	SB9->B9_FILIAL := xFilial("SB9")
	SB9->B9_COD := PadR(cCodigo, 15)
	SB9->B9_LOCAL := cLocal
	SB9->B9_DATA := dUltFech
	SB9->B9_QINI := 0
	SB9->B9_VINI1 := 0
	MsUnlock()

	lRegistro := SB9->(DbSeek(xFilial("SB9") + PadR(cCodigo, 15) + cLocal + DtoS(dUltFech)))
	If !lRegistro
		cErro := "A inclusão foi executada, mas a chave não foi localizada após a gravação."
	EndIf

Return lRegistro


Static Function ValidaTMs(cTmEntrada, cTmSaida)
	Local cQuery := ""
	Local cAliasTM := GetNextAlias()
	Local cCodigo := ""
	Local lEntradaValida := .F.
	Local lSaidaValida := .F.
	Local lEntradaZeroValida := .F.
	Local lSaidaZeroValida := .F.
	Local nPos := 0

	cTmEntrada := AllTrim(cTmEntrada)
	cTmSaida := AllTrim(cTmSaida)

	If Len(cTmEntrada) <> 3 .Or. Len(cTmSaida) <> 3
		Alert("Informe códigos de TM com três dígitos.")
		Return .F.
	EndIf

	If cTmEntrada == cTmSaida
		Alert("As TMs de entrada e saída devem ser diferentes.")
		Return .F.
	EndIf

	For nPos := 1 To 3
		If !(SubStr(cTmEntrada, nPos, 1) $ "0123456789") .Or. !(SubStr(cTmSaida, nPos, 1) $ "0123456789")
			Alert("Os códigos de TM devem conter somente números.")
			Return .F.
		EndIf
	Next

	cQuery += "SELECT F5_CODIGO, F5_TIPO, F5_VAL "
	cQuery += "FROM " + RetSQLName("SF5") + " SF5 "
	cQuery += "WHERE F5_FILIAL = '" + xFilial("SF5") + "' "
	cQuery += "AND F5_CODIGO IN ('" + cTmEntrada + "', '" + cTmSaida + "', '103', '503') "
	cQuery += "AND D_E_L_E_T_ <> '*' "
	cQuery := ChangeQuery(cQuery)
	dbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasTM, .T., .T.)
	dbSelectArea(cAliasTM)

	While !(cAliasTM)->(EoF())
		cCodigo := AllTrim((cAliasTM)->F5_CODIGO)
		If cCodigo == "103" .And. (cAliasTM)->F5_TIPO == "D" .And. (cAliasTM)->F5_VAL == "N"
			lEntradaZeroValida := .T.
		ElseIf cCodigo == "503" .And. (cAliasTM)->F5_TIPO == "R" .And. (cAliasTM)->F5_VAL == "N"
			lSaidaZeroValida := .T.
		ElseIf cCodigo == cTmEntrada .And. (cAliasTM)->F5_TIPO == "D" .And. (cAliasTM)->F5_VAL == "S"
			lEntradaValida := .T.
		ElseIf cCodigo == cTmSaida .And. (cAliasTM)->F5_TIPO == "R" .And. (cAliasTM)->F5_VAL == "S"
			lSaidaValida := .T.
		EndIf
		(cAliasTM)->(dbSkip())
	EndDo

	(cAliasTM)->(dbCloseArea())

	If !lEntradaValida .Or. !lSaidaValida
		Alert("A TM de entrada deve ser tipo D e a de saída tipo R; ambas devem permitir valor no SF5.")
		Return .F.
	EndIf

	If !lEntradaZeroValida .Or. !lSaidaZeroValida
		Alert("Para custo zero, as TMs 103 (entrada) e 503 (saída) devem existir no SF5 sem atualização de valor.")
		Return .F.
	EndIf

Return .T.

Static Function CsvLogPath()
	Local cDiretorio := GetTempPath(.F.)
	Local cNomeLog := "MovInterno_" + DtoS(Date()) + "_" + StrTran(Time(), ":", "") + ".LOG"

	If Right(cDiretorio, 1) <> "/" .And. Right(cDiretorio, 1) <> "\"
		cDiretorio += IIf("/" $ cDiretorio, "/", "\")
	EndIf

Return cDiretorio + cNomeLog

Static Function CsvLogClientPath(cFileLog)
	Local cDiretorioServidor := GetTempPath(.F.)
	Local cDiretorioCliente := GetTempPath(.T.)
	Local cNomeLog := ""

	If Right(cDiretorioServidor, 1) <> "/" .And. Right(cDiretorioServidor, 1) <> "\"
		cDiretorioServidor += IIf("/" $ cDiretorioServidor, "/", "\")
	EndIf
	If Right(cDiretorioCliente, 1) <> "/" .And. Right(cDiretorioCliente, 1) <> "\"
		cDiretorioCliente += IIf("/" $ cDiretorioCliente, "/", "\")
	EndIf

	cNomeLog := StrTran(cFileLog, cDiretorioServidor, "")

Return cDiretorioCliente + cNomeLog

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
	ProcRegua(2 * FT_FLastRec())
	While !FT_FEOF()
		cLinha := FT_FREADLN()
		nLinha++
		IncProc()

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

					If lQuantidadeValida .And. nDigitosQtd > 0
						nQuantidade := Val(cNumeroQtd)
				EndIf

					If Upper(cCusto) == "FALSO" .And. lQuantidadeValida .And. nQuantidade == 0
						cNumero := "0"
						lNumeroValido := .T.
						nDigitos := 1
						UpdFileLog(nHdlLog, "Linha " + StrZero(nLinha, 5) + ": custo FALSO interpretado como zero para quantidade-alvo zero." + Chr(13) + Chr(10))
					EndIf

					If Empty(cCodigo) .Or. Empty(cLocal) .Or. !lNumeroValido .Or. nDigitos == 0 .Or. !lQuantidadeValida .Or. nDigitosQtd == 0
						UpdFileLog(nHdlLog, "Linha " + StrZero(nLinha, 5) + ": produto, local, quantidade ou custo inválido. Valores negativos não são aceitos." + Chr(13) + Chr(10))
						lValido := .F.
					Else
						nCusto := Val(cNumero)
						AAdd(aRegistros, {cCodigo + Chr(1) + cLocal, nQuantidade, nCusto, nLinha})
					EndIf
				EndIf
			EndIf
		EndIf

		FT_FSKIP()
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
