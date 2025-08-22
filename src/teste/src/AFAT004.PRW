#include "Totvs.Ch"
#INCLUDE 'FWMVCDEF.CH'

STATIC cZ05CLIENT := ""		// Código do Cliente para pesagem
STATIC cZ05LOJA   := ""		// Código da Loja para pesagem

Static oTable := Nil
Static cAlias := Nil

//-------------------------------------------------
/*/{Protheus.doc} AFAT004
Rotina para digitação do peso dos itens da notas fiscal

@type function
@version 1.0
@author Wagner Mobile Costa

@since 08/11/2021
/*/
//-------------------------------------------------
User Function AFAT004()

Local oBrowse
Local aSeek		:= {}
Local aField	:= {}
Local aBrowse	:= {}
Local nField    := 1
Local cQuery	:= ""
Local cFields   := ""
Local cPicture  := ""
	
	If ! Pergunte("AFAT004")
		Return .F.
	EndIf

	cAlias := GetNextAlias()
	oMark  := FWMarkBrowse():New()
	oTable := FWTemporaryTable():New( cAlias )	

	oBrowse := FWMBrowse():New()

	aAdd( aField, {"F2_FILIAL","C" , Len( SF2->F2_FILIAL ), 0, "Filial" } )
	aAdd( aField, {"F2_SERIE","C" , Len( SF2->F2_SERIE ), 0, "Serie"} )
	aAdd( aField, {"F2_DOC","C" , Len( SF2->F2_DOC ), 0, "Nota Fiscal" } )
	aAdd( aField, {"F2_EMISSAO","D" , 8, 0, "Dt Emissão NF" } )
	aAdd( aField, {"D2_PEDIDO","C" , Len( SD2->D2_PEDIDO ), 0, "Pedido" } )
	aAdd( aField, {"D2_ITEMPV","C" , Len( SD2->D2_ITEMPV ), 0, "Item PV" } )
	aAdd( aField, {"F2_CLIENT","C" , Len( SF2->F2_CLIENT ), 0, "Cliente" } )
	aAdd( aField, {"F2_LOJA","C" , Len( SF2->F2_LOJA ), 0, "Loja" } )
	aAdd( aField, {"A1_NOME","C" , Len( SA1->A1_NOME ), 0, "Razão Social" } )
	aAdd( aField, {"D2_ITEM","C" , Len( SD2->D2_ITEM ), 0, "Item NF" } )
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
		If ! Empty(cFields)
			cFields += ","
		EndIf
		cFields += aField[nField][1] 
	Next

	oTable:SetFields( aField )
	oTable:AddIndex("1", {"F2_FILIAL", "F2_SERIE", "F2_DOC", "D2_ITEM"})
	oTable:AddIndex("2", {"F2_FILIAL", "D2_PEDIDO", "D2_ITEMPV"})
	oTable:Create()

	cQuery := "INSERT INTO "+oTable:GetRealName() + "(" + cFields + ") "
	cQuery += "SELECT " + cFields + " "
	cQuery +=   "FROM " + RetSqlName("SF2") + " SF2 JOIN " + RetSqlName("SD2") + " SD2 ON D2_FILIAL = F2_FILIAL " +;
                 "AND D2_SERIE = F2_SERIE AND D2_DOC = F2_DOC AND SD2.D_E_L_E_T_ = ' ' "
	cQuery +=   "JOIN " + RetSqlName("SC6") + " SC6 ON C6_FILIAL = F2_FILIAL AND C6_NUM = D2_PEDIDO " +;
				 "AND C6_ITEM = D2_ITEMPV AND SC6.D_E_L_E_T_ = ' ' "
	cQuery +=   "JOIN " + RetSqlName("SA1") + " SA1 ON A1_FILIAL = '" + xFilial("SA1") + "' AND A1_COD = F2_CLIENT " +;
				 "AND A1_LOJA = F2_LOJA AND SA1.D_E_L_E_T_ = ' ' "
	cQuery +=  "WHERE F2_FILIAL = '" + xFilial("SF2") + "' " +;
				 "AND F2_EMISSAO BETWEEN '" + Dtos(mv_par01) + "' AND '" + Dtos(mv_par02) + "' " +;
				 "AND F2_CLIENTE BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "' " +;
				 "AND F2_LOJA BETWEEN '" + mv_par05 + "' AND '" + mv_par06 + "' " +;
				 "AND SF2.D_E_L_E_T_ = ' '"

    If (nError := TCSQLExec(cQuery)) <> 0
		_cErro := TCSQLERROR()
		APMsgAlert(AllTrim(_cErro),"erro")
    EndIf
	DbSelectArea(cAlias)

	aAdd(aSeek, {"Filial + Serie + Nota + Item", {{"", "C", 255, 0, "Filial + Serie + Nota + Item",,}} } )
	aAdd(aSeek, {"Filial + Pedido + Item", {{"", "C", 255, 0, "Filial + Pedido + Item",,}} } )

	oBrowse:SetAlias( cAlias )
	oBrowse:SetTemporary( .T. )
	oBrowse:SetFields( aBrowse )
	oBrowse:SetSeek( .T., aSeek )

	oBrowse:SetDescription("Pesagem de Clientes")
	oBrowse:AddLegend( "U_AFAT04LG(1)", "GREEN", "Carga Complementar em Aberto" )
	oBrowse:AddLegend( "U_AFAT04LG(2)", "RED"  , "Carga Complementar Finalizada" )
	oBrowse:AddLegend( "U_AFAT04LG(3)", "BLUE"  , "Remessas Complementares Geradas pela nova Rotina" )
	oBrowse:AddLegend( "C6_XPESO2 = 0 .OR. C6_XPESO3 = 0", "WHITE" , "Registros com PESO 2 e PESO 3 em branco" )
	oBrowse:Activate()

	oTable:Delete()

