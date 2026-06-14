# Seed Utility: SDUI no Cloud Firestore

Este subprojeto contém o script utilitário de Seed desenvolvido em Node.js para automatizar o carregamento e a atualização dos templates JSON de Server-Driven UI (SDUI) no Google Cloud Firestore.

Ele lê os arquivos localizados na pasta `sdui_with_firestore/assets/sdui/`, valida a sintaxe dos mesmos e os envia para a coleção do Firestore mapeada no Flutter POC.

---

## 📂 Estrutura de Documentos no Firestore

O script envia cada arquivo JSON para a coleção `sdui_templates`. O ID do documento será o próprio nome do arquivo (sem a extensão `.json`).

Por exemplo:
- `product_detail.json` ➡️ Coleção: `sdui_templates` | Documento ID: `product_detail`
- `product_filter.json` ➡️ Coleção: `sdui_templates` | Documento ID: `product_filter`
- `product_list.json` ➡️ Coleção: `sdui_templates` | Documento ID: `product_list`

Cada documento é persistido na seguinte estrutura de campos:

```json
{
  "template": {
    "type": "screen",
    "appBar": { ... },
    "body": { ... }
    // Conteúdo original do arquivo JSON
  },
  "updatedAt": Timestamp // Data de envio
}
```

---

## 🛠️ Pré-requisitos

Certifique-se de ter instalado em sua máquina:
- **Node.js** (versão 18 ou superior)
- **npm** ou outro gerenciador de pacotes equivalente

---

## 📥 Instalação

Navegue até a pasta `seed` do projeto e instale as dependências:

```bash
npm install
```

---

## 🚀 Como Executar

O utilitário suporta dois modos de conexão com o Firestore: **Local Emulator** e **Instância de Produção/Staging**.

### 1. Usando o Firestore Emulator (Recomendado para Testes Locais)
Para rodar apontando para o emulador local do Firebase:

```bash
npm run seed -- --emulator
# ou a abreviação:
npm run seed -- -e
```

> **Nota:** Por padrão, o script tentará conectar em `127.0.0.1:8080`. Se o seu emulador estiver rodando em uma porta diferente, você pode configurar a variável de ambiente:
> ```bash
> export FIRESTORE_EMULATOR_HOST="localhost:8085"
> npm run seed
> ```

---

### 2. Conectando a um Banco de Dados Firestore de Produção/Homologação

Para conectar a uma instância real na nuvem do Google Cloud Firebase, você precisa de um arquivo de credenciais de **Conta de Serviço (Service Account)**.

#### Passos para obter as credenciais:
1. No console do Firebase, acesse **Configurações do Projeto** ⚙️ > **Contas de Serviço**.
2. Clique no botão **Gerar nova chave privada** e faça o download do arquivo JSON.
3. Salve esse arquivo dentro do diretório `seed` com o nome `service-account.json`.

#### Executando o script:
Uma vez que o arquivo `service-account.json` estiver presente na pasta, basta executar:

```bash
npm run seed
```

**Alternativas de credenciais:**
- Caso o arquivo tenha outro nome ou esteja em outro caminho, execute passando o parâmetro `--key`:
  ```bash
  npm run seed -- --key=/caminho/para/sua/chave.json
  ```
- Ou defina a variável de ambiente do Google Cloud:
  ```bash
  export GOOGLE_APPLICATION_CREDENTIALS="/caminho/para/sua/chave.json"
  npm run seed
  ```

---

## 🔍 Validações do Script

Para garantir a confiabilidade dos deploys das telas SDUI, o script realiza as seguintes etapas automatizadas antes do upload:
1. **Verificação de Pasta:** Garante que o diretório `sdui_with_firestore/assets/sdui` existe e possui arquivos.
2. **Validação de Sintaxe JSON:** Se qualquer arquivo JSON possuir erros de sintaxe (como vírgulas extras, chaves faltando), o script interrompe o processo e relata o arquivo com erro com a respectiva linha de erro, impedindo o envio de dados corrompidos para o Firestore.
3. **Logs Detalhados:** Apresenta logs formatados no terminal indicando o progresso e o status de cada arquivo individualmente.
