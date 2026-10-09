// Dart Native Messaging host
// guest271314 10-4-2026
//
// https://github.com/dart-lang/sdk/issues/64476#issuecomment-6077106598
//
// dart compile exe nm_dart.dart -S debug_dart.txt -o nm_dart
// WASM doesn't work right now... No WASI
// dart compile wasm nm_dart.dart -S debug_dart_wasm.txt -o nm_dart.wasm

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

const int COMMA = 44;
const int OPEN_BRACKET = 91;
const int CLOSE_BRACKET = 93;
const int CHUNK_SIZE = 1024 * 1024; // 1 MiB

const int STDIN_FILENO = 0;
const int STDOUT_FILENO = 1;

final DynamicLibrary _libc = DynamicLibrary.process();

// The Windows CRT only exports the underscore-prefixed POSIX names.
String _posix(String name) => _libc.providesSymbol(name) ? name : '_$name';

// ssize_t read(int, void*, size_t) on POSIX vs. int _read(int, void*,
// unsigned) on Windows: an Int32 result and a Size count work for both since
// counts stay far below 2^31. Not leaf calls because they may block.
typedef _IoNative = Int32 Function(Int32, Pointer<Uint8>, Size);
typedef _IoDart = int Function(int, Pointer<Uint8>, int);
final _read = _libc.lookupFunction<_IoNative, _IoDart>(_posix('read'));
final _write = _libc.lookupFunction<_IoNative, _IoDart>(_posix('write'));

@Native<Pointer<Uint8> Function(Size)>(symbol: 'malloc', isLeaf: true)
external Pointer<Uint8> _malloc(int size);

@Native<Void Function(Pointer<Uint8>)>(symbol: 'free', isLeaf: true)
external void _free(Pointer<Uint8> ptr);

// CRTs with text-mode descriptors (Windows) would otherwise translate CR/LF
// and treat Ctrl-Z as EOF in the binary length headers.
void _setBinaryMode() {
  if (!_libc.providesSymbol('_setmode')) return;
  final setmode = _libc.lookupFunction<Int32 Function(Int32, Int32),
      int Function(int, int)>('_setmode');
  const O_BINARY = 0x8000;
  setmode(STDIN_FILENO, O_BINARY);
  setmode(STDOUT_FILENO, O_BINARY);
}

// Messages are read into a single reusable native buffer laid out as
// [4-byte length][message][1 spare byte for a closing bracket], and echoed
// back from it without copying.
void main() {
  _setBinaryMode();
  var capacity = 4 + CHUNK_SIZE + 1;
  var buffer = _allocate(capacity);
  try {
    while (readFully(buffer, 0, 4)) {
      final length = buffer.cast<Uint32>().value;
      if (capacity < 4 + length + 1) {
        capacity = 4 + length + 1;
        final grown = _allocate(capacity);
        grown.cast<Uint32>().value = length;
        _free(buffer);
        buffer = grown;
      }
      if (!readFully(buffer, 4, 4 + length)) break;
      sendMessage(buffer, length);
    }
  } catch (e) {
    // Suppress safely to align with original script fallback design
  }
  exit(0);
}

Pointer<Uint8> _allocate(int size) {
  final ptr = _malloc(size);
  if (ptr == nullptr) throw OutOfMemoryError();
  return ptr;
}

// Reading at most half of the default 64 KiB pipe capacity per call keeps
// the pipe from being drained completely while the writer refills it, so the
// reader rarely has to sleep (and be woken up) on an empty pipe.
const int MAX_READ = 32 * 1024;

bool readFully(Pointer<Uint8> buffer, int start, int end) {
  while (start < end) {
    final count = end - start < MAX_READ ? end - start : MAX_READ;
    final n = _read(STDIN_FILENO, buffer + start, count);
    if (n <= 0) return false;
    start += n;
  }
  return true;
}

void writeFully(Pointer<Uint8> buffer, int start, int end) {
  while (start < end) {
    final n = _write(STDOUT_FILENO, buffer + start, end - start);
    if (n <= 0) throw const StdoutException('write failed');
    start += n;
  }
}

// Echoes the message stored at buffer[4, 4 + length), whose length header is
// already in buffer[0, 4). Large messages are split into JSON array chunks of
// about CHUNK_SIZE that are framed in place: each chunk's header overwrites
// the tail of the previous (already written) chunk.
void sendMessage(Pointer<Uint8> buffer, int length) {
  if (length <= CHUNK_SIZE) {
    writeFully(buffer, 0, 4 + length);
    return;
  }

  final bytes = buffer.asTypedList(4 + length + 1);
  final view = ByteData.sublistView(bytes);
  int index = 0;
  while (index < length) {
    final searchStart = index + CHUNK_SIZE - 8;
    int splitIndex = length;
    if (searchStart < length) {
      final comma = bytes.indexOf(COMMA, 4 + searchStart);
      if (comma >= 0 && comma < 4 + length) splitIndex = comma - 4;
    }

    final chunkStart = 4 + index;
    final chunkEnd = 4 + splitIndex;
    if (chunkStart == chunkEnd) break;

    if (bytes[chunkStart] == COMMA) bytes[chunkStart] = OPEN_BRACKET;
    final hasAppend = bytes[chunkEnd - 1] != CLOSE_BRACKET;
    final saved = bytes[chunkEnd];
    if (hasAppend) bytes[chunkEnd] = CLOSE_BRACKET;
    final payloadLength = chunkEnd - chunkStart + (hasAppend ? 1 : 0);
    view.setUint32(chunkStart - 4, payloadLength, Endian.host);

    writeFully(buffer, chunkStart - 4, chunkStart + payloadLength);

    bytes[chunkEnd] = saved;
    index = splitIndex;
  }
}
