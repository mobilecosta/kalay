#include "protheus.ch"
#include "rwmake.ch"
#include "topconn.ch"
#INCLUDE "TBICONN.CH"
#include 'totvs.ch'
#Include 'FWMVCDef.ch'
#Include "FWPrintSetup.ch"
#INCLUDE "RPTDEF.CH"
#INCLUDE "colors.ch"

/*/{Protheus.doc} xpcp001a
	Função responsavel por gerar a impressão da etiqueta de produção, chamada pelo PE FISTRFNFE.
	@type  User Function
	@author Claudio Bozzi
	@since 11/05/2022
	@version 1.0
	@param Nil
	@return Nil
/*/
User Function xpcp001a(nOpc)

	Private aArea 		:= GetArea()
	Private aAreaSB1 	:= SB1->(GetArea())
	Private aAreaSB8 	:= SB8->(GetArea())
	Private nQuant		:= 0
	Private cPerg		:= 'XPCP001A'

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
	Private oArial17N := TFont():New("Arial",,17,,.t.,,,,,.f.,.f.)

	If nOpc = 2
		If MsgYesNo("Deseja imprimir a etiqueta de produção referente a quantidade total do apontamento?", "Etiqueta de Produção")
			nOpc := 1
		ElseIf ! Pergunte(cPerg,.T.) // Pergunta no SX1
			Return
		EndIf
	EndIf

    If oPrinter != Nil
	    FwMsgRun(, {|| Impressao(nOpc)}, "Executando...", "Executando impressão.")
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
Static Function Impressao(nOpc)

	Local nX := 0

	// Posiciona produto
	SB1->(DbSetOrder(1))	//B1_FILIAL + B1_COD
	SB1->(MsSeek(xFilial('SB1') + SH6->H6_PRODUTO ))

	// Posiciona saldos por lote
	SB8->(DbSetOrder(3))	//B8_FILIAL + B8_PRODUTO + B8_LOCAL + B8_LOTECTL + B8_NUMLOTE + DTOS(B8_DTVALID)
	SB8->(MsSeek(xFilial('SB8') + SH6->H6_PRODUTO + SH6->H6_LOCAL + SH6->H6_LOTECTL + SH6->H6_NUMLOTE))

	If nOpc = 2 .And. MV_PAR01 > 0
		nQuant := MV_PAR02
		For nX := 1 To MV_PAR01
			If AllTrim(SB1->B1_TIPO) = 'PI'
				MontarImp()
			ElseIf AllTrim(SB1->B1_TIPO) = 'PA'
				MontarImp2()
			EndIf
		Next
	Else
		nQuant := SD3->D3_QUANT
		If AllTrim(SB1->B1_TIPO) = 'PI'
			MontarImp()
		ElseIf AllTrim(SB1->B1_TIPO) = 'PA'
			MontarImp2()
		EndIf
	EndIf

    oPrinter:Preview()

Return

