import 'package:sqflite/sqflite.dart';
import '../../core/database_helper.dart';
import '../models/unidades_curriculares_model.dart';

class UnidadesCurricularesRepository {
  Future<void> insertUnidadeCurricular(UnidadesCurriculares unidadeCurricular) async {
    final db = await DatabaseHelper.initDb();
    await db.insert(
      'Unidades_Curriculares',
      unidadeCurricular.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<UnidadesCurriculares>> getUnidadesCurriculares() async {
    final db = await DatabaseHelper.initDb();
    final List<Map<String, Object?>> unidadeCurricularMaps = await db.query('Unidades_Curriculares');
    return unidadeCurricularMaps.map((map) {
      return UnidadesCurriculares(
        idUc: map['idUc'] as int?,
        nomeUc: map['nome_uc'] as String,
        cargahoraria: map['cargahoraria'] as int,
        idcurso: map['idcurso'] as int,
      );
    }).toList();
  }

  Future<void> updateUnidadeCurricular(UnidadesCurriculares unidadeCurricular) async {
    final db = await DatabaseHelper.initDb();
    await db.update(
      'Unidades_Curriculares',
      unidadeCurricular.toMap(),
      where: 'idUc = ?',
      whereArgs: [unidadeCurricular.idUc],
    );
  }

  Future<void> deleteUnidadeCurricular(int id) async {
    final db = await DatabaseHelper.initDb();
    await db.delete(
      'Unidades_Curriculares',
      where: 'idUc = ?',
      whereArgs: [id],
    );
  }
}