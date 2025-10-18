#include "totvs.ch"
User Function Dicionario 
Local cDir
Local aTables := {}
Local aValor  := {}
Local aQtd    := {}
Local aStru   := {}
Local i 
Local cEmp
Local cFil  
Local cCampos := ""
Local cTexto  := "Este Programa atualiza o dicionário de dados do Protheus "+;
	"quando aos seus campos numéricos.  É necessário acesso exclusivo ao sistema "+;
	"e a existência de 3 arquivos (tabelas.txt, valor.txt e quantidade.txt) numa "+;
	"pasta disponível na estação executora dessa rotina.  "+;
	"Confirma a execução?"
If !MsgYesNo(cTexto,"Dicionário numérico Protheus")
	Return
Endif     
cDir:=cGetFile(,,1,"C:\",.F., GETF_LOCALHARD+GETF_RETDIRECTORY,.T.,.T.)
If Empty(cDir)
	Return
Endif
Processa({|| aTables:=LoadArray(cDir+"tabelas.txt")},"Lendo tabelas")
Processa({|| aValor:=LoadArray(cDir+"Valor.txt")},"Campos de Valores")
Processa({|| aQtd:=LoadArray(cDir+"quantidade.txt")},"Campos de Quantidade")
If Len(aTables)*Len(aValor)*Len(aQtd)==0  
	MsgStop("Problemas com os arquivos de definição de campos!","Erro")
	Return
Endif
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

MsgYesNo("PROCESSO CONCLUIDO"+CRLF+cCampos,"Dicionário")
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
If File(cArq)
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
Else
	MsgStop(cArq+" não encontrado!","Erro")
Endif
Return aArray


Static Function Sel_Empr(cEmp,cFil)
Local oDlg
Local aEmpFil:={}
Local aEmp:={}
Local aFil:={}
Local aNome:={}
Local nList:=1                  

//DbUseArea(.T.,"DBFCDX","sigamat.emp","ZZZ",.f.,.f.)
Use sigamat.emp alias "ZZZ" New

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
@ 14,30 MsGet nTam1 of oDlg Pixel Picture "99" Valid nTam1>0.and.nTam1<=18 .and. Formata(nTam1,nDec1,@cPict1) 
@ 30,05 Say "Decimal:" of oDlg Pixel
@ 29,30 MsGet nDec1 of oDlg Pixel Picture "99" Valid nDec1<=(nTam1-2) .and. Formata(nTam1,nDec1,@cPict1)
@ 45,05 Say "Mascara:" of oDlg Pixel
@ 44,30 MsGet cPict1 of oDlg Pixel Size 100,10
@ 75,05 Say "Quantidades:" of oDlg Pixel
@ 90,05 Say "Tamanho:" of oDlg Pixel
@ 89,30 MsGet nTam2 of oDlg Pixel Picture "99" Valid nTam2>0.and.nTam2<=18 .and. Formata(nTam2,nDec2,@cPict2)
@ 105,05 Say "Decimal:" of oDlg Pixel
@ 104,30 MsGet nDec2 of oDlg Pixel Picture "99" Valid nDec2<=(nTam2-2) .and. Formata(nTam2,nDec2,@cPict2)
@ 120,05 Say "Mascara:" of oDlg Pixel 
@ 119,30 MsGet cPict2 of oDlg Pixel Size 100,10
Define sButton From 75,100 Type 1 Enable of oDlg Pixel Action oDlg:End()
Activate MsDialog oDlg Centered
AADD(aStru,{nTam1,nDec1,cPict1})
AADD(aStru,{nTam2,nDec2,cPict2})
Return

User function tstform
cDesc:=""
formata(11,3,@cDesc)
formata(3,0,@cdesc)//,
formata(5,2,@cdesc)
formata(10,3,@cdesc)//,
formata(6,0,@cdesc)
formata(3,1,@cdesc)
return 

Static Function Formata(nTam,nDec,cPict)
Local cDec  := If(nDec>0,"."+Repl("9",nDec),"")
Local cInt  := Repl("9",nTam-(nDec+If(nDec>0,1,0)))
Local nVirg := Int(Len(cInt)/3)
Local nSobr := Len(cInt)-(nVirg*3) 
Local i     
cInt := ""
For i:=1 to nVirg
	cInt += ","+"999"
Next  
If Left(cInt,1)==","
	cInt := Substr(cInt,2)
Endif
cPict := "@E "+Repl("9",nSobr)+If(nSobr>0,",","")+cInt+cDec
cPict := StrTran(cPict,",.",".")
Return .T.