#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

//-------------------------------------------------
/*/{Protheus.doc} ACOM001
Rotina de pesagens para o documento de entrada.

@type function
@version 1.0
@author Lucas José Corrêa Chagas

@since 30/08/2021
/*/
//-------------------------------------------------
User Function ACOM001()

    Local oBrowse as Object

    private cCadastro as Character

    public aArquivos as Array

    aArquivos := {}

    cCadastro := 'Pesagem de Compras'    

    oBrowse := FwLoadBrw("LOGWOOD_ACOM001")
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
Static Function BrowseDef() as Object
    
    Local oBrowse as Object

    oBrowse := FwMBrowse():New()
    oBrowse:SetAlias("Z00")
    oBrowse:SetDescription( cCadastro )

    oBrowse:AddLegend( "Z00_STATUS == '1'", "GREEN" , "Aberta"     )
    oBrowse:AddLegend( "Z00_STATUS == '2'", "YELLOW", "Iniciada"   )
    oBrowse:AddLegend( "Z00_STATUS == '3'", "RED"   , "Finalizada" )
    oBrowse:SetMenuDef("LOGWOOD_ACOM001")

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
Static Function MenuDef() as Array
    
    Local Rotinas as Array

    Rotinas := FWMVCMenu("LOGWOOD_ACOM001")

    aAdd( Rotinas, { 'Banco de Conhecimento', "MsDocument('Z00',Z00->(RecNo()), 4)", 0, 10, 0, NIL } )

    if findFunction('U_RCOM001')
        aAdd( Rotinas, { 'Impressão Romaneio de Entrada', "U_RCOM001(.T.)", 0, 11, 0, NIL } )
    endif

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
Static Function ModelDef() as Object

    Local aRel     as Array
    Local bPost    as CodeBlock
    Local oModel   as Object
    Local oStruZ00 as Object
    Local oStruZ01 as Object

    bPost := { |oMdl| ValModel( oMdl ) }

    oModel := MPFormModel():New( "AC001MVC" )

    oStruZ00 := FwFormStruct( 1, "Z00" )
    oStruZ01 := FwFormStruct( 1, "Z01" )
    oStruZ01:aFields[2,11] := { |a,b,c| FWInitCpo(a,b,c),xRet:=FWFldGet('Z00_NUM'),FWCloseCpo(a,b,c,.T.),FwSetVarMem(a,b,xRet),xRet } // relacionamento Z01_NUM com Z00_NUM

    oModel:AddFields( "Z00MASTER", NIL, oStruZ00 )
    oModel:SetPrimaryKey( { 'Z00_FILIAL', 'Z00_NUM' } )
    oModel:GetModel( "Z00MASTER" ):SetDescription( "Pesagem de Entrada" )
    
    aRel := {}
    aAdd( aRel, {'Z01_FILIAL', "fwXfilial('Z01')"} )
    aAdd( aRel, {'Z01_NUM'   , 'Z00_NUM'   } ) 
    oModel:AddGrid( 'Z01DETAIL', "Z00MASTER", oStruZ01,/*bLinePre*/, /*bLinePost*/,/*bPre - Grid Inteiro*/, bPost /*bLoad - Carga do modelo manualmente*/)  //cOwner é para quem pertence
    oModel:SetRelation( 'Z01DETAIL', aRel, Z01->(IndexKey(1)) )
    oModel:GetModel( 'Z01DETAIL' ):SetUniqueLine( {"Z01_FILIAL", "Z01_NUM", "Z01_ITEM"} ) 

    oModel:SetDescription("Cabeçalho da Pesagem de Entrada")
    oModel:GetModel( "Z00MASTER" ):SetDescription( "Pesagem de Entrada" )
    oModel:GetModel( 'Z01DETAIL' ):SetDescription( 'Produtos Pesados' )

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
Static Function ViewDef() as Object

    Local oView    as Object
    Local oModel   as Object
    Local oStPai   as Object
    Local oStFilho as Object

    oModel := FWLoadModel("LOGWOOD_ACOM001")
    oStPai := FWFormStruct(2, 'Z00')
    oStFilho := FWFormStruct(2, 'Z01')
     
    //Criando a View
    oView := FWFormView():New()
    oView:SetModel(oModel)
     
    //Adicionando os campos do cabeçalho e o grid dos filhos
    oView:AddField('VIEW_Z00',oStPai,"Z00MASTER")
    oView:AddGrid('VIEW_Z01',oStFilho,'Z01DETAIL')
    oView:AddIncrementField('VIEW_Z01','Z01_ITEM') // autoincremento
     
    //Setando o dimensionamento de tamanho
    oView:CreateHorizontalBox( 'CABEC', 40 )
    oView:CreateHorizontalBox( 'GRID' , 60 )
     
    //Amarrando a view com as box
    oView:SetOwnerView('VIEW_Z00','CABEC')
    oView:SetOwnerView('VIEW_Z01','GRID')    
     
    //Habilitando título
    oView:EnableTitleView('VIEW_Z00','Pesagem')
    oView:EnableTitleView('VIEW_Z01','Produtos')

    oView:GetViewStruct('Z01DETAIL'):RemoveField('Z01_NUM')

