# Skill: Flutter + Firestore SDUI POC

## Objetivo
Criar uma POC Flutter com integração ao Google Firestore onde:
- aproximadamente 65% do projeto seja implementado nativamente em Flutter;
- até 35% do projeto seja definido via arquivos JSON/SDUI carregados do Firestore;
- os dados venham de consultas a APIs;
- o data-bind entre os arquivos JSON SDUI e os resultados das APIs seja rápido, previsível e fácil de manter;
- o conteúdo funcione offline com sincronização/recuperação a partir do Firestore.

## Quando usar esta skill
Use esta skill quando você precisar:
- planejar a arquitetura de uma POC Flutter com SDUI dinâmica;
- decidir o que deve ficar em código nativo e o que pode ficar em JSON;
- integrar Firestore como fonte de configuração e conteúdo;
- criar um pipeline de dados com APIs, cache local e renderização dinâmica.

## Fluxo recomendado

### 1. Definir a divisão de responsabilidade
- Mantenha em Flutter nativo:
  - navegação complexa;
  - estado local e autenticação;
  - lógica de negócio sensível;
  - widgets reutilizáveis e componentes de alto desempenho;
  - integrações com SDKs e APIs específicas.
- Coloque em JSON/SDUI:
  - telas simples ou parcialmente dinâmicas;
  - layouts baseados em componentes reutilizáveis;
  - textos, regras visuais, mapeamentos de conteúdo e fluxo de tela.
- Garanta que a proporção final permaneça próxima a 65% nativo / 35% dinâmico.

### 2. Definir contratos de dados
- Criar um contrato claro entre:
  - resposta da API;
  - estrutura JSON SDUI;
  - mapeamento de campos para widgets e bindings.
- Padronizar:
  - nomes de campos;
  - tipos de dados;
  - nomes de ações;
  - regras de fallback quando um campo vier nulo.
- Evitar dependência forte de estruturas aninhadas difíceis de manter.

### 3. Planejar a integração com Firestore
- Usar Firestore para armazenar:
  - templates SDUI;
  - dados de configuração;
  - conteúdo público ou parcialmente dinâmico;
  - versões dos schemas.
- Implementar estratégia de cache local inteligente:
  - **Sincronização em Tempo Real (Snapshots)**: Assinar a coleção inteira de templates através de um único listener real-time no início do ciclo de vida do app para sincronizar automaticamente as atualizações em background;
  - **Estratégia Cache-First**: Buscar layouts prioritariamente a partir do cache local do dispositivo (`Source.cache`) para carregamento instantâneo (< 10ms) sem latência de rede ou requisições adicionais;
  - **Fallbacks Confiáveis**: Fallback automático para persistência secundária (ex: SharedPreferences) e assets JSON internos compilados no app.

### 4. Implementar o pipeline de dados
- Buscar dados da API;
- normalizar e transformar os resultados para um formato consistente;
- aplicar binding entre os campos da API e os placeholders/slots do JSON SDUI;
- renderizar com widgets Flutter nativos;
- manter logs simples e métricas básicas de latência e falha.

### 5. Otimizar performance e confiabilidade
- Evitar requisições de rede gRPC adicionais usando a base local sincronizada;
- preferir mapeamentos diretos e previsíveis;
- evitar recalcular bindings em excesso;
- usar cache local e reuso de modelos;
- validar se o binding funciona com dados reais de API antes de ampliar a POC;
- medir tempo de renderização e tempo de resposta das consultas.

## Pontos de decisão
- Se um recurso exige lógica complexa, estado ou integração nativa, deixe no Flutter.
- Se um recurso é visual, textual ou configurável e pode mudar sem novo deploy, deixe no JSON/Firestore.
- Se os dados precisam funcionar offline, sempre inclua um passo de cache local e fallback.
- Se o binding entre API e JSON ficar ambíguo, normalize a estrutura antes de implementar a tela.

## Critérios de qualidade
A POC está pronta quando:
- a arquitetura mantém o equilíbrio desejado entre Flutter nativo e JSON SDUI;
- os templates carregados do Firestore renderizam corretamente offline e online;
- os bindings entre API e JSON são claros, rápidos e consistentes;
- o fluxo de dados não depende de lógica espalhada em vários arquivos;
- a experiência de uso permanece estável mesmo com falhas de rede.

## Prompt útil para esta skill
Use prompts como:
1. "Proponha a arquitetura inicial da POC Flutter com Firestore, mantendo 65% nativo e 35% em SDUI JSON."
2. "Crie o contrato de dados entre a resposta da API e os campos do JSON SDUI."
3. "Implemente o fluxo offline com cache local e fallback do Firestore."
4. "Otimize o data-bind para que os dados da API sejam aplicados rapidamente nos componentes SDUI."

## Saída esperada
Esta skill ajuda a gerar decisões arquiteturais, contratos de dados, fluxo de integração e critérios de verificação para uma POC Flutter com Firestore e SDUI dinâmica.
