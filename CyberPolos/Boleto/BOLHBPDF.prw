#Include "RPTDEF.CH" 
#include 'TOTVS.CH'
#include 'FWPRINTSETUP.CH'
#Include 'TBICONN.CH'
#Include "FILEIO.CH"       
#include "apwizard.ch"
#Include "TBICODE.CH"
#Include "RWMAKE.CH"
#Include "TOPCONN.CH"


/*/{Protheus.doc} BOLHBPDF
Rotina usada para gerar boletos no momento da impressão do danfe
@type function
@version 12.1.25 
@author Cyberpolos
@since 25/01/2021
@param nTipo, numeric, tipo de processoa a ser realizado, 
@param cSerieDan, character, param_description
@param cNotaDan, character, param_description

/*/
User Function BOLHBPDF(_aEmp)
	
	//Local aDadosEmp := Nil	
	Local aBolText := {}
	Local aRecno   := {}
	Local oFont6n := Nil
	Local oFont10 := Nil
	Local oFont8n := Nil
	Local oFont10n:= Nil
	Local oFont16n:= Nil
	Local cQuery := ""
	Local cAlias := GetNextAlias()
	Local nA := 0
	Local nR := 0
	Local i  := 0
  	Local _cEnv  := AllTrim(Upper(GetEnvServer()))      //(+)adicionado por taki em 28/01/16
	Local nTipo		:= Nil	//PARAMIXB[1]  
	Local cSerieDan := Nil //PARAMIXB[2]
	Local cNotaDan	:= Nil //PARAMIXB[3]
	Local cPrefTit	:= Nil //PARAMIXB[4]
	Local cTitulo	:= Nil //PARAMIXB[5]
	Local cCodCli	:= Nil //PARAMIXB[6]
	Local cCond		:= Nil//FormatIN(Alltrim(GetMv('CP_BOLCOND')),'/')	
	Local cChave    := ""
	Local lSchedule := .F.
	Local lEnvioOK  := .F.
	Local aRetApi	:= {}
	Local lApi 	  	:= .F.	 
	Local nSalto    := 18
	Local _nLin     := 0


	Private aDadosEmp := Nil
    Private aCB_RN_NN := {}
    Private cNumSeq
	Private aDadosTit := {}
	Private aDadosBco := {}
	Private aDadosSac := {}
	Private aDados    := {}
	Private aBanco    := {}
	Private aMsg      := {}
	Private aStatus4  := {}
	Private cNum,cPrefix ,cParc,cTp,cCli,cLj

	Private _nVlrAbat              := 0
	Private cFXATU                 := "", cSeqN := '' , cSeq := ''
    Private cLinDigitavelCalculada := ''
	Private cNroDoc, cParcel
	Private _cNossoNum             := ''
	Private cBanco                 := Space(03)
	Private cPorta                 := Space(3)
	Private cConta                 := Space(10)
	Private cAgencia               := Space(05)
	Private cParcela               := ""
	Private aTitulos               := {}
	Private oPrinter               := Nil
	Private lAbortProcesso         := .F.
	Private lFazANexo              := .F.
	Private lEnviaEmail            := .F. //usuario pode nao querer anexar no email, mas desejar gerar o PDF para imprimir manualmente depois 
	Private lImpriBol              := Nil          
	Private cFilePdf     		   := ''
   	Private cPDFGer                := '' //GetTempPath() //SuperGetMv( 'CP_DIRBOL' ,, '' )
   	Private cPDFGer2               := ''
	Private cLayout                := ""
	Private cImag001               := ""
	Private cImag033               := ""
	Private cImag341               := ""
	Private lStatus4               := .F.
	Private cUltTitulo             := "" //Antonio Ricardo de Araujo - 24/05/2023 - Corrigir Duplicidades no envio de Boletos
                                           
	Default nTipo		:= 1
	Default cSerieDan	:= ""
	Default cNotaDan	:= ""
	

	 // Inicializa ambiente pelo schedule
	If Select("SX6") == 0
		RPCSetType(3)  		//| Nao utilizar licenca	
		RpcSetEnv(_aEmp[1] ,_aEmp[2])
		lSchedule := .T.		
	Endif    

	aDadosEmp := { SM0->M0_NOMECOM,; //[1]Nome da Empresa
	SM0->M0_ENDCOB,; //[2]Endereço
	AllTrim(SM0->M0_BAIRCOB) + ", " + AllTrim(SM0->M0_CIDCOB) + ", " + SM0->M0_ESTCOB,; //[3]Complemento
	"CEP: " + Subs(SM0->M0_CEPCOB,1,5) + "-" + Subs(SM0->M0_CEPCOB,6,3),; //[4]CEP
	"PABX/FAX: " + SM0->M0_TEL,; //[5]Telefones
	/*"CNPJ: " + */Subs(SM0->M0_CGC,1,2) + "." + Subs(SM0->M0_CGC,3,3) + "." + Subs(SM0->M0_CGC,6,3) + "/" + Subs(SM0->M0_CGC,9,4) + "-" + Subs(SM0->M0_CGC,13,2),; //[6]CGC
	"I.E.: " + SM0->M0_INSC}  //[7]I.E

	cCond := FormatIN(Alltrim(GetMv('CP_BOLCOND')),'/')
	lImpriBol := GetMV("CP_BOLIMP")

    DbSelectArea("SE1")
		/*/
		E1_XBOMAIL = '1' // Quando foi impresso o danfe, a rotina vai gerar o boleto.
		E1_XBOMAIL = '2' // Boleto ja gerado e enviado.
		E1_XBOMAIL = '4' // Reenvio de boleto, apos ser reenviado passa a ser '2'.
		/*/
	If lSchedule

		cQuery := " SELECT SE1.R_E_C_N_O_ RECNO, SE1.E1_XBOMAIL E1_XBOMAIL, SE1.E1_NUMBCO, SE1.E1_VENCREA,"
		cQuery += " SE1.E1_NUM E1_NUM, SE1.E1_PREFIXO E1_PREFIXO, SE1.E1_PARCELA E1_PARCELA"	
		cQuery += " FROM " + RetSqlName("SE1") + " SE1 (NOLOCK)"
		cQuery += " INNER JOIN " + RetSqlName("SED") + " SED (NOLOCK)"  // Ricardo Araujo - Suntech 27/04/2023            
    	cQuery += " ON SE1.E1_NATUREZ = SED.ED_CODIGO "                 // Alteração Realizada para Impedir
    	cQuery += " AND SED.ED_ENVCOB <> '2' "                          // envio de boletos para natureza 
    	cQuery += " AND SED.D_E_L_E_T_ = '' "                           // de operações que não permite envios
		cQuery += " WHERE SE1.D_E_L_E_T_ = '' "
		cQuery += " AND SE1.E1_FILIAL = '" + xFilial("SE1") + "'"
		cQuery += " AND SE1.E1_SALDO > 0 "
		cQuery += " AND SE1.E1_XBOMAIL in ('1','4')"	
		//cQuery += " ORDER BY SE1.E1_NUM, SE1.E1_PARCELA"	/*Ricardo Araujo*/	

		//| ntipo 1 = não possui o nosso numero (E1_NUMBCO) ainda, então tem que ser gerado. 
		//| ntipo 2 = existe o nosso numero (E1_NUMBCO) não precisa ser gerado.
		nTipo  := IIf(lImpriBol = .T.,2,1) 
		
		cPDFGer   := "/workflow/boletos/"
		cPDFGer2  := "/workflow/boletos/"

	Else

		nTipo     := PARAMIXB[1]
		cSerieDan := PARAMIXB[2]
		cNotaDan  := PARAMIXB[3]
		cPrefTit  := PARAMIXB[4]
		cTitulo   := PARAMIXB[5]
		cCodCli   := PARAMIXB[6]

		cParApi  := ''
		
		If Len(PARAMIXB) > 6
			lApi	 := PARAMIXB[7]
			cParApi  := PARAMIXB[8]		
		Else
			cPDFGer   := GetTempPath()
		EndIf

		If !Empty(cNotaDan)
		
			cQuery := " SELECT SE1.R_E_C_N_O_ RECNO, SE1.E1_XBOMAIL E1_XBOMAIL, SE1.E1_NUMBCO, SE1.E1_VENCREA,"
			cQuery += " SE1.E1_NUM E1_NUM, SE1.E1_PREFIXO E1_PREFIXO, SE1.E1_PARCELA E1_PARCELA"	
			cQuery += " FROM " + RetSqlName("SE1") + " SE1 (NOLOCK)"
			cQuery += " INNER JOIN " + RetSqlName("SED") + " SED (NOLOCK)"  // Ricardo Araujo - Suntech 27/04/2023            
    		cQuery += " ON SE1.E1_NATUREZ = SED.ED_CODIGO "                 // Alteração Realizada para Impedir
    		cQuery += " AND SED.ED_ENVCOB <> '2' "                          // envio de boletos para natureza 
    		cQuery += " AND SED.D_E_L_E_T_ = '' "                           // de operações que não permite envios
			cQuery += " INNER JOIN " + RetSqlName("SF2") + " SF2 (NOLOCK)"
			cQuery += " ON SE1.E1_FILIAL = SF2.F2_FILIAL" 
			cQuery += " AND SE1.E1_PREFIXO = SF2.F2_SERIE"
			cQuery += "	AND SE1.E1_NUM = SF2.F2_DOC"
			cQuery += " AND SE1.E1_CLIENTE = SF2.F2_CLIENTE"
			cQuery += " AND SE1.E1_LOJA = SF2.F2_LOJA"
			cQuery += " AND SF2.F2_CHVNFE <> ''"
			cQuery += " WHERE SE1.D_E_L_E_T_ = '' "
			cQuery += " AND SE1.E1_FILIAL = '" + xFilial("SE1") + "'"
			cQuery += " AND SE1.E1_PREFIXO = '" + cSerieDan + "'"
			cQuery += " AND SE1.E1_NUM = '" + cNotaDan + "'"
			cQuery += " AND SF2.F2_COND not in " + cCond        
			cQuery += " AND SE1.E1_SALDO > 0 "	

			If nTipo = 1
				//cQuery += " AND SE1.E1_XBOMAIL = ' ' "
				cQuery += " AND SE1.E1_XBOMAIL in (' ','1')
				cQuery += " AND SE1.E1_NUMBCO = '' "
			ElseIf nTipo = 2
				cQuery += " AND SE1.E1_XBOMAIL = '2' "
				cQuery += " AND SE1.E1_NUMBCO <> '' "
			ElseIf nTipo = 3
				cQuery += " AND SE1.E1_XBOMAIL <> ' ' "
			EndIf	

			//cQuery += " ORDER BY SE1.E1_NUM, SE1.E1_PARCELA"	/*Ricardo Araujo*/

		Else

			cQuery := " SELECT SE1.R_E_C_N_O_ RECNO, SE1.E1_XBOMAIL E1_XBOMAIL, SE1.E1_NUMBCO, SE1.E1_VENCREA,"
			cQuery += " SE1.E1_NUM E1_NUM, SE1.E1_PREFIXO E1_PREFIXO, SE1.E1_PARCELA E1_PARCELA"	
			cQuery += " FROM " + RetSqlName("SE1") + " SE1 (NOLOCK)"
			cQuery += " INNER JOIN " + RetSqlName("SED") + " SED (NOLOCK)"  // Ricardo Araujo - Suntech 27/04/2023            
    		cQuery += " ON SE1.E1_NATUREZ = SED.ED_CODIGO "                 // Alteração Realizada para Impedir
    		cQuery += " AND SED.ED_ENVCOB <> '2' "                          // envio de boletos para natureza 
    		cQuery += " AND SED.D_E_L_E_T_ = '' "                           // de operações que não permite envios
			cQuery += " WHERE SE1.D_E_L_E_T_ = '' "
			cQuery += " AND SE1.E1_FILIAL = '" + xFilial("SE1") + "'"
			cQuery += " AND SE1.E1_PREFIXO = '" + cPrefTit + "'"
			cQuery += " AND SE1.E1_NUM = '" + cTitulo + "'"
			cQuery += " AND SE1.E1_CLIENTE = '"+ cCodCli + "'"
			cQuery += " AND SE1.E1_SALDO > 0 "	

			If nTipo = 1
				cQuery += " AND SE1.E1_XBOMAIL in (' ','1') "
			ElseIf nTipo = 2
				cQuery += " AND SE1.E1_XBOMAIL = '2' "
				cQuery += " AND SE1.E1_NUMBCO <> '' "
			ElseIf nTipo = 3
				cQuery += " AND SE1.E1_XBOMAIL <> ' ' "	
			EndIf	

			//cQuery += " ORDER BY SE1.E1_NUM, SE1.E1_PARCELA" /*Ricardo Araujo*/ 	

		EndIf
		
		cPDFGer := cPDFGer + "\"
		cPDFGer2  := "/workflow/boletos/"

	EndIf

	nTipo := Iif(nTipo = 3,2,nTipo)


	//+-------------------------------------------------------
	// tratamento para nao haver execucao concorrente
	//+-------------------------------------------------------
	if !(LockByName('BOLHBPDF', .T., .F.)) .AND. !lApi
        ConOut("BOLHBPDF ja esta em execucao")
        if lSchedule
            RpcClearEnv()
        Endif
        Return
	Endif  

	
 	If Select(cAlias) > 0
		(cAlias)->(DbCloseArea())
	EndIf	

	if lApi
		If ! Empty(cParApi)
			cQuery += " AND SE1.E1_PARCELA = '" + cParApi + "' "
		EndIf
	EndIf

	cQuery += " ORDER BY SE1.E1_NUM, SE1.E1_PARCELA" /*Ricardo Araujo*/

	cImag001 := cPDFGer2 + 'bol001.jpg'
	cImag033 := cPDFGer2 + "logo_santander.bmp"
	cImag341 := cPDFGer2 + "logo_itau.bmp"

	dbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cAlias,.F.,.T.)

	If (cAlias)->(Eof()) .And. Alltrim(FunName()) $("BOLHBBOL")
		MsgAlert("Não localizado registros para NF "+cNotaDan+' - '+cSerieDan)
	EndIf
	
	While (cAlias)->(!Eof())

		aRecno:= {}
		lStatus4 := .F.

		// Caso tenha sido solicitado o reenvio dos boletos por data rotina BOLHBDIA
		If (cAlias)->E1_XBOMAIL == '4' .And. !Empty((cAlias)->E1_NUMBCO) .AND. (Dtos(Date()) > (cAlias)->E1_VENCREA)
			nTipo := 2
			lStatus4 := .T. //Variavel utilizada para definir o tipo de texto a ser enviado no email.
		ElseIf (cAlias)->E1_XBOMAIL == '1' .And. (Empty((cAlias)->E1_NUMBCO) .OR. !Empty((cAlias)->E1_NUMBCO)) .AND. (Dtos(Date()) <= (cAlias)->E1_VENCREA) // Ini - Antonio Ricardo de Araujo - 20/09/2023 - Corrigir envio em branco de Boletos
			nTipo := 1																						   												// 
		EndIf																                                   												// Fim - Antonio Ricardo de Araujo - 20/09/2023 - Corrigir envio em branco de Boletos
            	
     	If nTipo = 1 	 //IMPRESSAO DE BOLETOS NOVOS

			SE1->(DbGoTo((cAlias)->RECNO))	
			cChave := (cAlias)->E1_PREFIXO + (cAlias)->E1_NUM                           
											
			cFilePdf:= ""                              
							
			cTimeFiltrado:= Time()
			cTimeFiltrado:= STRTRAN(cTimeFiltrado,":","",1,5)
			cFilePdf :=	"Boleto_"+SE1->E1_CLIENTE+"_"+AllTrim(SE1->E1_NUM) //+AllTrim(SE1->E1_PARCELA)+"_"+cTimeFiltrado
			//cParcela := Iif(!Empty(AllTrim(SE1->E1_PARCELA))," Pcl. "+AllTrim(SE1->E1_PARCELA),"")
		
			oPrinter := Nil           
			oPrinter := FWMSPrinter():New(cFilePdf, IMP_PDF, .F., cPDFGer/*cCaminhosPDF*/, .T.,,,,,,,.F.,)
						
			oPrinter:SetPortrait()
			oPrinter:SetPaperSize(9)
			oPrinter:SetDevice(IMP_PDF)
			oPrinter:cPathPDF :=cPDFGer//cPathPDF

			While (cAlias)->(!Eof()) .And. cChave == (cAlias)->E1_PREFIXO + (cAlias)->E1_NUM
				SE1->(DbGoTo((cAlias)->RECNO))	

				aAdd(aRecno,(cAlias)->RECNO)

				aTitulos := { ;
							SE1->E1_NUM		,;
							SE1->E1_PREFIXO ,;
							SE1->E1_PARCELA ,;
							SE1->E1_TIPO	,;
							SE1->E1_CLIENTE ,;
							SE1->E1_LOJA    ,;
							''				,;
							SE1->E1_PORTADO ,;
							SE1->E1_AGEDEP  ;
						}              
		
		
				cNum    := aTitulos[1]
				cPrefix := aTitulos[2]
				cParc   := aTitulos[3]
				cTp     := aTitulos[4]
				cCli    := aTitulos[5]
				cLj     := aTitulos[6]
   
			
					
				DbSelectArea("SA1")
				SA1->(DbSetOrder(1))
				If !SA1->(DbSeek(xFilial("SA1") + SE1->E1_CLIENTE + SE1->E1_LOJA))
					Return
				EndIf			

				If  _cEnv == "TOTVS_SUNTECH"
					_cEmail   := Alltrim(SA1->A1_EMAIL)
					_cCc      := Alltrim(GetMV("CP_BOLMAIL")) 
					_cSubject := "Boleto HB - NF " + Alltrim(SE1->E1_NUM) //+ cParcela
				Else
					_cEmail   := 'suporte@hb.com.br' 
					_cCc      := ''
					_cSubject := "TESTE-HOMOLOGACAO - Boleto HB - NF " + Alltrim(SE1->E1_NUM) // + cParcela
				EndIf	
				
				If !Empty(SE1->E1_XBOMAIL) .And. lImpriBol
					//Como eh uma reimpressao o titulo ja tem um BANCO -pois ja foi gerado anteriormente
					//campos novos criados para justamente esse fim (boletos impressos e nao enviados por bordero ao banco nao gravam esses dados )
					cBanco   := PadR(SE1->E1_XBCO,3)
					cAgencia := PadR(SE1->E1_XAGE,5)
					cConta   := PadR(SE1->E1_XCONTA,10)
				Else
					
					cBanco   := PadR(GetMv("CP_XBANCO"), 3)
					cAgencia := PadR(GetMv("CP_XAGENCI"), 5)
					cConta   := PadR(GetMv("CP_XCONTA"), 10)
										
				Endif	

				//Mensagens que serão impressas
				DbSelectArea("ZB2")
				ZB2->(DbSetOrder(1))
				ZB2->(DbGoTop())
				If ZB2->(DbSeek(FWxFilial("ZB2")+cBanco+cAgencia+cConta))
					While ZB2->(!EOF()) .And. ZB2->ZB2_BANCO == cBanco .And. ZB2->ZB2_AGENCI == cAgencia .And. ZB2->ZB2_CONTA == cConta
						aAdd(aMsg,ZB2->ZB2_FORMUL)
						ZB2->(DbSkip())  
					EndDo
				EndIf
					
				If AllTrim(cBanco) == '001'
					cLayOut := cImag001 //cPDFGer2 + "BOL001.JPG"
				Endif
	
				If AllTrim(cBanco)  == '033'
					cLayOut := cImag033 //cPDFGer2 + "BOL033.JPG"
				Endif
	
				If AllTrim(cBanco)  == '341'
					cLayOut := cImag341 //cPDFGer2 + "BOL341.JPG"
				Endif
			
				aDadosTit := {}
				aDadosBco := {}
				aDadosSac := {}
				aDados    := {}
				aTitulos  := {}
				aCB_RN_NN := {}  
						
				If  Empty(SA1->A1_ENDCOB)
					aDadosSac := {  AllTrim(SA1->A1_NOME)                                			 ,; // [1]RazÃ£o Social
											AllTrim(SA1->A1_COD ) + "-" + SA1->A1_LOJA           	 ,; // [2]CÃ³digo
											AllTrim(SA1->A1_END ) + "-" + AllTrim(SA1->A1_BAIRRO)	 ,; // [3]EndereÃ§o
											AllTrim(SA1->A1_MUN )                                	 ,; // [4]Cidade
											SA1->A1_EST                                          	 ,; // [5]Estado
											SA1->A1_CEP                                          	 ,; // [6]CEP
											SA1->A1_CGC									         	 ,; // [7]CGC
											SA1->A1_PESSOA}	        								    // [8]PESSOA
				Else                                                                                    
						
					aDadosSac := {  AllTrim(SA1->A1_NOME)                               			 ,; // [1]RazÃ£o Social
											AllTrim(SA1->A1_COD ) + "-" + SA1->A1_LOJA          	 ,; // [2]CÃ³digo
											AllTrim(SA1->A1_ENDCOB ) + "-" + AllTrim(SA1->A1_BAIRRO) ,; // [3]EndereÃ§o
											AllTrim(SA1->A1_MUN )                                	 ,; // [4]Cidade
											SA1->A1_EST                                          	 ,; // [5]Estado
											SA1->A1_CEP                                          	 ,; // [6]CEP
											SA1->A1_CGC									         	 ,; // [7]CGC
											SA1->A1_PESSOA}	        								    // [8]PESSOA
				Endif
				
				//TextosRodape(cBanco)//fltro de bco na tela de impressao
									
				//aBolText := {cMensa1,cMensa2,cMensa3,cMensa4,cMensa5,cMensa6,cMensa7,cMensa8}
	
				//===============================================================
				//BOLETO BANCO DO BRASIL           
				//===============================================================
				If cBanco == '001'        
					Prep001()
		
					//Neste trecho passa as impressão via menu e os emails em que se anexa PDF
					oFont6n := Nil 
					oFont10 := Nil 
					oFont8n := Nil 
					oFont10n:= Nil 
					oFont16n:= Nil
					oFont6n := TFont():New("Arial",,-6,.T.)
					oFont10 := TFont():New("Arial",,-10,.F.)
					oFont8n := TFont():New("Arial",,-8,.T.)
					oFont10n:= TFont():New("Arial",,-10,.T.)
					oFont16n:= TFont():New("Arial",,-16,.T.)
									
					oPrinter:StartPage()            
					
					//Monta layout
					oPrinter:SayBitmap(05,05, cLayOut, 600, 800)
					
					oPrinter:Say(54,39,  SubStr(aDadosEmp[1], 1, 30), oFont10n)  //Nome do cedente
		
					oPrinter:Say(52,270, Alltrim(SEE->EE_AGENCIA)+"-"+Alltrim(SEE->EE_DVAGE) + "/" + AllTrim(SEE->EE_CONTA) +"-"+(SEE->EE_DVCTA)/*aDadosBco[3] + " / " + aDadosBco[4]*/ , oFont10n)  //Agencia/conta-digito
							
					oPrinter:Say(52,380, AllTrim(cNum)+AllTrim(cParc)/*aDadosTit[6]*/, oFont10n)  //Nosso numero  
					oPrinter:Say(76,39,  SubStr(aDadosSac[1], 1, 30) + " " + aLLtRIM(SA1->A1_CGC), oFont10n)  //Nome do sacado
					oPrinter:Say(74,270, Dtoc(aDadosTit[4]), oFont10n)  //Vencto do titulo
					oPrinter:Say(74,390, TransForm(aDadosBco[7], "@E 999,999,999.99"), oFont10n)  //Valor do titulo
					oPrinter:Say(99,39,  Alltrim(aDadosEmp[2]) + " " +  Alltrim(aDadosEmp[3]) + " " + AllTrim(aDadosEmp[4]) , oFont10n)  //EndereÃ§o Beneficiario
								
					//Dados do quadro 1
					oPrinter:Say(162,210, aCB_RN_NN[2], oFont16n)  //Linha digitavel 
					oPrinter:Say(180,445, Dtoc(aDadosTit[4]), oFont10n)  //Vencto do titulo 
								
					oPrinter:Say(202,39,  SubStr(aDadosEmp[1], 1, 30)+ " CNPJ: " + aDadosEmp[6], oFont10n)  //Nome do cedente 
					
					oPrinter:Say(202,445, /*aDadosBco[3] + " / " + aDadosBco[4] */AllTrim(SEE->EE_AGENCIA) + "/" + AllTrim(SEE->EE_CONTA) +"-"+SEE->EE_DVCTA, oFont10n)  //Agencia/conta-digito 
								
					oPrinter:Say(224,50, Dtoc(aDadosTit[2]), oFont10n)  //emissao
					oPrinter:Say(224,150, /*aDadosTit[6]*/AllTrim(cNum)+AllTrim(cParc), oFont10n)  //Nosso numero
					oPrinter:Say(224,252, /*aDadosTit[8]*/'DM', oFont10n)  //tipo 
					oPrinter:Say(224,325, "N", oFont10n)  //aceite N
					oPrinter:Say(224,370, Dtoc(aDadosTit[2]), oFont10n)  //emissao e processamento
												
					oPrinter:Say(224,450, _cNossoNum, oFont10n)
												
					oPrinter:Say(239,140, "17", oFont10n) //carteira fixa BB
								
					oPrinter:Say(239,200, "R$", oFont10n)  //Especie
					oPrinter:Say(239,450, TransForm(aDadosBco[7], "@E 999,999,999.99"), oFont10n)  //Valor do titulo
					
					oPrinter:Say(258,45, &(aMsg[1]), oFont10n)  //Msg 1
					oPrinter:Say(267,45, &(aMsg[2]), oFont10n) //Msg 2     
														
					If SA1->A1_PESSOA == 'F'
						oPrinter:Say(342,43,  SubStr(aDadosSac[1], 1, 30)  +  " " + TransForm(SA1->A1_CGC, "@R 999.999.999-99") , oFont10n)  //Nome do sacado				
					Else
						oPrinter:Say(342,43,  SubStr(aDadosSac[1], 1, 30)  +  " " + TransForm(SA1->A1_CGC, "@R 99.999.999/9999-99") , oFont10n)  //Nome do sacado				
					Endif
																								
					oPrinter:Say(351,45, aDadosSac[3] + " " + aDadosSac[4] + " - " + aDadosSac[5] + " - CEP: " + TransForm(aDadosSac[6], "@R 99999-999"), oFont8n)  //Endereco
											
					//Dados do quadro 2
					oPrinter:Say(452, 210,aCB_RN_NN[2], oFont16n)  //Linha digitavel
					oPrinter:Say(472,445, Dtoc(aDadosTit[4]), oFont10n)  //Vencto do titulo                                               
								
					oPrinter:Say(496,39,  SubStr(aDadosEmp[1], 1, 30) + " CNPJ: " + aDadosEmp[6], oFont10n)  //Nome do cedente 
					
					oPrinter:Say(495,445, AllTrim(SEE->EE_AGENCIA)+"-"+Alltrim(SEE->EE_DVAGE) + "/" + AllTrim(SEE->EE_CONTA) +"-"+SEE->EE_DVCTA/*aDadosBco[3] + " / " + aDadosBco[4]*/ , oFont10n)  //Agencia/conta-digito 
		
					oPrinter:Say(517,50, Dtoc(aDadosTit[2]), oFont10n)  //emissao
					oPrinter:Say(517,150, /*aDadosTit[6]*/ AllTrim(cNum)+AllTrim(cParc)  , oFont10n)  //Nosso numero//<----------
					oPrinter:Say(517,252, /*aDadosTit[8]*/'DM', oFont10n)  //tipo 
					oPrinter:Say(517,325, "N", oFont10n)  //aceite N
					oPrinter:Say(517,370, Dtoc(aDadosTit[2]), oFont10n)  //emissao e processamento
								
					oPrinter:Say(519,450, _cNossoNum, oFont10n)		
							
					oPrinter:Say(535,140, "17", oFont10n)  //Carteira Bco Brasil
								
					oPrinter:Say(535,200, "R$", oFont10n)  //Especie
					oPrinter:Say(535,450, TransForm(aDadosBco[7], "@E 999,999,999.99"), oFont10n)  //Valor do titulo
					
					oPrinter:Say(550,45, &(aMsg[1]), oFont10n)  //Msg 1
					oPrinter:Say(559,45, &(aMsg[2]), oFont10n) //Msg 2 
			
					If SA1->A1_PESSOA == 'F'
						oPrinter:Say(635,43,  SubStr(aDadosSac[1] , 1, 30) +  " " + TransForm(SA1->A1_CGC, "@R 999.999.999-99") , oFont10n)  //Nome do sacado
					Else
						oPrinter:Say(635,43,  SubStr(aDadosSac[1] , 1, 30) +  " " + TransForm(SA1->A1_CGC, "@R 99.999.999/9999-99") , oFont10n)  //Nome do sacado							    
					EndIf                                                                                                                              
									
					oPrinter:Say(645,45, aDadosSac[3] + " " + aDadosSac[4] + " - " + aDadosSac[5] + " - CEP: " + TransForm(aDadosSac[6], "@R 99999-999"), oFont8n)  //Endereco
								
					//Impressao do codigo de barras
					oPrinter:FWMSBAR("INT25", 56/*63*/, 4, aCB_RN_NN[1], oPrinter, .F.,, .T., 0.020, 1, .F., "Arial", NIL, .F., 0.6, 1, .F.)
				
					oPrinter:EndPage()
					
				EndIf
	
				//===============================================================
				//BOLETO SANTANDER
				//===============================================================
				If cBanco == '033'        
					Prep033()
		
					//Neste trecho passa as impressão via menu e os emails em que se anexa PDF
					oFont6n := Nil 
					oFont10 := Nil 
					oFont8n := Nil 
					oFont10n:= Nil 
					oFont16n:= Nil
					oFont6n := TFont():New("Arial",,-6,.T.)
					oFont10 := TFont():New("Arial",,-10,.F.)
					oFont8n := TFont():New("Arial",,-8,.T.)
					oFont10n:= TFont():New("Arial",,-10,.T.)
					oFont16n:= TFont():New("Arial",,-16,.T.)

					oFont8  := TFont():New("Arial",,08,.T.)
					oFont16 := TFont():New("Arial",,-16,.T.)
					oFont20 := TFont():New("Arial",,-20,.T.)
					oFont24 := TFont():New("Arial",,-24,.T.)
				
					oPrinter:StartPage()            
					
					//Monta layout
					//oPrinter:SayBitmap(05,05, cLayOut, 600, 800) // Cyberpolos - 14/02/2022 //|Deixa de usar leiaute em imagem
									
					nTransporta := 200   
					nTrans2 := 205                                
					nTrans3 := 15

					//Linhas quadro 1

					//horizontais 
					oPrinter:Line(035,040,035,550) //1
					oPrinter:Line(060,040,060,445) //2
					oPrinter:Line(085,040,085,445) //3
					oPrinter:Line(107,260,107,445) //4
					oPrinter:Line(130,040,130,550) //5

					//vertical
					oPrinter:Line(015,125,035,125) //1
					oPrinter:Line(015,175,035,175) //2
					oPrinter:Line(035,260,130,260) //3
					oPrinter:Line(085,340,130,340) //4
					oPrinter:Line(035,365,085,365) //5
					oPrinter:Line(035,445,130,445) //6
					
					oPrinter:SayBitmap(010,040,cLayOut,70,22 )
					oPrinter:Say(030,0130,"033-7",oFont20)
					oPrinter:Say(030,450,"Comprovante de Entrega",oFont10)
					oPrinter:Say(045,450,"(  )Mudou-se",oFont8)
					oPrinter:Say(055,450,"(  )Ausente",oFont8)
					oPrinter:Say(065,450,"(  )Não existe nº indicado",oFont8)
					oPrinter:Say(075,450,"(  )Recusado",oFont8)
					oPrinter:Say(085,450,"(  )Não procurado",oFont8)
					oPrinter:Say(095,450,"(  )Endereço insuficiente",oFont8)
					oPrinter:Say(105,450,"(  )Desconhecido",oFont8)
					oPrinter:Say(115,450,"(  )Falecido",oFont8)
					oPrinter:Say(125,450,"(  )Outros(anotar no verso)",oFont8)

					//linha pontilhada 1
					For i := 040 TO 550 STEP 10
						oPrinter:Line(135,i,135,i+05)
					Next i 

					//Dados do quadro 1	
					oPrinter:Say(045,039,"Beneficiário",oFont8)				
					oPrinter:Say(054,039,  SubStr(aDadosEmp[1], 1, 30), oFont10n)  //Nome do cedente
					oPrinter:Say(045,265,"Agência/Cód. Beneficiário",oFont8)
					oPrinter:Say(054,270, Alltrim(SEE->EE_AGENCIA) + "/" + Alltrim(SEE->EE_CODEMP) /*aDadosBco[3] + " / " + aDadosBco[4]*/ , oFont10n)  //Agencia/conta-digito
					oPrinter:Say(045,370,"Nro. Documento",oFont8)
					oPrinter:Say(054,380, aDadosTit[7]+AllTrim(cNum)+AllTrim(cParc)/*aDadosTit[6]*/, oFont10n)  //Nosso numero  
					
					oPrinter:Say(068,039,"Pagador",oFont8)
					oPrinter:Say(077,039,  SubStr(aDadosSac[1], 1, 30) + " " + aLLtRIM(SA1->A1_CGC), oFont10n)  //Nome do sacado
					oPrinter:Say(068,265,"Vencimento",oFont8)
					oPrinter:Say(075,270, Dtoc(aDadosTit[4]), oFont10n)  //Vencto do titulo
					oPrinter:Say(068,370,"Valor do Documento",oFont8)
					oPrinter:Say(075,390, TransForm(aDadosBco[7], "@E 999,999,999.99"), oFont10n)  //Valor do titulo
					//oPrinter:Say(101,39,  Alltrim(aDadosEmp[2]) + " " +  Alltrim(aDadosEmp[3]) + " " + AllTrim(aDadosEmp[4]) , oFont10n)  //Endereço Beneficiario
					oPrinter:Say(095,039,  Alltrim(aDadosEmp[2]) , oFont10n)  //Endereço Beneficiario
					oPrinter:Say(104,039, Alltrim(aDadosEmp[3]) + " " + AllTrim(aDadosEmp[4]) , oFont10n)  //Endereço Beneficiario

					oPrinter:Say (113,049,"Recebi(emos) o bloqueto/título",oFont10)
					oPrinter:Say (122,049,"com as características acima.",oFont10)

					oPrinter:Say (92,265,"Data",oFont8)
					oPrinter:Say (92,345,"Assinatura",oFont8)
					oPrinter:Say (115,265,"Data",oFont8)
					oPrinter:Say (115,345,"Entregador",oFont8)	

					//linhas quadrado 2
					//horizontais 
					oPrinter:Line(165,040,165,550) //1
					oPrinter:Line(185,040,185,550) //2
					oPrinter:Line(205,040,205,550) //3
					oPrinter:Line(225,040,225,550) //4
					oPrinter:Line(245,040,245,550) //5
					oPrinter:Line(345,040,345,550) //6
					oPrinter:Line(395,040,395,550) //7

					//Horizontal linhas curtas
					oPrinter:Line(265,435,265,550) //8
					oPrinter:Line(285,435,285,550) //9
					oPrinter:Line(305,435,305,550) //10
					oPrinter:Line(325,435,325,550) //11					

					//vertical	
					oPrinter:Line(145,125,165,125) //1
					oPrinter:Line(145,175,165,175) //2				 
					oPrinter:Line(205,125,245,125) //3
					oPrinter:Line(225,185,245,185) //4
					oPrinter:Line(205,237,245,237) //5
					oPrinter:Line(205,310,225,310) //6
					oPrinter:Line(205,345,245,345) //7
					oPrinter:Line(165,435,345,435) //8					
					
					//Dados do quadro 2
					oPrinter:SayBitmap(140,040,cLayOut,70,22 )	
					oPrinter:Say(162,130,"033-7",oFont20)
					oPrinter:Say(143,450,"Recibo do Pagador",oFont10)
					oPrinter:Say(162,190, aCB_RN_NN[2], oFont16n)  //Linha digitavel 
					oPrinter:Say(173,039,"Local de Pagamento",oFont8)
					oPrinter:Say(180,120,"(PAGAR PREFERENCIALMENTE NO GRUPO SANTANDER - GC)",oFont10)
					oPrinter:Say(172,440,"Vencimento",oFont8)
					oPrinter:Say(182,445, Dtoc(aDadosTit[4]), oFont10n)  //Vencto do titulo 
					oPrinter:Say(192,39,"Beneficiário",oFont8)			
					oPrinter:Say(202,39,  SubStr(aDadosEmp[1], 1, 30)+ " CNPJ: " + aDadosEmp[6], oFont10n)  //Nome do cedente 
					oPrinter:Say(192,440,"Agência/Cód. Beneficiário",oFont8)
					oPrinter:Say(202,445, Alltrim(SEE->EE_AGENCIA) + "/" + Alltrim(SEE->EE_CODEMP) , oFont10n)  //Agencia/conta-digito     
					oPrinter:Say(212,039,"Data do Documento",oFont8)
					oPrinter:Say(222,050, Dtoc(aDadosTit[2]), oFont10n)  //emissao
					oPrinter:Say(212,130,"Nro. Documento",oFont8)
					oPrinter:Say(222,150, aDadosTit[7]+AllTrim(cNum)+AllTrim(cParc), oFont10n)  //Nosso numero
					oPrinter:Say(212,242,"Espécie Doc.",oFont8)
					oPrinter:Say(222,252, /*aDadosTit[8]*/'DM', oFont10n)  //tipo 
					oPrinter:Say(212,315,"Aceite",oFont8)
					oPrinter:Say(222,325, "N", oFont10n)  //aceite N
					oPrinter:Say(212,350,"Data do Processamento",oFont8)
					oPrinter:Say(222,370, Dtoc(aDadosTit[2]), oFont10n)  //emissao e processamento
					oPrinter:Say(212,440,"Nosso Número",oFont8)							
					oPrinter:Say(222,450, _cNossoNum+" - " + DigitSant(_cNossoNum), oFont10n)  //Nosso numero   + DIGITO
					oPrinter:Say(232,039,"Uso do Banco",oFont8)
					oPrinter:Say(232,130,"Carteira",oFont8)							
					oPrinter:Say(242,140, "101", oFont10n)  //carteira fixa santander
					oPrinter:Say(232,190,"Espécie",oFont8)			
					oPrinter:Say(242,200, "R$", oFont10n)  //Especie
					oPrinter:Say(232,242,"Quantidade",oFont8)
					oPrinter:Say(232,350,"Valor",oFont8)
					oPrinter:Say(232,440,"Valor do Documento",oFont8)
					oPrinter:Say(242,450, TransForm(aDadosBco[7], "@E 999,999,999.99"), oFont10n)  //Valor do titulo
										
					oPrinter:Say(252,440,"(-)Desconto/Abatimento",oFont8)					
					oPrinter:Say(272,440,"(-)Outras Deduções",oFont8)
					oPrinter:Say(292,440,"(+)Mora/Multa",oFont8)
					oPrinter:Say(312,440,"(+)Outros Acréscimos",oFont8)
					oPrinter:Say(332,440,"(=)Valor Cobrado",oFont8) 

					oPrinter:Say(252,039,"Instruções",oFont8)
					oPrinter:Say(262,45, &(aMsg[1]), oFont10n)  //Msg 1
					oPrinter:Say(272,45, &(aMsg[2]), oFont10n)  //Msg 2 
					oPrinter:Say(352,039,"Pagador",oFont8)  

					If SA1->A1_PESSOA == 'F'
						oPrinter:Say(362,43,  SubStr(aDadosSac[1], 1, 30)  +  " " + TransForm(SA1->A1_CGC, "@R 999.999.999-99") , oFont10n)  //Nome do sacado				
					Else
						oPrinter:Say(362,43,  SubStr(aDadosSac[1], 1, 30)  +  " " + TransForm(SA1->A1_CGC, "@R 99.999.999/9999-99") , oFont10n)  //Nome do sacado				
					EndIf						
					
					oPrinter:Say(372,43, aDadosSac[3] + " " + aDadosSac[4] + " - " + aDadosSac[5] + " - CEP: " + TransForm(aDadosSac[6], "@R 99999-999"), oFont8n)  //Endereco
					oPrinter:Say(392,039,"Sacador/Avalista",oFont8)	
					oPrinter:Say(403,350,"Autenticação Mecânica",oFont8)

					//linhas pontilhadas 2
					For i := 040 TO 550 STEP 10
						oPrinter:Line(425,i,425,i+05)
					Next i 

					//Linhas do quadro 3

					//horizontais 
					oPrinter:Line(455,040,455,550) //1
					oPrinter:Line(475,040,475,550) //2
					oPrinter:Line(495,040,495,550) //3
					oPrinter:Line(515,040,515,550) //4
					oPrinter:Line(535,040,535,550) //5
					oPrinter:Line(635,040,635,550) //6
					oPrinter:Line(685,040,685,550) //7
					
					//Horizontal linhas curtas
					oPrinter:Line(555,435,555,550) //8
					oPrinter:Line(575,435,575,550) //9
					oPrinter:Line(595,435,595,550) //10
					oPrinter:Line(615,435,615,550) //11					
					
					//vertical	
					oPrinter:Line(435,125,455,125) //1
					oPrinter:Line(435,175,455,175) //2				 
					oPrinter:Line(495,125,535,125) //3
					oPrinter:Line(515,185,535,185) //4
					oPrinter:Line(495,237,535,237) //5
					oPrinter:Line(495,310,515,310) //6
					oPrinter:Line(495,345,535,345) //7
					oPrinter:Line(455,435,635,435) //8

					//Dados do quadro 3
					oPrinter:SayBitmap(430,040,cLayOut,70,22 )
					oPrinter:Say(452,130,"033-7",oFont20)
					oPrinter:Say(452,190,aCB_RN_NN[2], oFont16n)  //Linha digitavel
					oPrinter:Say(463,039,"Local de Pagamento",oFont8)
					oPrinter:Say(470,120,"(PAGAR PREFERENCIALMENTE NO GRUPO SANTANDER - GC)",oFont10)
					oPrinter:Say(463,440,"Vencimento",oFont8)
					oPrinter:Say(472,445, Dtoc(aDadosTit[4]), oFont10n)  //Vencto do titulo                                               
					oPrinter:Say(482,039,"Beneficiário",oFont8) 			
					oPrinter:Say(492,039,  SubStr(aDadosEmp[1], 1, 30) + " CNPJ: " + aDadosEmp[6], oFont10n)  //Nome do cedente 
					oPrinter:Say(482,440,"Agência/Cód. Beneficiário",oFont8)			
					oPrinter:Say(492,445, Alltrim(SEE->EE_AGENCIA) + "/" + Alltrim(SEE->EE_CODEMP) /*aDadosBco[3] + " / " + aDadosBco[4]*/ , oFont10n)  //Agencia/conta-digito
					oPrinter:Say(502,039,"Data do Documento",oFont8)
					oPrinter:Say(512,050, Dtoc(aDadosTit[2]), oFont10n)  //emissao
					oPrinter:Say(502,130,"Nro. Documento",oFont8)
					oPrinter:Say(512,150, aDadosTit[7]+AllTrim(cNum)+AllTrim(cParc), oFont10n)  //Nosso numero
					oPrinter:Say(502,242,"Espécie Doc.",oFont8)
					oPrinter:Say(512,252, /*aDadosTit[8]*/'DM', oFont10n)  //tipo 
					oPrinter:Say(502,315,"Aceite",oFont8)
					oPrinter:Say(512,325, "N", oFont10n)  //aceite N
					oPrinter:Say(502,350,"Data do Processamento",oFont8)
					oPrinter:Say(512,370, Dtoc(aDadosTit[2]), oFont10n)  //emissao e processamento
					oPrinter:Say(502,440,"Nosso Número",oFont8)				
					oPrinter:Say(512,450, _cNossoNum+" - " + DigitSant(_cNossoNum), oFont10n)        
					oPrinter:Say(522,039,"Uso do Banco",oFont8)
					oPrinter:Say(522,130,"Carteira",oFont8)
					oPrinter:Say(532,140, "101", oFont10n)  //Carteira
					oPrinter:Say(522,190,"Espécie",oFont8)			
					oPrinter:Say(532,200, "R$", oFont10n)  //Especie
					oPrinter:Say(522,242,"Quantidade",oFont8)
					oPrinter:Say(522,350,"Valor",oFont8)
					oPrinter:Say(522,440,"Valor do Documento",oFont8)
					oPrinter:Say(532,450, TransForm(aDadosBco[7], "@E 999,999,999.99"), oFont10n)  //Valor do titulo
					
					oPrinter:Say(542,440,"(-)Desconto/Abatimento",oFont8)					
					oPrinter:Say(562,440,"(-)Outras Deduções",oFont8)
					oPrinter:Say(582,440,"(+)Mora/Multa",oFont8)
					oPrinter:Say(602,440,"(+)Outros Acréscimos",oFont8)
					oPrinter:Say(622,440,"(=)Valor Cobrado",oFont8) 

					oPrinter:Say(542,039,"Instruções",oFont8)
					oPrinter:Say(552,045, &(aMsg[1]), oFont10n)  //Msg 1
					oPrinter:Say(562,045, &(aMsg[2]),oFont10n)   //Msg 2 
					oPrinter:Say(642,039,"Pagador",oFont8)	  					
							
					If SA1->A1_PESSOA == 'F'
						oPrinter:Say(652,43,  SubStr(aDadosSac[1] , 1, 30) +  " " + TransForm(SA1->A1_CGC, "@R 999.999.999-99") , oFont10n)  //Nome do sacado
					Else
						oPrinter:Say(652,43,  SubStr(aDadosSac[1] , 1, 30) +  " " + TransForm(SA1->A1_CGC, "@R 99.999.999/9999-99") , oFont10n)  //Nome do sacado
					EndIf

					oPrinter:Say(662,43, aDadosSac[3] + " " + aDadosSac[4] + " - " + aDadosSac[5] + " - CEP: " + TransForm(aDadosSac[6], "@R 99999-999"), oFont8n)  //Endereco
					oPrinter:Say(692,039,"Sacador/Avalista",oFont8)	
					oPrinter:Say(692,350,"Autenticação Mecânica - Ficha de Compensação",oFont8)
					
					//Impressao do codigo de barras
					oPrinter:FWMSBAR("INT25", 57/*63*/, 3, aCB_RN_NN[1], oPrinter, .F.,, .T., 0.020, 1, .F., "Arial", NIL, .F., 0.6, 1, .F.)
						
					oPrinter:EndPage()

				EndIf
							
				//===============================================================
				//BOLETO ITAU - 
				//===============================================================
				If cBanco == '341'        
					//ImprITAU(oFont6n,oFont10,oFont8n,oFont10n,oFont16n,cLayOut, aBolText, aDadosEmp)   
					Prepa341()
	
					//Neste trecho passa as impressão via menu e os emails em que se anexa PDF
					oFont6n := Nil 
					oFont10 := Nil 
					oFont8n := Nil 
					oFont10n:= Nil 
					oFont16n:= Nil
					oFont6n := TFont():New("Arial",,-6,.T.)
					oFont10 := TFont():New("Arial",,-10,.F.)
					oFont8n := TFont():New("Arial",,-8,.T.)
					oFont10n:= TFont():New("Arial",,-10,.T.)
					oFont16n:= TFont():New("Arial",,-16,.T.)

					oFont18n:= TFont():New("Arial",,-18,.T.)

					oFont8  := TFont():New("Arial",,08,.T.)
					oFont16 := TFont():New("Arial",,-16,.T.)
					oFont20 := TFont():New("Arial",,-20,.T.)
					oFont24 := TFont():New("Arial",,-24,.T.)
									
					oPrinter:StartPage()  

					//linhas quadrado 1
					//horizontais 
					oPrinter:Line(118,025,118,560) //1
					oPrinter:Line(138,025,138,560) //2
					oPrinter:Line(158,025,158,560) //3
					oPrinter:Line(178,025,178,560) //4
					oPrinter:Line(198,025,198,560) //5
					
					//Vertical
					oPrinter:Line(118,025,198,025) //1
					oPrinter:Line(103,145,118,145) //2				 
					oPrinter:Line(103,190,118,190) //3

					oPrinter:Line(118,270,138,270) //4
					oPrinter:Line(118,370,138,370) //5
					oPrinter:Line(118,405,178,405) //6
					oPrinter:Line(118,460,138,460) //7

					oPrinter:Line(138,180,158,180) //8
					oPrinter:Line(138,300,178,300) //9

					oPrinter:Line(158,125,178,125) //10
					oPrinter:Line(158,225,178,225) //11
					oPrinter:Line(158,300,178,300) //12          
									
					//Monta layout
					//oPrinter:SayBitmap(05,05, cLayOut, 600, 800) // Cyberpolos - 14/02/2022 //|Deixa de usar leiaute em imagem
					oPrinter:SayBitmap(088,025,cLayOut,30,30 )	
								
					nTransporta := 200
					nTrans2     := 205
					nTrans3     := 15

					oPrinter:Say(113,055,"Banco Itaú S.A.",oFont16n)
					oPrinter:Say(115,150,"341-7",oFont18n)

					oPrinter:Say(315 - nTransporta,210-nTrans3, aCB_RN_NN[2], oFont16n)  //Linha digitavel
					oPrinter:Say(330- nTrans2,45-nTrans3,"Cedente",oFont8)								
					oPrinter:Say(340- nTrans2,45-nTrans3,  SubStr(aDadosEmp[1], 1, 30), oFont10n)  //Nome do cedente
					oPrinter:Say(330- nTrans2,290-nTrans3,"Agência / Código Cedente",oFont8) 
					oPrinter:Say(340- nTrans2,290-nTrans3, aDadosBco[3] + " / " + aDadosBco[4] + " - " + aDadosBco[5], oFont10n)  //Agencia/conta-digito
					oPrinter:Say(330- nTrans2,425-nTrans3,"Qualidade",oFont8) 
					oPrinter:Say(330- nTrans2,390-nTrans3,"Espécie",oFont8)
					oPrinter:Say(340- nTrans2,400-nTrans3, "R$", oFont10n)  //Especie
					oPrinter:Say(330- nTrans2,480-nTrans3,"Nosso Número",oFont8)																																					
					oPrinter:Say(340- nTrans2,480-nTrans3,(  "109"   + "/" + aCB_RN_NN[3] + "-" + ModDe10(aDadosBco[3]+aDadosBco[4]+"109"+aCB_RN_NN[3])  )   , oFont10n)  //Nosso numero	
					oPrinter:Say(350- nTrans2,45-nTrans3,"Número do Documento",oFont8)							
					oPrinter:Say(360- nTrans2,45-nTrans3,  aDadosTit[1], oFont10n)  //Numero do titulo
					oPrinter:Say(350- nTrans2,200-nTrans3,"CPF/CNPJ",oFont8)
					oPrinter:Say(360- nTrans2,200-nTrans3, aDadosEmp[6], oFont10n)  //CNPJ do emitente
					oPrinter:Say(350- nTrans2,320-nTrans3,"Vencimento",oFont8)
					oPrinter:Say(360- nTrans2,320-nTrans3, Dtoc(aDadosTit[4]), oFont10n)  //Vencto do titulo
					oPrinter:Say(350- nTrans2,425-nTrans3,"Valor documento",oFont8)
					oPrinter:Say(360- nTrans2,450-nTrans3, TransForm(aDadosBco[7], "@E 999,999,999.99"), oFont10n)  //Valor do titulo
					oPrinter:Say(370- nTrans2,45-nTrans3,"(-)Desconto/Abatimento",oFont8)					
					oPrinter:Say(370- nTrans2,145-nTrans3,"(-)Outras Deduções",oFont8)
					oPrinter:Say(370- nTrans2,245-nTrans3,"(+)Mora/Multa",oFont8)
					oPrinter:Say(370- nTrans2,320-nTrans3,"(+)Outros Acréscimos",oFont8)
					oPrinter:Say(370- nTrans2,425-nTrans3,"(=)Valor Cobrado",oFont8) 					
					oPrinter:Say(390- nTrans2,45-nTrans3,"Sacado",oFont8) 
					oPrinter:Say(400- nTrans2,45-nTrans3,  Alltrim(aDadosEmp[2]) + " " +  Alltrim(aDadosEmp[3]) + " " + AllTrim(aDadosEmp[4]) , oFont10n)  //EndereÃ§o Beneficiario
					oPrinter:Say(410- nTrans2,490-nTrans3,"Autenticação Mecânica",oFont8)
					
					//linhas pontilhadas 2
					For i := 025 TO 560 STEP 10
						oPrinter:Line(285,i,285,i+05)
					Next i	

					//linhas quadrado 2
					//horizontais 
					oPrinter:Line(328,025,328,560) //1
					oPrinter:Line(348,025,348,560) //2
					oPrinter:Line(368,025,368,560) //3
					oPrinter:Line(388,025,388,560) //4
					oPrinter:Line(408,025,408,560) //5
					oPrinter:Line(428,405,428,560) //6
					oPrinter:Line(448,405,448,560) //7
					oPrinter:Line(468,405,468,560) //8
					oPrinter:Line(488,405,488,560) //9
					oPrinter:Line(508,025,508,560) //10
					oPrinter:Line(548,025,548,560) //11
					
					//Vertical
					oPrinter:Line(313,145,328,145) //1				 
					oPrinter:Line(313,190,328,190) //2
					oPrinter:Line(328,025,548,025) //3
					oPrinter:Line(328,405,508,405) //4
					oPrinter:Line(368,125,408,125) //5
					oPrinter:Line(368,235,408,235) //6
					oPrinter:Line(368,295,388,295) //7
					oPrinter:Line(368,330,408,330) //8
					oPrinter:Line(388,190,408,190) //9					
					oPrinter:Line(538,405,548,405) //10

					//Dados do quadro 2
					oPrinter:SayBitmap(298,025,cLayOut,30,30 )
					oPrinter:Say(323,055,"Banco Itaú S.A.",oFont16n)
					oPrinter:Say(325,150,"341-7",oFont18n)					
					oPrinter:Say(525- nTransporta, 210-nTrans3,aCB_RN_NN[2], oFont16n)  //Linha digitavel

					oPrinter:Say(540- nTrans2,45-nTrans3,"Local de pagamento",oFont8)							
					oPrinter:Say(550- nTrans2,45-nTrans3,  "ATENÇÃO O VENCIMENTO PAGUE PREFERENCIALMENTE NO ITAÚ", oFont10n)  //Local de pagamento					
					oPrinter:Say(540- nTrans2,425-nTrans3,"Vencimento",oFont8)
					oPrinter:Say(550- nTrans2,450-nTrans3, Dtoc(aDadosTit[4]), oFont10n)  //Vencto do titulo
					oPrinter:Say(560- nTrans2,45-nTrans3,"Cedente",oFont8)
					oPrinter:Say(570- nTrans2,45-nTrans3,  SubStr(aDadosEmp[1], 1, 30), oFont10n)  //Nome do cedente
					oPrinter:Say(560- nTrans2,425-nTrans3,"Agência / Código Cedente",oFont8)
					oPrinter:Say(570- nTrans2,450-nTrans3, aDadosBco[3] + " / " + aDadosBco[4] + " - " + aDadosBco[5], oFont10n)  //Agencia/conta-digito
					oPrinter:Say(580- nTrans2,45-nTrans3,"Data do documento",oFont8)
					oPrinter:Say(590- nTrans2,45-nTrans3,  Dtoc(aDadosTit[2]), oFont10n)  //Emissao do titulo
					oPrinter:Say(580- nTrans2,145-nTrans3,"Nº documento",oFont8)
					oPrinter:Say(590- nTrans2,150-nTrans3, aDadosTit[1], oFont10n)  //Numero do titulo
					oPrinter:Say(580- nTrans2,255-nTrans3,"Espécie doc.",oFont8)												
					oPrinter:Say(590- nTrans2,270-nTrans3, "DM", oFont10n)  //Especie
					oPrinter:Say(580- nTrans2,315-nTrans3,"Aceite",oFont8)
					oPrinter:Say(590- nTrans2,325-nTrans3, "N", oFont10n)  //Aceite
					oPrinter:Say(580- nTrans2,350-nTrans3,"Data processamento",oFont8)
					oPrinter:Say(590- nTrans2,360-nTrans3, Dtoc(aDadosTit[3]), oFont10n)  //Data do processamento
					oPrinter:Say(580- nTrans2,420-nTrans3,"Nosso número",oFont8)
					oPrinter:Say(590- nTrans2,480-nTrans3,(  "109"   + "/" + aCB_RN_NN[3] + "-" + ModDe10(aDadosBco[3]+aDadosBco[4]+"109"+aCB_RN_NN[3])  )   , oFont10n)  //Nosso numero						
					oPrinter:Say(600- nTrans2,045-nTrans3,"Uso do banco ",oFont8)	
					oPrinter:Say(600- nTrans2,145-nTrans3,"Carteira",oFont8)	
					oPrinter:Say(610- nTrans2,145-nTrans3, aDadosBco[6], oFont10n)
					oPrinter:Say(600- nTrans2,210-nTrans3,"Espécie",oFont8)
					oPrinter:Say(610- nTrans2,215-nTrans3, "R$", oFont10n)  //Moeda
					oPrinter:Say(600- nTrans2,255-nTrans3,"Quantidade",oFont8)
					oPrinter:Say(600- nTrans2,350-nTrans3,"Valor documento",oFont8)
					oPrinter:Say(600- nTrans2,425-nTrans3,"(=)Valor documento",oFont8)
					oPrinter:Say(610- nTrans2,450-nTrans3, TransForm(aDadosBco[7], "@E 999,999,999.99"), oFont10n)  //Valor do titulo

					oPrinter:Say(620- nTrans2,45-nTrans3,"Instruções ( Texto de responsabilidade do cedente)",oFont8)					
					oPrinter:Say(635-nTrans2,45, &(aMsg[1]), oFont10n)  //Msg 1
					oPrinter:Say(645-nTrans2,45, &(aMsg[2]), oFont10n)  //Msg 2 

					oPrinter:Say(620- nTrans2,425-nTrans3,"(-)Desconto/Abatimento",oFont8)					
					oPrinter:Say(640- nTrans2,425-nTrans3,"(-)Outras Deduções",oFont8)
					oPrinter:Say(660- nTrans2,425-nTrans3,"(+)Mora/Multa",oFont8)
					oPrinter:Say(680- nTrans2,425-nTrans3,"(+)Outros Acréscimos",oFont8)
					oPrinter:Say(700- nTrans2,425-nTrans3,"(=)Valor Cobrado",oFont8) 
															
					oPrinter:Say(720- nTrans2,45-nTrans3,"Sacado",oFont8) 															
					oPrinter:Say(730- nTrans2,45, aDadosSac[2] + " / " + aDadosSac[1], oFont8n)  //Sacado							
						
					If SA1->A1_PESSOA == 'F'
						oPrinter:Say(730- nTrans2,360,"CNPJ: " + TransForm(aDadosSac[7], "@R 999.999.999-99"), oFont8n)  //CNPJ / CPF
					Else
						oPrinter:Say(730- nTrans2,360,"CNPJ: " + TransForm(aDadosSac[7], "@R 99.999.999/9999-99"), oFont8n)  //CNPJ / CPF
					EndIf
												
					oPrinter:Say(740- nTrans2,45, aDadosSac[3], oFont8n)  //Endereco
					oPrinter:Say(750- nTrans2,45, aDadosSac[4] + " - " + aDadosSac[5] + " - CEP: " + TransForm(aDadosSac[6], "@R 99999-999"), oFont8n)  //Mun. + Est + CEP

					oPrinter:Say(750- nTrans2,425-nTrans3,"Cód. baixa",oFont8) 
					oPrinter:Say(760- nTrans2,45-nTrans3,"Sacador/Avalista",oFont8)	
					oPrinter:Say(760- nTrans2,415-nTrans3,"Autenticação mecânica - Ficha de Compensação",oFont8)
																	
					//Impressao do codigo de barras
					oPrinter:FWMSBAR("INT25", 46, 2, aCB_RN_NN[1], oPrinter, .F.,, .T., 0.020, 1, .F., "Arial", NIL, .F., 0.6, 1, .F.)
													
					oPrinter:EndPage()                
					
				EndIf       
				/*
				RecLock("SE1",.F.)
					SE1->E1_XBOMAIL = '3'
				MsUnlock()
				*/
				nA++ 			
   		
   				(cAlias)->(DbSkip())

			EndDo

			oPrinter:Preview()    

			/*Ricardo Araujo*/
			If !lApi
				Sleep(9000)              
			EndIf
			
			//anexa no email se for um arquivo do rootpath
			If lSchedule          
				_cAttach1 := cPDFGer2 + cFilePdf + ".pdf"
			Else 		
				CpyT2S( oPrinter:cpathpdf+cFilePdf+".pdf", cPDFGer2, .F. )
				_cAttach1 := cPDFGer2 + cFilePdf + ".pdf"
			EndIf
				
			FreeObj(oPrinter)                 
			oPrinter := Nil	

			//_cBody    := MontaCorpo()

			//lEnvioOK := EnvMail(, _cEmail, _cCc, "", _cSubject, _cBody, _cAttach1,"")

			//If lEnvioOK		

			For nR := 1 To len(aRecno)

				SE1->(DbGoTo(aRecno[nR]))				

				If !Empty(SE1->E1_NUMBCO)

					If cUltTitulo <> SE1->E1_NUM // Ini - Antonio Ricardo de Araujo - 24/05/2023 - Corrigir Duplicidades no envio de Boletos
						_cBody   := MontaCorpo()
						lEnvioOK := EnvMail(, _cEmail, _cCc, "", _cSubject, _cBody, _cAttach1,"")
					EndIf                        // Fim - Antonio Ricardo de Araujo - 24/05/2023 - Corrigir Duplicidades no envio de Boletos

					If lEnvioOK
						RecLock("SE1",.F.)
							SE1->E1_XBOMAIL = '2'
						MsUnlock() 
					EndIf
					
				EndIf
				
				cUltTitulo := SE1->E1_NUM

			Next nR

			//EndIf	

			FERASE(_cAttach1)
			
		ElseIf nTipo = 2 //REIMPRESSAO DE BOLETOS

			SE1->(DbGoTo((cAlias)->RECNO))	                 
			cChave := (cAlias)->E1_PREFIXO + (cAlias)->E1_NUM       
			aStatus4 := {}                   
											
			cFilePdf:= ""                              
							
			cTimeFiltrado:= Time()
			cTimeFiltrado:= STRTRAN(cTimeFiltrado,":","",1,5)
			cFilePdf :=	"Boleto_"+SE1->E1_CLIENTE+"_"+AllTrim(SE1->E1_NUM)//+AllTrim(SE1->E1_PARCELA)+"_"+cTimeFiltrado
			//cParcela := Iif(!Empty(AllTrim(SE1->E1_PARCELA))," Pcl. "+AllTrim(SE1->E1_PARCELA),"")
   	
			if lAPi
				cPDFGer   := "/workflow/boletos/"
			EndIf	

			oPrinter := Nil           
			oPrinter := FWMSPrinter():New(cFilePdf, IMP_PDF, .F., cPDFGer/*cCaminhosPDF*/, .T.,,,,,,,.F.,)
			oPrinter:SetPortrait()
			oPrinter:SetPaperSize(9)
			oPrinter:SetDevice(IMP_PDF)
			oPrinter:cPathPDF :=cPDFGer//cPathPDF

			While (cAlias)->(!Eof()) .And. cChave == (cAlias)->E1_PREFIXO + (cAlias)->E1_NUM
				SE1->(DbGoTo((cAlias)->RECNO))	

				aAdd(aRecno,(cAlias)->RECNO)
		
				aTitulos := { ;
								SE1->E1_NUM,     ;
								SE1->E1_PREFIXO,  ;
							SE1->E1_PARCELA,   ;
							SE1->E1_TIPO,      ;
							SE1->E1_CLIENTE,  ;
							SE1->E1_LOJA,    ;
							'',             ;
							SE1->E1_PORTADO,;
							SE1->E1_AGEDEP  ;
						}              
	
	
				cNum    := aTitulos[1]
				cPrefix := aTitulos[2]
				cParc   := aTitulos[3]
				cTp     := aTitulos[4]
				cCli    := aTitulos[5]
				cLj     := aTitulos[6]			

				DbSelectArea("SA1")
				SA1->(DbSetOrder(1))
				If !SA1->(DbSeek(xFilial("SA1") + SE1->E1_CLIENTE + SE1->E1_LOJA))
					Return
				EndIf

				If  _cEnv == "TOTVS_SUNTECH" 
					_cEmail   := Alltrim(SA1->A1_EMAIL)
					_cCc      := Alltrim(GetMV("CP_BOLMAIL"))
					_cSubject := "Boleto HB - NF " + Alltrim(SE1->E1_NUM) //+ cParcela
				Else
					_cEmail   := 'suporte@hb.com.br' 
					_cCc      := ''
					_cSubject := "TESTE-HOMOLOGACAO - Boleto HB - NF " + Alltrim(SE1->E1_NUM) //+ cParcela
				EndIf
					
				//Como eh uma reimpressao o titulo ja tem um BANCO -pois ja foi gerado anteriormente
				//cBanco   := SE1->E1_PORTADO
				//cAgencia := SE1->E1_AGEDEPc
				//cConta   := SE1->E1_CONTA
				cBanco   := PadR(SE1->E1_XBCO,3)
				cAgencia := PadR(SE1->E1_XAGE,5)
				cConta   := PadR(SE1->E1_XCONTA,10)

				//Mensagens que serão impressas
				DbSelectArea("ZB2")
				ZB2->(DbSetOrder(1))
				ZB2->(DbGoTop())
				If ZB2->(DbSeek(FWxFilial("ZB2")+cBanco+cAgencia+cConta))
					While ZB2->(!EOF()) .And. ZB2->ZB2_BANCO == cBanco .And. ZB2->ZB2_AGENCI == cAgencia .And. ZB2->ZB2_CONTA == cConta
						aAdd(aMsg,ZB2->ZB2_FORMUL)
						ZB2->(DbSkip())  
					EndDo
				EndIf
				
				If AllTrim(cBanco) == '001'
					cLayOut := cImag001 //cPDFGer2 + "BOL001.JPG"
				Endif
	
				If AllTrim(cBanco)  == '033'
					cLayOut := cImag033 //cPDFGer2 + "BOL033.JPG"
				Endif
	
				If AllTrim(cBanco)  == '341'
					cLayOut := cImag341 //cPDFGer2 + "BOL341.JPG"
				Endif
				

				aDadosTit := {}
				aDadosBco := {}
				aDadosSac := {}
				aDados    := {}
				aTitulos  := {}	
				aCB_RN_NN := {}  
						
				If  Empty(SA1->A1_ENDCOB)
					aDadosSac := {  AllTrim(SA1->A1_NOME)                                		 	,; // [1]RazÃ£o Social
											AllTrim(SA1->A1_COD ) + "-" + SA1->A1_LOJA           	,; // [2]CÃ³digo
											AllTrim(SA1->A1_END ) + "-" + AllTrim(SA1->A1_BAIRRO)	,; // [3]EndereÃ§o
											AllTrim(SA1->A1_MUN )                                	,; // [4]Cidade
											SA1->A1_EST                                          	,; // [5]Estado
											SA1->A1_CEP                                          	,; // [6]CEP
											SA1->A1_CGC									         	,; // [7]CGC
											SA1->A1_PESSOA}	        								   // [8]PESSOA
				Else                                                                                    
						
					aDadosSac := {  AllTrim(SA1->A1_NOME)                                		 	,; // [1]RazÃ£o Social
											AllTrim(SA1->A1_COD ) + "-" + SA1->A1_LOJA           	,; // [2]CÃ³digo
											AllTrim(SA1->A1_ENDCOB ) + "-" + AllTrim(SA1->A1_BAIRRO),; // [3]EndereÃ§o
											AllTrim(SA1->A1_MUN )                                	,; // [4]Cidade
											SA1->A1_EST                                          	,; // [5]Estado
											SA1->A1_CEP                                          	,; // [6]CEP
											SA1->A1_CGC									         	,; // [7]CGC
											SA1->A1_PESSOA}	        								   // [8]PESSOA
				EndIf
				
				//===============================================================
				//BOLETO BANCO DO BRASIL
				//===============================================================
				If cBanco == '001'        
					Prep001A()
			
					//Neste trecho passa as impressão via menu e os emails em que se anexa PDF
					oFont6n := Nil 
					oFont10 := Nil 
					oFont8n := Nil 
					oFont10n:= Nil 
					oFont16n:= Nil
					oFont6n := TFont():New("Arial",,-6,.T.)
					oFont10 := TFont():New("Arial",,-10,.F.)
					oFont8n := TFont():New("Arial",,-8,.T.)
					oFont10n:= TFont():New("Arial",,-10,.T.)
					oFont16n:= TFont():New("Arial",,-16,.T.)
					oFont8  := TFont():New("Arial",,08,.T.)
								
					oPrinter:StartPage()            
					
					//Monta layout
					oPrinter:SayBitmap(05,05, cLayOut, 600, 800)
					
					
					oPrinter:Say(54,39,  SubStr(aDadosEmp[1], 1, 30), oFont10n)  //Nome do cedente
			
					oPrinter:Say(52,270, Alltrim(SEE->EE_AGENCIA)+"-"+Alltrim(SEE->EE_DVAGE) + "/" + AllTrim(SEE->EE_CONTA) +"-"+(SEE->EE_DVCTA)/*aDadosBco[3] + " / " + aDadosBco[4]*/ , oFont10n)  //Agencia/conta-digito
							
					oPrinter:Say(52,380, AllTrim(cNum)+AllTrim(cParc)/*aDadosTit[6]*/, oFont10n)  //Nosso numero  
					oPrinter:Say(76,39,  SubStr(aDadosSac[1], 1, 30) + " " + aLLtRIM(SA1->A1_CGC), oFont10n)  //Nome do sacado
					oPrinter:Say(74,270, Dtoc(aDadosTit[4]), oFont10n)  //Vencto do titulo
					oPrinter:Say(74,390, TransForm(aDadosBco[7], "@E 999,999,999.99"), oFont10n)  //Valor do titulo
					oPrinter:Say(99,39,  Alltrim(aDadosEmp[2]) + " " +  Alltrim(aDadosEmp[3]) + " " + AllTrim(aDadosEmp[4]) , oFont10n)  //EndereÃ§o Beneficiario
								
					//Dados do quadro 1
					oPrinter:Say(162,210, aCB_RN_NN[2], oFont16n)  //Linha digitavel 
					oPrinter:Say(180,445, Dtoc(aDadosTit[4]), oFont10n)  //Vencto do titulo 
								
					oPrinter:Say(202,39,  SubStr(aDadosEmp[1], 1, 30)+ " CNPJ: " + aDadosEmp[6], oFont10n)  //Nome do cedente 
					
					oPrinter:Say(202,445, /*aDadosBco[3] + " / " + aDadosBco[4] */AllTrim(SEE->EE_AGENCIA) + "/" + AllTrim(SEE->EE_CONTA) +"-"+SEE->EE_DVCTA, oFont10n)  //Agencia/conta-digito 
								
					oPrinter:Say(224,50, Dtoc(aDadosTit[2]), oFont10n)  //emissao
					oPrinter:Say(224,150, /*aDadosTit[6]*/AllTrim(cNum)+AllTrim(cParc), oFont10n)  //Nosso numero
					oPrinter:Say(224,252, /*aDadosTit[8]*/'DM', oFont10n)  //tipo 
					oPrinter:Say(224,325, "N", oFont10n)  //aceite N
					oPrinter:Say(224,370, Dtoc(aDadosTit[2]), oFont10n)  //emissao e processamento
					oPrinter:Say(224,450, _cNossoNum, oFont10n)
								
					oPrinter:Say(239,140, "17", oFont10n) //carteira fixa BB
								
					oPrinter:Say(239,200, "R$", oFont10n)  //Especie
					oPrinter:Say(239,450, TransForm(aDadosBco[7], "@E 999,999,999.99"), oFont10n)  //Valor do titulo
			
					oPrinter:Say(258,45, &(aMsg[1]), oFont10n)  //Msg 1
					oPrinter:Say(267,45, &(aMsg[2]),oFont10n)  //Msg 2    
														
					If SA1->A1_PESSOA == 'F'
						oPrinter:Say(342,43,  SubStr(aDadosSac[1], 1, 30)  +  " " + TransForm(SA1->A1_CGC, "@R 999.999.999-99") , oFont10n)  //Nome do sacado				
					Else
						oPrinter:Say(342,43,  SubStr(aDadosSac[1], 1, 30)  +  " " + TransForm(SA1->A1_CGC, "@R 99.999.999/9999-99") , oFont10n)  //Nome do sacado				
					EndIf
																								
					oPrinter:Say(351,45, aDadosSac[3] + " " + aDadosSac[4] + " - " + aDadosSac[5] + " - CEP: " + TransForm(aDadosSac[6], "@R 99999-999"), oFont8n)  //Endereco
											
					//Dados do quadro 2
					oPrinter:Say(452, 210,aCB_RN_NN[2], oFont16n)  //Linha digitavel
					oPrinter:Say(472,445, Dtoc(aDadosTit[4]), oFont10n)  //Vencto do titulo                                               
								
					oPrinter:Say(496,39,  SubStr(aDadosEmp[1], 1, 30) + " CNPJ: " + aDadosEmp[6], oFont10n)  //Nome do cedente 
									
					oPrinter:Say(495,445, AllTrim(SEE->EE_AGENCIA)+"-"+Alltrim(SEE->EE_DVAGE) + "/" + AllTrim(SEE->EE_CONTA) +"-"+SEE->EE_DVCTA/*aDadosBco[3] + " / " + aDadosBco[4]*/ , oFont10n)  //Agencia/conta-digito 

					oPrinter:Say(517,50, Dtoc(aDadosTit[2]), oFont10n)  //emissao
					oPrinter:Say(517,150, /*aDadosTit[6]*/ AllTrim(cNum)+AllTrim(cParc)  , oFont10n)  //Nosso numero//<----------
					oPrinter:Say(517,252, /*aDadosTit[8]*/'DM', oFont10n)  //tipo 
					oPrinter:Say(517,325, "N", oFont10n)  //aceite N
					oPrinter:Say(517,370, Dtoc(aDadosTit[2]), oFont10n)  //emissao e processamento
								
					oPrinter:Say(519,450, _cNossoNum, oFont10n)		
			
					oPrinter:Say(535,140, "17", oFont10n)  //Carteira Bco Brasil
								
					oPrinter:Say(535,200, "R$", oFont10n)  //Especie
					oPrinter:Say(535,450, TransForm(aDadosBco[7], "@E 999,999,999.99"), oFont10n)  //Valor do titulo
					
					oPrinter:Say(550,45, &(aMsg[1]), oFont10n)  //Msg 1
					oPrinter:Say(559,45, &(aMsg[2]), oFont10n)  //Msg 2    
				
					If SA1->A1_PESSOA == 'F'
						oPrinter:Say(635,43,  SubStr(aDadosSac[1] , 1, 30) +  " " + TransForm(SA1->A1_CGC, "@R 999.999.999-99") , oFont10n)  //Nome do sacado
					Else
						oPrinter:Say(635,43,  SubStr(aDadosSac[1] , 1, 30) +  " " + TransForm(SA1->A1_CGC, "@R 99.999.999/9999-99") , oFont10n)  //Nome do sacado							    
					EndIf                                                                                                                                    
										
					oPrinter:Say(645,45, aDadosSac[3] + " " + aDadosSac[4] + " - " + aDadosSac[5] + " - CEP: " + TransForm(aDadosSac[6], "@R 99999-999"), oFont8n)  //Endereco
								
					//Impressao do codigo de barras
					oPrinter:FWMSBAR("INT25", 56/*63*/, 4, aCB_RN_NN[1], oPrinter, .F.,, .T., 0.020, 1, .F., "Arial", NIL, .F., 0.6, 1, .F.)
				
					oPrinter:EndPage()
	
				EndIf     	   
				
				//===============================================================
				//BOLETO SANTANDER
				//===============================================================
				If cBanco == '033'        
				Prep033a()
								
				//Neste trecho passa as impressão via menu e os emails em que se anexa PDF
					oFont6n := Nil 
					oFont10 := Nil 
					oFont8n := Nil 
					oFont10n:= Nil 
					oFont16n:= Nil
					oFont6n := TFont():New("Arial",,-6,.T.)
					oFont10 := TFont():New("Arial",,10,.F.)
					oFont8n := TFont():New("Arial",,-8,.T.)
					oFont10n:= TFont():New("Arial",,-10,.T.)
					oFont16n:= TFont():New("Arial",,-16,.T.)

					oFont8  := TFont():New("Arial",,08,.T.)
					oFont16 := TFont():New("Arial",,-16,.T.)
					oFont20 := TFont():New("Arial",,-20,.T.)
					oFont24 := TFont():New("Arial",,-24,.T.)
								
					oPrinter:StartPage()            
					
					//Monta layout
					//oPrinter:SayBitmap(05,05, cLayOut, 600, 800) // Cyberpolos - 14/02/2022 //|Deixa de usar leiaute em imagem
														
					nTransporta := 200
					nTrans2     := 205
					nTrans3     := 15

					//Linhas quadro 1

					//horizontais 
					oPrinter:Line(035,040,035,550) //1
					oPrinter:Line(060,040,060,445) //2
					oPrinter:Line(085,040,085,445) //3
					oPrinter:Line(107,260,107,445) //4
					oPrinter:Line(130,040,130,550) //5

					//vertical
					oPrinter:Line(015,125,035,125) //1
					oPrinter:Line(015,175,035,175) //2
					oPrinter:Line(035,260,130,260) //3
					oPrinter:Line(085,340,130,340) //4
					oPrinter:Line(035,365,085,365) //5
					oPrinter:Line(035,445,130,445) //6
					
					oPrinter:SayBitmap(010,040,cLayOut,70,22 )
					oPrinter:Say (30,130,"033-7",oFont20)
					oPrinter:Say (30,450,"Comprovante de Entrega",oFont10)
					oPrinter:Say (045,450,"(  )Mudou-se",oFont8)
					oPrinter:Say (055,450,"(  )Ausente",oFont8)
					oPrinter:Say (065,450,"(  )Não existe nº indicado",oFont8)
					oPrinter:Say (075,450,"(  )Recusado",oFont8)
					oPrinter:Say (085,450,"(  )Não procurado",oFont8)
					oPrinter:Say (095,450,"(  )Endereço insuficiente",oFont8)
					oPrinter:Say (105,450,"(  )Desconhecido",oFont8)
					oPrinter:Say (115,450,"(  )Falecido",oFont8)
					oPrinter:Say (125,450,"(  )Outros(anotar no verso)",oFont8)
					
					//linha pontilhada 1
					For i := 040 TO 550 STEP 10
						oPrinter:Line(135,i,135,i+05)
					Next i 
					
					//Dados do quadro 1
					oPrinter:Say (45,39,"Beneficiário",oFont8)
					oPrinter:Say(54,39,  SubStr(aDadosEmp[1], 1, 30), oFont10n)  //Nome do cedente
					oPrinter:Say (45,265,"Agência/Cód. Beneficiário",oFont8)
					oPrinter:Say(54,270, Alltrim(SEE->EE_AGENCIA) + "/" + Alltrim(SEE->EE_CODEMP) /*aDadosBco[3] + " / " + aDadosBco[4]*/ , oFont10n)  //Agencia/conta-digito
					oPrinter:Say (45,370,"Nro. Documento",oFont8)
					oPrinter:Say(54,380, aDadosTit[7]+AllTrim(cNum)+AllTrim(cParc)/*aDadosTit[6]*/, oFont10n)  //Nosso numero  
					
					oPrinter:Say (68,39,"Pagador",oFont8)
					oPrinter:Say(77,39,  SubStr(aDadosSac[1], 1, 30) + " " + aLLtRIM(SA1->A1_CGC), oFont10n)  //Nome do sacado
					oPrinter:Say (68,265,"Vencimento",oFont8)
					oPrinter:Say(75,270, Dtoc(aDadosTit[4]), oFont10n)  //Vencto do titulo
					oPrinter:Say (68,370,"Valor do Documento",oFont8)
					oPrinter:Say(75,390, TransForm(aDadosBco[7], "@E 999,999,999.99"), oFont10n)  //Valor do titulo
					//oPrinter:Say(101,39,  Alltrim(aDadosEmp[2]) + " " +  Alltrim(aDadosEmp[3]) + " " + AllTrim(aDadosEmp[4]) , oFont10n)  //EndereÃ§o Beneficiario
					oPrinter:Say(95,39,  Alltrim(aDadosEmp[2]) , oFont10n)  //Endereço Beneficiario
					oPrinter:Say(104,39, Alltrim(aDadosEmp[3]) + " " + AllTrim(aDadosEmp[4]) , oFont10n)  //Endereço Beneficiario

					oPrinter:Say (113,049,"Recebi(emos) o bloqueto/título",oFont10)
					oPrinter:Say (122,049,"com as características acima.",oFont10)

					oPrinter:Say (92,265,"Data",oFont8)
					oPrinter:Say (92,345,"Assinatura",oFont8)
					oPrinter:Say (115,265,"Data",oFont8)
					oPrinter:Say (115,345,"Entregador",oFont8)

					//linhas quadrado 2
					//horizontais 
					oPrinter:Line(165,040,165,550) //1
					oPrinter:Line(185,040,185,550) //2
					oPrinter:Line(205,040,205,550) //3
					oPrinter:Line(225,040,225,550) //4
					oPrinter:Line(245,040,245,550) //5
					oPrinter:Line(345,040,345,550) //6
					oPrinter:Line(395,040,395,550) //7

					//Horizontal linhas curtas
					oPrinter:Line(265,435,265,550) //8
					oPrinter:Line(285,435,285,550) //9
					oPrinter:Line(305,435,305,550) //10
					oPrinter:Line(325,435,325,550) //11					

					//vertical	
					oPrinter:Line(145,125,165,125) //1
					oPrinter:Line(145,175,165,175) //2				 
					oPrinter:Line(205,125,245,125) //3
					oPrinter:Line(225,185,245,185) //4
					oPrinter:Line(205,237,245,237) //5
					oPrinter:Line(205,310,225,310) //6
					oPrinter:Line(205,345,245,345) //7
					oPrinter:Line(165,435,345,435) //8					
					
					//Dados do quadro 2
					oPrinter:SayBitmap(140,040,cLayOut,70,22 )	
					oPrinter:Say(162,130,"033-7",oFont20)
					oPrinter:Say(143,450,"Recibo do Pagador",oFont10)									
					oPrinter:Say(162,190, aCB_RN_NN[2], oFont16n)  //Linha digitavel 
					oPrinter:Say(173,039,"Local de Pagamento",oFont8)
					oPrinter:Say(180,120,"(PAGAR PREFERENCIALMENTE NO GRUPO SANTANDER - GC)",oFont10)
					oPrinter:Say(172,440,"Vencimento",oFont8)	
					oPrinter:Say(182,445, Dtoc(aDadosTit[4]), oFont10n)  //Vencto do titulo 
					oPrinter:Say(192,39,"Beneficiário",oFont8)
					oPrinter:Say(202,39,  SubStr(aDadosEmp[1], 1, 30)+ " CNPJ: " + aDadosEmp[6], oFont10n)  //Nome do cedente 
					oPrinter:Say(192,440,"Agência/Cód. Beneficiário",oFont8)
					oPrinter:Say(202,445, Alltrim(SEE->EE_AGENCIA) + "/" + Alltrim(SEE->EE_CODEMP) , oFont10n)  //Agencia/conta-digito  
					oPrinter:Say(212,039,"Data do Documento",oFont8)
					oPrinter:Say(222,050, Dtoc(aDadosTit[2]), oFont10n)  //emissao
					oPrinter:Say(212,130,"Nro. Documento",oFont8)
					oPrinter:Say(222,150, aDadosTit[7]+AllTrim(cNum)+AllTrim(cParc), oFont10n)  //Nosso numero
					oPrinter:Say(212,242,"Espécie Doc.",oFont8)
					oPrinter:Say(222,252, /*aDadosTit[8]*/'DM', oFont10n)  //tipo 
					oPrinter:Say(212,315,"Aceite",oFont8)
					oPrinter:Say(222,325, "N", oFont10n)  //aceite N
					oPrinter:Say(212,350,"Data do Processamento",oFont8)
					oPrinter:Say(222,370, Dtoc(aDadosTit[2]), oFont10n)  //emissao e processamento
					oPrinter:Say(212,440,"Nosso Número",oFont8)
					oPrinter:Say(222,450, _cNossoNum+" - " + DigitSant(_cNossoNum), oFont10n)  //Nosso numero   + DIGITO
					oPrinter:Say(232,039,"Uso do Banco",oFont8)
					oPrinter:Say(232,130,"Carteira",oFont8)
					oPrinter:Say(242,140, "101", oFont10n)  //carteira fixa santander
					oPrinter:Say(232,190,"Espécie",oFont8)
					oPrinter:Say(242,200, "R$", oFont10n)  //Especie
					oPrinter:Say(232,242,"Quantidade",oFont8)
					oPrinter:Say(232,350,"Valor",oFont8)
					oPrinter:Say(232,440,"Valor do Documento",oFont8)
					oPrinter:Say(242,450, TransForm(aDadosBco[7], "@E 999,999,999.99"), oFont10n)  //Valor do titulo
					
					oPrinter:Say(252,440,"(-)Desconto/Abatimento",oFont8)					
					oPrinter:Say(272,440,"(-)Outras Deduções",oFont8)
					oPrinter:Say(292,440,"(+)Mora/Multa",oFont8)
					oPrinter:Say(312,440,"(+)Outros Acréscimos",oFont8)
					oPrinter:Say(332,440,"(=)Valor Cobrado",oFont8) 

					oPrinter:Say(252,039,"Instruções",oFont8)
					oPrinter:Say(262,045, &(aMsg[1]), oFont10n)  //Msg 1
					oPrinter:Say(272,045, &(aMsg[2]), oFont10n)  //Msg 2  
					oPrinter:Say(352,039,"Pagador",oFont8)					

					If SA1->A1_PESSOA == 'F'
						oPrinter:Say(362,43,  SubStr(aDadosSac[1], 1, 30)  +  " " + TransForm(SA1->A1_CGC, "@R 999.999.999-99") , oFont10n)  //Nome do sacado				
					Else
						oPrinter:Say(362,43,  SubStr(aDadosSac[1], 1, 30)  +  " " + TransForm(SA1->A1_CGC, "@R 99.999.999/9999-99") , oFont10n)  //Nome do sacado				
					EndIf						
					
					oPrinter:Say(372,43, aDadosSac[3] + " " + aDadosSac[4] + " - " + aDadosSac[5] + " - CEP: " + TransForm(aDadosSac[6], "@R 99999-999"), oFont8n)  //Endereco
					oPrinter:Say(392,039,"Sacador/Avalista",oFont8)	
					oPrinter:Say(403,350,"Autenticação Mecânica",oFont8)

					//linhas pontilhadas 2
					For i := 040 TO 550 STEP 10
						oPrinter:Line(425,i,425,i+05)
					Next i 

					//Dados do quadro 3
					//Linhas do quadro 3

					//horizontais 
					oPrinter:Line(455,040,455,550) //1
					oPrinter:Line(475,040,475,550) //2
					oPrinter:Line(495,040,495,550) //3
					oPrinter:Line(515,040,515,550) //4
					oPrinter:Line(535,040,535,550) //5
					oPrinter:Line(635,040,635,550) //6
					oPrinter:Line(685,040,685,550) //7
					
					//Horizontal linhas curtas
					oPrinter:Line(555,435,555,550) //8
					oPrinter:Line(575,435,575,550) //9
					oPrinter:Line(595,435,595,550) //10
					oPrinter:Line(615,435,615,550) //11					
					
					//vertical	
					oPrinter:Line(435,125,455,125) //1
					oPrinter:Line(435,175,455,175) //2				 
					oPrinter:Line(495,125,535,125) //3
					oPrinter:Line(515,185,535,185) //4
					oPrinter:Line(495,237,535,237) //5
					oPrinter:Line(495,310,515,310) //6
					oPrinter:Line(495,345,535,345) //7
					oPrinter:Line(455,435,635,435) //8
					
					oPrinter:SayBitmap(430,040,cLayOut,70,22 )
					oPrinter:Say(452,130,"033-7",oFont20)
					oPrinter:Say(452,190,aCB_RN_NN[2], oFont16n)  //Linha digitavel
					oPrinter:Say(463,039,"Local de Pagamento",oFont8)
					oPrinter:Say(470,120,"(PAGAR PREFERENCIALMENTE NO GRUPO SANTANDER - GC)",oFont10)
					oPrinter:Say(463,440,"Vencimento",oFont8)
					oPrinter:Say(472,445, Dtoc(aDadosTit[4]), oFont10n)  //Vencto do titulo 
					oPrinter:Say(482,039,"Beneficiário",oFont8)                                              
					oPrinter:Say(492,039,  SubStr(aDadosEmp[1], 1, 30) + " CNPJ: " + aDadosEmp[6], oFont10n)  //Nome do cedente 
					oPrinter:Say(482,440,"Agência/Cód. Beneficiário",oFont8)
					oPrinter:Say(492,445, Alltrim(SEE->EE_AGENCIA) + "/" + Alltrim(SEE->EE_CODEMP) /*aDadosBco[3] + " / " + aDadosBco[4]*/ , oFont10n)  //Agencia/conta-digito
					oPrinter:Say(502,039,"Data do Documento",oFont8)
					oPrinter:Say(512,050, Dtoc(aDadosTit[2]), oFont10n)  //emissao
					oPrinter:Say(502,130,"Nro. Documento",oFont8)
					oPrinter:Say(512,150, aDadosTit[7]+AllTrim(cNum)+AllTrim(cParc), oFont10n)  //Nosso numero
					oPrinter:Say(502,242,"Espécie Doc.",oFont8)
					oPrinter:Say(512,252, /*aDadosTit[8]*/'DM', oFont10n)  //tipo 
					oPrinter:Say(502,315,"Aceite",oFont8)
					oPrinter:Say(512,325, "N", oFont10n)  //aceite N
					oPrinter:Say(502,350,"Data do Processamento",oFont8)
					oPrinter:Say(512,370, Dtoc(aDadosTit[2]), oFont10n)  //emissao e processamento
					oPrinter:Say(502,440,"Nosso Número",oFont8)
					oPrinter:Say(512,450, _cNossoNum+" - " + DigitSant(_cNossoNum), oFont10n)  
					oPrinter:Say(522,039,"Uso do Banco",oFont8)
					oPrinter:Say(522,130,"Carteira",oFont8)   
					oPrinter:Say(532,140, "101", oFont10n)  //Carteira
					oPrinter:Say(522,190,"Espécie",oFont8)
					oPrinter:Say(532,200, "R$", oFont10n)  //Especie
					oPrinter:Say(522,242,"Quantidade",oFont8)
					oPrinter:Say(522,350,"Valor",oFont8)
					oPrinter:Say(522,440,"Valor do Documento",oFont8)
					oPrinter:Say(532,450, TransForm(aDadosBco[7], "@E 999,999,999.99"), oFont10n)  //Valor do titulo

					oPrinter:Say(542,440,"(-)Desconto/Abatimento",oFont8)					
					oPrinter:Say(562,440,"(-)Outras Deduções",oFont8)
					oPrinter:Say(582,440,"(+)Mora/Multa",oFont8)
					oPrinter:Say(602,440,"(+)Outros Acréscimos",oFont8)
					oPrinter:Say(622,440,"(=)Valor Cobrado",oFont8) 

					oPrinter:Say(542,039,"Instruções",oFont8)
					oPrinter:Say(552,45, &(aMsg[1]), oFont10n)  //Msg 1
					oPrinter:Say(562,45, &(aMsg[2]), oFont10n)  //Msg 2  
					oPrinter:Say(642,039,"Pagador",oFont8)					
							
					If SA1->A1_PESSOA == 'F'
						oPrinter:Say(652,43,  SubStr(aDadosSac[1] , 1, 30) +  " " + TransForm(SA1->A1_CGC, "@R 999.999.999-99") , oFont10n)  //Nome do sacado
					Else
						oPrinter:Say(652,43,  SubStr(aDadosSac[1] , 1, 30) +  " " + TransForm(SA1->A1_CGC, "@R 99.999.999/9999-99") , oFont10n)  //Nome do sacado
					EndIf

					oPrinter:Say(662,43, aDadosSac[3] + " " + aDadosSac[4] + " - " + aDadosSac[5] + " - CEP: " + TransForm(aDadosSac[6], "@R 99999-999"), oFont8n)  //Endereco
					oPrinter:Say(692,039,"Sacador/Avalista",oFont8)	
					oPrinter:Say(692,350,"Autenticação Mecânica - Ficha de Compensação",oFont8)
			
					//Impressao do codigo de barras
					oPrinter:FWMSBAR("INT25", 57/*63*/, 3, aCB_RN_NN[1], oPrinter, .F.,, .T., 0.020, 1, .F., "Arial", NIL, .F., 0.6, 1, .F.)
						
					oPrinter:EndPage() 
													
				Endif
							
				//===============================================================
				//BOLETO ITAU - 
				//===============================================================
				If cBanco == '341'        
					//ImprITAa(oFont6n,oFont10,oFont8n,oFont10n,oFont16n,cLayOut, aBolText, aDadosEmp)         
					Prep341a()
	
					//Neste trecho passa as impressão via menu e os emails em que se anexa PDF
					oFont6n := Nil 
					oFont10 := Nil 
					oFont8n := Nil 
					oFont10n:= Nil 
					oFont16n:= Nil
					oFont6n := TFont():New("Arial",,-6,.T.)
					oFont10 := TFont():New("Arial",,-10,.F.)
					oFont8n := TFont():New("Arial",,-8,.T.)
					oFont10n:= TFont():New("Arial",,-10,.T.)
					oFont16n:= TFont():New("Arial",,-16,.T.)
					oFont18n:= TFont():New("Arial",,-18,.T.)

					oFont8  := TFont():New("Arial",,08,.T.)
					oFont16 := TFont():New("Arial",,-16,.T.)
					oFont20 := TFont():New("Arial",,-20,.T.)
					oFont24 := TFont():New("Arial",,-24,.T.)
									
					oPrinter:StartPage()            

					//linhas quadrado 1
					//horizontais 
					oPrinter:Line(118,025,118,560) //1
					oPrinter:Line(138,025,138,560) //2
					oPrinter:Line(158,025,158,560) //3
					oPrinter:Line(178,025,178,560) //4
					oPrinter:Line(198,025,198,560) //5
					
					//Vertical
					oPrinter:Line(118,025,198,025) //1
					oPrinter:Line(103,145,118,145) //2				 
					oPrinter:Line(103,190,118,190) //3

					oPrinter:Line(118,270,138,270) //4
					oPrinter:Line(118,370,138,370) //5
					oPrinter:Line(118,405,178,405) //6
					oPrinter:Line(118,460,138,460) //7

					oPrinter:Line(138,180,158,180) //8
					oPrinter:Line(138,300,178,300) //9

					oPrinter:Line(158,125,178,125) //10
					oPrinter:Line(158,225,178,225) //11
					oPrinter:Line(158,300,178,300) //12

					
									
					//Monta layout
					//oPrinter:SayBitmap(05,05, cLayOut, 600, 800)
					oPrinter:SayBitmap(088,025,cLayOut,30,30 )	
								
					nTransporta := 200
					nTrans2     := 205
					nTrans3     := 15

					oPrinter:Say(113,055,"Banco Itaú S.A.",oFont16n)
					oPrinter:Say(115,150,"341-7",oFont18n)

					oPrinter:Say(315 - nTransporta,210-nTrans3, aCB_RN_NN[2], oFont16n)  //Linha digitavel

					oPrinter:Say(330- nTrans2,45-nTrans3,"Cedente",oFont8) 								
					oPrinter:Say(340- nTrans2,45-nTrans3,  SubStr(aDadosEmp[1], 1, 30), oFont10n)  //Nome do cedente
					oPrinter:Say(330- nTrans2,290-nTrans3,"Agência / Código Cedente",oFont8) 
					oPrinter:Say(340- nTrans2,290-nTrans3, aDadosBco[3] + " / " + aDadosBco[4] + " - " + aDadosBco[5], oFont10n)  //Agencia/conta-digito
					oPrinter:Say(330- nTrans2,425-nTrans3,"Qualidade",oFont8) 
					oPrinter:Say(330- nTrans2,390-nTrans3,"Espécie",oFont8) 
					oPrinter:Say(340- nTrans2,400-nTrans3, "R$", oFont10n)  //Especie
					oPrinter:Say(330- nTrans2,480-nTrans3,"Nosso Número",oFont8)																																					
					oPrinter:Say(340- nTrans2,480-nTrans3,(  "109"   + "/" + aCB_RN_NN[3] + "-" + ModDe10(aDadosBco[3]+aDadosBco[4]+"109"+aCB_RN_NN[3])  )   , oFont10n)  //Nosso numero	
					oPrinter:Say(350- nTrans2,45-nTrans3,"Número do Documento",oFont8)							
					oPrinter:Say(360- nTrans2,45-nTrans3,  aDadosTit[1], oFont10n)  //Numero do titulo
					oPrinter:Say(350- nTrans2,200-nTrans3,"CPF/CNPJ",oFont8)
					oPrinter:Say(360- nTrans2,200-nTrans3, aDadosEmp[6], oFont10n)  //CNPJ do emitente
					oPrinter:Say(350- nTrans2,320-nTrans3,"Vencimento",oFont8)
					oPrinter:Say(360- nTrans2,320-nTrans3, Dtoc(aDadosTit[4]), oFont10n)  //Vencto do titulo
					oPrinter:Say(350- nTrans2,425-nTrans3,"Valor documento",oFont8)
					oPrinter:Say(360- nTrans2,450-nTrans3, TransForm(aDadosBco[7], "@E 999,999,999.99"), oFont10n)  //Valor do titulo
					oPrinter:Say(370- nTrans2,45-nTrans3,"(-)Desconto/Abatimento",oFont8)					
					oPrinter:Say(370- nTrans2,145-nTrans3,"(-)Outras Deduções",oFont8)
					oPrinter:Say(370- nTrans2,245-nTrans3,"(+)Mora/Multa",oFont8)
					oPrinter:Say(370- nTrans2,320-nTrans3,"(+)Outros Acréscimos",oFont8)
					oPrinter:Say(370- nTrans2,425-nTrans3,"(=)Valor Cobrado",oFont8) 					
					oPrinter:Say(390- nTrans2,45-nTrans3,"Sacado",oFont8) 	
					oPrinter:Say(400- nTrans2,45-nTrans3,  Alltrim(aDadosEmp[2]) + " " +  Alltrim(aDadosEmp[3]) + " " + AllTrim(aDadosEmp[4]) , oFont10n)  //EndereÃ§o Beneficiario
					oPrinter:Say(410- nTrans2,490-nTrans3,"Autenticação Mecânica",oFont8)						
										
					//linhas pontilhadas 2
					For i := 025 TO 560 STEP 10
						oPrinter:Line(285,i,285,i+05)
					Next i 

					//linhas quadrado 2
					//horizontais 
					oPrinter:Line(328,025,328,560) //1
					oPrinter:Line(348,025,348,560) //2
					oPrinter:Line(368,025,368,560) //3
					oPrinter:Line(388,025,388,560) //4
					oPrinter:Line(408,025,408,560) //5
					oPrinter:Line(428,405,428,560) //6
					oPrinter:Line(448,405,448,560) //7
					oPrinter:Line(468,405,468,560) //8
					oPrinter:Line(488,405,488,560) //9
					oPrinter:Line(508,025,508,560) //10
					oPrinter:Line(548,025,548,560) //11
					
					//Vertical
					oPrinter:Line(313,145,328,145) //1				 
					oPrinter:Line(313,190,328,190) //2
					oPrinter:Line(328,025,548,025) //3
					oPrinter:Line(328,405,508,405) //4
					oPrinter:Line(368,125,408,125) //5
					oPrinter:Line(368,235,408,235) //6
					oPrinter:Line(368,295,388,295) //7
					oPrinter:Line(368,330,408,330) //8
					oPrinter:Line(388,190,408,190) //9					
					oPrinter:Line(538,405,548,405) //10

					//Dados do quadro 2
					oPrinter:SayBitmap(298,025,cLayOut,30,30 )
					oPrinter:Say(323,055,"Banco Itaú S.A.",oFont16n)
					oPrinter:Say(325,150,"341-7",oFont18n)
					oPrinter:Say(525- nTransporta, 210-nTrans3,aCB_RN_NN[2], oFont16n)  //Linha digitavel

					oPrinter:Say(540- nTrans2,45-nTrans3,"Local de pagamento",oFont8)							
					oPrinter:Say(550- nTrans2,45-nTrans3,  "ATENÇÃO O VENCIMENTO PAGUE PREFERENCIALMENTE NO ITAÚ", oFont10n)  //Local de pagamento	
					oPrinter:Say(540- nTrans2,425-nTrans3,"Vencimento",oFont8)				
					oPrinter:Say(550- nTrans2,450-nTrans3, Dtoc(aDadosTit[4]), oFont10n)  //Vencto do titulo
					oPrinter:Say(560- nTrans2,45-nTrans3,"Cedente",oFont8)
					oPrinter:Say(570- nTrans2,45-nTrans3,  SubStr(aDadosEmp[1], 1, 30), oFont10n)  //Nome do cedente
					oPrinter:Say(560- nTrans2,425-nTrans3,"Agência / Código Cedente",oFont8)	
					oPrinter:Say(570- nTrans2,450-nTrans3, aDadosBco[3] + " / " + aDadosBco[4] + " - " + aDadosBco[5], oFont10n)  //Agencia/conta-digito
					oPrinter:Say(580- nTrans2,45-nTrans3,"Data do documento",oFont8)
					oPrinter:Say(590- nTrans2,45-nTrans3,  Dtoc(aDadosTit[2]), oFont10n)  //Emissao do titulo
					oPrinter:Say(580- nTrans2,145-nTrans3,"Nº documento",oFont8)
					oPrinter:Say(590- nTrans2,150-nTrans3, aDadosTit[1], oFont10n)  //Numero do titulo											
					oPrinter:Say(580- nTrans2,255-nTrans3,"Espécie doc.",oFont8)							
					oPrinter:Say(590- nTrans2,270-nTrans3, "DM", oFont10n)  //Especie
					oPrinter:Say(580- nTrans2,315-nTrans3,"Aceite",oFont8)
					oPrinter:Say(590- nTrans2,325-nTrans3, "N", oFont10n)  //Aceite
					oPrinter:Say(580- nTrans2,350-nTrans3,"Data processamento",oFont8)
					oPrinter:Say(590- nTrans2,360-nTrans3, Dtoc(aDadosTit[3]), oFont10n)  //Data do processamento
					oPrinter:Say(580- nTrans2,420-nTrans3,"Nosso número",oFont8)
					oPrinter:Say(590- nTrans2,480-nTrans3,(  "109"   + "/" + aCB_RN_NN[3] + "-" + ModDe10(aDadosBco[3]+aDadosBco[4]+"109"+aCB_RN_NN[3])  )   , oFont10n)  //Nosso numero						
					oPrinter:Say(600- nTrans2,045-nTrans3,"Uso do banco ",oFont8)	
					oPrinter:Say(600- nTrans2,145-nTrans3,"Carteira",oFont8)	
					oPrinter:Say(610- nTrans2,145-nTrans3, aDadosBco[6], oFont10n)				
					oPrinter:Say(600- nTrans2,210-nTrans3,"Espécie",oFont8)
					oPrinter:Say(610- nTrans2,215-nTrans3, "R$", oFont10n)  //Moeda
					oPrinter:Say(600- nTrans2,255-nTrans3,"Quantidade",oFont8)
					oPrinter:Say(600- nTrans2,350-nTrans3,"Valor documento",oFont8)
					oPrinter:Say(600- nTrans2,425-nTrans3,"(=)Valor documento",oFont8)
					oPrinter:Say(610- nTrans2,450-nTrans3, TransForm(aDadosBco[7], "@E 999,999,999.99"), oFont10n)  //Valor do titulo
					
					oPrinter:Say(620- nTrans2,45-nTrans3,"Instruções ( Texto de responsabilidade do cedente)",oFont8)
					oPrinter:Say(635-nTrans2,45, &(aMsg[1]), oFont10n)  //Msg 1
					oPrinter:Say(645-nTrans2,45, &(aMsg[2]), oFont10n)  //Msg 2  

					oPrinter:Say(620- nTrans2,425-nTrans3,"(-)Desconto/Abatimento",oFont8)					
					oPrinter:Say(640- nTrans2,425-nTrans3,"(-)Outras Deduções",oFont8)
					oPrinter:Say(660- nTrans2,425-nTrans3,"(+)Mora/Multa",oFont8)
					oPrinter:Say(680- nTrans2,425-nTrans3,"(+)Outros Acréscimos",oFont8)
					oPrinter:Say(700- nTrans2,425-nTrans3,"(=)Valor Cobrado",oFont8) 
															
					oPrinter:Say(720- nTrans2,45-nTrans3,"Sacado",oFont8)
					oPrinter:Say(730- nTrans2,45, aDadosSac[2] + " / " + aDadosSac[1], oFont8n)  //Sacado							
						
					If SA1->A1_PESSOA == 'F'
						oPrinter:Say(730- nTrans2,360,"CNPJ: " + TransForm(aDadosSac[7], "@R 999.999.999-99"), oFont8n)  //CNPJ / CPF
					Else
						oPrinter:Say(730- nTrans2,360,"CNPJ: " + TransForm(aDadosSac[7], "@R 99.999.999/9999-99"), oFont8n)  //CNPJ / CPF
					EndIf
												
					oPrinter:Say(740- nTrans2,45, aDadosSac[3], oFont8n)  //Endereco
					oPrinter:Say(750- nTrans2,45, aDadosSac[4] + " - " + aDadosSac[5] + " - CEP: " + TransForm(aDadosSac[6], "@R 99999-999"), oFont8n)  //Mun. + Est + CEP
					oPrinter:Say(750- nTrans2,425-nTrans3,"Cód. baixa",oFont8) 
					oPrinter:Say(760- nTrans2,45-nTrans3,"Sacador/Avalista",oFont8)	
					oPrinter:Say(760- nTrans2,415-nTrans3,"Autenticação mecânica - Ficha de Compensação",oFont8)		
												
					//Impressao do codigo de barras
					oPrinter:FWMSBAR("INT25", 46, 2, aCB_RN_NN[1], oPrinter, .F.,, .T., 0.020, 1, .F., "Arial", NIL, .F., 0.6, 1, .F.)
													
					oPrinter:EndPage()          
								
				Endif    

				/*
				RecLock("SE1",.F.)
					SE1->E1_XBOMAIL = '3'
				MsUnlock()    
				*/
				nA++  

				//Em caso de Status 4 pego informações para enviar no email
				If lStatus4 .and. len(aStatus4) < 1
					aStatus4  := {SE1->E1_NUM,SE1->E1_PARCELA,aDadosBco[7],Dtoc(aDadosTit[4]),Dtoc(SE1->E1_VENCREA),DaySum(SE1->E1_VENCREA, 5)}  //numero, parcela, valor, vencimento, vencimento real, vencimento real + 5 dias
				EndIf
   		
   				(cAlias)->(DbSkip())
			
			EndDo

			oPrinter:Preview()    

			/*Ricardo Araujo*/
			If !lApi
				Sleep(8000)              
			EndIf      

			//anexa no email se for um arquivo do rootpath
			If lSchedule 
				_cAttach1 := cPDFGer2 + cFilePdf + ".pdf"
			ElseIf lAPi
				_cAttach1 := cPDFGer + cFilePdf + ".pdf"
				cLinhaDig := aCB_RN_NN[2]
			Else
				CpyT2S( oPrinter:cpathpdf+cFilePdf+".pdf", cPDFGer2, .F. )
				_cAttach1 := cPDFGer2 + cFilePdf + ".pdf"
			Endif
				
			FreeObj(oPrinter)                 
			oPrinter := Nil	

			If !lApi
				_cBody    := MontaCorpo()

				lEnvioOK := EnvMail(, _cEmail, _cCc, "", _cSubject, _cBody, _cAttach1,"")

				If lEnvioOK					 	

					For nR := 1 To len(aRecno)
						SE1->(DbGoTo(aRecno[nR]))
						RecLock("SE1",.F.)
							SE1->E1_XBOMAIL = '2'
						MsUnlock() 
					Next nR

				EndIf	

				FERASE(_cAttach1)      
			else
				aAdd(aRetApi, {_cAttach1, cLinhaDig})
			EndIf
        Endif		
	
    EndDo		    
	
	If lApi
		return aRetApi
	EndIf

	//MsgAlert("Foram gerados " + cValToChar(nA) + " boletos.")
    