Return oView

//-------------------------------------------------
/*/{Protheus.doc} ValModel
Validação do Modelo.
Entre outras coisas serve para validar o status da pesagem de acordo com os dados inputados na tela.

@type function
@version 1.0
@author Lucas José Corrêa Chagas

@since 02/09/2021

@param oGrid, object, Objeto equivalente ao grid da tela.

@return Logical, Verdadeiro ou Falso
/*/
//-------------------------------------------------
Static Function ValModel( oGrid as Object ) as Logical
    
    Local bError     as CodeBlock
    Local lRet       as logical
    Local lEncerrado as Logical
    Local nOperation as numeric
    Local nI         as Numeric
    Local nItens     as Numeric
    Local oModel     as Object
    Local oSolvs     as Object
    
    lRet := .f.
    lEncerrado := .t.
    nItens := 0
    oSolvs := TSolvs():New()
        bError := ErrorBlock( { |oError| oSolvs:TrataErro( oError ) } )
            Begin SEQUENCE
                oModel := FwModelActive() // pega o modelo ativo da tela.
                nOperation := oModel:GetOperation()    

                If ((nOperation == MODEL_OPERATION_UPDATE) .or. (nOperation == MODEL_OPERATION_INSERT))
                    for nI := 1 to oGrid:GetQtdLine()
                        oGrid:GoLine(nI)

                        If !oGrid:IsDeleted() // se não esiver deletado
                            nItens++ 

                            //oModel:SetValue('Z01DETAIL', 'Z01_FILIAL', FWxFILIAL('Z01'))                            
                            lEncerrado := lEncerrado .and. ((oGrid:GetValue('Z01_PENT') > 0) .and. (oGrid:GetValue('Z01_PSAIDA') > 0))
                        Endif
                    next

                    if ( nItens == 0 )
                        UserException('Não há itens inseridos na pesagem!')
                    endif

                    if !lEncerrado
                        oModel:SetValue("Z00MASTER", 'Z00_STATUS', '2')
                    else
                        oModel:SetValue("Z00MASTER", 'Z00_STATUS', '3')
                    endif
                EndIf

                lRet := .T.
            Recover
                FWAlertError( oSolvs:GetSimpleError(), cCadastro )
            End SEQUENCE
        ErrorBlock( bError )
        MsUnlockAll()
    FwFreeVar( @oSolvs )

return lRet

