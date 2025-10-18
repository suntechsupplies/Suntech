#Include 'Protheus.ch'
#include "Fileio.ch"
/*---------------------------------------------------------------------------------------------------------
{Protheus.doc}  tGzip
                Exemplo Tzip
@type           function
@version        1.0
@author         Carlos Eduardo Saturnino - Atlanta Consulting
@since          28/10/2021
@return         variant, return_description
---------------------------------------------------------------------------------------------------------*/
User Function tGzip()

    Local cTexto := ""
    Local aFiles := {} // O array receber� os nomes dos arquivos e do diret�rio
    Local aSizes := {} // O array receber� os tamanhos dos arquivos e do diretorio

    ADir("C:\tmp\img.jpg", aFiles, aSizes)//Verifica o tamanho do arquivo, par�metro exigido na FRead.

    nHandle := fopen('C:\tmp\img.jpg' , FO_READWRITE + FO_SHARED )
    cString := ""
    FRead( nHandle, cString, aSizes[1] ) //Carrega na vari�vel cString, a string ASCII do arquivo.

    cTexto := Encode64(cString) //Converte o arquivo para BASE64

    fclose(nHandle)

    //Cria uma c�pia do arquivo utilizando cTexto em um processo inverso(Decode64) para validar a convers�o.    
    nHandle := fcreate("C:\tmp\img2.jpg")
    FWrite(nHandle, Decode64(cTexto))
    fclose(nHandle)

Return
