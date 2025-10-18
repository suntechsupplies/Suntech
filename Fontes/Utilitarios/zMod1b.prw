//Bibliotecas
#Include 'TOTVS.CH'
#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
 
//Vari�veis Est�ticas
Static cTitulo  := "Extrato do CashBack"
Static cDefault := "CASHBACK"
 
/*/{Protheus.doc} zMod1b
Exemplo de Modelo 1 para cadastro de Artistas com valida��es
@author Atilio
@since 03/09/2016
@version 1.0
    @return Nil, Fun��o n�o tem retorno
    @example
    u_zMod1b()
/*/
 
User Function zMod1b()
    Local aArea     := GetArea()    
    Local cFunBkp   := FunName()
    Local oBrowse   := Nil
    Local cCampoAux := "ZB8_NUM"
    Local aPesquisa := {} 
     
    SetFunName("zMod1b")
     
    //Inst�nciando FWMBrowse - Somente com dicion�rio de dados
    oBrowse := FWMBrowse():New()
     
    //Setando a tabela de cadastro de Autor/Interprete
    oBrowse:SetAlias("ZB8")
 
    //Setando a descri��o da rotina
    oBrowse:SetDescription(cTitulo)

    aAdd(aPesquisa,{GetSX3Cache(cCampoAux, "X3_TITULO"), {{"", GetSX3Cache(cCampoAux, "X3_TIPO"), GetSX3Cache(cCampoAux, "X3_TAMANHO"), GetSX3Cache(cCampoAux, "X3_DECIMAL"), AllTrim(GetSX3Cache(cCampoAux, "X3_TITULO")), AllTrim(GetSX3Cache(cCampoAux, "X3_PICTURE"))}} } )
    
    //Adicionando a segunda legenda    
    oBrowse:AddLegend("ZB8->ZB8_TIPO == 'NF '", 'GREEN', 'CashBack',              '1' )
    oBrowse:AddLegend("ZB8->ZB8_TIPO == 'CB '", 'RED',   'Aplica��o de Cashback', '1' )
    oBrowse:AddLegend("ZB8->ZB8_TIPO == 'ER '", 'GRAY',  'Elimina��o de Res�duo', '1' )
    oBrowse:AddLegend("ZB8->ZB8_TIPO == 'AJ '", 'BLUE',  'Ajuste Negativo',       '1' )     
    
    //Adcionando Campo de Pesquisa
    oBrowse:SetSeek(.T., aPesquisa)
        
    //Ativa a Browse
    oBrowse:Activate()
     
    SetFunName(cFunBkp)
    RestArea(aArea)
Return Nil
 
/*---------------------------------------------------------------------*
 | Func:  MenuDef                                                      |
 | Autor: Daniel Atilio                                                |
 | Data:  03/09/2016                                                   |
 | Desc:  Cria��o do menu MVC                                          |
 *---------------------------------------------------------------------*/
 
Static Function MenuDef()
    Local aRot := {}
     
    //Adicionando op��es
    ADD OPTION aRot TITLE 'Visualizar'     ACTION 'VIEWDEF.zMod1b'       OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 2
    ADD OPTION aRot TITLE 'Incluir'        ACTION 'VIEWDEF.zMod1b'       OPERATION MODEL_OPERATION_INSERT ACCESS 0 //OPERATION 3
    ADD OPTION aRot TITLE 'Alterar'        ACTION 'VIEWDEF.zMod1b'       OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
    ADD OPTION aRot TITLE 'Excluir'        ACTION 'VIEWDEF.zMod1b'       OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5
    ADD OPTION aRot TITLE 'Gerar Cashback' ACTION 'U_ProcessaCashback()' OPERATION 9                      ACCESS 0 //OPERATION 6
 
Return aRot
 
/*---------------------------------------------------------------------*
 | Func:  ModelDef                                                     |
 | Autor: Daniel Atilio                                                |
 | Data:  03/09/2016                                                   |
 | Desc:  Cria��o do modelo de dados MVC                               |
 *---------------------------------------------------------------------*/
 
