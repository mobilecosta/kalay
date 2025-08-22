#Include "Totvs.ch"

/*/{Protheus.doc} APCP001A
  Função responsável por realizar as validações iniciais para possibilitar a distribuição de ordens de produção pela quantidade de batelada.

  @type user function
  @author Tiago Cunha
  @since 27/06/2025
  @version 1.0.0
/*/
User Function APCP001A()
	Local nQtdeBalat := POSICIONE("SB1",1,XFILIAL("SB1")+SC2->C2_PRODUTO,"B1_XQTDBAT")

	if !Empty(SC2->C2_DATRF) .And. SC2->C2_QUJE > 0
		FWAlertWarning("Não é possível distribuir a OP, pois ela se encontra encerrada ou já possui quantidade produzida", "Aviso")
		Return
	endif

	// Verifica se o nQtdeBalat é maior que zero
	if nQtdeBalat > 0
		APCP001B()
	Else
		FWAlertWarning("Não é possível distribuir a OP, pois não há quantidade de batelada", "Aviso")
	EndIf

Return


/*/{Protheus.doc} APCP001B
  Função que monta e exibe a interface de distribuição de ordens de produção pela quantidade de batelada.

  @type user function
  @author Tiago Cunha
  @since 27/06/2025
  @version 1.0.0
/*/
Static Function APCP001B()
	Local aArea        := GetArea()
	Local GetData
	Local cetData 	   := SC2->C2_EMISSAO
	Local getNumero
	Local cetNumero    := SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN
	Local oFont1 	     := TFont():New( "Tahoma", , -13, .T.)
	Local getProduto
	Local cetProduto   := SC2->C2_PRODUTO + " - " + ALLTRIM(POSICIONE("SB1",1,XFILIAL("SB1")+SC2->C2_PRODUTO,"B1_DESC"))
	Local GetQtde
	Local cetQtde 	   := SC2->C2_QUANT
	Local GetQtdeBalat
	Local cetQtdeBalat := POSICIONE("SB1",1,XFILIAL("SB1")+SC2->C2_PRODUTO,"B1_XQTDBAT")
	// B1_XQTDBAT
	Local oGroup1
	Local nOpca        := 0
	Local cFontUti     := "Tahoma"
	Local oFontBtn     := TFont():New(cFontUti,,-14)

	Private oDlgGrp
	Private oPanGrid
	Private oGetGrid
	Private aHeaderGrid := {}
	Private aColsGrid   := {}
	Private oDlgOP

	DEFINE MSDIALOG oDlgOP TITLE "Distribuir OP" FROM 000, 000  TO 500, 930 COLORS 0, 16777215 PIXEL

	@ 015, 004 GROUP oGroup1 TO 240, 465 PROMPT "" OF oDlgOP COLOR 16711680, 16777215 PIXEL
	@ /*025*/38, 015 SAY "Numero da OP:" 	 			SIZE 065, 010 OF oDlgOP FONT oFont1 PIXEL
	@ /*025*/38, 155 SAY "Produto:" 	 				SIZE 065, 010 OF oDlgOP FONT oFont1 PIXEL
	@ /*040*/56, 015 SAY "Data de Emissão:"	 		SIZE 065, 010 OF oDlgOP FONT oFont1  PIXEL
	@ /*040*/56, 155 SAY "Qtde:"				 		SIZE 065, 010 OF oDlgOP FONT oFont1 PIXEL
	@ /*040*/56, 265 SAY "Qtde Batelada:"			SIZE 085, 010 OF oDlgOP FONT oFont1 PIXEL

	@ /*025*/35, 070 MSGET getNumero 	VAR cetNumero 	SIZE 075, 010 OF oDlgOP COLORS 0, 16777215 READONLY PIXEL
	@ /*025*/35, 185 MSGET getProduto	VAR cetProduto 	SIZE 280, 010 OF oDlgOP COLORS 0, 16777215 READONLY PIXEL
	@ /*040*/54, 070 MSGET GetData 	VAR cetData 	SIZE 075, 010 OF oDlgOP COLORS 0, 16777215 READONLY PIXEL
	@ /*040*/54, 185 MSGET GetQtde 	VAR cetQtde 	SIZE 075, 010 OF oDlgOP COLORS 0, 16777215 READONLY PIXEL
	@ /*040*/54, 320 MSGET GetQtdeBalat VAR cetQtdeBalat SIZE 075, 010 OF oDlgOP COLORS 0, 16777215 READONLY PIXEL

	fMontaHead()

	oPanGrid := tPanel():New(075, 005, "", oDlgOP, , , , RGB(000,000,000), RGB(254,254,254), 458, 163)
	oGetGrid := FWBrowse():New()
	oGetGrid:DisableFilter()
	oGetGrid:DisableConfig()
	oGetGrid:DisableReport()
	oGetGrid:DisableSeek()
	oGetGrid:DisableSaveConfig()
	oGetGrid:SetFontBrowse(oFontBtn)
	oGetGrid:SetDataArray()
	oGetGrid:lHeaderClick := .f.

	oGetGrid:SetInsert(.T.)
	oGetGrid:SetAddLine({|| addLine()})
	oGetGrid:SetLineOk({|| lineOK()})
	oGetGrid:SetDelete(.T., {|| fDeleteLine()}) //Define que pode apagar as linhas
	oGetGrid:SetBlkBackColor({|| changeLineColor() }) //Define as cores de fundo das linhas que vão ser exibidas no browse
	oGetGrid:SetBlkColor({|| changeTextColor() }) //Define as cores de texto das linhas

	oGetGrid:SetEditCell(.T., {|| .T.})
	oGetGrid:SetColumns(aHeaderGrid)
	oGetGrid:SetArray(aColsGrid)
	oGetGrid:SetOwner(oPanGrid)
	oGetGrid:Activate()

	FWMsgRun(, {|| fMontarOPDistribuida(cetQtde, cetQtdeBalat) }, "Processando", "Distribuindo a OP...")

	ACTIVATE MSDIALOG oDlgOP CENTERED ON INIT EnchoiceBar(oDlgOP,{||tudoOK(@nOpca)},{|| nOpca := 1,oDlgOP:End()})

	If nOpca == 2 //BOTÃO OK
		Processa({|| fDistribuirOP(cetNumero)}, "Distribuindo a OP...")
	endIF

	RestArea(aArea)
