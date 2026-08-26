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
— dá para trocar sem mexer no código. Sem ela o script pergunta à API quais
modelos a conta tem e escolhe sozinho, porque nomes de modelo são aposentados
sem aviso e fixar um no código quebra o job em silêncio.

### Limites da camada gratuita

A camada gratuita da Groq permite 8.000 tokens por minuto. O job manda no
máximo 7.000 caracteres de cada matéria e pede até 700 tokens de resposta, o que
cabe com folga. Se ainda assim estourar, a Groq responde quanto falta esperar e
o script aguarda e repete, em vez de descartar a matéria.

Cada execução só resume o que é novo: matérias já resumidas antes são
reaproveitadas. Como as fontes publicam uma ou duas por dia e o job roda de 6 em
6 horas, isso é a diferença entre ~50 e ~1.200 chamadas por mês.

### O que vira notícia e o que vira cuidado

Cada matéria é classificada em um dos dois tipos, e é isso que decide a aba:

- **notícia** — fato datado: campanha de vacinação, projeto de lei, alerta.
- **cuidado** — guia que não envelhece: "Pode dar dipirona para cachorro?".

O perfil da fonte é o ponto de partida (blog de varejista vive de guia,
conselho de veterinária vive de notícia) e o título pode mudar a conclusão.
Fato datado ganha do formato de guia: prefeitura explicando como agendar
castração continua sendo notícia.

Guia aparece em **Cuidados**, abaixo das dicas escritas no app. Antes os dois
ficavam juntos e um guia que continuava valendo envelhecia junto com a notícia
do dia.

### Só entra o que dá para ler

Matéria que o agregador não consegue abrir é descartada. No app ela seria só um
título: abrir não entregaria nada e o único caminho seria sair para o navegador.

Foi por isso que o Google Notícias saiu das fontes, apesar de ser quem dava mais
volume — o link dele é um redirecionamento criptografado que só resolve dentro
do navegador.

As fontes atuais trazem `og:description` e `og:image`, metadados que o próprio
veículo publica para preview de link. Havendo chave da Groq, o resumo é refeito
a partir do texto da matéria e o app marca **"Resumido por IA"**.

**A IA nunca resume o que não pode ler.** Gerar um "resumo" a partir de um
título seria inventar conteúdo, e num app sobre saúde animal isso pode virar
orientação errada sobre medicamento ou doença.

### Dicas rápidas

A aba Cuidados abre com dicas curtas, e cada uma sai do texto de uma matéria
real — tocar nela abre o guia de onde veio, e o veículo aparece no próprio
cartão. Antes essas dicas eram digitadas dentro do app.

A dica sai da mesma chamada da IA que gera o resumo. Pedir separado dobraria as
chamadas, e o limite da camada gratuita é por minuto.

**O que a dica pode dizer é mais estreito que o resumo**, porque ela é lida
fora do contexto da matéria: observação, prevenção, higiene, rotina e quando
procurar um veterinário. Medicamento, dose e tratamento ficam de fora — "1 gota
por quilo" lido solto, sem a parte de que só vale com prescrição, vira
instrução de automedicação. Matéria sobre tratamento simplesmente não rende
dica, e o campo `dicaAvaliada` registra que a IA já foi consultada, para a
recusa não virar nova tentativa a cada execução.

### Ordem e validade

A lista vai da mais recente para a mais antiga, e a janela desejada é de 15
dias. Só a janela deixava o app com 7 matérias — as fontes brasileiras de pet
publicam pouco —, então há um piso: faltando matéria nova, a lista completa com
as mais recentes que sobraram, até o teto de 45 dias.

### Curadoria

`fontes.js` tem duas listas de termos. Um termo terminado em `*` é raiz e casa
com o que vier depois (`castra*` pega castração e CastraMóvel); sem o `*`, tem
de ser a palavra inteira — foi o que impediu `pet` de casar dentro de `Petz` e
aprovar uma matéria sobre limpar piscina.

A lista de exclusão existe porque feed oficial publica muito para o próprio
público: edital, anuidade, código de ética e cédula profissional não mudam nada
para quem tem um cachorro em casa.

O filtro tem teste (`node --test`), e o teste roda no CI antes de publicar.

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
