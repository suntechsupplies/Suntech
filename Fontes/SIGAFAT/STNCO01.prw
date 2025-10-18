#include 'protheus.ch'
#INCLUDE "FWMBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "topconn.ch"

user function STNCO01()
	Local aArea			:= GetArea()
	Local aParBox		:= {} 
	Local cPerg			:= "STNCO01"
	Local aRet			:= {}
	
	aAdd(aParBox,{1,"Vendedor"       ,Space(TAMSX3("A3_COD")[1])    ,"","","SA3","", 6, .T.        })
	aAdd(aParBox,{1,"Emissão de:    ",StoD(" / / ")                 ,""         ,"","",""   ,50,.T.})
	aAdd(aParBox,{1,"Emissão Até:   ",StoD(" / / ")                 ,""         ,"","",""   ,50,.T.})
	aAdd(aParBox,{1,"% Alt.Comissão:",0                             ,"@E 999.99","","",""   ,20,.T.})
	
	If ParamBox(aParBox ,"Manutenção de Comissao",@aRet, , , , , , , cPerg, .T., .T.)
   		monta_tela()
	endif

	RestArea(aArea)

return

static function CAR_DADOS()
    Local cQuery

    if Select("TRC") > 0
        dbSelectArea("TRC")
        TRC->(dbCloseArea())
    endif

    cQuery := " SELECT E3.E3_FILIAL, "
    cQuery += "       E3.E3_VEND, " 
    cQuery += "       E3.E3_EMISSAO, "
    cQuery += "       E3.E3_DATA, "
    cQuery += "       E3.E3_COMIS, "
    cQuery += "       E3.E3_BASE, "
    cQuery += "       E3.E3_PORC, "
    cQuery += "       E3_CODCLI, "
    cQuery += "       E3_LOJA, "
    cQuery += "       E3_PREFIXO, "
    cQuery += "       E3_NUM, "
    cQuery += "       E3_PARCELA, "
    cQuery += "       E3_TIPO, "
    cQuery += "       E3_SEQ "
    cQuery += " FROM " + RetSQLName("SE3") + " E3"
    cQuery += " WHERE E3.E3_VEND = '" + MV_PAR01 + "'"
    cQuery += " AND E3.E3_EMISSAO BETWEEN " + dtos(MV_PAR02)  + " AND " + dtos(MV_PAR03)
    cQuery += " AND E3.E3_DATA = ''" 
    cQuery += " AND E3.D_E_L_E_T_ = ' '"
    
    TcQuery ChangeQuery(cQuery) New Alias "TRC"

return


user function calcula()

    Local nCom      := 0
    Local nAtual    := 0
    Local nTotal    := 0

    Private lExec := .F.

    //Conta quantos registros existem, e seta no tamanho da régua - Carlos Eduardo Saturnino em 21/02/2022
    Count To nTotal

	dbSelectArea("TRC")
	TRC->(dbGoTop())
	
	if lExec
		msgAlert("Este Cálculo já foi executado !!", "Atenção")
		TRC->(dbCloseArea())
		return
	endif
	
	while !TRC->(eof())
        
        // Incrementa contador - Carlos Eduardo Saturnino em 21/02/2022
        nAtual++

        // Incrementa mensagem da régua de processamento - Carlos Eduardo Saturnino em 21/02/2022
        MsProcTxt("Atualizando registro " + cValToChar(nAtual) + " de " + cValToChar(nTotal) + "...")
		
        dbSelectArea("SE3")
		SE3->(dbSetOrder(3))    // E3_FILIAL+E3_VEND+E3_CODCLI+E3_LOJA+E3_PREFIXO+E3_NUM+E3_PARCELA+E3_TIPO+E3_SEQ
		SE3->(dbGoTop())

        If MV_PAR04 > 0 	
            while !SE3->(eof())
            //--------------------------------------------------------------------------------
            // Alterado por Carlos Eduardo Saturnino em 21/02/2022
            // Substituindo o IF condicional pelo dbSeek com a finalidade de diminuir o tempo
            // de gravação da rotina
            //--------------------------------------------------------------------------------
                /*
                
                if TRC->E3_FILIAL = SE3->E3_FILIAL .AND. TRC->E3_VEND = SE3->E3_VEND .AND. ;
                (SE3->E3_EMISSAO >= MV_PAR02 .OR. SE3->E3_EMISSAO <= MV_PAR03) .AND. STOD(TRC->E3_DATA) = SE3->E3_DATA
                if MV_PAR04 > 0 
                    nCom := SE3->E3_BASE * (MV_PAR04 / 100 )
                    RecLock("SE3",.F.)
                    SE3->E3_COMIS    := nCom
                    SE3->E3_PORC     := MV_PAR04
                    SE3->(MsUnlock())
                endif    

                */
                
                IF dbSeek(TRC->(E3_FILIAL + E3_VEND + E3_CODCLI + E3_LOJA + E3_PREFIXO + E3_NUM + E3_PARCELA + E3_TIPO + E3_SEQ)) .And. ( SE3->E3_EMISSAO >= MV_PAR02 .And. SE3->E3_EMISSAO <= MV_PAR03 )
                    nCom := SE3->E3_BASE * (MV_PAR04 / 100 )
                    If RecLock("SE3",.F.)
                        SE3->E3_COMIS    := nCom
                        SE3->E3_PORC     := MV_PAR04
                        SE3->(MsUnlock())
                    Endif
                Endif                
                
                TRC->(dbSkip())

            end

        Else
            msgAlert("Percentual de Comissão não preenchido. Cálculo não realizado !!!")
        Endif

	end

	TRB->(dbGoTop())
    
    //--------------------------------------------------------------------------------------------
    // Incluido por Carlos Eduardo Saturnino em 22/02/2022
    // Com a finalidade de efetuar o refresh com os dados de update do banco de dados no Browse
    //--------------------------------------------------------------------------------------------
    While ! TRB->(EOF())
        If RecLock("TRB",.F.)
            TRB->TR_POR 	:= MV_PAR04            
            TRB->(msUnlock())
            TRB->(dbSkip())
        Endif
    EndDo
    oBrowse:Refresh(.T.)
    FWAlertSuccess("Cálculo Finalizado", "Rotina de Manutenção de Comissões")
    
    lExec := .T.
	TRC->(dbCloseArea())

