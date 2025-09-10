#Include "Totvs.ch"
#INCLUDE "FWMVCDEF.CH"


/*/{Protheus.doc} AEST001
	MVC Separação

	@type User Function
	@author Tiago Cunha
	@since 01/07/2025
	@version 1.0.0
/*/
User Function AEST001()
	Local aArea   := GetArea()
	Local oBrowse := Nil

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZS1")
	oBrowse:SetDescription("Separação e Pesagem")
	oBrowse:SetMenuDef("CUSTOM.AEST001")

	oBrowse:Activate()

	RestArea(aArea)
Return Nil


/*/{Protheus.doc} MenuDef
	Lista de opcoes do menu

	@type  Static Function
	@author Tiago Cunha
	@since 01/07/2025
	@version 1.0.0
	@return array, Lista de opcoes do browser
/*/
Static Function MenuDef()

	Local aRotina := {}

	aAdd(aRotina, {'Ajustes de cor'    , 'VIEWDEF.CUSTOM.AEST001'                        , 0, 3, 0, NIL})
	aAdd(aRotina, {'Separar'           , 'VIEWDEF.CUSTOM.AEST001'              , 0, 4, 0, NIL})
	aAdd(aRotina, {'Estornar Sep'      , 'U_AEST001B()'                   , 0, 4, 0, NIL})
	aAdd(aRotina, {'Priorizar'         , 'U_AEST001A()'                        , 0, 4, 0, NIL})
	aAdd(aRotina, {'Despriorizar'      , 'U_AEST001A("2")'                        , 0, 4, 0, NIL})
	aAdd(aRotina, {'Visualizar'        , 'VIEWDEF.CUSTOM.AEST001'              , 0, 2, 0, NIL})
	aAdd(aRotina, {'Enviar p/ WIP'     , 'U_AEST001C()'                        , 0, 4, 0, NIL})
	aAdd(aRotina, {'Imp. Etq. Sep.'    , 'U_REST001a()'             , 0, 4, 0, NIL})

Return(aRotina)


/*/{Protheus.doc} ModelDef
	Constroi o modelo MVC

	@type  Static Function
	@author Tiago Cunha
	@since 01/07/2025
	@version 1.0.0
	@return Object, Modelo do MVC
/*/
Static Function ModelDef()

	Local oModel
	Local oStrZS1 := FWFormStruct(1,'ZS1')
	Local oStrZS2 := FWFormStruct(1,'ZS2')

	oModel := MPFormModel():New('AEST001_MAIN')
	oModel:SetDescription('Separação e pesagem')

	oModel:addFields('MODEL_ZS1',,oStrZS1)
	oModel:SetPrimaryKey({'ZS1_FILIAL', 'ZS1_NUMREQ'})

	oStrZS2:AddTrigger( 'ZS2_QTDSEP'	,'ZS2_SLDREQ'	, { || .T. } , {|| fAllConcluidos()})
	oStrZS2:AddTrigger( 'ZS2_LOTECT'	,'ZS2_DTVALI'	, { || .T. } , {|| fGetLotVld()})

	oModel:AddGrid("MODEL_ZS2", "MODEL_ZS1", oStrZS2)

	oModel:SetRelation("MODEL_ZS2", {{"ZS2_FILIAL", "ZS1_FILIAL" }, {"ZS2_NUMREQ", "ZS1_NUMREQ"}}, ZS2->(IndexKey(1)))

	oModel:GetModel('MODEL_ZS1'):SetDescription('Separação e pesagem')

Return(oModel)


/*/{Protheus.doc} ViewDef
	Monta o view da tela de cadastro

	@type  Static Function
	@author Tiago Cunha
	@since 01/07/2025
	@version 1.0.0
	@return Object, Modelo do View
/*/
Static Function ViewDef()

	Local oView   := Nil
	Local oModel  := ModelDef()
	Local oStrZS1 := FWFormStruct(2, 'ZS1')
	Local oStrZS2 := FWFormStruct(2, 'ZS2')

	//oStrZS2:SetProperty('FN6_FILORI',MVC_VIEW_CANCHANGE,.F. )
	// oStrLote:RemoveField( 'FN8_DTBAIX' )

	oView := FWFormView():New()
	oView:SetModel(oModel)

	oView:AddField('VIEW_ZS1', oStrZS1, 'MODEL_ZS1')
	oView:AddGrid("VIEW_ZS2",  oStrZS2, "MODEL_ZS2")

	oView:CreateHorizontalBox('BOX_ZS1', 040)
	oView:CreateHorizontalBox('BOX_ZS2', 060)

	oView:SetOwnerView('VIEW_ZS1', 'BOX_ZS1')
	oView:SetOwnerView('VIEW_ZS2', 'BOX_ZS2')

	oView:AddIncrementField('VIEW_ZS2', 'ZS2_ITEM')

	if INCLUI .Or. ALTERA
		oView:SetAfterViewActivate({|oView| loadData(oView, oModel)})
	endif

