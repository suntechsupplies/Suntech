# Teste cronometrado ZTR - pedido 005951

## Identificacao

- Ambiente: homologacao 170774, empresa 01, origem 03, transferencia 02 -> 03.
- Data: 2026-10-29. Horarios locais com referencia -03:00.
- Pedido origem: 03/005951, recno SC5 213726.
- externalId: ZTB5A493FE. ecommerceOrder: MKP99DDF051C9.
- Espelho criado automaticamente: 02/298379, identificador ZR03005951.
- NF de saida gerada automaticamente: 000209488/1.
- Chave NF-e: 32261004175844000396550010002094881580715110.
- Sequencial de saida: 9AOHG6. Sequencial de entrada: 9AOHG7.
- Produto: 10105560149001, quantidade 1, preco MKP 489,90, TES origem 6C5.
- Modelo configurado: 298377. Serie: 1. TES de entrada: 1J2.
- MV_ZTRAUT e MV_ZTRFAT: logicos .T.; MV_ZTRMAX: numerico 5.
- Exatamente um POST /orders enviado. Nao repetir a inclusao deste teste.
- Nao foram acionadas manualmente liberacao, faturamento, transmissao,
  publicacao XML, importacao ou distribuicao por endereco.

## Criterio de medicao

O inicio e o instante imediatamente anterior ao POST /orders. A duracao do POST
usa relogio monotonico do cliente. O relogio do banco foi conferido antes do
teste: 11:55:11.563, com resposta observada localmente as 11:55:11.851-03:00.
As marcas ZTR_DTATU/ZTR_HRATU tem precisao de segundos e sao sobrescritas a cada
rodada. As capturas abaixo preservam os valores observados, mas nao representam
o instante exato de cada gravacao interna. Eventos ausentes devem ser recuperados
nos logs atualizados do AppServer. Nao tratar o horario de uma consulta posterior
como se fosse o horario da autorizacao ou da importacao.

## Marcos observados

| Marco | Horario em 29/10/2026 | Tempo desde envio | Evidencia |
| --- | --- | --- | --- |
| Envio do pedido | 11:55:52.004 | 0 s | Registro local antes do POST |
| Retorno HTTP 201 | 11:56:03.059 | 11,054 s de duracao medida | API retornou pedido 005951 |
| Enfileiramento e origem apta | Durante a inclusao; instante interno nao capturado | A confirmar nos logs | ZTR unica; SC5 paga/aprovada/liberada |
| Origem validada como PRONTO | 11:56:25.994648 | Aproximadamente 33,991 s | Log ZTR |
| Inicio do job de criacao | 11:56:26.008339 | Aproximadamente 34,004 s | Log de entrada U_ZTRJOB |
| Inicio da inclusao do espelho | 11:56:30.567084 | Aproximadamente 38,563 s | Log de criacao 02/298379 |
| Espelho confirmado pela rotina | 11:56:37.158939 | Aproximadamente 45,155 s | Log ZTR: CRIADO |
| Criacao registrada pelo controlador | 11:56:37.587583 | Aproximadamente 45,584 s | Log ZTRORQ, etapa CRIADO |
| Liberacao na filial 02 | 11:57:31.573864 | Aproximadamente 1 min 39,570 s | Log ZTRORQ, etapa LIBERADO |
| NF de saida confirmada pelo controlador | 11:58:50.757847 | Aproximadamente 2 min 58,754 s | Log ZTRORQ: Documento confirmado na SF2/SD2; NF 000209488/1 |
| Inicio da transmissao | 12:00:37.951112 | Aproximadamente 4 min 45,947 s | Log: transmitindo notas de 000209488 a 000209488 |
| Chave NF-e preenchida | Observada as 12:02:08.580; instante exato pendente | Ate aproximadamente 6 min 16,576 s | Chave 32261004175844000396550010002094881580715110 |
| Autorizacao 100 | Confirmada na consulta de 12:08:29; instante exato pendente | Ate aproximadamente 12 min 37 s | F3_CODRSEF=100, F3_CODRET=M, sem cancelamento |
| XML detectado pelo publicador | Acompanhamento atualizado as 12:07:28; primeira publicacao ainda sem horario recuperado | Aproximadamente 11 min 36 s ate esse acompanhamento | ZOR:AG_ENTRADA; Publicados=0; ignorados=1; falhas=0 |
| Retorno do XML registrado no CKOCOL | 12:06:28 | Aproximadamente 10 min 35,996 s | CKO_DT_RET/CKO_HR_RET; nao equivale ao instante exato da autorizacao ou da escrita do arquivo |
| XML importado no Monitor | 12:10:30 | Aproximadamente 14 min 37,996 s | CKO_DT_IMP/CKO_HR_IMP; status 2, Arquivo Retornado com sucesso, sem erro |
| Entrada gerada na filial 03 | Ate 12:11:13; instante exato pendente de log | Ate aproximadamente 15 min 20,996 s | SD1: produto 10105560149001, quantidade 1, TES 1J2, armazem 02, seq 9AOHG7 |
| Enderecamento confirmado | Ate 12:11:13; instante exato pendente de log | Ate aproximadamente 15 min 20,996 s | SDA=0; SDB=1 em G18D, local 02, sem estorno, igual a saida |
| Conclusao do controlador | 12:11:13 | Aproximadamente 15 min 20,996 s | ZTR_DTATU/ZTR_HRATU; ZOR:CONCLUIDO; tentativa 1 |

