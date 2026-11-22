import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Opens « Le Dossier Bruxelles » (web/game), on the same site.
void openGame() {
  (globalContext['location'] as JSObject)['href'] = '/game/index.html'.toJS;
}
