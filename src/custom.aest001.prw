#Include "Totvs.ch"
#INCLUDE "FWMVCDEF.CH"


/*/{Protheus.doc} AEST001
	MVC Separa��o

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
	oBrowse:SetDescription("Separa��o e Pesagem")
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

	aAdd(aRotina, {'Incluir'           , 'alert("Incluir")'                        , 0, 3, 0, NIL})
	aAdd(aRotina, {'Separar'           , 'VIEWDEF.CUSTOM.AEST001'              , 0, 4, 0, NIL})
	aAdd(aRotina, {'Estornar Sep'      , 'U_AEST001B()'                   , 0, 4, 0, NIL})
	aAdd(aRotina, {'Priorizar'         , 'U_AEST001A()'                        , 0, 4, 0, NIL})
	aAdd(aRotina, {'Visualizar'        , 'VIEWDEF.CUSTOM.AEST001'              , 0, 4, 0, NIL})
	aAdd(aRotina, {'Transf. p/ WIP'    , 'U_AEST001C()'                        , 0, 4, 0, NIL})
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
	oModel:SetDescription('Separa��o e pesagem')

	oModel:addFields('MODEL_ZS1',,oStrZS1)
	oModel:SetPrimaryKey({'ZS1_FILIAL', 'ZS1_NUMREQ'})

	oModel:AddGrid("MODEL_ZS2", "MODEL_ZS1", oStrZS2)

	oModel:SetRelation("MODEL_ZS2", {{"ZS2_FILIAL", "ZS1_FILIAL" }, {"ZS2_NUMREQ", "ZS1_NUMREQ"}}, ZS2->(IndexKey(1)))
	// oModel:GetModel('MODEL_ZZB'):SetNoInsertLine(.T.)
	// oModel:GetModel('MODEL_ZZB'):SetUniqueLine({'ZZB_ITEM', 'ZZB_PROD'})

	// oModel:GetModel("MODEL_ZZA"):SetFldNoCopy({'ZZA_ID'})
	oModel:GetModel('MODEL_ZS1'):SetDescription('Separa��o e pesagem')

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

	oView := FWFormView():New()
	oView:SetModel(oModel)

	oView:AddField('VIEW_ZS1', oStrZS1, 'MODEL_ZS1')
	oView:AddGrid("VIEW_ZS2",  oStrZS2, "MODEL_ZS2")

	oView:CreateHorizontalBox('BOX_ZS1', 030)
	oView:CreateHorizontalBox('BOX_ZS2', 070)

	oView:SetOwnerView('VIEW_ZS1', 'BOX_ZS1')
	oView:SetOwnerView('VIEW_ZS2', 'BOX_ZS2')

	oView:AddIncrementField('VIEW_ZS2', 'ZS2_ITEM')

Return(oView)


/*/{Protheus.doc} AEST001A
	Prioriza��o

	@type User Function
	@author Tiago Cunha
	@since 01/07/2025
	@version 1.0.0
/*/
User Function AEST001A()
	Local cUsrsAltor := GetMv("MV_USRPRI", .F., "000000")
	Local cUser      := RetCodUsr()

	// Se o usu�rio possui permiss�o para realizar essa a��o
	if cUser $ cUsrsAltor
		RecLock("ZS1", .F.)
		ZS1->ZS1_REQPRI := "1" // Sim
		ZS1->(MsUnlock())

		FWAlertSuccess("Requisi��o priorizada com sucesso", "Sucesso")
	else
		FWAlertWarning("Usu�rio n�o autorizado para realizar a prioriza��o", "Aviso")
	endif
Return


/*/{Protheus.doc} AEST001B
	Estorno da separa��o

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
			FWAlertWarning("Op apontada n�o pode ser estornada", "Aviso")
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

		// Realiza o processo de estorno da separa��o
		if lContinua

		endif

	endif
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
	private cEndProd := ""
	local lContinua := .T.

	SB1->(dbSetOrder(1))
	if SB1->(dbSeek(FWxFilial("SB1")+ZS1->ZS1_CODPROD))

		if SB1->B1_LOCALIZ == "S"
			cEndProd := FWInputBox("Informe o Endere�o do Produto onde ser� armazenado:", "")
		endif
	endif

	// Valida se todos os ZS2 foram separados
	ZS2->(dbSetOrder(1))
	if ZS2->(dbSeek(FWxFilial("ZS2")+ZS1->ZS1_OP))
	  cMsg := ""

		While ZS2->(!EOF()) .And. AllTrim(ZS2->ZS2_OP) == AllTrim(ZS1->ZS1_OP)
			if ZS2->ZS2_SLDREQ <> 0
				lContinua := .F.
	  		cMsg      += "Produto " + AllTrim(ZS2->ZS2_CODEMP) + " n�o foi separado completamente, finalize a separa��o antes de realizar o envio para WIP." + CHR(13) + CHR(10)
			endif

			ZS2->(dbSkip())
		End

		if !lContinua
			u_zMsgLog( "Transf WIP" + CHR(13) + CHR(10) + cMsg, "Sucesso", 1, .F. )
		else
						aCab := {;
				{"D3_DOC"     , cNumDocD3                , NIL},;
				{"D3_TM"      , cTMProd                  , NIL},;
				{"D3_CC"      , Space(TamSX3("D3_CC")[1]), NIL},;
				{"D3_EMISSAO" , dDataBase                , NIL} ;
				}

			//MSExecAuto({|x,y| mata261(x,y)}, aAuto, 3)
			MSExecAuto({|x,y,z| MATA241(x,y,z)}, aCab, aItens, 3)
		endif
	endif

