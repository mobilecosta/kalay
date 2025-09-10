#include "TOTVS.ch"


/*/{Protheus.doc} MT381LOK
  Function A380TudoOK() - Responsável por avaliar se o empenho pode ser efetuado.
  
  @type User Function
  @author Tiago Cunha
  @since 20/08/2025
  @version 1.0
  @see https://tdn.totvs.com/pages/releaseview.action?pageId=6087777
/*/
User function MT380INC()
	Local lRet := .T.

	// INICIO REGRA ---------------------------
	// SEPARAÇÃO - Verifica se o empenho posicionado está vinculado a uma requisição de separação e se pode realizar a alteração.
	//-----------------------------------------
	if ALTERA
		dbSelectArea("ZS1")
		dbSelectArea("ZS2")

		SD4->(dbGoTo(M->(Recno())))

		ZS1->(dbSetOrder(2))
		if ZS1->(dbSeek(FWxFilial("ZS1") + M->D4_OP))

			if ZS1->ZS1_STATUS == "2" // – Permitir alteração apenas dos itens cujo ZS2_STATUS = “1”
				ZS2->(dbSetOrder(3)) // Filial + recnoSd4

				if ZS2->(dbSeek( FWxFilial("ZS2") + cValToChar(M->(Recno())) ))
					if ZS2_STATUS <> "1"
						FWAlertWarning("O empenho posicionado não pode ser alterado", "Aviso")
						lRet := .F.
					endif
				endIf

			elseif ZS1->ZS1_STATUS == "3" .Or. ZS1->ZS1_STATUS == "4"
				FWAlertWarning("Requisição para produção já separada, não é permitido alterar os empenhos", "Aviso")
				lRet := .F.
			endif

		endif
	endif
	// FIM REGRA ------------------------------
	// SEPARAÇÃO
	//-----------------------------------------

Return lRet


/*/{Protheus.doc} MT380ALT
  LOCALIZAÇÃO : Function A380Altera() - Responsável pela alteração de requisições empenhadas.
  EM QUE PONTO : Após a gravação de uma alteração de empenho. O Ponto de Entrada MT380ALT e utilizado para realizar operações complementares.
  
  @type User Function
  @author Tiago Cunha
  @since 20/08/2025
  @version 1.0
  @see https://tdn.totvs.com/pages/releaseview.action?pageId=6087774
/*/
User function MT380ALT()

	dbSelectArea("ZS1")
	dbSelectArea("ZS2")

	// INICIO REGRA ---------------------------
	// SEPARAÇÃO - Atualiza os dados na ZS2 quando o empenho for alterado.
	//-----------------------------------------
	ZS2->(dbSetOrder(3)) // Filial + recnoSd4
	if ZS2->(dbSeek( FWxFilial("ZS2") + cValToChar(SD4->(Recno()))) ) // Verifica se existe o registro na ZS2
		RecLock("ZS2", .F.)
		ZS2->ZS2_DTEMP  := SD4->D4_DATA
		ZS2->ZS2_QTDORI := SD4->D4_QTDEORI
		ZS2->ZS2_SLDREQ := SD4->D4_QTDEORI
		ZS2->ZS2_LOCAL  := SD4->D4_LOCAL
		ZS2->ZS2_LOTECT := SD4->D4_LOTECTL
		ZS2->(MsUnlock())
	endIF
	// FIM REGRA ------------------------------
	// SEPARAÇÃO
	//-----------------------------------------
Return
