#include 'protheus.ch'
#include 'restful.ch'
#Include 'topconn.ch' 

WSRESTFUL CPEstoqueDisponivel DESCRIPTION "HB - Estoque de produtos disponiveis" FORMAT "application/json"
	WSDATA SKU as String Optional
	WSMETHOD GET DESCRIPTION "Lista de estoques disponiveis " WSSYNTAX '/CPEstoqueDisponivel/{}' 
	
END WSRESTFUL     

//GET retorna estoques
WSMETHOD GET WSSERVICE CPEstoqueDisponivel
	Local lReturn 	:= .T.
	Local oResponse := JsonObject():New()
	Local _cAlias,cSku 
	
	::SetContentType('application/json')

	oResponse['status'] := 200
	oResponse['dados']	:={}
	
	_cAlias := GetNextAlias()
	
	//recebendo mesagem via parametros
	If Len(::aUrlParms) > 0
		cSku := alltrim(::aUrlParms[1])
		BeginSql Alias _cAlias
			SELECT B1.B1_COD AS SKU,B1.B1_CODBAR AS CODBAR,B1.B1_DESC AS DESCRICAO,B1.B1_POSIPI AS NCM,
			IIF(((B2_QATU - B2_RESERVA - B2_QEMP - B2_QACLASS - B2_QEMPSA - B2_QEMPPRJ - B2_QTNP - 5) + (B2_QNPT - B2_QEMPPRE)) < 0, 0, ((B2_QATU - B2_RESERVA - B2_QEMP - B2_QACLASS - B2_QEMPSA - B2_QEMPPRJ - B2_QTNP - 5) + (B2_QNPT - B2_QEMPPRE)))  AS DISPONIVEL
			FROM SB2010 B2
			INNER JOIN SB1010 B1 ON B1.B1_COD=B2.B2_COD
			AND B1.B1_TIPO IN ('PA','ME')
			AND B1.B1_MSBLQL<>'1'
			AND B1.D_E_L_E_T_=''
			WHERE B2.D_E_L_E_T_ = ''
			AND B2.B2_FILIAL='02'
			AND B2.B2_LOCAL='02' 
			AND LTRIM(RTRIM(B1.B1_COD))  = %Exp:cSku%
		EndSql
	Else
		BeginSql Alias _cAlias
			SELECT B1.B1_COD AS SKU,B1.B1_CODBAR AS CODBAR,B1.B1_DESC AS DESCRICAO,B1.B1_POSIPI AS NCM,
			IIF(((B2_QATU - B2_RESERVA - B2_QEMP - B2_QACLASS - B2_QEMPSA - B2_QEMPPRJ - B2_QTNP - 5) + (B2_QNPT - B2_QEMPPRE)) < 0, 0, ((B2_QATU - B2_RESERVA - B2_QEMP - B2_QACLASS - B2_QEMPSA - B2_QEMPPRJ - B2_QTNP - 5) + (B2_QNPT - B2_QEMPPRE)))  AS DISPONIVEL
			FROM SB2010 B2
			INNER JOIN SB1010 B1 ON B1.B1_COD=B2.B2_COD
			AND B1.B1_TIPO IN ('PA','ME')
			AND B1.B1_MSBLQL<>'1'
			AND B1.D_E_L_E_T_=''
			WHERE B2.D_E_L_E_T_ = ''
			AND B2.B2_FILIAL='02'
			AND B2.B2_LOCAL='02'
		EndSql
	Endif
		
	While (_cAlias)->(!Eof())
		oJsonSB2 := JsonObject():New()
		oJsonSB2['SKU'] 		:= Alltrim((_cAlias)->SKU)
		oJsonSB2['DESCRICAO']	:= Alltrim((_cAlias)->DESCRICAO)
		oJsonSB2['DISPONIVEL'] 	:= (_cAlias)->DISPONIVEL
		//oJsonSB2['CODBAR'] := Alltrim((_cAlias)->CODBAR)
		//oJsonSB2['NCM'] 	:= Alltrim((_cAlias)->NCM)
		
		aAdd(oResponse['dados'], oJsonSB2)
		
		(_cAlias)->(DbSkip())
	Enddo

   (_cAlias)->(DbCloseArea())  
	
	::setResponse(oResponse:ToJson())
	
Return lReturn
