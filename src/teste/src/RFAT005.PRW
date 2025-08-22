#INCLUDE "PROTHEUS.CH"

Static nPagina := 0

/*/{Protheus.doc} RFAT005
	Relatório do pedido complementar
	@type function
	@author Ademar Fernandes Jr.
	@since 30/10/2021
/*/
User Function RFAT005()
Local oReport	 := Nil
Local aPDFields	 := {}

If FindFunction("TRepInUse") .And. TRepInUse()
	//-- Interface de impressao
	aFieldsPD := {"A1_NOME","A1_MUN"}
	//Inicializa variaveis com lista de campos que devem ser ofuscados de acordo com usuario.
	FATPDLoad(Nil,Nil,aPDFields)     

	nPagina := 0
	oReport := ReportDef()
	oReport:PrintDialog()

	//Finaliza o gerenciamento dos campos com proteção de dados.
	FATPDUnLoad()
	ASize(aFieldsPD, 0)
EndIf
Return Nil


/*/{Protheus.doc} ReportDef
	A funcao estatica ReportDef devera ser criada para todos os relatorios que poderao ser agendados pelo usuario. 
	@type function
	@author Ademar Fernandes Jr.
	@since 30/10/2021
/*/
Static Function ReportDef()

Local oReport
Local oProduto
Local cAlias	:= GetNextAlias()
Local cPerg		:= "RFAT005"	//-"XMTR610"

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Criacao do componente de impressao                                      ³
//³TReport():New                                                           ³
//³ExpC1 : Nome do relatorio                                               ³
//³ExpC2 : Titulo                                                          ³
//³ExpC3 : Pergunte                                                        ³
//³ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao  ³
//³ExpC5 : Descricao                                                       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oReport := TReport():New("RFAT005","Pedidos Complementares",cPerg,{|oReport| ReportPrint(oReport,cAlias,oProduto)},"Relatório para controle dos pedidos complementares")
oReport:SetLandscape()
oReport:SetTotalInLine(.F.)

Pergunte(cPerg,.F.)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Criacao da secao utilizada pelo relatorio                               ³
//³TRSection():New                                                         ³
//³ExpO1 : Objeto TReport que a secao pertence                             ³
//³ExpC2 : Descricao da seçao                                              ³
//³ExpA3 : Array com as tabelas utilizadas pela secao. A primeira tabela   ³
//³        sera considerada como principal para a seção.                   ³
//³ExpA4 : Array com as Ordens do relatório                                ³
//³ExpL5 : Carrega campos do SX3 como celulas                              ³
//³        Default : False                                                 ³
//³ExpL6 : Carrega ordens do Sindex                                        ³
//³        Default : False                                                 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Criacao da celulas da secao do relatorio                                ³
//³TRCell():New                                                            ³
//³ExpO1 : Objeto TSection que a secao pertence                            ³
//³ExpC2 : Nome da celula do relatório. O SX3 será consultado              ³
//³ExpC3 : Nome da tabela de referencia da celula                          ³
//³ExpC4 : Titulo da celula                                                ³
//³        Default : X3Titulo()                                            ³
//³ExpC5 : Picture                                                         ³
//³        Default : X3_PICTURE                                            ³
//³ExpC6 : Tamanho                                                         ³
//³        Default : X3_TAMANHO                                            ³
//³ExpL7 : Informe se o tamanho esta em pixel                              ³
//³        Default : False                                                 ³
//³ExpB8 : Bloco de código para impressao.                                 ³
//³        Default : ExpC2                                                 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oClienteID := TRSection():New(oReport,"ID/Cliente",{"Z05","SA1"},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
oClienteID:lPrintHeader := .F.
oReport:OnPageBreak({ || (	nPagina ++, oReport:Section(1):lPrintHeader := .T.,;
							If(nPagina > 1, PrtCabec(oReport), Nil), oReport:Section(1):lPrintHeader := .F.) })

