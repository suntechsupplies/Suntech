#include 'protheus.ch'
#include 'parmtype.ch'

User Function TESTE()

	oExcel := FwMsExcelXlsx():New()

	lRet := oExcel:IsWorkSheet("WorkSheet1")
	oExcel:AddworkSheet("WorkSheet1")

	lRet := oExcel:IsWorkSheet("WorkSheet1")
	oExcel:AddTable ("WorkSheet1","Table1")
	oExcel:AddColumn("WorkSheet1","Table1","Col1",1,1,.F., "999.9")
	oExcel:AddColumn("WorkSheet1","Table1","Col2",2,2,.F., "999.99")
	oExcel:AddColumn("WorkSheet1","Table1","Col3",3,3,.F., "999.999")
	oExcel:AddColumn("WorkSheet1","Table1","Col4",1,1,.T., "999.9999")
	oExcel:AddColumn("WorkSheet1","Table1","Col5",1,1,.T., "999.99999")
	oExcel:AddColumn("WorkSheet1","Table1","Col6",1,1,.T., "999")

	oExcel:AddRow("WorkSheet1","Table1",{11.1,12.11,13.111,14.1111, 14.12345, 12.35})
	oExcel:AddRow("WorkSheet1","Table1",{21,22,23,24})
	oExcel:AddRow("WorkSheet1","Table1",{31,32,33,34})
	oExcel:AddRow("WorkSheet1","Table1",{41,42,43,44})

	oExcel:SetFont("arial")
	oExcel:SetFontSize(20)
	oExcel:SetItalic(.T.)
	oExcel:SetBold(.T.)
	oExcel:SetUnderline(.T.)

	oExcel:AddworkSheet("WorkSheet2")
	oExcel:AddTable("WorkSheet2","Table1")
	oExcel:AddColumn("WorkSheet2","Table1","Col1",1, 1)
	oExcel:AddColumn("WorkSheet2","Table1","Col2",2, 2)
	oExcel:AddColumn("WorkSheet2","Table1","Col3",3, 3)
	oExcel:AddColumn("WorkSheet2","Table1","Col4",1, 4)
	oExcel:AddColumn("WorkSheet2","Table1","Col5",1)

	oExcel:AddRow("WorkSheet2","Table1",{"11",12,13,stod("20121212"), .F.})
	oExcel:AddRow("WorkSheet2","Table1",{"21",22,23,stod("20121212"), .T.})
	oExcel:AddRow("WorkSheet2","Table1",{"31",32,33,stod("20121212"), .F.})
	oExcel:AddRow("WorkSheet2","Table1",{"41",42,43,stod("20121212"), .T.})
	oExcel:AddRow("WorkSheet2","Table1",{"51",52,53,stod("20121212"), .F.})

	oExcel:Activate()

	oExcel:GetXMLFile("TESTE.xlsx")

	oExcel:DeActivate()

Return
