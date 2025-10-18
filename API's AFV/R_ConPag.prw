#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"
//#Include "aarray.ch"
//#Include "json.ch"

/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Douglas.Silva Feat Carlos Eduardo Saturnino                                         *  
* Processa as informações e retorna o json                                                    *
* @since 	03/08/2019                                                                        *
* @version undefined                                                                          *
* @param oSelf, object, Objeto contendo dados da requisição efetuada pelo cliente, tais como: *
*    - Parâmetros querystring (parâmetros informado via URL)                                  *
*    - Objeto JSON caso o requisição seja efetuada via Request Post                           *
*    - Header da requisição                                                                   *
*    - entre outras ...                                                                       *
* @type Method                                                                                *
**********************************************************************************************/

#Define _Function	"CondPgto"
#Define _DescFun	"Condicao de Pagamento"
#Define Desc_Rest 	"Serviço REST para Disponibilizar / Inserir dados de " + _DescFun
#Define Desc_Get  	"Retorna o cadastro de Condicao de Pagamento informado de acordo com os parametros passados" 
#Define Desc_Post	"Cria o cadastro de cliente informado de acordo com data de atualização do cadastro"

user function R_ConPag()

return

WSRESTFUL rCondPgto DESCRIPTION _DescFun

	WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING    

WSMETHOD GET DESCRIPTION  Desc_Get  WSSYNTAX "/rCondPgto || /rCondPgto/{}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE nPag HEADERPARAM TENANTID WSSERVICE rCondPgto
	Local aArea		:= GetArea()
	Local cAliasTMP	:= GetNextAlias()
	Local nPag 		:= Self:nPag
	Local nPrzMd 	:= 0
	Local cSetResp
	Local nPagFim
	Local aCond
	Local _n, nX	
	


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
	
	//**********************************************************************
	// Alteracoes solicitadas por Michael em 26/02/2020
	//**********************************************************************
	// ,D.E4_DESCRI	DESCRICAO  		--> Alterado	26/02/2020
	// ,D.E4_COND  	CONDICOES  		--> Excluido	26/02/2020
	//,CASE D.E4_MSBLQL WHEN '1'	--> Alterado 	26/02/2020
	//					THEN '0' 
	//					ELSE '1' 
	//				END AS FLAGUSO
	//**********************************************************************
	
	// Faz a Consulta SQL no Banco
	BeginSql Alias cAliasTMP

		SELECT		(ROW_NUMBER() OVER (ORDER BY D.R_E_C_N_O_)) 			AS CONT  
				   	,((ROW_NUMBER() OVER (ORDER BY D.R_E_C_N_O_)) /1000)+1	AS PAG  
				   	,D.E4_CODIGO  	CODIGO
				   	,D.E4_COND		DESCRICAO
				   	,D.E4_ACRSFIN  	ACRESC
				   	,D.E4_DESCFIN  	DECRESC
				   	,D.E4_FORMA  	FORMA
					,CASE D.E4_ZZEAFV WHEN 'N' 
						THEN '0' 
						ELSE '1' 
					END AS FLAGUSO 
		FROM   		%Table:SE4% D
		WHERE  		D.%NotDel%
		AND			D.E4_MSBLQL = '2'
		ORDER BY 	D.R_E_C_N_O_ 

	EndSQL

	//****************************************************************
	// Seleciona a Tabela e posiciona no primeiro registro
	//****************************************************************
	dbSelectArea(cAliasTmp)
	(cAliasTmp)->( DbGoTop() )

	//****************************************************************
	// Armazena a página e registro final
	//****************************************************************
	While (cAliasTmp)->( !Eof() )
		nPagFim	:= (cAliasTmp)->PAG
		nReg 	:= (cAliasTmp)->CONT
		(cAliasTmp)->(dbSkip())
	EndDo

	//****************************************************************
	// Posiciona no primeiro registro
	//****************************************************************
	(cAliasTmp)->( DbGoTop() )

	//****************************************************************
	// Preenche a variável cSetResponse para montar o arquivo Json
	//****************************************************************
	If (cAliasTMP)->( Eof() )

		cSetResp := '{ "T_CONDPAGTO":[ "Nao Existe Dados Nessa Pagina" ]} '

	//****************************************************************
	// Caso a QueryString nPag estiver preenchida
	//****************************************************************
	ElseIf !Empty(nPag)
		
		//****************************************************************
		// Preenche o cabecalho do arquivo Json e atribui 1 para o primei-
		// ro registro
		//****************************************************************
		nX	:= 1
		cSetResp  := '{ "T_CONDPAGTO":[ ' 
		
		While (cAliasTmp)->( !Eof() )

			//****************************************************************
			// Grava os registros conforme a pagina solicitada na QueryString 
			//****************************************************************
			If nPag ==  (cAliasTMP)->PAG
				
				//****************************************************************
				// Simula a condicao de pagamento para calculo do prazo medio
				//****************************************************************
				aCond := Condicao( 1000, (cAliasTMP)->CODIGO )

				//****************************************************************
				// Calcula o Prazo Medio
				// Retorno 	aCond[_n][01] = Vencimento da Parcela
				//			aCond[_n][02] = Valor da Parcela
				//****************************************************************
				For _n := 1 to Len(aCond)
					nPrzMd 	+= (aCond[_n,01] - dDatabase)  				
				Next _n

				//****************************************************************
				// A partir do segundo registro, grava a vírgula para separar os  
				// colchetes do arquivo
				//****************************************************************
				If nX > 1
					cSetResp  +=' , '
				EndIf
				/*
				cSetResp  += '{'
				cSetResp  += '"CODIGO":"'				+ TRIM((cAliasTMP)->CODIGO)					
				cSetResp  += '","DESCRICAO":"'			+ TRIM((cAliasTMP)->DESCRICAO)											
				cSetResp  += '","PRAZOMEDIO":"'			// Depende de Customizacao da Suntech
				cSetResp  += '","CONDICOES":"'			+ TRIM((cAliasTMP)->CONDICOES)
				cSetResp  += '","FORMA":"'				+ TRIM((cAliasTMP)->FORMA)											
				cSetResp  += '","ACRESC":"'				+ ALLTRIM(cValToChar((cAliasTMP)->ACRESC))											
				cSetResp  += '","DECRESC":"'			+ ALLTRIM(cValToChar((cAliasTMP)->DECRESC))											
				cSetResp  += '"}'
				*/
				/***********************************************************************************
				* Alterado conforme solicitacao do Sr. Michael em 08/01/2020
				***********************************************************************************/
				
				cSetResp  += '{'
				cSetResp  += '"CODIGO":"'				+ TRIM((cAliasTMP)->CODIGO)									
				cSetResp  += '","DESCRICAO":"'			+ TRIM((cAliasTMP)->DESCRICAO)																
				cSetResp  += '","PRAZOMEDIO":'			+ cValtoChar(( Round( nPrzMd,1 ) / Len(aCond))-1)	
				cSetResp  += ',"INDICECONDPAGTO":'		+ cValToChar(0)									
				cSetResp  += ',"CODIGOTABELAPRECO":"'	// Passar valor da chave em branco				
				cSetResp  += '","PERCDESCPERMITIDO":'	+ ALLTRIM(cValToChar((cAliasTMP)->DECRESC))		
				cSetResp  += ',"QTDEPARCELAS":'			+ cValToChar(Len(aCond))						
				cSetResp  += ',"FLAGUSO":'             	+ (cAliasTMP)->FLAGUSO							
				cSetResp  += ',"CODIGOEMPRESAESP":"'	// Passar valor da chave em branco				
				cSetResp  += '","CODIGOEMPRESA":"'		// Passar valor da chave em branco				
				cSetResp  += '"}'
				
				(cAliasTMP)->(dbSkip())
				nX ++
			Endif
			nPrzMd := 0
		EndDo

		If cSetResp <> '{ "T_CONDPAGTO":[ "Nao Existe Dados Nessa Pagina" ]} '
			cSetResp  += ']'	
			cSetResp  += ',"PaginalAtual":'				+ cValToChar(Self:nPag)			
			cSetResp  += ',"TotalDePaginas":'			+ cValToChar(nPagFim)
			cSetResp  += '}'
		Endif
	EndIf

	//Fecha a tabela
	(cAliasTMP)->(DbCloseArea())

	//Envia o JSON Gerado para a aplicação
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)
