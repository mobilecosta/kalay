#Include 'protheus.ch'
#Include 'totvs.ch'
#Include "FWMVCDEF.ch"

User Function CFG0001() // TST001
	Local oDlg
	Local aRet          := {}
	Local lRet          := .F.
	Local cDescriSay    := 'Consulta'
	Local oSay              := NIL
	Private oLbx
	Private aCpos       := {}
	Private cRet        := ''
	Public __cRetorno   := ""

	FWMsgRun(, {|oSay| fMontaArray(oSay) }, cDescriSay, "Carregando dados...")

	DEFINE MSDIALOG oDlg TITLE "Consulta de Moedas" FROM 0,0 TO 250,500 PIXEL

	@ 001,001 LISTBOX oLbx FIELDS HEADER 'Moeda','Descrição' SIZE 250,95 OF oDlg PIXEL

	oLbx:SetArray( aCpos )
	oLbx:bLine      := {|| aCpos[oLbx:nAt]}
	oLbx:bLDblClick := {|| {oDlg:End(), lRet:=.T.,aRet := oLbx:aArray[oLbx:nAt]} }

	oTBtn2 := TButton():New( 108, 160, "Cancelar",oDlg,{|| oDlg:End() }, 040, 010,,,.F.,.T.,.F.,,.F.,,,.F. )
	oTBtn2 := TButton():New( 108, 210, "Selecionar",oDlg,{|| oDlg:End(), lRet:=.T., aRet := oLbx:aArray[oLbx:nAt] }, 040, 010,,,.F.,.T.,.F.,,.F.,,,.F. )

	ACTIVATE MSDIALOG oDlg CENTER

	If Len(aRet) > 0 .And. lRet
		If Empty(aRet[1])
			lRet := .F.
		Else
			__cRetorno := aRet[1]
			lRet := .T.
		EndIf
	EndIf

Return lRet


Static Function fMontaArray(oSay,cCliNome,cCliCod,cGetDocCli)
	Local nX := 0

	for nX := 1 to 5
		aAdd(aCpos,{cValToChar(nX), &("getMV('MV_MOEDA" + cValToChar(nX) + "')")})
	next

	If Len(aCpos) < 1
		aAdd(aCpos,{" "," "," "," ", " "})
	EndIf

	IF ValType(oLbx) == 'O'
		oLbx:SetArray( aCpos )
		oLbx:bLine     := {|| aCpos[oLbx:nAt]}
		oLbx:nAt := 1
		oLbx:refresh()
	EndIF

Return