return

static function Monta_Tela()
	Local cArqTrb, cIndice1, cIndice2
	Local i
    
    Private oBrowse
	Private aRotina		:= MenuDef()
	Private cCadastro 	:= "Executar alteração das Comissões"
	Private aCampos	:= {}, aSeek := {}, aDados := {}, aValores := {}, aFieFilter := {}
	Private lExec := .F.

	If Select("TRB") > 0
		dbSelectArea("TRB")
		TRB->(dbCloseArea ())
	Endif

	AAdd(aCampos,{"TR_FIL" 	, "C" , 06 , 0})
	AAdd(aCampos,{"TR_VEN"  , "C" , 50 , 0})
	AAdd(aCampos,{"TR_EMI"  , "D" , 10 , 0})
	AAdd(aCampos,{"TR_DAT"  , "D" , 10 , 0})
	AAdd(aCampos,{"TR_COM"  , "N" , 15 , 2})
	AAdd(aCampos,{"TR_BAS"  , "N" , 15 , 2})
	AAdd(aCampos,{"TR_POR"  , "N" ,  6 , 2})

	cArqTrb   := CriaTrab(aCampos,.T.)
	
	cIndice1 := Alltrim(CriaTrab(,.F.))
	cIndice2 := cIndice1

	cIndice1 := Left(cIndice1,5)+Right(cIndice1,2)+"A"
	cIndice2 := Left(cIndice2,5)+Right(cIndice2,2)+"B"

	If File(cIndice1+OrdBagExt())
		FErase(cIndice1+OrdBagExt())
	EndIf

	If File(cIndice2+OrdBagExt())
		FErase(cIndice2+OrdBagExt())
	EndIf

	//Criar e abrir a tabela
	dbUseArea(.T.,,cArqTrb,"TRB",Nil,.F.)
	
	CAR_DADOS()
	
	IndRegua("TRB", cIndice1, "TR_FIL"	,,, "Indice ID...")
	IndRegua("TRB", cIndice2, "TR_VEN",,, "Indice Login...")
	
	dbClearIndex()
	dbSetIndex(cIndice1+OrdBagExt())
	dbSetIndex(cIndice2+OrdBagExt())
	
	while !TRC->(eof())
		aadd(aValores,{ TRC->E3_FILIAL          ,;              // [01]
                        TRC->E3_VEND            ,;              // [02]
                        TRC->E3_EMISSAO         ,;              // [03]
                        TRC->E3_DATA            ,;              // [04]
                        TRC->E3_COMIS           ,;              // [05]
                        TRC->E3_BASE            ,;              // [06]
                        Round(TRC->E3_PORC,2)   })              // [07]
		TRC->(dbSkip())
	end
	
		
	For i:= 1 to len(aValores)
		If RecLock("TRB",.t.)
			TRB->TR_FIL		:= aValores[i,1]            // [01]
			TRB->TR_VEN		:= aValores[i,2]            // [02]
			TRB->TR_EMI  	:= STOD(aValores[i,3])      // [03]
			TRB->TR_DAT 	:= STOD(aValores[i,4])      // [04]
			TRB->TR_COM 	:= aValores[i,5]            // [05]
			TRB->TR_BAS 	:= aValores[i,6]            // [06]
			TRB->TR_POR 	:= aValores[i,7]            // [07]
			MsUnLock()
		Endif
	Next
	dbSelectArea("TRB")
	TRB->(DbGoTop())

	oBrowse := FWmBrowse():New()
	oBrowse:SetAlias( "TRB" )
	oBrowse:SetDescription( cCadastro )
	oBrowse:SetSeek(.T.,aSeek)
	oBrowse:SetTemporary(.T.)
	oBrowse:SetLocate()
	oBrowse:SetUseFilter(.T.)
	oBrowse:SetDBFFilter(.T.)
	oBrowse:SetFilterDefault( "" ) //Exemplo de como inserir um filtro padrão >>> "TR_ST == 'A'"
	oBrowse:SetFieldFilter(aFieFilter)
	oBrowse:DisableDetails()
	
	//Legenda da grade, é obrigatório carregar antes de montar as colunas
	/*oBrowse:AddLegend("TR_ST=='A'","GREEN" 	,"Grupo Administradores")
	oBrowse:AddLegend("TR_ST=='C'","BLUE"  	,"Grupo Contábil")
	oBrowse:AddLegend("TR_ST=='R'","RED"  	,"Grupo RH")*/
	
	//Detalhes das colunas que serão exibidas
	oBrowse:SetColumns(MontaColunas("TR_FIL"	,"Filial"		,01,"@!",0,006,0))
	oBrowse:SetColumns(MontaColunas("TR_VEN"	,"Vendedor"		,02,"@!",1,006,0))
	oBrowse:SetColumns(MontaColunas("TR_EMI"	,"Emissão"		,03,"@!",1,010,0))
	oBrowse:SetColumns(MontaColunas("TR_DAT"	,"Data"			,04,"@!",1,010,0))
	oBrowse:SetColumns(MontaColunas("TR_COM"	,"Comissão"		,05,"@E R$999999999.99",2,15,2))
	oBrowse:SetColumns(MontaColunas("TR_BAS"	,"Base"			,06,"@E R$999999999.99",2,15,2))
	oBrowse:SetColumns(MontaColunas("TR_POR"	,"Porcentagem"	,07,"@E   999999999.99",2,6,2))
    oBrowse:Activate()
   
	If !Empty(cArqTrb)
		Ferase(cArqTrb+GetDBExtension())
		Ferase(cArqTrb+OrdBagExt())
		cArqTrb := ""
		TRB->(DbCloseArea())
		delTabTmp('TRB')
    	dbClearAll()
	Endif

