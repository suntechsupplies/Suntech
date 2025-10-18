#include "protheus.ch"
#include "FINR127.ch"

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณFINR127   บAutor  ณ Clovis Magenta			 บData ณ 16/06/10บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Relatorio referente a lei 12.007                           บฑฑ
ฑฑบ          ณ Quita็ใo anual de debito                                   บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                         บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Function FINR127()

Local oReport
Private cPerg 	:= "FIN127"

oReport := ReportDef()
oReport:PrintDialog()

Return


// Impressao
Static Function ReportDef()

Local oReport
Local oSection1
Local oSection2
Local cTexto 	:= " "
Local cAlias	:= " "

oReport := TReport():New("FINR127",STR0002,cPerg,{|oReport| PrintReport(oReport)},STR0003) //"LEI Nบ 12.007" //"Relat๓rio de quita็ใo de Debitos"

AjustaSX1(cPerg)

Pergunte(cPerg,.F.)

oSection1 := TRSection():New(oReport,STR0004+ALLTRIM(SM0->M0_NOME),,,,,,,,,,.T.,/*25*/,,,.F.) //"DECLARAวรO DE QUITAวรO ANUAL DE DษBITOS "
oSection1:oReport:nFontBody := 20
oSection2 := TRSection():New(oReport,STR0005,cAlias,,,,,,,,,.T.,,,,.T.) //"QUITAวรO ANUAL DE DษBITOS"
oSection2:oReport:nFontBody := 12

oReport:SetLineHeight(50)
TRCell():New(oSection1,STR0006,"",,,80,,,,.T.,"LEFT",.F.,,.F.)

TRCell():New(oSection2,"E1_CLIENTE",cAlias,,PesqPict("SE1","E1_CLIENTE"), TamSX3("E1_CLIENTE")[1],,,,,"LEFT")
TRCell():New(oSection2,"E1_LOJA",cAlias,,PesqPict("SE1","E1_LOJA"), TamSX3("E1_LOJA")[1],,,,,"LEFT")
TRCell():New(oSection2,"A1_NOME",cAlias,,PesqPict("SA1","A1_NOME"), TamSX3("A1_NOME")[1],,,,,"LEFT")
TRCell():New(oSection2,STR0008,cAlias,,,10,,,,,"LEFT") // MES
TRCell():New(oSection2,STR0007,cAlias,,PesqPict("SE1","E1_SALDO"), TamSX3("E1_SALDO")[1],,,,,"RIGHT") //"SALDO PAGO"

Return oReport


Static Function PrintReport(oReport)
Local oSection1   := oReport:Section(1)
Local oSection2   := oReport:Section(2)
Local cQuery 		:= ""
Local cTitulo		:= STR0005  //"Quita็ใo ANUAL de D้bitos"
Local lSimples 	:= MV_PAR06 == 1 // Simplificado = 1 / Detalhado = 2
Local lModified 	:= .F.
Local cCliLoj 		:= ""
Local cAno			:= Alltrim(MV_PAR05)
Local cEmpresa		:= ALLTRIM(SM0->M0_NOME)
Local lPETexto  	:= ExistBlock("FIN127TXT")
Local lPEQry 		:= ExistBlock("FIN127QRY")
Local lPETitulo	:= ExistBlock("FIN127TIT")

#IFDEF TOP         

