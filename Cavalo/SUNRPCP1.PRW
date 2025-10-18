#INCLUDE "TOPCONN.CH"
#INCLUDE 'PROTHEUS.CH'
/*
Inguz Solucoes
Setembro/2021
Relatorio de Analise de Empenhos
*/

User Function SUNRPCP1()

//If FindFunction("TRepInUse") .And. TRepInUse()
	oReport:= ReportDef()
	oReport:PrintDialog()
//EndIf                   

Return

Static Function ReportDef()            

Local aOrdem      			:= {""}
Local cTitle      			:= "APONTAMENTOS DE PRODUÇÃO"
Local oReport 
Local oSection1
Local cAliasCTB 			:= GetNextAlias()

Private cNUMFIL        		:= ''        
Private dDATA	            := dDataBase 
Private cPRODUTO       		:= ''
Private cDESCRICAO       	:= ''
Private nJANEIRO            := 0
Private nFEVEREIRO          := 0
Private nMARCO              := 0
Private nABRIL              := 0
Private nMAIO               := 0
Private nJUNHO              := 0
Private nJULHO              := 0
Private nAGOSTO             := 0
Private nSETEMBRO           := 0
Private nOUTUBRO            := 0
Private nNOVEMBRO           := 0
Private nDEZEMBRO           := 0
Private nCONSPER            := 0
Private nCONSMED            := 0
Private cPerg				:= 'SUNRPCP1'
Private aImp                := {}


AjustaSX1()
Pergunte("SUNRPCP1",.F.)


oReport:= TReport():New("SUNRPCP1",cTitle,"SUNRPCP1", {|oReport| ReportPrint(oReport,aOrdem,cAliasCTB)},"Apontamentos de Produção") 
oReport:SetLandscape() 

oSection1:= TRSection():New(oReport,"Apontamentos de Produção",{"SB1","SB2","SC2","SD4"},aOrdem) 

oSection1:SetHeaderPage()

TRCell():New(oSection1,"cNUMFIL"  ,"   "	,"FILIAL            	"  	,'@!'	                    ,02	                            ,,,,,"LEFT")
TRCell():New(oSection1,"cPRODUTO","   "		,"PRODUTO           	"  	,PesqPict("SB1","B1_COD"	)	,TamSx3("B1_COD")		[1]	,,,,,"LEFT")
TRCell():New(oSection1,"CDESCRICAO","   "	,"DESCRIÇÃO         	"  	,PesqPict("SB1","B1_DESC")	    ,TamSx3("B1_DESC")	    [1]	,,,,,"LEFT")
TRCell():New(oSection1,"nJANEIRO"  ,"   "	,"JANEIRO         	    "  	,PesqPict("SD4","D4_QTDEORI")	,TamSx3("D4_QTDEORI")	[1]	,,,,,"LEFT")
TRCell():New(oSection1,"nFEVEREIRO","   "	,"FEVEREIRO         	"  	,PesqPict("SD4","D4_QTDEORI")	,TamSx3("D4_QTDEORI")	[1]	,,,,,"LEFT")
TRCell():New(oSection1,"nMARCO"    ,"   "	,"MARÇO         	    "  	,PesqPict("SD4","D4_QTDEORI")	,TamSx3("D4_QTDEORI")	[1]	,,,,,"LEFT")
TRCell():New(oSection1,"nABRIL"   ,"   "	,"ABRIL         	    "  	,PesqPict("SD4","D4_QTDEORI")	,TamSx3("D4_QTDEORI")	[1]	,,,,,"LEFT")
TRCell():New(oSection1,"nMAIO"    ,"   "	,"MAIO          	    "  	,PesqPict("SD4","D4_QTDEORI")	,TamSx3("D4_QTDEORI")	[1]	,,,,,"LEFT")
TRCell():New(oSection1,"nJUNHO"   ,"   "	,"JUNHO         	    "  	,PesqPict("SD4","D4_QTDEORI")	,TamSx3("D4_QTDEORI")	[1]	,,,,,"LEFT")
TRCell():New(oSection1,"nJULHO"   ,"   "	,"JULHO         	    "  	,PesqPict("SD4","D4_QTDEORI")	,TamSx3("D4_QTDEORI")	[1]	,,,,,"LEFT")
TRCell():New(oSection1,"nAGOSTO"  ,"   "	,"AGOSTO         	    "  	,PesqPict("SD4","D4_QTDEORI")	,TamSx3("D4_QTDEORI")	[1]	,,,,,"LEFT")
TRCell():New(oSection1,"nSETEMBRO","   "	,"SETEMBRO         	    "  	,PesqPict("SD4","D4_QTDEORI")	,TamSx3("D4_QTDEORI")	[1]	,,,,,"LEFT")
TRCell():New(oSection1,"nOUTUBRO"  ,"   "	,"OUTUBRO         	    "  	,PesqPict("SD4","D4_QTDEORI")	,TamSx3("D4_QTDEORI")	[1]	,,,,,"LEFT")
TRCell():New(oSection1,"nNOVEMBRO" ,"   "	,"NOVEMBRO         	    "  	,PesqPict("SD4","D4_QTDEORI")	,TamSx3("D4_QTDEORI")	[1]	,,,,,"LEFT")
TRCell():New(oSection1,"nDEZEMBRO" ,"   "	,"DEZEMBRO         	    "  	,PesqPict("SD4","D4_QTDEORI")	,TamSx3("D4_QTDEORI")	[1]	,,,,,"LEFT")
TRCell():New(oSection1,"nCONSPER"  ,"   "	,"CONSUMO DO PERÍODO    "  	,PesqPict("SD4","D4_QTDEORI")	,TamSx3("D4_QTDEORI")	[1]	,,,,,"LEFT")
TRCell():New(oSection1,"nCONSMED"  ,"   "	,"CONSUMO MÉDIO         "  	,PesqPict("SD4","D4_QTDEORI")	,TamSx3("D4_QTDEORI")	[1]	,,,,,"LEFT")

