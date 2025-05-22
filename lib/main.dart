// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:gerenciar_entrega/models/entrega_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      return db.execute('''
        CREATE TABLE entregas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nomeDestinatario TEXT,
          cep TEXT,
          endereco TEXT,
          descricao TEXT,
          status INTEGER
        )
      ''');
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
        useMaterial3: true,
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
  List<EntregaModel> entregas = [];
  final nomeDestinatarioController = TextEditingController();
  final descricaoController = TextEditingController();
  final cepController = TextEditingController();
  final enderecoController = TextEditingController();
  String? rua;
  String? bairro;
  bool carregando = false;

  @override
  void initState() {
    super.initState();
    atualizarEntregas();
  }

  Future<void> atualizarEntregas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('entregas');
    setState(() {
      entregas = List.generate(maps.length, (i) => EntregaModel.fromMap(maps[i]));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: entregas.isEmpty
          ? const Center(child: Text('Nenhuma entrega cadastrada.'))
          : ListView.builder(
              itemCount: entregas.length,
              itemBuilder: (context, index) {
                return cardEntrega(context, entregas[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioCadastro(context, entrega: null),
        tooltip: 'Adicionar',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _mostrarFormularioCadastro(BuildContext context, {required EntregaModel? entrega}) {
  final formKey = GlobalKey<FormState>();
  String nomeDestinatario = '';
  String descricao = '';
  nomeDestinatarioController.clear();
  descricaoController.clear();
  cepController.clear();
  enderecoController.clear();


  if (entrega != null) {
    nomeDestinatarioController.text = entrega.nomeDestinatario;
    descricaoController.text = entrega.descricao;
    cepController.text = entrega.cep.replaceAll(RegExp(r'\D'), '');
    enderecoController.text = entrega.endereco;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    backgroundColor: Colors.white,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 24,
              left: 16,
              right: 16,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entrega == null
                          ? '📦 Nova Entrega'
                          : '✏️ Editar Entrega',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Nome do Destinatário',
                        prefixIcon: const Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      controller: nomeDestinatarioController,
                      validator: (value) => value == null || value.isEmpty ? 'Informe o nome' : null,
                      onSaved: (value) => nomeDestinatario = value ?? '',
                    ),
                    const SizedBox(height: 12),
          
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'CEP',
                        prefixIcon: const Icon(Icons.location_on),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      controller: cepController,
                      keyboardType: TextInputType.number,
                      onChanged: (value) async {
                      if (value.length == 8) {
                        try {
                          setModalState(() => carregando = true);
                          await setCEP(value);
                        } catch (_) {
                          enderecoController.text = '';
                        } finally {
                          setModalState(() => carregando = false);
                        }
                      }
                    },
                    ),
                    const SizedBox(height: 12),
          
                    TextFormField(
                      controller: enderecoController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: carregando ? 'Procurando...' : 'Endereço',
                        prefixIcon: const Icon(Icons.map),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
          
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Descrição',
                        prefixIcon: const Icon(Icons.edit),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      controller: descricaoController,
                      validator: (value) => value == null || value.isEmpty ? 'Informe a descrição' : null,
                      onSaved: (value) => descricao = value ?? '',
                    ),
                    entrega != null 
                    ?Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Switch(
                          value: entrega?.status == 1,
                          onChanged: (value) {
                            setModalState(() {
                              entrega = entrega?.copyWith(status: value ? 1 : 0);
                            });
                          },
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (entrega?.status == 1) ? 'Concluída' : 'Em andamento',
                          style: TextStyle(
                            color: (entrega?.status == 1) ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ) : const SizedBox(),
                    const SizedBox(height: 24),
          
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                formKey.currentState!.save();
                                if (entrega == null) {
                                  final novaEntrega = EntregaModel(
                                  nomeDestinatario: nomeDestinatario,
                                  cep: cepController.text,
                                  endereco: enderecoController.text,
                                  descricao: descricao,
                                  status: 0,
                                );
                                await insertEntrega(novaEntrega);
                                } else {
                                  final entregaAtualizada = EntregaModel(
                                    id: entrega!.id,
                                    nomeDestinatario: nomeDestinatario,
                                    cep: cepController.text,
                                    endereco: enderecoController.text,
                                    descricao: descricao,
                                    status: entrega!.status,
                                  );
                                  await updateEntrega(entregaAtualizada);
                                }
                                
                                await atualizarEntregas();
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('Salvar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        }
      );
    },
  );
}



  Widget cardEntrega(BuildContext context, EntregaModel entrega) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildListTile(Icons.person, 'Destinatário', entrega.nomeDestinatario),
              _buildListTile(Icons.location_on, 'Endereço', entrega.endereco),
              _buildListTile(Icons.description, 'Descrição', entrega.descricao),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(
                      entrega.status == 1 ? 'Concluída' : 'Em andamento',
                      style: TextStyle(
                        color: entrega.status == 1 ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor:
                        entrega.status == 1 ? Colors.green.shade50 : Colors.orange.shade50,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    tooltip: 'Marcar como concluída',
                    onPressed: entrega.status == 1
                        ? null
                        : () async {
                            final atualizada = EntregaModel(
                              id: entrega.id,
                              nomeDestinatario: entrega.nomeDestinatario,
                              cep: entrega.cep,
                              endereco: entrega.endereco,
                              descricao: entrega.descricao,
                              status: 1,
                            );
                            await updateEntrega(atualizada);
                            await atualizarEntregas();
                          },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Excluir',
                    onPressed: () async {
                      _mostrarFormularioCadastro(context, entrega: entrega);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Excluir',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Confirmar exclusão'),
                          content: const Text('Deseja realmente excluir esta entrega?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Excluir'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await deleteEntrega(entrega.id!);
                        await atualizarEntregas();
                      }
                    },
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 14)),
    );
  }

  Future<void> insertEntrega(EntregaModel entrega) async {
    final db = await database;
    await db.insert('entregas', entrega.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateEntrega(EntregaModel entrega) async {
    final db = await database;
    await db.update('entregas', entrega.toMap(), where: 'id = ?', whereArgs: [entrega.id]);
  }

  Future<void> deleteEntrega(int id) async {
    final db = await database;
    await db.delete('entregas', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setCEP(String cep) async {
    cep = cep.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) throw Exception('CEP inválido. Deve conter 8 dígitos.');
    final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['erro'] == true) throw Exception('CEP não encontrado.');
      rua = jsonData['logradouro'];
      bairro = jsonData['bairro'];
      setState(() {
        enderecoController.text = '$rua, $bairro';
      });
    } else {
      throw Exception('Erro ao buscar CEP');
    }
  }
  
}