//-------------------------------------------------
/*/{Protheus.doc} ACOM001A
Lista Pesagens de Entrada que já foram finalizadas e não tem relacionamento com o nenhum documento de entrada.
Filtro da pesquisa considera o fornecedor da nota.

Rotina dispara pelos pontos de entrada MA103BUT e MA140BUT.

@type function
@version 1.0
@author Lucas José Corrêa Chagas

@since 02/09/2021
/*/
//-------------------------------------------------
User Function ACOM001A()

    Local Registros as Array
    Local aColsBkp  as Array
    Local dbClick   as CodeBlock
    Local hdClick   as CodeBlock
    Local bConfirm  as CodeBlock
    Local bSair     as CodeBlock
    Local bRec      as CodeBlock
    Local oModal    as Object
    Local oSolvs    as Object
    
    Private oGrid as Object
    Private MTodosA as Logical

    MTodosA := .f.

    If ( Empty(cA100For) .or. Empty(cLoja) ) .or. ( len(aCols) == 0 )
        FWAlertError( 'Verifique os dados do documento. Devem ser informados fornecedor e produtos.', cCadastro )
    else	
        bSair := { || Registros := {}, oModal:DeActivate() }
        bConfirm := { || Registros := aClone(oGrid:oData:aArray), oModal:DeActivate() }
        bRec := { || oSolvs:SafeRun( { || oGrid:SetArray( Busca() ), oGrid:Refresh( .t. ) } ) }

        oSolvs := TSolvs():New()
			if !oSolvs:SafeRun( { || TstPed() } )
                FWAlertError( oSolvs:GetSimpleError(), cCadastro )  
			else
				if !oSolvs:SafeRun( { || Registros := Busca() } )
					FWAlertError( oSolvs:GetSimpleError(), cCadastro )    
				else
					if (len(Registros) == 0)
						FWAlertError( 'Registros para criação de itens não encontrados!', cCadastro )
					else
						oModal  := FWDialogModal():New()       
							oModal:setTitle("Pesagens disponíveis")
							oModal:setSubTitle("Selecione os itens da lista abaixo para o Documento de Entrada.")
							oModal:EnableFormBar( .T. )
							oModal:SetCloseButton( .F. )
							oModal:SetEscClose( .F. )
							oModal:enableAllClient()
						
							oModal:createDialog()
							oModal:CreateFormBar()
							oModal:AddButton( 'Confirmar'       , bConfirm, 'Confirmar'       , , .T., .F., .T., )
							oModal:AddButton( 'Recarregar Itens', bRec    , 'Recarregar Itens', , .T., .F., .T., )
							oModal:AddButton( 'Cancelar'        , bSair   , 'Cancelar'        , , .T., .F., .T., )

							oGrid := FwBrowse():New( oModal:getPanelMain() )
								oGrid:SetDataArray(.t.)
								oGrid:SetArray( Registros )
								oGrid:DisableFilter()
								oGrid:DisableReport()
								oGrid:DisableConfig()
								oGrid:DisableLocate()
								oGrid:DisableSeek()
								
								oGrid:SetLineHeight(15)

								Colunas := {}
								oGrid:BldblClick := nil

								dbClick := { |oBrowse| iif( len(oGrid:oData:aArray) > 0, MarcaReg( oGrid:At() ), nil )  }
								hdClick := { |oBrowse| iif( len(oGrid:oData:aArray) > 0, MarcaReg( oGrid:At(), .t. ), nil )  }

								oGrid:AddMarkColumns( { || Iif(oGrid:oData:aArray[ oGrid:At(),01 ],'LBOK','LBNO') }, dbClick, hdClick )
								oGrid:BldblClick := dbClick

								aAdd( Colunas, oSolvs:NovaColuna({ || oGrid:oData:aArray[ oGrid:At(), 02 ]}, RetTitle( "Z01_NUM"   ), TamSx3( "Z01_NUM"   )[01], "C", PesqPict( "Z01", "Z01_NUM"   )) )
								aAdd( Colunas, oSolvs:NovaColuna({ || oGrid:oData:aArray[ oGrid:At(), 03 ]}, RetTitle( "Z01_ITEM"  ), TamSx3( "Z01_ITEM"  )[01], "C", PesqPict( "Z01", "Z01_ITEM"  )) )
								aAdd( Colunas, oSolvs:NovaColuna({ || oGrid:oData:aArray[ oGrid:At(), 04 ]}, RetTitle( "Z01_PROD"  ), TamSx3( "Z01_PROD"  )[01], "C", PesqPict( "Z01", "Z01_PROD"  )) )
								aAdd( Colunas, oSolvs:NovaColuna({ || oGrid:oData:aArray[ oGrid:At(), 05 ]}, RetTitle( "B1_DESC"   ), TamSx3( "B1_DESC"   )[01], "C", PesqPict( "SB1", "B1_DESC"   )) )
								aAdd( Colunas, oSolvs:NovaColuna({ || oGrid:oData:aArray[ oGrid:At(), 06 ]}, 'Peso Efetivo'         , TamSx3( "Z01_PENT"  )[01], "N", PesqPict( "Z01", "Z01_PENT"  )) )

								oGrid:SetColumns( Colunas )
							oGrid:Activate()
						oModal:Activate()

						if ( len( Registros ) > 0 )
							aColsBkp := aClone( aCols )
							Safe := oSolvs:SafeRun( { || CriaItens( Registros ) } )
							if !Safe
								aCols := aClone( aColsBkp )
								FWAlertError( oSolvs:GetSimpleError(), cCadastro )    
							endif
						endif
					endif
				endif
			endif
        TSolvs():Free( @oSolvs )
    endif