Return

//=========================================================================================
Static Function  Prep001()
	
	Local cNroDoc,  _nVlrAbat := 0, cParcel := ''
	Private cBarra := '', cLinha := ''      
	
	DbSelectArea("SA6")
	DbSelectArea("SEE")
	SA6->(DbSetOrder(1))
	SEE->(DbSetOrder(1))
	SA6->(DbSeek(xFilial("SA6") + cBanco + cAgencia + cConta))
	SEE->(DbSeek(xFilial("SEE") + cBanco + cAgencia + cConta))
	
	If !Empty(SE1->E1_NUMBCO) .And. Len(Alltrim(SE1->E1_NUMBCO)) == 12
		_cNossoNum := AllTrim(SEE->EE_CODEMP) + SubSTr(SE1->E1_NUMBCO, 3, 12)
		_cNossoNum := AllTrim(_cNossoNum)       
		cNroDoc := SubSTr(SE1->E1_NUMBCO, 3, 12)	 
	Else
		_cNossoNum := Alltrim(SEE->EE_CODEMP) + SubSTr(SEE->EE_FAXATU, 3, 12)  
		_cNossoNum := AllTrim(_cNossoNum) 
		cNroDoc	:= SubSTr(SEE->EE_FAXATU, 3, 12)
		RecLock("SEE",.F.)
			SEE->EE_FAXATU := Soma1(Alltrim(SEE->EE_FAXATU))
		MsUnlock()		
	EndIf	  	
    
    //Monta codigo de barras
	aDadosBanco  := {SEE->EE_CODIGO  									                ,; // [1]	Numero do Banco
	                'nBanco'							            					,; // [2]	Nome do Banco
                     SUBSTR(SEE->EE_AGENCIA,1,4)							            ,; // [3]	AgÃªncia
                     SUBSTR(SA6->A6_NUMCON,1,Len(AllTrim(SA6->A6_NUMCON)))				,; // [4]	Conta Corrente
                     SUBSTR(SA6->A6_DVCTA,1,Len(AllTrim(SA6->A6_DVCTA)))				,; // [5]	DÃ­gito da conta corrente
                     SUBSTR(SEE->EE_SUBCTA,1,3)                             			,; // [6]	Codigo da Carteira
                     SEE->EE_IOF                                     					,; // [7]	IOF
                     SEE->EE_INSTPRI                                 					,; // [8]	Instrucao Primaria
                     SEE->EE_INSTSEC                                 					,; // [9]	Instrucao Primaria
	                 'BmpBanco' }	 													   // [10]	Loggotipo Banco
    
	aDadosBco := {	SA6->A6_COD															,; // [1]Numero do Banco
					SA6->A6_NREDUZ														,; // [2]Nome do Banco
	                SUBSTR(SA6->A6_AGENCIA, 1, 4)+"-"+SUBSTR(SA6->A6_AGENCIA, 5, 5)		,; // [3]AgÃªncia
                    SUBSTR(SA6->A6_NUMCON,1,Len(AllTrim(SA6->A6_NUMCON))-1)				,; // [4]Conta Corrente
                    SUBSTR(SA6->A6_NUMCON,Len(AllTrim(SA6->A6_NUMCON)),1)  				,; // [5]DÃ­gito da conta corrente
                    "17"}


	_nVlrAbat := SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",1,,SE1->E1_CLIENTE,SE1->E1_LOJA) + SE1->E1_DECRESC - SE1->E1_ACRESC
	aAdd(aDadosBco, (SE1->E1_VALOR - _nVlrAbat))				
	cParcel  := If(Empty(SE1->E1_PARCELA),"0",SE1->E1_PARCELA)

	//Monta codigo de barras    
	aCB_RN_NN    :=codbarBB(	SE1->E1_PREFIXO	,SE1->E1_NUM	,SE1->E1_PARCELA	,SE1->E1_TIPO	,;
						Subs(aDadosBanco[1],1,3)	,substr(aDadosBanco[3],1,4)	,aDadosBanco[4] ,aDadosBanco[5]	,;
						cNroDoc		,_nVlrAbat	, "17"	,"9", SE1->E1_VENCTO	)


            	                            
    aDadosTit := {AllTrim(SE1->E1_NUM)+AllTrim(SE1->E1_PARCELA)		,;  //	[1]	Numero do titulo
					SE1->E1_EMISSAO									,;  //	[2]	Data da emissao do ti­tulo
					dDataBase										,;  //	[3]	Data da emissao do boleto
					SE1->E1_VENCTO									,;  //	[4]	Data do vencimento
					(SE1->E1_SALDO - _nVlrAbat) 					,;  //	[5]	Valor do ti­tulo
					aCB_RN_NN[3]									,;  //	[6]	Nosso numero (Ver formula para calculo)
					SE1->E1_PREFIXO									,;  //	[7]	Prefixo da NF
					SE1->E1_TIPO } 								  		//	[8]	Tipo do Titulo

	
	If Empty(SE1->E1_NUMBCO) .Or. Len(Alltrim(SE1->E1_NUMBCO)) == 8//se jÃ¡ nao foi impresso			
	 	DbSelectArea("SE1")
		RecLock("SE1",.F.)  
			SE1->E1_NUMBCO 	:= '00' + SubStr(_cNossoNum, 8, 10)  
			//(+)Adicionado por taki em 16/09/18
			SE1->E1_XBCO	:= cBanco
			SE1->E1_XAGE	:= cAgencia
			SE1->E1_XCONTA	:= cConta
		MsUnlock()
	Endif
				
