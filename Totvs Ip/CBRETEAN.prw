#include "protheus.ch"
#include "apvt100.ch"

/*
 * Rotina:		CBRETEAN
 * Autor:	
 * Data:		19/09/2013
 * Descrição:	Rotina responsável por quebrar o Código de barras em partes necessárias a buscar a quantidade na tabela SLK.
 * Retorno:		{"Código do Produto", "Quantidade", "Lote", "Data de Validade", "Número de Série"}
 				{"Código do Produto","Quantidade","Lote","Data de Validade","Número de Série","Endereco Destino"}
 */
 
User Function CBRETEAN()

      Local cCod        := AllTrim(PARAMIXB[1]) && Código da etiqueta lida
      Local cProduto    := Posicione("ZZ2", 3, xFilial("ZZ2") + cCod, "ZZ2_PRODUT"  )
      Local nQuant      := Posicione("ZZ2", 3, xFilial("ZZ2") + cCod, "ZZ2_QUANT"   )
      Local cLote       := ""
      Local dValid      := CToD("")
      Local cNumSer     := ""
      Local aRet        := {}

      aRet   := {cProduto, nQuant, cLote, dValid, cNumSer}

Return(aRet) 
