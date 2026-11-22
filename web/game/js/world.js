// The Island of Light: a cartoon low-poly village built from simple shapes
// (nothing to download). Morgane stole the island's words, so everything
// starts almost grey; each word found gives its object, and a little of the
// whole island, its colours back.
import * as THREE from 'three';

const GREY = new THREE.Color();
const tmp = new THREE.Color();

/** Faceted look: every triangle gets its own flat normal. */
function flat(geo) {
  const g = geo.index ? geo.toNonIndexed() : geo;
  g.computeVertexNormals();
  return g;
}

export class World {
  constructor(scene, { weak, clear = [] }) {
    this.scene = scene;
    this.weak = weak;
    this.clear = clear; // [x, z, r]: places where no tree may grow
    this.time = 0;
    this.colliders = []; // {x, z, r}
    this.paintable = []; // materials with a base colour and a word key
    this.crystals = [];
    this.saturation = { world: 0.12 }; // current colour amount per key
    this.target = { world: 0.12 };
    this.bridgeOpen = false;
    this.materials = new Map();
    this.build();
  }

  // ---------- materials ----------
  mat(color, key = 'world', extra = {}) {
    const id = `${color}|${key}|${JSON.stringify(extra)}`;
    if (this.materials.has(id)) return this.materials.get(id);
    const m = new THREE.MeshLambertMaterial({ color, ...extra });
    m.userData.base = new THREE.Color(color);
    m.userData.key = key;
    this.paintable.push(m);
    this.materials.set(id, m);
    return m;
  }

  mesh(geo, color, key, { cast = true, receive = false, extra } = {}) {
    const m = new THREE.Mesh(flat(geo), this.mat(color, key, extra));
    m.castShadow = cast && !this.weak;
    m.receiveShadow = receive;
    return m;
  }

  add(obj, x, y, z, collide = 0) {
    obj.position.set(x, y, z);
    this.scene.add(obj);
    if (collide) this.colliders.push({ x, z, r: collide });
    return obj;
  }

  islandRadius(angle) {
    return 38 + 3 * Math.sin(3 * angle) + 2 * Math.cos(5 * angle + 1);
  }

  // ---------- building the island ----------
  build() {
    this.buildSky();
    this.buildSea();
    this.buildIsland();
    this.buildRiverAndBridge();
    this.buildDock();
    this.buildVillage();
    this.buildEast();
    this.buildNature();
    this.buildClouds();
  }

  buildSky() {
    this.skyUniforms = {
      top: { value: new THREE.Color('#5fb2ff') },
      bottom: { value: new THREE.Color('#ffe6c4') },
    };
    const sky = new THREE.Mesh(
      new THREE.SphereGeometry(400, 24, 12),
      new THREE.ShaderMaterial({
        side: THREE.BackSide,
        depthWrite: false,
        uniforms: this.skyUniforms,
        vertexShader: 'varying vec3 vP; void main(){ vP = position; gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0); }',
        fragmentShader:
          'uniform vec3 top; uniform vec3 bottom; varying vec3 vP; void main(){ float h = clamp(normalize(vP).y*1.6+0.15,0.0,1.0); gl_FragColor = vec4(mix(bottom, top, h),1.0); }',
      }),
    );
    this.skyBase = { top: new THREE.Color('#5fb2ff'), bottom: new THREE.Color('#ffe6c4') };
    this.scene.add(sky);
    this.scene.fog = new THREE.Fog('#ffe6c4', 70, 190);
  }

  buildSea() {
    const geo = new THREE.PlaneGeometry(420, 420, this.weak ? 40 : 70, this.weak ? 40 : 70);
    const mat = this.mat('#2fa7d9', 'world', { transparent: true, opacity: 0.92 });
    mat.onBeforeCompile = (shader) => {
      shader.uniforms.uTime = this.seaTime = { value: 0 };
      shader.vertexShader = 'uniform float uTime;\n' + shader.vertexShader.replace(
        '#include <begin_vertex>',
        `#include <begin_vertex>
         transformed.z += sin(position.x * 0.12 + uTime * 1.1) * 0.35 + cos(position.y * 0.15 + uTime * 0.9) * 0.3;`,
      );
    };
    const sea = new THREE.Mesh(geo, mat);
    sea.rotation.x = -Math.PI / 2;
    sea.position.y = -0.9;
    sea.receiveShadow = !this.weak;
    this.scene.add(sea);
  }