return(Nil)

Static Function MontaColunas(cCampo,cTitulo,nArrData,cPicture,nAlign,nSize,nDecimal)

	Local aColumn
	Local bData 	:= {||}

	Default nAlign 	:= 1
	Default nSize 	:= 20
	Default nDecimal:= 0
	Default nArrData:= 0
	
	If nArrData > 0
		bData := &("{||" + cCampo +"}") //&("{||oBrowse:DataArray[oBrowse:At(),"+STR(nArrData)+"]}")
	EndIf
	
	aColumn := {cTitulo,bData,,cPicture,nAlign,nSize,nDecimal,.F.,{||.T.},.F.,{||.T.},NIL,{||.T.},.F.,.F.,{}}

Return {aColumn}

Static Function MenuDef()
	
	Local aRotina 	:= {}

    //-------------------------------------------------------------------------------------------------------------------------------
    // Cria a regua de processamento Carlos Eduardo Saturnino
    //-------------------------------------------------------------------------------------------------------------------------------
	//AADD(aRotina, {"Calcular"			, "u_calcula()"		, 0, 3, 0, Nil })
    AADD(aRotina, {"Calcular"			, 'MsAguarde({|| U_calcula()}, "Aguarde...", "Processando Registros...")'		, 0, 3, 0, Nil })

	
Return( aRotina )
