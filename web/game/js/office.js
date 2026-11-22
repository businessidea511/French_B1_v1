// Inside buildings, at night: rooms, corridors, low walls (the camera looks
// from above), furniture, and cold office light.
// Layouts: « lumen » (Lumen's headquarters), « studio » (the TV station),
// « immeuble » (Élise's building) and « metro » (the Bourse station).
import * as THREE from 'three';
import { std, glowTexture, signTexture, rand } from './city.js';

const WALL_H = 2.9;

// Wall segments [x0, z0, x1, z1] (gaps are doors), props, signs, light pools.
const LAYOUTS = {
  lumen: {
    bounds: [-20, 20, -24, 24],
    floor: '#2b2f36',
    wall: '#cfd3d8',
    cinema: [0, 18, 34, -0.6, 0, 0, 8],
    walls: [
      // outside
      [-20, -24, 20, -24], [-20, 24, -3, 24], [3, 24, 20, 24], [-20, -24, -20, 24], [20, -24, 20, 24],
      // lobby / corridor
      [-20, 8, -3, 8], [3, 8, 20, 8],
      // corridor walls with doors (office z 0, archives z -16, lab z 0, servers z -16)
      [-3, 8, -3, 1.4], [-3, -1.4, -3, -14.6], [-3, -17.4, -3, -24],
      [3, 8, 3, 1.4], [3, -1.4, 3, -14.6], [3, -17.4, 3, -24],
      // between the rooms
      [-20, -8, -3, -8], [3, -8, 20, -8],
    ],
    props: [
      ['reception', 0, 15, 0], ['logo', 0, 23.7, Math.PI, 'LUMEN'], ['plant', -17, 21], ['plant', 17, 21], ['plant', -17, 10.5],
      ['gate', -1.6, 9.5], ['gate', 1.6, 9.5], ['sofa', -12, 18, Math.PI / 2], ['sofa', 12, 18, -Math.PI / 2],
      // Lenoir's office (west)
      ['desk', -11, 0, 0], ['desk', -15.5, 4.5, Math.PI / 2], ['shelf', -19.4, -3, Math.PI / 2], ['plant', -5, 6],
      // archives (west, north)
      ['shelf', -17, -12, 0], ['shelf', -17, -16, 0], ['shelf', -17, -20, 0], ['shelf', -10, -12, 0], ['shelf', -10, -16, 0], ['shelf', -10, -20, 0],
      // laboratory (east)
      ['labtable', 9, -2, 0], ['labtable', 15, -2, 0], ['labtable', 9, 4, 0], ['screens', 19.4, 2, -Math.PI / 2], ['plant', 5, 6],
      // server room (east, north)
      ['rack', 9, -12, 0], ['rack', 9, -16, 0], ['rack', 9, -20, 0], ['rack', 15, -12, 0], ['rack', 15, -16, 0], ['rack', 15, -20, 0],
      ['terminal', 18.6, -22.5, -Math.PI / 2],
    ],
    signs: [
      ['BUREAU DU DIRECTEUR', -3.05, 2.5, 3.2, -Math.PI / 2], ['ARCHIVES', -3.05, 2.5, -12.8, -Math.PI / 2],
      ['LABORATOIRE', 3.05, 2.5, 3.2, Math.PI / 2], ['SERVEURS', 3.05, 2.5, -12.8, Math.PI / 2],
    ],
    pools: [[0, 16, '#d6e4ff'], [0, -4, '#d6e4ff'], [0, -18, '#d6e4ff'], [-11, 0, '#ffe2b8'], [-13, -16, '#d6e4ff'], [12, 0, '#9fd8ff'], [12, -16, '#ff6b6b']],
  },
  studio: {
    bounds: [-20, 20, -24, 24],
    floor: '#24262c',
    wall: '#3a3f4a',
    cinema: [0, 18, 34, -0.6, 0, 0, 8],
    walls: [
      [-20, -24, 20, -24], [-20, 24, -3, 24], [3, 24, 20, 24], [-20, -24, -20, 24], [20, -24, 20, 24],
      // lobby
      [-20, 10, -3, 10], [3, 10, 20, 10],
      // newsroom (west) and control room (east)
      [-3, 10, -3, 1.4], [-3, -1.4, -3, -6], [3, 10, 3, 1.4], [3, -1.4, 3, -6],
      // the studio (north), with a big door, and the storage room (north-west corner)
      [-20, -6, -3, -6], [3, -6, 20, -6], [-20, -15, -12.4, -15], [-9.6, -15, -9, -15], [-9, -15, -9, -24],
    ],
    props: [
      ['reception', 0, 16, 0], ['logo', 0, 23.7, Math.PI, 'TÉLÉ BRUXELLES'], ['plant', -17, 21], ['plant', 17, 21], ['sofa', 12, 17, -Math.PI / 2],
      // newsroom
      ['desk', -15, 6, 0], ['desk', -9, 6, 0], ['desk', -15, 0, 0], ['desk', -9, 0, 0], ['shelf', -19.4, 3, Math.PI / 2],
      // control room
      ['screens', 19.4, 3, -Math.PI / 2], ['desk', 14, 3, -Math.PI / 2], ['desk', 9, 3, -Math.PI / 2],
      // studio
      ['newsdesk', 4, -18, 0], ['camera', -2, -11, Math.PI], ['camera', 9, -11, Math.PI], ['spot', -6, -21], ['spot', 14, -21], ['bigscreen', 4, -23.6, 0],
      // storage room
      ['shelf', -18, -19, 0], ['shelf', -18, -22.5, 0], ['box', -12, -22],
    ],
    signs: [
      ['RÉDACTION', -3.05, 2.5, 3.2, -Math.PI / 2], ['RÉGIE', 3.05, 2.5, 3.2, Math.PI / 2],
      ['STUDIO 1 · EN DIRECT', 0, 2.6, -5.95, 0], ['RÉSERVE', -11, 2.5, -15.05, 0],
    ],
    pools: [[0, 16, '#d6e4ff'], [-12, 3, '#ffe2b8'], [12, 3, '#9fd8ff'], [4, -16, '#fff3d6'], [-15, -20, '#d6e4ff'], [-5, -10, '#ffd59a']],
  },
  // Élise's building, 12 rue des Ombres (stage A1-2): the hall, her flat, the attic, the cellar.
  immeuble: {
    bounds: [-16, 16, -20, 20],
    floor: '#3b2c21',
    wall: '#b7a88f',
    cinema: [0, 16, 30, -0.5, 0, 0, 6],
    walls: [
      [-16, -20, 16, -20], [-16, 20, -2, 20], [2, 20, 16, 20], [-16, -20, -16, 20], [16, -20, 16, 20],
      // the hall (south) and the flat's front door
      [-16, 10, -1.4, 10], [1.4, 10, 16, 10],
      // living room (west) | kitchen and bedroom (east)
      [0, 10, 0, 7.6], [0, 4.4, 0, -0.6], [0, -3.4, 0, -6], [0, 2, 16, 2],
      // the back of the flat: stairs to the attic (west) and to the cellar (east)
      [-16, -6, -9.4, -6], [-6.6, -6, 6.6, -6], [9.4, -6, 16, -6], [0, -6, 0, -20],
    ],
    props: [
      // hall
      ['mailboxes', -15.6, 15, Math.PI / 2], ['stairs', 13, 15, 0], ['plant', -14.5, 11.5], ['lamp', 6, 18.5], ['bike', 9, 11],
      // living room
      ['sofa', -10, 6, 0], ['rug', -9, 2.5], ['lowtable', -9, 2.5], ['shelf', -15.4, 0, Math.PI / 2], ['desk', -5, -3.5, Math.PI], ['lamp', -2, 8.5], ['plant', -14.5, 8.6],
      // kitchen
      ['counter', 8, 9.3, Math.PI], ['fridge', 15, 9, -Math.PI / 2], ['table', 7, 5.5], ['chair', 5.6, 5.5, Math.PI / 2], ['chair', 8.4, 5.5, -Math.PI / 2],
      // bedroom
      ['bed', 12.5, -2, -Math.PI / 2], ['wardrobe', 5, -5.3, 0], ['lamp', 15, 1], ['rug', 9, -2],
      // attic
      ['trunk', -13, -9.5, 0], ['box', -4, -17], ['box', -13.5, -18], ['oldchair', -6, -10, 0.6], ['mannequin', -10.5, -14.5], ['shelf', -2, -12, -Math.PI / 2],
      // cellar
      ['barrels', 14, -9, 0], ['bike', 3.5, -10, Math.PI / 2], ['boiler', 14.5, -18, 0], ['box', 9, -18.5], ['box', 4, -18], ['shelf', 15.4, -13.5, -Math.PI / 2],
    ],
    signs: [
      ['APPARTEMENT 3B · MOREAU', 0, 2.5, 10.17, 0], ['GRENIER ↑', -8, 2.5, -5.83, 0], ['CAVE ↓', 8, 2.5, -5.83, 0],
    ],
    pools: [[0, 15, '#ffd59a'], [-9, 3, '#ffe2b8'], [8, 6, '#fff3d6'], [11, -2, '#ffcf9a'], [-8, -13, '#c9b48a'], [8, -13, '#9fb4ff']],
  },
  // The Gazette newspaper at night (stage B1-2): reception, newsroom, archives, photo lab, the editor's office.
  gazette: {
    bounds: [-18, 18, -20, 20],
    floor: '#2e3138',
    wall: '#c9c2b4',
    cinema: [0, 18, 34, -0.6, 0, 0, 8],
    walls: [
      [-18, -20, 18, -20], [-18, 20, -2, 20], [2, 20, 18, 20], [-18, -20, -18, 20], [18, -20, 18, 20],
      // reception | newsroom
      [-18, 12, -2, 12], [2, 12, 18, 12],
      // archives (west), photo lab (middle), editor (east)
      [-18, -4, -13.4, -4], [-10.6, -4, -1.4, -4], [1.4, -4, 9.4, -4], [12.6, -4, 18, -4], [-6, -4, -6, -20], [6, -4, 6, -20],
    ],
    props: [
      ['desk', -9, 15, 0], ['plant', -16.5, 18.5], ['plant', 16.5, 18.5], ['sofa', 12, 16, -Math.PI / 2], ['logo', 0, 19.7, Math.PI, 'LA GAZETTE'],
      ['desk', -14, 6, 0], ['desk', -14, 0.5, 0], ['desk', -9, 6, 0], ['desk', -9, 0.5, 0], ['desk', -4, 6, 0], ['desk', -4, 0.5, 0], ['desk', 4, 6, 0], ['desk', 4, 0.5, 0], ['desk', 9, 6, 0], ['desk', 9, 0.5, 0], ['desk', 14, 6, 0], ['desk', 14, 0.5, 0],
      ['shelf', -14, -11, 0], ['shelf', -14, -15, 0], ['shelf', -9, -11, 0], ['shelf', -9, -15, 0], ['box', -8, -18.4],
      ['labtable', -3, -13, 0], ['labtable', 3, -13, 0], ['screens', 0, -19.6, 0], ['lamp', -5, -5.6],
      ['desk', 12, -10.5, 0], ['shelf', 17.4, -12, -Math.PI / 2], ['sofa', 9.5, -17.4, 0], ['plant', 16.5, -5.6],
    ],
    signs: [
      ['RÉDACTION', 0, 2.5, 12.17, 0], ['ARCHIVES', -12, 2.5, -3.83, 0], ['LABO PHOTO', 0, 2.5, -3.83, 0], ['RÉDACTEUR EN CHEF', 11, 2.5, -3.83, 0],
    ],
    pools: [[0, 16, '#d6e4ff'], [-9, 3, '#ffe2b8'], [9, 3, '#ffe2b8'], [-12, -12, '#c9b48a'], [0, -12, '#ff6b6b'], [12, -10, '#ffe2b8']],
  },
  // Victor's bookshop in Liège, at night (stage A2-4): the shop, his office, his mother's flat, the printing room.
  librairie: {
    bounds: [-14, 14, -18, 18],
    floor: '#4a3424',
    wall: '#8a7258',
    cinema: [0, 15, 30, -0.5, 0, 0, 6],
    walls: [
      [-14, -18, 14, -18], [-14, 18, 14, 18], [-14, -18, -14, 18], [14, -18, 14, 18],
      // shop (south) | office (west) and the flat (east)
      [-14, 4, -8.4, 4], [-5.6, 4, 5.6, 4], [8.4, 4, 14, 4], [0, 4, 0, -6],
      // the printing room under the office (north)
      [-14, -6, -9.4, -6], [-6.6, -6, 14, -6],
    ],
    props: [
      // shop
      ['shelf', -11, 15, 0], ['shelf', -11, 10.5, 0], ['shelf', 11, 15, 0], ['shelf', 11, 10.5, 0],
      ['shelf', -5, 13, Math.PI / 2], ['shelf', 5, 13, Math.PI / 2], ['desk', 0, 7, 0], ['sofa', -10, 6.2, 0], ['lamp', -13, 7.5], ['plant', 13, 6.5], ['rug', 0, 12],
      // Victor's office
      ['desk', -7, -0.5, Math.PI], ['shelf', -13.4, -1, Math.PI / 2], ['safe', -12.8, -4.6, Math.PI / 2], ['trunk', -2.6, -4.6, 0], ['lamp', -1.4, 2.6],
      // Odile's flat and Lina's corner
      ['table', 5, -1], ['chair', 3.6, -1, Math.PI / 2], ['chair', 6.4, -1, -Math.PI / 2], ['bed', 11.4, -3.2, -Math.PI / 2], ['wardrobe', 12.9, 2.2, -Math.PI / 2], ['lamp', 1.2, -4.8], ['rug', 10, -0.5],
      // printing room
      ['press', 0, -12.6, 0], ['box', -11.6, -16.2], ['box', -12.6, -9], ['barrels', 11, -15], ['shelf', 12.6, -9.6, -Math.PI / 2], ['shelf', -13.4, -12.6, Math.PI / 2], ['lamp', -5, -16.6],
    ],
    signs: [
      ['LIBRAIRIE LE PHÉNIX', 0, 2.5, 17.83, Math.PI], ['BUREAU', -7, 2.5, 4.17, 0], ['PRIVÉ', 7, 2.5, 4.17, 0], ['IMPRIMERIE', -8, 2.5, -5.83, 0],
    ],
    pools: [[0, 12, '#ffd59a'], [-7, -1, '#ffe2b8'], [7, -1, '#ffcf9a'], [0, -12, '#9fb4ff'], [-10, 7, '#ffd59a']],
  },
  // The night train to Liège (stage A2-2): car 8 (seats), car 7 (bar), car 6 (sleeping car), car 5 (luggage).
  train: {
    bounds: [-2.6, 2.6, -40, 40],
    floor: '#3e3430',
    wall: '#8a5a3c',
    moving: true,
    cinema: [0, 9, 52, -0.7, 0, 0, 30],
    walls: [
      [-2.6, -40, 2.6, -40], [-2.6, 40, 2.6, 40], [-2.6, -40, -2.6, 40], [2.6, -40, 2.6, 40],
      // between the cars (the door is on the right side)
      [-2.6, 22, 0, 22], [2, 22, 2.6, 22], [-2.6, 4, 0, 4], [2, 4, 2.6, 4],
      [-2.6, -14, 0, -14], [2, -14, 2.6, -14], [-2.6, -32, 0, -32], [2, -32, 2.6, -32],
      // the sleeping car: four compartments on the left, the corridor on the right
      [-0.2, 4, -0.2, 2.7], [-0.2, 1.3, -0.2, -1.6], [-0.2, -2.9, -0.2, -6.1], [-0.2, -7.4, -0.2, -10.8], [-0.2, -12.2, -0.2, -14],
      [-2.6, 0, -0.2, 0], [-2.6, -4.5, -0.2, -4.5], [-2.6, -9, -0.2, -9],
    ],
    props: [
      ['seat', -1.8, 24.6, 0], ['seat', 1.9, 24.6, 0], ['seat', -1.8, 27.2, Math.PI], ['seat', 1.9, 27.2, Math.PI], ['seat', -1.8, 29.8, Math.PI], ['seat', 1.9, 29.8, Math.PI], ['seat', -1.8, 32.4, 0], ['seat', 1.9, 32.4, 0], ['seat', -1.8, 35.0, Math.PI], ['seat', 1.9, 35.0, Math.PI], ['seat', -1.8, 37.6, Math.PI], ['seat', 1.9, 37.6, Math.PI],
      // bar car
      ['barcounter', -2, 12, 0], ['stool', -0.9, 9.4], ['stool', -0.9, 11.6], ['stool', -0.9, 13.8], ['bartable', 1.9, 8.5], ['bartable', 1.9, 12.5], ['bartable', 1.9, 16.5], ['lamp', 2.1, 20.5],
      // sleeping car
      ['bunk', -2.1, 2, 0], ['bunk', -2.1, -2.25, 0], ['bunk', -2.1, -6.75, 0], ['bunk', -2.1, -11.5, 0],
      // luggage car
      ['box', -1.9, -16.5], ['box', -1.9, -20], ['box', 1.9, -22], ['box', -1.9, -27], ['box', 1.9, -26.4], ['trunk', -1.8, -30, Math.PI / 2], ['bike', 1.9, -18, Math.PI / 2],
      // front platform
      ['box', -1.8, -38.6], ['lamp', 2, -38.6],
    ],
    signs: [
      ['VOITURE 7 · BAR', 1, 2.5, 22.17, 0], ['VOITURE 6 · COUCHETTES', 1, 2.5, 4.17, 0], ['VOITURE 5 · BAGAGES', 1, 2.5, -13.83, 0],
      ['PLATEFORME', 1, 2.5, -31.83, 0], ['COUCHETTE 3', -0.03, 2.4, -6.75, Math.PI / 2],
    ],
    pools: [[0, 31, '#ffe2b8'], [0, 13, '#ffcf8a'], [1.2, -5, '#d6e4ff'], [0, -23, '#9fb4ff'], [0, -36, '#ff9a6a']],
  },

  // The Bourse metro station (stage A1-3): ticket hall, gates, corridor, two platforms over the tracks.
  metro: {
    bounds: [-18, 18, -26, 22],
    floor: '#3a3d42',
    wall: '#d9d2c3',
    cinema: [0, 16, 30, -0.6, 0, 0, 6],
    walls: [
      [-18, -26, 18, -26], [-18, 22, -2.2, 22], [2.2, 22, 18, 22], [-18, -26, -18, 22], [18, -26, 18, 22],
      // the ticket hall ends at the gates (z 8), the corridor goes north on the west side
      [-18, 8, -9, 8], [-5, 8, 18, 8],
      [-9, 8, -9, -1], [-5, 8, -5, 1], [-5, 1, 18, 1],
      // the passage under the tracks to platform 2 (far west)
      [-14, -1, -14, -15.5],
    ],
    // The tracks: not walkable (a train can come).
    holes: [[-14, 18, -15.5, -10.5]],
    tracks: [[-14, 18, -13]],
    props: [
      ['ticketmachine', -16.8, 16, Math.PI / 2], ['ticketmachine', -16.8, 12.5, Math.PI / 2], ['guichet', 14, 14, 0],
      ['plant', -16.5, 20.5], ['bench', 6, 19, Math.PI], ['metromap', 0, 21.8, Math.PI],
      ['gate', -8.3, 8], ['gate', -5.7, 8],
      ['pillar', -2, -4], ['pillar', 6, -4], ['pillar', 14, -4], ['bench', 2, -2.2, Math.PI], ['bench', 10, -2.2, Math.PI], ['vending', 17.2, -6, -Math.PI / 2],
      ['pillar', -2, -20], ['pillar', 6, -20], ['pillar', 14, -20], ['bench', 2, -24.6, 0], ['bench', 10, -24.6, 0], ['phonebooth', 16.6, -23.5, -Math.PI / 2],
      ['metromap', -17.8, 3, Math.PI / 2],
    ],
    signs: [
      ['BOURSE · BEURS', 0, 2.6, 21.8, Math.PI], ['QUAI 1 · DIRECTION GARE DU MIDI', 6, 2.6, 0.83, Math.PI], ['QUAI 2 · DIRECTION ROI BAUDOUIN', 6, 2.6, -25.8, 0],
      ['← QUAI 2', -13.83, 2.4, -6, Math.PI / 2], ['GUICHET', 15.6, 2.6, 14, -Math.PI / 2],
    ],
    pools: [[0, 16, '#fff3d6'], [-7, 4, '#d6e4ff'], [6, -5, '#fff3d6'], [6, -21, '#fff3d6'], [-16, -8, '#d6e4ff'], [16, -23, '#ffcf6b']],
  },
};

