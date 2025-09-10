#include "protheus.ch"
#include "rwmake.ch"
#include "topconn.ch"
#INCLUDE "TBICONN.CH"
#include 'totvs.ch'
#Include 'FWMVCDef.ch'
#Include "FWPrintSetup.ch"
#INCLUDE "RPTDEF.CH"
#INCLUDE "colors.ch"

/*/{Protheus.doc} REST001a
FwMarkBrowse para exibir os itens do documento de entrada a serem impressos.
@type  User Function
@author Tiago Cunha
@since 01/08/2025
@version 1.0
/*/
User Function REST001a()

	Local aArea   := GetArea()

	Private aCpoInfo  := {}
	Private aCampos   := {}
	Private aCpoData  := {}
	Private oTable    := Nil
	Private oBrowse   := Nil
	Private aRotBKP   := {}

	Private dDigit	  As Date
	Private cNumReq   As Character

	Private aTexto  := {}
	Private nQuant  := 0
	Private nCaixas := 0
	Private nResto  := 0
	Private cEnter  := Chr(13) + Chr(10)

	cNumReq := ZS1->ZS1_NUMREQ

	FwMsgRun(,{ || fLoadData() }, "Imprimir Etiquetas", 'Carregando dados...')

	oBrowse := FwMBrowse():New()

	oBrowse:SetAlias('TRB')
	oBrowse:SetTemporary(.T.)

	oBrowse:AddMarkColumns(;
		{|| If(TRB->TMP_OK = "S", "LBOK", "LBNO")},;
		{|| SelectOne(oBrowse)             },;
		{|| SelectAll(oBrowse)             };
		)

	oBrowse:SetColumns(aCampos)

	oBrowse:SetEditCell( .T. ) 			// indica que o grid é editavel

	// oBrowse:acolumns[7]:ledit    := .T. // informa qual coluna é editável
	// oBrowse:acolumns[7]:cReadVar := 'TMP_QTD'

	// oBrowse:acolumns[8]:ledit    := .T. // informa qual coluna é editável
	// oBrowse:acolumns[8]:cReadVar := 'TMP_QTDETQ'

	oBrowse:AddButton("Confirmar"	,"u_REST001b()",,1)

	oBrowse:SetMenuDef('custom.REST001')

	oBrowse:SetDescription('Seleção de itens para impressão')

	oBrowse:Activate()

	If(Type('oTable') <> 'U')
		oTable:Delete()
		oTable := Nil
	Endif

	RestArea(aArea)

Return

/*/{Protheus.doc} fLoadData
Rotina para inserir dados da tabela temporaria do MarkBrowse
@author Claudio Bozzi
@since 01/02/2023
@version 1.0
/*/
Static Function fLoadData()

	Local nI      := 0
	Local _cAlias := GetNextAlias()

	If(Type('oTable') <> 'U')
		oTable:Delete()
		oTable := Nil
	Endif

	oTable := FwTemporaryTable():New('TRB')

	aCampos  := {}
	aCpoInfo := {}
	aCpoData := {}

	aAdd(aCpoInfo, {'Marcar'  		, '@!' 						, 1							})
	aAdd(aCpoInfo, {'Item'			, '@!' 						, TamSx3('ZS2_ITMREQ')[1]		})
	aAdd(aCpoInfo, {'Código'  		, '@!' 						, TamSx3('ZS2_CODEMP')[1]		})
	aAdd(aCpoInfo, {'Descrição'   	, '@!' 						, TamSx3('ZS2_DSCEMP')[1]		})
	aAdd(aCpoInfo, {'OP'  			, '@!' 						, TamSx3('ZS2_OP')[1]		})
	aAdd(aCpoInfo, {'Qtd. Etiquetas', '@E 999,999' 				, 6							})

	aAdd(aCpoData, {'TMP_OK'      , 'C'                     , 1                       	, 0							})
	aAdd(aCpoData, {'TMP_ITEM' 	  , TamSx3('ZS2_ITMREQ')[3] 	, TamSx3('ZS2_ITMREQ')[1] 		, 0							})
	aAdd(aCpoData, {'TMP_COD'  	  , TamSx3('ZS2_CODEMP')[3] 	, TamSx3('ZS2_CODEMP')[1] 		, 0							})
	aAdd(aCpoData, {'TMP_DESC'    , TamSx3('ZS2_DSCEMP')[3]    , TamSx3('ZS2_DSCEMP')[1]    	, 0							})
	aAdd(aCpoData, {'TMP_OP'      , TamSx3('ZS2_OP')[3] 		, TamSx3('ZS2_OP')[1] 		, 0							})
	aAdd(aCpoData, {'TMP_QTDETQ'  , TamSx3('D1_QUANT')[3]   , 6   						, 0							})

	For nI := 1 To Len(aCpoData)

		If(aCpoData[nI, 1] <> 'TMP_OK' .and. aCpoData[nI, 1] <> 'TMP_RECNO')

			aAdd(aCampos, FwBrwColumn():New())

			aCampos[Len(aCampos)]:SetData( &('{||' + aCpoData[nI,1] + '}') )
			aCampos[Len(aCampos)]:SetTitle(aCpoInfo[nI,1])
			aCampos[Len(aCampos)]:SetPicture(aCpoInfo[nI,2])
			aCampos[Len(aCampos)]:SetSize(aCpoData[nI,3])
			aCampos[Len(aCampos)]:SetDecimal(aCpoData[nI,4])

		EndIf

	next

	oTable:SetFields(aCpoData)
	oTable:Create()

	BeginSql Alias _cAlias

        SELECT ZS2_ITMREQ, ZS2_NUMREQ, ZS2_CODEMP, ZS2_DSCEMP, ZS2_OP
          FROM %TABLE:ZS2% ZS2
         WHERE ZS2.ZS2_FILIAL  = %xFilial:ZS2%
           AND ZS2.ZS2_NUMREQ     = %Exp:cNumReq%
           AND ZS2.%NOTDEL%
		   ORDER BY ZS2.ZS2_ITMREQ
	EndSQL

	(_cAlias)->(DbGoTop())

	DbSelectArea('TRB')

	While(!(_cAlias)->(EoF()))

		RecLock('TRB', .T.)

		TRB->TMP_OK 	  := 'S'
		TRB->TMP_ITEM := (_cAlias)->ZS2_ITMREQ
		TRB->TMP_COD  := (_cAlias)->ZS2_CODEMP
		TRB->TMP_DESC := (_cAlias)->ZS2_DSCEMP
		TRB->TMP_OP   := (_cAlias)->ZS2_OP

		TRB->TMP_QTDETQ  := 1

		TRB->(MsUnlock())

		(_cAlias)->(DbSkip())

	EndDo

	TRB->(DbGoTop())

	(_cAlias)->(DbCloseArea())