Return(oReport)

Static Function ReportPrint(oReport,aOrdem,cAliasCTB)

Local oSection1  := oReport:Section(1) 
Local lPrinted   := .F.
//Local lFiltra	 := .t.
Local nTotMes    := fRetMes()

Private aMeses   := {}

oReport:SetTitle(oReport:Title()  )

cQuery := " SELECT * FROM " + RETSQLNAME("SD4") + "  SD4 "
cQuery += " INNER JOIN " + RETSQLNAME("SB1") + " SB1 ON SB1.B1_COD = SD4.D4_COD AND SB1.D_E_L_E_T_ = '' " /*AND SB1.B1_FILIAL = SD4.D4_FILIAL -- Suntech Ricardo */
cQuery += " WHERE SD4.D_E_L_E_T_ = '' " 
cQuery += " AND SD4.D4_DATA >= '" + DTOS(MV_PAR03) + "' AND SD4.D4_DATA <= '" + DTOS(MV_PAR04) + "'  "
cQuery += " AND SD4.D4_COD >= '"  + MV_PAR01       + "' AND SD4.D4_COD <= '"  + MV_PAR02 + "' "
//cQuery += " AND SD4.D4_LOCAL = '99' "
cQuery += " ORDER BY SD4.D4_FILIAL,SD4.D4_COD,SD4.D4_DATA  " 

tcQuery cQuery New Alias "TARQ"

