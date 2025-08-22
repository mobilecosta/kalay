#include "Totvs.Ch"
#INCLUDE 'FWMVCDEF.CH'

Static lSel := Nil

//-------------------------------------------------
/*/{Protheus.doc} AFAT005
Rotina para Geração de Pedido Complementar

@type function
@version 1.0
@author Wagner Mobile Costa

@since 06/11/2021
/*/
//-------------------------------------------------
User Function AFAT005()

	Local oBrowse
	
	DbSelectArea("Z05")

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('Z05')
	oBrowse:SetDescription("Geração Pedido Complementar")
	oBrowse:AddLegend( "Z05_STATUS=='1'", "GREEN", "Em Aberto" )
	oBrowse:AddLegend( "Z05_STATUS=='2'", "RED"  , "Concluido" )
	oBrowse:Activate()

Return

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Define as operacoes da rotina
@author  Wagner Mobile Costa
@version 1.0
@since 06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
Static Function MenuDef() as Array
	Local aRotina := {}

    ADD OPTION aRotina TITLE "Pesquisar"	        ACTION "PesqBrw"            OPERATION 1 ACCESS 0
    ADD OPTION aRotina TITLE "Visualizar" 	        ACTION "VIEWDEF.AFAT005" 	OPERATION 2 ACCESS 0
    ADD OPTION aRotina TITLE "Incluir"    	        ACTION "VIEWDEF.AFAT005" 	OPERATION 3 ACCESS 0
    ADD OPTION aRotina TITLE "Alterar" 	        	ACTION "VIEWDEF.AFAT005" 	OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE "Excluir" 	        	ACTION "VIEWDEF.AFAT005" 	OPERATION 5 ACCESS 0
    ADD OPTION aRotina TITLE "Encerrar" 	        ACTION "U_AFAT005E()" 		OPERATION 4 ACCESS 0
    ADD OPTION aRotina TITLE "Relatório" 	        ACTION "U_RFAT005()" 		OPERATION 3 ACCESS 0

Return aRotina

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
			Contem a Construcao e Definicao do Modelo          
@author  	Wagner Mobile Costa
@version 	P12
@since   	30/09/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
Static Function ModelDef()
	Local oStruPAI := FWFormStruct( 1, 'Z05' )
	Local oModel   := MPFormModel():New('AFATM005', { || U_AFAT5PRE() } ,,,;
						{ |oModel| (U_AFAT5CAN(oModel), FWFORMCANCEL(SELF), lSel := .F., .T.) })
    Local oCommit  := AFAT005EV():New()
	
	oModel:AddFields( 'MASTER',, oStruPAI)
	oModel:SetDescription("Pedido Complementar")
	oModel:SetPrimaryKey( {} )

    oModel:GetModel('MASTER'):SetDescription("Pedido Complementar")
	oModel:SetVldActivate( { |oModel| U_AFAT5VLD(oModel) } )
    oModel:InstallEvent("AFAT005EV", /*cOwner*/, oCommit)

Return oModel

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
			Construcao da View
@author  	Wagner Mobile Costa
@version 	P12
@since   	30/09/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
Static Function ViewDef()

	Local oModel   := FWLoadModel("AFAT005")
    Local oStruPAI := FWFormStruct(2, 'Z05')
	Local oView

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField('VIEW_PAI', oStruPAI, 'MASTER')

	oView:CreateHorizontalBox('SUPERIOR', 25)
	OView:SetOwnerView('VIEW_PAI', 'SUPERIOR')

	oView:CreateHorizontalBox('INFERIOR', 75)

    oView:AddOtherObject('VIEW_ITEM',{| oPanel | U_AFAT006(oPanel) }, ,,  .F. )
	OView:SetOwnerView('VIEW_ITEM', 'INFERIOR')
	OView:EnableTitleView('VIEW_ITEM', 'Itens de Nota')

Return oView

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para validação de preenchimento do campo ZA5_CLIENT
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT05CL()

Return ! Z06->(DbSeek(xFilial() + FWFLDGET('Z05_ID')))

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para encerramento do processo de pesagem
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT005E()

Local lOk := .T.

	If Z05->Z05_STATUS == "2"
		APMsgAlert("Processo já encerrado !","Encerrado")
		Return
	EndIF

	M->Z05_NUMSC5 := ""
	If Z05->Z05_DIFPES > 0
	    MsgRun("Gerando Pedido de Vendas ...","Aguarde...",{|| GerPedido(lOk) })
		If ! lOk
			Return
		EndIf
	EndIf

	RecLock("Z05", .F.)
	Z05->Z05_STATUS := "2"
	Z05->Z05_NUMSC5 := M->Z05_NUMSC5
	Z05->Z05_FILSC5 := cFilAnt
	Z05->(MsUnLock())

