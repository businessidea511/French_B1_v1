// Liège at night: a grid of streets (three by three crossroads) around the
// Place du Marché, the small station Liège-Palais in the south, the pizzeria,
// the night shop, and the bookshop « Le Phénix » in the north-east corner.
// Built with the same houses, lamps and rain as Brussels (City).
import * as THREE from 'three';
import { City, std, glowTexture, signTexture, cobbleTexture } from './city.js';

export const LINES_X = [-30, 0, 30]; // streets running north–south
export const LINES_Z = [-30, 0, 30]; // streets running east–west
const EDGE = 37; // the town ends here
const HALF = 6.6; // half the width of a street with its sidewalks

export class Liege extends City {
  constructor(scene, opts) {
    super(scene, opts);
    this.cinema = [0, 13, 36, -0.75, 0, 3, 14];
  }

  build() {
    this.occluders = [];
    this.buildSky();
    this.buildGrid();
    this.buildRows();
    this.buildHouses();
    this.buildPlaces();
    this.buildRain();
  }

  // ---------- streets ----------
  buildGrid() {
    const road = cobbleTexture('#141518', '#3a3c42');
    road.repeat.set(4, 40);
    const roadMat = std('#ffffff', { map: road, roughness: 0.55, metalness: 0.15 });
    const walk = cobbleTexture('#2a2a2e', '#55565c', 256);
    walk.repeat.set(2, 30);
    const walkMat = std('#ffffff', { map: walk, roughness: 0.7 });
    const len = EDGE * 2;
    for (const z of LINES_Z) {
      const r = new THREE.Mesh(new THREE.PlaneGeometry(len, 8), roadMat);
      r.rotation.x = -Math.PI / 2;
      r.position.set(0, 0.004, z);
      r.receiveShadow = true;
      this.scene.add(r);
      for (const side of [-1, 1]) {
        const s = new THREE.Mesh(new THREE.PlaneGeometry(len, 2.8), walkMat);
        s.rotation.x = -Math.PI / 2;
        s.position.set(0, 0.002, z + side * 5.4);
        this.scene.add(s);
      }
    }
    for (const x of LINES_X) {
      const r = new THREE.Mesh(new THREE.PlaneGeometry(8, len), roadMat);
      r.rotation.x = -Math.PI / 2;
      r.position.set(x, 0.006, 0);
      r.receiveShadow = true;
      this.scene.add(r);
      for (const side of [-1, 1]) {
        const s = new THREE.Mesh(new THREE.PlaneGeometry(2.8, len), walkMat);
        s.rotation.x = -Math.PI / 2;
        s.position.set(x + side * 5.4, 0.003, 0);
        this.scene.add(s);
      }
    }
    // White lines at the crossroads, and lamps along every street.
    const paint = new THREE.MeshBasicMaterial({ color: '#c9c9c0' });
    for (const x of LINES_X) {
      for (const z of LINES_Z) {
        for (const [dx, dz, w, d] of [[0, -4.8, 7, 0.5], [0, 4.8, 7, 0.5], [-4.8, 0, 0.5, 7], [4.8, 0, 0.5, 7]]) {
          const line = new THREE.Mesh(new THREE.PlaneGeometry(w, d), paint);
          line.rotation.x = -Math.PI / 2;
          line.position.set(x + dx, 0.01, z + dz);
          this.scene.add(line);
        }
      }
    }
    for (const z of LINES_Z) for (let x = -24; x <= 24; x += 16) this.lamp(x, z - 4.4);
    for (const x of LINES_X) for (let z = -20; z <= 20; z += 20) this.lamp(x + 4.4, z + 6);
    // Puddles.
    const puddleMat = std('#05070b', { roughness: 0.05, metalness: 0.6, transparent: true, opacity: 0.85 });
    for (const [x, z] of [[-14, 1], [12, -29], [2, 18], [-29, -12], [29, 14], [-8, 31], [18, 1.5], [1, -16]]) {
      const p = new THREE.Mesh(new THREE.CircleGeometry(1 + ((x * 7) % 5 + 5) / 10, 14), puddleMat);
      p.rotation.x = -Math.PI / 2;
      p.position.set(x, 0.015, z);
      this.scene.add(p);
    }
  }

  /** Houses on both sides of every street, between the crossroads, and at the town's edges. */
  buildRows() {
    let seed = 30;
    const segments = (lines) => {
      const out = [];
      const cuts = [-EDGE, ...lines.flatMap((s) => [s - 7.2, s + 7.2]), EDGE];
      for (let i = 0; i < cuts.length; i += 2) if (cuts[i + 1] - cuts[i] > 3) out.push([cuts[i], cuts[i + 1]]);
      return out;
    };
    for (const z of LINES_Z) {
      for (const [a, b] of segments(LINES_X)) {
        this.row(a, z - 7.2, b, z - 7.2, 0, seed++); // north side, facing south
        this.row(a, z + 7.2, b, z + 7.2, Math.PI, seed++); // south side, facing north
      }
    }
    for (const x of LINES_X) {
      for (const [a, b] of segments(LINES_Z)) {
        this.row(x - 7.2, a, x - 7.2, b, Math.PI / 2, seed++); // west side, facing east
        this.row(x + 7.2, a, x + 7.2, b, -Math.PI / 2, seed++); // east side, facing west
      }
    }
    // Ends of the streets: houses across them (the station takes the south end of the middle street).
    for (const z of LINES_Z) {
      this.row(-EDGE - 0.2, z - 7, -EDGE - 0.2, z + 7, Math.PI / 2, seed++);
      this.row(EDGE + 0.2, z - 7, EDGE + 0.2, z + 7, -Math.PI / 2, seed++);
    }
    for (const x of LINES_X) {
      this.row(x - 7, -EDGE - 0.2, x + 7, -EDGE - 0.2, 0, seed++);
      if (x !== 0) this.row(x - 7, EDGE + 0.2, x + 7, EDGE + 0.2, Math.PI, seed++);
    }
  }

