class UnidadesCurriculares {
  final int? idUc;
  final String nomeUc;
  final int cargahoraria;
  final int idcurso;

  UnidadesCurriculares({
    this.idUc,
    required this.nomeUc,
    required this.cargahoraria,
    required this.idcurso,
  });

  Map<String, dynamic> toMap() {
    return {
      'idUc': idUc,
      'nome_uc': nomeUc,
      'cargahoraria': cargahoraria,
      'idcurso': idcurso,
    };
  }
}
