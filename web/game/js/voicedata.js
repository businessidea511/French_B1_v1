// Numbers and fixed sentences of the confrontations, shared by the game
// and the voice recording tool (tools/game_voices.mjs). No browser code here.

export const HOURS = ['minuit', 'une heure', 'deux heures', 'trois heures', 'quatre heures', 'cinq heures', 'six heures', 'sept heures', 'huit heures', 'neuf heures', 'dix heures', 'onze heures', 'midi'];
export const NUMBERS = ['zéro', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf', 'dix', 'onze', 'douze', 'treize', 'quatorze', 'quinze', 'seize', 'dix-sept', 'dix-huit', 'dix-neuf', 'vingt', 'vingt et un', 'vingt-deux', 'vingt-trois', 'vingt-quatre', 'vingt-cinq', 'vingt-six', 'vingt-sept', 'vingt-huit', 'vingt-neuf', 'trente'];

export const DEPART_MINUTES = [0, 10, 15, 20, 30, 40, 45, 50];
export const MINUTE_WORDS = { 0: '', 10: 'dix', 15: 'quinze', 20: 'vingt', 30: 'trente', 40: 'quarante', 45: 'quarante-cinq', 50: 'cinquante' };
export const departLine = (h, m) => `Le train part à ${NUMBERS[h]} heures${m ? ' ' + MINUTE_WORDS[m] : ''}.`;


/** Every sentence a man in grey can say with these banks (to record the voices once). */
export function bankLines(banks) {
  const out = [];
  for (const b of banks) {
    if (b.kind === 'phrase') for (const [ask, right] of b.items) out.push([ask, 'agent'], [right, 'denise']);
    if (b.kind === 'objets') { out.push([b.ask, 'agent']); for (const [w] of b.items) out.push([w, 'denise']); }
    if (b.kind === 'ecoute') {
      for (const g of b.gens) {
        if (g === 'heure') for (let h = 1; h < 12; h++) out.push([`Il est ${HOURS[h]}. Vous êtes en retard !`, 'agent']);
        if (g === 'chambre') for (let n = 10; n <= 30; n++) out.push([`Votre chambre d'hôtel, c'est la ${NUMBERS[n]} ?`, 'agent']);
        if (g === 'quai') for (let n = 1; n <= 12; n++) out.push([`Votre train part du quai ${NUMBERS[n]}.`, 'agent']);
        if (g === 'depart') for (let h = 18; h <= 23; h++) for (const m of DEPART_MINUTES) out.push([departLine(h, m), 'agent']);
      }
    }
  }
  return out;
}

