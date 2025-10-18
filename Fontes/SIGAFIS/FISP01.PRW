#Include "Protheus.ch"
#Include "TopConn.ch"

User Function FISP01()

	If ValidPerg()

		// Configura a resposta para a pergunta 16
		// Devido a mudança de Pergunte do SX1 para Parambox
		If MV_PAR16 == "Completa"
			MV_PAR16 := 1
		ElseIf MV_PAR16 == "Resumo"
			MV_PAR16 := 2	
		Else
			MV_PAR16 := 3	
		Endif

		// Configura a resposta para a pergunta 17	
		// Devido a mudança de Pergunte do SX1 para Parambox
		If MV_PAR17 == "Entrada"
			MV_PAR17 := 1
		Else
			MV_PAR17 := 2	
		Endif

		// Configura a resposta para a pergunta 18
		// Devido a mudança de Pergunte do SX1 para Parambox
		If MV_PAR18 == "Fisica"
			MV_PAR18 := 1
		ElseIf MV_PAR18 == "Juridica"
			MV_PAR18 := 2	
		Else
			MV_PAR18 := 3	
		Endif
		
		Processa({||GeraPlanilha()})
	Else 
		Aviso("FISP01", "Processo cancelado pelo usuário")
		Return()
	Endif

Return

Static Function GeraPlanilha()


Local _aStru := {}
Local nHandle
Local cCrLf 	:= Chr(13) + Chr(10)
Local nJ

If MV_PAR16 <> 2
	
	aadd( _aStru , {"FILIAL"    , "C" , 15 , 00 } ) //FT_FILIAL
	aadd( _aStru , {"DTENTR"    , "C" , 10 , 00 } ) //FT_ENTRADA
	aadd( _aStru , {"DTEMIS"    , "C" , 10 , 00 } ) //FT_EMISSAO
	aadd( _aStru , {"DOCFISC"   , "C" , 15 , 00 } ) //FT_NFISCAL
	aadd( _aStru , {"SERIE"     , "C" , 15 , 00 } ) //FT_SERIE
	aadd( _aStru , {"FORCLI"    , "C" , 15 , 00 } ) //FT_CLIEFOR
	aadd( _aStru , {"LOJA"      , "C" , 15 , 00 } ) //FT_LOJA
	aadd( _aStru , {"ESTADO"    , "C" , 15 , 00 } ) //FT_ESTADO
	aadd( _aStru , {"TES"       , "C" , 15 , 00 } ) //FT_CFOP
	aadd( _aStru , {"CFOP"      , "C" , 15 , 00 } ) //FT_CFOP
	aadd( _aStru , {"CODPRO"    , "C" , 15 , 00 } ) //FT_PRODUTO
	aadd( _aStru , {"DESCRI"    , "C" , 40 , 00 } ) //B1_DESC
	aadd( _aStru , {"POSIPI"    , "C" , 15 , 00 } ) //FT_POSIPI
	aadd( _aStru , {"VALCONT"   , "C" , 20 , 00 } ) //FT_VALCONT
	aadd( _aStru , {"BASPIS"    , "C" , 20 , 00 } ) //FT_BASPIS
	aadd( _aStru , {"ALQPIS"    , "C" , 15 , 00 } ) //FT_ALIQPIS
	aadd( _aStru , {"VALPIS"    , "C" , 20 , 00 } ) //FT_VALPIS
	aadd( _aStru , {"SITPIS"    , "C" , 15 , 00 } ) //FT_CSTPIS
	aadd( _aStru , {"BASCOF"    , "C" , 20 , 00 } ) //FT_BASCOF
	aadd( _aStru , {"ALQCOF"    , "C" , 15 , 00 } ) //FT_ALIQCOF
	aadd( _aStru , {"VALCOF"    , "C" , 20 , 00 } ) //FT_VALCOF
	aadd( _aStru , {"SITCOF"    , "C" , 15 , 00 } ) //FT_CSTCOF
	aadd( _aStru , {"CODBCCR"   , "C" , 15 , 00 } ) //FT_CODBCC 
	aadd( _aStru , {"INDNATF"   , "C" , 15 , 00 } ) //FT_INDNTFR
	aadd( _aStru , {"TBNATRE"   , "C" , 15 , 00 } ) //FT_TNATREC
	aadd( _aStru , {"NATREC"    , "C" , 15 , 00 } ) //FT_CNATREC
	aadd( _aStru , {"GRPNATR"   , "C" , 15 , 00 } ) //FT_GRUPONC
	aadd( _aStru , {"CNPJ"      , "C" , 20 , 00 } ) //A1_CGC OU A2_CGC
	aadd( _aStru , {"PESSOA"    , "C" , 20 , 00 } ) //A1_PESSOA OU A2_TPESSOA
	
	// Criar arquivo temporário e gerar o cabeçalho
	_cTemp := CriaTrab(_aStru, .T.)
	//   Alert('1')
	DbUseArea(.T.,"DBFCDX",_cTemp,"TMP1",.F.,.F.)
	//   Alert('3')
   /*
	RecLock("TMP1",.T.)
	MsUnLock()
	RecLock("TMP1",.T.)
	MsUnLock()
	RecLock("TMP1",.T.)
	TMP1->DESCRI := "Planilha de verificação PIS e COFINS"
	MsUnLock()
	RecLock("TMP1",.T.)
	MsUnLock()
	RecLock("TMP1",.T.)
	MsUnLock()
	*/
	RecLock("TMP1",.T.)
   TMP1->FILIAL  := GetSx3Cache( "FT_FILIAL", "X3_TITULO" )
	TMP1->DTENTR  := GetSx3Cache( "FT_ENTRADA", "X3_TITULO" )
	TMP1->DTEMIS  := GetSx3Cache( "FT_EMISSAO", "X3_TITULO" )
	TMP1->DOCFISC := GetSx3Cache( "FT_NFISCAL", "X3_TITULO" )
	TMP1->SERIE   := GetSx3Cache( "FT_SERIE", "X3_TITULO" )
	TMP1->FORCLI  := GetSx3Cache( "FT_CLIEFOR", "X3_TITULO" )
	TMP1->LOJA    := GetSx3Cache( "FT_LOJA", "X3_TITULO" )
	TMP1->ESTADO  := GetSx3Cache( "FT_ESTADO", "X3_TITULO" )
	TMP1->TES     := GetSx3Cache( If(MV_PAR17=1,"D1_TES","D2_TES"), "X3_TITULO" )
	TMP1->CFOP    := GetSx3Cache( "FT_CFOP", "X3_TITULO" )
	TMP1->CODPRO  := GetSx3Cache( "FT_PRODUTO", "X3_TITULO" )
	TMP1->DESCRI  := GetSx3Cache( "B1_DESC", "X3_TITULO" )
	TMP1->POSIPI  := GetSx3Cache( "FT_POSIPI", "X3_TITULO" )
	TMP1->VALCONT := GetSx3Cache( "FT_VALCONT", "X3_TITULO" )
	TMP1->BASPIS  := GetSx3Cache( "FT_BASEPIS", "X3_TITULO" )
	TMP1->ALQPIS  := GetSx3Cache( "FT_ALIQPIS", "X3_TITULO" )
	TMP1->VALPIS  := GetSx3Cache( "FT_VALPIS", "X3_TITULO" )
	TMP1->SITPIS  := GetSx3Cache( "FT_CSTPIS", "X3_TITULO" )
	TMP1->BASCOF  := GetSx3Cache( "FT_BASECOF", "X3_TITULO" )
	TMP1->ALQCOF  := GetSx3Cache( "FT_ALIQCOF", "X3_TITULO" )
	TMP1->VALCOF  := GetSx3Cache( "FT_VALCOF", "X3_TITULO" )
	TMP1->SITCOF  := GetSx3Cache( "FT_CSTCOF", "X3_TITULO" )
	TMP1->CODBCCR := GetSx3Cache( "FT_CODBCC", "X3_TITULO" ) 
	TMP1->INDNATF := GetSx3Cache( "FT_INDNTFR", "X3_TITULO" )
	TMP1->TBNATRE := GetSx3Cache( "FT_TNATREC", "X3_TITULO" )
	TMP1->NATREC  := GetSx3Cache( "FT_CNATREC", "X3_TITULO" )
	TMP1->GRPNATR := GetSx3Cache( "FT_GRUPONC", "X3_TITULO" )                         
	TMP1->CNPJ    := GetSx3Cache( If(MV_PAR17=1,"A2_CGC","A1_CGC"), "X3_TITULO" )
	TMP1->PESSOA  := GetSx3Cache( If(MV_PAR17=1,"A2_TPESSOA","A1_PESSOA"), "X3_TITULO" )
