//Bibliotecas
#Include "Totvs.ch"
#Include "FWMVCDef.ch"


//Variveis Estaticas
Static cTitulo    := "Formação do Preço de Venda"
Static cCamposChv := "ZZ1_FILIAL;ZZ1_PRODDP;ZZ1_VPRODP;ZZ1_PROBAS;ZZ1_DSCVDPR;ZZ1_CLIENT;ZZ1_LOJA;ZZ1_NOME"
Static cTabPai    := "ZZ1"
Static  __nTamLoja  	:= TamSx3('ZZ1_LOJA')[1]
Static  __nTamCodCli  	:= TamSx3('ZZ1_CLIENT')[1]
Static  __nTamVersao  	:= TamSx3('ZZ1_VPRODP')[1]
Static  __nTamProCod    := TamSx3('ZZ1_PRODDP')[1]


/*/{Protheus.doc} User Function ADPR001
	Formação do Preço de Venda;
	@author Lucas Silva Vieira
	@since 20/08/2024
	@version 1.0
	@type Function
/*/
User Function ADPR001()
	Local 	aArea   := FWGetArea()
	Local 	oBrowse
	Local 	nIgnore := 1
	Private aRotina := {}

	//Definicao do menu
	aRotina := MenuDef()

	//Instanciando o browse
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias(cTabPai)
	oBrowse:SetDescription(cTitulo)
	oBrowse:DisableDetails()

	//Ativa a Browse
	oBrowse:Activate()

	//Tratativa para ignorar warnings de ViewDef e ModelDef nunca chamados
	If nIgnore == 0
		ModelDef()
		ViewDef()
	EndIf

	FWRestArea(aArea)
Return Nil


/*/{Protheus.doc} MenuDef
	Menu de opcoes na funcao ADPR001
	@author Lucas Silva Vieira
	@since 20/08/2024
	@version 1.0
	@type Function
/*/
Static Function MenuDef()
	Local aRotina := {}

	//Adicionando opcoes do menu
	ADD OPTION aRotina TITLE "Visualizar" 		ACTION "U_ADPR001V(1)" OPERATION 1 ACCESS 0
	ADD OPTION aRotina TITLE "Incluir" 			ACTION "U_ADPR001V(2)" OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE "Alterar" 			ACTION "U_ADPR001V(3)" OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Excluir" 			ACTION "U_delReg()" OPERATION 5 ACCESS 0 //VIEWDEF.ADPR001
	ADD OPTION aRotina TITLE "Gerar Orçamento" 	ACTION "U_ADPR001O(4)" OPERATION 4 ACCESS 0

Return aRotina


/*/{Protheus.doc} ModelDef
	Modelo de dados na funcao ADPR001
	@author Lucas Silva Vieira
	@since 20/08/2024
	@version 1.0
	@type Function
/*/
Static Function ModelDef()
	Local oStruPai   := FWFormStruct(1, cTabPai, {|cCampo| Alltrim(cCampo) $ cCamposChv})
	Local oStruFilho := FWFormStruct(1, cTabPai)
	Local aRelation := {}
	Local oModel
	Local bPre := Nil
	Local bPos := Nil
	Local bCancel := Nil

	//Cria o modelo de dados para cadastro
	oModel := MPFormModel():New("ADPR001M", bPre, bPos, /*bCommit*/, bCancel)
	oModel:AddFields("ZZ1MASTER", /*cOwner*/, oStruPai)
	oModel:AddGrid("ZZ1DETAIL","ZZ1MASTER",oStruFilho,/*bLinePre*/, /*bLinePost*/,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)
	oModel:SetDescription(cTitulo)
	oModel:GetModel("ZZ1MASTER"):SetDescription( "Dados de - " + cTitulo)
	oModel:GetModel("ZZ1DETAIL"):SetDescription( "Grid de - " + cTitulo)
	oModel:SetPrimaryKey({})

	//Fazendo o relacionamento
	aAdd(aRelation, {"ZZ1_FILIAL", "FWxFilial('ZZ1')"} )
	aAdd(aRelation, {"", ""})
	oModel:SetRelation("ZZ1DETAIL", aRelation, ZZ1->(IndexKey(1)))

