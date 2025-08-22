#include 'totvs.ch'
#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include 'TOPCONN.CH'


User Function ADPR001V(nOpc)
	Local oDlg
	Local oFolder
	Local bBlocoOk     		:= {|| lOk := .T., onSave(nOpc, oDlg)}
	Local bBlocoCan    		:= {|| lOk := .F., oDlg:End()}
	Local aOutrasAc    		:= { }
	Local bBlocoIni    		:= {|| EnchoiceBar(oDlg, bBlocoOk, bBlocoCan, , aOutrasAc)}

	Private __nTamVersao  	:= TamSx3('ZZ1_VPRODP')[1]
	Private __nTamProDesc  	:= TamSx3('ZZ1_DSCVDP')[1]
	Private __nTamProCod    := TamSx3('ZZ1_PRODDP')[1]
	Private __nTamTES  		:= TamSx3('ZZ1_TES')[1]
	Private __nTamNomeCli  	:= TamSx3('A1_NOME')[1]
	Private __nTamLoja  	:= TamSx3('ZZ1_LOJA')[1]
	Private __nTamCodCli  	:= TamSx3('ZZ1_CLIENT')[1]
	Private __nTamCodPro  	:= TamSx3('B1_COD')[1]

	Private	cDescrPrd		:= space(__nTamProDesc)
	Private cProdDpr	   	:= space(__nTamProCod)
	Private cVersao	     	:= space(__nTamVersao)
	Private cDescricao   	:= space(__nTamProDesc)
	Private cTes 		   	:= space(__nTamTES)
	Private cNomeCli   		:= space(__nTamNomeCli)
	Private cLoja		   	:= space(__nTamLoja)
	Private cCodCli	   		:= space(__nTamCodCli)
	Private cProdBase  		:= space(__nTamCodPro)
	Private cTpOper 	 	:= Space(3)
	Private nTotal 	   		:= 0
	Private _nTotImp		:= 0
	Private nMaBrCaPer 		:= 0
	Private nMaBrCalcu 		:= 0
	Private nPrcUnitTot     := 0
	Private nOutros    		:= 0
	Private nFrete	   		:= 0
	Private nTerc      		:= 0
	Private nCustoDPR  		:= 0
	Private cTipoCli  		:= ""
	Private lViewMode       := .F.
	Private nRadio          := 2

	If nOpc == 1 .Or. nOpc == 3 // Visualizar ou Editar
		cProdDpr  := ZZ1->ZZ1_PRODDPR
		cVersao   := ZZ1->ZZ1_VPRODP
		lViewMode := nOpc == 1

		nFrete  := ZZ1->ZZ1_CSTFRT
		nTerc   := ZZ1->ZZ1_CSTTER
		nOutros := ZZ1->ZZ1_CSTOUT

		// Comercial
		_nTotImp := ZZ1->ZZ1_IMPOST
		nRadio  := IIf(ZZ1->ZZ1_IMPOST > 0, 1, 2)
		cTpOper := ZZ1->ZZ1_OPER
		cTes    := ZZ1->ZZ1_TES
		cCodCli := ZZ1->ZZ1_CLIENT
		cLoja   := ZZ1->ZZ1_LOJA
		nMaBrCaPer := ZZ1->ZZ1_MRGCAL
		nMaBrCalcu := ZZ1->ZZ1_MRGREA
	EndIf

	If nOpc == 3
		If !empty(ZZ1->ZZ1_ORCDPR)
			u_generatebudget(ZZ1->ZZ1_COD, 4)
		EndIf
	EndIf

	oFontn := TFont():New("Arial",, 20,, .T.,,,, .F., .F.)

	dbSelectArea("DG0")
	dbSelectArea("DG3")
	dbSelectArea("CZ3")
	// Pegando as dimensões da tela
	oSize := FwDefSize():New(.T.)
	oSize:AddObject( "CORPO",100, 080, .T., .T. )
	oSize:lLateral     := .F.  // Calculo vertical
	oSize:Process()

	oDlg := MSDialog():New(oSize:aWindSize[1],oSize:aWindSize[2],oSize:aWindSize[3],oSize:aWindSize[4],"ALTER",,,,nOr(WS_VISIBLE,WS_POPUP),CLR_BLACK,CLR_WHITE,,,.T.,,,,.F.)
	// DEFINE DIALOG oDlg TITLE "Formação de Preço de Venda" FROM oSize:aWindSize[1],oSize:aWindSize[2] TO oSize:aWindSize[3],oSize:aWindSize[4] PIXEL

	aCorpo := {oSize:GetDimension("CORPO","LININI"),;
		oSize:GetDimension("CORPO","COLINI"),;
		oSize:GetDimension("CORPO","XSIZE"),;
		oSize:GetDimension("CORPO","YSIZE")}

	nCorpo  := aCorpo[4] * 0.95
	nRodape := nCorpo + 20

	oTPanCorpo 	:= TPanel():New(30,00,"",oDlg,,.T.,,Nil,Nil,aCorpo[3],nCorpo)
	oTPanRodape := TPanel():New(nRodape,00,"",oDlg,,.T.,,Nil,Nil,aCorpo[3],aCorpo[4])

	@ -17,0 FOLDER oFolder SIZE aCorpo[3]+2,nCorpo OF oTPanCorpo  PIXEL

	oFolder:AddItem("Engenharia",.T.)
	oFolder:AddItem("Comercial",.T.)
	//Comercial
	@ 20, 10 BUTTON "Engenharia" SIZE 80, 18 PIXEL OF oFolder:aDialogs[1] ACTION navegar(oFolder, 1) WHEN .F.
	@ 40, 10 BUTTON "Comercial" SIZE 80, 18 PIXEL OF oFolder:aDialogs[1] ACTION navegar(oFolder, 2)

	//Tpainel Comercial
	//Group Dados do Produto
	@ 20,100 GROUP oDadoProd TO 70,aCorpo[3]-10 OF oFolder:aDialogs[1] LABEL "Dados do Produto" PIXEL

	@ 35,108 SAY "Produto Desenvolvido" OF oFolder:aDialogs[1] PIXEL
	oGetProdDes := TGet():New( 45, 108, { | u | If( PCount() == 0, cProdDpr, cProdDpr := u ) },oFolder:aDialogs[1], ;
		80, 012, "!@",{|| vldProdDes(cProdDpr, @cVersao, @cDescricao, @nCustoDPR, @cProdBase)}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"cProdDpr",,,,.T.  )
	oGetProdDes:cF3 := "DG0001"
	oGetProdDes:lActive := !lViewMode

	@ 35,200 SAY "Versão" OF oFolder:aDialogs[1] PIXEL
	oGetVersao := TGet():New( 45, 200, { | u | If( PCount() == 0, cVersao, cVersao := u ) },oFolder:aDialogs[1], ;
		80, 012, "!@",{|| .T.}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"cVersao",,,,.T.  )
	oGetVersao:lactive := .F.

	@ 35,300 SAY "Descrição" OF oFolder:aDialogs[1] PIXEL
	oGetDescri := TGet():New( 45, 300, { | u | If( PCount() == 0, cDescricao, cDescricao := u ) },oFolder:aDialogs[1], ;
		180, 012, "!@",{|| .T.}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"cDescricao",,,,.T.  )
	oGetDescri:lactive := .F.

	//Group Custo de Insumos: MOD, GGF e CIf
	@ 75,100 GROUP oDadoCusto TO 125,aCorpo[3]-10 OF oFolder:aDialogs[1] LABEL "Custo de Insumos: MOD, GGF e CIf" PIXEL

	@ 90,108 SAY "Custo DPR" OF oFolder:aDialogs[1] PIXEL
	// @ 130,108 GET oGetDescri VAR nCustoDPR SIZE 80,10 OF oFolder:aDialogs[1] PIXEL PICTURE "@E 99,999,999,999.9999" WHEN .F.
	oGetCustPr := TGet():New( 100, 108, { | u | If( PCount() == 0, nCustoDPR, nCustoDPR := u ) },oFolder:aDialogs[1], ;
		80, 012, "@E 99,999,999,999.9999",{|| .T.}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"nCustoDPR",,,,.T.  )
	oGetCustPr:lActive := !lViewMode

	//Group Outros Custos
	@ 130,100 GROUP oDadoOutrosCustos  TO 180,aCorpo[3]-10 OF oFolder:aDialogs[1] LABEL "Outros Custos" PIXEL

	@ 145,108 SAY "Frete" OF oFolder:aDialogs[1] PIXEL
	// @ 175,108 GET oGetFrete VAR nFrete SIZE 80,10 OF oFolder:aDialogs[1] PIXEL PICTURE "@E 99,999,999,999.9999"
	oGetFrete := TGet():New( 155, 108, { | u | If( PCount() == 0, nFrete, nFrete := u ) },oFolder:aDialogs[1], ;
		80, 012, "@E 99,999,999,999.9999",{|| calcTotal()}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"nFrete",,,,.T.  )
	oGetFrete:lActive := !lViewMode

	@ 145,200 SAY "Tercerização" OF oFolder:aDialogs[1] PIXEL
	// @ 175,200 GET oGetTerc VAR nTerc SIZE 80,10 OF oFolder:aDialogs[1] PIXEL PICTURE "@E 99,999,999,999.9999"
	oGetTerc := TGet():New( 155, 200, { | u | If( PCount() == 0, nTerc, nTerc := u ) },oFolder:aDialogs[1], ;
		80, 012, "@E 99,999,999,999.9999",{|| calcTotal()}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"nTerc",,,,.T.  )
	oGetTerc:lActive := !lViewMode

	@ 145,300 SAY "Outros" OF oFolder:aDialogs[1] PIXEL
	// @ 175,300 GET oGetOutros VAR nOutros SIZE 80,10 OF oFolder:aDialogs[1] PIXEL PICTURE "@E 99,999,999,999.9999"
	oGetOutros := TGet():New( 155, 300, { | u | If( PCount() == 0, nOutros, nOutros := u ) },oFolder:aDialogs[1], ;
		80, 012, "@E 99,999,999,999.9999",{|| calcTotal()}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"nOutros",,,,.T.  )
	oGetOutros:lActive := !lViewMode

	//Tpainel Engenharia
	@ 20, 10 BUTTON "Engenharia" SIZE 80, 18 PIXEL OF oFolder:aDialogs[2] ACTION navegar(oFolder, 1)
	@ 40, 10 BUTTON "Comercial" SIZE 80, 18 PIXEL OF oFolder:aDialogs[2] ACTION navegar(oFolder, 2) WHEN .F.

	//campos da engenharia
	aItems := {'Com Impostos','Sem Impostos'}
	oRadio := TRadMenu():New (20,100,aItems,,oFolder:aDialogs[2],,,,,,,,100,12,,,,.T.)
	oRadio:bSetGet := {|u|IIf (PCount()==0,nRadio,nRadio:=u)}
	oRadio:lHoriz := .T.
	oRadio:lActive := !lViewMode
	oRadio:bChange := {|| onCalcImposto(nOpc)}

	@ 35,100 GROUP oDadoFiscal TO 85,aCorpo[3]-10 OF oFolder:aDialogs[2] LABEL "Fiscal" PIXEL

	@ 50,108 SAY "Tipo de Operação" OF oFolder:aDialogs[2] PIXEL
	oGetTpOper := TGet():New( 60, 108, { | u | If( PCount() == 0, cTpOper, cTpOper := u ) },oFolder:aDialogs[2], ;
		80, 012, "!@",{|| vldTpOper(cTpOper, @cCodCli, @cLoja, @cProdBase, @cTes)}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"cTpOper",,,,.T.  )
	oGetTpOper:cF3 := "SX5DJ"
	oGetTpOper:lActive := !lViewMode

	@ 50,200 SAY "TES" OF oFolder:aDialogs[2] PIXEL
	oGetTES := TGet():New( 60, 200, { | u | If( PCount() == 0, cTes, cTes := u ) },oFolder:aDialogs[2], ;
		80, 012, "!@",{|| .T.}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"cTes",,,,.T.  )
	oGetTES:cF3 := "SF4"
	oGetTES:lActive := !lViewMode

	//dados do clientes
	@ 90,100 GROUP oDadoCliente TO 140,aCorpo[3]-10 OF oFolder:aDialogs[2] LABEL "Dados dos Clientes" PIXEL

	@ 105,108 SAY "Codigo" OF oFolder:aDialogs[2] PIXEL
	oGetCodCli := TGet():New( 115, 108, { | u | If( PCount() == 0, cCodCli, cCodCli := u ) },oFolder:aDialogs[2], ;
		80, 012, "!@",{|| fGetNome(cCodCli, @cLoja, @cNomeCli, @nOpc)}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"cCodCli",,,,.T.  )
	oGetCodCli:cF3 := "SA1"
	oGetCodCli:lActive := !lViewMode

	@ 102,200 SAY "Loja" OF oFolder:aDialogs[2] PIXEL
	oGetLoja := TGet():New( 115, 200, { | u | If( PCount() == 0, cLoja, cLoja := u ) },oFolder:aDialogs[2], ;
		80, 012, "!@",{|| .T.}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"cLoja",,,,.T.  )
	oGetLoja:lActive := .F.

	@ 105,300 SAY "Nome" OF oFolder:aDialogs[2] PIXEL
	oGetNome := TGet():New( 115, 300, { | u | If( PCount() == 0, cNomeCli, cNomeCli := u ) },oFolder:aDialogs[2], ;
		180, 012, "!@",{|| .T.}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"cNomeCli",,,,.T.  )
	oGetNome:lActive := .F.

	//totalizadores
	@ 145,100 GROUP oDadoTotaliza TO 195,aCorpo[3]-10 OF oFolder:aDialogs[2] LABEL "Totalizadores" PIXEL

	@ 160,108 SAY "Total dos Custos" OF oFolder:aDialogs[2] PIXEL
	oGetTotal := TGet():New( 170, 108, { | u | If( PCount() == 0, nTotal, nTotal := u ) },oFolder:aDialogs[2], ;
		80, 012, "@E 99,999,999,999.9999",{|| .T.}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"nTotal",,,,.T.  )
	oGetTotal:lActive := .F.

	@ 160,200 SAY "Total de Impostos" OF oFolder:aDialogs[2] PIXEL
	oGetImpostos := TGet():New( 170, 200, { | u | If( PCount() == 0, _nTotImp, _nTotImp := u ) },oFolder:aDialogs[2], ;
		80, 012, PesqPict( "ZZ1", "ZZ1_IMPOST"),{|| .T.}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"_nTotImp",,,,.T.  )
	oGetImpostos:lActive := .F.

	//margem
	@ 200,100 GROUP oDadoMargem TO 250,aCorpo[3]-10 OF oFolder:aDialogs[2] LABEL "Margem" PIXEL

	@ 215,108 SAY "Margem Bruta Calculada (%)" OF oFolder:aDialogs[2] PIXEL
	oGetMargPer := TGet():New( 225, 108, { | u | If( PCount() == 0, nMaBrCaPer, nMaBrCaPer := u ) },oFolder:aDialogs[2], ;
		80, 012, "@E 999.99",{|| calcTotal()}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"nMaBrCaPer",,,,.T.  )
	oGetMargPer:lActive := !lViewMode

	@ 215,200 SAY "Margem Bruta Calculada Real" OF oFolder:aDialogs[2] PIXEL
	oGetMargButa := TGet():New( 225, 200, { | u | If( PCount() == 0, nMaBrCalcu, nMaBrCalcu := u ) },oFolder:aDialogs[2], ;
		80, 012, "@E 99,999,999,999.9999", {|| calcTotal(1)}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"nMaBrCalcu",,,,.T.  )
	oGetMargPer:lActive := !lViewMode
	//Rodape
	@ 3,100 SAY "Preço Final Unitário" OF oTPanRodape PIXEL FONT oFontn
	oGetTotFin := TGet():New( 15, 100, { | u | If( PCount() == 0, nPrcUnitTot, nPrcUnitTot := u ) },oTPanRodape, ;
		80, 012, "@E 99,999,999,999.9999",{|| .T.}, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"nPrcUnitTot",,,,.T.  )
	oGetTotFin:lActive := .F.

	oFolder:SetOption(1)

	If nOpc == 1 .Or. nOpc == 3  // Visualização ou Editar
		Eval(oGetCodCli:BValid)
		Eval(oGetProdDes:BValid)
		Eval(oRadio:BChange)
	EndIf

	oDlg:Activate(, , , .F., , , bBlocoIni)

