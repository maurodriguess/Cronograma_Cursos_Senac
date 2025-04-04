import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static const _databaseName = 'education_database.db';
  static const _databaseVersion = 4;

  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static String formatarParaBanco(DateTime data) =>
      DateFormat('yyyy-MM-dd').format(data);
  static String formatarParaBrasil(DateTime data) =>
      DateFormat('dd/MM/yyyy').format(data);
  static DateTime? parseDataBrasileira(String dataStr) =>
      DateFormat('dd/MM/yyyy').parse(dataStr);

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Cursos (
        idCurso INTEGER PRIMARY KEY AUTOINCREMENT,
        nome_curso TEXT NOT NULL,
        cargahoraria INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE Turno (
        idTurno INTEGER PRIMARY KEY AUTOINCREMENT,
        turno TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE Instrutores (
        idInstrutor INTEGER PRIMARY KEY AUTOINCREMENT,
        nome_instrutor TEXT NOT NULL,
        especializacao TEXT,
        email TEXT,
        telefone TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE Unidades_Curriculares (
        idUc INTEGER PRIMARY KEY AUTOINCREMENT,
        nome_uc TEXT NOT NULL,
        cargahoraria INTEGER,
        idCurso INTEGER,
        FOREIGN KEY (idCurso) REFERENCES Cursos(idCurso)
      );
    ''');

    await db.execute('''
      CREATE TABLE Turma (
        idTurma INTEGER PRIMARY KEY AUTOINCREMENT,
        turma TEXT NOT NULL,
        idCurso INTEGER NOT NULL,
        idInstrutor INTEGER NOT NULL,
        idTurno INTEGER NOT NULL,
        FOREIGN KEY (idCurso) REFERENCES Cursos(idCurso),
        FOREIGN KEY (idInstrutor) REFERENCES Instrutores(idInstrutor),
        FOREIGN KEY (idTurno) REFERENCES Turno(idTurno)
      );
    ''');

    await db.execute('''
      CREATE TABLE Aulas (
        idAula INTEGER PRIMARY KEY AUTOINCREMENT,
        idUc INTEGER NOT NULL,
        idTurma INTEGER NOT NULL,
        data TEXT NOT NULL,
        horarioInicio TEXT NOT NULL,
        horarioFim TEXT NOT NULL,
        status TEXT DEFAULT 'agendada',
        observacoes TEXT,
        dataCriacao TEXT NOT NULL,
        dataAtualizacao TEXT NOT NULL,
        FOREIGN KEY (idUc) REFERENCES Unidades_Curriculares(idUc),
        FOREIGN KEY (idTurma) REFERENCES Turma(idTurma)
      );
    ''');

    await db.execute('CREATE INDEX idx_aulas_data ON Aulas(data);');
    await db.execute('CREATE INDEX idx_aulas_uc ON Aulas(idUc);');

    await _insertInitialData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logMigration(oldVersion, newVersion);

    if (oldVersion < 2) {
      await _createV2Tables(db);
    }

    if (oldVersion < 3) {
      await _upgradeToV3(db);
    }

    if (oldVersion < 4) {
      await _upgradeToV4(db);
    }
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Aulas (
        idAula INTEGER PRIMARY KEY AUTOINCREMENT,
        idUc INTEGER NOT NULL,
        idTurma INTEGER NOT NULL,
        data TEXT NOT NULL,
        horario TEXT NOT NULL,
        status TEXT DEFAULT 'agendada',
        observacoes TEXT,
        FOREIGN KEY (idUc) REFERENCES Unidades_Curriculares(idUc),
        FOREIGN KEY (idTurma) REFERENCES Turma(idTurma)
      );
    ''');
  }

  Future<void> _upgradeToV3(Database db) async {
    try {
      await db.execute(
          'ALTER TABLE Unidades_Curriculares ADD COLUMN cargahoraria INTEGER DEFAULT 0');
    } catch (e) {
      debugPrint('Erro ao atualizar para v3: $e');
    }
  }

  Future<void> _upgradeToV4(Database db) async {
    try {
      await db.execute('CREATE TABLE Aulas_backup AS SELECT * FROM Aulas');
      await db.execute('ALTER TABLE Aulas RENAME TO Aulas_old');

      await db.execute('''
        CREATE TABLE Aulas (
          idAula INTEGER PRIMARY KEY AUTOINCREMENT,
          idUc INTEGER NOT NULL,
          idTurma INTEGER NOT NULL,
          data TEXT NOT NULL,
          horarioInicio TEXT NOT NULL,
          horarioFim TEXT NOT NULL,
          status TEXT DEFAULT 'agendada',
          observacoes TEXT,
          dataCriacao TEXT NOT NULL,
          dataAtualizacao TEXT NOT NULL,
          FOREIGN KEY (idUc) REFERENCES Unidades_Curriculares(idUc),
          FOREIGN KEY (idTurma) REFERENCES Turma(idTurma)
        );
      ''');

      await db.execute('''
        INSERT INTO Aulas (
          idAula, idUc, idTurma, data, 
          horarioInicio, horarioFim, status, observacoes,
          dataCriacao, dataAtualizacao
        )
        SELECT 
          idAula, idUc, idTurma, data,
          substr(horario, 1, 5) AS horarioInicio,
          CASE 
            WHEN horario LIKE '%-%' THEN substr(horario, 7, 5)
            ELSE substr(horario, 1, 5)
          END AS horarioFim,
          status, observacoes,
          datetime('now') AS dataCriacao,
          datetime('now') AS dataAtualizacao
        FROM Aulas_old
      ''');

      await db.execute('DROP TABLE Aulas_old');
      await db.execute('DROP TABLE Aulas_backup');
    } catch (e) {
      debugPrint('Erro na migração v4: $e');
      await _alternativeV4Upgrade(db);
    }
  }

  Future<void> _alternativeV4Upgrade(Database db) async {
    try {
      await db.execute('ALTER TABLE Aulas ADD COLUMN horarioInicio TEXT');
      await db.execute('ALTER TABLE Aulas ADD COLUMN horarioFim TEXT');
      await db.execute('ALTER TABLE Aulas ADD COLUMN dataCriacao TEXT');
      await db.execute('ALTER TABLE Aulas ADD COLUMN dataAtualizacao TEXT');

      await db.execute('''
        UPDATE Aulas SET 
          horarioInicio = substr(horario, 1, 5),
          horarioFim = CASE 
            WHEN horario LIKE '%-%' THEN substr(horario, 7, 5)
            ELSE substr(horario, 1, 5)
          END,
          dataCriacao = datetime('now'),
          dataAtualizacao = datetime('now')
      ''');

      await db.execute('ALTER TABLE Aulas DROP COLUMN horario');
    } catch (e) {
      debugPrint('Erro na migração alternativa v4: $e');
      await _recreateV4Tables(db);
    }
  }

  Future<void> _recreateV4Tables(Database db) async {
    await db.execute('DROP TABLE IF EXISTS Aulas');
    await db.execute('''
      CREATE TABLE Aulas (
        idAula INTEGER PRIMARY KEY AUTOINCREMENT,
        idUc INTEGER NOT NULL,
        idTurma INTEGER NOT NULL,
        data TEXT NOT NULL,
        horarioInicio TEXT NOT NULL,
        horarioFim TEXT NOT NULL,
        status TEXT DEFAULT 'agendada',
        observacoes TEXT,
        dataCriacao TEXT NOT NULL,
        dataAtualizacao TEXT NOT NULL,
        FOREIGN KEY (idUc) REFERENCES Unidades_Curriculares(idUc),
        FOREIGN KEY (idTurma) REFERENCES Turma(idTurma)
      );
    ''');
  }

  void _logMigration(int oldVersion, int newVersion) {
    debugPrint(
        'Migrando banco de dados da versão $oldVersion para $newVersion');
  }

  Future<void> _insertInitialData(Database db) async {
    await db.insert('Turno', {'turno': 'Matutino'});
    await db.insert('Turno', {'turno': 'Vespertino'});
    await db.insert('Turno', {'turno': 'Noturno'});

    await db.insert('Cursos',
        {'nome_curso': 'Técnico em Informática', 'cargahoraria': 1200});
    await db.insert('Cursos',
        {'nome_curso': 'Técnico em Administração', 'cargahoraria': 1000});

    await db.insert('Instrutores', {
      'nome_instrutor': 'Prof. Silva',
      'especializacao': 'Programação',
      'email': 'silva@escola.com',
      'telefone': '(11) 99999-9999'
    });
  }

  Future<int> insertAula(Aula aula) async {
    try {
      final db = await database;
      return await db.insert('Aulas', aula.toMap());
    } catch (e) {
      debugPrint('Erro ao inserir aula: $e');
      rethrow;
    }
  }

  Future<int> updateAula(Aula aula) async {
    try {
      final db = await database;
      return await db.update(
        'Aulas',
        aula.copyWith(dataAtualizacao: DateTime.now()).toMap(),
        where: 'idAula = ?',
        whereArgs: [aula.idAula],
      );
    } catch (e) {
      debugPrint('Erro ao atualizar aula: $e');
      rethrow;
    }
  }

  Future<int> deleteAula(int idAula) async {
    try {
      final db = await database;
      return await db.delete(
        'Aulas',
        where: 'idAula = ?',
        whereArgs: [idAula],
      );
    } catch (e) {
      debugPrint('Erro ao deletar aula: $e');
      rethrow;
    }
  }

  Future<List<Aula>> getAulas() async {
    try {
      final db = await database;
      final maps = await db.query('Aulas');
      return maps.map((map) => Aula.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar aulas: $e');
      return [];
    }
  }

  Future<List<Aula>> getAulasComDetalhes() async {
    try {
      final db = await database;
      final maps = await db.rawQuery('''
        SELECT Aulas.*, 
               Unidades_Curriculares.nome_uc,
               Turma.turma,
               Instrutores.nome_instrutor
        FROM Aulas
        JOIN Unidades_Curriculares ON Aulas.idUc = Unidades_Curriculares.idUc
        JOIN Turma ON Aulas.idTurma = Turma.idTurma
        JOIN Instrutores ON Turma.idInstrutor = Instrutores.idInstrutor
        ORDER BY Aulas.data, Aulas.horarioInicio
      ''');
      return maps.map((map) => Aula.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar aulas com detalhes: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTurmas() async {
    try {
      final db = await database;
      return await db.query('Turma');
    } catch (e) {
      debugPrint('Erro ao buscar turmas: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUnidadesCurriculares() async {
    try {
      final db = await database;
      return await db.query('Unidades_Curriculares');
    } catch (e) {
      debugPrint('Erro ao buscar UCs: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCursos() async {
    try {
      final db = await database;
      return await db.query('Cursos');
    } catch (e) {
      debugPrint('Erro ao buscar cursos: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getInstrutores() async {
    try {
      final db = await database;
      return await db.query('Instrutores');
    } catch (e) {
      debugPrint('Erro ao buscar instrutores: $e');
      return [];
    }
  }
}

class Aula {
  final int? idAula;
  final int idUc;
  final int idTurma;
  final DateTime data;
  final TimeOfDay horarioInicio;
  final TimeOfDay horarioFim;
  final String status;
  final String? observacoes;
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;

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
        dataAtualizacao = dataAtualizacao ?? DateTime.now() {
    _validarHorarios();
  }

  void _validarHorarios() {
    if (horarioFim.hour < horarioInicio.hour ||
        (horarioFim.hour == horarioInicio.hour &&
            horarioFim.minute <= horarioInicio.minute)) {
      throw ArgumentError('Horário de fim deve ser após horário de início');
    }
  }

  int get duracaoMinutos =>
      (horarioFim.hour * 60 + horarioFim.minute) -
      (horarioInicio.hour * 60 + horarioInicio.minute);

  bool get foiRealizada {
    final aulaDateTime = DateTime(
        data.year, data.month, data.day, horarioFim.hour, horarioFim.minute);
    return aulaDateTime.isBefore(DateTime.now());
  }

  bool temConflito(Aula outra) {
    if (data != outra.data) return false;

    final inicioEstaDentro =
        _timeToMinutes(horarioInicio) >= _timeToMinutes(outra.horarioInicio) &&
            _timeToMinutes(horarioInicio) < _timeToMinutes(outra.horarioFim);

    final fimEstaDentro =
        _timeToMinutes(horarioFim) > _timeToMinutes(outra.horarioInicio) &&
            _timeToMinutes(horarioFim) <= _timeToMinutes(outra.horarioFim);

    return inicioEstaDentro || fimEstaDentro;
  }

  int _timeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  factory Aula.fromMap(Map<String, dynamic> map) {
    return Aula(
      idAula: map['idAula'] as int?,
      idUc: map['idUc'] as int,
      idTurma: map['idTurma'] as int,
      data: DateTime.parse(map['data'] as String),
      horarioInicio:
          TimeOfDayExtension.fromString(map['horarioInicio'] as String),
      horarioFim: TimeOfDayExtension.fromString(map['horarioFim'] as String),
      status: map['status'] as String,
      observacoes: map['observacoes'] as String?,
      dataCriacao: DateTime.parse(map['dataCriacao'] as String),
      dataAtualizacao: DateTime.parse(map['dataAtualizacao'] as String),
    );
  }

  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() {
    return {
      'idAula': idAula,
      'idUc': idUc,
      'idTurma': idTurma,
      'data': data.toIso8601String(),
      'horarioInicio': horarioInicio.to24Hours(),
      'horarioFim': horarioFim.to24Hours(),
      'status': status,
      'observacoes': observacoes,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataAtualizacao': dataAtualizacao.toIso8601String(),
    };
  }

  Aula copyWith({
    int? idAula,
    int? idUc,
    int? idTurma,
    DateTime? data,
    TimeOfDay? horarioInicio,
    TimeOfDay? horarioFim,
    String? status,
    String? observacoes,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
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
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Aula(idAula: $idAula, UC: $idUc, Turma: $idTurma, '
        'Data: ${data.day}/${data.month}/${data.year}, '
        'Horário: ${horarioInicio.to24Hours()}-${horarioFim.to24Hours()}, '
        'Status: $status)';
  }
}

extension TimeOfDayExtension on TimeOfDay {
  String format(BuildContext context, {bool alwaysUse24HourFormat = true}) {
    return MaterialLocalizations.of(context)
        .formatTimeOfDay(this, alwaysUse24HourFormat: alwaysUse24HourFormat);
  }

  String to24Hours() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  bool isAfter(TimeOfDay other) {
    return hour > other.hour || (hour == other.hour && minute > other.minute);
  }

  bool isBefore(TimeOfDay other) {
    return hour < other.hour || (hour == other.hour && minute < other.minute);
  }

  static TimeOfDay fromString(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}