Primeira captura do banco: 11:57:13.847. Nesse momento o espelho estava sem nota
e sem liberacao do cabecalho, com ZTR atualizada as 11:56:37. Isso nao indica
falha: cada rodada do controlador realiza no maximo uma acao por solicitacao.

Captura de 11:59:33.490: a NF 000209488/1 ja existia, mas F2_CHVNFE e
F3_CODRSEF ainda estavam vazios. A fila foi atualizada as 11:59:21 para aguardar
autorizacao, com tentativa 1. A SC9 ja aponta essa NF; os marcadores 10 observados
apos o faturamento nao devem ser interpretados isoladamente como falha de
liberacao, pois a liberacao anterior foi comprovada e o documento ja foi gerado.

Duracoes parciais comprovadas pelos logs:

- Job de criacao: aproximadamente 11,151 s, da entrada ate a confirmacao do espelho.
- Inclusao/conferencia do espelho: aproximadamente 6,592 s.
- Intervalo entre etapa CRIADO e LIBERADO: aproximadamente 53,986 s, incluindo
    espera pela proxima rodada e a execucao da liberacao, nao apenas tempo de CPU.
- Intervalo entre LIBERADO e documento confirmado na SF2/SD2: aproximadamente
    1 min 19,184 s, incluindo espera pela rodada de faturamento.
- Intervalo entre documento confirmado e inicio da transmissao: aproximadamente
    1 min 47,193 s, incluindo espera pelo agendamento fiscal.

Captura de 12:03:35.040: pedido em AG_NFE, tentativa 1, acompanhamento atualizado
as 12:03:31. A SF3 estava com F3_CODRET=T, F3_CODRSEF vazio e sem cancelamento.
Ainda nao havia entrada na filial 03. Essa leitura nao comprova rejeicao nem
autorizacao. A primeira observacao anterior sem chave foi as 11:59:33.490;
a chave ja estava preenchida na captura de 12:02:08.580.

Na nova consulta de 12:08:29.043, a autorizacao fiscal estava confirmada com
retorno 100 e sem cancelamento. A fila estava em AG_ENTRADA, atualizada as
12:07:28, tentativa 1, com o publicador informando zero falhas e um documento
ignorado por ja existir. Como ainda nao havia entrada ativa, isso indica arquivo
detectado em IN ou LIDOS, nao comprova importacao pelo Monitor. CKOCOL, SD1, SDA
e SDB da entrada ainda estavam sem registros ativos correspondentes nessa captura.

Os logs locais atualizados cobrem ate 12:06:14: recuperados faturamento e inicio
da transmissao, mas ainda faltam a primeira publicacao do XML e o instante exato
da autorizacao. Atualizar os logs seguintes para fechar esses eventos e as
etapas de leitura, entrada e enderecamento sem inferir horarios.

