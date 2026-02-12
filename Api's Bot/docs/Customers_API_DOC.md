# API Customers - Documentação v2.0

## Visão Geral

API REST para gerenciamento de clientes (tabela SA1) no Protheus.

| Informação | Valor |
|------------|-------|
| **Versão** | 2.0 |
| **Ambiente DEV** | `http://suntechsupplies170774.protheus.cloudtotvs.com.br:1607/rest` |
| **Endpoint** | `/customers` |
| **Autenticação** | Bearer Token JWT |

---

## Headers Obrigatórios

Todos os endpoints exigem os seguintes headers:

| Header | Tipo | Obrigatório | Descrição | Exemplo |
|--------|------|-------------|-----------|---------|
| `Authorization` | String | Sim | Token JWT no formato Bearer | `Bearer eyJhbGciOiJIUzI1...` |
| `X-Company` | String | Sim | Código da empresa | `99` |
| `X-Branch` | String | Sim | Código da filial | `01` |
| `Content-Type` | String | Sim* | Tipo do conteúdo (*POST/PUT) | `application/json` |

---

## Endpoints

### 1. GET /customers - Listar Clientes

Retorna lista paginada de clientes.

#### Request

```http
GET /customers?page=1&pageSize=100
```

#### Query Parameters

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|-------------|---------|-----------|
| `page` | Integer | Não | 1 | Número da página |
| `pageSize` | Integer | Não | 100 | Registros por página |

#### Exemplo cURL

```bash
curl -X GET "http://suntechsupplies170774.protheus.cloudtotvs.com.br:1607/rest/customers?page=1&pageSize=100" \
  -H "Authorization: Bearer {seu_token}" \
  -H "X-Company: 99" \
  -H "X-Branch: 01" \
  -H "Content-Type: application/json"
```

#### Response (200 OK)

```json
{
  "success": true,
  "message": "Customers retrieved successfully",
  "timestamp": "20260207T104500",
  "version": "2.0",
  "data": [
    {
      "recno": 1234,
      "code": "000001",
      "store": "01",
      "name": "EMPRESA TESTE LTDA",
      ...
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 100,
    "totalPages": 5,
    "totalRecords": 450
  }
}
```

---

### 2. GET /customers?code={code} - Buscar por Código

Retorna um cliente específico pelo código.

#### Request

```http
GET /customers?code=00000101
```

#### Query Parameters

| Parâmetro | Tipo | Formato | Descrição |
|-----------|------|---------|-----------|
| `code` | String | A1_COD + A1_LOJA | Código concatenado (ex: `00000101` = cliente 000001 loja 01) |

> **Nota:** Se informar apenas A1_COD (ex: `code=000001`), assume loja "01"

#### Exemplo cURL

```bash
curl -X GET "http://suntechsupplies170774.protheus.cloudtotvs.com.br:1607/rest/customers?code=00000101" \
  -H "Authorization: Bearer {seu_token}" \
  -H "X-Company: 99" \
  -H "X-Branch: 01"
```

#### Response (200 OK)

```json
{
  "success": true,
  "message": "Customer found",
  "timestamp": "20260207T104500",
  "version": "2.0",
  "data": {
    "recno": 1234,
    "code": "000001",
    "store": "01",
    "branch": "01",
    "name": "EMPRESA TESTE LTDA",
    ...
  }
}
```

---

### 3. GET /customers?taxId={taxId} - Buscar por CNPJ/CPF

Retorna um cliente específico pelo CNPJ ou CPF.

#### Request

```http
GET /customers?taxId=12345678000190
```

#### Exemplo cURL

```bash
curl -X GET "http://suntechsupplies170774.protheus.cloudtotvs.com.br:1607/rest/customers?taxId=12345678000190" \
  -H "Authorization: Bearer {seu_token}" \
  -H "X-Company: 99" \
  -H "X-Branch: 01"
```

---

### 4. POST /customers - Criar Cliente

Cria um novo cliente no sistema.

#### Request