  islandShape(extra) {
    const shape = new THREE.Shape();
    const n = 64;
    for (let i = 0; i <= n; i++) {
      const a = (i / n) * Math.PI * 2;
      const r = this.islandRadius(a) + extra;
      const x = Math.cos(a) * r;
      const y = Math.sin(a) * r;
      i === 0 ? shape.moveTo(x, y) : shape.lineTo(x, y);
    }
    return shape;
  }

  buildIsland() {
    const layer = (extra, depth, color, y) => {
      const geo = new THREE.ExtrudeGeometry(this.islandShape(extra), { depth, bevelEnabled: false, curveSegments: 4 });
      const m = this.mesh(geo, color, 'world', { cast: false, receive: true });
      m.rotation.x = Math.PI / 2;
      m.position.y = y;
      this.scene.add(m);
    };
    layer(5, 6, '#e9cf8f', -0.25); // sand beach
    layer(0, 6, '#79bf5a', 0); // grass
    layer(8, 5, '#3b6f8f', -1.6); // shallow sea floor ring

    // A low hill on the east side, under the lighthouse.
    const hill = this.mesh(new THREE.CylinderGeometry(9, 15, 2.2, 12), '#6fb552', 'world', { cast: false, receive: true });
    this.add(hill, 25, -0.1, -14);

    // Paths: sandy ellipses linking dock, plaza, bridge.
    const path = (x, z, w, d, rot = 0) => {
      const p = this.mesh(new THREE.CylinderGeometry(1, 1, 0.06, 10), '#e8d7a4', 'world', { cast: false, receive: true });
      p.scale.set(w, 1, d);
      p.rotation.y = rot;
      this.add(p, x, 0.03, z);
    };
    path(-21, 24, 2, 6);
    path(-17, 15, 2, 6, -0.5);
    path(-12, 6, 2.2, 5, -0.3);
    path(-10, 1, 6, 6);
    path(-3, -2, 7, 2);
    path(14, -4, 3.5, 2);
    path(19, -5.5, 3, 2.4, 0.3);
  }

  buildRiverAndBridge() {
    const river = this.mesh(new THREE.BoxGeometry(5, 0.2, 100), '#38b6e8', 'world', { cast: false, receive: true });
    this.add(river, 8, 0.02, 0);
    for (const side of [-1, 1]) {
      const bank = this.mesh(new THREE.BoxGeometry(0.8, 0.35, 100), '#9a8a5a', 'world', { cast: false, receive: true });
      this.add(bank, 8 + side * 2.8, 0.05, 0);
    }

    const bridge = new THREE.Group();
    for (let i = 0; i < 9; i++) {
      const plank = this.mesh(new THREE.BoxGeometry(0.85, 0.22, 3.4), i % 2 ? '#b07a45' : '#c08852', 'pont', { receive: true });
      plank.position.set(-3.6 + i * 0.9, 0.45 + Math.sin((i / 8) * Math.PI) * 0.5, 0);
      bridge.add(plank);
    }
    for (const side of [-1, 1]) {
      for (let i = 0; i < 5; i++) {
        const post = this.mesh(new THREE.BoxGeometry(0.22, 1.1, 0.22), '#8a5a30', 'pont');
        post.position.set(-3.6 + i * 1.8, 1.0 + Math.sin((i / 4) * Math.PI) * 0.5, side * 1.6);
        bridge.add(post);
      }
      const rail = this.mesh(new THREE.BoxGeometry(7.6, 0.18, 0.18), '#8a5a30', 'pont');
      rail.position.set(0, 1.55, side * 1.6);
      bridge.add(rail);
    }
    this.add(bridge, 8, 0, -4);

    // The guard's barrier: rises when the bridge opens.
    this.gate = new THREE.Group();
    const pole = new THREE.Group();
    for (let i = 0; i < 6; i++) {
      const s = this.mesh(new THREE.BoxGeometry(0.6, 0.25, 0.25), i % 2 ? '#ffffff' : '#e8443a', 'pont');
      s.position.x = 0.3 + i * 0.6;
      pole.add(s);
    }
    pole.position.set(0, 1.1, 0);
    pole.rotation.y = -Math.PI / 2; // across the bridge entrance
    this.gate.add(pole);
    this.gatePole = pole;
    const base = this.mesh(new THREE.BoxGeometry(0.5, 1.2, 0.5), '#6b4a2a', 'pont');
    base.position.y = 0.6;
    this.gate.add(base);
    this.add(this.gate, 4.2, 0, -5.8);
  }