Return

Static Function SelectOne(oBrowse)

	Local aArea  := TRB->(GetArea())
	Local cMarca := "N"

	cMarca := IIF(TRB->TMP_OK = "S", "N", "S")

	RecLock("TRB", .F.)
	TRB->TMP_OK := cMarca
	TRB->(MsUnlock())

	RestArea(aArea)

	oBrowse:Refresh()

	FWFreeVar(@aArea)
	FWFreeVar(@cMarca)

Return .T.

Static Function SelectAll(oBrowse)

	Local aArea  := TRB->(GetArea())
	Local cMarca := "N"

	TRB->(DBGoTop())

	cMarca := IIF(TRB->TMP_OK = "S", "N", "S")

	While TRB->(!Eof())

		RecLock("TRB", .F.)
		TRB->TMP_OK := cMarca
		TRB->(MsUnlock())

		TRB->(DBSkip())
	End

	RestArea(aArea)

	oBrowse:Refresh()

	FWFreeVar(@aArea)
	FWFreeVar(@cMarca)

Return

/*/{Protheus.doc} REST001b
	Função responsavel por gerar a impressão da etiqueta de entrada, chamada pelo PE MT103FIM e via menu MA103OPC.
	@author Claudio Bozzi
	@since 30/06/2022
	@version 1.0
	@param Nil
	@return Nil
/*/
User Function REST001b()

	Private aArea := GetArea()
	Private nPag  := 0

	Private oPrinter 		:= Nil

	oPrinter := GetPrinter()

	Private oArial6   := TFont():New("Arial",,6,,.f.,,,,,.f.,.f.)
	Private oArial6N  := TFont():New("Arial",,6,,.t.,,,,,.f.,.f.)
	Private oArial8   := TFont():New("Arial",,8,,.f.,,,,,.f.,.f.)
	Private oArial8N  := TFont():New("Arial",,8,,.t.,,,,,.f.,.f.)
	Private oArial10  := TFont():New("Arial",,10,,.f.,,,,,.f.,.f.)
	Private oArial10N := TFont():New("Arial",,10,,.t.,,,,,.f.,.f.)
	Private oArial12  := TFont():New("Arial",,12,,.f.,,,,,.f.,.f.)
	Private oArial12N := TFont():New("Arial",,12,,.t.,,,,,.f.,.f.)
	Private oArial15  := TFont():New("Arial",,15,,.f.,,,,,.f.,.f.)
	Private oArial15N := TFont():New("Arial",,15,,.t.,,,,,.f.,.f.)
	Private oArial17N := TFont():New("Arial",,17,,.t.,,,,,.f.,.f.)

	If oPrinter != Nil
		FwMsgRun(, {|| TratarImp()}, "Executando...", "Executando impressão.")
	EndIf

	RestArea(aArea)

Return