Return


Static Function addLine()
	aAdd(aColsGrid, {cValToChar(Len(aColsGrid)+1), 0, .F.}) // Adiciona uma nova linha com a quantidade zerada e não apagada
	oGetGrid:GoBottom(.F.)
Return .T.

Static Function tudoOK(nOpca as numeric)
	Local nI, nTotalLinhas := 0
	Local nQtdeTotal := 0
	Local lTemQtde   := .F.
	Local lOk        := .T.
	Local lVldTotal  := GetMV("MV_XVLDDIS", .F., .T.)

	// Verifica se todas as linhas possuem quantidade maior que zero
	For nI := 1 To Len(aColsGrid)
		If !aColsGrid[nI][3] // Se não está apagada
			If aColsGrid[nI][2] <= 0
				FWAlertWarning("Existe(m) linha(s) com quantidade menor ou igual a zero.", "Atenção")
				lOk := .F.
				Return
			EndIf

			nQtdeTotal += aColsGrid[nI][2]
			lTemQtde := .T.
			nTotalLinhas++
		EndIf
	Next

	// Verifica se a quantidade total é maior que zero
	If nQtdeTotal <= 0
		FWAlertWarning("A quantidade total das OPs que serão geradas deve ser maior que zero.", "Atenção")
		lOk := .F.
		Return
	EndIf

	// Verifica deve possuir pelo uma linha com quantidade
	If !lTemQtde
		FWAlertWarning("É necessário informar pelo menos uma linha com quantidade maior que zero.", "Atenção")
		lOk := .F.
		Return
	EndIf

	// Caso o parametro mv_XVLDDIS estiver verdadeiro o total das linhas deve ser igual a quantidade da OP.
	If lVldTotal
		If nQtdeTotal <> SC2->C2_QUANT
			FWAlertWarning("A soma das quantidades das OPs que serão geradas devem ser igual à quantidade da OP a ser distribuida.", "Atenção")
			lOk := .F.
			Return
		EndIf
	EndIf

	nOpca := 2
	oDlgOP:End()
Return

Static Function lineOK()
	Local lRet := .T.
	Local nDelPos := len(aColsGrid[oGetGrid:At()])

	if !oGetGrid:oData:aArray[oGetGrid:At()][nDelPos] .And. oGetGrid:oData:aArray[oGetGrid:At()][2] <= 0
		FWAlertWarning("A quantidade deve ser maior que zero.", "Atenção")
		lRet := .F.
	endif
