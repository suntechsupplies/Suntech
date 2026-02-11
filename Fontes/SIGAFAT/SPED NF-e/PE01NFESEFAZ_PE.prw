#INCLUDE "totvs.ch"
#INCLUDE "parmtype.ch"

#DEFINE TIPO_SAIDA 		"S"
#DEFINE TIPO_ENTRADA 	"E"

/*/{Protheus.doc} MSGNF01

Implementação do ponto de entrada da NFE para buscar as msg da notas da tabela de mensagen

@type function
@author Daniel A Braga
@since 14/07/2017

@history 14/07/2017, Daniel A Braga, Exemplo de implementação da nova função. 

@see Classe FswTemplMsg
/*/
User Function PE01NFESEFAZ()
	Local aArea 	    := Lj7GetArea({"SC5","SC6","SF1","SF2","SD1","SD2","SA1","SA2","SB1","SB5","SF4","SA3"})
	//	Local aParam 	    := PARAMIXB //aProd,cMensCli,cMensFis,aDest,aNota,aInfoItem,aDupl,aTransp,aEntrega,aRetirada,aVeiculo,aNFVinc,aNFVincRur

	Local aProd		  	:= PARAMIXB[1]
	Local cMensCli	  	:= PARAMIXB[2]
	Local cMensFis	  	:= PARAMIXB[3]
	Local aDest 	  	:= PARAMIXB[4]
	Local aNota 	  	:= PARAMIXB[5]
	Local aInfoItem   	:= PARAMIXB[6]
	Local aDupl		  	:= PARAMIXB[7]
	Local aTransp	  	:= PARAMIXB[8]
	Local aEntrega	  	:= PARAMIXB[9]
	Local aRetirada	  	:= PARAMIXB[10]
	Local aVeiculo	  	:= PARAMIXB[11]
	Local aReboque	  	:= PARAMIXB[12]   
	Local aNfVincRur  	:= PARAMIXB[13]
	Local aEspVol     	:= PARAMIXB[14]
	Local aNfVinc	  	:= PARAMIXB[15]
	Local aPIS		  	:= PARAMIXB[16]
	Local aCOFINS	  	:= PARAMIXB[17]
	Local aRetorno	  	:= {}   
	Local cTipo			:= iif(aNota[4] == "1" ,TIPO_SAIDA,TIPO_ENTRADA)
	Local cDocNF 		:= iif(cTipo == TIPO_SAIDA,SF2->F2_DOC     ,SF1->F1_DOC)
	Local cSerieNF		:= iif(cTipo == TIPO_SAIDA,SF2->F2_SERIE   ,SF1->F1_SERIE)
	Local cCodCliFor	:= iif(cTipo == TIPO_SAIDA,SF2->F2_CLIENTE ,SF1->F1_FORNECE)
	Local cLoja			:= iif(cTipo == TIPO_SAIDA,SF2->F2_LOJA    ,SF1->F1_LOJA)
	Local oFswTemplMsg  := FswTemplMsg():TemplMsg(cTipo,cDocNF,cSerieNF,cCodCliFor,cLoja)
	Local _nX
	Local _nQuant		:= 0
	Local _cEndEntr		:= ''

    Local cAliasTmp     := GetNextAlias()
	Local cAliasSC6    	:= GetNextAlias()
    Local aEspecie      := {}
    Local cGuarda       := ""
    Local nReg          := 0
    Local nVolume       := 0
    Local nE, nx, nY

	//Local _Pedido     := SC6->(C6_NUM    + C6_PEDCLI)
	//Local _cEnd		:= SA1->(A1_END    + A1_COMPLEM + A1_BAIRRO 	+ A1_EST	+ A1_MUN  )
	//Local _cEndEnt	:= SA1->(A1_ENDENT + A1_COMPENT + A1_BAIRROE 	+ A1_ESTE 	+ A1_MUNC )
	//						   OK				  OK		   OK			  OK          OK	

	// Efetua a soma da quantidade total de produtos na Nota Fiscal
	For _nX:= 1 to Len(aProd)
		_nQuant += aProd[_nX][09]
	Next _nX

	cMensCli 	:= oFswTemplMsg:getMsgNFE() 
	cMensCli 	+= AllTrim(SF2->F2_MENNOTA) +Chr(13)+Chr(10)

	//------------------------------------------------------------------
	// Insere a quantidade de Itens faturados no documento fiscal
	//------------------------------------------------------------------
	cMensCli	+= Chr(13) + Chr(10) + "Quantidade de Itens neste Docto. Fiscal : " + cValToChar(_nQuant) + iIf(_nQuant > 1," Itens"," Item") + Chr(13) + Chr(10)

	//--------------------------------------------------------------------------------
	// Identifica se o cadastro do Cliente possui endereço de entrega cadastrado
	// e o inclui no box "Informacoes Complementares" caso todos os campos abaixo estejam preenchidos 
	// SA1->(A1_ENDENT + A1_BAIRROE + A1_CEPE + A1_MUNE + A1_ESTE) e Gera a tag <entrega> por solicitação
    // da transportadora Jamef - @ Ricardo Araujo - Suntech - 04/06/2023
	//-------------------------------------------------------------------------------- 
	If !Empty(SA1->A1_ENDENT) .And. !Empty(SA1->A1_BAIRROE) .And. !Empty(SA1->A1_CEPE) .And. !Empty(SA1->A1_MUNE) .And. !Empty(SA1->A1_ESTE)
						
        aadd(aEntrega,SA1->A1_CGC)
		aadd(aEntrega,MyGetEnd(SA1->A1_ENDENT,"SA1")[1])
		aadd(aEntrega,AllTrim(cValToChar(IIF(MyGetEnd(SA1->A1_ENDENT,"SA1")[2]<>0,MyGetEnd(SA1->A1_ENDENT,"SA1")[2],"SN"))))
		aadd(aEntrega,AllTrim(MyGetEnd(SA1->A1_COMPENT,"SA1")[1]))
		aadd(aEntrega,SA1->A1_BAIRROE)
		aadd(aEntrega,SA1->A1_CODMUNE)
		aadd(aEntrega,SA1->A1_MUNE)
		aadd(aEntrega,Upper(SA1->A1_ESTE))
		aadd(aEntrega,SA1->A1_NOME)
		aadd(aEntrega,Iif(!Empty(SA1->A1_INSCR),VldIE(SA1->A1_INSCR,.T.,.F.),""))
		aadd(aEntrega,Alltrim(SA1->A1_CEPE))
		aadd(aEntrega,IIF(Empty(SA1->A1_PAIS),"1058"  ,Posicione("SYA",1,xFilial("SYA")+SA1->A1_PAIS,"YA_SISEXP")))
		aadd(aEntrega,IIF(Empty(SA1->A1_PAIS),"BRASIL",Posicione("SYA",1,xFilial("SYA")+SA1->A1_PAIS,"YA_DESCR" )))
		aadd(aEntrega,FormatTel(Alltrim(AllTrim(SA1->A1_DDD)+SA1->A1_TEL))) 
		aadd(aEntrega,Alltrim(SA1->A1_EMAIL))

        // <CNPJ>32128098000153</CNPJ>
        // <xNome>LOJA DA BRUTALIDADE LTDA</xNome>
        // <xLgr>R. BENEDITO VALADARES</xLgr>
        // <nro>146</nro>
        // <xBairro>CENTRO</xBairro>
        // <cMun>3147105</cMun>
        // <xMun>PARA DE MINAS</xMun>
        // <UF>MG</UF>
        // <CEP>35660630</CEP>
        // <cPais>1058</cPais>
        // <xPais>BRASIL</xPais>
        // <fone>031994804546</fone>
        // <email>comprasbrou@gmail.com</email>
        // <IE>0033267540062</IE>

    EndIf    
    
    //--------------------------------------------------------------------------------
    // Endereço de entrega no box - Informaçãoes complementares
    // @ Ricardo Araujo - Suntech - 04/06/2023
    //--------------------------------------------------------------------------------
    _cEndEntr := RetEndEnt()

	If !Empty(_cEndEntr)
		
		cMensCli += Chr(13) + Chr(10) + _cEndEntr + Chr(13) + Chr(10)

	Endif 


	//-------------------------------------------------
	// @ Ricardo Araujo - Suntech
    // Consulta o numero de pedido do cliente
    //-------------------------------------------------
    BeginSql Alias cAliasSC6

        SELECT		DISTINCT 
					SC6.C6_NUM,
					SC6.C6_PEDCLI
        FROM 		%Table:SC6% SC6
        WHERE		SC6.C6_FILIAL = %Exp:cFilant%
            AND 	SC6.C6_NUM    = %Exp:SC6->C6_NUM%
            AND		SC6.%NotDel%       
    
	EndSql

    //------------------------------------------------------------------------------------
	// @ Ricardo Araujo - Suntech
    // Informações complementares exclusão do frete e demais despesas acessórias da base de cálculo do IPI
    //------------------------------------------------------------------------------------

    cNome  := Alltrim(SA1->A1_NOME)
    cCNPJ  := Alltrim(SA1->A1_CGC)
    cIE    := Alltrim(Iif(!Empty(SA1->A1_INSCR),SA1->A1_INSCR, "ISENTO"))

    cMensCli += Chr(13) + Chr(10) + "O recebimento da(s) presente(s) mercadoria(s) autoriza que a SUNTECH SUPPLIES INDÚSTRIA E COMÉRCIO DE PRODUTOS ÓPTICOS E ESPORTIVOS LTDA (CNPJ nº 04.175.844/0001-24 e CNPJ nº 04.175.844/0003-96) receba, em seu favor, a restituição de eventuais indébitos tributários relacionados ao(s) produto(s) constante(s) da presente nota fiscal, nos termos do art. 166 da Lei nº 5.172/1966 (CTN)." + Chr(13) + Chr(10)


    //------------------------------------------------------------------------------------
	// @ Ricardo Araujo - Suntech
    // Percorre os itens caso exista mais de um pedido de cliente por pedido interno
    //------------------------------------------------------------------------------------
        
	(cAliasSC6)->(dbGoTop())
    While ! (cAliasSC6)->(Eof())
        
		cMensCli += Chr(13) + Chr(10) + "Pedido: " + (cAliasSC6)->C6_NUM + IIF(Empty((cAliasSC6)->C6_PEDCLI),""," Pedido Cliente: " + (cAliasSC6)->C6_PEDCLI)

        (cAliasSC6)->(dbSkip())
    EndDo

	//--------------------------------------------------------------------------------
	// @Author Carlos Eduardo Saturnino - Atlanta Consulting
    // Preenche o array de VOLUME e ESPÉCIE caso o mesmo não esteja preenchido
	//-------------------------------------------------------------------------------- 
    If Len(aEspVol) == 0

        //-------------------------------------------------
        // fecha a query caso a tabela esteja sendo usada
        //-------------------------------------------------
        If Select(cAliasTmp) > 0
            (cAliasTmp)->(dbCloseArea())
        Endif

        //-------------------------------------------------
        // Efetua a consulta no DB
        //-------------------------------------------------
        BeginSql Alias cAliasTmp

            SELECT		COUNT(CB6_TIPVOL)   AS VOLUME,
                        CB3.CB3_DESCRI      AS ESPECIE
            FROM 		%Table:CB6% CB6
            INNER JOIN 	%Table:CB3% CB3
                ON 			CB3.CB3_CODEMB = CB6.CB6_TIPVOL
                AND 		CB3.CB3_FILIAL = CB6.CB6_FILIAL
            WHERE		CB6.CB6_FILIAL = %Exp:cFilant%
                AND 		CB6.CB6_NOTA  = %Exp:SF2->F2_DOC%
                AND         CB6.CB6_SERIE = %Exp:SF2->F2_SERIE%
                AND			CB6.%NotDel%
                AND			CB3.%NotDel%            
            GROUP BY 	CB6_TIPVOL, CB3_DESCRI
        
        EndSql

        //-------------------------------------------------
        // Conta a Quantidade de Registros da Query
        //-------------------------------------------------
        (cAliasTmp)->(dbGoTop())
        While ! (cAliasTmp)->(Eof())
            nReg ++
            (cAliasTmp)->(dbSkip())
        EndDo

        //-------------------------------------------------
        // Preenche volume e espécie 
        //-------------------------------------------------
        (cAliasTmp)->(dbGoTop())
        While ! (cAliasTmp)->(Eof())
            For nY := 1 To nReg
                aadd(aEspecie,iif((cAliasTmp)->(.Not.Eof()),Alltrim((cAliasTmp)->ESPECIE),"Caixas"))
                nVolume += (cAliasTmp)->VOLUME
            Next nY
            (cAliasTmp)->(dbSkip())
        EndDo

        cEsp := ""
        nx 	 := 0
        For nE := 1 To Len(aEspecie)
            If !Empty(aEspecie[nE])
                nx ++
                cEsp := aEspecie[nE]
            EndIf
        Next

        cGuarda := ""
        If nx > 1
            cGuarda := "Diversos"
        Else
            cGuarda := cEsp
        EndIf

        If !Empty(cGuarda)
            aadd(aEspVol,{cGuarda,nVolume,Iif(SF2->F2_PLIQUI>0,SF2->F2_PLIQUI,1),Iif(SF2->F2_PBRUTO>0, SF2->F2_PBRUTO,1),"",""})
        Endif

        //-------------------------------------------------
        // Fecha a consulta
        //-------------------------------------------------
        (cAliasTmp)->(dbCloseArea())

    Endif

    // < Fim do trecho Atlanta Consulting > -----------------------------------------------------------------------------

	//Retorna na Ordem Esperada no Fonte NFESEFAZ
	aAdd(aRetorno , aProd)
	aAdd(aRetorno , cMensCli)
	aAdd(aRetorno , cMensFis)
	aAdd(aRetorno , aDest)
	aAdd(aRetorno , aNota)	
	aAdd(aRetorno , aInfoItem)	
	aAdd(aRetorno , aDupl)
	aAdd(aRetorno , aTransp)
	aAdd(aRetorno , aEntrega)	
	aAdd(aRetorno , aRetirada)	
	aAdd(aRetorno , aVeiculo)
	aAdd(aRetorno , aReboque)		
	aAdd(aRetorno , aNFVincRur)
	aAdd(aRetorno , aEspVol)
	aAdd(aRetorno , aNFVinc)
	aAdd(aRetorno , aPIS)
	aAdd(aRetorno , aCOFINS)

	Lj7RestArea(aArea)  	

