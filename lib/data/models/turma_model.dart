class Turma {
  final int? idTurma;
  final String turma;
  final int? idcurso;
  final int? idturno;
  final int? idinstrutor;

  Turma({
    this.idTurma,
    required this.turma,
    required this.idcurso,
    required this.idturno,
    required this.idinstrutor,
  });

  Map<String, dynamic> toMap() {
    return {
      'idTurma': idTurma,
      'turma': turma,
      'idcurso': idcurso,
      'idturno': idturno,
      'idinstrutor': idinstrutor,
    };
  }
}
