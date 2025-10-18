#include 'tbiconn.ch'
#Include "FILEIO.CH"       
#include "apwizard.ch"
#Include "RWMAKE.CH"
#Include "TOPCONN.CH"
#include 'TOTVS.CH'


/*/{Protheus.doc} User Function BOLHBDIA
    Rotina utilizada para selecionar um periodo de data em que sera reenviados os boletos. A rotina marcara o campo 
    E1_XBOMAIL = "4" para que o schedule posteriormente envie o boleto atraves da rotina BOLHBPDF.
    @type  Function
    @author user
    @since 21/02/2022
    @version 1.0
/*/
User Function BOLHBDIA()

    Local _oDlg
    Local _oTGet

    Private  _dDtIni  := Date()
    Private  _dDtFin  := Date()
    Private  _cCliIni := PADR("",TAMSX3("A1_COD")[1])
    Private  _cCliFin := PADR("",TAMSX3("A1_COD")[1])
    Private  _cBanco  := PADR("",TAMSX3("E1_PORTADO")[1])
    Private  _nTot    := 0
    Private  _cAlias  := ''
    Private  _nTotal  := 0
    Private  lEnd  

    DEFINE MSDIALOG _oDlg TITLE  "Reenvio de boletos por data"  FROM 010,010 TO 350,300 OF _oDlg PIXEL

    _oTGet := TGet():New( 010, 045, { | u | If( PCount() == 0, _dDtIni, _dDtIni := u ) },_oDlg, 060, 010, "@D",, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"_dDtIni",,,,.F.,.F.,,'Data De:',1)
    _oTGet := TGet():New( 035, 045, { | u | If( PCount() == 0, _dDtFin, _dDtFin := u ) },_oDlg, 060, 010, "@D",, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"_dDtFin",,,,.F.,.F.,,'Data Até:',1)
    _oTGet := TGet():New( 060, 045, { | u | If( PCount() == 0, _cCliIni, _cCliIni := u ) },_oDlg, 060, 010, "@!",{||_cCliFin:= PADR("",TAMSX3("A1_COD")[1])}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,"SA1","_cCliIni",,,,.F.,.F.,,'Cliente De:',1)
    _oTGet := TGet():New( 085, 045, { | u | If( PCount() == 0, _cCliFin, _cCliFin := u ) },_oDlg, 060, 010, "@!",{||_cBanco  := PADR("",TAMSX3("E1_PORTADO")[1])}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,"SA1","_cCliFin",,,,.F.,.F.,,'Cliente Até:',1)
    _oTGet := TGet():New( 110, 045, { | u | If( PCount() == 0, _cBanco, _cBanco := u ) },_oDlg, 060, 010, "@!",, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,"SA6","_cBanco",,,,.F.,.F.,,'Portador:',1)

    // Botões
    TButton():New( 145, 030, "Iniciar", _oDlg,{||IIf(!Empty(_dDtIni) .and. xVldDt(),xProgresso(Close(_oDlg)),_oDlg)},40,015,,,.F.,.T.,.F.,,.F.,,,.F. ) 
    TButton():New( 145, 080, "Fechar", _oDlg,{||Close(_oDlg)},40,015,,,.F.,.T.,.F.,,.F.,,,.F. ) 

ACTIVATE MSDIALOG _oDlg CENTER

Return

/*/{Protheus.doc} xVldDt
    Valida as datas informadas, se estiver ok busca as informações na SE1.
    @type  Static Function
    @author Cyberpolos
    @since 22/02/2022
    @version 1.0
/*/
Static Function xVldDt()

    Local _lOk := .T.

    If !Empty(_dDtIni)
        If Empty(_dDtFin)
                _dDtFin := _dDtIni 
        ElseIf _dDtFin < _dDtIni
                MsgInfo(' O campo DATA ATÉ, não pode ser menor que o DATA DE !','Atenção')
                _lOk := .F.
        EndIf 
    Else  
        MsgInfo(' O campo DATA DE, deve ser preenchido!','Atenção')
        _lOk := .F.
    EndIf

    If (!Empty(_cCliIni) .or. !Empty(_cCliFin)).and. _lOk

        If !Empty(_cCliIni) .and. Empty(_cCliFin)
            _cCliFin := _cCliIni
        ElseIf !Empty(_cCliFin) .and. Empty(_cCliIni)
            _cCliIni := _cCliFin
        ElseIf _cCliFin < _cCliIni
           MsgInfo("O campo CLIENTE DE, não pode ser maior que o campo CLIENTE ATÉ.", "Atenção")
           _lOk := .F.
        EndIf

    EndIf
       
    If _lOk  
        _lOk:= xGetSE1()  //| Busca dados para preenchimento da DCF.      
    EndIf

