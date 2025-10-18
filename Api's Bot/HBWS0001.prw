#INCLUDE "TOTVS.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "tbiconn.ch"
#INCLUDE "APWEBSRV.CH"

#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch" 


WSRESTFUL hbws0001 DESCRIPTION "hbws0001"
    
    WSMETHOD POST getfiles DESCRIPTION 'Realiza o getfiles de um arquivo' WSSYNTAX "/getfiles" PATH "/getfiles" PRODUCES "application/json;charset=utf-8"

ENDWSRESTFUL

WSMETHOD POST getfiles WSREST hbws0001

	Local oRet		:= JsonObject():new()
    Local cJson     := self:getContent()
    Local aRet      := {} /*Ricardo Araujo*/
    
    ::SetContentType('application/json')
    
    If !Empty(cJson)     
        aRet := getFiles(cJson)    
        If aRet[1]
            lRet    := .T.            
            oRet['TOTAL']    := 1
            oRet['PAGINA']   := 1
            oRet['PORPAGINA']:= 1
            oRet['PROXIMO']  := .F.
            oRet['RETORNOS'] := aRet[2]
            cRet := oRet:toJson()
            ::SetResponse(EncodeUtf8(cRet))
        Else
            lRet    := .F.
            oRet["message"] := aRet[2]
            oRet["type"]   := "error"
            oRet["code"]   := "400"
            SetRestFault(400, EncodeUTF8(aRet[2]))
        EndIf
    Else 
        lRet    := .F.
        SetRestFault(400, EncodeUTF8('Erro no Body'))
    EndIf
Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} getFiles
Retorna os base64 do arquivo, tipos aceitos sao boleto/danfe e xml
@author  Sidney Sales
@since   03/11/2021
@version 1.0
/*/
//-------------------------------------------------------------------

Static Function getFiles(cJson)
    
    Local oJson     := JsonObject():New()
    Local lRet      := .T.
    Local aParam    := {}
    Local i, cTitulo, cPrefixo, cCliente, cSerie, cNF, cDirDest, cIdEnt, cParcela
    Local aRet64    := {}
    Local cBarra    := '\'
    Local cFilAux   := cFilAnt    
    Default cTipo   := ValType(oJson['tipo']) //B=Boleto, D=Danfe, X=xml

    if IsSrvUnix()
        cBarra := "/"
    endif
    
    oJson:FromJson(cJson)

    //Valida se o tipo veio correamente
    If ValType(oJson['tipo']) == 'U'
        return {.F., 'body:tipo não enviado. Opções: B=Boleto, D=Danfe, X=XML'}
    EndIf

    //Inicia as variáveis, nem todas serao utilizadas, as que nao forem, serao iniciadas com vazio
    cFilAnt      := Iif(ValType(oJson['filial'])    != 'U', oJson['filial']     , cFilAux)
    cCliente     := Iif(ValType(oJson['cliente'])   != 'U', oJson['cliente']    , '')
    cLoja        := Iif(ValType(oJson['loja'])      != 'U', oJson['loja']       , '')
    cNF          := Iif(ValType(oJson['titulo'])    != 'U', oJson['titulo']     , '')
    cSerie       := Iif(ValType(oJson['prefixo'])   != 'U', oJson['prefixo']    , '')    
    cTitulo      := Iif(ValType(oJson['titulo'])    != 'U', oJson['titulo']     , '')
    cPrefixo     := Iif(ValType(oJson['prefixo'])   != 'U', oJson['prefixo']    , '')
    cParcela     := Iif(ValType(oJson['parcela'])   != 'U', oJson['parcela']    , '')

    //Caso seja tipo boleto, chamara a rotina usada pela HB passando os parametros
    If oJson['tipo'] == 'B'
        
        aAdd(aParam, 2)         //nTipo     := PARAMIXB[1] (Sempre será reimpressao)     
        aAdd(aParam, cSerie)    //cSerieDan := PARAMIXB[2]  
        aAdd(aParam, cNf)       //cNotaDan  := PARAMIXB[3]
        aAdd(aParam, cTitulo)   //cPrefTit  := PARAMIXB[4] 
        aAdd(aParam, cPrefixo)  //cTitulo   := PARAMIXB[5]  
        aAdd(aParam, cCliente)  //cCodCli   := PARAMIXB[6]  
        aAdd(aParam, .T.)       //lApi	    := PARAMIXB[7]
        aAdd(aParam, cParcela)  //cParApi   := PARAMIXB[8]		
        
        //Chama a rotina que gerará os arquivos
        aRet := EXECBLOCK("BOLHBPDF",.F.,.F.,aParam)

        If ValType(aRet) != 'A' 
            aRet64 := 'Não foi possível gerar o boleto'
            lRet   := .F.
        //Verifica se tem retorno e grava no array para retorno
        ElseIf Len(aRet) > 0
            For i := 1 to Len(aRet)                                
                oAux := getObj(aRet[i][1])
                oAux['linhadigitavel'] := StrTran(StrTran(aRet[i][2], '.', ''), ' ', '')
                aAdd(aRet64, oAux )                
                If FERASE(aRet[i][1]) == -1
                    Conout('Erro ao deletar arquivo(HBWS001)')
                EndIf                
            Next
        Else
            aRet64 := 'Boleto não localizado com os dados informados'
            lRet   := .F.
        EndIf

    //Se for danfe e xml
    ElseIf oJson['tipo'] $ 'D,X'
        
        //Tenta setar a NF
        If SF2->(DbSeek(xFilial('SF2') + Padr(cNF, Len(SF2->F2_DOC)) + Padr(cSerie, Len(SF2->F2_SERIE)) + Padr(cCliente, Len(SF2->F2_CLIENTE)) + Padr(cLoja, Len(SF2->F2_LOJA))))

            //Codigo da entidade usada no TSS, as rotinas padroes que devolvem esse código não retornavam corretamente e foi preciso fixar
            cIdEnt      := SuperGetMv('UF_ENTTSS', .F., , xFilial('SF2'))
            
            //Caso seja DANFE, chama a rotina que preenhce os parametros chamará a impressão padrão do danfe
            If oJson['tipo'] == 'D'  //DANFE            
                aRet  := danfe64(cIdEnt, cSerie, cNF)
                cMimi := 'application/pdf'
            EndIf

            //Se for XML, gera através de rotina customizada da UF, antes, cria o diretório 
            If oJson['tipo'] == 'X' //XML        
                cDirDest := '\uf\xml\'
                MakeDir('\uf\')
                MakeDir('\uf\xml\')
                aRet := U_UF_GERXML(SF2->(Recno()), cDirDest)
                cMimi := 'application/xml'
            EndIf

            //Caso o retorno seja ok, grava o objeto de retorno no array
            If aRet[1]
                aAdd(aRet64, getObj(aRet[2], cMimi))
                FERASE(aRet[2])        
            Else
                lRet := .F.
                aRet64 := aRet[2]
            EndIf
        
        Else
            Return { .F.,  'NF não localizada com os dados informados' }    
        EndIf

    Else
        Return { .F.,  'body:tipo não inválido. Opções: B=Boleto, D=Danfe, X=XML' }    
    EndIf
    
    cFilAnt := cFilAux

Return {lRet, aRet64}

//-------------------------------------------------------------------
/*/{Protheus.doc} getObj
Funcao auxiliar apenas pra devolver o objeto preenchido
@author  Sidney Sales
@since   03/11/2021
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function getObj(cFile, cMimiType)
    
    Local cBase64   := Enc64(cFile)        
    Local oJsonAux  := JsonObject():New()

    Default cMimiType := 'application/pdf'

    oJsonAux['base64_arquivo'] := 'data:'+cMimiType+';base64,' + cBase64