Return


/*/{Protheus.doc} zMsgLog
  Fun��o que mostra uma mensagem de Log com a op��o de salvar em txt

  @type function
  @author Tiago Cunha
  @since 28/03/2024
  @version 1.0.0
  @param cMsg, character, Mensagem de Log
  @param cTitulo, character, T�tulo da Janela
  @param nTipo, num�rico, Tipo da Janela (1 = Ok; 2 = Confirmar e Cancelar)
  @param lEdit, l�gico, Define se o Log pode ser editado pelo usu�rio
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

	//Definindo os textos dos bot�es
	If(nTipo == 1)
		cTxtConf:='&Ok'
	Else
		cTxtConf:='&Confirmar'
		cTxtCancel:='C&ancelar'
	EndIf

	//Criando a janela centralizada com os bot�es
	DEFINE MSDIALOG oDlgMens TITLE cTitulo FROM 000, 000  TO 300, 400 COLORS 0, 16777215 PIXEL
	//Get com o Log
	@ 002, 004 GET oMsg VAR cMsg OF oDlgMens MULTILINE SIZE 191, 121 FONT oFntTxt COLORS 0, 16777215 HSCROLL PIXEL
	If !lEdit
		oMsg:lReadOnly := .T.
	EndIf

	//Se for Tipo 1, cria somente o bot�o OK
	If (nTipo==1)
		@ 127, 144 BUTTON oBtnOk  PROMPT cTxtConf   SIZE 051, 019 ACTION (lRetMens:=.T., oDlgMens:End()) OF oDlgMens PIXEL

		//Sen�o, cria os bot�es OK e Cancelar
	ElseIf(nTipo==2)
		@ 127, 144 BUTTON oBtnOk  PROMPT cTxtConf   SIZE 051, 009 ACTION (lRetMens:=.T., oDlgMens:End()) OF oDlgMens PIXEL
		@ 137, 144 BUTTON oBtnCnc PROMPT cTxtCancel SIZE 051, 009 ACTION (lRetMens:=.F., oDlgMens:End()) OF oDlgMens PIXEL
	EndIf

	//Bot�o de Salvar em Txt
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

	//Se o nome n�o estiver em branco
	If !Empty(cPath)
		// //Teste de exist�ncia do diret�rio
		// If !ExistDir(SubStr(cFileNom,1,RAt('\',cFileNom)))
		// 	Alert("Diret�rio n�o existe:" + CRLF + SubStr(cFileNom, 1, RAt('\',cFileNom)) + "!")
		// 	Return
		// EndIf

		//Montando a mensagem
		cTexto := "Fun��o   - "+ FunName()       + CRLF
		cTexto += "Usu�rio  - "+ cUserName       + CRLF
		cTexto += "Data     - "+ dToC(dDataBase) + CRLF
		cTexto += "Hora     - "+ Time()          + CRLF
		cTexto += "Mensagem - "+ cTitulo + cQuebra  + cMsg + cQuebra + CRLF

		// //Testando se o arquivo j� existe
		// If File(cFileNom)
		// 	lOk := MsgYesNo("Arquivo j� existe, deseja substituir?", "Aten��o")
		// EndIf

		MemoWrite(cPath + cFileNom, cTexto)
		MsgInfo("Arquivo Gerado com Sucesso:"+ CRLF + cFileNom, "Aten��o")

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
        MsgStop("N�o foi poss�vel abrir o arquivo " + cDirP + cNomeArqP + "!", "Aten��o")
    EndIf 
     
    RestArea(aArea)
Return
