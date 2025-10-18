#Include "RPTDEF.CH" 
#include 'TOTVS.CH'
#include 'FWPRINTSETUP.CH'
#Include 'TBICONN.CH'
#Include "FILEIO.CH"       
#include "apwizard.ch"
#Include "TBICODE.CH"
#Include "RWMAKE.CH"
#Include "TOPCONN.CH"


/*/{Protheus.doc} ENVLDIGT
Rotina usada para gerar linha digitável dos boletos para envio em alerta de vencimento
@type function
@version 12.1.33 
@author Ricardo Araujo
@since 01/05/2022
@param 
@param 
@param 
/*/

User Function ENVLDIGT(_aEmp)
	
	Local aRecno    := {}
	Local cQuery    := ""
	Local cAlias    := GetNextAlias()
	Local nA        := 0
  	Local _cEnv     := AllTrim(Upper(GetEnvServer()))      //(+)adicionado por taki em 28/01/16
	Local nTipo		:= Nil //PARAMIXB[1]  
	Local cSerieDan := Nil //PARAMIXB[2]
	Local cNotaDan	:= Nil //PARAMIXB[3]
	Local cChave    := ""
	Local lSchedule := .F.
	Local lEnvioOK  := .F.
	Local lApi 	  	:= .F.	 

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
   	Private cPDFGer                := ''  //GetTempPath() //SuperGetMv( 'CP_DIRBOL' ,, '' )
   	Private cPDFGer2               := ''
	Private cLayout                := ""
	Private cImag001               := ""
	Private cImag033               := ""
	Private cImag341               := ""
	Private lStatus4               := .F.
                                           
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

    DbSelectArea("SE1")

	If lSchedule

		cQuery := " SELECT SE1.R_E_C_N_O_ RECNO, SE1.E1_XBOMAIL E1_XBOMAIL,"
		cQuery += " SE1.E1_NUM E1_NUM, SE1.E1_PREFIXO E1_PREFIXO, SE1.E1_PARCELA E1_PARCELA"	
		cQuery += " FROM " + RetSqlName("SE1") + " SE1 (NOLOCK)"
		cQuery += " WHERE SE1.D_E_L_E_T_ = '' "
		cQuery += " AND SE1.E1_FILIAL = '" + xFilial("SE1") + "'"
		cQuery += " AND SE1.E1_SALDO > 0 "
		cQuery += " AND SE1.E1_NUMBCO <> ''"
		cQuery += " AND (SE1.E1_VENCREA = CONVERT(VARCHAR,GETDATE()+3,112) ) OR (SE1.E1_VENCREA = CONVERT(VARCHAR,GETDATE(),112))"	
		cQuery += " ORDER BY SE1.E1_NUM, SE1.E1_PARCELA"		

		//| ntipo 1 = não possui o nosso numero (E1_NUMBCO) ainda então tem que ser gerado. 
		//| ntipo 2 = existe o nosso numero (E1_NUMBCO) não precisa ser gerado.
		nTipo  := IIf(lImpriBol = .T.,2,1) 
	
	EndIf

	//+-------------------------------------------------------
	// tratamento para nao haver execucao concorrente
	//+-------------------------------------------------------
	if !(LockByName('ENVLDIGT', .T., .F.)) .AND. !lApi
        ConOut("ENVLDIGT ja esta em execucao")
        if lSchedule
            RpcClearEnv()
        Endif
        Return
	Endif  

	
 	If Select(cAlias) > 0
		(cAlias)->(DbCloseArea())
	EndIf	

	dbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cAlias,.F.,.T.)

	If (cAlias)->(Eof()) .And. Alltrim(FunName()) $("ENVLDIGT")
		MsgAlert("Não localizado registros para NF " + cNotaDan + ' - ' + cSerieDan)
	EndIf
	
	While (cAlias)->(!Eof())

		aRecno:= {}

		SE1->(DbGoTo((cAlias)->RECNO))	
		cChave := (cAlias)->E1_PREFIXO + (cAlias)->E1_NUM                           
											
		While (cAlias)->(!Eof()) .And. cChave == (cAlias)->E1_PREFIXO + (cAlias)->E1_NUM
				
			SE1->(DbGoTo((cAlias)->RECNO))	

			aAdd(aRecno,(cAlias)->RECNO)

			aTitulos := { ;
						SE1->E1_NUM		,;
						SE1->E1_PREFIXO ,;
						allTrim(SE1->E1_PARCELA) ,;
						SE1->E1_TIPO	,;
						SE1->E1_CLIENTE ,;
						SE1->E1_LOJA    ,;
						''				,;
						SE1->E1_PORTADO ,;
						SE1->E1_AGEDEP  ;
					} 

			DbSelectArea("SA1")
			SA1->(DbSetOrder(1))
			If !SA1->(DbSeek(xFilial("SA1") + SE1->E1_CLIENTE + SE1->E1_LOJA))
				Return
			EndIf			

			If  _cEnv == "TOTVS_SUNTECH"
				_cEmail   := Alltrim(SA1->A1_EMAIL)
				_cCc      := Alltrim(GetMV("CP_BOLMAIL")) 
				_cSubject := "Aviso de Vencimento (HB) - Título - " + aTitulos[1] + IIF(aTitulos[3]='','',' - ' + aTitulos[3])
			Else
				_cEmail   := 'financeiro1@hb.com.br,financeiro2@hb.com.br,suporte@hb.com.br' 
				_cCc      := ''
				_cSubject := "TESTE-HOMOLOGACAO - Aviso de Vencimento (HB) - Título - " + aTitulos[1] + IIF(aTitulos[3]='','',' - ' + aTitulos[3])
			EndIf	
					
			cBanco   := PadR(SE1->E1_XBCO,3)
			cAgencia := PadR(SE1->E1_XAGE,5)
			cConta   := PadR(SE1->E1_XCONTA,10)

			aDadosTit := {}
			aDadosBco := {}
			aDadosSac := {}
			aDados    := {}
			aTitulos  := {}
			aCB_RN_NN := {}  
						
			//===============================================================
			//Dados do Boleto BANCO DO BRASIL           
			//===============================================================
			If cBanco == '001'        
					
				Prep001a()
									
			EndIf
	
			//===============================================================
			//Dados do Boleto SANTANDER
			//===============================================================
			If cBanco == '033'        
					
				Prep033a()
				
			EndIf
							
			//===============================================================
			//Dados do Boleto ITAU
			//===============================================================
			If cBanco == '341'        
 
 				Prep341a()
				
			EndIf       

			nA++ 			
   		
   			(cAlias)->(DbSkip())

		EndDo

		_cBody   := MontaCorpo()

		lEnvioOK := EnvMail(, _cEmail, _cCc, "", _cSubject, _cBody, "", "")

		If lEnvioOK		

			Conout("Email enviado com sucesso!")

		EndIf	
	
    EndDo		    
	
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
					SE1->E1_VENCREA   				                ,;  //	[4]	Data do vencimento //SE1->E1_VENCTO
					(SE1->E1_SALDO - _nVlrAbat) 					,;  //	[5]	Valor do tÃ­tulo
					aCB_RN_NN[3]									,;  //	[6]	Nosso numero (Ver formula para calculo)
					SE1->E1_PREFIXO									,;  //	[7]	Prefixo da NF
					SE1->E1_TIPO } 								  		//	[8]	Tipo do Titulo

	
	If Empty(SE1->E1_NUMBCO) .Or. Len(Alltrim(SE1->E1_NUMBCO)) == 8//se já nao foi impresso			
	 	DbSelectArea("SE1")
		RecLock("SE1",.F.)  
			SE1->E1_NUMBCO 	:= '00' + SubStr(_cNossoNum, 8, 10)  
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

   //SE1->E1_NUMBCO 	:= '00' + SubStr(_cNossoNum, 8, 10)  
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
             
   aDadosTit := {AllTrim(SE1->E1_NUM)+AllTrim(SE1->E1_PARCELA)	,;  //	[1]	Numero do ti­tulo
					SE1->E1_EMISSAO								,;  //	[2]	Data da emissao do titulo
					dDataBase									,;  //	[3]	Data da emissao do boleto
					SE1->E1_VENCREA								,;  //	[4]	Data do vencimento
					(SE1->E1_SALDO - _nVlrAbat) 				,;  //	[5]	Valor do ti­tulo
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
					SE1->E1_VENCREA											,;  //	[4]	Data do vencimento
					(SE1->E1_SALDO - _nVlrAbat) 							,;  //	[5]	Valor do tÃ­tulo
					aCB_RN_NN[3]											,;  //	[6]	Nosso nÃºmero (Ver fÃ³rmula para calculo)
					SE1->E1_PREFIXO											,;  //	[7]	Prefixo da NF
					SE1->E1_TIPO }  										    //	[8]	Tipo do Titulo

	             
    If Empty(SE1->E1_NUMBCO) .Or. Len(Alltrim(SE1->E1_NUMBCO)) == 8//se já nao foi impresso
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

   If !Empty(SE1->E1_NUMBCO) .And. Len(Alltrim(SE1->E1_NUMBCO)) == 12	 
		_cNossoNum := SE1->E1_NUMBCO
		_cNossoNum := AllTrim(_cNossoNum)       
		cNroDoc := SE1->E1_NUMBCO
	Else		                                  
		_cNossoNum := SEE->EE_FAXATU
		_cNossoNum := AllTrim(_cNossoNum)
		cNroDoc    := SEE->EE_FAXATU
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
						SE1->E1_VENCREA									,;  //	[4]	Data do vencimento
						(SE1->E1_SALDO - _nVlrAbat) 					,;  //	[5]	Valor do tÃ­tulo
						aCB_RN_NN[3]									,;  //	[6]	Nosso nÃºmero (Ver fÃ³rmula para calculo)
						SE1->E1_PREFIXO									,;  //	[7]	Prefixo da NF
						SE1->E1_TIPO} 									    //	[8]	Tipo do Titulo

	             
        
