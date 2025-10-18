#include 'protheus.ch'
#include 'parmtype.ch'
/*---------------------------------------------------------------------------------------------
{Protheus.doc}  M410STTS
                Este ponto de entrada pertence � rotina de pedidos de venda, MATA410().
                Est� em todas as rotinas de inclus�o, altera��o, exclus�o, c�pia e devolu��o 
                de compras.
                Executado ap�s todas as altera��es no arquivo de pedidos terem sido feitas
@type           function
@version        1.1
@author         Carlos Eduardo Saturnino - Atlanta Consulting
@since          07/04/2022
-----------------------------------------------------------------------------------------------
@version        1.2
@author         Cyberpolos
@since          18/01/2023
                Adicionado trecho para tratar da libera��o automaticas de pedidos de venda na 
                inclus�o, esses pedidos devem ter o campo SC5->C5_ZZTPPED == 'PE'.
---------------------------------------------------------------------------------------------*/
user function M410STTS()
	
	Local _nOper 		 := PARAMIXB[1]
	Local _cFilial		 := SC5->C5_FILIAL
	Local _cPedido		 := SC5->C5_NUM
    Local aArea     	 := GetArea()
    Local aAreaC5   	 := SC5->(GetArea())
    Local aAreaC6   	 := SC6->(GetArea())
    Local aAreaC9   	 := SC9->(GetArea())
				
	/*******************************************
	3 - Inclus�o
	4 - Altera��o
	5 - Exclus�o
	6 - Copia
	7 - Devolu��o de Compras
	/*******************************************/	

	
	If reclock("SC5", .F.)
		SC5->C5_STATU1  := cValtoChar(_nOper) // Campo de Controle do Acacias
		SC5->C5_ZSTATUS := cValtoChar(_nOper) // Suntech (Ricardo Araujo) - Gravar campo de controle para Integracao via API 17/01/2023
		SC5->(MsUnlock())
	Endif
	
	//---------------------------------------------------------
	// Posiciona nos itens do pedido de vendas
	//---------------------------------------------------------

	DBSelectArea("SC6")
	dbSetOrder(1)
	dbGoTop()
	If dbSeek(SC6->(C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO))
		While ! SC6->(Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == _cFilial + _cPedido .And. SC6->D_E_L_E_T_ <> '*'
			//---------------------------------------------------------
			// Efetua a grava��o dos itens do pedido de Vendas
			//---------------------------------------------------------
			If SC6->(Reclock("SC6", .F.))
				SC6->C6_STATU1  := cValtoChar(_nOper) // Campo de Controle do Acacias
				SC6->C6_ZSTATUS := cValtoChar(_nOper) // Suntech (Ricardo Araujo) - Gravar campo de controle para Integracao via API 17/01/2023
			Endif
			SC6->(MsUnlock())
			SC6->(Dbskip())
		EndDo
	Endif

    //Cyberpolos 18/01/2023 (Inicio)
    //| Trecho add para realizar a libera��o automatica de pedidos de vendas do tipo SC5->C5_ZZTPPED == 'PE'

    if _nOper = 3 .and. Alltrim(SC5->C5_ZZTPPED) == 'PE'

		//Gravo informa��es na SC5
		SC5->(reclock("SC5", .F.))
			SC5->C5_ZZSITFI := '2' //Liberado
			SC5->C5_ZZSITCO := '1' //Comercial Ok
		SC5->(MsUnlock())

        DbSelectArea("SC6")
		DbSetOrder(1)			
        SC6->(dbGotop())
				
		//posiciono na sc6 e realizo a libera���o item a item
		if MsSeek(xFilial("SC6")+SC5->C5_NUM)
            while SC6->(!EOF()) .and. SC5->C5_NUM == SC6->C6_NUM
                MaLibDoFat(SC6->(RecNo()),(SC6->C6_QTDVEN-SC6->C6_QTDENT),.F.,.F.,.T.,.T.) 
                SC6->(MaLiberOk({SC6->C6_NUM},.T.))
                SC6->(Dbskip())
            enddo
        endif
    endif

    RestArea(aAreaC9)
    RestArea(aAreaC6)
    RestArea(aAreaC5)
    RestArea(aArea)
    //Cyberpolos 18/01/2023 (Fim)

return
