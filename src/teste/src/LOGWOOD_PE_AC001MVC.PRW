#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

//-------------------------------------------------
/*/{Protheus.doc} AC001MVC
Ponto de entrada MVC para a rotina ACOM001.

@type function
@version 1.0
@author Lucas José Corrêa Chagas

@since 30/08/2021

@return variant, Retorno é o conteúdo da variável xRet
/*/
//-------------------------------------------------
User Function AC001MVC()

	Local aParam     As Array
	Local cIdPonto   as Character
	Local cIdModel   as Character
	Local cMsg       as Character
	Local lIsGrid    as Logical
	Local nLinha     as Numeric
	Local nQtdLinhas as Numeric
	Local oObj       as Object
	Local xRet       as Variant

	aParam := PARAMIXB
	xRet   := .T.

	If (aParam <> NIL)

		oObj       := aParam[1]
		cIdPonto   := aParam[2]
		cIdModel   := aParam[3]
		lIsGrid    := ( Len( aParam ) > 3 )
        cMsg       := ''
        nLinha     := 0
        nQtdLinhas := 0

		/*If lIsGrid
			nQtdLinhas := oObj:GetQtdLine()
			nLinha     := oObj:nLine
		EndIf*/

		do case
           /* case (cIdPonto == 'MODELPOS')
                cMsg := 'Chamada na validação total do modelo (MODELPOS).' + CRLF
                cMsg += 'ID ' + cIdModel + CRLF

                If !( xRet := ApMsgYesNo( cMsg + 'Continua ?' ) )
                    Help( ,, 'Help',, 'O MODELPOS retornou .F.', 1, 0 )
                EndIf

		    case (cIdPonto == 'FORMPOS')
                cMsg := 'Chamada na validação total do formulário (FORMPOS).' + CRLF
                cMsg += 'ID ' + cIdModel + CRLF

                If      cClasse == 'FWFORMGRID'
                    cMsg += 'É um FORMGRID com ' + Alltrim( Str( nQtdLinhas ) ) + ;
                        '     linha(s).' + CRLF
                    cMsg += 'Posicionado na linha ' + Alltrim( Str( nLinha     ) ) + CRLF
                ElseIf cClasse == 'FWFORMFIELD'
                    cMsg += 'É um FORMFIELD' + CRLF
                EndIf

                If !( xRet := ApMsgYesNo( cMsg + 'Continua ?' ) )
                    Help( ,, 'Help',, 'O FORMPOS retornou .F.', 1, 0 )
                EndIf

		    case (cIdPonto == 'FORMLINEPRE')
                If aParam[5] == 'DELETE'
                    cMsg := 'Chamada na pre validação da linha do formulário (FORMLINEPRE).' + CRLF
                    cMsg += 'Onde esta se tentando deletar uma linha' + CRLF
                    cMsg += 'É um FORMGRID com ' + Alltrim( Str( nQtdLinhas ) ) +;
                        ' linha(s).' + CRLF
                    cMsg += 'Posicionado na linha ' + Alltrim( Str( nLinha     ) ) +; CRLF
                    cMsg += 'ID ' + cIdModel + CRLF

                    If !( xRet := ApMsgYesNo( cMsg + 'Continua ?' ) )
                        Help( ,, 'Help',, 'O FORMLINEPRE retornou .F.', 1, 0 )
                    EndIf
                EndIf

		    case (cIdPonto == 'FORMLINEPOS')
                cMsg := 'Chamada na validação da linha do formulário (FORMLINEPOS).' +; CRLF
                cMsg += 'ID ' + cIdModel + CRLF
                cMsg += 'É um FORMGRID com ' + Alltrim( Str( nQtdLinhas ) ) + ;
                    ' linha(s).' + CRLF
                cMsg += 'Posicionado na linha ' + Alltrim( Str( nLinha     ) ) + CRLF

                If !( xRet := ApMsgYesNo( cMsg + 'Continua ?' ) )
                    Help( ,, 'Help',, 'O FORMLINEPOS retornou .F.', 1, 0 )
                EndIf

		    case (cIdPonto == 'MODELCOMMITTTS')
			    ApMsgInfo('Chamada apos a gravação total do modelo e dentro da transação (MODELCOMMITTTS).' + CRLF + 'ID ' + cIdModel )		    

		    case (cIdPonto == 'FORMCOMMITTTSPRE')

		    case (cIdPonto == 'FORMCOMMITTTSPOS')
			    ApMsgInfo('Chamada apos a gravação da tabela do formulário (FORMCOMMITTTSPOS).' + CRLF + 'ID ' + cIdModel)

		    case (cIdPonto == 'MODELCANCEL')
                cMsg := 'Chamada no Botão Cancelar (MODELCANCEL).' + CRLF + 'Deseja Realmente Sair ?'

                If !( xRet := ApMsgYesNo( cMsg ) )
                    Help( ,, 'Help',, 'O MODELCANCEL retornou .F.', 1, 0 )
                EndIf*/

            case (cIdPonto == 'MODELCOMMITNTTS')
			    if findFunction('U_ACOM0020')
                    FWMsgRun(, { || U_ACOM0020() }, cCadastro, "Alimentando banco de conhecimento. Aguarde..." )                    
                endif

		    case (cIdPonto == 'BUTTONBAR')
                xRet := {}

                if FindFunction('U_ACOM002')
                    aAdd( xRet, { 'Registro Peso Entrada', 'PENTRADA', { || U_ACOM002()      }, 'Registra Peso Entrada' } )
                    aAdd( xRet, { 'Registro Peso Saída'  , 'PSAIDA'  , { || U_ACOM002( .F. ) }, 'Registra Peso Saída'   } )
                endif
        endcase

	EndIf

Return xRet

Return