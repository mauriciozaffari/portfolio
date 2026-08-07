---
id: scan-page-performance
type: case_study
locale: pt-BR
status: published
confidentiality: public
updated: "2026-08-06"
title: Uma página que levava quatro minutos, e os cinco motivos
organization: Looper Insights
period: "2026"
technologies:
  - Ruby on Rails
  - PostgreSQL
  - ActiveRecord
---

## Problema

A principal página de scan levava mais de quatro minutos para carregar. Para um
cliente era pior: de dez a quinze minutos, tempo suficiente para as pessoas
deixarem de usar o recurso e pedirem a outra pessoa que mande uma planilha no
lugar.

## Abordagem

Não havia uma causa única, e essa é a parte interessante. Cinco coisas
distintas se acumulavam: um `COUNT DISTINCT` se espalhando sobre um join, um
scope que varria a tabela inteira em vez da fatia daquela requisição, um
sequential scan sobre 16,7 milhões de linhas, um join contra uma tabela de
aproximadamente 1,5 bilhão de linhas e a falta de cache em um agregado agrupado
caro.

Corrigi uma por vez e medi depois de cada correção, porque causas que se
acumulam mascaram umas às outras — corrija a segunda pior primeiro e a melhora
parece desprezível, o que tenta você a concluir que ali não estava o problema.
Duas das cinco pediam desnormalização em vez de ajuste de consulta: um booleano
levado para a linha que precisava dele, o que fez o join de um bilhão de linhas
desaparecer, e um agregado JSONB em cache, atualizado por um worker dedicado em
vez de calculado a cada requisição.

Para o cliente mais afetado, a correção foi mais estreita e saiu no mesmo dia:
uma verificação de existência que fazia trabalho linear passou a ser uma busca
O(1).

## Resultado

De quatro minutos para menos de um segundo. O caminho específico daquele
cliente saiu de dez a quinze minutos para praticamente instantâneo, entregue
como hotfix no mesmo dia. Um filtro relacionado na mesma página saiu de 322
segundos a frio para 25,5 segundos, ancorando uma subconsulta sem escopo para
que ela pudesse usar um índice que já existia.

Depois fiz essa classe inteira de regressão falhar de forma ruidosa,
habilitando `strict_loading` em toda a suíte de testes, para que um N+1
acidental quebre o CI em vez de chegar silenciosamente à produção.