Return(oView)


Static Function loadData(oView, oModel)
	local nX       := 1
	local nI       := 1
	Local cTecF5   := VK_F5
	Local cTecF6   := VK_F6
	Local cTecF7   := VK_F7
	Local bAcaoF5  := {|| u_aEst001D() }
	Local bAcaoF6  := {|| u_aEst001E() }
	Local bAcaoF7  := {|| u_aEst001F() }

	if ALTERA
		oModelZS1 := oModel:getModel("MODEL_ZS1")
		oModelZS1:SetValue("ZS1_STATUS", "2") // Em Separação

		if oModelZS1:GetValue("ZS1_USRSEP") == ""
			oModelZS1:SetValue("ZS1_USRSEP", RetCodUsr())
			oModelZS1:SetValue("ZS1_DTINSE", dDataBase)
			oModelZS1:SetValue("ZS1_HRINSE", Time())
		endif

		SetKey(cTecF5, bAcaoF5)
		SetKey(cTecF6, bAcaoF6)
		SetKey(cTecF7, bAcaoF7)
	endif

	oModel:getModel("MODEL_ZS2"):SetNoDeleteLine(.T.)
	oModel:getModel("MODEL_ZS2"):SetNoInsertLine(.T.)

	oView:Refresh()
Return


/*/{Protheus.doc} aEst001D
  Função que monta e exibe a tela de pesquisar item por codigo do produto e de barras

  @type user function
  @author Tiago Cunha
  @since 22/07/2025
  @version 1.0.0
/*/
User Function aEst001D()
	Local aArea        := FWGetArea()

	Local oFont1 	     := TFont():New( "Arial", , -13, .T.)

	Local oGroup1
	Local nOpca        := 0
	Local cFontUti     := "Arial"
	Local oFontBtn     := TFont():New(cFontUti,,-14)

	Private cCodBar  := Space(TamSX3('B1_CODBAR')[01])
	Private cCodProd := Space(TamSX3('B1_COD')[01])

	Private oGetCodBar
	Private oGetCodProd

	Private aHeaderGrid := {}
	Private aColsGrid   := {}
	Private oDlg

	DEFINE MSDIALOG oDlg TITLE "Localizar Item" FROM 000, 000  TO 100, 590 COLORS 0, 16777215 PIXEL

	@ /*025*/10, 010 SAY "Código de Barras:" 	 			SIZE 065, 010 OF oDlg FONT oFont1 PIXEL
	@ /*025*/10, 150 SAY "Código do Produto:" 	 				SIZE 065, 010 OF oDlg FONT oFont1 PIXEL

	@ /*025*/8, 065 MSGET oGetCodBar  VAR cCodBar  SIZE 075, 010 OF oDlg COLORS 0, 16777215  PIXEL
	oGetCodBar:bChange := {|| fgetProdCodBar(@cCodBar, @cCodProd) }
	oGetCodBar:SetFocus()

	@ /*025*/8, 212 MSGET oGetCodProd VAR cCodProd	SIZE 075, 010 OF oDlg F3 "SB1" COLORS 0, 16777215  PIXEL

	oBtnConfim := TButton():New( 28, 245, "Pesquisar", oDlg, { || MsgRun("Procurando Item...","Aguarde..." , {|| seekZS2(@cCodProd, oDlg) } ) }, 40,10,/*uParam8*/,/*oFont*/,/*uparam10*/.F.,/*lpixel*/.T.,/*uparam12*/.F.,/*uparam13*/,/*uparam14*/.F., /*bWhen*/,,.F. )

	ACTIVATE MSDIALOG oDlg CENTERED

	FWRestArea(aArea)
Return