If lSimples                

	cAlias := GetNextAlias()
	
	cQuery := " SELECT "
	cQuery += " COUNT(SE1.E1_CLIENTE) AS QTD, SE1.E1_CLIENTE, SE1.E1_LOJA, SA1.A1_NOME NOME, SUM(SE1.E1_SALDO) SALDO "
	cQuery += " FROM " + RetSqlName('SE1') + " SE1 " 
	cQuery += " JOIN " + RetSqlName("SA1") + " SA1 ON (SE1.E1_LOJA = SA1.A1_LOJA) AND (SE1.E1_CLIENTE = SA1.A1_COD) "
	cQuery += " WHERE "
	cQuery += " SE1.E1_CLIENTE >= '" + MV_PAR01 + "' "
	cQuery += " AND SE1.E1_CLIENTE <= '" + MV_PAR02 + "' "
	cQuery += " AND SE1.E1_LOJA >= '" + MV_PAR03 + "' "
	cQuery += " AND SE1.E1_LOJA <= '" + MV_PAR04 + "' "
	cQuery += " AND SUBSTRING(SE1.E1_VENCREA,1,4) = '" + MV_PAR05 + "' "
	cQuery += " AND SE1.E1_TIPOLIQ = ' ' "
	cQuery += " AND SE1.E1_TIPOFAT = ' ' "
	cQuery += " AND SE1.E1_TIPO NOT IN ('RA ', 'NCC') "
	cQuery += " AND SE1.E1_TIPO NOT IN ('AB-','IR-', 'IN-','IS-','PI-','CF-','CS-','FU-','FE-') " 
	cQuery += " AND SE1.D_E_L_E_T_ = ' ' "
	cQuery += " AND SA1.D_E_L_E_T_ = ' ' "  
	cQuery += " GROUP BY E1_CLIENTE,E1_LOJA,A1_NOME "
	cQuery += " ORDER BY E1_CLIENTE,E1_LOJA,A1_NOME "

Else

	cAlias := GetNextAlias()
	
	cQuery := " SELECT "  
	cQuery += " SE1.E1_CLIENTE, SE1.E1_LOJA, SA1.A1_NOME NOME, SUM(SE1.E1_SALDO) SALDO, SUM(SE1.E1_VALOR) VALOR, SUBSTRING(SE1.E1_VENCREA,5,2) MES "
	cQuery += " FROM " + RetSqlName('SE1') + " SE1 " 
	cQuery += " JOIN " + RetSqlName("SA1") + " SA1 ON (SE1.E1_LOJA = SA1.A1_LOJA) AND (SE1.E1_CLIENTE = SA1.A1_COD) "
	cQuery += " WHERE "
	cQuery += " SE1.E1_CLIENTE >= '" + MV_PAR01 + "' "
	cQuery += " AND SE1.E1_CLIENTE <= '" + MV_PAR02 + "' "                       
	cQuery += " AND SE1.E1_LOJA >= '" + MV_PAR03 + "' "
	cQuery += " AND SE1.E1_LOJA <= '" + MV_PAR04 + "' "
	cQuery += " AND SUBSTRING(SE1.E1_VENCREA,1,4) = '" + MV_PAR05 + "' "
	cQuery += " AND SE1.E1_TIPOLIQ = ' ' "
	cQuery += " AND SE1.E1_TIPOFAT = ' ' "
	cQuery += " AND SE1.E1_TIPO NOT IN ('RA ', 'NCC') "
	cQuery += " AND SE1.E1_TIPO NOT IN ('AB-','IR-', 'IN-','IS-','PI-','CF-','CS-','FU-','FE-') " 
	cQuery += " AND SE1.D_E_L_E_T_ = ' ' "
	cQuery += " AND SA1.D_E_L_E_T_ = ' ' "
	cQuery += " AND SA1.D_E_L_E_T_ = ' ' "
	cQuery += " AND SE1.E1_CLIENTE || SE1.E1_LOJA NOT IN (
		cQuery += " SELECT "
		cQuery += " A.E1_CLIENTE || A.E1_LOJA "
		cQuery += " FROM " + RetSqlName('SE1') + " A " 
		cQuery += " JOIN " + RetSqlName("SA1") + " B ON (A.E1_LOJA = B.A1_LOJA) AND (A.E1_CLIENTE = B.A1_COD) "
		cQuery += " WHERE "
		cQuery += " A.E1_CLIENTE >= '" + MV_PAR01 + "' "
		cQuery += " AND A.E1_CLIENTE <= '" + MV_PAR02 + "' "
		cQuery += " AND A.E1_LOJA >= '" + MV_PAR03 + "' "
		cQuery += " AND A.E1_LOJA <= '" + MV_PAR04 + "' "
		cQuery += " AND SUBSTRING(A.E1_VENCREA,1,4) = '" + MV_PAR05 + "' "
		cQuery += " AND A.E1_SALDO > 0 "
		cQuery += " AND A.E1_TIPOLIQ = ' ' "
		cQuery += " AND A.E1_TIPOFAT = ' ' "
		cQuery += " AND A.E1_TIPO NOT IN ('RA ', 'NCC') "
		cQuery += " AND A.E1_TIPO NOT IN ('AB-','IR-', 'IN-','IS-','PI-','CF-','CS-','FU-','FE-') " 
		cQuery += " AND A.D_E_L_E_T_ = ' ' "
		cQuery += " AND B.D_E_L_E_T_ = ' ' "  

	cQuery += " ) "	

	cQuery += " GROUP BY A1_NOME,E1_CLIENTE,E1_LOJA,SUBSTRING(SE1.E1_VENCREA,5,2) "
	cQuery += " ORDER BY A1_NOME,E1_CLIENTE,E1_LOJA,MES "

