#include "rwmake.ch"


Static Function zBaixa()

    Local aBaixa      := {}
    Local cAgencia    := ""
    Local cBanco      := ""
    Local _cFil       := ""
    Local cNum        := ""
    Local cPrefixo    := ""
    Local cTipo       := ""
    Local cConta      := ""
    Local cNumBlu     := ""
    Local cNatureza   := ""
    Local cNtMovBan   := ""
    Local cTipoPg     := ""
    Local nValor      := 0
    Local nVlPort     := 0
    Local nDescont    := 0
    Local nBluTaxa    := 0
    Local nVlTaxa     := 0
    Local lMsErroAuto := .F.
    Local lRet        := .T.
    Local aArea       := GetArea()
    
            
    
    _cFil     := (cAliasBl)->FILIAL
    cNumBlu   := (cAliasBl)->NUMBLU
    cPrefixo  := (cAliasBl)->PREFIXO
    cNum      := (cAliasBl)->NUM
    cTipo     := (cAliasBl)->TIPO
    nValor    := (cAliasBl)->VALOR
    nVlPort   := (cAliasBl)->VLPORT
    cTipoPg   := (cAliasBl)->TIPOPG
    cNatureza := (cAliasBl)->NATUREZA
    cBanco    := PADR(GetMV('CP_BLUFBCO'),TAMSX3("A6_COD")[1])
    cAgencia  := PADR(GetMV('CP_BLUFAGE'),TAMSX3("A6_AGENCIA")[1])
    cConta    := PADR(GetMV('CP_BLUFCTA'),TAMSX3("A6_NUMCON")[1])
    cNtMovBan := GetMV('CP_BLUNTMB')
    nBluTaxa  := GetMV('CP_BLUTAXA')

    //Se o pagamento foi realizado a vista é lançado o desconto
    //nDescont  := IIF(cTipoPg == "1", (((cAliasBl)->VALFAT * (cAliasBl)->RATEPG) / 100), 0)

    DbSelectArea("SE1")
    
    aBaixa := {{"E1_PREFIXO"   , cPrefixo          ,Nil    },;
               {"E1_NUM"      , cNum               ,Nil    },;
               {"E1_TIPO"     , cTipo              ,Nil    },;
               {"AUTMOTBX"    ,"NOR"               ,Nil    },;
               {"AUTBANCO"    , cBanco             ,Nil    },;
               {"AUTAGENCIA"  , cAgencia           ,Nil    },;
               {"AUTCONTA"    , cConta             ,Nil    },;
               {"AUTDTBAIXA"  , dDataBase          ,Nil    },;
               {"AUTDTCREDITO", dDataBase          ,Nil    },;
               {"AUTHIST"     ,"BAIXA BLU"         ,Nil    },;
               {"AUTDESCONT"  ,nDescont            ,Nil,.T.},;
               {"AUTJUROS"    ,0                   ,Nil,.T.},;
               {"AUTVALREC"   ,nValor              ,Nil    }}

    MSExecAuto({|x,y| Fina070(x,y)},aBaixa,3,.F.)  //| rotina padrão de baixa de títulos.

    If lMsErroAuto
        
        cLog+= "ERRO AO BAIXAR O TÍTULO: " +aBaixa[2][2]+" | " + MostraErro() + CRLF  
        lRet := .F.

    Else       

        cLog+= "TÍTULO: " +aBaixa[2][2]+" BAIXADO COM SUCESSO."   + CRLF                

    EndIf

    RestArea(aArea)

Return lRet
