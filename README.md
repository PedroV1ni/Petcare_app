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

Três passos precisam ser feitos antes de subir para a Play Store. Nenhum
deles está pronto no repositório.

### 1. Trocar o `applicationId`

Hoje é `com.example.petcare_app`, o placeholder do template do Flutter. A Play
Store rejeita qualquer pacote começando com `com.example`.

A ordem importa, porque o `google-services.json` é atrelado ao nome do pacote:

1. No Firebase Console, adicione um **novo app Android** com o pacote
   definitivo (ex.: `br.com.seudominio.petcare`)
2. Baixe o `google-services.json` novo e substitua `android/app/google-services.json`
3. Só então troque `applicationId` e `namespace` em `android/app/build.gradle.kts`
4. Renomeie a pasta de `MainActivity.kt` em
   `android/app/src/main/kotlin/` para refletir o novo pacote

Trocar o `applicationId` antes do passo 1 quebra o app: o Firebase recusa a
inicialização com `No matching client found for package name`.

### 2. Criar a chave de assinatura

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

### 3. Registrar o SHA-1 de release

O login com Google valida a assinatura do app. O SHA-1 cadastrado hoje no
Firebase é o da chave de **debug**, então o login funciona no emulador mas
falharia no app publicado. Extraia o SHA-1 da chave de release:

```bash
keytool -list -v -keystore ~/petcare-release.jks -alias petcare
```

E cadastre em Firebase Console → Configurações do projeto → Seus apps →
Android → Adicionar impressão digital.

## Créditos das imagens

As fotos das raças vêm do Wikimedia Commons. A maioria está sob licenças
Creative Commons que **exigem atribuição visível** — por isso o app tem uma
tela de créditos, acessível pelo ícone de informação em "Meus Pets".

Detalhes de licença e autoria de cada imagem em
[CREDITOS_IMAGENS.md](CREDITOS_IMAGENS.md), com a mesma lista servida ao app
por `assets/creditos.json`.
