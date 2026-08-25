import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Tela de entrada: alterna entre login e cadastro no mesmo formulario.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  bool _cadastrando = false;
  bool _ocultarSenha = true;
  bool _carregando = false;
  String? _erro;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      if (_cadastrando) {
        await _auth.signUp(_emailCtrl.text, _senhaCtrl.text);
      } else {
        await _auth.signIn(_emailCtrl.text, _senhaCtrl.text);
      }
      // Em caso de sucesso o AuthGate troca de tela sozinho; nao ha
      // navegacao manual aqui.
    } catch (e) {
      if (mounted) setState(() => _erro = AuthService.mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _entrarComGoogle() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await _auth.signInWithGoogle();
    } catch (e) {
      // mensagemDeErro devolve null quando o usuario so fechou o seletor
      // de contas - nesse caso a tela nao mostra erro nenhum.
      if (mounted) setState(() => _erro = AuthService.mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _recuperarSenha() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _erro = 'Escreva seu e-mail para receber o link.');
      return;
    }
    try {
      await _auth.resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link de recuperacao enviado para $email')),
      );
    } catch (e) {
      if (mounted) setState(() => _erro = AuthService.mensagemDeErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.pets, size: 64, color: Colors.brown.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'PetCare',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _cadastrando
                          ? 'Crie sua conta para salvar seus pets na nuvem'
                          : 'Entre para acessar seus pets e lembretes',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.brown.shade400),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: const Icon(Icons.mail_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'Informe seu e-mail';
                        if (!t.contains('@') || !t.contains('.')) {
                          return 'E-mail invalido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _senhaCtrl,
                      obscureText: _ocultarSenha,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_ocultarSenha
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _ocultarSenha = !_ocultarSenha),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if ((v ?? '').isEmpty) return 'Informe sua senha';
                        if (v!.length < 6) return 'Minimo de 6 caracteres';
                        return null;
                      },
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _erro!,
                                style: TextStyle(color: Colors.red.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _carregando ? null : _enviar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _carregando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _cadastrando ? 'Criar conta' : 'Entrar',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.brown.shade100)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'ou',
                            style: TextStyle(color: Colors.brown.shade300),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.brown.shade100)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _carregando ? null : _entrarComGoogle,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.brown.shade800,
                          side: BorderSide(color: Colors.brown.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'G',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Entrar com Google',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!_cadastrando)
                      TextButton(
                        onPressed: _carregando ? null : _recuperarSenha,
                        child: Text(
                          'Esqueci minha senha',
                          style: TextStyle(color: Colors.brown.shade600),
                        ),
                      ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: _carregando
                          ? null
                          : () => setState(() {
                                _cadastrando = !_cadastrando;
                                _erro = null;
                              }),
                      child: Text(
                        _cadastrando
                            ? 'Ja tenho conta. Entrar'
                            : 'Nao tenho conta. Cadastrar',
                        style: TextStyle(color: Colors.brown.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