Static Function fgetProdCodBar(cCodBar, cCodProd)
	_cCodProd := Posicione("SB1",5,xFilial("SB1")+ cCodBar,"B1_COD")

	if !Empty(_cCodProd) .And. !Empty(cCodBar)
		cCodProd := AllTrim(_cCodProd)
	else
		FWAlertWarning("Não foi possível localizar o produto com o código de barras informado!", "Atenção")
		cCodBar   := space(TamSX3('B1_CODBAR')[01])
		cCodProd  := space(TamSX3('B1_COD')[01])
	endif
Return

static function seekZS2(cCodProd, oDlg)
	Local aArea     := FWGetArea()
	local oModel    := FWModelActive() as object
	Local oModelZS2 := oModel:getModel( "MODEL_ZS2" )
	local nY := 1
	local lFround := .F.

	nLineBkp := oModelZS2:GetLine()
	nLine    := 0

	If !Empty(cCodProd)

		if oModelZS2:SeekLine({{"ZS2_CODEMP",cCodProd}}, .T., .T.)
			oDlg:End()
			oModelZS2:SeekLine({{"ZS2_CODEMP",cCodProd}}, .T., .T.)
		else
			FWAlertWarning("Não foi possível localizar o item!", "Atenção")
		endif

	EndIf

	FWRestArea(aArea)
return

/*/{Protheus.doc} aEst001E
  Função que monta e exibe a tela de seleção de lotes

  @type user function
  @author Tiago Cunha
  @since 22/07/2025
  @version 1.0.0
/*/
User Function aEst001E()
	Local aArea     := FWGetArea()
	Local oModel    := FWModelActive() as object
	Local oView		  := FwViewActive()
	Local oModelZS2 := oModel:getModel( "MODEL_ZS2" )
	Local nLinAtu   := oModelZS2:GetLine()

	cProd    := oModelZS2:GetValue("ZS2_CODEMP")
	cLocal   := oModelZS2:GetValue("ZS2_LOCAL")
	cLote    := ""

	F4Lote(,,,"U_AEST001",cProd, cLocal,NIL,NIL,2,,,.F.,@cLote)

	if ReadVar() <> "M->ZS2_LOTECT"
		oModelZS2:LoadValue("ZS2_LOTECT", AllTrim(cLote))
		oView:GetSubView("VIEW_ZS2"):Refresh()
	endif

	oModelZS2:GoLine(nLinAtu) // Retorna para a linha original

	FWRestArea(aArea)
Return


Static Function fGetLotVld()
	Local aArea     := FWGetArea()
	Local oModel    := FWModelActive() as object
	Local oModelZS2 := oModel:getModel( "MODEL_ZS2" )

	cLote    := oModelZS2:GetValue("ZS2_LOTECT")
	cProd    := oModelZS2:GetValue("ZS2_CODEMP")
	cLocal   := oModelZS2:GetValue("ZS2_LOCAL")

	dDTVld := CTod("//")

	if !Empty(cLote)
		dDTVld := Posicione("SB8",3,xFilial("SB8")+cProd+cLocal+cLote,"B8_DTVALID")
	endif

	FWRestArea(aArea)

Return dDTVld

/*/{Protheus.doc} aEst001F
  Função que monta e exibe a tela de seleção de balanças

  @type user function
  @author Tiago Cunha
  @since 22/07/2025
  @version 1.0.0
/*/
User Function aEst001F()
	Local aArea     := FWGetArea()
	Local oModel    := FWModelActive() as object
	Local oModelZS2 := oModel:getModel( "MODEL_ZS2" )

	cProd    := oModelZS2:GetValue("ZS2_CODEMP")
	cProdUM  := Posicione("SB1",1,xFilial("SB1") + cProd,"B1_UM")

	// Verifica se a unidade de medida do produto posicionado é KG, se for, exibe a tela de seleção de balanças
	lProdKg  := cProdUM == "KG"
	if lProdKg
		// Monta tela de seleção de balanças
		U_aEst001G()
	endif

	FWRestArea(aArea)
Return