function distToSegment(px, pz, [x0, z0, x1, z1]) {
  const dx = x1 - x0;
  const dz = z1 - z0;
  const len2 = dx * dx + dz * dz || 1;
  const t = Math.max(0, Math.min(1, ((px - x0) * dx + (pz - z0) * dz) / len2));
  return Math.hypot(px - (x0 + dx * t), pz - (z0 + dz * t));
}

export class Office {
  constructor(scene, { weak, layout = 'lumen' }) {
    this.scene = scene;
    this.weak = weak;
    this.time = 0;
    this.colliders = [];
    this.clues = [];
    this.occluders = [];
    this.blinks = [];
    this.L = LAYOUTS[layout];
    this.cinema = this.L.cinema;
    this.build();
  }

  add(obj, x, y, z, r = 0) {
    obj.position.set(x, y, z);
    this.scene.add(obj);
    if (r) this.colliders.push({ x, z, r });
    return obj;
  }

  box(w, h, d, material, cast = true) {
    const m = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), material);
    m.castShadow = cast && !this.weak;
    m.receiveShadow = true;
    return m;
  }

  build() {
    const L = this.L;
    this.scene.background = new THREE.Color('#07090d');
    this.scene.fog = new THREE.Fog('#0a0c12', 26, 80);
    const [x0, x1, z0, z1] = L.bounds;
    // Floor: polished, with faint tile lines.
    const c = document.createElement('canvas');
    c.width = c.height = 256;
    const x = c.getContext('2d');
    x.fillStyle = L.floor;
    x.fillRect(0, 0, 256, 256);
    x.strokeStyle = 'rgba(255,255,255,0.05)';
    for (let k = 0; k <= 4; k++) {
      x.beginPath(); x.moveTo(k * 64, 0); x.lineTo(k * 64, 256); x.stroke();
      x.beginPath(); x.moveTo(0, k * 64); x.lineTo(256, k * 64); x.stroke();
    }
    const tex = new THREE.CanvasTexture(c);
    tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
    tex.repeat.set((x1 - x0) / 4, (z1 - z0) / 4);
    tex.colorSpace = THREE.SRGBColorSpace;
    const floor = new THREE.Mesh(new THREE.PlaneGeometry(x1 - x0, z1 - z0), std('#ffffff', { map: tex, roughness: 0.3, metalness: 0.2 }));
    floor.rotation.x = -Math.PI / 2;
    floor.position.set((x0 + x1) / 2, 0, (z0 + z1) / 2);
    floor.receiveShadow = true;
    this.scene.add(floor);

    // Walls: low enough to see the rooms from above.
    const wallMat = std(L.wall, { roughness: 0.85 });
    const trim = std('#16181d', { roughness: 0.6 });
    for (const seg of L.walls) {
      const [a, b, cc, d] = seg;
      const len = Math.hypot(cc - a, d - b);
      const w = this.box(len + 0.3, WALL_H, 0.3, wallMat);
      w.position.set((a + cc) / 2, WALL_H / 2, (b + d) / 2);
      w.rotation.y = -Math.atan2(d - b, cc - a);
      this.scene.add(w);
      this.occluders.push(w);
      const top = this.box(len + 0.32, 0.08, 0.34, trim, false);
      top.position.set((a + cc) / 2, WALL_H, (b + d) / 2);
      top.rotation.y = w.rotation.y;
      this.scene.add(top);
    }
    // A moving train: lights rush past outside the windows.
    if (L.moving) {
      this.passing = [];
      const lampTex = glowTexture('rgba(255,210,150,0.95)');
      for (let k = 0; k < 18; k++) {
        const s = new THREE.Sprite(new THREE.SpriteMaterial({ map: lampTex, depthWrite: false, blending: THREE.AdditiveBlending }));
        const side = k % 2 ? 1 : -1;
        s.position.set(side * (6 + (k % 5) * 3), 2.5 + (k % 3), -60 + k * 7);
        s.scale.setScalar(1.6);
        this.scene.add(s);
        this.passing.push(s);
      }
      const ground = new THREE.Mesh(new THREE.PlaneGeometry(220, 220), std('#0b0d10', { roughness: 1 }));
      ground.rotation.x = -Math.PI / 2;
      ground.position.y = -0.4;
      this.scene.add(ground);
      // Windows all along both sides.
      for (const side of [-1, 1]) {
        for (let z = -38; z <= 38; z += 2.6) {
          const w = new THREE.Mesh(new THREE.PlaneGeometry(1.6, 0.9), new THREE.MeshBasicMaterial({ color: '#1a2a44' }));
          w.position.set(side * 2.42, 1.75, z);
          w.rotation.y = -side * Math.PI / 2;
          this.scene.add(w);
        }
      }
    }
    for (const [tx0, tx1, tz] of L.tracks || []) this.track(tx0, tx1, tz);
    for (const p of L.props) this.prop(...p);
    for (const [text, sx, sy, sz, rot] of L.signs) {
      const s = new THREE.Mesh(new THREE.PlaneGeometry(2.6, 0.45), new THREE.MeshBasicMaterial({
        map: signTexture(text, { fg: '#ffffff', bg: '#1d2533', w: 512, h: 88, font: 'bold 40px Arial, sans-serif', glow: false }),
      }));
      s.position.set(sx, sy, sz);
      s.rotation.y = rot;
      this.scene.add(s);
    }
    for (const [px, pz, color] of L.pools) {
      const pool = new THREE.Mesh(
        new THREE.CircleGeometry(4.2, 24),
        new THREE.MeshBasicMaterial({ map: glowTexture(this.rgba(color, 0.4)), transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }),
      );
      pool.rotation.x = -Math.PI / 2;
      pool.position.set(px, 0.02, pz);
      this.scene.add(pool);
    }
  }

  rgba(hex, a) {
    const c = new THREE.Color(hex);
    return `rgba(${Math.round(c.r * 255)},${Math.round(c.g * 255)},${Math.round(c.b * 255)},${a})`;
  }

  /** One piece of furniture. */
  prop(type, px, pz, rot = 0, text = '') {
    const g = new THREE.Group();
    const wood = std('#5a3e2a', { roughness: 0.6 });
    const metal = std('#8a9099', { metalness: 0.7, roughness: 0.35 });
    const dark = std('#1a1d23', { roughness: 0.5 });
    const glow = (color) => new THREE.MeshBasicMaterial({ color });
    let r = 0;
    const put = (mesh, x, y, z) => { mesh.position.set(x, y, z); mesh.castShadow = !this.weak; g.add(mesh); return mesh; };
    if (type === 'desk') {
      put(this.box(2.2, 0.08, 1.1, wood), 0, 0.76, 0);
      for (const sx of [-1, 1]) put(this.box(0.06, 0.76, 1, dark), sx * 1.05, 0.38, 0);
      put(this.box(0.8, 0.5, 0.05, dark), 0, 1.07, -0.3);
      put(new THREE.Mesh(new THREE.PlaneGeometry(0.74, 0.44), glow('#5fb8ff')), 0, 1.07, -0.27);
      put(this.box(0.5, 0.5, 0.5, std('#2a2d33')), 0, 0.45, 0.9);
      r = 1.2;
    } else if (type === 'shelf') {
      put(this.box(3, 2.4, 0.6, std('#4a4f57', { metalness: 0.5 })), 0, 1.2, 0);
      const colors = ['#8a4a3a', '#3a5a8a', '#c9b48a', '#3a6a4a', '#7a6a8a'];
      for (let row = 0; row < 3; row++) {
        for (let k = 0; k < 8; k++) {
          put(this.box(0.3, 0.5, 0.42, std(colors[(row * 3 + k) % 5])), -1.2 + k * 0.34, 0.45 + row * 0.75, 0.05);
        }
      }
      r = 1.4;
    } else if (type === 'rack') {
      put(this.box(1.2, 2.4, 2.6, dark), 0, 1.2, 0);
      for (let k = 0; k < 10; k++) {
        const led = put(new THREE.Mesh(new THREE.BoxGeometry(0.02, 0.05, 0.05), glow(k % 3 ? '#3aff7a' : '#ff4a4a')), 0.61, 0.4 + k * 0.2, -1 + (k % 4) * 0.6);
        this.blinks.push({ m: led, t: Math.random() * 6 });
      }
      r = 1.6;
    } else if (type === 'labtable') {
      put(this.box(3, 0.1, 1.4, std('#e8ecef', { roughness: 0.3 })), 0, 0.92, 0);
      put(this.box(2.8, 0.9, 1.2, std('#9aa3ad', { metalness: 0.4 })), 0, 0.45, 0);
      for (const sx of [-0.8, 0, 0.8]) put(new THREE.Mesh(new THREE.CylinderGeometry(0.08, 0.1, 0.35, 10), glow(sx ? '#7affd8' : '#ffd27a')), sx, 1.15, 0.1);
      r = 1.6;
    } else if (type === 'screens') {
      for (let k = 0; k < 3; k++) put(new THREE.Mesh(new THREE.PlaneGeometry(1.6, 1), glow(k === 1 ? '#ff5a5a' : '#4aa8ff')), (k - 1) * 1.7, 1.9, 0);
    } else if (type === 'bigscreen') {
      put(new THREE.Mesh(new THREE.PlaneGeometry(9, 3.2), glow('#1f5fbf')), 0, 2.2, 0);
      const t = new THREE.Mesh(new THREE.PlaneGeometry(8, 1), new THREE.MeshBasicMaterial({
        map: signTexture('JOURNAL DE 6 H · EN DIRECT', { fg: '#ffffff', bg: '#1f5fbf', font: 'bold 50px Arial, sans-serif', glow: false }),
      }));
      put(t, 0, 2.2, 0.01);
    } else if (type === 'reception') {
      put(this.box(5, 1.1, 1.2, std('#20242c', { metalness: 0.5, roughness: 0.4 })), 0, 0.55, 0);
      put(new THREE.Mesh(new THREE.PlaneGeometry(4.6, 0.12), glow('#7ad7ff')), 0, 1.0, 0.61);
      r = 2.4;
    } else if (type === 'logo') {
      put(new THREE.Mesh(new THREE.PlaneGeometry(6, 1.2), new THREE.MeshBasicMaterial({
        map: signTexture(text, { fg: '#cfe8ff', bg: '#0b0f16', font: 'bold 70px Arial, sans-serif' }),
      })), 0, 2.2, 0);
    } else if (type === 'gate') {
      put(this.box(0.25, 1.05, 1.4, metal), 0, 0.52, 0);
      r = 0.5;
    } else if (type === 'sofa') {
      put(this.box(3, 0.5, 1, std('#3a2e4a')), 0, 0.25, 0);
      put(this.box(3, 0.7, 0.25, std('#3a2e4a')), 0, 0.6, -0.4);
      r = 1.5;
    } else if (type === 'plant') {
      put(new THREE.Mesh(new THREE.CylinderGeometry(0.3, 0.24, 0.5, 10), std('#6a5a4a')), 0, 0.25, 0);
      put(new THREE.Mesh(new THREE.IcosahedronGeometry(0.55, 0), std('#2f6a3a', { flatShading: true })), 0, 0.95, 0);
      r = 0.4;
    } else if (type === 'terminal') {
      put(this.box(0.6, 1.2, 1, dark), 0, 0.6, 0);
      const screen = put(new THREE.Mesh(new THREE.PlaneGeometry(0.8, 0.5), glow('#3aff7a')), 0.31, 1.0, 0);
      screen.rotation.y = Math.PI / 2;
      this.blinks.push({ m: screen, t: 0, slow: true });
      r = 0.7;
    } else if (type === 'newsdesk') {
      put(this.box(5, 1, 1.4, std('#1f3a6b', { metalness: 0.4, roughness: 0.35 })), 0, 0.5, 0);
      put(new THREE.Mesh(new THREE.PlaneGeometry(4.8, 0.2), glow('#ffffff')), 0, 0.85, 0.71);
      r = 2.4;
    } else if (type === 'camera') {
      put(new THREE.Mesh(new THREE.CylinderGeometry(0.06, 0.25, 1.4, 6), dark), 0, 0.7, 0);
      put(this.box(0.4, 0.4, 0.8, dark), 0, 1.6, 0);
      put(new THREE.Mesh(new THREE.SphereGeometry(0.05, 6, 4), glow('#ff3030')), 0, 1.85, 0.3);
      r = 0.6;
    } else if (type === 'spot') {
      put(new THREE.Mesh(new THREE.CylinderGeometry(0.05, 0.05, 3, 6), dark), 0, 1.5, 0);
      put(new THREE.Mesh(new THREE.CylinderGeometry(0.3, 0.2, 0.4, 10), glow('#fff3d6')), 0, 3, 0);
      r = 0.4;
    } else if (type === 'box') {
      put(this.box(1, 1, 1, std('#8a6a4a')), 0, 0.5, 0);
      put(this.box(0.8, 0.8, 0.8, std('#7a5a3a')), 0.3, 1.4, 0.1);
      r = 0.9;
    } else if (type === 'safe') {
      put(this.box(0.9, 1.1, 0.9, std('#2a2d33', { metalness: 0.7, roughness: 0.35 })), 0, 0.55, 0);
      put(new THREE.Mesh(new THREE.CylinderGeometry(0.12, 0.12, 0.05, 14), std('#c9a24a', { metalness: 0.8 })), 0, 0.7, 0.47).rotation.x = Math.PI / 2;
      r = 0.7;
    } else if (type === 'press') {
      const iron = std('#3a3d42', { metalness: 0.6, roughness: 0.5 });
      put(this.box(3.4, 1, 2, iron), 0, 0.5, 0);
      for (const z of [-0.5, 0.5]) {
        const roller = put(new THREE.Mesh(new THREE.CylinderGeometry(0.3, 0.3, 3.2, 14), metal), 0, 1.35, z);
        roller.rotation.z = Math.PI / 2;
      }
      put(new THREE.Mesh(new THREE.TorusGeometry(0.55, 0.06, 6, 18), std('#8a2a2a', { metalness: 0.5 })), 1.8, 1.3, 0).rotation.y = Math.PI / 2;
      put(this.box(2.6, 0.04, 1.4, std('#efe9dc')), 0, 1.02, 0);
      r = 2.1;
    } else if (type === 'seat') {
      const cloth = std('#2f4a6a', { roughness: 0.9 });
      put(this.box(1.3, 0.45, 0.6, cloth), 0, 0.3, 0);
      put(this.box(1.3, 0.8, 0.18, cloth), 0, 0.85, -0.3);
      put(this.box(1.3, 0.12, 0.2, std('#e8e2d4')), 0, 1.3, -0.3);
      r = 0.6;
    } else if (type === 'barcounter') {
      put(this.box(0.9, 1.05, 8, std('#4a2e1e', { roughness: 0.4 })), 0, 0.52, 0);
      put(this.box(1, 0.06, 8.1, std('#c9a24a', { metalness: 0.7, roughness: 0.3 })), 0, 1.07, 0);
      for (let k = -3; k <= 3; k += 1.5) put(new THREE.Mesh(new THREE.CylinderGeometry(0.06, 0.06, 0.25, 8), glow(k > 0 ? '#7ad7a0' : '#ffb36b')), -0.2, 1.22, k);
      r = 0;
      for (let k = -3.5; k <= 3.5; k += 1) this.colliders.push({ x: px, z: pz + k, r: 0.55 });
    } else if (type === 'stool') {
      put(new THREE.Mesh(new THREE.CylinderGeometry(0.04, 0.04, 0.75, 6), metal), 0, 0.38, 0);
      put(new THREE.Mesh(new THREE.CylinderGeometry(0.2, 0.2, 0.07, 12), std('#7a2a2a')), 0, 0.76, 0);
      r = 0.3;
    } else if (type === 'bartable') {
      put(new THREE.Mesh(new THREE.CylinderGeometry(0.45, 0.45, 0.05, 14), wood), 0, 0.75, 0);
      put(new THREE.Mesh(new THREE.CylinderGeometry(0.05, 0.05, 0.75, 6), metal), 0, 0.38, 0);
      r = 0.5;
    } else if (type === 'bunk') {
      for (const y of [0.4, 1.5]) {
        put(this.box(0.8, 0.15, 3.4, std('#5a4a3a')), 0, y, 0);
        put(this.box(0.75, 0.12, 3.3, std('#e9e4da')), 0, y + 0.12, 0);
      }
      r = 0;
    } else if (type === 'mailboxes') {
      put(this.box(0.4, 1.2, 2.4, std('#6b5a3a', { metalness: 0.3 })), 0, 1.3, 0);
      for (let k = 0; k < 6; k++) put(this.box(0.02, 0.3, 0.7, std('#c9a24a', { metalness: 0.7 })), 0.21, 1.05 + (k % 2) * 0.45, -0.8 + Math.floor(k / 2) * 0.8);
      r = 0.6;
    } else if (type === 'stairs') {
      for (let k = 0; k < 7; k++) put(this.box(3, 0.22, 0.6, wood), 0, 0.11 + k * 0.22, -1.8 + k * 0.6);
      put(this.box(0.08, 1, 4.2, dark), 1.5, 1.4, 0);
      r = 2.2;
    } else if (type === 'lamp') {
      put(new THREE.Mesh(new THREE.CylinderGeometry(0.03, 0.03, 1.6, 6), dark), 0, 0.8, 0);
      put(new THREE.Mesh(new THREE.ConeGeometry(0.3, 0.35, 12, 1, true), glow('#ffd59a')), 0, 1.7, 0);
      r = 0.3;
    } else if (type === 'bike') {
      for (const sx of [-0.55, 0.55]) {
        const w = put(new THREE.Mesh(new THREE.TorusGeometry(0.33, 0.04, 6, 16), dark), sx, 0.35, 0);
        w.rotation.y = Math.PI / 2;
      }
      put(this.box(1.1, 0.06, 0.06, std('#7a2a2a', { metalness: 0.6 })), 0, 0.65, 0);
      r = 0.7;
    } else if (type === 'rug') {
      const m = put(new THREE.Mesh(new THREE.PlaneGeometry(3.6, 2.4), std('#6a2e2e', { roughness: 1 })), 0, 0.015, 0);
      m.rotation.x = -Math.PI / 2;
      m.castShadow = false;
    } else if (type === 'lowtable') {
      put(this.box(1.4, 0.06, 0.8, wood), 0, 0.42, 0);
      put(this.box(1.2, 0.4, 0.6, dark), 0, 0.2, 0);
      r = 0.8;
    } else if (type === 'table') {
      put(this.box(1.6, 0.07, 1.1, wood), 0, 0.76, 0);
      for (const [sx, sz] of [[-0.7, -0.45], [0.7, -0.45], [-0.7, 0.45], [0.7, 0.45]]) put(this.box(0.06, 0.76, 0.06, wood), sx, 0.38, sz);
      put(new THREE.Mesh(new THREE.CylinderGeometry(0.05, 0.04, 0.1, 10), std('#f2efe6')), -0.3, 0.85, 0.1);
      put(new THREE.Mesh(new THREE.CylinderGeometry(0.05, 0.04, 0.1, 10), std('#f2efe6')), 0.3, 0.85, -0.1);
      r = 1;
    } else if (type === 'chair' || type === 'oldchair') {
      const c = type === 'oldchair' ? std('#4a3a2a') : wood;
      put(this.box(0.5, 0.06, 0.5, c), 0, 0.46, 0);
      put(this.box(0.5, 0.6, 0.06, c), 0, 0.78, -0.24);
      for (const [sx, sz] of [[-0.22, -0.22], [0.22, -0.22], [-0.22, 0.22], [0.22, 0.22]]) put(this.box(0.04, 0.46, 0.04, c), sx, 0.23, sz);
      r = 0.4;
    } else if (type === 'counter') {
      put(this.box(5, 0.9, 0.8, std('#e6e1d6')), 0, 0.45, 0);
      put(this.box(5, 0.05, 0.85, std('#2a2a2e', { roughness: 0.3 })), 0, 0.92, 0);
      put(new THREE.Mesh(new THREE.CylinderGeometry(0.18, 0.18, 0.02, 14), dark), -1.2, 0.95, 0);
      r = 1.4;
    } else if (type === 'fridge') {
      put(this.box(0.8, 1.9, 0.8, std('#e8ecef', { roughness: 0.3 })), 0, 0.95, 0);
      r = 0.6;
    } else if (type === 'bed') {
      put(this.box(2.2, 0.45, 3, wood), 0, 0.23, 0);
      put(this.box(2.1, 0.2, 2.9, std('#e9e4da')), 0, 0.55, 0);
      put(this.box(2.1, 0.08, 1.9, std('#7a2e3a')), 0, 0.68, 0.45);
      put(this.box(0.9, 0.18, 0.5, std('#f4f1ea')), -0.5, 0.72, -1.15);
      put(this.box(0.9, 0.18, 0.5, std('#f4f1ea')), 0.5, 0.72, -1.15);
      r = 1.6;
    } else if (type === 'wardrobe') {
      put(this.box(2, 2.3, 0.7, std('#4a3524')), 0, 1.15, 0);
      r = 1.1;
    } else if (type === 'trunk') {
      put(this.box(1.4, 0.7, 0.8, std('#5a3a22')), 0, 0.35, 0);
      put(this.box(1.42, 0.08, 0.82, std('#a8853a', { metalness: 0.6 })), 0, 0.55, 0);
      r = 0.9;
    } else if (type === 'mannequin') {
      put(new THREE.Mesh(new THREE.CylinderGeometry(0.03, 0.2, 1, 8), dark), 0, 0.5, 0);
      put(new THREE.Mesh(new THREE.CylinderGeometry(0.22, 0.18, 0.7, 10), std('#c9b8a0')), 0, 1.3, 0);
      r = 0.4;
    } else if (type === 'barrels') {
      for (const [sx, sz] of [[0, 0], [0.9, 0.3], [0.3, 1]]) put(new THREE.Mesh(new THREE.CylinderGeometry(0.4, 0.4, 0.9, 12), std('#6a4a2a')), sx, 0.45, sz);
      r = 1.2;
    } else if (type === 'boiler') {
      put(new THREE.Mesh(new THREE.CylinderGeometry(0.6, 0.6, 2, 14), metal), 0, 1, 0);
      const l = put(new THREE.Mesh(new THREE.SphereGeometry(0.06, 6, 4), glow('#ff5a3a')), 0, 1.3, 0.61);
      this.blinks.push({ m: l, t: 0, slow: true });
      r = 0.8;
    } else if (type === 'ticketmachine') {
      put(this.box(0.7, 1.7, 1, std('#2a5a9a', { metalness: 0.4 })), 0, 0.85, 0);
      const s = put(new THREE.Mesh(new THREE.PlaneGeometry(0.6, 0.45), glow('#9fe0ff')), 0.36, 1.25, 0);
      s.rotation.y = Math.PI / 2;
      r = 0.7;
    } else if (type === 'guichet') {
      put(this.box(1.2, 1.1, 4, std('#3a3f4a')), 0, 0.55, 0);
      put(this.box(0.06, 1.2, 4, new THREE.MeshStandardMaterial({ color: '#9fd8ff', transparent: true, opacity: 0.25 })), -0.3, 1.7, 0);
      r = 0.9;
      for (const dz of [-1.4, 1.4]) this.colliders.push({ x: px + Math.sin(rot) * dz, z: pz + Math.cos(rot) * dz, r: 0.9 });
    } else if (type === 'bench') {
      put(this.box(2.4, 0.08, 0.5, wood), 0, 0.45, 0);
      put(this.box(2.4, 0.5, 0.06, wood), 0, 0.75, -0.22);
      for (const sx of [-1, 1]) put(this.box(0.06, 0.45, 0.45, dark), sx, 0.22, 0);
      r = 1.1;
    } else if (type === 'pillar') {
      put(this.box(0.8, 2.9, 0.8, std('#e8e2d4')), 0, 1.45, 0);
      put(this.box(0.84, 0.3, 0.84, std('#2a5a9a')), 0, 2.2, 0);
      r = 0.6;
    } else if (type === 'vending') {
      put(this.box(0.9, 1.9, 0.8, std('#9a2a2a')), 0, 0.95, 0);
      const s = put(new THREE.Mesh(new THREE.PlaneGeometry(0.6, 1.2), glow('#ffe6b0')), 0, 1.1, 0.41);
      s.castShadow = false;
      r = 0.7;
    } else if (type === 'phonebooth') {
      put(this.box(1.1, 2.3, 1.1, std('#2a3f6a', { metalness: 0.3 })), 0, 1.15, 0);
      put(new THREE.Mesh(new THREE.PlaneGeometry(0.8, 0.25), new THREE.MeshBasicMaterial({
        map: signTexture('TÉLÉPHONE', { fg: '#ffffff', bg: '#2a3f6a', w: 256, h: 64, font: 'bold 34px Arial, sans-serif', glow: false }),
      })), 0, 2.1, 0.56);
      r = 0.8;
    } else if (type === 'metromap') {
      put(new THREE.Mesh(new THREE.PlaneGeometry(2.4, 1.4), new THREE.MeshBasicMaterial({
        map: signTexture('M  ·  1 · 2 · 3 · 4 · 5 · 6', { fg: '#ffffff', bg: '#2a5a9a', w: 512, h: 300, font: 'bold 40px Arial, sans-serif', glow: false }),
      })), 0, 1.6, 0.05);
    }
    g.rotation.y = rot;
    this.add(g, px, 0, pz, r);
  }

  /** Metro tracks along x at z: a dark trench with rails, and a train that comes and goes. */
  track(x0, x1, z) {
    const len = x1 - x0;
    const cx = (x0 + x1) / 2;
    const pit = new THREE.Mesh(new THREE.PlaneGeometry(len, 5), std('#111216', { roughness: 0.95 }));
    pit.rotation.x = -Math.PI / 2;
    pit.position.set(cx, 0.01, z);
    this.scene.add(pit);
    const steel = std('#9aa0a8', { metalness: 0.8, roughness: 0.3 });
    for (const dz of [-0.75, 0.75]) {
      const rail = this.box(len, 0.08, 0.1, steel, false);
      rail.position.set(cx, 0.06, z + dz);
      this.scene.add(rail);
    }
    for (let x = x0 + 0.5; x < x1; x += 1.2) {
      const tie = this.box(0.25, 0.05, 2.2, std('#3a2e24'), false);
      tie.position.set(x, 0.03, z);
      this.scene.add(tie);
    }
    // Yellow safety lines along both platforms.
    for (const dz of [-2.4, 2.4]) {
      const line = new THREE.Mesh(new THREE.PlaneGeometry(len, 0.18), new THREE.MeshBasicMaterial({ color: '#e8c33a' }));
      line.rotation.x = -Math.PI / 2;
      line.position.set(cx, 0.025, z + dz);
      this.scene.add(line);
    }
    // The train.
    const train = new THREE.Group();
    const body = std('#c8ccd2', { metalness: 0.5, roughness: 0.35 });
    const stripe = std('#d13b2f', { roughness: 0.5 });
    for (let k = 0; k < 3; k++) {
      const car = this.box(9, 2.7, 2.6, body);
      car.position.set(k * 9.4, 1.55, 0);
      train.add(car);
      const band = this.box(9.02, 0.3, 2.62, stripe, false);
      band.position.set(k * 9.4, 1.0, 0);
      train.add(band);
      for (const side of [-1, 1]) {
        for (let w = -3; w <= 3; w += 2) {
          const win = new THREE.Mesh(new THREE.PlaneGeometry(1.4, 0.8), new THREE.MeshBasicMaterial({ color: '#ffe9b0' }));
          win.position.set(k * 9.4 + w, 1.95, side * 1.31);
          if (side < 0) win.rotation.y = Math.PI;
          train.add(win);
        }
      }
    }
    // The train is only seen between the two tunnel mouths.
    const clip = [new THREE.Plane(new THREE.Vector3(1, 0, 0), -x0), new THREE.Plane(new THREE.Vector3(-1, 0, 0), x1)];
    train.traverse((m) => { if (m.material) { m.material = m.material.clone(); m.material.clippingPlanes = clip; } });
    for (const tx of [x0, x1]) {
      const mouth = this.box(0.6, 3.4, 5.4, std('#16181d'), false);
      mouth.position.set(tx, 1.7, z);
      this.scene.add(mouth);
    }
    train.position.set(x1 + 40, 0, z);
    this.scene.add(train);
    this.train = { group: train, x0: x0 - 40, x1: x1 + 40, t: 6, stop: cx - 9.4 };
  }

  addClue(word, x, z) {
    const g = new THREE.Group();
    const glint = new THREE.Sprite(new THREE.SpriteMaterial({ map: glowTexture('rgba(255,235,170,0.95)'), depthWrite: false, blending: THREE.AdditiveBlending }));
    glint.scale.setScalar(0.9);
    glint.position.y = 0.5;
    g.add(glint);
    const ring = new THREE.Mesh(
      new THREE.RingGeometry(0.45, 0.55, 24),
      new THREE.MeshBasicMaterial({ color: '#ffd27a', transparent: true, opacity: 0.6, side: THREE.DoubleSide, depthWrite: false }),
    );
    ring.rotation.x = -Math.PI / 2;
    ring.position.y = 0.05;
    g.add(ring);
    const beam = new THREE.Mesh(
      new THREE.CylinderGeometry(0.07, 0.16, 5, 8, 1, true),
      new THREE.MeshBasicMaterial({ color: '#ffd27a', transparent: true, opacity: 0.35, depthWrite: false, blending: THREE.AdditiveBlending, side: THREE.DoubleSide }),
    );
    beam.position.y = 2.5;
    g.add(beam);
    g.position.set(x, 0, z);
    this.scene.add(g);
    const c = { word, group: g, glint, ring, beam, taken: false, t: Math.random() * 6 };
    this.clues.push(c);
    return c;
  }

  takeClue(c) {
    c.taken = true;
    c.group.visible = false;
  }

  walkable(x, z) {
    const [x0, x1, z0, z1] = this.L.bounds;
    if (x < x0 + 0.5 || x > x1 - 0.5 || z < z0 + 0.5 || z > z1 - 0.5) return false;
    if ((this.L.holes || []).some(([a, b, c, d]) => x > a && x < b && z > c && z < d)) return false;
    return !this.L.walls.some((seg) => distToSegment(x, z, seg) < 0.5);
  }

  heightAt() {
    return 0;
  }

  update(dt) {
    this.time += dt;
    for (const s of this.passing || []) {
      s.position.z += dt * 24;
      if (s.position.z > 60) s.position.z -= 120;
    }
    const tr = this.train;
    if (tr) {
      // Comes in, stops 8 seconds, leaves, and comes back a little later.
      tr.t += dt;
      const cycle = tr.t % 34;
      const g = tr.group.position;
      if (cycle < 6) g.x = tr.stop + (1 - cycle / 6) ** 2 * (tr.x1 - tr.stop);
      else if (cycle < 14) g.x = tr.stop;
      else if (cycle < 20) g.x = tr.stop - ((cycle - 14) / 6) ** 2 * (tr.stop - tr.x0);
      else g.x = tr.x1 + 20;
    }
    for (const b of this.blinks) {
      b.t += dt;
      b.m.visible = b.slow ? Math.sin(b.t * 2) > -0.6 : Math.sin(b.t * 7 + b.t * b.t * 0.01) > -0.2;
    }
    for (const c of this.clues) {
      if (c.taken) continue;
      c.t += dt;
      c.glint.scale.setScalar(0.7 + Math.sin(c.t * 4) * 0.25);
      c.ring.scale.setScalar(1 + Math.sin(c.t * 2.5) * 0.15);
      c.beam.material.opacity = 0.22 + Math.sin(c.t * 2) * 0.1;
    }
  }
}

void rand;
