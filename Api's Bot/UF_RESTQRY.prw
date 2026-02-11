#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'RESTFUL.CH'
#INCLUDE 'TOPCONN.CH'
#INCLUDE 'tbiconn.CH'

WSRESTFUL restqry DESCRIPTION 'API consulta de querys' FORMAT APPLICATION_JSON

	WSMETHOD GET  simples DESCRIPTION 'Retorna se o serviço está online'  	                         WSSYNTAX '/simples'       PRODUCES APPLICATION_JSON
	WSMETHOD GET  user    DESCRIPTION 'Retorna se o serviço está online'  	   PATH "/restqry/user"  WSSYNTAX '/user'          PRODUCES APPLICATION_JSON
	WSMETHOD POST         DESCRIPTION 'Efetua a consulta'      		                                 WSSYNTAX '/consulta'      PRODUCES APPLICATION_JSON
	WSMETHOD POST query   DESCRIPTION 'Efetua a consulta Direta'      		   PATH "/restqry/query" WSSYNTAX '/restqry/query' PRODUCES APPLICATION_JSON

ENDWSRESTFUL

WSMETHOD GET simples WSRESTFUL restqry
    Local lRet      := .T.
    oJson := JsonObject():New()
    oJson['mensagem'] := EncodeUTF8("REST PROTHEUS ONLINE. GRUPO DE EMPRESAS: " + cEmpAnt)
    self:SetResponse(oJson:toJson())
Return(lRet)

WSMETHOD GET user WSRESTFUL restqry
    Local lRet      := .T.
    oJson := JsonObject():New()
    oJson['usuario']    := EncodeUTF8(cUserName)
    oJson['codigo']     := EncodeUTF8(RetCodUsr())
    oJson['nome']       := EncodeUTF8(UsrFullName())
    self:SetResponse(oJson:toJson())
Return(lRet)

WSMETHOD POST WSSERVICE restqry
    Local cJson         := self:getContent()
    Local lRet          := .T.
    Local aRet

    conout(cJson)
    
    If ValType(cJson) != 'U' .AND. !Empty(cJson)
        oBody := JsonObject():New()                
        oBody:FromJson(cJson)
        If ValType("oBody") != 'U'
            aRet  := executaQry(oBody['QUERY'], oBody['ORDEM'], oBody['PAGINA'], oBody['PORPAGINA'] )
            If aRet[1]                            
                self:SetResponse(EncodeUTF8(aRet[2]:toJson()))                
            Else
                SetRestFault(400, aRet[2])
                lRet := .F.
            EndIf
        Else
            SetRestFault(400, 'Body enviado com erros')
            lRet := .F.
        EndIf
    Else
        SetRestFault(400, 'Body enviado com erros')
        lRet := .F.
    EndIf

Return lRet

WSMETHOD POST query WSRESTFUL restqry
    Local cJson         := self:getContent()
    Local lRet          := .T.
    Local aRet, i 
    
    If ValType(cJson) != 'U' .AND. !Empty(cJson)
        oBody := JsonObject():New()                
        oBody:FromJson(cJson)
        If ValType("oBody") != 'U'
            aRet  := execQuery(oBody['QUERY'] )
            If aRet[1]       

                self:SetResponse('{"RETORNOS": [')                

                For i := 1 to Len(aRet[2])
                    cJsonAux := aRet[2][i]:toJson()
                    cJsonAux := EncodeUTF8(cJsonAux)
                    If ValType(cJsonAux) != 'C'
                        cJsonAux := aRet[2][i]:toJson()
                    EndIf                    
                    self:SetResponse(cJsonAux + Iif(Len(aRet[2])>i, ',', ''))                
                Next

                self:SetResponse(']}')                

            Else
                SetRestFault(400, aRet[2])
                lRet := .F.
            EndIf
        Else
            SetRestFault(400, 'Body enviado com erros')
            lRet := .F.
        EndIf
    Else
        SetRestFault(400, 'Body enviado com erros')
        lRet := .F.
    EndIf

