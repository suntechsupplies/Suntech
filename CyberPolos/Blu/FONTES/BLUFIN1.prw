#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'tbiconn.ch'
#Include 'topconn.ch'  

/*/{Protheus.doc} BluFin1
Utilizada para localizar tí­tulos em atraso de um cliente no periodo determinado. Esses serão exibidos para seleção na markbrowser.
@type User Function
@version 2.0
@author Cyberpolos
@since 17/06/2020
/*/

User Function BluFin1()

    Local aArea      := GetArea()
    Local cPerg      := 'BLUFIN01'
    Local lUseBlu    := .F.
    Private cAlias   := ""
    Private cAlias2  := ""
    Private cCodCli  := ""
    Private cLoja    := ""
    Private cNomeCli := ""
    Private lRet     := .F.
    
    lUseBlu :=  GetMv('CP_BLUUSE') //| Parametro para verIficar se as rotina BLU está ativa

    If lUseBlu  //| Se rotinas API BLU estiver ativada
        
        If Pergunte(cPerg,.T.) //| Se as perguntas foram confirmadas
            Processa({||zGetSe1()},,,.T.)
        Else
            Return
        EndIf
        
        If lRet     //| Se há tí­tulos em atraso
            zMark() //| chamada para tela com titulos em atraso.
        EndIf

    Else

        MsgInfo("As rotinas da API BLU estão como desativadas no parametro CP_BLUUSE.","Atenção")

    EndIf

    RestArea(aArea)

Return

/*/{Protheus.doc} zGetSe1
description
@type Static Function
@version 2.0 
@author Cyberpolos
@since 17/06/2020
@param cPerg, character, recebe informações preenchida nas perguntas
@Return lRet, logico, retorna se a registros na SE1.
/*/
Static Function zGetSe1()

    Local cPortador := FormatIN(Alltrim(GetMv('CP_BLUFIN3')),'/') //Recebe informações do parametro de PORTADOR (E1_PORTADO) que a select não trara.
    Local cQuery    := ""
    Local cSituacao := FormatIN(Alltrim(GetMv('CP_BLUFIN2')),'/') //Recebe informações do parametro de SITUACAO (E1_SITUACA) que a select não trara.
    Local cTipo     := FormatIN(Alltrim(GetMv('CP_BLUFIN1')),'/') //Recebe informações do parametro de TIPO (E1_TIPO) de titulos que a select não trara.
       
    cAlias    := GetNextAlias()

    cQuery+=" SELECT" 
    cQuery+=" space(2) AS OK,"
    cQuery+="	E1_FILIAL AS FILIAL,"
    cQuery+="	E1_NUM AS NUMERO,"
    cQuery+="   E1_PARCELA AS PARCELA,"
    cQuery+="	E1_CLIENTE AS CLIENTE,"
    cQuery+="   E1_LOJA AS LOJA,"
    cQuery+="   CONVERT(CHAR(10), CONVERT(DATETIME, E1_VENCREA), 103) AS VENCREAL,"
    cQuery+="   E1_SALDO AS SALDO,"
    cQuery+="   E1_TIPO AS TIPO,"
    cQuery+="   E1_PREFIXO AS PREFIXO,"
    cQuery+="   E1_VALOR AS VALOR,"
    cQuery+="   E1_NOMCLI AS NOME,"
    cQuery+="   E1_XNUMBLU AS NUMBLU"
    cQuery+=" FROM" 
    cQuery+="	"+Retsqlname("SE1") + " (NOLOCK)"
    cQuery+=" WHERE" 
    cQuery+="	D_E_L_E_T_ <> '*' " 
    cQuery+="	AND E1_CLIENTE = '" +MV_PAR01+ "' AND E1_LOJA = '" +MV_PAR02+ "' "
    cQuery+="	AND E1_VENCREA BETWEEN '" +DTOS(MV_PAR03)+ "' AND '" +DTOS(MV_PAR04)+ "' "
    cQuery+="	AND LTRIM(RTRIM(E1_TIPO)) not in " + cTipo
    cQuery+="	AND E1_SITUACA not in " + cSituacao
    cQuery+="	AND LTRIM(RTRIM(E1_PORTADO)) not in " + cPortador
    cQuery+="   AND	E1_SALDO > 0 "
    cQuery+="   AND	E1_XNUMBLU = ' ' "
    cQuery+="	ORDER BY  E1_NUM, E1_PARCELA, E1_CLIENTE, E1_LOJA, E1_VENCREA" 
    
    TCQuery cQuery NEW ALIAS (cAlias)
    
    If (cAlias)->(EOF()) //| Se não há registros, defino para não seguir
       
        (cAlias)->(DbCloseArea())
        MsgInfo("Não há registros para os parâmetros informados.","Atenção")
       
        lRet := .F.
        
    Else

        lRet := .T.
        cCodCli   := MV_PAR01
        cLoja     := MV_PAR02
        cNomeCli  := Alltrim(POSICIONE ("SA1",1,xFilial("SA1")+cCodCli+cLoja,"A1_NOME"))

    EndIf
   
