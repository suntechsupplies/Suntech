# Testes de Integracao - APIs HB

Esta suite valida os contratos HTTP das APIs do diretorio `API's HB` em um ambiente de homologacao.

## Configuracao

Defina as variaveis de ambiente antes da execucao:

```powershell
$env:HB_API_BASE_URL = "https://servidor:porta/rest"
$env:HB_API_COMPANY = "01"
$env:HB_API_BRANCH = "01"
```

Escolha uma das formas de autenticacao abaixo.

Token Bearer ja obtido:

```powershell
$env:HB_API_TOKEN = "Bearer token-de-homologacao"
```

OAuth2 password grant:

```powershell
$env:HB_TOKEN_USERNAME = "usuario-de-homologacao"
$env:HB_TOKEN_PASSWORD = "senha-de-homologacao"
```

Quando `HB_TOKEN_URL` nao for informada, a suite usa `HB_API_BASE_URL + /api/oauth2/v1/token`. Defina `HB_TOKEN_URL` somente quando o endpoint OAuth estiver em outra URL.

As credenciais nao devem ser gravadas em arquivos do repositorio.

## Execucao

```powershell
py -3 -m unittest discover -s tests -p "test_*.py" -v
```

Sem `HB_API_BASE_URL` e sem uma das formas de autenticacao, os testes de API sao ignorados. Os cenarios mutaveis ficam desabilitados por padrao e exigem ativacao explicita.

## Inclusao rotativa de cliente

O teste `test_customers_create_rotating_test_customer` gera um CPF ficticio com digitos verificadores validos e o identifica pelo nome `AUTOTEST API HB`. Ele cria um novo registro a cada execucao e fica desativado por padrao, porque a API nao oferece exclusao de clientes.

Para habilita-lo apenas em homologacao:

```powershell
$env:HB_ENABLE_CREATE_TESTS = "true"
py -3 -m unittest tests.api_hb.test_contracts.ApiHbContractTests.test_customers_create_rotating_test_customer -v
```

## Cobertura inicial

- `CallCenter.prw`: validacao de POST/PUT sem rotina ou cabecalho, sem criar atendimentos.
- `Customers.prw`: consulta paginada e validacao de POST invalido.
- `Orders.prw`: consulta paginada e validacao de POST invalido.
- `GetXML.prw`: validacao de campos obrigatorios.
- `PRODUCTS.prw`: validacao de ID obrigatorio e consulta paginada.
- `TAXINVOICES.prw`: consulta da rota declarada.
- `ROMANEIOS.prw`: consulta da rota declarada.
- `Incidents.prw`: validação do contrato do evento financeiro de entrega, sem criação de instruções.
- `GENTOKEN.prw`: OAuth opcional, quando as credenciais forem informadas.
- `M410STTS.prw`: enfileiramento de pedido Marketplace elegível na tabela `ZTR` (teste opt-in).

O teste de contrato de `Incidents.prw` é ignorado por padrão porque a rota só existe após compilação e publicação no RPO de homologação. Para executá-lo depois da publicação:

```powershell
$env:HB_ENABLE_DELIVERY_FINANCIAL_EVENT_TESTS = "true"
py -3 -m unittest tests.api_hb.test_contracts.ApiHbContractTests.test_delivery_financial_events_requires_invoice_access_key -v
```

`CUSTOMERS.prw_old` e excluido por ser uma copia legada sem contrato ativo.

### CallCenter

O arquivo `callcenter_create_payload.json` usa uma combinacao de cabecalho e item encontrada nos CSVs de `SUA`/`SUB` do ambiente de teste `170774`. Mantem `oparation=2` para testar orcamento; os CSVs nao continham exemplos existentes com essa operacao. Quando informado, `processStatusCode` deve vir junto com `processStatusDescription`; a API grava o codigo em `UA_ZZSTATU` e a descricao em `UA_ZZDSTAT`. A chamada real `POST /callcenter` cria um atendimento e so e executada com opt-in explicito. Aponte a URL para o ambiente de teste, nao para producao:

