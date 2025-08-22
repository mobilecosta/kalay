#include "protheus.ch"
#include "rwmake.ch"
#include "topconn.ch"
#INCLUDE "TBICONN.CH"
#include 'totvs.ch'
#Include 'FWMVCDef.ch'
#Include "FWPrintSetup.ch"
#INCLUDE "RPTDEF.CH"
#INCLUDE "colors.ch"

/*/{Protheus.doc} xfat001a
FwMarkBrowse para exibir os itens do documento de saida a serem impressos.
@type  User Function
@author Claudio Bozi
@since 01/02/2023
@version 1.0
/*/
User Function xpcp001a()

	Local aArea   := GetArea()

	Private aCpoInfo  := {}
	Private aCampos   := {}
	Private aCpoData  := {}
	Private oTable    := Nil
	Private oBrowse   := Nil
	Private aRotBKP   := {}

	Private dDigit	  As Date
	Private cNumOp   As Character
	Private cNum   As Character
	Private cItemOp As Character
	Private cSequencia As Numeric

	Private aTexto  := {}
	Private nPesoLQ := 0
	Private nPesoBR := 0
	Private cIdioma := "1" // Português
	Private cEnter  := Chr(13) + Chr(10)

	cNumOp := SC2->(C2_NUM+C2_ITEM+C2_SEQUEN)
	cNum   := SC2->C2_NUM
	cItemOp := SC2->C2_ITEM
	cSequencia := SC2->C2_SEQUEN

	aRotBKP := aRotina

	aRotina := {}

	FwMsgRun(,{ || fLoadData() }, cCadastro, 'Carregando dados...')

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

	oBrowse:acolumns[5]:ledit    := .T. // informa qual coluna é editável
	oBrowse:acolumns[5]:cReadVar := 'TMP_PESLQ'

	oBrowse:acolumns[6]:ledit    := .T. // informa qual coluna é editável
	oBrowse:acolumns[6]:cReadVar := 'TMP_PESBR'

	oBrowse:acolumns[7]:ledit    := .T. // informa qual coluna é editável
	oBrowse:acolumns[7]:cReadVar := 'TMP_IDIOMA'


	oBrowse:acolumns[8]:ledit    := .T. // informa qual coluna é editável
	oBrowse:acolumns[8]:cReadVar := 'TMP_QTDETQ'

	oBrowse:AddButton("Confirmar"	,"u_xpcp001b()",,1)

	oBrowse:SetMenuDef('custom.xpcp001.prw')

	oBrowse:SetDescription('Seleção de itens para impressão')

	oBrowse:Activate()

	If(Type('oTable') <> 'U')
		oTable:Delete()
		oTable := Nil
	Endif

	aRotina := aRotBKP

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

	aAdd(aCpoInfo, {'Marcar'  		, '@!' 						, 1							, Nil})
	aAdd(aCpoInfo, {'OP'			, '@!' 						, TamSx3('H6_OP')[1]		, Nil})
	aAdd(aCpoInfo, {'Código'  		, '@!' 						, TamSx3('B1_COD')[1]		, Nil})
	aAdd(aCpoInfo, {'Descrição'   	, '@!' 						, TamSx3('B1_DESC')[1]		, Nil})
	aAdd(aCpoInfo, {'Peso Líquido'	, '@E 999,999,999.999999'	, TamSx3('B1_PESO')[1]		, Nil})
	aAdd(aCpoInfo, {'Peso Bruto'	, '@E 999,999,999.999999'	, TamSx3('B1_PESBRU')[1]    , Nil})
	aAdd(aCpoInfo, {'Idioma'        , '@!' 	 				    , 1							, {"1=Português", "2=Inglês", "3=Espanhol"} })
	aAdd(aCpoInfo, {'Qtd. Etiquetas', '@E 999,999' 				, 6							, Nil})

	aAdd(aCpoData, {'TMP_OK'      , 'C'                     , 1                       	, 0							})
	aAdd(aCpoData, {'TMP_OP' 	  , TamSx3('H6_OP')[3] 	, TamSx3('H6_OP')[1] 		, 0							})
	aAdd(aCpoData, {'TMP_COD'  	  , TamSx3('B1_COD')[3] 	, TamSx3('B1_COD')[1] 		, 0							})
	aAdd(aCpoData, {'TMP_DESC'    , TamSx3('B1_DESC')[3]    , TamSx3('B1_DESC')[1]    	, 0							})
	aAdd(aCpoData, {'TMP_PESLQ'	  , TamSx3('B1_PESO')[3]   , TamSx3('B1_PESO')[1] 	, TamSx3('B1_PESO')[2]		})
	aAdd(aCpoData, {'TMP_PESBR'   , TamSx3('B1_PESBRU')[3]      , TamSx3('B1_PESBRU')[1] 	    , TamSx3('B1_PESBRU')[2]	    })
	aAdd(aCpoData, {'TMP_IDIOMA'  , 'C', 1   						, 0							})
	aAdd(aCpoData, {'TMP_QTDETQ'  , TamSx3('D2_QUANT')[3]   , 6   						, 0							})

	For nI := 1 To Len(aCpoData)

		If(aCpoData[nI, 1] <> 'TMP_OK' .and. aCpoData[nI, 1] <> 'TMP_RECNO')

			aAdd(aCampos, FwBrwColumn():New())

			aCampos[Len(aCampos)]:SetData( &('{||' + aCpoData[nI,1] + '}') )
			aCampos[Len(aCampos)]:SetTitle(aCpoInfo[nI,1])
			aCampos[Len(aCampos)]:SetPicture(aCpoInfo[nI,2])
			aCampos[Len(aCampos)]:SetSize(aCpoData[nI,3])
			aCampos[Len(aCampos)]:SetDecimal(aCpoData[nI,4])
			aCampos[Len(aCampos)]:SetAlign(aCpoInfo[nI,3])

			if !Empty(aCpoInfo[nI,4])
				aCampos[Len(aCampos)]:SetOptions(aCpoInfo[nI,4])
			endif

		EndIf

	next

	oTable:SetFields(aCpoData)
	oTable:Create()

	BeginSql Alias _cAlias
        SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_QUANT, B1_COD, B1_DESC, B1_PESO, B1_PESBRU, B1_LM
            FROM %Table:SC2% SC2
            INNER JOIN %Table:SB1% SB1
                ON SB1.B1_FILIAL = %xFilial:SB1%
                AND SB1.B1_COD    = SC2.C2_PRODUTO
                AND SB1.%NotDel%
            WHERE SC2.C2_FILIAL = %xFilial:SC2%
                AND SC2.C2_NUM    = %Exp:cNum%
                AND SC2.C2_ITEM   = %Exp:cItemOp%
                AND SC2.C2_SEQUEN = %Exp:cSequencia%
            ORDER BY C2_NUM, C2_ITEM, C2_SEQUEN
	EndSQL

	(_cAlias)->(DbGoTop())

	DbSelectArea('TRB')

	While(!(_cAlias)->(EoF()))

		RecLock('TRB', .T.)

		TRB->TMP_OK 	:= 'S'
		TRB->TMP_OP     := (_cAlias)->(C2_NUM+C2_ITEM+C2_SEQUEN)
		TRB->TMP_COD 	:= (_cAlias)->B1_COD
		TRB->TMP_DESC  	:= (_cAlias)->B1_DESC
		TRB->TMP_PESLQ  := (_cAlias)->C2_QUANT * (_cAlias)->B1_PESO
		TRB->TMP_PESBR  := (_cAlias)->C2_QUANT * (_cAlias)->B1_PESBRU
		TRB->TMP_IDIOMA := '1' // Português
		TRB->TMP_QTDETQ := INT((_cAlias)->C2_QUANT/(_cAlias)->B1_LM)

		if TRB->TMP_QTDETQ == 0
			TRB->TMP_QTDETQ := 1
		endif

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