Return lRet

Static Function execQuery(cQuery)
    Local aStruct, i, oErro

    Local bBlock 	:= ErrorBlock()
    Local aRet      := {}
    Local aDados    := {}

	//funcao que valida os erros em tempo de execucao
	ErrorBlock( {|e| oErro := e, Break(e)})

	BEGIN SEQUENCE
        
        If Select('QRYRET') > 0 
            QRYRET->(DbCloseArea())
        EndIf

        TcQuery cQuery New Alias 'QRYRET'

        aStruct := QRYRET->(dbStruct())
        
        While QRYRET->(!Eof())
            oAux := JsonObject():New()
            For i := 1 to Len(aStruct)
                cCampo := Alltrim(aStruct[i][1])
                xValor := QRYRET->&(cCampo)
                If ValType(xValor) == 'C'
                    xValor := Alltrim(xValor)
                EndIf
                oAux[cCampo] := xValor
            Next
            aAdd(aDados, oAux)                        
            QRYRET->(DbSkip())
        EndDo                

    RECOVER       		

        ErrorBlock(bBlock)

    END SEQUENCE 

    If oErro != nil    
        aRet := {.F., 'Erro de execução: ' + oErro:Description}            
    Else
        aRet := {.T., aDados}
    EndIf

Return aRet

Static Function executaQry(cQuery, cOrdem, nPage, nPageSize )

    Local cQueryTotal, cQueryPag, aStruct, i, oErro, aRet 
    Local nTotal    := 0
    Local cBanco    := UPPER(TcGetDb())
    Local bBlock 	:= ErrorBlock()

	//funcao que valida os erros em tempo de execucao
	ErrorBlock( {|e| oErro := e, Break(e)})
    
    Default nPageSize := 10
    Default nPage     := 1

	BEGIN SEQUENCE

        cQueryTotal := " SELECT COUNT(*) AS TOTAL FROM (" + Alltrim(cQuery) + ") "+IIF(cBanco == "ORACLE","","AS")+" SQL "

        If Select('QRYTOT') > 0 
            QRYTOT->(DbCloseArea())
        EndIf
        
        TcQuery cQueryTotal New Alias 'QRYTOT'

        nTotal := QRYTOT->TOTAL
        
        // cQueryPag := "SELECT * FROM ("
        IF cBanco == 'ORACLE'
    
              cQueryPag  := ""
              cQueryPag  += "SELECT * FROM"
              cQueryPag  += " ( "
              cQueryPag  += "   SELECT a.*, rownum r__ "
              cQueryPag  += "   FROM "
              cQueryPag  += "   ( "
              cQueryPag  += "     "+cQuery+" "
              cQueryPag  += "     ORDER BY "+cOrdem+" "
              cQueryPag  += "   ) a "
              cQueryPag  += "   WHERE rownum < (( "+cValToChar(nPage)+" * "+cValToChar(nPageSize)+") + 1 ) "
              cQueryPag  += " ) "
              cQueryPag  += " WHERE r__ >= ((("+cValToChar(nPage)+"-1) * "+cValToChar(nPageSize)+") + 1) "
        ELSE
            cQueryPag := "with query as"
            cQueryPag += "("
            cQueryPag += "    select "+IIF(cBanco == "ORACLE","SQL.","")+"*, ROW_NUMBER() OVER(ORDER BY " + cOrdem + " ) as line from ( " + cQuery + " ) "+IIF(cBanco == "ORACLE","","AS")+" SQL"
            cQueryPag += ")"
            cQueryPag += "select top "+cValToChar(nPageSize)+" * from query "
            cQueryPag += "where line > ("+cValToChar(nPage)+" - 1) * ("+cValToChar(nPageSize)+") ORDER BY " + cOrdem
        EndIf
        

        If Select('QRYRET') > 0 
            QRYRET->(DbCloseArea())
        EndIf
        
        TcQuery cQueryPag New Alias 'QRYRET'

        aStruct := QRYRET->(dbStruct())

        oRet    := JsonObject():New()        
        oRet['TOTAL']    := nTotal
        oRet['PAGINA']   := nPage
        oRet['PORPAGINA']:= nPageSize
        oRet['PROXIMO']  := (nTotal / nPageSize) > nPage
        oRet['RETORNOS'] := {}
        
        While QRYRET->(!Eof())
            oAux := JsonObject():New()
            For i := 1 to Len(aStruct)
                cCampo := Alltrim(aStruct[i][1])
                oAux[cCampo] := QRYRET->&(cCampo)
            Next
            aAdd(oRet['RETORNOS'], oAux)                        
            QRYRET->(DbSkip())
        EndDo                

    RECOVER       		

        ErrorBlock(bBlock)

    END SEQUENCE 

    If oErro != nil    
        aRet := {.F., 'Erro de execução: ' + oErro:Description}            
    Else
        aRet := {.T., oRet}
    EndIf

