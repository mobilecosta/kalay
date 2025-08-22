#include 'Totvs.ch'
#INCLUDE 'FWMVCDEF.CH'

//-------------------------------------------------
/*/{Protheus.doc} MT490MNU
Ponto de Entrada para criação de opções na rotina MATA490

@type function
@version 1.0
@author Wagner Mobile Costa

@since 02/09/2021

@return Array, Array com as Rotinas
/*/
//-------------------------------------------------
USER FUNCTION MT490MNU()
    
    ADD OPTION aRotina TITLE "Atualizar Data Pagto" 	        ACTION "U_AFAT08DT()" 		OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE "Rel Comissão Motorista" 	        ACTION "U_xMatr540()" 		OPERATION 3 ACCESS 0

Return
