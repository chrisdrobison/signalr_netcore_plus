import 'dart:async';
import 'dart:typed_data';

import 'connection.dart';
import 'hub_protocol.dart';

class MessageBuffer {
  final HubProtocol protocol;
  final Connection connection;
  final int bufferSize;

  List<BufferedItem> _messages = <BufferedItem>[];
  int _totalMessageCount = 0;
  bool _waitForSequenceMessage = false;

  int _nextReceivingSequenceId = 1;
  int _latestReceivedSequenceId = 0;
  int _bufferedByteCount = 0;
  bool _reconnectInProgress = false;

  Timer? ackTimer;

  MessageBuffer({
    required this.protocol,
    required this.connection,
    this.bufferSize = 100000,
  });

  Future<void> send(HubMessage message) async {
    final serializedMessage = protocol.writeMessage(message);
    var completer = Completer<void>()..complete();

    if (message is HubInvocationMessage) {
      _totalMessageCount++;

      _bufferedByteCount +=
          (serializedMessage is Uint8List) ? serializedMessage.lengthInBytes : (serializedMessage as String).length;

      if (_bufferedByteCount >= bufferSize) {
        completer = Completer<void>();
      }
      _messages.add(BufferedItem(message: serializedMessage, id: _totalMessageCount, completer: completer));
    }

    try {
      if (!_reconnectInProgress) {
        await connection.send(serializedMessage);
      }
    } catch (e) {
      disconnected();
    }

    await completer.future;
  }

  void ack(AckMessage ackMessage) {
    var newestAckedMessage = -1;

    for (var i = 0; i < _messages.length; i++) {
      var element = _messages[i];
      if (element.id <= ackMessage.sequenceId) {
        newestAckedMessage = i;
        if (element.message is Uint8List) {
          _bufferedByteCount -= (element.message as Uint8List).lengthInBytes;
        } else {
          _bufferedByteCount -= (element.message as String).length;
        }
        element.completer.complete();
      } else if (_bufferedByteCount < bufferSize) {
        element.completer.complete();
      } else {
        break;
      }
    }

    if (newestAckedMessage != -1) {
      _messages = _messages.sublist(newestAckedMessage + 1);
    }
  }

  bool shouldProcessMessage(HubMessage message) {
    if (_waitForSequenceMessage) {
      if (message.type == MessageType.sequence) {
        return false;
      } else {
        _waitForSequenceMessage = false;
        return true;
      }
    }

    if (message is HubInvocationMessage) {
      return true;
    }

    final currentId = _nextReceivingSequenceId;
    _nextReceivingSequenceId++;
    if (currentId <= _latestReceivedSequenceId) {
      if (currentId == _latestReceivedSequenceId) {
        // Should only hit this if we just reconnected and the server is sending
        // Messages it has buffered, which would mean it hasn't seen an Ack for these messages
        _ackTimer();
      }
      // Ignore, this is a duplicate message
      return false;
    }

    _latestReceivedSequenceId = currentId;

    // Only start the timer for sending an Ack message when we have a message to ack. This also conveniently solves
    // timer throttling by not having a recursive timer, and by starting the timer via a network call (recv)
    _ackTimer();
    return true;
  }

  void resetSequence(SequenceMessage message) {
    if (message.sequenceId > _nextReceivingSequenceId) {
      connection.stop(Exception('Sequence ID greater than amount of messages we\'ve received.'));
      return;
    }

    _nextReceivingSequenceId = message.sequenceId;
  }

  void disconnected() {
    _reconnectInProgress = true;
    _waitForSequenceMessage = true;
  }

  Future<void> resend() async {
    final sequenceId = _messages.isEmpty ? _messages.first.id : _totalMessageCount + 1;
    await connection.send(protocol.writeMessage(SequenceMessage(sequenceId: sequenceId)));

    final messages = _messages;
    for (var element in messages) {
      await connection.send(element.message);
    }

    _reconnectInProgress = false;
  }

  void dispose(Exception? error) {
    error ??= Exception('Unable to reconnect to server.');

    for (var element in _messages) {
      element.completer.completeError(error);
    }
  }

  void _ackTimer() {
    if (ackTimer != null) {
      return;
    }

    ackTimer = Timer(Duration(seconds: 1), () async {
      try {
        if (!_reconnectInProgress) {
          await connection.send(protocol.writeMessage(AckMessage(sequenceId: _latestReceivedSequenceId)));
        }
      } catch (e) {
        // Ignore
      }
      ackTimer = null;
    });
  }
}

class BufferedItem {
  final Object message;
  final int id;
  final Completer<void> completer;

  BufferedItem({
    required this.message,
    required this.id,
    required this.completer,
  });
}
