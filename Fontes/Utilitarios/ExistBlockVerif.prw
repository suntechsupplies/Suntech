#Include "protheus.ch"

User Function Verify()

Local cMensagem := "Existe o ponto de entrada AIC060VPR"
Local cTítulo   := "AIC060VPR"
Local lAIC060VP := ExistBlock("AIC060VPR")
Local aEtiqueta := {}

// Opções do MessageBox
#define MB_OK              s0
#define MB_OKCANCEL        1
#define MB_YESNO           4
#define MB_ICONHAND        16
#define MB_ICONQUESTION    32
#define MB_ICONEXCLAMATION 48
#define MB_ICONASTERISK    64
  
// Retornos possíveis do MessageBox
#define IDOK			   1
#define IDCANCEL		   2
#define IDYES			   6
#define IDNO			   7


	// quando os elementos abaixo estiverem em branco e' porque nao foi conferido
	If lAIC060VP .and. ! ExecBlock("AIC060VPR",.F.,.F.,{"000001082385",1,{"10100040261001",1,"","",""}})

        MessageBox(cMensagem,cTítulo,MB_ICONEXCLAMATION)
		Break

    EndIf

Return
