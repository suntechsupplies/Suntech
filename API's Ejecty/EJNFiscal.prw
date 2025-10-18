#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"
/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Douglas.Silva Feat Carlos Eduardo Saturnino And Antonio Ricardo de Araujo           *  
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

#Define _Function	"rNFiscal"
#Define _DescFun	"rNFiscal"
#Define Desc_Rest 	"Serviço REST para Disponibilizar / Inserir dados de rNFiscal" 
#Define Desc_Get  	"Retorna o cadastro de rNFiscal informado de acordo com os parametros passados" 
#Define Desc_Post	"Cria o cadastro de rNFiscal informado de acordo com data de atualização do cadastro"


User Function EJ_NFISCAL()

Return

WSRESTFUL EJNFiscal DESCRIPTION Desc_Rest

	WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING    

	WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/EJNFiscal || /EJNFiscal/{}"

END WSRESTFUL

WSMETHOD GET WSRECEIVE nPag HEADERPARAM TENANTID WSSERVICE EJNFiscal
	
	Local aArea		:= GetArea()
	Local cAliasTMP	:= GetNextAlias()
	Local nPag		:= Self:nPag
	//Local nGetDate	:= SuperGetMV("MV_AFVDIAS",,90,)
	Local aDebug	:= {}
	Local nPagFim	:= 0
	Local cSetResp	:= ''
	Local cEmpAnt   := ''
	Local cFilAnt   := ''
	Local nX

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

	//Select de cadastro - Paginacao com 1000 itens 
	BeginSql Alias cAliasTmp

		SELECT		(ROW_NUMBER() OVER (ORDER BY F2.F2_DOC)/100)+1	PAG , 
		           	F2_DOC                                         	NTFISCAL ,
		           	F2_SERIE										NTFSERIE,
		           	F2_FILIAL                                      	FILIAL ,
					F2_ESPECIE                                      ESPECIE, 
		           	F2_EMISSAO                                   	DTEMIS , 
		           	F2_CLIENTE                    			        CODCLI , 
					F2_LOJA 										LOJA,	
		           	F2_VALMERC                                  	VALNF , 
		           	D2_PEDIDO                                      	NUMPED , 
		           	D2_TIPO                                        	CTIPO , 
		           	NULL                                           	MTVDEV ,
					F2_TRANSP										TRANSP ,
		           	D2_CF                                          	CODNATOP , 
		           	F2_COND                                        	CODCNDPAG , 
		           	F2_VEND1                                      	CODVEND 
	    FROM     	%Table:SF2% F2 
	    INNER JOIN 	%Table:SD2% D2 
	    ON         	F2_FILIAL   = D2_FILIAL 
	    AND        	F2_DOC      = D2_DOC 
	    AND        	F2_SERIE    = D2_SERIE 
	    AND        	D2_CLIENTE  = F2_CLIENTE 
	    AND        	D2_LOJA     = F2_LOJA 
	    AND        	D2.%NotDel%
	    INNER JOIN 	%Table:SA3% A3 
	    ON         	F2_VEND1 = A3_COD 
	    AND        	A3.%NotDel%
	    WHERE      	F2.%NotDel%
	    AND			D2.%NotDel%
	    AND			A3.%NotDel%
	    //AND        	F2_EMISSAO >= GETDATE()- %Exp:nGetDate% 
	    AND        	F2_TIPO     = 'N'
		AND 		F2_ZSTATUS <> '9' 
	    GROUP BY   	F2_DOC, 
	    			F2_FILIAL,
					F2_ESPECIE, 
	    			F2_EMISSAO, 
	    			F2_CLIENTE,
					F2_LOJA, 
	    			D2_CF, 
	    			D2_PEDIDO, 
	    			D2_TIPO,
					F2_TRANSP,
	    			F2_COND, 
	    			F2_VEND1, 
	    			F2_VALMERC, 
	    			F2_SERIE
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

	// Efetua o Preenchimento do Json
	If (cAliasTmp)->( Eof() )

		cSetResp := cSetResp := '{ "TE_NOTAFISCAL":"Nao Existe Dados Nessa Pagina"} '

	Else
		
		(cAliasTmp)->( DbGoTop() )
		nX		:= 1
		cSetResp:= '{ "TE_NOTAFISCAL":[ ' 

		While (cAliasTMP)->( !Eof() )
			
			IF (cAliasTmp)->PAG == nPag
				
				If nX > 1
					cSetResp  +=' , '
				EndIf

				cSetResp  += '{'
				cSetResp  += '"FILIAL":"'		+ TRIM((cAliasTMP)->FILIAL)
				cSetResp  += '","NTFISCAL":"'	+ (cAliasTMP)->NTFISCAL
				cSetResp  += '","SERIE":"'		+ (cAliasTMP)->NTFSERIE
				cSetResp  += '","TIPONOTA":"'	+ TRIM((cAliasTMP)->CTIPO)
				cSetResp  += '","ESPECIE":"'	+ TRIM((cAliasTMP)->ESPECIE)					
				cSetResp  += '","DTEMIS":"'		+ TRIM((cAliasTMP)->DTEMIS)											
				cSetResp  += '","CODCLI":"'		+ ALLTRIM((cAliasTMP)->CODCLI)
				cSetResp  += '","LOJA":"'		+ ALLTRIM((cAliasTMP)->LOJA)											
				cSetResp  += '","VALNF":'		+ ALLTRIM(cValToChar((cAliasTMP)->VALNF))										
				cSetResp  += ',"NUMPED":"'		+ TRIM((cAliasTMP)->NUMPED)								
				cSetResp  += '","MTVDEV":"'		+ cValToChar((cAliasTMP)->MTVDEV)
				cSetResp  += '","TRANSP":"'		+ TRIM((cAliasTMP)->TRANSP)	/* == Atualização - Ricardo Araujo 21/10/2024 ==*/									
				cSetResp  += '","CODNATOP":"'	+ TRIM((cAliasTMP)->CODNATOP)												
				cSetResp  += '","CODCNDPAG":"'	+ TRIM((cAliasTMP)->CODCNDPAG)											
				cSetResp  += '","CODVEND":"'	+ TRIM(((cAliasTMP)->CODVEND))											
				cSetResp  += '"}'

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