User Function aEst001G()
	Local aArea        := GetArea()


	Local oFont1 	     := TFont():New( "Arial", , -13, .T.)

	Local oGroup1
	Local nOpca        := 0
	Local cFontUti     := "Arial"
	Local oFontBtn     := TFont():New(cFontUti,,-14)

	Local aItems:= {'Item1','Item2','Item3'}

	Private cCodProd := Space(TamSX3('B1_COD')[01])
	Private cLote    := Space(TamSX3('H6_LOTECTL')[01])

	Private _nPesoBruto := 0
	Private _nTara := 0
	Private _nPesoLiquido := 0
	Private oGetPesoBruto
	Private oGetTara
	Private oGetPesoLiquido

	Private oDlgGrp
	Private oPanGrid
	Private oGetGrid

	Private oDlgX

	DEFINE MSDIALOG oDlgX TITLE "Integração com Balança" FROM 000, 000  TO 500, 930 COLORS 0, 16777215 PIXEL

	@ /*025*/10, 013 SAY "Balança:" 	 			SIZE 065, 010 OF oDlgX FONT oFont1 PIXEL
	cCombo1:= aItems[1]
	oCombo1 := TComboBox():New(21,013,{|u|if(PCount()>0,cCombo1:=u,cCombo1)},;
		aItems,130,20,oDlgX,,{|| .T. };
		,,,,.T.,,,,,,,,,'cCombo1')

	@ /*025*/48, 013 SAY "Peso Bruto:" 	 			SIZE 065, 010 OF oDlgX FONT oFont1 PIXEL
	@ /*025*/48, 120 SAY "Tara:" 	 				    SIZE 065, 010 OF oDlgX FONT oFont1 PIXEL
	@ /*025*/48, 320 SAY "Peso Liquido:" 	 		SIZE 065, 010 OF oDlgX FONT oFont1 PIXEL

	@ /*025*/60, 013 MSGET oGetPesoBruto  VAR _nPesoBruto  SIZE 075, 010 OF oDlgX COLORS 0, 16777215  PIXEL

	@ /*025*/60, 140 MSGET oGetTara       VAR _nTara SIZE 075, 010 OF oDlgX COLORS 0, 16777215 PIXEL

	@ /*025*/60, 320 MSGET oGetPesoLiquido VAR _nPesoLiquido SIZE 075, 010 OF oDlgX COLORS 0, 16777215 WHEN ( .F. ) PIXEL // se mv verificar for nao fica como desativado o campo

	ACTIVATE MSDIALOG oDlgX CENTERED

	RestArea(aArea)
Return

/*/{Protheus.doc} AEST001A
	Priorização / Despriorização da requisição

	@type User Function
	@author Tiago Cunha
	@param cTipo, character, 1 - Priorizar; 2 - Despriorizar
	@since 01/07/2025
	@version 1.0.0
/*/
User Function AEST001A(cTipo as character)
	Local cUsrsAltor := GetMv("MV_USRPRI", .F., "000000")
	Local cUser      := RetCodUsr()

	Default cTipo := "1" // 1 - Priorizar; 2 - Despriorizar

	if cTipo == "1"
		// Se o usuário possui permissão para realizar essa ação
		if cUser $ cUsrsAltor
			RecLock("ZS1", .F.)
			ZS1->ZS1_REQPRI := "1" // Sim
			ZS1->(MsUnlock())

			FWAlertSuccess("Requisição priorizada com sucesso", "Sucesso")
		else
			FWAlertWarning("Usuário não autorizado para realizar a priorização", "Aviso")
		endif
	else
		if cUser $ cUsrsAltor
			RecLock("ZS1", .F.)
			ZS1->ZS1_REQPRI := "2" // Não
			ZS1->(MsUnlock())

			FWAlertSuccess("Requisição despriorizada com sucesso", "Sucesso")
		else
			FWAlertWarning("Usuário não autorizado para realizar a despriorização", "Aviso")
		endif
	endif

Return

// static function PreSepAlt(oModel, nLine, cAction)
// 	Local lRet := .T.

// 	if cAction == "SETVALUE"
// 		fAllConcluidos()
// 	endif
// return lRet


