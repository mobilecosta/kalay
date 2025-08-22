#include "protheus.ch"

/*/{Protheus.doc} PrintPedido
Classe dados do Item
@type class
@version 1.00
@author Luiz Alves Felizardo
@since 11/08/2022
/*/
**************************************
Class PrintPed_Item From LongNameClass
	**************************************

	Data Item               As Character
	Data Codigo             As Character
	Data Descricao          As Character
	Data Unidade_Medida     As Character
	Data Quantidade         As Numeric
	Data Valor_Frete        As Numeric
	Data Valor_Unitario     As Numeric
	Data Valor_Unitario_Liq As Numeric
	Data Valor_Com_IPI      As Numeric
	Data NCM                As Character
	Data TES                As Character
	Data ICMS_Aliquota      As Numeric
	Data ICMS_Valor         As Numeric
	Data IPI_Aliquota       As Numeric
	Data IPI_Valor          As Numeric
	Data XIPI               As Character
	Data ST_Valor           As Numeric
	Data Total              As Numeric
	Data Observacao         As Character
	Data XObservacao         As Character
	Data Moeda              As Character
	Data Comprimento        As Numeric
	Data Largura            As Numeric
	Data Espessura          As Numeric
	Data Peso_Bruto         As Numeric
	Data Peso_Liquido       As Numeric
	Data Detalhes           As Character
	Data Imagem             As Character
	Data Marca              As Character

	Method New() Constructor
	Method Close()
	Method LerDados(cItem, cCod, cUM, nQuant, nValor, cTES, cObs, cCliCod, cCliLoj, cTipo, cCliTipo, nVlrFrete)

EndClass

********************************
Method New() Class PrintPed_Item
	********************************

	::Item           := ""
	::Codigo         := ""
	::Descricao      := ""
	::Unidade_Medida := ""
	::Quantidade     := 0
	::Valor_Frete    := 0
	::Valor_Unitario := 0
	::Valor_Com_IPI  := 0
	::NCM            := ""
	::TES            := ""
	::ICMS_Aliquota  := 0
	::ICMS_Valor     := 0
	::IPI_Aliquota   := 0
	::IPI_Valor      := 0
	::XIPI           := ""
	::ST_Valor       := 0
	::Total          := 0
	::Observacao     := ""
	::XObservacao    := ""
	::Moeda          := ""
	::Comprimento    := 0
	::Largura        := 0
	::Espessura      := 0
	::Peso_Bruto     := 0
	::Peso_Liquido   := 0
	::Valor_Unitario_Liq := 0
	::Detalhes       := ""
	::Imagem         := ""
	::Marca          := ""

Return()

	**********************************
Method Close() Class PrintPed_Item
	**********************************
Return()

	********************************************************************************************************************
