#include "protheus.ch"
#INCLUDE "TOPCONN.CH"


/*
Situações já tratadas:
	-- ICMS
	Calcula ICM = [N] e Credita ICM [SIM] 
	Calcula ICM [NAO] e Livro Fiscal ICM != [N]

	Livro Fiscal ICM = [T] E Red base ICMS != 0
	Livro Fiscal ICM = [T] E Sit Trib ICMS $ [20|70]
	Livro Fiscal ICM $ [I|O] E Sit Trib ICMS $ [00|10]
	
	Sit Trib ICMS $ [20|70] E Red Base ICMS = [0] 
	Sit Trib ICMS = [0]
	Sit Trib ICMS # [00|10] E Livro Fiscal ICM == [T]  

	-- CST PIS diferente do CST COFINS
	CST PIS != CST COF
	CST PIS = ''
	CST COF = ''
		
	-- TNATREC para NF saída
	CSTCOF = [02] E TNATREC <> [4310]
	CSTCOF = [03] E TNATREC <> [4311]
	CSTCOF = [06] E TNATREC <> [4313]
	CSTCOF = [07] E TNATREC <> [4314]
	CSTCOF = [08] E TNATREC <> [4315]
	CSTCOF = [09] E TNATREC <> [4316]
	TNATREC = '' E CNATREC = ''
	
	-- PIS e COFINS Saida x CST PIS E CST COF
	PIS e COFINS != [Ambos] e CST PIS $ [01|02|03|06]
	PIS e COFINS != [Nao COnsidera] e CST PIS $ [07|08|09]
	PIS e COFINS != [Ambos] e CST COF $ [01|02|03|06]
	PIS e COFINS != [Nao COnsidera] e CST COF $ [07|08|09]
	
	-- Crédito PIS e COFINS x CST PIS E CST COF
	Crédito PIS e COFINS != [Debita] E CST PIS $ [01|02|03]
	Crédito PIS e COFINS != [Calcula] E CST PIS $ [06]
	Crédito PIS e COFINS != [Nao Calcula] E CST PIS $ [07|08|09]
	Crédito PIS e COFINS != [Debita] E CST COF $ [01|02|03]
	Crédito PIS e COFINS != [Calcula] E CST COF $ [06]
	Crédito PIS e COFINS != [Nao Calcula] E CST COF $ [07|08|09]	

	-- Cred PIS e COFINS Entrada x CST PIS
	Crédito PIS e COFINS != [Credita] E CST PIS $ [50]
	Crédito PIS e COFINS != [Nao Calcula] E CST PIS > [67] e < [98] E != [73]
	Crédito PIS e COFINS != [Calcula] E CST PIS > [73]	
	Crédito PIS e COFINS != [Credita] E CST COF $ [50]
	Crédito PIS e COFINS != [Nao Calcula] E CST COF > [67] e < [98] E != [73]
	Crédito PIS e COFINS != [Calcula] E CST COF > [73] 

	-- CST em NF saída, < 50
	Tipo = [Saída] E CST PIS >= [50]
	Tipo = [Saída] E CST COF >= [50]

	-- CST em NF Entrada, >= 50
	Tipo = [Entrada] E CST COF < [50]
*/


User Function AVALIATES()
Local oReport
If TRepInUse()
	oReport := ReportDef()
	oReport:PrintDialog()	
EndIf
Return

Static Function ReportDef()
Local oReport
Local oSecTES
 
oReport := TReport():New("AVALIATES","Avaliador de TES",, {|oReport| ReportPrint(oReport)},"Avaliador de TES")	
oReport:SetLandscape() 
oReport:SetTotalInLine(.F.)                                                                                               

oSecObrig := TRSection():New(oReport,"Obrig")
TRCell():New(oSecObrig, "TRB_TABELA",,"Tabela",,8)
TRCell():New(oSecObrig, "TRB_CAMPO",,"Campo",,20)
TRCell():New(oSecObrig, "TRB_STATUS",,"Status")


