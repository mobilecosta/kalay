#include "totvs.ch"
#include 'parmtype.ch'
#include "RPTDef.CH"
#include "FWPrintSetup.ch"

/*/{Protheus.doc} PrintPedido
Classe de impressao de Pedidos de Venda e Orcamentos
@type class
@version 1.00
@author Luiz Alves Felizardo
@since 11/08/2022
/*/
Class PrintPedido From LongNameClass

    Data Cliente            As PrintPed_Cliente
    Data Transportadora     As PrintPed_Tranportadora
    Data CondicaoPagamento  As PrintPed_CondicaoPagamento
    Data Empresa            As PrintPed_Empresa
    Data Vendedor           As Array
    Data Itens              As Array
    Data Colunas_Relatorio  As Array
    Data Vencimentos        As Array
    Data Arquivos           As Array
    Data Frete_Valor        As Numeric
    Data Peso_Total         As Numeric
    Data Peso_Liquido       As Numeric
    Data Total_Pedido       As Numeric
    Data Despesas           As Numeric
    Data Numero             As Character
    Data Tipo               As Character
    Data Frete_Tipo         As Character
    Data Observacao         As Character
    Data Forma_Pagamento    As Character
    Data Natureza_Operacao  As Character
    Data Usuario_Codigo     As Character
    Data Usuario_Nome       As Character
    Data Arquivo_Pasta      As Character
    Data Arquivo_Nome       As Character
    Data Impressao_Regras   As Character
    Data Impressao_Detalhes As Character
    Data Impressao_Logo     As Character
    Data Valor_Extenso      As Character
    Data Arquivo_Regra      As Character
    Data Print              As Object
    Data Impressao_Tipo     As Numeric //1-Imprime, 2-Envia e-mail
    Data Data_Emissao       As Date

    Method New(cTipo) Constructor
    Method LeDados(cNumero)
    Method LeOrc(cFil, cNumero)
    Method LePed(cFil, cNumero)
    Method Close()
    Method PrintIni(cFil, cNumero)
    Method Imprime()
    Method Imprime_Cab()
    Method Imprime_Rod()
    Method PrintFim()
    Method CondComerc(cCondComerc)

EndClass

/*/{Protheus.doc} PrintPedido::New
Metodo de construcao da classe
@type method
@version 1.00
@author Luiz Alves Felizardo
@since 11/08/2022
@param cTipo, character, ORC - Orcamento
                         PED - Pedido de Venda
/*/
Method New(cTipo) Class PrintPedido

    Local  aPergs    As Array
    Local  aRet      As Array
    Local  aTipo     As Array
    Local  aDetProd  As Array
    Local  aImpRegra As Array

    Public nMgRight  As Numeric
	Public nMgDown   As Numeric

    ::Cliente            := PrintPed_Cliente():New()
    ::Transportadora     := PrintPed_Transportadora():New()
    ::Empresa            := PrintPed_Empresa():New()
    ::CondicaoPagamento  := PrintPed_CondicaoPagamento():New()
    ::Print              := Nil
    ::Frete_Valor        := 0
    ::Peso_Total         := 0
    ::Peso_Liquido       := 0
    ::Despesas           := 0
    ::Tipo               := cTipo
    ::Numero             := ""
    ::Frete_Tipo         := ""
    ::Observacao         := ""
    ::Natureza_Operacao  := ""
    ::Forma_Pagamento    := ""
    ::Usuario_Codigo     := ""
    ::Usuario_Nome       := ""
    ::Arquivo_Nome       := ""
    ::Arquivo_Pasta      := ""
    ::Impressao_Regras   := ""
    ::Impressao_Detalhes := ""
    ::Impressao_Logo     := ""
    ::Valor_Extenso      := ""
    ::Arquivo_Regra      := ""
    ::Impressao_Tipo     := 1
    ::Vendedor           := {}
    ::Itens              := {}
    ::Vencimentos        := {}
    ::Colunas_Relatorio  := {}
    ::Arquivos           := {}
    ::Data_Emissao       := SToD("")


    // Tabela de cã³digos de alinhamento horizontal.
    // 0 - Alinhamento ã  esquerda;
    // 1 - Alinhamento ã  direita;
    // 2 - Alinhamento centralizado
    // 3 - Alinhamento justificado. (Operação disponí­vel somente a partir da versão 1.6.2 da TOTVS Printer.)

    aAdd(::Colunas_Relatorio, {0080, "Item"          , 2, "Item"              , ""                   })
	aAdd(::Colunas_Relatorio, {0300, "Produto"	     , 0, "Codigo"            , ""                   })
	aAdd(::Colunas_Relatorio, {1000, "Descrição"     , 0, "Descricao"         , ""                   })
    aAdd(::Colunas_Relatorio, {0800, "Observação"    , 0, "XObservacao"        , ""                   })
	aAdd(::Colunas_Relatorio, {0100, "UN"            , 0, "Unidade_Medida"    , ""                   })	
	aAdd(::Colunas_Relatorio, {0150, "Qt.Pedida"     , 1, "Quantidade"        , "@E 9,999,999,999.99"})
	aAdd(::Colunas_Relatorio, {0150, "Vlr. S/I"      , 1, "Valor_Unitario_Liq", "@E 9,999,999,999.99"})
    aAdd(::Colunas_Relatorio, {0150, "Moeda"         , 2, "Moeda"             , ""                   })    
    aAdd(::Colunas_Relatorio, {0150, "IPI"           , 2, "XIPI"              , ""                   })
	aAdd(::Colunas_Relatorio, {0150, "NCM"           , 2, "NCM"               , ""                   })

    aRet      := {}
    aPergs    := {}
    aTipo     := {"I=Imprime", "E=Envia e-mail"}
    aDetProd  := {"S=Sim"    , "N=Não"         }
    aImpRegra := {"S=Sim"    , "N=Não"         }

    aAdd(aPergs, {2, "Tipo"           , "I", aTipo    , 50, ".T.", .F.})
    aAdd(aPergs, {2, "Detalha Produto", "S", aDetProd , 50, ".T.", .F.})
    aAdd(aPergs, {2, "Imprime Regras" , "S", aImpRegra, 50, ".T.", .F.})

               //aParametros, cTitle     , aRet , bOk, aButtons, lCentered, nPosX, nPosy, oDlgWizard, cLoad, lCanSave, lUserSave
    If !ParamBox(aPergs     , "Impressão", @aRet,    ,         , .T.      ,      ,      ,           ,      , .T.     , .T.      )
        Return(Nil)
    EndIf

    ::Impressao_Tipo     := IIF(Left(aRet[1], 1) = "I", 1, 2)
    ::Impressao_Detalhes := Left(aRet[2], 1)
    ::Impressao_Regras   := Left(aRet[3], 1)
Return()

/*/{Protheus.doc} PrintPedido::Close
Efetua e exclusao do objeto
@type method
@version 1.00
@author Luiz Alves Felizardo
@since 11/08/2022
/*/
Method Close() Class PrintPedido

    ::Cliente:Close()
    ::Transportadora:Close()
    ::Empresa:Close()
    ::CondicaoPagamento:Close()

Return()

/*/{Protheus.doc} PrintPedido::LeDados
Efetua a leitura e carga dos dados no classe
@type method
@version 1.00
@author Luiz Alves Felizardo
@since 11/08/2022
@param cFil   , character, Filial do Pedido ou Orcamento a ser lido
@param cNumero, character, Numero do Pedido ou Orcamento a ser lido
/*/
Method LeDados(cFil, cNumero) Class PrintPedido

    ::Frete_Valor       := 0
    ::Peso_Total        := 0
    ::Peso_Liquido      := 0
    ::Despesas          := 0
    ::Numero            := ""
    ::Frete_Tipo        := ""
    ::Observacao        := ""
    ::Natureza_Operacao := ""
    ::Forma_Pagamento   := ""
    ::Usuario_Codigo    := ""
    ::Usuario_Nome      := ""
    ::Valor_Extenso     := ""
    ::Arquivo_Regra     := ""
    ::Data_Emissao      := SToD("")
    ::Itens             := {}
    ::Vencimentos       := {}
    ::Vendedor          := {}

    Do Case
        Case ::Tipo = "ORC"
                If !::LeOrc(cFil, cNumero)
                    Return(.F.)
                Endif

        Case ::Tipo = "PED"
                If !::LePed(cFil, cNumero)
                    Return(.F.)
                EndIf
    EndCase

