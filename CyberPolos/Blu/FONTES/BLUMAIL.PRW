#Include "Totvs.CH"
#Include 'RWMake.ch'
#include 'FileIO.ch'
#Include 'RptDef.ch'
#Include "TOPCONN.CH"
#Include "Protheus.ch"
#Include "Tbiconn.ch"

#DEFINE PATH "\workflow\htm\blu\TEMP\"
//---------------------------------------------------------------------------------------------------------------------------------------------//
//---------------------------------------------------------------------------------------------------------------------------------------------//
//  Funcao : Blumail()            Autor : Cyberpolos                        Data : 27/08/2020     								   //
//  Uso :  aviso automatico por email			           //
//      																																	   //
// 																						                                                       //
//---------------------------------------------------------------------------------------------------------------------------------------------//
//---------------------------------------------------------------------------------------------------------------------------------------------// 

User Function Blumail(_aEmp)	

	Local cQuery        := ''
	Local _lEnviado     := ''
	
	Private _oProcess  	:= Nil
	Private lSchedule   := .F. 
	
//PREPARE ENVIRONMENT  EMPRESA '01'  FILIAL '04'

 // Inicializa ambiente pelo schedule
	If Select("SX6") == 0
		RPCSetType(3)  		//| Nao utilizar licenca	
		RpcSetEnv(_aEmp[1] ,_aEmp[2])
		lSchedule := .T.		
	Endif    
	//+-------------------------------------------------------
	// tratamento para nao haver execucao concorrente
	//+-------------------------------------------------------
	if !(LockByName('Blumail', .T., .F.))
        ConOut("Blumail ja esta em execucao")
        if lSchedule
            RpcClearEnv()
        Endif
        Return
	Endif    

	_oProcess	:= TWFProcess():New('','ENVIAR EMAIL BLU - HB')

	cQuery  += "SELECT "
	cQuery  += "ZBL_FILIAL AS FILIAL, "
	cQuery  += "ZBL_NUMBLU AS NUMBLU, "
	cQuery  += "ZBL_ORIGEM AS ORIGEM, "
	cQuery  += "ZBL_CODCLI AS CODCLI, "
	cQuery  += "ZBL_NOME AS NOME, "
	cQuery  += "ZBL_LOJA AS LOJA, "
	cQuery  += "ZBL_STATUS AS STATUS, "
	cQuery  += "ZBL_DATA AS DATA, "
	cQuery  += "ZBL_TPMAIL AS TPMAIL, "
	cQuery  += "ZBL_DOC AS DOC, "
	cQuery  += "ZBL_SERIE AS SERIE, "
	cQuery  += "ZBL_PEDIDO AS PEDIDO, "
	cQuery  += "R_E_C_N_O_ AS RECNO "
	cQuery  += "FROM ZBL010 AS ZBL "
	//cQuery  += "WHERE  ZBL_FILIAL = '"+ xFilial("ZBL") +"' "
	cQuery  += "WHERE ZBL.D_E_L_E_T_ = ' ' "
	cQuery  += "AND ZBL_TPMAIL <> ' ' "
	cQuery  += "AND ZBL_MAILST = 'N' "  // ALTERAR P 'S' APOS ENVIADO NO RECLOCK
	cQuery  += "ORDER BY ZBL_NUMBLU "
	
	/*
	TIPO EMAIL  0 =  EMAIL INTERNO  (ERRO DE INTEGRACAO)
	TIPO EMAIL  1 = ENVIAR (CLIENTES)
	TIPO EMAIL 2  = EMAIL INTERNO (COBRAÃƒâ€¡A AUTORIZADA)  SC5 = AUTORIZADA O FATURAMENTO, SE1 = So AVISAR Q FOI AUTORIZADA
	TIPO EMAIL 3  = EMAIL INTERNO ( AVISANDO DA DEVOLUCAO)
	TIPO EMAIL 4  = EMAIL INTERNO ( AVISANDO DO CANCELAMENTO)
	TIPO EMAIL 5  = EMAIL INTERNO ( AVISANDO SOBRE REJEICAO = O CLIENTE NEGOU)
	*/
	//***************************
	//Chamando a DbUseArea()
	DbUseArea( .T. , 'TOPCONN' , TcGenQry( ,, cQuery) , "TRBZBL" , .T. , .T. )
	TRBZBL->(DBGOTOP())
	//***************************
   While TRBZBL->(!EOF()) 
		
		//***************************************************************************** TITULOS
		IF TRBZBL->ORIGEM = 'SE1' .AND. TRBZBL->TPMAIL = '1'						//CONDICAO EMAIL TITULOS
		//***************************************************************************************		
		_lEnviado := EmailTit(TRBZBL->NUMBLU,TRBZBL->FILIAL)		
			
			If _lEnviado
				// relock
				DbSelectArea("ZBL")								
				DbSeek(TRBZBL->FILIAL+TRBZBL->NUMBLU)
				Reclock("ZBL",.F.)		
					ZBL->ZBL_MAILST = 'S'		
				Msunlock("ZBL")			

			EndIf

		ENDIF
		//**************************************************************************************************PEDIDO			
		IF 	TRBZBL->ORIGEM = 'SC5' .AND. TRBZBL->TPMAIL = '1'						// CONDICAO EMAIL PEDIDO
		//**************************************************************************************************	
		_lEnviado := EmailPed(TRBZBL->NUMBLU,TRBZBL->FILIAL)		
			
			If _lEnviado
				// relock
				DbSelectArea("ZBL")								
				DbSeek(TRBZBL->FILIAL+TRBZBL->NUMBLU)
				Reclock("ZBL",.F.)		
					ZBL->ZBL_MAILST = 'S'		
				Msunlock("ZBL")			

			EndIf

		ENDIF
	
		//******************************************************************AVISOS INTERNOS
		IF TRBZBL->TPMAIL = '0' .OR. TRBZBL->TPMAIL = '2' .OR. TRBZBL->TPMAIL = '3' .OR. TRBZBL->TPMAIL = '4' .OR. TRBZBL->TPMAIL = '5' .OR. TRBZBL->TPMAIL = '6'
		//********************************************************************
		_lEnviado := Emailint()		
			
			If _lEnviado
				// relock
				DbSelectArea("ZBL")								
				DbSeek(TRBZBL->FILIAL+TRBZBL->NUMBLU)
				Reclock("ZBL",.F.)		
					ZBL->ZBL_MAILST = 'S'		
				Msunlock("ZBL")		
			EndIf

		ENDIF

		TRBZBL->(DbSkip())  

    EndDo 		

	TRBZBL->(DbCloseArea())

	If lSchedule
        RpcClearEnv()
    Endif

