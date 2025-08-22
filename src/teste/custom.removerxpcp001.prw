#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#INCLUDE "protheus.ch"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} XPCP001
    Impressao da etiqueta de produção. Utilizada por botão em outras ações e no final do apontamento do PCP
    @type  Function
    @author Nicolas Fonseca
    @since 02/04/2024
    @version 1.0
    /*/
user Function XPCP001()
    Local nx
	Local cLocal
    Local cFile
    Local nOpc
    Local cPerg

	Private oFont10 := TFont():New('Arial',10,10,,.F.,,,,.T.,.F.,.F.)
	Private oFont6  := TFont():New('Arial',6,6,,.F.,,,,.T.,.F.,.F.)
    Private nLin
    Private nCol

    nx     := 1
	cLocal := "c:\temp\"
    cFile  := 'ETQPCP'+'.PDF'
    nLin   := 10
    nCol   := 10
    nOpc   := 1
    cPerg  := "XPCP001A"
    
	// SB1->(DbSetOrder(1))	//B1_FILIAL + B1_COD
	// SB1->(MsSeek(xFilial('SB1') + SC2->C2_PRODUTO ))

    oPrinter := FWMSPrinter():New( cFile , 6, .F. , cLocal, .T.)

    // if SB1->B1_TIPO == "PA" .OR. SB1->B1_TIPO == "PI"

    //     If !MsgYesNo("Deseja imprimir a etiqueta de producao com quantidade total?", "Etiqueta de Producao")
    //         nOpc := 2
    //         if !Pergunte(cPerg, .T.)
    //             Return
    //         endif
    //     EndIf
        
    //     oPrinter:Setup()

    //     if oPrinter:nModalResult != 1
    //         return
    //     endif
        
        oPrinter:SetMargin(001,001,001,001)

        IMP_PAGINA(cvaltochar(SC2->C2_QUANT))
        // if nOpc == 2

        //     for nX := 1 to MV_PAR01
        //         nLin   := 10
        //         nCol   := 10
                
        //         IMP_PAGINA(cvaltochar(MV_PAR02))
        //     next
        // else
        // endif
    // endif
    oPrinter:Print()

Return 

/*/{Protheus.doc} IMP_PAGINA
    Adiciona uma pagina a impressão
    @type  Function
    @author Nicolas da Fonseca
    @since 17/04/2024
    @version 1.0
    /*/
static Function IMP_PAGINA(cQuantidade)
    oPrinter:StartPage()

    cImagem := GetSrvProfString("STARTPATH","")+"LGMID"+cEmpAnt+".bmp"

    oPrinter:SayBitmap(5, 15, cImagem, 110, 50)
    oPrinter:Say(nLin+10, nCol + 170, "PRODUCAO", oFont10)
    oPrinter:SayAlign(nLin+10, nCol + 125, 'SB1->B1_DESC', oFont10, 175, 20,, 2, 1)

    nLin += 50
    oPrinter:Say(nLin, nCol + 10, "ORDEM DE PRODUCAO: " + 'SH6->H6_OP', oFont6)
    nLin += 8
    oPrinter:Say(nLin, nCol + 10, "LOTE: " + 'SH6->H6_LOTECTL', oFont6)
    nLin += 8
    oPrinter:Say(nLin, nCol + 10, "VALIDADE: " + 'dtoc(SH6->H6_DTVALID)', oFont6)
    nLin += 8
    oPrinter:Say(nLin, nCol + 10, "DATA: " + 'dtoc(SH6->H6_DTAPONT)', oFont6)
    nLin += 8
    oPrinter:Say(nLin, nCol + 10, "QUANTIDADE: " + 'cQuantidade', oFont6)
    nLin += 8
    oPrinter:Say(nLin, nCol + 10, "CÓDIGO PRODUTO: " + 'SH6->H6_PRODUTO', oFont6)
    nLin += 8
    oPrinter:Say(nLin, nCol + 10, "UM: " + 'SB1->B1_UM', oFont6)
    nLin += 8
    oPrinter:Say(nLin, nCol + 10, "TIPO: " + 'SB1->B1_TIPO', oFont6)

    oPrinter:Code128(40, 185, 'AllTrim(SH6->H6_PRODUTO)', 0.5, 25, .T., oFont6)

    // if AllTrim(SH6->H6_LOTECTL) != ""
    // oPrinter:Code128(75, 185, 'AllTrim(SH6->H6_LOTECTL)', 0.5, 25, .T., oFont6) 
    // endif
    
    oPrinter:Code128(120, 185, 'AllTrim(cQuantidade)', 0.5, 25, .T., oFont6)

    oPrinter:EndPage()
Return nil
