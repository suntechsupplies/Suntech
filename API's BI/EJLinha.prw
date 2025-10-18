#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"

/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Douglas.Silva                                                                       *  
* Processa as informações e retorna o json                                                    *
* @since 	28/07/2019                                                                        *
* @version undefined                                                                          *
* @param oSelf, object, Objeto contendo dados da requisição efetuada pelo cliente, tais como: *
*    - Parâmetros querystring (parâmetros informado via URL)                                  *
*    - Objeto JSON caso o requisição seja efetuada via Request Post                           *
*    - Header da requisição                                                                   *
*    - entre outras ...                                                                       *
* @type Method                                                                                *
**********************************************************************************************/
#Define _Function "Linha de Produto"
#Define _DescFun  "Linha de Produto"
#Define Desc_Rest "Serviço REST para Disponibilizar dados de Linha de Produto"
#Define Desc_Get  "Retorna o cadastro de Linha de Produtos informado de acordo com os parametros passados"

User Function EJLinha()

Return

WSRESTFUL EjLinha DESCRIPTION Desc_Rest

	WSDATA nPag		As Integer
	WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/EJLinha || /EJLinha/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE nPag WSSERVICE EjLinha
	Local aArea		:= GetArea()
	Local cAliasTMP
	Local cRet		
	Local cSetResp
	Local nX
	LOCAL nPagIni
	Local nPagFim
	Local nReg
	Local nRegFinal

	If Self:nPag == 1
		nPagIni		:= Self:nPag
		nPagFim		:= (Self:nPag*1000)
	Else
		nPagIni		:= (Self:nPag*1000)-999
		nPagFim		:= (Self:nPag*1000)
	EndIf

	// define o tipo de retorno do método
	::SetContentType("application/json")

	cRet		:= ""
	cAliasTMP 	:= GetNextAlias()


	//Select de cadastro 
	cQuery := "	SELECT (ROW_NUMBER() OVER (ORDER BY D.R_E_C_N_O_)) CONT  "

	cQuery += " , D.X5_CHAVE CODIGO"
	cQuery += " , D.X5_DESCRI 	DESCRICAO"
	cQuery += " FROM " + RetSqlName("SX5") + " D " 
	cQuery += " WHERE D.D_E_L_E_T_ <> '*' AND TRIM(X5_TABELA) = 'Z5'"
	cQuery += " ORDER BY D.R_E_C_N_O_ "

	cQuery := ChangeQuery(cQuery)

	//Verifica se há conexão em aberto, caso haja feche.
	IF Select(cAliasTMP)>0
		dbSelectArea(cAliasTMP)
		(cAliasTMP)->(dbCloseArea())
	EndIf

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),(cAliasTMP),.T.,.T.)

	dbSelectArea(cAliasTMP)
	dbSelectArea(cAliasTmp)

	(cAliasTmp)->( DbGoTop() )

	While (cAliasTmp)->( !Eof() )
		nReg := (cAliasTmp)->CONT
		(cAliasTmp)->(dbSkip())
	EndDo

	(cAliasTmp)->( DbGoTop() )

	If nReg <= 1000 
		nRegFinal := 1
	Else
		nRegFinal := Int(nReg/1000)+1 
	EndIf 


	If (cAliasTmp)->( Eof() )

		cSetResp := '{ "LinhaProduto":"Nao Existe Dados Nessa Pagina"} '

	Else


		(cAliasTmp)->( DbGoTop() )  
		nX	:= 1
		cSetResp  := '{ "LinhaProduto":[ ' 
		While (cAliasTmp)->( !Eof() )
			IF (cAliasTmp)->cont >= nPagIni .And. (cAliasTmp)->cont <= nPagFim
				If nX > 1
					cSetResp  +=' , '
				EndIf				
				cSetResp  += '{'
				cSetResp  += '"CODIGO":"'				+ TRIM((cAliasTMP)->CODIGO)					
				cSetResp  += '","DESCRICAO":"'			+ TRIM((cAliasTMP)->DESCRICAO)											
				cSetResp  += '"}'
				(cAliasTMP)->(dbSkip())
				nX:= nX+1
			Else
				(cAliasTMP)->(dbSkip())
				LOOP	
			EndIf
		EndDo
		cSetResp  += ']'	
		cSetResp  += ',"PaginalAtual":'				+ STR(Self:nPag)			
		cSetResp  += ',"TotalDePaginas":'			+ STR(nRegFinal)
		cSetResp  += '}'

	EndIf
	//Fecha a tabela
	(cAliasTMP)->(DbCloseArea())

	//Envia o JSON Gerado para a aplicação
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)