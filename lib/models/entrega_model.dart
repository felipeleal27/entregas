import 'dart:convert';

class EntregaModel {
  final int? id;
  final String nomeDestinatario;
  final String endereco;
  final String descricao;
  final int status;

  EntregaModel({
    this.id,
    required this.nomeDestinatario,
    required this.endereco,
    required this.descricao,
    required this.status,
  });

  factory EntregaModel.fromMap(Map<String, dynamic> map) {
    return EntregaModel(
      id: map['id'] as int?,
      nomeDestinatario: map['nomeDestinatario'] as String,
      endereco: map['endereco'] as String,
      descricao: map['descricao'] as String,
      status: map['status'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nomeDestinatario': nomeDestinatario,
      'endereco': endereco,
      'descricao': descricao,
      'status': status,
    };
  }

  factory EntregaModel.fromJson(String source) =>
      EntregaModel.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());
}
