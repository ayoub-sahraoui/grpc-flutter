import 'package:grpc/grpc.dart';
import '../generated/compte.pbgrpc.dart';

class GrpcClient {
  static CompteServiceClient? _client;
  static ClientChannel? _channel;

  static Future<CompteServiceClient> get client async {
    if (_client != null) return _client!;

    _channel = ClientChannel(
      '192.168.1.216',
      port: 5555,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
        connectTimeout: Duration(seconds: 5),
        idleTimeout: Duration(minutes: 1),
      ),
    );

    _client = CompteServiceClient(_channel!);
    return _client!;
  }

  static void dispose() {
    _channel?.shutdown();
    _client = null;
    _channel = null;
  }
}
