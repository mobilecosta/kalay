#INCLUDE 'TOTVS.CH'

Static aSX3SE3 := Nil

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para calculo da comissão por motorista
@author  	Wagner Mobile Costa
@version 	P12
@since   	07/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT008()

Local cTime := ""                    

If ! Pergunte("AFAT008")
    Return .F.
EndIf

cTime := Time()

// Deletando Conteudo Anterior
MsAguarde({|| DelComissao() },;
            "Aguarde...","Deletando Comissões não pagas")

// Gerando Comissão
MsAguarde({|| GerComissao() },;
            "Aguarde...","Gerando Comissão")

MsgInfo("Processamento finalizado com sucesso ! Inicio em [" + cTime + "] e fim em [" + Time() + "] - Tempo Total: " + ElapTime(cTime, Time()))

Return

Static Function DelComissao

Local cQuery  := ""

cQuery := "DELETE FROM " + RetSQlName("SE3") + " "
cQuery +=  "WHERE E3_FILIAL = '" + xFilial("SE3") + "' "
cQuery +=    "AND E3_EMISSAO BETWEEN '" + Dtos(mv_par01) + "' AND '" + Dtos(mv_par02) + "' "
cQuery +=    "AND E3_XMOTOR  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "' "
cQuery +=    "AND E3_XMOTOR <> ' ' AND E3_DATA  = ' ' AND D_E_L_E_T_ = ' '"

nError := TCSQLEXEC(cQuery)
cError := TcSqlError()
If nError <> 0 .And. ! Empty(cError)
    ApMsgAlert(cError, "Erro")
EndIf

Return

Static Function GerComissao

// Selecionar cronogramas da competencia do fechamento
BeginSql alias "QRY"
    SELECT C6_FILIAL AS E3_FILIAL, 
           C6_NOTA as E3_NUM, F2_EMISSAO as E3_EMISSAO, F2_SERIE as E3_SERIE, F2_CLIENTE as E3_CODCLI, F2_LOJA as E3_LOJA,
           SUM(C6_XPESO2) * MIN(Z04_VLFRET) as E3_BASE, MIN(DA4_XCOMIS) as E3_PORC, 
         ((SUM(C6_XPESO2) * MIN(Z04_VLFRET)) * MIN(DA4_XCOMIS) / 100) as E3_COMIS,
           C6_NUM as E3_PEDIDO, C6_LOCAL as E3_SEQ, 
           C5_MOEDA, C5_CODMOT as E3_XMOTOR, SUM(C6_XPESO2) as E3_XPESO, MIN(Z04_VLFRET) as E3_XVLFRET
      FROM %table:SC6% SC6 
      JOIN %table:SC5% SC5 on C5_FILIAL = C6_FILIAL and C5_NUM = C6_NUM and C5_CODMOT <> ' ' and SC5.D_E_L_E_T_  = ' '
      JOIN %table:SF2% SF2 on F2_FILIAL = C6_FILIAL and F2_SERIE = C6_SERIE and F2_DOC = C6_NOTA 
       and F2_EMISSAO BETWEEN %exp:mv_par01% AND %exp:mv_par02% and SF2.D_E_L_E_T_  = ' '
      JOIN %table:Z04% Z04 on Z04_FILIAL = %xfilial:Z04% and Z04_CODCLI = C5_CLIENTE and Z04_LOJA = C5_LOJACLI 
       and Z04_LOCAL = C6_LOCAL AND Z04.D_E_L_E_T_ = ' '
      JOIN %table:DA4% DA4 on DA4_FILIAL = %xfilial:DA4% and DA4_COD = C5_CODMOT 
       and DA4_COD BETWEEN %exp:mv_par03% AND %exp:mv_par04% and DA4_XCOMIS > 0 and DA4.D_E_L_E_T_  = ' '
      LEFT JOIN %table:SE3% SE3 on E3_FILIAL = C6_FILIAL and E3_NUM = C6_NOTA AND E3_XMOTOR = C5_CODMOT AND E3_SEQ = C6_LOCAL 
       AND SE3.D_E_L_E_T_ = ' '
     WHERE SC6.C6_FILIAL = %xfilial:SC6% and C6_NOTA <> ' ' and C6_XPESO2 > 0 and SC6.D_E_L_E_T_ = ' ' AND SE3.E3_NUM IS NULL
     GROUP BY C6_FILIAL, C6_NOTA, C6_NUM, C6_LOCAL, C5_CODMOT, C5_MOEDA, F2_EMISSAO, F2_SERIE, F2_CLIENTE, F2_LOJA
EndSql
TcSetField("QRY","E3_EMISSAO","D",8,0)

While ! QRY->(EOF())
    GravaSE3("QRY")

    QRY->(DbSkip())
EndDo
QRY->(DbCloseArea())

Return

Static Function GravaSE3(cAlias)

Local nField      := 0
Local nFields     := 0
Local cField      := ""
Local cValue      := ""

If aSX3SE3 == Nil
    aSX3SE3 := FWSX3Util():GetAllFields("SE3" , .F. )
EndIf

DbSelectArea(cAlias)
nFields := FCount()
RecLock("SE3", .T.)
For nField := 1 To Len(aSX3SE3)
    cField := aSX3SE3[nField]
    
    If (cAlias)->(FieldPos( cField )) > 0
        cValue := &(cAlias + "->" + cField )
    ElseIf cField = "E3_MOEDA"
        cValue := StrZero(&(cAlias + "->C5_MOEDA"), 2)
    Else
        cValue := CriaVar(cField, .T.)
    EndIf

    &("SE3->" + cField )  := cValue
Next 
SE3->E3_VENCTO := mv_par05
SE3->E3_VEND := SuperGetMv("MV_VENDPAD")
MsUnLock()

Return

//-----------------------------------------------------------------------------
/*/ {Protheus.doc} 
Rotina para atualização da data da comissão
@author  	Wagner Mobile Costa
@version 	P12
@since   	07/11/2021
@Parametros:
/*/
//-----------------------------------------------------------------------------
User Function AFAT08DT()

Local cTime := ""

If ! Pergunte("AFAT008DT")
    Return .F.
EndIf

cTime := Time()

// Gerando Comissão
MsAguarde({|| UpdPagto() }, "Aguarde...","Atualizando Data do Pagamento")

MsgInfo("Processamento finalizado com sucesso ! Inicio em [" + cTime + "] e fim em [" + Time() + "] - Tempo Total: " + ElapTime(cTime, Time()))

Return

Static Function UpdPagto

Local cQuery  := ""

cQuery := "UPDATE " + RetSQlName("SE3") + " "
cQuery +=    "SET E3_DATA = " + if(mv_par05 = 1, " E3_VENCTO ", "'" + Dtos(mv_par06) + "'")
cQuery +=  "WHERE E3_FILIAL = '" + xFilial("SE3") + "' "
cQuery +=    "AND E3_EMISSAO BETWEEN '" + Dtos(mv_par01) + "' AND '" + Dtos(mv_par02) + "' "
cQuery +=    "AND E3_XMOTOR  BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "' "
cQuery +=    "AND D_E_L_E_T_ = ' '"

nError := TCSQLEXEC(cQuery)
cError := TcSqlError()
If nError <> 0 .And. ! Empty(cError)
    ApMsgAlert(cError, "Erro")
EndIf

Return
