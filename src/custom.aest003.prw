#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
#Include "FWEVENTVIEWCONSTS.CH"


/*/{Protheus.doc} AEST003
	Informar Mistura

	@type User Function
	@author Tiago Cunha
	@since 01/07/2025
	@version 1.0.0
/*/
User Function AEST003()
	Local aArea          := GetArea()
	Local getNumero
	Local oFont1 	       := TFont():New( "Tahoma", , -13, .T.)
	Local getRequisicao
	Local nOpca          := 0

	Private cetRequisicao  := Space(TamSX3("ZS1_NUMREQ")[1])
	Private cetNumero      := Space(TamSX3("D4_OP")[1])
	Private oDlgGrp
	Private oPanGrid
	Private oGetGrid
	Private aHeaderGrid := {}
	Private aColsGrid   := {}
	Private oDlgOP

	DEFINE MSDIALOG oDlgOP TITLE "Informar Mistura" FROM 000, 000  TO 180, 380 COLORS 0, 16777215 PIXEL

	@ /*025*/38, 015 SAY "Número da OP:" 	 			SIZE 065, 010 OF oDlgOP FONT oFont1 PIXEL
	@ /*040*/56, 015 SAY "Requisição:"	 		SIZE 065, 010 OF oDlgOP FONT oFont1  PIXEL

	@ /*025*/35, 070 MSGET getNumero 	VAR cetNumero 	SIZE 075, 010 OF oDlgOP COLORS 0, 16777215 PIXEL F3 "SC2"
	@ /*025*/56, 070 MSGET getRequisicao	VAR cetRequisicao 	SIZE 075, 010 OF oDlgOP COLORS 0, 16777215 PIXEL  F3 "ZS1"

	ACTIVATE MSDIALOG oDlgOP CENTERED ON INIT EnchoiceBar(oDlgOP,{||tudoOK(@nOpca)},{|| nOpca := 1,oDlgOP:End()})

	If nOpca == 2 //BOTÃO OK
		FwMsgRun(,{ || callEvw() }, 'Informar Mistura', 'Enviando Notificação...')
	endIF

	RestArea(aArea)
Return


Static Function callEvw()

	ZS1->(dbSetOrder(3))
	if ZS1->(dbSeek(FWxFilial("ZS1")+AllTrim(cetRequisicao)))

		cMensagem := "Número da Ordem de Produção: " + ZS1->ZS1_OP + CHR(13) + CHR(10)
		cMensagem += "Número do Lote: " + allTrim(ZS1->ZS1_LOTECTL) + CHR(13) + CHR(10)
		cMensagem += "Código do Produto: " + allTrim(ZS1->ZS1_CODPRO) + CHR(13) + CHR(10)
		cMensagem += "Descrição do Produto: " + allTrim(ZS1->ZS1_DESCPR) + CHR(13) + CHR(10)
		cMensagem += "Data e Hora Fim da Separação: " + DToC(ZS1->ZS1_DTFSEP) + " " + ZS1->ZS1_HRFSEP + CHR(13) + CHR(10)
		cMensagem += "Tipo de Separação: " + AcaX3Combo("ZS1_TIPO",ZS1->ZS1_TIPO) + CHR(13) + CHR(10)

		// Pega os dados da requisição para enviar o EventViewer
		U_AEST003EW(cMensagem)

	endif
Return

Static Function AcaX3Combo(cCampo,cConteudo)
	Local aSx3Box   := RetSx3Box( Posicione("SX3", 2, cCampo, "X3CBox()" ),,, 1 )
	If cConteudo == ""
		cConteudo := " "
	EndIf
Return AllTrim( aSx3Box[Ascan( aSx3Box, { |aBox| aBox[2] = cConteudo } )][3] )


Static Function tudoOK(nOpca as numeric)
	Local lContinua := .T.

	// Verifica se informou a requisição
	If Empty(cetRequisicao)
		FWAlertWarning("Informe a requisição.", "Aviso")
		lContinua := .F.
	EndIf

	// Verifica se informou a OP
	If lContinua .And. Empty(cetNumero)
		FWAlertWarning("Informe a OP.", "Aviso")
	EndIf

	if lContinua
			ZS1->(dbSetOrder(3)) // filial + req
			if !ZS1->(dbSeek(FWxFilial("ZS1")+cetRequisicao))
				FWAlertWarning("Requisição informada não encontrada.", "Aviso")
				lContinua := .F.
			endIf
	endif

	if !lContinua
		Return
	endif

	nOpca := 2
	oDlgOP:End()
Return

/*/{Protheus.doc} AEST003EW
	Notifica o usuário

	@type User Function
	@author Tiago Cunha
	@since 01/07/2025
	@version 1.0.0
/*/
User Function AEST003EW(cMensagem)
	Local cEventID as character
	Local cTitulo as character

	cEventID  := "Z01" //Evento cadastrado na tabela E3

	cTitulo := 'Iniciar Inspeção'

	EventInsert(FW_EV_CHANEL_ENVIRONMENT, FW_EV_CATEGORY_MODULES, cEventID, FW_EV_LEVEL_INFO, "", cTitulo, cMensagem, .T.)

Return


User Function TstEW()
    Local cEventID as character
    Local cMensagem as character
    Local cTitulo as character
 
 
    cEventID  := "Z01" //Evento cadastrado na tabela E3
 
    cMensagem  := "Evento enviado com sucesso."
 
    cTitulo:='Teste do Event Viewer'      
 
    EventInsert(FW_EV_CHANEL_ENVIRONMENT, FW_EV_CATEGORY_MODULES, cEventID, FW_EV_LEVEL_INFO, "", cTitulo, cMensagem, .T.)
 
Return