Static Function TratarImp()
	Local nX := 0

	Private nVolume := 0

	BeginSql Alias "TMPETIQ"

		SELECT ZS2_ITMREQ, ZS2_NUMREQ, ZS2_CODEMP, ZS2_DSCEMP, ZS2_DTEMP, ZS2_OP, ZS2_PESLIQ, ZS2_PESBRT, ZS2_TARA, B1_UM
				FROM %TABLE:ZS2% ZS2
				INNER JOIN %TABLE:SB1% SB1
				ON SB1.B1_FILIAL  = %xFilial:SB1% AND SB1.B1_COD = ZS2.ZS2_CODEMP
				WHERE ZS2.ZS2_FILIAL  = %xFilial:ZS2%
					AND ZS2.ZS2_NUMREQ  = %Exp:cNumReq%
					AND ZS2.%NOTDEL%
					AND SB1.%NOTDEL%
			ORDER BY ZS2.ZS2_ITMREQ

	EndSql

	If TMPETIQ->(Eof())
		MsgAlert('Não há dados para impressão de etiqueta para o produto informado', 'Atenção')
	EndIf

	TRB->(DBGoTop())

		Do While ! TMPETIQ->(Eof())

			If TRB->TMP_OK = "N"
				TRB->(DBSkip())
				TMPETIQ->(DbSkip())
				Loop
			EndIf

			For nX := 1 To TRB->TMP_QTDETQ
				MontarImp()
			Next

			TMPETIQ->(DbSkip())
			TRB->(DBSkip())
		Enddo

		TMPETIQ->(DbCloseArea())

		oPrinter:Preview()

Return

Static Function MontarImp()
  Private nRow    := 15
	Private nCol    := 5

	oPrinter:SetPaperSize(0, 50, 50)
	oPrinter:SetMargin(001,001,001,001)
	oPrinter:StartPage()

	nRow += 20
	oPrinter:SayAlign(nRow, nCol, DToC(SToD(TMPETIQ->ZS2_DTEMP)), oArial10, 130, 50,, 2, 0)
	nRow += 10
	oPrinter:SayAlign(nRow, nCol, AllTrim(TMPETIQ->ZS2_CODEMP), oArial10, 130, 50,, 2, 0)
	nRow += 10

	cDesc := PadR(TMPETIQ->ZS2_DSCEMP, 26)
	oPrinter:SayAlign(nRow, nCol, AllTrim(cDesc), oArial10, 130, 50,, 2, 0)
	nRow += 10
	oPrinter:SayAlign(nRow, nCol, TMPETIQ->ZS2_OP, oArial10, 130, 50,, 2, 0)
	nRow += 10
	oPrinter:SayAlign(nRow, nCol, AllTrim(TMPETIQ->ZS2_NUMREQ), oArial10, 130, 50,, 2, 0)
	nRow += 10
	oPrinter:SayAlign(nRow, nCol, AllTrim(Transf( TMPETIQ->ZS2_PESBRT , PesqPict("ZS2","ZS2_PESBRT") )) + " " + AllTrim(TMPETIQ->B1_UM), oArial10, 130, 50,, 2, 0)
	nRow += 10
	oPrinter:SayAlign(nRow, nCol, AllTrim(Transf( TMPETIQ->ZS2_TARA , PesqPict("ZS2","ZS2_TARA") )) + " " + AllTrim(TMPETIQ->B1_UM), oArial10, 130, 50,, 2, 0)
	nRow += 10
	oPrinter:SayAlign(nRow, nCol, AllTrim(Transf( TMPETIQ->ZS2_PESLIQ , PesqPict("ZS2","ZS2_PESLIQ") )) + " " + AllTrim(TMPETIQ->B1_UM), oArial10, 130, 50,, 2, 0)

	oPrinter:EndPage()

Return

Static Function GetPrinter()

	Local oPrinter  as Object
	Local oSetup    as Object
	Local cTempFile as Character

	cTempFile := "REST001_" + DtoS(dDataBase) + "_" + StrTran(Time(),":","") + ".pdf"

	oPrinter := FWMSPrinter():New(cTempFile, IMP_PDF, .F.,, .T.,, oSetup,, .T.,,, .F.,)

	oPrinter:SetResolution(72)
	oPrinter:SetLandscape()

	oSetup := FWPrintSetup():New( PD_ISTOTVSPRINTER + ;
		PD_DISABLEPAPERSIZE + ;
		PD_DISABLEMARGIN + ;
		PD_DISABLEORIENTATION + ;
		PD_DISABLEDESTINATION ;
		, "Impressão de Etiqueta de Entrada")

	oSetup:SetPropert(PD_PRINTTYPE   , 6 ) //PDF
	oSetup:SetPropert(PD_ORIENTATION , 2 ) //Paisagen
	oSetup:SetPropert(PD_DESTINATION , 2)
	oSetup:SetPropert(PD_MARGIN      , {20,20,20,20})
	oSetup:SetPropert(PD_PAPERSIZE   , 2)

	IF oSetup:Activate() == PD_OK
		If oSetup:GetProperty(PD_PRINTTYPE) == IMP_PDF
			oPrinter:nDevice := IMP_PDF
			oPrinter:cPathPDF := oSetup:aOptions[PD_VALUETYPE]
			oPrinter:lViewPDF := .T.
		elseIf oSetup:GetProperty(PD_PRINTTYPE) == IMP_SPOOL
			oPrinter:nDevice := IMP_SPOOL
			oPrinter:cPrinter := oSetup:aOptions[PD_VALUETYPE]
		Endif
	Else
		oPrinter := nil
	EndIF

Return oPrinter
