---
id: release-engineering
type: case_study
locale: pt-BR
status: published
confidentiality: public
updated: "2026-10-04"
title: Sessenta releases e um botão de release
organization: Looper Insights
period: 2022 - 2026
technologies:
  - Ruby on Rails
  - RSpec
  - Cypress
  - GitHub Actions
---

## Problema

Os releases eram manuais e tribais: quem conhecia os passos os executava, e
os passos viviam na cabeça de alguém. O produto atende Disney, Warner Bros,
Sony e NBCUniversal, então um release ruim não é um inconveniente interno —
é um incidente visível para o cliente. Dois repositórios viraram três quando
o frontend foi extraído, o que triplicou a cerimônia.

## Abordagem

Eu conduzia o trem de releases de ponta a ponta nos três repositórios: um
code freeze quinzenal que eu instituí, gating de QA, deploys em produção,
hotfixes e um plano de rollback para cada release. Depois transformei as
partes que uma máquina consegue fazer em uma máquina fazendo: um workflow
automatizado de release que builda, roda os gates de qualidade, faz deploy e
verifica a saúde. O gate são nove linters mais a suíte end-to-end de Cypress
ligada aos deploys e aos merges de pull requests, então as verificações que
dependiam de alguém lembrar agora são o pipeline se recusando a continuar.
Os templates de plano de teste e checklist de rollback que escrevi se
tornaram os que PM e QA reproduziram para cada release seguinte.

Por um período também fui release manager de um código frontend que eu não
desenvolvia, porque conduzir o trem é uma habilidade separada de escrever o
código que ele entrega.

## Resultado

Mais de sessenta releases e hotfixes entregues ao longo de quatro eras de
nomenclatura do produto, sem o processo de release ser o gargalo. Os releases
pausavam quando eu estava de férias — a evidência mais forte que posso dar de
que o processo funcionava e de que eu ainda não tinha terminado de torná-lo
independente de mim.