  buildDock() {
    for (let i = 0; i < 14; i++) {
      const plank = this.mesh(new THREE.BoxGeometry(3.4, 0.25, 0.9), i % 2 ? '#a8733f' : '#b98248', 'world', { receive: true });
      this.add(plank, -22, 0.15, 31 + i);
    }
    for (const x of [-23.9, -20.1]) {
      for (let i = 0; i < 4; i++) {
        const post = this.mesh(new THREE.CylinderGeometry(0.2, 0.2, 2.4, 6), '#7a5230', 'world');
        this.add(post, x, -0.3, 32 + i * 4);
      }
    }
    // The boat ("le bateau").
    const boat = new THREE.Group();
    const hull = this.mesh(new THREE.CylinderGeometry(1.6, 1.0, 6.5, 6, 1, false, 0, Math.PI), '#d9534f', 'bateau');
    hull.rotation.set(Math.PI / 2, 0, Math.PI);
    hull.position.y = 0.6;
    boat.add(hull);
    const deck = this.mesh(new THREE.BoxGeometry(2.9, 0.15, 6.2), '#c08852', 'bateau');
    deck.position.y = 0.62;
    boat.add(deck);
    const mast = this.mesh(new THREE.CylinderGeometry(0.12, 0.12, 6, 6), '#7a5230', 'bateau');
    mast.position.y = 3.6;
    boat.add(mast);
    const sailGeo = new THREE.BufferGeometry().setFromPoints([
      new THREE.Vector3(0, 6.3, 0), new THREE.Vector3(0, 1.4, 0), new THREE.Vector3(0, 1.4, 2.6),
    ]);
    const sail = new THREE.Mesh(sailGeo, this.mat('#fff7e0', 'bateau', { side: THREE.DoubleSide }));
    sailGeo.computeVertexNormals();
    sail.castShadow = !this.weak;
    boat.add(sail);
    const flag = this.mesh(new THREE.BoxGeometry(0.05, 0.5, 0.8), '#ffc94d', 'bateau');
    flag.position.set(0, 6.4, 0.45);
    boat.add(flag);
    this.boat = boat;
    this.add(boat, -26.2, -0.6, 39, 0);
    this.colliders.push({ x: -26.2, z: 37, r: 1.6 }, { x: -26.2, z: 41, r: 1.6 });
  }

  house(x, z, { wall, roof, door = '#7a4a2a', key = 'world', w = 4.4, d = 4, h = 3, rot = 0, sign } = {}) {
    const g = new THREE.Group();
    const body = this.mesh(new THREE.BoxGeometry(w, h, d), wall, key, { receive: true });
    body.position.y = h / 2;
    g.add(body);
    const roofMesh = this.mesh(new THREE.ConeGeometry(Math.max(w, d) * 0.78, 2.4, 4), roof, key);
    roofMesh.position.y = h + 1.15;
    roofMesh.rotation.y = Math.PI / 4;
    roofMesh.scale.set(w / Math.max(w, d), 1, d / Math.max(w, d));
    g.add(roofMesh);
    const doorMesh = this.mesh(new THREE.BoxGeometry(1.1, 1.9, 0.15), door, key);
    doorMesh.position.set(0, 0.95, d / 2 + 0.05);
    g.add(doorMesh);
    for (const sx of [-1, 1]) {
      const win = this.mesh(new THREE.BoxGeometry(0.8, 0.8, 0.12), '#fff1b8', key, { cast: false });
      win.position.set(sx * w * 0.3, h * 0.6, d / 2 + 0.05);
      g.add(win);
    }
    const chimney = this.mesh(new THREE.BoxGeometry(0.6, 1.4, 0.6), '#9a8f86', key);
    chimney.position.set(w * 0.25, h + 1.4, -d * 0.15);
    g.add(chimney);
    if (sign) {
      const s = this.signBoard(sign, '#7a4a2a');
      s.position.set(0, h + 0.15, d / 2 + 0.2);
      g.add(s);
    }
    g.rotation.y = rot;
    this.add(g, x, 0, z, Math.max(w, d) * 0.62);
    return g;
  }

  signBoard(text, color) {
    const c = document.createElement('canvas');
    c.width = 256;
    c.height = 64;
    const x = c.getContext('2d');
    x.fillStyle = color;
    x.fillRect(0, 0, 256, 64);
    x.fillStyle = '#fff3d6';
    x.font = 'bold 34px Georgia, serif';
    x.textAlign = 'center';
    x.textBaseline = 'middle';
    x.fillText(text, 128, 34);
    const tex = new THREE.CanvasTexture(c);
    tex.colorSpace = THREE.SRGBColorSpace;
    const m = new THREE.Mesh(new THREE.PlaneGeometry(2.6, 0.65), new THREE.MeshBasicMaterial({ map: tex }));
    return m;
  }

