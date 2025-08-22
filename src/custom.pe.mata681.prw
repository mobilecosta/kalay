#include "TOTVS.ch"


/*/{Protheus.doc} User Function MT681INC
	Function A681Inclui() - Programa de inclus�o do movimento de estoque.
	� executado ap�s a grava��o dos dados na rotina de inclus�o do apontamento de produ��o PCP Mod2.

	@type Function
	@author Tiago Cunha
	@since 07/07/2025
	@version 1.0
	@param Nil
	@return Nil
	@see https://tdn.engpro.totvs.com.br/pages/releaseview.action?pageId=330838259
/*/
User Function MT681INC()

	if !ISINCALLSTACK("RESTCALLWS") // N�o vindo do REST
		If MsgYesNo("Deseja imprimir a etiqueta de produ��o deste apontamento?", "Etiqueta de Produ��o")
			u_xpcp001a()
		EndIf
	endif

	DBSelectArea("QPK")
	QPK->(DbSetOrder(1)) // QPK_FILIAL+QPK_OP+QPK_LOTE+QPK_NUMSER+QPK_PRODUT+QPK_REVI
	if QPK->(dbSeek(xFilial("QPK")+SH6->H6_OP))
		While QPK->(!EOF()) .And. QPK->QPK_OP == SH6->H6_OP .And. QPK->QPK_PRODUT == SH6->H6_PRODUTO
			if Empty(QPK->QPK_LOTE)
				// Atualiza o campo QPK_LOTE com o lote gerado (H6_LOTECTL)
				RecLock("QPK", .F.)
				QPK->QPK_LOTE := SH6->H6_LOTECTL
				QPK->(MsUnlock())
			endif

			QPK->(dbSkip())
		EndDo
	endif

Return
