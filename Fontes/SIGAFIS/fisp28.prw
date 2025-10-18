#Include "Protheus.ch"
#Include "TopConn.ch"

User Function FISP28()

	Local   cPerg := "FISP28    "

	ValidPerg(cPerg)
	If Pergunte(cPerg,.T.)
		Processa({||AjustaLivros()})
		MsgInfo("Correção Finalizada","Livros Fiscais")
	EndIf

Return

Static Function AjustaLivros()

	If MV_PAR05 <> 2

		DbSelectArea("SF1")
		DbSetOrder(1)
		DbSelectArea("SD1")
		DbSetOrder(1)
		DbSelectArea("SFT")
		DbSetOrder(1)//FT_FILIAL+FT_TIPOMOV+FT_SERIE+FT_NFISCAL+FT_CLIEFOR+FT_LOJA+FT_ITEM+FT_PRODUTO
		DbSelectArea("CD2")
		DbSetOrder(1)//CD2_FILIAL+CD2_TPMOV+CD2_SERIE+CD2_DOC+CD2_CODCLI+CD2_LOJCLI+CD2_ITEM+CD2_CODPRO+CD2_IMP
		// (2) CD2_FILIAL+CD2_TPMOV+CD2_SERIE+CD2_DOC+CD2_CODFOR+CD2_LOJFOR+CD2_ITEM+CD2_CODPRO+CD2_IMP

		cQuery := " SELECT COUNT(F1_FILIAL) AS RECSF1 "
		cQuery += " FROM " + RetSqlName("SF1") + " SF1 "
		cQuery += " WHERE F1_FILIAL BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'  "
		cQuery += " AND F1_DTDIGIT BETWEEN '" + DtoS(MV_PAR03) + "' AND '" + DtoS(MV_PAR04) + "' "
		cQuery += " AND F1_DOC BETWEEN '" + MV_PAR06 + "' AND '" + MV_PAR07 + "' "
		cQuery += " AND F1_SERIE BETWEEN '" + MV_PAR08 + "' AND '" + MV_PAR09 + "' "
		cQuery += " AND F1_FORNECE BETWEEN '" + MV_PAR12 + "' AND '" + MV_PAR13 + "' "
		cQuery += " AND F1_LOJA  BETWEEN '" + MV_PAR14 + "' AND '" + MV_PAR15 + "' "
		cQuery += " AND D_E_L_E_T_ = ' '  "

		TcQuery ChangeQuery(cQuery) Alias TMP NEW

		nRegTot := TMP->RECSF1

		TMP->(DbCloseArea())

		ProcRegua(nRegTot)

		cQuery := " SELECT F1_FILIAL, F1_DTDIGIT, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_TIPO, SF1.R_E_C_N_O_ AS RECSF1 "
		cQuery += " FROM " + RetSqlName("SF1") + " SF1 "
		cQuery += " WHERE F1_FILIAL BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'  "
		cQuery += " AND F1_DTDIGIT BETWEEN '" + DtoS(MV_PAR03) + "' AND '" + DtoS(MV_PAR04) + "' "
		cQuery += " AND F1_DOC BETWEEN '" + MV_PAR06 + "' AND '" + MV_PAR07 + "' "
		cQuery += " AND F1_SERIE BETWEEN '" + MV_PAR08 + "' AND '" + MV_PAR09 + "' "
		cQuery += " AND F1_FORNECE BETWEEN '" + MV_PAR12 + "' AND '" + MV_PAR13 + "' "
		cQuery += " AND F1_LOJA  BETWEEN '" + MV_PAR14 + "' AND '" + MV_PAR15 + "' "
		cQuery += " AND D_E_L_E_T_ = ' ' Order By F1_FILIAL,F1_DTDIGIT,F1_FORNECE,F1_LOJA,F1_DOC,F1_SERIE "

		TcQuery ChangeQuery(cQuery) Alias TMP NEW
		DbSelectArea("TMP")
		DbGotop()

		Do While TMP->(!Eof())

			cChaveD1 := TMP->F1_FILIAL + TMP->F1_DOC + TMP->F1_SERIE + TMP->F1_FORNECE + TMP->F1_LOJA
			cChaveFT := TMP->F1_FILIAL + "E" + TMP->F1_SERIE + TMP->F1_DOC + TMP->F1_FORNECE + TMP->F1_LOJA
			cFilSF4  := If( Empty( xFilial("SF4") ), xFilial("SF4"), TMP->F1_FILIAL )

			IncProc( TransForm( cChaveD1, "@R 99-999999XXX-XXX/999999-99" ) )

			If SD1->( DbSeek( cChaveD1 ) )
				nBasPisT := 0
				nBasCofT := 0
				nValPisT := 0
				nValCofT := 0
				Begin Transaction
					While SD1->(!Eof()) .And. SD1->D1_FILIAL + SD1->D1_DOC + SD1->D1_SERIE + SD1->D1_FORNECE + SD1->D1_LOJA  == cChaveD1
						If SF4->( DbSeek( cFilSF4 + SD1->D1_TES ) )

							/*-----------------------------------------------------------------------------------------------------------------------------------------
							nBasePis := If( SF4->F4_PISCOF $ '13' .And. SF4->F4_PISCRED <> '3', SD1->D1_TOTAL - SD1->D1_VALDESC + SD1->D1_VALFRE + SD1->D1_DESPESA, 0 )
							nBaseCOF := If( SF4->F4_PISCOF $ '23' .And. SF4->F4_PISCRED <> '3', SD1->D1_TOTAL - SD1->D1_VALDESC + SD1->D1_VALFRE + SD1->D1_DESPESA, 0 )
							-----------------------------------------------------------------------------------------------------------------------------------------*/

							//ALTERADO PARA SUNTECH POR TER LIMINAR JUDICIAL PARA TRATAR ESSE CASO
							If MV_PAR16 == 2 .And. SD1->D1_TIPO == "D"			// ICMS na Base do Pis/Cof  1= Sim ; 2 = Não
								nBasePis := If( SF4->F4_PISCOF $ '13' .And. SF4->F4_PISCRED <> '3', SD1->D1_TOTAL - SD1->D1_VALDESC + SD1->D1_VALFRE + SD1->D1_DESPESA - SD1->D1_VALICM, 0 )
								nBaseCOF := If( SF4->F4_PISCOF $ '23' .And. SF4->F4_PISCRED <> '3', SD1->D1_TOTAL - SD1->D1_VALDESC + SD1->D1_VALFRE + SD1->D1_DESPESA - SD1->D1_VALICM, 0 )
							Else
								nBasePis := If( SF4->F4_PISCOF $ '13' .And. SF4->F4_PISCRED <> '3', SD1->D1_TOTAL - SD1->D1_VALDESC + SD1->D1_VALFRE + SD1->D1_DESPESA, 0 )
								nBaseCOF := If( SF4->F4_PISCOF $ '23' .And. SF4->F4_PISCRED <> '3', SD1->D1_TOTAL - SD1->D1_VALDESC + SD1->D1_VALFRE + SD1->D1_DESPESA, 0 )
							Endif

							nValPis  := Round( nBasePis * SD1->D1_ALQIMP6 / 100, 2 )
							nValCof  := Round( nBaseCof * SD1->D1_ALQIMP5 / 100, 2 )
							If RecLock( "SD1", .F. )
								SD1->D1_BASIMP5 := nBaseCof
								SD1->D1_BASIMP6 := nBasePis
								SD1->D1_VALIMP5 := nValCof
								SD1->D1_VALIMP6 := nValPis
								SD1->D1_ALQIMP5 := SuperGetMv("MV_TXCOFIN")
								SD1->D1_ALQIMP6 := SuperGetMv("MV_TXPIS")
								SD1->(MsUnLock())
								nBasPisT  += nBasePis
								nBasCofT  += nBaseCof
								nValCofT  += nValCof
								nValPisT  += nValPis
								//cChaveFT  += SD1->D1_ITEM + SD1->D1_COD
								If MV_PAR10 = 1 .And. SFT->( DbSeek( cChaveFT + SD1->D1_ITEM + SD1->D1_COD ) )
									If RecLock( "SFT", .F. )
										SFT->FT_BASECOF := nBaseCof
										SFT->FT_BASEPIS := nBasePis
										SFT->FT_VALPIS  := nValPis
										SFT->FT_VALCOF  := nValCof
										SFT->FT_CODBCC  := SF4->F4_CODBCC
										SFT->FT_INDNTFR := SF4->F4_INDNTFR
										SFT->FT_CSTCOF  := SF4->F4_CSTCOF
										SFT->FT_CSTPIS  := SF4->F4_CSTPIS
										SFT->FT_ALIQPIS := SD1->D1_ALQIMP6
										SFT->FT_ALIQCOF := SD1->D1_ALQIMP5
										SFT->(MsUnLock())
										If MV_PAR11 = 1
											If SD1->D1_TIPO $ "DB"
												CD2->(DbSetOrder(1))
											Else
												CD2->(DbSetOrder(2))
											EndIf
											//PIS
											If CD2->( DbSeek( cChaveFT + SD1->D1_ITEM + SD1->D1_COD + "PS2" ) )
												If SF4->F4_PISCOF $ "24" .Or. SF4->F4_PISCRED = '3'
													If RecLock("CD2",.F.)
														CD2->(DbDelete())
														CD2->(MsUnLock())
													EndIf
												Else
													If RecLock("CD2",.F.)
														CD2->CD2_BC     := nBasePis
														CD2->CD2_VLTRIB := nValPis
														CD2->CD2_QTRIB  := SD1->D1_QUANT
														CD2->CD2_CST    := SF4->F4_CSTPIS
														CD2->(MsUnLock())
													EndIf
												EndIf
											Else
												If SF4->F4_PISCOF $ "13" .And. SF4->F4_PISCRED <> '3'
													If RecLock("CD2",.T.)
														CD2->CD2_FILIAL := SD1->D1_FILIAL
														CD2->CD2_TPMOV  := SFT->FT_TIPOMOV
														CD2->CD2_DOC    := SD1->D1_DOC
														CD2->CD2_SERIE  := SD1->D1_SERIE
														CD2->CD2_ITEM   := SD1->D1_ITEM
														If SD1->D1_TIPO $ "DB"
															CD2->CD2_CODCLI := SD1->D1_FORNECE
															CD2->CD2_LOJCLI := SD1->D1_LOJA
														Else
															CD2->CD2_CODFOR := SD1->D1_FORNECE
															CD2->CD2_LOJFOR := SD1->D1_LOJA
														EndIf
														CD2->CD2_IMP    := "PS2"
														CD2->CD2_CODPRO := SD1->D1_COD
														CD2->CD2_ORIGEM := Left(SD1->D1_CLASFIS,1)
														CD2->CD2_BC     := nBasePis
														CD2->CD2_VLTRIB := nValPis
														CD2->CD2_QTRIB  := SD1->D1_QUANT
														CD2->CD2_CST    := SF4->F4_CSTPIS
														CD2->CD2_ALIQ   := SD1->D1_ALQIMP6
														CD2->(MsUnLock())
													EndIf
												EndIf
											EndIf
											//COFINS
											If CD2->( DbSeek( cChaveFT + SD1->D1_ITEM + SD1->D1_COD + "CF2" ) )
												If SF4->F4_PISCOF $ "14" .Or. SF4->F4_PISCRED = '3'
													If RecLock("CD2",.F.)
														CD2->(DbDelete())
														CD2->(MsUnLock())
													EndIf
												Else
													If RecLock("CD2",.F.)
														CD2->CD2_BC     := nBaseCof
														CD2->CD2_VLTRIB := nValCof
														CD2->CD2_QTRIB  := SD1->D1_QUANT
														CD2->CD2_CST    := SF4->F4_CSTPIS
														CD2->(MsUnLock())
													EndIf
												EndIf
											Else
												If SF4->F4_PISCOF $ "23" .And. SF4->F4_PISCRED <> '3'
													If RecLock("CD2",.T.)
														CD2->CD2_FILIAL := SD1->D1_FILIAL
														CD2->CD2_TPMOV  := SFT->FT_TIPOMOV
														CD2->CD2_DOC    := SD1->D1_DOC
														CD2->CD2_SERIE  := SD1->D1_SERIE
														CD2->CD2_ITEM   := SD1->D1_ITEM
														If SD1->D1_TIPO $ "DB"
															CD2->CD2_CODCLI := SD1->D1_FORNECE
															CD2->CD2_LOJCLI := SD1->D1_LOJA
														Else
															CD2->CD2_CODFOR := SD1->D1_FORNECE
															CD2->CD2_LOJFOR := SD1->D1_LOJA
														EndIf
														CD2->CD2_IMP    := "CF2"
														CD2->CD2_CODPRO := SD1->D1_COD
														CD2->CD2_ORIGEM := Left(SD1->D1_CLASFIS,1)
														CD2->CD2_BC     := nBasePis
														CD2->CD2_VLTRIB := nValPis
														CD2->CD2_QTRIB  := SD1->D1_QUANT
														CD2->CD2_CST    := SF4->F4_CSTPIS
														CD2->CD2_ALIQ   := SD1->D1_ALQIMP5
														CD2->(MsUnLock())
													EndIf
												EndIf
											EndIf
										EndIf
									EndIf
								EndIf
							EndIf
						Else
							Alert( "TES não cadastrada!Filial/doc/serie-TES: (" + SD1->D1_FILIAL + "/" + SD1->D1_DOC  + "/" + SD1->D1_SERIE + "-" + SD1->D1_TES + ")" )
						EndIf
						SD1->(DbSkip())
					End
					SF1->(DbGoTo( TMP->RECSF1 ) )
					If RecLock("SF1",.F.)
						SF1->F1_VALIMP5 := nValCofT
						SF1->F1_VALIMP6 := nValPisT
						SF1->F1_BASIMP5 := nBasCofT
						SF1->F1_BASIMP6 := nBasPisT
						SF1->(MsUnLock())
					EndIf
				End Transaction
				DbCommitAll()

			EndIf

			TMP->(DbSkip())

		End

		TMP->(DbCloseArea())

	EndIf


	If MV_PAR05 <> 1

		DbSelectArea("SF2")
		DbSetOrder(1)
		DbSelectArea("SD2")
		DbSetOrder(3)
		DbSelectArea("SFT")
		DbSetOrder(1)//FT_FILIAL+FT_TIPOMOV+FT_SERIE+FT_NFISCAL+FT_CLIEFOR+FT_LOJA+FT_ITEM+FT_PRODUTO
		DbSelectArea("CD2")
		DbSetOrder(1)//CD2_FILIAL+CD2_TPMOV+CD2_SERIE+CD2_DOC+CD2_CODCLI+CD2_LOJCLI+CD2_ITEM+CD2_CODPRO+CD2_IMP
		// (2) CD2_FILIAL+CD2_TPMOV+CD2_SERIE+CD2_DOC+CD2_CODFOR+CD2_LOJFOR+CD2_ITEM+CD2_CODPRO+CD2_IMP

		cQuery := " SELECT count(F2_FILIAL) AS RECSF2 "
		cQuery += " FROM " + RetSqlName("SF2") + " SF2 "
		cQuery += " WHERE F2_FILIAL BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'  "
		cQuery += " AND F2_EMISSAO BETWEEN '" + DtoS(MV_PAR03) + "' AND '" + DtoS(MV_PAR04) + "' "
		cQuery += " AND F2_DOC BETWEEN '" + MV_PAR06 + "' AND '" + MV_PAR07 + "' "
		cQuery += " AND F2_SERIE BETWEEN '" + MV_PAR08 + "' AND '" + MV_PAR09 + "' "
		cQuery += " AND F2_CLIENTE BETWEEN '" + MV_PAR12 + "' AND '" + MV_PAR13 + "' "
		cQuery += " AND F2_LOJA  BETWEEN '" + MV_PAR14 + "' AND '" + MV_PAR15 + "' "
		cQuery += " AND D_E_L_E_T_ = ' ' "

		TcQuery ChangeQuery(cQuery) Alias TMP NEW

		nRegTot := TMP->RECSF2

		TMP->(DbCloseArea())

		ProcRegua(nRegTot)

		cQuery := " SELECT F2_FILIAL, F2_EMISSAO, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, F2_TIPO, SF2.R_E_C_N_O_ AS RECSF2 "
		cQuery += " FROM " + RetSqlName("SF2") + " SF2 "
		cQuery += " WHERE F2_FILIAL BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'  "
		cQuery += " AND F2_EMISSAO BETWEEN '" + DtoS(MV_PAR03) + "' AND '" + DtoS(MV_PAR04) + "' "
		cQuery += " AND F2_DOC BETWEEN '" + MV_PAR06 + "' AND '" + MV_PAR07 + "' "
		cQuery += " AND F2_SERIE BETWEEN '" + MV_PAR08 + "' AND '" + MV_PAR09 + "' "
		cQuery += " AND F2_CLIENTE BETWEEN '" + MV_PAR12 + "' AND '" + MV_PAR13 + "' "
		cQuery += " AND F2_LOJA  BETWEEN '" + MV_PAR14 + "' AND '" + MV_PAR15 + "' "
		cQuery += " AND D_E_L_E_T_ = ' ' Order By F2_FILIAL,F2_EMISSAO,F2_CLIENTE,F2_LOJA,F2_DOC,F2_SERIE "

		TcQuery ChangeQuery(cQuery) Alias TMP NEW
		DbSelectArea("TMP")
		DbGotop()

		Do While TMP->(!Eof())

			cChaveD2 := TMP->F2_FILIAL + TMP->F2_DOC + TMP->F2_SERIE + TMP->F2_CLIENTE + TMP->F2_LOJA
			cChaveFT := TMP->F2_FILIAL + "S" + TMP->F2_SERIE + TMP->F2_DOC + TMP->F2_CLIENTE + TMP->F2_LOJA
			cFilSF4  := If( Empty( xFilial("SF4") ), xFilial("SF4"), TMP->F2_FILIAL )

			IncProc( TransForm( cChaveD2, "@R 99-999999XXX-XXX/999999-99" ) )

			If SD2->( DbSeek( cChaveD2 ) )
				nBasPisT := 0
				nBasCofT := 0
				nValPisT := 0
				nValCofT := 0
				Begin Transaction
					While SD2->(!Eof()) .And. SD2->D2_FILIAL + SD2->D2_DOC + SD2->D2_SERIE + SD2->D2_CLIENTE + SD2->D2_LOJA  == cChaveD2
						If SF4->( DbSeek( cFilSF4 + SD2->D2_TES ) )

							/*-------------------------------------------------------------------------------------------------------------------------
							nBasePis := If( SF4->F4_PISCOF $ '13' .And. SF4->F4_PISCRED <> '3', SD2->D2_TOTAL + SD2->D2_VALFRE + SD2->D2_DESPESA, 0 )
							nBaseCOF := If( SF4->F4_PISCOF $ '23' .And. SF4->F4_PISCRED <> '3', SD2->D2_TOTAL + SD2->D2_VALFRE + SD2->D2_DESPESA, 0 )
							-------------------------------------------------------------------------------------------------------------------------*/

							//ALTERADO PARA SUNTECH POR TER LIMINAR JUDICIAL PARA TRATAR ESSE CASO
							If MV_PAR16 == 1			// SIM
								nBasePis := If( SF4->F4_PISCOF $ '13' .And. SF4->F4_PISCRED <> '3', SD2->D2_TOTAL + SD2->D2_VALFRE + SD2->D2_DESPESA, 0 )
								nBaseCOF := If( SF4->F4_PISCOF $ '23' .And. SF4->F4_PISCRED <> '3', SD2->D2_TOTAL + SD2->D2_VALFRE + SD2->D2_DESPESA, 0 )
							Else
								nBasePis := If( SF4->F4_PISCOF $ '13' .And. SF4->F4_PISCRED <> '3', SD2->D2_TOTAL + SD2->D2_VALFRE + SD2->D2_DESPESA - SD2->D2_VALICM, 0 )
								nBaseCOF := If( SF4->F4_PISCOF $ '23' .And. SF4->F4_PISCRED <> '3', SD2->D2_TOTAL + SD2->D2_VALFRE + SD2->D2_DESPESA - SD2->D2_VALICM, 0 )
							Endif

							nValPis  := Round( nBasePis * SD2->D2_ALQIMP6 / 100, 2 )
							nValCof  := Round( nBaseCof * SD2->D2_ALQIMP5 / 100, 2 )
							If RecLock( "SD2", .F. )
								SD2->D2_BASIMP5 := nBaseCof
								SD2->D2_BASIMP6 := nBasePis
								SD2->D2_VALIMP5 := nValCof
								SD2->D2_VALIMP6 := nValPis
								SD2->D2_ALQIMP5 := SuperGetMv("MV_TXCOFIN")
								SD2->D2_ALQIMP6 := SuperGetMv("MV_TXPIS")
								SD2->(MsUnLock())
								nBasPisT  += nBasePis
								nBasCofT  += nBaseCof
								nValCofT  += nValCof
								nValPisT  += nValPis
								//cChaveFT  += PadR(SD2->D2_ITEM,TamSX3("FT_ITEM")[1]) + SD2->D2_COD
								If MV_PAR10 = 1 .And. SFT->( DbSeek( cChaveFT + PadR(SD2->D2_ITEM,TamSX3("FT_ITEM")[1]) + SD2->D2_COD ) )
									If RecLock( "SFT", .F. )
										SFT->FT_BASECOF := nBaseCof
										SFT->FT_BASEPIS := nBasePis
										SFT->FT_VALPIS  := nValPis
										SFT->FT_VALCOF  := nValCof
										SFT->FT_CODBCC  := SF4->F4_CODBCC
										SFT->FT_INDNTFR := SF4->F4_INDNTFR
										SFT->FT_CSTCOF  := SF4->F4_CSTCOF
										SFT->FT_CSTPIS  := SF4->F4_CSTPIS
										SFT->FT_ALIQPIS := SD2->D2_ALQIMP6
										SFT->FT_ALIQCOF := SD2->D2_ALQIMP5
										SFT->(MsUnLock())
										If MV_PAR11 = 1
											If SD2->D2_TIPO $ "DB"
												CD2->(DbSetOrder(2))
											Else
												CD2->(DbSetOrder(1))
											EndIf
											//PIS
											If CD2->( DbSeek( cChaveFT + PadR(SD2->D2_ITEM,TamSX3("FT_ITEM")[1]) + SD2->D2_COD + "PS2" ) )
												If SF4->F4_PISCOF $ "24" .Or. SF4->F4_PISCRED = '3'
													If RecLock("CD2",.F.)
														CD2->(DbDelete())
														CD2->(MsUnLock())
													EndIf
												Else
													If RecLock("CD2",.F.)
														CD2->CD2_BC     := nBasePis
														CD2->CD2_VLTRIB := nValPis
														CD2->CD2_QTRIB  := SD2->D2_QUANT
														CD2->CD2_CST    := SF4->F4_CSTPIS
														CD2->(MsUnLock())
													EndIf
												EndIf
											Else
												If SF4->F4_PISCOF $ "13" .And. SF4->F4_PISCRED <> '3'
													If RecLock("CD2",.T.)
														CD2->CD2_FILIAL := SD2->D2_FILIAL
														CD2->CD2_TPMOV  := SFT->FT_TIPOMOV
														CD2->CD2_DOC    := SD2->D2_DOC
														CD2->CD2_SERIE  := SD2->D2_SERIE
														CD2->CD2_ITEM   := SD2->D2_ITEM
														If SD2->D2_TIPO $ "DB"
															CD2->CD2_CODFOR := SD2->D2_CLIENTE
															CD2->CD2_LOJFOR := SD2->D2_LOJA
														Else
															CD2->CD2_CODCLI := SD2->D2_CLIENTE
															CD2->CD2_LOJCLI := SD2->D2_LOJA
														EndIf
														CD2->CD2_IMP    := "PS2"
														CD2->CD2_CODPRO := SD2->D2_COD
														CD2->CD2_ORIGEM := Left(SD2->D2_CLASFIS,1)
														CD2->CD2_BC     := nBasePis
														CD2->CD2_VLTRIB := nValPis
														CD2->CD2_QTRIB  := SD2->D2_QUANT
														CD2->CD2_CST    := SF4->F4_CSTPIS
														CD2->CD2_ALIQ   := SD2->D2_ALQIMP6
														CD2->(MsUnLock())
													EndIf
												EndIf
											EndIf
											//COFINS
											If CD2->( DbSeek( cChaveFT + PadR(SD2->D2_ITEM,TamSX3("FT_ITEM")[1]) + SD2->D2_COD + "CF2" ) )
												If SF4->F4_PISCOF $ "14" .Or. SF4->F4_PISCRED = '3'
													If RecLock("CD2",.F.)
														CD2->(DbDelete())
														CD2->(MsUnLock())
													EndIf
												Else
													If RecLock("CD2",.F.)
														CD2->CD2_BC     := nBaseCof
														CD2->CD2_VLTRIB := nValCof
														CD2->CD2_QTRIB  := SD2->D2_QUANT
														CD2->CD2_CST    := SF4->F4_CSTPIS
														CD2->(MsUnLock())
													EndIf
												EndIf
											Else
												If SF4->F4_PISCOF $ "23" .And. SF4->F4_PISCRED <> '3'
													If RecLock("CD2",.T.)
														CD2->CD2_FILIAL := SD2->D2_FILIAL
														CD2->CD2_TPMOV  := SFT->FT_TIPOMOV
														CD2->CD2_DOC    := SD2->D2_DOC
														CD2->CD2_SERIE  := SD2->D2_SERIE
														CD2->CD2_ITEM   := SD2->D2_ITEM
														If SD1->D1_TIPO $ "DB"
															CD2->CD2_CODFOR := SD2->D2_CLIENTE
															CD2->CD2_LOJFOR := SD2->D2_LOJA
														Else
															CD2->CD2_CODCLI := SD2->D2_CLIENTE
															CD2->CD2_LOJCLI := SD2->D2_LOJA
														EndIf
														CD2->CD2_IMP    := "CF2"
														CD2->CD2_CODPRO := SD2->D2_COD
														CD2->CD2_ORIGEM := Left(SD2->D2_CLASFIS,1)
														CD2->CD2_BC     := nBasePis
														CD2->CD2_VLTRIB := nValPis
														CD2->CD2_QTRIB  := SD2->D2_QUANT
														CD2->CD2_CST    := SF4->F4_CSTPIS
														CD2->CD2_ALIQ   := SD2->D2_ALQIMP5
														CD2->(MsUnLock())
													EndIf
												EndIf
											EndIf
										EndIf
									EndIf
								EndIf
							EndIf
						Else
							Alert( "TES não cadastrada!Filial/doc/serie-TES: (" + SD2->D2_FILIAL + "/" + SD2->D2_DOC  + "/" + SD2->D2_SERIE + "-" + SD2->D2_TES + ")" )
						EndIf
						SD2->(DbSkip())
					End
					SF2->(DbGoTo( TMP->RECSF2 ) )
					If RecLock("SF2",.F.)
						SF2->F2_VALIMP5 := nValCofT
						SF2->F2_VALIMP6 := nValPisT
						SF2->F2_BASIMP5 := nBasCofT
						SF2->F2_BASIMP6 := nBasPisT
						SF2->(MsUnLock())
					EndIf
				End Transaction
				DbCommitAll()

			EndIf

			TMP->(DbSkip())

		End

		TMP->(DbCloseArea())

	EndIf



