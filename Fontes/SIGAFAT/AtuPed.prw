#include "totvs.ch"
#Include "rwmake.ch"
#Include "protheus.ch"
#Include "TopConn.ch"

/*
	Rotina		:	AtuPed
	Autor		:	Dione Oliveira
	Data		:	05/11/2019
	Descricao	:	Atualiza��o de pedidos de vendas C5_ZZSITFI
	Obs	 		:	
*/

User Function AtuPed()

	cFile := space(250)

	@ 100,001 To 280,520 Dialog oDlg1 Title "Atualiza��o de Dados"
	@ 010,018 Say "Atualizar: "
	@ 025,018 say "Diret�rio/Arquivo: "
	@ 025,070 get cFile F3 "DIR" valid !Empty(cFile) size 150,050
	@ 050,140 to 078,237
	@ 055,145 say "A planilha dever� ser salva no "
	@ 065,145 say "formato CSV (Separado por v�rgula)"
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
	
	cFile := Upper(cFile)

	If Empty(cFile)
		MsgStop("Informe o local de origem do arquivo (CSV) de importa��o.","Aten��o")
		Return
	Endif

	If !".CSV" $ cFile
		MsgStop("Somente arquivos com extens�o CSV ser�o aceitos para a importa��o"+CHR(13)+" A importa��o ser� abortada.","Aten��o")
		Return
	EndIf

	If !File(cFile)
		MsgStop("O arquivo " +Alltrim(cFile) + " n�o foi encontrado. A importa��o ser� abortada!","Aten��o")
		Return
	EndIf

   	nOp:= AVISO('Aten��o!', 'Os dados informados na planilha ir�o sobrepor dados existentes, deseja continuar?', { 'Sim', 'N�o' }, 1)

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
		MsgStop("A Importa��o n�o ser� realizada pois o arquivo esta vazio.","Aten��o")
		FT_FUSE()
		Return
	EndIf	
	
	If Len(aCampos[1]) <> 2
		MsgStop("A Importa��o n�o ser� realizada pois o arquivo possui colunas diferente das necess�rias (Cod. Tabela, Cod.Produto, Preco Venda, Ativo, Estado, Tipo Operac. e Faixa).","Aten��o")
		FT_FUSE()
		Return		
	EndIf	
	
	For i = 1 to Len(aDados)
		If Len(aDados[i]) <> 2
			MsgStop("A Importa��o n�o ser� realizada pois o arquivo possui linhas diferentes do layout exigido (Cod.Cliente, Risco).","Aten��o")
			FT_FUSE()
		Return		
	EndIf	
	Next i
	
	Begin Transaction
	
		Dbselectarea("SC5")
		Dbsetorder(1)
		
		For i = 1 to Len(aDados)
		
			If Empty(aDados[i,1]) .OR. Empty(aDados[i,2])
			   FT_FSKIP()
			   Loop
			Endif
	
		If Dbseek(xFilial("SC5") + aDados[i,1])
				If Found()
					Reclock("SC5",.F.)
					SC5->C5_ZZSITFI 	:= aDados[i,2]
					SC5->(MsUnlock())
				Endif	
			EndIf
		
		Next i

	End Transaction

	FT_FUSE()
	ApMsgInfo("Atualiza��o conclu�da com sucesso!","OK")
	
Return