  buildVillage() {
    this.house(-19, -8, { wall: '#7fb8ff', roof: '#3d5fc4', door: '#ffd166', key: 'maison', rot: 0.4 });
    this.house(-3, -14, { wall: '#ffd9a0', roof: '#c4583d', rot: -0.2 });
    this.house(-25, 7, { wall: '#ffb3c7', roof: '#8c4bb5', rot: 1.2 });
    this.house(-15, 15, { wall: '#c9f0b0', roof: '#4b8c3d', rot: 2.6 });
    // The bakery, door facing the plaza (west), with a red door.
    this.bakery = this.house(0, 8, { wall: '#fff0d4', roof: '#e8743a', door: '#e8443a', w: 5.4, d: 4.6, h: 3.4, rot: -Math.PI / 2, sign: 'Boulangerie' });

    // Market stall with bread ("le pain").
    const stall = new THREE.Group();
    const table = this.mesh(new THREE.BoxGeometry(2.6, 0.15, 1.2), '#b98248', 'pain');
    table.position.y = 1;
    stall.add(table);
    for (const sx of [-1.1, 1.1]) {
      const leg = this.mesh(new THREE.BoxGeometry(0.15, 2.6, 0.15), '#7a5230', 'pain');
      leg.position.set(sx, 1.3, 0);
      stall.add(leg);
    }
    const awning = this.mesh(new THREE.BoxGeometry(3, 0.12, 1.6), '#e8443a', 'pain');
    awning.position.y = 2.6;
    awning.rotation.x = 0.2;
    stall.add(awning);
    for (let i = 0; i < 4; i++) {
      const loaf = this.mesh(new THREE.CapsuleGeometry(0.16, 0.7, 2, 6), '#d9a05b', 'pain');
      loaf.rotation.z = Math.PI / 2;
      loaf.position.set(-0.9 + i * 0.6, 1.2, 0);
      stall.add(loaf);
    }
    this.add(stall, -4.5, 0, 13.5, 1.4);

    // The fountain ("la fontaine") in the plaza.
    const f = new THREE.Group();
    const basin = this.mesh(new THREE.CylinderGeometry(2.2, 2.4, 0.8, 10), '#b9b3ad', 'fontaine', { receive: true });
    basin.position.y = 0.4;
    f.add(basin);
    const water = this.mesh(new THREE.CylinderGeometry(1.9, 1.9, 0.1, 10), '#5ccfff', 'fontaine', { cast: false });
    water.position.y = 0.78;
    f.add(water);
    const column = this.mesh(new THREE.CylinderGeometry(0.3, 0.4, 2, 8), '#cfc9c2', 'fontaine');
    column.position.y = 1.6;
    f.add(column);
    const bowl = this.mesh(new THREE.CylinderGeometry(0.9, 0.4, 0.4, 8), '#b9b3ad', 'fontaine');
    bowl.position.y = 2.7;
    f.add(bowl);
    this.fountainDrops = [];
    for (let i = 0; i < 8; i++) {
      const drop = new THREE.Mesh(new THREE.SphereGeometry(0.09, 5, 4), this.mat('#9ee6ff', 'fontaine'));
      f.add(drop);
      this.fountainDrops.push({ m: drop, a: (i / 8) * Math.PI * 2, t: i / 8 });
    }
    this.add(f, -10, 0, 1, 2.6);

    // The cat ("le chat") on a crate.
    const crate = this.mesh(new THREE.BoxGeometry(1.2, 1.2, 1.2), '#a8733f', 'chat');
    this.add(crate, -8, 0.6, -11, 1.0);
    const cat = new THREE.Group();
    const body = this.mesh(new THREE.SphereGeometry(0.42, 7, 5), '#f08c2e', 'chat');
    body.scale.set(1.3, 0.9, 0.9);
    cat.add(body);
    const head = this.mesh(new THREE.SphereGeometry(0.3, 7, 5), '#f08c2e', 'chat');
    head.position.set(0.5, 0.35, 0);
    cat.add(head);
    for (const s of [-1, 1]) {
      const ear = this.mesh(new THREE.ConeGeometry(0.1, 0.2, 4), '#f08c2e', 'chat');
      ear.position.set(0.52, 0.66, s * 0.14);
      cat.add(ear);
      const eye = new THREE.Mesh(new THREE.SphereGeometry(0.045, 5, 4), new THREE.MeshBasicMaterial({ color: '#1b2440' }));
      eye.position.set(0.77, 0.4, s * 0.11);
      cat.add(eye);
    }
    const tail = this.mesh(new THREE.CylinderGeometry(0.06, 0.08, 0.8, 5), '#f08c2e', 'chat');
    tail.position.set(-0.55, 0.35, 0);
    tail.rotation.z = 0.8;
    cat.add(tail);
    this.catTail = tail;
    cat.rotation.y = -0.9;
    this.add(cat, -8, 1.55, -11);
    this.cat = cat;

    // Flowers ("la fleur").
    const colors = ['#ff5fa2', '#ffd23f', '#ff7b54', '#c77dff'];
    for (let i = 0; i < 14; i++) {
      const fl = new THREE.Group();
      const stem = this.mesh(new THREE.CylinderGeometry(0.03, 0.03, 0.6, 4), '#3f8f2f', 'fleur', { cast: false });
      stem.position.y = 0.3;
      fl.add(stem);
      const petal = this.mesh(new THREE.IcosahedronGeometry(0.2, 0), colors[i % 4], 'fleur', { cast: false });
      petal.position.y = 0.65;
      fl.add(petal);
      const a = i * 2.4;
      this.add(fl, -21 + Math.cos(a) * (1 + (i % 4) * 0.6), 0, 13 + Math.sin(a) * (1 + (i % 4) * 0.6));
    }

    // Fences and lanterns for life.
    for (let i = 0; i < 5; i++) {
      const lamp = new THREE.Group();
      const post = this.mesh(new THREE.CylinderGeometry(0.08, 0.1, 2.4, 6), '#3d3d4a', 'world');
      post.position.y = 1.2;
      lamp.add(post);
      const glass = new THREE.Mesh(new THREE.OctahedronGeometry(0.25, 0), new THREE.MeshBasicMaterial({ color: '#ffe08a' }));
      glass.position.y = 2.5;
      lamp.add(glass);
      const spots = [[-14, 3], [-6, 3], [-18, 20], [-21, 27], [2, -1.5]];
      this.add(lamp, spots[i][0], 0, spots[i][1], 0.3);
    }
  }

