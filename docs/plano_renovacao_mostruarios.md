# Plano de renovacao de mostruarios

## 1. Escopo confirmado em 04/11/2026

- Ambiente de desenvolvimento/homologacao: servidor 170774, consultas no contexto da empresa 01; movimentos 6V1 localizados na filial 01. Piloto de gravacao ainda a aprovar.
- Os materiais continuam fisicamente com o representante: retorno e nova remessa simbolicos.
- A empresa emite a NF-e de entrada correspondente ao retorno.
- Cliente na SA1 e representante na SA3 possuem codigos diferentes e o mesmo documento.
- Campo de descontinuacao informado: `SB1.B1_ZZDTDES`.
- TES de saida informada: `6V1`; TES de entrada vinculada no cadastro dessa TES.
- Precos e demais condicoes devem ser investigados nas notas e pedidos existentes.
- Escopo atualizado em 08/11/2026: automatizar retorno, pedido, liberacao e geracao da NF de saida via MATA461; AUTONFE padrao transmite e acompanha a autorizacao.
- Nao executar movimentos fiscais, inclusoes ou ajustes de saldo durante o levantamento.

## 2. Evidencias e limites da analise

| Evidencia | Fonte | Consequencia |
| --- | --- | --- |
| Base SB6, ligada a SB1 e SF4 | [MATR480 customizado](../Fontes/Relatorios/matr480_CUSTOM.prx#L235) | Usar registros de origem como candidatos, nao totais impressos |
| Nossos materiais em terceiros: `B6_TIPO = 'E'` | [Filtro do relatorio](../Fontes/Relatorios/matr480_CUSTOM.prx#L252) | Selecionar somente a direcao pertinente ao processo |
| SF4 exclui `F4_PODER3 = 'D'`; registros ativos e quantidade nao zero | [Consulta do relatorio](../Fontes/Relatorios/matr480_CUSTOM.prx#L242) | Reproduzir filtros pertinentes, observando o compartilhamento por tabela |
| Consulta do MATR480 nao restringe `SB6.B6_PODER3`; usa tipo, participante, periodo, produto e TES/SF4 | [Consulta do relatorio](../Fontes/Relatorios/matr480_CUSTOM.prx#L245) | Nao adicionar `B6_PODER3 = 'R'` como filtro de origem; `D` e usado para localizar movimentos de retorno |
| Saldo calculado por `ESTCalcTerc(produto, cliente, loja, identificador, TES, , data inicial, data final)` | [Calculo efetivo](../Fontes/Relatorios/matr480_CUSTOM.prx#L336) | Nao assumir que `B6_QUANT` e o saldo atual; validar tambem o periodo usado |
| Retornos localizados por filial, identificador, produto e `B6_PODER3 = 'D'` | [Detalhamento dos retornos](../Fontes/Relatorios/matr480_CUSTOM.prx#L545) | Preservar vinculo com cada origem e considerar retornos parciais |
| Conversao de unidade somente na apresentacao conforme parametro | [Exibicao de quantidades](../Fontes/Relatorios/matr480_CUSTOM.prx#L433) | Persistir unidade de processamento e controlar conversao explicitamente |
| Criacao local de pedidos usa `MsExecAuto`/`MATA410`, captura erros e confere itens gravados | [Padrao existente](../Fontes/SIGAFAT/ZTRVALID.prw#L1639) | Reaproveitar a abordagem, nao as regras especificas do processo ZTR |
| ExecAuto da MATA103 | [PCOM12003 - Documento de Entrada](https://tdn.totvs.com.br/pages/releaseview.action?pageId=235592777) e [exemplo de documento tipo devolucao](https://centraldeatendimento.totvs.com/hc/pt-br/articles/23214935762455-Cross-Segmentos-Totvs-Backoffice-Protheus-SIGACOM-Rotina-Autom%C3%A1tica-MATA103-Documento-Tipo-Devolu%C3%A7%C3%A3o) | Confirma `MsExecAuto` com opcao 3 para inclusao e lista fluxos distintos de Devolucao - Terceiros e Beneficiamento - Terceiros. O exemplo generico de tipo D usa fornecedor e formulario N; nao o copiar para o retorno proprio do projeto, cujos exemplos observados sao tipo B, formulario S, especie SPED, serie 3 e TES 3A1. Selecionar e homologar a secao/parametros exatos para o caso cliente/SA1, vinculos de origem e identificador SB6 antes de gravar. O quarto parametro `lWhenGet` abre a tela para edicao quando `.T.`; para processamento automatico deve ser omitido ou `.F.`. |
| Customizacao de MATA103 trata natureza de NCC | [MT103NTZ](../Fontes/SIGACOM/MT103NTZ.prw#L18) | Homologar efeitos financeiros; nao presumir retorno sem titulo |
| Retorno de poder de/em terceiros no faturamento | [FAT0057 - Emissao de Nota de Devolucao controlando Poder De/Em Terceiros](https://tdn.totvs.com/pages/viewpage.action?pageId=236431772) | Descreve retorno ao fornecedor de bem recebido para beneficiamento: origem MATA103 tipo B com TES de entrada `F4_PODER3 = 'R'`, `F4_TESDV` apontando para TES de saida tambem R, pedido/documento de saida relacionado a nota/item de origem e identificador `D1_IDENTB6`/`B6_IDENT`. Essa direcao e diferente do mostruario proprio enviado ao cliente; a TES local de retorno 3A1 e D, portanto nao aplicar FAT0057 sem confirmar a direcao e a regra fiscal da operacao. |
| Controle de poder de/em terceiros | [PCOM12007 - Controle de poder De/Em terceiros](https://tdn.totvs.com.br/pages/viewpage.action?pageId=229769259) | Distingue saldo SB2/SB6 conforme a direcao e a TES; em retorno, registra movimento de poder tipo D. Conferir o movimento de origem e os retornos por identificador, sem inferir a modalidade MATA103 apenas pelo nome "Devolucao - Terceiros". |

A consulta de referencias do editor para `ReportPrint` nao encontrou usos. Os comandos LS especificos de AdvPL nao estavam disponiveis; a analise continuou por leitura e busca textual.

O endpoint configurado `https://suntechsupplies170774.protheus.cloudtotvs.com.br:1607/rest` apresentou inicialmente `ConnectFailure`. Apos o restabelecimento do REST, em 04/11/2026, a autenticacao e as consultas somente leitura foram concluidas. A configuracao especial aponta para outro servidor e nao foi utilizada.

Foram confirmados no banco `B1_ZZDTDES`, a TES `6V1` e seu vinculo de retorno `3A1`. Ha exemplos reais de retorno com emissao propria; ver secao 9. Nao foi encontrada implementacao local de `ESTCalcTerc` nem exemplo reutilizavel da chamada automatica de MATA103 para este retorno. Contrato e suporte na release instalada devem ser verificados antes de implementar.

## 3. Processo proposto

1. **Levantar** remessas candidatas por empresa, filial, cliente/loja, TES, nota/serie, produto e identificador de terceiros. O recorte deve localizar saldos antigos, nao somente notas emitidas no periodo recente.
2. **Apurar** o saldo pelo mecanismo usado pelo MATR480, com data de referencia e parametros equivalentes. Trabalhar somente o saldo positivo selecionado, nunca repetir automaticamente a quantidade original da nota.
3. **Validar identidade**: localizar SA1 pelo cliente/loja da origem e SA3 pelo CPF/CNPJ normalizado. Exigir documento valido e correspondencia inequivoca no contexto de compartilhamento. Ausencia ou duplicidade gera pendencia, sem escolha automatica do primeiro registro. Nao filtrar `A1_TIPO = 'R'` como representante: no dicionario significa revendedor e ha correspondencias com SA3 tanto em clientes F quanto R. Representantes inativos exigem decisao explicita.
4. **Rastrear origem fiscal**: conferir SF2/SD2, item, TES, unidade, armazem e, quando aplicavel, lote. Validar cancelamentos, autorizacao, retornos existentes e vinculo do identificador. Nao associar itens apenas por produto ou numero da nota.
5. **Classificar produtos** pela data `B1_ZZDTDES`. Proposta a aprovar: descontinuado quando a data nao estiver vazia e for menor ou igual a data de referencia. Data futura nao torna o item descontinuado antecipadamente.
6. **Definir destinacao antes de qualquer retorno**: renovar fiscalmente ou faturar comercialmente os descontinuados. Proposta: decisao por item da origem, permitindo dividir quantidades; soma das destinacoes limitada ao saldo selecionado. Registrar usuario, data e aprovacao. Item sem decisao impede a efetivacao de sua unidade de processamento.
7. **Simular tudo**: verificar TES de retorno vinculada, configuracao da nova saida, valores, condicoes, cadastros e bloqueios. Exibir documentos previstos e pendencias antes de emitir o retorno.
8. **Revalidar e reservar logicamente** o saldo imediatamente antes da execucao. Impedir dois processos sobre a mesma origem/quantidade e detectar devolucao manual ocorrida depois do levantamento.
9. **Registrar o retorno simbolico** pela rotina padrao de MATA103, na modalidade adequada da release, com referencias originais e TES de entrada `3A1`, vinculada a `6V1`. O modelo historico consultado usa `F1_TIPO = 'B'`, `F1_FORMUL = 'S'`, especie SPED e serie 3; homologar essa modalidade, sem presumir tipo D. Nao criar SA2 automaticamente para um cliente SA1.
10. **Conferir retorno**: documento e itens gravados integralmente, referencias corretas, saldo antigo reduzido exatamente na quantidade processada e situacao fiscal adequada. Para renovacao integral, o saldo antigo deve zerar; na parcial, deve restar somente o nao selecionado. Nenhuma baixa direta de SB6.
11. **Gerar pedidos separados por finalidade** via MATA410: renovacao com quantidades retornadas e TES original validada; venda de descontinuados com TES comercial e condicoes aprovadas. Nao presumir que a TES comercial e a mesma da remessa.
12. **Liberar e faturar o pedido gerado** com serie fiscal aprovada e data prevista de entrega, validando SC9 antes de MATA461. O ZMOST nao transmite a NF-e; AUTONFE/AUTONFEMON padrao completam transmissao e autorizacao. Pedido faturado ainda precisa da conciliacao fiscal e de saldo.
13. **Conciliar as novas saidas**: renovacao cria novo saldo em terceiros; venda encerra a propriedade dos itens vendidos sem reabrir indevidamente saldo de remessa. Conferir documentos fiscais e efeitos de estoque/financeiro antes de concluir.

### Regras de seguranca do fluxo

- A tela oferece, quando ha mais de uma nota selecionada, processamento separado (uma entrada/pedido/NF por origem) ou consolidado (uma entrada/pedido/NF para o lote).
- A consolidacao preserva em cada SD1 a nota, serie, item e identificador SB6 de origem. Antes de qualquer inclusao, exige cliente/loja, fornecedor/loja e serie de retorno iguais, pedidos originais com condicoes comerciais compativeis e referencias completas dentro do limite de `C5_ZZOBS`; caso contrario, bloqueia a consolidacao e orienta o processamento separado.
- A disponibilidade da opcao no fonte local nao substitui homologacao fiscal/tecnica nem publicacao no RPO. A modalidade separada continua sendo a alternativa para origens incompatíveis.
- A consulta pode agrupar para exibicao, mas o executor deve manter o detalhamento de cada origem.
- A mesma TES original somente pode ser reutilizada se continuar valida para produto, cliente, UF e operacao na data atual; divergencias bloqueiam para analise fiscal.
- Descontinuacao nao e sinonimo de bloqueio cadastral. Se MATA103/MATA410 impedir o produto, aprovar uma solucao suportada; nao desbloquear SB1 temporariamente por automatismo.
- Valores do retorno seguem a origem e a regra fiscal aprovada; valores da nova remessa e da venda precisam de politicas explicitas. Nao usar custo como preco de venda por conveniencia.
- Renovacao simbolica nao deve gerar expedicao, recebimento fisico, picking ou movimentacao de endereco indevidos. Conferir WMS/ACD, lotes e efeitos de TES.
- Aprovacao fiscal deve considerar os prazos e requisitos legais da operacao; automacao nao torna uma renovacao automaticamente admissivel.

## 4. Levantamento no desenvolvimento

Levantamento inicial somente leitura realizado em 04/11/2026; resultados na secao 9. Complementar com um caso piloto aprovado e conciliacao no Protheus.

| Tabelas | O que verificar | Resultado esperado |
| --- | --- | --- |
| SX2/SX3 e indices SIX, pelas APIs/dicionario quando nao estiverem em SQL | Compartilhamento, campos, tamanhos, validacoes e indices; `B1_ZZDTDES`; classificacao real de representante; TES de retorno vinculada | Contrato de dados confirmado, sem fixar filial vazia ou nomes fisicos por suposicao |
| SA1/SA3 | `A1_CGC`/`A3_CGC`, cliente/loja, vendedor, bloqueios, duplicidades e elegibilidade | Relacao inequivoca entre cliente fiscal e representante; sem igualar codigos |
| SB1 | Data de descontinuacao, unidades/conversao, bloqueios, produto e controle de lote | Regra de classificacao e restricoes |
| SF4 | `6V1`, TES de retorno vinculada, TES comerciais encontradas; poder de terceiros, estoque, financeiro e CFOP | Vinculo `F4_TESDV = '3A1'` confirmado; aprovacao fiscal e TES comercial atual ainda pendentes |
| SB6 | Origens e retornos ativos por filial/cliente/loja/produto/identificador/TES | Amostra conciliavel com MATR480 e casos de retorno parcial |
| SF2/SD2 | Remessas com `6V1`, autorizacao/cancelamento, item, preco, lote, armazem e identificador; campos candidatos `D2_IDENTB6` e `D2_ITEM` | Reconstrucao inequivoca da origem e de seus valores |
| SF1/SD1 | Exemplos manuais corretos de retorno simbolico e emissao propria; campos candidatos `D1_NFORI`, `D1_SERIORI`, `D1_ITEMORI`, `D1_IDENTB6` | Modelo homologado para MATA103 e conciliacao de terceiros |
| SC5/SC6, SF2/SD2 | Pedidos e vendas existentes contra representantes, tabela, preco, TES, condicao e vinculos | Modelo comercial para venda de descontinuados, separado da renovacao |
| DA0/DA1, SE1 e configuracoes aplicaveis | Vigencia de preco, titulos existentes e eventuais efeitos financeiros dos retornos | Preco e cobranca comprovados; desconto em comissao depende de regra especifica |

O fato de os codigos SA1 e SA3 possuirem o mesmo documento nao comprova, sozinho, qual loja deve receber a nova nota. Preservar a loja da origem e tratar mudancas explicitamente.

## 5. Arquitetura

- Cockpit nativo dentro do Protheus, com interface, regras e orquestracao em AdvPL, conforme decisao atualizada do usuario em 04/11/2026. Sem aplicacao Angular/PO UI ou servidor web adicional nesta etapa.
- Rotina propria de gestao de renovacao, sem incorporar efeitos de gravacao no relatorio MATR480. Detalhamento do cockpit e padrao AdvPL na secao 10.
- Camadas separadas: levantamento/conciliacao, validacoes, aprovacao, adaptador MATA103, adaptador MATA410 e acompanhamento fiscal.
- Persistencia de controle de processo e itens em estrutura customizada a definir no dicionario; nao reutilizar a fila ZTR, que possui finalidade e regras diferentes.
- Cabecalho: identificador, empresa/filial, cliente/loja, representante, data de referencia, usuario/aprovador, estado e documentos gerados.
- Itens: chave completa da origem, identificador SB6, produto/unidade/lote/armazem, saldo observado, quantidade selecionada, destinacao, TES, valores e vinculos dos documentos gerados.
- Registrar separadamente operacoes executadas e evidencias de conferencia; uma origem pode ter renovacoes parciais legitimas em momentos diferentes.
- Estados conceituais: LEVANTADO, PENDENTE, APROVADO, RETORNO_EM_PROCESSO, RETORNO_REGISTRADO, AGUARDA_FISCAL_RETORNO, RETORNO_VALIDADO, PEDIDOS_GERADOS, AGUARDA_FATURAMENTO, CONCLUIDO e ERRO/RECUPERACAO.
- O desenho final exige idempotencia persistente e retomada por etapa. O executor-piloto atual usa bloqueio por nota, exige saldo armazenado integral, confere SF1/SD1 e SC5/SC6 e atualiza o cockpit depois de uma tentativa; nao oferece retomada persistente. Em falha apos criar a entrada, conferir SF1/SD1 antes de qualquer nova acao.
- Usar bloqueios e transacoes locais suportados, sem manter uma transacao de banco aberta durante comunicacao com TSS/SEFAZ ou aprovacao humana.
- Retorno emitido e pedido com erro exige retomar a criacao do pedido, nao repetir o retorno. Nota rejeitada ou cancelada exige reconciliacao e tratamento padrao, nao exclusao direta de registros.
- O botao Previa permanece somente leitura. Renovar exige confirmacao explicita, notas completas e saldo atual B6_SALDO; com multiplas notas, permite escolher consolidacao ou processamento separado. A consolidacao valida a compatibilidade antes da MATA103 e mantem a distribuicao por origem em SD1; a janela de etapas e o log ConOut sao volateis, e uma trilha auditavel requer estrutura propria aprovada no dicionario.

## 6. Plano de execucao e criterios de aceite

| Fase | Entrega | Criterio para avancar |
| --- | --- | --- |
| 1. Dados e fiscal | Amostra de remessa, retorno e venda; dicionario; matriz de TES, valores e referencias | Ambiente acessivel, piloto definido e regras aprovadas |
| 2. Cockpit e levantamento somente leitura | Tela nativa, filtros, consulta de elegibilidade e simulacao por origem com classificacao de descontinuados | Compilacao AdvPL validada, tela navegavel e quantidades conciliadas com MATR480 usando os mesmos parametros |
| 3. Gestao e aprovacoes | Tela de selecao/destinacao, controle persistente e protecao contra duplicidade | Divisao de quantidades correta, trilha de aprovacao e testes de concorrencia |
| 4. Retorno piloto | Adaptador padrao MATA103, emissao propria e reconciliacao | Uma origem autorizada para teste, retorno fiscal correto e saldo antigo reduzido exatamente |
| 5. Pedido e liberacao | Adaptador MATA410, liberacao via MaLibDoFat e conferencia integral SC9 | Cabecalho/itens conferidos, todas as quantidades liberadas sem bloqueio e sem duplicidade |
| 6. Faturamento e AUTONFE | MATA461 via MaPvlNfs; AUTONFE/AUTONFEMON padrao transmitem e acompanham autorizacao | SF2/SD2 comprovados, autorizacao fiscal conferida e saldo/efeitos de estoque e financeiro conciliados |
| 7. Piloto ampliado | Lote controlado, recuperacao e instrucoes operacionais | Casos criticos aprovados e autorizacao formal antes de producao |

Testes minimos: retorno integral e parcial; mesmo produto em duas notas ou itens; TES distintas; descontinuado passado/futuro/sem data; lote misto com venda e renovacao; CPF/CNPJ duplicado ou sem SA3; loja divergente; produto bloqueado; unidade alternativa e lote; devolucao concorrente; dupla execucao; falha apos retorno; timeout de inclusao; rejeicao/cancelamento de NF-e; retomada sem duplicar documentos; ausencia de movimentacao fisica indevida.

Na primeira entrega executavel, a verificacao mais barata e discriminante sera comparar o levantamento somente leitura com um caso real do MATR480, incluindo origem parcialmente devolvida. A primeira gravacao somente deve ocorrer depois dessa conciliacao e da aprovacao do documento de retorno modelo.

## 7. Decisoes ainda pendentes

1. Aprovar empresa/filial e cliente/loja, representante e nota/serie para o piloto de gravacao; exemplos somente leitura foram identificados na filial 01.
2. Aprovar matriz fiscal `6V1`/`3A1` confirmada no banco e definir TES comercial atual. `6V1` nao gera duplicata, portanto nao assumir que atenda a venda com cobranca.
3. Aprovar regra temporal de `B1_ZZDTDES` e decisao por item/quantidade, em vez de uma decisao unica para todo o representante.
4. Homologar serie 3, tipo B e formulario proprio S observados nos retornos; verificar autorizacao/cancelamento e contrato de automacao da MATA103 na release instalada.
5. Localizar exemplos atuais de venda de descontinuados para definir TES, tabela/preco, condicao, cobranca e eventual tratamento de comissao. O exemplo comercial de 2022 nao comprova a regra vigente.
6. Definir valores da nova remessa, vencimento/prazo fiscal, selecao por antiguidade e permissao de renovacao parcial.
7. Definir tratamento de representantes/cadastros inativos, mudanca de loja/UF e produtos bloqueados, sem alterar cadastros automaticamente.
8. Confirmar release Protheus, build AppServer, versao/data da LIB e caminho dos includes Protheus para validar os componentes utilizados. Confirmar tambem uso de SmartClient desktop, WebApp ou ambos para homologacao da tela.

## 8. Situacao desta etapa

Analise de fontes, consultas somente leitura no desenvolvimento e plano atualizados. Primeira implementacao isolada em AdvPL adicionada em ZMOST, sem alterar fontes operacionais existentes ou dados de negocio. Acesso REST restabelecido. Compilacao no RPO, execucao dos testes AdvPL, homologacao visual e conciliacao runtime de `ESTCalcTerc` ainda pendentes; validacao de autorizacao/cancelamento e emissao nao fazem parte desta primeira entrega.

## 9. Resultados das consultas de 04/11/2026

### Dicionario e matriz fiscal

- Tabelas fisicas confirmadas: SA1010, SA3010, SB1010, SB6010, SF4010, SF1010, SD1010, SF2010, SD2010, SC5010, SC6010, SX2010 e SX3010.
- SX2: SA1, SA3 e SB1 compartilhadas nos tres niveis consultados; filial fisica em branco. SB6, SF4 e documentos/pedidos exclusivos; movimentos 6V1 encontrados na filial 01.
- SX3: `B1_ZZDTDES` e data, tamanho 8; em SQL e armazenada em varchar. Nao tratar o tipo fisico como texto livre na implementacao AdvPL.
- SX3: `A1_TIPO` distingue consumidor final F de revendedor R, entre outros; nao define representante. `A3_MSBLQL`: 1 inativo, 2 ativo.
- `D2_ITEM` tem tamanho 2 e `D1_ITEMORI` tamanho 4: comparar respeitando preenchimento/tamanho, sem supor identica representacao textual.

| TES | Descricao | TES de devolucao | Poder de terceiros | Estoque | Duplicata | CFOP |
| --- | --- | --- | --- | --- | --- | --- |
| 6V1 | REM.P/MOSTRUARIO | 3A1 | R | S | N | 5912 |
| 3A1 | RET.REM.P/DEMONSTRAC | 6V1 | D | S | N | 1913 |

As duas TES foram encontradas na filial 01. O fato de movimentarem estoque exige homologacao do efeito contabil/fisico no ciclo simbolico; nao significa que se deva executar logistica fisica.

### Volume e elegibilidade preliminar

Criterio: SB6 ativa, filial 01, TES 6V1, tipo E, poder de terceiros R e participante C. Total historico: **61.168 registros**, quantidade original acumulada **63.782**, emissoes entre 25/02/2025 e 16/09/2026.

Com `B6_SALDO > 0`: **11.444 registros**, saldo armazenado acumulado **11.934 unidades**. O campo foi confirmado no dicionario, mas esses numeros **nao substituem ESTCalcTerc nem comprovam o saldo fiscal disponivel para executar**.

O cruzamento usa cliente/loja da origem em SA1 compartilhada e documento nao vazio de SA3 compartilhada, com remocao de pontos, barra e hifen. Ainda nao foi executada validacao de digitos verificadores de CPF/CNPJ.

| Tipo SA1 | Correspondencias SA3 | Representantes ativos | Registros SB6 | Saldo armazenado | Registros com produto descontinuado |
| --- | --- | --- | --- | --- | --- |
| F | 1 | 0 | 1.187 | 1.219 | 244 |
| F | 1 | 1 | 8.031 | 8.352 | 859 |
| R | 0 | 0 | 9 | 9 | 2 |
| R | 1 | 0 | 225 | 225 | 30 |
| R | 1 | 1 | 1.992 | 2.129 | 219 |

Ha **10.023 registros / 10.481 unidades armazenadas** com correspondencia unica e ativa em SA3; **1.078 desses registros** possuem produto com data de descontinuacao ate 04/11/2026. A contagem e de registros SB6, nao de produtos distintos nem de clientes distintos. Nao foram encontrados produtos com `B1_MSBLQL = '1'` nesse recorte.

Os 1.412 registros ligados a representantes inativos e os 9 sem correspondencia devem ficar em pendencia ate regra aprovada. Correspondencia ativa por documento e apenas pre-elegibilidade, nao autorizacao de processamento; por exemplo, cadastros internos tambem podem coincidir por documento.

Nenhum registro do recorte com representante unico/ativo apresentou simultaneamente `0 < B6_SALDO < B6_QUANT`. Portanto, o teste de retorno parcial ainda precisa de caso especifico; nao foi comprovado com essa amostra.

### Exemplos reais para investigacao, nao autorizacao de emissao

- Retorno `000286906/3`, filial 01, participante `R00114/01`, produto `10103860954114`, quantidade 1, TES 3A1: referencia remessa `000285055/3`, item original 01 e identificador `9AJ085`. A saida original SD2 foi localizada com TES 6V1 e preco unitario 195,96.
- Retorno `000286800/3`, participante `R00113/01`: tres itens vinculados a remessa `000285028/3`, identificadores `9AIXWM`, `9AIXWN`, `9AIXWO`, todos com quantidade 1. Os precos unitarios de saida consultados foram 195,96, 219,96 e 219,96.
- A amostra de oito itens de retorno 3A1 usa `F1_TIPO = 'B'`, `F1_FORMUL = 'S'`, especie SPED, serie 3, `F1_STATUS = 'A'` e chave preenchida. Esses campos isolados **nao comprovam autorizacao SEFAZ nem ausencia de cancelamento**; verificar eventos/retornos fiscais antes de usar como modelo homologado.
- Descontinuados com saldo armazenado 1 na remessa `000286778/3`, participante `R00107/01`: produtos `10102760302024` (04/07/2025), `10104740745025` (01/12/2025), `10104930302025` e `10105000092024` (05/05/2025). Representante com correspondencia unica e ativa no cruzamento.
- Na amostra comercial limitada aos clientes C06671, C06953, R00114 e R00113, apareceu uma venda em 01/12/2022, TES 5A6, descricao VENDA PROD ESTABELEC, poder de terceiros N, duplicata S, tabela TSU e condicao 008. Esse achado antigo e restrito **nao define a TES, tabela ou condicao atual para os descontinuados**.
- Consulta somente leitura adicional em 06/11/2026 para o piloto `000286778/3`: 38 registros SB6 e 38 itens SD2, todos com quantidade/saldo armazenado 1, unidade UN, TES 6V1, poder R e identificador D2_IDENTB6 correspondente a B6_IDENT. O SF2 possui chave informada, mas isso nao comprova autorizacao SEFAZ nem ausencia de cancelamento.
- O cliente SA1 `R00107/01` esta ativo e possui uma correspondencia SA2 unica e ativa `R00107/01` pelo documento, confirmando o cadastro necessario a entrada MATA103. Nao foi exibido nem registrado o documento fiscal.
- A origem SD2 aponta para o pedido `011221`, com 38 itens. O cabecalho original usa representante R00052, condicao 042, tipo N, moeda 1, tabela TSU, transportadora T00005 e frete C; os itens consultados usam TES 6V1, armazem 07, unidade UN e preco igual a D2_PRCVEN. C6_OPER esta vazio no pedido original; nao preencher por suposicao.
- Nos retornos manuais consultados, o cabeçalho SF1 usa `F1_TIPO = 'B'`, `F1_FORMUL = 'S'`, especie SPED, serie 3, fornecedor SA2, condicao 030, moeda 1 e status A; os itens SD1 usam TES 3A1, armazem 07, preco da origem e vinculam nota/serie/item/identificador. Homologar cada campo no piloto e nao copiar status nem chave de NF-e.

### Proximo marco
Para o mostruario proprio enviado ao cliente, a hipotese apoiada pelos registros locais e a entrada 3A1 via MATA103 tipo B/formulario proprio, sujeita a homologacao. A FAT0057 descreve a direcao oposta (bem de terceiro recebido e retorno ao fornecedor com TES de saida R); usar os requisitos de vinculo como comparacao, nao como roteiro intercambiavel. O piloto deve conferir SF1/SD1, a origem SF2/SD2 e o efeito final em SB6 antes de automatizar.

Aprovar um exemplo de representante e conciliar os itens de uma origem com o MATR480/ESTCalcTerc no Protheus, incluindo historico de retornos. Completar a pesquisa comercial com uma nota atual indicada pela operacao. Somente depois homologar a chamada de MATA103 para o modelo de retorno tipo B e a geracao dos pedidos, mantendo faturamento de saida supervisionado.

## 10. Cockpit nativo e padrao AdvPL

Decisao atualizada de 04/11/2026: executar a tela dentro do Protheus e desenvolver o modulo em AdvPL, preservando a arquitetura funcional e evitando introduzir outro padrao de linguagem. Esta secao descreve o projeto; a primeira implementacao para homologacao esta detalhada na secao 11 e ainda nao comprova compatibilidade no RPO.

### Padrao de desenvolvimento

| Tema | Orientacao adotada |
| --- | --- |
| Fontes e includes | Novos fontes .prw, usando protheus.ch e os includes necessarios aos componentes e ao acesso a dados; aproveitar os headers do ambiente existente |
| Entrada de menu | User Function com nome curto e exclusivo, conforme convencao Protheus; funcoes auxiliares locais como Static Function |
| Organizacao | Separar tela, levantamento, validacoes e execucao fiscal; usar funcoes pequenas e contratos de parametros/retornos explicitos. Classes apenas quando reduzirem complexidade real |
| Validacoes | Validar tipos, datas, quantidades e campos obrigatorios nas fronteiras; respeitar tamanhos e casas decimais do SX3 |
| Interface | Componentes nativos do Framework Protheus; selecionar controles e assinaturas documentados e compativeis com a LIB instalada |
| Erros e limpeza | Seguir o padrao local ErrorBlock/Begin Sequence/Recover, restaurando o ErrorBlock anterior e as areas de trabalho, inclusive em falhas; fechar aliases abertos pela rotina |
| Rotinas automaticas | Adaptadores MATA103/MATA410 verificam lMsErroAuto, capturam GetAutoGrLog e conferem documentos efetivamente gravados antes de avancar |
| Testes | Validar regras de forma isolada com os recursos existentes e executar conciliacao integrada em homologacao; nao introduzir outra linguagem ou framework de testes como requisito inicial |

Uma interface organizada e um fluxo seguro nao dependem da troca de linguagem. A modernizacao permanece no cockpit, na rastreabilidade, nas validacoes e na recuperacao de falhas.

### Desenho da tela

Nome funcional: **Renovacao de Mostruarios**. Usar componentes, icones, cores de estado e comportamento do Framework Protheus, respeitando o tema do usuario. Priorizar leitura de muitos itens e rastreabilidade; evitar uma sequencia de ParamBox ou um painel decorativo.

| Area | Conteudo | Comportamento |
| --- | --- | --- |
| Contexto | Empresa/filial da sessao, data de referencia e modo de operacao | Nao permitir troca de filial apenas mudando um filtro; respeitar contexto e permissoes do ERP |
| Filtros | Representante, cliente/loja, produto, nota/serie, TES, situacao cadastral e descontinuacao | Pesquisas padrao dos cadastros, limpar filtros e consultar explicitamente; nao carregar todos os historicos ao abrir |
| Resumo compacto | Origens, quantidades, descontinuados e pendencias do recorte efetivamente apurado | Indicar processamento em andamento e distinguir saldo armazenado de saldo calculado; nao misturar unidades diferentes em um total sem conversao |
| Grade principal | Selecao, situacao, cliente/loja, representante, nota/serie/item, produto, unidade, saldo calculado, quantidade escolhida, data de descontinuacao, destinacao e TES | Ordenacao/filtro suportados pelos componentes; origem fiscal sempre recuperavel mesmo em exibicao agrupada |
| Detalhes | Identificador SB6, remessa, retornos existentes, valores, lote/armazem e impedimentos | Exibir motivo textual de cada bloqueio, nao depender apenas de cor; consultar origem sem permitir alteracao indevida |
| Processo | Estado, usuario/aprovador, entrada gerada, pedidos de renovacao/venda e resultado das etapas | Disponivel quando houver persistencia e executores implementados; retomar etapa pendente sem duplicar documentos |
| Historico | Aprovacoes, tentativas, mensagens de erro e reconciliacoes | Preservar evidencia para suporte e auditoria, com acesso autorizado |

O layout deve redimensionar com o cliente: filtros compactos no topo, grade como area dominante e detalhes em aba ou divisao ajustavel. A grade usa TCBrowse com colunas TCColumn explicitas e dados provenientes do estado da consulta.

### Acoes e estados

- Primeira entrega: Consultar, Atualizar, Filtrar e Detalhar; selecao e simulacao somente onde ja houver regra implementada. Sem botoes fiscais ficticios ou mensagens de sucesso para etapas ainda inexistentes.
- Evolucao: Definir destinacao, Simular processo, Aprovar, Gerar retorno, Gerar pedidos e Retomar. Disponibilidade determinada por permissao, estado persistido e validacoes de negocio, nao apenas pela tela.
- Previsto para o fluxo completo: resumo de confirmacao com cliente, origens, quantidades, TES e efeitos antes de qualquer gravacao fiscal. Confirmacao separada para etapa destrutiva/irreversivel; nao permitir duplo clique gerar duas execucoes.
- Durante consulta: progresso e prevencao de reentrada. Se houver cancelamento suportado, interromper entre unidades de leitura e nao apresentar resultado parcial como completo.
- Tratar explicitamente consulta vazia, filtros invalidos, indisponibilidade, calculo incompleto e dados alterados apos o levantamento.
- O ZMOST libera e gera a NF de saida somente apos confirmacao explicita, serie/data informadas e validacao integral do pedido; AUTONFE padrao permanece responsavel pela transmissao e autorizacao.

### Organizacao das responsabilidades

| Componente conceitual | Responsabilidade |
| --- | --- |
| Entrada de menu e cockpit | Integrar a sessao Protheus, montar interface e encaminhar comandos; sem SQL ou regra fiscal nos eventos dos controles |
| Servico de levantamento | Consultar candidatos, calcular saldos, validar identidade e classificar produtos; reutilizavel fora da tela |
| Repositorio de consultas | Isolar acesso a dados, respeitando xFilial, RetSqlName, exclusao logica e consultas seguras; nao transportar para producao as filiais/tabelas fisicas fixadas no levantamento SQL |
| Regras de elegibilidade/destinacao | Validacoes testaveis de datas, quantidades e identidade, sem dependencia de objetos de interface |
| Orquestrador e adaptadores fiscais | Executor-piloto em ZMOST usa ExecAuto MATA103/MATA410, verificacoes SF1/SD1/SC5/SC6 e bloqueio por nota; persistencia e retomada auditavel exigem tabela propria ainda pendente |

Esses componentes sao fronteiras de responsabilidade, nao uma exigencia de criar muitos arquivos/classes antecipadamente. Criar apenas os necessarios para cada entrega. Manter um ponto de entrada simples de menu, sem namespaces ou contratos adicionais de linguagem.

### Ordem de implementacao

1. Aproveitar o ambiente AdvPL existente e confirmar release, LIB, includes, cliente desktop/WebApp e acesso autorizado a compilacao em homologacao; verificar build AppServer quando necessario para os componentes escolhidos.
2. Criar a entrada de menu e a estrutura da tela nativa em AdvPL, validando compilacao e abertura/fechamento no ambiente antes de ampliar o cockpit.
3. Implementar a primeira fatia vertical: cockpit + consulta de um cliente/nota + ESTCalcTerc + classificacao de descontinuacao + detalhes. Nao criar documentos nem tabelas de controle definitivas nesta fatia somente leitura.
4. Conferir resultados com MATR480 e testar interface no cliente efetivamente utilizado: redimensionamento, foco, consulta vazia, erro e grandes recortes. Diagnostico do editor nao substitui compilacao/execucao no RPO.
5. Introduzir selecao, destinacao e persistencia conforme dicionario aprovado; depois integrar as etapas fiscais ja previstas no plano.

Conclusao desta revisao: o cockpit AdvPL tem executor-piloto confirmado por usuario, com acompanhamento em sessao, retorno MATA103 e pedido MATA410; nenhuma chamada foi executada no RPO nesta revisao. Compilacao e homologacao fiscal/runtime continuam pendentes.

## 11. Primeira entrega: implementacao para homologacao

Fonte: [Fontes/SIGAFAT/ZMOST.prw](../Fontes/SIGAFAT/ZMOST.prw).

### Entradas

| Entrada | Finalidade | Efeitos |
| --- | --- | --- |
| `U_ZMOST()` | Cockpit nativo FWLayer/TCBrowse | Abre a tela; sem consulta automatica |
| Botao **Consultar** | Chama `Static Function ZMOSCON(aFiltro)` | Somente SELECT e ESTCalcTerc; sem documentos ou persistencia |
| Botao **Previa** | Chama `Static Function ZMSimul(aState)` | Resume quantidades selecionadas por unidade e destino; nao grava |
| Botao **Renovar** | Chama `Static Function ZMProcess(aState, oBrowse, oResumo)` | Com uma nota, segue direto no modo individual; com varias, oferece processamento nota a nota ou consolidado. Exige todas as linhas das origens, saldo atual completo, series iguais, mesmo cliente/loja e fornecedor/loja, condicoes comerciais originais compativeis e referencias dentro de `C5_ZZOBS`. Executa MATA103 tipo B/formulario S, confere SF1/SD1, cria e confere MATA410, libera via `MaLibDoFat` e confere SC9, fatura via MATA461/`MaPvlNfs` e confere SF2/SD2. A autorizacao/transmissao continua no AUTONFE padrao. Venda de descontinuados permanece bloqueada ate homologar a matriz comercial. |
| Botao **Testes** | Chama `Static Function ZMOSTST()` pelo wrapper estatico ZMTestRun | 39 testes de regras em memoria e resumo na tela; sem acesso ao banco |

No menu Protheus, cadastrar rotina do tipo funcao de usuario com identificador `U_ZMOST`, conforme padrao do configurador. Compilar somente no RPO de homologacao autorizado antes de executar; nao cadastrar diretamente em producao.

### Funcionalidades implementadas

- Contexto de empresa/filial da sessao, sem troca de filial por filtro.
- Filtros de cliente, loja, representante, nota, serie, produto, periodo, TES e classificacao. TES inicial vazia (todas as TES); quando preenchida, restringe a pesquisa. Periodo inicial 01/01/1900 ate a data atual para nao perder remessas antigas.
- Cliente, representante, nota e TES podem ficar vazios para listar notas de todos os clientes/representantes e TES da empresa/filial atuais, respeitando periodo, produto e classe. A tela de renovacao cobre somente participantes cliente (`B6_TPCF='C'`) com origem de venda/SA1/SA3; fornecedores (`F`) do MATR480 nao entram neste fluxo. A consulta permite no maximo 20.000 origens candidatas; ao exceder o limite ou falhar, descarta todo o resultado e nao apresenta lote parcial.
- No periodo padrao completo (01/01/1900 ate hoje), o saldo atual e filtrado por `B6_SALDO > 0`, conforme o controle SB6 documentado pela TOTVS. Em periodos personalizados, usa-se `ESTCalcTerc(produto, cliente, loja, identificador, TES, , data inicial, data final)`; nao aplicar o saldo armazenado como substituto nesse recorte historico. A apresentacao permanece na unidade da SB6, sem conversao para segunda unidade.
- SA1/SA3 por documento, sinalizando ausencia, ambiguidade ou representante inativo. Normalizacao de digitos e tamanho CPF/CNPJ; verificacao de digitos verificadores ainda nao implementada, indicada nos detalhes.
- SA2 por documento do cliente, exibindo codigo/loja no detalhe. Fornecedor ausente, inativo ou ambiguo bloqueia a previa de renovacao, mas nao a destinacao de venda; nao e criado fornecedor automaticamente.
- Classificacao por data B1_ZZDTDES: vazia ou futura em relacao a referencia = ATIVO; data menor ou igual a referencia = DESCONTINUADO. Essa classe nao substitui o bloqueio cadastral, conferido separadamente.
- Origem SF2/SD2 localizada por documento, serie, participante, produto, TES e identificador D2_IDENTB6. Mais de um resultado para a mesma origem SB6 gera pendencia, sem duplicar o saldo na grade.
- Verifica existencia e bloqueios de cliente/produto e TES de saida/retorno; sem validacao completa de CFOP, tributacao, autorizacao ou cancelamento de NF-e.
- Grade principal lista notas agrupadas por cliente/loja/numero/serie, com caixa por nota, representante, emissao, totais de itens, descontinuados, pendencias e contagem selecionada. Duplo clique na caixa alterna os itens elegiveis da nota; clique no cabecalho da caixa alterna a selecao em massa. Itens com pendencias sao ignorados; descontinuados ficam sem destino e exigem decisao explicita no detalhe. Abrir uma nota mostra os itens; selecao e simulacao continuam por item. O detalhe do item mostra ate dez retornos no periodo e informa a quantidade adicional.
- Selecao de quantidade positiva, limitada ao saldo calculado e a precisao do SX3. Para descontinuados, destino permanece pendente ate escolha explicita entre Renovar e Faturar.
- Previa das quantidades por unidade de medida e destinacao, sem somar unidades diferentes. O processamento efetivo e restrito a uma nota de origem completa e ao modo atual `B6_SALDO`; periodos historicos, parcialidades, mistura de destinacoes e multiplas notas sao bloqueados.
- A tela de acompanhamento informa validacao, MATA103, conferencia SF1/SD1, MATA410, conferencia SC5/SC6, liberacao/SC9, MATA461 e conferencia SF2/SD2. Os marcadores sao da sessao e as mensagens detalhadas vao para o console do AppServer; nao ha trilha persistente de processo.
- ZA1 nao foi reutilizada: seu contrato existente e fila de integracao AFV, chaveada por empresa/filial/pedido externo, com flags `ZA1_INTEGR`/`ZA1_EXCLUI` e um campo `ZA1_LOGERR`. Isso nao identifica origem SB6/itens nem documentos gerados e poderia interferir na integracao existente. ZTR/ZTR_MSGERR tambem nao sao usados: pertencem ao reabastecimento interfilial 03->02. Foram reaproveitados apenas padroes do processo de transferencia: bloqueio por nome, captura `GetAutoGrLog`, `MsExecAuto`, conferencia posterior dos itens e estados por etapa. Persistencia auditavel exigira tabela propria no dicionario.
- Alterar filtros nao modifica a consulta ja carregada ate Consultar novamente. O resumo mostra a referencia do levantamento efetivamente apresentado. Uma nova consulta ou Limpar descarta selecoes anteriores.

Nesta entrega, cada linha da origem tem uma unica quantidade/destinacao. A divisao de uma origem entre renovacao e venda nao esta implementada; sera tratada junto da gestao persistente, apos aprovacao da regra. A previa de destinacao nao substitui uma simulacao fiscal/comercial integral.

### Contrato do servico

Contrato interno de `Static Function ZMOSCON(aFiltro)`, chamado somente pelo botao **Consultar**; nao e uma entrada publica do RPO. `aFiltro` tem dez posicoes, sem dependencia dos controles da tela.

| Posicao | Conteudo | Tipo |
| --- | --- | --- |
| 1 | Cliente SA1 | Caracter, vazio para todos no recorte |
| 2 | Loja SA1 | Caracter, exige cliente quando preenchida |
| 3 | Codigo SA3 | Caracter, vinculo por documento |
| 4 | Nota de origem | Caracter |
| 5 | Serie | Caracter |
| 6 | Produto | Caracter |
| 7 | Data inicial | Data preenchida |
| 8 | Data final/referencia | Data preenchida, nao futura |
| 9 | TES de saida | Caracter; vazio significa todas as TES |
| 10 | Classe | Numerico: 1 todos, 2 ativos, 3 descontinuados |

Retorno: `{sucesso, linhas, erro, origensLidas}`. Em erro, linhas e um array vazio. Os indices das linhas estao definidos pelas constantes `ZM_*` no proprio fonte; incluem chave completa da origem, saldo calculado/armazenado, representante, classificacao, TES, pendencias e dados da selecao. `CONFERIR` indica ausencia das pendencias preliminares, nao aprovacao fiscal nem autorizacao de execucao.

Informe os filtros no cockpit e use **Consultar**. Em caso de erro, a grade descarta o resultado e nao mantem linhas parciais.

### Verificacao realizada e limites

- Checks estaticos: ausencia de operacoes de gravacao, nomes de funcoes ate dez caracteres, funcoes auxiliares resolvidas, blocos balanceados, escape de literais SQL e ausencia de filtro por saldo armazenado.
- Consulta SQL somente leitura no desenvolvimento: a nota 000286778/3 de R00107/01 tem 38 registros no recorte consultado, todos com item SD2 e identificador correspondente. Isso sustenta a associacao escolhida; nao equivale a executar o servico AdvPL nem a validar todos os saldos.
- Consultas agregadas RESTQry em 05/11/2026 no banco `CMKVNJ_170774_PR_DV`, com SB6 filial 01, tipo E, quantidade nao zero, periodo 01/01/1900-05/11/2026, SB1 compartilhada (`B1_FILIAL` em branco) e SF4 filial 01 com `F4_PODER3` diferente de D: 1.914 notas candidatas/68.972 linhas para clientes (`TPCF=C`) antes do saldo; filtrando `SIGN(B6_SALDO)=1`, 506 notas/14.432 linhas. Para fornecedores (`TPCF=F`), 469 notas/1.620 linhas candidatas e 33 notas/44 linhas com saldo armazenado positivo. Os grupos C observados tinham `B6_PODER3=R`; remover esse filtro nao alterou o conjunto candidato do DEV. Conforme confirmado pelo usuario, este banco de desenvolvimento e a base definitiva para este teste (nao ha outra base de teste, exceto producao). **Os 506 grupos com `B6_SALDO` positivo sao a referencia SQL de saldo armazenado nessa base; a equivalencia exata com `ESTCalcTerc` ainda precisa ser conciliada antes de substituir a funcao.**
- Foram definidos 39 testes, incluindo datas de descontinuacao, quantidades, precisao, normalizacao documental, representante e fornecedor SA2 ausente/inativo/ambiguo, destinos por nota, agrupamento multi-nota, conflito de pedido original, referencias consolidadas, serie incompativel, escape SQL, selecao individual/em massa e modo de saldo. `ZMOSTST()` e estatica e fica subordinada ao botao **Testes**; o resumo aparece na tela e os casos no console.
- O linter local interrompe a analise com `C2090 File not found PRTOPDEF.CH`. O arquivo existe tanto no diretorio configurado C:\totvs\includes quanto em Fontes/includes; a causa de resolucao/pre-processamento ainda nao foi determinada. Configuracao e headers padrao nao foram alterados.
- O usuario informou que compilou e executou a primeira versao, mas a tela nao apareceu, sem mensagem. Na revisao `20261104-02`, foi removido o bloqueio previo por area util minima de 1024 x 680; o painel de filtros passa a ajustar sua proporcao pela altura disponivel. MsAdvSize, filtros e construcao do FWLayer agora ficam dentro do tratamento de erros. Essa correcao ainda precisa ser confirmada no cliente.
- A abertura registra `[ZMOST][TELA] Inicio U_ZMOST; revisao=20261104-02`, a area util, `Ativando janela` e, no evento On Init, `Janela ativada`. Uma falha apresenta MsgStop e registra a etapa. Ausencia do marcador inicial no console da sessao indica que a entrada desta revisao nao foi atingida; conferir chamada, ambiente e RPO antes de atribuir o problema ao layout.
- O console anexado pelo usuario comprova compilacao de ZMOST e atualizacao de rpocustom.rpo em TOTVS_SUNTECH_TESTE as 14:54:21 de 04/11/2026. AppServer 24.3.1.9, build 7.00.240223P; fontes padrao do stack datados de 14/08/2026. O erro local de include nao corresponde a uma falha comprovada dessa compilacao no servidor.
- Na thread 3093394, chamada a partir do ExecFonte em empresa/filial 01/01, a revisao 20261104-02 registrou inicio as 14:56:17 e area util 1270 x 445. O trecho ate 14:57:03 nao contem `Ativando janela`, `Janela ativada` nem `Falha`. Isso localiza o bloqueio antes da ativacao, mas nao identifica sozinho qual construtor ou acesso ao dicionario aguardou. Os erros de encerramento de Schedule ocorreram durante o build, antes dessa chamada; nao foram vinculados causalmente ao cockpit. O aviso do latencylog tambem nao comprova a causa da falha de abertura.
- A revisao `20261104-03` registrou a janela antes da montagem do cockpit; o `ZMBuild` foi movido para o ON INIT e recebeu logs por etapa. Esse registro e historico, nao descreve a revisao atual.
- Os 19 testes da revisao anterior foram executados no Protheus em 05/11/2026, com zero falhas. A revisao `20261105-05` adicionou agrupamento e teste de notas; `20261105-06` acrescentou logs; `20261105-07` removeu a TES 6V1 implicita; `20261105-08` removeu o filtro extra `B6_PODER3='R'`; `20261105-09` instrumentou a comparacao; `20261105-10` usa `B6_SALDO` no periodo completo atual e `ESTCalcTerc` em periodos personalizados; `20261106-01` dimensiona colunas pelo SX3 ou pelo titulo; `20261106-02` desativou o autoajuste, mas a captura mostrou colunas mais comprimidas; `20261106-03` reativa o autoajuste; `20261106-04` adiciona selecao por checkbox na nota e em massa pelo cabecalho; `20261106-05` corrige largura e altura invertidas na grade de detalhes; `20261106-06` define explicitamente `lPixel=.T.` nessa grade, alinhando suas coordenadas ao `MsDialog Pixel`; `20261106-07` reduz a largura; `20261106-08` reduz largura e altura; `20261106-09` reduz novamente a grade e reserva mais espaco para os botoes do rodape; `20261106-10` habilita explicitamente as barras horizontal e vertical no viewport da grade; `20261106-11` recalcula o layout do modal no espaco de coordenadas dos controles (cerca de metade das dimensoes do dialogo, conforme medido nas capturas), mantendo grade e botoes dentro da janela. A revisao `20261106-12` adiciona validacao SA2, modos de destino por nota, agrupamento multi-nota, 37 testes definidos e executor sequencial MATA103/MATA410 com acompanhamento nao persistente. Conforme confirmado pelo usuario, o DEV em `:1607` e a base definitiva deste teste. **A revisao visual, os 37 testes, a compilacao no RPO, o saldo runtime e o executor fiscal ainda precisam de validacao/homologacao.** Checks estaticos nao substituem homologacao no RPO.
9. Em homologacao e com piloto fiscal aprovado, compilar o fonte atual no RPO, conferir os 39 testes e validar as oito etapas, SF1/SD1, SC5/SC6, SC9, SF2/SD2 e saldo SB6. A autorizacao da NF-e deve ser acompanhada pelo AUTONFE. Em falha apos criar documentos, nao repetir o fluxo: reconciliar e retomar manualmente a etapa pendente. Testar duas origens compativeis nos modos individual e consolidado; testar tambem a recusa de consolidacao para series, participantes ou condicoes comerciais divergentes.

### Roteiro de aceite no Protheus

1. Compilar ZMOST no ambiente de homologacao, com includes da release instalada. Resolver o C2090 de ambiente se tambem ocorrer no compilador conectado e registrar quaisquer erros reais do fonte.
2. Executar o botao **Testes** e conferir 39 casos aprovados, zero falhas.
3. Compilar a versao local atual no RPO de homologacao e executar `U_ZMOST()` na empresa 01/filial 01. Conferir abertura, Consultar, Previa, selecao por nota/item, modal e visibilidade do botao Renovar. Executar os 39 testes e comparar a consulta com MATR480, inclusive `R00107/01`, nota `000286778/3`. Nao iniciar Renovar ate validar saldo e autorizacao da nota de origem.
4. Consultar R00107/01, nota 000286778/3, TES 6V1 e periodo 01/01/1900 a 04/11/2026. Comparar saldo positivo item a item com MATR480 na primeira unidade e parametros equivalentes; o resultado runtime ainda nao tem contagem de aceite definida.
5. Conferir datas de descontinuacao, detalhes da origem e retornos. Escolher quantidade parcial e destino de um descontinuado; a previa deve separar as unidades e nao gerar documentos.
6. Consultar com cliente e representante vazios para listar notas de todos os representantes na filial. Se o limite de 20.000 origens for excedido, confirmar erro claro e ausencia de resultado parcial. Testar quantidade zero/excedente, data invalida/futura, consulta vazia e cadastro pendente; selecao com pendencia nao deve permitir previa completa.
7. Testar nova consulta/limpeza, redimensionamento, foco, navegacao horizontal, clientes/lojas distintos e erro de consulta. Nenhum resultado parcial deve permanecer selecionavel apos falha.
8. No modo Previa, confirmar ausencia de novas SF1/SD1, SC5/SC6 e movimentos fiscais.
9. Em homologacao e com piloto fiscal aprovado, validar os modos individual e consolidado, as oito etapas e a reconciliacao SF1/SD1, SC5/SC6, SC9, SF2/SD2 e SB6. Nao repetir automaticamente apos falhas; confirmar se a saida foi autorizada no AUTONFE e reconciliar os documentos antes de retomar.

## 12. Atualizacao do executor em 09/11/2026

- O fonte local `Fontes/SIGAFAT/ZMOST.prw` agora oferece os modos individual (uma entrada, pedido e nota de saida por nota de origem) e consolidado (um conjunto para origens compativeis). A consolidacao exige mesma serie, cliente/loja, fornecedor/loja, cabecalhos comerciais compativeis nos pedidos originais e referencias que caibam em `C5_ZZOBS`; cada item preserva nota, serie, item e identificador SB6 em SD1.
- Depois de conferir MATA410/SC5/SC6, o executor libera as quantidades por `MaLibDoFat`, valida SC9 integralmente, fatura com MATA461/`MaPvlNfs` e confere SF2/SD2 e `C5_NOTA`. Serie fiscal e data prevista sao informadas pelo operador. A transmissao/autorizacao permanece no AUTONFE padrao.
- O modo efetivo esta bloqueado fora de ambiente de teste/homologacao. Venda de itens descontinuados continua bloqueada ate aprovacao da matriz comercial. Falha apos gravacao nao dispara repeticao automatica; exige reconciliacao antes de retomar.
- A validacao local do editor nao apontou erros, e a analise estatica nao encontrou chamadas ZM sem definicao nem colisoes dos novos nomes de funcao. Os 39 testes AdvPL foram adicionados/atualizados, mas ainda nao executados no Protheus. Este fonte nao foi compilado/publicado no RPO e nao deve ser considerado homologado para emissao real.