// Função que verifica o status dos itens
Static Function fAllConcluidos()
	local oModel    := FWModelActive() as object
	local oView 	  := FwViewActive()
	local oModelZS1 := oModel:getModel( "MODEL_ZS1" )
	local oModelZS2 := oModel:getModel( "MODEL_ZS2" )
	local nTotal    := 0
	local nNaoIniciados := 0
	local nSepParci := 0
	local nConcluidos := 0
	local nX := 0
	local nY := 0
	local nZS2Total      := oModelZS2:Length()
	local nZS2Concluidos := 0
	local nLinZS2bkp     := oModelZS2:GetLine()

	local nSaldo         := 0

	for nX := 1 to nZS2Total
		oModelZS2:GoLine(nX)

		nQtdSep := 0
		if nX == nLinZS2bkp
			nQtdSep := M->ZS2_QTDSEP
		else
			nQtdSep := oModelZS2:GetValue("ZS2_QTDSEP")
		endif

		nSaldo := oModelZS2:GetValue("ZS2_QTDORI") - nQtdSep

		if nQtdSep == 0
			oModelZS2:SetValue("ZS2_STATUS", "1") // 1 – Não iniciado
			nNaoIniciados++
		elseif nSaldo <> 0 .And. nQtdSep < oModelZS2:GetValue("ZS2_QTDORI") .And. nQtdSep > 0
			oModelZS2:SetValue("ZS2_STATUS", "2") // 2 – Separação parcial
			nSepParci += 1
		elseif nSaldo == 0 .And. nQtdSep == oModelZS2:GetValue("ZS2_QTDORI")
			oModelZS2:SetValue("ZS2_STATUS", "3") // 3 -Concluído
			nConcluidos += 1
		endif

		// Atualiza o saldo de cada linha
		oModelZS2:SetValue("ZS2_SLDREQ", nSaldo)
	next

	// Totaliza para atualizar o ZS1
	if nConcluidos == nZS2Total .And. nZS2Total > 0
		oModelZS1:SetValue("ZS1_STATUS", "3") // 3 – Separação finalizada

		oModelZS1:SetValue("ZS1_DTFSEP", dDataBase)
		oModelZS1:SetValue("ZS1_HRFSEP", Time())

		dDataini := oModelZS1:GetValue("ZS1_DTINSE")
		dDatafim := oModelZS1:GetValue("ZS1_DTFSEP")
		cHoraini := oModelZS1:GetValue("ZS1_HRINSE")
		cHorafim := oModelZS1:GetValue("ZS1_HRFSEP")
		oModelZS1:SetValue("ZS1_TEMSEP", DifPeriodo(dDataIni, cHoraini, dDataFim, cHorafim))
	else
		oModelZS1:SetValue("ZS1_DTFSEP", cToD("//"))
		oModelZS1:SetValue("ZS1_HRFSEP", "")
		oModelZS1:SetValue("ZS1_TEMSEP", "")
	endif

	oModelZS2:GoLine(nLinZS2bkp) // Retorna para a linha original
	nSaldo := oModelZS2:GetValue("ZS2_QTDORI") - M->ZS2_QTDSEP

Return nSaldo


/*/{Protheus.doc} AEST001B
	Estorno da separação

	@type User Function
	@author Tiago Cunha
	@since 01/07/2025
	@version 1.0.0
/*/
User Function AEST001B()
	Local lContinua := .T.

	SC2->(dbSetOrder(1))
	if SC2->(dbSeek(FWxFilial("SC2")+ZS1->ZS1_OP))

		// Verifica se a op sofreu apontamento
		if !Empty(SC2->C2_DATRF) .And. SC2->C2_QUJE > 0
			FWAlertWarning("Op apontada não pode ser estornada", "Aviso")
			lContinua := .F.
		endif

		// Verifica se o empenho foi baixado
		if lContinua .And. SD4->(dbSeek(FwxFilial("SD4")+ SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN))
			While SD4->(!EOF()) .And. AllTrim(SD4->D4_OP) == AllTrim(SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN)
				if SD4->D4_QUANT <> SD4->D4_QTDORI
					lContinua := .F.
				endif

				SD4->(dbSkip())
			End

			if !lContinua
				FWAlertWarning("A Op possui empenho baixado", "Aviso")
			endif
		endif

		// Realiza o processo de estorno da separação
		if lContinua

			// Verifica se o status da requisição é 4 - Transf. p/ WIP
			if ZS1->ZS1_STATUS == "4"
				if !fEstornar(ZS1->ZS1_DOC)
					Return
				endif
			endif

			// Atualiza a SZ2 para os valores defaults
			Reclock("ZS1", .F.)
			ZS1->ZS1_STATUS := "1"
			ZS1->ZS1_USRSEP := ""
			ZS1->ZS1_DTINSE := cToD("//")
			ZS1->ZS1_HRINSE := ""
			ZS1->ZS1_USREST := RetCodUsr()
			ZS1->ZS1_DATEST := dDataBase
			ZS1->ZS1_HOREST := Time()
			ZS1->ZS1_DTFSEP := cToD("//")
			ZS1->ZS1_HRFSEP := ""
			ZS1->(MsUnlock())

			// Resetando os itens da ZS2
			ZS2->(dbSetOrder(2)) // filial + numreq + item req
			if ZS2->(dbSeek(FWxFilial("ZS2") + ZS1->ZS1_NUMREQ))
				While ZS2->(!EOF()) .And. AllTrim(ZS2->ZS2_NUMREQ) == AllTrim(ZS1->ZS1_NUMREQ)

					Reclock("ZS2", .F.)
					ZS2->ZS2_SLDREQ := ZS2->ZS2_QTDORI
					ZS2->ZS2_QTDSEP := 0
					ZS2->ZS2_STATUS := "1"
					ZS2->(MsUnlock())
					ZS2->(dbSkip())
				End
			endif

			FWAlertSuccess("Estorno da requisição de separação realizado com sucesso", "Aviso")
		endif

	endif
