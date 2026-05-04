# Documento de Implementacao - Rotina Assincrona de XML e DANFE

## 1. Objetivo
Implementar uma rotina assincrona para capturar, processar e armazenar XML e DANFE de NF-e no SaaS, com foco em:

1. Reduzir dependencia de consulta sincrona no ERP.
2. Melhorar performance e disponibilidade de consulta.
3. Garantir rastreabilidade, idempotencia e seguranca.
4. Gerar DANFE no mesmo padrao operacional usado para boletos e etiquetas.

## 2. Escopo

1. Captura de eventos de NF-e integrada/autorizada/cancelada no ERP.
2. Processamento assincrono via fila.
3. Gravacao de XML original autorizado no banco do SaaS.
4. Geracao de DANFE assincrona por worker dedicado.
5. Armazenamento do DANFE em base64 ou binario (recomendado binario com metadado de content-type).
6. APIs de consulta no SaaS para XML e DANFE.
7. Observabilidade, reprocessamento e governanca de erros.

## 3. Principios Tecnicos

1. XML oficial sempre imutavel.
2. Idempotencia por chave da NF-e e versao de evento.
3. Eventual consistency controlada por SLA.
4. Fallback temporario ao ERP em caso de documento nao disponivel no SaaS.
5. Seguranca por criptografia, trilha de auditoria e controle de acesso.

## 4. Arquitetura Proposta

1. Produtor de eventos no ERP.
2. Fila de mensagens.
3. Worker de ingestao de XML.
4. Worker de geracao de DANFE.
5. Banco de dados do SaaS.
6. Armazenamento de arquivos (ou tabela de blobs).
7. API de consulta no SaaS.
8. Dashboard de monitoramento.

## 5. Fluxo Assincrono

1. ERP detecta integracao/autorizacao de NF-e.
2. ERP publica evento na fila com metadados minimos.
3. Worker de XML consome evento.
4. Worker consulta origem oficial e obtem XML original.
5. Worker valida hash e persiste XML no SaaS.
6. Worker publica evento interno para geracao de DANFE.
7. Worker de DANFE consome evento e gera PDF usando o mesmo padrao de rotina de boletos/etiquetas.
8. Worker persiste DANFE e atualiza status.
9. API do SaaS atende consultas a partir do banco.
10. Se nao houver documento, API retorna status de processamento ou fallback configurado.

## 6. Contrato de Evento (ERP para Fila)

Exemplo:

```json
{
  "eventId": "uuid",
  "eventType": "NFE_AUTHORIZED",
  "occurredAt": "2026-05-03T12:00:00Z",
  "tenantId": "suntech",
  "empresa": "01",
  "filial": "02",
  "doc": "000197612",
  "serie": "1",
  "cliente": "C05774",
  "loja": "01",
  "chaveNfe": "3226...",
  "idEnt": "020043",
  "version": 1
}
```

## 7. Modelo de Dados Sugerido

### Tabela fiscal_document

1. id
2. tenant_id
3. empresa
4. filial
5. doc
6. serie
7. cliente
8. loja
9. chave_nfe
10. status_fiscal
11. protocolo
12. data_emissao
13. created_at
14. updated_at

### Tabela fiscal_xml

1. id
2. fiscal_document_id
3. xml_content
4. xml_hash_sha256
5. schema_version
6. source
7. immutable_flag
8. created_at

### Tabela fiscal_danfe

1. id
2. fiscal_document_id
3. pdf_content
4. pdf_hash_sha256
5. generator_version
6. generated_at
7. created_at

### Tabela fiscal_event_log

1. id
2. event_id
3. event_type
4. payload
5. processing_status
6. error_message
7. retry_count
8. created_at
9. processed_at

## 8. Indices e Unicidade

1. Unico por tenant_id + chave_nfe em fiscal_document.
2. Indice por tenant_id + doc + serie + filial.
3. Indice por processing_status em fiscal_event_log.
4. Unico por event_id em fiscal_event_log para idempotencia.

## 9. Estrategia de Geracao de DANFE

