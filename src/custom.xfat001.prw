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
User Function xfat001a()

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
	Private oArial15N := TFont():New("Arial",,15,,.t.,,,,,.f.,.f.)
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
	Local nQuant := 0
	Local aPergs := {}
	Local nX     := 0

	aAdd(aPergs, {1, "Quantidade",  nQuant,  "", ".T.", "", ".T.", 80,  .F.}) // MV_PAR01

	if ParamBox(aPergs, "Impressão", , , , , , , , , .F., .F.)
		SA1->(DbSetOrder(1))	//A1_FILIAL+A1_COD+A1_LOJA
		if SA1->(MsSeek(xFilial('SA1') + SF2->F2_CLIENTE + SF2->F2_LOJA))
			if MV_PAR01 > 0
				For nX := 1 To MV_PAR01
					MontarImp()
				Next
			else
				MontarImp()
			endif

			oPrinter:Preview()
		else
			FWAlertWarning("Não foi possível localizar o cliente", "Cliente não encontrado")
		endIF
	endIF

Return

Static Function MontarImp()

	Private nRow    := 30
	Private nCol    := 15

	oPrinter:SetPaperSize(0, 100,140)
	oPrinter:SetMargin(001,001,001,001)
	oPrinter:StartPage()

	// oPrinter:Say( nRow+5, nCol,"PRODUÇÃO",oArial17N,,,)
	oPrinter:SayAlign(nRow, nCol, AllTrim(SA1->A1_NOME), oArial17, 370, 50,, 2, 0)

	nRow += 90
	oPrinter:Say( nRow, nCol,"Transp: ",oArial17N,,,)

	cTransp := "Não Informado"
	if !Empty(SF2->F2_TRANSP)
		SA4->(DbSetOrder(1)) //A4_FILIAL+A4_COD
		if SA4->(MsSeek(xFilial('SA4') + SF2->F2_TRANSP))
			cTransp := AllTrim(SA4->A4_NOME)
		endif
	endif

	oPrinter:Say( nRow, nCol+52,AllTrim(cTransp),oArial17,,,)

	nRow += 22
	oPrinter:Say( nRow, nCol,"Nr NFe: ",oArial17N,,,)
	oPrinter:Say( nRow, nCol+52,AllTrim(SF2->F2_DOC),oArial17,,,)

	nRow += 22
	oPrinter:Say( nRow, nCol,"Série NFe: ",oArial17N,,,)
	oPrinter:Say( nRow, nCol+68,AllTrim(SF2->F2_SERIE),oArial17,,,)

	nRow += 22
	oPrinter:Say( nRow, nCol,"Data NFe: ",oArial17N,,,)
	oPrinter:Say( nRow, nCol+65,dToC(SF2->F2_EMISSAO),oArial17,,,)

	nRow += 22
	oPrinter:Say( nRow, nCol,"Volumes: ",oArial17N,,,)
	oPrinter:Say( nRow, nCol+65,cValToChar(SF2->F2_VOLUME1) + " " + AllTrim(SF2->F2_ESPECI1),oArial17,,,)

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
