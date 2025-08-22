#include "PROTHEUS.CH"
#include "FWMBROWSE.CH"
#include "FWMVCDEF.CH"

/*/{Protheus.doc} SchedDef
Retorna do Protheus na rotina schedule os parametros do relatorio para agendamento
@type function
@version 1.00
@author Luiz Alves Felizardo
@since 16/08/2022
@return array, parametros para execucao do relatorio
/*/
Static Function SchedDef()

	Local aOrd  := {}
	Local aPar  := {}
	Local cPerg := "RFAT001A"

	aPar := {;
		"R"  ,; //Tipo R para relatorio e P para processo
	cPerg,; //Pergunte do relatorio ou processo
	"SCJ",; //Alias
	aOrd  ; //Array de ordens de impressao do relatorio
	}

Return(aPar)

/*/{Protheus.doc} RFAT001A
Impressao do Orcamento diretamente do Menu
@type function
@version 1.00
@author Luiz Alves Felizardo
@since 17/08/2022
/*/
User Function RFAT001A()

	Private cPerg As Character

	cPerg := "RFAT001A"

	If !Pergunte(cPerg)
		Return()
	EndIf

	Processa({|| fProc()}, "Imprimindo orçamentos...", "Aguarde...")

Return()


Static Function fProc()

	Local   cAliPeds  As Character
	Local   nRegAtu   As Numeric
	Local   nRegTot   As Numeric

	Private oPrintOrc As Object

	nRegAtu   := 0
	nRegTot   := 0
	cQuery    := " SELECT "
	cQuery    += "      SCJ.CJ_FILIAL "
	cQuery    += "    , SCJ.CJ_NUM "
	cQuery    += " FROM "
	cQuery    += "    " + RetSQLName("SCJ") + " SCJ (NOLOCK) "
	// cQuery    += "    INNER JOIN " + RetSQLName("SA3") + " SA3 (NOLOCK) "
	// cQuery    += "    ON  SA3.A3_FILIAL  = '" + xFilial("SA3") + "' "
	// cQuery    += "    AND SA3.A3_COD     = SCJ.CJ_XVEND1 "
	// cQuery    += "    AND SA3.D_E_L_E_T_ = SCJ.D_E_L_E_T_ "
	cQuery    += " WHERE "

	If MV_PAR01 = 2
		cQuery += "     SCJ.CJ_FILIAL = '" + xFilial("SCJ") + "' "
	Else
		cQuery += "     SCJ.CJ_FILIAL BETWEEN '" + MV_PAR02 + "' AND '" + MV_PAR03 + "' "
	EndIf

	cQuery    += "    AND SCJ.CJ_CLIENTE BETWEEN '" + MV_PAR04       + "' AND '" + MV_PAR05       + "' "
	cQuery    += "    AND SCJ.CJ_LOJA    BETWEEN '" + MV_PAR06       + "' AND '" + MV_PAR07       + "' "
	cQuery    += "    AND SCJ.CJ_NUM     BETWEEN '" + MV_PAR08       + "' AND '" + MV_PAR09       + "' "
	cQuery    += "    AND SCJ.CJ_EMISSAO BETWEEN '" + DToS(MV_PAR10) + "' AND '" + DToS(MV_PAR11) + "' "
	cQuery    += "    AND SCJ.CJ_XVEND1  BETWEEN '" + MV_PAR12       + "' AND '" + MV_PAR13       + "' "
	// cQuery    += "    AND SA3.A3_SUPER   BETWEEN '" + MV_PAR14       + "' AND '" + MV_PAR15       + "' "
	// cQuery    += "    AND SA3.A3_GEREN   BETWEEN '" + MV_PAR16       + "' AND '" + MV_PAR17       + "' "
	cQuery    += "    AND SCJ.D_E_L_E_T_ <> '*' "
	cQuery    := ChangeQuery(cQuery)
	cAliPeds  := MPSysOpenQuery(cQuery)
	oPrintOrc := PrintOrcamento():New("ORC")

	(cAliPeds)->(DBGoTop())
	(cAliPeds)->(DBEval({|| nRegTot++}))
	(cAliPeds)->(DBGoTop())

	ProcRegua(nRegTot)

	While (cAliPeds)->(!Eof())

		nRegAtu++

		IncProc("Processando " + CValToChar(nRegAtu) + " de " + CValToChar(nRegTot) + "...")
		If oPrintOrc:PrintIni((cAliPeds)->CJ_FILIAL, (cAliPeds)->CJ_NUM)
			oPrintOrc:Imprime()
			oPrintOrc:PrintFim()
		EndIf

		(cAliPeds)->(DBSkip())
	End

	(cAliPeds)->(DBCloseArea())

	oPrintOrc:Close()

Return()

/*/{Protheus.doc} RFAT001B
Impressao direto pelo Outas Acoes da tela de Orcamentos
@type function
@version 1.00
@author Luiz Alves Felizardo
@since 17/08/2022
/*/
User Function RFAT001B()

	Private oPrintOrc As Object

	oPrintOrc := PrintOrcamento():New("ORC")
	If oPrintOrc:PrintIni(SCJ->CJ_FILIAL, SCJ->CJ_NUM)
		oPrintOrc:Imprime()
		oPrintOrc:PrintFim()
	EndIf
	oPrintOrc:Close()

Return()