1. Reutilizar padrao de execucao de boletos/etiquetas.
2. Worker dedicado de renderizacao.
3. Isolar diretorio de trabalho por tenant e idEnt.
4. Capturar logs de preview, arquivo gerado e tempo de execucao.
5. Em caso de falha, aplicar retry com backoff.
6. Apos sucesso, remover arquivos temporarios.

## 10. Regras de Idempotencia e Retries

1. Se event_id ja processado com sucesso, ignorar.
2. Se evento duplicado com mesma chave e versao, ignorar.
3. Retries automaticos: 3 a 5 tentativas.
4. Falha definitiva vai para dead letter queue.
5. Disponibilizar reprocessamento manual por chave.

## 11. Seguranca e Compliance

1. Criptografia em transito e em repouso.
2. Controle de acesso por tenant e escopo de usuario.
3. Auditoria de consulta e download.
4. XML original nao pode ser alterado.
5. Politica de retencao definida por juridico/fiscal.
6. Mascaramento de dados sensiveis em logs.

## 12. APIs no SaaS

### Consulta XML

1. Entrada: chave_nfe ou doc/serie/filial.
2. Saida: XML oficial e metadados de status.

### Consulta DANFE

1. Entrada: chave_nfe ou doc/serie/filial.
2. Saida: PDF ou base64_arquivo no padrao ja usado.

### Status de Processamento

1. Entrada: event_id ou chave_nfe.
2. Saida: pending, processing, done, failed e motivo.

### Reprocessamento

1. Entrada: chave_nfe.
2. Acao: republica evento para fila.

## 13. SLA e Monitoramento

1. SLA de ingestao de XML: ate 60 segundos apos evento.
2. SLA de geracao de DANFE: ate 120 segundos apos XML persistido.
3. Metricas:
4. taxa de sucesso por etapa.
5. tempo medio por etapa.
6. tamanho da fila.
7. taxa de retries.
8. itens em dead letter queue.

## 14. Plano de Implementacao por Fases

### Fase 1 - Base de Eventos e XML

1. Criar tabelas.
2. Criar publisher no ERP.
3. Criar worker de ingestao XML.
4. Criar API de consulta de XML.
5. Criar dashboard basico.

### Fase 2 - DANFE Assincrona

1. Criar worker de DANFE no padrao boletos/etiquetas.
2. Persistir PDF e metadados.
3. Criar API de consulta de DANFE.
4. Criar reprocessamento manual.

### Fase 3 - Resiliencia e Otimizacoes

1. Dead letter queue.
2. Alertas automaticos.
3. Fallback controlado ao ERP.
4. Cache e tuning de performance.

## 15. Plano de Testes (Desenvolvimento e Homologacao)

1. Teste de integracao do evento ERP para fila.
2. Teste de idempotencia com evento duplicado.
3. Teste de falha temporaria e retry.
4. Teste de falha definitiva e dead letter queue.
5. Teste de consulta antes e depois de processamento.
6. Teste de multi-tenant.
7. Teste de seguranca por perfil.
8. Teste de carga com lote de NF-e.
9. Teste de cancelamento e atualizacao de status.
10. Teste de rastreabilidade ponta a ponta.

## 16. Criterios de Aceite

1. XML oficial disponivel no SaaS dentro do SLA.
2. DANFE disponivel no SaaS dentro do SLA.
3. Sem duplicidade para mesma chave_nfe.
4. Reprocessamento funcional por chave.
5. Logs e auditoria completos por evento.
6. Indicadores operacionais disponiveis em dashboard.

## 17. Riscos e Mitigacoes

1. Atraso no processamento da fila: mitigacao com auto-scaling e alertas.
2. Falha de geracao de DANFE: mitigacao com retries e fila de reprocesso.
3. Divergencia de dados ERP vs SaaS: mitigacao com validacao de hash e reconciliacao periodica.
4. Crescimento de armazenamento: mitigacao com politica de retencao e arquivamento frio.

## 18. Observacao Final

Para compliance fiscal, manter sempre o XML original autorizado como fonte oficial. O DANFE pode ser gerado sob demanda ou armazenado, conforme politica de custo e performance.
