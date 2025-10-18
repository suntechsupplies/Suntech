#Include "Totvs.CH"
#Include 'RWMake.ch'
#include 'FileIO.ch'
#Include 'RptDef.ch'
#Include "TOPCONN.CH"
#Include "Protheus.ch"
#Include "Tbiconn.ch"

//---------------------------------------------------------------------------------------------------------------------------------------------//
//---------------------------------------------------------------------------------------------------------------------------------------------//
//  Funcao : CPMAILTR()            Autor : Cyberpolos                        Data : 10/12/2020     								   //
//  Uso :  LINK DE RASTREIO DE OBJETOS DAS TRANSPORTADORAS			           //
//      																																	   //
// 																						                                                       //
//---------------------------------------------------------------------------------------------------------------------------------------------//
//---------------------------------------------------------------------------------------------------------------------------------------------// 

user Function CPMAILTR()

	Local _aEmp 		:= PARAMIXB[1]    
	Local _lEnviado		:= .T.
	LocaL cQuery		:= ''
	Private lSchedule   := .F. 

 // Inicializa ambiente pelo schedule
	If Select("SX6") == 0
		RPCSetType(3)  		//| Nao utilizar licenca	
		RpcSetEnv(_aEmp[1] ,_aEmp[2])
		lSchedule := .T.		
	Endif    
	//+-------------------------------------------------------
	// tratamento para nao haver execucao concorrente
	//+-------------------------------------------------------
	if !(LockByName('CPMAILTR', .T., .F.))
        ConOut("CPMAILTR ja esta em execucao")
        if lSchedule
            RpcClearEnv()
        Endif
        Return
	Endif    
   

	cQuery  += "SELECT "
	cQuery  += "F2_FILIAL AS FILIAL, "
	cQuery  += "F2_DOC AS DOC, "
	cQuery  += "F2_SERIE AS SERIE, "
	cQuery  += "F2_CLIENTE AS CLIENTE, "	
	cQuery  += "F2_LOJA AS LOJA, "
	cQuery  += "F2_EMISSAO AS EMISSAO, "
	cQuery  += "F2_EST AS ESTADO, "
	cQuery  += "F2_HORA AS HORA, "
	cQuery  += "F2_DAUTNFE AS DAUTNFE, "
	cQuery  += "F2_CHVNFE AS CHVNFE, "	
	cQuery  += "F2_TRANSP AS TRANSP, 
	cQuery  += "F2_XTRACKI AS XTRACKI, 
	cQuery  += "A1_CGC AS CGC, "	
	cQuery  += "A1_NOME AS NOME, "
	cQuery  += "A1_EST AS EST, "
	cQuery  += "A1_MUN AS MUN, "
	cQuery  += "A1_EMAIL AS EMAIL, "
	cQuery  += "A1_INSCR AS INSCR "	
	cQuery  += "FROM "+Retsqlname("SF2") + " AS SF2 (NOLOCK) "
	cQuery  += "INNER JOIN	"+Retsqlname("SA1") + " SA1 (NOLOCK) ON SA1.A1_COD = SF2.F2_CLIENTE AND SA1.A1_LOJA = SF2.F2_LOJA AND SA1.D_E_L_E_T_ = ' ' "	
	cQuery  += "WHERE SF2.D_E_L_E_T_ = ' ' "   
	cQuery  += "AND SF2.F2_FILIAL = '"+xFilial("SF2")+"' "   
	cQuery  += "AND SF2.F2_DAUTNFE <= '"+DToS(Date()-2)+"' "		// Grava a data em que foi autorizada a NF	
	cQuery  += "AND SF2.F2_DAUTNFE > '"+DToS(Date()-30)+"' "		// Grava a data em que foi autorizada a NF	
	cQuery  += "AND SF2.F2_HAUTNFE <> ' ' "		//grava a data em que foi autorizada a NF	
	cQuery  += "AND SF2.F2_CHVNFE <> ' ' "		
	cQuery  += "AND SF2.F2_XENVML = 'URL' "  // ALTERAR P 'OBJ' APOS ENVIADO NO RECLOCK
	
		
	//***************************
	//Chamando a DbUseArea()
	DbUseArea( .T. , 'TOPCONN' , TcGenQry( ,, cQuery) , "TRBSF2" , .T. , .T. )
	TRBSF2->(DBGOTOP())
	//***************************
   While TRBSF2->(!EOF()) 
	
		_lEnviado := XMAILTR()		
			
			If _lEnviado
				// relock
				DbSelectArea("SF2")	
				DbSetOrder(1)							
			//	DbSeek(TRBSF2->FILIAL+TRBSF2->DOC+TRBSF2->SERIE)
				DbSeek(xFilial("SF2")+TRBSF2->DOC+TRBSF2->SERIE)
				Reclock("SF2",.F.)		
				SF2->F2_XENVML := 'OBJ'		
				Msunlock("SF2")			

			EndIf


		TRBSF2->(DbSkip())  

    EndDo 		

	TRBSF2->(DbCloseArea())


