#Include "Protheus.ch"
#Include "Totvs.ch"
#Include "tbiconn.ch""

/*-------------------------------------------------------------------------------
{Protheus.doc}  CalcPeLeg       
                Calcula o Peso Bruto e Peso Liquido dos pedidos legados
                da virada de release
@type           function
@version        1.0
@author         Carlos Eduardo Saturnino - Atlanta Consulting
@since          06/04/2022
-------------------------------------------------------------------------------*/
User Function CalcPeLeg()
    
    Local cAliasTMP     := GetNextAlias()


    If Select(cAliasTMP) > 0
        (cAliasTmp)->(dbCloseArea())
    Endif
    
    BEGINSQL Alias cAliasTMP

        SELECT      SC6.C6_FILIAL,
                    SC6.C6_NUM, 
                    SUM((SC6.C6_QTDVEN - SC6.C6_QTDENT) * SB1.B1_PESO   )   AS C5_PESOL,
                    SUM((SC6.C6_QTDVEN - SC6.C6_QTDENT) * SB1.B1_PESBRU )   AS C5_PBRUTO
        FROM      	%Table:SC6% SC6
        INNER JOIN  %Table:SC5% SC5
            ON          SC5.C5_NUM = SC6.C6_NUM
        INNER JOIN  %Table:SB1% SB1
            ON          SB1.B1_COD = SC6.C6_PRODUTO
        WHERE       C5_EMISSAO >= '20220401'
            AND         	SC6.%NotDel%
            AND         	SC5.%NotDel%
            AND         	SB1.%NotDel%
            AND         	SB1.B1_MSBLQL <> '1'
            AND             SC5.C5_FILIAL = %Exp:FwFilial("SC5")%
            AND         	SC6.C6_QTDVEN - SC6.C6_QTDENT > 0
        GROUP BY    	SC6.C6_FILIAL, SC6.C6_NUM
        ORDER BY    	SC6.C6_FILIAL, SC6.C6_NUM    

    ENDSQL

    dbSelectArea("SC5")
    dbGoTop()
    DbSetOrder(1)                               // C5_FILIAL + C5_NUM
    While !(cAliasTmp)->(Eof())
        If dbSeek((cAliasTmp)->(C6_FILIAL + C6_NUM))                         
            Reclock("SC5",.F.)
            SC5->C5_PESOL   := (cAliasTmp)->C5_PESOL
            SC5->C5_PBRUTO  := (cAliasTmp)->C5_PBRUTO
            SC5->(msUnlock())
        Endif
        Conout( '[CalcPeleg.PRW] [Thread ' + cValToChar(ThreadID()) + '] [' + FWTimeStamp(2) + '] [Filial : '+ (cAliasTmp)->C6_FILIAL+'] [ Pedido Numero : ' + (cAliasTmp)->C6_NUM + '] [ Peso Liquido : ' + cValToChar((cAliasTmp)->C5_PESOL) + '] [ Peso Bruto  : ' +  cValToChar((cAliasTmp)->C5_PBRUTO) + ']')
        (cAliasTmp)->(dbSkip())
    EndDo

Return()
