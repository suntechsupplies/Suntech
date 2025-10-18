#include 'protheus.ch'
#include 'parmtype.ch'
#include "tcbrowse.ch"
#include "topconn.ch"
#include "rwmake.ch"

user function cartaAnu()

	Private x := 72 / 2.54
	Private oPrinter  := Nil
	Private nLin	  := 0
	Private nLeft     := 1
	Private oFont10   := TFont():New("Arial", 10, 10,, .F.,,,,, .F., .F.)
	Private oFont10N  := TFont():New("Arial", 10, 10,, .T.,,,,, .F., .F.)
	Private oFont12   := TFont():New("Arial", 12, 12,, .F.,,,,, .F., .F.)
	Private oFont12N  := TFont():New("Arial", 12, 12,, .T.,,,,, .F., .F.)
	Private oFont14   := TFont():New("Arial", 14, 14,, .F.,,,,, .F., .F.)
	Private oFont14N  := TFont():New("Arial", 14, 14,, .T.,,,,, .F., .F.)
	Private oFont18N  := TFont():New("Times New Roman", 18, 18,, .T.,,,,, .F., .F.) //  Define a fonte
	Private nInicio   := 0000  // Indica a posição da primeira coluna

	Private oOk      := LoadBitmap( nil, "LBOK" )
	Private oNo      := LoadBitmap( nil, "LBNO" )

	Private cCliente
	Private cLoja
	Private cRepr
	Private cCPF
	Private cRG
	Private nEsp

	Private oDlg
	Private aBrowse
	Private nMarcado := .F.
	Private aDados := {}

	If ValidPerg()
		Processa({|| relAnu() }, "Aguarde...", "Imprimindo...",.F.)
	EndIf

return

static function relAnu()

	if MV_PAR03 == "José Ubaldo"
		cRepr := "JOSÉ UBALDO LOMONACO NETO"
		cCPF  := "007.032.468-95"
		cRG   := "9.979.016"
		nEsp  := 0250
	elseif MV_PAR03 == "José de Anchieta"
		cRepr := "JOSÉ DE ANCHIETA DA COSTA AGUIAR TOSCHI"
		cCPF  := "003.777.728-95"
		cRG   := "6.434.860"
		nEsp  := 0210
	endif

	oPrinter := FWMSPrinter():New("carta_anuencia_"+dToS(date()) + strTran(time(), ":", "")+".rel",6,.f.,,.t.,.f.,,,.f.,,,.t.)

	oPrinter:StartPage()
	imprRel()
	oPrinter:EndPage()

	oPrinter:Preview()

return

static function imprRel()

	impCabLogo()
	impCabecalho()

return

static function impCabLogo()

	nLin := 0010

	dbSelectArea("SM0")
	SM0->(dbseek(cEmPant + cFilant))

	// oPrinter:Say(Linha, Coluna, Texto, Fonte, Tamanho em Pixel)
	oPrinter:SayBitmap(nLin, nLeft*x, "/SYSTEM/logo_suntech.jpg", 3*x, 2*x )
	nLin += 0020
	oPrinter:Say(nLin, nInicio + 0135, SM0->M0_NOMECOM, oFont14N)
	nLin += 0020
	oPrinter:Say(nLin, nInicio + 0160, AllTrim(SM0->M0_ENDCOB) + ' - ' + AllTrim(M0_BAIRCOB) + ' - ' + alltrim(SM0->M0_CIDCOB) + " - " + SM0->M0_ESTCOB + ". CEP " + Transform(SM0->M0_CEPCOB,"@R 99999-999"), oFont10N)
	nLin += 0010
	oPrinter:Say(nLin, nInicio + 0240,"CNPJ: " + Transform(SM0->M0_CGC,"@R 99.999.999/9999-99") + " - IE: " + SM0->M0_INSC,oFont10N)
	nLin += 0010
	oPrinter:Say(nLin, nInicio + 0280, "Tel: " + AllTrim(SM0->M0_TEL), oFont10N)
	nLin += 0010
	oPrinter:Box(nLin, 5, nLin, 580) // linha horizontal

return

