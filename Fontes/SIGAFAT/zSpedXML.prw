//Bibliotecas
#Include "Protheus.ch"
    
/*/{Protheus.doc} zSpedXML
Função que gera o arquivo xml da nota (normal ou cancelada) através do documento e da série disponibilizados
@author Atilio
@since 25/07/2017
@version 1.0
@param cDocumento, characters, Código do documento (F2_DOC)
@param cSerie, characters, Série do documento (F2_SERIE)
@param cArqXML, characters, Caminho do arquivo que será gerado (por exemplo, C:\TOTVS\arquivo.xml)
@param lMostra, logical, Se será mostrado mensagens com os dados (erros ou a mensagem com o xml na tela)
@type function
@example Segue exemplo abaixo
    u_zSpedXML("000176349", "1", "C:\TOTVS\arquivo1.xml", .F.) //Não mostra mensagem com o XML
        
    u_zSpedXML("000000001", "1", "C:\TOTVS\arquivo2.xml", .T.) //Mostra mensagem com o XML
/*/
    
User Function zSpedXML(cDocumento, cSerie, cArqXML, lMostra)
    Local aArea        := GetArea()
    Local cURLTss      := PadR(GetNewPar("MV_SPEDURL","http://"),250)  
    Local oWebServ
    Local cIdEnt       := RetIdEnti()
    Local cTextoXML    := ""
    Local oFileXML
    Default cDocumento := "000176349"
    Default cSerie     := "1"
    Default cArqXML    := GetTempPath()+"arquivo_"+cSerie+cDocumento+".xml"
    Default lMostra    := .T.
        
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
                        
                //Senão, pega o xml normal (foi alterado abaixo conforme dica do Jorge Alberto)
                Else
                    cTextoXML := '<?xml version="1.0" encoding="UTF-8"?>'
                    cTextoXML += '<nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="4.00">'
                    cTextoXML += oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFE:cXML
                    cTextoXML += oWebServ:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFE:cXMLPROT
                    cTextoXML += '</nfeProc>'
                EndIf
                    
                //Gera o arquivo
                oFileXML := FWFileWriter():New(cArqXML, .T.)
                oFileXML:SetEncodeUTF8(.T.)
                oFileXML:Create()
                oFileXML:Write(cTextoXML)
                oFileXML:Close()
                    
                //Se for para mostrar, será mostrado um aviso com o conteúdo
                If lMostra
                    Aviso("zSpedXML", cTextoXML, {"Ok"}, 3)
                EndIf
                    
            //Caso não encontre as notas, mostra mensagem
            Else
                ConOut("zSpedXML > Verificar parâmetros, documento e série não encontrados ("+cDocumento+"/"+cSerie+")...")
                    
                If lMostra
                    Aviso("zSpedXML", "Verificar parâmetros, documento e série não encontrados ("+cDocumento+"/"+cSerie+")...", {"Ok"}, 3)
                EndIf
            EndIf
            
        //Senão, houve erros na classe
        Else
            ConOut("zSpedXML > "+IIf(Empty(GetWscError(3)), GetWscError(1), GetWscError(3))+"...")
                
            If lMostra
                Aviso("zSpedXML", IIf(Empty(GetWscError(3)), GetWscError(1), GetWscError(3)), {"Ok"}, 3)
            EndIf
        EndIf
    EndIf
    RestArea(aArea)
Return