Return aRet

Static Function criaArea(cQuery, cEmp)
    Local nPosIni   := 1
    Local lExit     := .F.
    Local aTabs     := {}
    
    Default cEmp    := cEmpAnt

    While !lExit
        nPosIni := At(cEmp + '0', cQuery, nPosIni)
        If nPosIni != 0
            cTab := SubStr(cQuery, nPosIni-3, 3)
            If aScan(aTabs, cTab) == 0
                aAdd(aTabs, cTab)
            EndIf
        Else
            lExit := .T.
        EndIf
    EndDo
Return

//-------------------------------------------------------------------
/*/{Protheus.doc} UF_RESTQRY
User Function auxiliar para executar via RPC
@author  Sidney Sales
@since   26/09/2022
@version 1.0
/*/
//-------------------------------------------------------------------
User Function UF_RESTQRY(aParams)
    Local cEmp, cFil, cJson, cVerbo, cModulo
    
    If ValType(aParams) != 'A' .OR. Empty(aParams) 
        return {.F., 'Parametros não enviados.'}    
    Else
        cEmp   := aParams[1]
        cFil   := aParams[2]
        cJson  := aParams[3]
        cVerbo := aParams[4]
        cModulo:= ''
        If Len(aParams) > 4 
            cModulo:= aParams[5]
        EndIf
    EndIf

    VarInfo( 'UF: Parametros: ', aParams, , .T.) 
    
    //Inicia outra Thread com outra empresa e filial
    RpcSetType(3)
    If RpcSetEnv( cEmp, cFil,,,cModulo)
        If cVerbo == 'POST'

            If ValType(cJson) != 'U' .AND. !Empty(cJson)
                oBody := JsonObject():New()                
                oBody:FromJson(cJson)
                If ValType("oBody") != 'U'
                    aRet  := executaQry(oBody['QUERY'], oBody['ORDEM'], oBody['PAGINA'], oBody['PORPAGINA'] )
                    If aRet[1]                            
                        cRet := aRet[2]:toJson()        
                        lRet := .T.                        
                    Else
                        cRet := aRet[2]
                        lRet := .F.
                    EndIf
                Else
                    cRet := 'Body enviado com erros'
                    lRet := .F.
                EndIf
            Else
                cRet := 'Body enviado com erros'
                lRet := .F.
            EndIf
        ElseIf cVerbo == 'GET'
            oJson := JsonObject():New()
            oJson['mensagem'] := EncodeUTF8("REST PROTHEUS ONLINE. GRUPO DE EMPRESAS: " + cEmpAnt)
            cRet := oJson:toJson() 
            lRet := .T.
        Else
            oJson := JsonObject():New()
            oJson['mensagem'] := EncodeUTF8("Metodo nao preparado("+cVerbo+")")
            cRet := oJson:toJson() 
            lRet := .F.    
        EndIf
    Else
        lRet := .F.
        cRet := 'Nao foi possivel abrir o ambiente para empresa/filial: ' + cEmp + '/' + cFil
    EndIf

    RpcClearEnv()

Return {lRet, cRet}