Endif

If lPEQry
	cQuery:= ExecBlock("FIN127QRY", .F.,.F., {cQuery,MV_PAR01,MV_PAR02,MV_PAR03,MV_PAR04,MV_PAR05,MV_PAR06})
EndIf

cQuery := ChangeQuery(cQuery)

dbUseArea( .T., "TOPCONN", TcGenQry(,,cQuery),cAlias , .T., .F. )

oSection1:Cell("DECLARACAO"):SetBlock( { || cTexto } )

DbSelectArea(cAlias)
(cAlias)->(dbGoTop())

If !lSimples
	oSection2:Cell("E1_CLIENTE"):SetBlock( { || (cAlias)->(E1_CLIENTE) } )
	oSection2:Cell("E1_LOJA"):SetBlock( { || (cAlias)->(E1_LOJA) } )
	oSection2:Cell("A1_NOME"):SetBlock( { || (cAlias)->(NOME) } )
	oSection2:Cell(STR0008):SetBlock( { || MesExtenso( Val((cAlias)->(MES))) } ) //"MสS"
	oSection2:Cell(STR0007):SetBlock( { || (cAlias)->(VALOR) } ) //"SALDO PAGO"
Endif

If lPETitulo
	cTitulo := ExecBlock("FIN127TIT", .F.,.F., {cTitulo})
EndIf	

oReport:SetTitle(cTitulo)

If lSimples

	While !(cAlias)->(eof())
		If (cAlias)->(SALDO) == 0
			cTexto 	:= STR0009+cEmpresa+STR0010+Alltrim((cAlias)->(NOME))+STR0011+cAno+STR0012+STR0013+cAno+STR0014
			//	cTexto 	:= "Em cumprimento เ Lei 12.007, de 29 de julho de 2009, o "+cEmpresa+" declara que o cliente "+Alltrim((cAlias)->(NOME))+" estแ quite quanto เs faturas com "+;
//			"vencimento no ano de "+cAno+". Esta declara็ใo substitui, para comprova็ใo do cumprimento das obriga็๕es do cliente, "+;
//			"as quita็๕es dos pagamentos mensais das faturas do ano de "+cAno+", bem como dos anos anteriores."
			If lPETexto
				cTexto := EXECBLOCK("FIN127TXT", .F., .F., {cTexto,(cAlias)->(NOME), cAno })
			Endif
			oSection1:Init()
			oSection1:Printline()
			oSection1:Finish()
			oReport:EndPage()
		Endif
		
		(cAlias)->(dbSkip())
	EndDo	                  

Else

	oSection1:Init()
	oSection2:Init()
	cCliLoj := (cAlias)->(E1_CLIENTE)+(cAlias)->(E1_LOJA)
	
	While !(cAlias)->(eof())
	
	If (cAlias)->(SALDO) == 0
		cTexto 	:= STR0009+cEmpresa+STR0010+Alltrim((cAlias)->(NOME))+STR0011+cAno+STR0012+STR0013+cAno+STR0014