/*/{Protheus.doc} xpcp001b
	Função responsavel por gerar a impressão da etiqueta de entrada, chamada pelo PE MT103FIM e via menu MA103OPC.
	@author Claudio Bozzi
	@since 30/06/2022
	@version 1.0
	@param Nil
	@return Nil
/*/
User Function xpcp001b()

	Private aArea := GetArea()
	Private nPag  := 0

	Private lAdjustToLegacy := .F.
	Private lDisableSetup  	:= .T.
	Private cLocal          := "\spool"
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
	Private oArial20  := TFont():New("Arial",,20,,.f.,,,,,.f.,.f.)
	Private oArial20N := TFont():New("Arial",,20,,.t.,,,,,.f.,.f.)
	Private oArial30N := TFont():New("Arial",,30,,.t.,,,,,.f.,.f.)

	If oPrinter != Nil
		FwMsgRun(, {|| TratarImp()}, "Executando...", "Executando impressão.")
	EndIf

	RestArea(aArea)

Return

Static Function TratarImp()

	Local nX := 0

	BeginSql Alias "TMPETIQ"

        SELECT C2_NUM, C2_ITEM, C2_SEQUEN, C2_QUANT, C2_XLOTE, B1_COD, B1_DESC, B1_PESO, B1_PESBRU, B1_LM
            FROM %Table:SC2% SC2
            INNER JOIN %Table:SB1% SB1
                ON SB1.B1_FILIAL = %xFilial:SB1%
                AND SB1.B1_COD    = SC2.C2_PRODUTO
                AND SB1.%NotDel%
            WHERE SC2.C2_FILIAL = %xFilial:SC2%
                AND SC2.C2_NUM    = %Exp:cNum%
                AND SC2.C2_ITEM   = %Exp:cItemOp%
                AND SC2.C2_SEQUEN = %Exp:cSequencia%
            ORDER BY C2_NUM, C2_ITEM, C2_SEQUEN

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
			// nQuant := nQE
			nPesoLQ   := TRB->TMP_PESLQ
			nPesoBR   := TRB->TMP_PESBR
			cIdioma   := TRB->TMP_IDIOMA
			MontarImp()
		Next

		TMPETIQ->(DbSkip())
		TRB->(DBSkip())
	Enddo

	TMPETIQ->(DbCloseArea())

	oPrinter:Preview()

