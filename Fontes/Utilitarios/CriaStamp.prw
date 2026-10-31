#Include "prtopdef.ch"
#Include "TOTVS.CH"
#Include "TOPCONN.CH"

/*/{Protheus.doc} TESTE
Realiza a criação dos campos S_T_A_M_P_ e I_N_S_D_T_ sem a necessidade de 'dropar' e 'apendar' as tabelas…
@type function
@version 12.1.2210
@author Sangar Zucchi
@since 04/03/2024
@see https://tdn.totvs.com/pages/viewpage.action?pageId=563943271
@see https://tdn.totvs.com/display/tec/TCConfig
/*/
User Function CriaStamp()

Local aParamBox := {}
Local aRet      := {}
Local cTabAlias := ""
Local cTabList  := ""
Local aTabAlias := {}
Local aSucesso  := {}
Local aFalha    := {}
Local cTabSQL   := ""
Local cResumo   := ""
Local nI        := 0
Local lOkStamp  := .F.
Local lOkInsDt  := .F.
Private oMainWnd

aAdd(aParamBox, {1, "Tabelas (alias SX2, separadas por vírgula)", Space(80), "", "", "", "", 120, .T.})

If ! ParamBox(aParamBox, "Criação de STAMP/INSDT", @aRet)
	Return
EndIf

cTabList := Upper(AllTrim(aRet[1]))

If Empty(cTabList)
	FWAlertError("Informe ao menos um alias de tabela.", "CRIASTAMP")
	Return
EndIf

aTabAlias := CSTParse(cTabList)

If Len(aTabAlias) == 0
	FWAlertError("Nenhum alias válido foi informado.", "CRIASTAMP")
	Return
EndIf

// Montando o ambiente em caso de execução do código direto via VSCode ou chamada direta. Caso for chamar via menu, comentar o código 'RPC' abaixo:
// Realizando o login na Empresa 01 / Filial 0101
RpcClearEnv()
RpcSetType(3)
RpcSetEnv('01','0101','','','','',{})

// Conectando ao BD
TCLink()

// Consultando S_T_A_M_P_ e I_N_S_D_T_ para novas tabelas
xRet := TCConfig( 'GETUSEROWSTAMP' )//Consulta se a criação da coluna S_T_A_M_P_ para novas tabelas está habilitada, retorna 'ON' ou 'OFF'.
xRet := TCConfig( 'GETUSEROWINSDT' )//Consulta se a criação da coluna I_N_S_D_T_ para novas tabelas está habilitada, retorna 'ON' ou 'OFF'.

// Consultando S_T_A_M_P_ e I_N_S_D_T_ para abertura de tabelas
xRet := TCConfig( 'GETAUTOSTAMP' )//Consulta se a criação automática da coluna S_T_A_M_P_ na abertura da tabela está habilitada, retorna 'ON' ou 'OFF'.
xRet := TCConfig( 'GETAUTOINSDT' )//Consulta se a criação automática da coluna I_N_S_D_T_ na abertura da tabela está habilitada, retorna 'ON' ou 'OFF'.

// Habilitando S_T_A_M_P_ e I_N_S_D_T_ para novas tabelas
xRet := TCConfig( 'SETUSEROWSTAMP=ON' )//Permite ligar ou desligar a criação da coluna interna S_T_A_M_P_ para novas tabelas.
xRet := TCConfig( 'SETUSEROWINSDT=ON' )//Permite ligar ou desligar a criação da coluna interna I_N_S_D_T_ para novas tabelas.

// Habilitando S_T_A_M_P_ e I_N_S_D_T_ para abertura de tabelas
lOkStamp := (TCConfig('SETAUTOSTAMP=ON') == 'OK') .And. (TCConfig('SETUSEROWSTAMP=ON') == 'OK') //Permite habilitar a criação automática da coluna S_T_A_M_P_ na abertura da tabela.
lOkInsDt := (TCConfig('SETAUTOINSDT=ON') == 'OK') .And. (TCConfig('SETUSEROWINSDT=ON') == 'OK') //Permite habilitar a criação automática da coluna I_N_S_D_T_ na abertura da tabela.