Return

Static Function onSave(nOpc, oDlg)
	Local lRet := .F.

	If nOpc == 4
		Processa({|| lRet := saveData(nOpc)}, "Deletando Registro...")
	else
		Processa({|| lRet := saveData(nOpc)}, "Salvando Registro...")
	EndIf

	If lRet
		oDlg:End()
		oDlg:End()
	EndIf

Return lRet

Static Function onCalcImposto(nOpc)

	If oRadio:nOption == 1 .And. (nOpc == 3 .Or. nOpc == 2)
		If Empty(cCodCli) .And. Empty(cTes)
			FWAlertWarning("Informe o Cliente e TES para realizar esta operação", "Aviso")
			oRadio:SetOption(1)
			Return .F.
		EndIf

		Processa({|| lRet := calcImposto()}, "Calculando impostos...")
	elseIf oRadio:nOption == 2
		_nTotImp := 0
		calcTotal()
		oGetImpostos:CtrlRefresh()
	EndIf

Return .T.

Static Function calcTotal(nZig)
	Default nZig := 0

	nTotal := nCustoDPR + nFrete + nTerc + nOutros
	lRet := .T.

	If nMaBrCaPer >= 0 .And. nMaBrCaPer <= 300 //100

		If nZig == 0
			nAuxMargem := (nMaBrCaPer / 100) * nTotal
			nMaBrCalcu := nTotal + nAuxMargem
			nPrcUnitTot := nMaBrCalcu + _nTotImp
		else

			If nMaBrCalcu >= nTotal
				nDIferen := nMaBrCalcu - nTotal

				If nDIferen > 0
					nMaBrCaPer := (nDIferen / nTotal) * 100

					If nMaBrCaPer > 100
						lRet := .T.//.F.
						//nMaBrCaPer := 0
						FWAlertWarning("A Margem Bruta Calculada (%) deve ser entre 0 e 100%", "Atenção")
					EndIf
				else
					nMaBrCaPer := 0
				EndIf
			else
				lRet := .F.
				FWAlertWarning("Valor da margem bruta calculada é inferior a soma do custo DPR", "Aviso")
			EndIf

			nPrcUnitTot := nMaBrCalcu + _nTotImp
		EndIf

		oGetMargPer:CtrlRefresh()
		oGetTotFin:CtrlRefresh()
		oGetMargButa:CtrlRefresh()
	Else
		FWAlertWarning("A Margem Bruta Calculada (%) deve ser entre 0 e 100%", "Atenção")
		//nMaBrCalcu := 0
		lRet := .T.//.F.
	EndIf