Return

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Define as operacoes da rotina
@author  Wagner Mobile Costa
@version 1.0
@since 08/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
Static Function MenuDef() as Array
	Local aRotina := {}

    ADD OPTION aRotina TITLE "Pesquisar"	        			ACTION "PesqBrw"            OPERATION 1 ACCESS 0
    ADD OPTION aRotina TITLE "Visualizar" 	        			ACTION "U_AFAT04V()" 		OPERATION 2 ACCESS 0
    ADD OPTION aRotina TITLE "Alterar" 	        				ACTION "U_AFAT04P()" 		OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE "Gerar Pedido Complementar" 		ACTION "U_AFAT04C()" 		OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE "Visualizar Pedido Complementar" 	ACTION "U_AFAT04VC()" 		OPERATION 2 ACCESS 0

Return aRotina

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para alteração do peso do item da nota
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT04V()

Local aFields  := { "C6_FILIAL", "C6_NOTA", "C6_SERIE", "C6_NUM", "C6_ITEM", "C6_CLI", "C6_LOJA", "C6_PRODUTO", "C6_DESCRI",;
					"C6_PRCVEN", "C6_VALOR", "C6_TES", "C6_LOCAL", "C6_QTDVEN", "C6_XPESO2", "C6_XPESO3", "C6_XDIFPES",;
					"C6_XPERDIF" }

	SC6->(DbSetOrder(1))
	SC6->(DbSeek((cAlias)->F2_FILIAL + (cAlias)->D2_PEDIDO + (cAlias)->D2_ITEMPV))

	cCadastro := "Peso do Pedido [" + SC6->C6_NUM + "] - Item: " + SC6->C6_ITEM + " - Filial: " + SC6->C6_FILIAL
	AxVisual("SC6", SC6->(Recno()), 2, aFields)

Return


//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para alteração do peso do item da nota
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT04P()