If lOkStamp .Or. lOkInsDt
	For nI := 1 To Len(aTabAlias)
		cTabAlias := aTabAlias[nI]

		If ! ExisteSX2(cTabAlias)
			aAdd(aFalha, cTabAlias + " (não encontrada no SX2)")
			Loop
		EndIf

		// Abre a tabela em modo exclusivo para forçar a criação automática dos campos internos.
		cTabSQL := RetSQLName(cTabAlias)

		If Select(cTabAlias) > 0
			(cTabAlias)->(DbCloseArea())
		EndIf

		USE (cTabSQL) ALIAS (cTabAlias) EXCLUSIVE NEW VIA "TOPCONN"

		If ! NetErr()
			TCRefresh(cTabSQL)
			aAdd(aSucesso, cTabAlias)
		Else
			aAdd(aFalha, cTabAlias + " (não foi possível abrir em modo Exclusivo)")
		EndIf

		If Select(cTabAlias) > 0
			(cTabAlias)->(DbCloseArea())
		EndIf
	Next nI
Else
	FWAlertError("Não foi possível ativar os recursos de STAMP/INSDT no banco.", "CRIASTAMP")
EndIf

// Desabilitando S_T_A_M_P_ e I_N_S_D_T_ para novas tabelas
xRet := TCConfig( 'SETUSEROWSTAMP=OFF' )//Permite ligar ou desligar a criação da coluna interna S_T_A_M_P_ para novas tabelas.
xRet := TCConfig( 'SETUSEROWINSDT=OFF' )//Permite ligar ou desligar a criação da coluna interna I_N_S_D_T_ para novas tabelas.

// Desabilitando S_T_A_M_P_ e I_N_S_D_T_ para abertura de tabelas
xRet := TCConfig( 'SETAUTOSTAMP=OFF' )//Permite habilitar a criação automática da coluna S_T_A_M_P_ na abertura da tabela.
xRet := TCConfig( 'SETAUTOINSDT=OFF' )//Permite habilitar a criação automática da coluna I_N_S_D_T_ na abertura da tabela.

// Desconectando do BD
TCUnlink()

If Len(aSucesso) > 0
	cResumo := "Sucesso: " + CSTJoin(aSucesso)
	If Len(aFalha) > 0
		cResumo += Chr(13) + Chr(10) + "Falhas: " + CSTJoin(aFalha)
	EndIf
	FWAlertSuccess(cResumo, "CRIASTAMP")
ElseIf Len(aFalha) > 0
	FWAlertError("Nenhuma tabela processada com sucesso." + Chr(13) + Chr(10) + "Falhas: " + CSTJoin(aFalha), "CRIASTAMP")
EndIf

Return

Static Function CSTParse(cLista)
Local aAlias := {}
Local cWork  := ""
Local cItem  := ""
Local nPos   := 0

cWork := Upper(AllTrim(cLista))
cWork := StrTran(cWork, ";", ",")

Do While ! Empty(cWork)
	nPos := At(",", cWork)

	If nPos > 0
		cItem := AllTrim(SubStr(cWork, 1, nPos - 1))
		cWork := SubStr(cWork, nPos + 1)
	Else
		cItem := AllTrim(cWork)
		cWork := ""
	EndIf

	If ! Empty(cItem) .And. AScan(aAlias, {|cAlias| cAlias == cItem}) == 0
		aAdd(aAlias, cItem)
	EndIf
EndDo

Return aAlias

Static Function CSTJoin(aLista)
Local cRet := ""
Local nI   := 0

For nI := 1 To Len(aLista)
	If ! Empty(cRet)
		cRet += ", "
	EndIf
	cRet += aLista[nI]
Next nI

Return cRet
