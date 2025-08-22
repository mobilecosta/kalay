#include "protheus.ch"
#include "rwmake.ch"
#include "topconn.ch"
#INCLUDE "TBICONN.CH"
#include 'totvs.ch'
#Include 'FWMVCDef.ch'
#Include "FWPrintSetup.ch"
#INCLUDE "RPTDEF.CH"
#INCLUDE "colors.ch"

/*/{Protheus.doc} REST001A
	Função responsavel por gerar a impressão da etiqueta de produção, chamada pelo PE FISTRFNFE.

	@type  User Function
	@author Tiago Cunha
	@since 09/07/2025
	@version 1.0
	@param Nil
	@return Nil
/*/
User Function REST001A()

	Private aArea 		:= GetArea()
	Private aAreaSB1 	:= SB1->(GetArea())
	Private aAreaSB8 	:= SB8->(GetArea())
	Private nQuant		:= 0

	Private lAdjustToLegacy := .F.
	Private lDisableSetup  	:= .T.
	Private cLocal          := "\spool"
	Private oPrinter 		 := Nil

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
	Private nCol    := 5

	oPrinter:SetPaperSize(0, 50, 50)
	oPrinter:SetMargin(001,001,001,001)
	oPrinter:StartPage()

	nRow += 20
	oPrinter:SayAlign(nRow, nCol, "05/05/2025", oArial10, 130, 50,, 2, 0)
	nRow += 10
	oPrinter:SayAlign(nRow, nCol, "MP0001", oArial10, 130, 50,, 2, 0)
	nRow += 10
	oPrinter:SayAlign(nRow, nCol, "DIOXIO DE TITANIO", oArial10, 130, 50,, 2, 0)
	nRow += 10
	oPrinter:SayAlign(nRow, nCol, "000000000000001", oArial10, 130, 50,, 2, 0)
	nRow += 10
	oPrinter:SayAlign(nRow, nCol, "0000001", oArial10, 130, 50,, 2, 0)
	nRow += 10
	oPrinter:SayAlign(nRow, nCol, "15,5000 KG", oArial10, 130, 50,, 2, 0)
	nRow += 10
	oPrinter:SayAlign(nRow, nCol, "0,50000 KG", oArial10, 130, 50,, 2, 0)
	nRow += 10
	oPrinter:SayAlign(nRow, nCol, "12,0000 KG", oArial10, 130, 50,, 2, 0)

	oPrinter:EndPage()

Return

Static Function GetPrinter()

	Local oPrinter  as Object
	Local oSetup    as Object
	Local cTempFile as Character

	cTempFile := "rest001_" + DtoS(dDataBase) + "_" + StrTran(Time(),":","") + ".pdf"

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
