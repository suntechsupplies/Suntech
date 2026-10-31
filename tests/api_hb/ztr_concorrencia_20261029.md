# Teste concorrente ZTR - 2026-10-29

## Escopo autorizado

Dois pedidos enviados em paralelo na homologacao 170774, empresa 01/filial 03.
Cada pedido contem dois produtos, quantidade 1 de cada. Total solicitado:
dois pedidos, quatro itens, duas unidades de cada produto. Nenhum reenvio de POST.

| Produto | Descricao | Preco MKP | Preco TTR | Saldo disponivel por endereco na 02 antes do teste | Endereco |
| --- | --- | --- | --- | --- | --- |
| 10105560149001 | Produto do teste anterior | 489,90 | 45,00 | 15 | G18D |
| 10100020243024 | OC HB ROCKER 2.0 MATTE BLACK BLUE CHROME | 409,90 | 44,38 | 36 | H13B |

Os dois enderecos existem no armazem 02 da filial 03. Precos ativos, moeda 1,
vigentes e sem ambiguidade na ultima vigencia conferida. O lote usa tabela MKP,
cliente C30156/03, condicao 194, TES de venda 6C5, origem B2C, subtipo HB,
financeiro 7, comercial 1 e liberacao S. Total de cada pedido: 899,80.
Modelo de transferencia 298377 e serie 1; MV_ZTRAUT/MV_ZTRFAT logicos .T.

## Disparo

Limite deste teste: o POST /orders foi usado pelo assistente apenas para gerar
pedidos. O usuario esclareceu que o sistema real nao utiliza essa API para incluir
pedidos. O fluxo ZTR recebe pedidos ja gravados pelo M410STTS e nao chama a API.
Portanto, o lock SA1 e o erro do segundo POST nao comprovam falha de concorrencia
do orquestrador. As alteracoes experimentais de protecao na API foram removidas;
nao foram feitas alteracoes funcionais no fluxo ZTR nesta revisao de escopo.
Um teste representativo de concorrencia deve partir de pedidos incluidos pelo
caminho real do sistema e acompanhar sua selecao pela fila.

Dois trabalhadores no mesmo cliente foram sincronizados por barreira e enviaram
um POST /orders cada. As marcas de envio do cliente diferem em 1 ms; isso
comprova disparo concorrente do cliente, nao inicio simultaneo de processamento
no servidor. O orquestrador continua selecionando e processando a fila de forma
controlada, com os bloqueios existentes.

| Disparo | externalId | ecommerceOrder | Envio (-03:00) | Resultado da chamada |
| --- | --- | --- | --- | --- |
| 1 | ZTE75E43BC | MKPEE5556224B | 12:28:53.980 | HTTP 201 as 12:29:05.199; pedido 03/005952, recno 213728; duracao 11,219 s |
| 2 | ZT6E88AB76 | MKP9DF20DA1ED | 12:28:53.979 | Timeout de leitura apos 30,198 s; log posterior confirma erro MATA410 as 12:30:45, sem pedido encontrado |

O timeout do disparo 2 nao comprova rollback nem ausencia de inclusao. Nao repetir
o POST. Recuperar primeiro a SC5 da filial 03 por C5_ZZNPEXT=ZT6E88AB76 e a ZTR
por ZTR_APIID=ZT6E88AB76, sempre filtrando registros ativos.

## Acompanhamento

A primeira consulta de recuperacao nao chegou ao RESTQry: a autenticacao OAuth
tambem terminou com timeout de leitura. Em uma tentativa posterior, exclusivamente
de leitura, a API voltou a responder.

Resultados confirmados no banco:

- Disparo 1: exatamente um pedido ativo 03/005952, com dois itens distintos,
	quantidade 1 cada, precos MKP 489,90 e 409,90, TES 6C5, pago/aprovado/liberado.
- Schedule criou espelho 02/298380, com os mesmos produtos, quantidade 1 cada,
	precos TTR 45,00 e 44,38, TES 5F3, armazem 02.
- Schedule gerou NF 000209489/1, dois itens, vinculada ao espelho 298380.
	Chave 32261004175844000396550010002094891813410208.
- Fila do pedido 005952: uma tentativa, ZOR:CONCLUIDO as 12:41:16.
- NF autorizada com F3_CODRSEF=100, sem cancelamento.
- Monitor: retorno do XML as 12:36:31, importacao as 12:40:31, status 2, sem erro.
- SD1: dois itens ativos, quantidade 1 cada, TES 1J2 e armazem 02.
- Primeiro produto: sequencial 9AOHGA, SDA=0, SDB=1 em G18D, sem estorno.
- Segundo produto: sequencial 9AOHGB, SDA=0, SDB=1 em H13B, sem estorno.
- Disparo 2: nao localizado na SC5 por externalId nem ecommerceOrder, incluindo
	registros ativos e excluidos, e nao localizado na ZTR por identificador.
	Na captura de pedidos da filial 03 a partir de 005952, somente 005952 existia.
	A consulta de 12:48:44 novamente encontrou somente 005952 no lote.

