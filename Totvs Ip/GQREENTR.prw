#INCLUDE "totvs.ch"
#INCLUDE "topconn.ch"

/*/{Protheus.doc} GQREENTR
Módulo		: COMPRAS
Tipo		: Ponto de entrada
Finalidade	: Ponto de Entrada localizado após a gravacao de todos os registros da nota fiscal de entrada
Nota		: Gravação de campos na SF1 e criação do registro na CD5
Ambiente   	: COMPRAS
Cliente		: SUNTECH - HB
Autor      	: Dione Oliveira - TOTVS IP
Data Criação: 10/06/2018
Param. Pers : -
Campos Pers.: -
/*/

User Function GQREENTR()

	local aArea   := getArea()
	local aAreaD1 := SD1->(getArea())
	local aAreaB1 := SB1->(getArea())
	local cChave  := xFilial("SD1") + SF1->F1_DOC + SF1->F1_SERIE + SF1->F1_FORNECE + SF1->F1_LOJA

	//chama rotina para tela complementar nota de exportação
	fGQREENTR()

	dbSelectArea("SD1")
	dbSetOrder(1) // D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
	dbSeek(cChave)

	restArea(aAreaD1)
	restArea(aAreaB1)
	restArea(aArea)

return


Static Function fGQREENTR()

