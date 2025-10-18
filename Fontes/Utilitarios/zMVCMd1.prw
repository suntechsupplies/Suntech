/* ===
    Esse ù um exemplo disponibilizado no Terminal de Informaùùo
    Confira o artigo sobre esse assunto, no seguinte link: https://terminaldeinformacao.com/2015/08/26/exemplos-de-rotinas-mvc-em-advpl/
    Caso queira ver outros conteùdos envolvendo AdvPL e TL++, veja em: https://terminaldeinformacao.com/advpl/
=== */

//Bibliotecas
#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

//Variùveis Estùticas
Static cTitulo := "Grp.Produtos (Mod.1)"

/*/{Protheus.doc} zMVCMd1
Funùùo para cadastro de Grupo de Produtos (ZB8), exemplo de Modelo 1 em MVC
@author Atilio
@since 17/08/2015
@version 1.0
	@return Nil, Funùùo nùo tem retorno
	@example
	u_zMVCMd1()
	@obs Nùo se pode executar funùùo MVC dentro do fùrmulas
/*/

User Function zMVCMd1()
	Local aArea   := GetArea()
	Local oBrowse
	
	//Instùnciando FWMBrowse - Somente com dicionùrio de dados
	oBrowse := FWMBrowse():New()
	
	//Setando a tabela de cadastro de Autor/Interprete
	oBrowse:SetAlias("ZB8")

	//Setando a descriùùo da rotina
	oBrowse:SetDescription(cTitulo)
	
	//Legendas
	oBrowse:AddLegend( "ZB8->BM_PROORI == '1'", "GREEN",	"Original" )
	oBrowse:AddLegend( "ZB8->BM_PROORI == '0'", "RED",	"Nùo Original" )
	
	//Ativa a Browse
	oBrowse:Activate()
	
	RestArea(aArea)
Return Nil

/*---------------------------------------------------------------------*
 | Func:  MenuDef                                                      |
 | Autor: Daniel Atilio                                                |
 | Data:  17/08/2015                                                   |
 | Desc:  Criaùùo do menu MVC                                          |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/

Static Function MenuDef()
	Local aRot := {}
	
	//Adicionando opùùes
	ADD OPTION aRot TITLE 'Visualizar' ACTION 'VIEWDEF.zMVCMd1' OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 1
	ADD OPTION aRot TITLE 'Legenda'    ACTION 'u_zMVC01Leg'     OPERATION 6                      ACCESS 0 //OPERATION X
	ADD OPTION aRot TITLE 'Incluir'    ACTION 'VIEWDEF.zMVCMd1' OPERATION MODEL_OPERATION_INSERT ACCESS 0 //OPERATION 3
	ADD OPTION aRot TITLE 'Alterar'    ACTION 'VIEWDEF.zMVCMd1' OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
	ADD OPTION aRot TITLE 'Excluir'    ACTION 'VIEWDEF.zMVCMd1' OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5

Return aRot

/*---------------------------------------------------------------------*
 | Func:  ModelDef                                                     |
 | Autor: Daniel Atilio                                                |
 | Data:  17/08/2015                                                   |
 | Desc:  Criaùùo do modelo de dados MVC                             |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/

Static Function ModelDef()
	//Criaùùo do objeto do modelo de dados
	Local oModel := Nil
	
	//Criaùùo da estrutura de dados utilizada na interface
	Local oStZB8 := FWFormStruct(1, "ZB8")
	
	//Instanciando o modelo, nùo ù recomendado colocar nome da user function (por causa do u_), respeitando 10 caracteres
	oModel := MPFormModel():New("zMVCMd1M",/*bPre*/, /*bPos*/,/*bCommit*/,/*bCancel*/) 
	
	//Atribuindo formulùrios para o modelo
	oModel:AddFields("FORMZB8",/*cOwner*/,oStZB8)
	
	//Setando a chave primùria da rotina
	oModel:SetPrimaryKey({'ZB8_FILIAL,ZB8_NUM,ZB8_PREFIX,ZB8_PARCEL'})
	
	//Adicionando descriùùo ao modelo
	oModel:SetDescription("Modelo de Dados do Cadastro " + cTitulo)
	
	//Setando a descriùùo do formulùrio
	oModel:GetModel("FORMZB8"):SetDescription("Formulùrio do Cadastro " + cTitulo)
Return oModel

/*---------------------------------------------------------------------*
 | Func:  ViewDef                                                      |
 | Autor: Daniel Atilio                                                |
 | Data:  17/08/2015                                                   |
 | Desc:  Criaùùo da visùo MVC                                         |
 | Obs.:  /                                                            |
 *---------------------------------------------------------------------*/

Static Function ViewDef()
	//Criaùùo do objeto do modelo de dados da Interface do Cadastro de Autor/Interprete
	Local oModel := FWLoadModel("zMVCMd1")
	
	//Criaùùo da estrutura de dados utilizada na interface do cadastro de Autor
	Local oStZB8 := FWFormStruct(2, "ZB8")  //pode se usar um terceiro parùmetro para filtrar os campos exibidos { |cCampo| cCampo $ 'ZB8_NOME|ZB8_DTAFAL|'}
	
	//Criando oView como nulo
	Local oView := Nil

	//Criando a view que serù o retorno da funùùo e setando o modelo da rotina
	oView := FWFormView():New()
	oView:SetModel(oModel)
	
	//Atribuindo formulùrios para interface
	oView:AddField("VIEW_ZB8", oStZB8, "FORMZB8")
	
	//Criando um container com nome tela com 100%
	oView:CreateHorizontalBox("TELA",100)
	
	//Colocando tùtulo do formulùrio
	oView:EnableTitleView('VIEW_ZB8', 'Dados do Grupo de Produtos' )  
	
	//Forùa o fechamento da janela na confirmaùùo
	oView:SetCloseOnOk({||.T.})
	
	//O formulùrio da interface serù colocado dentro do container
	oView:SetOwnerView("VIEW_ZB8","TELA")
Return oView

/*/{Protheus.doc} zMVC01Leg
Funùùo para mostrar a legenda das rotinas MVC com grupo de produtos
@author Atilio
@since 17/08/2015
@version 1.0
	@example
	u_zMVC01Leg()
/*/

User Function zMVC01Leg()
	Local aLegenda := {}
	
	//Monta as cores
	AADD(aLegenda,{"BR_VERDE",		"Original"  })
	AADD(aLegenda,{"BR_VERMELHO",	"Nùo Original"})
	
	BrwLegenda("Grupo de Produtos", "Procedencia", aLegenda)
Return


