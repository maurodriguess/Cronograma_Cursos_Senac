import 'package:cronograma/data/models/aula_model.dart';
import 'package:cronograma/data/repositories/calendarios_repository.dart';
import 'package:flutter/material.dart';

class AutomatizadorCalendario {
  final CalendariosRepository _repo;

  AutomatizadorCalendario(this._repo);

  Future<AgendamentoResultado> agendarAulasAutomaticamente({
    required int idUc,
    required int idTurma,
    required int cargaHorariaTotal,
    required TimeOfDay horarioInicio,
    required TimeOfDay horarioFim,
    required List<int> diasDaSemana,
    required DateTime dataInicio,
    required DateTime dataTermino,
  }) async {
    try {
      // Validações básicas
      if (cargaHorariaTotal <= 0) {
        throw ArgumentError('Carga horária deve ser maior que zero');
      }
      
      if (horarioInicio.hour > horarioFim.hour || 
          (horarioInicio.hour == horarioFim.hour && horarioInicio.minute >= horarioFim.minute)) {
        throw ArgumentError('Horário de término deve ser após horário de início');
      }

      if (dataInicio.isAfter(dataTermino)) {
        throw ArgumentError('Data de término deve ser após data de início');
      }

      if (diasDaSemana.isEmpty) {
        throw ArgumentError('Selecione pelo menos um dia da semana');
      }

      // Gera as aulas
      final resultado = _gerarAulas(
        idUc: idUc,
        idTurma: idTurma,
        inicio: horarioInicio,
        fim: horarioFim,
        dias: diasDaSemana,
        start: dataInicio,
        end: dataTermino,
        cargaTotal: cargaHorariaTotal,
      );

      // Salva as aulas usando o repositório
      await _repo.salvarAulas(resultado.aulas);

      return resultado;
    } catch (e) {
      throw Exception('Falha no agendamento automático: $e');
    }
  }

  AgendamentoResultado _gerarAulas({
    required int idUc,
    required int idTurma,
    required TimeOfDay inicio,
    required TimeOfDay fim,
    required List<int> dias,
    required DateTime start,
    required DateTime end,
    required int cargaTotal,
  }) {
    final aulas = <Aula>[];
    final duracaoAula = (fim.hour - inicio.hour) + (fim.minute - inicio.minute) / 60;
    final totalAulasDesejadas = (cargaTotal / duracaoAula).ceil();
    DateTime currentDate = start;
    int aulasGeradas = 0;

    while (currentDate.isBefore(end) && aulasGeradas < totalAulasDesejadas) {
      if (dias.contains(currentDate.weekday)) {
        aulas.add(Aula(
          idUc: idUc,
          idTurma: idTurma,
          data: DateTime(currentDate.year, currentDate.month, currentDate.day),
          horarioInicio: inicio,
          horarioFim: fim,
          status: 'agendada',
          dataCriacao: DateTime.now(),
          dataAtualizacao: DateTime.now(),
        ));
        aulasGeradas++;
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    final cargaHorariaAgendada = aulasGeradas * duracaoAula;

    return AgendamentoResultado(
      aulas: aulas,
      aulasDesejadas: totalAulasDesejadas,
      aulasAgendadas: aulasGeradas,
      cargaHorariaDesejada: cargaTotal,
      cargaHorariaAgendada: cargaHorariaAgendada,
    );
  }
}

class AgendamentoResultado {
  final List<Aula> aulas;
  final int aulasDesejadas;
  final int aulasAgendadas;
  final double cargaHorariaDesejada;
  final double cargaHorariaAgendada;

  AgendamentoResultado({
    required this.aulas,
    required this.aulasDesejadas,
    required this.aulasAgendadas,
    required this.cargaHorariaDesejada,
    required this.cargaHorariaAgendada,
  });

  bool get cargaHorariaCompleta => cargaHorariaAgendada >= cargaHorariaDesejada;
}