Return

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para encerramento do processo de pesagem
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
Static Function GerPedido(lOk)

Local aCabec := {}
Local aItens := {}
Local aLinha := {}

PRIVATE lMsErroAuto := .F.

	M->Z05_NUMSC5 := GetSxeNum("SC5","C5_NUM")
	While SC5->(MsSeek(xFilial("SC5")+M->Z05_NUMSC5))
		M->Z05_NUMSC5 := GetSxeNum("SC5","C5_NUM")
	End
	RollBAckSx8()

	BeginSQL Alias "QRY"
		SELECT MIN(C5_CONDPAG) AS C5_CONDPAG, MIN(C5_TIPOCLI) AS C5_TIPOCLI, MIN(C5_MOEDA) AS C5_MOEDA, 
		       C6_PRODUTO, SUM(Z06_DIFPES) AS C6_QTDVEN, MIN(C6_PRCVEN) AS C6_PRCVEN, MIN(C6_OPER) AS C6_OPER,
			   MIN(C6_TES) AS C6_TES, MIN(C6_LOCAL) AS C6_LOCAL, MIN(C6_DESCRI) AS C6_DESCRI, MIN(C6_LOTECTL) AS C6_LOTECTL,
			   MIN(C6_DTVALID) AS C6_DTVALID, MIN(C6_LOCALIZ) AS C6_LOCALIZ, MIN(C6_NUMSERI) AS C6_NUMSERI, 
			   MIN(C6_CC) AS C6_CC
		  FROM %table:Z06% Z06  
		  JOIN %table:SC6% SC6 ON C6_FILIAL = Z06_FILPED AND C6_NUM = Z06_NUMSC5 AND C6_ITEM = Z06_ITMSC5 AND SC6.D_E_L_E_T_ = ' '
		  JOIN %table:SC5% SC5 ON C5_FILIAL = C6_FILIAL AND C5_NUM = C6_NUM AND SC5.D_E_L_E_T_ = ' '
		 WHERE Z06_FILIAL = %exp:xFilial('Z06')% AND Z06_ID = %exp:Z05->Z05_ID% AND Z06.D_E_L_E_T_ = ' ' 
		 GROUP BY C6_PRODUTO
	     ORDER BY C6_PRODUTO
	EndSql
	TcSetField("QRY","C6_DTVALID","D",8,0)

	aadd(aCabec,{"C5_FILIAL" ,xFilial("SC5") ,Nil})
	aadd(aCabec,{"C5_NUM"    ,M->Z05_NUMSC5  ,Nil})
	aadd(aCabec,{"C5_TIPO"   ,"N"            ,Nil})
	aadd(aCabec,{"C5_CLIENTE",Z05->Z05_CLIENT,Nil})
	aadd(aCabec,{"C5_LOJACLI",Z05->Z05_LOJA  ,Nil})
	aadd(aCabec,{"C5_LOJAENT",Z05->Z05_LOJA  ,Nil})
	aadd(aCabec,{"C5_EMISSAO",dDataBase,Nil})
	aadd(aCabec,{"C5_CONDPAG",QRY->C5_CONDPAG,Nil})
	aadd(aCabec,{"C5_TIPOCLI",QRY->C5_TIPOCLI,Nil})
	aadd(aCabec,{"C5_MOEDA",QRY->C5_MOEDA,Nil})
	aadd(aCabec,{"C5_MENNOTA","VENDA COMPLEMENTAR CONFORME CARGA ENVIADA",Nil})
	aadd(aCabec,{"C5_ORIGEM","AFAT005",Nil})
	
	//Itens
	While ! QRY->(Eof())
		aLinha := {}

		aadd(aLinha,{"C6_ITEM"   ,StrZero(Len(aItens) + 1,2),Nil})
		aadd(aLinha,{"C6_PRODUTO",QRY->C6_PRODUTO,Nil})
		aadd(aLinha,{"C6_LOCAL",QRY->C6_LOCAL,Nil})
		aadd(aLinha,{"C6_DESCRI",QRY->C6_DESCRI,Nil})
		aadd(aLinha,{"C6_QTDVEN",QRY->C6_QTDVEN,Nil})
		aadd(aLinha,{"C6_PRCVEN",QRY->C6_PRCVEN,Nil})
		aadd(aLinha,{"C6_TES",QRY->C6_TES,Nil})
		aadd(aLinha,{"C6_QTDLIB",QRY->C6_QTDVEN,Nil})
		If ! Empty(QRY->C6_LOTECTL)
			aadd(aLinha,{"C6_LOTECTL",QRY->C6_LOTECTL,Nil})
		EndIF
		If ! Empty(QRY->C6_DTVALID)
			aadd(aLinha,{"C6_DTVALID",QRY->C6_DTVALID,Nil})
		EndIF
		If ! Empty(QRY->C6_LOCALIZ)
			aadd(aLinha,{"C6_LOCALIZ",QRY->C6_LOCALIZ,Nil})
		EndIf
		If ! Empty(QRY->C6_NUMSERI)
			aadd(aLinha,{"C6_NUMSERI",QRY->C6_NUMSERI,Nil})
		EndIf
		If ! Empty(QRY->C6_CC)
			aadd(aLinha,{"C6_CC",QRY->C6_CC,Nil})
		EndIf
		aadd(aItens,aLinha)
		QRY->(DbSkip())
	EndDo
	QRY->(DbCloseArea())
	
	MATA410(aCabec,aItens,3)
	If !lMsErroAuto
		ConfirmSX8()
	Else
		DisarmTransaction()
		RollBackSX8()
		MostraErro()
		lOk := .F.
	EndIf

