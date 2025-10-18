//Bibliotecas
#Include "Protheus.ch"
#Include "Totvs.ch"
#Include "FWMBROWSE.ch"
#Include "FWMVCDef.ch"

//Variveis Estaticas
Static cTitulo := "Calendario de CashBack"
Static cAliasMVC := "ZB7"

/*/{Protheus.doc} User Function ZB7010
Cadastro tabela ZB7
@author Antonio Ricardo.
@since 29/01/2025
@version 1.0
@type function
/*/


User Function ZB7010()
    Local aArea   := FWGetArea()
    Local oBrowse
    Private aRotina := {}

    //Definicao do menu
    aRotina := MenuDef()

    //Instanciando o browse
    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias(cAliasMVC)
    oBrowse:SetDescription(cTitulo)
    //oBrowse:SetFilterDefault({|aFilter| aFilter->(ZZ4_FILIAL) := GetMV("FILIAL")})
    oBrowse:DisableDetails()

    //Ativa a Browse
    oBrowse:Activate()

    FWRestArea(aArea)
Return Nil

/*/{Protheus.doc} MenuDef
Menu de opcoes na funcao ZB7010
@author LUiz A.
@since 16/11/2023
@version 1.0
@type function
/*/

Static Function MenuDef()
    Local aRotina := {}

    //Adicionando opcoes do menu
    ADD OPTION aRotina TITLE "Visualizar"     ACTION "AXPESQUI" OPERATION 1 ACCESS 0
    ADD OPTION aRotina TITLE "Incluir"        ACTION "AXINCLUI" OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE "Alterar"        ACTION "AXVISUAL" OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE "Excluir"        ACTION "AXDELETA" OPERATION 5 ACCESS 0
    ADD OPTION aRotina TITLE "Copiar"         ACTION "AXCOPIA"  OPERATION 9 ACCESS 0
    ADD OPTION aRotina TITLE "Visualizar (M)" ACTION "U_ZB7VIS" OPERATION 1 ACCESS 0
    ADD OPTION aRotina TITLE "Incluir (M)"    ACTION "U_ZB7INC" OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE "Alterar (M)"    ACTION "U_ZB7ALT" OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE "Excluir (M)"    ACTION "U_ZB7EXC" OPERATION 5 ACCESS 0


Return aRotina

/*/{Protheus.doc} ModelDef
Modelo de dados na funcao ZB7010
@author Luiz A.
@since 16/11/2023
@version 1.0
@type function
/*/

Static Function ModelDef()
    Local oStruct := FWFormStruct(1, cAliasMVC)
    Local oModel
    Local bPre := Nil
    Local bPos := Nil
    Local bCancel := Nil


    //Cria o modelo de dados para cadastro
    oModel := MPFormModel():New("ZB7010", bPre, bPos, /*bCommit*/, bCancel)
    oModel:AddFields("ZB7MASTER", /*cOwner*/, oStruct)
    oModel:SetDescription(cTitulo)
    oModel:GetModel("ZB7MASTER"):SetDescription( "Dados de - " + cTitulo)
    oModel:SetPrimaryKey({'ZB7_FILIAL,ZB7_ID'})
Return oModel

/*/{Protheus.doc} ViewDef
Visualizacao de dados na funcao ZB7010
@author LUiz A.
@since 16/11/2023
@version 1.0
@type function
/*/

Static Function ViewDef()
    Local oModel := FWLoadModel("ZB7010")
    Local oStruct := FWFormStruct(2, cAliasMVC)
    Local oView

    //Cria a visualizacao do cadastro
    oView := FWFormView():New()
    oView:SetModel(oModel)
    oView:AddField("VIEW_ZB7", oStruct, "ZB7MASTER")
    oView:CreateHorizontalBox("TELA" , 100 )
    oView:SetOwnerView("VIEW_ZB7", "TELA")

Return oView

/*/{Protheus.doc} ZB7INC
Incluir (manual)
@author Antonio Ricardo
@since 29/01/2025
@version 1.0
@type function
/*/
 
User Function ZB7INC()
    Local aArea       := FWGetArea()
    Local aAreaZB7    := ZB7->(FWGetArea())
    Local nOpcao      := 0
    Private cCadastro := "Teste de Inclusão"
     
    //Chama a função
    nOpcao := AxInclui('ZB7', 0, 3)
    If nOpcao == 1
        FWAlertInfo("Intervalo Cadastrado: " + ZB7->ZB7_ID, "Exemplo AxInclui")
    EndIf
     
    FWRestArea(aAreaZB7)
    FWRestArea(aArea)
Return


/*/{Protheus.doc} ZB7VIS
Visualizar (manual)
@author Antonio Ricardo
@since 29/01/2025
@version 1.0
@type function
/*/
 
User Function ZB7VIS()
    Local aArea       := FWGetArea()
    Local aAreaZB7    := ZB7->(FWGetArea())
    Local nOpcao      := 0
    Private cCadastro := "Teste de Visualização"
     
    //Chama a função
    nOpcao := AxVisual('ZB7', ZB7->(RecNo()), 2)
    If nOpcao == 1
        FWAlertInfo("Intervalo visualizado: " + ZB7->ZB7_ID, "Exemplo AxVisual")
    EndIf
     
    FWRestArea(aAreaZB7)
    FWRestArea(aArea)
Return
 
/*/{Protheus.doc} ZB7INC
Alterar (manual)
@author Antonio Ricardo
@since 29/01/2025
@version 1.0
@type function
/*/

User Function ZB7ALT()
    Local aArea       := FWGetArea()
    Local aAreaZB7    := ZB7->(FWGetArea())
    Local nOpcao      := 0
    Private cCadastro := "Teste de Alteração"
     
    //Chama a função
    nOpcao := AxAltera('ZB7', ZB7->(RecNo()), 4)
    If nOpcao == 1
        FWAlertInfo("Intervalo alterado: " + ZB7->ZB7_ID, "Exemplo AxAltera")
    EndIf
     
    FWRestArea(aAreaZB7)
    FWRestArea(aArea)
Return
 
 
/*/{Protheus.doc} ZB7EXC
Excluir (manual)
@author Antonio Ricardo
@since 29/01/2025
@version 1.0
@type function
/*/
 
User Function ZB7EXC()
    Local aArea       := FWGetArea()
    Local aAreaZB7    := ZB7->(FWGetArea())
    Local nOpcao      := 0
    Private cCadastro := "Teste de Exclusão"
     
    //Chama a função
    nOpcao := AxDeleta('ZB7', ZB7->(RecNo()), 5)
    If nOpcao == 1
        FWAlertInfo("Intervalo alterado: " + ZB7->ZB7_ID, "Exemplo AxDeleta")
    EndIf
     
    FWRestArea(aAreaZB7)
    FWRestArea(aArea)
Return
