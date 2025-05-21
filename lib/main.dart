import 'package:flutter/material.dart';
import 'package:gerenciar_entrega/models/entrega_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initDatabase();
  runApp(const MyApp());
}

late Future<Database> database;

Future<void> _initDatabase() async {
  database = openDatabase(
    join(await getDatabasesPath(), 'entregas.db'),
    version: 1,
    onCreate: (db, version) {
      return db.execute('''CREATE TABLE entregas ( 
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          nomeDestinatario TEXT, 
          endereco TEXT, 
          descricao TEXT, 
          status INTEGER
        )''');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(title: 'Entregas'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<EntregaModel>> entregasFuture;

  @override
  void initState() {
    super.initState();
    entregasFuture = getEntregas();
  }

  void atualizarEntregas() {
    setState(() {
      entregasFuture = getEntregas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: FutureBuilder<List<EntregaModel>>(
        future: entregasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma entrega cadastrada'));
          }
          final entregas = snapshot.data!;
          return ListView.builder(
            itemCount: entregas.length,
            itemBuilder: (context, index) {
              return cardEntrega(context, entregas[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              final formKey = GlobalKey<FormState>();
              String nomeDestinatario = '';
              String endereco = '';
              String descricao = '';

              return AlertDialog(
                title: const Text('Cadastrar Entrega'),
                content: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Nome do Destinatário',
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty
                                  ? 'Informe o nome'
                                  : null,
                          onSaved: (value) => nomeDestinatario = value ?? '',
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Endereço',
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty
                                  ? 'Informe o endereço'
                                  : null,
                          onSaved: (value) => endereco = value ?? '',
                        ),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Descrição',
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty
                                  ? 'Informe a descrição'
                                  : null,
                          onSaved: (value) => descricao = value ?? '',
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        final novaEntrega = EntregaModel(
                          nomeDestinatario: nomeDestinatario,
                          endereco: endereco,
                          descricao: descricao,
                          status: 0,
                        );
                        await insertEntrega(novaEntrega);
                        Navigator.of(context).pop();
                        atualizarEntregas();
                      }
                    },
                    child: const Text('Salvar'),
                  ),
                ],
              );
            },
          );
        },
        tooltip: 'Adicionar',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget cardEntrega(BuildContext context, EntregaModel entrega) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () async {
                  await deleteEntrega(entrega.id!);
                              atualizarEntregas();
                },
                icon: Icon(Icons.delete, color: Colors.red, size: 25),
              ),
            ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(Icons.person, color: Colors.blue),
                    ),
                    title: const Text(
                      'Destinatário',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      entrega.nomeDestinatario,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: const Icon(Icons.location_on, color: Colors.green),
                    ),
                    title: const Text(
                      'Endereço',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      entrega.endereco,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(Icons.description, color: Colors.blue),
                    ),
                    title: const Text(
                      'Descrição',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      entrega.descricao,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          entrega.status == 1 ? 'Concluída' : 'Em andamento',
                          style: TextStyle(
                            color: entrega.status == 1
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: entrega.status == 1
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          // Implementar detalhes se quiser
                        },
                        child: const Text('Ver detalhes'),
                      ),
                      TextButton(
                        onPressed: entrega.status == 1
                            ? null
                            : () async {
                                final atualizada = EntregaModel(
                                  id: entrega.id,
                                  nomeDestinatario: entrega.nomeDestinatario,
                                  endereco: entrega.endereco,
                                  descricao: entrega.descricao,
                                  status: 1,
                                );
                                await updateEntrega(atualizada);
                                atualizarEntregas();
                              },
                        child: CircleAvatar(
                          backgroundColor: entrega.status == 1
                              ? Colors.grey.shade300
                              : Colors.green.shade100,
                          child: const Icon(
                            Icons.check,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> insertEntrega(EntregaModel entrega) async {
    final db = await database;
    await db.insert(
      'entregas',
      entrega.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<EntregaModel>> getEntregas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('entregas');
    return List.generate(maps.length, (i) {
      return EntregaModel.fromMap(maps[i]);
    });
  }

  Future<void> updateEntrega(EntregaModel entrega) async {
    final db = await database;
    await db.update(
      'entregas',
      entrega.toMap(),
      where: 'id = ?',
      whereArgs: [entrega.id],
    );
  }

  Future<void> deleteEntrega(int id) async {
    final db = await database;
    await db.delete('entregas', where: 'id = ?', whereArgs: [id]);
  }
}