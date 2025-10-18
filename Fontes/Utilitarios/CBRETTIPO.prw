user function CBRETIP2()

Local cID     := paramixb[1]

Local cTipo := ""

CB0->(DBSETORDER(1))
CB0->(DbSeek(Xfilial("CB0")+cID ))

cTipo := CB0->CB0_TIPO

VtAlert("Passou pelo ponto de entrada = CBRETIP2 = ","Aviso!",.t.,4000)
// Customização de usuário

return cTipo