Return

Static Function fEstornar(cDocumento)
	Local aArea    := FWGetArea()
	Local aAreaSD3
	Local aCab     := {}
	Local aItens   := {}
	Local aItem    := {}
	Local cChave   := ""
	Local lRet     := .F.
	Private lMsErroAuto := .F.

	//Abre a tabela de movimentações, e se conseguir posicionar no documento
	DbSelectArea("SD3")
	SD3->(DbSetOrder(2)) // D3_FILIAL + D3_DOC + D3_COD
	If SD3->(MsSeek(FWxFilial('SD3') + cDocumento))
		aAreaSD3 := SD3->(FWGetArea())
		cChave   := SD3->D3_FILIAL + SD3->D3_DOC

		//Adiciona no cabeçalho as chaves da tabela
		aCab := {;
			{"D3_DOC", SD3->D3_DOC, Nil};
			}

		//Enquanto houver dados que for o mesmo documento, adiciona no array de itens
		ProcRegua(0)
		While ! SD3->(EoF()) .And. SD3->D3_FILIAL + SD3->D3_DOC == cChave
			IncProc("Adicionando produto " + Alltrim(SD3->D3_COD) + "...")

			aItem := {}
			aAdd(aItem, {"D3_COD",     SD3->D3_COD,   Nil})
			aAdd(aItem, {"D3_UM",      SD3->D3_UM,    Nil})
			aAdd(aItem, {"D3_QUANT",   SD3->D3_QUANT, Nil})
			aAdd(aItem, {"D3_LOCAL",   SD3->D3_LOCAL, Nil})
			aAdd(aItem, {"D3_ESTORNO", "S",           Nil})
			aAdd(aItens, aClone(aItem))

			SD3->(DbSkip())
		EndDo

		//Volta onde estava na SD3
		FWRestArea(aAreaSD3)

		//Aciona o ExecAuto
		MsExecAuto({|x, y, z| MATA241(x, y, z)}, aCab, aItens, 6)

		//Se houve erro, exibe
		If lMsErroAuto
			MostraErro()
		Else
			lRet := .T.
		EndIf

	Else
		FWAlertError("Documento não foi encontrado!", "Atenção")
	EndIf

	FWRestArea(aArea)
Return


/*/{Protheus.doc} AEST001C
	Transf WIP

	@type User Function
	@author Tiago Cunha
	@since 01/07/2025
	@version 1.0.0
/*/
User Function AEST001C()
	Private aArea := GetArea()

	FwMsgRun(, {|| transfWip()}, "Executando...", "Transferindo WIP...")

	RestArea(aArea)

Return


