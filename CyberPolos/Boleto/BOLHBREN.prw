#Include 'Protheus.ch'
#Include "rwmake.ch"   
#Include 'TBICONN.CH'
#Include "TOPCONN.CH"

/*/{Protheus.doc} User Function BOLHBREN
    (long_description)
    @type  Function
    @author Cyberpolos
    @since 01/02/2021
    @version 1.0
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
    /*/
User Function BOLHBREN()

    Local _oDlg
    Local lExec       := .F.
    Private _cTitIni  := PADR("",TAMSX3("E1_NUM")[1])
    Private _cTitFin  := PADR("",TAMSX3("E1_NUM")[1])
    Private _cPrefixo := PADR("1",TAMSX3("E1_PREFIXO")[1])
    Private _cCliIni  := PADR("",TAMSX3("A1_COD")[1])
    Private _cCliFin  := PADR("",TAMSX3("A1_COD")[1])
    Private _cEmiIni  := Ctod("  /  /  ")
    Private _cEmiFin  := Ctod("  /  /  ")
    Private _cAlias   := ""
    Private _aProcess  := {"1=Envio","2=Reenvio"}
    private _cProcess  := "1"

    DEFINE DIALOG _oDlg TITLE "Boletos Renegociados"  FROM 180,180 TO 580,500 PIXEL

        //Nota Inicial
        _oBrowse := TGet():New( 015,030,{|u|If( PCount() == 0,_cTitIni,_cTitIni := u)},_oDlg,060,010,"@!",{||},0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,"SE1","_cTitIni",,,,.F.,.F.,,'Título De:      ',2)
        //Nota Final
        _oBrowse := TGet():New( 035,030,{|u|If( PCount() == 0,_cTitFin,_cTitFin := u)},_oDlg,060,010,"@!",{||},0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,"SE1","_cTitFin",,,,.F.,.F.,,'Título Até:     ',2)
        //Serie
        _oBrowse := TGet():New( 055,030,{|u|If( PCount() == 0,_cPrefixo,_cPrefixo := u)},_oDlg,040,010,"@!",{||},0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,"_cPrefixo",,,,.F.,.F.,,'Prefixo:         ',2) 
        //Cliente inicial
        _oBrowse := TGet():New( 075,030,{|u|If( PCount() == 0,_cCliIni,_cCliIni := u)},_oDlg,040,010,"@!",{||},0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,"SA1","_cCliIni",,,,.F.,.F.,,'Cliente De:    ',2) 
        //Cliente final
        _oBrowse := TGet():New( 095,030,{|u|If( PCount() == 0,_cCliFin,_cCliFin := u)},_oDlg,040,010,"@!",{||},0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,"SA1","_cCliFin",,,,.F.,.F.,,'Cliente Até:   ',2) 
       //Emissão inicial
        _oBrowse := TGet():New( 115,030,{|u|If( PCount() == 0,_cEmiIni,_cEmiIni := u)},_oDlg,040,010,"@D",{||},0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,"_cEmiIni",,,,.F.,.F.,,'Emis. De:      ',2) 
       //Emissão final
        _oBrowse := TGet():New( 135,030,{|u|If( PCount() == 0,_cEmiFin,_cEmiFin := u)},_oDlg,040,010,"@D",{||},0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,"_cEmiFin",,,,.F.,.F.,,'Emis. Até:     ',2) 
        
        oBrowse := TComboBox():New(155,030,{|u|If( PCount() == 0,_cProcess,_cProcess := u)},_aProcess,055,013,_oDlg,,{||},,,,.T.,,,,,,,,,'_cProcess',"Processar:   ",2)

        TButton():New( 180, 065, "Confirmar", _oDlg,{||lExec:= .T.,close(_oDlg)},40,015,,,.F.,.T.,.F.,,.F.,,,.F. ) 
        TButton():New( 180, 115, "Sair", _oDlg,{||close(_oDlg)},40,015,,,.F.,.T.,.F.,,.F.,,,.F. ) 

    ACTIVATE DIALOG _oDlg CENTERED

    If lExec        
        xDados()
    EndIf