Static Function MontarImp()

    Private nRow    := 40
	Private nCol    := 15

	oPrinter:SetPaperSize(0, 140,100)
	oPrinter:SetMargin(001,001,001,001)
	oPrinter:StartPage()

    oPrinter:SayBitmap( nRow, nCol+180,'\system\etq'+cEmpAnt+cFilAnt+'.png')

    oPrinter:Say( nRow+5, nCol+40,"PRODUÇÃO",oArial17N,,,)

    nRow += 20
    oPrinter:Say( nRow, nCol,AllTrim(SH6->H6_PRODUTO),oArial15N,,,)

    nRow += 15
    oPrinter:Say( nRow, nCol,AllTrim(SB1->B1_DESC),oArial15N,,,)

    nRow += 15
    oPrinter:Say( nRow, nCol,AllTrim(SH6->H6_LOTECTL),oArial15N,,,)

    nRow += 15
    oPrinter:Say( nRow, nCol,dToC(SB8->B8_DTVALID),oArial15N,,,)

    nRow += 15
    oPrinter:Say( nRow, nCol,AllTrim(cValToChar(nQuant)),oArial15N,,,)

    oPrinter:FWMSBAR("CODE128" /*cTypeBar*/,11.5/*nRow*/ ,1/*nCol*/, AllTrim(SH6->H6_PRODUTO)/*cCode*/,oPrinter/*oPrint*/,/*lCheck*/,/*Color*/,.T./*lHorz*/,/*nWidth*/,0.6/*nHeigth*/,.F./*lBanner*/,"Arial"/*cFont*/,NIL/*cMode*/,.F./*lPrint*/,/*nPFWidth*/,/*nPFHeigth*/,.F./*lCmtr2Pix*/)
    oPrinter:Say( nRow+55, nCol,AllTrim(SH6->H6_PRODUTO),oArial12,,,)

    oPrinter:FWMSBAR("CODE128" /*cTypeBar*/,14.8/*nRow*/ ,1/*nCol*/, AllTrim(SH6->H6_LOTECTL)/*cCode*/,oPrinter/*oPrint*/,/*lCheck*/,/*Color*/,.T./*lHorz*/,/*nWidth*/,0.6/*nHeigth*/,.F./*lBanner*/,"Arial"/*cFont*/,NIL/*cMode*/,.F./*lPrint*/,/*nPFWidth*/,/*nPFHeigth*/,.F./*lCmtr2Pix*/)
    oPrinter:Say( nRow+95, nCol,AllTrim(SH6->H6_LOTECTL),oArial12,,,)

    oPrinter:FWMSBAR("CODE128" /*cTypeBar*/,18.5/*nRow*/ ,1/*nCol*/, AllTrim(cValToChar(nQuant))/*cCode*/,oPrinter/*oPrint*/,/*lCheck*/,/*Color*/,.T./*lHorz*/,/*nWidth*/,0.6/*nHeigth*/,.F./*lBanner*/,"Arial"/*cFont*/,NIL/*cMode*/,.F./*lPrint*/,/*nPFWidth*/,/*nPFHeigth*/,.F./*lCmtr2Pix*/)
    oPrinter:Say( nRow+140, nCol,AllTrim(cValToChar(nQuant)),oArial12,,,)

    nRow += 160
    oPrinter:Say( nRow, nCol,"ORDEM DE PRODUÇÃO: ",oArial12N,,,)
    oPrinter:Say( nRow, nCol+110,AllTrim(SH6->H6_OP),oArial12,,,)
    
    nRow += 10
    oPrinter:Say( nRow, nCol,"LOTE: ",oArial12N,,,)
    oPrinter:Say( nRow, nCol+30,AllTrim(SH6->H6_LOTECTL),oArial12,,,)

    nRow += 10
    oPrinter:Say( nRow, nCol,"VALIDADE: ",oArial12N,,,)
    oPrinter:Say( nRow, nCol+52,dToC(SB8->B8_DTVALID),oArial12,,,)

    nRow += 10
    oPrinter:Say( nRow, nCol,"DATA: ",oArial12N,,,)
    oPrinter:Say( nRow, nCol+30,dToC(SH6->H6_DTPROD),oArial12,,,)

    nRow += 10
    oPrinter:Say( nRow, nCol,"QUANTIDADE: ",oArial12N,,,)
    oPrinter:Say( nRow, nCol+70,AllTrim(cValToChar(nQuant)),oArial12,,,)

    nRow += 10
    oPrinter:Say( nRow, nCol,"CÓDIGO PRODUTO: ",oArial12N,,,)
    oPrinter:Say( nRow, nCol+95,AllTrim(SH6->H6_PRODUTO),oArial12,,,)

    nRow += 10
    oPrinter:Say( nRow, nCol,"DESCRIÇÃO: ",oArial12N,,,)
    oPrinter:Say( nRow, nCol+60,SubStr(AllTrim(SB1->B1_DESC),1,24),oArial12,,,)

    nRow += 10
    oPrinter:Say( nRow, nCol,"UM: ",oArial12N,,,)
    oPrinter:Say( nRow, nCol+20,AllTrim(SB1->B1_UM),oArial12,,,)

    nRow += 10
    oPrinter:Say( nRow, nCol,"TIPO: ",oArial12N,,,)
    oPrinter:Say( nRow, nCol+30,AllTrim(SB1->B1_TIPO),oArial12,,,)

	oPrinter:EndPage()