static function impCabecalho()

	local cData      := ""
	local dDataAtual := dDataBase
	local cTexto     := ""
	local aTexto     := {}

	nLin += 0020
	oPrinter:Say(nLin, nInicio + 0250, "CARTA DE ANUÊNCIA", oFont14N)
	nLin += 0010
	oPrinter:Say(nLin, nInicio + 0270, "(Liberação de Protesto)", oFont10N)

	cData := cValToChar(Day(dDataAtual))
	cData += " de "
	cData += MesExtenso(dDataAtual)
	cData += " de "
	cData += cValToChar(Year(dDataAtual))

	nLin += 0020

	POSICIONE("SA1", 1, xFilial("SA1")+cCliente+cLoja, "!eof()")

	oPrinter:Say(nLin, nInicio+0010, "Itupeva (SP)," + cData, oFont12)

	nLin += 0020
	oPrinter:Say(nLin, nInicio+0010, "Ilmo. Sr.", oFont12)
	nLin += 0015
	oPrinter:Say(nLin, nInicio+0010, "Titular do Tabelião de Protesto de Título", oFont12)
	nLin += 0015
	oPrinter:Say(nLin, nInicio+0010, AllTrim(SA1->A1_MUN) + "/" + AllTrim(SA1->A1_EST), oFont12)
	nLin += 0020

	cTexto := "A Suntech Supplies Ind. e Com. Prod. Óticos e Esp. Ltda, neste ato representada pelo sócio: " + cRepr
	cTexto += ", portador do RG: " + cRG + " - SSP/SP e CPF/MF: " + cCPF + " declara que a empresa: "

	aTexto := charToImp(cTexto, 118)

	for nX := 1 to len(aTexto)
		oPrinter:Say(nLin, nInicio + 0010, AllTrim(aTexto[nX]), oFont12 )
		nLin += 0015
	next nX

	nLin += 0020

	oPrinter:Say(nLin, nInicio+0010, "SACADO: " + SA1->A1_NOME, oFont12N)
	nLin += 0015
	oPrinter:Say(nLin, nInicio+0010, "CNPJ/CPF: " + SA1->A1_CGC, oFont12)
	nLin += 0015
	oPrinter:Say(nLin, nInicio+0010, "END. COBR: " + AllTrim(SA1->A1_END) + " - " + AllTrim(SA1->A1_BAIRRO) + " - " + AllTrim(SA1->A1_MUN) + "/" + SA1->A1_EST, oFont12)
	nLin += 0020
	oPrinter:Say(nLin, nInicio+0010, "Liquidou sua dívida, referente ao(s) título(s) abaixo discriminado(s) protestado por este Cartório.", oFont12)
	nLin += 0020
	oPrinter:Say(nLin, nInicio+0010, "Nº Duplicata", oFont12N)
	oPrinter:Say(nLin, nInicio+0160, "Data Emissão", oFont12N)
	oPrinter:Say(nLin, nInicio+0310, "Vencimento Real", oFont12N)
	oPrinter:Say(nLin, nInicio+0510, "Valor", oFont12N)
	nLin += 0020

	if !Empty(aDados)
		for nI := 1  to len(aDados)
			if aDados[nI,1] == .T.
				oPrinter:Say(nLin, nInicio+0010, aDados[nI,2], oFont12)
				oPrinter:Say(nLin, nInicio+0160, aDados[nI,3], oFont12)
				oPrinter:Say(nLin, nInicio+0310, aDados[nI,4], oFont12)
				oPrinter:Say(nLin, nInicio+0490, Transform(aDados[nI,5], "@E 999,999.99"), oFont12)
				nLin += 0010
			endif
		next nI
	endif

	nLin += 0020

	cTexto := "Portanto nada temos a opor contra o cancelamento do protesto do(s) título(s) acima especificados, "
	cTexto += "por ser pura expressão da verdade e para que surta efeitos legais, assinamos a presente carta de "
	cTexto += "anuência nos termos da Lei 9.492 de 10/09/1997."

	aTexto := charToImp(cTexto, 128)

	for nY := 1 to len(aTexto)
		oPrinter:Say(nLin, nInicio + 0010, AllTrim(aTexto[nY]), oFont12 )
		nLin += 0015
	next nY

	nLin += 0020

	oPrinter:Say(nLin, nInicio+0010, "Cordialmente,", oFont12)

	nLin += 0030

	oPrinter:Say(nLin, nInicio+0150, "________________________________________________________________", oFont12)
	nLin += 0020
	oPrinter:Say(nLin, nInicio+nEsp, cRepr, oFont12N)