return


//=========================================================================================
Static Function  Prep001a()
	
	Local _nVlrAbat := 0
	Local cParcel := ''
	Private cBarra := ''      
	Private cLinha := ''      
	
	DbSelectArea("SA6")
	DbSelectArea("SEE")
	SA6->(DbSetOrder(1))
	SEE->(DbSetOrder(1))
	SA6->(DbSeek(xFilial("SA6") + cBanco + cAgencia + cConta))
	SEE->(DbSeek(xFilial("SEE") + cBanco + cAgencia + cConta))	

   //SE1->E1_NUMBCO := '00' + SubStr(_cNossoNum, 8, 10)  
   _cNossoNum := substr(SE1->E1_NUMBCO,3,10)
	cNroDoc := SubSTr(SE1->E1_NUMBCO, 3, 12)	    
	
   //Monta codigo de barras
	aDadosBanco  := {SEE->EE_CODIGO  									            ,; // [1]Numero do Banco
	                'nBanco'							            				,; // [2]Nome do Banco
                     SUBSTR(SEE->EE_AGENCIA,1,4)							        ,; // [3]AgÃªncia
                     SUBSTR(SA6->A6_NUMCON,1,Len(AllTrim(SA6->A6_NUMCON)))			,; // [4]Conta Corrente
                     SUBSTR(SA6->A6_DVCTA,1,Len(AllTrim(SA6->A6_DVCTA)))			,; // [5]DÃ­gito da conta corrente
                     SUBSTR(SEE->EE_SUBCTA,1,3)                             		,; // [6]Codigo da Carteira
                     SEE->EE_IOF                                     				,; // [7]IOF
                     SEE->EE_INSTPRI                                 				,; // [8]Instrucao Primaria
                     SEE->EE_INSTSEC                        				        ,; // [9]Instrucao Primaria
	                 'BmpBanco' }												       // [10]Loggotipo Banco
    
	aDadosBco := {	SA6->A6_COD														,; // [1]Numero do Banco
					SA6->A6_NREDUZ													,; // [2]Nome do Banco
	                SUBSTR(SA6->A6_AGENCIA, 1, 4)+"-"+SUBSTR(SA6->A6_AGENCIA, 5, 5)	,; // [3]AgÃªncia
                    SUBSTR(SA6->A6_NUMCON,1,Len(AllTrim(SA6->A6_NUMCON))-1)			,; // [4]Conta Corrente
                    SUBSTR(SA6->A6_NUMCON,Len(AllTrim(SA6->A6_NUMCON)),1)			,; // [5]DÃ­gito da conta corrente
                    "17"}

	_nVlrAbat := SomaAbat(SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,"R",1,,SE1->E1_CLIENTE,SE1->E1_LOJA) + SE1->E1_DECRESC - SE1->E1_ACRESC
	aAdd(aDadosBco, (SE1->E1_VALOR - _nVlrAbat))				
	
   cParcel  := If(Empty(SE1->E1_PARCELA),"0",SE1->E1_PARCELA)

	//Monta codigo de barras    
	aCB_RN_NN    :=codbarBB(	SE1->E1_PREFIXO	,SE1->E1_NUM	,SE1->E1_PARCELA	,SE1->E1_TIPO	,;
						Subs(aDadosBanco[1],1,3)	,substr(aDadosBanco[3],1,4)	,aDadosBanco[4] ,aDadosBanco[5]	,;
						cNroDoc		,_nVlrAbat	, "17"	,"9", SE1->E1_VENCTO	)
             
   aDadosTit := {AllTrim(SE1->E1_NUM)+AllTrim(SE1->E1_PARCELA)	,;  //	[1]	NÃºmero do titulo
					SE1->E1_EMISSAO								,;  //	[2]	Data da emissao do ti­tulo
					dDataBase									,;  //	[3]	Data da emissao do boleto
					SE1->E1_VENCTO								,;  //	[4]	Data do vencimento
					(SE1->E1_SALDO - _nVlrAbat) 				,;  //	[5]	Valor do titulo
					aCB_RN_NN[3]								,;  //	[6]	Nosso numero (Ver formula para calculo)
					SE1->E1_PREFIXO								,;  //	[7]	Prefixo da NF
					SE1->E1_TIPO }   								//	[8]	Tipo do Titulo