TRCell():New(oClienteID,"Z05ID"		,cAlias,"Cod.ID"				,/*Picture*/,/*Tamanho*/			,/*lPixel*/,{|| Z05_ID })
TRCell():New(oClienteID,"Z05DATA"	,cAlias,"Data"					,/*Picture*/,TamSx3("Z05_DATA")[1]+2,/*lPixel*/,{|| Z05_DATA })
TRCell():New(oClienteID,"CLIENTE"	,cAlias,"Cod.Cliente"			,/*Picture*/,/*Tamanho*/			,/*lPixel*/,{|| Z05_CLIENT })
TRCell():New(oClienteID,"LOJACLI"	,cAlias,"Loja"					,/*Picture*/,/*Tamanho*/			,/*lPixel*/,{|| Z05_LOJA })
TRCell():New(oClienteID,"NOMECLI"	,"    ",RetTitle("A1_NREDUZ")	,/*Picture*/,30			,/*lPixel*/,{|| cNomCli:=SA1->A1_NREDUZ,Substr(FATPDObfuscate(cNomCli,"A1_NOME"),1,30) })
TRCell():New(oClienteID,"ESTADO"	,"    ","Estado"				,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| SA1->A1_EST })
TRCell():New(oClienteID,"PESOTOTID"	,"    ","Peso 1"			,PesqPictQt("Z05_PESO1",16),/*Tamanho*/,/*lPixel*/,{|| Z05_PESO1 })
TRCell():New(oClienteID,"PESO2"	,"    ","Peso 2"			,PesqPictQt("Z05_PESO2",16),/*Tamanho*/,/*lPixel*/,{|| (Z05_PESO2) })
TRCell():New(oClienteID,"PESO3"	,"    ","Peso 3"			,PesqPictQt("Z05_PESO3",16),/*Tamanho*/,/*lPixel*/,{|| (Z05_PESO3) })
TRCell():New(oClienteID,"DIFPES","    ","Dif Peso"			,PesqPictQt("Z05_DIFPES",16),/*Tamanho*/,/*lPixel*/,{|| (Z05_DIFPES) })
TRCell():New(oClienteID,"Z05_STATUS",cAlias,"Status   ",/*Picture*/								,9,/*lPixel*/,{|| If(Z05_STATUS == "2", "Encerrado", "Aberto") })
TRCell():New(oClienteID,"Z05_FILSC5","    ","Fil Ped"			,PesqPict("Z05","Z05_FILSC5"),/*Tamanho*/,/*lPixel*/,{|| Z05_FILSC5 })
TRCell():New(oClienteID,"Z05_NUMSC5","    ","Ped Complementar"			,PesqPict("Z05","Z05_NUMSC5"),/*Tamanho*/,/*lPixel*/,{|| Z05_NUMSC5 })
TRCell():New(oClienteID,"Z05_NUMNF","    ","Nf Complementar"			,PesqPict("SF2","F2_DOC"),/*Tamanho*/,/*lPixel*/,{|| Z05_NUMNF })

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Secao Itens                            	    			       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oProduto := TRSection():New(oClienteID,"Itens",{"Z06","SC6"},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/)
oProduto:lPrintHeader := .F.
oProduto:SetHeaderSection(.F.)
oProduto:SetHeaderBreak(.F.) 
oProduto:lHeaderPage:=.F. 

