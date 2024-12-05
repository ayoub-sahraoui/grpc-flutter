import 'package:flutter/foundation.dart';
import '../generated/compte.pb.dart';
import '../repositories/compte_repository.dart';

class CompteProvider with ChangeNotifier {
  final _repository = CompteRepository();

  List<Compte> _comptes = [];
  SoldeStats? _stats;
  bool _loading = false;
  String? _error;
  List<Compte> _filteredComptes = [];

  List<Compte> get comptes => _comptes;
  List<Compte> get filteredComptes => _filteredComptes;
  SoldeStats? get stats => _stats;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadComptes() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      _comptes = await _repository.getAllComptes();
      _stats = await _repository.getTotalSolde();
      _filteredComptes = _comptes; // Initialize filtered list with all comptes
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> saveCompte(
      double solde, String dateCreation, TypeCompte type) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      await _repository.saveCompte(
        solde: solde,
        dateCreation: dateCreation,
        type: type,
      );

      await loadComptes(); // Refresh the list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteCompte(String id) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final success = await _repository.deleteCompte(id);
      if (success) {
        await loadComptes(); // Refresh the list after successful deletion
      } else {
        _error = 'Failed to delete compte';
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> filterComptesByType(TypeCompte type) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      _filteredComptes = await _repository.findComptesByType(type);
    } catch (e) {
      _error = e.toString();
      _filteredComptes = []; // Reset filtered list on error
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Reset filters and show all comptes
  void resetFilters() {
    _filteredComptes = _comptes;
    notifyListeners();
  }

  // Get a specific compte by ID
  Future<Compte?> getCompteById(String id) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      return await _repository.getCompteById(id);
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
