#include "protheus.ch"
#include "rwmake.ch"
#include "topconn.ch"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} xdpr001a
FwMBrowse para exibir a lista de priorização do desenvolvimento de produtos.
@type  User Function
@author Claudio Bozi
@since 26/03/2025
@version 1.0
/*/
User Function xdpr001a()

	Local aArea   := GetArea()

    Private aCpoInfo  := {}
    Private aCampos   := {}
    Private aCpoData  := {}
    Private oTable    := Nil
    Private oBrowse   := Nil
    Private aRotBKP   := {}

	Private cNum   	As Character 

    Private _cAlias := 'TEMP1'
	Private aTexto  := {}
	Private nQuant  := 0
	Private nCaixas := 0
	Private nResto  := 0
	Private cEnter  := Chr(13) + Chr(10)

    FwMsgRun(,{ || fLoadData() }, "Lista de Prioridades", 'Carregando dados...')

    oBrowse := FwMBrowse():New()

    oBrowse:SetAlias('TRB')
    oBrowse:SetTemporary(.T.)

	oBrowse:AddMarkColumns(;
							{|| If(TRB->TMP_OK = "S", "LBOK", "LBNO")},;
							{|| SelectOne(oBrowse)             },;
							{|| SelectAll(oBrowse)             };
	)

	oBrowse:AddLegend("TMP_XSTATU == '02'", "GREEN" , "Produto Priorizado"    ,,.F.)
	oBrowse:AddLegend("TMP_XSTATU <> '02'", "RED"   , "Produto não Priorizado",,.F.)

    oBrowse:SetColumns(aCampos)

	oBrowse:SetEditCell( .T. ) 			// indica que o grid é editavel

	oBrowse:acolumns[7]:ledit    := .T. // informa qual coluna é editável
	oBrowse:acolumns[7]:cReadVar := 'TMP_XPRIOR'

	oBrowse:AddButton("Confirmar"	,"u_xdpr001b()",,3,1)

    oBrowse:SetMenuDef('custom.xdpr001')

    oBrowse:SetDescription('Lista de prioridades')
    
	oBrowse:Activate()

    If(Type('oTable') <> 'U')
        oTable:Delete()
        oTable := Nil
    Endif

	RestArea(aArea)

Return

/*/{Protheus.doc} fLoadData
Rotina para inserir dados da tabela temporaria do MarkBrowse
@author Claudio Bozzi
@since 01/02/2023
@version 1.0
/*/
Static Function fLoadData()

    Local nI      := 0

    If(Type('oTable') <> 'U')
        oTable:Delete()
        oTable := Nil
    Endif

    oTable := FwTemporaryTable():New('TRB')

    aCampos  := {}
    aCpoInfo := {}
    aCpoData := {}

    aAdd(aCpoInfo, {'Marcar'  		, '@!' 						, 1							})
    aAdd(aCpoInfo, {'Prod Desenv'	, '@!' 						, TamSx3('DG3_CDACDV')[1]	})
    aAdd(aCpoInfo, {'Desc Desenv'   , '@!' 						, TamSx3('DG3_DSACDV')[1]	})
    aAdd(aCpoInfo, {'ID Fluig' 		, '@!' 						, TamSx3('DG3_XIDFLG')[1]	})
    aAdd(aCpoInfo, {'Status'	    , '@!'	                    , TamSx3('DG3_XSTATU')[1]	})
    aAdd(aCpoInfo, {'Prioridade'	, '99' 						, TamSx3('DG3_XPRIOR')[1]	})
    aAdd(aCpoInfo, {'recno'         , '@E 9999999999999'		, 13 	                    })

    aAdd(aCpoData, {'TMP_OK'      , 'C'                         , 1                       	, 0	})
    aAdd(aCpoData, {'TMP_CDACDV'  , TamSx3('DG3_CDACDV')[3] 	, TamSx3('DG3_CDACDV')[1] 	, 0	})
    aAdd(aCpoData, {'TMP_DSACDV'  , TamSx3('DG3_DSACDV')[3] 	, TamSx3('DG3_DSACDV')[1] 	, 0	})
    aAdd(aCpoData, {'TMP_XIDFLG'  , TamSx3('DG3_XIDFLG')[3] 	, TamSx3('DG3_XIDFLG')[1] 	, 0	})
    aAdd(aCpoData, {'TMP_XSTATU'  , TamSx3('DG3_XSTATU')[3]     , TamSx3('DG3_XSTATU')[1] 	, 0	})
    aAdd(aCpoData, {'TMP_XPRIOR'  , TamSx3('DG3_XPRIOR')[3] 	, TamSx3('DG3_XPRIOR')[1] 	, 0	})
    aAdd(aCpoData, {'TMP_RECNO'   , 'N'                         , 13   	                    , 0 })

    For nI := 1 To Len(aCpoData)

        If(aCpoData[nI, 1] <> 'TMP_OK' .and. aCpoData[nI, 1] <> 'TMP_RECNO')

            aAdd(aCampos, FwBrwColumn():New())

            aCampos[Len(aCampos)]:SetData( &('{||' + aCpoData[nI,1] + '}') )
            aCampos[Len(aCampos)]:SetTitle(aCpoInfo[nI,1])
            aCampos[Len(aCampos)]:SetPicture(aCpoInfo[nI,2])
            aCampos[Len(aCampos)]:SetSize(aCpoData[nI,3])
            aCampos[Len(aCampos)]:SetDecimal(aCpoData[nI,4])
            aCampos[Len(aCampos)]:SetAlign(aCpoInfo[nI,3])

        EndIf

    next

    oTable:SetFields(aCpoData)
    oTable:Create()

	If select (_cAlias) > 0
		(_cAlias)->(DbCloseArea())
	EndIf

    BeginSql Alias _cAlias

        SELECT DG3_CDACDV, DG3_DSACDV, DG3_XIDFLG, DG3_XSTATU, DG3_XPRIOR, R_E_C_N_O_ AS RECNO
          FROM %TABLE:DG3% DG3
         WHERE DG3.DG3_FILIAL  = %xFilial:DG3%
           AND DG3.DG3_XSTATU  <> '09'
           AND DG3.%NOTDEL%
   	     ORDER BY DG3_XPRIOR
    EndSQL

    (_cAlias)->(DbGoTop())

    DbSelectArea('TRB')

    While(!(_cAlias)->(EoF()))

        RecLock('TRB', .T.)

            TRB->TMP_OK 	    := 'N'
			TRB->TMP_CDACDV  	:= (_cAlias)->DG3_CDACDV
            TRB->TMP_DSACDV 	:= (_cAlias)->DG3_DSACDV
            TRB->TMP_XIDFLG  	:= (_cAlias)->DG3_XIDFLG
			TRB->TMP_XSTATU 	:= (_cAlias)->DG3_XSTATU
            TRB->TMP_XPRIOR     := (_cAlias)->DG3_XPRIOR
            TRB->TMP_RECNO      := (_cAlias)->RECNO

        TRB->(MsUnlock())

        (_cAlias)->(DbSkip())

    EndDo

    TRB->(DbGoTop())

Return

Static Function SelectOne(oBrowse)

    Local aArea  := TRB->(GetArea())
    Local cMarca := "N"

    cMarca := IIF(TRB->TMP_OK = "S", "N", "S")

	RecLock("TRB", .F.)
		TRB->TMP_OK := cMarca
	TRB->(MsUnlock())

    RestArea(aArea)

    oBrowse:Refresh()

    FWFreeVar(@aArea)
    FWFreeVar(@cMarca)

Return .T.
 
Static Function SelectAll(oBrowse)
	
    Local aArea  := TRB->(GetArea())
    Local cMarca := "N"
    
    TRB->(DBGoTop())
    
    cMarca := IIF(TRB->TMP_OK = "S", "N", "S")
    
    While TRB->(!Eof())

		RecLock("TRB", .F.)
			TRB->TMP_OK := cMarca
		TRB->(MsUnlock())

		TRB->(DBSkip())
    End

    RestArea(aArea)

    oBrowse:Refresh()

    FWFreeVar(@aArea)
    FWFreeVar(@cMarca)

Return

/*/{Protheus.doc} nomeFunction
Gravar listade prioridades
@type user function
@author user
@since 29/03/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function xdpr001b()

    TRB->(DBGoTop())

	Do While ! TRB->(Eof())

        If TRB->TMP_OK = 'S'

            dbSelectArea("DG3")
            DG3->(dbGoTo(TRB->TMP_RECNO))
            
            RecLock("DG3",.F.)
                DG3->DG3_XSTATU := '02'
                DG3->DG3_XPRIOR := TRB->TMP_XPRIOR
            MsUnLock()
            
            DG3->(dbCloseArea())

        EndIf

        TRB->(DbSkip())

    EndDo

    FwMsgRun(,{ || fLoadData() }, "Lista de Prioridades", 'Carregando dados...')

    oBrowse:GoTop(.T.)
    oBrowse:Refresh()

Return