Return

/*/{Protheus.doc} zMarck
Monta markbrowser com os dados de títulos vencidos. 
@type Static Function
@version 1.0
@author Cyberpolos
@since 17/06/2020
/*/
Static Function zMark()
    
    Local aButtons    := {}
    Local aCpoBro     := {}
    Local cArq        := ""
    Local oFont       := TFont():New('Courier new',,-14,.T.)
    Private _lMd      := .T.
    Private cMark     := GetMark()
    Private lInverte  := .F.
    Private nQtdGeral := 0
    Private oDlg      := Nil
    Private oMark     := Nil
    Private oSay      := Nil

    //| Define quais colunas serao exibidas na MsSelect
    aCpoBro	:= {{ "OK"			,, "Mark"       ,"@!"},;
			    { "FILIAL"		,, "Filial"     ,"@!"},;
                { "NUMERO"		,, "Numero"     ,"@!"},;	
			    { "PREFIXO"		,, "Prefixo"    ,"@!"},;		
			    { "PARCELA"		,, "Parcela"    ,"@!"},;	
                { "TIPO"		,, "Tipo"       ,"@!"},;
                { "VALOR"		,, "Valor R$"   ,"@E 999,999,999.99"},;			
                { "SALDO"		,, "Saldo R$"   ,"@E 999,999,999.99"},;	
			    { "VENCREAL"	,, "Venc. Real" ,"@D"},;
                { "NUMBLU"		,, "Num. BLU"   ,"@!"}}                	   

    DEFINE MSDIALOG oDlg TITLE "Tí­tulos em atraso" From 9,0 To 590,1000 PIXEL

        DbSelectArea((cAlias))

        cArq := CriaTrab(NIL,.F.)
        Copy To &cArq
        (cAlias)->(DbCloseArea())

        cAlias2    := GetNextAlias()

        //| Abre arquivo temporario
        DbUseArea(.T.,,cArq,cAlias2,.T.)
        DbGoTop()

        oMark := MsSelect():New((cAlias2),"OK","",aCpoBro,@lInverte,@cMark,{30,1,250,500},,,,,)
        oMark:bMark := {|| Disp(1)} 

        oSay :=	TSay():New( 260,020,{||"Cód. Cliente: " +cCodCli },oDlg,,oFont,,,,.T.,,,500,10)
        oSay :=	TSay():New( 260,140,{||"Loja: " +cLoja },oDlg,,oFont,,,,.T.,,,500,10)
        oSay :=	TSay():New( 270,020,{||"Nome: " +cNomeCli },oDlg,,oFont,,,,.T.,,,500,10)
        oSay :=	TSay():New( 270,420,{||"Total: " +CvalTochar(Transform(nQtdGeral,"@E 99,999.99")) },oDlg,,oFont,,,,.T.,,,500,10)

        //| Add botão Marcar/Desmarcar todas os títulos.
        Aadd( aButtons, {"Marcar/Desmarcar", {|| Disp(2)}, "Marcar/Desmarcar", "Marcar/Desmarcar" , {|| .T.}} ) 

    //| Exibe a Dialog
    ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar(oDlg,{|| IIF(zSalvar(),oDlg:End(),oDlg)},{|| oDlg:End()},,@aButtons)	

    //| Fecha a Area e elimina os arquivos de apoio criados em disco.
    (cAlias2)->(DbCloseArea())
    	
	IIf(File(cArq + GetDBExtension()),FErase(cArq  + GetDBExtension()) ,Nil)
       
Return

/*/{Protheus.doc} Disp
Seleção dos títulos em atraso.
@type Static Function
@version 2.0
@author Cyberpolos
@since 22/06/2020
@param nOpc, numeric,  1 = está sendo clicado um registro por vez, 2 está sendo enviado para marcar/desmarcar todos os registros.
/*/
Static Function Disp(nOpc)
 	
    If nOpc = 1 //| opção 1 = selecionando linha a linha

       If (cAlias2)->OK == cMark

             RecLock((cAlias2), .F. )                
               (cAlias2)->OK := cMark         
            MsUnLock() 

            nQtdGeral += (cAlias2)->SALDO  //| Soma os valores

        Else

            RecLock((cAlias2), .F. )                
               (cAlias2)->OK := SPACE(2)         
            MsUnLock() 

            nQtdGeral -= (cAlias2)->SALDO //| subtrai os valores
            
        EndIf

   
    Else  //| opção 2 = marca/desmarca todos

        nQtdGeral := 0 //| limpo a variavel

        If _lMd

            dbSelectArea((cAlias2))
            (cAlias2)->(DbGoTop())
            
            While !Eof()        

                If RecLock( (cAlias2), .F. )                
                        (cAlias2)->OK := cMark               
                   MsUnLock()   
                EndIf

                nQtdGeral += (cAlias2)->SALDO  //| Soma os valores
    
                (cAlias2)->(dbSkip())
            EndDo

            _lMd := .F.

        Else

            dbSelectArea((cAlias2))
            (cAlias2)->(DbGoTop())

            While !Eof() 

                If RecLock( (cAlias2), .F. )                
                        (cAlias2)->OK := SPACE(2)                
                MsUnLock()        
                EndIf        
               
                (cAlias2)->(dbSkip())

            EndDo

            _lMd := .T.

        EndIf

    EndIf

	oMark:oBrowse:Refresh()
    oSay:Refresh()