Static Function ModelDef()
    //Blocos de c�digo nas valida��es
    Local bVldPre := {|| u_zM1bPre()} //Antes de abrir a Tela
    Local bVldPos := {|| u_zM1bPos()} //Valida��o ao clicar no Confirmar
    Local bVldCom := {|| u_zM1bCom()} //Fun��o chamadao ao cancelar
    Local bVldCan := {|| u_zM1bCan()} //Fun��o chamadao ao cancelar
     
    //Cria��o do objeto do modelo de dados
    Local oModel := Nil
     
    //Cria��o da estrutura de dados utilizada na interface
    Local oStZB8 := FWFormStruct(1, "ZB8")
     
    //Editando caracter�sticas do dicion�rio
    oStZB8:SetProperty('ZB8_NUM',    MODEL_FIELD_WHEN,    FwBuildFeature(STRUCT_FEATURE_WHEN,    '.F.'))                                 //Modo de Edi��o
    oStZB8:SetProperty('ZB8_NUM',    MODEL_FIELD_INIT,    FwBuildFeature(STRUCT_FEATURE_INIPAD,  'GetSXENum("ZB8", "ZB8_NUM")'))         //Ini Padr�o
    oStZB8:SetProperty('ZB8_NOMCLI', MODEL_FIELD_WHEN,    FwBuildFeature(STRUCT_FEATURE_WHEN,    '.T.'))                                 //Modo de Edi��o
    //oStZB8:SetProperty('ZB8_CLIENT', MODEL_FIELD_OBRIGAT, Iif(RetCodUsr()!='000000', .T., .F.) )                                       //Campo Obrigat�rio
    //oStZB8:SetProperty('ZB8_CLIENT', MODEL_FIELD_INIT,    FwBuildFeature(STRUCT_FEATURE_INIPAD,  "'"+cDefault+"'"))                    //Ini Padr�o
     
    //Instanciando o modelo, n�o � recomendado colocar nome da user function (por causa do u_), respeitando 10 caracteres
    oModel := MPFormModel():New("zMod1bM", bVldPre, bVldPos, bVldCom, bVldCan) 
     
    //Atribuindo formul�rios para o modelo
    oModel:AddFields("FORMZB8",/*cOwner*/,oStZB8)
     
    //Setando a chave prim�ria da rotina
    oModel:SetPrimaryKey({{'ZB8_FILIAL,ZB8_NUM,ZB8_PREFIX,ZB8_PARCEL'}})
     
    //Adicionando descri��o ao modelo
    oModel:SetDescription("Modelo de Dados do Cadastro "+cTitulo)
     
    //Setando a descri��o do formul�rio
    oModel:GetModel("FORMZB8"):SetDescription("Formul�rio do Cadastro "+cTitulo)
     
    //Pode ativar?
    oModel:SetVldActive( { | oModel | fAlterar( oModel ) } )
Return oModel
 
/*---------------------------------------------------------------------*
 | Func:  ViewDef                                                      |
 | Autor: Daniel Atilio                                                |
 | Data:  03/09/2016                                                   |
 | Desc:  Cria��o da vis�o MVC                                         |
 *---------------------------------------------------------------------*/
 
Static Function ViewDef()
    //Local aStruZB8    := ZB8->(DbStruct())
     
    //Cria��o do objeto do modelo de dados da Interface do Cadastro de Autor/Interprete
    Local oModel := FWLoadModel("zMod1b")
     
    //Cria��o da estrutura de dados utilizada na interface do cadastro de Autor
    Local oStZB8 := FWFormStruct(2, "ZB8")  //pode se usar um terceiro par�metro para filtrar os campos exibidos { |cCampo| cCampo $ 'SZB8_NOME|SZB8_DTAFAL|'}
     
    //Criando oView como nulo
    Local oView := Nil
 
    //Criando a view que ser� o retorno da fun��o e setando o modelo da rotina
    oView := FWFormView():New()
    oView:SetModel(oModel)
     
    //Atribuindo formul�rios para interface
    oView:AddField("VIEW_ZB8", oStZB8, "FORMZB8")
     
    //Criando um container com nome tela com 100%
    oView:CreateHorizontalBox("TELA",100)
     
    //Colocando t�tulo do formul�rio
    oView:EnableTitleView('VIEW_ZB8', 'Dados - '+cTitulo )  
     
    //For�a o fechamento da janela na confirma��o
    oView:SetCloseOnOk({||.T.})
     
    //O formul�rio da interface ser� colocado dentro do container
    oView:SetOwnerView("VIEW_ZB8","TELA")
Return oView
 
/*/{Protheus.doc} zM1bPre
Fun��o chamada na cria��o do Modelo de Dados (pr�-valida��o)
@type function
@author Atilio
@since 03/09/2016
@version 1.0
/*/
 