Return

// ********************************************************************************************************
						///EMAIL - INTERNO
//*********************************************************************************************************

Static Function EmailInt()

	Local _lEnviado := .T.
	Local cHtml     := ""
	Local _cCc      := ""
	Local _cCco     := ""

DbSelectArea("TRBZBL")

//******************************** Inicio 
/*
TIPO TPEMAIL 2  = EMAIL INTERNO (COBRANCA AUTORIZADA)  SC5 = AUTORIZADA O FATURAMENTO, SE1 = So AVISAR Q FOI AUTORIZADA
TIPO TPEMAIL 3  = EMAIL INTERNO ( AVISANDO DA DEVOLUCAO)
TIPO TPEMAIL 4  = EMAIL INTERNO ( AVISANDO DO CANCELAMENTO)
TIPO TPEMAIL 5  = EMAIL INTERNO ( AVISANDO SOBRE REJEIÃ‡ÃƒO = O CLIENTE NEGOU)
 */

   // Montagem do HTML.
   cHtml += '<html xmlns="http://www.w3.org/1999/xhtml">' 
   cHtml += '<head>' 
   cHtml += '<meta charset="iso-8859-1">'       
   cHtml += '<title>Registros nao localizados</title>' 
   cHtml += "</head>" 
   
   cHtml += ' <style type="text/css">' 
    		
   cHtml += '.table-a{'
   cHtml += 'border-spacing:0;border-collapse:collapse;border-top:solid 2px #000000;border-bottom:solid 2px #cccccc;padding-bottom:5px;}'
   
   cHtml += '  #table-b { '
   cHtml += "font-family: 'Lucida Sans Unicode', 'Lucida Grande', Sans-Serif;" 
   cHtml += "font-size: 13px;" 
   cHtml += "background: #fff;" 
   cHtml += "margin: 10px;" 
   cHtml += "width: 95%; " 
   cHtml += "border-collapse: collapse; " 
   cHtml += "text-align: left; } "    
   
   cHtml += "#table-b th { " 
   cHtml += "font-size: 14px; " 
   cHtml += "font-weight: normal; " 
   cHtml += "color: #333; " 
   cHtml += "padding: 10px 8px; " 
   cHtml += "border-bottom: 2px solid #1b1a1a; } "   
   
   cHtml += "#table-b td { "   
   cHtml += "color: #333; "   
   cHtml += "padding: 6px 8px; } " 
   
   cHtml += "#table-b tbody tr:hover td { " 
   cHtml += " background-color: #ffffff; "
   cHtml += "} "
   cHtml += ".footer-texto {font-family: 'Open Sans Condensed', Arial, sans-serif;font-size: 13px; color: #fff;  }"
   cHtml += '</style> <body style="background: #ffffff; width:90%; margin: 0 auto;">'   
   cHtml += "<center>"
   cHtml += '<table width=100% class="table-a" style=" text-align: left;">'
   cHtml += '<tbody>'
   cHtml += '<tr>'
   cHtml += '<td style="padding-top:20px;padding-bottom:20px;background:#ffffff;">'
   cHtml += '<table style="border-spacing:0;border-collapse:collapse;width:100%;margin:0 auto">'
   cHtml += '<tbody>'
   cHtml += '<tr>'
   cHtml += '<td width=100% style="text-align:center;"><a style="padding: 0px;"href="https://www.hb.com.br/" target=_blank><img src="https://i.imgur.com/KiXeiRk.jpeg" width="600" height="250" alt="Logo"></a>'
   cHtml += '</td>'
   cHtml += '</tr>'
   cHtml += '</tbody>'
   cHtml += '</table>'
   cHtml += '</td>'
   cHtml += '</tr>'
   cHtml += '</tbody>'
   cHtml += '</table>'       
  
