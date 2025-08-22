#INCLUDE 'TOTVS.CH'
#INCLUDE 'FWMVCDEF.CH'

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para consulta dos itens para pesagem de clientes
@author  	Wagner Mobile Costa
@version 	P12
@since   	04/10/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT006(oOwner)
Local cFilter := ""

    oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('Z06')
	oBrowse:SetOwner(oOwner)

	oBrowse:SetMenuDef("AFAT006")
	oBrowse:DisableDetails()
	IF Type("M->Z05_ID") <> "U"
		oBrowse:AddFilter("FILTRO", cFilter := ("Z06_ID = '" + M->Z05_ID + "'"))
		oBrowse:SetFilterDefault(cFilter)
	Else
		oBrowse:SetTopFun("xFilial('Z06')+FWFLDGET('Z05_ID')")
    	oBrowse:SetBotFun("xFilial('Z06')+FWFLDGET('Z05_ID')")
	EndIF

	oBrowse:Activate()

Return oBrowse


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
    ADD OPTION aRotina TITLE "Selecionar Itens" 	ACTION "U_AFAT006S()" 			OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE "Visualizar" 	        ACTION "VIEWDEF.AFAT006" 		OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE "Alterar"    	        ACTION "U_AFAT006A()" 			OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE "Excluir" 	        	ACTION "U_AFAT006E()" 			OPERATION 5 ACCESS 0

Return aRotina

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
			Contem a Construcao e Definicao do Modelo          
@author  	Wagner Mobile Costa
@version 	P12
@since   	05/10/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
Static Function ModelDef()
	Local oStruPAI := FWFormStruct( 1, 'Z06' )
	Local oModel   := MPFormModel():New('AFATM006',, { |oModel| .T. })
	
	oModel:AddFields( 'MASTER',, oStruPAI)
	oModel:SetDescription("Itens da Pesagem de Clientes")
	oModel:SetPrimaryKey( {} )

    oModel:GetModel('MASTER'):SetDescription("Itens da Pesagem de Clientes")

Return oModel

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
			Construcao da View
@author  	Wagner Mobile Costa
@version 	P12
@since   	13/10/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
Static Function ViewDef()

	Local oModel   	:= FWLoadModel("AFAT006")
    Local oStruPAI 	:= FWFormStruct(2, 'Z06' )
	Local oView

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField('VIEW_MASTER', oStruPAI, 'MASTER')

	oView:CreateHorizontalBox('SUPERIOR', 100)
	OView:SetOwnerView('VIEW_MASTER', 'SUPERIOR')

Return oView

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para alteração do peso do item da nota
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT006A()

Local aFields  := { "C6_FILIAL", "C6_NOTA", "C6_SERIE", "C6_NUM", "C6_ITEM", "C6_CLI", "C6_LOJA", "C6_PRODUTO", "C6_DESCRI",;
					"C6_PRCVEN", "C6_VALOR", "C6_TES", "C6_LOCAL", "C6_QTDVEN", "C6_XPESO2", "C6_XPESO3", "C6_XDIFPES",;
					"C6_XPERDIF" }

	If FWFLDGET('Z05_STATUS') = "2"
		APMsgAlert("O processo já foi encerrado não é permitido alteração de itens","Processo")
		Return .F.
	EndIF

	If SC6->(DbSeek(Z06->Z06_FILPED + Z06->Z06_NUMSC5 + Z06->Z06_ITMSC5))
		cCadastro := "Peso do Pedido [" + Z06->Z06_NUMSC5 + "] - Item: " + Z06->Z06_ITMSC5 + " - Filial: " + Z06->Z06_FILPED
		AxAltera("SC6", SC6->(Recno()), 4, aFields, { "C6_XPESO2", "C6_XPESO3" })

		RecLock("Z06", .F.)
		Z06->Z06_PESO2 := SC6->C6_XPESO2
		Z06->Z06_PESO3 := SC6->C6_XPESO3
		Z06->Z06_DIFPES := SC6->C6_XDIFPES
		Z06->Z06_DIFPER := SC6->C6_XPERDIF
		Z06->(MsUnLock())

		U_AFAT006T()
	Else
		APMsgAlert("Item de pedido [" + Z06->Z06_ITMSC5 + "] não encontrado","Não Encontrado")
	EndIf

