---
id: cognito-auth-migration
type: case_study
locale: pt-BR
status: published
confidentiality: public
updated: "2026-08-06"
title: Levando todos os usuários para uma autenticação gerenciada
organization: Looper Insights
period: 2021 - 2022
technologies:
  - Ruby on Rails
  - AWS Cognito
  - OIDC
  - Redis
---

## Problema

A autenticação era feita em casa, e os clientes corporativos começavam a pedir
coisas em que autenticação feita em casa é ruim: identidade federada, o single
sign-on deles e um tratamento de tokens que pudéssemos mostrar durante uma
revisão de segurança.

## Abordagem

Liderei a migração de toda a empresa para o AWS Cognito ao longo de cerca de
dois meses: integração OIDC, verificação de tokens bearer, tratamento de
refresh e sessões guardadas em Redis com persistência em banco, para que um
restart não desconectasse todo mundo.

A parte que exige cuidado não é o sistema novo, é a transição. Todo usuário
existente tinha de continuar funcionando o tempo todo, o que significou rodar
os dois caminhos contra tráfego real antes de o código legado poder ser
removido — e então removê-lo de verdade, em vez de deixar um ramo morto para
confundir quem fosse ler depois.

## Resultado

Um único provedor de identidade gerenciado para toda a plataforma, com o SSO de
cliente passando a ser um exercício de configuração e não um projeto de
engenharia. Depois construí sobre essa base as páginas voltadas ao cliente,
autenticadas pelo próprio single sign-on de um estúdio.
