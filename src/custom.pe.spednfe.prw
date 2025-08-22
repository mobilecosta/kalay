#include "TOTVS.ch"

/*/{Protheus.doc} User Function FISTRFNFE
  Este ponto de entrada tem por finalidade incluir novos botões na rotina SPEDNFE().

	@type  Function
	@author Tiago Cunha
	@since 09/07/2025
	@version 1.0
	@param Nil
	@return Nil
	@see https://tdn.totvs.com/pages/releaseview.action?pageId=6077029
/*/
User Function FISTRFNFE()

	AAdd(aRotina, { "Ajusta Volumes", "U_EXPA001", 0, 3, 0 , Nil} )
	AAdd(aRotina, {"Imp. Etiq. Exp.", "U_xfat001a", 0, 2, 0, NIL})

Return