User Function zM1bPre()
    Local oModelPad  := FWModelActive()
    Local nOpc       := oModelPad:GetOperation()
    Local lRet       := .T.
     
    //Se for inclus�o ou exclus�o
    If nOpc == MODEL_OPERATION_INSERT
        If RetCodUsr() == '000000'
            oModelPad:GetModel('FORMZB8'):GetStruct():SetProperty('ZB8_NUM',   MODEL_FIELD_WHEN,    FwBuildFeature(STRUCT_FEATURE_WHEN,    '.F.'))
            oModelPad:GetModel('FORMZB8'):GetStruct():SetProperty('ZB8_NOMCLI',MODEL_FIELD_WHEN,    FwBuildFeature(STRUCT_FEATURE_WHEN,    '.F.'))
        EndIf
    EndIf
Return lRet
 
/*/{Protheus.doc} zM1bPos
Fun��o chamada no clique do bot�o Ok do Modelo de Dados (p�s-valida��o)
@type function
@author Atilio
@since 03/09/2016
@version 1.0
/*/
 
User Function zM1bPos()
    Local oModelPad  := FWModelActive()
    Local cNum       := oModelPad:GetValue('FORMZB8', 'ZB8_NUM')
    Local lRet       := .T.
     
    //Se a descri��o estiver em branco
    If Empty(cNum) .Or. Alltrim(Upper(cNum)) == cDefault
        lRet := .F.
        Aviso('Aten��o', 'Campo N�mero esta em branco!', {'OK'}, 03)
    EndIf
     
Return lRet
 
/*/{Protheus.doc} zM1bCom
Fun��o chamada ap�s validar o ok da rotina para os dados serem salvos
@type function
@author Atilio
@since 03/09/2016
@version 1.0
/*/
 
