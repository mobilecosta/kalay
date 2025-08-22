#INCLUDE "TOTVS.CH"
#INCLUDE "TBICONN.CH"
#include "FWPrintSetup.ch"
#include 'parmtype.ch'
#INCLUDE "RPTDEF.CH"

User Function ETQ02()
	Local nx
	Local cFile
	Local nOpc

	Private oFont12n := TFont():New('Arial',12,12,,.T.,,,,.T.,.F.,.F.)
	Private oFont12 := TFont():New('Arial',12,12,,.F.,,,,.T.,.F.,.F.)
	Private oFont11 := TFont():New('Arial',11,11,,.F.,,,,.T.,.F.,.F.)
	Private oFont10 := TFont():New('Arial',10,10,,.F.,,,,.T.,.F.,.F.)
	Private oFont6  := TFont():New('Arial',6,6,,.F.,,,,.T.,.F.,.F.)
	Private nLin
	Private nCol
	Private nDevice         := 6 // 6 = PDF
	Private oPrinter
	Private oSetup
	Private cArqLogo         := ""

	nx     := 1
	cFile  := 'ETQPCP'+'.PDF'
	nLin   := 10
	nCol   := 10
	nOpc   := 1

	cArqLogo             := "\system\danfe" + cEmpAnt + cFilAnt + ".bmp"
	If !File(cArqLogo)
		cArqLogo         := "\system\danfe" + cEmpAnt + Left(cFilAnt, 4) + ".bmp"
		If !File(cArqLogo)
			cArqLogo     := "\system\danfe" + cEmpAnt + Left(cFilAnt, 2) + ".bmp"
			If !File(cArqLogo)
				cArqLogo := "\system\danfe" + cEmpAnt + ".bmp"
			EndIf
		EndIf
	EndIF

	oPrinter := FWMSPrinter():New( cFile , nDevice, .F. , GetTempPath(), .T.,,oSetup)
	oPrinter:SetResolution(72)
	oPrinter:SetPortrait(.T.) // Retrato
	oPrinter:SetMargin(60, 60, 60, 60)
	oPrinter:SetParm("-RFS")
	oPrinter:cPathPDF := GetTempPath()

	oSetup := FWPrintSetup():New(  PD_ISTOTVSPRINTER + ;
		PD_DISABLEPAPERSIZE + ;
		PD_DISABLEMARGIN + ;
		PD_DISABLEORIENTATION + ;
		PD_DISABLEDESTINATION ;
		, "Impressão de Relatório de Romaneio" )

	oSetup:SetPropert(PD_PRINTTYPE   , 6 ) //PDF
	oSetup:SetPropert(PD_ORIENTATION , 1 ) //Paisagem
	oSetup:SetPropert(PD_DESTINATION , 2)
	oSetup:SetPropert(PD_MARGIN      , {60,60,60,60})
	oSetup:SetPropert(PD_PAPERSIZE   , 2)

	IMP_PAGINA()

	IF oSetup:Activate() == PD_OK
		cPastaLoc := oSetup:aOptions[6]
		cArquivo_Pasta := oPrinter:cPathPDF
		oPrinter:SetPortrait(.T.)
		If oSetup:GetProperty(PD_PRINTTYPE) == IMP_PDF
			oPrinter:nDevice := IMP_PDF
			oPrinter:cPathPDF := oSetup:aOptions[PD_VALUETYPE]
			oPrinter:lViewPDF := .T.
			oPrinter:Preview()
		elseIf oSetup:GetProperty(PD_PRINTTYPE) == IMP_SPOOL
			oPrinter:nDevice := IMP_SPOOL
			oPrinter:cPrinter := oSetup:aOptions[PD_VALUETYPE]
		Endif
	Else
		Return(.F.)
	EndIF
Return


/*/{Protheus.doc} IMP_PAGINA
    Adiciona uma pagina a impressão
    @type  Function
    @author Nicolas da Fonseca
    @since 17/04/2024
    @version 1.0
    /*/
static Function IMP_PAGINA()
	local nLin := 35

	oPrinter:StartPage()

	oPrinter:Box(nLin, 0, 841, 560) // box para orientação
	oPrinter:SayBitmap(nLin+5, 15, cArqLogo, 130, 60) // logo

	nLin += 12
	oPrinter:Say(nLin, nCol + 230, "ENTRADA", oFont12n)
	oPrinter:SayAlign(nLin, nCol + 190, 'BALDE HT KALAY COLOUR CONCENTRATES AND ADDITIVES M-10L EXP AM - NA', oFont12, 190, 50,, 0, 1)

	nLin += 80
	oPrinter:Say(nLin, nCol + 10, "FORNECEDOR: " + '', oFont10)
	nLin += 10.5
	oPrinter:Say(nLin, nCol + 10, "CNPJ: " + '', oFont10)
	nLin += 10.5
	oPrinter:Say(nLin, nCol + 10, "CODIGO: " + '', oFont10)
	nLin += 10.5
	oPrinter:Say(nLin, nCol + 10, "DESCRIÇÃO: " + '', oFont10)
	nLin += 10.5
	oPrinter:Say(nLin, nCol + 10, "QUANTIDADE: " + '', oFont10)
	nLin += 10.5
	oPrinter:Say(nLin, nCol + 10, "UM: " + '', oFont10)
	nLin += 10.5
	oPrinter:Say(nLin, nCol + 10, "VOLUMES: " + '', oFont10)
	nLin += 10.5
	oPrinter:Say(nLin, nCol + 10, "LOTE: " + '', oFont10)
	nLin += 10.5
	oPrinter:Say(nLin, nCol + 10, "DATA : " + '', oFont10)

	// oPrinter:Code128(40, 200, 'AllTrim(SH6->H6_PRODUTO)', 0.5, 25, .T., oFont10)

	// // if AllTrim(SH6->H6_LOTECTL) != ""
	// // oPrinter:Code128(75, 185, 'AllTrim(SH6->H6_LOTECTL)', 0.5, 25, .T., oFont6)
	// // endif

	// oPrinter:Code128(120, 185, 'AllTrim(cQuantidade)', 0.5, 25, .T., oFont6)

	oPrinter:EndPage()
Return nil