## Sequencia funcional

| Ordem | Responsavel | Resultado esperado |
| --- | --- | --- |
| 1 | API /orders e PE de enfileiramento | SC5/SC6/SC9 origem e solicitacao ZTR |
| 2 | Schedule U_ZTRSCHED -> U_ZTRORQ | Selecionar solicitacao apta, sem duplicar |
| 3 | U_ZTRVALID -> U_ZTRJOB | Criar e conferir SC5/SC6 do espelho 02/298379 |
| 4 | U_ZTRLIB | Liberar espelho, sem bloqueio de credito ou estoque |
| 5 | U_ZTRFAT -> MaPvlNfs | Gerar uma unica NF de saida na filial 02 |
| 6 | Agendamento fiscal padrao -> TSS/SEFAZ | Transmitir e obter autorizacao 100 |
| 7 | U_ZTRXML -> U_GETXML | Publicar XML autorizado no diretorio IN |
| 8 | Importador/Monitor | Ler XML e formar SDS/SDT; A140IGRV aplica a TES |
| 9 | SCHEDCOMCOL e PEs COMCOL2/COMCOLF4 | Gerar SF1/SD1 na filial 03 com TES 1J2 |
| 10 | MT103FIM/U_ZTREND ou recuperacao do controlador | MATA265 distribui nos enderecos da saida |
| 11 | U_ZTRORQ | Conferir documentos, quantidades, lotes, TES e enderecos e concluir |

A chamada exata que realizar o enderecamento deve ser identificada nos logs;
nao presumir que foi MT103FIM se a recuperacao pelo controlador o executou.

## Fechamento

Ciclo concluido e comprovado no banco na consulta de 12:12:06.053:

- ZTR: ZOR:CONCLUIDO, pedido 005951 -> espelho 298379, tentativa 1.
- NF 000209488/1 autorizada, F3_CODRSEF=100, sem cancelamento.
- Monitor: um registro ativo, status 2, CKO_CODERR vazio.
- Entrada: uma unidade do produto, TES 1J2, armazem 02, seq 9AOHG7.
- SDA: quantidade original 1 e saldo 0.
- SDB destino: uma unidade em G18D/local 02, sem estorno.
- SDB origem: uma unidade em G18D/local 02, seq 9AOHG6, sem estorno.

Tempo total ate o acompanhamento de conclusao: **aproximadamente 15 min 21 s**,
do envio as 11:55:52.004 ate a marca ZTR de 12:11:13. A marca final possui
precisao de segundos; nao e uma medicao subsegundo da ultima gravacao do estoque.
O POST consumiu 11,054 s pelo relogio monotonico; a diferenca entre os horarios
locais impressos, arredondados a milissegundos, e de 11,055 s.

| Intervalo observado | Duracao aproximada | Interpretacao |
| --- | --- | --- |
| Retorno API -> criacao registrada | 34,529 s | Espera pelo Schedule e criacao do espelho |
| Criacao registrada -> liberacao | 53,986 s | Proxima rodada e liberacao |
| Liberacao -> NF confirmada | 1 min 19,184 s | Proxima rodada e faturamento |
| NF confirmada -> inicio transmissao | 1 min 47,193 s | Agendamento fiscal |
| Inicio transmissao -> retorno no CKOCOL | 5 min 50,049 s | Transmissao, servicos externos, atualizacao fiscal e disponibilizacao do XML; nao atribuir todo esse tempo a SEFAZ |
| Retorno CKOCOL -> importacao | 4 min 02 s | Janela observada entre retorno e importacao no Monitor |
| Importacao -> conclusao na ZTR | 43 s | Entrada, distribuicao e confirmacao do controlador; tempos individuais ainda dependem do log |

Permanecem pendentes apenas as marcas individuais de autorizacao, escrita do XML,
gravacao SF1/SD1 e MATA265, bem como a identificacao do acionamento pelo MT103FIM
ou pelo controlador. Isso nao invalida a conclusao comprovada nas tabelas, mas
impede atribuir duracoes exatas a cada uma dessas subetapas sem os logs seguintes.