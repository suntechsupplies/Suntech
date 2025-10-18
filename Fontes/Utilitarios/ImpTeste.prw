#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'


User Function ImpTeste()

Local nx
Local cFontMaior := "016,013" //Fonte maior - títulos dos campos obrigatórios do DANFE ("altura da fonte, largura da fonte")
Local cFontMenor := "015,008" //Fonte menor - campos variáveis do DANFE ("altura da fonte, largura da fonte")
Local cPorta := "LPT1"  

    MSCBPRINTER("ZEBRA",cPorta,,,.F.,,,,,,)

    MSCBCHKSTATUS(.F.)

    MSCBBEGIN(1,4)   

For nx:=1 to 3

    If nx > 1
        MSCBBEGIN(1,4)
    EndIf
    
    //Criação do Box
    MSCBBox(02,02,98,148)

    //Criação das linhas Horizontais - sentido: de cima para baixo
    MSCBLineH(02, 012, 98)
    MSCBLineH(02, 047, 98)
    MSCBLineH(02, 057, 98)
    MSCBLineH(02, 084, 98)
    MSCBLineH(40, 101, 98)
    MSCBLineH(02, 101, 98)
    MSCBLineH(02, 111, 98)
    MSCBLineH(02, 138, 98)

    //Criação das linhas verticais - sentido: da direita para esquerda
    MSCBLineV(32, 84, 101)
    MSCBLineV(64, 84, 101)

    //Criação dos campos de textos fixos da etiqueta
    MSCBSay(17.5, 06.25, "DANFE SIMPLIFICADO - ETIQUETA", "N", "A", cFontMaior)
    MSCBSay(04  , 15   , "CHAVE DE ACESSO:"             , "N", "A", cFontMaior)
    MSCBSay(22.5, 48.75, "PROTOCOLO DE AUTORIZACAO:"    , "N", "A", cFontMaior)
    MSCBSay(04, 60,      "NOME/RAZAO SOCIAL:"           , "N", "A", cFontMaior)
    MSCBSay(04, 66.25 ,  "CPF:"                         , "N", "A", cFontMaior)
    MSCBSay(04  , 70    , "IE:"                         , "N", "A", cFontMaior)
    MSCBSay(04  , 73.75 , "UF:"                         , "N", "A", cFontMaior)
    MSCBSay(04  , 88.75 , "SERIE:"                      , "N", "A", cFontMaior)
    MSCBSay(04  , 93.75 , "N_A7:"                       , "N", "A", cFontMaior)
    MSCBSay(34  , 88.75 , "DATA EMISSAO:"               , "N", "A", cFontMaior)
    MSCBSay(65.5, 88.75 , "TIPO OPER.:"                 , "N", "A", cFontMaior)
    MSCBSay(65.5, 92.5  , "0 - ENTRADA"                 , "N", "A", cFontMenor)
    MSCBSay(65.5, 96.25 , "1 - SAIDA"                   , "N", "A", cFontMenor)
    MSCBSay(35  , 105.5 , "DESTINATARIO"                , "N", "A", cFontMaior)
    MSCBSay(04  , 113.75, "NOME/RAZAO SOCIAL:"          , "N", "A", cFontMaior) 
    MSCBEND()               

Next	

MSCBCLOSEPRINTER()

Return