oSecTES := TRSection():New(oReport,"TES",{"TRB"})
TRCell():New(oSecTES,"TRB_TIPO"		,"TRB"    ,"Tipo",,8)
TRCell():New(oSecTES,"TRB_TES"			,"TRB"    ,"TES",,8)
TRCell():New(oSecTES,"TRB_CAMPO"		,"TRB"    ,"Campo Avaliado",,10)
TRCell():New(oSecTES,"TRB_NOMECAMP"	,"TRB"    ,"Titulo Campo",,20)
TRCell():New(oSecTES,"TRB_VLENCONT"	,"TRB"    ,"Valor Encontrado")
TRCell():New(oSecTES,"TRB_VLESPERA"	,"TRB"    ,"Valor Esperado  ")
TRCell():New(oSecTES,"TRB_DESCRIC"		,"TRB"    ,"Descricao",,120)


oBreak := TRBreak():New(oSecTES,oSecTES:Cell("TRB_TES"))

Return oReport


Static Function ReportPrint(oReport)  
Local vPIS := {}
Local vICMS := {}
Local oSecObrig := oReport:Section(1)
Local oSecTES := oReport:Section(2)
 
 

	VerifCad(oSecObrig)

	sQuery := " SELECT * " 
	sQuery += " FROM " +RetSqlName("SF4")+ " " 
	sQuery += " WHERE D_E_L_E_T_ = ' ' "
	
	TCQUERY SQuery Alias TRB New

	TRB->( dbGoTop() )
	oSecTES:Init()	
	While !EOF()
		//ICMS
		If TRB->( F4_CREDICM == 'S' .AND. F4_ICM = 'N' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_CREDICM",F4_CREDICM,"S","Credito de ICMS = SIM, mas Cálculo = NÃO") )
		Endif
		If TRB->( F4_ICM == 'N' .AND. F4_LFICM != 'N')
		  	TRB->( GeraCell(oSecTES,"ANALISAR",F4_CODIGO,"F4_ICM",F4_ICM,"S","Para considerar o Livro, Calcula ICMS deve ser [SIM]") )
		Endif
				
		/// REALMENTE PODE ACONTECER DE NÃO TER O CALCULO DE ICMS E SER PRECISO JOGAR EM OUTRAS, TROCADO DE ERRO PARA ANALISAR
	
		If TRB->( F4_ICM == 'N' .AND. F4_LFICM == 'T')
			TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_ICM",F4_ICM,"S","NAO CALCULA ICMS E LANÇA EM TRIBUTADAS") )
		Endif
		
				
		// INCLUIDOS RICARDO BATAGLIA
		
		// CIAP
		If TRB->( F4_ATUATF == 'S' .AND. F4_CIAP != 'S')
			TRB->( GeraCell(oSecTES,"ANALISAR",F4_CODIGO,"F4_ATUATF",F4_ATUATF,"S","ATUALIZA ATIVO E NAO CONTROLA CIAP") )
		Endif
		
		// FALTA DO CODBCC PARA TES QUE EFETUAM CREDITO DO IMPOSTO
		If TRB->( F4_PISCRED $ '1|4' .AND. F4_TIPO == 'E' .AND. EMPTY(F4_CODBCC))
			TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_CODBCC",F4_CODBCC," PREENCHIDO","TES DE ENTRADA COM CREDITO/CALCULO DO IMPOSTO SEM INFORMACAO DO TIPO DE CREDITO") )
		Endif
		
		If TRB->( F4_PISCRED $ '2|3' .AND. F4_TIPO $ 'E|S' .AND. !EMPTY(F4_CODBCC))
			TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_CODBCC",F4_CODBCC," NAO PREENCHER ","CODIGO BASE CREDITO PREENCHIDO INCORRETAMENTE") )
		Endif
		
	
				
		// LIVRO FISCAL -> ICMS
		If TRB->( F4_LFICM == 'T' .AND. F4_BASEICM != 0)
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_LFICM",F4_LFICM,"I ou O","Base reduzida, livro de ICMS deve ser Isento ou Outros") )		
		Endif
		If TRB->( F4_LFICM == 'T' .AND. F4_SITTRIB $ '20|70' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_LFICM",F4_LFICM,"I ou O","CST 20 ou 70,Base Reduzida,  livro de ICMS deve ser Isento ou Outros") )
		Endif
		If TRB->( F4_LFICM $ 'I|O' .AND. F4_SITTRIB $ '00|10' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_LFICM",F4_LFICM,"T","CST 00 ou 10, livro de ICMS deve ser Tributado") )
		Endif

		//SIT TRIB ICMS
		If TRB->( F4_SITTRIB $'20|70' .AND. F4_BASEICM == 0 )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_LFICM",F4_LFICM,"T","CST 20 ou 70,Base Reduzida, deve ter valor de reducao de base") )
		Endif
		If TRB->( F4_SITTRIB ='' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_SITTRIB",F4_SITTRIB,"Não Vazio","Sit Trib de ICMS não pode ser vazia") )
		Endif
		If TRB->( !(F4_SITTRIB $ '00|10') .AND. F4_LFICM == 'T' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_SITTRIB",F4_SITTRIB,"00 OU 10","Livro Tributado, Sit trib de ICMS deve ser 00 ou 10") )
		Endif

		// CST PIS diferente do CST COFINS		
		If TRB->( F4_CSTPIS != F4_CSTCOF )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_CSTPIS",F4_CSTPIS,F4_CSTCOF,"CST PIS != CST COFINS") )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_CSTCOF",F4_CSTCOF,F4_CSTPIS,"CST PIS != CST COFINS") )		  	
		Endif
		If TRB->( F4_CSTPIS == '' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_CSTPIS",F4_CSTPIS,"Não Vazio","CST PIS vazio") )		
		Endif		
		If TRB->( F4_CSTCOF == '' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_CSTCOF",F4_CSTCOF,"Não Vazio","CST COFINS vazio") )		
		Endif		
                                                                                                                                       
		//TNATREC para NF saída
		If TRB->( F4_CSTCOF=='02' .AND. F4_TNATREC != '4310' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_TNATREC",F4_TNATREC,"4310","Aliq Diferenciada de PIS e COFINS (CST 02) precisa que o campo seja preenchido com [4310]") )
		Endif		
		If TRB->( F4_CSTCOF=='03' .AND. F4_TNATREC != '4311' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_TNATREC",F4_TNATREC,"4311","Aliq Unid Medida de PIS e COFINS (CST 03) precisa que o campo seja preenchido com [4311]") )
		Endif
		If TRB->( F4_CSTCOF=='06' .AND. F4_TNATREC != '4313' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_TNATREC",F4_TNATREC,"4313","Aliq Zero de PIS e COFINS (CST 06) precisa que o campo seja preenchido com [4313]") )
		Endif
		If TRB->( F4_CSTCOF=='07' .AND. F4_TNATREC != '4314' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_TNATREC",F4_TNATREC,"4314","PIS e COFINS Isento (CST 07) precisa que o campo seja preenchido com [4314]") )
		Endif
		If TRB->( F4_CSTCOF=='08' .AND. F4_TNATREC != '4315' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_TNATREC",F4_TNATREC,"4315","PIS e COFINS Sem Incidencia (CST 08) precisa que o campo seja preenchido com [4315]") )
		Endif
		If TRB->( F4_CSTCOF=='09' .AND. F4_TNATREC != '4316' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_TNATREC",F4_TNATREC,"4316","PIS e COFINS em Suspensão (CST 09) precisa que o campo seja preenchido com [4316]") )
		Endif
		If TRB->(F4_TNATREC != '' .AND. F4_CNATREC = '' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_CNATREC",F4_CNATREC,"Nao Vazio","TNATREC preenchido, mas CNATREC em branco") )		
		Endif		 
		
		//PIS e COFINS Saida x CSTPIS
		If TRB->( F4_PISCOF != '3' .AND. F4_CSTPIS $'01|02|03|06' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_PISCOF",F4_PISCOF,"3 - Ambos","CST PIS 01,02,03 ou 06, PIS e COFINS deve ser [Ambos]") )		
		Endif		
		If TRB->( F4_PISCOF != '4' .AND. F4_CSTPIS $'07|08|09' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_PISCOF",F4_PISCOF,"4 - Nao Considera","CST PIS 07,08 ou 09, PIS/COFINS deve ser [Não Considera]") )		
		Endif		

	//Cred PIS COFINS Saida x CSTPIS
		If TRB->( F4_PISCRED != '2' .AND. F4_CSTPIS $'01|02|03' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_PISCRED",F4_PISCRED,"2 - Debita","CST PIS 01,02 ou 03, Cred PIS/COF deve ser [Debita]") )		
		Endif	
		If TRB->( F4_PISCRED != '3' .AND. F4_CSTPIS $'07|08|09' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_PISCRED",F4_PISCRED,"3 - Nao Calcula","CST PIS 07,08 ou 09 Cred PIS/COF deve ser [Nao Calcula]") )		
		Endif	
		If TRB->( F4_PISCRED != '4' .AND. F4_CSTPIS $'06' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_PISCRED",F4_PISCRED,"4 - Calcula","CST PIS 06,Cred PIS/COF deve ser [Calcula]") )		
		Endif	

		//PIS e COFINS Saida x CSTPIS
		If TRB->( F4_PISCOF != '3' .AND. F4_CSTCOF $'01|02|03|06' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_PISCOF",F4_PISCOF,"3 - Ambos","CST COF 01,02,03 ou 06, PIS e COFINS deve ser [Ambos]") )		
		Endif		
		If TRB->( F4_PISCOF != '4' .AND. F4_CSTCOF $'07|08|09' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_PISCOF",F4_PISCOF,"4 - Nao Considera","CST COF 07,08 ou 09, PIS/COFINS deve ser [Não Considera]") )		
		Endif		

		//Cred PIS COFINS Saida x CSTPIS
		If TRB->( F4_PISCRED != '2' .AND. F4_CSTCOF $'01|02|03' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_PISCRED",F4_PISCRED,"2 - Debita","CST COF 01,02 ou 03, Cred PIS/COF deve ser [Debita]") )		
		Endif	
		If TRB->( F4_PISCRED != '4' .AND. F4_CSTCOF $'06' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_PISCRED",F4_PISCRED,"4 - Calcula","CST COF 06, Cred PIS/COF deve ser [Calcula]") )		
		Endif	
		If TRB->( F4_PISCRED != '3' .AND. F4_CSTCOF $'07|08|09' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_PISCRED",F4_PISCRED,"3 - Nao Calcula","CST COF 07,08 ou 09, Cred PIS/COF deve ser [Nao Calcula]") )		
		Endif

	
		//Cred PIS e COFINS Entrada x CST PIS
		If TRB->( F4_PISCRED != '1' .AND. F4_CSTPIS $'50' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_PISCRED",F4_PISCRED,"1 - Credita","CST PIS 50, Cred PIS/COF deve ser [Credita]") )		
		Endif			
		If TRB->( F4_PISCRED != '3' .AND.( F4_CSTPIS >= '67' .AND. F4_CSTPIS <= '98') .AND. F4_CSTPIS != '73'  )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_PISCRED",F4_PISCRED,"3 - Nao Calcula","CST PIS de 67 a 98, exceto 73, Cred PIS/COF deve ser [Nao Calcula]") )		
		Endif			
		If TRB->( F4_PISCRED != '4' .AND. F4_CSTPIS $'73' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_PISCRED",F4_PISCRED,"4 - Calcula","CST PIS 73, Cred PIS/COF deve ser [Calcula]") )		
		Endif			

		//Cred PIS e COFINS Entrada x CST COFINS
		If TRB->( F4_PISCRED != '1' .AND. F4_CSTCOF $'50' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_PISCRED",F4_PISCRED,"1 - Credita","CST COF 50, Cred PIS/COF deve ser [Credita]") )		
		Endif			
		If TRB->( F4_PISCRED != '3' .AND.( F4_CSTCOF >= '67' .AND. F4_CSTCOF <= '98') .AND. F4_CSTCOF != '73'  )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_PISCRED",F4_PISCRED,"3 - Nao Calcula","CST COF de 67 a 98, exceto 73, Cred PIS/COF deve ser [Nao Calcula]") )		
		Endif			
		If TRB->( F4_PISCRED != '4' .AND. F4_CSTCOF $'73' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_PISCRED",F4_PISCRED,"4 - Calcula","CST COF 73, Cred PIS/COF deve ser [Calcula]") )		
		Endif		


		//CST em NF saída, < 50
		If TRB->( F4_TIPO == 'S' .AND. F4_CSTPIS >= '50' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_CSTPIS",F4_CSTPIS,"< 50","TES de Saída deve ter CST 01, 02, 03, 06, 07, 08 ou 09") )		
		Endif
		If TRB->( F4_TIPO == 'S' .AND. F4_CSTCOF >= '50' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_CSTCOF",F4_CSTCOF,"< 50","TES de Saída deve ter CST 01, 02, 03, 06, 07, 08 ou 09") )		
		Endif		

		//CST em NF Entrada, >= 50
		If TRB->( F4_TIPO == 'E' .AND. F4_CSTPIS < '50' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_CSTPIS",F4_CSTPIS,">= 50","TES de Entrada deve ter CST 50 ou 67 a 98") )		
		Endif		
		If TRB->( F4_TIPO == 'E' .AND. F4_CSTCOF < '50' )
		  	TRB->( GeraCell(oSecTES,"ERRO",F4_CODIGO,"F4_CSTCOF",F4_CSTCOF,">= 50","TES de Entrada deve ter CST 50 ou 67 a 98") )		
		Endif		
			

		TRB->( dbSkip() )
	End	
	oSecTES:finish()
	TRB->( dbCloseArea() )	
Return

Static Function VerifCad(oSession)
	oSecObrig := oSession
	oSecObrig:Init()

	GeraCellObrig(oSecObrig,"SF4","F4_SITTRIB")
	GeraCellObrig(oSecObrig,"SF4","F4_CTIPI")
	GeraCellObrig(oSecObrig,"SF4","F4_CSTPIS")
	GeraCellObrig(oSecObrig,"SF4","F4_CSTCOF")
	GeraCellObrig(oSecObrig,"SF4","F4_TPREG")
	GeraCellObrig(oSecObrig,"SB1","B1_DESC")
	GeraCellObrig(oSecObrig,"SB1","B1_POSIPI")	

	oSecObrig:Finish()
Return
	
Static Function GeraCellObrig(oSession,cTabela,cCampo)
// Comentado - Migração 12.1.23 - Tiago Quintana - 05/08/2019
//	SX3->( dbSetOrder(2) )
//	SX3->( dbGoTop() )

//Migração 12.1.23 - Tiago Quintana - 05/08/2019
Local xNomCpo 	:= Nil
Local xObrCpo	:= Nil
Local xResCpo 	:= Nil
 
xNomCpo := GETSX3CACHE(cCampo, "X3_CAMPO")
xResCpo := GETSX3CACHE(cCampo, "X3_RESERV")

	oSecObrig := oSession
	oSecObrig:Cell("TRB_TABELA"):SetValue(RetSqlName(cTabela))
	oSecObrig:Cell("TRB_CAMPO"):SetValue(cCampo)

// Comentado - Migração 12.1.23 - Tiago Quintana - 05/08/2019
/*	if 	SX3->( dbSeek(cCampo) )
		oSecObrig:Cell("TRB_STATUS"):SetValue(IIF(x3uso(SX3->X3_USADO) .and. ((SubStr(BIN2STR(SX3->X3_OBRIGAT),1,1)== "x") .or. VerByte(SX3->x3_reserv,7)),"T","F"))
	else
		oSecObrig:Cell("TRB_STATUS"):SetValue("NA")
	endif	
*/

	if 	!Empty(xNomCpo)
		oSecObrig:Cell("TRB_STATUS"):SetValue(IIF (X3Uso(xNomCpo) .and. ((X3Obrigat(xNomCpo)) .or. VerByte(xResCpo,7)),"T","F"))
	else
		oSecObrig:Cell("TRB_STATUS"):SetValue("NA")
	endif	

	oSecObrig:PrintLine()
Return

Static Function GeraCell(oSession,cTipo,cCodigo,cCampo,cVLEncont,cVlEspera,cDescric)
// Comentado - Migração 12.1.23 - Tiago Quintana - 05/08/2019
//	SX3->( dbSetOrder(2) )
//	SX3->( dbGoTop() )
	oSecTES:= oSession
	oSecTES:Cell("TRB_TIPO"):SetValue(cTipo)
	oSecTES:Cell("TRB_TES"):SetValue(cCodigo)	
	oSecTES:Cell("TRB_CAMPO"):SetValue(cCampo)
// Comentado - Migração 12.1.23 - Tiago Quintana - 05/08/2019
//	oSecTES:Cell("TRB_NOMECAMP"):SetValue( IIF(SX3->( dbSeek(cCampo) ),x3Titulo(),"") )
	oSecTES:Cell("TRB_NOMECAMP"):SetValue( IIF(!Empty(cCampo),FWX3Titulo(cCampo),"") )
	oSecTES:Cell("TRB_VLENCONT"):SetValue(cVLEncont)
	oSecTES:Cell("TRB_VLESPERA"):SetValue(cVlEspera)
	oSecTES:Cell("TRB_DESCRIC"):SetValue(cDescric)	
	oSecTES:PrintLine()
Return