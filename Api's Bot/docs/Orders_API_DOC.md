# Orders API - Documentação

**Versão:** 2.0  
**Autor:** Suntech  
**Endpoint Base:** `/orders`  
**Content-Type:** `application/json`

---

## Índice

- [Visão Geral](#visão-geral)
- [Autenticação e Ambiente](#autenticação-e-ambiente)
- [Endpoints](#endpoints)
  - [GET /orders - Listar Pedidos](#get-orders---listar-pedidos)
  - [GET /orders - Buscar Pedido Específico](#get-orders---buscar-pedido-específico)
  - [POST /orders - Criar Pedido (Unitário)](#post-orders---criar-pedido-unitário)
  - [POST /orders - Criar Pedidos (Lote)](#post-orders---criar-pedidos-lote)
  - [PUT /orders - Atualizar Pedido](#put-orders---atualizar-pedido)
- [Estruturas de Dados](#estruturas-de-dados)
  - [Cabeçalho do Pedido (Header)](#cabeçalho-do-pedido-header)
  - [Itens do Pedido](#itens-do-pedido)
- [Respostas Padrão](#respostas-padrão)
- [Códigos de Status HTTP](#códigos-de-status-http)
- [Validações](#validações)
- [Exemplos Completos](#exemplos-completos)

---

## Visão Geral

API REST para gerenciamento de Pedidos de Venda no Protheus (MATA410 - `SC5`/`SC6`). Suporta operações de consulta, criação (unitária e em lote) e atualização de pedidos de venda.

A API utiliza `MsExecAuto` para integrar com a rotina padrão `MATA410`, garantindo execução de todas as regras de negócio do sistema.

---

## Autenticação e Ambiente

| Parâmetro | Descrição |
|-----------|-----------|
| **Empresa** | Fixada como `"01"` |
| **Filial** | Padrão `"01"`, pode ser alterada via query parameter `branch` |
| **Tabelas** | `SC5`, `SC6`, `SA1`, `SA2`, `SA3`, `SA4`, `SB1`, `SB2`, `SE4`, `SF4`, `DA0`, `DA1` |

---

## Endpoints

---

### GET /orders - Listar Pedidos

Retorna uma lista paginada de pedidos de venda.

#### Query Parameters

| Parâmetro | Tipo | Obrigatório | Padrão | Descrição |
|-----------|------|:-----------:|--------|-----------|
| `page` | Integer | Não | `1` | Número da página |
| `pageSize` | Integer | Não | `100` | Quantidade de registros por página |
| `pending` | Integer | Não | `0` | `1` = Retorna somente pedidos sem nota fiscal |
| `branch` | String | Não | `"01"` | Código da filial |

#### Exemplo de Requisição

```
GET /orders?page=1&pageSize=20&branch=01
```

#### Exemplo de Resposta (200 OK)

```json
{
  "success": true,
  "message": "Orders retrieved successfully",
  "data": [
    {
      "orderNumber": "000123",
      "branch": "01",
      "externalId": "B2B-00456",
      "orderType": "N",
      "issueDate": "11/02/2026",
      "externalDate": "10/02/2026",
      "customerCode": "C00001",
      "customerStore": "01",
      "customerName": "CLIENTE EXEMPLO LTDA",
      "customerTaxId": "12345678000199",
      "paymentCondition": "001",
      "priceTable": "001",
      "salespersonCode": "000001",
      "carrierCode": "000001",
      "freightType": "C",
      "freightValue": 150.00,
      "currency": 1,
      "discountPercent": 5.00,
      "invoiceNumber": "",
      "invoiceSeries": "",
      "invoiceMessage": "MENSAGEM NA NOTA",
      "orderSource": "API",
      "orderSubtype": "",
      "couponCode": "",
      "observation": "OBSERVACAO DO PEDIDO",
      "recno": 12345,
      "items": [
        {
          "itemNumber": "01",
          "productCode": "PROD001",
          "productName": "PRODUTO EXEMPLO",
          "quantity": 10.00,
          "unitPrice": 25.50,
          "totalValue": 255.00,
          "operationCode": "",
          "discountPercent": 0.00,
          "tesCode": "501"
        }
      ]
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "totalPages": 5,
    "totalRecords": 98
  }
}
```

---

### GET /orders - Buscar Pedido Específico

Retorna um pedido específico por número do pedido ou ID externo.

#### Query Parameters

| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|:-----------:|-----------|
| `orderNumber` | String | Condicional* | Número do pedido (`C5_NUM`) |
| `externalId` | String | Condicional* | ID externo do pedido (`C5_ZZNPEXT`) |
| `branch` | String | Não | Código da filial (padrão `"01"`) |

> \* Pelo menos um dos dois (`orderNumber` ou `externalId`) deve ser informado.

#### Exemplo de Requisição

```
GET /orders?orderNumber=000123&branch=01
GET /orders?externalId=B2B-00456
```

#### Exemplo de Resposta (200 OK)

```json
{
  "success": true,
  "message": "Order found",
  "data": {
    "orderNumber": "000123",
    "branch": "01",
    "externalId": "B2B-00456",
    "orderType": "N",
    "issueDate": "11/02/2026",
    "customerCode": "C00001",
    "customerStore": "01",
    "paymentCondition": "001",
    "priceTable": "001",
    "salespersonCode": "000001",
    "carrierCode": "000001",
    "freightType": "C",
    "freightValue": 150.00,
    "currency": 1,
    "discountPercent": 0.00,
    "invoiceNumber": "",
    "invoiceSeries": "",
    "invoiceMessage": "",
    "orderSource": "API",
    "orderSubtype": "",
    "couponCode": "",
    "observation": "",
    "recno": 12345,
    "items": [
      {
        "itemNumber": "01",
        "productCode": "PROD001",
        "productName": "PRODUTO EXEMPLO",
        "quantity": 10.00,
        "unitPrice": 25.50,
        "totalValue": 255.00,
        "operationCode": "",
        "discountPercent": 0.00,
        "tesCode": "501"
      }
    ]
  }
}
```

#### Resposta - Pedido Não Encontrado (404)

```json
{
  "success": false,
  "message": "Order not found",
  "data": null
}
```

---

### POST /orders - Criar Pedido (Unitário)

Cria um novo pedido de venda no Protheus via `MsExecAuto(MATA410)`.

#### Query Parameters

| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|:-----------:|-----------|
| `branch` | String | Não | Código da filial (padrão `"01"`, sobrescreve o campo `branch` do body) |

#### Request Body

```json
{
  "customerCode": "C00001",
  "customerStore": "01",
  "paymentCondition": "001",
  "orderType": "N",
  "issueDate": "20260211",
  "salespersonCode": "000001",
  "priceTable": "001",
  "carrierCode": "000001",
  "freightType": "C",
  "freightValue": 150.00,
  "discountPercent": 5.00,
  "currency": 1,
  "invoiceMessage": "Mensagem na nota fiscal",
  "observation": "Observacao do pedido",
  "externalId": "B2B-00456",
  "externalDate": "20260210",
  "orderSource": "API",
  "orderSubtype": "",
  "couponCode": "",
  "financialStatus": "",
  "commercialStatus": "",
  "customerType": "J",
  "branch": "01",
  "items": [
    {
      "itemNumber": "01",
      "productCode": "PROD001",
      "quantity": 10,
      "unitPrice": 25.50,
      "totalValue": 255.00,
      "discountPercent": 0,
      "operationCode": "",
      "tesCode": "501"
    },
    {
      "itemNumber": "02",
      "productCode": "PROD002",
      "quantity": 5,
      "unitPrice": 100.00,
      "totalValue": 500.00,
      "discountPercent": 10,
      "operationCode": "",
      "tesCode": "501"
    }
  ]
}
```

#### Campos do Cabeçalho (Header)

| Campo JSON | Campo Protheus | Tipo | Obrigatório | Padrão | Descrição |
|------------|---------------|------|:-----------:|--------|-----------|
| `customerCode` | `C5_CLIENTE` | String | **Sim** | - | Código do cliente (SA1) |
| `customerStore` | `C5_LOJACLI` / `C5_LOJAENT` | String | Não | `"01"` | Loja do cliente |
| `paymentCondition` | `C5_CONDPAG` | String | **Sim** | - | Condição de pagamento (SE4) |
| `orderType` | `C5_TIPO` | String | Não | `"N"` | Tipo do pedido (N=Normal, D=Devolução, etc.) |
| `issueDate` | `C5_EMISSAO` | String | Não | Data atual | Data de emissão (formato `YYYYMMDD`) |
| `salespersonCode` | `C5_VEND1` | String | Não | - | Código do vendedor (SA3) |
| `priceTable` | `C5_TABELA` | String | Não | - | Tabela de preço (DA0) |
| `carrierCode` | `C5_TRANSP` | String | Não | - | Código da transportadora (SA4) |
| `freightType` | `C5_TPFRETE` | String | Não | `"C"` | Tipo de frete (`C`=CIF, `F`=FOB) |
| `freightValue` | `C5_FRETE` | Number | Não | `0` | Valor do frete |
| `discountPercent` | `C5_DESC1` | Number | Não | `0` | Percentual de desconto |
| `currency` | `C5_MOEDA` | Number | Não | `1` | Código da moeda |
| `invoiceMessage` | `C5_MENNOTA` | String | Não | - | Mensagem na nota fiscal |
| `observation` | `C5_ZZOBS` | String | Não | - | Observação interna |
| `externalId` | `C5_ZZNPEXT` | String | Não | - | ID externo (nº pedido B2B) — usado para evitar duplicidade |
| `externalDate` | `C5_ZZDTEMI` | String | Não | - | Data externa (formato `YYYYMMDD`) |
| `orderSource` | `C5_ZZORIGE` | String | Não | `"API"` | Origem do pedido (B2B, AFV, API, etc.) |
| `orderSubtype` | `C5_ZZTPPED` | String | Não | - | Subtipo do pedido |
| `couponCode` | `C5_ZZCUPOM` | String | Não | - | Código do cupom |
| `financialStatus` | `C5_ZZSITFI` | String | Não | - | Status financeiro |
| `commercialStatus` | `C5_ZZSITCO` | String | Não | - | Status comercial |
| `customerType` | `C5_TIPOCLI` | String | Não | - | Tipo de cliente (`F`=Física, `J`=Jurídica, `R`=Rural) |
| `branch` | - | String | Não | `"01"` | Filial (usado somente quando não informado via query parameter) |

#### Campos dos Itens

| Campo JSON | Campo Protheus | Tipo | Obrigatório | Padrão | Descrição |
|------------|---------------|------|:-----------:|--------|-----------|
| `itemNumber` | `C6_ITEM` | String | Não | Sequencial (`01`, `02`...) | Número do item |
| `productCode` | `C6_PRODUTO` | String | **Sim** | - | Código do produto (SB1) |
| `quantity` | `C6_QTDVEN` | Number | **Sim** | - | Quantidade vendida (deve ser > 0) |
| `unitPrice` | `C6_PRCVEN` | Number | Não | - | Preço unitário |
| `totalValue` | `C6_VALOR` | Number | Não | - | Valor total do item |
| `discountPercent` | `C6_DESCONT` | Number | Não | `0` | Percentual de desconto do item |
| `operationCode` | `C6_OPER` | String | Não | - | Código da operação (TES) |
| `tesCode` | `C6_TES` | String | Não | - | Código TES explícito |

#### Resposta de Sucesso (201 Created)

```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "orderNumber": "000124",
    "externalId": "B2B-00456",
    "branch": "01",
    "customerCode": "C00001",
    "customerStore": "01",
    "recno": 12346
  }
}
```

#### Resposta - ExternalId Duplicado (409 Conflict)

```json
{
  "success": false,
  "message": "Order with this externalId already exists",
  "data": {
    "orderNumber": "000123",
    "externalId": "B2B-00456",
    "branch": "01",
    "recno": 12345
  }
}
```

#### Resposta - Erro de Validação (400 Bad Request)

```json
{
  "success": false,
  "message": "Validation errors: customerCode is required; At least one item is required",
  "data": null
}
```

#### Resposta - Erro no MsExecAuto (422 Unprocessable Entity)

```json
{
  "success": false,
  "message": "AJUDA:A410TE - Tipo de Entrada/Saida nao cadastrado.",
  "data": {
    "helpCode": "AJUDA:A410TE",
    "errorItem": 1,
    "errors": ["Tipo de Entrada/Saida nao cadastrado."],
    "sentFields": {
      "C5_CLIENTE": "C00001",
      "C5_LOJACLI": "01",
      "C5_CONDPAG": "001"
    },
    "sentHeader": {
      "C5_CLIENTE": "C00001",
      "C5_LOJACLI": "01"
    },
    "sentItems": [
      {
        "C6_ITEM": "01",
        "C6_PRODUTO": "PROD001",
        "C6_QTDVEN": "10"
      }
    ]
  }
}
```

---

### POST /orders - Criar Pedidos (Lote)

Cria múltiplos pedidos em uma única requisição. Cada pedido é processado individualmente e pode ter sua própria filial.

#### Request Body

```json
{
  "orders": [
    {
      "customerCode": "C00001",
      "customerStore": "01",
      "paymentCondition": "001",
      "externalId": "B2B-00456",
      "branch": "01",
      "items": [
        {
          "productCode": "PROD001",
          "quantity": 10,
          "unitPrice": 25.50
        }
      ]
    },
    {
      "customerCode": "C00002",
      "customerStore": "01",
      "paymentCondition": "002",
      "externalId": "B2B-00457",
      "branch": "02",
      "items": [
        {
          "productCode": "PROD002",
          "quantity": 5,
          "unitPrice": 100.00
        }
      ]
    }
  ]
}
```

> A detecção de lote é automática: se o JSON contiver a chave `"orders"` com um array, a API entra em modo batch.

#### Resposta - Todos Criados com Sucesso (201 Created)

```json
{
  "success": true,
  "message": "All orders created successfully",
  "totalOrders": 2,
  "results": [
    {
      "order": 1,
      "success": true,
      "message": "Order created successfully",
      "orderNumber": "000124",
      "externalId": "B2B-00456",
      "branch": "01",
      "customerCode": "C00001",
      "customerStore": "01",
      "recno": 12346
    },
    {
      "order": 2,
      "success": true,
      "message": "Order created successfully",
      "orderNumber": "000125",
      "externalId": "B2B-00457",
      "branch": "02",
      "customerCode": "C00002",
      "customerStore": "01",
      "recno": 12347
    }
  ]
}
```

#### Resposta - Sucesso Parcial (207 Multi-Status)

```json
{
  "success": false,
  "message": "Some orders failed",
  "totalOrders": 2,
  "results": [
    {
      "order": 1,
      "success": true,
      "message": "Order created successfully",
      "orderNumber": "000124",
      "externalId": "B2B-00456",
      "branch": "01",
      "customerCode": "C00001",
      "customerStore": "01",
      "recno": 12346
    },
    {
      "order": 2,
      "success": false,
      "message": "Validation errors: customerCode is required"
    }
  ]
}
```

---

### PUT /orders - Atualizar Pedido

Atualiza um pedido de venda existente via `MsExecAuto(MATA410)` no modo alteração.

#### Query Parameters

| Parâmetro | Tipo | Obrigatório | Descrição |
|-----------|------|:-----------:|-----------|
| `branch` | String | Não | Código da filial (padrão `"01"`) |

#### Request Body

O corpo deve conter `orderNumber` ou `externalId` para identificar o pedido. Os demais campos são opcionais — somente os campos informados serão atualizados.

```json
{
  "orderNumber": "000123",
  "salespersonCode": "000002",
  "freightType": "F",
  "freightValue": 200.00,
  "observation": "Pedido atualizado via API",
  "items": [
    {
      "itemNumber": "01",
      "productCode": "PROD001",
      "quantity": 15,
      "unitPrice": 24.00
    }
  ]
}
```

Ou identificando pelo ID externo:

```json
{
  "externalId": "B2B-00456",
  "freightType": "C",
  "freightValue": 0
}
```

#### Resposta de Sucesso (200 OK)

```json
{
  "success": true,
  "message": "Order updated successfully",
  "data": {
    "orderNumber": "000123",
    "externalId": "B2B-00456",
    "branch": "01",
    "recno": 12345
  }
}
```

#### Resposta - Pedido Não Encontrado (404)

```json
{
  "success": false,
  "message": "Order not found",
  "data": null
}
```

#### Resposta - Erro no MsExecAuto (422 Unprocessable Entity)

```json
{
  "success": false,
  "message": "Erro no MsExecAuto MATA410 UPDATE - Pedido: 000123",
  "data": {
    "helpCode": "AJUDA:...",
    "sentHeader": { "...": "..." },
    "sentItems": [ { "...": "..." } ]
  }
}
```

---

## Respostas Padrão

Todas as respostas seguem a estrutura:

```json
{
  "success": true | false,
  "message": "Mensagem descritiva",
  "data": { ... } | [ ... ] | null,
  "pagination": { ... } | null
}
```

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `success` | Boolean | Indica se a operação foi bem-sucedida |
| `message` | String | Mensagem descritiva do resultado |
| `data` | Object/Array/null | Dados retornados (pedido, lista, detalhes de erro) |
| `pagination` | Object/null | Dados de paginação (somente no GET de listagem) |

### Objeto de Paginação

```json
{
  "page": 1,
  "pageSize": 100,
  "totalPages": 5,
  "totalRecords": 450
}
```

---

## Códigos de Status HTTP

| Código | Significado | Quando é Retornado |
|--------|-------------|-------------------|
| `200` | OK | GET bem-sucedido / PUT bem-sucedido |
| `201` | Created | POST — pedido(s) criado(s) com sucesso |
| `207` | Multi-Status | POST batch — alguns pedidos falharam |
| `400` | Bad Request | JSON inválido ou campos obrigatórios ausentes |
| `404` | Not Found | Pedido não encontrado (GET/PUT) |
| `409` | Conflict | ExternalId duplicado (POST) |
| `422` | Unprocessable Entity | Erro no `MsExecAuto` (regra de negócio Protheus) |
| `520` | Unknown Error | Erro inesperado/exceção não tratada |

---

## Validações

### Criação (POST)

| Regra | Detalhe |
|-------|---------|
| `customerCode` obrigatório | Deve existir na tabela `SA1` |
| `paymentCondition` obrigatório | Deve existir na tabela `SE4` |
| `items` obrigatório | Pelo menos 1 item |
| `items[].productCode` obrigatório | Deve existir na tabela `SB1` |
| `items[].quantity` obrigatório | Deve ser maior que 0 |
| `externalId` único | Se informado, rejeita duplicidade (HTTP 409) |
| `salespersonCode` (opcional) | Se informado, deve existir em `SA3` |
| `priceTable` (opcional) | Se informada, deve existir em `DA0` |
| `carrierCode` (opcional) | Se informado, deve existir em `SA4` |

### Atualização (PUT)

| Regra | Detalhe |
|-------|---------|
| `orderNumber` ou `externalId` | Pelo menos um é obrigatório para localizar o pedido |
| Pedido deve existir | Retorna 404 se não encontrado |

### Sanitização de Dados

- Campos de código: removidos caracteres especiais (`'`, `"`, `\`, espaços), convertidos para maiúsculas, truncados ao tamanho do dicionário.
- Campos de texto: removidos `'`, `"`, `\`, caracteres de controle (`\0`, `\t`, `\n`, `\r`), truncados ao tamanho do dicionário.
- Datas: extraídos somente dígitos e convertidos via `SToD()`.

---

## Exemplos Completos

### 1. Listar Pedidos Pendentes (sem NF)

```
GET /orders?pending=1&page=1&pageSize=50&branch=01
```

### 2. Buscar Pedido por ExternalId

```
GET /orders?externalId=B2B-00456
```

### 3. Criar Pedido Simples

```http
POST /orders?branch=01
Content-Type: application/json

{
  "customerCode": "C00001",
  "customerStore": "01",
  "paymentCondition": "001",
  "externalId": "B2B-00789",
  "orderSource": "B2B",
  "items": [
    {
      "productCode": "PROD001",
      "quantity": 10,
      "unitPrice": 50.00
    }
  ]
}
```

### 4. Criar Pedidos em Lote

```http
POST /orders
Content-Type: application/json

{
  "orders": [
    {
      "customerCode": "C00001",
      "customerStore": "01",
      "paymentCondition": "001",
      "externalId": "LOTE-001",
      "branch": "01",
      "items": [
        { "productCode": "PROD001", "quantity": 5, "unitPrice": 30.00 }
      ]
    },
    {
      "customerCode": "C00002",
      "customerStore": "01",
      "paymentCondition": "002",
      "externalId": "LOTE-002",
      "branch": "02",
      "items": [
        { "productCode": "PROD003", "quantity": 2, "unitPrice": 150.00 },
        { "productCode": "PROD004", "quantity": 1, "unitPrice": 500.00 }
      ]
    }
  ]
}
```

### 5. Atualizar Pedido

```http
PUT /orders?branch=01
Content-Type: application/json

{
  "orderNumber": "000123",
  "freightType": "F",
  "freightValue": 250.00,
  "observation": "Frete alterado para FOB",
  "items": [
    {
      "itemNumber": "01",
      "productCode": "PROD001",
      "quantity": 20,
      "unitPrice": 48.00
    }
  ]
}
```

---

## Observações Técnicas

- A API suprime automaticamente as **Alçadas de Aprovação** (`AO4`) durante a execução via variáveis `_lAprov` e `lAlcada`.
- Em caso de erro no `MsExecAuto`, a API tenta detectar se o pedido foi criado mesmo assim (ex.: erro pós-commit do módulo de aprovação). Se confirmado, retorna sucesso com um campo `warning`.
- A API utiliza `DisarmTransaction()` para descartar transações pendentes em caso de falha.
- Os erros do `MsExecAuto` são capturados via `GetAutoGrLog()` e parseados para retornar informações estruturadas ao consumidor, incluindo o HELP code, campos enviados e mensagens do modelo.
- O campo `externalId` (`C5_ZZNPEXT`) é indexado (índice 12 da `SC5`) e utilizado como chave de idempotência para evitar pedidos duplicados.
- No modo batch, o ambiente (`RpcSetEnv`) é reconfigurado para cada pedido, permitindo que cada um tenha sua própria filial.
