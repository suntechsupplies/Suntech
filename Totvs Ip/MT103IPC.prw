#include "rwmake.ch"

/**
 * Este Ponto de Entrada tem por objetivo atualizar os campos customizados no Documento de Entrada e na Pr� Nota de Entrada 
 *  ap�s a importa��o dos itens do Pedido de Compras (SC7).
 * Sera atualizada a descricao do produto
 *
 * @author Dione Oliveira
 * @since 28/08/2019
 */
 
User Function MT103IPC

	Local nPosAtual := PARAMIXB[1]
	Local nPosDescr := aScan(aHeader,{|x| Alltrim(x[2])== "D1_ZZDESC"})

	If nPosDescr > 0
		aCols[nPosAtual,nPosDescr] := SC7->C7_DESCRI
	Endif

Return      