Return

//-------------------------------------------------
/*/{Protheus.doc} CriaItens
Cria itens no Acols do documento de entrada

@type function
@version 1.0
@author Lucas José Corrêa Chagas

@since 02/09/2021

@param Registros, array, Registros para geração
/*/
//-------------------------------------------------
Static Function CriaItens( Registros as Array )

    Local Item       as Character
    Local I          as Numeric
    Local J          as Numeric
    Local K          as Numeric	
	Local pD1_QUANT  as numeric
	Local pD1_TOTAL  as numeric
	Local pD1_TES    as numeric
	Local pD1_XPESAG as numeric
	Local pD1_XITPES as numeric
	Local pD1_VUNIT  as Numeric
	
	pD1_QUANT  := aScan( aHeader, { |x| AllTrim(x[2]) == "D1_QUANT"  } )
	pD1_TOTAL  := aScan( aHeader, { |x| AllTrim(x[2]) == "D1_TOTAL"  } )
	pD1_TES    := aScan( aHeader, { |x| AllTrim(x[2]) == "D1_TES"    } )
	pD1_XPESAG := aScan( aHeader, { |x| AllTrim(x[2]) == "D1_XPESAG" } )
	pD1_XITPES := aScan( aHeader, { |x| AllTrim(x[2]) == "D1_XITPES" } )
	pD1_VUNIT  := aScan( aHeader, { |x| AllTrim(x[2]) == "D1_VUNIT"  } )
	
    for i := 1 to len(Registros)
        if Registros[i, 1]
		
			k := 0
			j := 1
			while ( j <= len(aCols) ) .and. ( k == 0 )
				item := alltrim(aCols[ j, aScan( aHeader, { |x| AllTrim(x[2]) == "D1_COD" } ) ])			
				if ( item == alltrim( Registros[i, 4] ) )
					k := j
				endif
				
				j++
			enddo
			
			if ( k == 0 )
				UserException('Item de romaneio selecionado não pertence a este documento!')
			endif
			
			aCols[ k, pD1_XPESAG ] := Registros[i, 2]
            DisparaTri( "D1_XPESAG", k )

            aCols[ k, pD1_XITPES ] := Registros[i, 3]
            DisparaTri( "D1_XITPES", k )

            aCols[ k, pD1_QUANT ] := Registros[i, 6]
            DisparaTri( "D1_QUANT", k )

            aCols[ k, pD1_TOTAL ] := Registros[i, 6] * aCols[ k, pD1_VUNIT ]
            DisparaTri( "D1_TOTAL", k )

            if ( pD1_TES > 0)
                dbSelectArea('SF4')
                SF4->(dbSetOrder(1))
                SF4->(dbSeek( fwxFilial('SF4') + aCols[ k, pD1_TES ] ))
                DisparaTri( "D1_TES", k )
            endif
        endif
    next

Return

//-------------------------------------------------
/*/{Protheus.doc} DisparaTri
Rotina para disparo de trigger.

@type function
@version 1.0
@author Lucas José Corrêa Chagas

@since 03/09/2021

@param Campo, character, Campo da SX3
@param Pos, numeric, Posição do Acols
/*/
//-------------------------------------------------
Static Function DisparaTri( Campo as Character, Pos as Numeric )

    /*Local Coluna as Numeric
    Local Reg    as Numeric*/

    If ExistTrigger( Campo )

        RunTrigger( 2, Pos, nil, , Campo )
    EndIf

Return

