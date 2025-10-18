#Include 'Protheus.ch'
#INCLUDE "TBICONN.CH" // BIBLIOTECA

User Function Impressora()

Local cPorta := "LPT1"
Local cModelo := "ZEBRA"

MSCBPRINTER(cModelo, cPorta,,10,.F.,,,,,,.F.,)
MSCBCHKSTATUS(.F.)
MSCBBEGIN(1,6)
MSCBSAY(10,10,"TESTE IMPRESSAO EM REDE", "N","A","040,030")
MSCBEND()
MSCBCLOSEPRINTER()

Return