Return

Static Function MontarImp2()

    Private nRow    := 5
	Private nCol    := 5

	oPrinter:SetPaperSize(0, 50,95)
	oPrinter:SetMargin(001,001,001,001)
	oPrinter:StartPage()

    oPrinter:SayBitmap( nRow, nCol+180,'\system\etq'+cEmpAnt+cFilAnt+'.png')

    nRow += 20
    oPrinter:Say( nRow, nCol,AllTrim(SH6->H6_PRODUTO),oArial15N,,,)

    nRow += 15
    oPrinter:Say( nRow, nCol,AllTrim(SB1->B1_DESC),oArial15N,,,)

    nRow += 15
    oPrinter:Say( nRow, nCol,AllTrim(SH6->H6_LOTECTL),oArial15N,,,)

    nRow += 15
    oPrinter:Say( nRow, nCol,dToC(SB8->B8_DTVALID),oArial15N,,,)

    nRow += 15
    oPrinter:Say( nRow, nCol,AllTrim(cValToChar(nQuant)),oArial15N,,,)

    oPrinter:FWMSBAR("CODE128" /*cTypeBar*/,3.5/*nRow*/ ,9/*nCol*/, AllTrim(SH6->H6_PRODUTO)/*cCode*/,oPrinter/*oPrint*/,/*lCheck*/,/*Color*/,.T./*lHorz*/,/*nWidth*/,0.6/*nHeigth*/,.F./*lBanner*/,"Arial"/*cFont*/,NIL/*cMode*/,.F./*lPrint*/,/*nPFWidth*/,/*nPFHeigth*/,.F./*lCmtr2Pix*/)
    nRow += 20
    oPrinter:Say( nRow-30, nCol+130,AllTrim(SH6->H6_PRODUTO),oArial12,,,)

    oPrinter:FWMSBAR("CODE128" /*cTypeBar*/,6.5/*nRow*/ ,9/*nCol*/, AllTrim(SH6->H6_LOTECTL)/*cCode*/,oPrinter/*oPrint*/,/*lCheck*/,/*Color*/,.T./*lHorz*/,/*nWidth*/,0.6/*nHeigth*/,.F./*lBanner*/,"Arial"/*cFont*/,NIL/*cMode*/,.F./*lPrint*/,/*nPFWidth*/,/*nPFHeigth*/,.F./*lCmtr2Pix*/)
    nRow += 7
    oPrinter:Say( nRow, nCol+130,AllTrim(SH6->H6_LOTECTL),oArial12,,,)

    oPrinter:FWMSBAR("CODE128" /*cTypeBar*/,9.5/*nRow*/ ,9/*nCol*/, AllTrim(cValToChar(nQuant))/*cCode*/,oPrinter/*oPrint*/,/*lCheck*/,/*Color*/,.T./*lHorz*/,/*nWidth*/,0.6/*nHeigth*/,.F./*lBanner*/,"Arial"/*cFont*/,NIL/*cMode*/,.F./*lPrint*/,/*nPFWidth*/,/*nPFHeigth*/,.F./*lCmtr2Pix*/)
    nRow += 35
    oPrinter:Say( nRow, nCol+130,AllTrim(cValToChar(nQuant)),oArial12,,,)

	oPrinter:EndPage()

Return

Static Function GetPrinter()

    Local oPrinter  as Object
    Local oSetup    as Object
    Local cTempFile as Character
    
    cTempFile := "xpcp001_" + DtoS(dDataBase) + "_" + StrTran(Time(),":","") + ".pdf"
    
	oPrinter := FWMSPrinter():New(cTempFile, IMP_PDF, .F.,, .T.,, oSetup,, .T.,,, .F.,)

	oPrinter:SetResolution(72)
	oPrinter:SetLandscape()

    oSetup := FWPrintSetup():New( PD_ISTOTVSPRINTER + ;
                                    PD_DISABLEPAPERSIZE + ;
                                    PD_DISABLEMARGIN + ;
                                    PD_DISABLEORIENTATION + ;
                                    PD_DISABLEDESTINATION ;
                                    , "Impressão de Etiqueta de Produção")

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