TRCell():New(oProduto,"Z06_NUMSC5"	,cAlias,RetTitle("Z06_NUMSC5"),PesqPict("Z06","Z06_NUMSC5")	,TamSx3("Z06_NUMSC5")[1]	,/*lPixel*/,{|| Z06_NUMSC5 })
TRCell():New(oProduto,"Z06_ITMSC5"	,cAlias,RetTitle("Z06_ITMSC5"),PesqPict("Z06","Z06_ITMSC5")	,TamSx3("Z06_ITMSC5")[1]	,/*lPixel*/,{|| Z06_ITMSC5 })
TRCell():New(oProduto,"C6_NOTA"		,cAlias,RetTitle("C6_NOTA"),PesqPict("SC6","C6_NOTA")	,TamSx3("C6_NOTA")[1]	,/*lPixel*/,{|| C6_NOTA })
TRCell():New(oProduto,"C6_PRODUTO"	,cAlias,RetTitle("C6_PRODUTO"),PesqPict("SC6","C6_PRODUTO")			,TamSx3("C6_PRODUTO")[1]	,/*lPixel*/,{|| C6_PRODUTO })
TRCell():New(oProduto,"C6_LOCAL"	,cAlias,RetTitle("C6_LOCAL"),PesqPict("SC6","C6_LOCAL")			,TamSx3("C6_LOCAL")[1]	,/*lPixel*/,{|| C6_LOCAL })
TRCell():New(oProduto,"C6_DESCRI"	,cAlias,RetTitle("C6_DESCRI"),PesqPict("SC6","C6_DESCRI")		,TamSx3("C6_DESCRI")[1]	,/*lPixel*/,{|| C6_DESCRI })
TRCell():New(oProduto,"C6_UM"		,cAlias,RetTitle("C6_UM"),/*Picture*/						,/*Tamanho*/			,/*lPixel*/,{|| C6_UM })
TRCell():New(oProduto,"C6_QTDVEN"	,cAlias,RetTitle("C6_QTDVEN"),PesqPictQt("C6_QTDVEN",16)	,TamSx3("C6_QTDVEN")[1]	,/*lPixel*/,{|| C6_QTDVEN },,,"RIGHT")
TRCell():New(oProduto,"C6_PRCVEN"	,cAlias,RetTitle("C6_PRCVEN"),PesqPictQt("C6_PRCVEN",16)	,TamSx3("C6_PRCVEN")[1]	,/*lPixel*/,{|| C6_PRCVEN },,,"RIGHT")
TRCell():New(oProduto,"C6_VALOR"	,cAlias,RetTitle("C6_VALOR"),PesqPict("SC6","C6_VALOR",16)	,TamSx3("C6_VALOR")[1]	,/*lPixel*/,{|| C6_VALOR },,,"RIGHT")
TRCell():New(oProduto,"C6_TES"		,cAlias,"TES"	,/*Picture*/								,/*Tamanho*/			,/*lPixel*/,{|| C6_TES })
TRCell():New(oProduto,"Z06_PESO1"	,cAlias,"PESO 1",/*Picture*/								,TamSx3("Z06_PESO1")[1]	,/*lPixel*/,{|| Z06_PESO1 })
TRCell():New(oProduto,"Z06_PESO2"	,cAlias,"PESO 2",/*Picture*/								,TamSx3("Z06_PESO2")[1]	,/*lPixel*/,{|| Z06_PESO2 })
TRCell():New(oProduto,"Z06_PESO3"	,cAlias,"PESO 3",/*Picture*/								,TamSx3("Z06_PESO3")[1]	,/*lPixel*/,{|| Z06_PESO3 })
TRCell():New(oProduto,"Z06_DIFPES"	,cAlias,"Dif Peso",/*Picture*/								,TamSx3("Z06_DIFPES")[1]	,/*lPixel*/,{|| Z06_DIFPES })
TRCell():New(oProduto,"Z06_DIFPER"	,cAlias,"% Dif",/*Picture*/									,TamSx3("Z06_DIFPER")[1]	,/*lPixel*/,{|| Z06_DIFPER })

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Impressao do Cabecalho no topo da pagina                               ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oReport:Section(1):Setedit(.T.)
oReport:Section(1):Section(1):Setedit(.T.)
Return(oReport)


/*/{Protheus.doc} ReportPrint
	A funcao estatica ReportDef devera ser criada para todos os relatorios que poderao ser agendados pelo usuario.
	@type function
	@author Ademar Fernandes Jr.
	@since 30/10/2021
	@param oReport, object, param_description
	@param cAlias, character, param_description
	@param oProduto, object, param_description
	@return variant, return_description
/*/
Static Function ReportPrint(oReport,cAlias,oProduto)

Local cIdNum	:= ""
Local cWhere	:= ""

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Transforma parametros Range em expressao SQL                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
MakeSqlExpr(oReport:uParam)

dbSelectArea("SC5")		// Pedido de Vendas
dbSetOrder(2)			// DT Emissao + Numero
dbSelectArea("SC6")		// Itens do Pedido de Vendas
dbSetOrder(1)			// Num. Pedido + Item + Produto
dbSelectArea("Z05")		// Pesagem de Clientes
dbSetOrder(1)			// ID Sequencial
dbSelectArea("Z06")		// Itens da Pesagem de Clientes
dbSetOrder(1)			// ID Sequencial

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Transforma parametros Range em expressao SQL                            ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
MakeSqlExpr(oReport:uParam)	

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Query do relatório da secao 1                                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oReport:Section(1):BeginQuery()