Return(.T.)

/*/{Protheus.doc} PrintPedido::PrintIni
Inicia a impressao do relatorio
@type method
@version  1.00
@author Luiz Alves Felizardo
@since 12/22/2022
@param cFil   , character, Filial do Pedido ou Orcamento
@param cNumero, character, Numero do Pedido ou Orcamento
@return Logical, Se iniciou com sucesso ou nao
/*/
Method PrintIni(cFil, cNumero) Class PrintPedido

    Local   cPastaRel As Character
    Local   cNomeArq  As Character
    Local   lFirst    As Logical

    lFirst := Empty(::Numero)
  
    If !::LeDados(cFil, cNumero)
        Return(.F.)
    EndIf

    cPastaRel := AllTrim(SuperGetMV("MT_DIRREL", .F., "\imp_rel\"))
    cNomeArq  := ::Tipo + "_" + ::Numero + "_" + DToS(dDataBase) + "_" + StrTran(Time(), ":", "") + ".PDF"

	If !ExistDir(cPastaRel)
		If MakeDir(cPastaRel) > 0
            MsgAlert("Não foi possível criar a pasta dos temporários (" + cPastaRel + ")" + ;
                     "Error: " + cValToChar(FError())                                       , "Atenção")
            Return(.F.)
        EndIf        
	EndIf

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

    ::Arquivo_Pasta  := IIF(lFirst, cPastaRel, ::Arquivo_Pasta)
    ::Arquivo_Nome   := cNomeArq
    ::Impressao_Logo := cArqLogo

	If ::Impressao_Tipo == 1
		lVisuPDF := .T.
	Else
		lVisuPDF := .F.
	EndIf

    cTitulo := IIF(::Tipo = "ORC", "Orcamento de Venda", "Pedido de Venda")
    cTitulo += ::Numero + "_" + ::Cliente:Codigo + "_" + ::Cliente:Loja + "_" + ::Cliente:Nome_Fantasia

    aAdd(::Arquivos, {::Cliente:eMail, cNomeArq, cTitulo})

	::Print := FWMSPrinter():New(::Arquivo_Nome, IMP_PDF, .T., ::Arquivo_Pasta, .T.,,,, .F., .F.,, lVisuPDF)        
        ::Print:cPathPDF := ::Arquivo_Pasta    
        ::Print:SetResolution(78)
        ::Print:SetMargin(60, 60, 60, 60)

        nMgRight := 3100
        nMgDown	 := 2300

        If ::Impressao_Tipo == 1
            ::Print:SetLandscape(.T.)
            ::Print:SetPaperSize(DMPAPER_A4)
            If lFirst
                ::Print:Setup()
                ::Arquivo_Pasta := ::Print:cPathPDF
            EndIf
            
            If lFirst
                If ::Print:nModalResult == PD_OK
                    ::Print:SetPaperSize(DMPAPER_A4)
                Else
                    Return(.F.)
                EndIf
            Else
                ::Print:SetPaperSize(DMPAPER_A4)
            EnDIf
        Else
            ::Print:SetLandscape(.T.)
            ::Print:SetPaperSize(DMPAPER_A4)
        EndIf
Return(.T.)

/*/{Protheus.doc} PrintPedido::Imprime
Realiza a impressao do pedido
@type method
@version 1.00
@author Luiz Alves Felizardo
@since 12/22/2022
/*/
Method Imprime() Class PrintPedido

    Local   nI       As Numeric
    Local   nX       As Numeric
    Local   nW       As Numeric
    Local   cDirRel  As Character

    Private nPagAtu  As Numeric
    Private nPagTot  As Numeric
    Private nLimCDet As Numeric //Limite de linhas com detalhes
    Private nLimSDet As Numeric //Limite de linhas sem detalhes
    Private nContLin As Numeric
    Private cHoraRel As Character
 	Private oFontIt  As Object
	Private oFontItn As Object
	Private oFont12  As Object
	Private oFont12n As Object
	Private oFont14n As Object
	Private oFont16n As Object
	Private oFont20n As Object

 	oFontIt	 := TFont():New("Arial",, 09,, .F.,,,, .F., .F.)
    oFontIt2 := TFont():New("Arial",, 11,, .F.,,,, .F., .F.)
	oFontItn := TFont():New("Arial",, 09,, .T.,,,, .F., .F.)
	oFont12	 := TFont():New("Arial",, 12,, .F.,,,, .F., .F.)
	oFont12n := TFont():New("Arial",, 12,, .T.,,,, .F., .F.)
	oFont14n := TFont():New("Arial",, 14,, .T.,,,, .F., .F.)
	oFont16n := TFont():New("Arial",, 16,, .T.,,,, .F., .F.)
	oFont20n := TFont():New("Arial",, 20,, .T.,,,, .F., .F.)
    cDirRel  := AllTrim(SuperGetMV("MT_DIRREL", .F., "\imp_rel\"))
    nI       := 0
    nLin     := 0
    nLimCDet := 3
    nLimSDet := 20
    nTotal   := 0
    nPagAtu  := 1    
    nPagTot  := Len(::Itens) / nLimSDet
    nPagTot  += IIF(::Impressao_Detalhes = "S", Len(::Itens) / nLimCDet, 0)
    nPagTot  := Int(nPagTot) + IIF(nPagTot - Int(nPagTot) > 0, 1, 0)
    cHoraRel := Time()
    aRegras  := {}
    lBrush   := .F.
    nContLin  := 0

    If ::Impressao_Regras = "S"
        oFile := FwFileReader():New(cDirRel + ::Arquivo_Regra)
        If oFile:Open()
            cRegras := OemToAnsi(AllTrim(oFile:FullRead()))
            aRegras := ::CondComerc(cRegras)
            oFile:Close()

            nPagRegras := Len(aRegras) / 30
            nPagRegras := Int(nPagRegras) + IIF(nPagRegras - Int(nPagRegras) > 0, 1, 0)
            nPagTot    += nPagRegras
        EndIf
    EndIf

    ::Imprime_Cab()

    //
	aColTot := {}
    aAdd(aColTot, "ICMS"          )
    // aAdd(aColTot, "IPI"           )
	aAdd(aColTot, "Sub. Trib."    )
    aAdd(aColTot, "Vrl.Un. C/ IPI")
	aAdd(aColTot, "Vlr. Total"    )
    aAdd(aColTot, "Vlr.Un. Liq"   ) 

    //Monta a linha de totalizadores de itens
    aTotItens := {}
    For nX := 1 To Len(::Colunas_Relatorio)
        If ::Colunas_Relatorio[nX, 3] = 1
            aAdd(aTotItens, 0 )
        Else
            aAdd(aTotItens, "")
        EndIf
    Next

    For nI := 1 To Len(::Itens)
        nLin    += 56
        nColAtu := 0
        oItem   := ::Itens[nI]
        
        fVerBrush(::Print, nLin, 056, nMgRight, @lBrush)

        For nX := 1 To Len(::Colunas_Relatorio)
            cDados := "oItem:" + ::Colunas_Relatorio[nX, 4]
            xDados := &(cDados)
            nDados := 0

            Do Case
                Case valType(xDados) == "N"
                        cDados := AlLTrim(Transform(xDados, ::Colunas_Relatorio[nX, 5]))
                        nDados := xDados

                Case valType(xDados) == "D"
                        cDados := DToC(xDados)

                Otherwise
                        cDados := xDados
            EndCase

            nPosTot := aScan(aColTot, {|x| x = ::Colunas_Relatorio[nX, 2]})
            If nPosTot > 0
                aTotItens[nX] += nDados
            EndIf

            ::Print:SayAlign(nlin, nColAtu, cDados, oFontIt, ::Colunas_Relatorio[nX, 1], 50,, ::Colunas_Relatorio[nX, 3])
            nColAtu  += ::Colunas_Relatorio[nX, 1]
        Next

        nContLin++
        nTotal  += oItem:Total

        If nContLin >= nLimSDet .AND. nI < Len(::Itens)
            ::Imprime_Rod()
            ::Imprime_Cab()
            nContLin := 0
        EndIf
    Next

    //Totalizador de itens
    nLin    += 56
    nColAtu := 0
    fVerBrush(::Print, nLin, 056, nMgRight, @lBrush)

    For nX := 1 To Len(::Colunas_Relatorio)

        If nX = 1
            ::Print:SayAlign(nlin, nColAtu, "Total", oFontItn, ::Colunas_Relatorio[nX, 1], 50,, ::Colunas_Relatorio[nX, 3])
            nColAtu += ::Colunas_Relatorio[nX, 1]
            Loop
        EndIf
        
        nPosTot := aScan(aColTot, {|x| x = ::Colunas_Relatorio[nX, 2]})
        If nPosTot = 0
            nColAtu += ::Colunas_Relatorio[nX, 1]
            Loop
        EndIf

        xDados := AllTrim(Transform(aTotItens[nX], ::Colunas_Relatorio[nX, 5]))

        ::Print:SayAlign(nlin, nColAtu, xDados, oFontItn, ::Colunas_Relatorio[nX, 1], 50,, ::Colunas_Relatorio[nX, 3])

        nColAtu += ::Colunas_Relatorio[nX, 1]
    Next

    ::Imprime_Rod()

    //Imprime os detalhes dos produtos em nova pagina
    If ::Impressao_Detalhes = "S"
        ::Imprime_Cab(.F.)
        nContLin := 0

        For nI := 1 To Len(::Itens)
            nColAtu := 0
            oItem   := ::Itens[nI]
            
            nContLin++

            nLinIni := nLin
            nLin    += 50
            fVerBrush(::Print, nLin, 400, nMgRight, @lBrush)
            ::Print:SayAlign(nlin, 0020, "Código: " + oItem:Codigo      , oFontIt, 500, 50,, 0)

            nLin    += 50
            ::Print:SayAlign(nlin, 0020, "Descrição: " + oItem:Descricao, oFontIt, 500, 50,, 0)

            cArquivo := cDirRel + AllTrim(oItem:Codigo) + ".bmp"
            If File(cArquivo)
                fErase(cArquivo)
            EndIf

            lPict := RepExtract(oItem:Imagem, cArquivo, .T., .T.)

            If !File(cArquivo)
                cArquivo := Left(cArquivo, Len(cArquivo) - 3) + "jpg"
                If !File(cArquivo)
                    cArquivo := Left(cArquivo, Len(cArquivo) - 3) + "mpeg"
                    If !File(cArquivo)
                        lPict := .F.
                    EndIf
                EndIf
            EndIf

            If lPict
                nLin += 50
                ::Print:SayBitmap(nLin, 020, cArquivo, 350, 250)            
            EndIf

            //Coluna dois do desenho
            nLin    := nLinIni
            nLin    += 150
            ::Print:SayAlign(nlin, 420, "Comprimento: "  + Transform(oItem:Comprimento , PesqPict("SB5", "B5_COMPR" )), oFontIt, 500, 50,, 0)
            nLin    += 50
            ::Print:SayAlign(nlin, 420, "Largura: "      + Transform(oItem:Largura     , PesqPict("SB5", "B5_LARG"  )), oFontIt, 500, 50,, 0)
            nLin    += 50
            ::Print:SayAlign(nlin, 420, "Espessura: "    + Transform(oItem:Espessura   , PesqPict("SB5", "B5_ESPESS")), oFontIt, 500, 50,, 0)
            nLin    += 50
            ::Print:SayAlign(nlin, 420, "Peso Bruto: "   + Transform(oItem:Peso_Bruto  , PesqPict("SB1", "B1_PESO"  )), oFontIt, 500, 50,, 0)
            nLin    += 50
            ::Print:SayAlign(nlin, 420, "Peso Líquido: " + Transform(oItem:Peso_Liquido, PesqPict("SB1", "B1_PESBRU")), oFontIt, 500, 50,, 0)

            //Coluna trãªs do desenho
            nLin    := nLinIni
            nLin    += 50
            ::Print:SayAlign(nlin, 800, "Detalhes do Produto"                , oFontIt, 2000, 50,, 0)

            aDetalhes := StrTokArr(oItem:Detalhes, Chr(10))
            For nW := 1 To Len(aDetalhes)
                nLin    += 34
                ::Print:SayAlign(nlin, 800, aDetalhes[nW]                    , oFontIt, 2000, 50,, 0)
            Next

            nLin := nLinIni
            nLin += 360
            nLin += 50
            If nContLin >= nLimCDet .AND. nI < Len(::Itens)
                ::Imprime_Rod()
                ::Imprime_Cab(.F.)
                nContLin := 0
            EndIf
        Next

        ::Imprime_Rod()
    EndIf

    If ::Impressao_Regras = "S" .AND. Len(aRegras) > 0
        nContLin  := 0

        ::Imprime_Cab(.F.)

        For nW := 1 To Len(aRegras)
            nContLin++
            nLin    += 34
            ::Print:SayAlign(nlin, 0020, aRegras[nW]                    , oFontIt2, 3000, 50,, 0)

            If nContLin > 30
                nContLin := 0
                ::Imprime_Rod()
                ::Imprime_Cab(.F.)
            Endif
        Next

        ::Imprime_Rod()
    EndIf
Return()

/*/{Protheus.doc} PrintPedido::Imprime_Cab
Imprime o cabecalho
@type method
@version 1.00
@author Luiz Alves Felizardo
@since 12/22/2022
@param lImpItens, logical, Define se imprimira o cabecalho dos itens
/*/
Method Imprime_Cab(lImpItens) Class PrintPedido

    Local   nI        := 0
	Local   cArqLogo  := ::Impressao_Logo
	Local   nColEmpr  := 450
	Local   nColOrca  := 2500
	Local   nLinBox	  := 0
	Local   nAltura	  := 35
	Local   nColUsr	  := 1000
	Local   nColSta	  := 1800
	Local   nColPed	  := 2500
	Local   nColCond  := 2000
	Local   nColCli	  := 200

    Default lImpItens := .T.

    nlin     := 0
    lBrush   := .F.
    nQtdVend := 1// Len(::Vendedor)
    nQtdVend := 1//IIF(nQtdVend = 0, 1, nQtdVend)

    ::Print:StartPage() 
    ::Print:SayBitmap(000,000, cArqLogo, 400, 300)
    
	//Empresa
	::Print:SayAlign(nlin, nColEmpr, ::Empresa:Razao_Social                                      , oFont12 , nColOrca - nColEmpr, nAltura,, 0)
    
	nlin += 34
	::Print:SayAlign(nlin, nColEmpr, ::Empresa:Endereco                                          , oFont12 , nColOrca - nColEmpr, nAltura,, 0)

	nlin += 34
	::Print:SayAlign(nlin, nColEmpr, Transform(::Empresa:CEP,"@R 99999-999") + " - " + ;
                                    ::Empresa:Cidade                        + "-"   + ;
     							    ::Empresa:Estado                                            , oFont12 , nColOrca - nColEmpr, nAltura,, 0)

	nlin += 34
	::Print:SayAlign(nlin, nColEmpr, "Fone: " + ::Empresa:Telefone + ;
                                    " - Fax: " + ::Empresa:FAX                                  , oFont12 , nColOrca - nColEmpr, nAltura,, 0)

	nlin += 34
	::Print:SayAlign(nlin, nColEmpr, "CNPJ " + Transform(::Empresa:CNPJ, "@R 99.999.999/9999-99"), oFont12 , nColOrca - nColEmpr, nAltura,, 0)

	nlin += 34
	::Print:SayAlign(nlin, nColEmpr, "Inscrição Estadual: " + ::Empresa:IE                       , oFont12 , nColOrca - nColEmpr, nAltura,, 0)

	nlin += 34
	::Print:SayAlign(nlin, nColEmpr, "Web Site: " + ::Empresa:Site                               , oFont12 , nColOrca - nColEmpr, nAltura,, 0)
	
    nlin += 34
	::Print:SayAlign(nlin, nColEmpr, "E-mail: " + ::Empresa:Email                                , oFont12 , nColOrca - nColEmpr, nAltura,, 0)

	//Orã§amento
    Do Case
        Case ::Tipo = "ORC"
            cTitulo := "Orçamento de Venda"

        Case ::Tipo = "PED"
            cTitulo := "Pedido de Venda"

        Otherwise
            cTitulo := ""
    EndCase

	nlin := 0
	::Print:SayAlign(nlin, nColOrca, cTitulo                                                     , oFont20n, nMgRight - nColOrca, 100    ,, 2)
	
    nlin += 100
	::Print:SayAlign(nlin, nColOrca, "Departamento Comercial"	                                , oFont16n, nMgRight - nColOrca, 100    ,, 2)
	
    nlin += 100
	::Print:SayAlign(nlin, nColOrca, DtoC(dDataBase) + " - " +;
                                    cHoraRel                +;
                                    " - Página: " + cValToChar(nPagAtu) + " de " + ;
                                    cValToChar(nPagTot)	                                        , oFont12 , nMgRight - nColOrca, nAltura,, 2)

	//Vendedor e Info do Pedido
	nLin    := 300
	nLinBox := 294
	::Print:Box(nLinBox, 000	, nLinBox + (nQtdVend * 60) + 10, nColUsr ) //Box Vendedor
	::Print:Box(nLinBox, nColUsr, nLinBox + (nQtdVend * 60) + 10, nColPed ) //Box Usuario
	::Print:Box(nLinBox, nColPed, nLinBox + (nQtdVend * 60) + 10, nMgRight) //Box Pedido

    ::Print:SayAlign(nlin, 0020        , "Vendedor:"                  , oFont12n, nColSta            , nAltura,, 0)
    ::Print:SayAlign(nlin, nColUsr + 20, "Usuario: "  + ::Usuario_Nome, oFont12n, nColSta - nColUsr  , nAltura,, 0)
	::Print:SayAlign(nlin, nColPed + 20, "Pedido N.: " + ::Numero     , oFont12n, nMgRight - nColPed , nAltura,, 0)

    If Len(::Vendedor) > 0
        For nI := 1 To 1//Len(::Vendedor)
            ::Print:SayAlign(nlin, 0200, ::Vendedor[nI, 1], oFont12n, nColSta, nAltura,, 0)
            nlin += 35
        Next
    Else
        nlin += 35
    EndIf

	//Cliente
	nlin    += 40
    nLinIni := nLin
    nLinBox += (nQtdVend * 35) + 20
	::Print:Box(nLinBox, 000, nLinBox + 320, nColCond)    //Box Cliente
	
	::Print:SayAlign(nlin, 0000, "Cód. Cliente:"                                                 , oFont12n, nColCli           , nAltura,, 1)
	::Print:SayAlign(nlin, 0210, ::Cliente:Codigo + "-" + ::Cliente:Loja                  		 , oFont12 , nColCond - nColCli, nAltura,, 0)
	::Print:SayAlign(nlin, 1280, "UF:"                                                           , oFont12n, nColCli           , nAltura,, 0)
	::Print:SayAlign(nlin, 1370, ::Cliente:UF                                                    , oFont12 , 200	           , nAltura,, 0)
	
    nlin += 35
	::Print:SayAlign(nlin, 0000, "Razão Social:"                                                 , oFont12n, nColCli           , nAltura,, 1)
	::Print:SayAlign(nlin, 0210, ::Cliente:Razao_Social                                          , oFont12 , nColCond - nColCli, nAltura,, 0)
	::Print:SayAlign(nlin, 1280, "CEP:"                                                          , oFont12n, nColCli           , nAltura,, 0)
	::Print:SayAlign(nlin, 1370, Transform(::Cliente:CEP, "@R 99999-999")                        , oFont12 , 200               , nAltura,, 0)
	
    nlin += 35
	::Print:SayAlign(nlin, 0000, "Nome:"		                                                 , oFont12n, nColCli           , nAltura,, 1)
	::Print:SayAlign(nlin, 0210, ::Cliente:Nome_Fantasia                                         , oFont12 , nColCond - nColCli, nAltura,, 0)
	::Print:SayAlign(nlin, 1280, "Insc. Estadual:"                                               , oFont12n, 300	           , nAltura,, 0)	
	::Print:SayAlign(nlin, 1500, ::Cliente:IE                                                    , oFont12 , 500	           , nAltura,, 0)
	
    nlin += 35
	::Print:SayAlign(nlin, 0000, "Endereço:"			                                         , oFont12n, nColCli           , nAltura,, 1)
	::Print:SayAlign(nlin, 0210, ::Cliente:Endereco + " - " + ::Cliente:Bairro                   , oFont12 , nColCond - nColCli, nAltura,, 0)
	
    nlin += 35
	::Print:SayAlign(nlin, 0000, "Cidade:"                                                       , oFont12n, nColCli           , nAltura,, 1)
	::Print:SayAlign(nlin, 0210, ::Cliente:Cidade                                                , oFont12 , 950	              , nAltura,, 0)
	
    nlin += 35
	::Print:SayAlign(nlin, 0000, "Telefone:"                                                     , oFont12n, nColCli           , nAltura,, 1)
	::Print:SayAlign(nlin, 0210, ::Cliente:Telefone                                              , oFont12 , 650               , nAltura,, 0)
	
    nlin += 35
	::Print:SayAlign(nlin, 0000, "CNPJ / CPF:"                                                   , oFont12n, nColCli           , nAltura,, 1)	
	::Print:SayAlign(nlin, 0210, ::Cliente:CPF_CNPJ                                              , oFont12 , 500		          , nAltura,, 0)

    nlin += 35
	::Print:SayAlign(nlin, 0000, "E-Mail:"			                                            , oFont12n, nColCli	          , nAltura,, 1)
	::Print:SayAlign(nlin, 0210, ::Cliente:EMail                                                 , oFont12 , 650               , nAltura,, 0)

	//Condiã§ãµes
	::Print:Box(nLinBox, nColCond, nLinBox + 320, nMgRight)		//Box Condiã§ãµes
	
    nLinFim := nLin
	nLin    := nLinIni	
	::Print:SayAlign(nlin, nColCond      , "Condições Gerais"			                        , oFont12n, nMgRight - nColCond, nAltura,, 2)
	
    nlin += 35
	::Print:SayAlign(nlin, nColCond      , "Data de Criação:"			                        , oFont12n, 370                , nAltura,, 1)
	::Print:SayAlign(nlin, nColCond + 380, DtoC(::Data_Emissao)		                            , oFont12 , 700                , nAltura,, 0)
	
    // nlin += 35	
	// ::Print:SayAlign(nlin, nColCond		, "Valores expressos em (R$):"		                     , oFont12n, 370                , nAltura,, 1)
	// ::Print:SayAlign(nlin, nColCond + 380, ::Valor_Extenso                                       , oFont12 , 700                , nAltura,, 0)
	
    nlin += 35
	::Print:SayAlign(nlin, nColCond		, "Condição de pagamento:"		                         , oFont12n, 370                , nAltura,, 1)
	::Print:SayAlign(nlin, nColCond + 380, ::CondicaoPagamento:Nome                              , oFont12 , 700                , nAltura,, 0)
	
    // nlin += 35
	// ::Print:SayAlign(nlin, nColCond		, "Forma Pagamento:"					                 , oFont12n, 370                , nAltura,, 1)
	// ::Print:SayAlign(nlin, nColCond + 380, ::Forma_Pagamento                                     , oFont12 , 700                , nAltura,, 0)
	
    // nlin += 35
	// ::Print:SayAlign(nlin, nColCond		, "1º Vencimento:"                                       , oFont12n, 370                , nAltura,, 1)
	// ::Print:SayAlign(nlin, nColCond + 380, IIF(Len(::Vencimentos) = 0,;
    //                                        "", DToC(::Vencimentos[1, 1]))                       , oFont12 , 700                , nAltura,, 0)
    // nlin += 35
	// ::Print:SayAlign(nlin, nColCond		 , "Despesas:"                , oFont12n, 370  , nAltura,, 1)
	// ::Print:SayAlign(nlin, nColCond + 380, cValToChar(::Despesas)     , oFont12 , 700  , nAltura,, 0)


	//Att
	nLin    := nLinFim + 60
	nLinBox += 320
	::Print:Box(nLinBox, 000	, nLinBox + 60, nColUsr ) //Box Vendedor
	::Print:Box(nLinBox, nColUsr, nLinBox + 60, nColPed ) //Box Usuario
	::Print:Box(nLinBox, nColPed, nLinBox + 60, nMgRight) //Box Pedido

	::Print:SayAlign(nlin, 020          , "Natureza da Operação: "                               , oFont12n, 300                 , nAltura,, 0)
	::Print:SayAlign(nlin, nColUsr + 20 , "Transportadora: "                                     , oFont12n, 300                 , nAltura,, 0)
	::Print:SayAlign(nlin, nColPed + 20 , "Tipo Frete:"                                          , oFont12n, 300                 , nAltura,, 0)
    
    ::Print:SayAlign(nlin, 0350         , Left(::Natureza_Operacao, 35)                          , oFont12 , 700                 , nAltura,, 0)
    ::Print:SayAlign(nlin, nColUsr + 250, ::Transportadora:Nome                                  , oFont12 , 700                 , nAltura,, 0)
    ::Print:SayAlign(nlin, nColPed + 200, ::Frete_Tipo                                           , oFont12 , 700                 , nAltura,, 0)

    nLinBox += 50
    nlin	+= 50
    // fPrintParcelas(::Self, @nlin, nLinBox)

	// nLin    += 90
    nColAtu := 0
    If lImpItens
        For nI := 1 To Len(::Colunas_Relatorio)
            ::Print:SayAlign(nlin, nColAtu, ::Colunas_Relatorio[nI, 2], oFontItn, ::Colunas_Relatorio[nI, 1], 50,, ::Colunas_Relatorio[nI, 3])
            nColAtu  += ::Colunas_Relatorio[nI, 1]
        Next
    EndIf

Return()

Static Function getLabelImpost(cChave)
	Local cText := ""

	DBSelectArea("ZLI")
	if ZLI->(dbSeek(xFilial("ZLI") + cChave))
		cText := AllTrim(ZLI->ZLI_DESC)
	else
		cText := ""
	endif
REturn cText

/*/{Protheus.doc} PrintPedido::Imprime_Rod
Imprime o rodape
@type method
@version 1.00
@author Luiz Alves Felizardo
@since 12/22/2022
/*/
Method Imprime_Rod() Class PrintPedido
	
    Local nLinBox	:= 2100
    Local nLin		:= 2100
    Local nColTra	:= 0000
    // Local nColFrete := 2500	
    Local nColFrete := 2000	
    Local nAltura	:= 300

	::Print:Box(nLinBox, nColTra  , nLinBox + nAltura, nColFrete) //Box Transportadora
	::Print:Box(nLinBox, nColFrete, nLinBox + nAltura, nMgRight ) //Box Frete

    nlin += 35
    ::Print:SayAlign(nlin, 0020, "Observação:"                                    , oFont12n, 1500     , nAltura,, 0)
    ::Print:SayAlign(nlin, nColFrete+10, "Frete: " + ::Frete_Tipo                         , oFont12 , nColFrete, nAltura,, 0)

    nlin += 35
    nWidth := 1950
    ::Print:SayAlign(nlin, 0020, ::Observacao                                     , oFont12 , nWidth     , nAltura,, 0)
    // ::Print:SayAlign(nlin, 2510, "Valor Frete: R$ " + Alltrim(Transform(::Frete_Valor,"@E 999,999,999.99")), oFont12 , nColFrete, nAltura,, 0)
    
    cEmbala := ""
    cPedMin := ""
    cDispon := ""
    cImpst  := ""
    cClass  := ""
	if ISINCALLSTACK("MATA415")
		cEmbala := AllTrim(SX5Desc("Z1", AllTrim(SCJ->CJ_XEMBALA)))
        cPedMin := AllTrim(SX5Desc("Z2", AllTrim(SCJ->CJ_XPEDMIN )))
        cDispon := AllTrim(SX5Desc("Z3", AllTrim(SCJ->CJ_XDISPON )))
        cImpst  := getLabelImpost(AllTrim(SCJ->CJ_XINFIMP ))
        cClass  := AcaX3Combo("CJ_XCLASS", SCJ->CJ_XCLASS)
	elseif ISINCALLSTACK("MATA410")
		cEmbala := AllTrim(SX5Desc("Z1", AllTrim(SC5->C5_XEMBALA)))
        cPedMin := AllTrim(SX5Desc("Z2", AllTrim(SC5->C5_XPEDMIN )))
        cDispon := AllTrim(SX5Desc("Z3", AllTrim(SC5->C5_XDISPON )))
        cImpst  := getLabelImpost(AllTrim(SC5->C5_XINFIMP))
        cClass := AcaX3Combo("C5_XCLASS", SC5->C5_XCLASS)
	endif

    // SX5Desc("Z1", '01')
    ::Print:SayAlign(nlin, nColFrete+10, "Embalagem: " + cEmbala, oFont12 , nColFrete, nAltura,, 0)

    nlin += 35
    // ::Print:SayAlign(nlin, nColFrete+10, "Peso Total(kg): " + cValToChar(::Peso_Total)    , oFont12 , nColFrete, nAltura,, 0)
    ::Print:SayAlign(nlin, nColFrete+10, "Pedido mínimo: " + cPedMin, oFont12 , nColFrete, nAltura,, 0)

    nlin += 35
    // ::Print:SayAlign(nlin, nColFrete+10, "Peso Líquido(kg): " + cValToChar(::Peso_Liquido), oFont12 , nColFrete, nAltura,, 0)
    ::Print:SayAlign(nlin, nColFrete+10, "Disponibilidade: " + cDispon, oFont12 , nColFrete, nAltura,, 0)

    nlin += 35
    ::Print:SayAlign(nlin, nColFrete+10, "Classificação: " + cClass, oFont12 , nColFrete, nAltura,, 0)

    nlin += 35
    nColx := 1200
    ::Print:SayAlign(nlin, nColFrete+10, cImpst, oFont12 , nColx, nAltura,, 0)

    ::Print:EndPage()

    nPagAtu++
Return()

Static Function AcaX3Combo(cCampo,cConteudo)
Local aSx3Box   := RetSx3Box( Posicione("SX3", 2, cCampo, "X3CBox()" ),,, 1 )
If cConteudo == ""
	cConteudo := " " 
EndIf
REturn Upper(AllTrim( aSx3Box[Ascan( aSx3Box, { |aBox| aBox[2] = cConteudo } )][3] ))


/*/{Protheus.doc} PrintPedido::PrintFim
Finaliza a impressao enviado o PDF para impressora ou email
@type method
@version 1.00
@author Luiz Alves Felizardo
@since 12/22/2022
/*/
Method PrintFim() Class PrintPedido


    Local nI     As Numeric
    Local cCopia As Character

    cCopia := ""
    
    ::Print:EndPage()
    ::Print:Preview()

    If ::Impressao_Tipo = 2
        cCopia := ""
        
        For nI := 1 To Len(::Vendedor)
            If Empty(::Vendedor[nI, 2])
                Loop
            EndIf
            cCopia += ::Vendedor[nI, 2] + ";"
        Next

        cCopia := Left(cCopia, Len(cCopia) - 1)

        For nI := 1 To Len(::Arquivos)
            fEnviaMail(::Cliente:EMail, ::Arquivos[nI, 2], ::Arquivos[nI, 3], cCopia)
        Next
    EndIf

Return()

*********************************************
Method LeOrc(cFil, cNumero) Class PrintPedido
*********************************************

    Local nTPesLiq As Numeric
    Local nTPesBru As Numeric
    Local nTPedido As Numeric
    Local nX       As Numeric
    Local cNatOper As Character

    nTPesLiq := 0
    nTPesBru := 0
    nTPedido := 0
    nX       := 0

    DBSelectArea("SCJ")
    DBSelectArea("SCK")    

    SCJ->(DBSetOrder(1))
    SCK->(DBSetOrder(1))
    
    If SCJ->(!DBSeek(cFil + cNumero))
        Return(.F.)
    EndIf

    If !::Empresa:LerDados(cFil)
        Return(.F.)
    EndIf

    If !::Cliente:LerDados(SCJ->CJ_CLIENTE, SCJ->CJ_LOJA, "SA1")
        Return(.F.)
    EndIf

    oVendedor := PrintPed_Vendedor():New()

    For nX := 1 To 10
        cCpoVend := "CJ_XVEND" + cValToChar(nX)

        If !(SCJ->(FieldPos(cCpoVend)) > 0)
            Loop
        EndIf

        If Empty(&("SCJ->" + cCpoVend))
            Loop
        EndIf
        
        oVendedor:LerDados(&("SCJ->" + cCpoVend))

        aAdd(::Vendedor, {oVendedor:Nome, oVendedor:Email})
    Next

    ::Transportadora:LerDados(SCJ->CJ_XTRANSP)
    ::CondicaoPagamento:LerDados(SCJ->CJ_CONDPAG)

    cVlrItem := 0

    SCK->(DBSeek(cFil + cNumero))
    While SCK->(!Eof());
    .AND. SCK->CK_FILIAL = cFil;
    .AND. SCK->CK_NUM    = cNumero
		cVlrItem += SCK->CK_VALOR
		SCK->(dbSkip())
	EndDo

    nVlrFrete :=  SCJ->CJ_FRETE

    SCK->(DbGoTop())
    SCK->(DBSeek(cFil + cNumero))
    While SCK->(!Eof());
        .AND. SCK->CK_FILIAL = cFil;
        .AND. SCK->CK_NUM    = cNumero

        If Empty(cNatOper) .AND. !Empty(SCK->CK_TES)
            If SF4->(DBSeek(xFilial("SF4") + SCK->CK_TES))
                cNatOper := SF4->F4_TEXTO
            EndIf
        EndIf

        //Calculo de valor percentual de um item em relação ao total de mercadoria, necessário para calcular o percentual de frete a ser aplicado no item
        nPercFrete := (SCK->CK_VALOR * 100) / cVlrItem
        nVlrFItem  := nVlrFrete * (nPercFrete/100)

        oProd := PrintPed_Item():New()
            oProd:LerDados(SCK->CK_ITEM   ,;
                           SCK->CK_PRODUTO,;
                           SCK->CK_UM     ,;
                           SCK->CK_QTDVEN ,;
                           SCK->CK_PRCVEN ,;
                           SCK->CK_TES    ,;
                           SCK->CK_XOBS   ,;
                           SCJ->CJ_CLIENTE,;
                           SCJ->CJ_LOJA   ,;
                           SCJ->CJ_TIPO   ,;
                           SCJ->CJ_TIPOCLI,;
                           nVlrFItem       ;
            )

            aAdd(::Itens, oProd)

            nTPesLiq += oProd:Peso_Liquido
            nTPesBru += oProd:Peso_Bruto
            nTPedido += oProd:Total

            oProd:Close()

        SCK->(DBSkip())
    End

    If SCJ->CJ_TPFRETE $ "C|R"
        nTPedido += SCJ->CJ_DESPESA
        nTPedido += SCJ->CJ_SEGURO
        nTPedido += SCJ->CJ_FRETE
        nTPedido += SCJ->CJ_FRETAUT
    EndIf

    ::Numero            := SCJ->CJ_NUM
    ::Usuario_Codigo    := SCJ->CJ_XUSRINC
    ::Usuario_Nome      := AllTrim(UsrRetName(SCJ->CJ_XUSRINC))
    ::Forma_Pagamento   := SCJ->CJ_XFORMA + " - " + Posicione("SX5", 1, xFilial("SX5") + "24" + SCJ->CJ_XFORMA, "X5_DESCRI")
    ::Frete_Tipo        := fTipoFrete(SCJ->CJ_TPFRETE)
    ::Frete_Valor       := SCJ->CJ_FRETE
    ::Natureza_Operacao := cNatOper
    ::Observacao        := Left(SCJ->CJ_XOBS, 810)
    ::Peso_Total        := nTPesBru
    ::Peso_Liquido      := nTPesLiq
    ::Total_Pedido      := nTPedido
    ::Valor_Extenso     := Transform(nTPedido, "@E 999,999,999.99")
    ::Vencimentos       := Condicao(nTPedido, ::CondicaoPagamento:Codigo,, dDataBase)
    ::Data_Emissao      := SCJ->CJ_EMISSAO
    ::Arquivo_Regra     := "condcomerc_orc.txt"

Return(.T.)

*********************************************
Method LePed(cFil, cNumero) Class PrintPedido
*********************************************

    Local nTPesLiq As Numeric
    Local nTPesBru As Numeric
    Local nTPedido As Numeric
    Local nX       As Numeric
    Local cNatOper As Character    

    nTPesLiq := 0
    nTPesBru := 0
    nTPedido := 0
    nX       := 0

    DBSelectArea("SC5")
    DBSelectArea("SC6")    
    DBSelectArea("SD2")    

    SC5->(DBSetOrder(1))
    SC6->(DBSetOrder(1))
    SD2->(DBSetOrder(8))
    
    If SC5->(!DBSeek(cFil + cNumero))
        Return(.F.)
    EndIf

    SD2->(DBSeek(cFil + cNumero))

    If !::Empresa:LerDados(cFil)
        Return(.F.)
    EndIf
    
    If !::Cliente:LerDados(SC5->C5_CLIENTE, SC5->C5_LOJACLI, "SA1")
        Return(.F.)
    EndIf
    
    oVendedor := PrintPed_Vendedor():New()

    For nX := 1 To 10
        cCpoVend := "C5_VEND" + cValToChar(nX)

        If !(SC5->(FieldPos(cCpoVend)) > 0)
            Loop
        EndIf
        
        If Empty(&("SC5->" + cCpoVend))
            Loop
        EndIf

        oVendedor:LerDados(&("SC5->" + cCpoVend))

        aAdd(::Vendedor, {oVendedor:Nome, oVendedor:Email})
    Next

    ::Transportadora:LerDados(SC5->C5_TRANSP)
    ::CondicaoPagamento:LerDados(SC5->C5_CONDPAG)

    cVlrItem := 0

    SC6->(DBSeek(cFil + cNumero))
    While SC6->(!Eof());
    .AND. SC6->C6_FILIAL = cFil;
    .AND. SC6->C6_NUM    = cNumero
		cVlrItem += SC6->C6_VALOR
		SC6->(dbSkip())
	EndDo

    nVlrFrete :=  SC5->C5_FRETE

    SC6->(DBGoTop())
    SC6->(DBSeek(cFil + cNumero))
    While SC6->(!Eof());
        .AND. SC6->C6_FILIAL = cFil;
        .AND. SC6->C6_NUM    = cNumero

        If Empty(cNatOper) .AND. !Empty(SC6->C6_TES)
            If SF4->(DBSeek(xFilial("SF4") + SC6->C6_TES))
                cNatOper := AllTrim(SF4->F4_TEXTO)
            EndIf
        EndIf

        //Calculo de valor percentual de um item em relação ao total de mercadoria, necessário para calcular o percentual de frete a ser aplicado no item
        nPercFrete := (SC6->C6_VALOR * 100) / cVlrItem
        nVlrFItem  := nVlrFrete * (nPercFrete/100)

        oProd := PrintPed_Item():New()
            oProd:LerDados(SC6->C6_ITEM   ,;
                           SC6->C6_PRODUTO,;
                           SC6->C6_UM     ,;
                           SC6->C6_QTDVEN ,;
                           SC6->C6_PRCVEN ,;
                           SC6->C6_TES    ,;
                           SC6->C6_XOBS   ,;
                           SC5->C5_CLIENTE,;
                           SC5->C5_LOJACLI,;
                           SC5->C5_TIPO   ,;
                           SC5->C5_TIPOCLI,;                           
                           nVlrFItem ;                           
            )

            aAdd(::Itens, oProd)

            nTPesLiq += oProd:Peso_Liquido
            nTPesBru += oProd:Peso_Bruto
            nTPedido += oProd:Total

            oProd:Close()

        SC6->(DBSkip())
    End

    nTPedido += SC5->C5_DESPESA
    
    If SC5->C5_TPFRETE $ "C|R"
        nTPedido += SC5->C5_SEGURO
        nTPedido += SC5->C5_FRETE
        nTPedido += SC5->C5_FRETAUT
    EndIf

    If SC5->C5_ACRSFIN > 0
        nTaxa    := nTPedido * (SC5->C5_ACRSFIN / 100)
        nTPedido -= nTaxa
    EndIf

    ::Numero            := SC5->C5_NUM
    ::Usuario_Codigo    := SC5->C5_XUSRINC
    ::Usuario_Nome      := AllTrim(UsrRetName(SC5->C5_XUSRINC))
    ::Forma_Pagamento   := SC5->C5_XFORMA + " - " + Posicione("SX5", 1, xFilial("SX5") + "24" + SC5->C5_XFORMA, "X5_DESCRI")
    ::Despesas          := Transform(SC5->C5_DESPESA, "@E 999,999,999.99")
    ::Frete_Tipo        := fTipoFrete(SC5->C5_TPFRETE)
    ::Frete_Valor       := SC5->C5_FRETE
    ::Natureza_Operacao := cNatOper
    ::Observacao        := Left(SC5->C5_XOBS, 810)
    ::Peso_Total        := nTPesBru
    ::Peso_Liquido      := nTPesLiq
    ::Total_Pedido      := nTPedido
    ::Valor_Extenso     := Transform(nTPedido, "@E 999,999,999.99")
    ::Vencimentos       := Condicao(nTPedido, ::CondicaoPagamento:Codigo,, IIF(Empty(SD2->D2_EMISSAO),dDataBase,SD2->D2_EMISSAO))
    ::Data_Emissao      := SC5->C5_EMISSAO
    ::Arquivo_Regra     := "condcomerc_ped.txt"

Return(.T.)

*****************************************************
Static Function fPrintParcelas(oClass, nlin, nLinBox)
*****************************************************
	Local nBox		:= 0
	Local nParcela	:= 0
	Local nTamCol	:= 790

	Local nColBxI	:= 0
	Local nColBxF	:= 0
	Local nAltBox	:= 120

	Local nAltura	:= 40

	Local nColPar	:= 010
	Local nColVen	:= 210
	Local nColVal	:= 500
	Local nColFim 	:= nTamCol

	For nBox := 1 to 4

		If nBox > 1
			nColBxI	+= nTamCol
		EndIf

		If nBox != 4
			nColBxF	+= nTamCol
		else
			nColBxF	:= nMgRight
		EndIf

		oClass:Print:Box(nLinBox ,nColBxI ,nLinBox + nAltBox ,nColBxF)	
	Next

	For nParcela := 1 to Len(oClass:Vencimentos)

		// oClass:Print:SayAlign(nlin, nColPar, "Parcela: " + cValToChar(nParcela)                                                          , oFont12, nColVen, nAltura,, 0)
		// oClass:Print:SayAlign(nlin, nColVen, "Vcto: "    + DtoC(oClass:Vencimentos[nParcela,01])                                         , oFont12, nColVal, nAltura,, 0)
		// oClass:Print:SayAlign(nlin, nColVal, "Valor R$ " + Alltrim(Transform(oClass:Vencimentos[nParcela,02],PesqPict("SC6","C6_VALOR"))), oFont12, nColFim, nAltura,, 0)

		nColPar	+= nTamCol
		nColVen	+= nTamCol
		nColVal	+= nTamCol
		nColFim += nTamCol

		If nParcela == 4 .Or.  nParcela == 8
			nlin    += nAltura
			nColPar	:= 010
			nColVen	:= 210
			nColVal	:= 500
			nColFim := nTamCol
		EndIf
	Next

    If Len(oClass:Vencimentos) < 4
        nlin += nAltura - 15
    EndIf
    
    If Len(oClass:Vencimentos) < 8
        nlin += nAltura - 15
    EndIf
Return()

*********************************
Static Function fTipoFrete(cTipo)
*********************************

    Local cRet As Character

    Do Case
        Case cTipo = "C"
            cRet := "CIF"
        Case cTipo = "F"
            cRet := "FOB"
        Case cTipo = "T"
            cRet := "Por conta de Terceiros"
        Case cTipo = "R"
            cRet := "Por conta do Remetente"
        Case cTipo = "D"
            cRet := "Por conta do Destinatário"
        Case cTipo = "S"
            cRet := "Sem Frete"
        Otherwise
            cRet := "Não informado"
    EndCase

Return(cRet)

*****************************************************************
Static Function fEnviaMail(cMailDest, cNomeArq, cAssunto, cCopia)
*****************************************************************

    Local   nSendPort   := SuperGetMV("MT_MAILPOR", .F., 587)  // PORTA SMTP
    Local   cSendSrv	:= SuperGetMV("MT_MAILSRV", .F., "" )  // ENDERECO SMTP
    Local   cUser	    := SuperGetMV("MT_MAILCNT", .F., "" )  // USUARIO PARA AUTENTICACAO SMTP
    Local   cPass	    := SuperGetMV("MT_MAILPSW", .F., "" )  // SENHA PARA AUTENTICA SMTP
    Local   lAutentica  := SuperGetMV("MT_MAILAUT", .F., .T.)  // VERIFICAR A NECESSIDADE DE AUTENTICACAO
    Local   nTimeout	:= SuperGetMV("MT_MAILTIM", .F., 120)  // TIMEOUT PARA A CONEXAO
    Local   lSSL		:= SuperGetMV("MT_MAILSSL", .F., .T.)  // VERIFICA O USO DE SSL
    Local   lTLS		:= SuperGetMV("MT_MAILTLS", .F., .T.)  // VERIFICA O USO DE TLS
    Local   cPastaRel   := AllTrim(SuperGetMV("MT_DIRREL", .F., "\imp_rel\"))
    Local   cMsg 	    := ""
    Local   cTitulo     := cAssunto
    Local   nError	    := 0
    Local   oMailServer := Nil

    Default cMailDest   := ""
    Default cNomeArq    := ""
    Default cAssunto    := ""
    Default cCopia      := ""

    IF At(':',cSendSrv) != 0
        nSendPort := Val(Substr(cSendSrv, At(':', cSendSrv) + 1))
        cSendSrv	:= Substr(cSendSrv, 1 , At(':', cSendSrv) - 1)
    EndIf

    oMailServer := TMailManager():New()

    If Empty(cMailDest)
        //Conout("Nao ha destinatarios cadastrado para este processo (" + cProc + ")")
        FWAlertWarning("Nao ha destinatarios cadastrado para este processo","INFO")
        Return()
    EndIf

    //Monta o corpo do e-mail
    cMsg += "<html>"
    cMsg += "<head>"
    cMsg += "<style>"
    cMsg += "table, th, td {"
    cMsg += "border: 1px solid black;"
    cMsg += "border-collapse: collapse;"
    cMsg += "font-family:arial;"
    cMsg += "}"
    cMsg += "th, td {"
    cMsg += "padding: 15px;"
    cMsg += "font-family:arial;"
    cMsg += "}"
    cMsg += "#t01 {"
    cMsg += "padding: 15px;"
    cMsg += "background-color: #C0C0C0;"
    cMsg += "font-family:arial;"
    cMsg += "}"
    cMsg += "</style>"
    cMsg += "</head>"
    cMsg += "<body>"
    
    If "ORC" $ cNomeArq
            cMsg += "<h1 style='font-family:arial;'>Confirmaã§ã£o de Orã§amento</h1>"
    Else
            cMsg += "<h1 style='font-family:arial;'>Confirmaã§ã£o de Pedido</h1>"
    EndIf

    cMsg += "<p style='font-family:arial;'>Gerado automaticamente pelo sistema Microsiga Protheus 12.</p>"
    cMsg += "<p style='font-family:arial;'>Em caso de resposta, favor responder usando a opã§ã£o 'Responder a todos', senã£o os vendedores nã£o receberã£o a resposta.</p>"
    cMsg += "</body>"   
    cMsg += "</html>"

    //Cria o objeto da mensagem
    oMessage := TMailMessage():New()
    oMessage:Clear()
    oMessage:cFrom    := cUser      //Remetente
    oMessage:cTo      := cMailDest  //Destinatarios
    oMessage:cSubject := cTitulo    //Assunto
    oMessage:cBody    := cMsg       //Corpo do email
    oMessage:cCC      := cCopia     //Copias
    oMessage:AttachFile(cPastaRel + cNomeArq)

   //Habilita o SSL se configurado
   If lSSL
      oMailServer:SetUseSSL(lSSL)
   EndIf

   //Habilita o TLS se configurado
   If lTLS
      oMailServer:SetUseTLS(lTLS)
   EndIf

   // Inicializacao do objeto de Email
   nError := oMailServer:Init("", cSendSrv, cUser, cPass, , nSendPort)
   If nError != 0
      //Conout("Falha ao Iniciazar SMTP server: " + oMailServer:GetErrorString(nError))
      FWAlertWarning("Falha ao Iniciazar SMTP server: " + oMailServer:GetErrorString(nError),"INFO")
      Return()
   EndIf

   // Define o Timeout SMTP
   nError := oMailServer:SetSMTPTimeout(nTimeout)
   If nError != 0
      //Conout("Nã£o foi possível definir tempo limite para " + cValToChar(nTimeout))
      FWAlertWarning("Não foi possível definir tempo limite para " + cValToChar(nTimeout),"INFO")
      Return()
   EndIf

   // Conecta ao servidor
   nError := oMailServer:SMTPConnect()
   If nError != 0
      //Conout("Nã£o foi possível conectar no servidor SMTP: " + oMailServer:GetErrorString(nError))
      FWAlertWarning("Não foi possível conectar no servidor SMTP: " + oMailServer:GetErrorString(nError),"INFO")
      Return()
   EndIf

   // authenticate on the SMTP server (if needed)
   If lAutentica
      nError := oMailServer:SmtpAuth(cUser, cPass)
      If nError != 0
         //Conout("Nã£o foi possível autenticar no servidor SMTP: " + oMailServer:GetErrorString(nError))
         FWAlertWarning("Não foi possível autenticar no servidor SMTP: " + oMailServer:GetErrorString(nError),"INFO")
         Return()
      EndIf
   EndIf

   nError := oMessage:Send(oMailServer)
   If nError != 0
      //Conout("Erro ao enviar o e-mail (" +  oMailServer:GetErrorString(nError) + ")")
      FWAlertWarning("Erro ao enviar o e-mail (" +  oMailServer:GetErrorString(nError) + ")","INFO")
      Return()
   EndIf  

   oMailServer:SmtpDisconnect()
   
Return()

Method CondComerc(cCondComerc) Class PrintPedido

    Local aAux      As Array
    Local aRet      As Array
    Local nAtu      As Numeric
    Local nMaxCol 	As Numeric
	aAux      	:= {}
    aRet        := {}
    nAtu      	:= 0
    nMaxCol 	:= 600

	//Quebrando o Array, conforme -Enter-
    aAux := StrTokArr(cCondComerc,Chr(13))
     
    //Correndo o Array e retirando o tabulamento
    For nAtu:=1 To Len(aAux)
        aAux[nAtu] := AllTrim(StrTran(aAux[nAtu],Chr(10),''))
    Next
     
    //Correndo as linhas quebradas
    For nAtu:=1 To Len(aAux)
     
        //Se o tamanho de Texto, for maior que o nãºmero de colunas
        If (Len(aAux[nAtu]) > nMaxCol)
         
            //Enquanto o Tamanho for Maior
            While (Len(aAux[nAtu]) > nMaxCol)                                 
                				
                nUltPos:=Rat(' ',SubStr(aAux[nAtu],1,nMaxCol))
                 
                //Se nã£o encontrar espaã§o em branco, a ãºltima posiã§ã£o serã¡ a coluna mã¡xima
                If(nUltPos==0)
                    nUltPos:=nMaxCol
                EndIf
                 
                //Adicionando Parte da Sring (de 1 atã© a ãšlima posiã§ã£o vã¡lida)
                AAdd(aRet, SubStr(aAux[nAtu],1,nUltPos))
                 
                //Quebrando o resto da Character
                aAux[nAtu] := SubStr(aAux[nAtu], nUltPos+1, Len(aAux[nAtu]))
            EndDo
             
            //Adicionando o que sobrou
            AAdd(aRet, aAux[nAtu])
        Else
            //Se for menor que o Mã¡ximo de colunas, adiciona o texto
            AAdd(aRet, aAux[nAtu])
        EndIf
    Next

	ASize(aAux,0)

Return(aRet)

*******************************
Static Function fPictRGB(R,G,B)
*******************************

	Local nRGB := B * 65536 + G * 256 + R	

Return(nRGB)

******************************************************************
Static Function fVerBrush(oPrint, nlin, nAltura, nMgRight, lBrush)
******************************************************************

	If lBrush
		oPrint:FillRect( {nlin - 10, 0000, nlin + nAltura - 10, nMgRight }, TBrush():New( , fPictRGB(204,204,204)) )
	EndIf
	lBrush := !lBrush

Return(lBrush)
