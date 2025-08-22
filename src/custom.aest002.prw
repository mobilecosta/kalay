#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} AEST002
	MVC Cadastro de Balança

	@type User Function
	@author Tiago Cunha
	@since 01/07/2025
	@version 1.0.0
/*/
User Function AEST002()
	Local aArea   := GetArea()
	Local oBrowse := Nil

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZS3")
	oBrowse:SetDescription("Cadastro de Balança")
	oBrowse:SetMenuDef("CUSTOM.AEST002")

	oBrowse:Activate()

	RestArea(aArea)
Return Nil


Static Function MenuDef()
    Local aRot := {}
     
    //Adicionando opções
    ADD OPTION aRot TITLE 'Visualizar' ACTION 'VIEWDEF.CUSTOM.AEST002' OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 1
    ADD OPTION aRot TITLE 'Incluir'    ACTION 'VIEWDEF.CUSTOM.AEST002' OPERATION MODEL_OPERATION_INSERT ACCESS 0 //OPERATION 3
    ADD OPTION aRot TITLE 'Alterar'    ACTION 'VIEWDEF.CUSTOM.AEST002' OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
    ADD OPTION aRot TITLE 'Excluir'    ACTION 'VIEWDEF.CUSTOM.AEST002' OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5
 
Return aRot


Static Function ModelDef()

  Local oModel        := Nil
  Local oStructZS3     := FWFormStruct(1, 'ZS3')
  
   //Criando o modelo e os relacionamentos
   oModel := MPFormModel():New('MODELZS3')
   oModel:AddFields('ZS3MASTER',/*cOwner*/,oStructZS3)
   oModel:SetPrimaryKey({})
     
   //Setando as descrições
   oModel:SetDescription("Cadastro de Marketplaces")
   oModel:GetModel('ZS3MASTER'):SetDescription('"Cadastro de Marketplaces"')

Return ( oModel )

Static Function ViewDef()
    
    Local oView        := Nil
    Local oModel        := FWLoadModel('CUSTOM.AEST002')
    Local oStructZS3    := FWFormStruct(2, 'ZS3')
     
    //Criando a View
    oView := FWFormView():New()
    oView:SetModel(oModel)
     
    //Adicionando os campos do cabeçalho e o grid dos filhos
    oView:AddField('VIEW_ZS3',oStructZS3,'ZS3MASTER')
     
    //Setando o dimensionamento de tamanho
    oView:CreateHorizontalBox('FORM',100)
     
    //Amarrando a view com as box
    oView:SetOwnerView('VIEW_ZS3','FORM')
     
    //Força o fechamento da janela na confirmação
    oView:SetCloseOnOk({||.T.})

Return oView
