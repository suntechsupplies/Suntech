#include "totvs.ch"



User Function Dicionario
	Local aTables:={}
	Local aValor:={}
	Local aQtd:={}
	Local aStru:={}
	Local i
	Local cEmp
	Local cFil
	Local cCampos:=""
	Local cTexto:="Este Programa atualiza o dicionário de dados do Protheus "+;
		"quando aos seus campos numéricos. É necessário acesso exclusivo ao sistema "+;
		"e a existência de 3 arquivos (tabelas.txt, valor.txt e quantidade.txt) numa "+;
		"pasta c:\totvs11\ na estação executora dessa rotina."+Chr(10)+;
		"Confirma a execução?"
	If !MsgYesNo(cTexto)
		Return
	Endif
	Processa({|| aTables:=LoadArray("c:\totvs11\tabelas.txt")},"Lendo tabelas")
	Processa({|| aValor:=LoadArray("c:\totvs11\Valor.txt")},"Campos de Valores")
	Processa({|| aQtd:=LoadArray("c:\totvs11\quantidade.txt")},"Campos de Quantidade")
	Sel_Empr(@cEmp,@cFil)
	If !MsgYesNo("Confirma atualização da empresa "+cEmp+"/"+cFil+"?")
		Return
	Endif
	Processa({|| RpcSetEnv(cEmp,cFil)},"Aguarde! Abrindo Empresa.")
	If Len(aValor)>0.and.Len(aQtd)>0
		Estrutura(@aStru,aValor[1],aQtd[1])
	Else
		MsgStop("Não foi gerado lista de campos para alterar.  Verifique se os arquivos existem.")
		Return
	Endif

	SX3->(DbSetOrder(2))
	For i:=1 to Len(aValor)
		SX3->(DbSeek(Padr(aValor[i],10)))
		If SX3->(Found())
			RecLock("SX3",.f.)
			SX3->X3_TAMANHO:=aStru[1,1]
			SX3->X3_DECIMAL:=aStru[1,2]
			SX3->X3_PICTURE:=aStru[1,3]
			SX3->(MsUnlock())
		Else
			cCampos+="Campo não encontrado - "+aValor[i]+CRLF
		Endif
	Next
	For i:=1 to Len(aQtd)
		SX3->(DbSeek(Padr(aQtd[i],10)))
		If SX3->(Found())
			RecLock("SX3",.f.)
			SX3->X3_TAMANHO:=aStru[2,1]
			SX3->X3_DECIMAL:=aStru[2,2]
			SX3->X3_PICTURE:=aStru[2,3]
			SX3->(MsUnlock())
			//Conout("Campo "+aValor[i])
		Else
			cCampos+="Campo não encontrado - "+aQtd[i]+CRLF
		Endif
	Next

	Processa({|| AlterTable(aTables)},"Alterando Estruturas")

	MsgAlert("PROCESSO CONCLUIDO"+CRLF+cCampos)
Return

Static Function AlterTable(aTables)
	Local i
	ProcRegua(Len(aTables))
	For i:=1 to Len(aTables)
		X31UPDTABLE(aTables[i])
		IncProc(aTables[i])
	Next
Return

Static Function LoadArray(cArq)
	Local aArray:={}
	Local cTexto:=""
	FT_FUSE(cArq)
	ProcRegua(FT_FLASTREC())
	While !FT_FEOF()
		cTexto:=FT_FREADLN()
		cTexto:=AllTrim(Left(cTexto,At(" ",cTexto)))
		IncProc()
		aAdd(aArray,cTexto)
		FT_FSKIP()
	End
	FT_FUSE()
Return aArray


Static Function Sel_Empr(cEmp,cFil)
	Local oDlg
	Local aEmpFil:={}
	Local aEmp:={}
	Local aFil:={}
	Local aNome:={}
	Local nList:=1

	DbUseArea(.T.,"DBFCDX","sigamat.emp","ZZZ",.f.,.f.)
	While ZZZ->(!Eof())
		aAdd(aEmpFil,M0_CODIGO+"-"+M0_CODFIL+":"+M0_NOME+"/"+M0_FILIAL)
		AADD(aEmp,M0_CODIGO)
		AADD(aFil,M0_CODFIL)
		ZZZ->(DbSkip())
	End
	Define MsDialog oDlg fROM 0,0 to 200,400 Title "Escolha uma Empresa/Filial" Pixel
	@ 05,05 ListBox nList Items aEmpFil Of oDlg Pixel Size 190,50
	Define Sbutton from 70,150 Type 1 Enable of oDlg Pixel Action oDlg:End()
	Activate MsDialog oDlg Centered
	ZZZ->(DbCloseArea())
	cEmp:=aEmp[nList]
	cFil:=aFil[nList]
Return

Static Function Estrutura(aStru,cValor,cQtd)
	Local nTam1	:= TamSx3(cValor)[1]
	Local nTam2	:= TamSx3(cQtd)[1]
	Local nDec1	:= TamSx3(cValor)[2]
	Local nDec2 := TamSx3(cQtd)[2]
	Local cPict1:= X3Picture(cValor)
	Local cPict2:= X3Picture(cQtd)
	Local oDlg
	Define MsDialog oDlg Title "Campos Numéricos" From 0,0 to 300,400 Pixel
	@ 05,05 Say "Valores:" of oDlg Pixel
	@ 15,05 Say "Tamanho:" of oDlg Pixel
	@ 14,30 MsGet nTam1 of oDlg Pixel Picture "99" Valid nTam1>0.and.nTam1<=18
	@ 30,05 Say "Decimal:" of oDlg Pixel
	@ 29,30 MsGet nDec1 of oDlg Pixel Picture "99" Valid nDec1<=(nTam1-2)
	@ 45,05 Say "Mascara:" of oDlg Pixel
	@ 44,30 MsGet cPict1 of oDlg Pixel Size 100,10
	@ 75,05 Say "Quantidades:" of oDlg Pixel
	@ 90,05 Say "Tamanho:" of oDlg Pixel
	@ 89,30 MsGet nTam2 of oDlg Pixel Picture "99" Valid nTam2>0.and.nTam2<=18
	@ 105,05 Say "Decimal:" of oDlg Pixel
	@ 104,30 MsGet nDec2 of oDlg Pixel Picture "99" Valid nDec2<=(nTam2-2)
	@ 120,05 Say "Mascara:" of oDlg Pixel Size 100,10
	@ 119,30 MsGet cPict2 of oDlg Pixel
	Define sButton From 75,100 Type 1 Enable of oDlg Pixel Action oDlg:End()
	Activate MsDialog oDlg Centered
	AADD(aStru,{nTam1,nDec1,cPict1})
	AADD(aStru,{nTam2,nDec2,cPict2})
Return
