#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

User Function HTML()
    Local aSize         := MsAdvSize()
    Local nPort         := 0
    Local cPasta        := "\boletos\"
    Local cHtml         := cPasta + "mailbody.html"
    Local oModal
    Local oWebEngine 
    Private oWebChannel := TWebChannel():New()
     
    //Se a pasta não existir, cria a pasta
    If ! ExistDir(cPasta)
        MakeDir(cPasta)
    EndIf
 
    //Se o arquivo não existir, cria um vazio
    If ! File(cHtml)
        MemoWrite(cHtml, "<h1>Arquivo não encontrado!</h1>")
    EndIf
 
    //Cria a dialog
    oModal := MSDialog():New(aSize[7],0,aSize[6],aSize[5], "Página Local",,,,,,,,,.T./*lPixel*/)
 
        //Prepara o conector
        nPort := oWebChannel::connect()
 
        //Cria o componente que irá carregar o arquivo local
        oWebEngine := TWebEngine():New(oModal, 0, 0, 100, 100,/*cUrl*/, nPort)
        oWebEngine:SetHtml(MemoRead(EncodeUTF8(cHtml, "cp1251")))
        oWebEngine:Align := CONTROL_ALIGN_ALLCLIENT
    oModal:Activate()
Return

Static Function readFile()

    //Definindo o arquivo a ser lido
    oFile := FWFileReader():New("\boletos\mailbody.html")
    
    //Se o arquivo pode ser aberto
    If (oFile:Open())
    
        //Se não for fim do arquivo
        If !(oFile:EoF())
            cConteudo  := oFile:FullRead()
            
            //Alert(cConteudo)
        EndIf
        
        //Fecha o arquivo e finaliza o processamento
        oFile:Close()
    EndIf

    HTML()
    
Return cConteudo