Return

/*ÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Function  ³ ValidPerg() - Cria grupo de Perguntas.
ÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ*/
Static Function ValidPerg(_cPerg)

Local _SALIAS  := ALIAS()
//Local cPerg    := "FISP28    "
Local cPerg    := _cPerg
Local aRegs    := {}
Local I,J

Dbselectarea("SX1")
Dbsetorder(1)

AADD(aRegs,{cPerg,"01","Filial de    :"				,"Filial de   :"				,"Filial de   :"				,"mv_ch1","C",02,0,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SM0",""})
AADD(aRegs,{cPerg,"02","Filial ate   :"				,"Filial Ate  :"				,"Filial Ate  :"				,"mv_ch2","C",02,0,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","SM0",""})
AADD(aRegs,{cPerg,"03","Data de      :"				,"Data de     :"				,"Data de     :"				,"mv_ch3","D",08,0,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"04","Data ate     :"				,"Data ate    :"				,"Data ate    :"				,"mv_ch4","D",08,0,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"05","Movimento    :"				,"Status      :"				,"Status      :"				,"mv_ch5","N",01,0,0,"C","","mv_par05","Entrada","","","","","Saida","","","","","Ambas","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"06","Documento de :"				,"Documento de :"				,"Documento de :"				,"mv_ch6","C",09,0,0,"G","","mv_par06","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"07","Documento ate:"				,"Documento ate:"				,"Documento ate:"				,"mv_ch7","C",09,0,0,"G","","mv_par07","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"08","Serie de     :"				,"Serie de     :"				,"Serie de     :"				,"mv_ch8","C",03,0,0,"G","","mv_par08","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"09","Serie Ate    :"				,"Serie Ate    :"				,"Serie Ate    :"				,"mv_ch9","C",03,0,0,"G","","mv_par09","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"10","Atualiza SFT :"				,"Status      :"				,"Status      :"				,"mv_chA","N",01,0,0,"C","","mv_par10","Sim","","","","","Nao","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"11","Atualiza CD2 :"				,"Status      :"				,"Status      :"				,"mv_chB","N",01,0,0,"C","","mv_par11","Sim","","","","","Nao","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"12","For/Cli    de:"				,"Documento de :"				,"Documento de :"				,"mv_chc","C",06,0,0,"G","","mv_par12","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"13","For/Cli    ate:"			,"Documento ate:"				,"Documento ate:"				,"mv_chd","C",06,0,0,"G","","mv_par13","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"14","Loja de      :"				,"Serie de     :"				,"Serie de     :"				,"mv_che","C",02,0,0,"G","","mv_par14","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"15","Loja Ate     :"				,"Serie Ate    :"				,"Serie Ate    :"				,"mv_chf","C",02,0,0,"G","","mv_par15","","","","","","","","","","","","","","","","","","","","","","","","","",""})
AADD(aRegs,{cPerg,"16","ICMS na Base do Pis/Cof :"	,"ICMS na Base do Pis/Cof :"	,"ICMS na Base do Pis/Cof :"	,"mv_chg","N",01,0,0,"C","","mv_par16","Sim","","","","","Nao","","","","","","","","","","","","","","","","","","","",""})
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

Dbselectarea(_SALIAS)

Return

Return