  buildEast() {
    // Lighthouse.
    const lh = new THREE.Group();
    for (let i = 0; i < 5; i++) {
      const ring = this.mesh(new THREE.CylinderGeometry(1.6 - i * 0.18, 1.78 - i * 0.18, 1.6, 10), i % 2 ? '#ffffff' : '#e8443a', 'world');
      ring.position.y = 0.8 + i * 1.6;
      lh.add(ring);
    }
    const top = this.mesh(new THREE.CylinderGeometry(1.1, 1.1, 1.2, 10), '#3d3d4a', 'world');
    top.position.y = 8.8;
    lh.add(top);
    this.lamp = new THREE.Mesh(new THREE.SphereGeometry(0.7, 10, 8), new THREE.MeshBasicMaterial({ color: '#fff3b0' }));
    this.lamp.position.y = 8.8;
    lh.add(this.lamp);
    const cap = this.mesh(new THREE.ConeGeometry(1.4, 1.4, 10), '#e8443a', 'world');
    cap.position.y = 10.1;
    lh.add(cap);
    this.add(lh, 26, 1, -16, 2.2);

    // The ancient tree and the treasure chest.
    const trunk = this.mesh(new THREE.CylinderGeometry(0.7, 1.1, 4.5, 7), '#7a5230', 'world');
    this.add(trunk, 25, 2.25, -3.5, 1.4);
    for (const [dx, dy, dz, r] of [[0, 5.6, 0, 3.2], [1.8, 4.8, 1, 2.2], [-1.6, 5, -0.8, 2.3], [0.4, 7, -0.3, 2]]) {
      const crown = this.mesh(new THREE.IcosahedronGeometry(r, 0), '#3f9b4a', 'world');
      this.add(crown, 25 + dx, dy, -3.5 + dz);
    }
    const chest = new THREE.Group();
    const box = this.mesh(new THREE.BoxGeometry(1.8, 1, 1.2), '#9a5b2b', 'world');
    box.position.y = 0.5;
    chest.add(box);
    const lid = new THREE.Group();
    const lidMesh = this.mesh(new THREE.CylinderGeometry(0.6, 0.6, 1.8, 8, 1, false, 0, Math.PI), '#b06a33', 'world');
    lidMesh.rotation.z = Math.PI / 2;
    lidMesh.position.z = 0.6;
    lid.add(lidMesh);
    lid.position.set(0, 1, -0.6);
    chest.add(lid);
    for (const x of [-0.6, 0.6]) {
      const band = this.mesh(new THREE.BoxGeometry(0.15, 1.05, 1.25), '#ffc94d', 'world');
      band.position.set(x, 0.52, 0);
      chest.add(band);
    }
    const lock = this.mesh(new THREE.BoxGeometry(0.35, 0.4, 0.1), '#ffc94d', 'world');
    lock.position.set(0, 0.85, 0.65);
    chest.add(lock);
    this.chest = chest;
    this.chestLid = lid;
    chest.rotation.y = -0.3;
    this.add(chest, 22, 0, -6.5, 1.3);
    // Glow that appears when the chest opens.
    this.chestGlow = new THREE.Mesh(
      new THREE.SphereGeometry(1.2, 12, 8),
      new THREE.MeshBasicMaterial({ color: '#ffe08a', transparent: true, opacity: 0, depthWrite: false }),
    );
    this.chestGlow.position.set(22, 1.3, -6.5);
    this.scene.add(this.chestGlow);
  }

