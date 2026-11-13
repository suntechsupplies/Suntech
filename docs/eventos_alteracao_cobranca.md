# Eventos de alteracao de cobranca

## Objetivo e escopo

Este documento descreve o contrato e o comportamento da API `POST /incidents`, implementada em [Incidents.prw](../API's%20HB/Incidents.prw). A API recebe eventos financeiros associados a uma NF-e e a titulos em cobranca bancaria. Ela nao confirma que o banco executou a instrucao: o registro de uma ocorrencia pendente na FI2 deve ser acompanhado pelos processos bancarios aplicaveis.

## Tipos de evento

| `eventType` | Ocorrencia SEB | Operacao | Efeito no Protheus |
| --- | --- | --- | --- |
| `DO_NOT_PROTEST` | `10` | `N` | Registra ocorrencia pendente para nao protestar o titulo. |
| `EXTEND_DUE_DATE` | `06` | `P` | Altera o vencimento do titulo via FINA040 e registra a ocorrencia na FI2. |
| `REQUEST_BANK_WRITE_OFF` | `02` | `B` | Registra solicitacao pendente de baixa bancaria; nao baixa o titulo por si so. |

As ocorrencias precisam estar cadastradas na SEB como saida para o banco `341` (Itau). A data do evento e informativa; para prorrogacao, `newDueDate` e a nova data efetivamente aplicada ao titulo.

## Contrato da requisicao

Envie JSON para `POST /incidents` na base REST configurada. `company` e `branch` sao parametros opcionais do servico; quando a filial nao e informada, a API tenta usar a filial do titulo elegivel.

Campos obrigatorios do corpo:

| Campo | Regra |
| --- | --- |
| `eventId` | Identificador do evento; ate 60 caracteres alfanumericos, hifen ou sublinhado. A idempotencia e por titulo e ocorrencia, nao global. |
| `eventType` | Um dos tres tipos listados acima. |
| `occurredAt` | Envie data/hora ISO-8601 com `T`; a implementacao verifica o separador e a validade da data `AAAA-MM-DD`, mas nao valida integralmente hora e fuso. |
| `invoice.number` | Numero da NF-e. |
| `invoice.series` | Serie da NF-e. |
| `invoice.accessKey` | Chave de acesso da NF-e. |
| `bankAccount.bankCode` | Deve ser `341`. |
| `bankAccount.agency` | Agencia da conta vinculada ao titulo. |
| `bankAccount.account` | Conta vinculada ao titulo. |
| `newDueDate` | Obrigatorio para `EXTEND_DUE_DATE`, no formato `AAAA-MM-DD`, posterior ao vencimento mais antigo elegivel. |

`reason` e opcional e e armazenado com limite de 200 caracteres no log da ocorrencia.

```json
{
  "eventId": "evt-20261113-001",
  "eventType": "EXTEND_DUE_DATE",
  "occurredAt": "2026-11-13T10:30:00-03:00",
  "newDueDate": "2026-12-13",
  "reason": "Acordo aprovado",
  "invoice": {
    "number": "000123456",
    "series": "1",
    "accessKey": "CHAVE_NFE_44_DIGITOS"
  },
  "bankAccount": {
    "bankCode": "341",
    "agency": "2731",
    "account": "03199"
  }
}
```

Substitua os valores de exemplo por dados validos do ambiente autorizado. Nao use a chave ilustrativa como dado real.

## Elegibilidade e processamento

A API localiza a NF em SF2 e os titulos correspondentes em SE1, relacionando filial, serie, numero, cliente e loja. A chave de acesso desambigua notas que compartilham numero e serie. O titulo precisa estar vinculado ao banco 341 e a agencia/conta informadas, ter identificadores de cobranca bancaria (`E1_IDCNAB` e `E1_NUMBOR`), saldo positivo e nao estar baixado.

Cada parcela elegivel recebe sua propria ocorrencia. Em `EXTEND_DUE_DATE`, a API calcula o deslocamento usando o vencimento mais antigo e aplica o mesmo numero de dias a cada parcela, preservando a distancia entre vencimentos.

A idempotencia e controlada por titulo e ocorrencia. Repetir o mesmo `eventId` para uma ocorrencia ja registrada retorna sucesso sem criar outra. Uma instrucao pendente para o mesmo titulo/ocorrencia, criada com outro evento, e rejeitada. O identificador do evento e persistido na mensagem de controle da FI2.

Para `EXTEND_DUE_DATE`, o vencimento e alterado por FINA040 antes da confirmacao da FI2. Se a alteracao ocorrer e a gravacao da FI2 falhar, a resposta indica necessidade de conciliacao manual. Nao reenvie cegamente o evento: confira SE1 e FI2 e reconcilie o resultado antes de tentar novamente.

## Respostas

A resposta JSON informa `success`, `message`, `eventId`, `status` e `instructionsCreated`.

| HTTP | Uso principal |
| --- | --- |
| `200` | Evento ja processado, sem nova instrucao. |
| `201` | Ocorrencia(s) registrada(s) como pendente(s). |
| `207` | Falha parcial depois de uma ou mais parcelas processadas; exige conciliacao. |
| `400` | JSON ou campos invalidos/ausentes. |
| `404` | Nenhum titulo elegivel para a ocorrencia. |
| `422` | Inconsistencia de elegibilidade, ocorrencia bancaria ou processamento. |
| `500` | Falha de ambiente, configuracao ou processamento; pode exigir conciliacao manual. |

## Testes e implantacao

Os testes de contrato ficam em [test_contracts.py](../tests/api_hb/test_contracts.py), e as instrucoes para habilita-los estao no [README da suite](../tests/api_hb/README.md#L62). Eles sao ignorados por padrao e exigem habilitacao explicita e endpoint publicado em homologacao. Os cenarios atuais cobrem validacoes, os tres tipos de evento e respostas para titulos artificiais sem elegibilidade; nao comprovam alteracao de vencimento, gravacao efetiva na FI2 nem processamento pelo banco.

Antes de habilitar testes, confirme que a URL aponta para homologacao. Para testes com titulo real, use um roteiro separado, autorizado e conciliado; nao reutilize os payloads de contrato como teste de gravacao.

## Fontes e configuracao

| Item | Uso/requisito |
| --- | --- |
| [API's HB/Incidents.prw](../API's%20HB/Incidents.prw) | Implementa `POST /incidents`, validacao, selecao de titulos, alteracao via FINA040 e registro da ocorrencia. |
| [tests/api_hb/test_contracts.py](../tests/api_hb/test_contracts.py) | Testes de contrato para campos invalidos, tipos de evento e ausencia de titulo elegivel. |
| `SF2` e `SE1` | NF-e e parcelas elegiveis; a consulta relaciona numero, serie, chave de acesso, filial, cliente e loja. |
| `SEB` | Deve conter as ocorrencias `10`, `06` e `02` como ocorrencias de saida para o banco `341`. |
| `FI2` | Registra uma ocorrencia por titulo; exige os campos customizados `FI2_APILOG`, `FI2_APIMSG` e `FI2_OPEAPI`. |
| Aliases REST | `SE1`, `FI2` e `SEB` precisam estar abertos no contexto da filial. |
| Publicacao | A rota so pode ser testada apos compilacao e publicacao do fonte no RPO de homologacao. |

Nao ha parametros `MV_` proprios no fonte atual. A configuracao funcional esta nos cadastros `SEB`, nos dados bancarios do titulo em `SE1` e nos campos de controle customizados da `FI2`.