/* Tratamento 
TIPO TPEMAIL 2  = EMAIL INTERNO (COBRANCA AUTORIZADA)  SC5 = AUTORIZADA O FATURAMENTO, SE1 = So AVISAR Q FOI AUTORIZADA
TIPO TPEMAIL 3  = EMAIL INTERNO ( AVISANDO DA DEVOLUCAO)
TIPO TPEMAIL 4  = EMAIL INTERNO ( AVISANDO DO CANCELAMENTO)
TIPO TPEMAIL 5  = EMAIL INTERNO ( AVISANDO SOBRE REJEICAO = O CLIENTE NEGOU)
 */
    IF TRBZBL->TPMAIL = '0' 
   		cHtml += "<table width='95%' id='table-b' summary='Registros'>"    
    	cHtml += "<tr><td scope=row colspan='2' ><font face=arial><b><strong style='color:#005898;border:none;'> ERRO DURANTE O PROCESSO DE INTEGRACAO</strong></b>  </font></td>"
		cHtml += "<td scope=row colspan='2' style='text-align:right;' ><font face=arial><b>Data do e-mail:</b> "+ DToC(Date()) +" </font></td>"
		cHtml += "</tr>"		
		cHtml += "</table><br><br>" 

		cHtml += "<table width='95%' id='table-b' summary='Registros'>" 
		cHtml += "<tr>" 
		cHtml += "<th width='95%'align='left'style='font-size:13pt;font-family:Trebuchet MS;padding-top:20px;'><p>Prezados(as),<br><br>" 
		cHtml += "Informamos que ocorreram problemas durante o processo de Integracao do Codigo blu ' <span style='color:#005898;'>"+AllTrim(TRBZBL->NUMBLU)+" '</span>.<br><br>"
		cHtml += 'Segue abaixo as informacoes para seu melhor controle do mesmo:'
		cHtml += "<br><br></p></th>" 
		cHtml += "</tr>" 
		
		cHtml += "<tr><td>Codigo BLU: "+TRBZBL->NUMBLU+"</td></tr>"
		cHtml += "<tr><td>Cliente: "+TRBZBL->CODCLI+" - "+TRBZBL->NOME+"</td></tr> "
		cHtml += "<br>"
		_cTit := 'BLU - ERRO DE INTEGRACAO'		
   
    ElseIf TRBZBL->TPMAIL = '2' .AND. AllTrim(TRBZBL->ORIGEM) = 'SE1'	
  		cHtml += "<table width='95%' id='table-b' summary='Registros'>"    
    	cHtml += "<tr><td scope=row colspan='2' ><font face=arial><b><strong style='color:#005898;border:none;'> TITULO - AUTORIZADO </strong></b>  </font></td>"
		cHtml += "<td scope=row colspan='2' style='text-align:right;' ><font face=arial><b>Data do e-mail:</b> "+ DToC(Date()) +" </font></td>"
		cHtml += "</tr>"		
		cHtml += "</table><br><br>"   
		
		cHtml += "<table width='95%' id='table-b' summary='Registros'>" 
		cHtml += "<tr>" 
		cHtml += "<th width='95%'align='left'style='font-size:13pt;font-family:Trebuchet MS;padding-top:20px;'><p>Prezados(as),<br><br>" 
		cHtml += "Informamos que foi autorizada a Cobranca do titulo para o Codigo blu ' <span style='color:#005898;'>"+AllTrim(TRBZBL->NUMBLU)+" '</span>.<br><br>"
		cHtml += 'Segue abaixo as informacoes para seu melhor controle do mesmo:'
		cHtml += "<br><br></p></th>" 
		cHtml += "</tr>" 
		
		cHtml += "<tr><td>Codigo BLU: "+TRBZBL->NUMBLU+"</td></tr>"
		cHtml += "<tr><td>Cliente: "+TRBZBL->CODCLI+" - "+TRBZBL->NOME+"</td></tr>"
		cHtml += "<br>"
		_cTit := 'BLU - TITULO AUTORIZADO'		
   
    elseIf TRBZBL->TPMAIL = '2' .AND. AllTrim(TRBZBL->ORIGEM) = 'SC5'	   
		cHtml += "<table width='95%' id='table-b' summary='Registros'>"    
    	cHtml += "<tr><td scope=row colspan='2' ><font face=arial><b><strong style='color:#005898;border:none;'> PEDIDO - COBRANCA AUTORIZADA </strong></b>  </font></td>"
		cHtml += "<td scope=row colspan='2' style='text-align:right;' ><font face=arial><b>Data do e-mail:</b> "+ DToC(Date()) +" </font></td>"
		cHtml += "</tr>"		
		cHtml += "</table><br><br>" 
				
		cHtml += "<table width='95%' id='table-b' summary='Registros'>" 
		cHtml += "<tr>" 
		cHtml += "<th width='95%'align='left'style='font-size:13pt;font-family:Trebuchet MS;padding-top:20px;'><p>Prezados(as),<br><br>" 
		cHtml += "Informamos que foi autorizada o faturamento para o Codigo blu ' <span style='color:#005898;'>"+AllTrim(TRBZBL->NUMBLU)+" '</span>.<br><br>"
		cHtml += 'Segue abaixo as informacoes para seu melhor controle do mesmo:'
		cHtml += "<br><br></p></th>" 
		cHtml += "</tr>" 
		
		cHtml += "<tr><td>Codigo BLU: "+TRBZBL->NUMBLU+"</td></tr>"
		cHtml += "<tr><td>Cliente: "+TRBZBL->CODCLI+" - "+TRBZBL->NOME+"</td></tr> "
		cHtml += "<tr><td>Pedido: "+TRBZBL->PEDIDO +" </td></tr>"
		cHtml += "<br>"
		_cTit := 'BLU - PEDIDO DE COBRANCA AUTORIZADO'		
   
    ElseIF TRBZBL->TPMAIL = '3' 
 		cHtml += "<table width='95%' id='table-b' summary='Registros'>"    
    	cHtml += "<tr><td scope=row colspan='2' ><font face=arial><b><strong style='color:#005898;border:none;'> AVISO DE DEVOLUCAO </strong></b>  </font></td>"
		cHtml += "<td scope=row colspan='2' style='text-align:right;' ><font face=arial><b>Data do e-mail:</b> "+ DToC(Date()) +" </font></td>"
		cHtml += "</tr>"		
		cHtml += "</table><br><br>" 

		cHtml += "<table width='95%' id='table-b' summary='Registros'>" 
		cHtml += "<tr>" 
		cHtml += "<th width='95%'align='left'style='font-size:13pt;font-family:Trebuchet MS;padding-top:20px;'><p>Prezados(as),<br><br>" 
		cHtml += "Informamos que foi autorizada a Cobranca do titulo para o Codigo blu ' <span style='color:#005898;'>"+AllTrim(TRBZBL->NUMBLU)+" '</span>.<br><br>"
		cHtml += 'Segue abaixo as informacoes para seu melhor controle do mesmo:'
		cHtml += "<br><br></p></th>" 
		cHtml += "</tr>" 
		
		cHtml += "<tr><td>Codigo BLU: "+TRBZBL->NUMBLU+"</td></tr>"
		cHtml += "<tr><td>Cliente: "+TRBZBL->CODCLI+" - "+TRBZBL->NOME+"</td></tr> "
		cHtml += "<br>"	
		_cTit := 'BLU - AVISO DE DEVOLUCAO'	
   
    ElseIF TRBZBL->TPMAIL = '4' 	  
		cHtml += "<table width='95%' id='table-b' summary='Registros'>"    
    	cHtml += "<tr><td scope=row colspan='2' ><font face=arial><b><strong style='color:#005898;border:none;'> AVISO DE CANCELAMENTO </strong></b>  </font></td>"
		cHtml += "<td scope=row colspan='2' style='text-align:right;' ><font face=arial><b>Data do e-mail:</b> "+ DToC(Date()) +" </font></td>"
		cHtml += "</tr>"		
		cHtml += "</table><br><br>" 

		cHtml += "<table width='95%' id='table-b' summary='Registros'>" 
		cHtml += "<tr>" 
		cHtml += "<th width='95%'align='left'style='font-size:13pt;font-family:Trebuchet MS;padding-top:20px;'><p>Prezados(as),<br><br>" 
		cHtml += "Informamos que foi cancelada o Faturamento\Cobranca para o Codigo blu ' <span style='color:#005898;'>"+AllTrim(TRBZBL->NUMBLU)+" '</span>.<br><br>"
		cHtml += 'Segue abaixo as informacoes para seu melhor controle do mesmo:'
		cHtml += "<br><br></p></th>" 
		cHtml += "</tr>" 
		
		cHtml += "<tr><td>Codigo BLU: "+TRBZBL->NUMBLU+"</td></tr>"
		cHtml += "<tr><td>Cliente: "+TRBZBL->CODCLI+" - "+TRBZBL->NOME+"</td></tr> "
		cHtml += "<br>"
		_cTit := 'BLU - AVISO DE CANCELAMENTO'			
   
    ElseIF TRBZBL->TPMAIL = '5' .AND. AllTrim(TRBZBL->ORIGEM) = 'SC5'	   
		cHtml += "<table width='95%' id='table-b' summary='Registros'>"    
    	cHtml += "<tr><td scope=row colspan='2' ><font face=arial><b><strong style='color:#005898;border:none;'> AVISO DE REJEICAO </strong></b>  </font></td>"
		cHtml += "<td scope=row colspan='2' style='text-align:right;' ><font face=arial><b>Data do e-mail:</b> "+ DToC(Date()) +" </font></td>"
		cHtml += "</tr>"		
		cHtml += "</table><br><br>" 		

		cHtml += "<table width='95%' id='table-b' summary='Registros'>" 
		cHtml += "<tr>" 
		cHtml += "<th width='95%'align='left'style='font-size:13pt;font-family:Trebuchet MS;padding-top:20px;'><p>Prezados(as),<br><br>" 
		cHtml += "Informamos que o cliente nao autorizou a Cobranca do Pedido para o Codigo blu ' <span style='color:#005898;'>"+AllTrim(TRBZBL->NUMBLU)+" '</span>.<br><br>"
		cHtml += 'Segue abaixo as informacoes para seu melhor controle do mesmo:'
		cHtml += "<br><br></p></th>" 
		cHtml += "</tr>" 
		
		cHtml += "<tr><td>Codigo BLU: "+TRBZBL->NUMBLU+"</td></tr>"
		cHtml += "<tr><td>Cliente: "+TRBZBL->CODCLI+" - "+TRBZBL->NOME+"</td></tr> "
		cHtml += "<tr><td>Pedido: "+TRBZBL->PEDIDO +" </td></tr>"	
		cHtml += "<br>"
		_cTit := 'BLU - AVISO DE REJEICAO'	

	ElseIF TRBZBL->TPMAIL = '5' .AND. AllTrim(TRBZBL->ORIGEM) = 'SE1'	  
		cHtml += "<table width='95%' id='table-b' summary='Registros'>"    
    	cHtml += "<tr><td scope=row colspan='2' ><font face=arial><b><strong style='color:#005898;border:none;'> AVISO DE REJEICAO </strong></b>  </font></td>"
		cHtml += "<td scope=row colspan='2' style='text-align:right;' ><font face=arial><b>Data do e-mail:</b> "+ DToC(Date()) +" </font></td>"
		cHtml += "</tr>"		
		cHtml += "</table><br><br>" 
		
		cHtml += "<table width='95%' id='table-b' summary='Registros'>" 
		cHtml += "<tr>" 
		cHtml += "<th width='95%'align='left'style='font-size:13pt;font-family:Trebuchet MS;padding-top:20px;'><p>Prezados(as),<br><br>" 
		cHtml += "Informamos que o cliente nao autorizou a Cobranca do titulo para o Codigo blu ' <span style='color:#005898;'>"+AllTrim(TRBZBL->NUMBLU)+" '</span>.<br><br>"
		cHtml += 'Segue abaixo as informacoes para seu melhor controle do mesmo:'
		cHtml += "<br><br></p></th>" 
		cHtml += "</tr>" 
		
		cHtml += "<tr><td>Codigo BLU: "+TRBZBL->NUMBLU+"</td></tr>"
		cHtml += "<tr><td>Cliente: "+TRBZBL->CODCLI+" - "+TRBZBL->NOME+"</td></tr> "
		cHtml += "<br>"	
				
		_cTit := 'BLU - AVISO DE REJEICAO'	

	ElseIF TRBZBL->TPMAIL = '6' 

		DbSelectArea("ZBL")								
		DbSeek(TRBZBL->FILIAL+TRBZBL->NUMBLU)
	 
 		cHtml += "<table width='95%' id='table-b' summary='Registros'>"    
    	cHtml += "<tr><td scope=row colspan='2' ><font face=arial><b><strong style='color:#005898;border:none;'> AVISO ERRO DE DEVOLUCAO </strong></b>  </font></td>"
		cHtml += "<td scope=row colspan='2' style='text-align:right;' ><font face=arial><b>Data do e-mail:</b> "+ DToC(Date()) +" </font></td>"
		cHtml += "</tr>"		
		cHtml += "</table><br><br>" 

		cHtml += "<table width='95%' id='table-b' summary='Registros'>" 
		cHtml += "<tr>" 
		cHtml += "<th width='95%'align='left'style='font-size:13pt;font-family:Trebuchet MS;padding-top:20px;'><p>Prezados(as),<br><br>" 
		cHtml += "Informamos que houve erro ao tentar enviar a devolução para o Codigo blu ' <span style='color:#005898;'>"+AllTrim(TRBZBL->NUMBLU)+" '</span>.<br><br>"
		cHtml += 'Segue abaixo as informacoes para seu melhor controle do mesmo:'
		cHtml += "<br><br></p></th>" 
		cHtml += "</tr>" 
		
		cHtml += "<tr><td>Codigo BLU: "+TRBZBL->NUMBLU+"</td></tr>"
		cHtml += "<tr><td>Cliente: "+TRBZBL->CODCLI+" - "+TRBZBL->NOME+"</td></tr> "
		cHtml += "<tr><td>Erro: "+Alltrim(ZBL->ZBL_MSGBLU)+"</td></tr> "
		cHtml += "<br>"	
		_cTit := 'BLU - ERRO NA DEVOLUCAO'	
   ENDIF
   //**********fim  
      
   cHtml += '</table>'
   cHtml += '<table width=100% class="table-a" style="background-color: #1b1a1a; font-size:10.0pt;color: #fff; padding-top:15px;padding-bottom:15px; float: left;">'          
   cHtml += '<tr style="font-size:10.0pt;"><td align="center"><table>'
   cHtml += '<td  class="footer"><table  width="180" ><tr><td>'
   cHtml += '<span class="footer-texto"><p>&nbsp;&nbsp;&nbsp;<b> Garantia e Assist&ecirc;ncia - </b></p></span>'                                 
   cHtml += '<span class="footer-texto"><p> &nbsp;&nbsp;&nbsp; De segunda &agrave; sexta <br>' 
   cHtml += '&nbsp;&nbsp;&nbsp; 11 4591-8600<br>&nbsp;&nbsp;&nbsp; das 8h-12h | 13h-16h</p>'
   cHtml += '</span></td></tr></table></td>' 
   cHtml += '<td><table width="100"></table></td>'                                
   cHtml += '<td class="footer"><table width="180" ><tr><td>'
   cHtml += '<span class="footer-texto"><p><b>Andamento de pedidos - </b></p></span>'                                 
   cHtml += '<span class="footer-texto"><p>De segunda &agrave; sexta<br>WhatsApp 11 94082-2942 <br>das 09h00 &agrave;s 18h</p>'
   cHtml += '</span></td></tr></table></td>'
   cHtml += '</table></td></tr>'				
   cHtml +=	'</table></center>'	
   cHtml += '</body>'
   cHtml += '</html>'
         
   _cPara  := AllTrim(GetMv("CP_BLUEINT"))	 // parametro com os email internos
			 
	//envia o email	 
   xEnvia(_cTit,cHtml,_cPara,_cCc,_cCco)
  
   // se for cancelamento interno mandar um isolado somente para o representante
   If  TRBZBL->TPMAIL = '4' .AND. alltrim(TRBZBL->ORIGEM) = 'SC5'
		_nTot   := 0							
		_cAlias := GetNextAlias()   
		
		BeginSql Alias _cAlias
			SELECT SC5.C5_VEND1 AS VENDEDOR, SA3.A3_EMAIL AS EMAIL
			FROM %Table:SC5% SC5 (NOLOCK)
			INNER JOIN %Table:SA3% SA3 (NOLOCK) ON SA3.%NotDel% AND SC5.C5_VEND1 = SA3.A3_COD 							
			WHERE SC5.C5_FILIAL = %Exp:TRBZBL->FILIAL%
			AND SC5.C5_XNUMBLU = %Exp:TRBZBL->NUMBLU%							      	           
			AND SC5.%NotDel% 
		EndSql 

		Count to _nTot
		
		if _nTot > 0
			(_cAlias)->(DbGoTop())
			_cPara:= (_cAlias)->EMAIL   // email do vendedor
			_cCco:= AllTrim(GetMv("CP_BLUEINT"))	 // parametro com os email internos	com copia oculta	
			xEnvia(_cTit,cHtml,_cPara,_cCc,_cCco)			
		else
			(_cAlias)->(DbCloseArea())
		EndIF	
   EndIf
   
