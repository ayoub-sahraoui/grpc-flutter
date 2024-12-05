import 'package:grpc/grpc.dart';

import '../generated/compte.pb.dart';
import '../generated/compte.pbgrpc.dart';
import '../services/grpc_client.dart';

class CompteRepository {
  Future<List<Compte>> getAllComptes() async {
    try {
      final client = await GrpcClient.client;
      final response = await client.allComptes(GetAllComptesRequest());
      return response.comptes;
    } on GrpcError catch (e) {
      print('gRPC error: ${e.code} - ${e.message}');
      if (e.code == StatusCode.unavailable) {
        throw Exception(
            'Server is unavailable. Please check your connection and try again.');
      }
      rethrow;
    } catch (e) {
      print('Error: $e');
      throw Exception(
          'Failed to connect to the server. Please try again later.');
    }
  }

  Future<Compte> getCompteById(String id) async {
    final client = await GrpcClient.client;
    final response = await client.compteById(
      GetCompteByIdRequest()..id = id,
    );
    return response.compte;
  }

  Future<SoldeStats> getTotalSolde() async {
    final client = await GrpcClient.client;
    final response = await client.totalSolde(GetTotalSoldeRequest());
    return response.stats;
  }

  Future<Compte> saveCompte({
    required double solde,
    required String dateCreation,
    required TypeCompte type,
  }) async {
    final client = await GrpcClient.client;
    final request = SaveCompteRequest()
      ..compte = (CompteRequest()
        ..solde = solde
        ..dateCreation = dateCreation
        ..type = type);

    final response = await client.saveCompte(request);
    return response.compte;
  }

  // Add delete compte method
  Future<bool> deleteCompte(String id) async {
    try {
      final client = await GrpcClient.client;
      final response = await client.deleteCompte(
        DeleteCompteRequest()..id = id,
      );
      return response.success;
    } on GrpcError catch (e) {
      print('gRPC error: ${e.code} - ${e.message}');
      if (e.code == StatusCode.unavailable) {
        throw Exception(
            'Server is unavailable. Please check your connection and try again.');
      }
      rethrow;
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to delete compte. Please try again later.');
    }
  }

  // Add find comptes by type method
  Future<List<Compte>> findComptesByType(TypeCompte type) async {
    try {
      final client = await GrpcClient.client;
      final response = await client.findComptesByType(
        FindComptesByTypeRequest()..type = type,
      );
      return response.comptes;
    } on GrpcError catch (e) {
      print('gRPC error: ${e.code} - ${e.message}');
      if (e.code == StatusCode.unavailable) {
        throw Exception(
            'Server is unavailable. Please check your connection and try again.');
      }
      rethrow;
    } catch (e) {
      print('Error: $e');
      throw Exception(
          'Failed to fetch comptes by type. Please try again later.');
    }
  }
}
