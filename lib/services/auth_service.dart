import 'package:firebase_auth/firebase_auth.dart';

/// Camada fina sobre o FirebaseAuth.
///
/// Existe para que as telas nao dependam direto do SDK e para traduzir os
/// codigos de erro do Firebase em mensagens que dao para mostrar ao usuario.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<void> signOut() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Traduz FirebaseAuthException para texto em portugues.
  static String mensagemDeErro(Object e) {
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