Static Function transfWip()
	local lContinua := .T.
	local cTMReq    := SuperGetMv("MV_REQPRO", .F., "950")

	private cEndProd := ""
	// Variáveis para controle de execução automática
	Private lMsHelpAuto := .T. // Se .T., exibe mensagens de help
	Private lMsErroAuto := .F. // Se .F., não exibe erros automáticos

	aItensSD3 := {}
	aCabSD3   := {}
	aItemSDB  := {}

	cEndProd  := FWInputBox("Informe o Endereço do Produto onde será armazenado:", "")

	// Valida se todos os ZS2 foram separados
	ZS2->(dbSetOrder(1))
	if ZS2->(dbSeek(FWxFilial("ZS2")+ZS1->ZS1_NUMREQ))
		cMsg := ""

		While ZS2->(!EOF()) .And. AllTrim(ZS2->ZS2_NUMREQ) == AllTrim(ZS1->ZS1_NUMREQ)
			if ZS2->ZS2_SLDREQ <> 0
				lContinua := .F.
				cMsg   += "Produto [" + AllTrim(ZS2->ZS2_CODEMP) + "] não foi separado completamente, finalize a separação antes de realizar o envio para WIP." + CHR(13) + CHR(10) + CHR(13) + CHR(10)
			else

				SB1->(dbSetOrder(1))
				if SB1->(dbSeek(FWxFilial("SB1")+ ZS1->ZS1_CODPROD))

					_aItem := {;
						{"D3_COD", ZS2->ZS2_CODEMP, NIL},;   // Código do produto
						{"D3_UM",      SB1->B1_UM, NIL},;       // Unidade de medida
						{"D3_QUANT",   ZS2->ZS2_QTDSEP, NIL},;     // Quantidade do item (1.99)
						{"D3_LOCAL",   ZS2->ZS2_LOCAL, NIL},;     // Local de estoque
						{"D3_LOTECTL", ZS2->ZS2_LOTECT, NIL};     // Lote
					}

					aAdd(aItensSD3, _aItem)
					if SB1->B1_LOCALIZ == "S"
					endif
				endif

			endif

			ZS2->(dbSkip())
		End

		if !lContinua
			u_zMsgLog( "Enviar p/ WIP" + CHR(13) + CHR(10) + CHR(13) + CHR(10) + cMsg, "Aviso", 1, .F. )
		else

			cNumDocD3 := NextNumero("SD3", 2, "D3_DOC", .T.)
			aCabSD3   := {;
				{"D3_DOC"     , cNumDocD3                , NIL},;
				{"D3_TM"      , cTMReq                  , NIL},;
				{"D3_CC"      , Space(TamSX3("D3_CC")[1]), NIL},;
				{"D3_EMISSAO" , dDataBase                , NIL};
				}

			lMsErroAuto := .F.
			lMsHelpAuto := .T.

			SB8->(DbSetOrder(1))

			//Aciona o ExecAuto
			MSExecAuto({|x, y, z| MATA241(x, y, z)}, aCabSD3, aItensSD3, 3)

			If lMsErroAuto
				MostraErro()          // Exibe mensagem de erro
				DisarmTransaction()   // Desfaz a transação em caso de erro
			else
				FWAlertSuccess("Transferência para o WIP concluida com sucesso", "Sucesso")

				RecLock("ZS1", .F.)
				ZS1->ZS1_DOC    := cNumDocD3
				ZS1->ZS1_STATUS := "4" // 4 - Transf. p/ WIP
				ZS1->(MsUnlock())

				if MsgYesNo("Deseja imprimir as etiquetas dos itens da requisição " + ZS1->ZS1_NUMREQ + " ?", "Confirmação")
				
					// Chama a função de impressão das etiquetas
					U_REST001a()
				endIf
			endIF

		endif
	endif

Return



/*/{Protheus.doc} zMsgLog
  Função que mostra uma mensagem de Log com a opção de salvar em txt

  @type function
  @author Tiago Cunha
  @since 28/03/2024
  @version 1.0.0
  @param cMsg, character, Mensagem de Log
  @param cTitulo, character, Título da Janela
  @param nTipo, numérico, Tipo da Janela (1 = Ok; 2 = Confirmar e Cancelar)
  @param lEdit, lógico, Define se o Log pode ser editado pelo usuário
  @return lRetMens, Define se a janela foi confirmada
/*/