User Function zM1bCom()
    Local oModelPad  := FWModelActive()
    Local cNum       := oModelPad:GetValue('FORMZB8', 'ZB8_NUM')
    Local cPrefixo   := oModelPad:GetValue('FORMZB8', 'ZB8_PREFIX')
    Local cParcela   := oModelPad:GetValue('FORMZB8', 'ZB8_PARCEL')
    Local cTipo      := oModelPad:GetValue('FORMZB8', 'ZB8_TIPO')
    Local cPortador  := oModelPad:GetValue('FORMZB8', 'ZB8_PORTAD')
    Local cCliente   := oModelPad:GetValue('FORMZB8', 'ZB8_CLIENT')
    Local cLoja      := oModelPad:GetValue('FORMZB8', 'ZB8_LOJA')
    Local cNomCli    := oModelPad:GetValue('FORMZB8', 'ZB8_NOMCLI')
    Local dEmissao   := oModelPad:GetValue('FORMZB8', 'ZB8_EMISSA')
    Local cVencimento:= oModelPad:GetValue('FORMZB8', 'ZB8_VENCTO')
    Local nValor     := oModelPad:GetValue('FORMZB8', 'ZB8_VALOR')
    Local nBasComiss := oModelPad:GetValue('FORMZB8', 'ZB8_BASCOM')
    Local nSaldo     := oModelPad:GetValue('FORMZB8', 'ZB8_SALDO')
    Local cVendedor  := oModelPad:GetValue('FORMZB8', 'ZB8_VEND1')
    Local nOpc       := oModelPad:GetOperation()
    Local lRet       := .T.
     
    //Se for Inclus�o
    If nOpc == MODEL_OPERATION_INSERT
        RecLock('ZB8', .T.)
            ZB8_FILIAL := FWxFilial('ZB8')
            ZB8_NUM    := cNum
            ZB8_PREFIX := cPrefixo
            ZB8_PARCEL := cParcela  
            ZB8_TIPO   := cTipo 
            ZB8_PORTAD := cPortador
            ZB8_CLIENT := cCliente
            ZB8_LOJA   := cLoja
            ZB8_NOMCLI := cNomCli
            ZB8_EMISSA := dEmissao
            ZB8_VENCTO := cVencimento
            ZB8_VALOR  := nValor
            ZB8_SALDO  := nSaldo
            ZB8_VEND1  := cVendedor
            ZB8_BASCOM := nBasComiss
        ZB8->(MsUnlock())
        ConfirmSX8()

        SA1->(dbGoTop())
		SA1->(dbSetOrder(1))
		If SA1->(dbSeek(xFilial("SA1")+ZB8->ZB8_CLIENT+ZB8->ZB8_LOJA))
			RecLock("SA1",.F.)
                IF ZB8->ZB8_TIPO == 'CB ' .OR. ZB8->ZB8_TIPO == 'ER ' .OR. ZB8->ZB8_TIPO == 'AJ '
                    A1_ZZVLCSB -= ZB8->ZB8_VALOR
                Else
                    A1_ZZVLCSB += ZB8->ZB8_VALOR
                EndIf			   
			SA1->(MsUnlock())
		Endif

        Aviso('Aten��o', 'Inclus�o realizada!', {'OK'}, 03)
         
    //Se for Altera��o
    ElseIf nOpc == MODEL_OPERATION_UPDATE
        RecLock('ZB8', .F.)
            ZB8_VENCTO := cVencimento
            ZB8_VALOR  := nValor
            ZB8_SALDO  := nSaldo
            ZB8_PORTAD := cPortador
            ZB8_VEND1  := cVendedor
            ZB8_BASCOM := nBasComiss
        ZB8->(MsUnlock())

        SA1->(dbGoTop())
		SA1->(dbSetOrder(1))
		If SA1->(dbSeek(xFilial("SA1")+ZB8->ZB8_CLIENT+ZB8->ZB8_LOJA))
			RecLock("SA1",.F.)
                IF ZB8->ZB8_VALOR <> nValor
                    A1_ZZVLCSB += (nValor - ZB8->ZB8_VALOR)
                EndIf			   
			SA1->(MsUnlock())
		Endif
         
        Aviso('Aten��o', 'Altera��o realizada!', {'OK'}, 03)
         
    //Se for Exclus�o
    ElseIf nOpc == MODEL_OPERATION_DELETE
        RecLock('ZB8', .F.)
            DbDelete()
        ZB8->(MsUnlock())

        SE1->(dbGoTop())
		SE1->(dbSetOrder(1))
        If SE1->(dbSeek(xFilial("SE1")+ZB8->ZB8_PREFIXO+ZB8->ZB8_NUM+ZB8->ZB8_PARCELA+ZB8->ZB8_TIPO))
			RecLock("SE1",.F.)
			    E1_ZZCASHB := 'N'
			SE1->(MsUnlock())
		Endif

        SA1->(dbGoTop())
		SA1->(dbSetOrder(1))
		If SA1->(dbSeek(xFilial("SA1")+ZB8->ZB8_CLIENT+ZB8->ZB8_LOJA))
			RecLock("SA1",.F.)
                IF ZB8->ZB8_TIPO == 'CB ' .OR. ZB8->ZB8_TIPO == 'ER ' .OR. ZB8->ZB8_TIPO == 'AJ '
                    A1_ZZVLCSB += ZB8->ZB8_VALOR
                Else
                    A1_ZZVLCSB -= ZB8->ZB8_VALOR
                EndIf			   
			SA1->(MsUnlock())
		Endif

        Aviso('Aten��o', 'Exclus�o realizada!', {'OK'}, 03)
    EndIf
Return lRet
 
/*/{Protheus.doc} zM1bCan
Fun��o chamada ao cancelar as informa��es do Modelo de Dados (bot�o Cancelar)
@type function
@author Atilio
@since 03/09/2016
@version 1.0
/*/
 
User Function zM1bCan()
    //Local oModelPad  := FWModelActive()
    Local lRet       := .T.
     
    //Somente permite cancelar se o usu�rio confirmar
    lRet := MsgYesNo("Deseja cancelar a opera��o?", "Aten��o")
Return lRet
 
/*---------------------------------------------------------------------*
 | Func:  fAlterar                                                     |
 | Autor: Daniel Atilio                                                |
 | Data:  03/09/2016                                                   |
 | Desc:  Define se pode abrir o Modelo de Dados                       |
 *---------------------------------------------------------------------*/
 
Static Function fAlterar( oModel )
    Local lRet       := .T.
    Local nOperation := oModel:GetOperation()
 
    //Se for exclus�o
    If nOperation == MODEL_OPERATION_DELETE
        //Se n�o for o Administrador
        If RetCodUsr() != '000000'
            lRet := .F.
            Aviso('Aten��o', 'Somente o Administrador pode excluir registros!', {'OK'}, 03)
        EndIf
    EndIf
 
Return lRet