//-------------------------------------------------
/*/{Protheus.doc} Busca
Busca os dados das pesagens através de consulta SQL.

@type function
@version 1.0
@author Lucas José Corrêa Chagas

@since 03/09/2021

@return Array, Array com os dados encontrados.
/*/
//-------------------------------------------------
Static Function Busca()

    Local Registro as Array
    Local Retorno  as Array
    Local cAlias   as Character
    Local cQuery   as Character

    cQuery := "SELECT "
    cQuery += "	Z01_NUM, Z01_ITEM, Z01_PROD, B1_DESC, "
    cQuery += "	(Z01_PENT - Z01_PSAIDA) AS PLIQ"
    cQuery += "FROM "
    cQuery += "	" + RetSqlName('Z00') + " Z00 "
    cQuery += "INNER JOIN " + RetSqlName('Z01') + " Z01 ON "
    cQuery += "	Z01.Z01_FILIAL = Z00.Z00_FILIAL "
    cQuery += "	AND Z01.Z01_NUM = Z00.Z00_NUM "
    cQuery += "	AND Z01.Z01_DOC = '" + Space(TamSx3('Z01_DOC')[1]) + "' "
    cQuery += "	AND Z01.Z01_SERIE = '" + Space(TamSx3('Z01_SERIE')[1]) + "' "
    cQuery += "	AND Z01.Z01_ITNFE = '" + Space(TamSx3('Z01_ITNFE')[1]) + "' "
    cQuery += "	AND Z01.D_E_L_E_T_ = ' ' "
    cQuery += "INNER JOIN " + RetSqlName('SB1') + " SB1 ON "
    cQuery += "	SB1.B1_FILIAL = '" + fwXfilial('SB1') + "' "
    cQuery += "	AND SB1.B1_COD = Z01.Z01_PROD"
    cQuery += "	AND SB1.D_E_L_E_T_ = ' '"
    cQuery += "WHERE "
    cQuery += "	Z00.Z00_FILIAL = '" + fwXfilial('Z00') + "' "
    cQuery += "	AND Z00.Z00_FORN = '" + cA100For + "' "
    cQuery += "	AND Z00.Z00_LOJA = '" + cLoja + "' "
    cQuery += "	AND Z00.Z00_STATUS = '3' "
    cQuery += "	AND Z00.D_E_L_E_T_ = ' ' "
    cQuery += "ORDER BY "
    cQuery += "	Z01_FILIAL, Z01_NUM, Z01_ITEM, Z01_PROD "

    Retorno := {}
    cAlias := MPSysOpenQuery( changeQuery(cQuery) )

    while !(cAlias)->(EOF())

        Registro := {}
        aAdd( Registro, .F.                 )
        aAdd( Registro, (cAlias)->Z01_NUM   )
        aAdd( Registro, (cAlias)->Z01_ITEM  )
        aAdd( Registro, (cAlias)->Z01_PROD  )
        aAdd( Registro, (cAlias)->B1_DESC   )
        aAdd( Registro, (cAlias)->PLIQ      )

        aAdd( Retorno, aClone(registro) )

        (cAlias)->(dbSkip())
    enddo
    (cAlias)->(dbCloseArea())

Return Retorno

//-------------------------------------------------
/*/{Protheus.doc} MarcaReg
Marca registros na tela.

@type function
@version 1.0
@author Lucas José Corrêa Chagas

@since 02/09/2021

@param Posicao, numeric, Posição do registro no grid
@param Todos, logical, Se marca todos ou não.
/*/
//-------------------------------------------------
Static Function MarcaReg( Posicao as Numeric, Todos as Logical )

    Local i as numeric

    default Posicao := -1
    default Todos := .F.
	
    if !Todos
        oGrid:oData:aArray[posicao, 1] := !oGrid:oData:aArray[posicao, 1]
    else
        MTodosA := !MTodosA
        
        for i := 1 to len( oGrid:oData:aArray )
            oGrid:oData:aArray[i, 1] := MTodosA
        next i

        ogrid:Refresh(.f.)
    endif

Return