TARQ->(dbGoTop())
While TARQ->(!Eof())

    nMes := 0
    nPos := 0 
    If Substr(TARQ->D4_DATA,5,2) == '01' 
        nMes := 1
    ElseIf Substr(TARQ->D4_DATA,5,2) == '02' 
        nMes := 2
    ElseIf Substr(TARQ->D4_DATA,5,2) == '03' 
        nMes := 3
    ElseIf Substr(TARQ->D4_DATA,5,2) == '04' 
        nMes := 4
    ElseIf Substr(TARQ->D4_DATA,5,2) == '05' 
        nMes := 5
    ElseIf Substr(TARQ->D4_DATA,5,2) == '06' 
        nMes := 6
    ElseIf Substr(TARQ->D4_DATA,5,2) == '07' 
        nMes := 7
    ElseIf Substr(TARQ->D4_DATA,5,2) == '08' 
        nMes := 8
    ElseIf Substr(TARQ->D4_DATA,5,2) == '09' 
        nMes := 9
    ElseIf Substr(TARQ->D4_DATA,5,2) == '10' 
        nMes := 10
    ElseIf Substr(TARQ->D4_DATA,5,2) == '11' 
        nMes := 11
    ElseIf Substr(TARQ->D4_DATA,5,2) == '12' 
        nMes := 12
    Endif                                                                

    nPos := Ascan(aMeses, {|x|x[1]+x[2] == TARQ->D4_FILIAL+TARQ->D4_COD })
    If nPos == 0

        If Substr(TARQ->D4_DATA,5,2) == '01' 
            Aadd(aMeses,{ TARQ->D4_FILIAL,TARQ->D4_COD , TARQ->B1_DESC,TARQ->D4_QTDEORI,0,0,0,0,0,0,0,0,0,0,0,TARQ->D4_QTDEORI,0 })
        ElseIf Substr(TARQ->D4_DATA,5,2) == '02' 
            Aadd(aMeses,{ TARQ->D4_FILIAL,TARQ->D4_COD , TARQ->B1_DESC,0,TARQ->D4_QTDEORI,0,0,0,0,0,0,0,0,0,0,TARQ->D4_QTDEORI,0 })
        ElseIf Substr(TARQ->D4_DATA,5,2) == '03' 
            Aadd(aMeses,{ TARQ->D4_FILIAL,TARQ->D4_COD , TARQ->B1_DESC,0,0,TARQ->D4_QTDEORI,0,0,0,0,0,0,0,0,0,TARQ->D4_QTDEORI,0 })
        ElseIf Substr(TARQ->D4_DATA,5,2) == '04' 
            Aadd(aMeses,{ TARQ->D4_FILIAL,TARQ->D4_COD , TARQ->B1_DESC,0,0,0,TARQ->D4_QTDEORI,0,0,0,0,0,0,0,0,TARQ->D4_QTDEORI,0 })
        ElseIf Substr(TARQ->D4_DATA,5,2) == '05' 
            Aadd(aMeses,{ TARQ->D4_FILIAL,TARQ->D4_COD , TARQ->B1_DESC,0,0,0,0,TARQ->D4_QTDEORI,0,0,0,0,0,0,0,TARQ->D4_QTDEORI,0 })
        ElseIf Substr(TARQ->D4_DATA,5,2) == '06' 
            Aadd(aMeses,{ TARQ->D4_FILIAL,TARQ->D4_COD , TARQ->B1_DESC,0,0,0,0,0,TARQ->D4_QTDEORI,0,0,0,0,0,0,TARQ->D4_QTDEORI,0 })
        ElseIf Substr(TARQ->D4_DATA,5,2) == '07' 
            Aadd(aMeses,{ TARQ->D4_FILIAL,TARQ->D4_COD , TARQ->B1_DESC,0,0,0,0,0,0,TARQ->D4_QTDEORI,0,0,0,0,0,TARQ->D4_QTDEORI,0 })
        ElseIf Substr(TARQ->D4_DATA,5,2) == '08' 
            Aadd(aMeses,{ TARQ->D4_FILIAL,TARQ->D4_COD , TARQ->B1_DESC,0,0,0,0,0,0,0,TARQ->D4_QTDEORI,0,0,0,0,TARQ->D4_QTDEORI,0 })
        ElseIf Substr(TARQ->D4_DATA,5,2) == '09' 
            Aadd(aMeses,{ TARQ->D4_FILIAL,TARQ->D4_COD , TARQ->B1_DESC,0,0,0,0,0,0,0,0,TARQ->D4_QTDEORI,0,0,0,TARQ->D4_QTDEORI,0 })
        ElseIf Substr(TARQ->D4_DATA,5,2) == '10' 
            Aadd(aMeses,{ TARQ->D4_FILIAL,TARQ->D4_COD , TARQ->B1_DESC,0,0,0,0,0,0,0,0,0,TARQ->D4_QTDEORI,0,0,TARQ->D4_QTDEORI,0 })
        ElseIf Substr(TARQ->D4_DATA,5,2) == '11' 
            Aadd(aMeses,{ TARQ->D4_FILIAL,TARQ->D4_COD , TARQ->B1_DESC,0,0,0,0,0,0,0,0,0,0,TARQ->D4_QTDEORI,0,TARQ->D4_QTDEORI,0 })
        ElseIf Substr(TARQ->D4_DATA,5,2) == '12' 
            Aadd(aMeses,{ TARQ->D4_FILIAL,TARQ->D4_COD , TARQ->B1_DESC,0,0,0,0,0,0,0,0,0,0,0,TARQ->D4_QTDEORI,TARQ->D4_QTDEORI,0 })
        Endif

    Else
        If nMes == 1
            aMeses[nPos,04] += TARQ->D4_QTDEORI
            aMeses[nPos,16] += TARQ->D4_QTDEORI
        ElseIf nMes == 2
            aMeses[nPos,05] += TARQ->D4_QTDEORI
            aMeses[nPos,16] += TARQ->D4_QTDEORI
        ElseIf nMes == 3
            aMeses[nPos,06] += TARQ->D4_QTDEORI
            aMeses[nPos,16] += TARQ->D4_QTDEORI
        ElseIf nMes == 4
            aMeses[nPos,07] += TARQ->D4_QTDEORI
            aMeses[nPos,16] += TARQ->D4_QTDEORI
        ElseIf nMes == 5
            aMeses[nPos,08] += TARQ->D4_QTDEORI
            aMeses[nPos,16] += TARQ->D4_QTDEORI
        ElseIf nMes == 6
            aMeses[nPos,09] += TARQ->D4_QTDEORI
            aMeses[nPos,16] += TARQ->D4_QTDEORI
        ElseIf nMes == 7
            aMeses[nPos,10] += TARQ->D4_QTDEORI
            aMeses[nPos,16] += TARQ->D4_QTDEORI
        ElseIf nMes == 8
            aMeses[nPos,11] += TARQ->D4_QTDEORI
            aMeses[nPos,16] += TARQ->D4_QTDEORI
        ElseIf nMes == 9
            aMeses[nPos,12] += TARQ->D4_QTDEORI
            aMeses[nPos,16] += TARQ->D4_QTDEORI
        ElseIf nMes == 10
            aMeses[nPos,13] += TARQ->D4_QTDEORI
            aMeses[nPos,16] += TARQ->D4_QTDEORI
        ElseIf nMes == 11
            aMeses[nPos,14] += TARQ->D4_QTDEORI
            aMeses[nPos,16] += TARQ->D4_QTDEORI
        ElseIf nMes == 12
            aMeses[nPos,15] += TARQ->D4_QTDEORI
            aMeses[nPos,16] += TARQ->D4_QTDEORI
        EndIf                                                                                                                        
    EndIf

    TARQ->(dbSkip())