EndIf

If MV_PAR16 < 3   

	_aStru := {}
	
	aadd( _aStru , {"FILIAL"    , "C" , 15 , 00 } ) //FT_FILIAL
	aadd( _aStru , {"SITPIS"    , "C" , 15 , 00 } ) //FT_ENTRADA
	aadd( _aStru , {"SITCOF"    , "C" , 15 , 00 } ) //FT_EMISSAO
	aadd( _aStru , {"CFOP"      , "C" , 15 , 00 } ) //FT_NFISCAL
	aadd( _aStru , {"DESCRI"    , "C" , 40 , 00 } ) //X5_DESCRI
	aadd( _aStru , {"VALCONT"   , "C" , 20 , 00 } ) //FT_VALCONT
	aadd( _aStru , {"BASPIS"    , "C" , 20 , 00 } ) //FT_BASPIS
	aadd( _aStru , {"VALPIS"    , "C" , 20 , 00 } ) //FT_VALPIS
	aadd( _aStru , {"BASCOF"    , "C" , 20 , 00 } ) //FT_BASCOF
	aadd( _aStru , {"VALCOF"    , "C" , 20 , 00 } ) //FT_VALCOF

	
	// Criar arquivo temporário e gerar o cabeçalho
	_cTemp2 := CriaTrab(_aStru, .T.)
	Use &_cTemp2 New Alias "TMP2" New Exclusive
	Index On FILIAL+SITPIS+SITCOF+CFOP To &_cTemp2

	RecLock("TMP2",.T.)
   TMP2->FILIAL  := GetSx3Cache( "FT_FILIAL", "X3_TITULO" )
	TMP2->SITPIS  := GetSx3Cache( "FT_CSTPIS", "X3_TITULO" )
	TMP2->SITCOF  := GetSx3Cache( "FT_CSTCOF", "X3_TITULO" )
	TMP2->CFOP    := GetSx3Cache( If(MV_PAR17=1,"D1_TES","D2_TES"), "X3_TITULO" )
	TMP2->DESCRI  := GetSx3Cache( "F4_TEXTO", "X3_TITULO" )
	TMP2->VALCONT := GetSx3Cache( "FT_VALCONT", "X3_TITULO" )
	TMP2->BASPIS  := GetSx3Cache( "FT_BASEPIS", "X3_TITULO" )
	TMP2->VALPIS  := GetSx3Cache( "FT_VALPIS", "X3_TITULO" )
	TMP2->BASCOF  := GetSx3Cache( "FT_BASECOF", "X3_TITULO" )
	TMP2->VALCOF  := GetSx3Cache( "FT_VALCOF", "X3_TITULO" )


	_aStru := {}
	
	aadd( _aStru , {"FILIAL"    , "C" , 15 , 00 } ) //FT_FILIAL
	aadd( _aStru , {"SITPIS"    , "C" , 15 , 00 } ) //FT_ENTRADA
	aadd( _aStru , {"SITCOF"    , "C" , 15 , 00 } ) //FT_EMISSAO
	aadd( _aStru , {"VALCONT"   , "C" , 20 , 00 } ) //FT_VALCONT
	aadd( _aStru , {"BASPIS"    , "C" , 20 , 00 } ) //FT_BASPIS
	aadd( _aStru , {"VALPIS"    , "C" , 20 , 00 } ) //FT_VALPIS
	aadd( _aStru , {"BASCOF"    , "C" , 20 , 00 } ) //FT_BASCOF
	aadd( _aStru , {"VALCOF"    , "C" , 20 , 00 } ) //FT_VALCOF

	
	// Criar arquivo temporário e gerar o cabeçalho
	_cTemp3 := CriaTrab(_aStru, .T.)
	Use &_cTemp3 New Alias "TMP3" New Exclusive
	Index On FILIAL+SITPIS+SITCOF To &_cTemp3

	RecLock("TMP3",.T.)
   TMP3->FILIAL  := GetSx3Cache( "FT_FILIAL", "X3_TITULO" )
	TMP3->SITPIS  := GetSx3Cache( "FT_CSTPIS", "X3_TITULO" )
	TMP3->SITCOF  := GetSx3Cache( "FT_CSTCOF", "X3_TITULO" )
	TMP3->VALCONT := GetSx3Cache( "FT_VALCONT", "X3_TITULO" )
	TMP3->BASPIS  := GetSx3Cache( "FT_BASEPIS", "X3_TITULO" )
	TMP3->VALPIS  := GetSx3Cache( "FT_VALPIS", "X3_TITULO" )
	TMP3->BASCOF  := GetSx3Cache( "FT_BASECOF", "X3_TITULO" )
	TMP3->VALCOF  := GetSx3Cache( "FT_VALCOF", "X3_TITULO" )


