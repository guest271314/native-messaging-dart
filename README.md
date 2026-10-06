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

## License
Do What the Fuck You Want to Public License [WTFPLv2](http://www.wtfpl.net/about/)
