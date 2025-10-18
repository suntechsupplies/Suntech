#INCLUDE 'TOTVS.CH'
#INCLUDE 'TOPCONN.CH'

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

Private oMainWnd

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
xRet := TCConfig( 'SETAUTOSTAMP=ON' )//Permite habilitar a criação automática da coluna S_T_A_M_P_ na abertura da tabela.
xRet := TCConfig( 'SETAUTOINSDT=ON' )//Permite habilitar a criação automática da coluna I_N_S_D_T_ na abertura da tabela.

// Abrindo as tabelas que desejo criar os campos S_T_A_M_P_ e I_N_S_D_T_ automaticamente sem necessidade de 'DROPAR' e 'APENDAR' elas:
dbSelectArea('SB2')

// Desabilitando S_T_A_M_P_ e I_N_S_D_T_ para novas tabelas
xRet := TCConfig( 'SETUSEROWSTAMP=OFF' )//Permite ligar ou desligar a criação da coluna interna S_T_A_M_P_ para novas tabelas.
xRet := TCConfig( 'SETUSEROWINSDT=OFF' )//Permite ligar ou desligar a criação da coluna interna I_N_S_D_T_ para novas tabelas.

// Desabilitando S_T_A_M_P_ e I_N_S_D_T_ para abertura de tabelas
xRet := TCConfig( 'SETAUTOSTAMP=OFF' )//Permite habilitar a criação automática da coluna S_T_A_M_P_ na abertura da tabela.
xRet := TCConfig( 'SETAUTOINSDT=OFF' )//Permite habilitar a criação automática da coluna I_N_S_D_T_ na abertura da tabela.

// Desconectando do BD
TCUnlink()

FWAlertSuccess("Campos criados com Sucesso na Tabela SB2!", "CRIASTAMP")

Return