Return _lOk

/*/{Protheus.doc} xGetSE1
    Select na SE1 em busca de registros que estejam dentro da data informada.
    @type  Static Function
    @author Cyberpolos
    @since 22/02/2022
    @version 1.0
/*/
Static Function xGetSE1()

    Local _lOk := .T. 
    Local _cDtIni 
    Local _cDtFin

    _cAlias  := GetNextAlias()
	
	_cDtIni := DTOS(_dDtIni)
	_cDtFin := DTOS(_dDtFin)

    cQuery := " SELECT SE1.R_E_C_N_O_ RECNO, SE1.E1_XBOMAIL E1_XBOMAIL,"
    cQuery += " SE1.E1_NUM E1_NUM, SE1.E1_PREFIXO E1_PREFIXO"	
    cQuery += " FROM " + RetSqlName("SE1") + " SE1 (NOLOCK)"
    cQuery += " INNER JOIN " + RetSqlName("SED") + " SED (NOLOCK)"  // Ricardo Araujo - Suntech 27/04/2023            
    cQuery += " ON SE1.E1_NATUREZ = SED.ED_CODIGO "                 // Alteração Realizada para Impedir
    cQuery += " AND SED.ED_ENVCOB <> '2' "                          // envio de boletos para natureza 
    cQuery += " AND SED.D_E_L_E_T_ = '' "                           // de operações que não permite envios
    cQuery += " WHERE SE1.D_E_L_E_T_ = '' "
    cQuery += " AND SE1.E1_FILIAL = '" + xFilial("SE1") + "'"
    cQuery += " AND SE1.E1_SALDO > 0 "
    cQuery += " AND SE1.E1_NUMBCO <> '' "
    cQuery += " AND SE1.E1_XBCO <> '' "
    cQuery += " AND SE1.E1_XAGE <> '' "
    cQuery += " AND SE1.E1_XCONTA <> '' "
    cQuery += " AND SE1.E1_VENCREA BETWEEN '" + _cDtIni + "' AND '" + _cDtFin + "' "

    If !Empty(_cCliIni)
        cQuery += " AND SE1.E1_CLIENTE BETWEEN '" + _cCliIni + "' AND '" + _cCliFin + "' "
    EndIf

    If !Empty(_cBanco)
        cQuery += " AND SE1.E1_PORTADO = '" + _cBanco + "' "
    EndIf
    
    TCQuery cQuery NEW ALIAS (_cAlias)

    count To _nTotal

    if _nTotal = 0
        MsgInfo("Não foi localizado registros para o periodo informado","Atenção")
        _lOk := .F.          
    endif 
    
Return _lOk

/*/{Protheus.doc} xProgresso
    Barra de progresso
    @type  Static Function
    @author Cyberpolos
    @since 22/02/2022
    @version 1.0
/*/
Static Function xProgresso()  

    Processa({|lEnd|xPutSE1(@lEnd)},"Aguarde...", "Executando rotina.",.T.)

Return

/*/{Protheus.doc} xPutSE1
    Preenche o campo E1_XBOMAIL para que o mesmo seja selecionado pela rotina BOLHBPDF em schedule para reenvio do boleto.
    @type  Static Function
    @author Cyberpolos
    @since 22/02/2022
    @version 1.0
/*/
 Static Function xPutSE1(lEnd)
 
 	ProcRegua(_nTotal)

    (_cAlias)->(DbGotop())  

    While (_cAlias)->(!EOF())

        IncProc("Agendando envio do boleto nº: "+(_cAlias)->E1_NUM)

        SE1->(DbGoTo((_cAlias)->RECNO))

        RecLock("SE1",.F.)
            SE1->E1_XBOMAIL = '4'
        MsUnlock()

        (_cAlias)->(DbSkip())

    EndDo

    (_cAlias)->(dbCloseArea ())

Return
