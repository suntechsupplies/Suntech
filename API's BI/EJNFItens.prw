#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"

/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Douglas.Silva Feat Carlos Eduardo Saturnino                                         *  
* Processa as informações e retorna o json                                                    *
* @since 	05/08/2019                                                                        *
* @version undefined                                                                          *
* @param oSelf, object, Objeto contendo dados da requisição efetuada pelo cliente, tais como: *
*    - Parâmetros querystring (parâmetros informado via URL)                                  *
*    - Objeto JSON caso o requisição seja efetuada via Request Post                           *
*    - Header da requisição                                                                   *
*    - entre outras ...                                                                       *
* @type Method                                                                                *
**********************************************************************************************/

#Define _Function	"RNFITENS"
#Define _DescFun	"RNFITENS"
#Define Desc_Rest 	"Serviço REST para Disponibilizar / Inserir dados de TRNFITENS" 
#Define Desc_Get  	"Retorna o cadastro de RNFITENS informado de acordo com os parametros passados" 
#Define Desc_Post	"Cria o cadastro de RNFITENS informado de acordo com data de atualização do cadastro"


user function R_NF_IT()

return

WSRESTFUL rNFitens DESCRIPTION Desc_Rest

	WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING    
	
	WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/RNFITENS || /RNFITENS/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE nPag HEADERPARAM TENANTID WSSERVICE RNFITENS
	Local aArea		:= GetArea()
	Local cAliasTMP	:= GetNextAlias()
	LOCAL nPag		:= Self:nPag
	Local nGetDate	:= SuperGetMV("MV_AFVDIAS",,90)	
	Local cSetResp	:= ''
	Local aDebug	:= {}
	Local nX
	Local nPagFim

	// define o tipo de retorno do método
	::SetContentType("application/json")
	//**********************************************************************************
	// Efetua a preparação do ambiente 
	//**********************************************************************************
	/*
    If FindFunction("WfPrepEnv") //.And. cNumemp <> _cEmpresa + _cFilial 
		WfPrepEnv(_cEmpresa,_cFilial)
		cEmpant := _cEmpresa
		cFilant := _cFilial
		cNumEmp	:= _cEmpresa + _cFilial 
		Sleep(5000)
	Endif
    */

	If !Empty(SELF:TENANTID)
		_cEmpresa := Left(Upper(SELF:TENANTID), At(",",Upper(SELF:TENANTID))-1)
		_cFilial := Substr(Upper(SELF:TENANTID), At(",",Upper(SELF:TENANTID))+1)
	EndIf

	cEmpAnt := _cEmpresa
	cFilAnt := _cFilial

    // < Fim > -------------------------------------------------------------------------

	//Verifica se há conexão em aberto, caso haja feche.
	IF Select(cAliasTmp)>0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf

	//Select de cadastro	
	BeginSql Alias cAliasTmp 

		SELECT     ( (DENSE_RANK() OVER (ORDER BY F2.F2_DOC))/50) + 1         		PAG , 
		           	D2_FILIAL                                                       FILIAL, 
		           	D2_DOC                                                          NTFISCAL, 
		           	D2_SERIE														NTFSERIE,
		           	D2_PEDIDO                                                       NUMPED, 
		           	D2_COD                                                          CODPRO, 
		           	D2_QUANT                                                        QTDE, 
		           	D2_DESC                                                         DESCO, 
		           	D2_PRCVEN                                                       VALOR, 
		           	B1_DESC                                                         DESCPRO, 
		           	D2_ITEM                                                         ITEM, 
		           	D2_DESCON                                                       VLDESC, 
		           	'0'                                                             VLCOM, 
		           	D2_VALICM + D2_VALIMP5 + D2_VALIMP6 + D2_VALIPI + D2_ICMSRET    VLIMP, 
		           	D2_QUANT  * B1_PESO                                             TOTPESO 
		FROM      	%TABLE:SD2% D2 
		INNER JOIN 	%TABLE:SF2% F2 
		ON         	D2_FILIAL = F2_FILIAL 
		AND        	D2_DOC = F2_DOC 
		AND        	D2_CLIENTE = F2_CLIENTE 
		AND        	D2_LOJA = F2_LOJA 
		INNER JOIN 	%TABLE:SB1% B1 
		ON         	D2_COD = B1_COD 
		AND        	B1.%NotDel% 
		WHERE      	D2.%NotDel% 
		AND        	D2_EMISSAO >= GETDATE()- %Exp:nGetDate% 
		AND        	F2_TIPO = 'N'
		AND			B1_TIPO IN ('PA','ME') 
		UNION 
		        	(	SELECT 	((DENSE_RANK() OVER (ORDER BY D1.D1_DOC))/50) + 1          			PAG ,
		                           	D1_FILIAL                                                       FILIAL,
		                            D1_DOC                                                          NTFISCAL,
		                            D1_SERIE														NTFSERIE,
		                            D2_PEDIDO                                                       NUMPED,
		                            D1_COD                                                          CODPRO,
		                            D1_QUANT                                                        QTDE,
		                            D1_DESC                                                         DESCO,
		                            D1_VUNIT                                                        VALOR,
		                            B1_DESC                                                         DESCPRO,
		                            D1_ITEM                                                         ITEM,
		                            D1_DESC                                                         VLDESC,
		                            '0'                                                             VLCOM,
		                            D1_VALICM + D1_VALIMP5 + D1_VALIMP6 + D1_VALIPI + D1_ICMSRET    VLIMP,
		                            D1_QUANT  * B1_PESO                                             TOTALPESO
		                   FROM    	%TABLE:SD1% D1, 
		                           	%TABLE:SD2% D2, 
		                           	%TABLE:SF2% F2, 
		                           	%TABLE:SB1% B1 
		                   WHERE   	D1_FILIAL = D2_FILIAL 
		                   AND     	D1_NFORI = D2_DOC 
		                   AND     	D1_SERIORI = D2_SERIE 
		                   AND     	D2_CLIENTE = D1_FORNECE 
		                   AND     	D2_LOJA = D1_LOJA 
		                   AND     	D1_COD = D2_COD 
		                   AND     	D2.%NotDel% 
		                   AND     	D2_FILIAL = F2_FILIAL 
		                   AND     	D2_DOC = F2_DOC 
		                   AND     	D2_CLIENTE = F2_CLIENTE 
		                   AND     	D2_LOJA = F2_LOJA 
		                   AND     	D2_COD = B1_COD 
		                   AND     	B1.%NotDel% 
		                   AND     	D1.%NotDel% 
		                   AND     	D1_TIPO = 'D'
		                   AND		B1_TIPO IN ('PA','ME') 
		                   AND    	D1_EMISSAO >= GETDATE()- %Exp:nGetDate%		) 
		ORDER BY PAG

		                  
	EndSql
	
	aDebug := GetLastQuery()
	
	dbSelectArea(cAliasTmp)
	(cAliasTmp)->( DbGoTop() )

	While (cAliasTmp)->( !Eof() )
		nPagFim := (cAliasTmp)->PAG
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->( DbGoTop() )

	If (cAliasTmp)->( Eof() )

		cSetResp := '{ "TE_NOTAFISCALITEM":"Nao Existe Dados Nessa Pagina"} '

	Else

		(cAliasTMP)->( DbGoTop() )  
		nX		:= 1
		cSetResp:= '{ "TE_NOTAFISCALITEM":[ ' 
		
		While (cAliasTMP)->( !Eof() )
				
			If (cAliasTmp)->PAG == nPag	
				
				If nX > 1
					cSetResp  +=' , '
				EndIf

				cSetResp  += '{'
				cSetResp  += '"NTFISCAL":"'	+ TRIM((cAliasTMP)->FILIAL + (cAliasTMP)->NTFISCAL + (cAliasTMP)->NTFSERIE)					
				cSetResp  += '","NUMPED":"'	+ TRIM((cAliasTMP)->FILIAL)	+ TRIM((cAliasTMP)->NUMPED)										
				cSetResp  += '","CODPRO":"'	+ TRIM((cAliasTMP)->CODPRO)										
				cSetResp  += '","QTDE":'	+ TRIM(cValToChar((cAliasTMP)->QTDE))										
				cSetResp  += ',"DESCO":'	+ TRIM(cValToChar((cAliasTMP)->DESCO))								
				cSetResp  += ',"VALOR":'	+ TRIM(cValToChar((cAliasTMP)->VALOR))											
				cSetResp  += ',"DESCPRO":"'	+ StrTran(StrTran(TRIM((cAliasTMP)->DESCPRO ),'"', ''),"'", '')
				cSetResp  += '","ITEM":"'	+ TRIM((cAliasTMP)->ITEM)											
				cSetResp  += '","VLDESC":'	+ TRIM(cValToChar((cAliasTMP)->VLDESC))											
				cSetResp  += ',"VLCOM":'	+ TRIM(((cAliasTMP)->VLCOM))											
				cSetResp  += ',"VLIMP":'	+ TRIM(cValToChar((cAliasTMP)->VLIMP))											
				cSetResp  += '}'
				(cAliasTmp)->(dbSkip())
				nX++
			Else
				(cAliasTmp)->(dbSkip())
				LOOP	
			Endif
		EndDo

		cSetResp  += ']'	
		cSetResp  += ',"PaginalAtual":'				+ cValToChar(Self:nPag)			
		cSetResp  += ',"TotalDePaginas":'			+ cValToChar(nPagFim)
		cSetResp  += '}'

	EndIf
	//Fecha a tabela
	(cAliasTMP)->(DbCloseArea())

	//Envia o JSON Gerado para a aplicação
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)
