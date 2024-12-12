import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


class DatabaseHelper {
  static Future<Database> initDb() async {
    return openDatabase(
      join(await getDatabasesPath(), 'education_database.db'),
      onCreate: (db, version) async {
        // Criação das tabelas conforme o diagrama
        await db.execute('''
          CREATE TABLE Estagio (
            idEstagio INTEGER PRIMARY KEY,
            idturma INTEGER,
            descricao TEXT,
            duracao INTEGER,
            FOREIGN KEY (idturma) REFERENCES Turma(idTurma)
          );
        ''');

        await db.execute('''
          CREATE TABLE Turno (
            idTurno INTEGER PRIMARY KEY,
            turno TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE Calendarios (
            idCalendarios INTEGER PRIMARY KEY,
            ano INTEGER,
            mes TEXT,
            data_inicio DATE,
            data_fim DATE,
            idturma INTEGER,
            FOREIGN KEY (idturma) REFERENCES Turma(idTurma)
          );
        ''');

        await db.execute('''
          CREATE TABLE Cursos (
            idCursos INTEGER PRIMARY KEY,
            nome_curso TEXT,
            cargahoraria INTEGER
          );
        ''');

        await db.execute('''
          CREATE TABLE Unidades_Curriculares (
            idUc INTEGER PRIMARY KEY,
            nome_uc TEXT,
            cargahoraria INTEGER,
            idcurso INTEGER,
            FOREIGN KEY (idcurso) REFERENCES Cursos(idCursos)
          );
        ''');

        await db.execute('''
          CREATE TABLE Instrutores (
            idInstrutores INTEGER PRIMARY KEY,
            nome_instrutor TEXT
          );
        ''');

        await db.execute('''
          CREATE TABLE Turma (
            idTurma INTEGER PRIMARY KEY,
            turma TEXT,
            idcurso INTEGER,
            idturno INTEGER,
            idinstrutor INTEGER,
            FOREIGN KEY (idcurso) REFERENCES Cursos(idCursos),
            FOREIGN KEY (idturno) REFERENCES Turno(idTurno),
            FOREIGN KEY (idinstrutor) REFERENCES Instrutores(idInstrutores)
          );
        ''');
      },
      version: 1,
    );
  }
}