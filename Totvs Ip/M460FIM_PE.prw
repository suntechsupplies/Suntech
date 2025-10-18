#INCLUDE "totvs.ch"
#INCLUDE "parmtype.ch"

/*/{Protheus.doc} M460FIM

Ponto de entrada no final da geracao da NF Saida, utilizado
para gravacao de dados adicionais.

@type function
@author Deivid A. C. de Lima
@since 19/04/2010

@see MSGNF02
/*/
User Function M460FIM()

	//Executa o Wizard do Acelerador de Mensagens da NF no final da geração da NF de Saída
	if funname() <> 'ACDV168'
		If ExistBlock("MSGNF02",.F.,.T.)
			ExecBlock("MSGNF02",.F.,.T.,{})
		Endif
	endif
Return
