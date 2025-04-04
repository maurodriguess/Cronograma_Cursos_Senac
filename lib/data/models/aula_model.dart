import 'package:flutter/material.dart';

class Aula {
  final int? idAula;
  final int idUc;
  final int idTurma;
  final DateTime data;
  final TimeOfDay horarioInicio;
  final TimeOfDay horarioFim;
  final String status; // 'agendada', 'confirmada', 'cancelada', 'realizada'
  final String? observacoes;
  final DateTime? dataCriacao;
  final DateTime? dataAtualizacao;

  Aula({
    this.idAula,
    required this.idUc,
    required this.idTurma,
    required this.data,
    required this.horarioInicio,
    required this.horarioFim,
    this.status = 'agendada',
    this.observacoes,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  })  : dataCriacao = dataCriacao ?? DateTime.now(),
        dataAtualizacao = dataAtualizacao ?? DateTime.now();

  // Duração da aula em minutos
  int get duracaoMinutos {
    return (horarioFim.hour * 60 + horarioFim.minute) -
        (horarioInicio.hour * 60 + horarioInicio.minute);
  }

  // Verifica se a aula já ocorreu
  bool get foiRealizada {
    final agora = DateTime.now();
    final aulaDateTime = DateTime(
      data.year,
      data.month,
      data.day,
      horarioFim.hour,
      horarioFim.minute,
    );
    return aulaDateTime.isBefore(agora);
  }

  factory Aula.fromMap(Map<String, dynamic> map) {
    return Aula(
      idAula: map['idAula'] as int?,
      idUc: map['idUc'] as int,
      idTurma: map['idTurma'] as int,
      data: DateTime.parse(map['data'] as String),
      horarioInicio: _parseTime(map['horarioInicio'] as String),
      horarioFim: _parseTime(map['horarioFim'] as String),
      status: map['status'] as String? ?? 'agendada',
      observacoes: map['observacoes'] as String?,
      dataCriacao: map['dataCriacao'] != null
          ? DateTime.parse(map['dataCriacao'] as String)
          : null,
      dataAtualizacao: map['dataAtualizacao'] != null
          ? DateTime.parse(map['dataAtualizacao'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idAula': idAula,
      'idUc': idUc,
      'idTurma': idTurma,
      'data': data.toIso8601String(),
      'horarioInicio': _formatTime(horarioInicio),
      'horarioFim': _formatTime(horarioFim),
      'status': status,
      'observacoes': observacoes,
      'dataCriacao': dataCriacao?.toIso8601String(),
      'dataAtualizacao': dataAtualizacao?.toIso8601String(),
    };
  }

  // Helper para converter String para TimeOfDay
  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  // Helper para formatar TimeOfDay como String
  static String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Cria uma cópia com novos valores
  Aula copyWith({
    int? idAula,
    int? idUc,
    int? idTurma,
    DateTime? data,
    TimeOfDay? horarioInicio,
    TimeOfDay? horarioFim,
    String? status,
    String? observacoes,
  }) {
    return Aula(
      idAula: idAula ?? this.idAula,
      idUc: idUc ?? this.idUc,
      idTurma: idTurma ?? this.idTurma,
      data: data ?? this.data,
      horarioInicio: horarioInicio ?? this.horarioInicio,
      horarioFim: horarioFim ?? this.horarioFim,
      status: status ?? this.status,
      observacoes: observacoes ?? this.observacoes,
      dataCriacao: this.dataCriacao,
      dataAtualizacao: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Aula(idAula: $idAula, UC: $idUc, Turma: $idTurma, ${data.day}/${data.month}/${data.year} ${_formatTime(horarioInicio)}-${_formatTime(horarioFim)}, Status: $status)';
  }
}
