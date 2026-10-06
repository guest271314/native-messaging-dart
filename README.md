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
- 64 MiB of JSON arrays filled with `null` values at 1 MiB maximum JSON array length per message

### Test multiple Native Messaging hosts

For each Native Messaging host create a host manifest, in the same form as, and include the extension ID that points to a single extension to run all hosts, for example

```json
{
  "name": "nm_dart",
  "description": "dart Native Messaging Host",
  "path": "/home/user/native-messaging-dart/nm_dart",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/",
    "chrome-extension://zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz/"
  ]
}
```

```json
{
  "name": "nm_zig_wasi",
  "description": "Zig WASI Native Messaging host",
  "path": "/home/user/native-messaging-webassembly/nm_zig_wasi.sh",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv/",
    "chrome-extension://zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz/"
  ]
}
```
where the extension ID `zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz` connects to multiple Native Messaging hosts, e.g., [NativeMessagingHosts](https://github.com/guest271314/NativeMessagingHosts), from the same extension. Then run the script `test_stdin.js` to compare performance between hosts in DevTools Snippets or Console; on the HTML extension page; in background pages; in `ServiceWorker` of the extension

```devtools
async function nativeMessagingPerformanceTest(i = 10, ...rt) {
  const runtimes = rt?.length
    ? new Map(rt.map((host) => [host, 0]))
    : new Map([
    ["nm_assemblyscript", 0],
    ["nm_bash", 0],
    ["nm_bun", 0],
    ["nm_c", 0],
    ["nm_cpp", 0],
    ["nm_d8", 0],
    ["nm_deno", 0],
    ["nm_llrt", 0], // Uses subprocess to read STDIN
    ["nm_nodejs", 0],
    ["nm_python", 0],
    ["nm_qjs", 0],
    ["nm_rust", 0],
    ["nm_shermes", 0],
    ["nm_spidermonkey", 0],
    ["nm_tjs", 0],
    ["nm_typescript", 0],
    ["nm_wasm", 0],
    ["nm_ruby", 0],
    ["nm_go", 0],
    ["nm_lua", 0],
    ["nm_boa", 0],
    ["nm_rquickjs", 0],
    ["nm_runjs", 0],
    ["nm_scriptc", 0],
    ["nm_componentize_js", 0],
    ["nm_componentize_qjs", 0],
    ["nm_js2wasm", 0],
    ["nm_zig", 0],
    ["nm_zig_wasi", 0],
    ["nm_tinygo_wasi", 0],
    ["nm_warpo", 0],
    ["nm_c_wasi", 0],
    ["nm_cpp_wasi", 0],
    ["nm_rust_wasi", 0],
    ["nm_php", 0],
    ["nm_go_wasi", 0],
    ["nm_javy", 0],
    ["nm_javy_node_wasi", 0],
    ["nm_qjs_wasi", 0],
    ["nm_dart", 0]
  ]);
  for (let j = 0; j < i; j++) {
    for (const [runtime] of runtimes) {
      console.log(`${runtime} run no. ${j} of ${i}}`);
      try {
        let len = 0;
        const { resolve, reject, promise } = Promise.withResolvers();
        const now = performance.now();
        const port = chrome.runtime.connectNative(runtime);
        port.onMessage.addListener((message) => {
          len += message.length;
          if (len < 209715) return;
          console.assert(message.length === 209715, {
            message,
            runtime,
          });
          const n = runtimes.get(runtime);
          runtimes.set(runtime, n + ((performance.now() - now) / 1000));
          port.disconnect();
          resolve();
        });
        port.onDisconnect.addListener(() => reject(chrome.runtime.lastError));
        port.postMessage(new Array(209715));
        // Handle SpiderMonkey, send "\r\n\r\n" to process full message with js
        if (runtime === "nm_spidermonkey") {
          port.postMessage("\r\n\r\n");
        }
        await promise;
      } catch (e) {
        console.log(e, runtime);
        continue;
      }
    }
    await scheduler.postTask(() => {}, {
      delay: 10
    });
  }
  const sorted = [...runtimes].map(([k, n]) => [k, n / i]).sort((
    [, a],
    [, b],
  ) => a < b ? -1 : a === b ? 0 : 1);
  console.table(sorted);
}
await nativeMessagingPerformanceTest(200); // Run each host 200 times
```

which will render a table in DevTools showing fastest to slowest average time per host to roundtrip 1 MiB JSON array containing `null` values

```devtools
0	'nm_shermes'	0.037
1	'nm_rquickjs'	0.0405
2	'nm_warpo'	0.041
3	'nm_go'	0.04110000000149012
4	'nm_lua'	0.041199999999254944
5	'nm_cpp'	0.0415
6	'nm_zig_wasi'	0.0425
7	'nm_c'	0.04360000000149011
8	'nm_zig'	0.044800000000745056
9	'nm_d8'	0.0455
10	'nm_c_wasi'	0.04910000000149012
11	'nm_tinygo_wasi'	0.049399999998509886
12	'nm_tjs'	0.0495
13	'nm_scriptc'	0.0505
14	'nm_rust'	0.0515
15	'nm_boa'	0.05319999999925494
16	'nm_assemblyscript'	0.053600000001490115
17	'nm_runjs'	0.05919999999925494
18	'nm_typescript'	0.059600000001490114
19	'nm_wasm'	0.060100000001490114
20	'nm_rust_wasi'	0.06069999999925494
21	'nm_deno'	0.06560000000149012
22	'nm_componentize_qjs'	0.068
23	'nm_bun'	0.0695
24	'nm_dart'	0.07189999999850988
25	'nm_javy'	0.07839999999850988
26	'nm_cpp_wasi'	0.08390000000223517
27	'nm_go_wasi'	0.08440000000223517
28	'nm_qjs_wasi'	0.09389999999850988
29	'nm_nodejs'	0.09510000000149012
30	'nm_qjs'	0.09869999999925494
31	'nm_php'	0.099
32	'nm_spidermonkey'	0.10010000000149012
33	'nm_ruby'	0.10559999999776483
34	'nm_python'	0.11389999999850989
35	'nm_bash'	0.12009999999776483
36	'nm_javy_node_wasi'	0.13290000000223517
37	'nm_componentize_js'	0.23220000000298024
38	'nm_js2wasm'	0.25490000000223517
39	'nm_llrt'	0.30420000000298025
```

Run `nm_dart` 100 times
```devtools
await nativeMessagingPerformanceTest(100, "nm_dart");
```

Run `nm_dart`, `nm_lua`, `nm_zig` for comparsion of average time per host for 500 roundtrips
```devtools
await nativeMessagingPerformanceTest(500, "nm_dart", "nm_lua", "nm_zig");
```

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