Return

//================================================================================
Static Function CALC_diBB(cVariavel)

	Local Auxi := 0
	Local sumdig := 0

	cbase  := cVariavel
	lbase  := LEN(cBase)
	base   := 9
	sumdig := 0
	Auxi   := 0
	iDig   := lBase
	While iDig >= 1
		If base == 1
			base := 9
		EndIf
		auxi   := Val(SubStr(cBase, idig, 1)) * base
		sumdig := SumDig+auxi
		base   := base - 1
		iDig   := iDig-1
	EndDo
	auxi := mod(Sumdig,11)
	If auxi == 10
		auxi := "X"
	Else
		auxi := str(auxi,1,0)
	EndIf

Return(auxi)
//================================================================================
Static Function codbarBB(	cPrefixo	,cNumero	,cParcela	,cTipo	,;
						cBanco		,cAgencia	,cConta		,cDacCC	,;
						cNroDoc		,nValor		,cCart		,cMoeda	, dVencto )

	Local cNosso		:= ""
	Local cDigNosso		:= ""
	Local NNUM			:= ""
	Local cCampoL		:= ""
	Local cFatorValor	:= ""
	Local cLivre		:= ""
	Local cDigBarra		:= ""
	Local cBarra		:= ""
	Local cParte1		:= ""
	Local cDig1			:= ""
	Local cParte2		:= ""
	Local cDig2			:= ""
	Local cParte3		:= ""
	Local cDig3			:= ""
	Local cParte4		:= ""
	Local cParte5		:= ""
	Local cDigital		:= ""
	Local aRet			:= {}
	Local nTam := Len( AllTrim(SEE->EE_CODEMP) )
	Local lConvenio6 := .F.

	cAgencia:=STRZERO(Val(cAgencia),4)
			
	cNosso := ""    

	If lConvenio6
		NNUM := StrZero(Val(SEE->EE_CODEMP),nTam)+StrZero(Val(cNroDoc),5)	//STRZERO(Val(cNroDoc),11)
		//Nosso Numero
		cDigNosso  := CALC_diBB(NNUM)
		cNosso     := NNUM +"-"+ cDigNosso

		// campo livre			// verificar a conta e carteira
		cCampoL := NNUM+substr(SE1->E1_AGEDEP,1,4)+STRZERO(VAL(SE1->E1_CONTA),8)+cCart
	Else
		NNUM := StrZero(Val(SEE->EE_CODEMP),nTam)+StrZero(Val(cNroDoc),10)	//STRZERO(Val(cNroDoc),11)
		cCampoL := "000000" + NNUM+"17"//"21"
	EndIf
                                                                   
	//campo livre do codigo de barra                   // verificar a conta
	If nValor > 0
		cFatorValor  := fatorBB(dVencto)+strzero(nValor*100,10)
	Else
		cFatorValor  := fatorBB(dVencto)+strzero(SE1->E1_SALDO*100,10)
	EndIf

	cLivre := cBanco+cMoeda+cFatorValor+cCampoL

	// campo do codigo de barra
	cDigBarra := CALC_5pBB( cLivre )
	cBarra    := Substr(cLivre,1,4)+cDigBarra+Substr(cLivre,5,40)

	// composicao da linha digitavel
	cParte1  := cBanco+cMoeda
	cParte1  := cParte1 + SUBSTR(cBarra,20,5)
	cDig1    := DIGIT0BB( cParte1 )
	cParte2  := SUBSTR(cBarra,25,10)
	cDig2    := DIGIT0BB( cParte2 )
	cParte3  := SUBSTR(cBarra,35,10)
	cDig3    := DIGIT0BB( cParte3 )
	cParte4  := " "+cDigBarra+" "
	cParte5  := cFatorValor

	cDigital := substr(cParte1,1,5)+"."+substr(cparte1,6,4)+cDig1+" "+;
				substr(cParte2,1,5)+"."+substr(cparte2,6,5)+cDig2+" "+;
				substr(cParte3,1,5)+"."+substr(cparte3,6,5)+cDig3+" "+;
				cParte4+;
				cParte5

	Aadd(aRet,cBarra)
	Aadd(aRet,cDigital) 

	If lConvenio6
		Aadd(aRet,NNUM+"-"+cDigNosso)		
	Else
		Aadd(aRet,NNUM)		
	EndIf