// Considera as filiais abaixo?
if MV_PAR01 == 1
	cFilPVde  := MV_PAR02
	cFilPVate := MV_PAR03
else
	cFilPVde  := Space(Len(Z05->Z05_FILIAL))
	cFilPVate := Replicate("Z", Len(Z05->Z05_FILIAL))
endif

// Considera o Status 
if MV_PAR14 == 1
	cWhere := "('1') "
elseif MV_PAR14 == 2
	cWhere := "('2') "
else
	cWhere := "(' ','1','2') "
EndIf
cWhere := "%" + cWhere + "%"

BEGIN REPORT QUERY oProduto
	BeginSql Alias cAlias
		SELECT Z05_ID, Z05_DATA, Z05_STATUS, Z05_CLIENT, Z05_LOJA, Z05_PESO1, Z05_PESO2, Z05_PESO3, Z05_DIFPES,Z05_FILSC5,Z05_NUMSC5,
		       (SELECT MAX(C6_NOTA) FROM %Table:SC6% WHERE C6_FILIAL = Z05_FILSC5 AND C6_NUM = Z05_NUMSC5 
			       AND D_E_L_E_T_ = ' ') AS Z05_NUMNF,
			   Z06_NUMSC5,Z06_ITMSC5,C6_NOTA,C6_PRODUTO,C6_LOCAL,C6_DESCRI,C6_UM,C6_QTDVEN,C6_PRCVEN,C6_VALOR,C6_TES,
			   Z06_PESO1,Z06_PESO2,Z06_PESO3,Z06_DIFPES,Z06_DIFPER
		  FROM %Table:Z05% Z05
		  JOIN %Table:Z06% Z06 ON Z05_FILIAL = Z05_FILIAL AND Z06_ID = Z05_ID AND Z06.D_E_L_E_T_ = ' ' 
		  JOIN %Table:SC6% SC6 ON C6_FILIAL = Z06_FILPED AND C6_FILIAL BETWEEN %Exp:cFilPVde% AND %Exp:cFilPVate%
		   AND C6_NUM = Z06_NUMSC5 AND C6_ITEM = Z06_ITMSC5 AND C6_PRODUTO BETWEEN %Exp:MV_PAR04% AND %Exp:MV_PAR05%
		   AND C6_NOTA BETWEEN %Exp:MV_PAR10% AND %Exp:MV_PAR11% AND C6_LOCAL BETWEEN %Exp:MV_PAR15% AND %Exp:MV_PAR16% 
		   AND SC6.D_E_L_E_T_ = ' ' 
		 WHERE Z05_FILIAL = %Exp:xFilial("Z05")% AND Z05_STATUS IN %Exp:cWhere% 
		   AND Z05_DATA BETWEEN %Exp:MV_PAR12% AND %Exp:MV_PAR13%
		   AND Z05_CLIENT BETWEEN %Exp:MV_PAR06% AND %Exp:MV_PAR07%
		   AND Z05_LOJA	 BETWEEN %Exp:MV_PAR08% AND %Exp:MV_PAR09%
		   AND Z05.D_E_L_E_T_ = ' '
		 ORDER BY Z05_ID, C6_FILIAL, C6_NUM, C6_ITEM
	EndSql 
	// GetLastQuery()[2]
END REPORT QUERY oProduto

nTreg := len(GetLastQuery()[3])

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Metodo EndQuery ( Classe TRSection )                                    ³
//³Prepara o relatório para executar o Embedded SQL.                       ³
//³ExpA1 : Array com os parametros do tipo Range                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oReport:Section(1):EndQuery()

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Metodo TrPosition()                                                     ³
//³Posiciona em um registro de uma outra tabela. O posicionamento será     ³
//³realizado antes da impressao de cada linha do relatório.                ³
//³ExpO1 : Objeto Report da Secao                                          ³
//³ExpC2 : Alias da Tabela                                                 ³
//³ExpX3 : Ordem ou NickName de pesquisa                                   ³
//³ExpX4 : String ou Bloco de código para pesquisa. A string será macroexe-³
//³        cutada.                                                         ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
TRPosition():New(oReport:Section(1):Section(1),"SA1",1,{|| xFilial("SA1")+(cAlias)->Z05_CLIENT+(cAlias)->Z05_LOJA })

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Inicio da impressao do fluxo do relatório                               ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
dbSelectArea(cAlias)
dbGoTop()

