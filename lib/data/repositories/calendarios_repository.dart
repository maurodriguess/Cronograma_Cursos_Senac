import 'package:cronograma/core/database_helper.dart' hide Aula;
import 'package:cronograma/data/models/aula_model.dart' show Aula;
import 'package:sqflite/sqflite.dart';
import '../models/calendarios_model.dart';

class CalendariosRepository {
  final DatabaseHelper _databaseHelper;

  CalendariosRepository(this._databaseHelper);

  /// Insere um novo calendário no banco de dados
  Future<int> insertCalendario(Calendarios calendario) async {
    final db = await _databaseHelper.database;
    try {
      return await db.insert(
        'Calendarios',
        {
          'ano': calendario.ano,
          'mes': calendario.mes,
          'data_inicio': DatabaseHelper.formatarParaBanco(
              DateTime.parse(calendario.dataInicio)),
          'data_fim': DatabaseHelper.formatarParaBanco(
              DateTime.parse(calendario.dataFim)),
          'idturma': calendario.idTurma,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Falha ao inserir calendário: $e');
    }
  }

  /// Obtém todos os calendários cadastrados
  Future<List<Calendarios>> getCalendarios() async {
    final db = await _databaseHelper.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('Calendarios');
      return maps.map((map) => _mapearCalendario(map)).toList();
    } catch (e) {
      throw Exception('Falha ao buscar calendários: $e');
    }
  }

  /// Atualiza um calendário existente
  Future<int> updateCalendario(Calendarios calendario) async {
    final db = await _databaseHelper.database;
    try {
      return await db.update(
        'Calendarios',
        {
          'ano': calendario.ano,
          'mes': calendario.mes,
          'data_inicio': DatabaseHelper.formatarParaBanco(
              DateTime.parse(calendario.dataInicio)),
          'data_fim': DatabaseHelper.formatarParaBanco(
              DateTime.parse(calendario.dataFim)),
          'idturma': calendario.idTurma,
        },
        where: 'idCalendarios = ?',
        whereArgs: [calendario.idCalendarios],
      );
    } catch (e) {
      throw Exception('Falha ao atualizar calendário: $e');
    }
  }

  /// Remove um calendário pelo ID
  Future<int> deleteCalendario(int id) async {
    final db = await _databaseHelper.database;
    try {
      return await db.delete(
        'Calendarios',
        where: 'idCalendarios = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Falha ao deletar calendário: $e');
    }
  }

  /// Busca calendários associados a uma turma específica
  Future<List<Calendarios>> getCalendariosPorTurma(int idTurma) async {
    final db = await _databaseHelper.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'Calendarios',
        where: 'idturma = ?',
        whereArgs: [idTurma],
      );
      return maps.map((map) => _mapearCalendario(map)).toList();
    } catch (e) {
      throw Exception('Falha ao buscar calendários por turma: $e');
    }
  }

  /// Salva uma lista de aulas no banco de dados
  Future<void> salvarAulas(List<Aula> aulas) async {
    final db = await _databaseHelper.database;
    try {
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final aula in aulas) {
          batch.insert(
            'Aulas',
            {
              'idUc': aula.idUc,
              'idTurma': aula.idTurma,
              'data': DatabaseHelper.formatarParaBanco(aula.data),
              'horario': aula.horarioInicio,
              'status': aula.status,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit();
      });
    } catch (e) {
      throw Exception('Falha ao salvar aulas: $e');
    }
  }

  /// Verifica conflitos de período
  Future<bool> existeCalendarioNoPeriodo(DateTime inicio, DateTime fim,
      {int? idIgnorar}) async {
    final db = await _databaseHelper.database;
    try {
      final result = await db.rawQuery(
          '''
        SELECT COUNT(*) as count FROM Calendarios 
        WHERE (
          (? BETWEEN data_inicio AND data_fim) OR
          (? BETWEEN data_inicio AND data_fim) OR
          (data_inicio BETWEEN ? AND ?) OR
          (data_fim BETWEEN ? AND ?)
        ${idIgnorar != null ? 'AND idCalendarios != ?' : ''}
      ''',
          [
            DatabaseHelper.formatarParaBanco(inicio),
            DatabaseHelper.formatarParaBanco(fim),
            DatabaseHelper.formatarParaBanco(inicio),
            DatabaseHelper.formatarParaBanco(fim),
            DatabaseHelper.formatarParaBanco(inicio),
            DatabaseHelper.formatarParaBanco(fim),
            if (idIgnorar != null) idIgnorar,
          ].where((e) => e != null).toList());

      return (result.first['count'] as int) > 0;
    } catch (e) {
      throw Exception('Falha ao verificar período: $e');
    }
  }

  /// Mapeia um Map para o modelo Calendarios
  Calendarios _mapearCalendario(Map<String, dynamic> map) {
    return Calendarios(
      idCalendarios: map['idCalendarios'] as int?,
      ano: map['ano'] as int,
      mes: map['mes'] as String,
      dataInicio: DatabaseHelper.formatarParaBrasil(
          DateTime.parse(map['data_inicio'] as String)),
      dataFim: DatabaseHelper.formatarParaBrasil(
          DateTime.parse(map['data_fim'] as String)),
      idTurma: map['idturma'] as int,
    );
  }
}
