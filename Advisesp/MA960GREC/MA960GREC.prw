#include 'protheus.ch'

/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  MA960GREC  º Autor ³ Julio              º Data ³  25/07/23   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³preenchimento dos campos F6_TIPOGNU, F6_DOCORIG, F6_DETRECE º±±
±±º          ³e F6_CODPROD de acordo com o código de receita e UF.        º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³                                                            º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
//-------------------------------------------------------------------

User Function MA960GREC()
 
    Local aParam    := {0, '', '', 0, ''}   //Parâmetros de retorno default
    Local cReceita  := PARAMIXB[1]          //Código de Receita da guia atual
    Local cUF       := PARAMIXB[2]          //Sigla da UF da guia atual
    Local aUFESt    := {}
    Local cDocOr    := "1"
    Local nPos      := 0
    Local nCodPro   := 34

    aAdd( aUFESt, { "AC", 10 } )
    aAdd( aUFESt, { "AL", 10 } )
    aAdd( aUFESt, { "AM", 22 } )
    aAdd( aUFESt, { "AP", 10 } )
    aAdd( aUFESt, { "BA", 10 } )
    aAdd( aUFESt, { "CE", 10 } )
    aAdd( aUFESt, { "DF", 24 } )
    aAdd( aUFESt, { "GO", 10 } )
    aAdd( aUFESt, { "MA", 10 } )
    aAdd( aUFESt, { "MG", 10 } )
    aAdd( aUFESt, { "MS", 22 } )
    aAdd( aUFESt, { "MT", 22 } )
    aAdd( aUFESt, { "PA", 10 } )
    aAdd( aUFESt, { "PB", 10 } )
    aAdd( aUFESt, { "PE", 24 } )
    aAdd( aUFESt, { "PI", 10 } )
    aAdd( aUFESt, { "PR", 10 } )
    aAdd( aUFESt, { "RJ", 22 } )
    aAdd( aUFESt, { "RN", 22 } )
    aAdd( aUFESt, { "RO", 10 } )
    aAdd( aUFESt, { "RR", 10 } )
    aAdd( aUFESt, { "RS", 22 } )
    aAdd( aUFESt, { "SC", 24 } )
    aAdd( aUFESt, { "SP", 22 } )
    aAdd( aUFESt, { "SE", 10 } )
    aAdd( aUFESt, { "TO", 22 } )

    nPos := aScan( aUFESt, { |x| x[1] == cUF } )
    
    If nPos > 0
        nCodigo := aUFESt[nPos][2]

        If nCodigo == 10
            cDocOr := "1"       //Retorna os campos F6_TIPOGNU, F6_DOCORIG, F6_DETRECE, F6_CODPROD e F6_CODAREA de acordo com o código de receita e sigla da UF da guia atual.
        ElseIf nCodigo == 24 .OR. nCodigo == 22
            cDocOr := "2"
        Endif

        If cUF == "MT" .AND. Alltrim(cReceita) == "100099"
            cReceita := "000105"
        ElseIf cUF == "MT" .AND. Alltrim(cReceita) == "100102"
            cReceita := "000055"
        ElseIf cUF == "MT" .AND. Alltrim(cReceita) == "100129"
            cReceita := "000057"
        Endif

        cReceita := M->F6_CODREC
        
        If cUF $ "AC/AM/AP/BA/CE/GO/MG/MS/PA/PI/PR/RJ/RN/RR/RS/SE"
            cReceita := "      "
        Endif

        If cUF == "PE"
            nCodPro := 20
        Else
            nCodPro := 34
        Endif

        aParam := {nCodigo, cDocOr, cReceita, nCodPro, ''}
    Endif
 
Return aParam
