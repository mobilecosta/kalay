#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

//-------------------------------------------------
/*/{Protheus.doc} ACOM003
Cadastro de Balanças

@type function
@version 1.0
@author Lucas José Corrêa Chagas

@since 30/08/2021
/*/
//-------------------------------------------------
User Function ACOM003()

    Local oBrowse as Object

    private cCadastro as Character

    cCadastro := 'Cadastro de Balanças'    

    oBrowse := FwLoadBrw("LOGWOOD_ACOM003")
    if ( oBrowse != nil )
        oBrowse:Activate()
    endif

Return

//-------------------------------------------------
/*/{Protheus.doc} BrowseDef
Define a criação do browse na rotina.

@type function
@version 1.0
@author Lucas José Corrêa Chagas

@since 30/08/2021

@return Object, Instância do FwMBrowse já configurado.
/*/
//-------------------------------------------------
Static Function BrowseDef()
    
    Local oBrowse as Object

    oBrowse := FwMBrowse():New()
    oBrowse:SetAlias("Z02")
    oBrowse:SetDescription( cCadastro )
    oBrowse:SetMenuDef("LOGWOOD_ACOM003")

Return (oBrowse)

//-------------------------------------------------
/*/{Protheus.doc} MenuDef
Define o menu da Rotina.

@type function
@version 1.0
@author Lucas José Corrêa Chagas

@since 30/08/2021

@return Array, Array com o Menu Criado
/*/
//-------------------------------------------------
Static Function MenuDef()
    
    Local Rotinas as Array

    Rotinas := FWMVCMenu("LOGWOOD_ACOM003")

    aAdd( Rotinas, { 'Ativar Comunicação'   , 'U_ACOM003A', 0, 10, 0, NIL } )
    aAdd( Rotinas, { 'Desativar Comunicação', 'U_ACOM003A', 0, 11, 0, NIL } )

Return Rotinas

//-------------------------------------------------
/*/{Protheus.doc} ModelDef
Define o modelo a ser utilizado no MVC.

@type function
@version 1.0
@author Lucas José Corrêa Chagas

@since 30/08/2021

@return Object, objeto MpFormModel
/*/
//-------------------------------------------------
Static Function ModelDef()

    Local oModel   as Object
    Local oStruZ02 as Object

    // INSTANCIA O MODELO
    oModel := MPFormModel():New("AC003MVC")

    // INSTANCIA O SUBMODELO
    oStruZ02 := FwFormStruct(1, "Z02")

    oModel:AddFields( "Z02MASTER", NIL, oStruZ02 )
    oModel:SetPrimaryKey( { 'Z02_FILIAL', 'Z02_ID' } )
    oModel:GetModel( "Z02MASTER" ):SetDescription( "Balanças" )

    oModel:SetDescription("Cadastro de Balanças")

Return (oModel)

//-------------------------------------------------
/*/{Protheus.doc} ViewDef
Define a visualização da tela.

@type function
@version 1.0
@author Lucas José Corrêa Chagas

@since 30/08/2021

@return Object, Objeto FWFormView
/*/
//-------------------------------------------------
Static Function ViewDef()

    Local oView  as Object
    Local oModel as Object
    Local oStPai as Object

    oModel := FWLoadModel("LOGWOOD_ACOM003")
    oStPai := FWFormStruct(2, 'Z02')
     
    //Criando a View
    oView := FWFormView():New()
    oView:SetModel(oModel)
     
    //Adicionando os campos do cabeçalho e o grid dos filhos
    oView:AddField('VIEW_Z02',oStPai,"Z02MASTER")
     
    //Setando o dimensionamento de tamanho
    oView:CreateHorizontalBox( 'CABEC', 100 )
     
    //Amarrando a view com as box
    oView:SetOwnerView('VIEW_Z02','CABEC')
     
    //Habilitando título
    oView:EnableTitleView('VIEW_Z02','Balança')

Return oView

//-------------------------------------------------
/*/{Protheus.doc} ACOM003A
Chamada de menu específico da rotina.

@type function
@version 1.0
@author Lucas José Corrêa Chagas

@since 31/08/2021

@param Alias, character, Alias da Tela
@param Reg, numeric, Registro posicionado
@param Opc, numeric, Opção de Execução.
/*/
//-------------------------------------------------
User Function ACOM003A( Alias as Character, Reg as Numeric, Opc as Numeric )

    do case
        case (Opc == 7)
            PUTMV("LW_PBAL", .T.)
        case (Opc == 8)
            PUTMV("LW_PBAL", .F.)
    endcase

Return