Return

Static Function MontarImp()

	Private nRow    := 40
	Private nCol    := 15

	oPrinter:SetPaperSize(0, 100,140)
	oPrinter:SetMargin(001,001,001,001)
	oPrinter:StartPage()

	cProd := PadL("X", TamSx3("B1_COD")[1], "X")
	oPrinter:Say( nRow, nCol,AllTrim(SC2->C2_PRODUTO),oArial10,,,)
	nRow  += 10
	oPrinter:Say( nRow, nCol,AllTrim(SB1->B1_DESC),oArial15N,,,)

	cPesoLiq := AllTrim(Transform(nPesoLQ, GetSX3Cache("D1_QUANT", "X3_PICTURE")))
	cPesoBruto := AllTrim(Transform(nPesoBR, GetSX3Cache("D1_QUANT", "X3_PICTURE")))

	oPrinter:Code128(80, 285, AllTrim(SC2->C2_PRODUTO), 0.5, 21, .T., oArial8N)

	oPrinter:Code128(120, 285, AllTrim(SC2->C2_XLOTE), 0.5, 21, .T., oArial8N)

	oPrinter:Code128(160, 285, cPesoLiq, 0.5, 21, .T., oArial8N)

	oPrinter:Code128(200, 285, cPesoBruto, 0.5, 21, .T., oArial8N)

	cQrCode := SC2->C2_PRODUTO
	cQrCode += AllTrim(SB1->B1_DESC) + Chr(13)+Chr(10)
	cQrCode += AllTrim(SC2->C2_XLOTE) + Chr(13)+Chr(10)
	cQrCode += cPesoLiq + Chr(13)+Chr(10)
	cQrCode += cPesoBruto + Chr(13)+Chr(10)
	cQrCode += dToC(SC2->C2_DATPRI) + Chr(13)+Chr(10)
	cQrCode += dToC(SC2->C2_XDTVLD)

	oPrinter:QRCode(140,nCol,cQrCode, 90)

	// Idioma 1 - Português 2- Inglês 3 - Espanhol
	cSayLot := ""
	nColVlrLot := 0
	cSayCnpj := ""
	nColVlrCnpj := 0
	cSayPesoLiq := ""
	nColVlrLiq := 0
	cSayPesoBruto := ""
	nColVlrBruto := 0
	cSayFab := ""
	nColVlrFab := 0
	cSayVal := ""
	nColVlrVal := 0
	cSayOp := ""
	nColVlrOp := 0

	Do Case
	Case cIdioma == '1'
		cSayLot := "LOTE: "
		nColVlrLot := nCol+38

		cSayPesoLiq := "Peso Líquido: "
		nColVlrLiq := nCol+80

		cSayPesoBruto := "Peso Bruto: "
		nColVlrBruto := nCol+70

		cSayFab := "Fáb.: "
		nColVlrFab := nCol+30

		cSayVal := "Val.: "
		nColVlrVal := nCol+28

		cSayOp := "OP: "
		nColVlrOp := nCol+22
	Case cIdioma == '2' // Inglês

		cSayLot := "Batch Nr.: "
		nColVlrLot := nCol+60

		cSayPesoLiq := "Net Wt: "
		nColVlrLiq := nCol+45

		cSayPesoBruto := "Gross Wt: "
		nColVlrBruto := nCol+60

		cSayFab := "MFG Date.: "
		nColVlrFab := nCol+65

		cSayVal := "EXP Date.: "
		nColVlrVal := nCol+65

		cSayOp := "PO: "
		nColVlrOp := nCol+22
	Case cIdioma == '3' // Espanhol
		cSayLot := "LOTE: "
		nColVlrLot := nCol+40

		cSayPesoLiq := "Peso Neto: "
		nColVlrLiq := nCol+63

		cSayPesoBruto := "Peso Bruto: "
		nColVlrBruto := nCol+68

		cSayFab := "Fab: "
		nColVlrFab := nCol+28

		cSayVal := "Venc.: "
		nColVlrVal := nCol+37

		cSayOp := "OP: "
		nColVlrOp := nCol+22
	EndCase

	nRow += 110
	oPrinter:Say( nRow, nCol,cSayLot,oArial15N,,,)
	oPrinter:Say( nRow, nColVlrLot,AllTrim(SC2->C2_XLOTE),oArial15,,,)

	nRow += 15
	oPrinter:Say( nRow, nCol,cSayPesoLiq,oArial15N,,,)
	oPrinter:Say( nRow, nColVlrLiq,cPesoLiq,oArial15,,,)

	nRow += 15
	oPrinter:Say( nRow, nCol,cSayPesoBruto,oArial15N,,,)
	oPrinter:Say( nRow, nColVlrBruto,cPesoBruto,oArial15,,,)

	nRow += 15
	oPrinter:Say( nRow, nCol,cSayFab,oArial15N,,,)
	oPrinter:Say( nRow, nColVlrFab,dToC(SC2->C2_DATPRI),oArial15,,,)

	nRow += 15
	oPrinter:Say( nRow, nCol,cSayVal,oArial15N,,,)
	oPrinter:Say( nRow, nColVlrVal,dToC(SC2->C2_XDTVLD),oArial15,,,)

	nRow += 15
	oPrinter:Say( nRow, nCol,cSayOp,oArial15N,,,)
	oPrinter:Say( nRow, nColVlrOp,AllTrim(SC2->(C2_NUM+C2_ITEM+C2_SEQUEN)),oArial15,,,)

	oPrinter:EndPage()

Return

Static Function GetPrinter()

	Local oPrinter  as Object
	Local oSetup    as Object
	Local cTempFile as Character

	cTempFile := "xfat001_" + DtoS(dDataBase) + "_" + StrTran(Time(),":","") + ".pdf"

	oPrinter := FWMSPrinter():New(cTempFile, IMP_PDF, .F.,, .T.,, oSetup,, .T.,,, .F.,)

	oPrinter:SetResolution(72)
	oPrinter:SetLandscape()

	oSetup := FWPrintSetup():New( PD_ISTOTVSPRINTER + ;
		PD_DISABLEPAPERSIZE + ;
		PD_DISABLEMARGIN + ;
		PD_DISABLEORIENTATION + ;
		PD_DISABLEDESTINATION ;
		, "Impressão de Pick List de Pedidos de Venda")

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
