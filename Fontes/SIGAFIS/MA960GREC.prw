#include "protheus.ch" 
 
 
//-------------------------------------------------------------------
/*/{Protheus.doc} MA960GREC
Ponto de Entrada para preenchimento dos campos F6_TIPOGNU, F6_DOCORIG, F6_DETRECE e F6_CODPROD de acordo com o código de receita e UF.
 
@author 
@since 
/*/
//-------------------------------------------------------------------
User Function MA960GREC()
 
    Local aParam   := {0, '', '', 0, ''} //Parâmetros de retorno default
    Local cReceita := PARAMIXB[1]        //Código de Receita da guia atual
    Local cUF      := PARAMIXB[2]        //Sigla da UF da guia atual
 
    If Alltrim(cReceita) $ '100102'                  //.And. cUF $ 'SP' //Valida o Código de Receita e sigla da UF da guia atual
        aParam := {22, '2', '6666', 33, '000055'}    //Retorna os campos F6_TIPOGNU, F6_DOCORIG, F6_DETRECE, F6_CODPROD e F6_CODAREA de acordo com o código de receita e sigla da UF da guia atual.
    EndIf
    
Return aParam