Return lRet

Static Function vldTpOper(cTpOper, cCodCli, cLoja, cProdBase, cTes)
	Local lRet := .T.
	Local _cCliente := PadR(cCodCli, TamSx3('A1_COD')[1])
	Local _cLoja := PadR(cLoja, TamSx3('A1_LOJA')[1])

	If !Empty(cTpOper) .And. !Empty(_cCliente) .And. !Empty(_cLoja)
		cTes := MaTESInt(2,cTpOper,_cCliente,_cLoja,"C",cProdBase)
		If EmPty(cTes)
			FWAlertWarning("Tipo de Operação não encontrada!", "Atenção")
			lRet := .F.
		EndIf
	EndIf

Return lRet

Static Function vldProdDes(cProdDes, cVersao, cDescrPrd, nCustoDPR, cProdBase)
	Local lRet := .F.
	Local _cVersao := ""

	cProdDes := PadR(cProdDes, TamSx3('DG0_CDACDV')[1])
	cDescrPrd := ""
	nCustoDPR := 0

	If IsInCallStack("CONPAD1")
		_cVersao := ACPORET[2]
	EndIf

	If ExistCPO('DG0',cProdDes)
		lRet := .T.

		If val(AllTrim(posicione('DG0',1,xfilial('DG0')+cProdDes+_cVersao, "DG0_TPST"))) < 5
			FWAlertWarning("O Produto Desenvolvido não está liberado!", "Atenção")
			lRet := .F.
			Return lRet
		EndIf

		If !IsInCallStack("CONPAD1")
			cVersao    := AllTrim(posicione('DG0',1,xfilial('DG0')+cProdDes, "DG0_NRVRAC"))
		EndIf
		cDacpy      := AllTrim(posicione('DG0',1,xfilial('DG0')+cProdDes+_cVersao, "DG0_CDACPY"))
		nCustoDPR   := posicione('DG0',1,xfilial('DG0')+cProdDes+_cVersao, "DG0_VLCSPO")
		cProdBase   := posicione('DG0',1,xfilial('DG0')+cProdDes+_cVersao, "DG0_XPRBAS")

		calcTotal()

		If !Empty(cDacpy) // Pega a descrição
			cDescrPrd := AllTrim(POSICIONE("CZ3",1,xFilial("DG3")+cDacpy,"CZ3_DSAC"))
		EndIf
	EndIf
