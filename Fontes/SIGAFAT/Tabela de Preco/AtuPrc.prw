#include "totvs.ch"
#Include "rwmake.ch"
#Include "protheus.ch"
#Include "TopConn.ch"

/*
	Rotina		:	AtuPrec
	Autor		:	Dione Oliveira
	Data		:	07/08/2019
	Descricao	:	Importação arquivo CSV para atualizar preços para tabelas de preços
	Obs	 		:	
*/



User Function AtuPrec()

	cFile := space(250)

	@ 100,001 To 280,520 Dialog oDlg1 Title "Importação - Tabela de Preço"
	@ 010,018 Say "Importar/Atualizar: "
	@ 025,018 say "Diretório/Arquivo: "
	@ 025,070 get cFile F3 "DIR" valid !Empty(cFile) size 150,050
	@ 050,140 to 078,237
	@ 055,145 say "A planilha deverá ser salva no "
	@ 065,145 say "formato CSV (Separado por vírgula)"
	@ 060,028 BmpButton Type 01 Action Confirma()
	@ 060,070 BmpButton Type 02 Action Close(oDlg1)
	Activate Dialog oDlg1 Centered
	
Return

/*====================================================================*/

Static Function Confirma()
	
	Local cLinha  := ""
	Local lPrim   := .T.
	Local aCampos := {}
	Local aDados  := {}
	local nTotal  := 0
	Local nI 	  := 0
	
	cFile := Upper(cFile)

	If Empty(cFile)
		MsgStop("Informe o local de origem do arquivo (CSV) de importação.","Atenção")
		Return
	Endif

	If !".CSV" $ cFile
		MsgStop("Somente arquivos com extensão CSV serão aceitos para a importação"+CHR(13)+" A importação será abortada.","Atenção")
		Return
	EndIf

	If !File(cFile)
		MsgStop("O arquivo " +Alltrim(cFile) + " não foi encontrado. A importação será abortada!","Atenção")
		Return
	EndIf


   	nOp:= AVISO('Atenção!', 'Os dados informados na planilha irão sobrepor dados existentes, deseja continuar?', { 'Sim', 'Não' }, 1)

	If nOp = 2
		Return
	Endif

	Close(Odlg1)
	
	FT_FUSE(cFile)
	FT_FGOTOP()
	
	While !FT_FEOF()
	 
		cLinha := FT_FREADLN()
	 
		If lPrim
			AADD(aCampos,Separa(cLinha,";",.T.))
			lPrim := .F.
		Else
			AADD(aDados,Separa(cLinha,";",.T.))
		EndIf
	 
		FT_FSKIP()
	EndDo
	
	nTotal := Len(aDados)
	
	If len(aDados) = 0
		MsgStop("A Importação não será realizada pois o arquivo esta vazio.","Atenção")
		FT_FUSE()
		Return
	EndIf	
	
	If Len(aCampos[1]) <> 8
		MsgStop("A Importação não será realizada pois o arquivo possui colunas diferente das necessárias (Cod. Tabela, Cod.Produto, Preco Venda, Ativo, Estado, Tipo Operac., Faixa e Preço Máximo).","Atenção")
		FT_FUSE()
		Return		
	EndIf	
	

	
	For nI = 1 to Len(aDados)
		//MsProcTxt("Analisando linhas do arquivo " + cValToChar(i) + " de " + cValToChar(nTotal) + "...")
		//MsProcTxt("Analisando linhas do arquivo ")
		If Len(aDados[nI]) <> 8
			MsgStop("A Importação não será realizada pois o arquivo possui linhas diferentes do layout exigido (Cod. Tabela, Cod.Produto, Preco Venda, Ativo, Estado, Tipo Operac., Faixa e Preço Máximo).","Atenção")
			FT_FUSE()
		Return		
	EndIf	
	Next nI
	
	Begin Transaction
	
		Dbselectarea("DA1")
		Dbsetorder(1) 	//Cod. Tabela + Cod.Produto + Faixa + Item
		
		For nI = 1 to Len(aDados)
			/* 1:Cod. Tabela, 2:Cod.Produto, 3:Preco Venda, 4:Ativo, 5:Estado, 6:Tipo Operac. e 7:Faixa */
		
			If Empty(aDados[nI,1]) .OR. Empty(aDados[nI,2]) .OR. Empty(aDados[nI,3])  
			   FT_FSKIP()
			   Loop
			Endif
			
			//MsProcTxt("Atualizando os preços: " + cValToChar(i) + " de " + cValToChar(nTotal) + "...")
			//MsProcTxt("Atualizando os preços: " )

	
		If Dbseek(xFilial("DA1") + aDados[nI,1] + aDados[nI,2])
				If Found()
					Reclock("DA1",.F.)
		
					DA1->DA1_PRCVEN := Val(aDados[nI,3])
					DA1->DA1_ATIVO 	:= aDados[nI,4]
					DA1->DA1_ESTADO := aDados[nI,5]
					DA1->DA1_TPOPER := aDados[nI,6]
					DA1->DA1_QTDLOT := Val(aDados[nI,7])
					DA1->DA1_PRCMAX := Val(aDados[nI,8]) // Alteração para atualizar o preço máximo DE/para do B2C
		
					MsUnlock()
				Endif	
			EndIf
		
		Next nI

	End Transaction

	
	FT_FUSE()
	ApMsgInfo("Atualização concluída com sucesso!","OK")
	
Return
