#INCLUDE 'FWMVCDEF.CH'
#INCLUDE 'TOTVS.CH'

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Frete Clientes x Armazem          
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT003()
	Local oBrowse
	Local aArea	:= GetArea()
	
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias('Z03')
	oBrowse:SetDescription("Frete Clientes x Armazem")
	oBrowse:DisableDetails()
	oBrowse:Activate()

	RestArea(aArea)

Return NIL

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
			Define as operacoes da aplicacao
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
Static Function MenuDef()
	Local aRotina := {}

	ADD OPTION aRotina TITLE "Pesquisar"  	ACTION "PesqBrw"             	OPERATION 1 ACCESS 0
	ADD OPTION aRotina TITLE "Visualizar" 	ACTION "VIEWDEF.AFAT003" 		OPERATION 2 ACCESS 0
	ADD OPTION aRotina TITLE "Incluir"	    ACTION "VIEWDEF.AFAT003" 		OPERATION 3 ACCESS 0
	ADD OPTION aRotina TITLE "Alterar"    	ACTION "VIEWDEF.AFAT003"		OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Excluir"    	ACTION "VIEWDEF.AFAT003"		OPERATION 5 ACCESS 0
Return aRotina

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
			Contem a Construcao e Definicao do Modelo          
@author  	Wagner Mobile Costa
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
Static Function ModelDef()
	Local oStruZ03 := FWFormStruct( 1, 'Z03' )
	Local oStruZ04 := FWFormStruct( 1, 'Z04' )

    // Cria o objeto do Modelo de Dados
	Local oModel   := MPFormModel():New('FATM003',,{ |oModel| .T. },,)
	
	// Adiciona ao modelo uma estrutura de formulário de edição por campo
	oModel:AddFields( 'Z03MASTER', /*cOwner*/, oStruZ03, /*bPreValidacao*/,  /*pOSvALIDACAO*/, /*bCarga*/ )
	//Adiciona Descricao
	oModel:SetDescription("Cliente")
	//Ordem
	oModel:SetPrimaryKey( {} )

	//Adiciona Detalhe
	oModel:AddGrid('Z04DETAIL', 'Z03MASTER', oStruZ04)
	//Faz o Relacionamento
	oModel:SetRelation('Z04DETAIL', { { 'Z04_FILIAL', 'xFilial("Z04")' },;
									  { 'Z04_CODCLI', 'Z03_CODCLI'     },;
									  { 'Z04_LOJA', 'Z03_LOJA'     } },; 
		                              Z04->(IndexKey(1)) )
	    
    // Adiciona Descricao do componente
	oModel:GetModel('Z03MASTER'):SetDescription("Cliente")
	oModel:GetModel('Z04DETAIL'):SetDescription("Armazens")
	
Return oModel


//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
			Construcao da View
@author  	Wagner Mobile Costa   
@version 	P12
@since   	06/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
Static Function ViewDef()

// Cria Objeto
Local oModel  := FWLoadModel("AFAT003")

// Cria estrutura
Local oStruZ03 := FWFormStruct(2, 'Z03')
Local oStruZ04 := FWFormStruct(2, 'Z04')
	
//Interface       
Local oView

	oStruZ04:RemoveField('Z04_CODCLI')
	oStruZ04:RemoveField('Z04_LOJA')

	//Cria Objeto de View
	oView := FWFormView():New()

	//Define Qual Modelo
	oView:SetModel(oModel)

	//Define Mestre
	oView:AddField('VIEW_Z03', oStruZ03, 'Z03MASTER')

	//Cria Box
	oView:CreateHorizontalBox('SUPERIOR', 20)
	oView:CreateHorizontalBox('INFERIOR', 80)

	//Relaciona ID
	OView:SetOwnerView('VIEW_Z03', 'SUPERIOR')

	//Adiciona Detail
	oView:AddGrid('VIEW_Z04', oStruZ04, 'Z04DETAIL')
	OView:SetOwnerView('VIEW_Z04', 'INFERIOR')

Return oView
