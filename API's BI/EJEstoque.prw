#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"

/*---------------------------------------------------------------------------------------------*
* {Protheus.doc}  GET                                                                          *
* Processa as informações e retorna o json                                                   *
* @since 	05/03/2020                                                                         *
* @version undefined                                                                           *
* @param oSelf, object, Objeto contendo dados da requisis�o efetuada pelo cliente, tais como:  *
*    - Parâmetros querystring (parâmetros informado via URL)                                 *
*    - Objeto JSON caso o requisição seja efetuada via Request Post                          *
*    - Header da requisição                                                                  *
*    - entre outras ...                                                                        *
* @type Method                                                                                 *
*----------------------------------------------------------------------------------------------*/

#Define _Function	"Estoque"
#Define _DescFun  	"Quantidade de Produtos em Estoque"
#Define Desc_Rest 	"Serviço REST para Disponibilizar dados de Produtos em Estoque"
#Define Desc_Get  	"Retorna a quantidade de produtos em estoque de acordo com os parametros passados" 

WSRESTFUL EjEstoque DESCRIPTION Desc_Rest

	WSDATA nPag		As Integer
	
	WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/EjEstoque || /EjEstoque/{}"

END WSRESTFUL

/*-------------------------------------------------------------------------
{Protheus.doc} Get
EjEstoque   Fun��o Respons�vel por preencher os dados de Estoque para Ejecty
@type       User function
@version    12.1.25
@author     
@since      05/03/2021
-------------------------------------------------------------------------*/
WSMETHOD GET WSRECEIVE nPag WSSERVICE EjEstoque
	Local aArea		:= GetArea()
	Local cAliasTMP
	Local cRet		
	Local cSetResp
	Local nX
	Local nPagFim	
	Local nPag		:= Self:nPag 
	Local aTabs		:= {}
	Local _cEmpresa	:= "01"
	Local _cFilial	:= "01"
	Local _lSegue	:= .F.

	If FindFunction("WfPrepEnv") .And. IsBlind()

		//-------------------------------------------------------------------------
		// Cofigura empresa/filial
		//-------------------------------------------------------------------------
		RpcSetEnv( _cEmpresa,_cFilial,,, "GET", "METHOD", aTabs,,,,)
		cEmpant := _cEmpresa
		cFilant := _cFilial
	
		//-------------------------------------------------------------------------
		// Enquanto nao configura empresa e filial fica dentro
		// do "laco" verificando
		//-------------------------------------------------------------------------
		While ! _lSegue
			If _cEmpresa + _cFilial == cNumEmp
				_lSegue := .T.
			Endif
		End
	Endif


    //-------------------------------------------------------------------------
	// define o tipo de retorno do metodo
    //-------------------------------------------------------------------------
	::SetContentType("application/json")

	cRet		:= ""
	aArea     	:= GetArea()
	cAliasTMP 	:= GetNextAlias()

	//-------------------------------------------------------------------------
    //Verifica se ha conexao em aberto, caso haja feche.
    //-------------------------------------------------------------------------
	IF Select(cAliasTmp)>0
		dbSelectArea(cAliasTmp)
		(cAliasTmp)->(dbCloseArea())
	EndIf

    //-------------------------------------------------------------------------
	//Select de cadastro 
    //-------------------------------------------------------------------------
	BeginSQL Alias cAliasTMP
	
		SELECT		((ROW_NUMBER() OVER (ORDER BY A.R_E_C_N_O_)) /1000)+1	AS PAG  
					, B2_FILIAL                                             AS Filial
                    , B2_COD												AS CodigoProduto
					, (	B2_QATU - B2_RESERVA - B2_QEMP - B2_QACLASS -
					 	B2_QEMPSA - B2_QEMPPRJ - B2_QEMPPRE	) 				AS QtdeEstoque
                    , B2_LOCAL                                              AS Armazem
		FROM		%Table:SB2% A
		INNER JOIN 	%Table:SB1% B
		ON 			B1_COD = B2_COD
		WHERE		B1_MSBLQL = '2' 
        AND         (	B2_QATU - B2_RESERVA - B2_QEMP - B2_QACLASS -
					 	B2_QEMPSA - B2_QEMPPRJ - B2_QEMPPRE	) > 0
		AND			B1_TIPO IN ('PA','ME')
		AND			A.%NotDel%
		AND			B.%NotDel%
		ORDER BY 	A.B2_COD, A.B2_LOCAL
		
	EndSql

    //-------------------------------------------------------------------------
	// Guarda a ultima pagina
    //-------------------------------------------------------------------------
	dbSelectArea(cAliasTmp)
	(cAliasTmp)->( DbGoTop() )
	While (cAliasTmp)->( !Eof() )
		nPagFim		:= (cAliasTmp)->PAG
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->( DbGoTop() )

	If (cAliasTmp)->( Eof() )
		cSetResp := '{ "estoque":[ "retorno":"Nao Existe Itens Nessa Pagina"] }'
	Else
		(cAliasTmp)->( DbGoTop() )  
		nX	:= 1
		cSetResp  := '{ "estoque":[ '
		While (cAliasTmp)->( !Eof() ) 
			If nPag == (cAliasTmp)->PAG 			
				If nX > 1
					cSetResp  +=' , '
				EndIf				
				cSetResp  += '{'
				cSetResp  += '"empresa":"'	    	        + cEmpant
                cSetResp  += '","filial":"'	          	    + TRIM((cAliasTmp)->Filial)
				cSetResp  += '","codigoProduto":"'	    	+ TRIM((cAliasTmp)->CodigoProduto)
                cSetResp  += '","armazem":"'    	    	+ TRIM((cAliasTmp)->Armazem)
				cSetResp  += '","estoqueProntaEntrega":'	+ TRIM(cValToChar((cAliasTmp)->QtdeEstoque))
				cSetResp  += '}'

				(cAliasTmp)->(dbSkip())
				nX:= nX+1
			Else
				(cAliasTmp)->(dbSkip())
			Endif
		EndDo
		cSetResp  += ']'
		cSetResp  += ',"PaginalAtual":'				+ cValToChar(Self:nPag)			
		cSetResp  += ',"TotalDePaginas":'			+ cValToChar(nPagFim)
		cSetResp  += '}'

	EndIf
	//-------------------------------------------------------------------------
    //Fecha a tabela
    //-------------------------------------------------------------------------
	(cAliasTmp)->(DbCloseArea())

    //-------------------------------------------------------------------------
	//Envia o JSON Gerado para a aplicacao
    //-------------------------------------------------------------------------
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)