Return lRet

Static Function fGetNome(cCodCli, cLoja, cNomeCli, nOpc)
	Local lRet := .F.
	Local _cLoja := ""

	If IsInCallStack("CONPAD1")
		_cLoja := ACPORET[2]
	EndIf

	If !Empty(cCodCli) .And. ExistCPO('SA1',cCodCli)
		lRet := .T.
		If !IsInCallStack("CONPAD1")
			If nOpc == 1 .or. nOpc == 3
				cLoja    := ZZ1->ZZ1_LOJA
			else
				cLoja    := AllTrim(posicione('SA1',1,xfilial('SA1')+cCodCli, "A1_LOJA"))
			EndIf
		EndIf
		cNomeCli := AllTrim(posicione('SA1',1,xfilial('SA1')+cCodCli+_cLoja, "A1_NOME"))
		cTipoCli := AllTrim(posicione('SA1',1,xfilial('SA1')+cCodCli+_cLoja, "A1_TIPO"))
	EndIf
Return lRet

Static Function navegar(oTFolder, nPage)
	oTFolder:ShowPage(nPage)
Return

Static function saveData(nOpc)
	Local lRet		:= .F.
	Local cAlias 	:= "ZZ1"
	Local cChave	:= ""
	Local cCod 		:= ""

	If nOpc == 2
		cCod := GetSxeNum("ZZ1","ZZ1_COD")
	elseIf nOpc == 3
		cCod := ZZ1->ZZ1_COD
	EndIf

	If !empty(cProdDpr) .and. !empty(cVersao) .and. !empty(nCustoDPR)
		dbSelectArea(cAlias)
		/*dbSetOrder(01) // ZZ1_FILIAL+ZZ1_CLIENT+ZZ1_LOJA+ZZ1_PRODDP+ZZ1_VPRODP
		cChave := FWxFilial(cAlias)+PadR(cCodCli, __nTamCodCli)+PadR(cLoja, __nTamLoja)+PadR(cProdDpr, __nTamProCod)+PadR(cVersao, __nTamVersao)
		*/

		dbSetOrder(02) // ZZ1_FILIAL+ZZ1_COD
		cChave := FWxFilial(cAlias)+cCod

		If nOpc == 2 .Or. nOpc == 3
			If (!ZZ1->(dbSeek(cChave)))
				If ZZ1->(Reclock(cAlias, .T.))
					ZZ1->ZZ1_COD 	:= cCod
					ZZ1->ZZ1_FILIAL := FWxFilial("ZZ1")
					ZZ1->ZZ1_PRODDP	:= allTrim(cProdDpr)
					ZZ1->ZZ1_VPRODP	:= alltrim(cVersao)
					ZZ1->ZZ1_PROBAS	:= allTrim(cProdBase)
					ZZ1->ZZ1_DSCVDP	:= alltrim(cDescricao)
					ZZ1->ZZ1_CSTFRT	:= nFrete
					ZZ1->ZZ1_CSTTER	:= nTerc
					ZZ1->ZZ1_CSTOUT	:= nOutros
					ZZ1->ZZ1_OPER  	:= alltrim(cTpOper)
					ZZ1->ZZ1_TES   	:= allTrim(cTes)
					ZZ1->ZZ1_CLIENT	:= alltrim(cCodCli)
					ZZ1->ZZ1_LOJA  	:= allTrim(cLoja)
					ZZ1->ZZ1_NOME  	:= allTrim(cNomeCli)
					ZZ1->ZZ1_TTCUST	:= nTotal
					ZZ1->ZZ1_MRGCAL	:= nMaBrCaPer
					ZZ1->ZZ1_PRCUNI	:= nCustoDPR
					ZZ1->ZZ1_MRGREA	:= nMaBrCalcu
					ZZ1->ZZ1_IMPOST := _nTotImp
					ZZ1->( ConfirmSx8())
					ZZ1->(msUnlock())
					lRet := .T.
				else
					ZZ1->(RollbackSx8())
				EndIf
			Else
				If ZZ1->(Reclock(cAlias, .F.))
					ZZ1->ZZ1_PRODDP	:= allTrim(cProdDpr)
					ZZ1->ZZ1_VPRODP	:= alltrim(cVersao)
					ZZ1->ZZ1_PROBAS	:= allTrim(cProdBase)
					ZZ1->ZZ1_DSCVDP	:= alltrim(cDescricao)
					ZZ1->ZZ1_CSTFRT	:= nFrete
					ZZ1->ZZ1_CSTTER	:= nTerc
					ZZ1->ZZ1_CSTOUT	:= nOutros
					ZZ1->ZZ1_OPER  	:= alltrim(cTpOper)
					ZZ1->ZZ1_TES   	:= allTrim(cTes)
					ZZ1->ZZ1_CLIENT	:= alltrim(cCodCli)
					ZZ1->ZZ1_LOJA  	:= allTrim(cLoja)
					ZZ1->ZZ1_NOME  	:= allTrim(cNomeCli)
					ZZ1->ZZ1_TTCUST	:= nTotal
					ZZ1->ZZ1_MRGCAL	:= nMaBrCaPer
					ZZ1->ZZ1_PRCUNI	:= nCustoDPR
					ZZ1->ZZ1_MRGREA	:= nMaBrCalcu
					ZZ1->ZZ1_IMPOST := _nTotImp
					ZZ1->(msUnlock())
					lRet := .T.
				else
					ZZ1->(RollbackSx8())
				EndIf
			EndIf
		else
			lRet := .T.
		EndIf
	else
		FwAlertInfo("VerIfique os campos da aba Engenharia!" + CRLF + "Campos obrigatórios:" + CRLF + "* Produto Desenvolvido" + CRLF + "* Versão" +CRLF + "* Custo DPR")
		lRet := .F.
	EndIf

