#include "TOTVS.ch"


/*/{Protheus.doc} User Function MA651GRV
    Responsável por atualizar os arquivos envolvidos na Ordem de Producao.

    @type  Function
    @author Tiago Cunha
    @since 07/07/2025
    @version 1.0
    @param 1.00
    @see https://tdn.totvs.com/pages/releaseview.action?pageId=6087650
/*/
User Function MA651GRV()
	Local aArea := FWGetArea()
	// Busca o valor do parâmetro MV_LOTKLY (primeiro lote a ser utilizado)
	Local cPrimeiroLote := GetMV("MV_LOTKLY")
	Local cUltimoLote   := GetMV("MV_LOTKLY2")

	if Empty(cPrimeiroLote)
		cPrimeiroLote := Soma1(PadL(cPrimeiroLote, GetSx3Cache("H6_LOTECTL","X3_TAMANHO"), "0"))
		cUltimoLote   := cPrimeiroLote
	else
		cUltimoLote   := Soma1(PadL(cUltimoLote, GetSx3Cache("H6_LOTECTL","X3_TAMANHO"), "0"))
	endif

	RecLock("SC2", .F.)
	SC2->C2_XLOTE  := cUltimoLote
	SC2->C2_XDTVLD := date() + SB1->B1_PRVALID
	SC2->(MsUnlock())

	// Atualiza os parâmetros MV_LOTKLY e MV_LOTKLY2
	putMV("MV_LOTKLY", cPrimeiroLote)
	putMV("MV_LOTKLY2", cUltimoLote)


	// INICIO REGRA ---------------------------
	// SEPARAÇÃO - Criação automática da requisição de separação.
	// Neste ponto as validações principais já foram feitas pelo PE M651Dpc.
	//-----------------------------------------
	// Criação dos registros da requisição para separação.
	cNumReq := getSXENum( "ZS1", "ZS1_NUMREQ")

	// Gravação do cabeçalho da requisição
	RecLock("ZS1", .T.)
	ZS1->ZS1_FILIAL := FWxFilial('ZS1')
	ZS1->ZS1_NUMREQ := cNumReq
	ZS1->ZS1_EMISSA := dDatabase
	ZS1->ZS1_REQPRI := "2" // Não priorizado
	ZS1->ZS1_OP     := SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN
	ZS1->ZS1_DTEMOP := SC2->C2_EMISSAO
	ZS1->ZS1_CODPRO := SB1->B1_COD
	ZS1->ZS1_DESCPR := SB1->B1_DESC
	ZS1->ZS1_STATUS := "1" // Separar e pesar
	ZS1->ZS1_TIPO   := "1" // Padrão
	ZS1->ZS1_RECSC2 := SC2->(Recno())
	ZS1->(MsUnlock())

	// Gravação dos itens da requisição
	// Se posiciona na SD4
	SD4->(dbSetOrder(2))
	if SD4->(dbSeek(FwxFilial("SD4")+ SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN))
		nCount := 0
		While SD4->(!EOF()) .And. AllTrim(SD4->D4_OP) == AllTrim(SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN)
			nCount += 1
			RecLock("ZS2", .T.)
			ZS2->ZS2_FILIAL := FWxFilial('ZS2')
			ZS2->ZS2_NUMREQ := cNumReq
			ZS2->ZS2_ITMREQ := StrZero(nCount, TamSX3("ZS2_ITMREQ")[1])
			ZS2->ZS2_STATUS := "1" // Não Iniciado
			ZS2->ZS2_TRT    := SD4->D4_TRT
			ZS2->ZS2_CODEMP := SD4->D4_COD
			ZS2->ZS2_DSCEMP := ALLTRIM(POSICIONE("SB1",1,XFILIAL("SB1")+SD4->D4_COD,"B1_DESC"))
			ZS2->ZS2_OP     := SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN
			ZS2->ZS2_DTEMP  := SD4->D4_DATA
			ZS2->ZS2_QTDORI := SD4->D4_QTDEORI
			ZS2->ZS2_SLDREQ := SD4->D4_QTDEORI
			ZS2->ZS2_QTDSEP := 0
			ZS2->ZS2_LOCAL  := ALLTRIM(POSICIONE("SB1",1,XFILIAL("SB1")+SD4->D4_COD,"B1_LOCPAD"))

			// Pega lote com saldo disponivel
			
			ZS2->ZS2_LOTECT := SD4->D4_LOTECTL
			ZS2->ZS2_RECSD4 := SD4->(Recno())
			ZS2->(MsUnlock())

			SD4->(dbSkip())
		End
	endif

	ConfirmSX8()
	// FIM REGRA ------------------------------
	// SEPARAÇÃO
	//-----------------------------------------

	FWRestArea(aArea)

Return


/*/{Protheus.doc} User Function M651Dpc
    Validação para Firmar OPs Previstas

    @type  Function
    @author Tiago Cunha
    @since 07/07/2025
    @version 1.0
    @param 1.00
    @see https://tdn.totvs.com/pages/releaseview.action?pageId=6089358
/*/
User Function M651Dpc()
	Local aArea := FWGetArea()
	Local lRet  := .T.

	// INICIO REGRA ---------------------------
	// SEPARAÇÃO
	// Validação 1 - Verifica se a OP possui empenhos gerados, caso não possui da mensagem de aviso na tela e não permite firmar a OP.
	// Validação 2 - Verifica se a op possui todos os empenhos com apropriação indireta
	// OP marcada sim ou não: Função IsMark('C2_OK', cMarca)
	//-----------------------------------------
	SD4->(dbSetOrder(2))
	if !(SD4->(dbSeek(FwxFilial("SD4")+ SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN)))
		lRet := .F.
		FWAlertWarning("Não existe empenhos para esta OP, gere os empenhos antes de firmar a OP.", "Aviso")
	else
		lTodosInd := .T.
		SB1->(dbSetOrder(1))
		While SD4->(!EOF()) .And. AllTrim(SD4->D4_OP) == AllTrim(SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN) .And. lTodosInd

			// Verificando se o produto do empenho é de apropriação indireta
			if SB1->(dbSeek(FwxFilial("SB1")+SD4->D4_COD))
				if SB1->B1_APROPRI <> "I"
					lTodosInd := .F.
				endif
			endif

			SD4->(dbSkip())
		End

		if !lTodosInd
			lRet := .F.
			FWAlertWarning("Itens que não sejam de apropriação indireta não podem passar pelo processo de requisição automática", "Aviso")
		endif
	endif
	// FIM REGRA ------------------------------
	// SEPARAÇÃO
	//-----------------------------------------

	FWRestArea(aArea)
Return lRet
