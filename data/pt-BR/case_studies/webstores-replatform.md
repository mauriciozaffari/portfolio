---
id: webstores-replatform
type: case_study
locale: pt-BR
status: draft
confidentiality: public
updated: "2026-08-06"
title: Trocando a plataforma do produto principal sem pará-lo
organization: Looper Insights
period: 2024 - 2025
technologies:
  - Ruby on Rails
  - React
  - PostgreSQL
  - RSpec
---

## Problema

O produto principal tinha acumulado a década habitual de decisões: um frontend
React embutido dentro do monolito Rails, de modo que os dois não podiam ser
implantados nem testados de forma independente, e uma parcela grande do código
anterior aos padrões que o time depois adotou. Reescrever tudo de uma vez não
era opção — ele atende Disney, Warner Bros, Sony e NBCUniversal e responde por
55% da receita da empresa.

## Abordagem

Conduzi a troca de plataforma como uma sequência de passos entregáveis, e não
como um branch que vivesse por seis meses. Em 261 commits sobre 844 arquivos,
reescrevi mais de 20% de uma base de código de aproximadamente 244.000 linhas,
elevando a cobertura de testes conforme avançava, porque eram os testes que
tornavam o passo seguinte seguro.

Em paralelo, extraí o frontend — cerca de 138.759 linhas de React — do monolito
para um repositório próprio, o que permitiu que frontend e backend passassem a
ser construídos, testados e implantados em cadências próprias.

## Resultado

Entregue de forma incremental, com a cobertura de testes saindo de 72% para 80%
ao longo do trabalho e continuando a subir depois. O product manager descreveu
o resultado como um release transformador. A extração do frontend é o que
tornou o trabalho de frontend seguinte independente dos ciclos de release do
backend.
