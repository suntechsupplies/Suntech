#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'
#include 'rwmake.ch'

/*/{Protheus.doc} 
	@author Anderson | Cyberpolos
	@since 09/12/2019
	@version 1.0  |  P12 
	@obs Cliente HB
	@description   GERAR LINK DA TRANSPORTADORA CORRETA
	campo F2_XTRACKI 
	@type function
/*/

//** FUNCAO CHAMADA  PELO PONTO DE ENTRADA "M460FIM()" 

User Function CPTRASF2()

	Local _cDocx 	:= PARAMIXB[1]
	Local _cSerie 	:= PARAMIXB[2]
	//Local _cCnpj 	:= SM0->M0_CGC  //Se for cnpj corrente = SM0->M0_CGC	

	//TRANSPORTADORAS AUTORIZADAS 
	cXtransp	:= AllTrim(SuperGetMv("CP_XTRANSP",.F.,""))
	_clink1 	:= ''

	DbSelectArea("SA4")
	DbSetOrder(1)

	// transportadora cadastrada e autorizada
	If SA4->A4_COD = SF2->F2_TRANSP .AND. SA4->A4_COD $ cXtransp
		//Valida qual translink da transportadora
		DO CASE
			//TRANSPORTADORA BRASSPRESS
		CASE AllTrim(SA4->A4_COD) == "T00028"
			//_clink1 := "https://www.braspress.com.br/site/w/tracking/search?cnpj="+_cCnpj+"&documentType=NOTAFISCAL&numero="+Alltrim(cValToChar(Val(_cDocx)))
			_clink1 := "https://b2b.hb.com.br/tracking/nf/" + Alltrim(_cDocx) + "/" + Alltrim(_cSerie)

			//TRANSPORTADORA TNT BRASIL (FEDEX) LTDA
		CASE AllTrim(SA4->A4_COD) == "T00002" //Início - Suntech (Ricardo Araujo)
			//tratar api -
			//_clink1 :="https://radar.tntbrasil.com.br/radar/public/eventoNotaFiscalCliente/"+_cCnpj+"/"+Alltrim(cValToChar(Val(_cDocx)))+"-"+zTiraZeros(_cSerie)
			_clink1 := "https://b2b.hb.com.br/tracking/nf/" + Alltrim(_cDocx) + "/" + Alltrim(_cSerie)
			// Fim - Suntech (Ricardo Araujo)

			//TRANSPORTADORA MOVVI LOGISTICA LTDA
		CASE AllTrim(SA4->A4_COD) == "T00009" 
			//tratar api -
			//_clink1 :="https://cyberpolos.com.br/rastreador/?cliente="+_cCnpj+"&nota="+Alltrim(cValToChar(Val(_cDocx)))+"&serie="+Alltrim(cValToChar(Val(_cSerie)))
			_clink1 := "https://b2b.hb.com.br/tracking/nf/" + Alltrim(_cDocx) + "/" + Alltrim(_cSerie)
	
				//TRANSPORTADORA JAMEF LOGISTICA LTDA
		CASE AllTrim(SA4->A4_COD) == "T00031" 
			//tratar api -
			//_clink1 :="https://b2b.hb.com.br/tracking/nf/"+Alltrim(_cDocx)+"/"+Alltrim(cValToChar(Val(_cSerie)))
			_clink1 := "https://b2b.hb.com.br/tracking/nf/" + Alltrim(_cDocx) + "/" + Alltrim(_cSerie)
				//TRANSPORTADORA JADLOG LOGISTICA LTDA
		CASE AllTrim(SA4->A4_COD) == "T00034" 
			//tratar api -
			//_clink1 :="https://b2b.hb.com.br/tracking/nf/"+Alltrim(_cDocx)+"/"+Alltrim(cValToChar(Val(_cSerie)))
			_clink1 := "https://b2b.hb.com.br/tracking/nf/" + Alltrim(_cDocx) + "/" + Alltrim(_cSerie)
		OTHERWISE		
		ENDCASE

		DbSelectArea("SF2")
		DbSetOrder(1)
		//grava o link da Transportadora na SF2
		IF DbSeek(xFilial("SF2")+_cDocx+_cSerie)
			If _clink1 <> ''
			RecLock("SF2",.F.)

			SF2->F2_XTRACKI := _clink1
			SF2->F2_XENVML := 'URL'	

			MsUnlock()

			ENDIF
		ENDIF	

	ENDIF

Return

/*/{Protheus.doc} zTiraZeros
Função que tira zeros a esquerda de uma variável caracter
@author Atilio - Implantado por (Ricardo Araujo Suntech)
@since 19/07/2017
@version undefined
@param cTexto, characters, Texto que terá zeros a esquerda retirados
@type function
@example Exemplos abaixo:
    u_zTiraZeros("00000090") //Retorna "90"
    u_zTiraZeros("00000909") //Retorna "909"
    u_zTiraZeros("0000909A") //Retorna "909A"
    u_zTiraZeros("000909AB") //Retorna "909AB"
/*/

static Function zTiraZeros(cTexto)
    
	Local aArea     := GetArea()
    Local cRet      := ""
    Local lContinua := .T.
    Default cTexto  := ""
 
    //Pegando o texto atual
    cRet := Alltrim(cTexto)
 
    //Enquanto existir zeros a esquerda
    While lContinua
        //Se a priemira posição for diferente de 0 ou não existir mais texto de retorno, encerra o laço
        If SubStr(cRet, 1, 1) <> "0" .Or. Len(cRet) ==0
            lContinua := .F.
        EndIf
         
        //Se for continuar o processo, pega da próxima posição até o fim
        If lContinua
            cRet := Substr(cRet, 2, Len(cRet))
        EndIf
    EndDo
     
    RestArea(aArea)

Return cRet