## Evidencias recuperadas nos logs atualizados

Os logs atualizados cobrem ate 12:46. No pedido 005952:

- 12:36:31.483113: XML publicado em IN.
- 12:41:02.049372: MT103FIM confirmou inclusao da NF 000209489/1.
- 12:41:02.445116 / 12:41:02.492585: plano identificou G18D e H13B.
- 12:41:04.209302: executados=2, pendentes=2, VALIDADO SDA/SDB.
- 12:41:04.210379: U_ZTREND concluiu com itens=2 e resultado=OK.
- 12:41:16.948784: controlador confirmou CONCLUIDO, sem repetir distribuicao.

O enderecamento efetivo deste documento foi acionado pelo MT103FIM. Depois, o
controlador chamou U_ZTREND em simulacao e confirmou que nao havia saldo pendente.
Tempo aproximado do envio do pedido 005952 ate conclusao: 12 min 23 s.

O segundo POST e identificado na thread 2140051 do AppServer REST especial 1:

- 12:28:56.186423: payload com externalId ZT6E88AB76.
- 12:28:56.186977: inicio de MsExecAuto MATA410, com duas linhas de itens.
- Snapshots de 12:29/12:30: tentativa de bloquear recno 28351 do alias SA1,
  iniciada as 12:29:04.
- 12:30:45.875628: MsExecAuto terminou com lMsErroAuto=.T.
- 12:30:45.883957: AJUDA:A410NAOREG, "Nao ha registros a serem gravados no
  SC6 - Itens do Pedido de Vendas".
- 12:30:45.930232: falha ao escrever a resposta REST (Error -100); a conexao do
  cliente ja havia expirado.

Isso comprova que a requisicao chegou ao servidor e terminou com erro no MATA410,
nao que o cliente deixou de envia-la. A espera por lock de SA1 foi observada,
mas o detentor do lock e a relacao exata com A410NAOREG ainda exigem diagnostico.
Nao afirmar deadlock SQL sem evidencia adicional.

Tambem houve erro de chave duplicada em update de CKOCOL as 12:40:31, durante
COLAUTOREAD. Apesar desse erro, a importacao e a entrada deste documento foram
confirmadas no banco e o ciclo concluiu; a ocorrencia nao deve ser ocultada nem
confundida com a falha anterior do segundo POST.

Nao foram acionados manualmente faturamento, transmissao, XML, importacao ou
enderecamento. Nao foi criado outro pedido para substituir o disparo sem resposta.

## Resultado do primeiro lote

- Fluxo de um pedido com dois produtos: concluido e comprovado no banco.
- Lote concorrente de duas inclusoes: nao aprovado; segundo POST terminou com erro.
- Diagnosticar lock SA1 e A410NAOREG na criacao concorrente antes de repetir o lote.
- Avaliar separadamente a ocorrencia de chave duplicada do Monitor.
- Nenhuma nova inclusao ou reenvio foi executado nesta verificacao.

## Repeticao autorizada com clientes distintos

O usuario autorizou uma nova execucao com dois clientes diferentes, sem alterar
a API ou o orquestrador. A API foi usada exclusivamente como gerador de teste.
Foram selecionados clientes ativos, pessoa fisica, estado SP, condicao 194 e
historico de pedidos MKP na filial 03, com registros SA1 diferentes:

- C30156/03, recno SA1 28351.
- C07896/01, recno SA1 8174.

Saldo por endereco antes do novo lote: 14 unidades disponiveis do produto
10105560149001 em G18D e 35 do produto 10100020243024 em H13B, filial 02/local02.
Cada pedido recebeu novamente dois itens, quantidade 1 cada, total MKP 899,80.
As marcas de envio diferem em 2 ms.

| Disparo | Cliente | externalId | ecommerceOrder | Envio (-03:00) | Resultado da chamada | Pedido confirmado no banco |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | C30156/03 | ZT21D32E42 | MKPEA88CD01B9 | 13:11:15.007 | Timeout de leitura apos 30,086 s | 03/005953 |
| 2 | C07896/01 | ZTA48111B2 | MKP9E5299B64F | 13:11:15.005 | HTTP 201 as 13:11:26.662, duracao 11,657 s | 03/005954 |