Return lOk

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para encerramento do processo de pesagem
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------

User Function AFAT5VLD(oModel)

Local lRet 		 := .T.
Local nOperation := oModel:GetOperation()

	If nOperation = 4 .And. Z05->Z05_STATUS = "2"
		Help(,, "AFAT5VLD",, "O processo já foi encerrado e não pode mais ser editado !", 1, 0) 
		lRet := .F.
	ElseIf nOperation = 5 .And. ! Empty(Z05->Z05_NUMSC5)
		Help(,, "AFAT5VLD",, "Para exclusão não pode haver pedido vinculado !", 1, 0) 
		lRet := .F.
	EndIf

Return lRet

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para execução da seleção de itens automaticamente
@author  	Wagner Mobile Costa
@version 	P12
@since   	08/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------

User Function AFAT5PRE()

	If ! Empty(U_AFAT04CL())		// Aciona a opção de selecionar itens
		If lSel == Nil
			lSel := .F.
		EndIf
		If ! lSel
			lSel := .T.
			U_AFAT006S()
		EndIF
	EndIf

Return .T.

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para exclusão dos itens selecionados durante a inclusão
@author  	Wagner Mobile Costa
@version 	P12
@since   	08/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------

User Function AFAT5CAN(oModel)

Local nOperation := oModel:GetOperation()
Local cQuery := "DELETE FROM " + RetSQlName("Z06") + " "

	If nOperation == 3
		cQuery +=  "WHERE Z06_FILIAL = '" + xFilial("Z06") + "' AND Z06_ID = '" + FWFLDGET('Z05_ID') + "' AND D_E_L_E_T_ = ' '"

		nError := TCSQLEXEC(cQuery)
		cError := TcSqlError()
		If nError <> 0 .And. ! Empty(cError)
			ApMsgAlert(cError, "Erro")
		EndIf
	EndIF	

Return .T.


/*/{Protheus.doc} TINCA001EV
    (long_description)
    @since 10/02/2021
    @version version
/*/
Class AFAT005EV FROM FWModelEvent
    Method New() CONSTRUCTOR
    Method AfterTTS()

ENDCLASS

/*/{Protheus.doc} New
    (long_description)
    @since 10/02/2021
    @version version
/*/
Method New() Class AFAT005EV

Return


/*/{Protheus.doc} AfterTTS
    (long_description)
    @since 10/02/2021
    @version version
    @param oModel, objeto, Objeto Model
    @param cModelId, objeto, Id do submodelo
/*/
Method AfterTTS(oModel, cModelId) Class AFAT005EV

Local cQuery := "DELETE FROM " + RetSQlName("Z06") + " "

    If oModel:GetOperation() == MODEL_OPERATION_INSERT .And. ! Empty(U_AFAT04CL())
		If MsgYesNo("Deseja encerrar o processo ?")
			U_AFAT005E()
		EndIf
	ElseIf oModel:GetOperation() == MODEL_OPERATION_DELETE
		cQuery +=  "WHERE Z06_FILIAL = '" + xFilial("Z06") + "' AND Z06_ID = '" + Z05->Z05_ID + "' AND D_E_L_E_T_ = ' '"

		nError := TCSQLEXEC(cQuery)
		cError := TcSqlError()
		If nError <> 0 .And. ! Empty(cError)
			ApMsgAlert(cError, "Erro")
		EndIf
    EndIF
	lSel := .F.

Return
