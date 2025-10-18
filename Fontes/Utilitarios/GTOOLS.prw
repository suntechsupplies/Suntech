#include 'protheus.ch'
#include 'parmtype.ch'
#include "totvs.ch"
#Include "apwizard.ch"
/*‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹‹
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±…ÕÕÕÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÀÕÕÕÕÕÕ—ÕÕÕÕÕÕÕÕÕÕÕÕÕª±±
±±∫Programa  ≥GTOOLS    ∫Autor  ≥ Cristiam Rossi     ∫ Data ≥  21/03/18   ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕ ÕÕÕÕÕÕœÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±∫Desc.     ≥ Funcionalidades para levantamento de fontes x RPO          ∫±±
±±∫          ≥                                                            ∫±±
±±ÃÕÕÕÕÕÕÕÕÕÕÿÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕÕπ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂﬂ*/
User Function gTools

	local   oWizard
	local   oPanel
	local   oBtn
	local   oCombo
	local   cCombo  := "1-HTML"
	private oGet
	private _nQtd   := 0
	private oPasta
	private cPasta  := Space(50)
	private aFontes := {}
	private cRelat
	private nHdl    := -1
	private nCombo  := 1

	SET DATE BRITISH

	DEFINE WIZARD oWizard TITLE "Levantamento de Fontes x RPO" ;
	HEADER "Confrontar a pasta de fontes com o ambiente" ;
	MESSAGE "" ;
	TEXT "Esta rotina ir· pesquisar todos os fontes da pasta informada e comparar com as versıes compiladas no RPO." ;
	NEXT {||.T.} ;
	FINISH {|| .T. } ;
	PANEL

	CREATE PANEL oWizard ;
	HEADER "Informe a pasta do projeto" ;
	MESSAGE "A rotina ir· carregar os fontes para verificaÁ„o" ;
	BACK {|| .T. } ;
	NEXT {|| verFontes( cPasta ) } ;
	FINISH {|| .T. } ;
	PANEL
	oPanel := oWizard:GetPanel(2)
	@ 15,15 SAY "Pasta dos fontes:" SIZE 45,8 PIXEL OF oPanel
	@ 13,60 button oBtn prompt "Sel.Pasta" size 45, 12 action getPasta()  PIXEL OF oPanel
	@ 25,15 MSGET oPasta Var cPasta SIZE 240,10 PIXEL OF oPanel when .F.

	@ 115,15 Say "Obs: A rotina ir· buscar subpastas." of oPanel Pixel

	CREATE PANEL oWizard ;
	HEADER "Fontes encontrados" ;
	MESSAGE "" ;
	BACK {|| .T. } ;
	NEXT {|| verifRPO() } ;
	FINISH {|| .T. } ;
	PANEL
	oPanel := oWizard:GetPanel(3)
	@ 15,15 SAY "Fontes encontrados:" PIXEL OF oPanel
	@ 25,15 MSGET oGet var _nQtd PICTURE "@E 999,999,999" SIZE 40,10 WHEN .f. PIXEL OF oPanel

	@ 45,15 SAY "VisualizaÁ„o do RelatÛrio:" PIXEL OF oPanel
	@ 55,15 MSCOMBOBOX oCombo VAR cCombo ITEMS {"1-HTML","2-CSV"} SIZE 038, 010 PIXEL OF oPanel on Change (nCombo := iif(left(cCombo,1)=="1",1,2) )
	@ 115,15 Say "Obs: PrÛximo passo È a verificaÁ„o no RPO." of oPanel Pixel


	CREATE PANEL oWizard ;
	HEADER "FinalizaÁ„o" ;
	MESSAGE "ConfirmaÁ„o." ;
	BACK {|| .T. } ;
	NEXT {|| .F. } ;
	FINISH {|| .T. } ;
	PANEL
	oPanel := oWizard:GetPanel(4)
	@ 15,15 SAY "O relatÛrio j· foi aberto, caso queira abrir novamente selecione o bot„o." SIZE 200,8 PIXEL OF oPanel
	@ 25,60 button oBtn prompt "relatÛrio" size 45, 12 action abrirRel() PIXEL OF oPanel

	ACTIVATE WIZARD oWizard CENTERED

return nil