```powershell
$env:HB_API_BASE_URL = "https://suntechsupplies170774.protheus.cloudtotvs.com.br:1607/rest"
$env:HB_ENABLE_CALLCENTER_CREATE_TESTS = "true"
py -3 -m unittest tests.api_hb.test_contracts.CallCenterContractTests.test_post_creates_attendance_from_homologation_payload -v
```

Cada execucao habilitada pode criar um novo atendimento. Confira ambiente, cliente, itens e autorizacao antes de habilitar.

### Fila de reabastecimento ZTR

O teste `test_orders_marketplace_enqueues_replenishment` cria um pedido pela API `POST /orders` na filial 03 com `financialStatus = "7"` (pago), `commercialStatus = "1"` e `isReleased = "S"`. Confere a situacao financeira na SC5, o cabecalho e a quantidade integral por item na SC9, sem bloqueio de credito e sem nota fiscal. Para gerar a reposicao, aceita `C9_BLEST` vazio ou `02`: a falta de estoque na origem e justamente o motivo do abastecimento, nao um impedimento para criar o espelho. Isso nao significa liberacao de estoque para faturamento. No enfileiramento, a solicitacao na ZTR deve ficar em `AG_LIB`, com `ZTR_LIBOK = "N"`, pois o PE e executado antes da liberacao aplicada pela API; sua confirmacao cabe ao validador. O teste nao realiza baixa financeira, nao fatura nem cria o pedido espelho. Ele e desativado por padrao e deve ser executado somente em homologacao, com a ZTR fisica criada e os fontes publicados no RPO.

O fonte `Fontes/SIGAFAT/ZTRVALID.prw` contem o validador e o processador manual por pedido. Compile-o e execute `U_ZTRPROC()` na filial 03. Informe o pedido de origem e um pedido modelo da filial 02 com tabela TTR, cliente S00003/01, origem INT, tipo TR e itens com TES/operacao/armazem uniformes. O modo inicial e Simular; Efetivar exige confirmacao e cria somente o pedido, sem liberar, faturar ou registrar entrada. O job usa o cabecalho/configuracao fiscal do modelo e exige preco TTR ativo, vigente, em moeda 1 e sem ambiguidade de faixa para todos os produtos; nao utiliza o preco MKP como fallback. Cada origem recebe um identificador `ZR03` + numero no `C5_ZZNPEXT` do espelho, usado na recuperacao de tentativas interrompidas. So grava `ZTR_PEDTRF` e `CRIADO` apos conferir cabecalho e todos os itens. Uma simulacao nao altera SC5, SC6 ou ZTR; confira mensagens `[ZTR]` no console do AppServer.

Cada execução deixa um pedido de teste e um registro na `ZTR` para inspeção; não há exclusão automática, para preservar a evidência do teste.

O payload usa o produto `10105560149001`, quantidade 1 e preco MKP de 489,90, consultado em 26/10/2026; confirme sua vigencia antes de repetir em outro momento. Na mesma consulta, o preco TTR era 45,00. Ao excluir o pedido de origem pelo Protheus, o `M410STTS` (operacao 5) exclui logicamente a solicitacao ZTR apenas se nao houver espelho, tentativas de processamento ou status protegido. Solicitacoes com historico de reposicao sao preservadas para conferencia; o espelho nao e cancelado automaticamente. Compile o PE atualizado antes de excluir os pedidos de teste e confira o resultado na fila. O teste de inclusao nao executa exclusoes.

```powershell
$env:HB_ENABLE_ZTR_ENQUEUE_TESTS = "true"
py -3 -m unittest tests.api_hb.test_contracts.ApiHbContractTests.test_orders_marketplace_enqueues_replenishment -v
```

### Orquestrador ZTR

Guia tecnico e operacional completo: [Fluxo automatico de transferencia interfilial ZTR](../../docs/fluxo_transferencia_interfilial_ztr.md).
Inclui AutoNFe, FISVALNFE, parametros, fontes, agendamentos, tabelas, recuperacao e evidencias.

