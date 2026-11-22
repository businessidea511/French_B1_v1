// Numbers and fixed sentences of the confrontations, shared by the game
// and the voice recording tool (tools/game_voices.mjs). No browser code here.

export const HOURS = ['minuit', 'une heure', 'deux heures', 'trois heures', 'quatre heures', 'cinq heures', 'six heures', 'sept heures', 'huit heures', 'neuf heures', 'dix heures', 'onze heures', 'midi'];
export const NUMBERS = ['zéro', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf', 'dix', 'onze', 'douze', 'treize', 'quatorze', 'quinze', 'seize', 'dix-sept', 'dix-huit', 'dix-neuf', 'vingt', 'vingt et un', 'vingt-deux', 'vingt-trois', 'vingt-quatre', 'vingt-cinq', 'vingt-six', 'vingt-sept', 'vingt-huit', 'vingt-neuf', 'trente'];

export const DEPART_MINUTES = [0, 10, 15, 20, 30, 40, 45, 50];
export const MINUTE_WORDS = { 0: '', 10: 'dix', 15: 'quinze', 20: 'vingt', 30: 'trente', 40: 'quarante', 45: 'quarante-cinq', 50: 'cinquante' };
export const departLine = (h, m) => `Le train pour Charleroi part à ${NUMBERS[h]} heures${m ? ' ' + MINUTE_WORDS[m] : ''}.`;
export const quaiLine = (n) => `Attention : le train de Namur part du quai ${NUMBERS[n]}.`;
// Floors (ordinal numbers) and prices (euros and cents).
export const ORDINALS = ['', 'premier', 'deuxième', 'troisième', 'quatrième', 'cinquième', 'sixième', 'septième', 'huitième', 'neuvième'];
export const etageLine = (n) => `Le voisin habite au ${ORDINALS[n]} étage.`;
export const etageShow = (n) => `${n === 1 ? '1er' : n + 'e'} étage`;
export const PRICE_CENTS = [0, 10, 20, 30, 40, 50];
const CENT_WORDS = { 10: 'dix', 20: 'vingt', 30: 'trente', 40: 'quarante', 50: 'cinquante' };
export const prixLine = (e, c) => `Ça fait ${e === 1 ? 'un' : NUMBERS[e]} euro${e > 1 ? 's' : ''}${c ? ' ' + CENT_WORDS[c] : ''}.`;
export const prixShow = (e, c) => `${e},${String(c).padStart(2, '0')} €`;


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
        if (g === 'quai') for (let n = 1; n <= 12; n++) out.push([quaiLine(n), 'agent']);
        if (g === 'depart') for (let h = 18; h <= 23; h++) for (const m of DEPART_MINUTES) out.push([departLine(h, m), 'agent']);
        if (g === 'etage') for (let n = 1; n <= 9; n++) out.push([etageLine(n), 'agent']);
        if (g === 'prix') for (let e = 1; e <= 9; e++) for (const c of PRICE_CENTS) out.push([prixLine(e, c), 'agent']);
      }
    }
  }
  return out;
}