Return _lEnviado

// ********************************************************************************************************
						///EMAIL -TITULOS BLU 
//*********************************************************************************************************
static Function EmailTit(_cXNUMBLU,_cFil) 	
	Local _lEnviado		:= .T. 	 
	Local _cPara		:= ''  
	Local _cCc			:= '' 
	Local _cCco			:= ''  
	Local _cBody		:= '' 	 	
	Local _cTit         := ''  
    Local _cRet 	    := ''  	
	Local _nNfT         := 0  
	Local _nQtdT        := 0  
	Local _lColor	    := .F.  
	Local _oHtml	   	:= Nil  	
	Local _cAlias	   	:= ''		
	Local _nTot         := 0
							
	_cAlias := GetNextAlias()   
 	
	BeginSql Alias _cAlias
		SELECT SE1.E1_FILIAL, SE1.E1_PREFIXO AS PREFIXO, SE1.E1_NUM AS NUMERO, SE1.E1_PARCELA AS PARCELA, SE1.E1_TIPO AS TIPO , SE1.E1_NATUREZ AS NATUREZA, SE1.E1_CLIENTE, SE1.E1_NOMCLI, SE1.E1_EMISSAO AS EMISSAO, 
		SE1.E1_VENCREA AS VREAL, SE1.E1_VALOR AS VALOR, SE1.E1_SALDO AS SALDO, SE1.E1_VEND1 AS VENDEDOR, SE1.E1_PEDIDO AS PEDIDO, SE1.E1_XNUMBLU AS NUMBLU,
		SA1.A1_COD AS CODCLI, SA1.A1_NOME AS CLIENTE, SA1.A1_NREDUZ AS NREDUZ, SA1.A1_CGC AS CNPJ, SA1.A1_INSCR AS INSCR, SA1.A1_MUN AS MUN ,SA1.A1_EST AS UF , SA1.A1_EMAIL AS EMAIL 
		FROM %Table:SE1% SE1 (NOLOCK)				
		INNER JOIN %Table:SA1% SA1 (NOLOCK) ON SA1.%NotDel%  AND SA1.A1_COD = SE1.E1_CLIENTE AND  SA1.A1_LOJA = SE1.E1_LOJA
		WHERE SE1.E1_FILIAL = %Exp:_cFil%	
			AND SE1.E1_XNUMBLU  = %Exp:_cXNUMBLU%						      	           
			AND SE1.%NotDel% 
	EndSql 

	Count to _nTot
	
	if _nTot > 0
		(_cAlias)->(DbGoTop())	
				
		If lSchedule
			_oProcess:NewTask('Inicio','/workflow/blu/blumail-se1.htm')	 
		Else
			_oProcess:NewTask('Inicio','C:\htm\BLUMAIL-SE1.htm')	 
		EndIf

		_oHtml   := _oProcess:oHtml
				
		_oHtml:Valbyname('CLIENTE'    		,(_cAlias)->CODCLI)
		_oHtml:Valbyname('FANTASIA'    		,(_cAlias)->NREDUZ)
		_oHtml:Valbyname('CNPJ'    			,(_cAlias)->CNPJ)
		_oHtml:Valbyname('IE'    			,(_cAlias)->INSCR)
		_oHtml:Valbyname('CIDADE'    		,(_cAlias)->MUN)
		_oHtml:Valbyname('UF'    			,(_cAlias)->UF)
		_oHtml:Valbyname('DATAHJ'  			,DToC(Date()))
		_oHtml:Valbyname('CP_BLUECNT'  		,AllTrim(GetMv("CP_BLUECNT"))) // email de contato no layout
	