Return

Static Function xDados()

    Local cIndexName := ""
    Local cIndexKey  := ""
    Local cFilter    := ""
    Local _oDlg      := Nil
    Local lExec      := .F.
    
    	
    _cTitFin := Iif(Empty(_cTitFin),_cTitIni,_cTitFin)    
    _cCliFin := Iif(Empty(_cCliFin),_cCliIni,_cCliFin)    
    _cEmiFin := Iif(Empty(_cEmiFin),_cEmiIni,_cEmiFin)    
    cIndexName	:= Criatrab(Nil,.F.)
	//cIndexKey	:= "E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO+DTOS(E1_EMISSAO)"
	cIndexKey	:= "E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO"
    
    
    cFilter	+= "E1_FILIAL=='"+xFilial("SE1")+"' .And. E1_SALDO > 0 .And."
	cFilter	+= " E1_PREFIXO ='" + _cPrefixo + "'"

    If !Empty(_cTitIni) .Or. !Empty(_cTitFin)
	    cFilter	+= " .And. E1_NUM >='" + _cTitIni + "' .And. E1_NUM <= '" + _cTitFin + "'"
    EndIf
    If !Empty(_cCliIni) .Or. !Empty(_cCliFin)
	    cFilter	+= " .And. E1_CLIENTE>='" + _cCliIni + "'.And. E1_CLIENTE<='" + _cCliFin + "'"
    EndIf
    If !Empty(_cEmiIni) .Or. !Empty(_cEmiFin)	
	    cFilter	+= " .And. DTOS(E1_EMISSAO)>='"+DTOS(_cEmiIni)+"'.and. DTOS(E1_EMISSAO)<='"+DTOS(_cEmiFin)+"'"
    EndIf

    If _cProcess == "1"
	    cFilter += ".And. Alltrim(E1_TIPO)$('NF|FT') .And. Empty(E1_NUMBCO) "    
    Else
        cFilter += ".And. Alltrim(E1_TIPO)$('NF|FT') .And. E1_XBOMAIL = '2' "  
    EndIf
	

    IndRegua("SE1", cIndexName, cIndexKey,, cFilter, "Aguarde selecionando registros....")
    DbSelectArea("SE1")
    #IFNDEF TOP
        DbSetIndex(cIndexName + OrdBagExt())
    #ENDIF
    dbGoTop()


    @ 001,001 TO 400,700 DIALOG _oDlg TITLE "Seleção de Títulos"
	@ 001,001 TO 170,350 BROWSE "SE1" MARK "E1_OK"
	@ 180,310 BMPBUTTON TYPE 01 ACTION (lExec := .T.,Close(_oDlg))
	@ 180,280 BMPBUTTON TYPE 02 ACTION (lExec := .F.,Close(_oDlg))
	ACTIVATE DIALOG _oDlg CENTERED

    If lExec
	    Processa({|lEnd|NovoBol()})
    Endif

    RetIndex("SE1")
    Ferase(cIndexName+OrdBagExt())

Return


Static Function NovoBol()

    Local cTitulo := ""

    DbGoTop()
    ProcRegua(RecCount())
    
    While !EOF()

        If Marked("E1_OK")

            If Alltrim(cTitulo) == Alltrim(SE1->E1_NUM)
                SE1->(DbSkip())
                Loop
            EndIf            

            If ExistBlock("BOLHBPDF",.F.,.T.)
                If _cProcess == "1"
                    ExecBlock("BOLHBPDF",.F.,.T.,{1,,,SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_CLIENTE})
                Else
                    ExecBlock("BOLHBPDF",.F.,.T.,{2,,,SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_CLIENTE})
                EndIf
            Endif

        EndIf

        cTitulo := SE1->E1_NUM
        SE1->(DbSkip())

    EndDo

Return