EndIf                                 

DbSelectArea("SA1")
DbSetOrder(1)

DbSelectArea("SA2")
DbSetOrder(1)

If MV_PAR17 = 1

	For nJ := 1 To 2 
	
		If nJ = 1
			cQuery := "select Count(FT_FILIAL) REGTOT "
		Else
			cQuery := "select D1_TIPO TIPO,FT_FILIAL,FT_ENTRADA,FT_EMISSAO,FT_NFISCAL,FT_SERIE,FT_CLIEFOR,FT_LOJA,FT_PRODUTO,FT_CSTPIS,FT_CSTCOF,FT_CFOP,FT_VALCONT,FT_ESTADO,FT_POSIPI"
			cQuery += ",FT_ALIQCOF,FT_ALIQPIS,FT_BASEPIS,FT_BASECOF,FT_VALPIS,FT_VALCOF,D1_TES TES,B1_DESC,X5_DESCRI,FT_CODBCC,FT_INDNTFR,FT_TNATREC,FT_CNATREC,FT_GRUPONC,FT_TIPOMOV "
		EndIf
		cQuery += "FROM " + RetSqlName("SD1") + " SD1, " + RetSqlName("SFT") + " SFT, " + RetSqlName("SB1") + " SB1, " + RetSqlName("SX5") + " SX5 "
		cQuery += "WHERE D1_FILIAL between '" + mv_par01 + "' and '" + mv_par02 + "' "
		cQuery += "AND D1_DTDIGIT between '" + dtos(mv_par03) + "' and '" + dtos(mv_par04) + "' " 
		cQuery += "AND D1_DOC between '" + mv_par05 + "' and '" + mv_par06 + "' "
		cQuery += "AND D1_SERIE between '" + mv_par07 + "' and '" + mv_par08 + "' "
		cQuery += "AND D1_COD between '" + mv_par09 + "' and '" + mv_par10 + "' "
		If !Empty(MV_PAR12)
			cQuery += "AND D1_TES = '" + MV_PAR12 + "' "
		EndIf 		
		If !Empty(MV_PAR13)
			cQuery += "AND D1_CF = '" + MV_PAR13 + "' "
		EndIf   
		cQuery += "AND D1_COD = B1_COD AND B1_FILIAL = '" + xFilial("SB1") + "' AND SB1.D_E_L_E_T_ = ' ' "	
		cQuery += "AND D1_CF = X5_CHAVE AND X5_FILIAL = '" + xFilial("SX5") + "' AND X5_TABELA = '13' AND SX5.D_E_L_E_T_ = ' ' "		
		cQuery += "AND D1_FILIAL = FT_FILIAL  "
		cQuery += "AND D1_DTDIGIT= FT_ENTRADA "
		cQuery += "AND D1_DOC    = FT_NFISCAL "
		cQuery += "AND D1_SERIE  = FT_SERIE "
		cQuery += "AND D1_FORNECE= FT_CLIEFOR "
		cQuery += "AND D1_LOJA   = FT_LOJA " 
		cQuery += "AND D1_ITEM   = FT_ITEM " 
		cQuery += "AND D1_COD    = FT_PRODUTO "
		cQuery += "AND FT_TIPOMOV = 'E' "       
		cQuery += "AND NOT FT_OBSERV  LIKE '%CANCELADA%'  "
		If !Empty(MV_PAR11)
			cQuery += "AND FT_POSIPI = '" + MV_PAR11 + "' "
		EndIf 		
		If !Empty(MV_PAR14)
			cQuery += "AND FT_CSTPIS = '" + MV_PAR14 + "' "
		EndIf 		
		If !Empty(MV_PAR15)
			cQuery += "AND FT_CSTCOF = '" + MV_PAR15 + "' "
		EndIf   		
		cQuery += "AND SFT.D_E_L_E_T_ = ' ' "
		cQuery += "AND SD1.D_E_L_E_T_ = ' ' "
		If nJ = 2
			cQuery += "ORDER BY FT_FILIAL,FT_CSTPIS,FT_CSTCOF,FT_CFOP,FT_ENTRADA,FT_SERIE,FT_NFISCAL "
		EndIf                                                             
		dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'QTMP', .F., .T.)
		If nJ = 1
			nRegtot := QTMP->REGTOT                
			QTMP->(DbCloseArea())
			ProcRegua(nRegTot)
		EndIf		
	Next nJ	  
	
