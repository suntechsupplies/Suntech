#INCLUDE "MATR550.CH"
#INCLUDE "Protheus.CH"

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ MATR550  ³ Autor ³ Marco Bianchi         ³ Data ³ 05/06/06 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Relacao de Notas Fiscais                                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ SIGAFAT - R4                                               ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function XMATR550()

Local oReport	:= Nil
Local aPDFields	:= {"A1_NOME","A2_NOME"}

FATPDLoad(Nil,Nil,aPDFields)	 
oReport := ReportDef()

// Ajusta tamanho da Fonte
oReport:nFontBody 	:= 11

// Altura da Linha
oReport:nLineHeight	:= 37

// Desabilita a alteração de orientação do Relatorio (Sempre Landscape/Paisagem)
oReport:lDisableOrientation := .T.

oReport:PrintDialog()
FATPDUnload()

Return

/*ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ReportDef ³ Autor ³ Marco Bianchi         ³ Data ³05/06/06  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³A funcao estatica ReportDef devera ser criada para todos os ³±±
±±³          ³relatorios que poderao ser agendados pelo usuario.          ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ExpO1: Objeto do relatório                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³Nenhum                                                      ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   DATA   ³ Programador   ³Manutencao efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function ReportDef()

Local oReport,oSintetico,oItens,oItensD1,oItensD2,oCabec,oCabecF1,oCabecF2,oTotDia
Local cAliasQry := GetNextAlias()
Local cNota 	:= ""
Local cSerieView 	:= ""
Local nAcN1  	:= 0, nAcN2 := 0, nAcN3 := 0, nAcN4 := 0, nAcN5 := 0, nAcN6 := 0, nVlrISS := 0, nFretAut := 0
Local cCod		:= ""
Local cDesc		:= ""
Local cPedido	:= ""
Local nQuant	:= 0
Local nPrcVen	:= 0
Local nValadi	:= 0
Local cItemPV	:= ""

// Variaveis Base Localizacao
Local cCliente 		:= ""
Local cLoja			:= ""
Local cNome			:= ""
Local dEmissao 		:= CTOD("  /  /  ")
Local cTipo    		:= ""
Local nTotal 		:= 0
Local nTotcImp  	:= 0

Local nAcG1			:= 0
Local nAcG2			:= 0
Local nAcGAdi		:= 0
Local nTotNetGer	:= 0

Local cTitD2Doc := RetTitle("D2_DOC")
Local cTitD2Qtd := RetTitle("D2_QUANT")	
Local cTitD2VIp := RetTitle("D2_VALIPI")	
Local cTitD2VIc := RetTitle("D2_VALICM")
Local cTitD2VIs := RetTitle("D2_VALISS")

Local cPicD2Doc := PesqPict("SD2","D2_DOC")		
Local cPicD2Ser := PesqPict("SD2","D2_SERIE")    
Local cPicD2Qtd := "@E 999999999999999999.99"                            	
Local cPicD2Tot := PesqPict("SD2","D2_TOTAL")	
Local cPicD2VIp := PesqPict("SD2","D2_VALIPI")	
Local cPicD2VIc := PesqPict("SD2","D2_VALICM")	
Local cPicD2VIs := PesqPict("SD2","D2_VALISS")
Local cPicD2Pvn := PesqPict("SD2","D2_PRCVEN")	
Local cPicD2Ped := PesqPict("SD2","D2_PEDIDO") 
Local cPicD2IPv := PesqPict("SD2","D2_ITEMPV")

Local cTamD2Doc := TamSX3("D2_DOC")[1]	        
Local cTamD2Qtd := TamSX3("D2_QUANT")[1]	        
Local cTamD2Tot := TamSX3("D2_TOTAL")[1]	        
Local cTamD2VIp := TamSX3("D2_VALIPI")[1]	    
Local cTamD2VIc := TamSX3("D2_VALICM")[1]	    
Local cTamD2VIs := TamSX3("D2_VALISS")[1]
Local cTamD2Cod := TamSX3("D2_COD")[1]
Local cTamB1Dsc := TamSX3("B1_DESC")[1]
Local cTamD2PVn := TamSX3("D2_PRCVEN")[1]
Local cTamD2Ped := TamSX3("D2_PEDIDO")[1]
Local cTamD2IPV := TamSX3("D2_ITEMPV")[1]

Local cTitF2Cli := RetTitle("F2_CLIENTE")	
Local cTitF2Loj := RetTitle("F2_LOJA")		
Local cTitA1Nom := RetTitle("A1_NOME")		
Local cTitF2Emi := RetTitle("F2_EMISSAO")	
Local cTitF2Tip := RetTitle("F2_TIPO")

Local cTamF2Cli := TamSX3("F2_CLIENTE")[1]+ 5
Local cTamF2Emi := TamSX3("F2_EMISSAO")[1]+ 5


//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Criacao do componente de impressao                                      ³
//³                                                                        ³
//³TReport():New                                                           ³
//³ExpC1 : Nome do relatorio                                               ³
//³ExpC2 : Titulo                                                          ³
//³ExpC3 : Pergunte                                                        ³
//³ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao  ³
//³ExpC5 : Descricao                                                       ³
//³                                                                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//oReport := TReport():New("XMATR550",STR0030,"MTR550P9R1", {|oReport| ReportPrint(oReport,cAliasQry,oSintetico,oItens,oItensD1,oItensD2,oCabec,oCabecF1,oCabecF2,oTotDia)},"Romaneio de Faturamento")  // "Relacao de Notas Fiscais"###"Este programa ira emitir a relacao de notas fiscais."
oReport := TReport():New("XMATR550","Romaneio de Faturamento","XMTR550P9R", {|oReport| ReportPrint(oReport,cAliasQry,oSintetico,oItens,oItensD1,oItensD2,oCabec,oCabecF1,oCabecF2,oTotDia)},"Romaneio de Faturamento")

// Suprime a Impressão da Pagina de Parametros
oReport:lHideEmpFil := .T.

// Configura o relatorio no formato Paisagem
oReport:SetLandscape(.T.) 

Pergunte(oReport:uParam,.F.)
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Criacao da secao utilizada pelo relatorio                               ³
//³                                                                        ³
//³TRSection():New                                                         ³
//³ExpO1 : Objeto TReport que a secao pertence                             ³
//³ExpC2 : Descricao da seçao                                              ³
//³ExpA3 : Array com as tabelas utilizadas pela secao. A primeira tabela   ³
//³        sera considerada como principal para a seção.                   ³
//³ExpA4 : Array com as Ordens do relatório                                ³
//³ExpL5 : Carrega campos do SX3 como celulas                              ³
//³        Default : False                                                 ³
//³ExpL6 : Carrega ordens do Sindex                                        ³
//³        Default : False                                                 ³
//³                                                                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Criacao da celulas da secao do relatorio                                ³
//³                                                                        ³
//³TRCell():New                                                            ³
//³ExpO1 : Objeto TSection que a secao pertence                            ³
//³ExpC2 : Nome da celula do relatório. O SX3 será consultado              ³
//³ExpC3 : Nome da tabela de referencia da celula                          ³
//³ExpC4 : Titulo da celula                                                ³
//³        Default : X3Titulo()                                            ³
//³ExpC5 : Picture                                                         ³
//³        Default : X3_PICTURE                                            ³
//³ExpC6 : Tamanho                                                         ³
//³        Default : X3_TAMANHO                                            ³
//³ExpL7 : Informe se o tamanho esta em pixel                              ³
//³        Default : False                                                 ³
//³ExpB8 : Bloco de código para impressao.                                 ³
//³        Default : ExpC2                                                 ³
//³                                                                        ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If cPaisLoc == "BRA"

	// Sintetico
	oSintetico := TRSection():New(oReport,STR0055,{"SF2","SD2"},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
	oSintetico:SetTotalInLine(.F.)
	TRCell():New(oSintetico,"CNOTA"		,/*Tabela*/,cTitD2Doc		             , cPicD2Doc ,cTamD2Doc         	        ,/*lPixel*/,{|| cNota })
	TRCell():New(oSintetico,"CSERIEVIEW",/*Tabela*/,SerieNfId("SD2",7,"D2_SERIE"), cPicD2Ser ,SerieNfId("SD2",6,"D2_SERIE")	,/*lPixel*/,{|| cSerieView })
	TRCell():New(oSintetico,"NACN1"		,/*Tabela*/,cTitD2Qtd	                 , cPicD2Qtd ,cTamD2Qtd         	        ,/*lPixel*/,{|| nAcN1 },,,"RIGHT")
	TRCell():New(oSintetico,"NACN2"		,/*Tabela*/,STR0039					     , cPicD2Tot ,cTamD2Tot         	        ,/*lPixel*/,{|| nAcN2 },,,"RIGHT")
	TRCell():New(oSintetico,"NACN5"		,/*Tabela*/,cTitD2VIp				     , cPicD2VIp ,cTamD2VIp             	    ,/*lPixel*/,{|| nAcN5 },,,"RIGHT")
	TRCell():New(oSintetico,"NACN4"		,/*Tabela*/,cTitD2VIc				     , cPicD2VIc ,cTamD2VIc             	    ,/*lPixel*/,{|| nAcN4 },,,"RIGHT")
	TRCell():New(oSintetico,"NVLRISS"	,/*Tabela*/,cTitD2VIs				     , cPicD2VIs ,cTamD2VIs             	    ,/*lPixel*/,{|| nVlrISS },,,"RIGHT")
	TRCell():New(oSintetico,"NDESPACES",/*Tabela*/ ,STR0032					     , cPicD2Tot ,cTamD2Tot         	        ,/*lPixel*/,{|| nAcN3+nFretAut },,,"RIGHT")
	TRCell():New(oSintetico,"NACN6"		,/*Tabela*/,STR0033					     , cPicD2Tot ,cTamD2Tot         	        ,/*lPixel*/,{|| nAcN6 },,,"RIGHT")

    // Analitico
	oCabec := TRSection():New(oReport,STR0056,{"SF2","SD2","SA1"},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
	oCabec:SkipLine(1)
	oCabec:SetTotalInLine(.F.)
	TRCell():New(oCabec,"F2_CLIENTE"	,/*Tabela*/,cTitF2Cli	,/*Picture*/,cTamF2Cli  ,/*lPixel*/,{|| cCliente })
	TRCell():New(oCabec,"F2_LOJA"		,/*Tabela*/,cTitF2Loj	,/*Picture*/,/*Tamanho*/,/*lPixel*/,{||  cLoja})
	TRCell():New(oCabec,"A1_NOME"		,/*Tabela*/,cTitA1Nom	,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| cNome})
	TRCell():New(oCabec,"F2_EMISSAO"	,/*Tabela*/,cTitF2Emi	,/*Picture*/,cTamF2Emi  ,/*lPixel*/,{||  dEmissao})
	TRCell():New(oCabec,"F2_TIPO"		,/*Tabela*/,cTitF2Tip	,/*Picture*/,/*Tamanho*/,/*lPixel*/,{||  cTipo })

	oItens := TRSection():New(oCabec,STR0057,{"SF2","SD2","SB1"},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
	oItens:SkipLine(1)
	oItens:SetTotalInLine(.F.)
	TRCell():New(oItens,"CCOD"			,/*Tabela*/,STR0035					,/*Picture*/					,cTamD2Cod+2	,/*lPixel*/,{|| Alltrim(cCod)	},,.T.)
	TRCell():New(oItens,"CDESC"			,/*Tabela*/,STR0036					,/*Picture*/					,cTamB1Dsc		,/*lPixel*/,{|| Alltrim(cDesc)	},,.T.)
	TRCell():New(oItens,"NQUANT"		,/*Tabela*/,/*STR0037*/"Quant"		,cPicD2Qtd               		,cTamD2Qtd		,/*lPixel*/,{|| nQuant			},,,"RIGHT")
	TRCell():New(oItens,"NPRCVEN"		,/*Tabela*/,/*STR0038*/"Vlr.Unit"	,cPicD2Pvn                		,cTamD2PVn		,/*lPixel*/,{|| nPrcVen			},,,"RIGHT")
	TRCell():New(oItens,"NTOTAL"		,/*Tabela*/,/*STR0039*/"Vlr.Merc"	,cPicD2Tot               		,cTamD2Tot		,/*lPixel*/,{|| nTotal			},,,"RIGHT")
	// Coluna abaixo incluída para corrigir a impressão em PDF que estava sobrepondo caracteres no relatório
	TRCell():New(oItens,""				,/*Tabela*/,""						,"@!" 		 		           	,5				,/*lPixel*/,{||  "     "		})	
	TRCell():New(oItens,"CPEDIDO"		,/*Tabela*/,STR0043					,cPicD2Ped  		           	,cTamD2Ped+5	,/*lPixel*/,{|| Alltrim(cPedido)})
	TRCell():New(oItens,"CITEMPV"		,/*Tabela*/,STR0044					,cPicD2IPv                   	,cTamD2IPV		,/*lPixel*/,{|| Alltrim(cItemPV)})

	oReport:Section(1):SetUseQuery(.F.) // Novo compomente tReport para adcionar campos de usuario no relatorio qdo utiliza query    
	oReport:Section(2):SetUseQuery(.F.) // Novo compomente tReport para adcionar campos de usuario no relatorio qdo utiliza query
	oReport:Section(2):Section(1):SetUseQuery(.F.) // Novo compomente tReport para adcionar campos de usuario no relatorio qdo utiliza query

	Else

	oCabecF1 := TRSection():New(oReport,STR0061,{"SF1"},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
	oCabecF1:SetTotalInLine(.F.)
	TRCell():New(oCabecF1,"CCLIENTE"	,/*Tabela*/,RetTitle("F2_CLIENTE"	),/*Picture*/, 50		 ,/*lPixel*/,{|| Substr(cCliente,1,TamSx3("F2_CLIENTE")[01])})
	TRCell():New(oCabecF1,"CLOJA"		,/*Tabela*/,RetTitle("F2_LOJA"		),/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| cLoja 		})
	TRCell():New(oCabecF1,"CNOME"		,/*Tabela*/,RetTitle("A1_NOME"		),/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| cNome 		})
 	TRCell():New(oCabecF1,"CEMISSAO"	,/*Tabela*/,RetTitle("F2_EMISSAO"	),/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| dEmissao 	})
	TRCell():New(oCabecF1,"CTIPO"		,/*Tabela*/,RetTitle("F2_TIPO"		),/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| cTipo 		})


	oCabecF2 := TRSection():New(oReport,STR0062,{"SF2"},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
	oCabecF2:SetTotalInLine(.F.)
	TRCell():New(oCabecF2,"CCLIENTE"	,/*Tabela*/,RetTitle("F2_CLIENTE"	),/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| Substr(cCliente,1,TamSx3("F2_CLIENTE")[01])})
	TRCell():New(oCabecF2,"CLOJA"		,/*Tabela*/,RetTitle("F2_LOJA"		),/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| cLoja 		})
	TRCell():New(oCabecF2,"CNOME"		,/*Tabela*/,RetTitle("A1_NOME"		),/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| cNome 		})
 	TRCell():New(oCabecF2,"CEMISSAO"	,/*Tabela*/,RetTitle("F2_EMISSAO"	),/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| dEmissao 	})
	TRCell():New(oCabecF2,"CTIPO"		,/*Tabela*/,RetTitle("F2_TIPO"		),/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| cTipo 		})


    // Analitico SD1
	oItensD1 := TRSection():New(oReport,STR0063,{"SD1"},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
	oItensD1:SetTotalInLine(.F.)
	TRCell():New(oItensD1,"CCOD"		,/*Tabela*/,RetTitle("D2_COD" 		)	,/*Picture*/					,TamSX3("D2_COD"	)[1]	,/*lPixel*/,{|| cCod		},,.T.)
	TRCell():New(oItensD1,"CDESC"		,/*Tabela*/,RetTitle("B1_DESC"		)	,/*Picture*/					,TamSX3("B1_DESC"	)[1]	,/*lPixel*/,{|| cDesc		},,.T.)
	TRCell():New(oItensD1,"PEDIDO"		,/*Tabela*/,RetTitle("D2_PEDIDO"	)	,/*Picture*/					,TamSX3("D2_PEDIDO"	)[1]	,/*lPixel*/,{|| cPedido		})
	TRCell():New(oItensD1,"ITEM"		,/*Tabela*/,RetTitle("D2_ITEM"		)	,/*Picture*/					,TamSX3("D2_ITEM"	)[1]	,/*lPixel*/,{|| cItemPV		})
	TRCell():New(oItensD1,"NQUANT"		,/*Tabela*/,RetTitle("D2_QUANT"		)	,cPicD2Qtd 						,TamSX3("D2_QUANT"	)[1]	,/*lPixel*/,{|| nQuant		},,,"RIGHT")
	TRCell():New(oItensD1,"NPRCVEN"		,/*Tabela*/,RetTitle("D2_PRCVEN"	)	,PesqPict("SD2","D2_PRCVEN"	)	,TamSX3("D2_PRCVEN"	)[1]	,/*lPixel*/,{|| nPrcVen		},,,"RIGHT")
	TRCell():New(oItensD1,"NTOTAL"		,/*Tabela*/,STR0039						,PesqPict("SD2","D2_TOTAL"	)	,TamSX3("D2_TOTAL"	)[1]	,/*lPixel*/,{|| nTotal		},,,"RIGHT")
	TRCell():New(oItensD1,"NTOTCIMP"	,/*Tabela*/,RetTitle("D2_TOTAL"		)	,PesqPict("SD2","D2_TOTAL"	)	,TamSX3("D2_TOTAL"	)[1]	,/*lPixel*/,{|| nTotcImp 	},,,"RIGHT")


    // Analitico SD2
	oItensD2 := TRSection():New(oReport,STR0064,{"SD2"},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
	oItensD2:SetTotalInLine(.F.)
	TRCell():New(oItensD2,"CCOD"		,/*Tabela*/,RetTitle("D2_COD"		)	,/*Picture*/					,TamSX3("D2_COD"	)[1]	,/*lPixel*/,{|| cCod		},,.T.)
	TRCell():New(oItensD2,"CDESC"		,/*Tabela*/,RetTitle("B1_DESC"		)	,/*Picture*/					,TamSX3("B1_DESC"	)[1]	,/*lPixel*/,{|| cDesc		},,.T.)
	TRCell():New(oItensD2,"PEDIDO"		,/*Tabela*/,RetTitle("D2_PEDIDO"	)	,/*Picture*/					,TamSX3("D2_PEDIDO"	)[1]	,/*lPixel*/,{|| cPedido		})
	TRCell():New(oItensD2,"ITEM"		,/*Tabela*/,RetTitle("D2_ITEM"		)	,/*Picture*/					,TamSX3("D2_ITEM"	)[1]	,/*lPixel*/,{|| cItemPV		})
	TRCell():New(oItensD2,"NQUANT"		,/*Tabela*/,RetTitle("D2_QUANT"		)	,cPicD2Qtd 						,TamSX3("D2_QUANT"	)[1]	,/*lPixel*/,{|| nQuant		},,,"RIGHT")
	TRCell():New(oItensD2,"NPRCVEN"		,/*Tabela*/,RetTitle("D2_PRCVEN"	)	,PesqPict("SD2","D2_PRCVEN"	)	,TamSX3("D2_PRCVEN"	)[1]	,/*lPixel*/,{|| nPrcVen		},,,"RIGHT")
		If cPaisLoc == "MEX" .AND. SD2->(FieldPos("D2_VALADI")) > 0
		TRCell():New(oItensD2,"NVALADI"	,/*Tabela*/,RetTitle("D2_VALADI"	)	,PesqPict("SD2","D2_VALADI"	)	,TamSX3("D2_VALADI"	)[1]	,/*lPixel*/,{|| nValadi		},,,"RIGHT")
		EndIf
	TRCell():New(oItensD2,"NTOTAL"		,/*Tabela*/,STR0039						,PesqPict("SD2","D2_TOTAL"	)	,TamSX3("D2_TOTAL"	)[1]	,/*lPixel*/,{|| nTotal		},,,"RIGHT")
	TRCell():New(oItensD2,"NTOTCIMP"	,/*Tabela*/,RetTitle("D2_TOTAL"		)	,PesqPict("SD2","D2_TOTAL"	)	,TamSX3("D2_TOTAL"	)[1]	,/*lPixel*/,{|| nTotcImp 	},,,"RIGHT")

         
    // Total Geral
   	oTotGer := TRSection():New(oReport,STR0060,{"SF2","SD2"},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
	oTotGer:SetTotalInLine(.F.)
	oTotGer:SetEdit(.F.)

	TRCell():New(oTotGer,"CCOD"			,/*Tabela*/,RetTitle("D2_COD"		)	,/*Picture*/					,TamSX3("D2_COD"	)[1]	,/*lPixel*/,/*{|| code-block de impressao }*/	)
	TRCell():New(oTotGer,"CDESC"		,/*Tabela*/,RetTitle("B1_DESC"		)	,/*Picture*/					,TamSX3("B1_DESC"	)[1]	,/*lPixel*/,/*{|| code-block de impressao }*/	)
	TRCell():New(oTotGer,"PEDIDO"		,/*Tabela*/,RetTitle("D2_PEDIDO"	)	,/*Picture*/					,TamSX3("D2_PEDIDO"	)[1]	,/*lPixel*/,/*{|| code-block de impressao }*/	)
	TRCell():New(oTotGer,"ITEM"			,/*Tabela*/,RetTitle("D2_ITEM"		)	,/*Picture*/					,TamSX3("D2_ITEM"	)[1]	,/*lPixel*/,/*{|| code-block de impressao }*/	)
	TRCell():New(oTotGer,"NACG1"		,/*Tabela*/,RetTitle("D2_QUANT"	)	,cPicD2Qtd							,TamSX3("D2_QUANT"	)[1]	,/*lPixel*/,{|| nACG1},,,"RIGHT"				)
	TRCell():New(oTotGer,"NPRCVEN"		,/*Tabela*/,RetTitle("D2_PRCVEN")	,PesqPict("SD2","D2_PRCVEN"	)		,TamSX3("D2_PRCVEN"	)[1]	,/*lPixel*/,/*{|| code-block de impressao}*/	)

		If cPaisLoc == "MEX"
		TRCell():New(oTotGer,"NACGADI"	,/*Tabela*/,RetTitle("D2_VALADI")	,PesqPict("SD2","D2_VALADI"	)		,TamSX3("D2_VALADI"	)[1]	,/*lPixel*/,{|| nAcGAdi}	)
		EndIf

	TRCell():New(oTotGer,"NACG2"		,/*Tabela*/,STR0039					,PesqPict("SD2","D2_TOTAL"	)		,TamSX3("D2_TOTAL"	)[1]	,/*lPixel*/,{|| nACG2},,,"RIGHT"				)
	TRCell():New(oTotGer,"NTOTNETGER"	,/*Tabela*/,STR0054					,PesqPict("SD2","D2_TOTAL"	)		,TamSX3("D2_TOTAL"	)[1]	,/*lPixel*/,{|| nTotNetGer},,,"RIGHT"			)	

	EndIf

Return(oReport)

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ReportPrin³ Autor ³Marco Bianchi          ³ Data ³05/06/2006³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³A funcao estatica ReportDef devera ser criada para todos os ³±±
±±³          ³relatorios que poderao ser agendados pelo usuario.          ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³Nenhum                                                      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ExpO1: Objeto Report do Relatório                           ³±±
±±³          ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³   DATA   ³ Programador   ³Manutencao efetuada                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³          ³               ³                                            ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function ReportPrint(oReport,cAliasQry,oSintetico,oItens,oItensD1,oItensD2,oCabec,oCabecF1,oCabecF2,oTotDia)

Local cPicD2Qtd := "@E 999999999999999999.99"
Local cPicD2Tot := PesqPict("SD2","D2_TOTAL")	

	If ( cPaisLoc#"BRA" )

	TRFunction():New(oItensD1:Cell("NQUANT"),    /* cID */,"SUM",/*oBreak*/,STR0037,cPicD2Qtd					 ,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)  
	TRFunction():New(oItensD1:Cell("NTOTAL"),    /* cID */,"SUM",/*oBreak*/,STR0039,PesqPict("SD2","D2_TOTAL"	),/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)  
	TRFunction():New(oItensD1:Cell("NTOTCIMP"),  /* cID */,"SUM",/*oBreak*/,STR0047,PesqPict("SD2","D2_VALISS"	),/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)  

	TRFunction():New(oItensD2:Cell("NQUANT"),    /* cID */,"SUM",/*oBreak*/,STR0037,cPicD2Qtd					 ,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)
		If cPaisLoc == "MEX"
		TRFunction():New(oItensD2:Cell("NVALADI"),/* cID */,"SUM",/*oBreak*/,RetTitle("D2_VALADI"),PesqPict("SD2","D2_VALADI"	),/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)  
		EndIf
	TRFunction():New(oItensD2:Cell("NTOTAL"),    /* cID */,"SUM",/*oBreak*/,STR0039,PesqPict("SD2","D2_TOTAL"	),/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)  
	TRFunction():New(oItensD2:Cell("NTOTCIMP"),  /* cID */,"SUM",/*oBreak*/,STR0047,PesqPict("SD2","D2_VALISS"	),/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)  


	oReport:SetTotalInLine(.F.)

	TRImpLocTop(oReport,cAliasQry)

	Else
		If mv_par17 == 1

			TRFunction():New(oItens:Cell("NQUANT"),   /* cID */,"SUM",/*oBreak*/,STR0037,cPicD2Qtd ,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)  
			TRFunction():New(oItens:Cell("NTOTAL"),   /* cID */,"SUM",/*oBreak*/,STR0039,cPicD2Tot ,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)  
			oReport:SetTotalInLine(.F.)
			TRImpAna(oReport,cAliasQry,oItens,oCabec,oTotDia)   

		EndIf
	EndIf

Return

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ TRImpAna ³ Autor ³ Marco Bianchi         ³ Data ³ 07/06/06 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Imprime Relatorio Analitico (Base Brasil).                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATR550 - R4		                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

Static Function TRImpAna(oReport,cAliasQry,oItens,oCabec,oTotDia)

	Local nAcD1		:= 0
	Local nAcD2		:= 0
	Local nAcD3		:= 0
	Local nAcD4		:= 0
	Local nAcD5		:= 0
	Local nAcD6		:= 0
	Local nAcD7		:= 0
	Local dEmisAnt	:= CtoD(Space(08))
	Local nReg     	:= 0
	Local nTotQuant	:= 0
	Local nTotal   	:= 0
	Local nTotIcm  	:= 0
	Local nTotIPI  	:= 0
	Local nTotRet		:= 0
	Local nTotRetIt	:= 0
	Local cNumPed  	:= ""
	Local cMascara 	:= GetMv("MV_MASCGRD")
	Local nTamRef  	:= Val(Substr(cMascara,1,2))
	Local dEmiDia 	:= dDataBase
	Local nFrete  	:= 0
	Local nIcmAuto	:= 0
	Local nSeguro 	:= 0
	Local nDespesa	:= 0
	Local nValIPI 	:= 0
	Local nValICM 	:= 0
	Local nValISS 	:= 0
	Local nVlrISS	:= 0
	Local cNForObf 	:= ""
	Local cNCliObf 	:= ""
	Local cTipoNF 	:= 0
	Local lFirst		:= .F.
	Local cSelect		:= ""
	Local cIdWhere	:= ""
	Local cFilSA1 	:= xFilial("SA1")
	Local cFilSA2 	:= xFilial("SA2")
	Local cFilSF2 	:= xFilial("SF2")
	Local cFilSD2 	:= xFilial("SD2")
	Local cFilSB1 	:= xFilial("SB1")
	Local cFilSA7 	:= xFilial("SA7")
	Local nTamD2_TOTAL  := TAMSX3("D2_TOTAL")[2]
	Local nTamD2_PRCVEN := TAMSX3("D2_PRCVEN")[2]

	TrataFilt(@oReport, 2)

	oReport:Section(2):Cell("F2_CLIENTE"):SetBlock({|| cCliente})
	oReport:Section(2):Cell("F2_LOJA"):SetBlock({|| cLoja})
	oReport:Section(2):Cell("A1_NOME"):SetBlock({|| cNome})
	oReport:Section(2):Cell("F2_EMISSAO"):SetBlock({|| dEmissao})
	oReport:Section(2):Cell("F2_TIPO"):SetBlock({|| cTipo})

	oReport:Section(2):Section(1):Cell("CCOD"):SetBlock({|| cCod})
	oReport:Section(2):Section(1):Cell("CDESC"):SetBlock({|| cDesc})
	oReport:Section(2):Section(1):Cell("NQUANT"):SetBlock({|| nQuant})
	oReport:Section(2):Section(1):Cell("NPRCVEN"):SetBlock({|| nPrcVen})
	oReport:Section(2):Section(1):Cell("NTOTAL"):SetBlock({|| xMoeda((cAliasQry)->D2_TOTAL, 1, MV_PAR13, (cAliasQry)->D2_EMISSAO, nTamD2_TOTAL)})
	oReport:Section(2):Section(1):Cell("CPEDIDO"):SetBlock({|| cPedido})
	oReport:Section(2):Section(1):Cell("CITEMPV"):SetBlock({|| cItemPV})

	oReport:Section(3):Cell("CCOD")
	oReport:Section(3):Cell("CDESC")

	oReport:Section(3):Cell("NPRCVEN")
	oReport:Section(3):Cell("CPEDIDO")
	oReport:Section(3):Cell("CITEMPV")

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Filtragem do relatório                                                  ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Query do relatório da secao 1 - SINTETICO                               ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cAliasSD2	:= cAliasQry
	cWhere		:= "%"
	If MV_PAR15 == 2
		cWhere	+= "AND F2_TIPO<>'D'"
	EndIf
	cWhere		+= " AND NOT (" + IsRemito(2,"F2_TIPODOC") + ")"
	cWhere		+="%"

	cSelect	:= "%"
	cSelect	+= IIf(SerieNfId("SF2",3,"F2_SERIE")<>"F2_SERIE", ", F2_SDOC,D2_SDOC ", "")
	cSelect	+= "%"

	cIDWhere	:= "%"
	cIDWhere	+= SerieNfId("SF2",3,"F2_SERIE") + " >= '" + mv_par06 + "'"
	cIDWhere	+= "AND " + SerieNfId("SF2",3,"F2_SERIE") + " <= '" + mv_par07 + "'"
	cIDWhere	+= "%"

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Transforma parametros Range em expressao SQL                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	MakeSqlExpr(oReport:uParam)

	oReport:Section(2):BeginQuery()
	BeginSql Alias cAliasQry
	SELECT F2_DOC,F2_SERIE,F2_EMISSAO,F2_TIPO,F2_ICMSRET,F2_CLIENTE,F2_LOJA,
	       F2_FRETE,F2_FRETAUT,F2_ICMAUTO,F2_VALBRUT,F2_VALIPI,F2_VALICM,F2_VALISS,
	       D2_DOC,D2_SERIE,D2_COD,D2_GRUPO,D2_TP,D2_TIPO,D2_CLIENTE,D2_LOJA,D2_GRADE,
	       D2_CF,D2_TES,D2_LOCAL,D2_PRCVEN,D2_ICMSRET,D2_QUANT,D2_TOTAL,D2_EMISSAO,
	       D2_VALIPI,D2_CODISS,D2_VALISS,D2_VALICM,D2_ITEM,F2_FRETE,F2_SEGURO,F2_DESPESA, D2_GRADE,D2_PEDIDO, D2_ITEMPV,
	       B1_DESC, A1_NOME, A1_COD, A1_LOJA, F4_INCSOL, F4_AGREG, F4_ICM, F4_ISS %Exp:cSelect%
	  FROM %Table:SD2% SD2, %Table:SB1% SB1, %Table:SF4% SF4, %Table:SF2% SF2
	       LEFT JOIN %Table:SA1% SA1 ON A1_FILIAL	= %xFilial:SA1%
	                                AND A1_COD = F2_CLIENTE
	                                AND A1_LOJA = F2_LOJA
	                                AND SA1.%notdel%
	 WHERE F2_FILIAL = %xFilial:SF2%
	   AND F2_DOC >= %Exp:mv_par01%
	   AND F2_DOC <= %Exp:mv_par02%
	   AND F2_EMISSAO >= %Exp:DtoS(mv_par03)%
	   AND F2_EMISSAO <= %Exp:DtoS(mv_par04)%
	   AND %Exp:cIdWhere%
	   AND SF2.%notdel%
	   AND D2_FILIAL = %xFilial:SD2%
	   AND D2_CLIENTE = F2_CLIENTE
	   AND D2_LOJA = F2_LOJA
	   AND D2_DOC = F2_DOC
	   AND D2_SERIE = F2_SERIE
	   AND SD2.%notdel%
	   AND B1_FILIAL = %xFilial:SB1%
	   AND B1_COD = D2_COD
	   AND SB1.%notdel%
	   AND F4_FILIAL = %xFilial:SF4%
	   AND F4_CODIGO = D2_TES
	   AND SF4.%notdel%
	   %Exp:cWhere%
	   ORDER BY SF2.F2_EMISSAO,SF2.F2_DOC,SF2.F2_SERIE,SD2.D2_ITEM
	   
	EndSql
	//ORDER BY SF2.F2_EMISSAO,SF2.F2_DOC,SF2.F2_SERIE,SD2.D2_COD,SD2.D2_ITEM

    _cFile := "c:\temp\Query_" + Dtos(dDatabase) + "_" + StrTran(Time(),":","") + ".TXT"
	MemoWrite(_cFile, GetLastQuery()[2])

	oReport:Section(2):EndQuery({mv_par16,mv_par05,mv_par10,mv_par11})

	TRPosition():New(oReport:Section(2),"SA1",1,{|| cFilSA1 + (cAliasQry)->F2_CLIENTE + (cAliasQry)->F2_LOJA})
	TRPosition():New(oReport:Section(2),"SD2",3,{|| cFilSD2 + (cAliasQry)->F2_DOC + (cAliasQry)->F2_SERIE + (cAliasQry)->F2_CLIENTE + (cAliasQry)->F2_LOJA + (cAliasQry)->D2_COD + (cAliasQry)->D2_ITEM})
	TRPosition():New(oReport:Section(2),"SF2",1,{|| cFilSF2 + (cAliasQry)->F2_DOC + (cAliasQry)->F2_SERIE + (cAliasQry)->F2_CLIENTE + (cAliasQry)->F2_LOJA})
	TRPosition():New(oReport:Section(2):Section(1),"SB1",1,{|| cFilSB1 + (cAliasQry)->D2_COD})
	TRPosition():New(oReport:Section(2):Section(1),"SD2",3,{|| cFilSD2 + (cAliasQry)->F2_DOC + (cAliasQry)->F2_SERIE + (cAliasQry)->F2_CLIENTE + (cAliasQry)->F2_LOJA + (cAliasQry)->D2_COD + (cAliasQry)->D2_ITEM})
	TRPosition():New(oReport:Section(2):Section(1),"SF2",1,{|| cFilSF2 + (cAliasQry)->F2_DOC + (cAliasQry)->F2_SERIE + (cAliasQry)->F2_CLIENTE + (cAliasQry)->F2_LOJA})

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Inicio da impressao do fluxo do relatório                               ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	oReport:SetMeter((cAliasQry)->(LastRec()))
	dbSelectArea(cAliasQry)
	nAcN1	:= 0
	nAcN2	:= 0
	nAcN3	:= 0
	nAcN4	:= 0
	nAcN5	:= 0
	nAcN6	:= 0

	While !oReport:Cancel() .And. !(cAliasQry)->(Eof())

		IF (cAliasQry)->F2_TIPO $ "BD"
			dbSelectArea("SA2")
			dbSetOrder(1)
			dbSeek(cFilSA2+(cAliasQry)->F2_CLIENTE+(cAliasQry)->F2_LOJA)
			oCabec:Cell("F2_CLIENTE"):SetTitle("Fornecedor")
			cNome := SA2->A2_NOME
			If Empty(cNForObf) .And. FATPDIsObfuscate("A2_NOME")
				cNForObf := FATPDObfuscate(cNome)
			EndIf
			If !Empty(cNForObf)
				cNome := cNForObf
			EndIf
		else
			oCabec:Cell("F2_CLIENTE"):SetTitle("Cliente")
			cNome := (cAliasQry)->A1_NOME
			If Empty(cNCliObf) .And. FATPDIsObfuscate("A1_NOME")
				cNCliObf := FATPDObfuscate(cNome)
			EndIf
			If !Empty(cNCliObf)
				cNome := cNCliObf
			EndIf
		EndIf

		dbSelectArea(cAliasQry)

		nTotRet	:= 0
		nTotRetIt	:= 0
		nCt			:= 1
		dEmisAnt	:= (cAliasQry)->F2_EMISSAO
		cNota		:= (cAliasQry)->F2_DOC
		cSerie		:= (cAliasQry)->F2_SERIE
		cSerieView	:= Alltrim((cAliasQry)->&(SerieNfId("SF2",3,"F2_SERIE")))
		nFrete		:= (cAliasQry)->F2_FRETE
		nICMSRet	:= (cAliasQry)->F2_ICMSRET
		nFretAut	:= (cAliasQry)->F2_FRETAUT
		nIcmAuto	:= (cAliasQry)->F2_ICMAUTO
		nSeguro	:= (cAliasQry)->F2_SEGURO
		nDespesa	:= (cAliasQry)->F2_DESPESA
		nValIPIF2	:= (cAliasQry)->F2_VALIPI
		nValICMF2	:= (cAliasQry)->F2_VALICM
		nValISSF2	:= (cAliasQry)->F2_VALISS
		cTipoNF	:= (cAliasQry)->F2_TIPO
		dEmissao	:= (cAliasQry)->F2_EMISSAO
		cTipo		:= (cAliasQry)->F2_TIPO
		cCliente	:= (cAliasQry)->F2_CLIENTE
		cLoja		:= (cAliasQry)->F2_LOJA

		oReport:Section(2):Init()
		oReport:Section(2):Section(1):Init()

		lFirst := .T.

		While (cAliasQry)->(! Eof()) .AND. (cAliasQry)->D2_DOC == cNota .AND. (cAliasQry)->D2_SERIE == cSerie

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Valida o produto conforme a mascara       ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			lRet := ValidMasc((cAliasQry)->D2_COD,MV_PAR08)
			If !lRet
				(cAliasQry)->(dBSkip())
				Loop
			Endif

			cNumPed  := (cAliasQry)->D2_PEDIDO
			nTotQuant:= 0
			nTotal   := 0
			nTotICM  := 0
			nTotIPI  := 0
			nTotRetIt:= 0

			If (cAliasQry)->F4_INCSOL == "S"
				nTotRet	  += (cAliasQry)->D2_ICMSRET
				nTotRetIt := (cAliasQry)->D2_ICMSRET
			Endif

			nReg := 0
			dbSelectArea(cAliasQry)
			If (cAliasQry)->D2_GRADE == "S" .And. MV_PAR09 == 1
				cProdRef := Substr((cAliasQry)->D2_COD,1,nTamRef)
				While (cAliasQry)->(! Eof()) .And. cProdRef == Substr((cAliasQry)->D2_COD,1,nTamRef) .And. (cAliasQry)->D2_GRADE == "S" .And. cNumPed == (cAliasQry)->D2_PEDIDO
					nTotQuant	+= (cAliasQry)->D2_QUANT
					nTotal		+= (cAliasQry)->D2_TOTAL
					nTotIPI	+= (cAliasQry)->D2_VALIPI

					If ((Empty((cAliasQry)->D2_CODISS) .And. (cAliasQry)->D2_VALISS == 0) .Or.;	// ISS
						(!Empty((cAliasQry)->D2_CODISS) .And. (cAliasQry)->F4_ISS <> "S" .And. (cAliasQry)->D2_VALISS == 0))
						nTotIcm	+= (cAliasQry)->D2_VALICM
					EndIf
					nReg	:= (cAliasQry)->(Recno())
					(cAliasQry)->(dbSkip())

					//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
					//³ Valida o produto conforme a mascara       ³
					//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
					lRet := ValidMasc((cAliasQry)->D2_COD,MV_PAR08)
					If ! lRet
						(cAliasQry)->(dbSkip())
					Endif

				EndDo

				nAcN1 += nTotQuant

				If (cAliasQry)->F4_AGREG <> "N"
					nAcN2 += xMoeda(nTotal,1,MV_PAR13,(cAliasQry)->D2_EMISSAO)
					If (cAliasQry)->F4_AGREG == "D"
						nAcN2 -= xMoeda(nTotICM,1,MV_PAR13,(cAliasQry)->D2_EMISSAO)
					EndIf
				EndIf

				nAcN4 += xMoeda(nTotICM,1,MV_PAR13,(cAliasQry)->D2_EMISSAO)
				nAcN5 += xMoeda(nTotIPI,1,MV_PAR13,(cAliasQry)->D2_EMISSAO)

				cCod	:= (cAliasQry)->D2_COD
				If mv_par12 == 1
					cDesc := (cAliasQry)->B1_DESC
				Else
					SA7->(dBSetOrder(2))
					If SA7->(dBSeek(cFilSA7+(cAliasQry)->D2_COD+(cAliasQry)->F2_CLIENTE+(cAliasQry)->F2_LOJA))
						cDesc := SA7->A7_DESCCLI
					Else
						cDesc := (cAliasQry)->B1_DESC
					Endif
				Endif

				dbSelectArea(cAliasQry)
				nQuant		:= (cAliasQry)->D2_QUANT
				nPrcVen	:= xMoeda((cAliasQry)->D2_PRCVEN,1,MV_PAR13,(cAliasQry)->D2_EMISSAO)
				cLocal		:= (cAliasQry)->D2_LOCAL
				nAcN2		:= xMoeda((cAliasQry)->D2_TOTAL,1,MV_PAR13,(cAliasQry)->D2_EMISSAO)
				cCF			:= (cAliasQry)->D2_CF
				cTes		:= (cAliasQry)->D2_TES
				cPedido	:= (cAliasQry)->D2_PEDIDO
				cItemPV	:= (cAliasQry)->D2_ITEMPV
				nVlrISS	:= xMoeda(nValISS,1,MV_PAR13,dEmiDia)

				If lRet .And. lFirst
					oReport:Section(2):PrintLine()
					lFirst := .F.
				Endif

				oReport:Section(2):Section(1):PrintLine()

			Else

				cCod	:= (cAliasQry)->D2_COD
				If mv_par12 == 1
					cDesc := (cAliasQry)->B1_DESC
				Else
					SA7->(dBSetOrder(2))
					If SA7->(dBSeek(cFilSA7+(cAliasQry)->D2_COD+(cAliasQry)->F2_CLIENTE+(cAliasQry)->F2_LOJA))
						cDesc := SA7->A7_DESCCLI
					Else
						cDesc := (cAliasQry)->B1_DESC
					Endif
				Endif

				nQuant		:= (cAliasQry)->D2_QUANT
				nPrcVen	:= xMoeda((cAliasQry)->D2_PRCVEN,1,MV_PAR13,(cAliasQry)->D2_EMISSAO, nTamD2_PRCVEN)
				cLocal		:= (cAliasQry)->D2_LOCAL
				nTotal		:= xMoeda((cAliasQry)->D2_TOTAL,1,MV_PAR13,(cAliasQry)->D2_EMISSAO, nTamD2_TOTAL)
				cCF			:= (cAliasQry)->D2_CF
				cTes		:= (cAliasQry)->D2_TES
				cPedido	:= (cAliasQry)->D2_PEDIDO
				cItemPV	:= (cAliasQry)->D2_ITEMPV
				nValIpi	:= xMoeda((cAliasQry)->D2_VALIPI,1,MV_PAR13,(cAliasQry)->D2_EMISSAO)
				nValIcm	:= IIf((cAliasQry)->F4_ICM == "S", xMoeda((cAliasQry)->D2_VALICM, 1, MV_PAR13, (cAliasQry)->D2_EMISSAO), 0)
				nVlrISS	:= IIf((cAliasQry)->F4_ISS == "S", xMoeda((cAliasQry)->D2_VALISS, 1, MV_PAR13, dEmiDia),                 0)

				If lRet .And. lFirst
					oReport:Section(2):PrintLine()
					lFirst := .F.
				Endif

				oReport:Section(2):Section(1):PrintLine()

				nAcN1 += (cAliasQry)->D2_QUANT

				If (cAliasQry)->F4_AGREG <> "N"
					nAcN2 += xMoeda((cAliasQry)->D2_TOTAL, 1, MV_PAR13, (cAliasQry)->D2_EMISSAO, nTamD2_TOTAL)
					If (cAliasQry)->F4_AGREG = "D"
						nAcN2 -= xMoeda((cAliasQry)->D2_VALICM, 1, MV_PAR13, (cAliasQry)->D2_EMISSAO)
					EndIf
				Endif

				If ((Empty((cAliasQry)->D2_CODISS) .And. (cAliasQry)->D2_VALISS == 0) .Or.;	// ISS
					(!Empty((cAliasQry)->D2_CODISS) .And. (cAliasQry)->F4_ISS <> "S" .And. (cAliasQry)->D2_VALISS == 0))
					nAcN4 += xMoeda((cAliasQry)->D2_VALICM, 1, MV_PAR13, (cAliasQry)->D2_EMISSAO)
				EndIf

				nAcN5 += xMoeda((cAliasQry)->D2_VALIPI, 1, MV_PAR13, (cAliasQry)->D2_EMISSAO)

			Endif
			dEmiDia := (cAliasQry)->D2_EMISSAO

			dbSelectArea(cAliasQry)
			If nReg == 0
				(cAliasQry)->(dBSkip())
			Endif

		EndDo

		nAcN3 := 0
		If (nAcN2 + nAcN4 + nAcN5) # 0

			oReport:Section(2):Section(1):SetTotalText(STR0048 + Alltrim(cNota) + "/" + cSerieVIEW)
			oReport:Section(2):Section(1):Finish()

			nAcN3 += nFretAut

			If (nICMSRet > 0) .Or. (nICMAuto > 0) .Or. (nAcN3 != 0 .Or. nFretAut != 0)
				oReport:SkipLine(1)
			EndIf
		EndIf

		nAcD1 += nAcN1
		nAcD2 += IIF(cTipoNF $ "IP",0,nAcN2)
		nAcD3 += nAcN3
		nAcD4 += nAcN4
		nAcD5 += nAcN5
		nAcD6 += IIF(cTipoNF $ "IP",0,nAcN6)
		nAcD7 += nVlrISS

		nAcn1		:= 0
		nAcn2		:= 0
		nAcn3		:= 0
		nAcn4		:= 0
		nAcn5		:= 0
		nAcn6		:= 0
		nVlrISS		:= 0

		oReport:IncMeter()
		oReport:SkipLine()
		oReport:SkipLine()

		oReport:PrintText("Prefixo    Numero      Parcela                    Valor         Emissao        Vencimento"		,,)
		oReport:SkipLine()
		oReport:FatLine()

		dbSelectArea("SE1")
		dbSetOrder(1)
		If dbSeek(FwFilial("SE1") + cSerie + cNota )
			While (SE1->( ! Eof()) .And. SE1->(E1_FILIAL + E1_PREFIXO + E1_NUM ) == FwFilial("SE1") + cSerie + cNota )
				oReport:PrintText( SE1->E1_PREFIXO 	+ Space(08) + SE1->E1_NUM + Space(07) + SE1->E1_PARCELA + Space(06) + Transform(SE1->E1_SALDO, PesqPict("SE1", "E1_SALDO")) + Space(07) + Dtoc(SE1->E1_EMISSAO) + Space(07) + Dtoc(SE1->E1_VENCREA))
				SE1->(dbSkip())
			EndDo
		Endif

		oReport:SkipLine(5)
		oReport:PrintText("Nome Completo (Legivel) : ______________________________________________________________________________________________________________________________________")  
		oReport:SkipLine(3)
		oReport:PrintText("CPF.: __________________________________________________________________________________________________________________________________________________________")  
		oReport:SkipLine(3)
		oReport:PrintText("Assinatura.: ___________________________________________________________________________________________________________________________________________________")  
		oReport:Section(2):SetPageBreak(.T.)
		oReport:Section(2):Finish()
		
		// Força a Quebra de Pagina 
		If oReport:PageBreak() == .F.
			oReport:Section(2):SetPageBreak(.T.)
			oReport:nRow := 374
		Endif	

	EndDo
	
Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³TRImpLocTop³ Autor ³ Marco Bianchi        ³ Data ³ 07/06/06 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Impressao do Relatorio (Base Localizada - Top)             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATR550 - R4                                               ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function TRImpLocTop(oReport,cAliasQry)

	Local nCt			:= 0
	Local lContinua		:= .T.
	Local dEmisAnt		:= CtoD(Space(08))
	Local cExpTot		:= ""
	Local cSelect		:= ""
	Local cSelectUni	:= ""
	Local cExp2			:= ""
	Local cIdWhere		:= ""
	Local cIdWhereU		:= ""
	Local nY			:= 0
	Local cSCpo			:= ""
	Local cCpoSD2		:= ""
	Local cCpoSD1		:= ""
	Local cCamposD2		:= ""
	Local cCamposD1		:= ""

	Private aImpostos	:= {}
	Private cAliasSF2 	:= ""
	Private cAliasSF1 	:= ""
	Private cAliasSD1 	:= ""
	Private cAliasSD2 	:= ""
	Private nFrete   	:= 0
	Private nFretAut 	:= 0
	Private nSeguro  	:= 0
	Private nDespesa 	:= 0
	Private nMoeda   	:= 0
	Private nTxMoeda 	:= 0
	Private nDecs		:= MsDecimais(mv_par13)
	Private nTamA1COD	:= TamSx3("A1_COD")[01]

	oReport:Section(1):Cell("CCLIENTE"	):SetBlock({|| Substr(cCliente,1,nTamA1COD)})
	oReport:Section(1):Cell("CLOJA"		):SetBlock({|| cLoja})
	oReport:Section(1):Cell("CNOME"		):SetBlock({|| cNome})
	oReport:Section(1):Cell("CEMISSAO"	):SetBlock({|| dEmissao})
	oReport:Section(1):Cell("CTIPO"		):SetBlock({|| cTipo})

	oReport:Section(2):Cell("CCLIENTE"	):SetBlock({|| Substr(cCliente,1,nTamA1COD)})
	oReport:Section(2):Cell("CLOJA"		):SetBlock({|| cLoja})
	oReport:Section(2):Cell("CNOME"		):SetBlock({|| cNome})
	oReport:Section(2):Cell("CEMISSAO"	):SetBlock({|| dEmissao})
	oReport:Section(2):Cell("CTIPO"		):SetBlock({|| cTipo})

	//oReport:Section(5):Cell("NACG1"		):SetBlock({|| nAcG1})
	//oReport:Section(5):Cell("NACG2"		):SetBlock({|| nAcG2})

	If cPaisLoc == "MEX"
		oReport:Section(5):Cell("NACGADI"):SetBlock({|| nAcGADI})
	EndIf

	//oReport:Section(5):Cell("NACGIMPINC"	):SetBlock({|| nAcGImpInc})
	//oReport:Section(5):Cell("NACGIMPNOINC"	):SetBlock({|| nAcGImpNoInc})
	oReport:Section(5):Cell("NTOTNETGER"	):SetBlock({|| nTotNetGer})

	//oReport:Section(6):Cell("NACD1"		):SetBlock({|| nAcD1})
	//oReport:Section(6):Cell("NACD2"		):SetBlock({|| nAcD2})

	If cPaisLoc == "MEX"
		oReport:Section(6):Cell("NACDADI"	):SetBlock({|| nAcDAdi})
	EndIf

	oReport:Section(6):Cell("NTOTDIA"	):SetBlock({|| nTotDia})

	If mv_par17 == 2
		oReport:Section(3):SetHeaderSection(.F.)	// Desabilita Impressao Cabecalho no Topo da Pagina
		oReport:Section(4):SetHeaderSection(.T.)	// Desabilita Impressao Cabecalho no Topo da Pagina
		oReport:Section(3):Disable()
		oReport:Section(4):Hide()

		oReport:Section(4):Acell[1]:SetTitle(Space(Len(oReport:Section(4):Acell[1]:GETTEXT())))
		oReport:Section(4):Acell[2]:SetTitle(Space(Len(oReport:Section(4):Acell[2]:GETTEXT())))
		oReport:Section(4):Acell[3]:Disable()
		oReport:Section(4):Acell[4]:Disable()
		oReport:Section(4):Acell[5]:Disable()
		oReport:Section(4):Acell[6]:Disable()
		oReport:Section(4):Acell[7]:Disable()
		oReport:Section(4):Acell[9]:Disable() //PRCVEN

		oReport:Section(5):Acell[3]:Disable()
		oReport:Section(5):Acell[4]:Disable()
		oReport:Section(5):Acell[5]:Disable()
		oReport:Section(5):Acell[6]:Disable()
		oReport:Section(5):Acell[7]:Disable()
		oReport:Section(5):Acell[9]:Disable() //PRCVEN

		oReport:Section(6):Acell[3]:Disable()
		oReport:Section(6):Acell[4]:Disable()
		oReport:Section(6):Acell[5]:Disable()
		oReport:Section(6):Acell[6]:Disable()
		oReport:Section(6):Acell[7]:Disable()
		oReport:Section(6):Acell[9]:Disable() //PRCVEN

	EndIf

	cNota		:= ""
	cSerie    := ""
	cSerieView:= ""
	nAcN1		:= 0
	nAcN2		:= 0
	nAcImpInc	:= 0
	nAcImpnoInc	:= 0
	nAcDImpInc  := 0
	nAcDImpNoInc:= 0
	nAcD1		:= 0
	nAcD2		:= 0
	nAcD3		:= 0
	nAcDAdi		:= 0
	nAcG1		:= 0
	nAcG2		:= 0
	nAcGADI		:= 0
	nAcGImpInc	:= 0
	nAcGImpNoInc:= 0
	nAcG3		:= 0
	nTotNeto	:= 0
	nTotNetGer	:= 0
	nTotDia		:= 0

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Cria Indice de Trabalho                                      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cWhereF2 := "%"
	if mv_par14 == 2   //nao imprimir notas com moeda diferente da escolhida
		cWhereF2 += " AND F2_MOEDA=" + Alltrim(str(mv_par13))
	endif
	cWhereF2 += " AND NOT ("+IsRemito(2,"F2_TIPODOC")+")"

	cWhereF1 := "%"
	if mv_par14 == 2   //nao imprimir notas com moeda diferente da escolhida
		cWhereF1 += " AND F1_MOEDA=" + Alltrim(str(mv_par13))
	endif
	cWhereF1 += " AND NOT ("+IsRemito(2,"F1_TIPODOC")+")"

	cSCpo 	  := "1"
	cCpoSD2   := "D2_VALIMP" + cSCpo
	cCpoSD1   := "D1_VALIMP" + cSCpo
	cCamposD2 := "%"
	cCamposD1 := "%"
	While SD2->(FieldPos(cCpoSD2)) > 0 .And. SD1->(FieldPos(cCpoSD1)) > 0
		cCamposD2 += ","+cCpoSD2 + " " + Substr(cCpoSD2,4)
		cCamposD1 += ","+cCpoSD1 + " " + Substr(cCpoSD1,4)
		cSCpo := Soma1(cSCpo)
		cCpoSD2 := "D2_VALIMP" + cSCpo
		cCpoSD1 := "D1_VALIMP" + cSCpo
	EndDo
	cCamposD2 += "%"
	cCamposD1 += "%"

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Transforma parametros Range em expressao SQL                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	MakeSqlExpr(oReport:uParam)

	If !( Empty(mv_par05) )
		cWhereF2 += " AND " + MV_PAR05
		cWhereF1 += " AND " + StrTran(MV_PAR05, "D2_", "D1_")
	EndIf
	If !( Empty(mv_par10) )
		cWhereF2 += " AND " + MV_PAR10
		cWhereF1 += " AND " + StrTran(MV_PAR10, "D2_", "D1_")
	EndIf
	If !( Empty(mv_par11) )
		cWhereF2 += " AND " + MV_PAR11
		cWhereF1 += " AND " + StrTran(MV_PAR11, "D2_", "D1_")
	EndIf
	If !( Empty(mv_par16) )
		cWhereF2 += " AND " + MV_PAR16
		cWhereF1 += " AND " + StrTran(MV_PAR16, "F2_CLIENTE", "F1_FORNECE")
	EndIf
	cWhereF2 +="%"
	cWhereF1 +="%"

	If cPaisLoc == "MEX"
		cExpTot := "% D2_TOTAL-D2_VALADI TOTAL, D2_VALADI VALADI%"
	Else
		cExpTot := "% D2_TOTAL TOTAL,0 VALADI %"
	EndIf

	cIDWhere:= "%"
	cIDWhere+= SerieNfId("SF2",3,"F2_SERIE")+" >= '"+mv_par06+"'"
	cIDWhere+= "AND "+SerieNfId("SF2",3,"F2_SERIE")+" <= '"+mv_par07+"'"
	cIDWhere+= "%"

	cIDWhereU:= "%"
	cIDWhereU+= SerieNfId("SF1",3,"F1_SERIE")+" >= '"+mv_par06+"'"
	cIDWhereU+= "AND "+SerieNfId("SF1",3,"F1_SERIE")+" <= '"+mv_par07+"'"
	cIDWhereU+= "%"

	cSelect:= "%"
	cSelect+= Iif(SerieNfId("SF2",3,"F2_SERIE")<>"F2_SERIE",",F2_SDOC","")
	cSelect+= "%"

	cSelectUni:= "%"
	cSelectUni+= Iif(SerieNfId("SF1",3,"F1_SERIE")<>"F1_SERIE",",F1_SDOC","")
	cSelectUni+= "%"

	cExp2:= "%D2_DESCON VALDESC,D2_ITEM ITEM%"


	oReport:Section(1):BeginQuery()

	BeginSql Alias cAliasQry
SELECT F2_CLIENTE CLIFOR,F2_LOJA LOJA,F2_DOC DOC,F2_SERIE SERIE,F2_EMISSAO EMISSAO %Exp:cSelect%
		,F2_MOEDA MOEDA,F2_TXMOEDA TXMOEDA,F2_TIPO TIPO,F2_ESPECIE ESPECIE
		,F2_FRETE FRETE,F2_FRETAUT FRETAUT,F2_SEGURO SEGURO,F2_DESPESA DESPESA
		,SA1.A1_NOME NOME,D2_DOC DOCITEM,D2_SERIE SERIEITEM,D2_CLIENTE CLIFORITEM,D2_LOJA LOJAITEM,D2_TIPO TIPOITEM
		,D2_GRADE GRADE,D2_COD COD ,D2_QUANT QUANT
		,D2_CF CF,D2_TES TES,D2_LOCAL ALMOX,D2_ITEMPV ITEMPV,D2_PEDIDO PEDIDO,D2_REMITO REMITO,D2_ITEMREM ITEMREM
		,D2_PRCVEN PRCVEN,%Exp:cExpTot% ,D2_DESCON VALDESC,D2_ITEM ITEM, "2" TIPODOC %Exp:cCamposD2%
FROM %Table:SF2% SF2, %Table:SD2% SD2, %Table:SA1% SA1
WHERE	F2_FILIAL = %xFilial:SF2%
		AND F2_DOC >= %Exp:mv_par01% AND F2_DOC <= %Exp:mv_par02%
		AND F2_EMISSAO >= %Exp:DTOS(mv_par03)%  AND F2_EMISSAO <= %Exp:DTOS(mv_par04)%
		AND %Exp:cIDWhere%
		AND F2_TIPO <> 'D'
		AND SF2.%notdel%
		AND SA1.A1_FILIAL = %xFilial:SA1% AND SA1.A1_COD = F2_CLIENTE AND SA1.A1_LOJA = F2_LOJA
		AND SA1.%notdel%
		AND D2_FILIAL = %xFilial:SD2% AND D2_CLIENTE = F2_CLIENTE AND D2_LOJA = F2_LOJA
		AND D2_DOC = F2_DOC AND D2_SERIE = F2_SERIE
		AND SD2.%notdel%
		%Exp:cWhereF2%		
			
UNION ALL
	
SELECT	F1_FORNECE CLIFOR,F1_LOJA LOJA,F1_DOC DOC,F1_SERIE SERIE,F1_DTDIGIT EMISSAO %Exp:cSelectUni%
		,F1_MOEDA MOEDA,F1_TXMOEDA TXMOEDA,F1_TIPO TIPO,F1_ESPECIE ESPECIE
		,F1_FRETE,0 FRETAUT,F1_SEGURO SEGURO,F1_DESPESA DESPESA
		,SA1.A1_NOME NOME,D1_DOC DOCITEM,D1_SERIE SERIEITEM,D1_FORNECE CLIFORITEM,D1_LOJA LOJAITEM,D1_TIPO TIPOITEM
		," " GRADE,D1_COD COD,D1_QUANT QUANT
		,D1_CF CF,D1_TES TES,D1_LOCAL ALMOX,D1_ITEMPV ITEMPV,D1_NUMPV PEDIDO,D1_REMITO REMITO,D1_ITEMREM ITEMREM
		,D1_VUNIT PRCVEN,D1_TOTAL TOTAL,0 VALADI,D1_VALDESC VALDESC,D1_ITEM ITEM, "1" TIPODOC %Exp:cCamposD1%
FROM %Table:SF1% SF1, %Table:SD1% SD1, %Table:SA1% SA1
WHERE	F1_FILIAL = %xFilial:SF1%
		AND F1_DOC >= %Exp:mv_par01% AND F1_DOC <= %Exp:mv_par02%
		AND F1_DTDIGIT >= %Exp:DtoS(mv_par03)% AND F1_DTDIGIT <= %Exp:DtoS(mv_par04)%
		AND %Exp:cIDWhereU%
		AND F1_TIPO = 'D'
		AND SF1.%notdel%
		AND SA1.A1_FILIAL = %xFilial:SA1% AND SA1.A1_COD = F1_FORNECE AND SA1.A1_LOJA=F1_LOJA
		AND SA1.%notdel%
		AND D1_FILIAL = %xFilial:SD1% AND D1_FORNECE = F1_FORNECE AND D1_LOJA = F1_LOJA
		AND D1_DOC = F1_DOC AND D1_SERIE = F1_SERIE
		AND SD1.%notdel%
		%Exp:cWhereF1%		
ORDER BY EMISSAO,TIPODOC,DOC,SERIE,COD,ITEM
	EndSql
	oReport:Section(1):EndQuery()

	TcSetField(cAliasQry, 'EMISSAO', 'D', 08, 0  )
	oReport:SetMeter((cAliasQry)->(LastRec()))
	dbSelectArea(cAliasQry)
	dbGoTop()
	While !(cAliasQry)->(Eof()) .And. lContinua

		oReport:IncMeter()

		dEmisAnt   := (cAliasQry)->EMISSAO
		dEmissao   := (cAliasQry)->EMISSAO
		cNota		:= (cAliasQry)->DOC
		cTipo		:= (cAliasQry)->TIPO
		cTipoDoc	:= (cAliasQry)->TIPODOC
		cSerie		:= (cAliasQry)->SERIE
		cSerieView	:= Alltrim((cAliasQry)->&(SerieNfId("SF2",3,"SERIE")))
		cCliente	:= (cAliasQry)->CLIFOR + (cAliasQry)->LOJA
		cNome	  	:= (cAliasQry)->NOME
		cLoja		:= (cAliasQry)->LOJA
		nFrete		:= (cAliasQry)->FRETE
		nSeguro	:= (cAliasQry)->SEGURO
		nDespesa	:= (cAliasQry)->DESPESA
		nMoeda		:= (cAliasQry)->MOEDA
		nTxMoeda	:= (cAliasQry)->TXMOEDA
		nFretAut	:= (cAliasQry)->FRETAUT
		nCt			:= 1

		If (cAliasQry)->TIPODOC == "1"
			TRPrinD1Top(@nCt,oReport,cAliasQry)
		Else
			TRPrinD2Top(@nCt,oReport,cAliasQry)
		Endif

		nAcN3 := 0
		nTotNeto := 0
		If nAcN2 > 0
			nAcN3 := xmoeda(nFrete + nSeguro + nDespesa, nMoeda, mv_par13, dEmisAnt, nDecs+1, nTXMoeda)
			nTotNeto := nAcN2 + nAcN3 + nFretAut + nAcImpInc

			If nAcN3 != 0 .Or. nFretAut != 0
				oReport:PrintText(STR0032 + " ------------> " + Str(nAcN3+nFretAut,14,2))		// DESPESAS ACESSORIAS
				oReport:SkipLine(1)
			EndIf

			If cTipoDoc == "2"
				nAcGImpInc		+= nAcImpInc
				nAcGImpNoInc	+= nAcImpNoInc
				nAcG1			+= nAcN1
				nAcG2			+= nAcN2
				nAcG3			+= nAcN3 + nFretAut
				nTotNetGer		+= nAcN2 + nAcN3 + nAcImpInc
			Else
				nAcGImpInc		-= nAcImpInc
				nAcGImpNoInc	-= nAcImpNoInc
				nAcG1			-= nAcN1
				nAcG2			-= nAcN2
				nAcG3			-= nAcN3 + nFretAut
				nTotNetGer		-= nAcN2 + nAcN3 + nAcImpInc
			Endif
		EndIf

		nTotDia += nAcN2 + nAcImpInc

		For nY := 1 to Len(aImpostos)
			If (aImpostos[nY][3] == "2") .And. cPaisLoc == "COL"
				nTotNeto	-= nAcImpNoInc
				nTotNetGer	-= nAcImpNoInc
				nTotDia	-= nAcImpNoInc
			EndIf
		Next

		nAcDImpInc		+= nAcImpInc
		nAcDImpNoInc	+= nAcImpNoInc
		nAcD1			+= nAcN1
		nAcD2			+= nAcN2
		nAcD3			+= nAcN3 + nFretAut

		nAcImpInc		:= 0
		nAcImpNoInc	:= 0
		nAcn1			:= 0
		nAcn2			:= 0
		nAcn3			:= 0

		If ( nAcd1 > 0 .And. ( dEmisAnt != (cAliasQry)->EMISSAO .Or. Eof()))
			oReport:Section(6):SetHeaderSection(.F.)
			oReport:PrintText(STR0034 +  DtoC(dEmisAnt))
			oReport:FatLine()
			oReport:Section(6):Init()
			oReport:Section(6):PrintLine()
			oReport:Section(6):Finish()
			oReport:SkipLine(2)

			nAcDImpInc  := 0
			nAcDImpNoInc:= 0
			nAcD1 		:= 0
			nAcD2 		:= 0
			nAcD3 		:= 0
			nTotDia		:= 0
			nAcdAdi		:= 0
		Endif

	End // Documento, Serie

	oReport:Section(5):SetHeaderSection(.F.)
	oReport:PrintText(STR0060)
	oReport:Section(5):Init()

	oReport:Section(5):Cell("CCOD"):Hide()
	oReport:Section(5):Cell("CDESC"	):Hide()
	//oReport:Section(5):Cell("ALMOX"):Hide()
	oReport:Section(5):Cell("PEDIDO"):Hide()
	oReport:Section(5):Cell("ITEM"):Hide()
	//oReport:Section(5):Cell("REMITO"):Hide()
	//oReport:Section(5):Cell("ITEMREM"):Hide()
	//oReport:Section(5):Cell("NACGIMPINC"):Hide()
	//oReport:Section(5):Cell("NACGIMPNOINC"):Hide()

	oReport:Section(5):PrintLine()
	oReport:Section(5):Finish()

Return .T.


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³TRPrinD2Top³ Autor ³ Marco Bianchi        ³ Data ³ 08/06/06 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Imprime itens do SD2 (Base Localizada Top).                ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATR550 - R4 	                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

STATIC Function TRPRIND2TOP(nCt,oReport,cAliasQry)

	Local nTotImpInc		:= 0
	Local nTotImpNoInc	:= 0
	Local nImpInc			:= 0
	Local nImpNoInc		:= 0
	Local nQuant			:= 0
	Local nPrcVen			:= 0
	Local nValadi			:= 0
	Local nTotal			:= 0
	Local nTotcImp		:= 0
	Local cNumPed		  	:= ""
	Local nY				:= 0
	Local cMascara		:= GetMv("MV_MASCGRD")
	Local nTamRef			:= Val(Substr(cMascara,1,2))
	Local nReg				:= 0
	Local cFilSF2			:= ""
	Local cFilSD2			:= ""
	Local lValadi			:= cPaisLoc == "MEX"

	oReport:Section(2):Cell("CCLIENTE"	):SetBlock({|| Substr(cCliente,1,nTamA1COD)})
	oReport:Section(2):Cell("CLOJA"		):SetBlock({|| cLoja})
	oReport:Section(2):Cell("CNOME"		):SetBlock({|| cNome})
	oReport:Section(2):Cell("CEMISSAO"	):SetBlock({|| dEmissao})
	oReport:Section(2):Cell("CTIPO"		):SetBlock({|| cTipo})

	oReport:Section(4):Cell("CCOD"		):SetBlock({|| cCod})
	//oReport:Section(4):Cell("ALMOX"		):SetBlock({|| cLocal})
	oReport:Section(4):Cell("CDESC"		):SetBlock({|| cDesc})
	oReport:Section(4):Cell("NQUANT"	):SetBlock({|| nQuant})
	oReport:Section(4):Cell("NPRCVEN"	):SetBlock({|| nPrcVen})

	If lValadi
		oReport:Section(4):Cell("NVALADI"	):SetBlock({|| nValadi})
	EndIf

	oReport:Section(4):Cell("NTOTAL"	):SetBlock({|| nTotal})
	//oReport:Section(4):Cell("NIMPINC"	):SetBlock({|| nImpInc})
	//oReport:Section(4):Cell("NIMPNOINC"):SetBlock({|| nImpnoInc})
	oReport:Section(4):Cell("NTOTCIMP"	):SetBlock({|| nTotcImp})
	oReport:Section(4):Cell("PEDIDO"	):SetBlock({|| cPedido})
	oReport:Section(4):Cell("ITEM"		):SetBlock({|| cItemPV})
	//oReport:Section(4):Cell("REMITO"	):SetBlock({|| cRemito})
	//oReport:Section(4):Cell("ITEMREM"	):SetBlock({|| cItemrem})

	nAcN1			:= 0
	nAcN2			:= 0
	nAcImpInc		:= 0
	nAcImpnoInc	:= 0

	If len(oReport:Section(2):GetAdvplExp("SF2")) > 0
		cFilSF2	:= oReport:Section(2):GetAdvplExp("SF2")
	EndIf
	If len(oReport:Section(4):GetAdvplExp("SD2")) > 0
		cFilSD2	:= oReport:Section(4):GetAdvplExp("SD2")
	EndIf

	While (cAliasQry)->(! Eof()) .and. (cAliasQry)->DOC + (cAliasQry)->SERIE + (cAliasQry)->CLIFOR + (cAliasQry)->LOJA == cNota + cSerie + cCliente

		dbSelectArea("SF2")
		dbSetOrder(1)
		dbSeek( xFilial("SF2") + (cAliasQry)->DOC + (cAliasQry)->SERIE + (cAliasQry)->CLIFOR + (cAliasQry)->LOJA )
		// Verifica filtro do usuario
		If !( Empty(cFilSF2) ) .And. !(&cFilSF2)
			dbSelectArea(cAliasQry)
			dbSkip()
			Loop
		EndIf

		dbSelectArea("SD2")
		dbSetOrder(3)
		dbSeek( xFilial("SD2")+ (cAliasQry)->DOCITEM +(cAliasQry)->SERIEITEM +(cAliasQry)->CLIFORITEM + (cAliasQry)->LOJAITEM +(cAliasQry)->COD + (cAliasQry)->ITEM )
		// Verifica filtro do usuario
		If !( Empty(cFilSD2) ) .And. !(&cFilSD2)
			dbSelectArea(cAliasQry)
			dbSkip()
			Loop
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Valida o produto conforme a mascara         ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea(cAliasQry)
		lRet	:= ValidMasc((cAliasQry)->COD, MV_PAR08)
		If ! lRet
			(cAliasQry)->(dbSkip())
			Loop
		Endif

		If nCt == 1
			oReport:Section(2):Init()
			oReport:Section(2):PrintLine()
			oReport:Section(2):Finish()
			oReport:Section(4):Init()
			nCt++
		EndIf

		cCod	:= IIF((cAliasQry)->GRADE == "S".And. MV_PAR09 == 1, Substr((cAliasQry)->COD,1,nTamRef), (cAliasQry)->COD)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Utiliza Descricao conforme mv_par12         ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		If mv_par12 == 1
			cDesc := Posicione("SB1",1,xFilial("SB1")+(cAliasQry)->COD,"B1_DESC")
		Else
			dbSelectArea("SA7");dbSetOrder(2)
			If dbSeek(xFilial("SA7")+(cAliasQry)->COD+(cAliasQry)->CLIFOR+(cAliasQry)->LOJA)
				cDesc := SA7->A7_DESCCLI
			Else
				cDesc := Posicione("SB1",1,xFilial("SB1")+(cAliasQry)->COD,"B1_DESC")
			Endif
		Endif

		dbSelectArea(cAliasQry)
		cCf				:= (cAliasQry)->CF
		cTes			:= (cAliasQry)->TES
		cNumPed		:= (cAliasQry)->PEDIDO
		nTotQuant		:= 0
		nTotal			:= 0
		nTotcImp		:= 0
		nTotImpInc		:= 0
		nTotImpNoInc	:= 0
		nPrcVen		:= xmoeda((cAliasQry)->PRCVEN,(cAliasQry)->MOEDA,mv_par13,,nDecs+1,(cAliasQry)->TXMOEDA)
		If lValadi
			nValadi	:= xmoeda((cAliasQry)->VALADI,(cAliasQry)->MOEDA,mv_par13,,nDecs+1,(cAliasQry)->TXMOEDA)
		EndIf
		cLocal			:= (cAliasQry)->ALMOX
		cPedido		:= (cAliasQry)->PEDIDO
		cItemPV		:= (cAliasQry)->ITEMPV
		cRemito		:= (cAliasQry)->REMITO
		cItemRem		:= (cAliasQry)->ITEMREM

		nReg := 0
		If (cAliasQry)->GRADE == "S" .And. MV_PAR09 == 1
			cProdRef	:= Substr((cAliasQry)->COD,1,nTamRef)
			cCod		:= Substr((cAliasQry)->COD,1,nTamRef)
			While (cAliasQry)->(! Eof()) .And. cProdRef == Substr((cAliasQry)->COD,1,nTamRef) .And. (cAliasQry)->GRADE == "S" .And. cNumPed == (cAliasQry)->PEDIDO
				nTotQuant	+= (cAliasQry)->QUANT
				nTotal		+= IIF(!((cAliasQry)->TIPO $ "IP"), xmoeda((cAliasQry)->TOTAL, (cAliasQry)->MOEDA, mv_par13, (cAliasQry)->EMISSAO, nDecs+1, (cAliasQry)->TXMOEDA), 0)

				If (cAliasQry)->TIPO == "I"
					nCompIcm	+= xmoeda((cAliasQry)->TOTAL, (cAliasQry)->MOEDA, mv_par13, (cAliasQry)->EMISSAO, nDecs+1, (cAliasQry)->TXMOEDA)
				EndIf

				nImpInc		:= 0
				nImpNoInc		:= 0

				aImpostos		:= TesImpInf((cAliasQry)->TES)

				For nY := 1 to Len(aImpostos)
					cCampImp	:= (cAliasQry)+"->"+(Substr(aImpostos[nY][2],4))
					If ( aImpostos[nY][3]=="1" )
						nImpInc	+= xmoeda(&cCampImp, (cAliasQry)->MOEDA, mv_par13, (cAliasQry)->EMISSAO, nDecs+1, (cAliasQry)->TXMOEDA)
					Else
						nImpNoInc	+= xmoeda(&cCampImp, (cAliasQry)->MOEDA, mv_par13, (cAliasQry)->EMISSAO, nDecs+1, (cAliasQry)->TXMOEDA)
					EndIf
				Next

				nTotImpInc		+= nImpInc
				nTotImpNoInc	+= nImpNoInc

				nReg			:= (cAliasQry)->(Recno())

				(cAliasQry)->(dbSkip())

				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ Valida o produto conforme a mascara       ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				lRet			:= ValidMasc((cAliasQry)->COD,MV_PAR08)
				If ! lRet
					(cAliasQry)->(dbSkip())
					Loop
				Endif
			End

			nTotcImp		:= (nTotal + nTotImpInc)
			nQuant			:= nTotQuant
			oReport:Section(4):PrintLine()

			nAcN1			+= nTotQuant
			nAcN2			+= nTotal
			nAcImpInc		+= nTotImpInc
			nAcImpNoInc	+= nTotImpNoInc

		Else

			nImpInc		:= 0
			nImpNoInc		:= 0

			aImpostos		:= TesImpInf((cAliasQry)->TES)

			For nY := 1 to Len(aImpostos)
				cCampImp	:= cAliasQry + "->" + (substr(aImpostos[nY][2],4))
				If ( aImpostos[nY][3] == "1" )
					nImpInc	+= xmoeda(&cCampImp, (cAliasQry)->MOEDA, mv_par13, (cAliasQry)->EMISSAO, nDecs+1, (cAliasQry)->TXMOEDA)
				Else
					nImpNoInc	+= xmoeda(&cCampImp, (cAliasQry)->MOEDA, mv_par13, (cAliasQry)->EMISSAO, nDecs+1, (cAliasQry)->TXMOEDA)
				EndIf
			Next

			cCod			:= (cAliasQry)->COD
			nQuant			:= (cAliasQry)->QUANT
			nPrcVen		:= xMoeda((cAliasQry)->PRCVEN, (cAliasQry)->MOEDA, MV_PAR13, (cAliasQry)->EMISSAO, nDecs+1, (cAliasQry)->TXMOEDA)
			If lValadi
				nValadi	:= xMoeda((cAliasQry)->VALADI, (cAliasQry)->MOEDA, MV_PAR13, (cAliasQry)->EMISSAO, nDecs+1, (cAliasQry)->TXMOEDA)
			EndIf
			nTotal			:=  xMoeda((cAliasQry)->TOTAL, (cAliasQry)->MOEDA, MV_PAR13, (cAliasQry)->EMISSAO, nDecs+1, (cAliasQry)->TXMOEDA)

			For nY := 1 to Len(aImpostos)
				If (aImpostos[nY][3] == "2") .And. cPaisLoc == "COL"
					nTotcImp	:= (nImpInc + xMoeda((cAliasQry)->TOTAL, (cAliasQry)->MOEDA, mv_par13, (cAliasQry)->EMISSAO, nDecs+1, (cAliasQry)->TXMOEDA)) - nImpNoInc
				Else
					nTotcImp	:=  nImpInc + xMoeda((cAliasQry)->TOTAL, (cAliasQry)->MOEDA, mv_par13, (cAliasQry)->EMISSAO, nDecs+1, (cAliasQry)->TXMOEDA)
				EndIf
			Next

			oReport:Section(4):PrintLine()

			nAcImpInc		+= nImpInc
			nAcImpNoInc	+= nImpNoInc

			nAcN1			+= (cAliasQry)->QUANT
			nAcN2			+= xmoeda((cAliasQry)->TOTAL,(cAliasQry)->MOEDA,mv_par13,(cAliasQry)->EMISSAO,nDecs+1,(cAliasQry)->TXMOEDA)

		Endif

		If lValadi
			nAcgAdi		+= nValadi
			nAcdAdi		+= nValadi
		EndIf

		dbSelectArea(cAliasQry)
		If nReg == 0
			dbSkip()
		Endif
	EndDo // Nota

	If !(nQuant + nTotal + nImpInc + nImpNoInc + nTotcImp > 0)
		oReport:Section(4):AFunction	:= {}
		TRFunction():New(oReport:Section(4):Cell("NQUANT")		,/* cID */,"SUM",/*oBreak*/,STR0037,"@E 999999999999999999.99"	 ,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)
		TRFunction():New(oReport:Section(4):Cell("NTOTAL")		,/* cID */,"SUM",/*oBreak*/,STR0039,PesqPict("SD2","D2_TOTAL"	),/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)
		//TRFunction():New(oReport:Section(4):Cell("NIMPINC")		,/* cID */,"SUM",/*oBreak*/,STR0045,PesqPict("SD2","D2_VALIPI"	),/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)
		//TRFunction():New(oReport:Section(4):Cell("NIMPNOINC")	,/* cID */,"SUM",/*oBreak*/,STR0046,PesqPict("SD2","D2_VALICM"	),/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)
		TRFunction():New(oReport:Section(4):Cell("NTOTCIMP")	,/* cID */,"SUM",/*oBreak*/,STR0047,PesqPict("SD2","D2_VALISS"	),/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)
		oReport:SetTotalInLine(.F.)
	Else
		oReport:Section(4):SetTotalText(STR0048 + " " +  cNota + "/" + cSerie)
		oReport:Section(4):Finish()
	EndIf

Return


/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³TRPrinD1Top³ Autor ³ Marco Bianchi        ³ Data ³ 07/06/06 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Imprime itens do SD1 (Base Localizada - Top).              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATR550 - R4		                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/

STATIC Function TRPRIND1TOP(nCt,oReport,cAliasQry)

	Local nY			:= 0
	Local cFilSF1		:= ""
	Local cFilSD1		:= ""
	Local nQuant		:= 0
	Local nTotal		:= 0
	Local nImpInc		:= 0
	Local nImpNoInc	:= 0
	Local nTotcImp	:= 0

	oReport:Section(1):Cell("CCLIENTE"	):SetBlock({|| Substr(cCliente,1,nTamA1COD)})
	oReport:Section(1):Cell("CLOJA"		):SetBlock({|| cLoja})
	oReport:Section(1):Cell("CNOME"		):SetBlock({|| cNome})
	oReport:Section(1):Cell("CEMISSAO"	):SetBlock({|| dEmissao})
	oReport:Section(1):Cell("CTIPO"		):SetBlock({|| cTipo})

	oReport:Section(3):Cell("CCOD"		):SetBlock({|| cCod})
	//oReport:Section(3):Cell("ALMOX"		):SetBlock({|| cLocal})
	oReport:Section(3):Cell("CDESC"		):SetBlock({|| cDesc})
	oReport:Section(3):Cell("NQUANT"	):SetBlock({|| nQuant})
	oReport:Section(3):Cell("NPRCVEN"	):SetBlock({|| nPrcVen})
	oReport:Section(3):Cell("NTOTAL"	):SetBlock({|| nTotal})
	//oReport:Section(3):Cell("NIMPINC"	):SetBlock({|| nImpInc})
	//oReport:Section(3):Cell("NIMPNOINC"):SetBlock({|| nImpnoInc})
	oReport:Section(3):Cell("NTOTCIMP"	):SetBlock({|| nTotcImp})
	oReport:Section(3):Cell("PEDIDO"	):SetBlock({|| cPedido})
	oReport:Section(3):Cell("ITEM"		):SetBlock({|| cItemPV})
	//oReport:Section(3):Cell("REMITO"	):SetBlock({|| cRemito})
	//oReport:Section(3):Cell("ITEMREM"	):SetBlock({|| cItemrem})

	nAcN1			:= 0
	nAcN2			:= 0
	nAcImpInc		:= 0
	nAcImpnoInc	:= 0
	cPedido		:= ""
	cItemPV		:= ""
	cRemito		:= ""
	cItemrem		:= ""
	cLocal			:= ""

	If len(oReport:Section(1):GetAdvplExp("SF1")) > 0
		cFilSF1 := oReport:Section(1):GetAdvplExp("SF1")
	EndIf
	If len(oReport:Section(3):GetAdvplExp("SD1")) > 0
		cFilSD1 := oReport:Section(3):GetAdvplExp("SD1")
	EndIf

	While (cAliasQry)->(! Eof()) .and. (cAliasQry)->TIPODOC == "1" .And. (cAliasQry)->DOC + (cAliasQry)->SERIE + (cAliasQry)->CLIFOR + (cAliasQry)->LOJA == cNota + cSerie + cCliente

		dbSelectArea("SF1")
		dbSetOrder(1)
		dbSeek( xFilial("SF1") + (cAliasQry)->DOC + (cAliasQry)->SERIE + (cAliasQry)->CLIFOR + (cAliasQry)->LOJA )
		// Verifica filtro do usuario
		If !( Empty(cFilSF1) ) .And. !(&cFilSF1)
			dbSelectArea(cAliasQry)
			dbSkip()
			Loop
		EndIf

		dbSelectArea("SD1")
		dbSetOrder(1)
		dbSeek( xFilial("SD1") + (cAliasQry)->DOCITEM + (cAliasQry)->SERIEITEM + (cAliasQry)->CLIFORITEM + (cAliasQry)->LOJAITEM + (cAliasQry)->COD + (cAliasQry)->ITEM )
		// Verifica filtro do usuario
		If !( Empty(cFilSD1) ) .And. !(&cFilSD1)
			dbSelectArea(cAliasQry)
			dbSkip()
			Loop
		EndIf

		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Valida o produto conforme a mascara         ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea(cAliasQry)
		lRet := ValidMasc((cAliasQry)->COD,MV_PAR08)

		If !lRet
			dbSkip()
			Loop
		Endif

		If nCt == 1
			oReport:Section(1):Init()
			oReport:Section(1):PrintLine()
			oReport:Section(1):Finish()
			oReport:Section(3):Init()
			nCt++
		EndIf
		dbSelectArea(cAliasQry)

		nTotQuant   := 0
		nTotcImp    := 0
		nTotal      := 0
		nImpInc  	:= 0
		nImpNoInc	:= 0

		aImpostos	:= TesImpInf((cAliasQry)->TES)
		For nY := 1 to Len(aImpostos)
			cCampImp	:= cAliasQry + "->" + (Substr(aImpostos[nY][2],4))
			If ( aImpostos[nY][3] == "1" )
				nImpInc	+= xmoeda(&cCampImp, (cAliasQry)->MOEDA, mv_par13, (cAliasQry)->EMISSAO, nDecs+1, (cAliasQry)->TXMOEDA)
			Else
				nImpNoInc	+= xmoeda(&cCampImp, (cAliasQry)->MOEDA, mv_par13, (cAliasQry)->EMISSAO, nDecs+1, (cAliasQry)->TXMOEDA)
			EndIf
		Next

		If mv_par12 == 1
			cDesc := Posicione("SB1",1,xFilial("SB1")+(cAliasQry)->COD,"B1_DESC")
		Else
			SA7->(dbSetOrder(2))
			If SA7->(dbSeek(xFilial("SA7") + (cAliasQry)->COD + (cAliasQry)->CLIFOR + (cAliasQry)->LOJA))
				cDesc := SA7->A7_DESCCLI
			Else
				cDesc := Posicione("SB1",1,xFilial("SB1")+(cAliasQry)->COD,"B1_DESC")
			Endif
		Endif

		dbSelectArea(cAliasQry)
		cCod		:= (cAliasQry)->COD
		nQuant		:= (cAliasQry)->QUANT
		nPrcVen	:=           xMoeda(((cAliasQry)->PRCVEN - ((cAliasQry)->VALDESC/(cAliasQry)->QUANT)) ,(cAliasQry)->MOEDA, mv_par13, (cAliasQry)->EMISSAO, nDecs+1, (cAliasQry)->TXMOEDA)
		nTotal		:=           xMoeda(((cAliasQry)->TOTAL -   (cAliasQry)->VALDESC),                     (cAliasQry)->MOEDA, mv_par13, (cAliasQry)->EMISSAO, nDecs+1, (cAliasQry)->TXMOEDA)
		nTotcImp	:= nImpInc + xmoeda(((cAliasQry)->TOTAL -   (cAliasQry)->VALDESC),                     (cAliasQry)->MOEDA, mv_par13, (cAliasQry)->EMISSAO, nDecs+1, (cAliasQry)->TXMOEDA)
		cLocal		:= (cAliasQry)->ALMOX

		oReport:Section(3):PrintLine()

		nAcImpInc		+= nImpInc
		nAcImpNoInc	+= nImpNoInc

		nAcN1		+= (cAliasQry)->QUANT
		nAcN2		+= xmoeda(((cAliasQry)->TOTAL - (cAliasQry)->VALDESC), (cAliasQry)->MOEDA, mv_par13, (cAliasQry)->EMISSAO, nDecs+1, (cAliasQry)->TXMOEDA)

		dbSelectArea(cAliasQry)
		dbSkip()
	EndDo

	If !(nQuant + nTotal + nImpInc + nImpNoInc + nTotcImp > 0)
		oReport:Section(3):aFunction := {}		// Zera array de totais
		TRFunction():New(oReport:Section(3):Cell("NQUANT"),   /* cID */,"SUM",/*oBreak*/,STR0037,"@E 999999999999999999.99"  ,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)
		TRFunction():New(oReport:Section(3):Cell("NTOTAL"),   /* cID */,"SUM",/*oBreak*/,STR0039,PesqPict("SD2","D2_TOTAL"	),/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)
		//TRFunction():New(oReport:Section(3):Cell("NIMPINC"),  /* cID */,"SUM",/*oBreak*/,STR0045,PesqPict("SD2","D2_VALIPI"	),/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)
		//TRFunction():New(oReport:Section(3):Cell("NIMPNOINC"),/* cID */,"SUM",/*oBreak*/,STR0046,PesqPict("SD2","D2_VALICM"	),/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)
		TRFunction():New(oReport:Section(3):Cell("NTOTCIMP"), /* cID */,"SUM",/*oBreak*/,STR0047,PesqPict("SD2","D2_VALISS"	),/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/)
		oReport:SetTotalInLine(.F.)
	Else
		oReport:Section(3):SetTotalText(STR0048 + " " +  cNota + "/" + cSerieView)
		oReport:Section(3):Finish()
	EndIf

Return

/*/{Protheus.doc} TrataFilt
Realiza o tratamento dos filtros de usuário de acordo com o tipo de relatório selecionado (analítico/sintético)
@author 	Nairan Alves Silva
@since 		10/12/2018
@param		oReport	- Objeto tReport
@param		nTipo	- Tipo do relatório. 1 - Sintético, 2 - Analítico
@Return		Nil
/*/

Static Function TrataFilt(oReport, nTipo)

	Local nSecoes := 0
	Local nSecao  := 0

	If cPaisLoc == "BRA"
		// Limpar os filtros de usuarios de todas as secoes do relatorio
		If nTipo == 1
			// Limpar os filtros de usuario independente da quantidade de secoes que o relatorio apresentar.
			// Obs: ao desmarcar a opção para imprimir a "Página de Parametros" na tela
			// "Personalizar Relatorio", o TReport retira do relatorio uma secao que eh a secao
			// da Pagina de Parametros, o que reduz a quantidade de secoes do relatorio.
			nSecoes := Len(oReport:aSection)
			For nSecao := 2 To nSecoes
				oReport:aSection[nSecao]:aUserFilter := {}
			Next nSecoes
		Else
			oReport:aSection[1]:aUserFilter := {}
		EndIf
	EndIf
Return

/*/{Protheus.doc} Scheddef
Realiza o tratamento do Pergunte via Schedule, não considerando 
o conteúdo da tabela SXD
@author 	Paulo Figueira
@since 		03/07/2019
@Return		aParam


Static Function Scheddef()

	Local aParam	:= {}
	aParam := { "R",;	//Tipo R para relatorio P para processo
	"MTR550P9R1",;		// Pergunte do relatorio, caso nao use passar ParamDef
	"SF2",;  			// Alias
	Nil,;  				//Array de ordens
	Nil}				//Título

Return aParam
*/



//-----------------------------------------------------------------------------------
/*/{Protheus.doc} FATPDLoad
    @description
    Inicializa variaveis com lista de campos que devem ser ofuscados de acordo com usuario.
	Remover essa função quando não houver releases menor que 12.1.27

    @type  Function
    @author Squad CRM & Faturamento
    @since  05/12/2019
    @version P12.1.27
    @param cUser, Caractere, Nome do usuário utilizado para validar se possui acesso ao 
        dados protegido.
    @param aAlias, Array, Array com todos os Alias que serão verificados.
    @param aFields, Array, Array com todos os Campos que serão verificados, utilizado 
        apenas se parametro aAlias estiver vazio.
    @param cSource, Caractere, Nome do recurso para gerenciar os dados protegidos.
    
    @return cSource, Caractere, Retorna nome do recurso que foi adicionado na pilha.
    @example FATPDLoad("ADMIN", {"SA1","SU5"}, {"A1_CGC"})
/*/
//-----------------------------------------------------------------------------------
Static Function FATPDLoad(cUser, aAlias, aFields, cSource)
	Local cPDSource := ""

	If FATPDActive()
		cPDSource := FTPDLoad(cUser, aAlias, aFields, cSource)
	EndIf

Return cPDSource


//-----------------------------------------------------------------------------------
/*/{Protheus.doc} FATPDUnload
    @description
    Finaliza o gerenciamento dos campos com proteção de dados.
	Remover essa função quando não houver releases menor que 12.1.27

    @type  Function
    @author Squad CRM & Faturamento
    @since  05/12/2019
    @version P12.1.27
    @param cSource, Caractere, Remove da pilha apenas o recurso que foi carregado.
    @return return, Nulo
    @example FATPDUnload("XXXA010") 
/*/
//-----------------------------------------------------------------------------------
Static Function FATPDUnload(cSource)

	If FATPDActive()
		FTPDUnload(cSource)
	EndIf

Return Nil

//-----------------------------------------------------------------------------------
/*/{Protheus.doc} FATPDIsObfuscate
    @description
    Verifica se um campo deve ser ofuscado, esta função deve utilizada somente após 
    a inicialização das variaveis atravez da função FATPDLoad.
	Remover essa função quando não houver releases menor que 12.1.27

    @type  Function
    @author Squad CRM & Faturamento
    @since  05/12/2019
    @version P12.1.27
    @param cField, Caractere, Campo que sera validado
    @param cSource, Caractere, Nome do recurso que buscar dados protegidos.
    @param lLoad, Logico, Efetua a carga automatica do campo informado
    @return lObfuscate, Lógico, Retorna se o campo será ofuscado.
    @example FATPDIsObfuscate("A1_CGC",Nil,.T.)
/*/
//-----------------------------------------------------------------------------------
Static Function FATPDIsObfuscate(cField, cSource, lLoad)

	Local lObfuscate := .F.

	If FATPDActive()
		lObfuscate := FTPDIsObfuscate(cField, cSource, lLoad)
	EndIf

Return lObfuscate

//-----------------------------------------------------------------------------
/*/{Protheus.doc} FATPDObfuscate
    @description
    Realiza ofuscamento de uma variavel ou de um campo protegido.
	Remover essa função quando não houver releases menor que 12.1.27

    @type  Function
    @sample FATPDObfuscate("999999999","U5_CEL")
    @author Squad CRM & Faturamento
    @since 04/12/2019
    @version P12
    @param xValue, (caracter,numerico,data), Valor que sera ofuscado.
    @param cField, caracter , Campo que sera verificado.
    @param cSource, Caractere, Nome do recurso que buscar dados protegidos.
    @param lLoad, Logico, Efetua a carga automatica do campo informado

    @return xValue, retorna o valor ofuscado.
/*/
//-----------------------------------------------------------------------------
Static Function FATPDObfuscate(xValue, cField, cSource, lLoad)

	If FATPDActive()
		xValue := FTPDObfuscate(xValue, cField, cSource, lLoad)
	EndIf

Return xValue


//-----------------------------------------------------------------------------
/*/{Protheus.doc} FATPDActive
    @description
    Função que verifica se a melhoria de Dados Protegidos existe.

    @type  Function
    @sample FATPDActive()
    @author Squad CRM & Faturamento
    @since 17/12/2019
    @version P12    
    @return lRet, Logico, Indica se o sistema trabalha com Dados Protegidos
/*/
//-----------------------------------------------------------------------------
Static Function FATPDActive()

	Static _lFTPDActive := Nil

	If _lFTPDActive == Nil
		_lFTPDActive := ( GetRpoRelease() >= "12.1.027" .Or. !Empty(GetApoInfo("FATCRMPD.PRW")) )
	Endif

Return _lFTPDActive
