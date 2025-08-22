#INCLUDE 'TOTVS.CH'
#INCLUDE 'FWMVCDEF.CH'

Static oDlg   := Nil
Static oTable := Nil
Static cAlias := Nil
Static oMark  := Nil

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para seleção dos itens para pesagem de clientes
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT007(oOwner)

Local aSeek		:= {}
Local aField	:= {}
Local aBrowse	:= {}
Local nField    := 1
Local cQuery	:= ""
Local cFields   := ""
Local cPicture  := ""

	cAlias := GetNextAlias()
	oMark  := FWMarkBrowse():New()
	oTable := FWTemporaryTable():New( cAlias )	
	oDlg   := oOwner

	aAdd( aField, {"F2_OK","C" , 2, 0, ""} )
	aAdd( aField, {"F2_FILIAL","C" , Len( SF2->F2_FILIAL ), 0, "Filial" } )
	aAdd( aField, {"F2_SERIE","C" , Len( SF2->F2_SERIE ), 0, "Serie"} )
	aAdd( aField, {"F2_DOC","C" , Len( SF2->F2_DOC ), 0, "Nota Fiscal" } )
	aAdd( aField, {"D2_PEDIDO","C" , Len( SD2->D2_PEDIDO ), 0, "Pedido" } )
	aAdd( aField, {"D2_ITEMPV","C" , Len( SD2->D2_ITEMPV ), 0, "Item PV" } )
	aAdd( aField, {"F2_CLIENT","C" , Len( SF2->F2_CLIENT ), 0, "Cliente" } )
	aAdd( aField, {"F2_LOJA","C" , Len( SF2->F2_LOJA ), 0, "Loja" } )
	aAdd( aField, {"D2_COD","C" , Len( SD2->D2_COD ), 0, "Produto" } )
	aAdd( aField, {"C6_DESCRI","C" , Len( SC6->C6_DESCRI ), 0, "Descrição" } )
	aAdd( aField, {"D2_PRCVEN","N" , TAMSX3("D2_PRCVEN")[1], TAMSX3("D2_PRCVEN")[2], "Preço Unitário", PesqPict("SD2","D2_PRCVEN") } )
	aAdd( aField, {"D2_TOTAL","N" , TAMSX3("D2_TOTAL")[1], TAMSX3("D2_TOTAL")[2], "Valor Total", PesqPict("SD2","D2_TOTAL") } )
	aAdd( aField, {"D2_TES","C" , Len( SD2->D2_TES ), 0, "T.E.S" } )
	aAdd( aField, {"D2_LOCAL","C" , Len( SD2->D2_LOCAL ), 0, "Armazém" } )
	aAdd( aField, {"D2_QUANT","N" , TAMSX3("D2_QUANT")[1], TAMSX3("D2_QUANT")[2], "Quantidade NF", PesqPict("SD2","D2_QUANT") } )
	aAdd( aField, {"C6_XPESO2","N" , TAMSX3("C6_XPESO2")[1], TAMSX3("C6_XPESO2")[2], "Peso 2", PesqPict("SC6","C6_XPESO2") } )
	aAdd( aField, {"C6_XPESO3","N" , TAMSX3("C6_XPESO3")[1], TAMSX3("C6_XPESO3")[2], "Peso 3", PesqPict("SC6","C6_XPESO3") } )
	aAdd( aField, {"C6_XDIFPES","N" , TAMSX3("C6_XDIFPES")[1], TAMSX3("C6_XDIFPES")[2], "Dif Peso", PesqPict("SC6","C6_XDIFPES") } )
	aAdd( aField, {"C6_XPERDIF","N" , TAMSX3("C6_XPERDIF")[1], TAMSX3("C6_XPERDIF")[2], "", PesqPict("SC6","C6_XPERDIF") } )

	For nField := 1 To Len(aField)
		cPicture := "@!"
		If Len(aField[nField]) > 5
			cPicture := aField[nField][6]
		EndIf
		If ! Empty(aField[nField][5])
			aAdd( aBrowse, { aField[nField][5], aField[nField][1], aField[nField][2], aField[nField][3], aField[nField][4], cPicture })
		EndIf
		If aField[nField][1] <> "F2_OK"
			If ! Empty(cFields)
				cFields += ","
			EndIf
			cFields += aField[nField][1] 
		EndIf
	Next

	oTable:SetFields( aField )
	oTable:AddIndex("1", {"F2_FILIAL", "F2_SERIE", "F2_DOC", "D2_ITEMPV"})
	oTable:Create()

	cQuery := "INSERT INTO "+oTable:GetRealName() + "(" + cFields + ") "
	cQuery += "SELECT " + cFields + " "
	cQuery +=   "FROM " + RetSqlName("SF2") + " SF2 JOIN " + RetSqlName("SD2") + " SD2 ON D2_FILIAL = F2_FILIAL " +;
                 "AND D2_SERIE = F2_SERIE AND D2_DOC = F2_DOC AND SD2.D_E_L_E_T_ = ' ' "
	cQuery +=   "JOIN " + RetSqlName("SC6") + " SC6 ON C6_FILIAL = F2_FILIAL AND C6_NUM = D2_PEDIDO " +;
				 "AND C6_ITEM = D2_ITEMPV AND C6_XPESO2 > 0 AND C6_XPESO3 > 0 AND SC6.D_E_L_E_T_ = ' ' "
	cQuery +=   "JOIN " + RetSqlName("SC5") + " SC5 ON C5_FILIAL = F2_FILIAL AND C5_NUM = D2_PEDIDO AND C5_TIPO = 'N' " +;
				 "AND C5_ORIGEM <> 'AFAT005' AND SC5.D_E_L_E_T_ = ' ' "
	cQuery +=   "LEFT JOIN " + RetSqlName("Z06") + " Z06 ON Z06_FILIAL = '" + xFilial("Z06") + "' AND Z06_FILPED = F2_FILIAL " +;
				 "AND Z06_NUMSC5 = D2_PEDIDO AND Z06_ITMSC5 = D2_ITEMPV AND Z06.D_E_L_E_T_ = ' ' "
	cQuery +=  "WHERE F2_FILIAL = '" + xFilial("SF2") + "' AND F2_CLIENTE = '" + FWFLDGET('Z05_CLIENT') + "' " +;
				 "AND F2_LOJA = '" + FWFLDGET('Z05_LOJA') + "' " +;
				 "AND F2_EMISSAO BETWEEN '" + Dtos(mv_par01) + "' AND '" + Dtos(mv_par02) + "' " +;
				 "AND SF2.D_E_L_E_T_ = ' ' AND Z06.Z06_ID IS NULL "

    If (nError := TCSQLExec(cQuery)) <> 0
		_cErro := TCSQLERROR()
		APMsgAlert(AllTrim(_cErro),"erro")
    EndIf
	DbSelectArea(cAlias)

	aAdd(aSeek, {"Filial + Serie + Nota + Item", {{"", "C", 255, 0, "Filial + Serie + Nota + Item",,}} } )

	oMark:SetOwner(oOwner)
	oMark:SetAlias( cAlias )
	oMark:SetTemporary( .T. )
	oMark:SetDescription( "Itens para Pesagem" )
	oMark:SetFieldMark( "F2_OK" )
	oMark:SetFields( aBrowse )
	oMark:SetSeek( .T., aSeek )
	oMark:SetMenuDef("AFAT007")

	oMark:Activate()