Else

	For nJ := 1 To 2 
	
		If nJ = 1
			cQuery := "select Count(FT_FILIAL) REGTOT "
		Else
			cQuery := "select D2_TIPO TIPO,FT_FILIAL,FT_ENTRADA,FT_EMISSAO,FT_NFISCAL,FT_SERIE,FT_CLIEFOR,FT_LOJA,FT_PRODUTO,FT_POSIPI,FT_CSTPIS,FT_CSTCOF,FT_CFOP,FT_VALCONT,FT_ESTADO,FT_POSIPI"
			cQuery += ",FT_ALIQCOF,FT_ALIQPIS,FT_BASEPIS,FT_BASECOF,FT_VALPIS,FT_VALCOF,D2_TES TES,B1_DESC,X5_DESCRI,FT_CODBCC,FT_INDNTFR,FT_TNATREC,FT_CNATREC,FT_GRUPONC,FT_TIPOMOV "
		EndIf
		cQuery += "FROM " + RetSqlName("SD2") + " SD2, " + RetSqlName("SFT") + " SFT, " + RetSqlName("SB1") + " SB1, " + RetSqlName("SX5") + " SX5 "
		cQuery += "WHERE D2_FILIAL between '" + mv_par01 + "' and '" + mv_par02 + "' "
		cQuery += "AND D2_EMISSAO between '" + dtos(mv_par03) + "' and '" + dtos(mv_par04) + "' " 
		cQuery += "AND D2_DOC between '" + mv_par05 + "' and '" + mv_par06 + "' "
		cQuery += "AND D2_SERIE between '" + mv_par07 + "' and '" + mv_par08 + "' "
		cQuery += "AND D2_COD between '" + mv_par09 + "' and '" + mv_par10 + "' "
		If !Empty(MV_PAR12)
			cQuery += "AND D2_TES = '" + MV_PAR12 + "' "
		EndIf 		
		If !Empty(MV_PAR13)
			cQuery += "AND D2_CF = '" + MV_PAR13 + "' "
		EndIf   
		cQuery += "AND D2_COD = B1_COD AND B1_FILIAL = '" + xFilial("SB1") + "' AND SB1.D_E_L_E_T_ = ' ' "		
		cQuery += "AND D2_CF = X5_CHAVE AND X5_FILIAL = '" + xFilial("SX5") + "' AND X5_TABELA = '13' AND SX5.D_E_L_E_T_ = ' ' "		
		cQuery += "AND D2_FILIAL = FT_FILIAL  "
		cQuery += "AND D2_EMISSAO= FT_ENTRADA "
		cQuery += "AND D2_DOC    = FT_NFISCAL "
		cQuery += "AND D2_SERIE  = FT_SERIE "
		cQuery += "AND D2_CLIENTE= FT_CLIEFOR "
		cQuery += "AND D2_LOJA   = FT_LOJA " 
		cQuery += "AND D2_ITEM   = FT_ITEM " 
		cQuery += "AND D2_COD    = FT_PRODUTO "
		cQuery += "AND FT_TIPOMOV = 'S' "
		cQuery += "AND NOT FT_OBSERV  LIKE '%CANCELADA%' "
		If !Empty(MV_PAR11)
			cQuery += "AND FT_POSIPI = '" + MV_PAR11 + "' "
		EndIf 		
		If !Empty(MV_PAR14)
			cQuery += "AND FT_CSTPIS = '" + MV_PAR14 + "' "
		EndIf 		
		If !Empty(MV_PAR15)
			cQuery += "AND FT_CSTCOF = '" + MV_PAR15 + "' "
		EndIf   		
		cQuery += "AND SFT.D_E_L_E_T_ = ' ' "
		cQuery += "AND SD2.D_E_L_E_T_ = ' ' "
		If nJ = 2
			cQuery += "ORDER BY FT_FILIAL,FT_CSTPIS,FT_CSTCOF,FT_CFOP,FT_ENTRADA,FT_SERIE,FT_NFISCAL "
		EndIf                                                             
		dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), 'QTMP', .F., .T.)
		If nJ = 1
			nRegtot := QTMP->REGTOT                
			QTMP->(DbCloseArea())
			ProcRegua(nRegTot)
		EndIf		
	Next nJ	  
	
EndIf

nCont := 1

