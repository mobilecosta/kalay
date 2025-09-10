#include "TOTVS.ch"


/*/{Protheus.doc} MT381LOK
  Ponto de Entrada, localizado na validação da linha no Ajuste Empenho Mod. 2, utilizado para confirmar inclusão na linha do produto no Ajuste Empenho Modelo 2.
  
  @type User Function
  @author Tiago Cunha
  @since 20/08/2025
  @version 1.0
  @see https://tdn.totvs.com/display/public/PROT/MT381LOK
/*/
User function MT381LOK()
	// Local ExpL1 := PARAMIXB[1]
	Local ExpL2 := PARAMIXB[2] // Se é alteração
	Local lRet  := .T.

	nPosRecno   := aScan(aHeader,{|aX| AllTrim(aX[2]) == "D4_REC_WT"})

	// INICIO REGRA ---------------------------
	// SEPARAÇÃO - Verifica se o empenho posicionado está vinculado a uma requisição de separação e se pode realizar a alteração.
  //-----------------------------------------
	if ExpL2

		if aCols[n, nPosRecno] > 0

			lRet := SepVldAlte(aCols, n, nPosRecno)

		endif
	endif
	// FIM REGRA ------------------------------
	// SEPARAÇÃO
	//-----------------------------------------

Return lRet


/*/{Protheus.doc} SepVldAlte
    Valida se pode alterar o empenho vinculado a requisição de separação
    
    @type Static Function
    @author Tiago Cunha
    @since 17/08/2025
    @version 1.0.0
/*/
Static Function SepVldAlte(aCols, n, nPosRecno)
	Local lRet := .T.

	SD4->(dbGoTo(aCols[n, nPosRecno]))

	ZS1->(dbSetOrder(2))
	if ZS1->(dbSeek(FWxFilial("ZS1") + SD4->D4_OP))

		if ZS1->ZS1_STATUS == "2" // – Permitir alteração apenas dos itens cujo ZS2_STATUS = “1”
			ZS2->(dbSetOrder(3)) // Filial + recnoSd4

			if ZS2->(dbSeek( FWxFilial("ZS2") + cValToChar(aCols[n, nPosRecno]) ))
				if ZS2->ZS2_STATUS <> "1"
					FWAlertWarning("O empenho posicionado não pode ser alterado", "Aviso")
					lRet := .F.
				endif
			endIf

		elseif ZS1->ZS1_STATUS == "3" .Or. ZS1->ZS1_STATUS == "4"
			FWAlertWarning("Requisição para produção já separada, não é permitido alterar os empenhos", "Aviso")
			lRet := .F.
		endif

	endif

Return lRet


/*/{Protheus.doc} MTA381GRV
    (O Ponto de entrada MTA381GRV é utilizado para realizar operações complementares após a inclusão, alteração e exclusão de um item de ajuste de empenho mod II
    
    @type User Function
    @author Tiago Cunha
    @since 17/08/2025
    @version 1.0.0
    @see https://tdn.totvs.com/display/PROT/MTA381GRV+-+Ajuste+de+Empenho
/*/
User Function MTA381GRV()
	Local aArea      := FWGetArea()
	// Local ExpL1   := PARAMIXB[1] // Incluir
	// Local ExpL2   := PARAMIXB[2] // Excluir
	Local ExpL3   := PARAMIXB[3] // Alterar
	Local nX      := 1

	nPosCod    := aScan(aHeader,{|aX| AllTrim(aX[2]) == "D4_COD"})
	nPosTRT    := aScan(aHeader,{|aX| AllTrim(aX[2]) == "D4_TRT"})
	nPosLocal  := aScan(aHeader,{|aX| AllTrim(aX[2]) == "D4_LOCAL"})
	nPosQuant  := aScan(aHeader,{|aX| AllTrim(aX[2]) == "D4_QUANT"})
	nPosQtdOri := aScan(aHeader,{|aX| AllTrim(aX[2]) == "D4_QTDEORI"})
	nPosSegUM  := aScan(aHeader,{|aX| AllTrim(aX[2]) == "D4_QTSEGUM"})
	nPosLotCtl := aScan(aHeader,{|aX| AllTrim(aX[2]) == "D4_LOTECTL"})
	nPosLote   := aScan(aHeader,{|aX| AllTrim(aX[2]) == "D4_NUMLOTE"})
	nPosDValid := aScan(aHeader,{|aX| AllTrim(aX[2]) == "D4_DTVALID"})
	nPosPotenc := aScan(aHeader,{|aX| AllTrim(aX[2]) == "D4_POTENCI"})
	nPosData   := aScan(aHeader,{|aX| AllTrim(aX[2]) == "D4_DATA"})
	nPosOPorig := aScan(aHeader,{|aX| AllTrim(aX[2]) == "D4_OPORIG"})
	nPosRecno  := aScan(aHeader,{|aX| AllTrim(aX[2]) == "D4_REC_WT"})
	nPosPrdOri := aScan(aHeader,{|aX| AllTrim(aX[2]) == "D4_PRDORG"})

	// Se for alteração irá realizar a atualização da ZS2 com os dados atualizados do empenho
	if ExpL3
		for nX := 1 to len(aCols)

			// Verifica se o empenho existe
			if aCols[nX, nPosRecno] > 0

				SD4->(dbGoTo(aCols[nX, nPosRecno]))

				ZS2->(dbSetOrder(3)) // Filial + recnoSd4
				if ZS2->(dbSeek( FWxFilial("ZS2") + cValToChar(aCols[nX, nPosRecno]) ))
					RecLock("ZS2", .F.)
					ZS2->ZS2_DTEMP  := aCols[nX, nPosData]
					ZS2->ZS2_QTDORI := aCols[nX, nPosQtdOri]
					ZS2->ZS2_SLDREQ := aCols[nX, nPosQtdOri]
					ZS2->ZS2_LOCAL  := aCols[nX, nPosLocal]
					ZS2->ZS2_LOTECT := aCols[nX, nPosLotCtl]
					ZS2->(MsUnlock())
				endIF
			else
				// Se não existir deve conferir se existe ZS1 se existir deve incluir o novo item na ZS2 ?
				loop
			endif

		next
	endif

	FWRestArea(aArea)
Return