//-------------------------------------------------
/*/{Protheus.doc} TstPed
Testa se itens do documento tem amarração com pedido de compras

@type function
@version 1.0
@author Lucas José Corrêa Chagas

@since 03/09/2021
/*/
//-------------------------------------------------
Static Function TstPed()
	
	Local PcNfe as Logical
	Local i     as numeric
	Local PosP  as numeric
	Local PosIp as Numeric
	
	PcNfe := SuperGetMv('MV_PCNFE', .f., .f.)
	if PcNfe
		PosP  := aScan( aHeader, { |x| AllTrim(x[2]) == "D1_PEDIDO" } )
		PosIp := aScan( aHeader, { |x| AllTrim(x[2]) == "D1_ITEMPC" } )
		
		if (( PosP == 0 ) .or. ( PosIp == 0 ))
			userException('Campos D1_PEDIDO ou D1_ITEMPC não estão presentes na tela!')
		endif
		
		for i := 1 to len(aCols)
			if ( Empty(aCols[i, posp]) .or. Empty(aCols[i, posip]) )
				UserException('Verifique os itens do documento, número do pedido de compras não informado!')
			endif
		next
	endif
	
Return

//-------------------------------------------------
/*/{Protheus.doc} ACOM001B
Rotina para processar amarração entre pesagem de entrada e documento de entrada.

@type function
@version 1.0
@author Lucas José Corrêa Chagas

@since 03/09/2021

@param Opc, numeric, Opção
@param Doc, character, Documento
@param Serie, character, Série
@param Fornec, character, Fornecedor
@param Loja, character, Loja
@param oSolvs, object, Instancia da Classe TSolvs
/*/
//-------------------------------------------------
User Function ACOM001B( Opc as Numeric, Doc as Character, Serie as Character, Fornec as Character, Loja as Character, oSolvs as Object )

    oSolvs:AbreArea( 'SD1' ) // D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
    oSolvs:AbreArea( 'Z01', 3 ) // Z01_FILIAL+Z01_DOC+Z01_SERIE+Z01_ITNFE
    oSolvs:AbreArea( 'Z00', 3 ) // Z00_FILIAL+Z00_NUM+Z00_FORN+Z00_LOJA

    BeginTran()
    // primeiro, limpa os relacionamentos existentes.
    if Z01->(dbSeek( fwXfilial('Z01') + Doc + Serie ))
        while !Z01->(EOF()) .and. ( Z01->Z01_FILIAL == fwXfilial('Z01') ) .and. ( Z01->Z01_DOC == Doc ) .and. ( Z01->Z01_SERIE == Serie )
            Z00->(dbGoTop())
            if Z00->(dbSeek( fwXfilial('Z00') + Z01->Z01_NUM + Fornec + Loja ))

                if RecLock('Z01', .f.)
                    Z01->Z01_DOC   := ''
                    Z01->Z01_SERIE := ''
                    Z01->Z01_ITNFE := ''

                    Z01->(MsUnlock())
                endif
            endif

            Z01->(dbSkip())
        enddo
    endif

    if (( opc == 3 ) .or. ( opc == 4 )) // inclusão ou alteração
        if SD1->(dbSeek( fwXfilial('SD1') + Doc + Serie + Fornec + Loja))            
            Z01->(dbSetOrder(1)) // Z01_FILIAL+Z01_NUM+Z01_ITEM+Z01_PROD
            while !SD1->(EOF()) .and. ( SD1->D1_FILIAL == fwXfilial('SD1') ) .and. ( SD1->D1_DOC == Doc ) .and. ( SD1->D1_SERIE == Serie ) .and. ( SD1->D1_FORNECE == Fornec ) .and. ( SD1->D1_LOJA == Loja )

                Z01->(dbGotOp())
                Z00->(dbGoTop())

                if Z00->(dbSeek( fwXfilial('Z00') + SD1->D1_XPESAG + Fornec + Loja ))
                    if Z01->(dbSeek( fwXfilial('Z01') + SD1->D1_XPESAG + SD1->D1_XITPES + SD1->D1_COD ))

                        if RecLock('Z01', .f.)
                            Z01->Z01_DOC   := Doc
                            Z01->Z01_SERIE := Serie
                            Z01->Z01_ITNFE := SD1->D1_ITEM

                            Z01->(MsUnlock())
                        endif

                    endif
                endif

                SD1->(dbSkip())
            enddo
        endif
    endif
    EndTran()

Return