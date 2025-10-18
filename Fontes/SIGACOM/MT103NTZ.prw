#INCLUDE "MATA103.CH"
#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} MT103NTZ
Muda a natureza do título tipo NCC que será gerado apartir de uma nota fiscal de venda  
@author Antonio Ricardo de Araujo - Email: ricardo.araujo@hb.com.br
@since  01/09/2022
@version 1.0
@see Abaixo os paremetros que deverão ser utilizados
    MV_NATNCC - Código da Natuerza que irá ser utilizada para classificar a NCC
 
/*/
User Function MT103NTZ()          

Local ExpC1 := ParamIxb[1]
Local aArea := getArea()

    If ((SE1->E1_TIPO = "NCC") .AND. (cTipo = "D"))

        ExpC1 := GETMV("MV_NATNCC")
    Else

        ExpC1 := ParamIxb[1]

    EndIf

restArea(aArea)

Return ExpC1
