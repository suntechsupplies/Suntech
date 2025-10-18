#include 'protheus.ch'

/*/
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  TITICMST  � Autor � Julio              � Data �  25/07/23    ���
�������������������������������������������������������������������������͹��
���Descricao �Altera��o Data Vencimento da GNRE                           ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       �                                                            ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
/*/
//-------------------------------------------------------------------

User Function TITICMST()
 
    Local cOrigem := PARAMIXB[1]
    Local cTipoImp := PARAMIXB[2]
    //Local lDifal := PARAMIXB[3]
  
    If AllTrim(cOrigem) $ 'MATA460A/MATA461/' //Nota fiscal de Saida e Entrada
        SE2->E2_VENCTO  := DataValida(SE2->E2_EMISSAO+1,.T.)
        SE2->E2_VENCREA := DataValida(SE2->E2_EMISSAO+1,.T.)
    ElseIf AllTrim(cOrigem) == 'MATA103'
        SE2->E2_VENCTO  := DataValida(SE2->E2_EMISSAO+1,.T.)
        SE2->E2_VENCREA := DataValida(SE2->E2_EMISSAO+1,.T.)
    EndIf

    
Return {SE2->E2_NUM,SE2->E2_VENCTO}