Local aFields  := { "C6_FILIAL", "C6_NOTA", "C6_SERIE", "C6_NUM", "C6_ITEM", "C6_CLI", "C6_LOJA", "C6_PRODUTO", "C6_DESCRI",;
					"C6_PRCVEN", "C6_VALOR", "C6_TES", "C6_LOCAL", "C6_QTDVEN", "C6_XPESO2", "C6_XPESO3", "C6_XDIFPES",;
					"C6_XPERDIF" }

	SC6->(DbSetOrder(1))
	SC6->(DbSeek((cAlias)->F2_FILIAL + (cAlias)->D2_PEDIDO + (cAlias)->D2_ITEMPV))

	If U_AFAT04LG(3)
		APMsgAlert("Nota do tipo pedido de complementar não tem peso informado !","Pedido Complementar")
		Return .F.
	EndIf

	Z06->(DbSetOrder(2))
	If Z06->(MsSeek(xFilial("Z06") + SC6->(C6_FILIAL + C6_NUM + C6_ITEM)))
		APMsgAlert("Item já vinculado a um processo de pedido complementar. Não pode mais ser editado !","Pedido Complementar")
	Else
		cCadastro := "Peso do Pedido [" + SC6->C6_NUM + "] - Item: " + SC6->C6_ITEM + " - Filial: " + SC6->C6_FILIAL
		AxAltera("SC6", SC6->(Recno()), 4, aFields, { "C6_XPESO2", "C6_XPESO3" })

		RecLock(cAlias, .F.)
		(cAlias)->C6_XPESO2  := SC6->C6_XPESO2
		(cAlias)->C6_XPESO3  := SC6->C6_XPESO3
		(cAlias)->C6_XDIFPES := SC6->C6_XDIFPES
		(cAlias)->C6_XPERDIF := SC6->C6_XPERDIF
		(cAlias)->(MsUnlock())
	EndIf

Return

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para geração de pedido complementar
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT04C()

	cZ05CLIENT := (cAlias)->F2_CLIENT
	cZ05LOJA   := (cAlias)->F2_LOJA
	FWExecView("Geração Pedido Complementar", "AFAT005", 3, , {|| .T.}) 	

	cZ05CLIENT := ""
	cZ05LOJA   := ""

Return

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para geração de pedido complementar
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT04VC()

	Z06->(DbSetOrder(2))
	If 	Z06->(MsSeek(xFilial("Z06") + (cAlias)->F2_FILIAL + (cAlias)->D2_PEDIDO + (cAlias)->D2_ITEMPV)) .And.;
		Z05->(MsSeek(xFilial("Z05") + Z06->Z06_ID))
		M->Z05_ID := Z06->Z06_ID
		FWExecView("Visualização Pedido Complementar", "AFAT005", 1, , {|| .T.}) 	
	Else
		APMsgAlert("Pedido complementar não localizado !","Pedido Complementar")
	EndIf

Return


//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para retorno da legenda
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT04LG(nTipo)

Local lRet := .F.

	If nTipo = 1
		Z06->(DbSetOrder(2))
		lRet := ((cAlias)->C6_XPESO2 > 0 .And. (cAlias)->C6_XPESO3 > 0)
		If Z06->(MsSeek(xFilial("Z06") + (cAlias)->F2_FILIAL + (cAlias)->D2_PEDIDO + (cAlias)->D2_ITEMPV)) .And.;
		   Z05->(MsSeek(xFilial("Z05") + Z06->Z06_ID)) .AND. Z05->Z05_STATUS == "2"
			lRet := .F.
		EndIf
		Z06->(DbSetOrder(1))
	ElseIf nTipo = 2
		Z06->(DbSetOrder(2))
		lRet := ((cAlias)->C6_XPESO2 > 0 .And. (cAlias)->C6_XPESO3 > 0) .And.;
				Z06->(MsSeek(xFilial("Z06") + (cAlias)->F2_FILIAL + (cAlias)->D2_PEDIDO + (cAlias)->D2_ITEMPV)) .And.;
				Z05->(MsSeek(xFilial("Z05") + Z06->Z06_ID)) .AND. Z05->Z05_STATUS == "2"
		Z06->(DbSetOrder(1))
	ElseIf nTipo = 3
		SC5->(DbSetOrder(1))
		lRet := SC5->(MsSeek((cAlias)->F2_FILIAL + (cAlias)->D2_PEDIDO)) .And. AllTrim(SC5->C5_ORIGEM) == "AFAT005"
	EndIf

Return lRet

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Inicialização do campo Z05_CLIENT
@author  	Wagner Mobile Costa
@version 	P12
@since   	08/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT04CL()

	Return cZ05CLIENT

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Inicialização do campo Z05_LOJA
@author  	Wagner Mobile Costa
@version 	P12
@since   	08/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT04LJ()

	Return cZ05LOJA
