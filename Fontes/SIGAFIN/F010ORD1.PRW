#include 'protheus.ch'
#include 'TOTVS.ch'	
/*------------------------------------------------------------------------------------
{Protheus.doc}  F010ORD1
                Altera a ordenação do Array de títulos da posição Financeira
@type           function
@version        1.0
@author         Carlos Eduardo Saturnino - Atlanta consulting
@since          05/04/2022
@return         cIndes, novo índice a ser usado no array de Títulos
------------------------------------------------------------------------------------*/
User Function F010ORD1()
    
    Local cIndex    := "DTOS(E1_VENCREA)"
    Local aArea     := GetArea()

    RestArea(aArea)

Return(cIndex)