//		_cEmail := AllTrim((_cAlias)->EMAIL)
										
		While (_cAlias)->(!EOF()) 
		
			_cRet += '<tr>'
			
			_cRet += '<td  style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
			_cRet += AllTrim((_cAlias)->PREFIXO)
			_cRet += '</td>'
			
			_cRet += '<td  style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
			_cRet += AllTrim((_cAlias)->NUMERO)
			_cRet += '</td>'

			_cRet += '<td  style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
			_cRet += AllTrim((_cAlias)->PARCELA)
			_cRet += '</td>'
			
			_cRet += '<td  style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
			_cRet += Dtoc(Stod((_cAlias)->EMISSAO))
			_cRet += '</td>'							
																
			_cRet += '<td  style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
			_cRet += Dtoc(Stod((_cAlias)->VREAL))
			_cRet += '</td>'									

			_cRet += '<td align="right" style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
			_cRet += "R$ "+ Transform((_cAlias)->VALOR, '@E 999,999.99' )
			_cRet += '</td>'
			
			_cRet += '<td align="right" style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
			_cRet += "R$ "+ Transform((_cAlias)->SALDO, '@E 999,999.99' )
			_cRet += '</td>'
											
			_cRet += '</tr>' + CRLF

			_lColor := !_lColor
			_nQtdT++	 
			_nNfT  += (_cAlias)->SALDO
													
			(_cAlias)->(DbSkip())	
									
		EndDo
		
		_oHtml:Valbyname('LISTAITENS'    	,_cRet )
		_oHtml:Valbyname('TOTITENS'    		,CValToChar(_nQtdT))
		_oHtml:Valbyname('TOTNF'    		,Transform(_nNfT, '@E 999,999.99' ))					
		
		_cBody 	:= _oHtml:HtmlCode()	
		_cTit	:= 'E-MAIL TITULOS BLU - HB'  		
		_cPara 	:= ''
		_cCc 	:= GetMv('CP_BLUETIT') // PARAMETRO PARA QUEM RECEBE OS EMAILS DO TITULO COMO COPIA
		_cCco 	:= '' 

		// funcao de conexao e envio + parametros
		xEnvia(_cTit,_cBody,_cPara,_cCc,_cCco)				

	  	(_cAlias)->(DbCloseArea())

	Else
		If !lSchedule
		
			MsgInfo("Nao encontrado registros deste produto para esse cliente.","Atencao")
						
		Else
		
			ConOut("Nao encontrado registros deste produto para esse cliente.")		  
						
		EndIf
		
		(_cAlias)->(DbCloseArea())		
				
	EndIf