While QTMP->(!Eof())
	
	IncProc( "Processando..." + cValToChar(nCont) + "/" + cValTochar(nRegTot) )
		
	If MV_PAR16 <> 2         
		If (QTMP->FT_TIPOMOV == "E" .And. QTMP->TIPO $ "DB") .OR. (QTMP->FT_TIPOMOV == "S" .And. ! QTMP->TIPO $ "DB") 
		   SA1->( DbSeek( xFilial("SA1") + QTMP->FT_CLIEFOR + QTMP->FT_LOJA ) )
		   cCNPJ := Transform( SA1->A1_CGC, If( Len(Trim(SA1->A1_CGC)) < 14, "@R 999.999.999-99", "@R 99.999.999/9999-99" ) )
		   cPess := If( Len(Trim(SA1->A1_CGC)) < 14, "1 - PF", "2 - PJ" )
		Else
		   SA2->( DbSeek( xFilial("SA2") + QTMP->FT_CLIEFOR + QTMP->FT_LOJA ) )
		   cCNPJ := Transform( SA2->A2_CGC, If( Len(Trim(SA2->A2_CGC)) < 14, "@R 999.999.999-99", "@R 99.999.999/9999-99" ) )
		   cPess := If( Len(Trim(SA2->A2_CGC)) < 14, "1 - PF", "2 - PJ" )
		EndIf                                                       
		
		If MV_PAR18 = 3 .Or. Val(Left(cPess,1)) = MV_PAR18

			RecLock("TMP1",.T.)
		   TMP1->FILIAL  := "'"+QTMP->FT_FILIAL 
			TMP1->DTENTR  := DtoC(StoD(QTMP->FT_ENTRADA)) 
			TMP1->DTEMIS  := DtoC(Stod(QTMP->FT_EMISSAO)) 
			TMP1->DOCFISC := "'"+QTMP->FT_NFISCAL 
			TMP1->SERIE   := "'"+QTMP->FT_SERIE 
			TMP1->FORCLI  := "'"+QTMP->FT_CLIEFOR 
			TMP1->LOJA    := "'"+QTMP->FT_LOJA 
			TMP1->ESTADO  := "'"+QTMP->FT_ESTADO 
			TMP1->TES     := "'"+QTMP->TES 
			TMP1->CFOP    := "'"+QTMP->FT_CFOP 
			TMP1->CODPRO  := QTMP->FT_PRODUTO 
			TMP1->DESCRI  := QTMP->B1_DESC 
			TMP1->POSIPI  := QTMP->FT_POSIPI 
			TMP1->VALCONT := Transform(QTMP->FT_VALCONT, "@E 999999999999999.99" ) 
			TMP1->BASPIS  := Transform(QTMP->FT_BASEPIS, "@E 999999999999999.99" ) 
			TMP1->ALQPIS  := Transform(QTMP->FT_ALIQPIS, "@E 999.99" ) 
			TMP1->VALPIS  := Transform(QTMP->FT_VALPIS, "@E 999999999999999.99" ) 
			TMP1->SITPIS  := "'"+QTMP->FT_CSTPIS 
			TMP1->BASCOF  := Transform(QTMP->FT_BASECOF, "@E 999999999999999.99" ) 
			TMP1->ALQCOF  := Transform(QTMP->FT_ALIQCOF, "@E 999.99" ) 
			TMP1->VALCOF  := Transform(QTMP->FT_VALCOF, "@E 999999999999999.99" ) 
			TMP1->SITCOF  := "'"+QTMP->FT_CSTCOF 
			TMP1->CODBCCR := If(!Empty(QTMP->FT_CODBCC),"'","")+QTMP->FT_CODBCC  
			TMP1->INDNATF := If(!Empty(QTMP->FT_INDNTFR),"'","")+QTMP->FT_INDNTFR 
			TMP1->TBNATRE := If(!Empty(QTMP->FT_TNATREC),"'","")+QTMP->FT_TNATREC 
			TMP1->NATREC  := If(!Empty(QTMP->FT_CNATREC),"'","")+QTMP->FT_CNATREC 
			TMP1->GRPNATR := If(!Empty(QTMP->FT_GRUPONC),"'","")+QTMP->FT_GRUPONC 
			TMP1->CNPJ    := cCNPJ                                       
			tmp1->PESSOA  := cPess
			TMP1->(MsUnLock())
		EndIf
		If MV_PAR16 < 3
			If TMP2->( DBSEEK( "'" + PADR(QTMP->FT_FILIAL,14) + "'" + PADR(QTMP->FT_CSTPIS,14) + "'" + PADR(QTMP->FT_CSTCOF,14) + "'" + PADR(QTMP->FT_CFOP,14) ) )
			   RecLock( "TMP2", .F. )
				TMP2->VALCONT := Transform(Val(StrTran(TMP2->VALCONT,",","."))+QTMP->FT_VALCONT, "@E 999999999999999.99" )
				TMP2->BASPIS  := Transform(Val(StrTran(TMP2->BASPIS,",","."))+QTMP->FT_BASEPIS, "@E 999999999999999.99" )
				TMP2->VALPIS  := Transform(Val(StrTran(TMP2->VALPIS,",","."))+QTMP->FT_VALPIS, "@E 999999999999999.99" )
				TMP2->BASCOF  := Transform(Val(StrTran(TMP2->BASCOF,",","."))+QTMP->FT_BASECOF, "@E 999999999999999.99" )
				TMP2->VALCOF  := Transform(Val(StrTran(TMP2->VALCOF,",","."))+QTMP->FT_VALCOF, "@E 999999999999999.99" )
	         TMP2->(MsUnLock())
	      Else
				RecLock( "TMP2", .T. )
	         TMP2->FILIAL  := "'"+QTMP->FT_FILIAL                          
				TMP2->SITPIS  := "'"+QTMP->FT_CSTPIS                           
				TMP2->SITCOF  := "'"+QTMP->FT_CSTCOF
				TMP2->CFOP    := "'"+QTMP->FT_CFOP
				TMP2->DESCRI  := QTMP->X5_DESCRI                       
				TMP2->VALCONT := Transform(QTMP->FT_VALCONT, "@E 999999999999999.99" )
				TMP2->BASPIS  := Transform(QTMP->FT_BASEPIS, "@E 999999999999999.99" )
				TMP2->VALPIS  := Transform(QTMP->FT_VALPIS, "@E 999999999999999.99" )
				TMP2->BASCOF  := Transform(QTMP->FT_BASECOF, "@E 999999999999999.99" )
				TMP2->VALCOF  := Transform(QTMP->FT_VALCOF, "@E 999999999999999.99" )
				TMP2->(MsUnLock())
	      EndIf
			If TMP3->( DBSEEK( "'" + PADR(QTMP->FT_FILIAL,14) + "'" + PADR(QTMP->FT_CSTPIS,14) + "'" + PADR(QTMP->FT_CSTCOF,14) ) ) 
			   RecLock( "TMP3", .F. )                                                                                                
				TMP3->VALCONT := Transform(Val(StrTran(TMP3->VALCONT,",","."))+QTMP->FT_VALCONT, "@E 999999999999999.99" )
				TMP3->BASPIS  := Transform(Val(StrTran(TMP3->BASPIS,",","."))+QTMP->FT_BASEPIS, "@E 999999999999999.99" )
				TMP3->VALPIS  := Transform(Val(StrTran(TMP3->VALPIS,",","."))+QTMP->FT_VALPIS, "@E 999999999999999.99" )
				TMP3->BASCOF  := Transform(Val(StrTran(TMP3->BASCOF,",","."))+QTMP->FT_BASECOF, "@E 999999999999999.99" )
				TMP3->VALCOF  := Transform(Val(StrTran(TMP3->VALCOF,",","."))+QTMP->FT_VALCOF, "@E 999999999999999.99" )
	         TMP3->(MsUnLock())
	      Else
				RecLock( "TMP3", .T. )
	         TMP3->FILIAL  := "'"+QTMP->FT_FILIAL                          
				TMP3->SITPIS  := "'"+QTMP->FT_CSTPIS                           
				TMP3->SITCOF  := "'"+QTMP->FT_CSTCOF
				TMP3->VALCONT := Transform(QTMP->FT_VALCONT, "@E 999999999999999.99" )
				TMP3->BASPIS  := Transform(QTMP->FT_BASEPIS, "@E 999999999999999.99" )
				TMP3->VALPIS  := Transform(QTMP->FT_VALPIS, "@E 999999999999999.99" )
				TMP3->BASCOF  := Transform(QTMP->FT_BASECOF, "@E 999999999999999.99" )
				TMP3->VALCOF  := Transform(QTMP->FT_VALCOF, "@E 999999999999999.99" )
				TMP3->(MsUnLock())
	      EndIf
	   EndIf
   EndIf
   
   nCont++
	QTMP->(DbSkip())

