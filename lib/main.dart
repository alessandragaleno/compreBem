import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'screens/map_screen.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RegistrationScreen(),
    );
  }
}

// classe para manipular o banco de dados SQLite
class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._init();

  DatabaseHelper._init();

  // Inicializa o banco de dados
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app.db');
    return _database!;
  }

  // Criação do banco de dados e tabelas
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    print("Caminho do banco de dados: $path"); // exibe o caminho do banco de dados no console

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        email TEXT,
        phone TEXT,
        password TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE shopping_lists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        name TEXT,
        items TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
    // log para confirmar a criação do banco
    print("Banco de dados e tabelas criados com sucesso!");
  }
}

// tela de cadastro
class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController photoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  // Função para cadastrar usuário
  void _register(BuildContext context) async {
    // obtém a instância do banco de dados
    final db = await DatabaseHelper.instance.database;

    // verifica se as senhas digitadas são iguais
    if (passwordController.text != confirmPasswordController.text) {
      if (!mounted) return; // Garante que o widget ainda está na árvore antes de chamar o contexto
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('As senhas não coincidem!')), // Exibe uma mensagem de erro
      );
      return; // encerra a função sem cadastrar o usuário
    }

    // insere os dados do usuário no banco de dados
    await db.insert('users', {
      'username': usernameController.text, // nome de usuário
      'email': emailController.text, // email do usuário
      'phone': photoController.text, // telefone do usuário
      'password': passwordController.text, // senha (idealmente deveria ser criptografada)
    });

    if (!mounted) return; // verifica se widget ainda está ativo antes de navegar

    // Navega para a tela de login após o cadastro bem-sucedido
    Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: usernameController, decoration: InputDecoration(labelText: 'Nome de usuário')),
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'E-mail')),
            TextField(controller: photoController, decoration: InputDecoration(labelText: 'Telefone')),
            TextField(
              controller: passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Senha',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            TextField(
              controller: confirmPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(labelText: 'Confirme a senha'),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () => _register(context), child: Text('Cadastro')),
          ],
        ),
      ),
    );
  }
}

// tela de login
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // função para Login do usuário
  void _login(BuildContext context) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [usernameController.text, passwordController.text],
    );

    if (result.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuário ou senha inválidos!')),
      );
    } else {
      // Navega para a tela inicial após login bem-sucedido
      Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: usernameController, decoration: InputDecoration(labelText: 'Nome de usuário')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Senha')),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () => _login(context), child: Text('Entrar')),
          ],
        ),
      ),
    );
  }
}

// Tela Inicial com opções para gerenciar listas de compras
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Início')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bem-vindo! Aqui você pode gerenciar suas listas de compras.'),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MapScreen()),
              );
            }, 
            child: Text('Criar nova lista de compras')),
          ],
        ),
      ),
    );
  }
}