  buildNature() {
    // The word tree ("l'arbre").
    const t = new THREE.Group();
    const trunk = this.mesh(new THREE.CylinderGeometry(0.35, 0.55, 2.4, 6), '#8a5a30', 'arbre');
    trunk.position.y = 1.2;
    t.add(trunk);
    for (const [y, r] of [[3.2, 2], [4.6, 1.5], [5.7, 1]]) {
      const c = this.mesh(new THREE.ConeGeometry(r, 1.9, 7), '#2f9e44', 'arbre');
      c.position.y = y;
      t.add(c);
    }
    const apple = this.mesh(new THREE.SphereGeometry(0.18, 6, 4), '#e8443a', 'arbre');
    apple.position.set(1.2, 3, 0.5);
    t.add(apple);
    this.add(t, -28, 0, -2, 0.9);

    // Forest around the island: instanced, cheap to draw.
    const spots = [];
    const rand = mulberry(7);
    for (let i = 0; i < (this.weak ? 45 : 80); i++) {
      const a = rand() * Math.PI * 2;
      const r = this.islandRadius(a) - 2 - rand() * 8;
      const x = Math.cos(a) * r;
      const z = Math.sin(a) * r;
      if (Math.abs(x - 8) < 5) continue; // river
      if (x > -26 && x < -17 && z > 18) continue; // path to the dock
      if (Math.hypot(x - 22, z + 6) < 6 || Math.hypot(x - 26, z + 16) < 4) continue;
      spots.push([x, z, 0.8 + rand() * 0.7, rand() < 0.5]);
    }
    const free = ([x, z]) =>
      !this.colliders.some((c) => Math.hypot(x - c.x, z - c.z) < c.r + 1.6) &&
      !this.clear.some(([cx, cz, r]) => Math.hypot(x - cx, z - cz) < r);
    for (const [x, z] of [[14, 6], [16, 12], [18, -18], [13, -12], [30, 4], [20, 10], [-30, -14], [-12, -20], [-30, 16]]) {
      spots.push([x, z, 1 + rand() * 0.5, rand() < 0.5]);
    }
    spots.splice(0, spots.length, ...spots.filter(free));
    const pines = spots.filter((s) => s[3]);
    const rounds = spots.filter((s) => !s[3]);
    const trunkGeo = flat(new THREE.CylinderGeometry(0.25, 0.4, 2, 5));
    const pineGeo = flat(new THREE.ConeGeometry(1.5, 3.6, 6));
    const roundGeo = flat(new THREE.IcosahedronGeometry(1.6, 0));
    const inst = (geo, color, list, y) => {
      const m = new THREE.InstancedMesh(geo, this.mat(color), list.length);
      const o = new THREE.Object3D();
      list.forEach(([x, z, s], i) => {
        o.position.set(x, y * s, z);
        o.scale.setScalar(s);
        o.rotation.y = x * 3;
        o.updateMatrix();
        m.setMatrixAt(i, o.matrix);
      });
      m.castShadow = !this.weak;
      this.scene.add(m);
    };
    inst(trunkGeo, '#7a5230', spots, 1);
    inst(pineGeo, '#2e8b57', pines, 3.4);
    inst(roundGeo, '#58b847', rounds, 3);
    for (const [x, z, s] of spots) this.colliders.push({ x, z, r: 0.7 * s });

    // Rocks on the beach.
    const rockGeo = flat(new THREE.DodecahedronGeometry(1, 0));
    const rocks = [];
    for (let i = 0; i < 22; i++) {
      const a = rand() * Math.PI * 2;
      const r = this.islandRadius(a) + 2 + rand() * 2;
      rocks.push([Math.cos(a) * r, Math.sin(a) * r, 0.4 + rand() * 0.8]);
    }
    const rm = new THREE.InstancedMesh(rockGeo, this.mat('#9a9590'), rocks.length);
    const o = new THREE.Object3D();
    rocks.forEach(([x, z, s], i) => {
      o.position.set(x, 0, z);
      o.scale.set(s, s * 0.7, s);
      o.rotation.set(s, s * 4, 0);
      o.updateMatrix();
      rm.setMatrixAt(i, o.matrix);
    });
    this.scene.add(rm);
  }

