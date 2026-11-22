import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Opens « La Quête des Mots Perdus » (web/game), on the same site.
void openGame() {
  (globalContext['location'] as JSObject)['href'] = '/game/index.html'.toJS;
}