RESET ENVIRONMENT

Return  	

// ********************************************************************************************************
///EMAIL - PARA LINK DE RASTREIO
//
static Function XMAILTR()
	Local lSchedule   	:= .F. 
	Local _oProcess  	:= Nil	
	Local _lEnviado		:= .T.
	Local _lDiscon		:= .T.
	Local _cPara		:= ''
	Local _cCc			:= ''
	Local _cCco			:= ''
	Local _cBody		:= ''
	Local _cTit         := ''
	LocaL cHtml 		:= ''	
	Local _oHtml	   	:= Nil

	_oProcess	:= TWFProcess():New('','EMAIL HB OBJETO')


//	If lSchedule
	//	_oProcess:NewTask('Inicio','/workflow/blu/CPMAVIS.htm')    
		
//	Else
//		_oProcess:NewTask('Inicio','E:\htm\CPMAVIS.htm')
//	EndIf

//	_oHtml   := _oProcess:oHtml  

		//cabeçalho
	cHtml += '<html xmlns=http://www.w3.org/1999/xhtml><head><meta charset=UTF-8><title>HB Objeto Correios </title> </head>'    
    cHtml += '<style type=text/css> body{font-family:Trebuchet MS,sans-serif;}'        
	cHtml += '.table-a{border-spacing:0;border-collapse:collapse;border-top:solid 2px #000000;border-bottom:solid 2px #cccccc;padding-bottom:5px;}'
    cHtml += '.table-b {font-family: Lucida Sans Unicode, Lucida Grande, Sans-Serif;font-size: 21px;margin: 0 auto;width: 100%;border-collapse: collapse;text-align: left; } ' 
    cHtml += '.table-b th {font-size: 14px;font-weight: bold;color: #333;padding: 2px 5px;border:solid #7e7e7e 1.0pt;border-bottom: 2px solid #1c1c1c;}'  
    cHtml += '.table-b td {padding: 0px 5px;color: #333;border:none;}' 
    cHtml += '.table-b tbody td {font-size:11.0pt;font-family:Trebuchet MS,sans-serif;color:#333333;}'
    cHtml += '.table-c {font-size:9.0pt;font-family:Trebuchet MS,sans-serif;color:#333333;background:#fff;padding:2.25pt 2.25pt 2.25pt 2.25pt;}'
    cHtml += '.table-c td { border:solid #7e7e7e 1.0pt;border-left: none; border-right: none;padding: 0px 5px; }'      
    cHtml += ".footer-texto {font-family: 'Open Sans Condensed', Arial, sans-serif;font-size: 13px; color: #fff;  }"   
    cHtml += '</style> <body style="background: #ffffff; width: 90%;  margin: 0 auto;"> '
    cHtml += '<table width=100% class="table-a" style=" text-align: left;"><tbody><tr>'
    cHtml += '<td style="padding-top:20px;padding-bottom:20px;background:#ffffff;"><table style="border-spacing:0;border-collapse:collapse;width:100%;margin:0 auto">'
    cHtml += '<tbody><tr><td width=100% style="text-align:center;"><a style="text-decoration:none;font-size:50px;color:#fffefe;padding: 0px;"href="https://www.hb.com.br/" target=_blank><img src="https://i.imgur.com/KiXeiRk.jpeg" width="600" height="250" alt="Logo"></a>'
    cHtml += '</td></tr></tbody></table></td></tr></tbody></table><table width="100%" summary=Registros>'    
    cHtml += '<tr><td scope=row colspan="2" ><font face=arial><b><strong style="color:#2196F3;border:none;"> INFORMA&Ccedil;&Otilde;ES </strong></b>  </font></td>'
	cHtml += '<td scope=row colspan="2" style="text-align:right;" ><font face=arial><b>Data do e-mail:</b> '+DToC(Date())+'</font></td></tr></table>'  
	
		//conteudo
	cHtml += '<table width="100%" summary=Registros><tr> '
	cHtml += '<td  align="left" style="padding-top:20px;"><p><span style="font-size:12.0pt;color:#333333;">Prezado cliente,</br></br>'
	cHtml += 'Informamos os detalhes do nosso mais recente faturamento.'
	cHtml += '</span><br><br></p></td></tr></table>'
	cHtml += '<table width="100%"  summary=Registros>'
	cHtml += '<tr> <td colspan="4" style="border-bottom: 2px solid #1c1c1c;font-family:Times New Roman,sans-serif;font-size:13.5pt;"><b>DETALHES </b></td><tr>'
	cHtml += '</table>'
	cHtml += '<table class="table-b" style="margin-bottom: 10px;" summary=Registros>'
	cHtml += '<tbody><tr>'
	cHtml += '<td width="40%" colspan="2"><b>CLIENTE: </b>'+TRBSF2->CLIENTE+'</td>'
	cHtml += '<td width="60%" colspan="2"><b>NOME : </b>'+TRBSF2->NOME+'</td>'
	cHtml += '</tr><tr>'
	cHtml += '<td width="40%" colspan="2"><b>CNPJ: </b>'+TRBSF2->CGC+'</td>'
	cHtml += '<td width="60%" colspan="2"><b>IE: </b>'+TRBSF2->INSCR+'</td>'
	cHtml += '</tr><tr>'
	cHtml += '<td width="40%" colspan="2"><b>CIDADE: </b>'+TRBSF2->MUN+'</td>'
	cHtml += '<td width="60%" colspan="2"><b>ESTADO: </b>'+TRBSF2->EST+'</td>'
	cHtml +='</tr></tbody>'
	cHtml += '</table>'
	cHtml += '<table border=0 cellspacing=0 cellpadding=0 width=100%>'
	cHtml += '<tbody class="table-c"><tr>'    	
    cHtml += '<td width="40%" colspan="2"><b>NOTA FISCAL: </b>'+TRBSF2->DOC+'</td> ' 
    cHtml += '<td width="60%" colspan="2"><b>CHAVE: </b>'+TRBSF2->CHVNFE+'</td>'                      	
    cHtml += '</tr><tr>'

	
		DO CASE
		//TRANSPORTADORA BRASSPRESS
		CASE AllTrim(TRBSF2->TRANSP) == "T00028"
		cHtml += '<tr> <td  width="100%" colspan="4"  align="left" style="padding-top:20px;border:none;"><p><span style="font-size:12.0pt;color:#333333;">
		cHtml += 'Informamos tamb&eacute;m que esse faturamento segue atrav&eacute;s da transportadora:'
		cHtml += '</span></p></td></tr>
		cHtml += '<tr> <td  width="100%" colspan="4" align="left" style="padding-top:0px;border:none;"><p><span style="font-size:12.0pt;color:#333333;">'
      	cHtml += '<a style="text-decoration:none;font-size:50px;color:#fffefe;padding: 0px;"href="https://www.braspress.com" target=_blank><img src="https://i.imgur.com/0Sr17fG.png" width="262" height="62" alt="Logo"></a>'
      	cHtml += '</span></p></td></tr><tr><td width="50%" colspan="2" align="left" style="padding-top:20px;border-top:none;"><p><span style="font-size:12.0pt;color:#333333;">'
       	cHtml += '&nbsp;&nbsp;&nbsp;<b>Central (11) 3429-3333</b></span><br><br></p></td>'
		//TRANSPORTADORA MOVVI LOGISTICA LTDA
		CASE AllTrim(TRBSF2->TRANSP) == "T00009"
		cHtml += '<tr> <td  width="100%" colspan="4"  align="left" style="padding-top:20px;border:none;"><p><span style="font-size:12.0pt;color:#333333;">
		cHtml += 'Informamos tamb&eacute;m que esse faturamento segue atrav&eacute;s da transportadora:'
		cHtml += '</span></p></td></tr>
		cHtml += '<tr> <td  width="100%" colspan="4" align="left" style="padding-top:20px;border:none;"><p><span style="font-size:12.0pt;color:#333333;"> &nbsp;&nbsp;&nbsp;'
		cHtml += '<a style="text-decoration:none;font-size:50px;color:#fffefe;padding: 0px;"href="https://www.movvi.com.br" target=_blank><img src="https://i.imgur.com/wKSiqrT.png" width="202" height="103" alt="Logo"></a>'
		cHtml += '</span></p></td></tr><tr><td  width="50%" colspan="2" align="left" style="padding-top:20px;border-top:none;"><p><span style="font-size:12.0pt;color:#333333;">'
		cHtml += ' &nbsp;&nbsp;&nbsp;<b>Administra&ccedil;&atilde;o Central (19) 3578-3600</b></span><br><br></p></td>'
		//TRANSPORTADORA TNT BRASIL (FEDEX) - Ricardo Araujo (Suntech)
		CASE AllTrim(TRBSF2->TRANSP) == "T00002"
		cHtml += '<tr> <td  width="100%" colspan="4"  align="left" style="padding-top:20px;border:none;"><p><span style="font-size:12.0pt;color:#333333;">
		cHtml += 'Informamos tamb&eacute;m que esse faturamento segue atrav&eacute;s da transportadora:'
		cHtml += '</span></p></td></tr>
		cHtml += '<tr> <td  width="100%" colspan="4" align="left" style="padding-top:20px;border:none;background-color:#4D148C" ><p><span style="font-size:12.0pt;color:#333333;"> &nbsp;&nbsp;&nbsp;'
		cHtml += '<a style="text-decoration:none;font-size:50px;color:#fffefe;padding: 0px;"href="https://www.fedex.com/pt-br/home.html" target=_blank><img src="https://www.fedex.com/content/dam/fedex-com/logos/logo.png" width="176" height="50" alt="Logo"></a>'
		cHtml += '</span></p></td></tr><tr><td  width="50%" colspan="2" align="left" style="padding-top:20px;border-top:none;"><p><span style="font-size:12.0pt;color:#333333;">'
		cHtml += ' &nbsp;&nbsp;&nbsp;<b>Nas capitais e regiões metropolitanas (tarifas de chamadas locais): 3003-0199 Em outras localidades: 0800 979 6979</b></span><br><br></p></td>'
		// Fim - Ricardo Araujo (Suntech)
		//TRANSPORTADORA JAMEF - Ricardo Araujo (Suntech)
		CASE AllTrim(TRBSF2->TRANSP) == "T00031"
		cHtml += '<tr> <td  width="100%" colspan="4"  align="left" style="padding-top:20px;border:none;"><p><span style="font-size:12.0pt;color:#333333;">
		cHtml += 'Informamos tamb&eacute;m que esse faturamento segue atrav&eacute;s da transportadora:'
		cHtml += '</span></p></td></tr>
		cHtml += '<tr> <td  width="100%" colspan="4" align="left" style="padding-top:20px;border:none;background-color:#fffefe" ><p><span style="font-size:12.0pt;color:#333333;"> &nbsp;&nbsp;&nbsp;'
		cHtml += '<a style="text-decoration:none;font-size:40px;color:#fffefe;padding: 0px;"href="https://www.jamef.com.br" target=_blank><img src="https://b2b.hb.com.br/assets/images/nova-logo-jamef.e5bdb98e.png" width="232" height="73" alt="Logo"></a>'
		cHtml += '</span></p></td></tr><tr><td  width="50%" colspan="2" align="left" style="padding-top:20px;border-top:none;"><p><span style="font-size:12.0pt;color:#333333;">'
		cHtml += ' &nbsp;&nbsp;&nbsp;<b>Nas capitais e regiões metropolitanas (tarifas de chamadas locais): 3003-0199 Em outras localidades: 0800 979 6979</b></span><br><br></p></td>'
		// Fim - Ricardo Araujo (Suntech)
		//TRANSPORTADORA JADLOG - Ricardo Araujo (Suntech)
		CASE AllTrim(TRBSF2->TRANSP) == "T00034"
		cHtml += '<tr> <td  width="100%" colspan="4"  align="left" style="padding-top:20px;border:none;"><p><span style="font-size:12.0pt;color:#333333;">
		cHtml += 'Informamos tamb&eacute;m que esse faturamento segue atrav&eacute;s da transportadora:'
		cHtml += '</span></p></td></tr>
		cHtml += '<tr> <td  width="100%" colspan="4" align="left" style="padding-top:20px;border:none;background-color:#fffefe" ><p><span style="font-size:12.0pt;color:#333333;"> &nbsp;&nbsp;&nbsp;'
		cHtml += '<a style="text-decoration:none;font-size:40px;color:#fffefe;padding: 0px;"href="https://www.jadlog.com.br/jadlog/home" target=_blank><img src="https://b2b.hb.com.br/assets/images/jadlog_logo.png" width="232" height="73" alt="Logo"></a>'
		cHtml += '</span></p></td></tr><tr><td  width="50%" colspan="2" align="left" style="padding-top:20px;border-top:none;"><p><span style="font-size:12.0pt;color:#333333;">'
		cHtml += ' &nbsp;&nbsp;&nbsp;<b>Nas capitais e regiões metropolitanas (tarifas de chamadas locais): 3003-0199 Em outras localidades: 0800 979 6979</b></span><br><br></p></td>'
		// Fim - Ricardo Araujo (Suntech)
		OTHERWISE		
		ENDCASE

	cHtml += '<td width="50%" colspan="2" align="left" style="padding-top:20px;border-top:none;"><p><span style="font-size:12.0pt;color:#3702f7;font-weight: bold;">Link de Rastreamento:&nbsp;&nbsp;&nbsp;'
	//cHtml += '<a href="https://www.braspress.com.br/site/w/tracking/search?cnpj='+SM0->M0_CGC+'&documentType=NOTAFISCAL&numero='+TRBSF2->DOC+' "><b> Clique Aqui</b></a>'
	cHtml += '<a href="'+TRBSF2->XTRACKI+'"><b> Clique Aqui</b></a>'
	cHtml += '</span><br><br></p></td>'
	cHtml += '</tr></tbody></table>'
	cHtml += '<table border="0" cellspacing="0" cellpadding="0" width="100%" style="margin: 0 auto;">'
	cHtml += '<tbody><tr><td>'
	cHtml += '<p style="font-size:12pt;margin-top: 25px;margin-bottom: 10px;">'
	cHtml += '<br><br>Muito Obrigado,<br><br>Suntech Supplies</p></td></tr></tbody></table>'


		//rodape
	cHtml += '<table width="100%" class="table-a" style="background-color: #1c1c1c; color: #fff;padding-top:15px;padding-bottom:15px;"> '         
    cHtml += '<tr style="font-size:10.0pt;"> <td align="center"><table>'           
    cHtml += '<td  class="footer"><table  width="180" ><tr><td > <span class="footer-texto">'
    cHtml += '<p>&nbsp;&nbsp;&nbsp;<b> Garantia e Assist&ecirc;ncia - </b></p></span><span class="footer-texto"> <p> &nbsp;&nbsp;&nbsp; De segunda &agrave; sexta <br>'                                             
    cHtml += '&nbsp;&nbsp;&nbsp; das 8h-12h | 13h-16h</p></span></td></tr></table></td><td> <table width="100"></table></td><td class="footer"><table width="180" >' 
    cHtml += '<tr><td><span class="footer-texto"><p><b>Andamento de pedidos - </b></p></span><span class="footer-texto"><p>De segunda &agrave; sexta<br>'                                       
    cHtml += 'das 09h00 &agrave;s 18h</p></span></td></tr></table></td></table></td></tr></table></body></html>'


	//_oHtml:Valbyname('DATAHJ'  			,DToC(Date()))	
	//_oHtml:Valbyname('MSGOBJ'    	,cHtml )


	_cBody 	:= cHtml // _oHtml:HtmlCode()
	_cTit 	:= "HB - RASTREAMENTO DE OBJETO"
	_cPara 	:= TRBSF2->EMAIL
	_cCc 	:= GetMv('CP_EMLTRAK')  // PARAMETRO PARA QUEM RECEBE EMAILS DO TRAKING COPIA
	_cCco 	:= GetMv('CP_EMLTROK')  // PARAMETRO PARA QUEM RECEBE EMAILS DO TRAKING COPIA OCULTA

	// funcao de conexao e envio + parametros
	xEnvia(_cTit,_cBody,_cPara,_cCc,_cCco)



