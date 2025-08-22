#include 'Totvs.ch'

//-------------------------------------------------
/*/{Protheus.doc} M410STTS
Ponto de Entrada na manutenção do pedido de venda para realização de operações complementares
Inclusão/Alteração/Exclusão (ParamIXB 3, 4 ou 5)

@type function
@version 1.0
@author Wagner Mobile Costa

@since 02/09/2021

@return Array, Array com as Rotinas
/*/
//-------------------------------------------------
USER FUNCTION M410STTS()
    
Local aArea := GetArea()	

	If ParamIXB[1] == 5 // Exclusão
		DbSelectArea("Z05")
		DbSetOrder(2)	// Z05_FILIAL + Z05_FILSC5 + Z05_NUMSC5
		If DbSeek(xFilial() + SC5->C5_FILIAL + SC5->C5_NUM)
			RecLock("Z05", .F.)
			Z05->Z05_STATUS := "1"
			Z05->Z05_FILSC5 := ""
			Z05->Z05_NUMSC5 := ""
			MsUnLock()
		EndIf
	EndIf


RestArea(aArea)

Return
