
//salva no log de console (geralmente \protheus10\bin\appserver\totvsconsole.log) com indicação do dia em que foi compilado.

User function mostra_fonte()

Local aFontes := {}
Local nI , nT
aFontes := GetSrcArray("*.PRW")
nT := len(aFontes)
If nT > 0
   For nI := 1 to nT
     aData := GetAPOInfo(aFontes[nI])
     conout("Fonte "+aData[1]+";"+aData[2]+";"+aData[3]+";"+dtoc(aData[4]))
   Next
   MsgInfo("Fontes encontrados. Verifique log de console.")
Else
   MsgStop("Nenhum fonte encontrado.")
Endif

Return