Private _oJanela
Private aComboVia	:= {"1 -Maritima","2 -Fluvial","3 -Lacustre","4 -Aerea","5 -Postal","6 -Ferroviaria","7 -SUFRAMA","8 -Conduto","9 -Meios Proprios","10-Entrada/Saida Ficta","11-Courier","12-HandCarry"}
Private aComboTp	:= {"0-Declaracao Importacao","1-Declaracao Simplif. Import"}
Private aComboFor	:= {"1-Import p/ Conta Propria","2-Import p/ conta e ordem","3-Import por Encomenda"}
Private cComboVia
Private cComboTp
Private cComboFor
Private cTitulo		:= "Informações da Declaração de Importação"
Private cNrDI 		:= SPACE(12)
Private cLocal 		:= SPACE(30)
Private cUFLocal	:= SPACE(2)
Private cAtoCon		:= SPACE(20)
Private cCNPJAd		:= SPACE(14)
Private cUFTer		:= SPACE(2)
Private cTransp		:= SF1->F1_TRANSP
Private cPlaca		:= SF1->F1_PLACA
Private cEspecie	:= SF1->F1_ESPECI1
Private nVolume		:= SF1->F1_VOLUME1
Private nPBruto		:= SF1->F1_PBRUTO
Private nPLiqui		:= SF1->F1_PLIQUI
Private nVlrDes		:= SF1->F1_DESCONT
Private nLin		:= 004
Private dDtDesem	:= cTod("  /  /  ")
Private dDtDI		:= cTod("  /  /  ")
Private dDtPgImp	:= cTod("  /  /  ")
Private lRet		:= .F.

	//Verfica se está na primeira classificacao
	dbSelectArea("SD1")
	dbSetOrder(1)//D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
	dbSeek(xFilial("SD1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA)

	If Alltrim(SF1->F1_EST) == "EX"

		// Abertura da tela para colocar as informações de importação
		DEFINE MSDIALOG _oJanela  TITLE cTitulo FROM 000,000 to 360,700 PIXEL

		nLin+=10
		@ nLin,012 Say "No. da DI/DA:" SIZE 140,20 OF _oJanela PIXEL
		@ nLin,060 MSGET cNrDI WHEN .T. SIZE 80,07 PICTURE "@R 99.99999999-99" OF _oJanela PIXEL
		@ nLin,170 Say "Registro DI:" SIZE 140,20 OF _oJanela PIXEL
		@ nLin,210 MSGET dDtDI WHEN .T. SIZE 80,07 OF _oJanela PIXEL
		nLin+=15
		@ nLin,012 Say "Dt Desembar.:" SIZE 140,20 OF _oJanela PIXEL
		@ nLin,060 MSGET dDtDesem WHEN .T. SIZE 80,07 OF _oJanela PIXEL
		@ nLin,170 Say "Dt.Pg.Impost:" SIZE 140,20 OF _oJanela PIXEL
		@ nLin,210 MSGET dDtPgImp WHEN .T. SIZE 80,07 OF _oJanela PIXEL
		nLin+=15
		@ nLin,012 Say "Descr.Local:" SIZE 140,20 OF _oJanela PIXEL
		@ nLin,060 MSGET cLocal WHEN .T. SIZE 80,07 PICTURE "@!" OF _oJanela PIXEL
		@ nLin,170 Say "UF Desembara:" SIZE 140,20 OF _oJanela PIXEL
		@ nLin,210 MSGET cUFLocal F3 "12" VALID Vazio().Or.ExistCpo("SX5","12"+cUFLocal) WHEN .T. SIZE 80,07 OF _oJanela PIXEL
		nLin+=15
		@ nLin,012 Say "Tp. Doc. Imp:" SIZE 140,20 OF _oJanela PIXEL
		@ nLin,060 COMBOBOX cComboTp ITEMS aComboTp WHEN .T. SIZE 80,07 OF _oJanela PIXEL
		@ nLin,170 Say "Forma Import:" SIZE 140,20 OF _oJanela PIXEL
		@ nLin,210 COMBOBOX cComboFor ITEMS aComboFor WHEN .T. SIZE 80,07 OF _oJanela PIXEL
		nLin+=15
		@ nLin,012 Say "Via Transp.:" SIZE 140,20 OF _oJanela PIXEL
		@ nLin,060 COMBOBOX cComboVia ITEMS aComboVia WHEN .T. SIZE 80,07 OF _oJanela PIXEL
		@ nLin,170 Say "Ato Concesso:" SIZE 140,20 OF _oJanela PIXEL
		@ nLin,210 MSGET cAtoCon WHEN .T. SIZE 80,07 OF _oJanela PIXEL
		nLin+=15
		@ nLin,012 Say "CNPJ Adquirente:" SIZE 140,20 OF _oJanela PIXEL
		@ nLin,060 MSGET cCNPJAd WHEN .T. SIZE 80,07 PICTURE "@R 99.999.999/9999-99" OF _oJanela PIXEL
		@ nLin,170 Say "UF Terceiro:" SIZE 140,20 OF _oJanela PIXEL
		@ nLin,210 MSGET cUFTer F3 "12" VALID Vazio().Or.ExistCpo("SX5","12"+cUFTer) WHEN .T. SIZE 80,07 OF _oJanela PIXEL
		nLin+=15
		@ nLin,012 Say "Transportadora:" SIZE 140,20 OF _oJanela PIXEL
		@ nLin,060 MSGET cTransp F3 "SA4" VALID Vazio().Or.ExistCpo("SA4") WHEN .T. SIZE 80,07 OF _oJanela PIXEL
		@ nLin,170 Say "Placa:" SIZE 140,20 OF _oJanela PIXEL
		@ nLin,210 MSGET cPlaca WHEN .T. SIZE 80,07 OF _oJanela PIXEL
		nLin+=15
		@ nLin,012 Say "Especie:" SIZE 140,20 OF _oJanela PIXEL
		@ nLin,060 MSGET cEspecie WHEN .T. SIZE 80,07 OF _oJanela PIXEL
		@ nLin,170 Say "Volume:" SIZE 140,20 OF _oJanela PIXEL
		@ nLin,210 MSGET nVolume WHEN .T. SIZE 80,07 OF _oJanela PIXEL
		nLin+=15
		@ nLin,012 Say "Peso Bruto:" SIZE 140,20 OF _oJanela PIXEL
		@ nLin,060 MSGET nPBruto WHEN .T. SIZE 80,07 PICTURE "@E 999,999,999,999.99" OF _oJanela PIXEL
		@ nLin,170 Say "Peso Liquido:" SIZE 140,20 OF _oJanela PIXEL
		@ nLin,210 MSGET nPLiqui WHEN .T. SIZE 80,07 PICTURE "@E 999,999,999,999.99" OF _oJanela PIXEL
		nLin+=25

		@ nLin,170 BUTTON "Confirmar" SIZE 50,12 ACTION(updSF1()) OF _oJanela PIXEL
		@ nLin,240 BUTTON "Cancelar" SIZE 50,12 ACTION(cancela()) OF _oJanela PIXEL

		Activate Dialog _oJanela Centered

		// Atualiza tabela CD5 - Complemento de Importacao caso tenha confirmado a tela de informações.
		If lRet
			updCD5()
			MsgInfo("Gravação concluída com sucesso.","AVISO")
		EndIf
	EndIf

	//Executa o Wizard do Acelerador de Mensagens da NF no final da geração da NF de Entrada
	If ExistBlock("MSGNF01",.F.,.T.)
		ExecBlock("MSGNF01",.F.,.T.,{})
	Endif

Return(lRet)

**************************
Static Function updSF1()
**************************
// Gravação dos campos da tela de informações na SF1
// Tem a opção de voltar na tela anterior

Local aOpc	:= {"Sim","Não"}
Local nOpc	:= 0
Local cTit	:= "ATENÇÃO!!!"
Local cMsg	:= "Deseja confirmar a operação? Após a confirmação não poderá ser mais alterada qualquer informação. Para voltar a tela anterior clique em NÃO."

	nOpc := Aviso(cTit,cMsg,aOpc)

	If nOpc == 1
		SF1->(RecLock("SF1",.F.))
			SF1->F1_ZZDI	:= cNrDI
			SF1->F1_ZZDIDT	:= dDtDI
			SF1->F1_ZZDIIMP	:= dDtPgImp
			SF1->F1_ZZDILD	:= cLocal
			SF1->F1_ZZDIUF	:= cUFLocal
			SF1->F1_ZZDIDD	:= dDtDesem
			SF1->F1_ZZDIDES	:= nVlrDes
			SF1->F1_ZZDIVIA	:= cComboVia
			SF1->F1_ZZDIAC	:= cAtoCon
			SF1->F1_ZZCNPJA	:= cCNPJAd
			SF1->F1_ZZUFTER	:= cUFTer
			SF1->F1_ZZTPIMP	:= cComboTp
			SF1->F1_ZZFORIM	:= cComboFor
			SF1->F1_TRANSP	:= cTransp
			SF1->F1_PLACA	:= cPlaca
			SF1->F1_ESPECI1	:= cEspecie
			SF1->F1_VOLUME1 := nVolume
			SF1->F1_PBRUTO	:= nPBruto
			SF1->F1_PLIQUI	:= nPLiqui
		SF1->(MsUnLock())

		lRet := .T.
		_oJanela:End()
	EndIf

Return(lRet)


**************************
Static Function updCD5()
**************************
// Gravação da CD5

Local aArea    	:= GetArea()
Local aAreaSD1  := SD1->(GetArea())
Local aAreaCD5  := CD5->(GetArea())

	dbSelectArea("CD5")
	dbsetorder(1)
	dbseek( xFilial("CD5") + SF1->(F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA))

	While CD5->(!Eof()) .AND. CD5->(CD5_DOC+CD5_SERIE+CD5_FORNEC+CD5_LOJA) == SF1->(F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA) .AND. CD5->CD5_FILIAL == xFilial("CD5")
		RecLock("CD5",.F.)
        	CD5->(dbDelete())
  		CD5->(MsUnlock("CD5"))

		CD5->(dbSkip())
	EndDo

	dbSelectArea("SD1")
	dbSetOrder(1) && D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
	dbSeek(xFilial("SD1")+ SF1->(F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA))

	While SD1->(!Eof()) .AND. SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA) == SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA) .AND. SD1->D1_FILIAL == xFilial("SD1")

		RecLock("CD5", .T.)
			CD5->CD5_FILIAL  :=  xFilial("CD5")
			CD5->CD5_DOC     :=  SF1->F1_DOC
			CD5->CD5_SERIE   :=  SF1->F1_SERIE
			CD5->CD5_ESPEC   :=  SF1->F1_ESPECIE
			CD5->CD5_FORNEC  :=  SF1->F1_FORNECE
	        CD5->CD5_LOJA    :=  SF1->F1_LOJA
			CD5->CD5_TPIMP   :=  SF1->F1_ZZTPIMP
			CD5->CD5_DOCIMP  :=  SF1->F1_ZZDI
			CD5->CD5_BSPIS   :=  SD1->D1_BASIMP6
		    CD5->CD5_ALPIS   :=  SD1->D1_ALQIMP6
		    CD5->CD5_VLPIS   :=  SD1->D1_VALIMP6
	     	CD5->CD5_BSCOF   :=  SD1->D1_BASIMP5
	        CD5->CD5_ALCOF   :=  SD1->D1_ALQIMP5
		    CD5->CD5_VLCOF   :=  SD1->D1_VALIMP5
		    CD5->CD5_LOCAL   :=  "0"
		    CD5->CD5_DTPPIS  :=  SF1->F1_ZZDIIMP
	    	CD5->CD5_DTPCOF  :=  SF1->F1_ZZDIIMP
			CD5->CD5_NDI     :=  SF1->F1_ZZDI
			CD5->CD5_DTDI    :=  SF1->F1_ZZDIDT
			CD5->CD5_LOCDES  :=  SF1->F1_ZZDILD
			CD5->CD5_UFDES   :=  SF1->F1_ZZDIUF
	    	CD5->CD5_DTDES   :=  SF1->F1_ZZDIDD
			CD5->CD5_CODEXP  :=  SF1->F1_FORNECE
			CD5->CD5_NADIC   :=  SD1->D1_ZZDIAD
			CD5->CD5_SQADIC  :=  SD1->D1_ZZDISE
			CD5->CD5_CODFAB  :=  IIf(!Empty(SD1->D1_ZZFABR),SD1->D1_ZZFABR,SF1->F1_FORNECE)
			CD5->CD5_BCIMP	 :=  SD1->D1_TOTAL
			CD5->CD5_VDESDI  :=  SF1->F1_ZZDIDES
			CD5->CD5_DSPAD	 :=  SD1->D1_ZZCPTZ
			CD5->CD5_VLRII	 :=  SD1->D1_II
			CD5->CD5_LOJFAB	 :=  IIf(!Empty(SD1->D1_ZZFABR),SD1->D1_ZZLJFAB,SF1->F1_LOJA)
			CD5->CD5_LOJEXP	 :=  SF1->F1_LOJA
			CD5->CD5_ACDRAW  :=  SF1->F1_ZZDIAC
			CD5->CD5_VAFRMM	 :=  SD1->D1_ZZAFRMM
			CD5->CD5_INTERM	 :=  SF1->F1_ZZFORIM
			CD5->CD5_CNPJAE	 :=  SF1->F1_ZZCNPJA
			CD5->CD5_UFTERC	 :=  SF1->F1_ZZUFTER
			CD5->CD5_ITEM	 :=  SD1->D1_ITEM
			CD5->CD5_VTRANS	 :=  SF1->F1_ZZDIVIA
			CD5->CD5_SDOC	 :=  SF1->F1_SERIE
		CD5->(MsUnlock("CD5"))
	SD1->(DbSkip())
	EndDo

	lRet := .T.

  	CD5->(RestArea(aAreaCD5))
  	SD1->(RestArea(aAreaSD1))
  	RestArea(aArea)

Return(lRet)


************************
Static Function cancela
************************
// Caso clique em cancelar, terá a opção de voltar para a tela anterior

Local aOpc	:= {"Sim","Não"}
Local nOpc	:= 0
Local cTit	:= "ATENÇÃO!!!"
Local cMsg	:= "Deseja mesmo cancelar a operação? Isso fará com que as informações da DI não sejam gravadas na nota fiscal. Clique em NÃO para voltar na tela anterior."

	nOpc := Aviso(cTit,cMsg,aOpc)

	If nOpc == 1
		lRet := .F.
		_oJanela:End()
	EndIf

Return(lRet)