{{flutter_js}}
{{flutter_build_config}}

// Offline support comes from our own sw.js (registered in index.html), not
// Flutter's service worker, which newer Flutter versions no longer ship.
_flutter.loader.load();