  buildClouds() {
    this.clouds = [];
    const geo = flat(new THREE.IcosahedronGeometry(1, 0));
    const mat = new THREE.MeshLambertMaterial({ color: '#ffffff', transparent: true, opacity: 0.9 });
    for (let i = 0; i < 9; i++) {
      const c = new THREE.Group();
      for (let k = 0; k < 4; k++) {
        const puff = new THREE.Mesh(geo, mat);
        puff.position.set(k * 1.8 - 2.7, Math.sin(k * 2) * 0.5, (k % 2) * 0.8);
        puff.scale.setScalar(1.4 + (k % 3) * 0.5);
        c.add(puff);
      }
      c.position.set(-80 + i * 20, 22 + (i % 3) * 4, -50 + (i % 4) * 30);
      this.scene.add(c);
      this.clouds.push(c);
    }
  }

  // ---------- word crystals ----------
  addCrystal(word, x, z) {
    const g = new THREE.Group();
    const gem = new THREE.Mesh(
      new THREE.OctahedronGeometry(0.55, 0),
      new THREE.MeshLambertMaterial({ color: '#7df9ff', emissive: '#2bb3ff', emissiveIntensity: 0.8, flatShading: true }),
    );
    g.add(gem);
    const halo = new THREE.Mesh(
      new THREE.RingGeometry(0.7, 0.95, 20),
      new THREE.MeshBasicMaterial({ color: '#bff6ff', transparent: true, opacity: 0.6, side: THREE.DoubleSide, depthWrite: false }),
    );
    halo.rotation.x = -Math.PI / 2;
    halo.position.y = -1.1;
    g.add(halo);
    g.position.set(x, 1.5, z);
    this.scene.add(g);
    const c = { word, group: g, gem, halo, taken: false, t: Math.random() * 6 };
    this.crystals.push(c);
    return c;
  }

  takeCrystal(c) {
    c.taken = true;
    c.burst = 0;
  }

  /** A word was found: its objects get their colours, the island a little more. */
  restore(key, wordsFound, totalWords) {
    if (key) this.target[key] = 1;
    this.target.world = 0.12 + 0.88 * Math.min(1, wordsFound / totalWords);
  }

  /** Every object at this colour amount, at once (the intro starts in full colour). */
  setAllColors(v) {
    this.savedTarget = { ...this.target };
    for (const m of this.paintable) {
      this.saturation[m.userData.key] = v;
      this.target[m.userData.key] = v;
    }
    this.applyColors(true);
  }

  /** Morgane steals the words: the colours flow out (slowly, for the intro). */
  drainColors() {
    for (const k of Object.keys(this.target)) this.target[k] = 0;
    Object.assign(this.target, this.savedTarget || { world: 0.12 });
  }

  restoreInstantly() {
    for (const k of Object.keys(this.target)) this.saturation[k] = this.target[k];
    this.applyColors(true);
  }

