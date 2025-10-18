#Include "Protheus.ch"
#Include "totvs.ch"

/*---------------------------------------------------------------------------------
{Protheus.doc} 	MA410MNU
TODO 			Inclusao de Rotina no Menu do Faturamento
@author 		carlos.saturnino@atlantaconsulting.com.br
@since 			06/09/2020
@version 		1.0
@return 		${return}, 
				${return_description}
@type 			User Function
---------------------------------------------------------------------------------*/
User Function MA410MNU()

	Aadd(aRotina, {	"Importacao Pedido de Vendas"	,"U_fAutoriza()"	, 0 , 4 , 82 , .T. })

Return(.T.)

/*---------------------------------------------------------------------------------
{Protheus.doc} 	fAutoriza
TODO 			Verificacao de alcada do usuario
@author 		carlos.saturnino@atlantaconsulting.com.br
@since 			06/09/2020
@version 		1.0
@return 		${return}, 
				${return_description}
@type 			User Function
---------------------------------------------------------------------------------*/

User Function fAutoriza()

	Local cCodigo  	:= Space(30)
	Local _cSenha   := Space(30)
	Local lAutoriz	:= .F.
	Local nOpca    	:= 0
	Local cAuth		:= "" 

	DEFINE MSDIALOG oDlgSenha TITLE "Autorizacao Importação Especial" From 001,001 to 125,300 Pixel STYLE DS_MODALFRAME
	
	oSaySenha := tSay():New(012,010,{|| "Digite o Usuario:"   },oDlgSenha,,,,,,.T.,CLR_BLACK,CLR_WHITE,60,9)
	oGetSenha := tGet():New(010,050,{|u| if(PCount()>0,cCodigo:=u,cCodigo)}, oDlgSenha,085,9,"@A",{ ||  },,,,,,.T.,,, { || .T. } ,,,,.F.,,,'cCodigo')

	oSaySenha := tSay():New(022,010,{|| "Digite a senha:"   },oDlgSenha,,,,,,.T.,CLR_BLACK,CLR_WHITE,60,9)
	oGetSenha := tGet():New(020,050,{|u| if(PCount()>0,_cSenha:=u,_cSenha)}, oDlgSenha,085,9,"@A",{ ||  },,,,,,.T.,,, { || .T. } ,,,,.F.,.T.,,'_cSenha')

	oBtnOk := tButton():New(040,035,"Ok"  		, oDlgSenha, {|| nOpca := 1, ::End() },40,12,,,,.T.,,,, { ||  },,)
	oBtnNo := tButton():New(040,080,"Cancelar"  , oDlgSenha, {|| nOpca := 2, ::End() },40,12,,,,.T.,,,, { ||  },,)

	ACTIVATE MSDIALOG oDlgSenha CENTERED
	
	If nOpca == 1
		cAuth 		:= Alltrim(cCodigo) + ":" + Alltrim(_cSenha)
		lAutoriz 	:= U_Especial002(cAuth)
		
		If ! lAutoriz 
			MsgStop("Usuário e/ou senha inválidos!!!","Acesso não Permitido !! ")		
		Else
			MsgInfo("Integração dos Pedidos de Vendas Efetuados com sucesso !!!", "Processamento")
		Endif
	
	ElseIf nOpca == 2
		MsgStop("Processo Cancelado pelo usuário !!","Cancelado !! ")
	Endif

Return()