Exatamente dois POSTs enviados nessa repeticao, sem reenvios. A consulta posterior
confirmou uma SC5 ativa e uma solicitacao ZTR para cada identificador. Os dois
pedidos tem financeiro 7, comercial 1, liberacao S e os dois itens esperados,
quantidade 1 cada, precos 489,90/409,90 e TES 6C5. O timeout do pedido 005953
nao significou falha de gravacao.

Evolucao capturada no banco:

- 13:14:24: 005953 ainda em AG_LIB por SC9 insuficiente na verificacao anterior;
	005954 ja estava com espelho 298381 liberado.
- 13:16:14: os dois pedidos ja tinham espelhos, sem acao manual.
- 005953 -> 298382: ZOR:LIBERADO as 13:15:55, tentativa 1, aguardando rodada fiscal.
- 005954 -> 298381 -> NF 000209490/1: ZOR:AG_NFE as 13:15:49, tentativa 1.
- Os dois espelhos possuem dois itens, quantidade 1 cada, precos TTR 45,00/44,38,
	TES 5F3, armazem 02, cliente S00003/01 e identificador ZR03 correspondente.
- A nova consulta SC9 da origem 005953 encontrou quantidade 1 por item, credito
	vazio e estoque vazio/02, condicao aceita para reposicao; nada foi desbloqueado
	manualmente pelo assistente.

Captura de 13:17:55.693: ambos em AG_NFE, tentativa 1. O pedido
005953/espelho 298382 ja gerou NF 000209491/1, acompanhamento as 13:17:26.
O pedido 005954/espelho 298381 segue com NF 000209490/1, acompanhamento as
13:17:21. Nenhuma tinha retorno fiscal 100 nessa leitura. A chave da NF
000209490 ja estava preenchida; a de 000209491 ainda estava vazia.

Nova captura de 13:24:04.710 e logs atualizados ate 13:21:

- As duas notas estavam autorizadas, retorno fiscal 100 e sem cancelamento.
- NF 000209490: XML publicado em IN as 13:20:46.143798; controlador registrou
	AG_ENTRADA as 13:20:47.620942. CKOCOL registra retorno 13:20:46 e importacao
	13:20:49, status 2, sem CKO_CODERR.
- NF 000209491: XML publicado em IN as 13:20:52.523044; controlador registrou
	AG_ENTRADA as 13:20:53.879581. Ainda nao havia registro ativo CKOCOL para essa
	nota na consulta de 13:24.
- As duas filas permaneciam em AG_ENTRADA, tentativa 1, sem falha do publicador.
- Ainda nao havia SD1 ativa de nenhuma dessas notas na filial 03; portanto,
	entrada e enderecamento dos quatro itens nao estavam concluidos.
- A publicacao do segundo XML ocorreu depois da marca de importacao do primeiro;
	isso e compativel com aguardar nova varredura, mas nao prova o escalonamento
	interno do Importador. Nao foi forcada reimportacao ou classificacao manual.

## Conclusao da repeticao com clientes distintos

Consulta de 13:27:01.677 confirmou os dois ciclos concluidos:

| Pedido origem | Espelho | NF | Conclusao ZTR | Tempo desde envio, aproximado | Tentativas |
| --- | --- | --- | --- | --- | --- |
| 005953 | 298382 | 000209491/1 | 13:26:30 | 15 min 15 s | 1 |
| 005954 | 298381 | 000209490/1 | 13:26:26 | 15 min 11 s | 1 |

As duas notas estavam autorizadas, sem cancelamento. As entradas da filial 03
possuem dois itens cada, quantidade 1 por produto e TES 1J2:

| NF | Produto | Sequencial entrada | Saldo SDA | Quantidade SDB | Endereco | Estorno |
| --- | --- | --- | --- | --- | --- | --- |
| 000209490 | 10105560149001 | 9AOHGG | 0 | 1 | G18D | Nao |
| 000209490 | 10100020243024 | 9AOHGH | 0 | 1 | H13B | Nao |
| 000209491 | 10105560149001 | 9AOHGI | 0 | 1 | G18D | Nao |
| 000209491 | 10100020243024 | 9AOHGJ | 0 | 1 | H13B | Nao |

Resultado da repeticao: dois pedidos com clientes distintos enviados em paralelo,
dois espelhos e duas notas, com quatro itens concluidos automaticamente e sem
reenvio. A API foi somente gerador do teste, sem alteracoes de codigo. O
orquestrador processou a fila de forma controlada, nao por faturamentos simultaneos.

Ressalva: somente uma chamada retornou 201 dentro do timeout do cliente; a outra
teve gravacao confirmada posteriormente no banco. Portanto, o teste valida a
conclusao dos dois fluxos, mas nao elimina o problema de tempo de resposta do
gerador nem comprova que compartilhar o cliente era a unica causa anterior.
Os horarios de conclusao tem precisao de segundos e incluem esperas de Schedule.