End

QTMP->(DbCloseArea())

If  MV_PAR16 <> 2

	DbSelectArea("TMP1")
	nHandle := MsfCreate(Lower(_cTemp)+".csv",0)
		
	If nHandle > 0
		ProcRegua(0)
			
		IncProc("Aguarde! Gerando arquivo de integração com Excel...")
		TMP1->(DbGoTop())
		while !TMP1->(Eof())
			For nJ := 1 To TMP1->(Fcount())
			    fWrite(nHandle, TMP1->(FieldGet(nJ)) + ";" )  
			Next nJ
			fWrite(nHandle, cCrLf ) // Pula linha
			TMP1->(DbSkip())
		end
		
		IncProc("Aguarde! Abrindo o arquivo...")
		
		fClose(nHandle)
		cPath := Lower(AllTrim(GetTempPath()))
		__CopyFIle(Lower(_cTemp)+".csv", cPath+_ctemp+".csv")
		
		oExcelApp:= MsExcel():New()
		//oExcelApp:WorkBooks:Open(AllTrim(GetTempPath())+_ctemp+".dbf")
		oExcelApp:WorkBooks:Open(cPath+_ctemp+".csv")
		oExcelApp:SetVisible(.T.)
		TMP1->(DbCloseArea())
		Ferase(_cTemp+GetDbExtension())           
		
	endif
		
EndIf		
		
