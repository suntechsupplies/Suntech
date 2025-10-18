#include "rwmake.ch"

User Function FA060Qry()

    Local cRet    := ""
    Local lUseBlu := .T.

    //Parametro para verIficar se as rotina BLU está ativa
    lUseBlu :=  GetMv('CP_BLUUSE')

    If lUseBlu
        // Expressao SQL de filtro que sera adicionada a clausula WHERE da Query.
        cRet := " E1_XNUMBLU = '' "
    Else
        cRet := " E1_NUM <> '' "    
    EndIf

Return cRet
