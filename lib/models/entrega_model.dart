class EntregaModel {
  final int? id;
  final String nomeDestinatario;
  final String cep;
  final String endereco;
  final String numeroDaCasa;
  final String descricao;
  final int status;

  EntregaModel({
    this.id,
    required this.nomeDestinatario,
    required this.cep,
    required this.endereco,
    required this.numeroDaCasa,
    required this.descricao,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nomeDestinatario': nomeDestinatario,
      'cep': cep,
      'endereco': endereco,
      'numeroDaCasa': numeroDaCasa,
      'descricao': descricao,
      'status': status,
    };
  }

  factory EntregaModel.fromMap(Map<String, dynamic> map) {
    return EntregaModel(
      id: map['id'],
      nomeDestinatario: map['nomeDestinatario'],
      cep: map['cep'],
      endereco: map['endereco'],
      numeroDaCasa: map['numeroDaCasa'],
      descricao: map['descricao'],
      status: map['status'],
    );
  }

  EntregaModel copyWith({
    int? id,
    String? nomeDestinatario,
    String? cep,
    String? endereco,
    String? numeroDaCasa,
    String? descricao,
    int? status,
  }) {
    return EntregaModel(
      id: id ?? this.id,
      nomeDestinatario: nomeDestinatario ?? this.nomeDestinatario,
      cep: cep ?? this.cep,
      endereco: endereco ?? this.endereco,
      numeroDaCasa: numeroDaCasa ?? this.numeroDaCasa,
      descricao: descricao ?? this.descricao,
      status: status ?? this.status,
    );
  }
}