Return aRet

//-----------------------------------------------------------------------
Static Function CALC_5pBB(cVariavel)

	Local Auxi := 0
	Local sumdig := 0

	cbase  := cVariavel
	lbase  := LEN(cBase)
	base   := 2
	sumdig := 0
	Auxi   := 0
	iDig   := lBase
	While iDig >= 1
		If base >= 10
			base := 2
		EndIf
		auxi   := Val(SubStr(cBase, idig, 1)) * base
		sumdig := SumDig+auxi
		base   := base + 1
		iDig   := iDig-1
	EndDo
	auxi := mod(sumdig,11)
	If auxi == 0 .or. auxi == 1 .or. auxi >= 10
		auxi := 1
	Else
		auxi := 11 - auxi
	EndIf

Return(str(auxi,1,0))

//-----------------------------------------------------------------------
Static Function DIGIT0BB(cVariavel)

	Local Auxi := 0
	Local sumdig := 0

	cbase  := cVariavel
	lbase  := LEN(cBase)
	umdois := 2
	sumdig := 0
	Auxi   := 0
	iDig   := lBase

	While iDig >= 1
		auxi   := Val(SubStr(cBase, idig, 1)) * umdois
		sumdig := SumDig+If (auxi < 10, auxi, (auxi-9))
		umdois := 3 - umdois
		iDig:=iDig-1
	EndDo

	cValor:=AllTrim(STR(sumdig,12))
	nDezena:=VAL(ALLTRIM(STR(VAL(SUBSTR(cvalor,1,1))+1,12))+"0")
	auxi := nDezena - sumdig

	If auxi >= 10
		auxi := 0
	EndIf

Return(str(auxi,1,0))
//-----------------------------------------------------------------------

