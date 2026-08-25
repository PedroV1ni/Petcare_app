import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Camada fina sobre o FirebaseAuth.
///
/// Existe para que as telas nao dependam direto do SDK e para traduzir os
/// codigos de erro do Firebase em mensagens que dao para mostrar ao usuario.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Client OAuth do tipo 3 (web) gerado ao ativar o Login do Google.
  /// No Android e ele que o Google usa como serverClientId para emitir o
  /// idToken que o Firebase aceita. Nao e segredo: ja vai no
  /// android/app/google-services.json, que esta versionado.
  static const String _serverClientId =
      '416285618937-b7i5f1qcqtj2k7uu95o7u516867i0uje.apps.googleusercontent.com';

  static bool _googleIniciado = false;

  /// O initialize do google_sign_in 7.x deve rodar uma unica vez por processo.
  static Future<void> _garanteGoogleIniciado() async {
    if (_googleIniciado) return;
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _googleIniciado = true;
  }

  /// Emite o usuario atual a cada login/logout. E a fonte de verdade que o
  /// AuthGate e os providers escutam.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;

  Future<void> signIn(String email, String senha) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  Future<void> signUp(String email, String senha) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha,
    );
  }

  /// Entra com a conta Google e troca o idToken por uma sessao do Firebase.
  ///
  /// No google_sign_in 7.x o authentication devolve apenas idToken - nao ha
  /// mais accessToken - e o Firebase aceita a credencial so com ele.
  Future<void> signInWithGoogle() async {
    await _garanteGoogleIniciado();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw FirebaseAuthException(
        code: 'operation-not-supported-in-this-environment',
        message: 'Login com Google nao e suportado nesta plataforma.',
      );
    }

    final GoogleSignInAccount conta = await GoogleSignIn.instance.authenticate();
    final String? idToken = conta.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message: 'O Google nao devolveu um idToken.',
      );
    }

    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  /// Encerra a sessao do Firebase e tambem a do Google, senao o proximo
  /// "Entrar com Google" reaproveita a conta sem deixar escolher outra.
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Sem sessao Google ativa (login por e-mail/senha): nada a fazer.
    }
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Traduz os erros de autenticacao para texto em portugues.
  ///
  /// Devolve null quando o usuario apenas desistiu do fluxo do Google: nesse
  /// caso nao ha nada de errado para mostrar na tela.
  static String? mensagemDeErro(Object e) {
    if (e is GoogleSignInException) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
          return null;
        case GoogleSignInExceptionCode.interrupted:
        case GoogleSignInExceptionCode.uiUnavailable:
          return 'O login com Google foi interrompido. Tente de novo.';
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          return 'Login com Google mal configurado. Confira o SHA-1 do app '
              'no Firebase Console e o google-services.json do projeto.';
        default:
          return 'Nao foi possivel entrar com o Google. Tente de novo.';
      }
    }
    if (e is! FirebaseAuthException) return 'Algo deu errado. Tente de novo.';
    switch (e.code) {
      case 'invalid-email':
        return 'E-mail invalido.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Ja existe uma conta com esse e-mail.';
      case 'weak-password':
        return 'A senha precisa ter ao menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sem conexao. Verifique sua internet.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um momento.';
      case 'operation-not-allowed':
        return 'Login por e-mail/senha nao esta habilitado no Firebase '
            'Console (Authentication > Sign-in method).';
      case 'configuration-not-found':
        return 'O Authentication ainda nao foi ativado neste projeto. '
            'Abra o Firebase Console > Authentication > Comecar e habilite '
            'o provedor E-mail/senha.';
      default:
        return e.message ?? 'Algo deu errado. Tente de novo.';
    }
  }
}
