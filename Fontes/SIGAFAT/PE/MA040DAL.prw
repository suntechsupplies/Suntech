#Include "Protheus.ch"
 
/*--------------------------------------------------------------------------------------------------------------*
 | P.E.:  MA040DAL                                                                                              |
 | Desc:  Este ponto de entrada pertence � rotina de manuten��o do cadastro de vendedores, MATA040.             | 
 |        Ele � executado na rotina de altera��o (MA040ALT), ap�s a grava��o dos dados do vendedor.             |
 | Link:  http://tdn.totvs.com/pages/releaseview.action?pageId=6784256                                          |
 | Autor: Antonio Ricardo de Araujo - Suntech 22/06/2023                                                        |
 *--------------------------------------------------------------------------------------------------------------*/
 
User Function MA040DAL()
    Local aArea := GetArea()
    Local aAreaA3 := SA3->(GetArea())
    Local lRet := .T.
     
	DbSelectArea("SA3")
	DbSetOrder(3)
	If dbSeek(xFilial("SA3")+SA3->A3_CGC)
		RECLOCK("SA3",.F.)
			SA3->A3_ZSTATUS := "4"
		MSUNLOCK()
	Endif
     
    RestArea(aAreaA3)
    RestArea(aArea)
Return lRet