Static function FatorBB(dVencto)
	If Len(ALLTRIM(SUBSTR(DTOC(dVencto),7,4))) = 4
		cData := SUBSTR(DTOC(dVencto),7,4)+SUBSTR(DTOC(dVencto),4,2)+SUBSTR(DTOC(dVencto),1,2)
	Else
		cData := "20"+SUBSTR(DTOC(dVencto),7,2)+SUBSTR(DTOC(dVencto),4,2)+SUBSTR(DTOC(dVencto),1,2)
	EndIf
	cFator := STR(1000+(STOD(cData)-STOD("20000703")),4)

Return(cFator)

//===============================================================================
Static Function Prep033()

	Local _nVlrAbat := 0
	Local cParcel   := ' '
	Local cNroDoc   := ''

	DbSelectArea("SA6")
	DbSelectArea("SEE")
	SA6->(DbSetOrder(1))
	SEE->(DbSetOrder(1))
	SA6->(DbSeek(xFilial("SA6") + cBanco + cAgencia + cConta))
	SEE->(DbSeek(xFilial("SEE") + cBanco + cAgencia + cConta))
	            
 	If !Empty(SE1->E1_NUMBCO) .And. Len(Alltrim(SE1->E1_NUMBCO)) == 12	 
		_cNossoNum := SE1->E1_NUMBCO
		_cNossoNum := AllTrim(_cNossoNum)       
		cNroDoc := SE1->E1_NUMBCO
	Else		                                  
		_cNossoNum := SEE->EE_FAXATU  
		_cNossoNum := AllTrim(_cNossoNum) 
		cNroDoc	:= SEE->EE_FAXATU
		RecLock("SEE",.F.)
			SEE->EE_FAXATU := Soma1(Alltrim(SEE->EE_FAXATU))
		MsUnlock()
	EndIf
	
	//Monta codigo de barras
	aDadosBanco  := {	SEE->EE_CODIGO  									     ,;	//	[1]	Numero do Banco
	                	'nBanco'							            		 ,;	//	[2]	Nome do Banco
                     	SUBSTR(SEE->EE_AGENCIA,1,4)							     ,;	//	[3]	AgÃªncia
	                 	SUBSTR(SA6->A6_NUMCON,1,Len(AllTrim(SA6->A6_NUMCON)))	 ,;	//	[4]	Conta Corrente
	                  	SUBSTR(SA6->A6_DVCTA,1,Len(AllTrim(SA6->A6_DVCTA)))		 ,;	//	[5]	DÃ­gito da conta corrente
	                   	SUBSTR(SEE->EE_SUBCTA,1,3)                             	 ,; //	[6]	Codigo da Carteira
	                    SEE->EE_IOF                                    			 ,; //	[7]	IOF
	                    SEE->EE_INSTPRI                                			 ,; //	[8]	Instrucao Primaria
	                    SEE->EE_INSTSEC                                			 ,; //	[9]	Instrucao Primaria
		                'BmpBanco'  }												//	[10]Loggotipo Banco

	//Dados do Banco
	aDadosBco := {	SA6->A6_COD ,;// [1]Numero do Banco
					SA6->A6_NREDUZ,;// [2]Nome do Banco
					Alltrim(SubStr(SA6->A6_AGENCIA,1,4)),;// [3]AgÃªncia
					Alltrim(SubStr(SA6->A6_NUMCON,1,7)),;// [4]Conta Corrente
					Alltrim(SubStr(SA6->A6_DVCTA,1,1)),;// [5]DÃ­gito da conta corrente
					Alltrim(SubStr(SA6->A6_CARTEIR,1,2))}// [6]Codigo da Carteira

				
	//Monta codigo de barras
	_nVlrAbat := SomaAbat(SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA, "R", 1, , SE1->E1_CLIENTE, SE1->E1_LOJA)
	aAdd(aDadosBco, (SE1->E1_VALOR - _nVlrAbat))
	cParcel  := If(Empty(SE1->E1_PARCELA),"0",SE1->E1_PARCELA)    
	
	cNroDoc	:= _cNossoNum 
	                        //santander   
	                        
    aCB_RN_NN    := CodBarSantander(Subs(aDadosBanco[1],1,3)+"9"			,;	//Banco
						  Subs(aDadosBanco[3],1,4)							,;	//Agencia
						  aDadosBanco[4]									,;	//Conta
						  aDadosBanco[5]									,;	//Digito da Conta
						  aDadosBanco[6]									,;	//Carteira*
						  AllTrim(SE1->E1_NUM)+AllTrim(SE1->E1_PARCELA)		,;	//Documento
						  (SE1->E1_SALDO-_nVlrAbat)							,;	//Valor do Titulo
						  SE1->E1_VENCTO									,;	//Vencimento
						  SEE->EE_CODEMP									,;	//Convenio
						  cNroDoc  											,;	//Sequencial
						  Iif(SE1->E1_DECRESC > 0,.t.,.f.)					,;	//Se tem desconto
						  SE1->E1_PARCELA									,;	//Parcela
						  aDadosBanco[3])						  			  	//Agencia Completa
 				                            
    aDadosTit := {AllTrim(SE1->E1_NUM)+AllTrim(SE1->E1_PARCELA)				,;  //	[1]	NÃºmero do tÃ­tulo
					SE1->E1_EMISSAO											,;  //	[2]	Data da emissÃ£o do tÃ­tulo
					dDataBase												,;  //	[3]	Data da emissÃ£o do boleto
					SE1->E1_VENCTO											,;  //	[4]	Data do vencimento
					(SE1->E1_SALDO - _nVlrAbat) 							,;  //	[5]	Valor do tÃ­tulo
					aCB_RN_NN[3]											,;  //	[6]	Nosso nÃºmero (Ver fÃ³rmula para calculo)
					SE1->E1_PREFIXO											,;  //	[7]	Prefixo da NF
					SE1->E1_TIPO }  										    //	[8]	Tipo do Titulo

	             
    If Empty(SE1->E1_NUMBCO) .Or. Len(Alltrim(SE1->E1_NUMBCO)) == 8//se jÃ¡ nao foi impresso
		SE1->(RecLock("SE1", .F.))      
			SE1->E1_NUMBCO := _cNossoNum+DigitSant(_cNossoNum)    //GRAVA NOSSO NUMERO NO TITULO
			SE1->E1_XBCO	:= cBanco
			SE1->E1_XAGE	:= cAgencia
			SE1->E1_XCONTA	:= cConta        
		SE1->(MsUnLock())       
	EndIf

Return

//===============================================================================
Static Function Prep033a()

	Local _nVlrAbat := 0
	Local cParcel   := ' '
	Local cNroDoc   := ''

	DbSelectArea("SA6")
	DbSelectArea("SEE")
	SA6->(DbSetOrder(1))
	SEE->(DbSetOrder(1))
	SA6->(DbSeek(xFilial("SA6") + cBanco + cAgencia + cConta))
	SEE->(DbSeek(xFilial("SEE") + cBanco + cAgencia + cConta))
	            
	//cNroDoc     := SE1->E1_NUMBCO
    //_cNossoNum  := substr(SE1->E1_NUMBCO,1,length(SE1->E1_NUMBCO)-1)
  	If !Empty(SE1->E1_NUMBCO) .And. Len(Alltrim(SE1->E1_NUMBCO)) == 13
		_cNossoNum := AllTrim(SE1->E1_NUMBCO)
		_cNossoNum := substr(_cNossoNum,1,len(_cNossoNum)-1)
		_cNossoNum := AllTrim(_cNossoNum)       
		cNroDoc := SE1->E1_NUMBCO
	Else		                                  
		_cNossoNum := SEE->EE_FAXATU  
		_cNossoNum := AllTrim(_cNossoNum) 
		cNroDoc	:= SEE->EE_FAXATU
		RecLock("SEE",.F.)
			SEE->EE_FAXATU := Soma1(Alltrim(SEE->EE_FAXATU))
		MsUnlock()
	EndIf
	
	//Monta codigo de barras
	aDadosBanco  := {   SEE->EE_CODIGO  									     ,;	//	[1]	Numero do Banco
	                	'nBanco'							            		,;	//	[2]	Nome do Banco
                     	SUBSTR(SEE->EE_AGENCIA,1,4)							    ,;	//	[3]	AgÃªncia
	                 	SUBSTR(SA6->A6_NUMCON,1,Len(AllTrim(SA6->A6_NUMCON)))	,;	//	[4]	Conta Corrente
	                  	SUBSTR(SA6->A6_DVCTA,1,Len(AllTrim(SA6->A6_DVCTA)))		,;	//	[5]	DÃ­gito da conta corrente
	                   	SUBSTR(SEE->EE_SUBCTA,1,3)                             	,;  //	[6]	Codigo da Carteira
	                    SEE->EE_IOF                                  			,;  //	[7]	IOF
	                    SEE->EE_INSTPRI                                 		,;  //	[8]	Instrucao Primaria
	                    SEE->EE_INSTSEC                                 		,;  //	[9]	Instrucao Primaria
		                'BmpBanco' }										 		//	[10]	Loggotipo Banco

	//Dados do Banco
	aDadosBco := {	SA6->A6_COD												    ,;// [1]Numero do Banco
					SA6->A6_NREDUZ												,;// [2]Nome do Banco
					Alltrim(SubStr(SA6->A6_AGENCIA,1,4))						,;// [3]AgÃªncia
					Alltrim(SubStr(SA6->A6_NUMCON,1,7))							,;// [4]Conta Corrente
					Alltrim(SubStr(SA6->A6_DVCTA,1,1))							,;// [5]DÃ­gito da conta corrente
					Alltrim(SubStr(SA6->A6_CARTEIR,1,2))}						  // [6]Codigo da Carteira

				
	//Monta codigo de barras
	_nVlrAbat := SomaAbat(SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA, "R", 1, , SE1->E1_CLIENTE, SE1->E1_LOJA)
	aAdd(aDadosBco, (SE1->E1_VALOR - _nVlrAbat))
	cParcel  := If(Empty(SE1->E1_PARCELA),"0",SE1->E1_PARCELA)
    
	cNroDoc	:= _cNossoNum 
	                        
    aCB_RN_NN    := CodBarSantander(Subs(aDadosBanco[1],1,3)+"9"			,;	//Banco
						Subs(aDadosBanco[3],1,4)						,;	//Agencia
						aDadosBanco[4]									,;	//Conta
						aDadosBanco[5]									,;	//Digito da Conta
						aDadosBanco[6]									,;	//Carteira*
						AllTrim(SE1->E1_NUM)+AllTrim(SE1->E1_PARCELA)	,;	//Documento
						(SE1->E1_SALDO-_nVlrAbat)						,;	//Valor do Titulo
						SE1->E1_VENCTO									,;	//Vencimento
						SEE->EE_CODEMP									,;	//Convenio
						cNroDoc  										,;	//Sequencial
						Iif(SE1->E1_DECRESC > 0,.t.,.f.)				,;	//Se tem desconto
						SE1->E1_PARCELA									,;	//Parcela
						aDadosBanco[3])									  	//Agencia Completa
 				                            
    aDadosTit   := {AllTrim(SE1->E1_NUM)+AllTrim(SE1->E1_PARCELA)		,;  //	[1]	NÃºmero do tÃ­tulo
						SE1->E1_EMISSAO									,;  //	[2]	Data da emissÃ£o do tÃ­tulo
						dDataBase										,;  //	[3]	Data da emissÃ£o do boleto
						SE1->E1_VENCTO									,;  //	[4]	Data do vencimento
						(SE1->E1_SALDO - _nVlrAbat) 					,;  //	[5]	Valor do tÃ­tulo
						aCB_RN_NN[3]									,;  //	[6]	Nosso nÃºmero (Ver fÃ³rmula para calculo)
						SE1->E1_PREFIXO									,;  //	[7]	Prefixo da NF
						SE1->E1_TIPO} 									    //	[8]	Tipo do Titulo

	             
        
return

//====================================================================================================
//calcula o cÃ³digo de barras do SANTANDER
Static Function CodBarSantander(cBanco,cAgencia,cConta,cDacCC,cCarteira,cNroDoc,nValor,dvencimento,cConvenio,cSequencial,_lTemDesc,_cParcela,_cAgCompleta)

	Local cCodEmp      := StrZero(Val(SubStr(cConvenio,1,7)),7)
	Local cNumSeq
	Local blvalorfinal := strzero(nValor*100,10)
	Local cNNumSDig    := cCpoLivre := cCBSemDig := cCodBarra := cNNum := cFatVenc := ''
	Local cNossoNum
                           
	//a agencia deve ter 4 digitos 
	//o convencio deve ter 7 digitos
	//o sequencial deve ter 7 digitos
	//  cNroDoc - numero do titulo + parcela
	//  CSEQUENCIAL - nosso nro mesmo

	//Fator Vencimento - POSICAO DE 06 A 09

	cFatVenc := FatorVencimento(dvencimento) //STRZERO(dvencimento - CtoD("07/10/1997"),4)

	cNumSeq := strzero(val(cSequencial),7)                                  
	cNumSeq := cNumSeq + DigitSant(cNumSeq)		

	//Nosso Numero sem digito
	cNNumSDig := cNumSeq
	//Nosso Numero
	cNNum := cNumSeq
	//Nosso Numero para impressao
	cNossoNum := cNNum
	//cCpoLivre := StrZero(Val(cAgencia),4) + StrZero(Val(cConta),8) + AllTrim(Str( modulo10cr( +StrZero(Val(cAgencia),4) + StrZero(Val(cConta),7) + Substr(cNNumSDig,1,7) ) ) ) + Substr(cNNumSDig,1,3) + cNNumSDig
	cCpoLivre := "9" + cCodEmp + "00000" + cNumSeq + "0" + "101"    
	//            912345670000012345670101

	//Dados para Calcular o Dig Verificador Geral
	cCBSemDig := cBanco + cFatVenc + blvalorfinal + cCpoLivre
	//Codigo de Barras Completo
	cCodBarra := cBanco + modulo11cr(cCBSemDig) + cFatVenc + blvalorfinal + cCpoLivre   
	// 0339XDDDD1234567890 912345670000012345670101 

	//Digito Verificador do Primeiro Campo                  
	cPrCpo := cBanco + SubStr(cCodBarra,20,5) 
	//          0339 912345
	cDvPrCpo := AllTrim(Str(Modulo10cr(cPrCpo)))

	//Digito Verificador do Segundo Campo
	cSgCpo := SubStr(cCodBarra,25,10)
	cDvSgCpo := AllTrim(Str(Modulo10cr(cSgCpo)))

	//Digito Verificador do Terceiro Campo
	cTrCpo := SubStr(cCodBarra,35,10)
	cDvTrCpo := AllTrim(Str(Modulo10cr(cTrCpo)))

	//Digito Verificador Geral
	cDvGeral := SubStr(cCodBarra,5,1)

	//Linha Digitavel
	cLindig := SubStr(cPrCpo,1,5) + "." + SubStr(cPrCpo,6,4) + cDvPrCpo + " "   //primeiro campo
	cLinDig += SubStr(cSgCpo,1,5) + "." + SubStr(cSgCpo,6,5) + cDvSgCpo + " "   //segundo campo
	cLinDig += SubStr(cTrCpo,1,5) + "." + SubStr(cTrCpo,6,5) + cDvTrCpo + " "   //terceiro campo
	cLinDig += " " + cDvGeral              //dig verificador geral
	cLinDig += "  " + SubStr(cCodBarra,6,4)+SubStr(cCodBarra,10,10)  // fator de vencimento e valor nominal do titulo

Return({cCodBarra,cLinDig,cNossoNum})

//-----------------------------------------------------------------------------------
//calcula digito do nosso nro do SANTANDER
Static Function DigitSant(cNossNro)

	Local cDIgit := ' ',cAux:=' ' 
	Local nIndex := Len(cNossNro) 
	Local nFator := 1
	Local nSoma  := 0 
	Local nResto := 0

	While nIndex > 0 
		cAux := substr(cNossNro,nIndex, 1)
		nFator+=1
		
		if nFator > 9
			nFator:=2
		endif
			
		nSoma += Val(cAux) * nFator
		
		nIndex -= 1
	EndDo

	nResto := (nSoma % 11)

	cDigit := ' '

	If nResto == 10
		cDigit := '1'
	EndIf

	If nResto == 1 .or. nResto == 0
		cDigit := '0'
	EndIf

	If nResto != 10 .and. nResto != 1 .and. nResto != 0
		cDigit := ALLTRIM( STR(11-nResto) )
	EndIf
	
Return cDigit

//=============================================================
//modulo de 11 usado para o SANTANDER
Static Function Modulo11cr(cData,cBanc)

	Local L := 0  
	Local D := 0  
	Local P := 0  

	L := Len(cdata)
	D := 0
	P := 1

   While L > 0 
      P := P + 1
      D := D + (Val(SubStr(cData, L, 1)) * P)
      If P = 9 
         P := 1
      EndIf
      L := L - 1
   EndDo
   D := 11 - (mod(D,11))
   If (D == 10 .Or. D == 11 .or. D == 0 .Or. D == 1)
      D := 1
   EndIf
   D := AllTrim(Str(D))

Return(D)   

//====================================================================================
//modulo de 10 usado para o SANTANDER

Static Function Modulo10cr(cData)

	Local L := 0
	Local D := 0
	Local P := 0
	Local B := .F.

	L := Len(cData)  //TAMANHO DE BYTES DO CARACTER
	B := .T.   
	D := 0     //DIGITO VERIFICADOR

	While L > 0 
		P := Val(SubStr(cData, L, 1))
		If (B) 
			P := P * 2
			If P > 9 
				P := P - 9
			EndIf
		EndIf

		D := D + P
		L := L - 1
		B := !B
	EndDo

	D := 10 - (Mod(D,10))	
	If D = 10
		D := 0
	EndIf
   
Return(D)


//--------------------------------------------------------------------
Static Function DigitDif (cDado1, cDado2)

	Local cRet := ''
	Local nIndex1 := Len(cDado1)
	Local nNum := 0 
	Local cTam := ''
								
	nNum:= Val(cDado1)+Val(cDado2)
	cTam := AllTrim(STR(nNUm))

	If nIndex1  >= Len(cTam)
		cRet := STRZERO(nNUm, nIndex1)
	Else
		cRet := STRZERO(nNUm, Len(cTam))
	EndIf

 
Return cRet

User function ragvai()

	Local c1 := '239104761', c2 := '8351202', c3 := '', c0 := ''

	c1 :=  Dv10HSBC('399983512')//1
	c1 :=  Dv10HSBC('0200002391')//7
				
	//39998.35121 02000.023917

	c0 := InvDigitDAC(c1)
	c3:= DigitDif((c1+c0+"5"),c2)
	c0 := InvDigitDAC(c3)

Return

    
//===============================================================================
//calcula código de barra, linha digitavel e nosso numero do banco ITAU
Static Function Prepa341()
	
    Local _nValor := 0
    LOcal aDadosBanco := {}

	DbSelectArea("SA6")
	DbSelectArea("SEE")
	SA6->(DbSetOrder(1))
	SEE->(DbSetOrder(1))
	SA6->(DbSeek(xFilial("SA6") + cBanco + cAgencia + cConta))
	SEE->(DbSeek(xFilial("SEE") + cBanco + cAgencia + cConta))
    
	If !Empty(SE1->E1_NUMBCO) .And. Len(Alltrim(SE1->E1_NUMBCO)) == 8
		_cNossoNum := SE1->E1_NUMBCO
		_cNossoNum := AllTrim(_cNossoNum)       
		cNroDoc := AllTrim(SE1->E1_NUMBCO)
	Else
		_cNossoNum := SEE->EE_FAXATU  
		_cNossoNum := AllTrim(_cNossoNum) 
		cNroDoc	:= SEE->EE_FAXATU
		RecLock("SEE",.F.)
			SEE->EE_FAXATU := Soma1(Alltrim(SEE->EE_FAXATU))
		MsUnlock()
	EndIf		 
                
	//Dados do Banco
	aDadosBco := {SA6->A6_COD 							   ,;// [1]Numero do Banco
					SA6->A6_NREDUZ						   ,;// [2]Nome do Banco
					Alltrim(SubStr(SA6->A6_AGENCIA,1,4))   ,;// [3]Agencia
					Alltrim(SubStr(SA6->A6_NUMCON,1,5))	   ,;// [4]Conta Corrente
					Alltrim(SubStr(SA6->A6_DVCTA,1,1))	   ,;// [5]Di­gito da conta corrente
					Alltrim(SubStr(SA6->A6_CARTEIR,1,3))	}// [6]Codigo da Carteira


	aDadosBanco  := {SEE->EE_CODIGO	   ,;     // [1]Numero do Banco
		"Banco Itaú S.A."              ,;     // [2]Nome do Banco
		SEE->EE_AGENCIA                ,;     // [3]Agencia
		SEE->EE_CONTA                  ,;     // [4]Conta Corrente
		SEE->EE_DVCTA                  ,;     // [5]DÃ­gito da conta corrente
		"109"                 			}     // [6]Codigo da Carteira

	cNumSeq	:=   _cNossoNum 
	  
	//Monta codigo de barras
	_nVlrAbat := SomaAbat(SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA, "R", 1, , SE1->E1_CLIENTE, SE1->E1_LOJA)
    _nValor := SE1->E1_VALOR - _nVlrAbat
	aAdd(aDadosBco, (SE1->E1_VALOR - _nVlrAbat))
	
	aCB_RN_NN    := CalculosBco(Subs(aDadosBanco[1],1,3)+"9",AllTrim(aDadosBanco[3]),AllTrim(aDadosBanco[4]),aDadosBanco[5],AllTrim(_cNossoNum),_nValor,Datavalida(SE1->E1_VENCTO,.T.))
	                   
	aDadosTit    := {AllTrim(SE1->E1_NUM)+AllTrim(SE1->E1_PARCELA)	,;      // [1] NÃºmero do tÃ­tulo
		SE1->E1_EMISSAO                              					,;  // [2] Data da emissÃ£o do tÃ­tulo
		Date()   		                               					,;  // [3] Data da emissÃ£o do boleto
		Datavalida(SE1->E1_VENCTO,.T.)                 					,;  // [4] Data do vencimento
		_nValor															,;  // [5] Valor do i­tulo
		aCB_RN_NN[3]                   		          					,;  // [6] Nosso numero (Ver formula para calculo)
		SE1->E1_PREFIXO                               					,;  // [7] Prefixo da NF
		SE1->E1_TIPO	                           						}   // [8] Tipo do Titulo
		
    If Empty(SE1->E1_NUMBCO) .Or. Len(Alltrim(SE1->E1_NUMBCO)) == 12	//se jÃ¡ nao foi impresso			
		SE1->(RecLock("SE1", .F.))
			SE1->E1_NUMBCO 	:= _cNossoNum   // Nosso nÃºmero (Ver fÃ³rmula para calculo)
			SE1->E1_XBCO	:= cBanco
			SE1->E1_XAGE	:= cAgencia
			SE1->E1_XCONTA	:= cConta
		SE1->(MsUnLock())       
	EndIf

Return
    
//===============================================================================
//calcula código de barra, linha digitavel e nosso numero do banco ITAU
Static Function Prep341a()
	
	Local _nValor := 0
	Local aDadosBanco := {}

	DbSelectArea("SA6")
	DbSelectArea("SEE")
	SA6->(DbSetOrder(1))
	SEE->(DbSetOrder(1))
	SA6->(DbSeek(xFilial("SA6") + cBanco + cAgencia + cConta))
	SEE->(DbSeek(xFilial("SEE") + cBanco + cAgencia + cConta))
    
	cNroDoc     := AllTrim(SE1->E1_NUMBCO)
	_cNossoNum  := SE1->E1_NUMBCO
   
   
   //Dados do Banco
	aDadosBco := {SA6->A6_COD 							,;// [1]Numer	o do Banco
					SA6->A6_NREDUZ						,;// [2]Nome do Banco
					Alltrim(SubStr(SA6->A6_AGENCIA,1,4)),;// [3]Agencia
					Alltrim(SubStr(SA6->A6_NUMCON,1,5)) ,;// [4]Conta Corrente
					Alltrim(SubStr(SA6->A6_DVCTA,1,1))  ,;// [5]Di­gito da conta corrente
					Alltrim(SubStr(SA6->A6_CARTEIR,1,3)) }// [6]Codigo da Carteira


	aDadosBanco  := {SEE->EE_CODIGO,;    // [1]Numero do Banco
		"Banco Itaú S.A."          ,;    // [2]Nome do Banco
		SEE->EE_AGENCIA            ,;    //  "9999"                 ,; // [3]Agencia
		SEE->EE_CONTA              ,;    //  "99999"				,; // [4]Conta Corrente
		SEE->EE_DVCTA              ,;    //  AGENCIA      "9"  		,; // [5]DÃ­gito da conta corrente
		"109"                  		}    //  [6]Codigo da Carteira

	cNumSeq	:=   _cNossoNum 
	  
	//Monta codigo de barras
	_nVlrAbat := SomaAbat(SE1->E1_PREFIXO, SE1->E1_NUM, SE1->E1_PARCELA, "R", 1, , SE1->E1_CLIENTE, SE1->E1_LOJA)
   _nValor := SE1->E1_VALOR - _nVlrAbat
	aAdd(aDadosBco, (SE1->E1_VALOR - _nVlrAbat))
	
	aCB_RN_NN    := CalculosBco(Subs(aDadosBanco[1],1,3)+"9",AllTrim(aDadosBanco[3]),AllTrim(aDadosBanco[4]),aDadosBanco[5],AllTrim(_cNossoNum),_nValor,Datavalida(SE1->E1_VENCTO,.T.))
	                   
	aDadosTit    := {AllTrim(SE1->E1_NUM)+AllTrim(SE1->E1_PARCELA)	,;  // [1] NÃºmero do tÃ­tulo
		SE1->E1_EMISSAO                              				,;  // [2] Data da emissÃ£o do tÃ­tulo
		Date()   		                               				,;  // [3] Data da emissÃ£o do boleto
		Datavalida(SE1->E1_VENCTO,.T.)                 				,;  // [4] Data do vencimento
		_nValor														,;  // [5] Valor do tÃ­tulo
		aCB_RN_NN[3]                   		          				,;  // [6] Nosso nÃºmero (Ver fÃ³rmula para calculo)
		SE1->E1_PREFIXO                               				,;  // [7] Prefixo da NF
		SE1->E1_TIPO	                           					}   // [8] Tipo do Titulo