User Function zMsgLog(cMsg, cTitulo, nTipo, lEdit)
	Local lRetMens := .F.
	Local oDlgMens
	Local oBtnOk, cTxtConf := ""
	Local oBtnCnc, cTxtCancel := ""
	Local oBtnSlv
	Local oFntTxt := TFont():New("Lucida Console",,-015,,.F.,,,,,.F.,.F.)
	Local oMsg
	Default cMsg    := "..."
	Default cTitulo := "zMsgLog"
	Default nTipo   := 1 // 1=Ok; 2= Confirmar e Cancelar
	Default lEdit   := .F.

	//Definindo os textos dos botões
	If(nTipo == 1)
		cTxtConf:='&Ok'
	Else
		cTxtConf:='&Confirmar'
		cTxtCancel:='C&ancelar'
	EndIf

	//Criando a janela centralizada com os botões
	DEFINE MSDIALOG oDlgMens TITLE cTitulo FROM 000, 000  TO 300, 400 COLORS 0, 16777215 PIXEL
	//Get com o Log
	@ 002, 004 GET oMsg VAR cMsg OF oDlgMens MULTILINE SIZE 191, 121 FONT oFntTxt COLORS 0, 16777215 HSCROLL PIXEL
	If !lEdit
		oMsg:lReadOnly := .T.
	EndIf

	//Se for Tipo 1, cria somente o botão OK
	If (nTipo==1)
		@ 127, 144 BUTTON oBtnOk  PROMPT cTxtConf   SIZE 051, 019 ACTION (lRetMens:=.T., oDlgMens:End()) OF oDlgMens PIXEL

		//Senão, cria os botões OK e Cancelar
	ElseIf(nTipo==2)
		@ 127, 144 BUTTON oBtnOk  PROMPT cTxtConf   SIZE 051, 009 ACTION (lRetMens:=.T., oDlgMens:End()) OF oDlgMens PIXEL
		@ 137, 144 BUTTON oBtnCnc PROMPT cTxtCancel SIZE 051, 009 ACTION (lRetMens:=.F., oDlgMens:End()) OF oDlgMens PIXEL
	EndIf

	//Botão de Salvar em Txt
	@ 127, 004 BUTTON oBtnSlv PROMPT "&Salvar em .txt" SIZE 051, 019 ACTION (fSalvArq(cMsg, cTitulo)) OF oDlgMens PIXEL
	ACTIVATE MSDIALOG oDlgMens CENTERED

Return lRetMens

Static Function fSalvArq(cMsg, cTitulo)
	Local cFileNom :='\log_'+dToS(Date())+StrTran(Time(),":")+".txt"
	Local cPath := ""
	Local cQuebra  := CRLF + CRLF + "+=======================================================================+" + CRLF
	// Local lOk      := .T.
	Local cTexto   := ""
	local tmp := getTempPath()

	//Pegando o caminho do arquivo
	cPath := tFileDialog( "Arquivo TXT *.txt | *.txt",;
		'Arquivo .txt...',, tmp, .F., GETF_RETDIRECTORY )

	//Se o nome não estiver em branco
	If !Empty(cPath)
		// //Teste de existência do diretório
		// If !ExistDir(SubStr(cFileNom,1,RAt('\',cFileNom)))
		// 	Alert("Diretório não existe:" + CRLF + SubStr(cFileNom, 1, RAt('\',cFileNom)) + "!")
		// 	Return
		// EndIf

		//Montando a mensagem
		cTexto := "Função   - "+ FunName()       + CRLF
		cTexto += "Usuário  - "+ cUserName       + CRLF
		cTexto += "Data     - "+ dToC(dDataBase) + CRLF
		cTexto += "Hora     - "+ Time()          + CRLF
		cTexto += "Mensagem - "+ cTitulo + cQuebra  + cMsg + cQuebra + CRLF

		// //Testando se o arquivo já existe
		// If File(cFileNom)
		// 	lOk := MsgYesNo("Arquivo já existe, deseja substituir?", "Atenção")
		// EndIf

		MemoWrite(cPath + cFileNom, cTexto)
		MsgInfo("Arquivo Gerado com Sucesso:"+ CRLF + cFileNom, "Atenção")

		fAbreArq(cPath, cFileNom)
		// If lOk
		// EndIf
	EndIf
Return

Static Function fAbreArq(cDirP, cNomeArqP)
	Local aArea:= GetArea()

	//Tentando abrir o objeto
	nRet := ShellExecute("open", cDirP + cNomeArqP, "", cDirP, 1)

	//Se houver algum erro
	If nRet <= 32
		MsgStop("Não foi possível abrir o arquivo " + cDirP + cNomeArqP + "!", "Atenção")
	EndIf

	RestArea(aArea)
Return
