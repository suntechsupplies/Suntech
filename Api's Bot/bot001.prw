#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "Totvs.ch"
#Include 'TOTVSWebSrv.ch'

#Define Desc_Rest 	"Serviço REST para Disponibilizar Relatorios Para Bot"
/*-------------------------------------------------------------------
{Protheus.doc} 	WsRestFul Bot001
TODO 			Metodo WSRestFul para Get de Cadastros
@since 			19/08/2020
@version 		1.0
-------------------------------------------------------------------*/
WSRESTFUL bot001 DESCRIPTION Desc_Rest

	WSDATA CNPJ	       As String
    WSDATA Pedido	   As String
	WSDATA Filial	   As String	
    WSDATA Liquidados  As Integer
	WSDATA TENANTID    As String
	
	//--------------------------------------------------------------------------------------------------------------
    //{protocolo}://{host}/{api}/{agrupador}/{dominio}/{versao}/{recurso}". 
    //Ex: https://fluig.totvs.com/api/ecm/security/v1/users.
    //--------------------------------------------------------------------------------------------------------------
	WSMETHOD GET posicaoFin										;
	DESCRIPTION "Retorna Relatório de Posição Financeira "	    ;
	WSSYNTAX    "api/bot/suntech/v1.0/posicaoFin"			    ;
	PATH 	    "api/bot/suntech/v1.0/posicaoFin"	

	WSMETHOD GET pedidoVendas									;
	DESCRIPTION "Retorna Pedido de Vendas " 					;
	WSSYNTAX    "api/bot/suntech/v1.0/pedidoVendas"	    		;
	PATH        "api/bot/suntech/v1.0/pedidoVendas"		

END WSRESTFUL

/*-------------------------------------------------------------------
{Protheus.doc} 	GET Posição Financeira
TODO 			Retorna Relatorio de Posição Financeira em Base64
@since 			15/11/2021
@version 		1.0
@type 			WsMethod Rest
-------------------------------------------------------------------*/
WSMETHOD GET posicaoFin WSRECEIVE CNPJ, Liquidados WSSERVICE bot001

	Local _cCNPJ		:= Self:CNPJ
    Local _nliquidados	:= Self:Liquidados
	Local aArea			:= GetArea()
	Local cSetResp      := ''

  	// define o tipo de retorno do método - Solicitação do Joao Krabbe
	::SetContentType("application/json")

	//-------------------------------------------------------------------
	// Posiciona no cadastro de clientes para recuperar o codigo/loja
	//-------------------------------------------------------------------
	dbSelectArea("SA1")
	dbSetOrder(3)                   // A1_FILIAL+A1_CGC
	dbGoTop()
	
	If ! dbSeek(FwFilial("SA1") + _cCNPJ )
        cSetResp := '{ "Retorno":"Nao foi possível a geração do relatório de Posição Financeira para esse CNPJ !!"} '
	Else
        cSetResp := '{'
        cSetResp += '"PAGINA": 1,'
        cSetResp += '"PORPAGINA": 1,'
        cSetResp += '"RETORNOS": ['
        cSetResp += '{'
        cSetResp += '"base64_arquivo": "data:text/html;base64,' + U_FR340_Sun({SA1->A1_COD, SA1->A1_COD, SA1->A1_LOJA, SA1->A1_LOJA, _nliquidados}) + '"'
        cSetResp += '}'
        cSetResp += '],'
        cSetResp += '"PROXIMO": false,'
        cSetResp += '"TOTAL": 1'
        cSetResp += '}'
    Endif

	//-------------------------------------------------------------------
	// Retorna o relatório em Base64 e restaura a area de trabalho
	//-------------------------------------------------------------------
	::SetResponse( cSetResp ) 
	RestArea(aArea)		
	
Return(.T.)

/*-------------------------------------------------------------------
{Protheus.doc} 	GET pedidoVendas
TODO 			Retorna Pedido de Vendas para Nota Fiscal em base64
@since 			04/09/2020
@version 		1.0
-------------------------------------------------------------------*/
WSMETHOD GET pedidoVendas WSRECEIVE Pedido, Filial HEADERPARAM TENANTID  WSSERVICE bot001

	Local _cPedido	:= Self:Pedido
	Local _cEmpresa	:= "01"
	Local _cFilial	:= "02"
	Local aArea		:= GetArea()
    Local cSetResp  := ''

	If !Empty(SELF:TENANTID)
		_cEmpresa := Left(Upper(SELF:TENANTID), At(",",Upper(SELF:TENANTID))-1)
		_cFilial  := Substr(Upper(SELF:TENANTID), At(",",Upper(SELF:TENANTID))+1)
	EndIf

	cEmpAnt := _cEmpresa
	cFilAnt := _cFilial

	WfPrepEnv(_cEmpresa,_cFilial)

  	// define o tipo de retorno do método - Solicitação do Joao Krabbe
	::SetContentType("application/json")
	
	//-------------------------------------------------------------------
	// Posiciona na tabela de Pedido de Vendas
	//-------------------------------------------------------------------
	dbSelectArea("SC5")
	dbSetOrder(1)
	
	If ! dbSeek(FwFilial("SC5") + _cPedido )
        cSetResp := '{ "Retorno":"Nao foi possivel a geracao do relatorio de Pedido de Vendas para esse numero de Pedido  !!"} '
	Else
        cSetResp := '{'
        cSetResp += '"PAGINA": 1,'
        cSetResp += '"PORPAGINA": 1,'
        cSetResp += '"RETORNOS": ['
        cSetResp += '{'
        cSetResp += '"base64_arquivo": "data:text/html;base64,' + U_MTR730_Sun({ SC5->C5_NUM, SC5->C5_NUM }) + '"'
        cSetResp += '}'
        cSetResp += '],'
        cSetResp += '"PROXIMO": false,'
        cSetResp += '"TOTAL": 1'
        cSetResp += '}'
    Endif

	//-------------------------------------------------------------------
	// Retorna o relatório em Base64 e restaura a area de trabalho
	//-------------------------------------------------------------------
	::SetResponse( cSetResp ) 
	RestArea(aArea)		
	
Return(.T.)