Return

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para exclusão do item da nota
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT006E()

	If FWFLDGET('Z05_STATUS') = "2"
		APMsgAlert("O processo já foi encerrado não é permitido exclusão de itens","Processo")
		Return .F.
	EndIF

	FWExecView("Item", "AFAT006", 5, , {|| .T.}) 	
	U_AFAT006T()

Return
//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para atualização da totalização do cabecalho
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT006T

Local oModel	:= FWModelActive()
Local oView    	:= FWViewActive()
Local oModelZ05	:= oModel:GetModel('MASTER')
Local oStru 	:= oModelZ05:GetStruct()
Local aArea		:= GetArea()

	M->Z05_PESO1  := 0
	M->Z05_PESO2  := 0
	M->Z05_PESO3  := 0
	M->Z05_DIFPES := 0

	Z06->(DbSeek(xFilial() + M->Z05_ID))
	While Z06->Z06_FILIAL = xFilial("Z06") .AND. Z06->Z06_ID = M->Z05_ID
		M->Z05_PESO1  += Z06->Z06_PESO1
		M->Z05_PESO2  += Z06->Z06_PESO2
		M->Z05_PESO3  += Z06->Z06_PESO3
		M->Z05_DIFPES += Z06->Z06_DIFPES

		Z06->(DbSkip())
	EndDo

	oStru:SetProperty( 'Z05_PESO1', MODEL_FIELD_WHEN, { || .T. })
	oStru:SetProperty( 'Z05_PESO2', MODEL_FIELD_WHEN, { || .T. })
	oStru:SetProperty( 'Z05_PESO3', MODEL_FIELD_WHEN, { || .T. })
	oStru:SetProperty( 'Z05_DIFPES', MODEL_FIELD_WHEN, { || .T. })
	
	oModelZ05:SetValue("Z05_PESO1", M->Z05_PESO1)
	oModelZ05:SetValue("Z05_PESO2", M->Z05_PESO2)
	oModelZ05:SetValue("Z05_PESO3", M->Z05_PESO3)
	oModelZ05:SetValue("Z05_DIFPES", M->Z05_DIFPES)
	oModel:lModify := .T.

	oStru:SetProperty( 'Z05_PESO1', MODEL_FIELD_WHEN, { || .F. })
	oStru:SetProperty( 'Z05_PESO2', MODEL_FIELD_WHEN, { || .F. })
	oStru:SetProperty( 'Z05_PESO3', MODEL_FIELD_WHEN, { || .F. })
	oStru:SetProperty( 'Z05_DIFPES', MODEL_FIELD_WHEN, { || .F. })
	If oView <> Nil
		oView:Refresh()
		oView:lModify := .T.
	EndIf
	RestArea(aArea)

Return

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para abertura de tela para seleção dos itens para pesagem de clientes
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT006S

Local oDlg   := Nil
Local aCords := Nil

	If FWFLDGET('Z05_STATUS') = "2"
		APMsgAlert("O processo já foi encerrado não é permitido mais a inclusão de itens","Processo")
		Return .F.
	EndIF

	If Empty(FWFLDGET('Z05_CLIENT')) .Or. Empty(FWFLDGET('Z05_LOJA'))
		APMsgAlert("É obrigatório o preenchimento do cliente/loja","Cliente")
		Return .F.
	EndIf

	If ! Pergunte("AFAT006")
		Return .F.
	EndIf
	
	aCords := FWGetDialogSize(oMainWnd)				// Objeto que recebe as cordenadas da Dialog Principal do Protheus.
	oDlg   := MSDialog():New(aCords[1] + 500, aCords[2], aCords[3] + 500, aCords[4], "Seleção de Itens",,,,,CLR_BLACK,CLR_WHITE,,,.T.)

	U_AFAT007(oDlg)
	oDlg:Activate()

	U_AFAT07DT()

Return

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para calculo do peso do item da nota
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT06PS()

	M->C6_XDIFPES := 0
	M->C6_XPERDIF := 0
	If M->C6_XPESO2 > 0 .And. M->C6_XPESO3 > 0
		M->C6_XDIFPES := M->C6_XPESO3 - M->C6_QTDVEN
		M->C6_XPERDIF := M->C6_XPESO3 / M->C6_XPESO2 * 100
		If M->C6_XPERDIF > 0
			M->C6_XPERDIF := Round(-M->C6_XPERDIF + 100, 2)
		EndIf
	EndIf

Return .T.
