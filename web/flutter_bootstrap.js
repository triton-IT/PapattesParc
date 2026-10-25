{{flutter_js}}
{{flutter_build_config}}
// Retire only the previous Flutter worker belonging to this app scope.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.getRegistrations().then(function(registrations) {
    const scope = new URL('.', document.baseURI).href;
    for (const registration of registrations) {
      const worker = registration.active || registration.waiting;
      if (registration.scope === scope && worker &&
          new URL(worker.scriptURL).pathname.endsWith('/flutter_service_worker.js')) {
        registration.unregister();
      }
    }
  }).catch(function(){});
}
_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    try {
      const runner = await engineInitializer.initializeEngine();
      await runner.runApp();
    } catch (error) { window.showBootError(); }
  }
}).catch(function(){ window.showBootError(); });
