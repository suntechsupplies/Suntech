#INCLUDE 'PROTHEUS.CH' 

/*
===============================================================================================================================
Programa----------: HBTMKST
Autor-------------: Gustavo Buson
Data da Criacao---: 10/06/2019
===============================================================================================================================
Descrição---------: Cadastro de Status dos Atendimentos no Televendas
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function HBTMKST

Private cCadastro    := "Status SAC Suntech"
Private aRotina  := MenuDef()
Private cAlias  := "SZ1"

AxCadastro(cAlias,cCadastro,,)  // Não funciona
//mBrowse( ,,,, cAlias )  // Funciona
Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 28/08/2018
===============================================================================================================================
Descrição---------: Utilizacao de Menu Funcional
===============================================================================================================================
Parametros--------: aRotina
        1. Nome a aparecer no cabecalho
        2. Nome da Rotina associada
        3. Reservado
        4. Tipo de Transa‡„o a ser efetuada:
      1 - Pesquisa e Posiciona em um Banco de Dados
      2 - Simplesmente Mostra os Campos
      3 - Inclui registros no Bancos de Dados
      4 - Altera o registro corrente
      5 - Remove o registro corrente do Banco de Dados
        5. Nivel de acesso
        6. Habilita Menu Funcional
===============================================================================================================================
Retorno-----------: Array com opcoes da rotina
===============================================================================================================================
*/
Static Function MenuDef()

Local aRotina := {    { "Pesquisar"  , "AxPesqui"      , 0 , 1 } ,;
        { "Visualizar"  , "AxVisual"      , 0 , 2 } ,;
        { "Incluir"      , "AxInclui"      , 0 , 3 } ,;
        { "Alterar"      , "AxAltera"      , 0 , 4 } ,;
        { "Excluir"      , "AxDeleta"  , 0 , 5 }  }

Return( aRotina )

