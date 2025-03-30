import 'package:sqflite/sqflite.dart';
import '../../core/database_helper.dart';
import '../models/instrutores_model.dart';

class InstrutoresRepository {
  // Insert an instructor and return the new ID
  Future<int> insertInstrutor(Instrutores instrutor) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(
      'Instrutores',
      instrutor.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all instructors with error handling
  Future<List<Instrutores>> getInstrutores() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> instrutorMaps = 
          await db.query('Instrutores');
      return instrutorMaps.map(Instrutores.fromMap).toList();
    } catch (e) {
      throw Exception('Failed to load instructors: $e');
    }
  }

  // Update an instructor and return number of affected rows
  Future<int> updateInstrutor(Instrutores instrutor) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'Instrutores',
      instrutor.toMap(),
      where: 'idInstrutores = ?',
      whereArgs: [instrutor.idInstrutores],
    );
  }

  // Delete an instructor and return number of affected rows
  Future<int> deleteInstrutor(int id) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'Instrutores',
      where: 'idInstrutores = ?',
      whereArgs: [id],
    );
  }

  // Get instructor ID by name (corrected and optimized)
  Future<int?> getInstrutorIdByNome(String nomeInstrutor) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> result = await db.query(
      'Instrutores',  // Fixed table name (was 'Instrutor')
      columns: ['idInstrutores'],  // Only select needed column
      where: 'nome_instrutor = ?',
      whereArgs: [nomeInstrutor],
      limit: 1,  // Only need first match
    );
    
    return result.isNotEmpty ? result.first['idInstrutores'] as int? : null;
  }

  // Check if instructor exists by name
  Future<bool> instrutorExists(String nomeInstrutor) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT 1 FROM Instrutores WHERE nome_instrutor = ? LIMIT 1',
      [nomeInstrutor],
    );
    return result.isNotEmpty;
  }

  // Get instructors by specialization
  Future<List<Instrutores>> getInstrutoresByEspecializacao(String especializacao) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> results = await db.query(
      'Instrutores',
      where: 'especializacao = ?',
      whereArgs: [especializacao],
    );
    return results.map(Instrutores.fromMap).toList();
  }
}