Return aRetorno

/*-----------------------------------------------------------------------	
{Protheus.doc} 	RetEndEnt
TODO 			Retorna o Endereço de Entrega (Caso esteja preenchido)
@author 		@ Ricardo Araujo - Suntech
@since 			15/05/2022
@version 		1.0
-----------------------------------------------------------------------*/
Static Function RetEndEnt()

	Private _cRet := '' 

	If !Empty(SA1->A1_ENDENT) .And. !Empty(SA1->A1_BAIRROE) .And. !Empty(SA1->A1_CEPE) .And. !Empty(SA1->A1_MUNE) .And. !Empty(SA1->A1_ESTE)
		_cRet := "Endereço de Entrega.: " + SA1->( Alltrim(A1_ENDENT) + ", " + Alltrim(A1_COMPENT) + " - " + Alltrim(A1_BAIRROE) + " - " + Alltrim(A1_CEPE) + " - " + Alltrim(A1_MUNE) + "/" + Alltrim(A1_ESTE))
	Endif

Return (_cRet)

Static Function MyGetEnd(cEndereco,cAlias)

Local cCmpEndN	:= SubStr(cAlias,2,2)+"_ENDNOT"
Local cCmpEst	:= SubStr(cAlias,2,2)+"_EST"
Local aRet		:= {"",0,"",""}

//Campo ENDNOT indica que endereco participante mao esta no formato <logradouro>, <numero> <complemento>
//Se tiver com 'S' somente o campo de logradouro sera atualizado (numero sera SN)
If (&(cAlias+"->"+cCmpEst) == "DF") .Or. ((cAlias)->(FieldPos(cCmpEndN)) > 0 .And. &(cAlias+"->"+cCmpEndN) == "1")
	aRet[1] := cEndereco
	aRet[3] := "SN"
Else
	aRet := FisGetEnd(cEndereco, (&(cAlias+"->"+cCmpEst)))
EndIf

Return aRet

static function FormatTel(cTel)
	local cRet := ""
	default cTel := SM0->M0_TEL
	cRet := strtran(strtran(strtran(strtran(strtran(cTel, "(", ""), ")", ""), "+", ""), "-", ""), " ", "")
return cRet
