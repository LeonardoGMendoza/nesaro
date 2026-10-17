# Nesaro · ネサロ · 根咲路

**Respostas automáticas no Direct.** A pessoa comenta uma palavra-chave num post ou Reel e a Nesaro manda a mensagem no Direct na hora, pela API oficial da Meta.

```
nesaro/
├── app/        App Flutter (Android e iPhone) — Firebase Auth + Firestore
├── backend/    API .NET 10 em camadas — roda no seu VPS (Docker)
├── firebase/   Regras de segurança do Firestore
└── firebase.json
```

---

## Como as peças conversam

```
[App Flutter] ──login──► [Firebase Auth]
     │ cria/edita automações
     ▼
[Firestore] ◄──── grava histórico e contadores ──── [API .NET no VPS]
                                                      ▲        │
                                       webhook        │        │ envia a DM
                                     (comentário)     │        ▼
                                                   [Instagram / Meta]
```

- O **app** só mexe nos dados do próprio usuário (garantido pelas regras do Firestore).
- O **backend** é o único que conhece o token do Instagram. O token fica **criptografado** e nunca chega no celular.
- A senha do Instagram **nunca** passa pela Nesaro: a conexão é pelo OAuth oficial da Meta.

---

## Backend: arquitetura em camadas

```
backend/src/
├── Nesaro.Domain/          entidades e regras puras (não depende de nada)
├── Nesaro.Application/     casos de uso + interfaces (depende só do Domain)
├── Nesaro.Infrastructure/  Firestore, Firebase, API da Meta, fila, criptografia
└── Nesaro.Api/             endpoints HTTP — composition root
backend/tests/
└── Nesaro.Domain.Tests/    testes da regra de palavra-chave
```

| Camada | Conteúdo |
|---|---|
| Domain | `Automation`, `Execution`, `InstagramConnection`, `IncomingComment`, `KeywordMatcher` (maiúsculas, acentos, pontuação e emojis ignorados) |
| Application | `ProcessCommentHandler`, `ConnectInstagramHandler`, `DisconnectInstagramHandler`, `RefreshInstagramTokensHandler` e as interfaces `IAutomationRepository`, `IExecutionRepository`, `IInstagramConnectionRepository`, `ITokenStore`, `IInstagramClient`, `ICommentQueue`, `IOAuthStateService`, `IIdTokenVerifier`, `IClock` |
| Infrastructure | Repositórios Firestore, `InstagramClient` (HttpClient tipado), `OAuthStateService` e `FirestoreTokenStore` (Data Protection), `ChannelCommentQueue`, workers em segundo plano |
| Api | `/webhooks/instagram`, `/auth/instagram/start`, `/auth/instagram/callback`, `/auth/instagram/disconnect`, `/health`, validação da assinatura da Meta, filtro de login Firebase |

### Regras de injeção de dependência

1. **Dependências só apontam para dentro:** Api → Infrastructure → Application → Domain. O Domain não referencia nada.
2. **A Application só conhece interfaces.** Nenhum caso de uso usa Firestore, `HttpClient` ou ASP.NET diretamente.
3. **Cada camada registra o que é dela:** `AddApplication()` e `AddInfrastructure(configuration)`. O `Program.cs` só chama os dois.
4. **Tempo de vida:**
   - `Singleton`: `FirestoreDb`, `FirebaseApp`, fila, relógio, serviço de state OAuth, verificador de token, validador de assinatura
   - `Scoped`: casos de uso, repositórios e token store
   - `HttpClient` tipado: `AddHttpClient<IInstagramClient, InstagramClient>()`
   - `HostedService`: `CommentProcessingWorker` e `TokenRefreshWorker`
5. **Sem dependência cativa:** os workers são Singleton, então nunca recebem serviços Scoped no construtor. Eles criam um escopo por item com `IServiceScopeFactory`.
6. **Options Pattern validado:** `MetaOptions` e `FirebaseProjectOptions` usam `[Required]` com `ValidateOnStart()`. Se faltar configuração, a API nem sobe.
7. **Só injeção por construtor:** nada de `new` em serviços e nada de service locator, com exceção dos workers acima, que precisam do escopo.
8. **Segredos fora do código:** tudo vem de variáveis de ambiente (`.env` no VPS).

### Fluxo de um comentário

1. A Meta chama `POST /webhooks/instagram`.
2. A API confere a assinatura `X-Hub-Signature-256`, coloca o comentário na fila e responde 200 na hora.
3. O `CommentProcessingWorker` pega o comentário e chama o `ProcessCommentHandler`, que:
   - descobre o cliente pela conta do Instagram (`igAccounts/{id}`)
   - pega a primeira automação ativa que casa com o texto e o post
   - cria `executions/{commentId}`. Se o documento já existir, para aí: é a **idempotência**
   - envia a resposta privada (DM) e depois a resposta pública opcional
   - registra sucesso ou falha e atualiza os contadores

---

## App Flutter

```
app/lib/
├── core/            tema (cores do logo) e configuração
├── data/
│   ├── models/          Automation, Execution, InstagramStatus
│   ├── repositories/    Auth, Automation, Execution, Account
│   └── services/        NesaroApi (chama o backend)
├── features/
│   ├── auth/            login, cadastro, esqueci a senha, aceite dos termos
│   ├── home/            navegação inferior
│   ├── dashboard/       números e atividade recente
│   ├── automations/     lista, criar, editar, ativar/pausar, duplicar, excluir
│   └── account/         conectar/desconectar Instagram, sair
├── widgets/         logotipo desenhado em código
├── app.dart
└── main.dart        composition root (MultiProvider)
```