Compile `Fontes/SIGAFAT/ZTRSCHED.prw`, `Fontes/SIGAFAT/ZTRORQ.prw`, `Fontes/SIGAFAT/ZTRVALID.prw`,
`Fontes/SIGAFAT/ZTRXML.prw`, `Fontes/SIGACOM/PE_IMPORTADOR/ZTREND.prw` e
`Fontes/SIGACOM/PE_IMPORTADOR/ZTRCOL.prw` no mesmo ambiente.
O controlador `U_ZTRORQ(cEmpresa, cModelo, cSerie, lEfetiva, nLimite)` abre um job
isolado, percorre um lote por antiguidade e executa no maximo uma acao por pedido
em cada rodada. Sem argumentos, usa a empresa da sessao e somente simula.

Parametros do controlador, lidos na filial 03:

| Parametro | Tipo | Padrao | Finalidade |
| --- | --- | --- | --- |
| `MV_ZTRAUT` | Logico | `.F.` | Autorizar rodadas efetivas |
| `MV_ZTRMOD` | Caractere | Vazio | Pedido modelo TTR existente na filial 02 |
| `MV_ZTRSER` | Caractere | Vazio | Serie fiscal previamente validada na filial 02 |
| `MV_ZTRFAT` | Logico | `.F.` | Autorizar faturamento automatico em homologacao |
| `MV_ZTRMAX` | Numerico | `5` | Limite de tentativas acumuladas na ZTR |

Teste primeiro pela filial 03, no ExecFonte, com a chamada sem gravacao:

```advpl
U_ZTRORQ("01", "", "", .F., 20)
```

Os argumentos vazios acima permitem acompanhar espelhos existentes. Para criar
novos espelhos ou conferir faturamento, informe modelo e serie validos; omitindo
esses argumentos, os valores sao obtidos dos parametros. A simulacao nao grava
ZTR/SC5/SC6, nao libera, nao fatura, nao publica XML nem endereca. O retorno e
`{sucessoDoLote, resumo, {{pedido, sucesso, etapa, mensagem}, ...}}` e os logs usam
`[ZTRORQ]`. Falhas individuais nao impedem a conferencia dos demais pedidos.

Para o Schedule, use a entrada sem argumentos `U_ZTRSCHED`, cujo fonte define
`SchedDef()` como processo, sem grupo de perguntas, permitindo selecionar filiais
e sem permitir a opcao Sempre Ativo. O proprio Schedule prepara o ambiente; a
entrada recusa ambiente nao inicializado ou filial diferente de 03. Ela le
`MV_ZTRAUT` na empresa/filial do cadastro e chama o controlador em job isolado,
usando `MV_ZTRMOD` e `MV_ZTRSER` e lote de 20 solicitacoes.

Cadastro inicial:

1. Acesse SIGACFG -> Ambiente -> Schedule -> Schedule, no ambiente de homologacao.
2. Confira um Agent habilitado no mesmo ambiente e com acesso ao RPO atualizado.
3. Inclua um agendamento com rotina `U_ZTRSCHED`, sem parenteses ou argumentos.
4. Selecione empresa 01 e somente filial 03, com usuario autorizado as operacoes
	nas filiais 02 e 03.
5. Configure recorrencia a cada minuto, data/hora de inicio e o Agent correto.
	Nao selecione Sempre Ativo nem cadastre uma segunda execucao para a filial 02.
6. Mantenha `MV_ZTRAUT=.F.` para as primeiras rodadas: a entrada apenas simula.
7. Confira o historico do Schedule e os logs `[ZTRSCHED]` / `[ZTRORQ]`. Depois de
	validar os resultados, altere `MV_ZTRAUT` para `.T.` na filial 03 para efetivar.

Nao informe `U_ZTRORQ("01",...)` no campo Rotina e nao agende `U_ZORUN` diretamente.
`U_ZTRORQ` continua disponivel para chamadas manuais parametrizadas e permanece
em simulacao por padrao. `MV_ZTRFAT` continua sendo uma autorizacao separada para
faturamento. O bloqueio por empresa impede rodadas sobrepostas; as rotinas de
criacao, liberacao e faturamento preservam seus bloqueios por solicitacao.
O controlador aceita lotes entre 1 e 100 pedidos nas chamadas manuais.