If  MV_PAR16 < 3

	DbSelectArea("TMP2")
	nHandle := MsfCreate(Lower(_cTemp2)+".csv",0)
		
	If nHandle > 0
		ProcRegua(0)
			
		IncProc("Aguarde! Gerando arquivo de integração com Excel...")
		//Imprime último registro com o cabeçalho das colunas
		TMP2->(DBGOBOTTOM())
		For nJ := 1 To TMP2->(Fcount())
			fWrite(nHandle, TMP2->(FieldGet(nJ)) + ";" )  
		Next nJ 
		fWrite(nHandle, cCrLf ) // Pula linha
		RecLock("TMP2",.F.)
		TMP2->(DbDelete()) 
		TMP2->(MsUnLock())
		
		TMP2->(DbGoTop())
		while !TMP2->(Eof())
			For nJ := 1 To TMP2->(Fcount())
			    fWrite(nHandle, TMP2->(FieldGet(nJ)) + ";" )  
			Next nJ
			fWrite(nHandle, cCrLf ) // Pula linha
			TMP2->(DbSkip())
		end
		
		IncProc("Aguarde! Abrindo o arquivo...")
		
		fClose(nHandle)
		cPath := Lower(AllTrim(GetTempPath()))
		__CopyFIle(Lower(_cTemp2)+".csv", cPath+_ctemp2+".csv")
		
		oExcelApp:= MsExcel():New()
		//oExcelApp:WorkBooks:Open(AllTrim(GetTempPath())+_ctemp+".dbf")
		oExcelApp:WorkBooks:Open(cPath+_ctemp2+".csv")
		oExcelApp:SetVisible(.T.)
		TMP2->(DbCloseArea())
		Ferase(_cTemp2+GetDbExtension())           
		
	endif



	DbSelectArea("TMP3")
	nHandle := MsfCreate(Lower(_cTemp3)+".csv",0)
		
	If nHandle > 0
		ProcRegua(0)
			
		IncProc("Aguarde! Gerando arquivo de integração com Excel...")
		//Imprime último registro com o cabeçalho das colunas
		TMP3->(DBGOBOTTOM())
		For nJ := 1 To TMP3->(Fcount())
			fWrite(nHandle, TMP3->(FieldGet(nJ)) + ";" )  
		Next nJ 
		fWrite(nHandle, cCrLf ) // Pula linha
		RecLock("TMP3",.F.)
		TMP3->(DbDelete()) 
		TMP3->(MsUnLock())
		
		TMP3->(DbGoTop())
		while !TMP3->(Eof())
			For nJ := 1 To TMP3->(Fcount())
			    fWrite(nHandle, TMP3->(FieldGet(nJ)) + ";" )  
			Next nJ
			fWrite(nHandle, cCrLf ) // Pula linha
			TMP3->(DbSkip())
		end
		
		IncProc("Aguarde! Abrindo o arquivo...")
		
		fClose(nHandle)
		cPath := Lower(AllTrim(GetTempPath()))
		__CopyFIle(Lower(_cTemp3)+".csv", cPath+_ctemp3+".csv")
		
		oExcelApp:= MsExcel():New()
		//oExcelApp:WorkBooks:Open(AllTrim(GetTempPath())+_ctemp+".dbf")
		oExcelApp:WorkBooks:Open(cPath+_ctemp3+".csv")
		oExcelApp:SetVisible(.T.)
		TMP3->(DbCloseArea())
		Ferase(_cTemp3+GetDbExtension())           
		
	endif
		
EndIf		
		
		
Return		
		
