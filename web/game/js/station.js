// La Gare du Midi, late at night: a big hall with iron columns, the departure
// board, the ticket office, the lockers, a café, and platform 3 with the
// last train to Liège waiting under cold lights.
import * as THREE from 'three';
import { std, rand, glowTexture, signTexture } from './city.js';

/** Large polished floor tiles, drawn once. */
function tileTexture() {
  const c = document.createElement('canvas');
  c.width = c.height = 512;
  const x = c.getContext('2d');
  const r = rand(5);
  for (let i = 0; i < 8; i++) {
    for (let j = 0; j < 8; j++) {
      const l = 0.82 + r() * 0.18;
      const base = (i + j) % 2 ? [92, 88, 82] : [118, 112, 104];
      x.fillStyle = `rgb(${base.map((v) => Math.round(v * l)).join(',')})`;
      x.fillRect(i * 64, j * 64, 64, 64);
    }
  }
  x.strokeStyle = 'rgba(20,20,20,0.6)';
  x.lineWidth = 2;
  for (let k = 0; k <= 8; k++) {
    x.beginPath(); x.moveTo(k * 64, 0); x.lineTo(k * 64, 512); x.stroke();
    x.beginPath(); x.moveTo(0, k * 64); x.lineTo(512, k * 64); x.stroke();
  }
  const tex = new THREE.CanvasTexture(c);
  tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.anisotropy = 4;
  return tex;
}

