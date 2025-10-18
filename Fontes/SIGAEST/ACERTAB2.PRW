#INCLUDE "PROTHEUS.CH"
/*-------------------------------------------------------------
{Protheus.doc}  ACERTAB2
                EFETUA O UPDATE DA TABELA SB2 DE ACORDO COM OS 
                SALDOS APURADOS NA TABELA SBF
@type           Function
@version        12.1.23
@author         Carlos Eduardo Saturnino - Atlanta Consulting
@since          27/06/2021
-------------------------------------------------------------*/
User Function ACERTAB2()            

    Local aArea         := GetArea()
    Local cAliasTmp     := GetNextAlias()
    Local aDadosSD3     := {}
    Local cFileLog      := 'C:\TEMP\SB2xSBF.LOG'
    Local nHdlLog       := ''
    Local lMsErroAuto   := .F.
    Local cErrAuto      := ""

	//---------------------------------------------------------------------
	// -- CRIA ARQUIVO DE LOG -- 
	//---------------------------------------------------------------------
	nHdlLog  := MSFCreate(cFileLog,0)

	If nHdlLog < 0

		Aviso('ATENÇÃO', 'PROBLEMAS NA CRIAÇÃO DO ARQUIVO DE LOG DE INCONSISTÊNCIAS!' + Chr(10) + Chr(13) + 'Código do erro: ' + StrZero(FError(),10), {'OK'}, 3)

	Else
		//---------------------------------------------------------------------
		// -- Atualiza arquivo de LOG --
		//---------------------------------------------------------------------
		UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] INICIANDO PROCESSO DE BALANCEAMENTA DAS TABELAS SB2/SBF' + Chr(13) + Chr(10))


        //----------------------------------------------------------
        // Efetua a Query de controle da inclusão de Dados
        //----------------------------------------------------------
        BeginSql Alias cAliasTmp 

            SELECT		BF_PRODUTO
                        , BF_LOCAL
                        , B1_UM
                        , B1_GRUPO
                        , B1_CONTA
                        , SUM(BF_QUANT) 		    AS BF_QUANT
                        , B2_QATU
                        , SUM(BF_QUANT)  - B2_QATU	AS DIFERENCA
            FROM 		SBF010 BF
            INNER JOIN 	SB2010 B2
            ON 			BF_PRODUTO 		 =  B2_COD
            AND			BF_FILIAL 		 =  B2_FILIAL
            AND			BF_LOCAL 		 =  B2_LOCAL
            INNER JOIN 	SB1010 B1
            ON 			B1_COD			 = BF_PRODUTO
            WHERE		BF_FILIAL		 = %Exp:FwFilial("SBF")%
            AND			BF.D_E_L_E_T_	<> '*'
            AND			B2.D_E_L_E_T_	<> '*'
            AND			B1.D_E_L_E_T_	<> '*'
            AND			B2_QACLASS       = 0
            GROUP BY 	BF_PRODUTO, B2_QATU, BF_LOCAL, B1_UM, B1_GRUPO, B1_CONTA    

        EndSQL

        //----------------------------------------------------------
        // Posiciona na Tabela SB1 para desativar o controle de
        // Endereçamento
        //----------------------------------------------------------
        dbSelectArea("SB1")
        dbSetOrder(1)               // B1_FILIAL+B1_COD

        While ! (cAliasTmp)->(EOF())

            If (cAliasTmp)->DIFERENCA <> 0
                //----------------------------------------------------------
                // Formata o valor do Lançamento, e o TM correspondente
                //----------------------------------------------------------
                If (cAliasTmp)->DIFERENCA < 0
                    nQuant  := (cAliasTmp)->DIFERENCA * -1
                    cTM     := "503"
                Else
                    nQuant  := (cAliasTmp)->DIFERENCA
                    cTM     := "103"        
                Endif

                If SB1->(dbSeek(FwFilial("SB1") + (cAliasTmp)->BF_PRODUTO))

                    //----------------------------------------------------------
                    // Desativa o controle de endereçamento
                    //----------------------------------------------------------
                    Reclock("SB1")
                    SB1->B1_LOCALIZ := "N"
                    msUnlock()

                    //----------------------------------------------------------
                    // Preenche o array do ExecAuto
                    //----------------------------------------------------------
                    aadd(aDadosSD3,{"D3_TM"			,cTM	    				,Nil})
                    aadd(aDadosSD3,{"D3_COD"		,SB1->B1_COD	            ,Nil})
                    aadd(aDadosSD3,{"D3_UM"			,SB1->B1_UM     			,Nil})
                    aadd(aDadosSD3,{"D3_LOCAL"		,(cAliasTmp)->BF_LOCAL      ,Nil})
                    aadd(aDadosSD3,{"D3_QUANT"		,nQuant 					,Nil})
                    aadd(aDadosSD3,{"D3_CUSTO1"		,0          				,Nil})
                    aadd(aDadosSD3,{"D3_EMISSAO"	,dDataBase					,Nil})
                    aadd(aDadosSD3,{"D3_GRUPO"		,SB1->B1_GRUPO	        	,Nil})
                    aadd(aDadosSD3,{"D3_CONTA"		,""                 		,Nil})

                    MSExecAuto({|x,y| mata240(x,y)},aDadosSD3,3)

                    If lMsErroAuto 													

                        cErrAuto := MostraErro(cFileLog)													
                        UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] [ Produto: ' +  (cAliasTmp)->BF_PRODUTO + ' | Local: ' +  (cAliasTmp)->BF_LOCAL + ' | Tipo de Mov.: ' + cTm + ' | Quantidade : '+ cValToChar(nQuant) +' | Armazém : ' + (cAliasTmp)->BF_LOCAL + ' ] Inconsistência na atualização dos dados. Detalhe do Erro: ' + cErrAuto  + Chr(13) + Chr(10))

                    Else

                        UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] [ Produto: ' +  (cAliasTmp)->BF_PRODUTO + ' | Local: ' +  (cAliasTmp)->BF_LOCAL + ' | Tipo de Mov.: ' + cTm + ' | Quantidade : '+ cValToChar(nQuant) +' | Armazém : ' + (cAliasTmp)->BF_LOCAL + ' ] [ Atualizado com Sucesso !!! ]' + Chr(13) + Chr(10))

                    EndIf
                    
                    //----------------------------------------------------------
                    // Re-ativa o controle de endereçamento
                    //----------------------------------------------------------
                    Reclock("SB1")
                    SB1->B1_LOCALIZ := "S"
                    msUnlock()
                
                Endif

            Endif
            
            aDadosSD3 := {}
            (cAliasTmp)->(dbSkip())
        
        EndDo
        
        UpdFileLog(nHdlLog, '[' + DtoC(Date()) + ' - ' + Time() + '] PROCESSO DE BALANCEAMENTO DA TABELA SB2 X SBF ENCERRADO' + Chr(13) + Chr(10))
    
    Endif
    
    restArea(aArea)

Return()

/*---------------------------------------------------------------------
TODO 			Descrição auto-gerada.
@author 		Carlos Eduardo Saturnino
@since 			17/12/2019
@version 		1.0
---------------------------------------------------------------------*/
Static Function UpdFileLog(nHdlLog, cMsg)

	FWrite(nHdlLog, cMsg)

Return Nil