Return _lEnviado


// ********************************************************************************************************
						///EMAIL - PEDIDOS BLU 
//*********************************************************************************************************
static Function EmailPed(_cXNUMBLU,_cFil) 	
	Local _lEnviado		:= .T.  
	Local _lDiscon		:= .T. 	
	Local _cPara		:= ''  
	Local _cCc			:= '' 
	Local _cCco			:= ''  
	Local _cBody		:= ''     	
	Local _cTit         := ''  
    Local _cRet 	    := ''  	
	Local _nNfT         := 0  
	Local _nQtdT        := 0  
	Local _lColor	    := .F.  
	Local _oHtml	   	:= Nil  		
	Local _cAlias	   	:= '' 		
	Local _nTot			:= 0
	Local lSemBlq := GetMv("CP_BLUCEST")  // .T. = + itens bloqueados / .F. = sem itens bloqueados

	_cAlias := GetNextAlias()   
 	
	 If lSemBlq
 			BeginSql Alias _cAlias			 
				SELECT SC5.C5_XNUMBLU AS XNUMBLU, SC5.C5_NUM,SC5.C5_FILIAL,SC5.C5_TIPO AS TIPO, SC5.C5_TIPOCLI AS TIPOCLI, SC5.C5_DESCONT AS DESCONT, SC5.C5_DESC1 AS DESC1,					
					   SC6.C6_CLI , SC6.C6_LOJA, SC6.C6_NUM AS NUM, SC6.C6_LOJA AS LOJA, SC6.C6_TES AS TES, SC6.C6_VALDESC AS VALDESC, 
					   SC6.C6_PRODUTO AS PRODUTO, SC6.C6_QTDVEN AS QUANT, SC6.C6_PRCVEN AS PRCVEN, SC6.C6_PRUNIT AS PRUNIT, SC6.C6_NFORI AS NFORI, SC6.C6_SERIORI AS SERIORI,
					   SC6.C6_VALOR AS VALOR, SC6.C6_PEDCLI AS PEDCLI, SC6.C6_ENTREG AS ENTREGA, SC6.C6_DATFAT,
					   SA1.A1_COD AS CODCLI, SA1.A1_NOME AS CLIENTE, SA1.A1_NREDUZ AS NREDUZ, SA1.A1_CGC AS CNPJ, 
					   SA1.A1_INSCR AS INSCR, SA1.A1_MUN AS MUN ,SA1.A1_EST AS UF , SA1.A1_EMAIL AS EMAIL
				FROM %Table:SC5% SC5 (NOLOCK)
					INNER JOIN %Table:SC6% SC6 (NOLOCK) ON SC6.%NotDel% AND SC6.C6_NUM = SC5.C5_NUM AND SC6.C6_FILIAL = SC5.C5_FILIAL  				
					INNER JOIN %Table:SA1% SA1 (NOLOCK) ON SA1.%NotDel%  AND SA1.A1_COD = SC6.C6_CLI AND  SA1.A1_LOJA = SC6.C6_LOJA
					INNER JOIN %Table:SC9% SC9 (NOLOCK) ON SC9.C9_FILIAL = SC6.C6_FILIAL AND SC9.C9_PEDIDO = SC6.C6_NUM AND SC9.C9_ITEM = SC6.C6_ITEM 
					AND SC9.C9_CLIENTE = SC6.C6_CLI AND SC9.C9_LOJA = SC6.C6_LOJA AND SC9.D_E_L_E_T_ = ' ' AND SC9.C9_BLEST <> '02' 
				WHERE SC5.C5_FILIAL = %Exp:_cFil%
				AND SC5.C5_XNUMBLU = %Exp:_cXNUMBLU%							      	           
				AND SC5.%NotDel% 
			EndSql 
	Else
			BeginSql Alias _cAlias			 
				SELECT SC5.C5_XNUMBLU AS XNUMBLU, SC5.C5_NUM,SC5.C5_FILIAL,SC5.C5_TIPO AS TIPO, SC5.C5_TIPOCLI AS TIPOCLI, SC5.C5_DESCONT AS DESCONT, SC5.C5_DESC1 AS DESC1,					
					   SC6.C6_CLI , SC6.C6_LOJA, SC6.C6_NUM AS NUM, SC6.C6_LOJA AS LOJA, SC6.C6_TES AS TES, SC6.C6_VALDESC AS VALDESC, 
					   SC6.C6_PRODUTO AS PRODUTO, SC6.C6_QTDVEN AS QUANT, SC6.C6_PRCVEN AS PRCVEN, SC6.C6_PRUNIT AS PRUNIT, SC6.C6_NFORI AS NFORI, SC6.C6_SERIORI AS SERIORI,
					   SC6.C6_VALOR AS VALOR, SC6.C6_PEDCLI AS PEDCLI, SC6.C6_ENTREG AS ENTREGA, SC6.C6_DATFAT,
					   SA1.A1_COD AS CODCLI, SA1.A1_NOME AS CLIENTE, SA1.A1_NREDUZ AS NREDUZ, SA1.A1_CGC AS CNPJ, 
					   SA1.A1_INSCR AS INSCR, SA1.A1_MUN AS MUN ,SA1.A1_EST AS UF , SA1.A1_EMAIL AS EMAIL
				FROM %Table:SC5% SC5 (NOLOCK)
					INNER JOIN %Table:SC6% SC6 (NOLOCK) ON SC6.%NotDel% AND SC6.C6_NUM = SC5.C5_NUM AND SC6.C6_FILIAL = SC5.C5_FILIAL  				
					INNER JOIN %Table:SA1% SA1 (NOLOCK) ON SA1.%NotDel%  AND SA1.A1_COD = SC6.C6_CLI AND  SA1.A1_LOJA = SC6.C6_LOJA				
				WHERE SC5.C5_FILIAL = %Exp:_cFil%
				AND SC5.C5_XNUMBLU = %Exp:_cXNUMBLU%							      	           
				AND SC5.%NotDel% 
			EndSql 	
	EndIF				
			Count to _nTot	

	if _nTot > 0			
			
		(_cAlias)->(DbGoTop())	
			
		If lSchedule
			_oProcess:NewTask('Inicio','/workflow/blu/blumail-sc5.htm')	 
		Else
			_oProcess:NewTask('Inicio','C:\htm\BLUMAIL-SC5.htm')	 
		EndIf

		_oHtml   := _oProcess:oHtml
				
		_oHtml:Valbyname('CLIENTE'    		,(_cAlias)->CODCLI)
		_oHtml:Valbyname('FANTASIA'    		,(_cAlias)->NREDUZ)
		_oHtml:Valbyname('CNPJ'    			,(_cAlias)->CNPJ)
		_oHtml:Valbyname('IE'    			,(_cAlias)->INSCR)
		_oHtml:Valbyname('CIDADE'    		,(_cAlias)->MUN)
		_oHtml:Valbyname('UF'    			,(_cAlias)->UF)
		_oHtml:Valbyname('DATAHJ'  			,DToC(Date()))	
		_oHtml:Valbyname('CP_BLUECNT'  		,AllTrim(GetMv("CP_BLUECNT"))) // email de contato no layout

		_cPara 	:= Alltrim((_cAlias)->EMAIL)

		 aRelImp  := MaFisRelImp("MT100",{"SF2","SD2"})                            
            	
		//*******************************************************************************************************			
		//| Enquanto houver itens					
		While (_cAlias)->(!EOF()) 
				//| Tratativa para calcular o valor do pedido com impostos para enviar ao portal Blu.
			MaFisIni((_cAlias)->CODCLI,;		// 1-Codigo Cliente/Fornecedor
				(_cAlias)->LOJA,;			        // 2-Loja do Cliente/Fornecedor
				If( (_cAlias)->TIPO$'DB',"F","C"),;	// 3-C:Cliente , F:Fornecedor
				(_cAlias)->TIPO,;				    // 4-Tipo da NF
				(_cAlias)->TIPOCLI,;			        // 5-Tipo do Cliente/Fornecedor
				aRelImp,;							// 6-Relacao de Impostos que suportados no arquivo
				,;						   			// 7-Tipo de complemento
				,;									// 8-Permite Incluir Impostos no Rodape .T./.F.
				"SB1",;							    // 9-Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
				"MATA461")							// 10-Nome da rotina que esta utilizando a funcao

			If (_cAlias)->DESCONT > 0
				MaFisAlt("NF_DESCONTO", Min(MaFisRet(, "NF_VALMERC")-0.01, (_cAlias)->DESCONT+MaFisRet(, "NF_DESCONTO")) )
			EndIf
					
				//| Adiciona o item nos tratamentos de impostos
				SB1->(DbSeek(FWxFilial("SB1")+(_cAlias)->PRODUTO))
				MaFisAdd((_cAlias)->PRODUTO,;    // 01 - Codigo do Produto                    ( Obrigatorio )
				(_cAlias)->TES,;             // 02 - Codigo do TES                        ( Opcional )
				(_cAlias)->QUANT,;          // 03 - Quantidade                           ( Obrigatorio )
				(_cAlias)->PRCVEN,;          // 04 - Preco Unitario                       ( Obrigatorio )
				(_cAlias)->VALDESC,;         // 05 - Desconto
				(_cAlias)->NFORI,;           // 06 - Numero da NF Original                ( Devolucao/Benef )
				(_cAlias)->SERIORI,;         // 07 - Serie da NF Original                 ( Devolucao/Benef )
				0,;                       // 08 - RecNo da NF Original no arq SD1/SD2
				0,;                       // 09 - Valor do Frete do Item               ( Opcional )
				0,;                       // 10 - Valor da Despesa do item             ( Opcional )
				0,;                       // 11 - Valor do Seguro do item              ( Opcional )
				0,;                       // 12 - Valor do Frete Autonomo              ( Opcional )
				(_cAlias)->VALOR,;           // 13 - Valor da Mercadoria                  ( Obrigatorio )
				0,;                       // 14 - Valor da Embalagem                   ( Opcional )
				SB1->(RecNo()),;          // 15 - RecNo do SB1
				0)                        // 16 - RecNo do SF4				
						

				_cRet += '<tr>'
				
				_cRet += '<td  style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
				_cRet += AllTrim((_cAlias)->XNUMBLU)
				_cRet += '</td>'
				
				_cRet += '<td  style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
				_cRet += AllTrim((_cAlias)->NUM)
				_cRet += '</td>'
				
				_cRet += '<td  style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
				_cRet += AllTrim((_cAlias)->ENTREGA)
				_cRet += '</td>'									
																	
				_cRet += '<td  style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
				_cRet += AllTrim((_cAlias)->PRODUTO)
				_cRet += '</td>'
								
				_cRet += '<td  style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
				_cRet += AllTrim(POSICIONE("SB1",1,xFilial("SB1")+(_cAlias)->PRODUTO,"B1_DESC"))
				_cRet += '</td>'
	
				_cRet += '<td align="center" style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
				_cRet += CValToChar((_cAlias)->QUANT)
				_cRet += '</td>'

				_cRet += '<td align="right" style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
				_cRet += "R$ "+ Transform((_cAlias)->PRUNIT, '@E 999,999.99' )
				_cRet += '</td>'

				_cRet += '<td align="center" style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
				_cRet += CValToChar((_cAlias)->DESC1)+"%"
				_cRet += '</td>'

				_cRet += '<td align="right" style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
				_cRet += "R$ "+ Transform((_cAlias)->PRCVEN, '@E 999,999.99' )
				_cRet += '</td>'
				
				_cRet += '<td align="right" style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
				_cRet += "R$ "+ Transform(MaFisRet(,'NF_VALIPI') , '@E 999,999.99' )
				_cRet += '</td>'
				
				_cRet += '<td align="right" style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
				_cRet += "R$ "+ Transform(MaFisRet(,'NF_VALICM') , '@E 999,999.99' )
				_cRet += '</td>'

				_cRet += '<td align="right" style="border-top:solid #dddddd 1.0pt;border-left:solid #d5d5d5 1.0pt;border-bottom:none;border-right:solid #f2f2f2 1.0pt' + IIf(_lColor,';background:whitesmoke','') + '">'
				_cRet += "R$ "+ Transform(MaFisRet(,'NF_TOTAL') , '@E 999,999.99' )
				_cRet += '</td>'

				_cRet += '</tr>' + CRLF

				_lColor := !_lColor
				_nQtdT  += (_cAlias)->QUANT
				_nNfT  += MaFisRet(,'NF_TOTAL') 
														
				(_cAlias)->(DbSkip())	
						
				MaFisEnd()	
								
		EndDo
				
		_oHtml:Valbyname('LISTAITENS'    	,_cRet )
		_oHtml:Valbyname('TOTITENS'    		,CValToChar(_nQtdT))
		_oHtml:Valbyname('TOTNF'    		,Transform(_nNfT, '@E 999,999.99' ))

							
			_cBody 	:= _oHtml:HtmlCode()							
			_cTit	:= "E-MAIL BLU PEDIDOS - HB"
			//_cPara 	:= ''
			_cCc 	:= GetMv('CP_BLUEPED')  // PARAMETRO PARA QUEM RECEBE EMAILS DO PEDIDO COMO COPIA
			_cCco 	:= '' 

		// funcao de conexao e envio + parametros
			xEnvia(_cTit,_cBody,_cPara,_cCc,_cCco)	

	(_cAlias)->(DbCloseArea())
