class Turno {
  final int? idTurno;
  final String turno;

  Turno({
    this.idTurno,
    required this.turno,
  });

  Map<String, dynamic> toMap() {
    return {
      'idTurno': idTurno,
      'turno': turno,
    };
  }
}