Return lRet

Static Function changeTextColor()
	Local nTextColor := 0 As Numeric
	Local nDelPos := len(aColsGrid[oGetGrid:At()])

	//Se a linha estiver apagada, vai ser Branco
	If oGetGrid:oData:aArray[oGetGrid:At()][nDelPos]
		nTextColor := RGB(255, 255, 255)
		//Senão, vai ser Preto
	Else
		nTextColor := RGB(000, 000, 000)
	EndIf

Return nTextColor

Static Function changeLineColor()
	Local nLineColor := 0 As Numeric
	Local nDelPos := len(aColsGrid[oGetGrid:At()])

	//Se a linha estiver apagada, a cor será cinza
	If oGetGrid:oData:aArray[oGetGrid:At()][nDelPos]
		nLineColor := RGB(192, 192, 192)

	Else
		//Se a linha for Par, vai ser Cinza Claro
		If oGetGrid:At() % 2 == 0
			nLineColor := RGB(242, 242, 242)
			//Senão, se ela for Ímpar, vai ser Branco
		Else
			nLineColor := RGB(255, 255, 255)
		EndIf
	EndIf

Return nLineColor

Static Function fDeleteLine()
	nDelPos := len(aColsGrid[oGetGrid:At()])
	aColsGrid[oGetGrid:At()][nDelPos] := !aColsGrid[oGetGrid:At()][nDelPos] // Marca a linha como apagada

	oGetGrid:LineRefresh()
Return .T.


Static Function fMontaHead()
	Local nAtual
	Local aHeadAux := {}

	//Adicionando colunas
	//[1] - Titulo
	//[2] - Tipo
	//[3] - Tamanho
	//[4] - Decimais
	//[5] - Máscara
	aAdd(aHeadAux, {"Ordens de Produção", "C", 3, 0, "", .F.})
	aAdd(aHeadAux, {"Quantidade", "N", TamSX3("C2_QUANT")[1], TamSX3("C2_QUANT")[2], PesqPict("SC2","C2_QUANT"), .T.})

	//Percorrendo e criando as colunas
	For nAtual := 1 To Len(aHeadAux)
		aAdd(aHeaderGrid, FWBrwColumn():New())
		aHeaderGrid[nAtual]:SetData(&("{||oGetGrid:oData:aArray[oGetGrid:At(),"+Str(nAtual)+"]}"))
		aHeaderGrid[nAtual]:SetTitle( aHeadAux[nAtual][1] )
		aHeaderGrid[nAtual]:SetType(aHeadAux[nAtual][2] )
		aHeaderGrid[nAtual]:SetSize( aHeadAux[nAtual][3] )
		aHeaderGrid[nAtual]:SetDecimal( aHeadAux[nAtual][4] )
		aHeaderGrid[nAtual]:SetPicture( aHeadAux[nAtual][5] )

		If aHeadAux[nAtual][6]
			aHeaderGrid[nAtual]:SetEdit(.T.)
			aHeaderGrid[nAtual]:SetReadVar("oGetGrid:oData:aArray[oGetGrid:At(),"+Str(nAtual)+"]")
		EndIf
	Next
Return


/*/{Protheus.doc} fMontarOPDistribuida
	Distribui a quantidade total da OP em lotes de acordo com a quantidade da batelada.

	@type  Static Function
	@author Tiago Cunha
	@since 28/06/2025
	@version 1.0.0
	@param nQtdOP, numeric, Quantidade total da OP
	@param nQtdBatelada, numeric, Quantidade da batelada
/*/
Static Function fMontarOPDistribuida(nQtdOP, nQtdBatelada)
	Local nQtdCheia := 0 as numeric
	local nSobra := 0 as numeric
	local nSeq := 0 as numeric

	If nQtdBatelada <= 0 .Or. nQtdOP <= 0
		// Quantidade inválida
		Return aColsGrid
	EndIf

	nQtdCheia := Int(nQtdOP / nQtdBatelada)
	nSobra    := nQtdOP % nQtdBatelada

	For nSeq := 1 To nQtdCheia
		cSeq := cValToChar(nSeq)
		aAdd(aColsGrid, {cSeq, nQtdBatelada, .F.})
	Next

	If nSobra > 0
		cSeq := cValToChar(Len(aColsGrid)+1)
		aAdd(aColsGrid, {cSeq, nSobra, .F.})
	EndIf

	oGetGrid:SetArray(aColsGrid)
	oGetGrid:Refresh()