//--------------------------------------------
Static Function getPasta()
	cPasta := cGetFile('Arquivos (*.pr?)|*.pr?' , 'Selecione a pasta a ser carregada',1,'C:\',.T.,nOR( GETF_LOCALHARD, GETF_RETDIRECTORY ), .T., .T. )
	oPasta:SetText(cPasta)
	oPasta:Refresh()
return nil

//--------------------------------------------
Static Function verFontes()
	//local aTmp := {}
	local nI

	if empty( cPasta )
		msgAlert("Selecione uma pasta antes!")
		return .F.
	endif

	aSize( aFontes, 0 )
	aFontes := getFontes(cPasta)

	//	msgRun("Favor aguarde...","Coletando fontes",{|| aFontes := getFontes(cPasta)})

	msgRun("Favor aguarde...","Consultando RPO", {|| consRPO() })

	aSort( aFontes,,, {|itA, itB| itA[1]+itA[5] < itB[1]+itB[5]} )

	_nQtd := 0
	for nI := 1 to len( aFontes )
		if ! empty(aFontes[5])
			_nQtd++
		endif
	next

	oGet:SetText(_nQtd)
	oGet:refresh()

return len(aFontes) > 0


//--------------------------------------------
static function getFontes( cFolder )
	local aTmp  := {}
	local aTmp2 := {}
	local aRet  := {}
	local nX
	local nI

	if empty(cFolder)
		return {}
	endif

	if right( cFolder, 1) != "\"        // se for diferente de barra o caminho da pasta   EX: Z:\P12OS\Protheus\rdmake_new
		cFolder += "\"                  // Adicionar barra ao caminho da pasta            EX: Z:\P12OS\Protheus\rdmake_new\
	endif

	aTmp := Directory(cFolder + "*.*", "D", nil, .T., 1)       //   salva o caminho da pasta na variavel aTmp

	for nX := 1 to len(aTmp)  // Fazer um laÁo de repetiÁ„o de 1 ate o tamanho dos arquivos|pasta no caminho informado
		if upper(aTmp[nX,1]) != "."   // se a Matriz aTmp[nX,1] for diferente de .
			aTmp2 := getFontes( cFolder+aTmp[nX,1])  // chamar as funÁıes que busca os fontes, adicionando a subpasta
			for nI := 1 to len( aTmp2 )              // fazer um laÁo de repetiÁ„o de 1 ate o tamanho da subpasta
				aadd( aRet, aClone(aTmp2[nI]))       // Adicionar o fonte no array aRet
			next 
		endif
		if right( lower(aTmp[nX,1]), 4 ) == ".prw" .or. right( lower(aTmp[nX,1]), 4 ) == ".prx"    // se as ultimas 4 letras forem .prw ou .prx 
			aadd( aRet, aClone(aTmp[nX]) )                // adicionas o fonte no array aRet
			aTail(aRet)[5] := cFolder                     // retornar o array aRet, o ultimo caminho de pasta utilizado acima
		endif
	next

return aClone(aRet)     // Duplica o Array


//----------------------------------------------------------------------
static function consRPO()
	local aTipo
	local aArquivo
	local aLinha
	local aData
	local aHora
	local aFiles
	local nI

	aFiles := GetFuncArray( "U_*", @aTipo, @aArquivo, @aLinha, @aData, @aHora )  

	for nI := 1 to len( aFiles )
		if aTipo[nI] == "USER"
			if aScan( aFontes, {|it| it[1] == aArquivo[nI] } ) == 0
				aadd( aFontes, { aArquivo[nI], 0, CtoD("  /  /  "), "", ""} )
			endif
		endif
	next

return nil


//----------------------------------------------------------------------
static function abrirRel()
	ShellExecute( "Open", cRelat, "", "C:\", 3)
return nil


//----------------------------------------------------------------------
static function verifRPO()

	cRelat  := getTempPath()

	if nCombo == 1	// html
		cRelat += "gTools.html"
	else
		cRelat += "gTools.csv"
	endif

	if file( cRelat )
		if fErase( cRelat ) == -1
			msgStop("N„o foi possÌvel excluir o relatÛrio antigo: "+cRelat)
			return .F.
		endif
	endif

	nHdl := fCreate(cRelat)
	if nHdl == -1
		msgStop("N„o foi possÌvel criar o arquivo do relatÛrio: "+cRelat)
		return .F.
	endif

	Processa({|lEnd| consFontes(@lEnd)},"Aguarde...","Consultando RPO",.T.)

	FCLOSE(nHdl)
	abrirRel()
return .T.


//----------------------------------------------------------
static function consFontes(lEnd)
	//local nI
	local cTotal := " de "+cValToChar(len(aFontes))
	local aTemp
	local cLinha
	local xTemp
	local lCor1  	:= .F.
	local aCor   	:= {"#EEE9E9", "#CDC9C9"}
	Local _cEmpresa	:= "60"
	Local _cFilial	:= "01"
	Local nNTest	:= 0
	Local nTest		:= 0
	Local nZ
	Local _nCount	:= 0

	//**********************************************************************************
	// Efetua a preparaÁ„o do ambiente e a inclusao do Pedido de Vendas via MsExecAuto 
	//**********************************************************************************
	If FindFunction("WfPrepEnv") //.And. cNumemp <> _cEmpresa + _cFilial 
		WfPrepEnv(_cEmpresa,_cFilial)
		cEmpant := _cEmpresa
		cFilant := _cFilial
		cNumEmp	:= _cEmpresa + _cFilial 
		Sleep(5000)
	Endif

	//_cTBLog := SuperGetMV("HS_TABLOG",.F.,"ZAG")

	ProcRegua( len(aFontes) )

	if nCombo == 1		// HTML
		cLinha := "<html><head><title>gTools - inspeÁ„o de fontes</title></head><body>"
		cLinha += "VerificaÁ„o da pasta: <strong>"+cPasta+"</strong><br />"
		cLinha += "N˙mero de User Functions no RPO: <strong>"+cValToChar(len(aFontes))+"</strong><br />"
		cLinha += "Analisado em : <strong>"+ DtoC(date()) +" "+Time()+"</strong><br /><br />"

		cLinha += "<table width=100%><tr>"
		cLinha += "<th>SEQ</th>"
		cLinha += "<th>FONTE</th>"
		cLinha += "<th>TAMANHO</th>"
		cLinha += "<th>DTHR FONTE</th>"
		cLinha += "<th>DTHR RPO</th>"
		cLinha += "<th>STATUS RPO</th>"
		cLinha += "<th>CAMINHO DO FONTE</th>"
		//cLinha += "<th>Chamada de Log</th></tr>"	// Carlos Eduardo Saturnino
//		cLinha += "<th>TESTADO ?</th></tr>"			// Carlos Eduardo Saturnino
	else											// CSV
		cLinha := "SEQ;"
		cLinha += "FONTE;"
		cLinha += "TAMANHO;"
		cLinha += "DTHR fonte;"
		cLinha += "DTHR RPO;"
		cLinha += "STATUS RPO;"
		cLinha += "CAMINHO DO FONTE;"
		//cLinha += "Chamada de Log;"					// Carlos Eduardo Saturnino
		//cLinha += "TESTADO ?;"							// Carlos Eduardo Saturnino
		cLinha += CRLF
	endif
	Fwrite(nHdl, cLinha, Len(cLinha))

	For nZ := 1 to len(aFontes)

		If aFontes[nZ,2] <> 0

			_nCount ++
			
			xTemp := cValToChar(nZ)
			incProc("analisando fonte "+xTemp+cTotal)

			if lEnd		// usuario interrompeu
				if nCombo == 1		// HTML
					cLinha := "<tr><td colspan='7'>interrompido pelo usu·rio</td></tr>"
				else
					cLinha := "interrompido pelo usu·rio"
				endif
				Fwrite(nHdl, cLinha, Len(cLinha))
				exit
			endif

			//-------------------------------------------------------------------------------
			// Incluido para desconsiderar as User Functions nativas do RPO
			// Carlos Eduardo Saturnino em 18/04/2020
			//-------------------------------------------------------------------------------
			/*
			if nCombo == 1 
			cLinha := "<td>#"+xTemp + "</td>"
			cLinha += "<td>"+aFontes[nZ,1] + "</td>"
			cLinha += "<td>"+cValToChar(aFontes[nZ,2]) + "</td>"
			cLinha += "<td>"+DtoC(aFontes[nZ,3]) + " " + aFontes[nZ,4] + "</td>"
			else
			cLinha := "#"+xTemp + ";"
			cLinha += aFontes[nZ,1] + ";"
			cLinha += cValToChar(aFontes[nZ,2]) + ";"
			cLinha += DtoC(aFontes[nZ,3]) + " " + aFontes[nZ,4] + ";"
			endif
			*/

			if nCombo == 1 			// HTML
				If ! Empty(aFontes[nZ,4]) .And. aFontes[nZ,2] > 0	
					cLinha := "<td>#"+cValToChar(_nCount) + "</td>"							// Preenchimento do Sequencial
					cLinha += "<td>"+aFontes[nZ,1] + "</td>"								// Preenchimento do Nome do Fonte
					cLinha += "<td>"+cValToChar(aFontes[nZ,2]) + "</td>"					// Preenchimento do Tamanho do Programa
					cLinha += "<td>"+DtoC(aFontes[nZ,3]) + " " + aFontes[nZ,4] + "</td>"	// Preenchimento do Data e Hora do Programa
				Endif
			else
				If ! Empty(aFontes[nZ,4]) .And. aFontes[nZ,2] > 0	
					cLinha := "#"+cValToChar(_nCount) + ";"									// Preenchimento do SequenciaÁ
					cLinha += aFontes[nZ,1] + ";"											// Preenchimento do Nome do Fonte
					cLinha += cValToChar(aFontes[nZ,2]) + ";"								// Preenchimento do Tamanho do Programa
					cLinha += DtoC(aFontes[nZ,3]) + " " + aFontes[nZ,4] + ";"				// Preenchimento do Data e Hora do Programa 
				Endif
			endif

			//-------------------------------------------------------------------------------

			aTemp := GetAPOInfo(aFontes[nZ,1])

			if len( aTemp ) > 4		// tem dados no RPO
				//-------------------------------------------------------------------------------
				// Incluido para desconsiderar as User Functions nativas do RPO
				// Carlos Eduardo Saturnino em 18/04/2020
				//-------------------------------------------------------------------------------
				/*if nCombo == 1		// HTML
				cLinha += "<td>"+DtoC(aTemp[4]) + " " + aTemp[5] + "</td>"
				else
				cLinha += DtoC(aTemp[4]) + " " + aTemp[5] + ";"
				endif
				*/

				if nCombo == 1			// HTML
					If ! Empty(aFontes[nZ,4]) .And. aFontes[nZ,2] > 0
						cLinha += "<td>"+DtoC(aTemp[4]) + " " + aTemp[5] + "</td>"		// Preenchimento da Data e Hora do RPO
					Endif
				else
					If ! Empty(aFontes[nZ,4]) .And. aFontes[nZ,2] > 0
						cLinha += DtoC(aTemp[4]) + " " + aTemp[5] + ";"					// Preenchimento da Data e Hora do RPO
					Endif
				endif

				//-------------------------------------------------------------------------------

				if empty(aFontes[nZ,4]) 

					//-------------------------------------------------------------------------------
					// Incluido para desconsiderar as User Functions nativas do RPO
					// Carlos Eduardo Saturnino em 18/04/2020
					//-------------------------------------------------------------------------------
					/*
					if nCombo == 1		// HTML
					cLinha += '<td style="background-color:Red">FONTE n„o encontrado</td>'
					else
					cLinha += "FONTE n„o encontrado;"
					endif
					*/

				elseif DtoS(aFontes[nZ,3])+aFontes[nZ,4] > DtoS(aTemp[4])+aTemp[5]
					if nCombo == 1		// HTML
						cLinha += '<td style="background-color:LightBlue">RPO desatualizado</td>'		// Preenchimento do Status RPO
					else
						cLinha += "RPO desatualizado;"													// Preenchimento do Status RPO
					endif
					cDif := DtoS(aFontes[nZ,3])+aFontes[nZ,4] - DtoS(aTemp[4])+aTemp[5]

				elseif DtoS(aFontes[nZ,3])+aFontes[nZ,4] < DtoS(aTemp[4])+aTemp[5]
					if nCombo == 1		// HTML
						cLinha += '<td style="background-color:#EE82EE">FONTE desatualizado</td>'		// Preenchimento do Status RPO
					else
						cLinha += "FONTE desatualizado;"												// Preenchimento do Status RPO
					endif
				else
					if nCombo == 1		// HTML
						cLinha += '<td style="background-color:#00CC00">OK</td>'						// Preenchimento do Status RPO
					else
						cLinha += "OK;"																	// Preenchimento do Status RPO
					endif
				endif
			else
				if nCombo == 1		// HTML
					cLinha += "<td></td>"
					cLinha += '<td style="background-color:orange">FONTE n„o compilado</td>'			// Preenchimento do Status RPO
				else
					cLinha += ";"
					cLinha += "FONTE n„o compilado;"													// Preenchimento do Status RPO 
				endif
			endif

			//-------------------------------------------------------------------------------
			// Incluido para desconsiderar as User Functions nativas do RPO
			// Carlos Eduardo Saturnino em 18/04/2020
			//-------------------------------------------------------------------------------
			/*
			if nCombo == 1		// HTML
			cLinha += "<td>"+aFontes[nZ,5] + "</td>"
			else
			cLinha += aFontes[nZ,5] + CRLF
			endif

			if nCombo == 1		// HTML
			lCor1 := ! lCor1
			cLinha := '<tr style="background-color:'+iif(lCor1,aCor[1],aCor[2])+'">'+ cLinha +"</tr>"
			endif
			*/

			if nCombo == 1		// HTML
				If ! Empty(aFontes[nZ,4]) .And. aFontes[nZ,2] > 0
					cLinha += "<td>"+aFontes[nZ,5] + "</td>"				// Preenchimento do Caminho do Fonte
				Endif
			else
				If ! Empty(aFontes[nZ,4]) .And. aFontes[nZ,2] > 0
					//cLinha += aFontes[nZ,5] + CRLF							// Preenchimento do Caminho do Fonte
					cLinha += aFontes[nZ,5] 							// Preenchimento do Caminho do Fonte
				Endif
			endif

			//------------------------------------------------------
			// Verifica se o h· a chamada do Log na User Function
			//------------------------------------------------------
			/*
			If nCombo == 1 		// HTML
			cLinha += "<td>"+ "Hello World" + "</td>"
			Else
			cLinha += "Hello World"
			Endif
			*/
			//------------------------------------------------------
			// Verifica a User Function foi testada 
			//------------------------------------------------------
			/*
			If ! Empty(aFontes[nZ,4]) .And. aFontes[nZ,2] > 0
				dbSelectArea("ZAG")			
				dbSetOrder(4)
				If dbSeek(FwFilial("ZAG") + "U_" + Substr(aFontes[nZ,1], 1, AT(".",aFontes[nZ,1])-1) )
					If nCombo == 1 		// HTML
						cLinha += '<td style="background-color:#00CC00">Fonte Testado</td>'
					Else
						cLinha += "Fonte Testado" + CRLF
					Endif
					nTest ++
				Else
					If nCombo == 1 		// HTML
						cLinha += '<td style="background-color:Red">Fonte n„o Testado</td>'
					Else
						cLinha += "Fonte n„o Testado" + CRLF
					Endif
					nNTest ++		
				Endif
			Endif
			*/
			if nCombo == 1		// HTML
				If ! Empty(aFontes[nZ,4]) .And. aFontes[nZ,2] > 0						
					lCor1 := ! lCor1
					cLinha := '<tr style="background-color:'+iif(lCor1,aCor[1],aCor[2])+'">'+ cLinha +"</tr>"		// Preenchimento da cor da Linha
				Endif
			endif


			//-------------------------------------------------------------------------------

			Fwrite(nHdl, cLinha, Len(cLinha))

		Endif

	next nZ

	if nCombo == 1		// HTML
		cLinha += "Percentual de Fontes j·  Testados : <font color='#008000'><strong>" + cValToChar(Round((nTest  / _nCount)*100,2)) 	+ "%</strong></font><br />" 
		cLinha += "Percentual de Fontes n„o Testados : <font color='#990000'><strong>" 	 + cValToChar(Round((nNTest / _nCount)*100,2)) 	+ "%</strong></font><br /><br />"
		cLinha += "</table></body></html>"
		Fwrite(nHdl, cLinha, Len(cLinha))
	endif
	

return nil
