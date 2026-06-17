import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketClient {
  final IO.Socket socket;

  SocketClient(String url, {String? token})
      : socket = IO.io(
            url,
            IO.OptionBuilder()
                .setTransports(['websocket'])
                .enableAutoConnect()
                .setQuery({'token': token})
                .build());

  void connect() {
    socket.connect();
  }

  void disconnect() {
    socket.disconnect();
  }

  void emit(String event, dynamic data) {
    socket.emit(event, data);
  }

  void on(String event, Function(dynamic) handler) {
    socket.on(event, handler);
  }

  void off(String event) {
    socket.off(event);
  }
}
