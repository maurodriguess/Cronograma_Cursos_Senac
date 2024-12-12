class Estagio {
  final int? idEstagio;
  final int idturma;
  final String descricao;
  final int duracao;

  Estagio({
    this.idEstagio,
    required this.idturma,
    required this.descricao,
    required this.duracao,
  });

  Map<String, dynamic> toMap() {
    return {
      'idEstagio': idEstagio,
      'idturma': idturma,
      'descricao': descricao,
      'duracao': duracao,
    };
  }
}
