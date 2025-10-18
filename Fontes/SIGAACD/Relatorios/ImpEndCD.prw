#Include 'Protheus.ch'
#include 'topconn.ch'
#Include 'TbiConn.ch'
#Include 'Rwmake.ch'

/*/{protheus.doc}ImpEnd
Impressão de etiquetas de endereçamento
/*/

#DEFINE VELOCIDADE_IMPRESSORA 4
#DEFINE NLININI	 004
#DEFINE NQUEBNOR 004

User Function ImpEndCD

	Local aPergs   := {}
	Local nImpress := 0
	Local cPorta   := "LPT1" //u_GetPar("ZZ_PORT01","LPT1","C","Porta utilizada para impressão de etiquetas")

	local nQtdEtiq := 1
	local nLinha   := NLININI
	local nColuna  := 003
	Local nQuebra  := NQUEBNOR
	local aDados   := {}
	local lSeg     := .F.

	private cZPL

	AADD(aPergs,{1,"Local de",CriaVar("BE_LOCAL",.F.),"@!",'.T.',"DBE",'.T.',80,.F.})
	AADD(aPergs,{1,"Endereço de",CriaVar("BE_LOCALIZ",.F.),"@!",'.T.',,'.T.',80,.F.})
	AADD(aPergs,{1,"Local até",CriaVar("BE_LOCAL",.F.),"@!",'.T.',"DBE",'.T.',80,.F.})
	AADD(aPergs,{1,"Endereço até",CriaVar("BE_LOCALIZ",.F.),"@!",'.T.',,'.T.',80,.F.})

	If ParamBox(aPergs,"Parametros",{},,,,,,,"ImpEnd",.f.,.f.)

		MSCBPRINTER("ZEBRA",cPorta,,,.f.,,,,,,)
		MSCBCHKSTATUS(.f.)

		aDados := buscaDados()

		if aDados[1,3] > 0
			nImpress := aDados[1,3]
		endif

		MSCBBEGIN(nQtdEtiq,VELOCIDADE_IMPRESSORA)

		for nI := 1 to nImpress

			nLinha  := NLININI

			if lSeg
				MSCBBEGIN(nQtdEtiq,VELOCIDADE_IMPRESSORA)
				nColuna := 003
				nLinha  := NLININI
				lSeg := .F.
			endif

			if cValToChar(Mod(nI,2)) == "0"
				nColuna := 052
				lSeg := .T.
			endif

			MSCBSAYBAR(nColuna+7,nLinha,Alltrim(aDados[nI, 1]+aDados[nI, 2]),"N","MB07",10,.F.,.F.,.F.,,3,1,.F.,.F.,"1",.T.) // Código Barras EAN
			nLinha := nLinha + 15
			MSCBSAY(nColuna+20,nLinha,Alltrim(aDados[nI, 2]),"N","0","045",,,,,.t.)

			if lSeg .OR. nI == nImpress
				MSCBInfoEti("ImpEndCD","100X100")
				cZPL := MSCBEND()
				//MSCBCLOSEPRINTER()
			endif

		next nI

		MSCBCLOSEPRINTER()

	Endif

Return

static function buscaDados()

	local cQuery := ""
	local cAlias := getNextAlias()
	local aSBE   := {}
	local nRegs  := 0

	cQuery := " SELECT BE_LOCAL " + CRLF
	cQuery += "      , BE_LOCALIZ " + CRLF
	cQuery += "   FROM " + retSqlName( "SBE" ) + "  " + CRLF
	cQuery += "  WHERE D_E_L_E_T_ = '' " + CRLF
	cQuery += "    AND BE_FILIAL  = '" + xFilial("SBE") + "'" + CRLF
	cQuery += "    AND BE_LOCAL	>= '" + mv_par01 + "' " + CRLF
	cQuery += "    AND BE_LOCAL	<= '" + mv_par03 + "' " + CRLF
	cQuery += "    AND BE_LOCALIZ	>= '" + mv_par02 + "' " + CRLF
	cQuery += "    AND BE_LOCALIZ	<= '" + mv_par04 + "' " + CRLF
	cQuery += "  ORDER BY BE_LOCAL " + CRLF
	cQuery += "         , BE_LOCALIZ " + CRLF

	TcQuery cQuery New Alias (cAlias)

	Count To nRegs

	(cAlias)->(DbGoTop())

	while (cAlias)->(!eof())
		aAdd(aSBE, {(cAlias)->BE_LOCAL, (cAlias)->BE_LOCALIZ, nRegs})
		(cAlias)->(dbSkip())
	enddo

	(cAlias)->(dbCloseArea())

return aSBE

user function xPTO3()

	rpcClearEnv()
	//RpcSetEnv("99","01")
	RPCSetEnv("01", "02", "admin", "agis9", "EST")
	Define MSDialog oMainWND from 0,0 to 400, 500 pixel
	@ 5,5 button "ImpEndCD" of oMainWND pixel action U_ImpEndCD()
	Activate MSDialog oMainWND

return