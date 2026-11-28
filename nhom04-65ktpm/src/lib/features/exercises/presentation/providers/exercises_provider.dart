import 'package:flutter/foundation.dart';

import '../../data/repositories/question_bank_repository.dart';
import '../../domain/exercise_catalog.dart';

/// Nạp ngân hàng đề một lần và cung cấp danh mục bài tập cho các màn M3.
class ExercisesProvider extends ChangeNotifier {
  ExercisesProvider({QuestionBankRepository? repository})
    : _repository = repository ?? QuestionBankRepository();

  final QuestionBankRepository _repository;

  ExerciseCatalog? _catalog;
  bool _isLoading = false;
  String? _error;

  ExerciseCatalog? get catalog => _catalog;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load({bool force = false}) async {
    if (_isLoading || (_catalog != null && !force)) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _catalog = ExerciseCatalog(await _repository.loadSets());
    } catch (e) {
      debugPrint('M3 load question bank failed: $e');
      _error = 'Không tải được ngân hàng đề. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
