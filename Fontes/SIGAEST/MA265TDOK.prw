#include 'totvs.ch'    
#include 'protheus.ch'

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³ MA265TDOK³ Modificado ³ Régis Ferreira   ³ Data ³ 14/06/17 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Ponto de entrada executado na confirmação do               ³±±
±±³          ³ endereçamento de produtos, evitando assim que qualquer     ³±±
±±³          ³ produto seja endereçado fora do mês que o produto foi      ³±±
±±³          ³ produzido/comprado    									  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
/*/

User Function MA265TDOK()
                          
Local lExecuta := .T.
Local dDataDA := (SDA->DA_DATA)
Local dDataDB    
Local CompareDB    
Local CompareDA     
Local aAreaSDB  := SDB->(GetArea())      
Local cChave

dbSelectArea("SDB")
dbsetorder(1)  
dbseek(xFilial("SDB") + SDA->(DA_PRODUTO+DA_LOCAL+DA_NUMSEQ+DA_DOC+DA_SERIE+DA_CLIFOR+DA_LOJA))
           
CompareDA := subStr(DTOS(dDataDA),1,6)
For nI:=1 to Len(aCols)
	If !aCols[nI,Len(aHeader)+1]
		dDataDB   := aCols[nI][GdFieldPos("DB_DATA")]
		CompareDB := subStr(DTOS(dDataDB),1,6)
		If CompareDB <> CompareDA .AND. aCols[nI][GdFieldPos("DB_ESTORNO")] <> "S" 
			lExecuta := .F.
			Alert("Endereçamento deve ser feito no mesmo mês da movimentação, favor verificar a data que esse produto está sendo endereçado!")
		endif
   	endif  	
Next nI              

Return lExecuta                           