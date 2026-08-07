---
id: leadership
type: leadership
locale: pt-BR
status: draft
confidentiality: public
updated: "2026-08-06"
title: Como eu trabalho
---

Lidero um time pequeno de engenharia e nunca parei de escrever código. Continuo
sendo o maior contribuidor da base de código que lidero, e essa combinação é
deliberada, não uma falha em delegar: reviso código que eu mesmo poderia ter
escrito, e não imponho uma arquitetura que eu não esteja disposto a construir.
A alavancagem funciona nas duas direções — pelas decisões que as outras pessoas
herdam e pelo trabalho que eu entrego.

**Encontro a causa antes de escrever a correção.** Uma página lenta normalmente
tem mais de um motivo para ser lenta, e o primeiro que você encontra raramente
é o mais caro. Eu faço profiling, leio o plano de execução da consulta e
corrijo a coisa de verdade. Uma página que herdei levava mais de quatro minutos
para carregar por cinco motivos que se acumulavam; corrigindo um por vez, com
uma medição depois de cada um, ela ficou abaixo de um segundo. Adivinhar teria
corrigido um dos cinco.

**Um teste de regressão que passa antes da correção não vale nada.** Já
rejeitei testes meus por isso. Um deles inseria um valor em branco por um
caminho de escrita do ActiveRecord que silenciosamente o convertia em `nil`,
então o teste nunca exercitava o bug que dizia cobrir. Isso é falsa confiança,
e é pior do que não ter teste, porque impede que alguém volte a olhar.

**A integridade fica no banco de dados quando pode ficar.** Verificações de
unicidade na aplicação perdem corridas. Se uma duplicata nunca pode existir,
prefiro deduplicar uma vez, criar o índice único e deixar o sistema falhar de
forma fechada a partir dali.

**Code review é onde os padrões de fato se propagam.** Comento sobre rigor de
teste e formato da arquitetura, não sobre formatação — formatação é trabalho do
linter. Um princípio ao qual sempre volto: um controller sem um model
correspondente é um mau sinal, porque uma mudança de estado em um registro é
quase sempre o `update` daquele registro, e não um controller novo.

**Releases precisam de um plano de rollback que alguém realmente pensou.** Eu
cuido dos checklists de release: reversibilidade das migrações, drenagem das
filas, uma referência registrada do último estado bom conhecido. Quando nossa
ferramenta de release encontrou um padrão de merge que tornava o rebase
inseguro, corrigi a ferramenta e escrevi o motivo, para que a próxima pessoa
encontre um modo de falha documentado em vez de um mistério.

**Eu registro as coisas por escrito.** Decisões de arquitetura, notas de
domínio sobre os subsistemas que surpreendem as pessoas e os padrões de agentes
de IA que nossa organização segue hoje. Uma decisão que vive apenas em uma
thread do Slack precisa ser rediscutida cada vez que alguém novo pergunta.
