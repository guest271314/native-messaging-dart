## Dart Native Messaging host

> [dart-lang/sdk](https://github.com/dart-lang/sdk)
> 
> An approachable, portable, and productive language for high-quality apps on any platform
Dart is:
>
> - Approachable: Develop with a strongly typed programming language that is consistent, concise, and offers modern language features like null safety and patterns.
>
> - Portable: Compile to ARM, x64, or RISC-V machine code for mobile, desktop, and backend. Compile to JavaScript or WebAssembly for the web.
>
> - Productive: Make changes iteratively: use hot reload to see the result instantly in your running app. Diagnose app issues using [DevTools](https://dart.dev/tools/dart-devtools).
>
> Dart's flexible compiler technology lets you run Dart code in different ways, depending on your target platform and goals:
>
> - Dart Native: For programs targeting devices (mobile, desktop, server, and more), Dart Native includes both a Dart VM with JIT (just-in-time) compilation and an AOT (ahead-of-time) compiler for producing machine code.
>
> - Dart Web: For programs targeting the web, Dart Web includes both a development time compiler (dartdevc) and a production time compiler (dart2js).

### Compile 
#### Native executable
```shell
dart compile exe nm_dart.dart -S debug_dart.txt -o nm_dart
```

### Installation and usage on Chrome and Chromium

1. Navigate to `chrome://extensions`.
2. Toggle `Developer mode`.
3. Click `Load unpacked`.
4. Select `native-messaging-dart` folder.
5. Note the generated extension ID.
6. Open `nm_dart.json` in a text editor, set `"path"` to absolute path of `nm_dart`, and `chrome-extension://<ID>/` using ID from 5 in `"allowed_origins"` array.
7. Copy the `nm_dart.json` file to Chrome or Chromium configuration folder, e.g., Chromium on Linux `~/.config/chromium/NativeMessagingHosts`; Chrome dev channel on Linux `~/.config/google-chrome-unstable/NativeMessagingHosts`.
8. To test click `service worker` link in panel of unpacked extension which is DevTools for `background.js` in MV3 `ServiceWorker`, observe echo'ed message from `dart` Native Messaging host. To disconnect run `port.disconnect()`.

The Native Messaging host echoes back the message passed. 

For differences between OS and browser implementations see [Chrome incompatibilities](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Chrome_incompatibilities#native_messaging).

### Test standalone

#### Deno
```shell
deno -A ./nm_standalone_test.js ./nm_dart
```
#### Node.js
```shell
node ./nm_standalone_test_node.js ./nm_dart
```

Expected roundtrip of 

```javascript
try {
  for (
    const message of [
      Array(209715),
      "test",
      "",
      1,
      new Uint8Array([97]),
      Array(209715 * 64),
    ]
  ) {
    const result = await echoNativeMessage(message);
    console.log(result);
  }
} catch (e) {
  console.log(e.stack);
  console.trace();
} finally {
  subprocess.kill("SIGTERM");
}

```

- 1 MiB JSON array filled with `null` values
- JSON string `"test"`
- JSON empty string `""`
- JSON number `1`
- JSON object `{0:97}`
- 64 MiB of JSON arrays filled with `null` values at 1 MiB maximum JSON array length per message (see the Native Messaging protocol, below)

## Native messaging documentation
- [Chrome Developers](https://developer.chrome.com/docs/extensions/mv3/nativeMessaging/)
- [MDN Web Docs](https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Native_messaging)
- [Microsoft Edge Developer documentation](https://learn.microsoft.com/en-us/microsoft-edge/extensions-chromium/developer-guide/native-messaging)
- [Messaging between the app and JavaScript in a Safari web extension](https://developer.apple.com/documentation/safariservices/messaging-between-the-app-and-javascript-in-a-safari-web-extension)
- [Opera help Native messaging](https://help.opera.com/en/extensions/message-passing/#native-messaging)

[Native messaging protocol](https://developer.chrome.com/docs/extensions/mv3/nativeMessaging/#native-messaging-host-protocol) (Chrome Developers)

> Chrome starts each native messaging host in a separate process and communicates with it using standard input (`stdin`) and standard output (`stdout`). The same format is used to send messages in both directions; each message is serialized using JSON, UTF-8 encoded and is preceded with 32-bit message length in native byte order. The maximum size of a single message from the native messaging host is 1 MB, mainly to protect Chrome from misbehaving native applications. The maximum size of the message sent to the native messaging host is 64 MiB.
>
> The first argument to the native messaging host is the origin of the caller, usually `chrome-extension://[ID of allowed extension]`. This allows native messaging hosts to identify the source of the message when multiple extensions are specified in the allowed_origins key in the [native messaging host manifest](https://developer.chrome.com/docs/extensions/develop/concepts/native-messaging#native-messaging-host).




## License
Do What the Fuck You Want to Public License [WTFPLv2](http://www.wtfpl.net/about/)
