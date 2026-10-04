---
id: ai-delivery
type: case_study
locale: pt-BR
status: published
confidentiality: public
updated: "2026-10-04"
title: Colocando os primeiros recursos de IA em uma plataforma de clientes
organization: Looper Insights
period: "2026"
technologies:
  - Ruby on Rails
  - Integrações de LLM
  - ClickHouse
---

## Problema

A empresa queria recursos de IA no produto voltado aos clientes, e tinha seis
engenheiros em quem confiava para descobrir onde a IA realmente se paga. Dentro
da engenharia, assistentes de código com IA já estavam mudando a forma de
trabalhar, sem padrões compartilhados: cada engenheiro inventava seu próprio
workflow.

## Abordagem

Eu era um dos seis no piloto de IA da empresa, e assumi as duas metades do
problema — como construímos com IA, e o que entregamos com IA.

Para a primeira metade, escrevi o padrão de workflow AGENTS.md do time e o
compartilhei com toda a organização, de modo que o desenvolvimento guiado
por assistentes saiu de hábito pessoal para uma forma de trabalho
documentada e revisável. Publiquei avaliações de modelos que informaram a
escolha de ferramentas da organização.

Para a segunda metade, fui delivery lead da iniciativa de IA no produto
principal: páginas de IA voltadas aos clientes, incluindo uma autenticada
pelo single sign-on de um estúdio, e a arquitetura de segurança de dados
multi-tenant que permite um recurso de chat com LLM responder a partir dos
dados de um cliente sem que os dados de outro cliente estejam ao alcance. O
isolamento foi projetado antes do recurso ser aprovado, não retroajustado
depois.

## Resultado

Padrões adotados por toda a organização; páginas de IA no ar na frente de
clientes cujos nomes todos reconhecem; uma arquitetura de chat cujo modelo
de segurança foi revisado antes de entrar em produção.