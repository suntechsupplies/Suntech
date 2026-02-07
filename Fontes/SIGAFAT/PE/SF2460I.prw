#INCLUDE "PROTHEUS.CH"

User Function SF2460I()

    Private aArea := GetArea()

    //--------------------------------------------------------------------------------
    // @ Ricardo Araujo - Suntech - 02/02/2026
    // Preenche a data de entrega (F2_DTENTR) com base na data prevista do pedido (C5_FECENT)
    // Se C5_FECENT estiver vazio, usa a data de emissão + 5 dias
    //--------------------------------------------------------------------------------
    If SD2->(DbSetOrder(3), DbSeek(xFilial("SD2") + SF2->F2_DOC + SF2->F2_SERIE))
        
        If !Empty(SD2->D2_PEDIDO)
            
            DbSelectArea("SC5")
            DbSetOrder(1) // C5_FILIAL + C5_NUM
            If DbSeek(xFilial("SC5") + SD2->D2_PEDIDO)
                
                If !Empty(SC5->C5_FECENT) .And. SC5->C5_FECENT >= SF2->F2_EMISSAO
                    RecLock("SF2", .F.)
                        SF2->F2_DTENTR := SC5->C5_FECENT
                    MsUnlock()
                Else
                    RecLock("SF2", .F.)
                        SF2->F2_DTENTR := SF2->F2_EMISSAO + 5
                    MsUnlock()
                EndIf
                
            EndIf
            
        EndIf
        
    EndIf

    RestArea(aArea)

Return()
