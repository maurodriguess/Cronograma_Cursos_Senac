class Cursos {
  final int? idCursos;
  final String nomeCurso;
  final int cargahoraria; // Total workload in hours

  Cursos({
    this.idCursos,
    required this.nomeCurso,
    required this.cargahoraria,
  });

  // Factory constructor for creating from database maps
  factory Cursos.fromMap(Map<String, dynamic> map) {
    return Cursos(
      idCursos: map['idCursos'] as int?,
      nomeCurso: map['nome_curso'] as String,
      cargahoraria: map['cargahoraria'] as int,
    );
  }

  // Convert to map for database operations
  Map<String, dynamic> toMap() {
    return {
      'idCursos': idCursos,
      'nome_curso': nomeCurso,
      'cargahoraria': cargahoraria,
    };
  }

  // Format workload for display (e.g., "1200 horas")
  String get cargaHorariaFormatada => '$cargahoraria horas';

  // Categorize course by workload
  String get categoria {
    if (cargahoraria >= 1200) return 'Técnico';
    if (cargahoraria >= 400) return 'Certificação';
    return 'Curta Duração';
  }

  // Estimated duration in months (assuming 80h/month)
  int get duracaoEstimadaMeses => (cargahoraria / 80).ceil();

  // Complete course information
  String get infoCurso {
    return '''
    Curso: $nomeCurso
    Carga Horária: $cargaHorariaFormatada
    Categoria: $categoria
    Duração Estimada: $duracaoEstimadaMeses meses
    ''';
  }

  // Validate course data
  static bool validar({
    required String nome,
    required int cargaHoraria,
  }) {
    return nome.length >= 5 && cargaHoraria > 0;
  }

  // Helper to create short description
  String get descricaoResumida => '$nomeCurso ($categoria)';
}