class Calendarios {
  final int? idCalendarios;
  final int ano;
  final String mes;
  final String dataInicio;
  final String dataFim;
  final int idturma;

  Calendarios({
    this.idCalendarios,
    required this.ano,
    required this.mes,
    required this.dataInicio,
    required this.dataFim,
    required this.idturma,
  });

  Map<String, dynamic> toMap() {
    return {
      'idCalendarios': idCalendarios,
      'ano': ano,
      'mes': mes,
      'data_inicio': dataInicio,
      'data_fim': dataFim,
      'idturma': idturma,
    };
  }
}
