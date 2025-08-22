#Include 'protheus.ch'
#Include 'totvs.ch'
#Include "FWMVCDEF.ch"

User Function XFAT003() // TST001
	Local oDlg
	Local aRet          := {}
	Local lRet          := .F.
	Local cDescriSay    := 'Consulta'
	Local oSay              := NIL
	Local nX            := 0
	Private oLbx
	Private aCpos       := {}
	Private cRet        := ''
	Public __cRetorno   := ""

	chkFile("ZLI")

	DBSelectArea("ZLI")
	ZLI->(dbGoTop())
	if ZLI->(Eof()) // Verifica se possui registros, Caso não iremos da um insert
		aImpostos := {{"01", "Orçamento com impostos Inclusos (ICMS 12% + PIS 1,65% + COFINS 7,60%) "},;
			{"02", "Diferimento parcial do ICMS de acordo com o art. 28, inciso I, Anexo VIII do Decreto 7.871/2017(RICMS/PR), sendo: 38,46% "},;
			{"03", "Orçamento com impostos inclusos (ICMS 7% + PIS 1,65% + COFINS 7,60%) "},;
			{"04", "Orçamento com 7% de ICMS incluso"}}

		for nX := 1 to len(aImpostos)
			RecLock("ZLI", .T.)
			ZLI->ZLI_FILIAL  := FWxFilial('ZLI')
			ZLI->ZLI_CHAVE   := aImpostos[nX][1]
			ZLI->ZLI_DESC    := aImpostos[nX][2]
			ZLI->(MsUnlock())
		next
	endif

	FWMsgRun(, {|oSay| fMontaArray(oSay) }, cDescriSay, "Carregando dados...")

	DEFINE MSDIALOG oDlg TITLE "Consulta" FROM 0,0 TO 250,700 PIXEL

	@ 001,001 LISTBOX oLbx FIELDS HEADER 'Chave','Descrição' SIZE 350,95 OF oDlg PIXEL

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
	Local cQuery := ""
    Local cAlias := GetNextAlias()
 
    aCpos := {}
    cQuery := " SELECT ZLI_CHAVE,ZLI_DESC "+ CRLF
    cQuery += " FROM " + RetSqlName("ZLI") + " " +CRLF
    cQuery += " WHERE D_E_L_E_T_ = ' ' "+CRLF
    cQuery += " AND ZLI_FILIAL  = '" + xFilial("ZLI") + "' "+CRLF
 
    cQuery := ChangeQuery(cQuery)
 
    dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAlias,.T.,.T.)
 
    While (cAlias)->(!Eof())
        aAdd(aCpos,{(cAlias)->(ZLI_CHAVE),;
            AllTrim((cAlias)->(ZLI_DESC))})
        (cAlias)->(dbSkip())
    End
    (cAlias)->(dbCloseArea())

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
