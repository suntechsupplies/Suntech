#include 'totvs.ch'    
#include 'protheus.ch'

/*
Rotina		:	MA265TDOK
Autor		:	Dione Oliveira
Data		:	07/08/2019
Descricao	:	Ponto de entrada executado na confirma��o do              
				endere�amento de produtos, evitando assim que qualquer    
				produto seja endere�ado fora do m�s que o produto foi     
				produzido/comprado    									  
Obs	 		:

*/

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
			Alert("Endere�amento deve ser feito no mesmo m�s da movimenta��o, favor verificar a data que esse produto est� sendo endere�ado!")
		endif
   	endif  	
Next nI              

Return lExecuta                           