return

Static Function ValidPerg()

	Local aRet		:= {}
	Local aParamBox	:= {}
	Local lRet 		:= .F.
	local aRepr     := {"José Ubaldo", "José de Anchieta"}
	local aButtons  := {}

	aAdd(aParamBox,{1,"Código Cliente ",space(getSX3Cache("A1_COD","X3_TAMANHO")),"","","SA1","",50,.T.}) //MV_PAR01
	aAdd(aParamBox,{1,"Loja ",space(getSX3Cache("A1_LOJA","X3_TAMANHO")),"","","","",50,.T.}) //MV_PAR02
	aAdd(aParamBox,{2,"Representante","José Ubaldo",aRepr,80,"",.T.}) //MV_PAR03

	aAdd(aButtons,{17,{||buscaDupl(MV_PAR01, MV_PAR02)},})

	If ParamBox(aParamBox,"Carta Anuência",@aRet,,aButtons,,,,,"cartaAnu",.T.,.T.)
		lRet := .t.
		cCliente := MV_PAR01
		cLoja    := MV_PAR02
	EndIf

Return lRet

static function charToImp(cString,nQtdChar)
	local aRet 	:= {}
	local nLine := 0
	local nCount := MlCount( cString,nQtdChar )

	if nCount == 0
		aRet := {""}
	else
		For nLine := 1 To nCount
			aAdd(aRet,MemoLine(cString,nQtdChar,nLine))
		Next nLine
	endif
return aRet

static function buscaDupl(cCliente, cLoja)

	local cQuery  := ""
	local cAlias  := getNextAlias()
	local aBrowse := {}

	cQuery := " SELECT E1_NUM " + CRLF
	cQuery += "      , CASE WHEN E1_PARCELA = '' THEN '00' ELSE E1_PARCELA END AS PARCELA " + CRLF
	cQuery += "      , SUBSTRING(E1_EMISSAO,7,2)+'/'+SUBSTRING(E1_EMISSAO,5,2)+'/'+SUBSTRING(E1_EMISSAO,1,4) AS EMISSAO " + CRLF
	cQuery += "      , SUBSTRING(E1_VENCTO,7,2)+'/'+SUBSTRING(E1_VENCTO,5,2)+'/'+SUBSTRING(E1_VENCTO,1,4) AS VENCTO " + CRLF
	cQuery += "      , E1_VALOR " + CRLF
	cQuery += "   FROM " + retSqlName("SE1") + " SE1" + CRLF
	cQuery += "  WHERE E1_CLIENTE = '" + cCliente + "'" + CRLF
	cQuery += "    AND E1_LOJA = '" + cLoja + "'" + CRLF
	cQuery += "    AND E1_BAIXA <> '' " + CRLF
	cQuery += "    AND " + retSqlDel("SE1") + CRLF
	cQuery += "    AND " + retSqlFil("SE1") + CRLF

	TcQuery cQuery New Alias (cAlias)

	while (cAlias)->(!eof())

		aAdd(aBrowse, {.F., (cAlias)->E1_NUM+" / "+(cAlias)->PARCELA, (cAlias)->EMISSAO,(cAlias)->VENCTO,(cAlias)->E1_VALOR})
		(cAlias)->(dbSkip())
	enddo

	(cAlias)->(dbCloseArea())

	mostraBrw(aBrowse)

return aBrowse