  applyColors(force) {
    for (const m of this.paintable) {
      const key = m.userData.key;
      const s = Math.max(this.saturation[key] ?? 0, this.saturation.world);
      if (!force && m.userData.s === s) continue;
      m.userData.s = s;
      const base = m.userData.base;
      const l = base.r * 0.3 + base.g * 0.59 + base.b * 0.11;
      GREY.setRGB(l * 0.85 + 0.08, l * 0.85 + 0.09, l * 0.85 + 0.12);
      m.color.copy(GREY).lerp(base, s);
    }
    const s = this.saturation.world;
    tmp.setRGB(0.62, 0.66, 0.72);
    this.skyUniforms.top.value.copy(tmp).lerp(this.skyBase.top, s);
    tmp.setRGB(0.82, 0.82, 0.84);
    this.skyUniforms.bottom.value.copy(tmp).lerp(this.skyBase.bottom, s);
    this.scene.fog.color.copy(this.skyUniforms.bottom.value);
  }

  openBridge() {
    this.bridgeOpen = true;
  }

  /** Can the player stand here? */
  walkable(x, z) {
    const onDock = x > -23.7 && x < -20.3 && z > 29 && z < 44.3;
    const angle = Math.atan2(z, x);
    const onIsland = Math.hypot(x, z) < this.islandRadius(angle) + 3.5;
    if (!onIsland && !onDock) return false;
    if (x > 5.3 && x < 10.7) {
      const onBridge = z > -5.4 && z < -2.6;
      if (!onBridge || !this.bridgeOpen) return false;
    }
    if (!this.bridgeOpen && x > 3.4 && x < 5.4 && z > -6 && z < -2) return false; // the guard's barrier
    return true;
  }

  heightAt(x, z) {
    if (x > 4 && x < 12 && z > -5.6 && z < -2.4) return 0.55 + Math.sin(((x - 4.4) / 7.2) * Math.PI) * 0.5;
    if (x > -23.7 && x < -20.3 && z > 30.5) return 0.28;
    const hd = Math.hypot(x - 25, z + 14);
    if (hd < 15) return Math.max(0, Math.min(1.1, (15 - hd) / 6 * 1.1));
    return 0;
  }

  update(dt) {
    this.time += dt;
    if (this.seaTime) this.seaTime.value = this.time;
    // Colours flow back smoothly.
    let changed = false;
    for (const k of Object.keys(this.target)) {
      const cur = this.saturation[k] ?? 0;
      const want = this.target[k];
      if (Math.abs(cur - want) > 0.002) {
        this.saturation[k] = cur + (want - cur) * Math.min(1, dt * 1.8);
        changed = true;
      }
    }
    if (changed) this.applyColors();

    for (const c of this.crystals) {
      if (c.taken) {
        if (c.burst === undefined || c.burst > 1) continue;
        c.burst += dt * 2;
        c.group.scale.setScalar(1 + c.burst * 1.8);
        c.gem.material.transparent = true;
        c.gem.material.opacity = Math.max(0, 1 - c.burst);
        c.halo.material.opacity = Math.max(0, 0.6 - c.burst);
        if (c.burst > 1) c.group.visible = false;
        continue;
      }
      c.t += dt;
      c.gem.rotation.y += dt * 1.6;
      c.gem.position.y = Math.sin(c.t * 2.2) * 0.18;
      c.halo.scale.setScalar(1 + Math.sin(c.t * 3) * 0.12);
    }
    for (const d of this.fountainDrops) {
      d.t = (d.t + dt * 0.8) % 1;
      const r = 0.5 + d.t * 1.2;
      d.m.position.set(Math.cos(d.a) * r, 2.9 + d.t * 0.8 - d.t * d.t * 2.2, Math.sin(d.a) * r);
    }
    if (this.catTail) this.catTail.rotation.x = Math.sin(this.time * 2) * 0.4;
    for (const c of this.clouds) {
      c.position.x += dt * 0.8;
      if (c.position.x > 110) c.position.x = -110;
    }
    this.lamp.material.color.setHSL(0.14, 1, 0.7 + Math.sin(this.time * 3) * 0.15);
    const lift = this.bridgeOpen ? Math.PI / 2.3 : 0;
    this.gatePole.rotation.z += (lift - this.gatePole.rotation.z) * Math.min(1, dt * 3);
    if (this.chestOpening !== undefined) {
      this.chestOpening = Math.min(1, this.chestOpening + dt * 0.8);
      this.chestLid.rotation.x = -this.chestOpening * 1.9;
      this.chestGlow.material.opacity = Math.sin(this.chestOpening * Math.PI) * 0.8 + this.chestOpening * 0.15;
      this.chestGlow.scale.setScalar(1 + this.chestOpening * 2);
    }
  }

  openChest() {
    this.chestOpening = 0;
  }
}

function mulberry(seed) {
  return () => {
    seed |= 0;
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
