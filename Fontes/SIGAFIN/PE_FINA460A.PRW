#include "Totvs.CH"
/*-------------------------------------------------------------------
{Protheus.doc} FINA460A
Rotina apos a criação dos titulos novos pela liquidação
@author  Carlos Eduardo Saturnino
@since   08/04/2021
@version 1.0
-------------------------------------------------------------------*/
User Function FINA460A()
	Local nFor
	Local aParam := PARAMIXB
	Local xRet := .T.
	Local oObj := ''
	Local cIdPonto := ''
	Local cIdModel := ''
	
	If aParam <> NIL
		oObj := aParam[1]
		cIdPonto := aParam[2]
		cIdModel := aParam[3]

		If cIdPonto == "MODELVLDACTIVE"
			PUBLIC AxTit1 := {}
			PUBLIC AxTit2 := {}
		elseif cIdPonto == 'FORMLINEPOS' .and. cIdModel == "TITSELFO1"
			IF LEN(OOBJ:ADATAMODEL) > 0
				fOR nFor := 1 to len(OOBJ:ADATAMODEL)
					if len(OOBJ:ADATAMODEL[nFor][1][1]) > 21
						if OOBJ:ADATAMODEL[nFor][1][1][21] 
							SE1->(dbsetorder(1))
							IF SE1->(DBSEEK(xFilial("SE1")+OOBJ:ADATAMODEL[nFor][1][1][22]+OOBJ:ADATAMODEL[nFor][1][1][23]+OOBJ:ADATAMODEL[nFor][1][1][24]+OOBJ:ADATAMODEL[nFor][1][1][25]+OOBJ:ADATAMODEL[nFor][1][1][27]+OOBJ:ADATAMODEL[nFor][1][1][28]))
								if ASCAN(AxTit1,{|X| X[2] == SE1->(RECNO()) }) == 0 
									aadd(AxTit1,{1,SE1->(RECNO())})
								endif
							ENDIF
						endif
					endif
				Next nFor
			ENDIF
		elseif cIdPonto == 'FORMPOS' .AND.  cIdModel == "TITGERFO2"
			IF LEN(OOBJ:ADATAMODEL) > 0
				fOR nFor := 1 to len(OOBJ:ADATAMODEL)
					if len(OOBJ:ADATAMODEL[nFor][1][1]) > 20
						if ASCAN(AxTit2,{|X| X[1] == xfilial("SE1") .AND. X[2] == OOBJ:ADATAMODEL[nFor][1][1][5] .AND. X[3] == OOBJ:ADATAMODEL[nFor][1][1][6] .AND. X[4] == OOBJ:ADATAMODEL[nFor][1][1][7] .AND. X[5] == OOBJ:ADATAMODEL[nFor][1][1][20] .AND. X[6] == SE1->E1_CLIENTE .AND. X[7] == SE1->E1_LOJA  }) == 0
							aadd(AxTit2,{xfilial("SE1"),;
							OOBJ:ADATAMODEL[nFor][1][1][5],;
							OOBJ:ADATAMODEL[nFor][1][1][6],;
							OOBJ:ADATAMODEL[nFor][1][1][7],;
							OOBJ:ADATAMODEL[nFor][1][1][20],;
							SE1->E1_CLIENTE,;
							SE1->E1_LOJA})
						endif
					endif
				Next nFor
			ENDIF
		ELSEIF cIdPonto == 'MODELCOMMITNTTS'
			if len(AxTit1)>0 .AND.  len(AxTit2)>0
				nPos1 := ascan(AxTit1,{|x| x[1] == 1})
				IF nPos1 > 0
					SE1->(DBGOTO(AxTit1[nPos1][2]))
					cVnd1	:= SE1->E1_VEND1
					cVnd2	:= SE1->E1_VEND2
					cVnd3	:= SE1->E1_VEND3
					cVnd4	:= SE1->E1_VEND4
					cVnd5	:= SE1->E1_VEND5
					nCom1	:= SE1->E1_COMIS1
					nCom2	:= SE1->E1_COMIS2
					nCom3	:= SE1->E1_COMIS3
					nCom4	:= SE1->E1_COMIS4
					nCom5	:= SE1->E1_COMIS5
					FOR nFor := 1 to len(AxTit2)
						IF SE1->(DBSEEK(AxTit2[nFor][1]+AxTit2[nFor][2]+AxTit2[nFor][3]+AxTit2[nFor][4]+AxTit2[nFor][5]+AxTit2[nFor][6]+AxTit2[nFor][7]))
							reclock("SE1",.F.)
							SE1->E1_VEND1		:= cVnd1
							SE1->E1_VEND2		:= cVnd2
							SE1->E1_VEND3		:= cVnd3
							SE1->E1_VEND4		:= cVnd4
							SE1->E1_VEND5		:= cVnd5
							SE1->E1_COMIS1		:= nCom1
							SE1->E1_COMIS2		:= nCom2
							SE1->E1_COMIS3		:= nCom3
							SE1->E1_COMIS4		:= nCom4
							SE1->E1_COMIS5		:= nCom5
							MsUnlock()
						ENDIF
					next nFor
				ENDIF
			endif
		EndIf
	EndIf

Return xRet
