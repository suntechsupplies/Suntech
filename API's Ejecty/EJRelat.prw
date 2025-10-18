#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "Totvs.ch"
#Include 'TOTVSWebSrv.ch'

#Define Desc_Rest 	"Serviço REST para Disponibilizar Relatorios Para Ejecty"
/*-------------------------------------------------------------------
{Protheus.doc} 	WsRestFul ejRelat
TODO 			Metodo WSRestFul para Get de Cadastros
@since 			19/08/2020
@version 		1.0
-------------------------------------------------------------------*/

WSRESTFUL ejRelat DESCRIPTION Desc_Rest

    WSDATA PedidoEj	    As String
    WSDATA PedidoPt	    As String
	
	//--------------------------------------------------------------------------------------------------------------
    //{protocolo}://{host}/{api}/{agrupador}/{dominio}/{versao}/{recurso}". 
    //Ex: https://fluig.totvs.com/api/ecm/security/v1/users.
    //--------------------------------------------------------------------------------------------------------------
    WSMETHOD GET XmlNotaVenda									;
	DESCRIPTION "Retorna XML de Notas de Vendas " 				;
	WSSYNTAX    "api/bot/suntech/v1.0/xmlNotaVenda"    		    ;
	PATH        "api/bot/suntech/v1.0/xmlNotaVenda"	

    WSMETHOD GET emiteBoleto									;
	DESCRIPTION "Retorna Boleto Financeiro " 					;
	WSSYNTAX    "api/bot/suntech/v1.0/emiteBoleto"    		    ;
	PATH        "api/bot/suntech/v1.0/emiteBoleto"	

    WSMETHOD GET emiteDanfe 									;
	DESCRIPTION "Retorna Danfe da venda selecionada"    		;
	WSSYNTAX    "api/bot/suntech/v1.0/emiteDanfe"    		    ;
	PATH        "api/bot/suntech/v1.0/emiteDanfe"	


END WSRESTFUL


/*-------------------------------------------------------------------
{Protheus.doc} 	GET XmlNotaVenda
TODO 			Retorna XML da Nota Fiscal em base64
@since 			30/03/2022
@version 		1.0
-------------------------------------------------------------------*/
WSMETHOD GET XmlNotaVenda WSRECEIVE PedidoEj, PedidoPT  WSSERVICE ejRelat

	Local _cPedido	    := Self:Pedido
	Local aArea			:= GetArea()
    Local cSetResp      := ''
    Local cAlias        := GetNextAlias()
    Local nY

  	// define o tipo de retorno do método - Solicitação do Joao Krabbe
	::SetContentType("application/json")
    
	
	//-------------------------------------------------------------------
	// Posiciona na tabela de Pedido de Vendas
	//-------------------------------------------------------------------
    If !Empty(PedidoPt)
    
        BeginSql Alias cAlias
            
            SELECT		D2_FILIAL, D2_PEDIDO, D2_DOC, D2_SERIE
            FROM 		SD2010 SD2
            WHERE		D2_PEDIDO = %Exp:_cPedidoPT%
                AND 		SD2.%NotDel%
                AND         SD2.D2_FILIAL = '02'
            GROUP BY 	D2_FILIAL, D2_PEDIDO, D2_DOC, D2_SERIE	
        
        EndSql
    
    Else
    
        BeginSql Alias cAlias
            
            SELECT		D2_FILIAL, D2_PEDIDO, D2_DOC, D2_SERIE
            FROM 		SD2010 SD2
            WHERE		D2_PEDIDO = %Exp:_cPedidoEj%
                AND 		SD2.%NotDel%
                AND         SD2.D2_FILIAL = '02'
            GROUP BY 	D2_FILIAL, D2_PEDIDO, D2_DOC, D2_SERIE	
        
        EndSql
    
    Endif

	If (cAlias)->(Eof())
        
        cSetResp := '{ "Retorno":"Nao foi possivel a geracao do XML para o Pedido de Vendas solicitado  !!"} '
	
    Else

        cSetResp := '{ "pedido" : ['        
        
        For nY := 1 to Len(cAlias)
            
            If nY > 1
                cSetResp += ", "
            Endif
            

            cSetResp += '{ "notaFiscal": "' + (cAlias)->D2_DOC +'", '
            cSetResp += '"serie": "' + (cAlias)->D2_SERIE +'", '
            cSetResp += '"xml":"base64_arquivo", '
            cSetResp += '"data:' + fWSpedXML((cAlias)->D2_DOC, (cAlias)->D2_DOC) + '" }'

        Next nY

        cSetResp += ']}'
    
    Endif

	//-------------------------------------------------------------------
	// Retorna o relatório em Base64 e restaura a area de trabalho
	//-------------------------------------------------------------------
	::SetResponse( cSetResp ) 
	RestArea(aArea)		
	
