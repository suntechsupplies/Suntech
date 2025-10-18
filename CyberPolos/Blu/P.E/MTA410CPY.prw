#include 'protheus.ch'
#include 'parmtype.ch'

User Function MT410CPY()

    Local AreaSC5 := SC5->(GetArea())
    Local aArea   := GetArea()

    //Na copia de um pedido limpo os campos referente a customização do portal da Blu.
    M->C5_XNUMBLU := ""
    M->C5_XIDBLU  := ""
    M->C5_XLOGLIB := ""

    RestArea(AreaSC5)
    RestArea(aArea)

Return
