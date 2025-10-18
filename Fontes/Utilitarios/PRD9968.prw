#Include "PROTHEUS.CH"
#INCLUDE "TopConn.ch"

//--------------------------------------------------------------
/*/{Protheus.doc} PRD9968
Description

@param xParam Parameter Description
@return xRet Return Description
@author Leonardor
@since 27/03/2014
/*/
//--------------------------------------------------------------
User Function PRD9968()

Static oDlg
Static oButtonCanc
Static oButtonOk
Static oGetSer
Static cGetSer := "1 "
Static oGetNf
Static cGetNf := space(9)
Static oGetNi
Static cGetNi := space(9)
Static oGroup1
Static oSayNf
Static oSayNi
Static oSaySer

DEFINE MSDIALOG oDlg TITLE "Reenvio de E-mail XML" FROM 000, 000 TO 180, 206 COLORS 0, 16777215 PIXEL

    @ 000, 000 GROUP oGroup1 TO 068, 103 OF oDlg COLOR 0, 16777215 PIXEL
    @ 004, 005 SAY oSaySer        PROMPT "Série:"        SIZE 060, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 012, 005 MSGET oGetSer      VAR cGetSer            SIZE 060, 010 OF oDlg COLORS 0, 16777215 PIXEL
    @ 024, 005 SAY oSayNi         PROMPT "Nota Inicial:" SIZE 060, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 032, 005 MSGET oGetNi       VAR cGetNi             SIZE 080, 010 OF oDlg COLORS 0, 16777215 PIXEL PICTURE "@R 999999999"
    @ 044, 005 SAY oSayNf         PROMPT "Nota Final:"   SIZE 060, 007 OF oDlg COLORS 0, 16777215 PIXEL
    @ 052, 005 MSGET oGetNf       VAR cGetNf             SIZE 080, 010 OF oDlg COLORS 0, 16777215 PIXEL PICTURE "@R 999999999"
    @ 070, 021 BUTTON oButtonOk   PROMPT "Ok"            SIZE 037, 012 OF oDlg ACTION Reenviar()  PIXEL
    @ 070, 060 BUTTON oButtonCanc PROMPT "Cancelar"      SIZE 037, 012 OF oDlg ACTION Close(oDlg) PIXEL
ACTIVATE MSDIALOG oDlg

Return

Static Function Close(oDlg)
     oDlg:End()
Return .T.

Static Function Reenviar()

     Local cQuery  := ""
     Local cFilial := xFilial("SA1")
     Local cEnt    := ""

     Do Case
          Case (cFilial = '01')
               cEnt := '000001'
          Case (cFilial = '03')
               cEnt := '000002'
     EndCase

     cQuery := " UPDATE SPED050 "
     cQuery += " SET STATUSMAIL = '1' "
     cQuery += " WHERE "
     cQuery += "      ID_ENT = '"+cEnt+"' AND "
     cQuery += "      D_E_L_E_T_ = '' AND "
     cQuery += "      (NFE_ID BETWEEN '"+cGetSer+cGetNi+"' AND '"+cGetSer+cGetNf+"') "

     nRet = TcSqlExec(cQuery)
     If nRet <> 0
          cRet := TCSQLERROR()
          MsgBox(cRet)
     EndIf
     MsgInfo("E-mail será enviado em até 15 mins.")
     Close(oDlg)

Return .T.