Fluxo: validar origem -> criar espelho -> liberar -> faturar (opt-in) -> aguardar
autorizacao fiscal -> publicar XML -> aguardar Monitor/SCHEDCOMCOL -> enderecar ->
conferir SDA/SDB. A emissao permanece restrita a teste/homologacao. No modo
automatico, `MT460A` e carregado sem tela: valide previamente seus parametros
para o usuario/ambiente do agendamento. A transmissao ao TSS e a leitura e geracao
da entrada pelo Monitor continuam dependendo dos agendamentos padrao configurados;
o controlador nao transmite, nao reimporta manualmente nem contorna rejeicoes.

O `MT103FIM` pode enderecar imediatamente com `MV_ZTREND=.T.`; o controlador tambem
recupera entradas pendentes pela `U_ZTREND`. A conclusao exige nota integral,
autorizacao 100 sem cancelamento, chave fiscal unica, TES correta, saldo SDA zero
e distribuicao por produto/lote/endereco/quantidade correspondente a saida.
O fluxo e especifico de 03/02, cliente `S00003/01` e fornecedor `F02283/01`.

Nao foram criados estados ou campos de dicionario: o estado `CRIADO` e preservado
para compatibilidade com o publicador, e `ZTR_MSGERR` recebe `ZOR:<etapa> mensagem`.
`ZOR:CONCLUIDO ` retira a solicitacao das proximas rodadas. `CRIANDO`, `ERRO_REP`
e estados inconsistentes exigem recuperacao manual com conferencia dos documentos
existentes; nao sao recriados automaticamente. Erros posteriores a criacao
incrementam `ZTR_TENTAT`, que ja inclui tentativas de criacao; atingir o limite
suspende o processamento. Esperas normais nao incrementam tentativas. Antes de
reabilitar um pedido suspenso ou concluido, confira cancelamentos, documentos e
enderecamentos pelas rotinas padrao. Nao limpe vinculos ou marcadores por SQL.

O ciclo integral pelo Schedule foi comprovado em homologacao em 29/10/2026,
incluindo o pedido cronometrado 005951 e os pedidos 005953/005954 com dois produtos
e clientes distintos. Ver o guia completo e os relatorios de teste para horarios,
evidencias no banco e limitacoes. Isso nao equivale a homologacao de todos os
cenarios ou autorizacao de uso em producao; diagnosticos locais nao substituem
compilacao no RPO.

## EJTitulo

Os testes de titulos sao somente leitura. Eles consultam a primeira pagina e uma pagina sem dados; a baixa financeira via `PUT /EJTitulo` nao e automatizada.

```powershell
$env:EJECTY_API_BASE_URL = "https://servidor:porta/rest"
$env:EJECTY_TENANT_ID = "01,01"
py -3 -m unittest tests.api_hb.test_contracts.EjectyTitleContractTests -v
```

## Sincronizacao De Pagamentos

O fluxo de pagamento usa o formato retornado pelo Mercado Pago no `PUT /EJTitulo`. Como essa rota baixa titulos e pode gerar lancamentos financeiros, a execucao real deve ser explicitamente habilitada e as credenciais dos provedores devem ficar apenas em variaveis de ambiente.

Use `payment_payload.example.json` como formato de fixture local e informe seu caminho:

```powershell
$env:EJECTY_PAYMENT_PAYLOAD_FILE = "caminho\payment_payload.json"
py -3 -m unittest tests.api_hb.test_ejtitulo_payment_sync -v
```

Nao grave tokens Shopify, Mercado Pago ou TOTVS em fontes de teste.

### Simulacao De Sincronizacao

O simulador abaixo reproduz apenas a selecao de titulos pendentes do fluxo de pagamento. Ele nao chama provedores externos e nao executa `PUT /EJTitulo`.

```powershell
$env:EJECTY_API_BASE_URL = "https://servidor:porta/rest"
$env:EJECTY_TENANT_ID = "01,01"
py -3 tests/api_hb/ejecty_payment_sync_dry_run.py
```