Return

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
			Define as operacoes da aplicacao
@author  	Wagner Mobile Costa
@version 	P12
@since   	29/09/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
Static Function MenuDef()
	Local aRotina := {}

    ADD OPTION aRotina TITLE "Pesquisar"	        ACTION "PesqBrw"             	OPERATION 1 ACCESS 0
    ADD OPTION aRotina TITLE "Confirmar" 	        ACTION "U_AFAT007S()" 			OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE "Cancelar"    	        ACTION "U_AFAT007C()"			OPERATION 3 ACCESS 0

Return aRotina

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para fechamento da tela seleção dos itens para pesagem de clientes
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT007S()

	If cAlias <> Nil
		DbSelectArea(cAlias)
		DbGoTop()
		While ! Eof()
			If oMark:IsMark()
				RecLock("Z06", .T.)
				Z06->Z06_FILIAL := xFilial("Z06")
				Z06->Z06_ID := FWFLDGET('Z05_ID')
				Z06->Z06_FILPED := (cAlias)->F2_FILIAL
				Z06->Z06_NUMSC5 := (cAlias)->D2_PEDIDO
				Z06->Z06_ITMSC5 := (cAlias)->D2_ITEMPV
				Z06->Z06_PESO1 := (cAlias)->D2_QUANT
				Z06->Z06_PESO2 := (cAlias)->C6_XPESO2
				Z06->Z06_PESO3 := (cAlias)->C6_XPESO3
				Z06->Z06_DIFPES := (cAlias)->C6_XDIFPES
				Z06->Z06_DIFPER := (cAlias)->C6_XPERDIF
				Z06->(MsUnLock())
			EndIf
	
			DbSelectArea(cAlias)
			DbSkip()
		EndDo
		
		U_AFAT006T()
EndIf

	oDlg:End()
	
Return

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para fechamento da tela seleção dos itens para pesagem de clientes
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT007C()

	oDlg:End()
	
Return

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para deleção da tabela temporária
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT07DT()

	If oTable <> Nil
		oTable:Delete()
	EndIf

Return
