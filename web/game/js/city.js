// Brussels at night: « Rue des Ombres » and the « Place du Vieux Marché ».
// Rain, fog, street lamps, cobblestones, narrow houses with stepped gables.
// Houses, windows and doors are instanced (one draw each), so the whole
// street stays light enough for older phones.
import * as THREE from 'three';

export const std = (color, extra = {}) => new THREE.MeshStandardMaterial({ color, roughness: 0.9, metalness: 0, ...extra });

export function rand(seed) {
  return () => {
    seed |= 0;
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** Cobblestones drawn on a canvas once, repeated on the ground. */
export function cobbleTexture(base, stone, size = 512) {
  const c = document.createElement('canvas');
  c.width = c.height = size;
  const x = c.getContext('2d');
  x.fillStyle = base;
  x.fillRect(0, 0, size, size);
  const r = rand(3);
  const s = size / 16;
  for (let row = 0; row < 16; row++) {
    for (let col = 0; col < 16; col++) {
      const off = row % 2 ? s / 2 : 0;
      const l = 0.85 + r() * 0.3;
      x.fillStyle = shade(stone, l);
      const px = col * s + off + 2;
      const py = row * s + 2;
      x.beginPath();
      if (x.roundRect) x.roundRect(px, py, s - 4, s - 4, 5);
      else x.rect(px, py, s - 4, s - 4); // older phones
      x.fill();
    }
  }
  const tex = new THREE.CanvasTexture(c);
  tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.anisotropy = 4;
  return tex;
}

export function shade(hex, k) {
  const c = new THREE.Color(hex).multiplyScalar(k);
  return `#${c.getHexString()}`;
}

/** A soft round glow texture (lamp light on wet stones, neon halos). */
export function glowTexture(color) {
  const c = document.createElement('canvas');
  c.width = c.height = 128;
  const x = c.getContext('2d');
  const g = x.createRadialGradient(64, 64, 0, 64, 64, 64);
  g.addColorStop(0, color);
  g.addColorStop(1, 'rgba(0,0,0,0)');
  x.fillStyle = g;
  x.fillRect(0, 0, 128, 128);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

/** Text on a sign, glowing like neon or painted. */
export function signTexture(text, { fg = '#ffd27a', bg = '#1a1410', font = 'bold 54px Georgia, serif', w = 512, h = 128, glow = true } = {}) {
  const c = document.createElement('canvas');
  c.width = w;
  c.height = h;
  const x = c.getContext('2d');
  x.fillStyle = bg;
  x.fillRect(0, 0, w, h);
  x.font = font;
  x.textAlign = 'center';
  x.textBaseline = 'middle';
  if (glow) {
    x.shadowColor = fg;
    x.shadowBlur = 18;
  }
  x.fillStyle = fg;
  x.fillText(text, w / 2, h / 2 + 4);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

const WALL_COLORS = ['#7a4a3a', '#8a6a4a', '#5f5a55', '#6d5040', '#4f5866', '#7d6b55', '#5a4038', '#8b7a66', '#6a5a52', '#3f4a52'];

export class City {
  constructor(scene, { weak }) {
    this.scene = scene;
    this.weak = weak;
    this.time = 0;
    this.colliders = [];
    this.clues = [];
    this.flicker = [];
    this.houses = []; // [x, z, angle, width, height, color, depth]
    this.occluders = []; // what can hide the player from the camera
    this.build();
  }

  add(obj, x, y, z, r = 0) {
    obj.position.set(x, y, z);
    this.scene.add(obj);
    if (r) this.colliders.push({ x, z, r });
    return obj;
  }

  box(w, h, d, material, cast = true, receive = true) {
    const m = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), material);
    m.castShadow = cast && !this.weak;
    m.receiveShadow = receive;
    return m;
  }

  build() {
    this.buildSky();
    this.buildGround();
    this.buildRows();
    this.buildHouses();
    this.buildShops();
    this.buildStreetLife();
    this.buildSquare();
    this.buildRain();
  }

  // ---------- sky and air ----------
  buildSky() {
    const sky = new THREE.Mesh(
      new THREE.SphereGeometry(300, 24, 12),
      new THREE.ShaderMaterial({
        side: THREE.BackSide,
        depthWrite: false,
        fog: false,
        vertexShader: 'varying vec3 vP; void main(){ vP = position; gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0); }',
        fragmentShader:
          'varying vec3 vP; void main(){ float h = clamp(normalize(vP).y, 0.0, 1.0);' +
          ' vec3 c = mix(vec3(0.16,0.17,0.22), vec3(0.03,0.04,0.08), pow(h, 0.5)); gl_FragColor = vec4(c, 1.0); }',
      }),
    );
    this.scene.add(sky);
    this.scene.fog = new THREE.Fog('#141824', 18, 75);
    // The moon behind the clouds.
    const moon = new THREE.Sprite(new THREE.SpriteMaterial({ map: glowTexture('rgba(210,220,255,0.9)'), fog: false, depthWrite: false }));
    moon.scale.setScalar(30);
    moon.position.set(-60, 90, -160);
    this.scene.add(moon);
  }

  // ---------- ground ----------
  buildGround() {
    const road = cobbleTexture('#141518', '#3a3c42');
    road.repeat.set(4, 26);
    const roadMat = std('#ffffff', { map: road, roughness: 0.55, metalness: 0.15 });
    const street = new THREE.Mesh(new THREE.PlaneGeometry(8, 56), roadMat);
    street.rotation.x = -Math.PI / 2;
    street.position.set(0, 0, 12);
    street.receiveShadow = true;
    this.scene.add(street);

    const square = cobbleTexture('#17181b', '#46484e');
    square.repeat.set(22, 16);
    const plaza = new THREE.Mesh(new THREE.PlaneGeometry(44, 32), std('#ffffff', { map: square, roughness: 0.6, metalness: 0.1 }));
    plaza.rotation.x = -Math.PI / 2;
    plaza.position.set(0, 0.005, -29.5);
    plaza.receiveShadow = true;
    this.scene.add(plaza);

    // Sidewalks (a little higher), with kerbs.
    const walk = cobbleTexture('#2a2a2e', '#55565c', 256);
    walk.repeat.set(2, 28);
    const walkMat = std('#ffffff', { map: walk, roughness: 0.7 });
    for (const x of [-5.5, 5.5]) {
      const s = this.box(3, 0.14, 54, walkMat, false);
      s.position.set(x, 0.07, 13);
      this.scene.add(s);
      const kerb = this.box(0.18, 0.16, 54, std('#6b6d72'), false);
      kerb.position.set(x > 0 ? 4.05 : -4.05, 0.08, 13);
      this.scene.add(kerb);
    }
    // The alley: dark, wet.
    const alley = new THREE.Mesh(new THREE.PlaneGeometry(10, 3.2), std('#101114', { roughness: 0.4, metalness: 0.2 }));
    alley.rotation.x = -Math.PI / 2;
    alley.position.set(-11.5, 0.02, 10);
    this.scene.add(alley);

    // Tram rails down the street.
    const rail = std('#8d939c', { metalness: 0.9, roughness: 0.3 });
    for (const x of [-0.75, 0.75]) {
      const r = this.box(0.08, 0.02, 56, rail, false);
      r.position.set(x, 0.012, 12);
      this.scene.add(r);
    }

    // Puddles that catch the lamplight.
    const puddleMat = std('#05070b', { roughness: 0.05, metalness: 0.6, transparent: true, opacity: 0.85 });
    const r = rand(11);
    for (let i = 0; i < 14; i++) {
      const p = new THREE.Mesh(new THREE.CircleGeometry(0.6 + r() * 0.9, 14), puddleMat);
      p.rotation.x = -Math.PI / 2;
      p.scale.set(1, 0.6 + r() * 0.5, 1);
      const inSquare = i > 7;
      p.position.set(inSquare ? -18 + r() * 36 : -3.3 + r() * 6.6, 0.02, inSquare ? -16 - r() * 26 : 36 - r() * 48);
      this.scene.add(p);
    }
  }

  // ---------- the rows of houses ----------
  row(x0, z0, x1, z1, angle, seed, skip = []) {
    const r = rand(seed);
    const len = Math.hypot(x1 - x0, z1 - z0);
    const dx = (x1 - x0) / len;
    const dz = (z1 - z0) / len;
    let u = 0;
    while (u < len - 2) {
      const w = Math.min(4.6 + r() * 2.6, len - u);
      const mid = u + w / 2;
      const cx = x0 + dx * mid;
      const cz = z0 + dz * mid;
      if (!skip.some(([a, b]) => mid > a && mid < b)) {
        this.houses.push({ x: cx, z: cz, angle, w: w - 0.08, h: 9 + r() * 6, color: WALL_COLORS[Math.floor(r() * WALL_COLORS.length)], d: 7, gable: r() < 0.75, seed: r() });
      }
      u += w;
    }
  }

  buildRows() {
    // Street: west side (faces east, +x), east side (faces west).
    this.row(-7.2, 40, -7.2, 11.9, Math.PI / 2, 1); // the alley opens at z 8.3–11.7
    this.row(-7.2, 8.1, -7.2, -14.2, Math.PI / 2, 9);
    this.row(7.2, 40, 7.2, -14.2, -Math.PI / 2, 2);
    // Square: north, west, east, and the south corners.
    this.row(-23, -45, 23, -45, 0, 3);
    this.row(-21.8, -14, -21.8, -45, Math.PI / 2, 4);
    this.row(21.8, -14, 21.8, -45, -Math.PI / 2, 5);
    this.row(-21.8, -13.8, -7.2, -13.8, Math.PI, 6);
    this.row(7.2, -13.8, 21.8, -13.8, Math.PI, 7);
    // Far end of the street (beyond the taxi), seen through the fog.
    this.row(-7.2, 46, 7.2, 46, Math.PI, 8);
  }

  buildHouses() {
    const H = this.houses;
    const dummy = new THREE.Object3D();
    const n = H.length;
    const bodies = new THREE.InstancedMesh(new THREE.BoxGeometry(1, 1, 1), std('#ffffff', { roughness: 0.95 }), n);
    const roofs = new THREE.InstancedMesh(new THREE.BoxGeometry(1, 1, 1), std('#26272c', { roughness: 0.8 }), n);
    const steps = [];
    const lit = [];
    const dark = [];
    const doors = [];
    const sills = [];
    const color = new THREE.Color();
    const r = rand(21);
    H.forEach((h, i) => {
      const nx = Math.sin(h.angle);
      const nz = Math.cos(h.angle);
      const tx = Math.cos(h.angle);
      const tz = -Math.sin(h.angle);
      // Body: behind the front line.
      dummy.position.set(h.x - nx * h.d / 2, h.h / 2, h.z - nz * h.d / 2);
      dummy.rotation.set(0, h.angle, 0);
      dummy.scale.set(h.w, h.h, h.d);
      dummy.updateMatrix();
      bodies.setMatrixAt(i, dummy.matrix);
      bodies.setColorAt(i, color.set(h.color));
      // Roof slab.
      dummy.position.set(h.x - nx * (h.d / 2 + 0.3), h.h + 0.15, h.z - nz * (h.d / 2 + 0.3));
      dummy.scale.set(h.w + 0.1, 0.3, h.d - 0.4);
      dummy.updateMatrix();
      roofs.setMatrixAt(i, dummy.matrix);
      // Stepped gable on the front: the Brussels look.
      if (h.gable) {
        let sw = h.w;
        let y = h.h;
        for (let k = 0; k < 4; k++) {
          sw *= 0.74;
          const sh = 0.9;
          steps.push({ x: h.x - nx * 0.25, y: y + sh / 2, z: h.z - nz * 0.25, angle: h.angle, w: sw, h: sh, color: h.color });
          y += sh;
        }
      }
      // Windows: floors of 3 m, columns every ~1.6 m.
      const cols = Math.max(2, Math.floor(h.w / 1.6));
      const floors = Math.floor((h.h - 3) / 3);
      for (let f = 0; f < floors; f++) {
        for (let c = 0; c < cols; c++) {
          const u = -h.w / 2 + (c + 0.5) * (h.w / cols);
          const y = 4.4 + f * 3;
          const win = { x: h.x + tx * u + nx * 0.02, y, z: h.z + tz * u + nz * 0.02, angle: h.angle };
          (r() < 0.32 ? lit : dark).push(win);
          sills.push({ ...win, y: y - 0.75 });
        }
      }
      // Ground floor: a door, and a window.
      doors.push({ x: h.x + tx * (-h.w / 4) + nx * 0.03, y: 1.15, z: h.z + tz * (-h.w / 4) + nz * 0.03, angle: h.angle });
      (r() < 0.5 ? lit : dark).push({ x: h.x + tx * (h.w / 4) + nx * 0.02, y: 1.5, z: h.z + tz * (h.w / 4) + nz * 0.02, angle: h.angle, big: true });
    });
    bodies.instanceColor.needsUpdate = true;
    bodies.receiveShadow = true;
    bodies.castShadow = !this.weak;
    this.scene.add(bodies, roofs);
    this.occluders.push(bodies, roofs);

    const stepMesh = new THREE.InstancedMesh(new THREE.BoxGeometry(1, 1, 0.5), std('#ffffff', { roughness: 0.95 }), steps.length);
    steps.forEach((s, i) => {
      dummy.position.set(s.x, s.y, s.z);
      dummy.rotation.set(0, s.angle, 0);
      dummy.scale.set(s.w, s.h, 1);
      dummy.updateMatrix();
      stepMesh.setMatrixAt(i, dummy.matrix);
      stepMesh.setColorAt(i, color.set(s.color).multiplyScalar(0.92));
    });
    stepMesh.instanceColor.needsUpdate = true;
    this.scene.add(stepMesh);
    this.occluders.push(stepMesh);

    const panes = (list, material, w, h) => {
      const m = new THREE.InstancedMesh(new THREE.PlaneGeometry(1, 1), material, list.length);
      list.forEach((p, i) => {
        dummy.position.set(p.x, p.y, p.z);
        dummy.rotation.set(0, p.angle, 0);
        dummy.scale.set(p.big ? 1.6 : w, p.big ? 1.6 : h, 1);
        dummy.updateMatrix();
        m.setMatrixAt(i, dummy.matrix);
      });
      this.scene.add(m);
      return m;
    };
    panes(lit, new THREE.MeshBasicMaterial({ color: '#ffc27a' }), 0.9, 1.4);
    panes(dark, std('#0d1118', { roughness: 0.15, metalness: 0.5 }), 0.9, 1.4);
    panes(doors, std('#2a1a12', { roughness: 0.6 }), 1.1, 2.3);
    panes(sills, std('#8a8378'), 1.1, 0.12);

    // Walls and lamps along the alley.
    const brick = std('#3d2a24', { roughness: 0.95 });
    for (const z of [8.3, 11.7]) {
      const wall = this.box(9, 6, 0.4, brick);
      wall.position.set(-11.7, 3, z);
      this.scene.add(wall);
      this.occluders.push(wall);
    }
    const end = this.box(0.4, 6, 3.8, brick);
    end.position.set(-16.2, 3, 10);
    this.scene.add(end);
    this.occluders.push(end);
    // A lamp on the alley wall: the alley is dark, but not black.
    const alleyLamp = new THREE.Mesh(new THREE.SphereGeometry(0.16, 8, 6), new THREE.MeshBasicMaterial({ color: '#ffd59a' }));
    alleyLamp.position.set(-15.8, 3.2, 10);
    this.scene.add(alleyLamp);
    const alleyLight = new THREE.PointLight('#ffb36b', 9, 9, 1.8);
    alleyLight.position.set(-15, 3.2, 10);
    this.scene.add(alleyLight);
    const alleyHalo = new THREE.Sprite(new THREE.SpriteMaterial({ map: glowTexture('rgba(255,190,110,0.5)'), depthWrite: false, blending: THREE.AdditiveBlending }));
    alleyHalo.position.set(-15.7, 3.2, 10);
    alleyHalo.scale.setScalar(2.2);
    this.scene.add(alleyHalo);
  }

  // ---------- shops and their signs ----------
  shopSign(text, x, y, z, angle, opts) {
    const s = new THREE.Mesh(new THREE.PlaneGeometry(3.2, 0.8), new THREE.MeshBasicMaterial({ map: signTexture(text, opts), transparent: true }));
    s.position.set(x, y, z);
    s.rotation.y = angle;
    this.scene.add(s);
    // A soft halo around neon.
    const halo = new THREE.Sprite(new THREE.SpriteMaterial({ map: glowTexture(opts.halo || 'rgba(255,170,90,0.35)'), depthWrite: false }));
    halo.position.set(x + Math.sin(angle) * 0.2, y, z + Math.cos(angle) * 0.2);
    halo.scale.set(6, 2.4, 1);
    this.scene.add(halo);
    this.flicker.push({ halo, sign: s, base: 1, t: Math.random() * 10 });
    return s;
  }

  buildShops() {
    // Café « Le Corbeau » (east side), with its terrace.
    this.shopSign('Le Corbeau', 6.95, 3.6, 20, -Math.PI / 2, { fg: '#ff8a4d', halo: 'rgba(255,120,60,0.4)' });
    const awning = this.box(1.6, 0.1, 6, std('#5a1e1e'));
    awning.position.set(6.3, 3.0, 20);
    awning.rotation.z = 0.25;
    this.scene.add(awning);
    const glow = new THREE.Mesh(new THREE.PlaneGeometry(5, 2.2), new THREE.MeshBasicMaterial({ color: '#ffb46b' }));
    glow.position.set(6.97, 1.4, 20);
    glow.rotation.y = -Math.PI / 2;
    this.scene.add(glow);
    for (const [z, chairs] of [[18, 2], [22, 2]]) {
      const t = new THREE.Group();
      const top = this.box(0.8, 0.05, 0.8, std('#9aa0a8', { metalness: 0.7, roughness: 0.3 }));
      top.position.y = 0.75;
      t.add(top);
      const leg = this.box(0.06, 0.75, 0.06, std('#30333a', { metalness: 0.6 }));
      leg.position.y = 0.37;
      t.add(leg);
      for (let c = 0; c < chairs; c++) {
        const chair = this.box(0.42, 0.06, 0.42, std('#4a2e20'));
        chair.position.set(0, 0.45, c ? 0.65 : -0.65);
        t.add(chair);
        const back = this.box(0.42, 0.45, 0.05, std('#4a2e20'));
        back.position.set(0, 0.7, c ? 0.88 : -0.88);
        t.add(back);
      }
      this.add(t, 5.4, 0.14, z, 0.8);
    }

    // Hôtel du Lion (east side, further north): vertical neon.
    const hotel = new THREE.Mesh(new THREE.PlaneGeometry(0.8, 3.6), new THREE.MeshBasicMaterial({
      map: signTexture('HÔTEL', { fg: '#7ad7ff', bg: '#0c1420', w: 128, h: 512, font: 'bold 70px Georgia, serif' }),
    }));
    hotel.position.set(6.6, 5.5, 2);
    hotel.rotation.y = -Math.PI / 2 + 0.6;
    this.scene.add(hotel);
    const hh = new THREE.Sprite(new THREE.SpriteMaterial({ map: glowTexture('rgba(110,200,255,0.35)'), depthWrite: false }));
    hh.position.set(6.3, 5.5, 2);
    hh.scale.set(3, 6, 1);
    this.scene.add(hh);
    this.flicker.push({ halo: hh, sign: hotel, base: 1, t: 3, broken: true });
    this.shopSign('Hôtel du Lion', 6.95, 3.2, 0, -Math.PI / 2, { fg: '#bfe9ff', halo: 'rgba(110,200,255,0.25)' });

    // Number 12: Élise's building (west side).
    const plaque = new THREE.Mesh(new THREE.PlaneGeometry(0.5, 0.5), new THREE.MeshBasicMaterial({
      map: signTexture('12', { fg: '#f2e6c8', bg: '#1d3b5c', w: 128, h: 128, font: 'bold 80px Georgia, serif', glow: false }),
    }));
    plaque.position.set(-7.15, 2.6, 25.2);
    plaque.rotation.y = Math.PI / 2;
    this.scene.add(plaque);
    const doorLight = new THREE.Mesh(new THREE.SphereGeometry(0.12, 8, 6), new THREE.MeshBasicMaterial({ color: '#ffd9a0' }));
    doorLight.position.set(-6.95, 2.9, 26.4);
    this.scene.add(doorLight);
  }

  // ---------- lamps, cars, bins ----------
  lamp(x, z) {
    const g = new THREE.Group();
    const metal = std('#1d2026', { metalness: 0.7, roughness: 0.4 });
    const post = new THREE.Mesh(new THREE.CylinderGeometry(0.06, 0.1, 4.2, 8), metal);
    post.position.y = 2.1;
    post.castShadow = !this.weak;
    g.add(post);
    const arm = this.box(0.6, 0.06, 0.06, metal, false);
    arm.position.set(x > 0 ? -0.3 : 0.3, 4.15, 0);
    g.add(arm);
    const lantern = new THREE.Mesh(new THREE.CylinderGeometry(0.16, 0.24, 0.42, 6), new THREE.MeshBasicMaterial({ color: '#ffd59a' }));
    lantern.position.set(x > 0 ? -0.6 : 0.6, 3.95, 0);
    g.add(lantern);
    this.add(g, x, 0.14, z, 0.25);
    // Light on the wet ground (a soft glow, cheap).
    const pool = new THREE.Mesh(
      new THREE.CircleGeometry(3.4, 24),
      new THREE.MeshBasicMaterial({ map: glowTexture('rgba(255,190,110,0.55)'), transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }),
    );
    pool.rotation.x = -Math.PI / 2;
    pool.position.set(x + (x > 0 ? -0.6 : 0.6), 0.17, z);
    this.scene.add(pool);
    const halo = new THREE.Sprite(new THREE.SpriteMaterial({ map: glowTexture('rgba(255,200,130,0.45)'), depthWrite: false, blending: THREE.AdditiveBlending }));
    halo.position.set(x + (x > 0 ? -0.6 : 0.6), 3.95, z);
    halo.scale.setScalar(2.4);
    this.scene.add(halo);
  }

  car(x, z, color, angle = 0) {
    const g = new THREE.Group();
    const paint = std(color, { roughness: 0.25, metalness: 0.6 });
    const body = this.box(1.8, 0.6, 4.2, paint);
    body.position.y = 0.55;
    g.add(body);
    const cab = this.box(1.6, 0.55, 2.2, std('#0b0e14', { roughness: 0.1, metalness: 0.8 }));
    cab.position.set(0, 1.1, -0.2);
    g.add(cab);
    for (const [wx, wz] of [[-0.85, 1.3], [0.85, 1.3], [-0.85, -1.3], [0.85, -1.3]]) {
      const wheel = new THREE.Mesh(new THREE.CylinderGeometry(0.34, 0.34, 0.25, 12), std('#0b0b0b'));
      wheel.rotation.z = Math.PI / 2;
      wheel.position.set(wx, 0.34, wz);
      g.add(wheel);
    }
    for (const s of [-0.6, 0.6]) {
      const tail = new THREE.Mesh(new THREE.BoxGeometry(0.3, 0.12, 0.05), new THREE.MeshBasicMaterial({ color: '#ff2a2a' }));
      tail.position.set(s, 0.7, -2.12);
      g.add(tail);
    }
    g.rotation.y = angle;
    this.add(g, x, 0, z);
    this.colliders.push({ x, z: z - 1.2, r: 1.1 }, { x, z: z + 1.2, r: 1.1 });
  }

  buildStreetLife() {
    for (let z = 36; z > -12; z -= 10) {
      this.lamp(-4.4, z);
      this.lamp(4.4, z - 5);
    }
    this.car(3.1, 30, '#2b3a55');
    this.car(3.1, 8, '#5a1f24');
    this.car(-3.1, -4, '#3a3d42', Math.PI);
    // A taxi at the end of the street: where you arrive.
    this.car(-2.6, 38.5, '#d9a93a', Math.PI);
    const taxi = new THREE.Mesh(new THREE.BoxGeometry(0.6, 0.2, 0.3), new THREE.MeshBasicMaterial({ color: '#fff3c4' }));
    taxi.position.set(-2.6, 1.5, 38.5);
    this.scene.add(taxi);
    // Bins and a phone box.
    for (const [x, z] of [[-6.2, 16], [6.2, 12], [-14.8, 9.3]]) {
      const bin = new THREE.Mesh(new THREE.CylinderGeometry(0.3, 0.26, 0.9, 10), std('#2d3a2d', { roughness: 0.6 }));
      bin.castShadow = !this.weak;
      this.add(bin, x, 0.6, z, 0.35);
    }
    const booth = new THREE.Group();
    const frame = this.box(1.1, 2.4, 1.1, std('#7a1c1c', { roughness: 0.5 }));
    frame.position.y = 1.2;
    booth.add(frame);
    const boothLight = new THREE.Mesh(new THREE.PlaneGeometry(0.8, 1.4), new THREE.MeshBasicMaterial({ color: '#fff0c8' }));
    boothLight.position.set(0, 1.3, 0.56);
    booth.add(boothLight);
    booth.rotation.y = Math.PI / 2;
    this.add(booth, -6, 0.14, 2, 0.8);
  }

  buildSquare() {
    // The statue: a figure on a stone pedestal, in a dry fountain.
    const stone = std('#6a6660', { roughness: 0.95 });
    const basin = new THREE.Mesh(new THREE.CylinderGeometry(3.2, 3.4, 0.6, 20), stone);
    basin.position.y = 0.3;
    basin.receiveShadow = true;
    this.add(basin, 0, 0, -28, 3.6);
    const ped = this.box(1.6, 2.4, 1.6, stone);
    ped.position.set(0, 1.8, -28);
    this.scene.add(ped);
    const bronze = std('#3d4a40', { roughness: 0.4, metalness: 0.6 });
    const fig = new THREE.Group();
    const body = new THREE.Mesh(new THREE.CylinderGeometry(0.35, 0.5, 2, 10), bronze);
    body.position.y = 1;
    fig.add(body);
    const head = new THREE.Mesh(new THREE.SphereGeometry(0.28, 10, 8), bronze);
    head.position.y = 2.25;
    fig.add(head);
    const arm = new THREE.Mesh(new THREE.CylinderGeometry(0.09, 0.09, 1.2, 6), bronze);
    arm.position.set(0.55, 1.8, 0);
    arm.rotation.z = -1;
    fig.add(arm);
    fig.position.set(0, 3, -28);
    fig.rotation.y = 0.4;
    fig.traverse((m) => { m.castShadow = !this.weak; });
    this.scene.add(fig);

    // The newspaper kiosk.
    const k = new THREE.Group();
    const hut = this.box(2.4, 2.4, 2, std('#1f3b2a', { roughness: 0.6 }));
    hut.position.y = 1.2;
    k.add(hut);
    const roof = new THREE.Mesh(new THREE.ConeGeometry(2.1, 0.9, 8), std('#173022', { roughness: 0.5, metalness: 0.3 }));
    roof.position.y = 2.85;
    k.add(roof);
    const window = new THREE.Mesh(new THREE.PlaneGeometry(1.8, 1), new THREE.MeshBasicMaterial({ color: '#ffe0a0' }));
    window.position.set(0, 1.4, 1.01);
    k.add(window);
    const mags = new THREE.Mesh(new THREE.PlaneGeometry(2, 0.6), new THREE.MeshBasicMaterial({
      map: signTexture('PRESSE · JOURNAUX', { fg: '#ffe9b0', bg: '#1f3b2a', font: 'bold 40px Georgia, serif' }),
    }));
    mags.position.set(0, 2.2, 1.02);
    k.add(mags);
    this.add(k, -12, 0, -20, 1.6);

    // Benches.
    for (const [x, z, a] of [[12, -24, -Math.PI / 2], [-6, -34, Math.PI / 2], [10, -36, 0]]) {
      const b = new THREE.Group();
      const seat = this.box(1.8, 0.08, 0.5, std('#4a3424'));
      seat.position.y = 0.45;
      b.add(seat);
      const back = this.box(1.8, 0.45, 0.06, std('#4a3424'));
      back.position.set(0, 0.75, -0.24);
      b.add(back);
      b.rotation.y = a;
      this.add(b, x, 0, z, 0.9);
    }
    for (const [x, z] of [[-16, -18], [16, -18], [-16, -40], [16, -40], [-6, -16], [6, -42]]) this.lamp(x, z);

    // The metro entrance: railings, stairs going down, the « M » sign.
    const metal = std('#2a2f38', { metalness: 0.7, roughness: 0.35 });
    const hole = new THREE.Mesh(new THREE.PlaneGeometry(2.6, 4), new THREE.MeshBasicMaterial({ color: '#030405' }));
    hole.rotation.x = -Math.PI / 2;
    hole.position.set(0, 0.02, -41.5);
    this.scene.add(hole);
    for (let i = 0; i < 6; i++) {
      const step = this.box(2.6, 0.12, 0.5, std('#3a3c40'), false);
      step.position.set(0, -0.1 - i * 0.25, -40 - i * 0.55);
      this.scene.add(step);
    }
    for (const x of [-1.4, 1.4]) {
      const rail = this.box(0.06, 0.9, 4, metal);
      rail.position.set(x, 0.6, -41.5);
      this.scene.add(rail);
      this.colliders.push({ x, z: -40.5, r: 0.4 }, { x, z: -42.5, r: 0.4 });
    }
    const back = this.box(2.9, 0.9, 0.06, metal);
    back.position.set(0, 0.6, -43.5);
    this.scene.add(back);
    const signPost = new THREE.Group();
    const pole = new THREE.Mesh(new THREE.CylinderGeometry(0.06, 0.06, 3, 8), metal);
    pole.position.y = 1.5;
    signPost.add(pole);
    const m = new THREE.Mesh(new THREE.BoxGeometry(0.8, 0.8, 0.12), new THREE.MeshBasicMaterial({
      map: signTexture('M', { fg: '#ffffff', bg: '#1f4f9c', w: 128, h: 128, font: 'bold 96px Arial, sans-serif', glow: false }),
    }));
    m.position.y = 3.2;
    signPost.add(m);
    this.add(signPost, 2.2, 0, -39.4, 0.3);
    const mh = new THREE.Sprite(new THREE.SpriteMaterial({ map: glowTexture('rgba(90,150,255,0.4)'), depthWrite: false }));
    mh.position.set(2.2, 3.2, -39.3);
    mh.scale.setScalar(2.4);
    this.scene.add(mh);
  }

  // ---------- rain ----------
  buildRain() {
    const count = this.weak ? 700 : 1800;
    const pos = new Float32Array(count * 6);
    this.rainSeeds = [];
    for (let i = 0; i < count; i++) {
      const x = (Math.random() - 0.5) * 40;
      const y = Math.random() * 18;
      const z = (Math.random() - 0.5) * 40;
      this.rainSeeds.push([x, y, z]);
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    this.rain = new THREE.LineSegments(geo, new THREE.LineBasicMaterial({ color: '#9fb2cc', transparent: true, opacity: 0.35 }));
    this.rain.frustumCulled = false;
    this.scene.add(this.rain);
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
    ring.position.y = 0.2;
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
  walkable(x, z) {
    const street = x > -6.6 && x < 6.6 && z > -14.5 && z < 39.6;
    const square = x > -21 && x < 21 && z > -43.6 && z < -14;
    const alley = x > -15.6 && x < -6 && z > 8.7 && z < 11.3;
    if (!(street || square || alley)) return false;
    // The metro stairs: only at the entrance.
    if (x > -1.4 && x < 1.4 && z < -40.2) return false;
    return true;
  }

  heightAt(x, z) {
    if (z > -14 && z < 40 && Math.abs(x) > 4.1 && Math.abs(x) < 7) return 0.14;
    return 0;
  }

  update(dt, focus) {
    this.time += dt;
    // Rain falls around the player.
    const p = this.rain.geometry.attributes.position.array;
    const fall = dt * 22;
    for (let i = 0; i < this.rainSeeds.length; i++) {
      const s = this.rainSeeds[i];
      s[1] -= fall;
      if (s[1] < 0) s[1] += 18;
      const x = focus.x + s[0];
      const z = focus.z + s[2];
      p[i * 6] = x;
      p[i * 6 + 1] = s[1];
      p[i * 6 + 2] = z;
      p[i * 6 + 3] = x + 0.05;
      p[i * 6 + 4] = s[1] + 0.55;
      p[i * 6 + 5] = z;
    }
    this.rain.geometry.attributes.position.needsUpdate = true;

    for (const f of this.flicker) {
      f.t += dt;
      let k = 0.85 + Math.sin(f.t * 2) * 0.1;
      if (f.broken && Math.sin(f.t * 7.3) > 0.93) k = 0.15; // a tired neon
      f.halo.material.opacity = k;
      f.sign.material.opacity = f.broken ? Math.max(0.35, k) : 1;
      f.sign.material.transparent = true;
    }
    for (const c of this.clues) {
      if (c.taken) continue;
      c.t += dt;
      const s = 0.7 + Math.sin(c.t * 4) * 0.25;
      c.glint.scale.setScalar(s);
      c.ring.scale.setScalar(1 + Math.sin(c.t * 2.5) * 0.15);
      c.beam.material.opacity = 0.22 + Math.sin(c.t * 2) * 0.1;
    }
  }
}