EndDo
TARQ->(dbGoTop())

oReport:SetMeter(TARQ->(LastRec()))

If Len(aMeses) > 0

    For n1 := 1 to Len(aMeses)
            
        If lPrinted
		    oSection1:Finish()
		    lPrinted := .F.
	    Endif
		
	    oReport:IncMeter()
	    If oReport:Cancel()
		    Exit
	    EndIf                                          

        aMeses[n1,17] := aMeses[n1,16] / nTotMes
	    
        oSection1:Init()
         
    	oSection1:Cell("cNUMFIL"):SetValue(aMeses[n1,01])
	    oSection1:Cell("CPRODUTO"):SetValue(aMeses[n1,02])
        oSection1:Cell("CDESCRICAO"):SetValue(aMeses[n1,03])
        oSection1:Cell("nJANEIRO"):SetValue(aMeses[n1,04])
        oSection1:Cell("nFEVEREIRO"):SetValue(aMeses[n1,05])
        oSection1:Cell("nMARCO"):SetValue(aMeses[n1,06])
        oSection1:Cell("nABRIL"):SetValue(aMeses[n1,07])
        oSection1:Cell("nMAIO"):SetValue(aMeses[n1,08])
        oSection1:Cell("nJUNHO"):SetValue(aMeses[n1,09])
        oSection1:Cell("nJULHO"):SetValue(aMeses[n1,10])
        oSection1:Cell("nAGOSTO"):SetValue(aMeses[n1,11])
        oSection1:Cell("nSETEMBRO"):SetValue(aMeses[n1,12])
        oSection1:Cell("nOUTUBRO"):SetValue(aMeses[n1,13])
        oSection1:Cell("nNOVEMBRO"):SetValue(aMeses[n1,14])
        oSection1:Cell("nDEZEMBRO"):SetValue(aMeses[n1,15])
        oSection1:Cell("nCONSPER"):SetValue(aMeses[n1,16])
        oSection1:Cell("nCONSMED"):SetValue(aMeses[n1,17])

    	oSection1:PrintLine()		

    Next /*Corrigido o loop FOR*/

