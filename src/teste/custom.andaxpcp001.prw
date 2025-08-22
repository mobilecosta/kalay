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
	Função responsavel por gerar a impressão da etiqueta de produção, chamada pelo PE FISTRFNFE.

	@type  User Function
	@author Tiago Cunha
	@since 09/07/2025
	@version 1.0
	@param Nil
	@return Nil
/*/
User Function xpcp001a()

	Private aArea 		:= GetArea()
	Private aAreaSB1 	:= SB1->(GetArea())
	Private aAreaSB8 	:= SB8->(GetArea())
	Private nQuant		:= 0

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
	Private oArial15N  := TFont():New("Arial",,15,,.t.,,,,,.f.,.f.)
	Private oArial17 := TFont():New("Arial",,17,,.f.,,,,,.f.,.f.)
	Private oArial17N := TFont():New("Arial",,17,,.t.,,,,,.f.,.f.)

	If oPrinter != Nil
		FwMsgRun(, {|| Impressao()}, "Executando...", "Executando impressão.")
	EndIf

	RestArea(aArea)
	RestArea(aAreaSB1)
	RestArea(aAreaSB8)
Return

/*/{Protheus.doc} Impressao
	Função para impressão da etiqueta, codigo gerado atraves do BarTender UltaLite, ferramenta grafica para desenho de etiquetas Argox
	@type  Static Function
	@author Claudio Bozzi
	@since 11/05/2022
	@version 1.0
	@param Nil
	@return Nil
/*/
Static Function Impressao()
	// Posiciona no cliente
	Local nQuant := 1
	Local aPergs := {}
	Local nX     := 0

	aLangs     := {"1=Português", "2=Inglês", "3=Espanhol"}

	aAdd(aPergs, {2, "Idioma"           , "I", aLangs    , 50, ".T.", .F.}) // MV_PAR01
	aAdd(aPergs, {1, "Quantidade",  nQuant,  "", ".T.", "", ".T.", 80,  .F.}) // MV_PAR02

	if ParamBox(aPergs, "Impressão", , , , , , , , , .F., .F.)
		SB1->(DbSetOrder(1))	//A1_FILIAL+A1_COD+A1_LOJA
		if SB1->(MsSeek(xFilial('SB1') + SC2->C2_PRODUTO))
			if MV_PAR02 > 0
				For nX := 1 To MV_PAR02
					MontarImp()
				Next
			else
				MontarImp()
			endif

			oPrinter:Preview()
		else
			FWAlertWarning("Não foi possível localizar o Produto", "Aviso")
		endIF
	endIF
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

	oPrinter:Code128(80, 285, AllTrim(SC2->C2_PRODUTO), 0.5, 21, .T., oArial8N)

	oPrinter:Code128(120, 285, AllTrim(SC2->C2_XLOTE), 0.5, 21, .T., oArial8N)

	oPrinter:Code128(160, 285, cProd, 0.5, 21, .T., oArial8N)

	oPrinter:Code128(200, 285, cProd, 0.5, 21, .T., oArial8N)

	cQrCode := AllTrim(SB1->B1_DESC) + Chr(13)+Chr(10)
	cQrCode += AllTrim(SC2->C2_XLOTE) + Chr(13)+Chr(10)
	// liq
	// brut
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
	Case MV_PAR01 == '1'
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
	Case MV_PAR01 == '2' // Inglês

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
	Case MV_PAR01 == '3' // Espanhol
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
	oPrinter:Say( nRow, nColVlrLiq,'informa em tela',oArial15,,,)
	// B1_PESO

	nRow += 15
	oPrinter:Say( nRow, nCol,cSayPesoBruto,oArial15N,,,)
	oPrinter:Say( nRow, nColVlrBruto,'Informa em tela',oArial15,,,)
	// B1_PESBRU

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
		, "Impressão de Etiqueta de Expedição")

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