Method LerDados(cItem, cCod, cUM, nQuant, nValor, cTES, cObs, cCliCod, cCliLoj, cTipo, cCliTipo, nVlrFrete) Class PrintPed_Item
	********************************************************************************************************************

	::Item           := ""
	::Codigo         := ""
	::Descricao      := ""
	::Unidade_Medida := ""
	::Quantidade     := 0
	::Valor_Frete    := 0
	::Valor_Unitario := 0
	::Valor_Com_IPI  := 0
	::NCM            := ""
	::TES            := ""
	::ICMS_Aliquota  := 0
	::ICMS_Valor     := 0
	::IPI_Aliquota   := 0
	::IPI_Valor      := 0
	::ST_Valor       := 0
	::Total          := 0
	::Observacao     := ""
	::Comprimento    := 0
	::Largura        := 0
	::Espessura      := 0
	::Peso_Bruto     := 0
	::Peso_Liquido   := 0
	::Valor_Unitario_Liq := 0
	::Detalhes       := ""
	::Imagem         := ""
	::Marca          := ""

	DBSelectArea("SB1")
	DBSelectArea("SB5")

	SB1->(DBSetOrder(1))
	SB5->(DBSetOrder(1))

	SB1->(DBGoTop())
	SB5->(DBGoTop())

	If SB1->(!DBSeek(xFilial("SB1") + cCod))
		Return(.F.)
	EndIf

	cDesc               := ""
	cPIP                := ""
	cMoeda              := ""
	if ISINCALLSTACK("MATA415")
		cPIP  := AcaX3Combo("CK_XIPI", SCK->CK_XIPI)
		cDesc := SCK->CK_DESCRI
		
		cIdMoeda := SCK->CK_XMOEDA
		if Empty(cIdMoeda)
			cIdMoeda := "1"
		endif

		cMoeda := &("getMV('MV_MOEDA" + AllTrim(cIdMoeda) + "')")
	elseif ISINCALLSTACK("MATA410")
		cPIP  := AcaX3Combo("C6_XIPI", SC6->C6_XIPI)
		cDesc := SC6->C6_DESCRI

		cIdMoeda := SC6->C6_XMOEDA
		if Empty(cIdMoeda)
			cIdMoeda := "1"
		endif

		cMoeda := &("getMV('MV_MOEDA" + AllTrim(cIdMoeda) + "')")
	endif

	::Item               := cItem
	::Codigo             := ALLTRIM(SB1->B1_COD)
	::Descricao          := cDesc
	::XIPI               := cPIP
	::Unidade_Medida     := cUM
	::Quantidade         := nQuant
	::Valor_Frete        := nVlrFrete
	::Valor_Unitario     := nValor
	::Moeda              := cMoeda
	::Valor_Unitario_Liq := nValor
	::NCM                := SB1->B1_POSIPI
	::TES                := cTES
	::Marca              := SB1->B1_FABRIC

	If !Empty(cTES)
		SF4->(DBSetOrder(1))
		SF4->(DBSeek(xFilial("SF4") + cTES))

		MaFisIni(cCLiCod                           ,; // 01-Codigo Cliente/Fornecedor
		cCliLoj                           ,; // 02-Loja do Cliente/Fornecedor
		If(cTipo $ 'DB', "F", "C")        ,; // 03-C:Cliente , F:Fornecedor
			cTipo                             ,; // 04-Tipo da NF
			cCliTipo                          ,; // 05-Tipo do Cliente/Fornecedor
			MaFisRelImp("MT100",{"SF2","SD2"}),; // 06-Relacao de Impostos que suportados no arquivo
			,; // 07-Tipo de complemento
			,; // 08-Permite Incluir Impostos no Rodape .T./.F.
			"SB1"                             ,; // 09-Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
			"MATA461"                          ; // 10-Nome da rotina que esta utilizando a funcao
			)

			MaFisAdd(SB1->B1_COD              ,; // 1-Codigo do Produto                 ( Obrigatorio )
			cTES                     ,; // 2-Codigo do TES                     ( Opcional )
			nQuant                   ,; // 3-Quantidade                     ( Obrigatorio )
			nValor                   ,; // 4-Preco Unitario                 ( Obrigatorio )
			0                        ,; // 5 desconto
			""                       ,; // 6-Numero da NF Original             ( Devolucao/Benef )
			""                       ,; // 7-Serie da NF Original             ( Devolucao/Benef )
			,; // 8-RecNo da NF Original no arq SD1/SD2
			nVlrFrete                ,; // 9-Valor do Frete do Item         ( Opcional )
			0                        ,; // 10-Valor da Despesa do item         ( Opcional )
			0                        ,; // 11-Valor do Seguro do item         ( Opcional )
			0                        ,; // 12-Valor do Frete Autonomo         ( Opcional )
			(nQuant * nValor)        ,; // 13-Valor da Mercadoria             ( Obrigatorio )
			0                        ,; // 14-Valor da Embalagem             ( Opcional )
			0                        ,; // 15-RecNo do SB1
			0                         ; // 16-RecNo do SF4
			)

			MaFisTes(cTES, SF4->(RecNo()), 1) // Carrega a TES para a MATXFIS
			MaFisRecal("", 1)                 // Dispara o calculo do item

			::ICMS_Valor         := MaFisRet(, "NF_VALICM" )
			::IPI_Valor          := MaFisRet(, "NF_VALIPI" )
			::ST_Valor           := MaFisRet(, "NF_VALSOL" )
			::Valor_Unitario     := ( ::IPI_Valor + ::ST_Valor ) / nQuant + nValor
			MaFisEnd()
		EndIf

		::Valor_Com_IPI  := nValor + ::IPI_Valor
		::Total          := Round( ::IPI_Valor + ::ST_Valor + ( nValor * nQuant ), 2)
		::XObservacao     := cObs

		::Peso_Liquido   := Round(SB1->B1_PESO    * nQuant, TamSX3("B1_PESO"  )[1])
		::Peso_Bruto     := Round(SB1->B1_PESBRU  * nQuant, TamSX3("B1_PESBRU")[1])
		::Detalhes       := SB1->B1_XDETALH

		If SB5->(DBSeek(xFilial("SB5") + cCod))
			::Largura     := SB5->B5_LARG
			::Espessura   := SB5->B5_ESPESS
			::Comprimento := SB5->B5_COMPR
		EndIf

		::Imagem := AllTrim(SB1->B1_BITMAP)
		Return(.T.)

Static Function AcaX3Combo(cCampo,cConteudo)
	Local aSx3Box   := RetSx3Box( Posicione("SX3", 2, cCampo, "X3CBox()" ),,, 1 )
	If cConteudo == ""
		cConteudo := " "
	EndIf
REturn Upper(AllTrim( aSx3Box[Ascan( aSx3Box, { |aBox| aBox[2] = cConteudo } )][3] ))