```http
POST /customers
Content-Type: application/json
```

#### Body Parameters

| Campo | Tipo | Obrigatório | Campo SA1 | Descrição |
|-------|------|-------------|-----------|-----------|
| `taxId` | String | **Sim** | A1_CGC | CNPJ ou CPF |
| `name` | String | **Sim** | A1_NOME | Razão Social |
| `shortName` | String | Não | A1_NREDUZ | Nome Fantasia |
| `personType` | String | Não | A1_PESSOA | Tipo Pessoa (F=Física, J=Jurídica) |
| `customerType` | String | Não | A1_TIPO | Tipo Cliente (F=Consumidor, L=Produtor, R=Revendedor, S=Solidário, X=Exportação) |
| `stateRegistration` | String | Não | A1_INSCR | Inscrição Estadual |
| `municipalRegistration` | String | Não | A1_INSCRM | Inscrição Municipal |
| `address` | String | Não | A1_END | Endereço |
| `complement` | String | Não | A1_COMPLEM | Complemento |
| `neighborhood` | String | Não | A1_BAIRRO | Bairro |
| `city` | String | Não | A1_MUN | Município |
| `state` | String | Não | A1_EST | UF |
| `zipCode` | String | Não | A1_CEP | CEP |
| `cityCode` | String | Não | A1_COD_MUN | Código IBGE Município |
| `country` | String | Não | A1_PAIS | País |
| `countryCode` | String | Não | A1_CODPAIS | Código País |
| `areaCode` | String | Não | A1_DDD | DDD |
| `phone` | String | Não | A1_TEL | Telefone |
| `fax` | String | Não | A1_FAX | Fax |
| `whatsappAreaCode` | String/Number | Não | A1_ZZDDDW | DDD WhatsApp |
| `whatsappPhone` | String | Não | A1_TELW | WhatsApp |
| `email` | String | Não | A1_EMAIL | E-mail |
| `contact` | String | Não | A1_CONTATO | Contato |
| `salespersonCode` | String | Não | A1_VEND | Código Vendedor |
| `paymentCondition` | String | Não | A1_COND | Condição Pagamento |
| `priceTable` | String | Não | A1_TABELA | Tabela Preço |
| `region` | String | Não | A1_REGIAO | Região |
| `salesGroup` | String | Não | A1_GRPVEN | Grupo Venda |
| `taxGroup` | String | Não | A1_GRPTRIB | Grupo Tributário |
| `icmsContributor` | String | Não | A1_CONTRIB | Contribuinte ICMS (1=Sim, 2=Não, 9=Isento) |
| `creditLimit` | Number | Não | A1_LC | Limite Crédito |
| `carrierCode` | String | Não | A1_TRANSP | Código Transportadora |
| `enabledB2B` | String | Não | A1_ZZLB2B | Habilitado B2B (S/N) |
| `observation` | String | Não | A1_OBS | Observação |
| `store` | String | Não | A1_LOJA | Loja (default: "01") |

#### Exemplo cURL

```bash
curl -X POST "http://suntechsupplies170774.protheus.cloudtotvs.com.br:1607/rest/customers" \
  -H "Authorization: Bearer {seu_token}" \
  -H "X-Company: 99" \
  -H "X-Branch: 01" \
  -H "Content-Type: application/json" \
  -d '{
    "taxId": "12345678000190",
    "name": "EMPRESA TESTE LTDA",
    "shortName": "EMPRESA TESTE",
    "personType": "J",
    "customerType": "F",
    "stateRegistration": "123456789",
    "municipalRegistration": "",
    "address": "RUA TESTE, 100",
    "complement": "SALA 10",
    "neighborhood": "CENTRO",
    "city": "SAO PAULO",
    "state": "SP",
    "zipCode": "01310100",
    "cityCode": "3550308",
    "country": "BRASIL",
    "countryCode": "01058",
    "areaCode": "11",
    "phone": "999999999",
    "fax": "",
    "whatsappAreaCode": "11",
    "whatsappPhone": "999999999",
    "email": "contato@empresa.com",
    "contact": "JOAO SILVA",
    "salespersonCode": "000001",
    "paymentCondition": "001",
    "priceTable": "001",
    "region": "SP",
    "salesGroup": "",
    "taxGroup": "",
    "icmsContributor": "1",
    "creditLimit": 50000.00,
    "carrierCode": "",
    "enabledB2B": "S",
    "observation": "Cliente cadastrado via API",
    "store": "01"
  }'
```