Return

/*/{Protheus.doc} zSalvar
Salva na tabela de integração BLU, e grava o numero BLU no campo E1_XNUMBLU dos títulos selecionados.
@type Static Function
@version 2.0
@author Cyberpolos
@since 23/06/2020
/*/
Static Function zSalvar()

    Local cFiltro  := ""
    Local cLog     := ""
    Local cNumBlu  := ""
    local _cFil    := ""
    Local nQtdSel  := 0
    Local nSpc     := 15
   
    dbSelectArea((cAlias2))

    //| Filtro os selecionados
    cFiltro := " (cAlias2)->OK  ==  '" + cMark + "' "

    //| Aplico o filtro
    (cAlias2)->( DBSetFilter ({||&cFiltro},cFiltro) )
	
	Count To nQtdSel
    
    If nQtdSel > 0
    
        
        cNumBlu := SuperGetMv('CP_BLUNUM',,'')    //| Pega o numero BLU
	    cProBlu := soma1(cNumBlu)                 //| proximo numero Blu
	 
	    
	    SX6->(Dbseek(xFilial()+"CP_BLUNUM"))
		SX6->(RecLock("SX6",.F.))                 //| grava o proximo numero Blu no parametro.
			SX6->X6_CONTEUDO := cProBlu           //| Conteudo em Portugues
			SX6->X6_CONTENG  := cProBlu           //| Conteudo em Ingles
			SX6->X6_CONTSPA  := cProBlu           //| Conteudo em Espanhol
		SX6->(MsUnlock())

        If !empty(cNumBlu)

            cLog += ' Título(s) | ' + DTOC(date())+ " - "+time() + CRLF
            cLog += ' PREFIXO       NUMERO         PARCELA     TIPO        ' + CRLF
            
            dbSelectArea("SE1")
            DbSetOrder(2)  //| E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO

            (cAlias2)->(DbGoTop())

            _cFil := (cAlias2)->FILIAL

            While (cAlias2)->(!EOF())

                //| E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
                If DbSeek( _cFil + cCodCli + cLoja + (cAlias2)->PREFIXO + (cAlias2)->NUMERO + (cAlias2)->PARCELA + (cAlias2)->TIPO )

                    //armazena para log
                    clog += "  " +  alltrim((cAlias2)->PREFIXO) + space(nSpc-len(alltrim((cAlias2)->PREFIXO))) +"| " +;
                              alltrim((cAlias2)->NUMERO) + space(nSpc-len(alltrim((cAlias2)->NUMERO))) + "| " +;
                              alltrim((cAlias2)->PARCELA) + space(nSpc-len(alltrim((cAlias2)->PARCELA))) + "| "+;
                              alltrim((cAlias2)->TIPO) + space(nSpc-len(alltrim((cAlias2)->TIPO))) + CRLF
                        
                        //| Gravo o numero BLU nos títulos selecionados
                        RecLock("SE1",.F.)
                          SE1->E1_XNUMBLU := cNumBlu
                        SE1->( MsunLock())

                EndIf
            
                (cAlias2)->(dBskip())   
        
            EndDo             
            
            dbSelectArea("ZBL")

            RecLock("ZBL",.T.)

                ZBL->ZBL_FILIAL := _cFil
                ZBL->ZBL_NUMBLU := cNumBlu
                ZBL->ZBL_VALOR  := nQtdGeral
                ZBL->ZBL_CODCLI := cCodCli
                ZBL->ZBL_LOJA   := cLoja
                ZBL->ZBL_NOME   := cNomeCli
                ZBL->ZBL_INTEGR := ' '  //status  = aguardando integração
                ZBL->ZBL_DATA   := Date()
                ZBL->ZBL_ORIGEM := 'SE1'
                ZBL->ZBL_USER   := Alltrim(Substr(cUsername,1,20))
                ZBL->ZBL_LOGORI := cLog
                ZBL->ZBL_CGC    := Alltrim(POSICIONE ("SA1",1,xFilial("SA1")+cCodCli+cLoja,"A1_CGC"))
                ZBL->ZBL_BAIXAT := "N" 
           
            ZBL->(MsunLock())

            MsgInfo("Cobrança BLU nº "+cNumBlu+ ", gerada com sucesso. Aguarde integração automática ao Portal BLU.", "Atenção" )

            oDlg:End()

        Else

            MsgAlert( "Não foi possível gerar o número BLU [ZBL_NUMBLU] ", "Atenção" )
            
        EndIf    
    
    Else

        MsgInfo("É necessário ter selecionado ao menos um registro para seguir.", "Atenção" )
           
    EndIf

    //| Limpo o filtro
    (cAlias2)->(DBClearFilter())
    oMark:oBrowse:Refresh()
    oSay:Refresh()

Return 
