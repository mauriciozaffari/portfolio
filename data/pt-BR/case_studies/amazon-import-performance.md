---
id: amazon-import-performance
type: case_study
locale: pt-BR
status: draft
confidentiality: public
updated: "2026-08-06"
title: Reduzindo uma importação de 46 minutos para 16 minutos
organization: Looper Insights
period: "2026"
technologies:
  - Ruby on Rails
  - PostgreSQL
  - Redis
---

## Problema

As importações de merchandising da Amazon US levavam cerca de 46 minutos. As
entregas para clientes ficavam na fila atrás delas, então uma única importação
lenta atrasava os relatórios que as pessoas realmente estavam esperando. O
volume era a parte difícil: aproximadamente 273.000 posições de título por
scan, contra 12,5 a 13 milhões de títulos processados por semana.

## Abordagem

O gargalo não era a busca dos dados, era o caminho de escrita — cada linha
pagava por durabilidade e manutenção de índice de que não precisava enquanto
ainda estava em trânsito. Movi a ingestão para tabelas de staging UNLOGGED no
PostgreSQL, de modo que as linhas em andamento não passam pelo write-ahead log,
e depois promovi essas linhas para as tabelas reais quando a importação
terminava. Junto com isso, paralelizei a etapa de busca e passei a transmitir
os resultados por Redis em vez de acumulá-los na memória do processo.

As tabelas de staging são seguras aqui justamente porque o dado é
reconstruível: uma tabela UNLOGGED não sobrevive a uma queda do banco, e essa é
uma troca aceitável quando a ação de recuperação é rodar a importação de novo.

## Resultado

De 46 minutos para cerca de 16 — uma redução de 65%, confirmada de forma
independente por um colega que mediu o mesmo pipeline. As entregas para
clientes deixaram de ficar na fila atrás da janela de importação.