Return

//===============================================================================
//gera linha digitavel , nosso numero e cod barra                 
//agencia 3040
//dv      4
//conta   20300 
                          //3419   1234     12345    1    12345678
Static Function CalculosBco(cBanco,cAgencia,cConta,cDacCC,cNroDoc,nValor,dVencto)

	Local cDAC          := ''
	Local cCodBarra     := ''
	Local cCampo1       := ''
	Local cCampo2       := ''
	Local cCampo3       := ''
	Local cCampo4       := ''
	Local cCampo5       := ''
	Local cfator        := FatorVencimento(dVencto) //strzero(dVencto - ctod("07/10/97"),4)
	Local bldocnufinal  := strzero(val(cNroDoc),8)
	Local blvalorfinal  := strzero(int(nValor*100),10)
	Local cCodigo       := AllTrim(cAgencia) + AllTrim(cConta) + "109" + bldocnufinal
	Local cDACCodigo    := ModDe10(cCodigo)
	Local cDACAnexo4    := cDACCodigo
	Local cDAC3Anexo    := ModDe10(cAgencia + cConta)
	Local cCB           := ''
	Local cRN           := ''
	Local cNN           := ''
	

	cAgencia := AllTrim(cAgencia)
	cConta := AllTrim(cConta)   

	cDAC := InModulo11("341" + "9" +  cfator + blvalorfinal + "109" + bldocnufinal + cDACAnexo4 + cAgencia + cConta + cDAC3Anexo + "000")
	cCodBarra := "341" + "9" + AllTrim(STR(cDAC)) + cfator + blvalorfinal + "109" + bldocnufinal + cDACAnexo4 + cAgencia + cConta + cDAC3Anexo + "000"
	cCb := cCodBarra   
	cNN := bldocnufinal

	cCampo1 := "341" + "9" + "109"  + substr(bldocnufinal,1,2) 
	cCampo1 := cCampo1 + ModDe10(cCampo1)                   

	cCampo2 := substr(bldocnufinal,3,6) + cDACCodigo + substr(cAgencia,1,3) 
	cCampo2 := cCampo2 + ModDe10(cCampo2)

	cCampo3 := substr(cAgencia,4,1) + (cConta+cDacCC) + "000"                             
	cCampo3 := cCampo3 + ModDe10(cCampo3)
										
	cCampo4 := AllTrim(STR(cDAC))

	cCampo5 :=cfator + blvalorfinal   

	//34191.09008  00000.09008  02030.313049  2  61900000020000
	cRN   := SubStr(cCampo1, 1, 5) + '.' + SubStr(cCampo1, 6, 5)  + '  '
	cRN   := cRN + SubStr(cCampo2, 1, 5) + '.' + SubStr(cCampo2, 6, 6) +  '  '    
	cRN   := cRN + SubStr(cCampo3, 1, 5) + '.' + SubStr(cCampo3, 6, 6)  + '  '
	cRN   := cRN + cCampo4 + '  '
	cRN   := cRN + cCampo5

Return({cCB,cRN,cNN})



//=================================================================                           
Static Function ModDe10(cDado)

	Local cDIgit := ' ',cAux:=' ' 
	Local nIndex := Len(cDado) 
	Local nFator := 1
	Local nSoma := 0 , nResto := 0, nTemp:=0, cStrTemp:= '', nAjud:=0
	Local lDois := .T.

	While nIndex > 0 
		cAux := substr(cDado,nIndex, 1)
		
		If lDois
			nFator:=2
			lDois := .F.
		Else	
			nFator:=1
			lDois := .T.
		Endif
			
		nTemp := Val(cAux) * nFator
		cStrTemp := AllTrim(STR(nTemp))
		
		If nTemp < 10
			nSoma += nTemp
		Endif
		
		If nTemp >= 10 .and. nTemp <= 99
			nAjud:= val( substr(cStrTemp,1,1)  )
			nSOma += nAjud
			nAjud:=val( substr(cStrTemp,2,1)  )     
			nSOma += nAjud
		Endif                           
		
		If nTemp > 100
			nAjud:=val( substr(cStrTemp,1,1)  )
			nSOma += nAjud
			nAjud:=val( substr(cStrTemp,2,1)  )
			nSOma += nAjud
			nAjud:=val( substr(cStrTemp,3,1)  )
			nSOma += nAjud
		Endif

		nIndex -= 1

	EndDo

	nResto := (nSoma % 10)


	cDigit := ALLTRIM( STR(10-nResto) )

	If Val(cDigit) >= 10
		cDigit := '0'
	EndIf
		
Return cDigit


//=============================================================================
Static Function InModulo11(cData)

	Local L := 0
	Local D := 0
	Local P := 0

	L := Len(cdata)
	D := 0
	P := 1

	While L > 0
		P := P + 1
		D := D + (Val(SubStr(cData, L, 1)) * P)
		If P = 9
			P := 1
		End
		L := L - 1
	EndDo

	D := 11 - (mod(D,11))

	If (D == 0 .Or. D == 1 .Or. D == 10 .Or. D == 11)
		D := 1
	EndIf

Return(D)                             

/*/{Protheus.doc} EnvMail
Rotina de envio de emails  
@type function
@version  12.1.25
@author Cyberpolos
@since 25/01/2021
@param _cFrom, Character, remetente do email
@param _cTo, Character, destinatario do email 
@param _cCC, Character, destinatario da copia do email
@param _cBCC, Character, destinatario da copia oculta do email 
@param _cSubject,Character, Assunto do email 
@param _cBody, Character, corpo do email
@param _cAttach1, Character, anexo do email
@param _cAttach2, Character, anexo do email 2
@return Logical,  se foi enviado com sucesso
/*/
Static Function EnvMail(_cFrom, _cTo, _cCC, _cBCC, _cSubject, _cBody, _cAttach1, _cAttach2)

	Private _cSerMail	:= alltrim(GetMV("MV_RELSERV"))
	Private _cConta    	:= alltrim(GetMV("MV_RELACNT"))
	Private _cSenha		:= alltrim(GetMV("MV_RELPSW"))
	Private _lConectou	:= .F.
	Private _lEnviado	:= .F.
	Private _cMailError	:= ""

	If _cFrom == NIL .or. empty(_cFrom)
		_cFrom := _cConta
	EndIf
	
	// Conecta ao servidor de email
	CONNECT SMTP SERVER _cSerMail ACCOUNT _cConta PASSWORD _cSenha Result _lConectou

	If !(_lConectou) // Se nao conectou informa o erro
		GET MAIL ERROR _cMailError
		Alert(Space(12) + "Não foi possí­vel conectar ao Servidor de email. Procure o Administrador da rede."+chr(13)+chr(10)+"Erro retornado: "+_cMailError)
	Else
		
		If GetNewPar("MV_RELAUTH",.F.)
			_lRetAuth := MailAuth(_cConta,_cSenha)
		Else
			_lRetAuth := .T.
		EndIf
		
		
		If _lRetAuth
			SEND MAIL FROM _cFrom TO _cTo CC _cCc BCC _cBCC SUBJECT	_cSubject Body _cBody ATTACHMENT _cAttach1,_cAttach2 FORMAT TEXT RESULT _lEnviado
		Else
			Alert(Space(12) + "Nao foi possivel autenticar o usuario e senha para envio de e-mail!")
			_lEnviado := .F.
		EndIf
		
		If !(_lEnviado)
			GET MAIL ERROR _cMailError
			Alert(Space(12) + "Não foi possível enviar o email. Procure o Administrador da rede."+chr(13)+chr(10)+"Erro retornado: "+_cMailError)
		Endif
		
		DISCONNECT SMTP SERVER
	Endif

Return(_lEnviado)                                        

/*/{Protheus.doc} MONTACORPO
Monta o corpo do email
@type Function
@version 12.1.25
@author Cyberpolos
@since 25/01/2021
@return Character, retorna corpo do email
/*/
Static function MONTACORPO()

	Local cHtml := ""

   // Montagem do HTML.
    cHtml += '<html xmlns="http://www.w3.org/1999/xhtml">' 
    cHtml += '<head>' 
    cHtml += '<meta charset="iso-8859-1">'       
    cHtml += '<title>Registros nao localizados</title>' 
    cHtml += "</head>"    
    cHtml += ' <style type="text/css">'     		
    cHtml += '.table-a{'
    cHtml += 'border-spacing:0;border-collapse:collapse;border-top:solid 2px #000000;border-bottom:solid 2px #cccccc;padding-bottom:5px;}'   
    cHtml += '  #table-b { '
    cHtml += "font-family: 'Lucida Sans Unicode', 'Lucida Grande', Sans-Serif;" 
    cHtml += "font-size: 13px;" 
    cHtml += "background: #fff;" 
    cHtml += "margin: 10px;" 
    cHtml += "width: 95%; " 
    cHtml += "border-collapse: collapse; " 
    cHtml += "text-align: left; } "       
    cHtml += "#table-b th { " 
    cHtml += "font-size: 14px; " 
    cHtml += "font-weight: normal; " 
    cHtml += "color: #333; " 
    cHtml += "padding: 10px 8px; " 
    cHtml += "border-bottom: 2px solid #1b1a1a; } "      
    cHtml += "#table-b td { "   
    cHtml += "color: #333; "   
    cHtml += "padding: 6px 8px; } "    
    cHtml += "#table-b tbody tr:hover td { " 
    cHtml += " background-color: #ffffff; "
    cHtml += "} "
    cHtml += ".footer-texto {font-family: 'Open Sans Condensed', Arial, sans-serif;font-size: 13px; color: #fff;  }"
    cHtml += '</style> <body style="background: #ffffff; width:90%; margin: 0 auto;">'   
    cHtml += "<center>"
    cHtml += '<table width=100% class="table-a" style=" text-align: left;">'
    cHtml += '<tbody>'
    cHtml += '<tr>'
    cHtml += '<td style="padding-top:20px;padding-bottom:20px;background:#ffffff;">'
    cHtml += '<table style="border-spacing:0;border-collapse:collapse;width:100%;margin:0 auto">'
    cHtml += '<tbody>'
    cHtml += '<tr>'
    cHtml += '<td width=100% style="text-align:center;"><a style="padding: 0px;"href="https://www.hb.com.br/" target=_blank><img src="https://i.imgur.com/KiXeiRk.jpeg" width="600" height="250" alt="Logo"></a>'
    cHtml += '</td>'
    cHtml += '</tr>'
    cHtml += '</tbody>'
    cHtml += '</table>'
    cHtml += '</td>'
    cHtml += '</tr>'
    cHtml += '</tbody>'
    cHtml += '</table>'  

	If lStatus4 
          // estrutura do aStatus4:  1 - numero, 2 - parcela, 3 - valor, 4 - vencimento, 5 - vencimento real, 6 - vencimento real + 5 dias
		cHtml += "<tr>"
		cHtml += "<td align='center' bgcolor='#FFFFFF'><table width='90%' border='0' cellpadding='0' cellspacing='5'> "
		cHtml += "  <tr> "
		cHtml += "    <td style='font-family:Verdana, Geneva, sans-serif; font-size:13px; color:#000;'> "
		cHtml += "      <p>Prezado(a) cliente,</p> "
		cHtml += "      <p>Não identificamos o pagamento da fatura: "+ aStatus4[1]+" / "+aStatus4[2] +", valor de R$ "+TransForm(aStatus4[3], "@E 999,999,999.99")+" vencida em "+aStatus4[4]+".</p>"
		cHtml += "      <p>Anexo, boleto original.</p>"
		cHtml += "      <p>O pagamento deste boleto, poderá ser realizado através dos canais bancários ou redes credenciadas até a data limite de: "+Dtoc(aStatus4[6])+".</p>"
		cHtml += "      <p>Após esta data, o boleto seguirá automaticamente ao cartório. Fique Atento!!!</p>"
		cHtml += "      <p>A HB agradece sua atenção!</p><br><br>"
		cHtml += "      <p>Em caso de dúvidas, entre em contato conosco:</p>"
		cHtml += "      <p>Tel: (11) 4591-8604 / 4591-8606 / 4591-8619</p>"
		cHtml += "      <p>WhatssApp (11) 4591-8600 / (11) 98911-8763</p>"
		cHtml += "      <p>e-mail: financeiro1@hb.com.br;financeiro2@hb.com.br;financeiro3@hb.com.br</p><br><br>"
		cHtml += "      <p>Visite nossa página de vendas corporativa https://b2b.hb.com.br e para saber mais das novidades entre em https://www.hb.com.br</p><br><br>"
		cHtml += "      <span style='font-size:10px; text-align:center; color:#F00;'>Aten&ccedil;&atilde;o: esse e-mail foi gerado automaticamente, n&atilde;o &eacute; necess&aacute;ria nenhuma resposta.</span> </p></td> "
		cHtml += "  </tr> "
		cHtml += "</table></td><br><br><br> "


	Else
		
		cHtml += "<tr>"
		cHtml += "<td align='center' bgcolor='#FFFFFF'><table width='90%' border='0' cellpadding='0' cellspacing='5'> "
		cHtml += "  <tr> "
		cHtml += "    <td style='font-family:Verdana, Geneva, sans-serif; font-size:13px; color:#000;'> "
		cHtml += "      <p>Prezado(a) cliente,</p> "
		cHtml += "      <p>Segue(m), boleto(s) referente a NOTA FISCAL citada no assunto acima.</p> "
		cHtml += "      <p>Lembrando que o envio do boleto &eacute; gerado automaticamente, ap&oacute;s a emiss&atilde;o da NOTA em nosso sistema.</p><br> "
		cHtml += "      <span style='font-size:10px; text-align:center; color:#F00;'>Aten&ccedil;&atilde;o: esse e-mail foi gerado automaticamente, n&atilde;o &eacute; necess&aacute;ria nenhuma resposta.</span> </p></td> "
		cHtml += "  </tr> "
		cHtml += "</table></td><br><br><br> "
	
	EndIf

	//rodape
	cHtml += '<table width="100%" class="table-a" style="background-color: #1c1c1c; color: #fff;padding-top:15px;padding-bottom:15px;"> '         
    cHtml += '<tr style="font-size:10.0pt;"> <td align="center"><table>'           
    cHtml += '<td  class="footer"><table  width="180" ><tr><td > <span class="footer-texto">'
    cHtml += '<p>&nbsp;&nbsp;&nbsp;<b> Garantia e Assist&ecirc;ncia </b></p></span><span class="footer-texto"> <p> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 11 4591-8600 <br> &nbsp;&nbsp;&nbsp; De segunda &agrave; sexta <br>'                                             
    cHtml += '&nbsp;&nbsp;&nbsp; das 8h-12h | 13h-16h</p></span></td></tr></table></td><td> <table width="100"></table></td><td class="footer"><table width="180" >' 
    cHtml += '<tr><td><span class="footer-texto"><p><b>Andamento de pedidos </b></p></span><span class="footer-texto"><p>&nbsp;&nbsp;&nbsp; <br>De segunda &agrave; sexta<br>'                                       
    cHtml += 'das 09h00 &agrave;s 18h</p></span></td></tr></table></td></table></td></tr></table></body></html>'

Return cHtml