  shopSign(text, x, y, z, angle, opts) {
    const s = new THREE.Mesh(new THREE.PlaneGeometry(3.4, 0.8), new THREE.MeshBasicMaterial({ map: signTexture(text, opts), transparent: true }));
    s.position.set(x, y, z);
    s.rotation.y = angle;
    this.scene.add(s);
    const halo = new THREE.Sprite(new THREE.SpriteMaterial({ map: glowTexture(opts.halo || 'rgba(255,170,90,0.35)'), depthWrite: false }));
    halo.position.set(x + Math.sin(angle) * 0.2, y, z + Math.cos(angle) * 0.2);
    halo.scale.set(6, 2.4, 1);
    this.scene.add(halo);
    this.flicker.push({ halo, sign: s, base: 1, t: Math.random() * 10 });
  }

  shopWindow(x, z, angle, color) {
    const glow = new THREE.Mesh(new THREE.PlaneGeometry(4.6, 2.2), new THREE.MeshBasicMaterial({ color }));
    glow.position.set(x, 1.4, z);
    glow.rotation.y = angle;
    this.scene.add(glow);
  }

  buildPlaces() {
    // The station Liège-Palais, at the south end of the middle street.
    const hall = this.box(16, 10, 6, std('#6b5a48', { roughness: 0.9 }));
    hall.position.set(0, 5, EDGE + 3.2);
    this.scene.add(hall);
    this.occluders.push(hall);
    const glass = new THREE.Mesh(new THREE.PlaneGeometry(8, 4), new THREE.MeshBasicMaterial({ color: '#ffe0a8' }));
    glass.position.set(0, 2.4, EDGE + 0.15);
    glass.rotation.y = Math.PI;
    this.scene.add(glass);
    this.shopSign('LIÈGE-PALAIS', 0, 6.4, EDGE + 0.1, Math.PI, { fg: '#ffffff', bg: '#1f4f9c', halo: 'rgba(90,150,255,0.35)', font: 'bold 52px Arial, sans-serif' });

    // The night shop (west side of the middle street), the pizzeria (east side).
    this.shopSign('Épicerie de nuit', -6.95, 3.4, 14, Math.PI / 2, { fg: '#8ff0a8', halo: 'rgba(90,255,150,0.3)' });
    this.shopWindow(-6.97, 14, Math.PI / 2, '#d9ffe0');
    this.shopSign('Pizza Meuse', 6.95, 3.4, 12, -Math.PI / 2, { fg: '#ff8a4d', halo: 'rgba(255,120,60,0.4)' });
    this.shopWindow(6.97, 12, -Math.PI / 2, '#ffc28a');

    // The bookshop « Le Phénix », north-east corner (north side of the north street).
    this.shopSign('Librairie Le Phénix', 24, 3.5, -36.95, 0, { fg: '#ffd27a', halo: 'rgba(255,200,110,0.35)' });
    this.shopWindow(24, -36.97, 0, '#ffd9a0');

    // A café on the west street, and the Place du Marché sign.
    this.shopSign('Café du Pont', -23.05, 3.4, -14, -Math.PI / 2, { fg: '#ffb46b' });
    this.shopWindow(-23.03, -14, -Math.PI / 2, '#ffb46b');
    const place = new THREE.Mesh(new THREE.PlaneGeometry(2.6, 0.5), new THREE.MeshBasicMaterial({
      map: signTexture('Place du Marché', { fg: '#ffffff', bg: '#1d3b5c', w: 512, h: 96, font: 'bold 50px Georgia, serif', glow: false }),
    }));
    place.position.set(-6.95, 2.8, -9.5);
    place.rotation.y = Math.PI / 2;
    this.scene.add(place);

    // Parked cars along the streets (not on the chase route's middle).
    this.car(-3.1, 22, '#2b3a55');
    this.car(-27, -18, '#3a3d42', Math.PI);
    this.car(33.1, 18, '#5a1f24');
  }

  walkable(x, z) {
    if (Math.abs(x) > EDGE - 0.4 || Math.abs(z) > EDGE - 0.4) return false;
    return LINES_Z.some((s) => Math.abs(z - s) < HALF) || LINES_X.some((s) => Math.abs(x - s) < HALF);
  }

  heightAt() {
    return 0;
  }
}
