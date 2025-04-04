import '../../data/models/calendarios_model.dart';
import '../../data/repositories/calendarios_repository.dart';

class CalendariosViewModel {
  final CalendariosRepository repository;

  CalendariosViewModel(this.repository);

  Future<void> addCalendario(Calendarios calendario) async {
    try {
      await repository.insertCalendario(calendario);
    } catch (e) {
      print('Erro ao adicionar calendário: $e');
      rethrow;
    }
  }

  Future<List<Calendarios>> getCalendarios() async {
    try {
      return await repository.getCalendarios();
    } catch (e) {
      print('Erro ao obter calendários: $e');
      return [];
    }
  }

  Future<void> updateCalendario(Calendarios calendario) async {
    try {
      await repository.updateCalendario(calendario);
    } catch (e) {
      print('Erro ao atualizar calendário: $e');
      rethrow;
    }
  }

  Future<void> deleteCalendario(int id) async {
    try {
      await repository.deleteCalendario(id);
    } catch (e) {
      print('Erro ao deletar calendário: $e');
      rethrow;
    }
  }

  // Método adicional para buscar calendários por turma
  Future<List<Calendarios>> getCalendariosPorTurma(int idTurma) async {
    try {
      return await repository.getCalendariosPorTurma(idTurma);
    } catch (e) {
      print('Erro ao buscar calendários por turma: $e');
      return [];
    }
  }
}