static function mostraBrw(aBrowse)

	If !Empty(aBrowse)

		Define MsDialog oDlg From 0,0 to 380,800 Title "Duplicatas" Pixel
		oBrowse := TCBrowse():New( 010 ,001,400,150,,,,oDlg,,,,,{||},,,,,,,.F.,,.T.,,.F.,,,)
		oBrowse:SetArray(aBrowse)
		oBrowse:AddColumn(TCColumn():New(' ',{|| if(aBrowse[oBrowse:nAt,1],oOk,oNo) },,,,"LEFT",10,.T.,.T.,,,,.F.,))
		oBrowse:AddColumn(TCColumn():New('Duplicata',{||aBrowse[oBrowse:nAt,2] },,,,'LEFT',,.F.,.F.,,,,.F.,  ))
		oBrowse:AddColumn(TCColumn():New('Data Emissão',{||aBrowse[oBrowse:nAt,3] },,,,'LEFT',,.F.,.F.,,,,.F.,  ))
		oBrowse:AddColumn(TCColumn():New('Vencto Real',{||aBrowse[oBrowse:nAt,4] },,,,'LEFT',,.F.,.F.,,,,.F.,  ))
		oBrowse:AddColumn(TCColumn():New('Valor',{||aBrowse[oBrowse:nAt,5] },,,,'LEFT',,.F.,.F.,,,,.F.,  ))

		oBrowse:bHeaderClick := {|o,x| marcaCkb(aBrowse) , oBrowse:refresh()}
		oBrowse:bLDblClick   := {|z,x| aBrowse[oBrowse:nAt,1] := alteraCkb(aBrowse[oBrowse:nAt,1] ) }

		TButton():New( 170, 250, "Marcar Todos"	, oDlg,{||markAll(aBrowse) },40,010,,,.F.,.T.,.F.,,.F.,,,.F. )
		TButton():New( 170, 295, "Selecionar"	, oDlg,{|| validProc(aBrowse) },40,010,,,.F.,.T.,.F.,,.F.,,,.F. )
		TButton():New( 170, 340, "Fechar"	, oDlg,{|| oDlg:End() },40,010,,,.F.,.T.,.F.,,.F.,,,.F. )

		Activate MsDialog oDlg Centered

	Else
		aviso("Aviso","Não existem duplicatas para este Cliente",{"OK"})
	Endif

return

/*******************************************************************
* Controle de selecao de todas as pendencias                      *
*******************************************************************/
Static function markAll(aBrowse)

	local nI 		:= 0
	local nMarks	:= 0

	for nI := 1 to Len(aBrowse)
		if aBrowse[nI,1]
			nMarks++
		endIf
	next nI

	for nI := 1 to Len(aBrowse)
		aBrowse[nI,1] := (nMarks < Len(aBrowse))
	next nI

	oBrowse:refresh()

return

/*******************************************************************
* Controle de Marcações no browse                                 *
*******************************************************************/
Static Function marcaCkb(aBrowse)

	If nMarcado == .T.
		For i := 1 to len(aBrowse)
			aBrowse[i,1] := .F.
		next i
		nMarcado    := .F.
	Else
		For i := 1 to len(aBrowse)
			aBrowse[i,1] := .T.
		Next i
		nMarcado    := .T.
	Endif
Return

/*******************************************************************
* Controle de Marcações no browse                                 *
*******************************************************************/
Static Function alteraCkb(varCkb)

	If varCkb == .T.
		varCkb := .F.
	Else
		varCkb := .T.
	Endif

Return varCkb

/*******************************************************************
* Valida duplicatas selecionadas                                  *
*******************************************************************/
Static function validProc(aBrowse)

	if !existMarks(aBrowse)
		MsgBox("Nenhuma Duplicata Selecionada", "Atenção", "ALERT")
		return
	endIf

	if !MsgBox("Confirma as Duplicatas selecionadas ?", "Atenção", "YESNO")
		return
	endIf

	aDados := aBrowse
	oDlg:end()

	/*
	Msaguarde({|| EnviaPen(aBrowse,cMotivo1,cTipo), oDlg:end() }, "Aguarde", "Enviando Pendências....")
	*/
return

/*******************************************************************
* Verifica se o usuario selecionou ao menos uma duplicata         *
*******************************************************************/
static function existMarks(aBrowse)

	local nI	 := 0
	local lExist := .F.

	for nI := 1 to Len(aBrowse)
		if aBrowse[nI,1]
			lExist := .T.
			exit
		endIf
	next nI

return lExist

/*
user function xPTO4()

rpcClearEnv()
//RpcSetEnv("99","01")
RPCSetEnv("01", "01", "admin", "agis9", "EST")
Define MSDialog oMainWND from 0,0 to 400, 500 pixel
@ 5,5 button "cartaAnu" of oMainWND pixel action U_cartaAnu()
Activate MSDialog oMainWND

return
*/