EndIf

TARQ->(dbCloseArea())

oSection1:Finish()

Return Nil


Static Function AjustaSX1()

Local _sAlias := Alias()
Local aRegs := {}
Local i,j

dbSelectArea("SX1")
dbSetOrder(1)
cPerg := PADR(cPerg,10)

aAdd(aRegs,{cPerg,"01","Produto de  ?  "  ,"Produto de ?  "  ,"Produto de  ?  " ,"mv_ch1","C",15,0,0,"G",""        			,"mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SB1"})
aAdd(aRegs,{cPerg,"02","Produto até ?	" ,"Produto até ? "  ,"Produto até ?  " ,"mv_ch2","C",15,0,0,"G",""        			,"mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","SB1"})
aAdd(aRegs,{cPerg,"03","Data de     ?	" ,"Data de ? "      ,"Data de ?  "     ,"mv_ch3","D",08,0,0,"G",""        			,"mv_par03","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"04","Data até     ?	" ,"Data até ? "      ,"Data até ?  "   ,"mv_ch4","D",08,0,0,"G",""        			,"mv_par04","","","","","","","","","","","","","","","","","","","","","","","","",""})

For i:=1 to Len(aRegs)
	If !dbSeek(cPerg+aRegs[i,2])
		RecLock("SX1",.T.)
		For j:=1 to FCount()
			If j <= Len(aRegs[i])
				FieldPut(j,aRegs[i,j])
			Endif
		Next
		MsUnlock()
	Endif
Next
dbSelectArea(_sAlias)
Return()

// Funcao para retornar numero de meses informados no periodo 
Static Function fRetMes()
Local nRet  := 0
Local cQuery:= ''

cQuery := " SELECT DISTINCT MONTH(D4_DATA) AS MES FROM " + RETSQLNAME("SD4") + "  SD4 "
cQuery += " INNER JOIN " + RETSQLNAME("SB1") + " SB1 ON SB1.B1_COD = SD4.D4_COD AND SB1.D_E_L_E_T_ = '' " /*SB1.B1_FILIAL = SD4.D4_FILIAL AND -- Ricardo */
cQuery += " WHERE SD4.D_E_L_E_T_ = '' " 
cQuery += " AND SD4.D4_DATA >= '" + DTOS(MV_PAR03) + "' AND SD4.D4_DATA <= '" + DTOS(MV_PAR04) + "'  "
cQuery += " AND SD4.D4_COD >= '"  + MV_PAR01       + "' AND SD4.D4_COD <= '"  + MV_PAR02 + "' "
//cQuery += " AND SD4.D4_LOCAL = '99' "

tcQuery cQuery New AliaS "TXX1"

Count to nRet 

TXX1->(dbCloseArea())

Return(nRet)