//		cTexto 	:= "Em cumprimento เ Lei 12.007, de 29 de julho de 2009, o "+cEmpresa+" declara que o cliente "+Alltrim((cAlias)->(NOME))+" estแ quite quanto เs faturas com "+;
//						"vencimento no ano de "+cAno+". Esta declara็ใo substitui, para comprova็ใo do cumprimento das obriga็๕es do cliente, "+;
//						"as quita็๕es dos pagamentos mensais das faturas do ano de "+cAno+", bem como dos anos anteriores."

		If lPETexto
			cTexto := EXECBLOCK("FIN127TXT", .F., .F., {cTexto})
		Endif

	   If cCliLoj <> (cAlias)->(E1_CLIENTE)+(cAlias)->(E1_LOJA)
			oSection1:Finish()
			oSection2:Finish()
			oReport:EndPage()
			oSection1:Init()
			oSection2:Init()
			oSection1:Printline()
			oSection2:Printline()
			cCliLoj := (cAlias)->(E1_CLIENTE)+(cAlias)->(E1_LOJA)
			lModified := .T.
		Else
			If !lModified
				oSection1:Printline()
				lModified := .T.
			Endif
			oSection2:Printline()
		Endif
		
	Endif

	(cAlias)->(dbSkip())
	EndDo	 

Endif	                         

oSection1:Finish()
oSection2:Finish()

#ENDIF	

If Select(cAlias)>0
	(cAlias)->(DbClosearea())
Endif

Return NIL      


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณAjustaSX1 บAutor  ณCl๓vis Magenta      บ Data ณ  16/06/10   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ Ajusta pergunte caso o cliente nao tenha                   บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ AP                                                        บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/

Static Function AjustaSX1(cPerg)
Local aArea := GetArea()

dbSelectArea( "SX1" )
dbSetOrder( 1 )

// PutSx1(cGrupo,cOrdem,cPergunt,cPerSpa,cPerEng,cVar,;
//	cTipo ,nTamanho,nDecimal,nPresel,cGSC,cValid,;
//	cF3, cGrpSxg,cPyme,;
//	cVar01,cDef01,cDefSpa1,cDefEng1,cCnt01,;
//	cDef02,cDefSpa2,cDefEng2,;
//	cDef03,cDefSpa3,cDefEng3,;
//	cDef04,cDefSpa4,cDefEng4,;
//	cDef05,cDefSpa5,cDefEng5,;
//	aHelpPor,aHelpEng,aHelpSpa,cHelp)

If !dbSeek( cPerg )
	PutSx1(cPerg,"01","Cliente De?"   	,"Cliente De?"  	,"Cliente De?"		,"mv_ch1","C",TamSx3('E1_CLIENTE')[1]	,0,0,"G","","SA1"	,"",""	,"MV_PAR01")
	PutSx1(cPerg,"02","Cliente Ate?"   	,"Cliente Ate?"  	,"Cliente Ate?"	,"mv_ch2","C",TamSx3('E1_CLIENTE')[1]	,0,0,"G","","SA1"	,"",""	,"MV_PAR02")
	PutSx1(cPerg,"03","Loja De?"   		,"Loja De?"  		,"Loja De?"			,"mv_ch3","C",TamSx3('E1_LOJA')[1]	 	,0,0,"G","",""		,"",""	,"MV_PAR03")
   PutSx1(cPerg,"04","Loja Ate?"   		,"Loja Ate?"  		,"Loja Ate?"		,"mv_ch4","C",TamSx3('E1_LOJA')[1]	 	,0,0,"G","",""		,"",""	,"MV_PAR04")
   PutSx1(cPerg,"05","Ano Base?"   		,"Ano Base?"  		,"Ano Base?"		,"mv_ch5","C",4								,0,0,"G","",""		,"",""	,"MV_PAR05")
   PutSx1(cPerg,"06","Estilo"   			,"Estilo"  			,"Estilo"			,"mv_ch6","C",1								,0,1,"C","",""		,"",""	,"MV_PAR06","Simplificado","","","","Detalhado","","","")
Endif

RestArea( aArea )

Return Nil