lCab := .F.
oReport:SetMeter(nTreg)
While !oReport:Cancel() .And. !&(cAlias)->(Eof())
	
	If cIdNum != &(cAlias)->(Z05_ID)
		cIdNum := &(cAlias)->(Z05_ID)

		PrtCabec(oReport)
	EndIf

	dbSelectArea(cAlias)
	oReport:Section(1):Section(1):Init(.F.)
	oReport:Section(1):Section(1):PrintLine()
	
	dbSelectArea(cAlias)
	dbSkip()
EndDo

Return

Static Function PrtCabec(oReport)

	oReport:Section(1):Init()
	oReport:Section(1):PrintLine()
	oReport:Section(1):Finish()

	oReport:SkipLine()
	oReport:Section(1):Section(1):SetHeaderSection(.T.)
	oReport:Section(1):Section(1):PrintHeader()
	oReport:Section(1):Section(1):SetHeaderSection(.F.)

Return

/*/{Protheus.doc} FATPDLoad
    Inicializa variaveis com lista de campos que devem ser ofuscados de acordo com usuario.
	Remover essa função quando não houver releases menor que 12.1.27
    @type  function
    @author Squad CRM & Faturamento
    @since 30/10/2021
    @version P12.1.27
    @param cUser, Caractere, Nome do usuário utilizado para validar se possui acesso ao 
        dados protegido.
    @param aAlias, Array, Array com todos os Alias que serão verificados.
    @param aFields, Array, Array com todos os Campos que serão verificados, utilizado 
        apenas se parametro aAlias estiver vazio.
    @param cSource, Caractere, Nome do recurso para gerenciar os dados protegidos.
    @return cSource, Caractere, Retorna nome do recurso que foi adicionado na pilha.
    @example FATPDLoad("ADMIN", {"SA1","SU5"}, {"A1_CGC"})
/*/
Static Function FATPDLoad(cUser, aAlias, aFields, cSource)
	Local cPDSource := ""

	If FATPDActive()
		cPDSource := FTPDLoad(cUser, aAlias, aFields, cSource)
	EndIf
Return cPDSource

/*/{Protheus.doc} FATPDUnload
    Finaliza o gerenciamento dos campos com proteção de dados.
	Remover essa função quando não houver releases menor que 12.1.27
    @type  function
    @author Squad CRM & Faturamento
    @since 30/10/2021
    @version P12.1.27
    @param cSource, Caractere, Remove da pilha apenas o recurso que foi carregado.
    @return return, Nulo
    @example FATPDUnload("XXXA010") 
/*/
Static Function FATPDUnload(cSource)    
    If FATPDActive()
		FTPDUnload(cSource)    
    EndIf
Return Nil

/*/{Protheus.doc} FATPDObfuscate
    Realiza ofuscamento de uma variavel ou de um campo protegido.
	Remover essa função quando não houver releases menor que 12.1.27
    @type  function
    @sample FATPDObfuscate("999999999","U5_CEL")
    @author Squad CRM & Faturamento
    @since 30/10/2021
    @version P12.1.27
    @param xValue, (caracter,numerico,data), Valor que sera ofuscado.
    @param cField, caracter , Campo que sera verificado.
    @param cSource, Caractere, Nome do recurso que buscar dados protegidos.
    @param lLoad, Logico, Efetua a carga automatica do campo informado
    @return xValue, retorna o valor ofuscado.
/*/
Static Function FATPDObfuscate(xValue, cField, cSource, lLoad)
    If FATPDActive()
		xValue := FTPDObfuscate(xValue, cField, cSource, lLoad)
    EndIf
Return xValue   

/*/{Protheus.doc} FATPDActive
    Função que verifica se a melhoria de Dados Protegidos existe.
    @type  function
    @sample FATPDActive()
    @author Squad CRM & Faturamento
    @since 30/10/2021
    @version P12.1.27
    @return lRet, Logico, Indica se o sistema trabalha com Dados Protegidos
/*/
Static Function FATPDActive()
    Static _lFTPDActive := Nil
    If _lFTPDActive == Nil
        _lFTPDActive := ( GetRpoRelease() >= "12.1.027" .Or. !Empty(GetApoInfo("FATCRMPD.PRW")) )  
    Endif
Return _lFTPDActive 
