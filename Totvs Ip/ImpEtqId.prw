#Include "RwMake.ch"
#Include 'Protheus.ch'
#Include 'Topconn.ch'

 /*/{Protheus.doc} ImpEtqId
Impressão de etiquetas de identificação do volume temporário.

@author    Lucas Assis Mendes
@since    31/10/2013
@return    Nil
/*/
User Function ImpEtqId(aDados)

	Local __cVolume 	:= aDados[1]
	Local cPedido 		:= aDados[2]
	Local cNota   		:= IF(len(aDados)>=3,aDados[3],nil)
	Local cSerie  		:= IF(len(aDados)>=4,aDados[4],nil)
	Local cID     		:= ""
	Local _lPrimeiro 	:= .T.
	Local sConteudo

	If Upper(Alltrim(FunName())) == "ACDV177"
		If Type("_lPassou") == "U"
			Public _lPassou := .T.
		Else
			_lPrimeiro := .F.
		Endif
	Endif

	If _lPrimeiro
		cID := CBGrvEti('05',{__cVolume,cPedido,cNota,cSerie})

		MSCBBEGIN(1,3)
		MSCBBOX(01,02,34,76,1)
		MSCBLineV(30,30,76,1)
		MSCBLineV(23,02,76,1)
		MSCBLineV(15,02,76,1)
		MSCBLineH(23,30,34,1)
		MSCBSAY(32,33,"VOLUME","R","2","01,01")
		MSCBSAY(29,33,"CODIGO","R","2","01,01")
		MSCBSAY(26,33, __cVolume, "R", "2", "01,01")
		If cNota == NIL
			MSCBSAY(22,05,"Pedido","R","2","01,01")
			MSCBSAY(19,05,cPedido,"R", "2", "01,01")
		Else
			MSCBSAY(22,05,"Nota","R","2","01,01")
			MSCBSAY(19,05,cNota+ ' '+cSerie,"R", "2", "01,01")
		EndIf
		MSCBSAYBAR(12,22,cId,"R","MB07",8.36,.F.,.T.,.F.,,2,2,.F.,.F.,"1",.T.)
		MSCBInfoEti("Volume Temp.","30X100")
		sConteudo := MSCBEND()
	Endif

	cVolume := aDados[1]
	
Return(_lPrimeiro)