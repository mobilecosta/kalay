#Include 'parmtype.ch'
#Include 'RestFul.CH' 
#Include 'tbiconn.ch'
#Include "TopConn.ch"
#Include "TOTVS.CH"

#Define STR_PULA chr(13)+Chr(10)

WSRESTFUL WS_Consultas DESCRIPTION "Serviço REST para execução de query B"

    WSDATA _cAlias      As String //Alias da tabela
    WSDATA _cCampos     As String //Campos separados por virgula
    WSDATA _cWhere      As String //Campos separados por virgula
    WSDATA EMPRESA      As String //Campos separados por virgula
    WSDATA FILIAL       As String //Campos separados por virgula

    WSMETHOD GET DESCRIPTION "Retorna dados da consulta enviada" WSSYNTAX "/_cAlias,_cCampos,_cWhere"

END WSRESTFUL

WSMETHOD GET WSRECEIVE _cAlias,_cCampos,_cWhere WSSERVICE WS_Consultas

    Local aReturn   := {} 
    Local _cAlias   := cValtoChar(Self:_cAlias)
    Local _cCampos  := cValtoChar(Self:_cCampos)
    Local _cWhere   := cValtoChar(Self:_cWhere)
    Local aCab      := StrTokArr2( _cCampos, ",",.F.) //Titulo dos campos
    Local aCabAux   := {}
    Local nY        := 0

    default Self:empresa  := "01"
    default Self:filial   := "0101001"

	rpcSetType(3) //Informa que não haverá consumo de licenças
    rpcSetEnv(Self:empresa, Self:filial)   

    // define o tipo de retorno do método
	Self:SetContentType("application/json")

    //Executando a query
    aReturn := Consulta_SQL(_cAlias, _cCampos,aCab,_cWhere)

    IF LEN(aReturn) > 0
        
        For nY:= 1 to Len(aCab)            
            
            cCampo := aCab[nY]

            //TRATATIVA ESPECIAL PARA PEGAR DADOS DO CAMPO MEMO
            //ENVIAR ASSIM: CAST(CAST(A1_XTESTE AS VARBINARY(8000)) AS VARCHAR(8000)) AS A1_XTESTE 
            If At("CAST(CAST(", cCampo) > 0
                cCampo := SubStr(cCampo, At("CAST(CAST(", cCampo) + Len("CAST(CAST("))
                cCampo := SubStr(cCampo, 1, At(" AS", cCampo) - 1)
                cCampo := Alltrim(cCampo)
            EndIf 
               
            AADD(aCabAux,cCampo) 
        Next

        //Chama a funcao para gerar o JSON.
        cRet   := EncodeUTF8(JSON( { "Consulta" , aCabAux, aReturn}))

    Else
    
        Self:SetResponse('{"Retorno Protheus":')
		Self:SetResponse('[')
        Self:SetResponse('"Nao Existe dados para essa consulta!"]')
	    Self:SetResponse('}')

        Return(.T.)
    EndIf

    Self:SetResponse(cRet)

   RESET ENVIRONMENT

Return(.T.)

Static Function Consulta_SQL(_cAlias, _cCampos,aCab,_cWhere)

    Local cQuery    := ""
    Local cQRY      := ""
    Local aQuery    := {}
    Local aResult   := {}
    //Local aCab2     := aCab
    Local cCpoFil   := PrefixoCpo(_cAlias)+"_FILIAL"
    Local nX        := 0

     _cWhere := StrTran(_cWhere,"%20"," " )

    //Montando a Consulta
    cQuery := " SELECT "                           + STR_PULA
    cQuery += _cCampos                             + STR_PULA
    cQuery += " FROM"+" "+RetSQLName(_cAlias)      + STR_PULA
    cQuery += " WHERE "                            + STR_PULA
    cQuery += cCpoFil+"='"+xFilial(_cAlias)+"' "   + STR_PULA
    cQuery += "AND D_E_L_E_T_ = ' '"               + STR_PULA
    cQuery  += _cWhere                             + STR_PULA

    //Executando consulta
    cQuery := ChangeQuery(cQuery)
	cQRY := MPSysOpenQuery(cQuery)

	ConOut( PadC( "WS_CONSULTAS - Query", 30 ) )
	ConOut( Replicate( "-", 30 ) )
	ConOut( cValToChar(cQuery) )
	ConOut( Replicate( "-", 30 ) )
    conout("Empresa:"+cEmpAnt)
    conout("Filial:"+cFilAnt)

    //Percorrendo os registros
    While ! (cQRY)->(EoF())
        aQuery := {}
        For nX:= 1 to Len(aCab)            
            
            cCampo := aCab[nX]

			//TRATATIVA ESPECIAL PARA PEGAR DADOS DO CAMPO MEMO
            //ENVIAR ASSIM: CAST(CAST(A1_XTESTE AS VARBINARY(8000)) AS VARCHAR(8000)) AS A1_XTESTE
            If At("CAST(CAST(", cCampo) > 0
                cCampo := SubStr(cCampo, At("CAST(CAST(", cCampo) + Len("CAST(CAST("))
                cCampo := SubStr(cCampo, 1, At(" AS", cCampo) - 1)
                cCampo := Alltrim(cCampo)
            EndIf
                        
            prod := ALLTRIM(cValtoChar((cQRY)->&(cCampo))) 
            prod  := REPLACE(prod , '"', '')
            prod  := FwCutOff(prod,.T.)
               
            AADD(aQuery,REPLACE(prod , '\', '')) 
        Next
        AADD(aResult,aQuery)
        (cQRY)->(dbSkip())
    EndDo
    (cQRY)->(DbCloseArea())

Return aResult

/* {Protheus.doc}
//TODO (PT-BR) metodo que cria e formara um Json
*/
Static function JSON(aGeraXML)
   
    Local cJSON  := ""
    Local aCab   := aGeraXML[2]
    Local aLin   := aGeraXML[3]
    Local L      := 0
    Local C      := 0

    cJSON += '['

    FOR L:= 1 TO LEN( aLin )

        cJSON += '{'

        for C:= 1 to Len( aCab )

            IF VALTYPE(aLin[L][C]) = "C"
                If aCab[C] == "ObjectIn"
                    cConteudo := VldObj(aLin[L][C])
                ElseIf aCab[C] == "ObjectOut"
                    cConteudo := VldObj(aLin[L][C])
                ELSE
                    cConteudo := '"'+aLin[L][C]+'" '
                EndIf
            ELSEIF VALTYPE(aLin[L][C]) = "N"
                cConteudo := ALLTRIM(STR(aLin[L][C]))
            ELSEIF VALTYPE(aLin[L][C]) = "D"
                cConteudo := '"'+DTOC(aLin[L][C])+'"'
            ELSEIF VALTYPE(aLin[L][C]) = "L"
                cConteudo := IF(aLin[L][C], 'true' , 'false')
            ELSE
                cConteudo := '"'+aLin[L][C]+'"'
            ENDIF

            cJSON += '"'+aCab[C]+'":' + cConteudo

            IF C < LEN(aCab)
            cJSON += ','
            ENDIF

        Next
        cJSON += '}'
        IF L < LEN(aLin)
        cJSON += ','
        Else
        cJSON += ']'
        ENDIF

    Next

Return cJSON