Else
				If !lSchedule
				
				MsgInfo("Nao encontrado registros deste produto para esse cliente.","Atencao")
				_lCont := .F.
				
				Else
				
				ConOut("Nao encontrado registros deste produto para esse cliente.")		  
				_lCont := .F.
				
				EndIf
				
				(_cAlias)->(DbCloseArea())		
						
			EndIf	

Return _lEnviado

// static para fazer o trabalho de envio do email
				
static Function xEnvia(_cTit,_cBody,_cPara,_cCc,_cCco)
	Local _cServer		:= ALLTRIM(GetMv('CP_BLUESER',,''))		//|	Nome do servidor de envio de e-mail 				 
	Local _cAccount		:= ALLTRIM(GetMv('CP_BLUECNT',,''))		//|	Conta a ser utilizada no envio de e-mail			
	Local _cPassword	:= ALLTRIM(GetMv('CP_BLUEPSW',,''))		//|	Senha da conta de e-mail para envio     			 
	Local _lAuth		:= GetMv('CP_BLUEAUT',,'')				//|	Determina se o Servidor de Email necessita de Autenticacao
	Local _lOk			:= .T. 
	Local _lEnviado		:= .T.  
	Local _lDiscon		:= .T. 
	Local _cDe			:= _cAccount  	 
	Local _cErro		:= ''  
	Local _cEnv 		:= AllTrim(Upper(GetEnvServer()))  
	Local cAmbProd  	:= AllTrim(Upper(GetMv('CP_BLUPROD')))  //Nome do ambiente de produção
	Local _cMsgRet      := '' 
	Local _cAssunto  	:= ''	  
	Local _cMailb	   	:= '' 		

