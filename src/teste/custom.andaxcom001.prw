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
User Function xcom001a()

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
	MontarImp()

	oPrinter:Preview()

Return

Static Function MontarImp()

	Private nRow    := 15
	Private nCol    := 15

	oPrinter:SetPaperSize(0, 100,140)
	oPrinter:SetMargin(001,001,001,001)
	oPrinter:StartPage()

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

	oPrinter:SayBitmap( 5, nCol,cArqLogo)

	oPrinter:Say( nRow+20, nCol+210,"ENTRADA",oArial15N,,,)
	oPrinter:SayAlign(nRow+20+2, nCol+120, "PRODUTO TESTE 11 PRODUTO TESTE 11 PRODUTO TESTE 11", oArial15, 250, 50,, 2, 0)

	cProd := PadL("X", TamSx3("B1_COD")[1], "X")

	oPrinter:Code128(80, 285, cProd, 0.5, 25, .T., oArial8N)

	oPrinter:Code128(120+10, 285, cProd, 0.5, 25, .T., oArial8N)

	oPrinter:Code128(160+20, 285, cProd, 0.5, 25, .T., oArial8N)

	nRow += 100
	oPrinter:Say( nRow, nCol,"FORNECEDOR: ",oArial10N,,,)

	cTransp := "Não Informado"
	oPrinter:Say( nRow, nCol+62,AllTrim(cTransp),oArial10,,,)

	nRow += 15
	oPrinter:Say( nRow, nCol,"CNPJ: ",oArial10N,,,)
	oPrinter:Say( nRow, nCol+25,'TESTE CNPJ',oArial10,,,)

	nRow += 15
	oPrinter:Say( nRow, nCol,"CODIGO: ",oArial10N,,,)
	oPrinter:Say( nRow, nCol+37,'AllTrim(SF2->F2_SERIE)',oArial10,,,)

	nRow += 15
	oPrinter:Say( nRow, nCol,"DESCRIÇÂO: ",oArial10N,,,)
	oPrinter:Say( nRow, nCol+53,'dToC(SF2->F2_EMISSAO)',oArial10,,,)

	nRow += 15
	oPrinter:Say( nRow, nCol,"QUANTIDADE: ",oArial10N,,,)
	oPrinter:Say( nRow, nCol+56,'dToC(SF2->F2_EMISSAO)',oArial10,,,)

	nRow += 15
	oPrinter:Say( nRow, nCol,"UM: ",oArial10N,,,)
	oPrinter:Say( nRow, nCol+18,'dToC(SF2->F2_EMISSAO)',oArial10,,,)

	nRow += 15
	oPrinter:Say( nRow, nCol,"VOLUMES: ",oArial10N,,,)
	oPrinter:Say( nRow, nCol+43,'dToC(SF2->F2_EMISSAO)',oArial10,,,)

	nRow += 15
	oPrinter:Say( nRow, nCol,"LOTE: ",oArial10N,,,)
	oPrinter:Say( nRow, nCol+25,'dToC(SF2->F2_EMISSAO)',oArial10,,,)

	nRow += 15
	oPrinter:Say( nRow, nCol,"DATA: ",oArial10N,,,)
	oPrinter:Say( nRow, nCol+25,'dToC(SF2->F2_EMISSAO)',oArial10,,,)
	// oPrinter:Say( nRow, nCol+65,cValToChar(SF2->F2_VOLUME1) + " " + AllTrim(SF2->F2_ESPECIE1),oArial15,,,)

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