/** The departure board: yellow letters on black, like the old split-flap boards. */
function boardTexture(blinkRow) {
  const c = document.createElement('canvas');
  c.width = 1024;
  c.height = 384;
  const x = c.getContext('2d');
  x.fillStyle = '#07080a';
  x.fillRect(0, 0, 1024, 384);
  x.fillStyle = '#ffd34d';
  x.font = 'bold 40px "Courier New", monospace';
  x.fillText('DÉPARTS · VERTREK', 30, 52);
  x.fillStyle = '#9a8a5a';
  x.fillRect(30, 66, 964, 3);
  const rows = [
    ['23:50', 'LIÈGE-GUILLEMINS', '3', ''],
    ['23:55', 'ANVERS-CENTRAL', '1', 'SUPPRIMÉ'],
    ['00:10', 'LILLE-FLANDRES', '5', '+15 MIN'],
    ['00:25', 'NAMUR', '2', ''],
    ['00:40', 'CHARLEROI', '4', ''],
  ];
  x.font = 'bold 38px "Courier New", monospace';
  rows.forEach((row, i) => {
    const y = 120 + i * 56;
    x.fillStyle = i === blinkRow ? '#fff3c4' : '#ffd34d';
    x.fillText(row[0], 30, y);
    x.fillText(row[1], 170, y);
    x.fillText(row[2], 690, y);
    x.fillStyle = '#ff6b4d';
    x.fillText(row[3], 760, y);
  });
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

/** The station clock: 23:40. */
function clockTexture() {
  const c = document.createElement('canvas');
  c.width = c.height = 256;
  const x = c.getContext('2d');
  x.fillStyle = '#f4efe2';
  x.beginPath(); x.arc(128, 128, 122, 0, Math.PI * 2); x.fill();
  x.strokeStyle = '#1a1a1a';
  x.lineWidth = 8;
  x.stroke();
  for (let i = 0; i < 12; i++) {
    const a = (i / 12) * Math.PI * 2;
    x.lineWidth = i % 3 ? 4 : 9;
    x.beginPath();
    x.moveTo(128 + Math.sin(a) * 96, 128 - Math.cos(a) * 96);
    x.lineTo(128 + Math.sin(a) * 112, 128 - Math.cos(a) * 112);
    x.stroke();
  }
  const hand = (angle, len, w) => {
    x.lineWidth = w;
    x.beginPath();
    x.moveTo(128, 128);
    x.lineTo(128 + Math.sin(angle) * len, 128 - Math.cos(angle) * len);
    x.stroke();
  };
  hand(((11 + 40 / 60) / 12) * Math.PI * 2, 58, 9); // hour hand: 23:40
  hand((40 / 60) * Math.PI * 2, 92, 6);
  x.strokeStyle = '#c0392b';
  hand((40 / 60) * Math.PI * 2 + 0.6, 98, 2);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

export class Station {
  constructor(scene, { weak }) {
    this.scene = scene;
    this.weak = weak;
    this.time = 0;
    this.colliders = [];
    this.clues = [];
    this.flicker = [];
    this.occluders = [];
    // The intro camera: from the entrance, slowly into the hall.
    this.cinema = [0, 9, 21, -0.5, 0, 4, -2];
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
    this.scene.background = new THREE.Color('#0a0c12');
    this.scene.fog = new THREE.Fog('#0d1018', 22, 70);
    this.buildHall();
    this.buildBoard();
    this.buildTicketOffice();
    this.buildLockers();
    this.buildCafe();
    this.buildBenches();
    this.buildPlatform();
  }

  // ---------- the hall ----------
  buildHall() {
    const tiles = tileTexture();
    tiles.repeat.set(9, 7);
    const floor = new THREE.Mesh(new THREE.PlaneGeometry(36, 28), std('#ffffff', { map: tiles, roughness: 0.28, metalness: 0.25 }));
    floor.rotation.x = -Math.PI / 2;
    floor.position.set(0, 0, 8);
    floor.receiveShadow = true;
    this.scene.add(floor);

    const stone = std('#5a4a3e', { roughness: 0.95 });
    // Walls: west, east, south (with the entrance), and the high roof.
    const west = this.box(0.6, 14, 28, stone);
    west.position.set(-18.3, 7, 8);
    const east = west.clone();
    east.position.x = 18.3;
    this.scene.add(west, east);
    this.occluders.push(west, east);
    for (const x of [-11.5, 11.5]) {
      const s = this.box(13, 14, 0.6, stone);
      s.position.set(x, 7, 22.3);
      this.scene.add(s);
      this.occluders.push(s);
    }
    const lintel = this.box(10, 7, 0.6, stone);
    lintel.position.set(0, 10.5, 22.3);
    this.scene.add(lintel);
    this.occluders.push(lintel);
    // The entrance: rain outside, behind glass doors.
    const outside = new THREE.Mesh(new THREE.PlaneGeometry(10, 7), new THREE.MeshBasicMaterial({ color: '#1b2a44' }));
    outside.position.set(0, 3.5, 22.6);
    outside.rotation.y = Math.PI;
    this.scene.add(outside);
    for (let i = -2; i <= 2; i++) {
      const frame = this.box(0.12, 7, 0.12, std('#1d2026', { metalness: 0.7, roughness: 0.4 }), false);
      frame.position.set(i * 2.5, 3.5, 22.1);
      this.scene.add(frame);
    }
    // Tall arched windows (dark night behind).
    const winMat = new THREE.MeshBasicMaterial({ color: '#16233a' });
    for (const z of [2, 10, 18]) {
      for (const x of [-17.95, 17.95]) {
        const w = new THREE.Mesh(new THREE.PlaneGeometry(4, 7), winMat);
        w.position.set(x, 8, z);
        w.rotation.y = x < 0 ? Math.PI / 2 : -Math.PI / 2;
        this.scene.add(w);
      }
    }
    // Roof: iron beams over a dark glass roof.
    const roof = new THREE.Mesh(new THREE.PlaneGeometry(37, 29), std('#0e1118', { roughness: 0.6 }));
    roof.rotation.x = Math.PI / 2;
    roof.position.set(0, 14, 8);
    this.scene.add(roof);
    const iron = std('#2a2e36', { metalness: 0.8, roughness: 0.35 });
    for (let z = -5; z <= 21; z += 4.3) {
      const beam = this.box(36.6, 0.4, 0.3, iron, false);
      beam.position.set(0, 13.6, z);
      this.scene.add(beam);
    }
    // Iron columns.
    for (const x of [-9, 9]) {
      for (const z of [-2, 7, 16]) {
        const col = new THREE.Mesh(new THREE.CylinderGeometry(0.28, 0.36, 13.6, 10), iron);
        col.castShadow = !this.weak;
        this.add(col, x, 6.8, z, 0.5);
        const base = new THREE.Mesh(new THREE.CylinderGeometry(0.55, 0.6, 0.6, 10), iron);
        this.add(base, x, 0.3, z);
      }
    }
    // Hanging lamps: cold white light pools on the floor.
    for (const [x, z] of [[-5, 2], [5, 2], [-5, 12], [5, 12], [0, 18], [-13, 8], [13, 8]]) {
      const cable = this.box(0.03, 5, 0.03, iron, false);
      cable.position.set(x, 11.5, z);
      this.scene.add(cable);
      const shade = new THREE.Mesh(new THREE.ConeGeometry(0.6, 0.5, 12, 1, true), std('#2a2e36', { side: THREE.DoubleSide, metalness: 0.6 }));
      shade.position.set(x, 8.9, z);
      this.scene.add(shade);
      const bulb = new THREE.Mesh(new THREE.SphereGeometry(0.2, 8, 6), new THREE.MeshBasicMaterial({ color: '#e8f1ff' }));
      bulb.position.set(x, 8.7, z);
      this.scene.add(bulb);
      const pool = new THREE.Mesh(
        new THREE.CircleGeometry(4, 24),
        new THREE.MeshBasicMaterial({ map: glowTexture('rgba(210,225,255,0.42)'), transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }),
      );
      pool.rotation.x = -Math.PI / 2;
      pool.position.set(x, 0.02, z);
      this.scene.add(pool);
    }
    // The big clock.
    const clock = new THREE.Mesh(new THREE.CircleGeometry(1.4, 32), new THREE.MeshBasicMaterial({ map: clockTexture() }));
    clock.position.set(0, 11.2, -5.6);
    this.scene.add(clock);
  }

  // ---------- departures ----------
  buildBoard() {
    // The north wall, with the gate to the platforms below the board.
    const wall = std('#4a3e34', { roughness: 0.95 });
    for (const x of [-10.5, 10.5]) {
      const w = this.box(15, 14, 0.6, wall);
      w.position.set(x, 7, -6.3);
      this.scene.add(w);
      this.occluders.push(w);
    }
    const top = this.box(6, 7.5, 0.6, wall);
    top.position.set(0, 10.25, -6.3);
    this.scene.add(top);
    this.occluders.push(top);
    this.boardTex = [boardTexture(-1), boardTexture(0)];
    this.board = new THREE.Mesh(new THREE.PlaneGeometry(9, 3.4), new THREE.MeshBasicMaterial({ map: this.boardTex[0] }));
    this.board.position.set(-8.5, 7.6, -5.95);
    this.scene.add(this.board);
    const frame = this.box(9.4, 3.8, 0.2, std('#111318', { metalness: 0.6 }), false);
    frame.position.set(-8.5, 7.6, -6.05);
    this.scene.add(frame);
    // Ticket barriers on both sides of the inspector's gap.
    const metal = std('#7d848e', { metalness: 0.8, roughness: 0.3 });
    for (let x = -8; x <= 8; x += 1.6) {
      if (Math.abs(x) < 1.5) continue;
      const gate = this.box(0.25, 1.05, 1.1, metal);
      gate.position.set(x, 0.52, -5.2);
      this.scene.add(gate);
    }
    const voie = new THREE.Mesh(new THREE.PlaneGeometry(2.6, 0.7), new THREE.MeshBasicMaterial({
      map: signTexture('VOIE 3 →', { fg: '#ffffff', bg: '#1f4f9c', w: 256, h: 64, font: 'bold 40px Arial, sans-serif', glow: false }),
    }));
    voie.position.set(0, 4.6, -5.95);
    this.scene.add(voie);
  }

  buildTicketOffice() {
    // West wall: GUICHETS, two windows, warm light.
    const wood = std('#4a2e1e', { roughness: 0.7 });
    const counter = this.box(1.2, 1.15, 8, wood);
    counter.position.set(-16.6, 0.58, 6);
    this.scene.add(counter);
    this.colliders.push({ x: -16.6, z: 3, r: 1.2 }, { x: -16.6, z: 6, r: 1.2 }, { x: -16.6, z: 9, r: 1.2 });
    const glass = new THREE.Mesh(new THREE.PlaneGeometry(7.6, 2), new THREE.MeshBasicMaterial({ color: '#ffd9a0', transparent: true, opacity: 0.55 }));
    glass.position.set(-17.2, 2.3, 6);
    glass.rotation.y = Math.PI / 2;
    this.scene.add(glass);
    const sign = new THREE.Mesh(new THREE.PlaneGeometry(4, 0.8), new THREE.MeshBasicMaterial({
      map: signTexture('GUICHETS · LOKETTEN', { fg: '#ffffff', bg: '#1f4f9c', font: 'bold 44px Arial, sans-serif', glow: false }),
    }));
    sign.position.set(-17.9, 4.2, 6);
    sign.rotation.y = Math.PI / 2;
    this.scene.add(sign);
  }

  buildLockers() {
    // East wall: grey lockers, numbered. Number 7 is the one.
    const metal = std('#6f7782', { metalness: 0.7, roughness: 0.4 });
    const dark = std('#2b3038', { metalness: 0.5, roughness: 0.5 });
    const doors = [];
    let n = 1;
    for (let col = 0; col < 7; col++) {
      for (let row = 0; row < 3; row++) {
        doors.push({ z: 1.5 + col * 1.15, y: 0.6 + row * 1.1, n: n++ });
      }
    }
    const body = this.box(0.9, 3.4, 8.4, dark);
    body.position.set(17.5, 1.7, 5);
    this.scene.add(body);
    this.colliders.push({ x: 17.2, z: 2, r: 1.1 }, { x: 17.2, z: 5, r: 1.1 }, { x: 17.2, z: 8, r: 1.1 });
    for (const d of doors) {
      const door = this.box(0.06, 1.0, 1.05, d.n === 7 ? std('#8a7a5a', { metalness: 0.7, roughness: 0.35 }) : metal, false);
      door.position.set(17.03, d.y, d.z);
      this.scene.add(door);
      const label = new THREE.Mesh(new THREE.PlaneGeometry(0.3, 0.2), new THREE.MeshBasicMaterial({
        map: signTexture(String(d.n), { fg: '#111', bg: '#e8e2d0', w: 64, h: 48, font: 'bold 34px Arial, sans-serif', glow: false }),
      }));
      label.position.set(16.99, d.y + 0.3, d.z);
      label.rotation.y = -Math.PI / 2;
      this.scene.add(label);
      if (d.n === 7) this.locker7 = door;
    }
    const sign = new THREE.Mesh(new THREE.PlaneGeometry(3, 0.7), new THREE.MeshBasicMaterial({
      map: signTexture('CASIERS · LOCKERS', { fg: '#ffffff', bg: '#1f4f9c', font: 'bold 44px Arial, sans-serif', glow: false }),
    }));
    sign.position.set(17.95, 4.4, 5);
    sign.rotation.y = -Math.PI / 2;
    this.scene.add(sign);
  }

  buildCafe() {
    // Café « Le Quai », south-west corner, warm and nearly closed.
    const wood = std('#5a3a24', { roughness: 0.6 });
    const counter = this.box(5, 1.1, 1.2, wood);
    counter.position.set(-13, 0.55, 18.5);
    this.scene.add(counter);
    this.colliders.push({ x: -14.5, z: 18.5, r: 1.2 }, { x: -11.5, z: 18.5, r: 1.2 });
    const back = new THREE.Mesh(new THREE.PlaneGeometry(6, 3), new THREE.MeshBasicMaterial({ color: '#ffb46b' }));
    back.position.set(-13, 2.2, 21.9);
    back.rotation.y = Math.PI;
    this.scene.add(back);
    const sign = new THREE.Mesh(new THREE.PlaneGeometry(3.4, 0.8), new THREE.MeshBasicMaterial({ map: signTexture('Le Quai', { fg: '#ff9a5a' }), transparent: true }));
    sign.position.set(-13, 4.2, 21.9);
    sign.rotation.y = Math.PI;
    this.scene.add(sign);
    const halo = new THREE.Sprite(new THREE.SpriteMaterial({ map: glowTexture('rgba(255,140,80,0.35)'), depthWrite: false }));
    halo.position.set(-13, 4.2, 21.6);
    halo.scale.set(7, 2.6, 1);
    this.scene.add(halo);
    this.flicker.push({ halo, t: 0 });
    for (const [x, z] of [[-14, 13], [-10.5, 13.5]]) {
      const t = new THREE.Group();
      const top = this.box(0.9, 0.05, 0.9, std('#9aa0a8', { metalness: 0.7, roughness: 0.3 }));
      top.position.y = 0.75;
      t.add(top);
      const leg = this.box(0.07, 0.75, 0.07, std('#30333a'));
      leg.position.y = 0.37;
      t.add(leg);
      this.add(t, x, 0, z, 0.8);
    }
  }

  buildBenches() {
    const wood = std('#4a3424', { roughness: 0.7 });
    const iron = std('#22252b', { metalness: 0.6 });
    for (const z of [5, 9.5]) {
      for (const x of [-4.5, 4.5]) {
        const b = new THREE.Group();
        const seat = this.box(5, 0.1, 0.6, wood);
        seat.position.y = 0.48;
        b.add(seat);
        const back = this.box(5, 0.5, 0.08, wood);
        back.position.set(0, 0.8, -0.28);
        b.add(back);
        for (const lx of [-2.2, 2.2]) {
          const leg = this.box(0.08, 0.48, 0.5, iron, false);
          leg.position.set(lx, 0.24, 0);
          b.add(leg);
        }
        this.add(b, x, 0, z);
        this.colliders.push({ x: x - 1.6, z, r: 0.8 }, { x, z, r: 0.8 }, { x: x + 1.6, z, r: 0.8 });
      }
    }
  }

  // ---------- platform 3 and the train ----------
  buildPlatform() {
    const concrete = std('#5d5f63', { roughness: 0.9 });
    const plat = this.box(6, 1, 36, concrete, false);
    plat.position.set(0, -0.5, -24.5);
    this.scene.add(plat);
    for (const x of [-2.85, 2.85]) {
      const line = this.box(0.25, 0.02, 36, std('#e8c33a'), false);
      line.position.set(x, 0.01, -24.5);
      this.scene.add(line);
    }
    // Tracks on both sides, below the platform.
    const bed = std('#24221f', { roughness: 1 });
    const steel = std('#9aa2ac', { metalness: 0.9, roughness: 0.3 });
    for (const cx of [-6.2, 6.2]) {
      const ground = this.box(6.4, 0.2, 40, bed, false);
      ground.position.set(cx, -1.1, -24.5);
      this.scene.add(ground);
      for (const dx of [-0.75, 0.75]) {
        const rail = this.box(0.1, 0.12, 40, steel, false);
        rail.position.set(cx + dx, -0.95, -24.5);
        this.scene.add(rail);
      }
    }
    // The train on the east track: long carriages with lit windows.
    const paint = std('#5c1f24', { roughness: 0.45, metalness: 0.4 });
    for (let k = 0; k < 2; k++) {
      const car = this.box(3.2, 3.6, 17, paint);
      car.position.set(6.2, 1.0, -15 - k * 17.6);
      this.scene.add(car);
      const roofTop = this.box(3, 0.3, 17, std('#2a2d33', { metalness: 0.5 }), false);
      roofTop.position.set(6.2, 2.95, -15 - k * 17.6);
      this.scene.add(roofTop);
      for (let w = 0; w < 7; w++) {
        const win = new THREE.Mesh(new THREE.PlaneGeometry(1.5, 0.9), new THREE.MeshBasicMaterial({ color: k === 0 && w === 3 ? '#fff0c8' : '#ffd38f' }));
        win.position.set(4.58, 1.6, -21.5 + w * 2.1 - k * 17.6);
        win.rotation.y = -Math.PI / 2;
        this.scene.add(win);
      }
      const num = new THREE.Mesh(new THREE.PlaneGeometry(0.8, 0.8), new THREE.MeshBasicMaterial({
        map: signTexture(k === 0 ? '8' : '9', { fg: '#ffffff', bg: '#1a1a1a', w: 128, h: 128, font: 'bold 90px Arial, sans-serif', glow: false }),
      }));
      num.position.set(4.57, 2.4, -9 - k * 17.6);
      num.rotation.y = -Math.PI / 2;
      this.scene.add(num);
    }
    // Platform lamps.
    for (let z = -10; z > -42; z -= 8) {
      const post = this.box(0.12, 4.2, 0.12, std('#2a2e36', { metalness: 0.7 }), false);
      post.position.set(-2.2, 2.1, z);
      this.scene.add(post);
      const lamp = new THREE.Mesh(new THREE.BoxGeometry(1.4, 0.15, 0.3), new THREE.MeshBasicMaterial({ color: '#e8f1ff' }));
      lamp.position.set(-1.6, 4.2, z);
      this.scene.add(lamp);
      const pool = new THREE.Mesh(
        new THREE.CircleGeometry(3, 20),
        new THREE.MeshBasicMaterial({ map: glowTexture('rgba(210,225,255,0.4)'), transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }),
      );
      pool.rotation.x = -Math.PI / 2;
      pool.position.set(-1, 0.03, z);
      this.scene.add(pool);
    }
  }

  // ---------- clues ----------
  addClue(word, x, z) {
    const g = new THREE.Group();
    const glint = new THREE.Sprite(new THREE.SpriteMaterial({ map: glowTexture('rgba(255,235,170,0.95)'), depthWrite: false, blending: THREE.AdditiveBlending }));
    glint.scale.setScalar(0.9);
    glint.position.y = 0.35;
    g.add(glint);
    const ring = new THREE.Mesh(
      new THREE.RingGeometry(0.45, 0.55, 24),
      new THREE.MeshBasicMaterial({ color: '#ffd27a', transparent: true, opacity: 0.6, side: THREE.DoubleSide, depthWrite: false }),
    );
    ring.rotation.x = -Math.PI / 2;
    ring.position.y = 0.05;
    g.add(ring);
    // A thin column of light, seen from far away (over cars and benches).
    const beam = new THREE.Mesh(
      new THREE.CylinderGeometry(0.07, 0.16, 7, 8, 1, true),
      new THREE.MeshBasicMaterial({ color: '#ffd27a', transparent: true, opacity: 0.35, depthWrite: false, blending: THREE.AdditiveBlending, side: THREE.DoubleSide }),
    );
    beam.position.y = 3.5;
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

  // ---------- walking ----------
  /** The platform is behind the inspector's gate: open only when the story says so. */
  walkable(x, z) {
    const hall = x > -17.4 && x < 17.4 && z > -4.6 && z < 21.5;
    const gap = x > -1.3 && x < 1.3 && z > -6.6 && z <= -4.6 && this.gateOpen;
    const platform = x > -2.7 && x < 2.7 && z > -42 && z <= -6.6 && this.gateOpen;
    return hall || gap || platform;
  }

  heightAt() {
    return 0;
  }

  /** The camera stays inside the hall (never behind a wall). */
  clampCamera(v) {
    if (v.z > -6) {
      v.z = Math.min(v.z, 21.4);
      v.x = Math.max(-17, Math.min(17, v.x));
    } else {
      v.x = Math.max(-2.6, Math.min(2.6, v.x)); // on the platform: above it, not inside the train
    }
    v.y = Math.min(v.y, 12.5);
  }

  update(dt) {
    this.time += dt;
    // The departure board blinks on the Liège line.
    const blink = Math.floor(this.time * 1.5) % 2;
    if (blink !== this.lastBlink) {
      this.lastBlink = blink;
      this.board.material.map = this.boardTex[blink];
    }
    for (const f of this.flicker) {
      f.t += dt;
      f.halo.material.opacity = 0.8 + Math.sin(f.t * 2) * 0.12;
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