Return


/*/{Protheus.doc} fDistribuirOP
	Executa os execautos para realizar a distribuição da OP e exclusão da OP posicionada.

	@type  Static Function
	@author Tiago Cunha
	@since 28/06/2025
	@version 1.0.0
	@param cNumOp, character, Número da OP a ser distribuída
/*/
Static Function fDistribuirOP(cNumOp as character)
	Local aArea       := GetArea()
	Local nX          := 0
	Local nY 		      := 0
	Local cSeq        := "001"
	Local dInicio     := CToD("//")
	Local dEmissao    := CToD("//")
	Local dEntrega    := CToD("//")
	local cProduto    := ""
	local cItem       := ""
	local cNum        := ""
	Local nAtual      := 0
	Local nTotal      := 0
	Local lRet        := .T.

	Private lMsErroAuto := .F.


	// Conta quantas ops serão criadas na distribuição
	for nY := 1 to len(aColsGrid)
		if !aColsGrid[nY][3] // Verifica se a linha não está apagada
			nTotal++
		endif
	next

	ProcRegua(nTotal)

	// Se posiciona na Op e preenche as variáveis
	SC2->(DbSetOrder(1))
	if SC2->(DbSeek(xFilial("SC2")+cNumOp)) //FILIAL + NUM + ITEM + SEQUEN + ITEMGRD
		dInicio	 := SC2->C2_DATPRI
		dEmissao := SC2->C2_EMISSAO
		dEntrega := SC2->C2_DATPRF
		cProduto := SC2->C2_PRODUTO
		cSeq     := SC2->C2_SEQUEN
		cItem    := SC2->C2_ITEM
		cNum     := SC2->C2_NUM

		nOpcao := 3 // Inclusão

		for nX := 1 to len(aColsGrid)

			if !lRet
				Exit
			endif

			if !aColsGrid[nX][3] // Verifica se a linha não está apagada
				aDados :=   {{'C2_FILIAL'   ,xFilial('SC2')     ,NIL},;
					{'C2_SEQUEN'   ,"001"               ,NIL},;
					{'C2_DATPRI'   ,dInicio            ,NIL},;
					{'C2_DATPRF'   ,dEntrega           ,NIL},;
					{'C2_PRODUTO'  ,cProduto           ,NIL},;
					{'C2_QUANT'    ,aColsGrid[nX][2]   ,NIL},;
					{'AUTEXPLODE'  ,"S"                ,NIL}}

				nAtual++
				IncProc("Distribuindo OP " + cValToChar(nAtual) + " de " + cValToChar(nTotal) + "...")

				Begin Transaction

					MsExecAuto({|x, y|Mata650(x,y)},aDados,nOpcao)
					If lMsErroAuto
						lRet := .F.
						aErro := MostraErro()
						DisarmTransaction()
					EndIf

				End Transaction

			endif
		next

		if !lRet
			FWAlertWarning("Nõ foi possivel distribuir a OP " + cNumOp + ".", "Atenção")
			RestArea(aArea)
			Return
		endif

		SC2->(DbSetOrder(1))
		SC2->(DbSeek(xFilial("SC2")+cNumOp))

		//-----------------------------------
		// Exclusão da OP posicionada que foi distribuída
		//-----------------------------------
		nOpcao := 5 // Excluir

		aDados :=   {{'C2_FILIAL'   ,xFilial('SC2')     ,NIL},;
			{'C2_ITEM'     ,cItem              ,NIL},;
			{'C2_PRODUTO'  ,cProduto           ,NIL},;
			{'C2_NUM'      ,cNum               ,NIL},;
			{'C2_SEQUEN'   ,cSeq               ,NIL}}

		Begin Transaction

			MsExecAuto({|x, y|Mata650(x,y)},aDados,nOpcao)
			If !lMsErroAuto
				FWAlertSuccess("Distribuição da OP " + cNumOp + " realizada com sucesso!", "Sucesso")
			else
				aErro := MostraErro()
				DisarmTransaction()
			EndIf

		End Transaction
	endIf

	RestArea(aArea)
Return