return

//====================================================================================================
//calcula o código de barras do SANTANDER
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

	cFatVenc := STRZERO(dvencimento - CtoD("07/10/1997"),4)

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

//===============================================================================
//calcula codigo de barra, linha digitavel e nosso numero do banco ITAU
Static Function Prep341()
	
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
	aDadosBco := {SA6->A6_COD 							   ,;// [1]Numer	o do Banco
					SA6->A6_NREDUZ						   ,;// [2]Nome do Banco
					Alltrim(SubStr(SA6->A6_AGENCIA,1,4))   ,;// [3]AgÃªncia
					Alltrim(SubStr(SA6->A6_NUMCON,1,5))	   ,;// [4]Conta Corrente
					Alltrim(SubStr(SA6->A6_DVCTA,1,1))	   ,;// [5]DÃ­gito da conta corrente
					Alltrim(SubStr(SA6->A6_CARTEIR,1,3))	}// [6]Codigo da Carteira


	aDadosBanco  := {SEE->EE_CODIGO	   ,;     // [1]Numero do Banco
		"Banco Itaú S.A."              ,;     // [2]Nome do Banco
		SEE->EE_AGENCIA                ,;     // [3]AgÃªncia
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
		Datavalida(SE1->E1_VENCREA,.T.)                 					,;  // [4] Data do vencimento
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
	                   
	aDadosTit    := {AllTrim(SE1->E1_NUM)+AllTrim(SE1->E1_PARCELA)	,;  // [1] Numero do titulo
		SE1->E1_EMISSAO                              				,;  // [2] Data da emissao do titulo
		Date()   		                               				,;  // [3] Data da emissao do boleto
		Datavalida(SE1->E1_VENCREA,.T.)                 				,;  // [4] Data do vencimento
		_nValor														,;  // [5] Valor do ti­tulo
		aCB_RN_NN[3]                   		          				,;  // [6] Nosso numero (Ver formula para calculo)
		SE1->E1_PREFIXO                               				,;  // [7] Prefixo da NF
		SE1->E1_TIPO	                           					}   // [8] Tipo do Titulo

Return

//===============================================================================
//Gera linha digitavel , nosso numero e cod barra                 
//Agencia 3040
//DV      4
//Conta   20300 
                          //3419   1234     12345    1    12345678
Static Function CalculosBco(cBanco,cAgencia,cConta,cDacCC,cNroDoc,nValor,dVencto)

	Local cDAC          := ''
	Local cCodBarra     := ''
	Local cCampo1       := ''
	Local cCampo2       := ''
	Local cCampo3       := ''
	Local cCampo4       := ''
	Local cCampo5       := ''
	Local cfator        := strzero(dVencto - ctod("07/10/97"),4)
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
		cHtml += "      <p>Olá, " + SE1->E1_NOMCLI + ",</p> "
		cHtml += "      <p>Não identificamos o pagamento da fatura: "+ "XXXXXXXXX" +" / "+ "XXXXXXXXX" +", valor de R$ "+"XXXXXXXXX"+" vencida em "+"XXXXXXXXX"+".</p>"
		cHtml += "      <p>Anexo, boleto original.</p>"
		cHtml += "      <p>O pagamento deste boleto, poderá ser realizado através dos canais bancários ou redes credenciadas até a data limite de: "+"XXXXXXXXX"+".</p>"
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
		cHtml += "      <p>Olá, " + SE1->E1_NOMCLI + ",</p> "
		cHtml += "      <p>Gostaríamos de lembrar que o boleto da NF-e nº " + SE1->E1_NUM + IIF(SE1->E1_PARCELA='',''," - " + allTrim(SE1->E1_PARCELA)) + " vencerá em " + DTOC(aDadosTit[4]) + "</p> "
		cHtml += "      <p><h4>Algumas informações sobre o boleto:</h4></p>"
		cHtml += "      <p><b>Emitido por:</b> " + aDadosEmp[1] + " CNPJ: " + aDadosEmp[6]	+ "</p>"
		cHtml += "      <p><b>Emissão:</b> " + DTOC(aDadosTit[2]) + "</p>"
		cHtml += "      <p><b>Vencimento:</b> " + DTOC(aDadosTit[4]) + "</p>"
		cHtml += "      <p><b>Valor:</b> R$ " + TRANSFORM(aDadosTit[5], '@E 999,999.99') + "</p>"
		cHtml += "      <p><b>Código de Barras:</b> " + aCB_RN_NN[2] + "</p><br>"
		cHtml += "		<p>Em caso de dúvidas, entre em contato conosco:</p>"
		cHtml += "		<p>Tel: (11) 4591-8604 / 4591-8606 / 4591-8619</p>"
		cHtml += "		<p>WhatssApp (11) 4591-8600 / (11) 98911-8763</p>"
		cHtml += "		<p>e-mail: <a href='mailto:financeiro1@hb.com.br;financeiro2@hb.com.br;financeiro3@hb.com.br'>financeiro1@hb.com.br;financeiro2@hb.com.br;financeiro3@hb.com.br</a></p><br>"
		cHtml += "		<p>Visite nossa página de vendas corporativa <a href='https://b2b.hb.com.br'>https://b2b.hb.com.br</a> e para saber mais das novidades entre em <a href='https://www.hb.com.br'>https://www.hb.com.br</a></p>"
		cHtml += "		<p><hr></p>"
		cHtml += "      <p><h4>Como consultar a Nota Fiscal Eletrônica deste boleto?:</h4></p>"
		cHtml += "      <p><h4>Chave de Acesso da NF-e:</h4></p>"
		cHtml += "      <p>" + Posicione("SF2",1,xFilial("SF2") + SE1->E1_NUM,"F2_CHVNFE") + "</p>"
		cHtml += "      <p>Acesse o Portal da Nota Fiscal Eletrônica do Ministério da Fazenda em</p>"
		cHtml += "      <p><a href='http://www.nfe.fazenda.gov.br/'>http://www.nfe.fazenda.gov.br/</a></p>"
		cHtml += "      <p>Vá até Serviços mais Acessados >> Consultar NF-e. Digite a chave de acesso acima para acessar todas as informações sobre a NF-e.</p>"
		cHtml += "      <p>Se você já efetuou o pagamento, por favor desconsidere este e-mail.</p>
		cHtml += "      <p>Muito obrigado,</p>
		cHtml += "      <p>SUNTECH SUPPLIES</p>
		cHtml += "      <span style='font-size:10px; text-align:center; color:#F00;'>Aten&ccedil;&atilde;o: esse e-mail foi gerado automaticamente, n&atilde;o &eacute; necess&aacute;ria nenhuma resposta.</span> </p></td>"
		cHtml += "  </tr> "
		cHtml += "</table></td><br><br><br>"
	
	EndIf

	//rodape
	cHtml += '<table width="100%" class="table-a" style="background-color: #1c1c1c; color: #fff;padding-top:15px;padding-bottom:15px;"> '         
    cHtml += '<tr style="font-size:10.0pt;"> <td align="center"><table>'           
    cHtml += '<td  class="footer"><table  width="180" ><tr><td > <span class="footer-texto">'
    cHtml += '<p>&nbsp;&nbsp;&nbsp;<b> Garantia e Assist&ecirc;ncia </b></p></span><span class="footer-texto"> <p> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 11 4591-8600 <br> &nbsp;&nbsp;&nbsp; De segunda &agrave; sexta <br>'                                             
    cHtml += '&nbsp;&nbsp;&nbsp; das 8h-12h | 13h-16h</p></span></td></tr></table></td><td> <table width="100"></table></td><td class="footer"><table width="180" >' 
    cHtml += '<tr><td><span class="footer-texto"><p><b>Andamento de pedidos </b></p></span><span class="footer-texto"><p>&nbsp;&nbsp;&nbsp; <br>De segunda &agrave; sexta<br>'                                       
    cHtml += 'das 09h00 &agrave;s 18h</p></span></td></tr></table></td></table></td></tr></table>'
	cHtml += '</body></html>'	
	
Return cHtml
