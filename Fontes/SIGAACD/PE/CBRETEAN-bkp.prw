#include "protheus.ch"
#include "apvt100.ch"

/*
 * Rotina:		CBRETEAN
 * Autor:	
 * Data:		19/09/2013
 * Descri��o:	Rotina respons�vel por quebrar o C�digo de barras em partes necess�rias a buscar a quantidade na tabela SLK.
 * Retorno:		{"C�digo do Produto", "Quantidade", "Lote", "Data de Validade", "N�mero de S�rie"}
 				{"C�digo do Produto","Quantidade","Lote","Data de Validade","N�mero de S�rie","Endereco Destino"}
 */
 
User Function CBRETEAN()
    Local cCodBar     := AllTrim(PARAMIXB[1])                                               // C�digo da etiqueta lida
    Local cProduto    := Posicione("ZZ2", 1, xFilial("ZZ2") + cCodBar   , "ZZ2_PRODUT"  )   // Carlos Eduardo Saturnino em 08/04/2022
    Local nQuant      := Posicione("ZZ2", 1, xFilial("ZZ2") + cCodBar   , "ZZ2_QUANT"   )   // Carlos Eduardo Saturnino em 08/04/2022
    Local cEndDest    := Posicione("SB1", 1, xFilial("SB1") + cProduto  , "B1_LOCPAD"  )    // Carlos Eduardo Saturnino em 08/04/2022
    Local cLote       := ""
    Local dValid      := CToD("")
    Local cNumSer     := ""
    Local aRet        := {}

    aRet   := {cProduto, nQuant, cLote, dValid, cNumSer,/*cEndDest*/}

Return(aRet)
