//Bibliotecas
#Include "Protheus.ch"
#Include "Totvs.ch"
#Include "FWMBROWSE.ch"
#Include "FWMVCDef.ch"

//Variveis Estaticas
Static cTitulo := "Extrato do CashBack"
Static cAliasMVC := "ZB8"

/*/{Protheus.doc} User Function ZB8010
Cadastro tabela ZB8
@author Antonio Ricardo.
@since 29/01/2025
@version 1.0
@type function
/*/


User Function ZB8010()
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
Menu de opcoes na funcao ZB8010
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
    ADD OPTION aRotina TITLE "Visualizar (M)" ACTION "U_ZB8VIS" OPERATION 1 ACCESS 0
    ADD OPTION aRotina TITLE "Incluir (M)"    ACTION "U_ZB8INC" OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE "Alterar (M)"    ACTION "U_ZB8ALT" OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE "Excluir (M)"    ACTION "U_ZB8EXC" OPERATION 5 ACCESS 0


Return aRotina

/*/{Protheus.doc} ModelDef
Modelo de dados na funcao ZB8010
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
    oModel := MPFormModel():New("ZB8010", bPre, bPos, /*bCommit*/, bCancel)
    oModel:AddFields("ZB8MASTER", /*cOwner*/, oStruct)
    oModel:SetDescription(cTitulo)
    oModel:GetModel("ZB8MASTER"):SetDescription( "Dados de - " + cTitulo)
    oModel:SetPrimaryKey({'ZB8_FILIAL,ZB8_NUM,ZB8_PREFIX,ZB8_PARCEL'})

    oStruct:SetProperty('ZB8_EMISSAO', MODEL_FIELD_WHEN, FwBuildFeature(STRUCT_FEATURE_WHEN,   'INCLUI')) //Modo de Edição
    oStruct:SetProperty('ZB8_EMISSAO', MODEL_FIELD_INIT, FwBuildFeature(STRUCT_FEATURE_INIPAD, 'Date()')) //Inicializador Padrão
 
Return oModel

/*/{Protheus.doc} ViewDef
Visualizacao de dados na funcao ZB8010
@author LUiz A.
@since 16/11/2023
@version 1.0
@type function
/*/

Static Function ViewDef()
    Local oModel  := FWLoadModel("ZB8010")
    Local oStruct := FWFormStruct(1, cAliasMVC)
    Local oView

    //Cria a visualizacao do cadastro
    oView := FWFormView():New()
    oView:SetModel(oModel)
    oView:AddField("VIEW_ZB8", oStruct, "ZB8MASTER")
    oView:CreateHorizontalBox("TELA" , 100 )
    oView:SetOwnerView("VIEW_ZB8", "TELA")

Return oView

/*/{Protheus.doc} ZB8INC
Incluir (manual)
@author Antonio Ricardo
@since 29/01/2025
@version 1.0
@type function
/*/
 
User Function ZB8INC()
    Local aArea       := FWGetArea()
    Local aAreaZB8    := ZB8->(FWGetArea())
    Local nOpcao      := 0
    Private cCadastro := "Teste de Inclusão"
     
    //Chama a função
    nOpcao := AxInclui('ZB8', 0, 3)
    If nOpcao == 1
        FWAlertInfo("Intervalo Cadastrado: " + ZB8->ZB8_NUM+ZB8->ZB8_PREFIX+ZB8->ZB8_PARCEL, "Exemplo AxInclui")
    EndIf
     
    FWRestArea(aAreaZB8)
    FWRestArea(aArea)
Return


/*/{Protheus.doc} ZB8VIS
Visualizar (manual)
@author Antonio Ricardo
@since 29/01/2025
@version 1.0
@type function
/*/
 
User Function ZB8VIS()
    Local aArea       := FWGetArea()
    Local aAreaZB8    := ZB8->(FWGetArea())
    Local nOpcao      := 0
    Private cCadastro := "Teste de Visualização"
     
    //Chama a função
    nOpcao := AxVisual('ZB8', ZB8->(RecNo()), 2)
    If nOpcao == 1
        FWAlertInfo("Intervalo visualizado: " + ZB8->ZB8_NUM+ZB8->ZB8_PREFIX+ZB8->ZB8_PARCEL, "Exemplo AxVisual")
    EndIf
     
    FWRestArea(aAreaZB8)
    FWRestArea(aArea)
Return
 
/*/{Protheus.doc} ZB8INC
Alterar (manual)
@author Antonio Ricardo
@since 29/01/2025
@version 1.0
@type function
/*/

User Function ZB8ALT()
    Local aArea    := FWGetArea()
    Local aAreaZB8 := ZB8->(FWGetArea())
    lOCAL cString  := "ZB8"
    Local nOpcao   := 0
    lOCAL nReg     := ZB8->(RecNo())     
    Local aCpos    := {"ZB8_PREFIX","ZB8_PARCEL"}
    Private cCadastro := "Teste de Alteração"

    //Chama a função
    nOpcao := AxAltera(cString,nReg,4,,aCpos)
    
    If nOpcao == 1
        FWAlertInfo("Intervalo alterado: " + ZB8->ZB8_NUM+ZB8->ZB8_PREFIX+ZB8->ZB8_PARCEL, "Exemplo AxAltera")
    EndIf
     
    FWRestArea(aAreaZB8)
    FWRestArea(aArea)
Return Nil
 
 
/*/{Protheus.doc} ZB8EXC
Excluir (manual)
@author Antonio Ricardo
@since 29/01/2025
@version 1.0
@type function
/*/
 
User Function ZB8EXC()
    Local aArea       := FWGetArea()
    Local aAreaZB8    := ZB8->(FWGetArea())
    Local nOpcao      := 0
    Private cCadastro := "Teste de Exclusão"
     
    //Chama a função
    nOpcao := AxDeleta('ZB8', ZB8->(RecNo()), 5)
    If nOpcao == 1
        FWAlertInfo("Intervalo alterado: " + ZB8->ZB8_NUM+ZB8->ZB8_PREFIX+ZB8->ZB8_PARCEL, "Exemplo AxDeleta")
    EndIf
     
    FWRestArea(aAreaZB8)
    FWRestArea(aArea)
Return
