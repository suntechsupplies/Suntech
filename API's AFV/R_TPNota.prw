#Include "Protheus.ch"
#Include "RESTFUL.ch"
#Include "tbiconn.ch"
#Include "FWMVCDef.ch"

/**********************************************************************************************
* {Protheus.doc}  GET                                                                         *
* @author Douglas.Silva Feat Carlos Eduardo Saturnino                                         *  
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
#Define _Function	"Tipo de Nota"
#Define _DescFun	"RTPNota"
#Define Desc_Rest 	"Serviço REST para Disponibilizar / Inserir dados de Tipo de Nota" 
#Define Desc_Get  	"Retorna o cadastro de Tipo de Nota informado de acordo com os parametros passados" 
#Define Desc_Post	"Cria o cadastro de Tipo de Nota informado de acordo com data de atualização do cadastro"


user function R_TPNota()

return

WSRESTFUL RTPNota DESCRIPTION Desc_Rest

	WSDATA nPag		As Integer
    WSDATA TENANTID AS STRING    

WSMETHOD GET DESCRIPTION Desc_Get WSSYNTAX "/RTPNota || /RTPNota/{}"

END WSRESTFUL

WSMETHOD GET WSRECEIVE nPag HEADERPARAM TENANTID WSSERVICE RTPNota
	
	Local aArea		:= GetArea()
	Local cSetResp	:= ''
	Local nPag		:= Self:nPag
	Local aMtTpPed	:= {}
	Local nX,nZ

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


	// Tipos de Pedido de Vendas - Campo C5_TIPO 
	// N=Normal;C=Compl.Preco/Quantidade;I=Compl.ICMS;P=Compl.IPI;D=Dev.Compras;B=Utiliza Fornecedor
	aAdd(aMtTpPed,{"N"	, "Normal"					,1,0,0})
	aAdd(aMtTpPed,{"C"	, "Compl.Preco Quantidade"	,1,0,0})
	aAdd(aMtTpPed,{"I"	, "Compl.ICMS"				,1,0,0})
	aAdd(aMtTpPed,{"P"	, "Compl.IPI"				,1,0,0})
	aAdd(aMtTpPed,{"D"	, "Dev.Compras"				,0,1,0})
	aAdd(aMtTpPed,{"B"	, "Utiliza Fornecedor"		,0,1,0})

	//Inicio do retorno em JSON	
	cSetResp  := '{ "T_TIPONOTA":[ ' 
	nX		:= 1		

	For nZ := 1 To Len(aMtTpPed)

		If nX > 1
			cSetResp  +=' , '
		EndIf

		cSetResp  += '{'
		cSetResp  += '"Codigo":"'			 	+ RTRIM(FwNoAccent(aMtTpPed[nZ,01]))				
		cSetResp  += '","Descricao":"'		 	+ RTRIM(FwNoAccent(aMtTpPed[nZ,02]))																			
		cSetResp  += '","FlagVenda":'		 	+ cValToChar(aMtTpPed[nZ,03])
		cSetResp  += ',"FlagDevolucao":'		+ cValToChar(aMtTpPed[nZ,04])
		cSetResp  += ',"FlagDevolucao":'		+ cValToChar(aMtTpPed[nZ,05])
		cSetResp  += ' }'
		nX++

	Next nZ

	cSetResp  += ']'	
	cSetResp  += ',"PaginalAtual":'				+ STR(nPag)			
	cSetResp  += ',"TotalDePaginas":'			+ STR(nPag)
	cSetResp  += '}'

	//Envia o JSON Gerado para a aplicação
	::SetResponse( cSetResp ) 

	RestArea(aArea)

Return(.T.)