Return oModel


/*/{Protheus.doc} ViewDef
	Visualizacao de dados na funcao ADPR001
	@author Lucas Silva Vieira
	@since 20/08/2024
	@version 1.0
	@type Function
/*/
Static Function ViewDef()
	Local oModel     := FWLoadModel("ADPR001")
	Local oStruPai   := FWFormStruct(2, cTabPai, {|cCampo| Alltrim(cCampo) $ cCamposChv})
	Local oStruFilho := FWFormStruct(2, cTabPai, {|cCampo| ! Alltrim(cCampo) $ cCamposChv})
	Local oView

	//Cria a visualizacao do cadastro
	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_ZZ1", oStruPai, "ZZ1MASTER")
	oView:AddGrid("GRID_ZZ1",  oStruFilho,  "ZZ1DETAIL")

	//Partes da tela
	oView:CreateHorizontalBox("CABEC", 30)
	oView:CreateHorizontalBox("GRID", 70)
	oView:SetOwnerView("VIEW_ZZ1", "CABEC")
	oView:SetOwnerView("GRID_ZZ1", "GRID")

	//Adicionando campo incremental na grid
	oView:AddIncrementField("GRID_ZZ1", "ZZ1_ITEM")

Return oView


/*/{Protheus.doc} ADPR001O
Gera o Orçamento
@type function
@author Mario L. B. Faria
@since 2/11/2025
@param nOpc, numeric, Opção de processamento
/*/
User Function ADPR001O(nOpc)

	local aCabec 	 := {} as array
	local aItens 	 := {} as array
	local aLinha 	 := {} as array
	local nIndex     := 0  as numeric
	local nItem 	 := 1  as numeric
	local nQtd		 := 1  as numeric
	local nPrcVend	 := (ZZ1->ZZ1_MRGREA + ZZ1->ZZ1_IMPOST)//ZZ1->ZZ1_PRCUNI
	local nTotal	 := (nQtd * nPrcVend)
	Local cOrcamento := "" as Character
	local cProduto	 := ZZ1->ZZ1_PROBAS ///ZZ1_PRODDPR
	local cTES		 := ZZ1->ZZ1_TES
	local cCliente	 := ZZ1->ZZ1_CLIENT
	local cLoja		 := ZZ1->ZZ1_LOJA
	local cTpOper	 := ZZ1->ZZ1_OPER
	local cCodDesenv := ZZ1->ZZ1_PRODDP
	local cDescDesemv:= ZZ1->ZZ1_DSCVDP
	local cCondPag	 := ""
	local lOk    	 := .T. as logical
	Private lMsErroAuto := .F.

	dbSelectArea("SE4")
	dbSelectArea("SA1")
	dbSelectArea("SB1")
	SE4->(dbSetOrder(1))//E4_FILIAL+E4_CODIGO
	SA1->(dbSetOrder(1))//A1_FILIAL+A1_COD+A1_LOJA
	SB1->(dbSetOrder(1))//B1_FILIAL+B1_COD

	cCondPag := Posicione("SA1", 1, FWxFilial("SA1")+cCliente+cLoja,"A1_COND")

	If !empty(cCondPag)
		If SE4->(dbseek(FWxFilial("SE4")+cCondPag))
			lOk := .T.
		Else
			FwAlertInfo("Condicao de pagamento invalida!")
			lOk := .F.
		EndIf
	Else
		FWAlertWarning("Condicao de pagamento não encontrada!")
		lOk := .F.
	EndIf

	If !empty(cProduto) .and. lOK
		If SB1->(dbseek(FWxFilial("SB1")+cProduto))
			lOk := .T.
		Else
			lOk := .F.
			FwAlertInfo("Produto não localizado!")
		EndIf
	EndIf

	If lOk

		If Empty(ZZ1->ZZ1_ORCDPR)
			nOpc := 3
		Else
			nOpc := 4
		EndIf

		aCabec := {}
		aItens := {}

		If nOpc == 3
			aadd(aCabec,{"CJ_CLIENTE",	cCliente,	nil})
			aadd(aCabec,{"CJ_LOJA",		cLoja,		nil})
			aadd(aCabec,{"CJ_CONDPAG",	cCondPag,	nil})
		ElseIf nOpc == 4
			aAdd(aCabec,{"CJ_NUM", 		ZZ1->ZZ1_ORCDPR,Nil})
		EndIf

		If nOpc == 4
			aLinha := {}
			aAdd(aLinha,{"LINPOS","CK_ITEM","01"})
			aAdd(aLinha,{"AUTDELETA","S",Nil})
			aAdd(aItens,aLinha)
		EndIf

		For nIndex := 1 to nItem
			aLinha := {}
			aadd(aLinha,{"CK_ITEM",		StrZero(nIndex,TamSx3("CK_ITEM")[01]),	nil})
			aadd(aLinha,{"CK_PRODUTO",	cProduto,				nil})
			aadd(aLinha,{"CK_XCODDES",	cCodDesenv,				nil})
			aadd(aLinha,{"CK_XDESENV",	cDescDesemv,			nil})
			aadd(aLinha,{"CK_QTDVEN",	nQtd,					nil})
			aadd(aLinha,{"CK_PRCVEN",	nPrcVend,				nil})
			aadd(aLinha,{"CK_VALOR",	nTotal,					nil})
			aadd(aLinha,{"CK_OPER", 	cTpOper,				nil})
			aadd(aLinha,{"CK_TES",	    cTES,					nil})
			aadd(aItens,aLinha)

		Next nIndex

		//MATA415(aCabec,aItens,nOpc)
		MsAguarde({||MSExecAuto({|x,y,z| MATA415(x,y,z)},aCabec,aItens,nOpc)},"Aguarde...","Gerando orçamento...")

		If !lMsErroAuto
			
			cOrcamento := SCJ->CJ_NUM

			FwAlertSuccess("Incluido com sucesso! N° " + cOrcamento)
			ZZ1->(dbSetOrder(01))
			If ZZ1->(dbseek(FWxFilial("ZZ1")))
				If ZZ1->(recLock("ZZ1", .F.))
					ZZ1->ZZ1_ORCDPR := cOrcamento
					ZZ1->(msUnlock())
				EndIf
			EndIf
		Else
			FwAlertError("Erro na inclusao!")
			MostraErro()
		EndIf

	EndIf

return


User Function delReg()
	dbSelectArea(cTabPai)
	dbSetOrder(01) // ZZ1_FILIAL+ZZ1_CLIENT+ZZ1_LOJA+ZZ1_PRODDP+ZZ1_VPRODP
	cChave := FWxFilial(cTabPai)+PadR(ZZ1->ZZ1_CLIENT, __nTamCodCli)+PadR(ZZ1->ZZ1_LOJA, __nTamLoja)+PadR(ZZ1->ZZ1_PRODDPR, __nTamProCod)+PadR(ZZ1->ZZ1_VPRODP, __nTamVersao)

	If (ZZ1->(dbSeek(cChave)))
		If empty(ZZ1->ZZ1_ORCDPR)
			If ZZ1->(Reclock(cTabPai, .F.))
				ZZ1->(dbDelete())
				ZZ1->(msUnlock())
			EndIf
		Else
			FwAlertInfo("Não e possivel excluir este registro, ja existe um orçamento.")
		EndIf
	Else
		FwAlertError("Não foi possivel encontrar o registro para deleção, contate o administrador do sistema.", "Aviso")
	EndIf
Return .T.
