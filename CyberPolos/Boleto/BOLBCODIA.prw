#INCLUDE "PROTHEUS.CH"

User Function BOLBCODIA()                                       

Local oDlg
Local aRet := {}
Local cBco := Space(03)
Local cAge := Space(05)
Local cCta := Space(10)
Local cMsg, cMsg2, cMsg1
//Local nTipo := PARAMIXB[1]

Default nTipo := 1                              

	If nTipo == 1 
		cMsg := "Banco do Dia"
		cMsg1 := "Escolha o banco que será usado para impressão dos boletos"
		cMsg2 := ""
	Else
		cMsg := "Escolha o banco para o cliente"
		cMsg1 := "Cliente " + AllTrim(SA1->A1_NOME) + " - Banco atual do dia: "+Alltrim(GetMv("CP_XBANCO"))
		cMSg2 := "Nota Fiscal Número:" + AllTrim(SE1->E1_PREFIXO) + '-' + AllTrim(SE1->E1_NUM) + "/" + AllTrim(SE1->E1_PARCELA)+"  -  Banco do Cliente/Cadastro: "+Alltrim(SA1->A1_BCO1)
	EndIf		

	DEFINE MSDIALOG oDlg FROM 0,0 TO 180,500 PIXEL TITLE cMsg
											
		@ 003,010 SAY cMsg1 SIZE 400,7 PIXEL OF oDlg
		@ 013,010 SAY cMsg2 SIZE 400,7 PIXEL OF oDlg
		@ 025,010 SAY "Banco"   SIZE 30,7 PIXEL OF oDlg                                                       
		@ 040,010 SAY "Agência" SIZE 30,7 PIXEL OF oDlg
		@ 055,010 SAY "Conta"   SIZE 30,7 PIXEL OF oDlg
		@ 025,040 MSGET cBco F3 "SA6" VALID ExistCpo("SA6",cBco) PICTURE "@!" SIZE 15,7 PIXEL OF oDlg
		@ 040,040 MSGET cAge PICTURE "@!" SIZE 20,7 PIXEL OF oDlg
		@ 055,040 MSGET cCta PICTURE "@!" SIZE 40,7 PIXEL OF oDlg                
		DEFINE SBUTTON FROM 073,010 TYPE 1 OF oDlg ENABLE ACTION {|| IIf(Empty(cBco) .Or. Empty(cAge) .Or. Empty(cCta), MsgAlert("Preencha os parâmetros"),; 
																	IIf(nTipo == 1, fAjtParm(cBco, cAge, cCta, oDlg), oDlg:End()))}       
					
	ACTIVATE MSDIALOG oDlg CENTER

	aRet := {cBco, cAge, cCta}

Return aRet                                      
                                                                


Static Function fAjtParm(cBco, cAge, cCta, oDlg)

//Inclusao por Taki em 07/04/16 - Cyberpolos
//Forcando a agencia/conta correta - pois penso que dentro do mesmo banco estao selecionando 
//conta errada, o que nao tem SEE parametrizado e assim, nao localiza os parametros bancarios corretamente


	If Alltrim(cBco)=="001"   //bb
	cAge := ""
	cCta := ""
	Endif
	If Alltrim(cBco)=="033"	//santander
	cAge := "0535 "
	cCta := "13003028  "
	Endif
	If Alltrim(cBco)=="341"	//itau
	cAge := "2731 "
	cCta := "03199     "
	Endif

//                                                                
PutMv("CP_XBOLDIA",DToS(dDataBase))
PutMv("CP_XBANCO",cBco)
PutMv("CP_XAGENCI",cAge)
PutMv("CP_XCONTA",cCta)

MsgAlert("Banco Alterado") 
oDlg:End()

Return