Return _lEnviado

// static para fazer o trabalho de envio do email

static Function xEnvia(_cTit,_cBody,_cPara,_cCc,_cCco)
	Local _cServer		:= ALLTRIM(GetMv("MV_RELSERV"))	//Nome do servidor de envio de e-mail
	Local _cAccount		:= ALLTRIM(GetMv("MV_RELACNT"))	//Conta a ser utilizada no envio de e-mail
	Local _cPassword	:= ALLTRIM(GetMv("MV_RELPSW"))	//Senha da conta de e-mail para envio
	Local _lAuth		:= GetMv("MV_RELAUTH")			//Determina se o Servidor de Email necessita de Autenticacao
	Local _lOk			:= .T.
	Local _lEnviado		:= .T.
	Local _lDiscon		:= .T.
	Local _cDe			:= _cAccount
	Local _cErro		:= ''
	Local _cEnv 		:= AllTrim(Upper(GetEnvServer()))
	Local cAmbProd  	:= AllTrim(Upper(GetMv('CP_AMBIENT')))  //Nome do ambiente de produção
	Local _cMsgRet      := ''
	Local _cAssunto  	:= ''

//**************************************************** 		

	CONNECT SMTP SERVER _cServer ACCOUNT _cAccount PASSWORD _cPassword RESULT _lOk

	//+----------------------------------
	//|	Autentica, se necessï¿½rio
	//+----------------------------------
	If _lAuth
		If !MailAuth(_cAccount,_cPassword)
			_cMsgRet += CRLF + '   [HBMAIL] Erro ao conectar na conta de e-mail.'
			DISCONNECT SMTP SERVER
			Return .F.
		EndIf
	EndIf

	//+----------------------------------
	//| Se ok, envia email
	//+----------------------------------

	If  _cEnv $(cAmbProd)
		_cPara		:= _cPara
		_cCc		:= _cCc
		_cCco		:= _cCco
		_cAssunto	+= _cTit

	else

		_cPara		:= GetMv('CP_EMTESTE')   // PARAMETRO COM EMAILS QUE RECEBEM OS TESTES EXECUTADOS
		_cCc		:= ''
		_cCco		:= ''
		_cAssunto	+= "HOMOLOGACAO - "+ _cTit

	Endif

	_lEnviado := MailSend ( _cDe, {_cPara}, {_cCc}, {_cCco}, _cAssunto, _cBody, {''}, .T. )

	If _lEnviado

		_cMsgRet += CRLF + '   [HBMAIL] E-mail enviado com sucesso '

	Else
		GET MAIL ERROR _cErro
		_cMsgRet += CRLF + '   [HBMAIL] Erro ao enviar email: ' + _cErro

	Endif

	DISCONNECT SMTP SERVER Result _lDiscon
	

Return _lEnviado