A injeção de dependência no app segue a mesma ideia do backend: tudo é criado no `main.dart` com `provider`, e as telas pegam os repositórios com `context.read<...>()`. Nenhuma tela chama `FirebaseAuth.instance` ou `FirebaseFirestore.instance` direto.

---

## Passo a passo

### 1. Enviar para o GitHub (Git Bash)

```bash
cd ~/Documents
unzip nesaro.zip          # ou extraia pelo Windows
cd nesaro

git init -b main
git add .
git commit -m "Primeira versão da Nesaro: app Flutter + API .NET em camadas"
git remote add origin https://github.com/LeonardoGMendoza/nesaro.git
git push -u origin main
```

### 2. Firebase

1. Crie um projeto no [Firebase Console](https://console.firebase.google.com) (por exemplo, `nesaro`).
2. Ative **Authentication → E-mail/senha** e o **Firestore**.
3. Publique as regras:
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase use --add            # escolha o projeto
   firebase deploy --only firestore
   ```
4. Gere a **conta de serviço** para o backend: Configurações do projeto → Contas de serviço → *Gerar nova chave privada*. Salve como `backend/secrets/firebase-service-account.json`. Esse arquivo **não vai** para o GitHub.

### 3. App Flutter

```bash
cd app
flutter create . --org br.com.nesaro --platforms=android,ios   # gera as pastas android/ e ios/
flutter pub get

dart pub global activate flutterfire_cli
flutterfire configure          # cria lib/firebase_options.dart e liga o Firebase

# Rodar apontando para a API (no emulador Android, 10.0.2.2 = seu PC)
flutter run --dart-define=NESARO_API_URL=http://10.0.2.2:8080
```

Se o `pub get` reclamar de versão, rode `flutter pub upgrade --major-versions`.

### 4. Backend local

```bash
cd backend
dotnet build Nesaro.slnx
dotnet test Nesaro.slnx

# Configuração local (Git Bash)
export Meta__AppId=...
export Meta__AppSecret=...
export Meta__RedirectUri=http://localhost:8080/auth/instagram/callback
export Meta__WebhookVerifyToken=uma-senha-que-voce-inventa
export Firebase__ProjectId=seu-projeto
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/secrets/firebase-service-account.json"

dotnet run --project src/Nesaro.Api
curl http://localhost:8080/health
```

Se você só tiver o .NET 8 instalado, instale o SDK do .NET 10 (LTS) ou troque `net10.0` por `net8.0` nos `.csproj`. Nesse caso, ajuste também as versões dos pacotes `Microsoft.Extensions.*` para `8.0.x` e use `dotnet new sln` no lugar do `.slnx`.

### 5. App na Meta (Meta for Developers)

1. Crie um app do tipo **Business** e adicione o produto **Instagram → API setup with Instagram login**.
2. Copie o **App ID** e o **App Secret** do Instagram para o `.env`.
3. **Redirect URI** do OAuth: `https://api.SEU-DOMINIO/auth/instagram/callback`.
4. **Webhooks:** URL `https://api.SEU-DOMINIO/webhooks/instagram`, verify token igual ao `Meta__WebhookVerifyToken`, assine o campo **comments**.
5. Permissões: `instagram_business_basic`, `instagram_business_manage_comments` e `instagram_business_manage_messages`.
6. Para clientes de verdade, é preciso passar pela **App Review** e pela **verificação da empresa**. Enquanto isso, teste com contas adicionadas como testadoras no app.

### 6. Subir no VPS

```bash
# no VPS
git clone https://github.com/LeonardoGMendoza/nesaro.git
cd nesaro/backend
cp .env.example .env            # preencha
mkdir -p secrets keys
# copie firebase-service-account.json para ./secrets/
docker compose up -d --build
curl https://api.SEU-DOMINIO/health
```

- O DNS do domínio da API precisa apontar para o IP do VPS. O Caddy gera o HTTPS sozinho.
- **Já usa nginx ou Traefik no VPS (por exemplo, para o n8n)?** Remova o serviço `caddy` do `docker-compose.yml` e aponte o proxy que você já tem para `127.0.0.1:8080`.
- **Faça backup da pasta `keys/`.** São as chaves que descriptografam os tokens. Se ela for perdida, os clientes precisam reconectar o Instagram.

---

## Limitações conhecidas desta versão

- A fila é em memória: se a API reiniciar no meio do processamento, os comentários que estavam na fila se perdem. Para crescer, troque por Redis ou RabbitMQ implementando `ICommentQueue`.
- A escolha do post é pelo ID. A tela para escolher o post a partir das publicações da conta fica para a próxima etapa.
- Ainda não foram feitos: planos e pagamentos (Pix/cartão), limites por plano e o painel administrativo.

## Próximas etapas

1. Testar o fluxo completo com uma conta de teste na Meta
2. Seletor de posts no app (endpoint `GET /instagram/media`)
3. Planos e pagamentos (gateway com Pix) + limites por plano
4. Painel administrativo
5. Site (landing page + painel web)
