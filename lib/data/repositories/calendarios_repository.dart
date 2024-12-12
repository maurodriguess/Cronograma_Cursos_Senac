import 'package:sqflite/sqflite.dart';
import '../../core/database_helper.dart';
import '../models/calendarios_model.dart';

class CalendariosRepository {
  Future<void> insertCalendario(Calendarios calendario) async {
    final db = await DatabaseHelper.initDb();
    await db.insert(
      'Calendarios',
      calendario.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Calendarios>> getCalendarios() async {
    final db = await DatabaseHelper.initDb();
    final List<Map<String, Object?>> calendarioMaps = await db.query('Calendarios');
    return calendarioMaps.map((map) {
      return Calendarios(
        idCalendarios: map['idCalendarios'] as int?,
        ano: map['ano'] as int,
        mes: map['mes'] as String,
        dataInicio: map['data_inicio'] as String,
        dataFim: map['data_fim'] as String,
        idturma: map['idturma'] as int,
      );
    }).toList();
  }

  Future<void> updateCalendario(Calendarios calendario) async {
    final db = await DatabaseHelper.initDb();
    await db.update(
      'Calendarios',
      calendario.toMap(),
      where: 'idCalendarios = ?',
      whereArgs: [calendario.idCalendarios],
    );
  }

  Future<void> deleteCalendario(int id) async {
    final db = await DatabaseHelper.initDb();
    await db.delete(
      'Calendarios',
      where: 'idCalendarios = ?',
      whereArgs: [id],
    );
  }
}