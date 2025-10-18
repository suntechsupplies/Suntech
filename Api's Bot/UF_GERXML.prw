#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWIZARD.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE "RPTDEF.CH"                                      
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "TOTVS.CH"
#INCLUDE "PARMTYPE.CH"
#INCLUDE 'TbIconn.ch'
#INCLUDE 'Topconn.ch'

//-------------------------------------------------------------------
/*/{Protheus.doc} UF_GERXML
    Função que gera arquivo xml de notas transmitidas
    a partir do RECNO da SF2
    @type  User Function
    @author Sidney Sales
    @since 31/01/2019
    @param nRecnoSF2, numerico, recno da SF2
    @param cDirDest, caractere, diretorio onde o xml será salvo
    @return lRet, lógico, return_description
/*/
//-------------------------------------------------------------------

 User Function UF_GERXML(nRecnoSF2, cDirDest, cIdEnt, lRetXml)
    
Local lRet          := .F.
Local cURLTss       := PadR(GetNewPar("MV_SPEDURL","http://"),250)  
Local oTss, cRet          
Default cIdEnt      := SuperGetMv('UF_ENTTSS', .F., , xFilial('SF2'))
Default lRetXml     := .F.
 
    If nRecnoSF2 > 0 

        SF2->(DbGoTo(nRecnoSF2))
        
        If SF2->(!EOF())

            cArquivo    := cDirDest + "arquivo_" + Alltrim(SF2->F2_SERIE) + Alltrim(SF2->F2_DOC) + ".xml"

            //Instancia a conexão com o WebService do TSS    
            oTss:= WSNFeSBRA():New()
            oTss:cUSERTOKEN        := "TOTVS"
            oTss:cID_ENT           := cIdEnt
            oTss:oWSNFEID          := NFESBRA_NFES2():New()
            oTss:oWSNFEID:oWSNotas := NFESBRA_ARRAYOFNFESID2():New()
            aAdd(oTss:oWSNFEID:oWSNotas:oWSNFESID2,NFESBRA_NFESID2():New())
            aTail(oTss:oWSNFEID:oWSNotas:oWSNFESID2):cID := SF2->(F2_SERIE+F2_DOC)
            oTss:nDIASPARAEXCLUSAO := 0
            oTss:_URL              := AllTrim(cURLTss)+"/NFeSBRA.apw"   
         
            If oTss:RetornaNotas()
            
                //Se tiver dados
                If Len(oTss:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3) > 0
                
                    If oTss:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFECANCELADA != Nil
                        cXml := oTss:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFECANCELADA:cXML                        
                    Else
                        cXml := oTss:oWsRetornaNotasResult:OWSNOTAS:oWSNFES3[1]:oWSNFE:cXML
                    EndIf
                    
                    If lRetXml
                        cRet := cXml
                        lRet := .T.
                    ElseIf !MemoWrite(cArquivo, cXml)
                        lRet := .F.
                        cRet := 'Erro na gravação do arquivo'
                    Else
                        lRet := .T.
                        cRet := cArquivo
                    EndIf
                                        
                //Caso não encontre as notas, mostra mensagem
                Else
                    cRet := 'NF não localizada'
                    lRet  := .F.
                EndIf
            
            //Senão, houve erros na classe
            Else
                cRet := IIf(Empty(GetWscError(3)), GetWscError(1), GetWscError(3))
                lRet  := .F.
            EndIf
        Else
            cRet := 'NF não localizada'
            lRet  := .F.
        EndIf

    EndIf

Return {lRet, cRet}