#### Response (201 Created)

```json
{
  "success": true,
  "message": "Customer created successfully",
  "timestamp": "20260207T104500",
  "version": "2.0",
  "data": {
    "code": "000015",
    "store": "01",
    "taxId": "12345678000190",
    "recno": 1234
  }
}
```

---

### 5. PUT /customers - Atualizar Cliente

Atualiza um cliente existente.

#### Request

```http
PUT /customers
Content-Type: application/json
```

#### Body Parameters

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `code` | String | **Sim** | Código do cliente (A1_COD) |
| `store` | String | Não | Loja (default: "01") |
| *outros* | - | Não | Mesmos campos do POST |

#### Exemplo cURL

```bash
curl -X PUT "http://suntechsupplies170774.protheus.cloudtotvs.com.br:1607/rest/customers" \
  -H "Authorization: Bearer {seu_token}" \
  -H "X-Company: 99" \
  -H "X-Branch: 01" \
  -H "Content-Type: application/json" \
  -d '{
    "code": "000001",
    "store": "01",
    "phone": "888888888",
    "email": "novo@email.com",
    "creditLimit": 75000.00,
    "observation": "Atualizado via API"
  }'
```

#### Response (200 OK)

```json
{
  "success": true,
  "message": "Customer updated successfully",
  "timestamp": "20260207T104530",
  "version": "2.0",
  "data": {
    "code": "000001",
    "store": "01",
    "recno": 1234
  }
}
```

---

## Estrutura de Resposta

### Objeto Customer (GET)

```json
{
  "recno": 1234,
  "code": "000001",
  "store": "01",
  "branch": "01",
  "name": "EMPRESA TESTE LTDA",
  "shortName": "EMPRESA TESTE",
  "taxId": "12345678000190",
  "stateRegistration": "123456789",
  "municipalRegistration": "",
  "personType": "J",
  "customerType": "F",
  "blocked": false,
  "address": "RUA TESTE, 100",
  "complement": "SALA 10",
  "neighborhood": "CENTRO",
  "city": "SAO PAULO",
  "state": "SP",
  "zipCode": "01310100",
  "cityCode": "3550308",
  "country": "BRASIL",
  "countryCode": "01058",
  "areaCode": "11",
  "phone": "999999999",
  "fax": "",
  "whatsappAreaCode": 11,
  "whatsappPhone": "999999999",
  "email": "contato@empresa.com",
  "contact": "JOAO SILVA",
  "salespersonCode": "000001",
  "paymentCondition": "001",
  "priceTable": "001",
  "region": "SP",
  "salesGroup": "",
  "taxGroup": "",
  "icmsContributor": "1",
  "creditLimit": 50000.00,
  "availableCredit": 35000.00,
  "carrierCode": "",
  "enabledB2B": "S",
  "observation": "",
  "registrationDate": "07/02/2026",
  "registrationTime": "10:45"
}
```

### Objeto Pagination (GET List)

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

| Código | Status | Descrição |
|--------|--------|-----------|
| 200 | OK | Requisição executada com sucesso |
| 201 | Created | Cliente criado com sucesso |
| 400 | Bad Request | Requisição inválida (JSON malformado, campos obrigatórios) |
| 401 | Unauthorized | Token inválido ou expirado |
| 404 | Not Found | Cliente não encontrado |
| 409 | Conflict | CNPJ/CPF já cadastrado |
| 500 | Internal Server Error | Erro interno do servidor |

---

## Respostas de Erro

### 400 - Bad Request

