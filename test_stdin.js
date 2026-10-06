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
await nativeMessagingPerformanceTest(10);
