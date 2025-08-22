#include "TOTVS.ch"

/*/{Protheus.doc} User Function MTA650MNU
    Este ponto de entrada permite ao usuário adicionar novas opções ao menu principal da rotina. As novas opções devem ser adicionadas ao vetor "aRotina" utilizado por todas as rotinas do sistema para montagem do menu funcional. Abaixo segue a estrutura padrão deste vetor:
    
    Estrutura do vetor aRotina:
    [1]Nome a aparecer no cabecalho
    [2]Nome da Rotina associada
    [3]Reservado
    [4]Tipo de Transação a ser efetuada, podendo conter:
    1 - Pesquisa e Posiciona em um Banco de Dados
    2 - Simplesmente Mostra os Campos
    3 - Inclui registros no Bancos de Dados
    4 - Altera o registro corrente
    5 - Remove o registro corrente do Banco de Dados
    [5]Nivel de acesso
    [6]Habilita Menu Funcional

    @type  Function
    @author Tiago Cunha
    @since 27/06/2025
    @version 1.0
    @param 1.00
    @see https://tdn.totvs.com/display/public/PROT/MTA650MNU
/*/
User Function MTA650MNU()

	aAdd(aRotina,{'Distribuir OP', 'u_APCP001A()', 0, 2, 0, NIL})
    aAdd(aRotina,{'Imp. Etiq. Prod.', 'u_xpcp001a()', 0, 2, 0, NIL})

Return