Return oJsonAux

//-------------------------------------------------------------------
/*/{Protheus.doc} Enc64
Funcao que converte um arquivo em base64
Nao foi usada a rotina padrao de conversão pois em alguns casos ela 
não funcionava
@author  Sidney Sales
@since   29/10/2021
@version 1.0
/*/
//-------------------------------------------------------------------
Static Function Enc64(cFile)
    
    Local cTexto := ""
    Local aFiles := {} // O array receberá os nomes dos arquivos e do diretório
    Local aSizes := {} // O array receberá os tamanhos dos arquivos e do diretorio

    ADir(cFile, aFiles, aSizes)//Verifica o tamanho do arquivo, parâmetro exigido na FRead.

    nHandle := fopen(cFile , FO_READWRITE + FO_SHARED )
    cString := ""
    
    If Len(aSizes) > 0
        FRead( nHandle, cString, aSizes[1] ) //Carrega na variável cString, a string ASCII do arquivo.
        cTexto := Encode64(cString) //Converte o arquivo para BASE64
    EndIf
    
    fclose(nHandle)

return cTexto

//-------------------------------------------------------------------
/*/{Protheus.doc} danfe64
Funcao auxiliar criada para gerar um arquivo do danfe de uma NF especifica.
Isto será utilizado no bot
@type function
@version 12.1.27
@author Sidney Sales
@since 31/05/2021
@param cEntidade, character, Entidade
@param cSerie, character, Série da NF
@param cDoc, character, Número da NF
@return character, base64 do PDF da NF
/*/
//-------------------------------------------------------------------

