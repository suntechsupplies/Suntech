#Include "Protheus.ch"
#Include "TopConn.ch"

 
/*----------------------------------------------------------------------
{Protheus.doc}  MT410ROD
                Ajuste do Valor para acatar o desconto de Cash Back
@type           function
@version        
@author         Carlos Eduardo Saturnino
@since          07/05/2021
@return         return_type, return_description
---------------------------------------------------------------------*/ 
User Function MT410ROD()
    Local aArea     := GetArea()
    Local oObjOrig  := ParamIXB[1]
    Local cDescCli  := ParamIXB[2]
    Local nValBruto := ParamIXB[3] 
    Local nValDescA := ParamIXB[4] //+ C5_CASHBAK
    Local nValLiq   := ParamIXB[5] //- C5_CASHBAK

    //----------------------------------------------------------------     
    // Altera as descrições
	// Trecho comentado em 19/05/2021 até ser discutido internamente
	// como irá ser feito o controle de Cash Back
    //----------------------------------------------------------------     
    Eval(   oObjOrig            ,;
            cDescCli            ,;
            nValBruto           ,;
            nValDescA           ,;
            nValLiq              )
    
    RestArea(aArea)

Return
