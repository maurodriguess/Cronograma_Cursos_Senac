class Turma {
  final int? idTurma;
  final String turma;
  final int? idcurso;
  final int idturno;
  final int idinstrutor;

  Turma({
    this.idTurma,
    required this.turma,
    required this.idcurso,
    required this.idturno,
    required this.idinstrutor,
  });

  // Adicione este método ESSENCIAL
  factory Turma.fromMap(Map<String, dynamic> map) {
    return Turma(
      idTurma: map['idTurma'] as int?,
      turma: map['turma'] as String,
      idcurso: map['idcurso'] as int,
      idturno: map['idturno'] as int,
      idinstrutor: map['idinstrutor'] as int,
    );
  }

  // Método útil para operações de insert/update
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