Static Function danfe64(cEntidade, cSerie,  cDoc)

    Local oDanfe        := nil
    Local oSetup        := nil
    Local lEnd          := .F.
    Local lExistNFe     := .T.
    Local lIsLoja       := .F.
        
    Local cPath         := "ufdanfes"
    Local cArquivo		:= ''
    Local cBarra        := '\'
    Local cNFE_ID	    := cDoc + '_' + StrTran(Time(), ':', '_')
    Local aRet          := {.F., ''}

	if !empty(cEntidade) 

		if IsSrvUnix()
			cBarra := "/"
		endif
        
        cPathAux := cBarra + cPath + cBarra
		
        If !ExistDir(cBarra + cPath + cBarra + cEntidade + cBarra)

            cPathAux := cBarra + cPath + cBarra

            MakeDir(cPathAux)

            cPathAux += cEntidade

            If MakeDir(cPathAux) <> 0
                return {.F., 'Não foi possível criar a pasta ' + cPathAux + ' no servidor '				 }
			endIf

		endIf
        
        cPath       := cBarra + cPath + cBarra + cEntidade + cBarra
		cArquivo	:= cPath +  alltrim(cNFE_ID)+".pdf"
        		
        FERASE(cArquivo)
		
        oDANFE := FWMSPrinter():New(alltrim(cNFE_ID), IMP_PDF, .F. /*lAdjustToLegacy*/,cPath/*cPathInServer*/,.T.,/*lTReport*/,/*oPrintSetup*/,/*cPrinter*/,/*lServer*/,/*lPDFAsPNG*/,/*lRaw*/,.F.,/*nQtdCopy*/)
        oDanfe:SetResolution(78)
        oDanfe:SetPortrait()
        oDanfe:SetPaperSize(DMPAPER_A4)
        oDanfe:SetMargin(60,60,60,60)
        oDanfe:lServer := .T.
        oDanfe:nDevice := IMP_PDF
        oDanfe:cPathPDF := cPath
        oDANFE:SetCopies( 1 )
                    
        //alimenta parametros da tela de configuracao da impressao da DANFE
        MV_PAR01 := Padr(cDoc, Len(SF2->F2_DOC))
        MV_PAR02 := Padr(cDoc, Len(SF2->F2_DOC))
        MV_PAR03 := Padr(cSerie, Len(SF2->F2_SERIE))
        MV_PAR04 := 0 //[Operacao] NF de Entrada / Saida
        MV_PAR05 := 2 //[Frente e Verso] Nao
        MV_PAR06 := 2 //[DANFE simplificado] Nao

        oDanfe:lInJob := .T.

        U_DANFEProc(@oDanfe, @lEnd, cEntidade, Nil, Nil, @lExistNFe, lIsLoja)

        if !oDanfe:Preview() .or. !file(cArquivo)
            aRet := { .F., "Nao foi possivel gerar a DANFE para entidade: "+ alltrim(cEntidade) + " nota: " + alltrim(cNFE_ID) }
        Else
            aRet := {.T., cArquivo}
        endif

		oSetup := nil
		oDanfe := nil
    else
        return aRet := {.F., 'O código da entidade do TSS não foi informado.'}
	endif        

return aRet

//Rotina de testes
User Function testefiles

    Local oJson

    If Empty(FunName())
        PREPARE ENVIRONMENT EMPRESA '01' FILIAL '01'
    EndIf

    oJson := JsonObject():New()
    //82644
    //  000082623
    oJson['filial']   := '02'
    oJson['nf']       := '000082644'
    oJson['serie']    := '1'
    oJson['cliente']  := 'C04263'
    oJson['loja']     := '01'
    oJson['parcela']  := '01'

    // oJson['tipo']       := 'D'
    // oJson['prefixo']    := '1'
    // oJson['titulo']     := '000082644'

    // getFiles(oJson:toJson())

    oJson['tipo']       := 'B'
    
    oRet		:= JsonObject():new()
    
    aRet := getFiles(oJson:toJson())
    
    oRet['TOTAL']    := 1
    oRet['PAGINA']   := 1
    oRet['PORPAGINA']:= 1
    oRet['PROXIMO']  := .F.
    oRet['RETORNOS'] := aRet[2]    
    cRet := oRet:toJson()        
Return

/*Estrutura de Dados a ser enviada para a API através do método POST*/
//{
//    "filial": "02",
//    "titulo": "000104987",
//    "prefixo": "1",
//    "cliente": "C12302",
//    "loja": "01",
//    "tipo": "B",
//    "parcela": "01"
//}
