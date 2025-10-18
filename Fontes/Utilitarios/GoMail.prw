#Include 'TOTVS.CH'
#Include 'Protheus.ch'
#Include 'TBICONN.CH'


Static Function GoMail(_cFrom, _cTo, _cCC, _cBCC, _cSubject, _cBody, _cAttach1, _cAttach2)

	Local   _cEnv       := AllTrim(Upper(GetEnvServer()))
	Private _cSerMail	:= alltrim(GetMV("MV_RELSERV"))
	Private _cConta    	:= alltrim(GetMV("MV_RELACNT"))
	Private _cSenha		:= alltrim(GetMV("MV_RELPSW"))
	Private _lConectou	:= .F.
	Private _lEnviado	:= .F.
	Private _cMailError	:= ""


	If _cFrom == NIL .or. empty(_cFrom)
		_cFrom := _cConta
	EndIf

	If  _cEnv == "TOTVS_SUNTECH"
		_cEmail   := Alltrim(SA1->A1_EMAIL)
		_cCc      := Alltrim(GetMV("CP_BOLMAIL"))
		_cSubject := "CASHBACK - " + Alltrim(SA1->A1_NOME)
	Else
		_cEmail   := 'suporte@hb.com.br'
		_cCc      := 'aricardo.araujo@gmail.com'
		_cSubject := "DESENVOLVIMENTO - CASHBACK - " + Alltrim(SA1->A1_NOME)
	EndIf

	// Conecta ao servidor de email
	CONNECT SMTP SERVER _cSerMail ACCOUNT _cConta PASSWORD _cSenha Result _lConectou

	If !(_lConectou) // Se nao conectou informa o erro
		GET MAIL ERROR _cMailError
		Alert(Space(12) + "Não foi possí­vel conectar ao Servidor de email. Procure o Administrador da rede."+chr(13)+chr(10)+"Erro retornado: "+_cMailError)
	Else

		If GetNewPar("MV_RELAUTH",.F.)
			_lRetAuth := MailAuth(_cConta,_cSenha)
		Else
			_lRetAuth := .T.
		EndIf


		If _lRetAuth
			SEND MAIL FROM _cFrom TO _cTo CC _cCc BCC _cBCC SUBJECT	_cSubject Body _cBody ATTACHMENT _cAttach1,_cAttach2 FORMAT TEXT RESULT _lEnviado
		Else
			Alert(Space(12) + "Nao foi possivel autenticar o usuario e senha para envio de e-mail!")
			_lEnviado := .F.
		EndIf

		If !(_lEnviado)
			GET MAIL ERROR _cMailError
			Alert(Space(12) + "Não foi possível enviar o email. Procure o Administrador da rede."+chr(13)+chr(10)+"Erro retornado: "+_cMailError)
		Endif

		DISCONNECT SMTP SERVER
	Endif

Return(_lEnviado)
