# PetCare

Aplicativo Android de gerenciamento e cuidados com animais de estimação.

- **Frontend:** Flutter
- **Backend:** Firebase (Authentication + Cloud Firestore)
- **Projeto Firebase:** `petcare-8f604`

## Funcionalidades

| Tela | O que faz | Origem dos dados |
|---|---|---|
| Início | Lembretes do dia, dicas rápidas e atividade dos pets | Firestore + assets |
| Notícias | Notícias sobre pets | Firestore (`news`) |
| Cuidados | Guias de cuidado | Firestore (`care`) |
| Raças | 19 raças com filtro por espécie e busca | `assets/breeds/breeds.json` |
| Meus Pets | Cadastro e edição de pets | Firestore (`users/{uid}/pets`) |

Entrar por e-mail/senha ou conta Google. Cada usuário só enxerga os próprios
pets e lembretes — as regras em `firestore.rules` restringem
`users/{userId}` ao dono autenticado.

## Rodando o projeto

```bash
flutter pub get
flutter run
```

Os testes cobrem serialização dos modelos e integridade dos assets — inclusive
verificam que toda raça declarada em `breeds.json` tem o arquivo de imagem
correspondente no disco:

```bash
flutter test
```

## Publicando

Dois passos ainda faltam antes de subir para a Play Store.

O `applicationId` já é `br.com.pedrov1ni.petcare`, registrado no Firebase com
o SHA-1 da chave de debug.

### 1. Criar a chave de assinatura

O Gradle já está configurado para usar uma chave de release quando
`android/key.properties` existir, e cair na chave de debug quando não existir.
Gere a sua:

```bash
keytool -genkey -v -keystore ~/petcare-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias petcare
```

Crie `android/key.properties` com o conteúdo abaixo, usando as senhas que você
definiu no comando acima:

```properties
storePassword=SUA_SENHA
keyPassword=SUA_SENHA
keyAlias=petcare
storeFile=C:/caminho/para/petcare-release.jks
```

Esse arquivo e qualquer `.jks`/`.keystore` estão no `.gitignore`. **Nunca
versione a chave nem as senhas** — perder a chave significa não conseguir mais
publicar atualizações do app.

### 2. Registrar o SHA-1 de release

O login com Google valida a assinatura do app. O SHA-1 cadastrado hoje no
Firebase é o da chave de **debug**, então o login funciona no emulador mas
falharia no app publicado. Extraia o SHA-1 da chave de release:

```bash
keytool -list -v -keystore ~/petcare-release.jks -alias petcare
```

E cadastre em Firebase Console → Configurações do projeto → Seus apps →
Android → Adicionar impressão digital.

## Notícias automáticas

A aba Notícias não tem conteúdo escrito à mão: um job em
[.github/workflows/noticias.yml](.github/workflows/noticias.yml) roda a cada 6
horas, busca feeds RSS, filtra e publica na coleção `news` do Firestore. O app
lê essa coleção como sempre leu.

```bash
cd tools/noticias
npm install
npm run simular   # mostra o que seria publicado, sem escrever nem exigir chave
```

Rodar `simular` antes de mexer nos filtros de
[fontes.js](tools/noticias/fontes.js) evita descobrir problema só depois de
publicar.

### Segredos do repositório

| Secret | Obrigatório | Para quê |
|---|---|---|
| `FIREBASE_SERVICE_ACCOUNT` | sim | Gravar no Firestore. É o JSON da conta de serviço, inteiro |
| `GROQ_API_KEY` | não | Resumir as matérias por IA. Sem ela o job publica normalmente, usando o resumo do próprio veículo |

Há ainda a variável opcional `GROQ_MODEL`, caso a Groq aposente o modelo padrão
— dá para trocar sem mexer no código.

### Por que só parte das notícias tem resumo

Notícias vindas do Google Notícias chegam por um link de redirecionamento
criptografado: não é possível alcançar a matéria para ler resumo, imagem de capa
ou texto. Essas aparecem só com título, veículo e data.

As de link direto trazem `og:description` e `og:image` — metadados que o próprio
veículo publica para preview de link. Quando há chave da Groq, o resumo é
refeito a partir do texto da matéria e o app marca **"Resumido por IA"**.

**A IA nunca resume o que não pode ler.** Gerar um "resumo" a partir de um
título seria inventar conteúdo, e num app sobre saúde animal isso pode virar
orientação errada sobre medicamento ou doença.

## Planejamento

### Reconhecimento de raça por IA

Tirar uma foto do pet e o app sugerir a raça, ligando o resultado à tela de
Raças que já existe.

O que precisa ser decidido antes de implementar:

- **Onde o modelo roda.** Na nuvem (API de visão) é mais preciso e não pesa no
  APK, mas tem custo por chamada e exige internet. No aparelho (TensorFlow Lite
  com MobileNet) é grátis, funciona offline e responde rápido, mas adiciona
  alguns MB ao app e erra mais em raças parecidas.
- **O que fazer com o erro.** Classificador de raça acerta bem em raça pura e
  se perde em vira-lata — que é a maioria dos cães no Brasil e já é a primeira
  entrada do `breeds.json`. A resposta precisa ser sugestão com grau de
  confiança, nunca afirmação.
- **Privacidade.** Se a foto sair do aparelho, isso tem que estar dito de forma
  clara para o usuário.

O projeto já tem a base: `image_picker` para a câmera, e o catálogo de 19 raças
para onde apontar o resultado.

## Créditos das imagens

As fotos das raças vêm do Wikimedia Commons. A maioria está sob licenças
Creative Commons que **exigem atribuição visível** — por isso o app tem uma
tela de créditos, acessível pelo ícone de informação em "Meus Pets".

Detalhes de licença e autoria de cada imagem em
[CREDITOS_IMAGENS.md](CREDITOS_IMAGENS.md), com a mesma lista servida ao app
por `assets/creditos.json`.