//**************************************************** 		
	
		CONNECT SMTP SERVER _cServer ACCOUNT _cAccount PASSWORD _cPassword RESULT _lOk
	
		//+----------------------------------
		//|	Autentica, se necessï¿½rio
		//+----------------------------------
		If _lAuth
			If !MailAuth(_cAccount,_cPassword)
				_cMsgRet += CRLF + '   [BLUMAIL] Erro ao conectar na conta de e-mail.'
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
		
			_cPara		:= AllTrim(GetMv("CP_BLUEINT"))
		    _cCc		:= ''
			_cCco		:= ''
			_cAssunto	+= 'HOMOLOGACAO - '+ _cTit
					
		Endif
	
		_lEnviado := MailSend ( _cDe, {_cPara}, {_cCc}, {_cCco}, _cAssunto, _cBody, {''}, .T. )
	
		If _lEnviado
					
			_cMsgRet += CRLF + '   [BLUMAIL] E-mail enviado com sucesso ' 
			
		Else
			GET MAIL ERROR _cErro
			_cMsgRet += CRLF + '   [BLUMAIL] Erro ao enviar email: ' + _cErro
	
		Endif
	
		DISCONNECT SMTP SERVER Result _lDiscon
	

	//(_cAlias)->(DbCloseArea())

Return _lEnviado
