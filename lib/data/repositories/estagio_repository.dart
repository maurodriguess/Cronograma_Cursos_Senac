import 'package:sqflite/sqflite.dart';
import '../../core/database_helper.dart';
import '../models/estagio_model.dart';

class EstagioRepository {
  Future<void> insertEstagio(Estagio estagio) async {
    final db = await DatabaseHelper.initDb();
    await db.insert(
      'Estagio',
      estagio.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Estagio>> getEstagios() async {
    final db = await DatabaseHelper.initDb();
    final List<Map<String, Object?>> estagioMaps = await db.query('Estagio');
    return estagioMaps.map((map) {
      return Estagio(
        idEstagio: map['idEstagio'] as int?,
        idturma: map['idturma'] as int,
        descricao: map['descricao'] as String,
        duracao: map['duracao'] as int,
      );
    }).toList();
  }

  Future<void> updateEstagio(Estagio estagio) async {
    final db = await DatabaseHelper.initDb();
    await db.update(
      'Estagio',
      estagio.toMap(),
      where: 'idEstagio = ?',
      whereArgs: [estagio.idEstagio],
    );
  }

  Future<void> deleteEstagio(int id) async {
    final db = await DatabaseHelper.initDb();
    await db.delete(
      'Estagio',
      where: 'idEstagio = ?',
      whereArgs: [id],
    );
  }
}