Return(.T.)

/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------
{Protheus.doc}  fWSpedXML
                Função que gera o arquivo xml da nota (normal ou cancelada)
@author         Carlos Eduardo Saturnino
@since          30/03/2022
@version        1.0
@param          cDocumento, characters, Código do documento (F2_DOC)
@param          cSerie, characters, Série do documento (F2_SERIE)
@type           function
@example        fWSpedXML("000000001", "1") 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
 
Static Function fWSpedXML(cDocumento, cSerie)
    
    Local aArea        := GetArea()
    Local cURLTss      := PadR(GetNewPar("MV_SPEDURL","http://"),250)  
    Local oWebServ
    Local cIdEnt       := RetIdEnti()
    Local cTextoXML    := ""
    
    Default cDocumento := ""
    Default cSerie     := ""
        
    //Se tiver documento
    If !Empty(cDocumento)
        cDocumento := PadR(cDocumento, TamSX3('F2_DOC')[1])
        cSerie     := PadR(cSerie,     TamSX3('F2_SERIE')[1])
            
        //Instancia a conexão com o WebService do TSS    
        oWebServ:= WSNFeSBRA():New()
        oWebServ:cUSERTOKEN        := "TOTVS"
        oWebServ:cID_ENT           := cIdEnt
        oWebServ:oWSNFEID          := NFESBRA_NFES2():New()
        oWebServ:oWSNFEID:oWSNotas := NFESBRA_ARRAYOFNFESID2():New()
        aAdd(oWebServ:oWSNFEID:oWSNotas:oWSNFESID2,NFESBRA_NFESID2():New())
        aTail(oWebServ:oWSNFEID:oWSNotas:oWSNFESID2):cID := (cSerie+cDocumento)
        oWebServ:nDIASPARAEXCLUSAO := 0
        oWebServ:_URL              := AllTrim(cURLTss)+"/NFeSBRA.apw"
            
        //Se tiver notas
        If oWebServ:RetornaNotas()
            
            //Se tiver dados
            If Len(oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3) > 0
                
                //Se tiver sido cancelada
                If oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFECANCELADA != Nil
                    cTextoXML := oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFECANCELADA:cXML
                        
                //Senão, pega o xml normal
                Else
                    cTextoXML := '<?xml version="1.0" encoding="UTF-8"?>'
                    cTextoXML += '<nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">'
                    cTextoXML += oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFE:cXML
                    cTextoXML += oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFE:cXMLPROT
                    cTextoXML += '</nfeProc>'
                    cTextoXML := Encode64(cTextoXML)
                EndIf
                    
            //Caso não encontre as notas, mostra mensagem
            Else
                ConOut("fWSpedXML > Verificar parâmetros, documento e série não encontrados ("+cDocumento+"/"+cSerie+")...")
            EndIf
            
        //Senão, houve erros na classe
        Else
            ConOut("fWSpedXML > "+IIf(Empty(GetWscError(3)), GetWscError(1), GetWscError(3))+"...")
        EndIf

    EndIf

    RestArea(aArea)

Return (cTextoXML)
