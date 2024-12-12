class Cursos {
  final int? idCursos;
  final String nomeCurso;
  final int cargahoraria;

  Cursos({
    this.idCursos,
    required this.nomeCurso,
    required this.cargahoraria,
  });

  Map<String, dynamic> toMap() {
    return {
      'idCursos': idCursos,
      'nome_curso': nomeCurso,
      'cargahoraria': cargahoraria,
    };
  }
}
