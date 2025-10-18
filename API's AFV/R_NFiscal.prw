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

#Define _Function	"rNFiscal"
#Define _DescFun	"rNFiscal"
#Define Desc_Rest 	"Serviço REST para Disponibilizar / Inserir dados de rNFiscal" 
#Define Desc_Get  	"Retorna o cadastro de rNFiscal informado de acordo com os parametros passados" 
#Define Desc_Post	"Cria o cadastro de rNFiscal informado de acordo com data de atualização do cadastro"


user function R_NFISCAL()

return

WSRESTFUL rNFiscal DESCRIPTION Desc_Rest

	WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING    

	WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/rNFiscal || /rNFiscal/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE cDataDe, cDataAte,  nPag HEADERPARAM TENANTID WSSERVICE rNFiscal
	Local aArea		:= GetArea()
	Local cAliasTMP	:= GetNextAlias()
	Local nPag		:= Self:nPag
	Local nGetDate	:= SuperGetMV("MV_AFVDIAS",,90,)
	Local aDebug	:= {}
	Local nPagFim	:= 0
	Local cSetResp	:= ''	
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

		SELECT			(ROW_NUMBER() OVER (ORDER BY F2.F2_DOC)/1000)+1	PAG , 
		           		F2_DOC                                         	NTFISCAL ,
		           		F2_SERIE										NTFSERIE,
		           		F2_FILIAL                                      	FILIAL , 
		           		F2_EMISSAO                                   	DTEMIS , 
		           		F2_CLIENTE+F2_LOJA                    			CODCLI , 
		           		F2_VALMERC                                  	VALNF , 
		           		D2_PEDIDO                                      	NUMPED , 
		           		D2_TIPO                                        	CTIPO , 
		           		NULL                                           	MTVDEV , 
		           		D2_CF                                          	CODNATOP , 
		           		F2_COND                                        	CODCNDPAG , 
		           		F2_VEND1                                      	CODVEND 
	    FROM     		%Table:SF2% F2 
	    INNER JOIN 		%Table:SD2% D2 
	    ON         		F2_FILIAL = D2_FILIAL 
	    AND        		F2_DOC = D2_DOC 
	    AND        		F2_SERIE = D2_SERIE 
	    AND        		D2_CLIENTE = F2_CLIENTE 
	    AND        		D2_LOJA = F2_LOJA 
	    AND        		D2.%NotDel%
	    INNER JOIN 		%Table:SA3% A3 
	    ON         		F2_VEND1 = A3_COD 
	    AND        		A3.%NotDel%
	    WHERE      		F2.%NotDel%
	    AND				D2.%NotDel%
	    AND				A3.%NotDel%
	    AND        		F2_EMISSAO >= GETDATE()- %Exp:nGetDate% 
	    AND        		F2_TIPO = 'N' 
	    GROUP BY   		F2_DOC, 
	    				F2_FILIAL, 
	    				F2_EMISSAO, 
	    				F2_CLIENTE+F2_LOJA, 
	    				D2_CF, 
	    				D2_PEDIDO, 
	    				D2_TIPO,
	    				F2_COND, 
	    				F2_VEND1, 
	    				F2_VALMERC, 
	    				F2_SERIE
	     UNION ALL
	     (
	         SELECT  		(ROW_NUMBER() OVER (ORDER BY D1.D1_DOC)/1000)+1 PAG , 
	         				D1_DOC                                         	NTFISCAL , 
	         				D1_SERIE										NTFSERIE,                   	
	         				D1_FILIAL                                      	FILIAL , 
	         				D1_EMISSAO                                  	DTEMIS , 
	         				D1_FORNECE+D1_LOJA          					CODCLI , 
	         				SUM(D1_TOTAL)                             		VALNF , 
	         				D2_PEDIDO                      					NUMPED , 
	         				D2_TIPO                                        	CTIPO , 
	         				NULL                                           	MTVDEV , 
	         				D1_CF                                          	CODNATOP , 
	         				F2_COND                                        	CODCNDPAG , 
	         				F2_VEND1                                       	CODVEND 
	         FROM      		%Table:SD1% D1 
	         INNER JOIN		%Table:SD2% D2 
	         ON        		D1_FILIAL = D2_FILIAL 
	         AND       		D1_NFORI = D2_DOC 
	         AND       		D1_SERIORI = D2_SERIE 
	         AND       		D2_CLIENTE = D1_FORNECE 
	         AND       		D2_LOJA = D1_LOJA 
	         AND       		D1_COD = D2_COD 
	         AND       		D2.%NotDel%
	         INNER JOIN		%Table:SF2% F2 
	         ON        		D2_FILIAL = F2_FILIAL 
	         AND       		D2_DOC = F2_DOC 
	         AND       		D2_CLIENTE = F2_CLIENTE 
	         AND       		D2_LOJA = F2_LOJA 
	         INNER JOIN		%Table:SA3% A3 
	         ON        		F2_VEND1 = A3_COD 
	         WHERE    		D1.%NotDel%
	         AND 			D2.%NotDel%
	         AND			F2.%NotDel%
	         AND			A3.%NotDel%
	         AND       		D1_TIPO = 'D' 
	         AND       		D1_EMISSAO >= GETDATE()- %Exp:nGetDate% 
	         GROUP BY  		D1_DOC, 
	         				D1_FILIAL, 
	         				D1_EMISSAO, 
	         				D1_FORNECE+D1_LOJA, 
	         				D2_PEDIDO, 
	         				D2_TIPO,
	         				D1_CF, 
	         				F2_COND, 
	         				F2_VEND1, 
	         				D1_SERIE
	    ) ORDER BY PAG	
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
				cSetResp  += '"NTFISCAL":"'		+ TRIM((cAliasTMP)->FILIAL) + TRIM((cAliasTMP)->NTFISCAL + (cAliasTMP)->NTFSERIE)
				cSetResp  += '","TIPONOTA":"'	+ TRIM((cAliasTMP)->CTIPO)					
				cSetResp  += '","DTEMIS":"'		+ TRIM((cAliasTMP)->DTEMIS)											
				cSetResp  += '","CODCLI":"'		+ ALLTRIM((cAliasTMP)->CODCLI)										
				cSetResp  += '","VALNF":'		+ ALLTRIM(cValToChar((cAliasTMP)->VALNF))										
				cSetResp  += ',"NUMPED":"'		+ TRIM((cAliasTMP)->FILIAL)	+ TRIM((cAliasTMP)->NUMPED)								
				cSetResp  += '","MTVDEV":"'		+ cValToChar((cAliasTMP)->MTVDEV)										
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