return lRet

static function calcImposto()
	Local nQuant 	:= 1
	Local nVlrTotal := 0

	//Posiciona no cliente atual
	DbSelectArea("SA1")
	SA1->(dbSetOrder(1))
	SA1->(DbSeek(FWxFilial("SA1")+cCodCli+cLoja))

	nVlUnit   := nMaBrCalcu
	nVlrTotal := nQuant * nMaBrCalcu

	//Inicializa a função fiscal para poder simular os valores dos impostos
	MaFisIni(cCodCli, cLoja, "C", "S", cTipoCli, , , .F., "SB1")

	//Posiciona no produto atual
	DbSelectArea("SB1")
	SB1->(DbSeek(FWxFilial("SB1") + cProdBase))

	//Adicionando o produto para o cálculo dos impostos
	MaFisAdd(cProdBase, cTes, nQuant, nVlUnit, 0, "", "", , 0, 0, 0, 0, nVlrTotal, 0, SB1->(RecNo()))

	//Retorna a alíquota de IPI e de ICMS do item 1
	nAliqIPI := MaFisRet(1, 'IT_ALIQIPI')
	nAliqICM := MaFisRet(1, 'IT_ALIQICM')

	//Se tiver alíquota de IPI
	If(nAliqIPI > 0)
		cMensIPI := "IPI Não Incluso"
	EndIf

	_nTotImp := nAliqIPI + nAliqICM
	calcTotal()
	oGetImpostos:CtrlRefresh()

	//Encerra a função fiscal
	MaFisEnd()
return
