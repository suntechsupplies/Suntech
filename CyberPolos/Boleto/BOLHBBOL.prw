#Include 'Protheus.ch'
#Include "rwmake.ch"   
#Include 'TBICONN.CH'
#Include "TOPCONN.CH"
/*/{Protheus.doc} User Function BOLHBBOL
    Usada na Impressão e reimpressão de boletos, podendo selecionar se será impresso, por email ou ambos.
    @type  Function
    @author Cyberpolos | Suntech Supplies
    @since 01/02/2021
    @version 12.1.25 
/*/
User Function BOLHBBOL()

    Local _oDlg
    Private _cNfIni := PADR("",TAMSX3("F2_DOC")[1])
    Private _cNfFin := PADR("",TAMSX3("F2_DOC")[1])
    Private _cSerie := PADR("1",TAMSX3("F2_SERIE")[1])
    Private _aProcess  := {"1=Impressão","2=Reimpressão"}
    Private _cProcess  := "2"
    Private _cAlias := ""
    Private lCheck1 := .F.
	Private lCheck2 := .F.
	Private oCheck1 := Nil
	Private oCheck2 := Nil
    
    DEFINE DIALOG _oDlg TITLE "Impressão de boleto"  FROM 180,180 TO 450,500 PIXEL

        //Nota Inicial
        _oBrowse := TGet():New( 015,030,{|u|If( PCount() == 0,_cNfIni,_cNfIni := u)},_oDlg,060,010,"@!",{||},0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,"SF2","_cNfIni",,,,.F.,.F.,,'Nf De : ',2)
        //Nota Final
        _oBrowse := TGet():New( 035,030,{|u|If( PCount() == 0,_cNfFin,_cNfFin := u)},_oDlg,060,010,"@!",{||},0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,"SF2","_cNfFin",,,,.F.,.F.,,'Nf Ate: ',2)
        //Serie
        _oBrowse := TGet():New( 055,030,{|u|If( PCount() == 0,_cSerie,_cSerie := u)},_oDlg,030,010,"@!",{||},0,,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F.,,"_cSerie",,,,.F.,.F.,,'Serie : ',2) 

        oBrowse := TComboBox():New(075,030,{|u|If( PCount() == 0,_cProcess,_cProcess := u)},_aProcess,080,013,_oDlg,,{||},,,,.T.,,,,,,,,,'_cProcess',"Processar:",1)
        
        oCheck1:= TCheckBox():New(100,030,'Impresso',,_oDlg,100,210,,,,,,,,.T.,,,)
        oCheck2:= TCheckBox():New(100,090,'E-mail',,_oDlg,100,210,,,,,,,,.T.,,,)
        
        // Seta Eventos do primeiro Check
        oCheck1:bSetGet := {|| lCheck1 }
        oCheck1:bLClicked := {|| lCheck1:=!lCheck1 }
        
        oCheck2:bSetGet := {|| lCheck2 }
        oCheck2:bLClicked := {|| lCheck2:=!lCheck2 }
        
        oCheck1:CtrlRefresh()
        oCheck2:CtrlRefresh()

        TButton():New( 115, 065, "Confirmar", _oDlg,{||xDados(_oDlg)},40,015,,,.F.,.T.,.F.,,.F.,,,.F. ) 
        TButton():New( 115, 115, "Sair", _oDlg,{||close(_oDlg)},40,015,,,.F.,.T.,.F.,,.F.,,,.F. ) 

    ACTIVATE DIALOG _oDlg CENTERED

Return

Static Function xDados(_oDlg)

    Local lRet := .T.
    Local nOpcImp := IIf(_cProcess == "1",1,2)  //|1 - impressão  2 - reimpressão 
    Local nOpcPdf := IIf(_cProcess == "1",1,2)  //|1 - impressão  2 - reimpressão 

    If !Empty(_cSerie) .And. !Empty(_cNfIni)

        If _cNfFin < _cNfIni
           _cNfFin := _cNfIni
        EndIf

        lRet := xGetSf2()

        If lRet
            (_cAlias)->(DbGoTop()) 

            While (_cAlias)->(!Eof())                               
                    
                If ExistBlock("BOLHBIMP",.F.,.T.) .And. lCheck1  
                    ExecBlock("BOLHBIMP",.F.,.T.,{nOpcImp,(_cAlias)->SERIE,(_cAlias)->DOC})
                Endif

                nOpcPdf := IIf(lCheck1 .Or. _cProcess == "2" ,3,1)

                If ExistBlock("BOLHBPDF",.F.,.T.) .And. lCheck2 
                    ExecBlock("BOLHBPDF",.F.,.T.,{nOpcPdf,(_cAlias)->SERIE,(_cAlias)->DOC,'','',''})
                Endif
                
                (_cAlias)->(dbskip()) 

            EndDo

            (_cAlias)->(DbCloseArea())
            _oDlg:End()

        EndIf
    Else        
        MsgInfo("Os Campos NF e Serie, devem ser preenchidos.","Atenção")
    EndIf
    
Return

Static Function xGetSf2()

    Local cQuery := ""    
    Local lCont  := .F.
    Local _nTotal := 0
    Local cCond := FormatIN(Alltrim(GetMv('CP_BOLCOND')),'/')	

    _cAlias    := GetNextAlias()

    cQuery+=" SELECT" 
    cQuery+="   F2_FILIAL AS FILIAL,"
    cQuery+="	F2_DOC AS DOC,"
    cQuery+="   F2_SERIE AS SERIE"
    cQuery+=" FROM" 
    cQuery+="	"+Retsqlname("SF2") + " A (NOLOCK)"
    cQuery+=" WHERE" 
    cQuery+="	A.D_E_L_E_T_ <> '*' " 
    cQuery+="	AND A.F2_DOC BETWEEN '" + _cNfIni + "' AND '" + _cNfFin + "' "
    cQuery+="	AND A.F2_SERIE = '" +_cSerie + "' "
    cQuery+="	AND A.F2_COND not in " + cCond  
    cQuery+="	ORDER BY  F2_DOC
    
    TCQuery cQuery NEW ALIAS (_cAlias)

    count To _nTotal

    If _nTotal > 0
        lCont := .T.        
    Else
        MsgInfo("Não foram localizados registros para os parametros informados.","Atenção")
        (_cAlias)->(DbCloseArea())
        lCont := .F.
    EndIf

Return lCont