STATIC FUNCTION Impress()

	Local oFont8
	Local oFont10
	Local oFont16
	Local oFont16n
	Local oFont14n
	Local oFont24
	Local i        := 0
	Local _nLin    := 0//200
	Local aCoords1 := {0150,1900,0550,2300}
	Local aCoords2 := {0450,1050,0550,1900}
	Local aCoords3 := {_nLin+0710,1900,_nLin+0810,2300}
	Local aCoords4 := {_nLin+0980,1900,_nLin+1050,2300}
	Local aCoords5 := {_nLin+1330,1900,_nLin+1400,2300}
	Local aCoords6 := {_nLin+2000,1900,_nLin+2100,2300}
	Local aCoords7 := {_nLin+2270,1900,_nLin+2340,2300}
	Local aCoords8 := {_nLin+2620,1900,_nLin+2690,2300}
	Local oBrush
	Local nSalto   := 18
	//Local cSantLogo:="Santander10.bmp"
	Local cSantLogo:= ""//cPDFGer2 +"santban10.bmp"

	SET DATE FORMAT "dd/mm/yyyy"

	// Parâmetros de TFont.New()
	// 1.Nome da Fonte (Windows)
	// 3.Tamanho em Pixels
	// 5.Bold (T/F)
	oFont8  := TFont():New("Arial",9,08,.T.,.F.,5,.T.,5,.T.,.F.)
	//oFont10 := TFont():New("Arial",9,10,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont10 := TFont():New("Arial",9,10,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont16 := TFont():New("Arial",9,16,.T.,.T.,5,.T.,5,.T.,.F.)
	oFont16n:= TFont():New("Arial",9,16,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont14n:= TFont():New("Arial",9,14,.T.,.F.,5,.T.,5,.T.,.F.)
	oFont24 := TFont():New("Arial",9,24,.T.,.T.,5,.T.,5,.T.,.F.)
	oBrush  := TBrush():New("",4)
	oPrinter:StartPage()	// Inicia uma nova Pagina

	// Inicia aqui a alteracao para novo layout - RAI
	oPrinter:Line(0150,0560,0050,0560)
	oPrinter:Line(0150,0800,0050,0800)
	//oPrint:Say (0084,0100,aDadosBanco[2],oFont16)					// [2] Nome do Banco
	oPrinter:SayBitmap(0050,0100,cSantLogo,430,90 )

	//oPrint:Say (nSalto+0082,0567,aDadosBanco[1]+"-7",oFont24)					// [1] Numero do Banco
	oPrinter:Say (nSalto+0082,0567,Alltrim(SEE->EE_AGENCIA) + "/" + Alltrim(SEE->EE_CODEMP) ,oFont24)					// [1] Numero do Banco
	oPrinter:Say (nSalto+0084,1870,"Comprovante de Entrega",oFont10)
	oPrinter:Line(0150,0100,0150,2300)
	
	oPrinter:Say (nSalto+0150,0100,"Beneficiário",oFont8)
	//oPrint:Say (nSalto+0200,0100,aDadosEmp[1]	,oFont10)					// [1] Nome + CNPJ
	oPrinter:Say (nSalto+0200,0100,SubStr(aDadosEmp[1], 1, 30) + " CNPJ: " + aDadosEmp[6]	,oFont10)					// [1] Nome + CNPJ
	
	oPrinter:Say (nSalto+0150,1060,"Agência/Código Cedente",oFont8)
	//oPrint:Say (nSalto+0200,1060,aDadosBanco[3]+"/"+cCodEmp,oFont10)
	oPrinter:Say (nSalto+0200,1060,Alltrim(SEE->EE_AGENCIA) + "/" + Alltrim(SEE->EE_CODEMP),oFont10)
	
	oPrinter:Say (nSalto+0150,1510,"Nro.Documento",oFont8)
	//oPrint:Say (nSalto+0200,1510,aDadosTit[7]+aDadosTit[1],oFont10)	// [7] Prefixo + [1] Numero + Parcela
	oPrinter:Say (nSalto+0200,1510,aDadosTit[7]+AllTrim(cNum)+AllTrim(cParc),oFont10)	// [7] Prefixo + [1] Numero + Parcela
	
	oPrinter:Say (nSalto+0250,0100,"Pagador",oFont8)
	//oPrint:Say (nSalto+0300,0100,aDatSacado[1],oFont10)					// [1] Nome
	oPrinter:Say (nSalto+0300,0100,SubStr(aDadosSac[1], 1, 30) + " " + AllTrim(SA1->A1_CGC),oFont10)					// [1] Nome
	
	oPrinter:Say (nSalto+0250,1060,"Vencimento",oFont8)
	oPrinter:Say (nSalto+0300,1060,DTOC(aDadosTit[4]),oFont10)
	
	oPrinter:Say (nSalto+0250,1510,"Valor do Documento",oFont8)
	//oPrint:Say (nSalto+0300,1550,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),oFont10)
	oPrinter:Say (nSalto+0300,1550,AllTrim(TransForm(aDadosBco[7],"@E 999,999,999.99")),oFont10)
	
	oPrinter:Say (nSalto+0400,0100,"Recebi(emos) o bloqueto/título",oFont10)
	oPrinter:Say (nSalto+0450,0100,"com as características acima.",oFont10)
	oPrinter:Say (nSalto+0350,1060,"Data",oFont8)
	oPrinter:Say (nSalto+0350,1410,"Assinatura",oFont8)
	oPrinter:Say (nSalto+0450,1060,"Data",oFont8)
	oPrinter:Say (nSalto+0450,1410,"Entregador",oFont8)
	oPrinter:Line(0250,0100,0250,1900)
	oPrinter:Line(0350,0100,0350,1900)
	oPrinter:Line(0450,1050,0450,1900) //---
	oPrinter:Line(0550,0100,0550,2300)
	oPrinter:Line(0550,1050,0150,1050)
	oPrinter:Line(0550,1400,0350,1400)
	oPrinter:Line(0350,1500,0150,1500) //--
	oPrinter:Line(0550,1900,0150,1900)
	oPrinter:Say (nSalto+0150,1910,"(  )Mudou-se",oFont8)
	oPrinter:Say (nSalto+0190,1910,"(  )Ausente",oFont8)
	oPrinter:Say (nSalto+0230,1910,"(  )Não existe nº indicado",oFont8)
	oPrinter:Say (nSalto+0270,1910,"(  )Recusado",oFont8)
	oPrinter:Say (nSalto+0310,1910,"(  )Não procurado",oFont8)
	oPrinter:Say (nSalto+0350,1910,"(  )Endereço insuficiente",oFont8)
	oPrinter:Say (nSalto+0390,1910,"(  )Desconhecido",oFont8)
	oPrinter:Say (nSalto+0430,1910,"(  )Falecido",oFont8)
	oPrinter:Say (nSalto+0470,1910,"(  )Outros(anotar no verso)",oFont8)
	FOR i := 100 TO 2300 STEP 50
		oPrinter:Line(_nLin+0600,i,_nLin+0600,i+30)
	NEXT i    

	oPrinter:Line(_nLin+0710,0100,_nLin+0710,2300)
	oPrinter:Line(_nLin+0710,0560,_nLin+0610,0560)
	oPrinter:Line(_nLin+0710,0800,_nLin+0610,0800)
	//oPrint:Say (nSalto+nSalto+_nLin+0644,0100,aDadosBanco[2],oFont16)	// [2]Nome do Banco
	oPrinter:SayBitmap(_nLin+0610,0100,cSantLogo,430,90 )
	//oPrint:Say (nSalto+_nLin+0652,0567,aDadosBanco[1]+"-7",oFont24)	// [1]Numero do Banco
	oPrinter:Say (nSalto+_nLin+0652,0567,Alltrim(SEE->EE_AGENCIA) + "/" + Alltrim(SEE->EE_CODEMP),oFont24)	// [1]Numero do Banco
	
	oPrinter:Say (nSalto+_nLin+0654,1900,"Recibo do Pagador",oFont10)
	oPrinter:Line(_nLin+0810,0100,_nLin+0810,2300)
	oPrinter:Line(_nLin+0910,0100,_nLin+0910,2300)
	oPrinter:Line(_nLin+0980,0100,_nLin+0980,2300)
	oPrinter:Line(_nLin+1050,0100,_nLin+1050,2300)
	oPrinter:Line(_nLin+0910,0500,_nLin+1050,0500)
	oPrinter:Line(_nLin+0980,0750,_nLin+1050,0750)
	oPrinter:Line(_nLin+0910,1000,_nLin+1050,1000)
	oPrinter:Line(_nLin+0910,1350,_nLin+0980,1350)
	oPrinter:Line(_nLin+0910,1550,_nLin+1050,1550)

	oPrinter:Say (nSalto+_nLin+0710,0100,"Local de Pagamento",oFont8)
	//oPrint:Say (nSalto+_nLin+0750,0100,"QUALQUER BANCO ATÉ A DATA DO VENCIMENTO",oFont10)
	//oPrint:Say (nSalto+_nLin+0750,0100,"ATE O VENCIMENTO PAGUE PREFERENCIALMENTE NO SANTANDER",oFont8)
	oPrinter:Say (nSalto+_nLin+0750,0100,&(aMsg[1]),oFont8)
	//oPrint:Say (nSalto+_nLin+0775,0100,"APOS O VENCIMENTO PAGUE SOMENTE NO SANTANDER",oFont8)
	oPrinter:Say (nSalto+_nLin+0775,0100,&(aMsg[2]),oFont8)

	oPrinter:Say (nSalto+_nLin+0710,1910,"Vencimento",oFont8)
	//oPrint:Say (nSalto+_nLin+0750,1950,DTOC(aDadosTit[4]),oFont10)
	oPrinter:Say (nSalto+_nLin+0750,1950,DTOC(aDadosTit[4]),oFont10)

	oPrinter:Say (nSalto+_nLin+0810,0100,"Beneficiário",oFont8)
	//oPrint:Say (nSalto+_nLin+0835,0100,aDadosEmp[1]+"             - "+aDadosEmp[6],oFont10) //Nome + CNPJ
	oPrinter:Say (nSalto+_nLin+0835,0100,SubStr(aDadosEmp[1], 1, 30) + " CNPJ: " + aDadosEmp[6],oFont10) //Nome + CNPJ
	//oPrint:Say (nSalto+_nLin+0870,0100,AllTrim(aDadosEmp[2])+" "+AllTrim(aDadosEmp[3])+" "+AllTrim(aDadosEmp[4]),oFont10) //End
	oPrinter:Say (nSalto+_nLin+0870,0100,Alltrim(aDadosEmp[2]),oFont10) //End
	oPrinter:Say (nSalto+_nLin+0890,0100,Alltrim(aDadosEmp[3]) + " " + AllTrim(aDadosEmp[4]),oFont10) //End

	oPrinter:Say (nSalto+_nLin+0810,1910,"Agência/Código Cedente",oFont8)
	//oPrint:Say (nSalto+_nLin+0850,1950,aDadosBanco[3]+"/"+cCodEmp,oFont10)
	oPrinter:Say (nSalto+_nLin+0850,1950,Alltrim(SEE->EE_AGENCIA) + "/" + Alltrim(SEE->EE_CODEMP),oFont10)

	oPrinter:Say (nSalto+_nLin+0910,0100,"Data do Documento",oFont8)
	oPrinter:Say (nSalto+_nLin+0940,0100,DTOC(aDadosTit[2]),oFont10) // Emissao do Titulo (E1_EMISSAO)

	oPrinter:Say (nSalto+_nLin+0910,0505,"Nro.Documento",oFont8)
	//oPrint:Say (nSalto+_nLin+0940,0605,aDadosTit[7]+aDadosTit[1],oFont10) //Prefixo +Numero+Parcela
	oPrinter:Say (nSalto+_nLin+0940,0605,aDadosTit[7]+AllTrim(cNum)+AllTrim(cParc),oFont10) //Prefixo +Numero+Parcela

	oPrinter:Say (nSalto+_nLin+0910,1005,"Espécie Doc.",oFont8)
	oPrinter:Say (nSalto+_nLin+0940,1050,aDadosTit[8],oFont10) //Tipo do Titulo

	oPrinter:Say (nSalto+_nLin+0910,1355,"Aceite",oFont8)
	oPrinter:Say (nSalto+_nLin+0940,1455,"N",oFont10)

	oPrinter:Say (nSalto+_nLin+0910,1555,"Data do Processamento",oFont8)
	oPrinter:Say (nSalto+_nLin+0940,1655,DTOC(aDadosTit[3]),oFont10) // Data impressao
	oPrinter:Say (nSalto+_nLin+0910,1910,"Nosso Número",oFont8)
	//oPrint:Say (nSalto+_nLin+0940,1950,SUBSTR(aDadosTit[6],1,3)+"/"+SUBSTR(aDadosTit[6],4),oFont10)
	oPrinter:Say (nSalto+_nLin+0940,1950,PADL(alltrim(SUBSTR(aDadosTit[6],4)),14,'0'),oFont10)

	oPrinter:Say (nSalto+_nLin+0980,0100,"Uso do Banco",oFont8)
	oPrinter:Say (nSalto+_nLin+0980,0505,"Carteira",oFont8)
	oPrinter:Say (nSalto+_nLin+1010,0555,aDadosBco[6],oFont10)

	oPrinter:Say (nSalto+_nLin+0980,0755,"Espécie",oFont8)
	oPrinter:Say (nSalto+_nLin+1010,0805,"R$",oFont10)
	oPrinter:Say (nSalto+_nLin+0980,1005,"Quantidade",oFont8)
	oPrinter:Say (nSalto+_nLin+0980,1555,"Valor",oFont8)
	oPrinter:Say (nSalto+_nLin+0980,1910,"Valor do Documento",oFont8)
	oPrinter:Say (nSalto+_nLin+1010,1950,AllTrim(Transform(aDadosBco[7],"@E 999,999,999.99")),oFont10)//JSS Alterado para solução do caso 031197

	oPrinter:Say (nSalto+_nLin+1050,0100,"Instruções (Instruções de responsabilidade do beneficiário. Qualquer dúvida sobre este boleto, contate o beneficiário)",oFont8)
	//oPrint:Say (nSalto+_nLin+1150,0100,aBolText[1],oFont10)
	oPrinter:Say (nSalto+_nLin+1150,0100,&(aMsg[1]),oFont10)
	//oPrint:Say (nSalto+_nLin+1200,0100,aBolText[2],oFont10)
	oPrinter:Say (nSalto+_nLin+1200,0100,&(aMsg[2]),oFont10)
	//oPrint:Say (nSalto+_nLin+1200,0100,aBolText[2]+" "+AllTrim(Transform(((aDadosTit[5]*0.01)/30),"@E 99,999.99")),oFont10)
	//oPrinter:Say (nSalto+_nLin+1250,0100,aBolText[3],oFont10)
	oPrinter:Say (nSalto+_nLin+1050,1910,"(-)Desconto/Abatimento",oFont8)
	//oPrint:Say (nSalto+_nLin+1080,1950,AllTrim(Transform(aDadosTit[9],"@E 999,999,999.99")),oFont10) 
	oPrinter:Say (nSalto+_nLin+1120,1910,"(-)Outras Deduções",oFont8)
	oPrinter:Say (nSalto+_nLin+1190,1910,"(+)Mora/Multa",oFont8)
	oPrinter:Say (nSalto+_nLin+1260,1910,"(+)Outros Acréscimos",oFont8)
	//oPrint:Say (nSalto+_nLin+1290,1950,AllTrim(Transform(aDadosTit[10],"@E 999,999,999.99")),oFont10) 

	oPrinter:Say (nSalto+_nLin+1330,1910,"(=)Valor Cobrado",oFont8)    
	oPrinter:Say (nSalto+_nLin+1360,1950,AllTrim(Transform(aDadosBco[7],"@E 999,999,999.99")),oFont10) 

	
	oPrinter:Say (nSalto+_nLin+1400,0100,"Pagador",oFont8)
	If SA1->A1_PESSOA == 'F'
		
		//oPrint:Say (nSalto+_nLin+2720,0400,aDatSacado[1]+" ("+aDatSacado[2]+")",oFont10)
		oPrinter:Say (nSalto+_nLin+1430,0400,SubStr(aDadosSac[1], 1, 30) + " " + AllTrim(SA1->A1_CGC),oFont10)
		//oPrint:Say (nSalto+_nLin+2773,0400,aDatSacado[3],oFont10)
		//oPrint:Say (nSalto+_nLin+2826,0400,aDatSacado[6]+"    "+aDatSacado[4]+" - "+aDatSacado[5],oFont10)	// CEP+Cidade+Estado
		//oPrint:Say (nSalto+_nLin+2879,0400,"C.N.P.J.: "+TRANSFORM(aDatSacado[7],"@R 99.999.999/9999-99"),oFont10)	// CGC
		//oPrint:Say (nSalto+_nLin+2879,1950,SUBSTR(aDadosTit[6],1,3)+"/00"+SUBSTR(aDadosTit[6],4,8),oFont10)
	Else
		
		oPrinter:Say (nSalto+_nLin+2720,0400,SubStr(aDadosSac[1] , 1, 30) +  " " + TransForm(SA1->A1_CGC, "@R 99.999.999/9999-99"),oFont10)
		//oPrint:Say (nSalto+_nLin+2720,0400,aDatSacado[1]+" ("+aDatSacado[2]+")",oFont10)
		//oPrint:Say (nSalto+_nLin+2773,0400,aDatSacado[3],oFont10)
		//oPrint:Say (nSalto+_nLin+2826,0400,aDatSacado[6]+"    "+aDatSacado[4]+" - "+aDatSacado[5],oFont10)	// CEP+Cidade+Estado
		//oPrint:Say (nSalto+_nLin+2879,0400,"C.N.P.J.: "+TRANSFORM(aDatSacado[7],"@R 99.999.999/9999-99"),oFont10)	// CGC
	EndIf
	
	//oPrint:Say (nSalto+_nLin+1430,0400,aDatSacado[1]+" ("+aDatSacado[2]+")",oFont10)
	//oPrinter:Say (nSalto+_nLin+1430,0400,SubStr(aDadosSac[1], 1, 30) + " " + AllTrim(SA1->A1_CGC),oFont10)
	//oPrinter:Say (nSalto+_nLin+1483,0400,aDadosSac[3],oFont10)
	//oPrinter:Say (nSalto+_nLin+1536,0400,aDatSacado[6]+"    "+aDatSacado[4]+" - "+aDatSacado[5],oFont10) // CEP+Cidade+Estado
	//oPrinter:Say (nSalto+_nLin+1589,0400,"C.N.P.J.: "+TRANSFORM(aDatSacado[7],"@R 99.999.999/9999-99"),oFont10) // CGC
	//oPrint:Say (nSalto+_nLin+1589,1950,SUBSTR(aDadosTit[6],1,3)+"/00"+SUBSTR(aDadosTit[6],4,8),oFont10)
	//oPrint:Say (nSalto+_nLin+1589,1950,SUBSTR(aDadosTit[6],4,len(aDadosTit[6])-3),oFont10)
	oPrinter:Say (nSalto+_nLin+1605,0100,"Pagador/Avalista",oFont8)
	oPrinter:Say (nSalto+_nLin+1645,1500,"Autenticação Mecânica -",oFont8)
	oPrinter:Say (nSalto+_nLin+1645,1850,"Ficha de Compensação",oFont8)
	oPrinter:Line(_nLin+0710,1900,_nLin+1400,1900)
	oPrinter:Line(_nLin+1120,1900,_nLin+1120,2300)
	oPrinter:Line(_nLin+1190,1900,_nLin+1190,2300)
	oPrinter:Line(_nLin+1260,1900,_nLin+1260,2300)
	oPrinter:Line(_nLin+1330,1900,_nLin+1330,2300)
	oPrinter:Line(_nLin+1400,0100,_nLin+1400,2300)
	oPrinter:Line(_nLin+1640,0100,_nLin+1640,2300)

	_nLin := _nLin - 110
	FOR i := 100 TO 2300 STEP 50
		oPrinter:Line(_nLin+1890,i,_nLin+1890,i+30)
	NEXT i
	// Encerra aqui a alteracao para o novo layout - RAI
	oPrinter:Line(_nLin+2000,0100,_nLin+2000,2300)
	oPrinter:Line(_nLin+2000,0560,_nLin+1900,0560)
	oPrinter:Line(_nLin+2000,0800,_nLin+1900,0800)
	//oPrint:Say (nSalto+_nLin+1934,0100,aDadosBanco[2],oFont16)	// [2] Nome do Banco
	oPrinter:SayBitmap(_nLin+1900,0100,cSantLogo,430,90 )
	oPrinter:Say (nSalto+_nLin+1937,0567,aDadosBco[1]+"-7",oFont24)	// [1] Numero do Banco
	oPrinter:Say (nSalto+_nLin+1934,0820,aCB_RN_NN[2],oFont14n)		// [2] Linha Digitavel do Codigo de Barras
	oPrinter:Line(_nLin+2100,0100,_nLin+2100,2300)
	oPrinter:Line(_nLin+2200,0100,_nLin+2200,2300)
	oPrinter:Line(_nLin+2270,0100,_nLin+2270,2300)
	oPrinter:Line(_nLin+2340,0100,_nLin+2340,2300)
	oPrinter:Line(_nLin+2200,0500,_nLin+2340,0500)
	oPrinter:Line(_nLin+2270,0750,_nLin+2340,0750)
	oPrinter:Line(_nLin+2200,1000,_nLin+2340,1000)
	oPrinter:Line(_nLin+2200,1350,_nLin+2270,1350)
	oPrinter:Line(_nLin+2200,1550,_nLin+2340,1550)
	oPrinter:Say (nSalto+_nLin+2000,0100,"Local de Pagamento",oFont8)
	oPrinter:Say (nSalto+_nLin+2040,0100,"ATE O VENCIMENTO PAGUE PREFERENCIALMENTE NO SANTANDER",oFont8)
	oPrinter:Say (nSalto+_nLin+2065,0100,"APOS O VENCIMENTO PAGUE SOMENTE NO SANTANDER",oFont8)
	//oPrint:Say (nSalto+_nLin+2040,0100,"QUALQUER BANCO ATÉ A DATA DO VENCIMENTO",oFont10)
	oPrinter:Say (nSalto+_nLin+2000,1910,"Vencimento",oFont8)
	oPrinter:Say (nSalto+_nLin+2040,1950,DTOC(aDadosTit[4]),oFont10)
	oPrinter:Say (nSalto+_nLin+2100,0100,"Beneficiário",oFont8)
	//oPrint:Say (nSalto+_nLin+2125,0100,aDadosEmp[1]+"             - "+aDadosEmp[6],oFont10) //Nome + CNPJ
	oPrinter:Say (nSalto+_nLin+2125,0100,SubStr(aDadosEmp[1], 1, 30) + " CNPJ: " + aDadosEmp[6],oFont10) //Nome + CNPJ
	//oPrint:Say (nSalto+_nLin+2160,0100,AllTrim(aDadosEmp[2])+" "+AllTrim(aDadosEmp[3])+" "+AllTrim(aDadosEmp[4]),oFont10) //End
	oPrinter:Say (nSalto+_nLin+2160,0100,Alltrim(aDadosEmp[2]),oFont10) //End
	oPrinter:Say (nSalto+_nLin+2180,0100,Alltrim(aDadosEmp[3]) + " " + AllTrim(aDadosEmp[4]),oFont10) //End

	oPrinter:Say (nSalto+_nLin+2100,1910,"Agência/Código Cedente",oFont8)
	//oPrint:Say (nSalto+_nLin+2140,1950,aDadosBanco[3]+"/"+cCodEmp,oFont10)
	oPrinter:Say (nSalto+_nLin+2140,1950,Alltrim(SEE->EE_AGENCIA) + "/" + Alltrim(SEE->EE_CODEMP),oFont10)

	oPrinter:Say (nSalto+_nLin+2200,0100,"Data do Documento",oFont8)
	oPrinter:Say (nSalto+_nLin+2230,0100,DTOC(aDadosTit[2]),oFont10)			// Emissao do Titulo (E1_EMISSAO)
	oPrinter:Say (nSalto+_nLin+2200,0505,"Nro.Documento",oFont8)
	oPrinter:Say (nSalto+_nLin+2230,0605,aDadosTit[7]+aDadosTit[1],oFont10)	//Prefixo + Numero + Parcela
	oPrinter:Say (nSalto+_nLin+2200,1005,"Espécie Doc.",oFont8)
	oPrinter:Say (nSalto+_nLin+2230,1050,aDadosTit[8],oFont10)					//Tipo do Titulo
	oPrinter:Say (nSalto+_nLin+2200,1355,"Aceite",oFont8)
	oPrinter:Say (nSalto+_nLin+2230,1455,"N",oFont10)

	oPrinter:Say (nSalto+_nLin+2200,1555,"Data do Processamento",oFont8)
	//oPrint:Say (nSalto+_nLin+2230,1655,DTOC(aDadosTit[3]),oFont10) // Data impressao
	oPrinter:Say (nSalto+_nLin+2230,1655,Dtoc(aDadosTit[2]),oFont10) // Data impressao

	oPrinter:Say (nSalto+_nLin+2200,1910,"Nosso Número",oFont8)
	//oPrint:Say (nSalto+_nLin+2230,1950,SUBSTR(aDadosTit[6],1,3)+"/"+SUBSTR(aDadosTit[6],4),oFont10)
	//oPrint:Say (nSalto+_nLin+2230,1950,PADL(alltrim(SUBSTR(aDadosTit[6],4)),14,'0'),oFont10)
	oPrinter:Say (nSalto+_nLin+2230,1950,aDadosTit[7]+AllTrim(cNum)+AllTrim(cParc),oFont10)
	oPrinter:Say (nSalto+_nLin+2270,0100,"Uso do Banco",oFont8)
	oPrinter:Say (nSalto+_nLin+2270,0505,"Carteira",oFont8)
	oPrinter:Say (nSalto+_nLin+2300,0555,aDadosBco[6],oFont10)
	oPrinter:Say (nSalto+_nLin+2270,0755,"Espécie",oFont8)
	oPrinter:Say (nSalto+_nLin+2300,0805,"R$",oFont10)
	oPrinter:Say (nSalto+_nLin+2270,1005,"Quantidade",oFont8)
	oPrinter:Say (nSalto+_nLin+2270,1555,"Valor",oFont8)
	oPrinter:Say (nSalto+_nLin+2270,1910,"Valor do Documento",oFont8)
	//oPrint:Say (nSalto+_nLin+2300,1950,AllTrim(Transform(aDadosTit[11],"@E 999,999,999.99")),oFont10)
	oPrinter:Say (nSalto+_nLin+2300,1950,AllTrim(Transform(aDadosBco[7],"@E 999,999,999.99")),oFont10)


	oPrinter:Say (nSalto+_nLin+2340,0100,"Instruções (Instruções de responsabilidade do beneficiário. Qualquer dúvida sobre este boleto, contate o beneficiário)",oFont8)
	//oPrint:Say (nSalto+_nLin+2440,0100,aBolText[1],oFont10)
	oPrinter:Say (nSalto+_nLin+2440,0100,&(aMsg[1]),oFont10)
	//oPrint:Say (nSalto+_nLin+2490,0100,aBolText[2],oFont10)
	oPrinter:Say (nSalto+_nLin+2490,0100,&(aMsg[2]),oFont10)
	//oPrint:Say (nSalto+_nLin+2490,0100,aBolText[2]+" "+AllTrim(Transform(((aDadosTit[5]*0.01)/30),"@E 99,999.99")),oFont10)
	//oPrint:Say (nSalto+_nLin+2540,0100,aBolText[3],oFont10)

	oPrinter:Say (nSalto+_nLin+2340,1910,"(-)Desconto/Abatimento",oFont8)
	//oPrint:Say (nSalto+_nLin+2370,1950,AllTrim(Transform(aDadosTit[9],"@E 999,999,999.99")),oFont10) 
	oPrinter:Say (nSalto+_nLin+2410,1910,"(-)Outras Deduções",oFont8)
	oPrinter:Say (nSalto+_nLin+2480,1910,"(+)Mora/Multa",oFont8)
	oPrinter:Say (nSalto+_nLin+2550,1910,"(+)Outros Acréscimos",oFont8)
	//oPrint:Say (nSalto+_nLin+2580,1950,AllTrim(Transform(aDadosTit[10],"@E 999,999,999.99")),oFont10)
	oPrinter:Say (nSalto+_nLin+2620,1910,"(=)Valor Cobrado",oFont8)
	oPrinter:Say (nSalto+_nLin+2650,1950,AllTrim(Transform(aDadosBco[7],"@E 999,999,999.99")),oFont10)

	If SA1->A1_PESSOA == 'F'
		oPrinter:Say (nSalto+_nLin+2690,0100,"Pagador",oFont8)
		//oPrint:Say (nSalto+_nLin+2720,0400,aDatSacado[1]+" ("+aDatSacado[2]+")",oFont10)
		oPrinter:Say (nSalto+_nLin+2720,0400,SubStr(aDadosSac[1] , 1, 30) +  " " + TransForm(SA1->A1_CGC, "@R 999.999.999-99"),oFont10)
		//oPrint:Say (nSalto+_nLin+2773,0400,aDatSacado[3],oFont10)
		//oPrint:Say (nSalto+_nLin+2826,0400,aDatSacado[6]+"    "+aDatSacado[4]+" - "+aDatSacado[5],oFont10)	// CEP+Cidade+Estado
		//oPrint:Say (nSalto+_nLin+2879,0400,"C.N.P.J.: "+TRANSFORM(aDatSacado[7],"@R 99.999.999/9999-99"),oFont10)	// CGC
		//oPrint:Say (nSalto+_nLin+2879,1950,SUBSTR(aDadosTit[6],1,3)+"/00"+SUBSTR(aDadosTit[6],4,8),oFont10)
	Else
		oPrinter:Say (nSalto+_nLin+2690,0100,"Pagador",oFont8)
		oPrinter:Say (nSalto+_nLin+2720,0400,SubStr(aDadosSac[1] , 1, 30) +  " " + TransForm(SA1->A1_CGC, "@R 99.999.999/9999-99"),oFont10)
		//oPrint:Say (nSalto+_nLin+2720,0400,aDatSacado[1]+" ("+aDatSacado[2]+")",oFont10)
		//oPrint:Say (nSalto+_nLin+2773,0400,aDatSacado[3],oFont10)
		//oPrint:Say (nSalto+_nLin+2826,0400,aDatSacado[6]+"    "+aDatSacado[4]+" - "+aDatSacado[5],oFont10)	// CEP+Cidade+Estado
		//oPrint:Say (nSalto+_nLin+2879,0400,"C.N.P.J.: "+TRANSFORM(aDatSacado[7],"@R 99.999.999/9999-99"),oFont10)	// CGC
	EndIf

	oPrinter:Say (nSalto+_nLin+2879,1950,SUBSTR(aDadosTit[6],4,len(aDadosTit[6])-3),oFont10)
	oPrinter:Say (nSalto+_nLin+2895,0100,"Pagador/Avalista",oFont8)
	oPrinter:Say (nSalto+_nLin+2935,1500,"Autenticação Mecânica -",oFont8)
	oPrinter:Say (nSalto+_nLin+2935,1850,"Ficha de Compensação",oFont8)
	oPrinter:Line(_nLin+2000,1900,_nLin+2690,1900)
	oPrinter:Line(_nLin+2410,1900,_nLin+2410,2300)
	oPrinter:Line(_nLin+2480,1900,_nLin+2480,2300)
	oPrinter:Line(_nLin+2550,1900,_nLin+2550,2300)
	oPrinter:Line(_nLin+2620,1900,_nLin+2620,2300)
	oPrinter:Line(_nLin+2690,0100,_nLin+2690,2300)
	oPrinter:Line(_nLin+2930,0100,_nLin+2930,2300)

	//MSBAR("INT25"  ,27.8,1.5,CB_RN_NN[1],oPrint,.F.,,,,1.4,,,,.F.)   
	cFont:="Helvetica 65 Medium"
	//oPrint:FWMSBAR("INT25" /*cTypeBar*/,64.3/*nRow*/ ,2/*nCol*/, CB_RN_NN[1]/*cCode*/,oPrint/*oPrint*/,.F./*lCheck*/,/*Color*/,.T./*lHorz*/,0.017/*nWidth*/,0.95/*0.8*//*nHeigth*/,.F./*lBanner*/, cFont/*cFont*/,NIL/*cMode*/,.F./*lPrint*/,2/*nPFWidth*/,2/*nPFHeigth*/,.F./*lCmtr2Pix*/)
	oPrinter:FWMSBAR("INT25" /*cTypeBar*/,64.3/*nRow*/ ,2/*nCol*/, aCB_RN_NN[1]/*cCode*/,oPrinter/*oPrint*/,.F./*lCheck*/,/*Color*/,.T./*lHorz*/,0.017/*nWidth*/,0.95/*0.8*//*nHeigth*/,.F./*lBanner*/, cFont/*cFont*/,NIL/*cMode*/,.F./*lPrint*/,2/*nPFWidth*/,2/*nPFHeigth*/,.F./*lCmtr2Pix*/)
		

	oPrinter:EndPage()	// Finaliza a Pagina
RETURN 

Static Function FatorVencimento(dVencimento)
    
	Local dDataBase := CtoD("07/10/1997")  // Data base original
    Local dNovaBase := CtoD("22/02/2025")  // Nova data base para reinício do fator
    Local nFator := 0

    // Se a data de vencimento for antes de 22/02/2025, segue a regra antiga
    If dVencimento < dNovaBase
        nFator := dVencimento - dDataBase
    Else
        // Nova regra: reinicia do fator 1000 contando a partir de 22/02/2025
        nFator := 1000 + (dVencimento - dNovaBase)
    EndIf

	// Retorna o fator formatado com 4 dígitos
Return STRZERO(nFator, 4)
