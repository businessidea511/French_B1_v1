// Inside buildings, at night: rooms, corridors, low walls (the camera looks
// from above), furniture, and cold office light.
// Two layouts: « lumen » (Lumen's headquarters, chapter 4) and « studio »
// (the Télé Bruxelles TV station, chapter 5).
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
    }
    g.rotation.y = rot;
    this.add(g, px, 0, pz, r);
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
    return !this.L.walls.some((seg) => distToSegment(x, z, seg) < 0.5);
  }

  heightAt() {
    return 0;
  }

  update(dt) {
    this.time += dt;
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