Static FuncTion ValidPerg(cPerg)

	Local cRet
	
	Private cLoad 		:= ""	                                		
	Private aParamBox	:= {}
	Private aRet		:= {}  
	Private nQtdTit		:= 0
	Private nTotal		:= 0
	Private lCanSave	:= .F.
	Private lUserSave 	:= .F.
	Private lCentered 	:= .T. 
    Private bVldParams	:= {|| VldParams() } 
	
	//Parametros da rotina
	aAdd(aParamBox, {1,"Filial De"         				,cFilant                           ,"","","","",Len(cFilant),.F.})                                 		// 01
	aAdd(aParamBox, {1,"Filial Ate"        				,cFilant                           ,"","","","",Len(cFilant),.T.})                                 		// 02
	aAdd(aParamBox, {1,"Emissao De"      				,CtoD("")                          ,"","","","",60,.T.})                                  				// 03
	aAdd(aParamBox, {1,"Emissao Ate"     				,CtoD("")                          ,"","","","",60,.T.})                                  				// 04
	aAdd(aParamBox, {1,"Nota De"          				,Space(Len(SF2->F2_DOC))           ,"","","","",Len(SF2->F2_DOC)+5,.F.})     				// 05
	aAdd(aParamBox, {1,"Nota Ate"         				,Replicate("z", Len(SF2->F2_DOC))  ,"","","","",Len(SF2->F2_DOC)+5,.T.})   		// 06
	aAdd(aParamBox, {1,"Serie De"         				,Space(Len(SF2->F2_SERIE))         ,"","","","",Len(SF2->F2_SERIE)+5,.F.})              	// 07
	aAdd(aParamBox, {1,"Serie Ate"        				,Replicate("z", Len(SF2->F2_SERIE)),"","","","",Len(SF2->F2_SERIE)+5,.T.})      // 08
	aAdd(aParamBox, {1,"Produto De"         			,Space(Len(SB1->B1_COD))           ,"","","","",Len(SB1->B1_COD)+45,.F.})               	// 09
	aAdd(aParamBox, {1,"Produto Ate"        			,Replicate("z", Len(SB1->B1_COD))  ,"","","","",Len(SB1->B1_COD) +45,.T.})     	// 10
	aAdd(aParamBox, {1,"NCM (Branco p/ Todos)"			,Space(Len(SYD->YD_TEC))           ,"","","SYD","",Len(SYD->YD_TEC)+100,.F.})     			// 11
	aAdd(aParamBox, {1,"TES (Branco p/ Todos)"			,Space(Len(SF4->F4_CODIGO))        ,"","","SF4","",Len(SF4->F4_CODIGO)+5,.F.}) 			// 12
	aAdd(aParamBox, {1,"CFOP (Branco p/ Todos)"			,Space(Len(SF4->F4_CF))            ,"","","","",Len(SF4->F4_CF)+5,.F.})     				// 13
	aAdd(aParamBox, {1,"CTS Pis (Branco p/ Todos)"		,Space(Len(SF4->F4_CSTPIS)),"","","","",Len(SF4->F4_CSTPIS)+5,.F.})				// 14
	aAdd(aParamBox, {1,"CTS Cofins (Branco p/ Todos)"   ,Space(Len(SF4->F4_CSTCOF)),"","","","",Len(SF4->F4_CSTCOF)+5,.F.})				// 15
	aAdd(aParamBox, {2,"Tipo de Impressao"				,"Completa",{"Completa","Resumo", "Detalhe"},100,"",.T.})						// 16
	aAdd(aParamBox, {2,"Tipo de Movimento"				,"Saida",{"Entrada","Saida"},100,"",.T.})										// 17
	aAdd(aParamBox, {2,"Tipo de Pessoa"					,"Ambas",{"Fisica","Juridica", "Ambas"},100,"",.T.})							// 18

    If ParamBox(aParambox, "FISP01 - Parâmetros", @aRet, /*bVldParams*/, , lCentered, , , , cLoad, lCanSave, lUserSave)	
		cRet := .T.
	Else
		cRet := .F.
	Endif

	/*
	PutSx1(cPerg, "01","Da Filial              :"," "," ","mv_ch1","C", 02,0,0,"G","", "SM0"      ,"","","mv_par01",""             , "", "", "", ""          , "", "", "", "", "", "", "", "", "", "", "", {}, {}, {} ) 
	PutSx1(cPerg, "02","Ate a Filial           :"," "," ","mv_ch2","C", 02,0,0,"G","", "SM0"      ,"","","mv_par02",""             , "", "", "", ""          , "", "", "", "", "", "", "", "", "", "", "", {}, {}, {} )
	PutSx1(cPerg, "03","Da Data                :"," "," ","mv_ch3","D", 08,0,0,"G","", ""      ,"","","mv_par03",""             , "", "", "", ""          , "", "", "", "", "", "", "", "", "", "", "", {}, {}, {} )
	PutSx1(cPerg, "04","Ate a Data             :"," "," ","mv_ch4","D", 08,0,0,"G","", ""      ,"","","mv_par04",""             , "", "", "", ""          , "", "", "", "", "", "", "", "", "", "", "", {}, {}, {} )
	PutSx1(cPerg, "05","Da Nota                :"," "," ","mv_ch5","C", 09,0,0,"G","", ""      ,"","","mv_par05",""             , "", "", "", ""          , "", "", "", "", "", "", "", "", "", "", "", {}, {}, {} )
	PutSx1(cPerg, "06","Ate Nota               :"," "," ","mv_ch6","C", 09,0,0,"G","", ""      ,"","","mv_par06",""             , "", "", "", ""          , "", "", "", "", "", "", "", "", "", "", "", {}, {}, {} )
	PutSx1(cPerg, "07","Da Serie               :"," "," ","mv_ch7","C", 03,0,0,"G","", ""      ,"","","mv_par07",""             , "", "", "", ""          , "", "", "", "", "", "", "", "", "", "", "", {}, {}, {} )
	PutSx1(cPerg, "08","Ate a Serie            :"," "," ","mv_ch8","C", 03,0,0,"G","", ""      ,"","","mv_par08",""             , "", "", "", ""          , "", "", "", "", "", "", "", "", "", "", "", {}, {}, {} )
	PutSx1(cPerg, "09","Do Produto             :"," "," ","mv_ch9","C", 15,0,0,"G","", "SB1"   ,"","","mv_par09",""             , "", "", "", ""          , "", "", "", "", "", "", "", "", "", "", "", {}, {}, {} )
	PutSx1(cPerg, "10","Ate Produto            :"," "," ","mv_cha","C", 15,0,0,"G","", "SB1"   ,"","","mv_par10",""             , "", "", "", ""          , "", "", "", "", "", "", "", "", "", "", "", {}, {}, {} )
	aHelpPor := {}
	AAdd( aHelpPor, "Para imprimir todos deixe em branco." )
	PutSx1(cPerg, "11","NCM                    :"," "," ","mv_chb","C", 10,0,0,"G","", "SYD"   ,"","","mv_par11",""             , "", "", "", ""          , "", "", "", "", "", "", "", "", "", "", "", aHelpPor,{},{} )
	PutSx1(cPerg, "12","TES                    :"," "," ","mv_chc","C", 03,0,0,"G","", "SF4"   ,"","","mv_par12",""             , "", "", "", ""          , "", "", "", "", "", "", "", "", "", "", "", aHelpPor,{},{} )
	AAdd( aHelpPor, "Preencha apenas com os 3 últimos digitos" )
	PutSx1(cPerg, "13","CFOP                   :"," "," ","mv_chd","C", 05,0,0,"G","", ""      ,"","","mv_par13",""             , "", "", "", ""          , "", "", "", "", "", "", "", "", "", "", "", aHelpPor,{},{} )
	aHelpPor := {}
	AAdd( aHelpPor, "Para imprimir todos deixe em branco." )
	PutSx1(cPerg, "14","CTS PIS                :"," "," ","mv_che","C", 02,0,0,"G","", ""      ,"","","mv_par14",""             , "", "", "", ""          , "", "", "", "", "", "", "", "", "", "", "", aHelpPor,{},{} )
	PutSx1(cPerg, "15","CTS COF                :"," "," ","mv_chf","C", 02,0,0,"G","", ""      ,"","","mv_par15",""             , "", "", "", ""          , "", "", "", "", "", "", "", "", "", "", "", aHelpPor,{},{} )
	aHelpPor := {}
	PutSx1(cPerg, "16","Tipo de Impressao      :"," "," ","mv_chg","N", 01,0,1,"C","",""       ,"","","mv_par16","Completa"     , "", "", "", "Resumos"    , "", "", "Detalhe"   , "", "", ""     , "", "", "", "", "",aHelpPor, aHelpEng, aHelpSpa )
	PutSx1(cPerg, "17","Qual o Tipo Movimento  :"," "," ","mv_chh","N", 01,0,1,"C","",""       ,"","","mv_par17","Entrada"      , "", "", "", "Saida"     , "", "", ""          , "", "", ""     , "", "", "", "", "",aHelpPor, aHelpEng, aHelpSpa )
	PutSx1(cPerg, "18","Tipo de Pessoa         :"," "," ","mv_chI","N", 01,0,1,"C","",""       ,"","","mv_par18","Fisica"       , "", "", "", "Juridica"  , "", "", "Ambas"     , "", "", ""     , "", "", "", "", "",aHelpPor, aHelpEng, aHelpSpa )
	*/
	
Return(cRet)

		