```json
{
  "success": false,
  "message": "CNPJ/CPF (taxId) is required",
  "timestamp": "20260207T104500",
  "version": "2.0"
}
```

### 401 - Unauthorized

```json
{
  "success": false,
  "message": "Invalid or expired token",
  "timestamp": "20260207T104500",
  "version": "2.0"
}
```

### 404 - Not Found

```json
{
  "success": false,
  "message": "Customer not found",
  "timestamp": "20260207T104500",
  "version": "2.0"
}
```

### 409 - Conflict

```json
{
  "success": false,
  "message": "Customer with this CNPJ/CPF already exists",
  "timestamp": "20260207T104500",
  "version": "2.0",
  "data": {
    "code": "000001",
    "store": "01"
  }
}
```

---

## Mapeamento de Campos SA1

| Campo API | Campo SA1 | Tipo | Tamanho |
|-----------|-----------|------|---------|
| code | A1_COD | Char | 6 |
| store | A1_LOJA | Char | 2 |
| name | A1_NOME | Char | 40 |
| shortName | A1_NREDUZ | Char | 20 |
| taxId | A1_CGC | Char | 14 |
| stateRegistration | A1_INSCR | Char | 18 |
| municipalRegistration | A1_INSCRM | Char | 15 |
| personType | A1_PESSOA | Char | 1 |
| customerType | A1_TIPO | Char | 1 |
| blocked | A1_MSBLQL | Char | 1 |
| address | A1_END | Char | 40 |
| complement | A1_COMPLEM | Char | 20 |
| neighborhood | A1_BAIRRO | Char | 30 |
| city | A1_MUN | Char | 30 |
| state | A1_EST | Char | 2 |
| zipCode | A1_CEP | Char | 8 |
| cityCode | A1_COD_MUN | Char | 7 |
| country | A1_PAIS | Char | 20 |
| countryCode | A1_CODPAIS | Char | 5 |
| areaCode | A1_DDD | Char | 3 |
| phone | A1_TEL | Char | 15 |
| fax | A1_FAX | Char | 15 |
| whatsappAreaCode | A1_ZZDDDW | Num | 2 |
| whatsappPhone | A1_TELW | Char | 15 |
| email | A1_EMAIL | Char | 40 |
| contact | A1_CONTATO | Char | 15 |
| salespersonCode | A1_VEND | Char | 6 |
| paymentCondition | A1_COND | Char | 3 |
| priceTable | A1_TABELA | Char | 3 |
| region | A1_REGIAO | Char | 3 |
| salesGroup | A1_GRPVEN | Char | 6 |
| taxGroup | A1_GRPTRIB | Char | 3 |
| icmsContributor | A1_CONTRIB | Char | 1 |
| creditLimit | A1_LC | Num | 14,2 |
| availableCredit | A1_LC - A1_SALDUP | Num | - |
| carrierCode | A1_TRANSP | Char | 6 |
| enabledB2B | A1_ZZLB2B | Char | 1 |
| observation | A1_OBS | Char | 20 |
| registrationDate | A1_DTCAD | Date | 8 |
| registrationTime | A1_HRCAD | Char | 5 |

---

## Logs

A API gera logs de auditoria em: `\api_logs\api_customers_YYYYMMDD.log`

Formato:
```
[20260207 10:45:00] [GET] [99/01] Customers query executed
[20260207 10:45:30] [POST] [99/01] Customer creation attempted
[20260207 10:46:00] [PUT] [99/01] Customer update attempted
```

---

## Changelog

### v2.0 (2026-02-07)
- Autenticação via Bearer Token JWT
- Headers X-Company e X-Branch para multi-tenant
- Paginação com OFFSET/FETCH
- Parâmetro `code` concatenado (A1_COD + A1_LOJA)
- Campo `recno` em todas as respostas
- Respostas padronizadas com success/message/data/pagination
- Logs de auditoria

---

## Autor

**Suntech Supplies**

Documentação gerada em: 07/02/2026
