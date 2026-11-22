// Chibi characters (big head, small body) made of simple shapes.
import * as THREE from 'three';

const lam = (color, extra = {}) => new THREE.MeshLambertMaterial({ color, flatShading: true, ...extra });
const basic = (color) => new THREE.MeshBasicMaterial({ color });

function part(geo, mat, x, y, z, cast) {
  const m = new THREE.Mesh(geo, mat);
  m.position.set(x, y, z);
  m.castShadow = cast;
  return m;
}

/**
 * A person. Options: skin, shirt, pants, hair, hat ('cap' | 'chef' | 'helmet' | 'captain' | null),
 * scarf, beard, apron, backpack, scale.
 */
export function makeCharacter(o, { weak = false } = {}) {
  const cast = !weak;
  const root = new THREE.Group();
  const body = new THREE.Group();
  root.add(body);

  const skin = lam(o.skin || '#f2c49b');
  const shirt = lam(o.shirt || '#3d7bd9');
  const pants = lam(o.pants || '#2b3550');

  // Legs pivot at the hips.
  const legGeo = new THREE.CapsuleGeometry(0.13, 0.42, 2, 6);
  const legs = [-0.15, 0.15].map((x) => {
    const pivot = new THREE.Group();
    pivot.position.set(x, 0.62, 0);
    pivot.add(part(legGeo, pants, 0, -0.3, 0, cast));
    pivot.add(part(new THREE.BoxGeometry(0.2, 0.12, 0.3), lam('#3b2a20'), 0, -0.58, 0.05, cast));
    body.add(pivot);
    return pivot;
  });

  const torso = part(new THREE.CapsuleGeometry(0.3, 0.4, 3, 8), shirt, 0, 0.98, 0, cast);
  torso.scale.set(1, 1, 0.8);
  body.add(torso);
  if (o.apron) body.add(part(new THREE.BoxGeometry(0.46, 0.55, 0.05), lam(o.apron), 0, 0.92, 0.25, false));
  if (o.scarf) {
    const scarf = part(new THREE.TorusGeometry(0.22, 0.08, 5, 10), lam(o.scarf), 0, 1.35, 0, false);
    scarf.rotation.x = Math.PI / 2;
    body.add(scarf);
    body.add(part(new THREE.BoxGeometry(0.14, 0.35, 0.06), lam(o.scarf), 0.1, 1.15, 0.26, false));
  }
  if (o.backpack) body.add(part(new THREE.BoxGeometry(0.42, 0.5, 0.25), lam(o.backpack), 0, 1.0, -0.33, cast));

  const armGeo = new THREE.CapsuleGeometry(0.1, 0.38, 2, 6);
  const arms = [-1, 1].map((s) => {
    const pivot = new THREE.Group();
    pivot.position.set(s * 0.38, 1.25, 0);
    pivot.add(part(armGeo, shirt, 0, -0.26, 0, cast));
    pivot.add(part(new THREE.SphereGeometry(0.1, 6, 5), skin, 0, -0.52, 0, false));
    body.add(pivot);
    return pivot;
  });

  // Head.
  const head = new THREE.Group();
  head.position.y = 1.78;
  head.add(part(new THREE.SphereGeometry(0.46, 10, 8), skin, 0, 0, 0, cast));
  for (const s of [-1, 1]) {
    head.add(part(new THREE.SphereGeometry(0.07, 6, 5), basic('#1b2440'), s * 0.16, 0.02, 0.41, false));
    head.add(part(new THREE.SphereGeometry(0.025, 4, 3), basic('#ffffff'), s * 0.16 + 0.025, 0.05, 0.47, false));
    head.add(part(new THREE.SphereGeometry(0.07, 6, 4), lam('#ff9e9e', { transparent: true, opacity: 0.55 }), s * 0.27, -0.12, 0.35, false));
  }
  const mouth = part(new THREE.TorusGeometry(0.07, 0.018, 4, 8, Math.PI), basic('#7a2a2a'), 0, -0.13, 0.43, false);
  mouth.rotation.z = Math.PI;
  head.add(mouth);
  if (o.hair) {
    const hair = part(new THREE.SphereGeometry(0.49, 10, 6, 0, Math.PI * 2, 0, Math.PI * 0.55), lam(o.hair), 0, 0.03, -0.02, cast);
    head.add(hair);
    if (o.longHair) head.add(part(new THREE.BoxGeometry(0.8, 0.6, 0.25), lam(o.hair), 0, -0.25, -0.3, cast));
  }
  if (o.beard) head.add(part(new THREE.SphereGeometry(0.3, 8, 6, 0, Math.PI * 2, Math.PI * 0.5, Math.PI * 0.5), lam(o.beard), 0, -0.12, 0.2, false));
  if (o.hat === 'cap') {
    head.add(part(new THREE.CylinderGeometry(0.47, 0.5, 0.25, 10), lam(o.hatColor || '#e8443a'), 0, 0.32, 0, cast));
    head.add(part(new THREE.BoxGeometry(0.5, 0.05, 0.35), lam(o.hatColor || '#e8443a'), 0, 0.22, 0.42, false));
  } else if (o.hat === 'chef') {
    head.add(part(new THREE.CylinderGeometry(0.38, 0.32, 0.45, 10), lam('#ffffff'), 0, 0.5, 0, cast));
    head.add(part(new THREE.SphereGeometry(0.42, 8, 6), lam('#ffffff'), 0, 0.78, 0, cast));
  } else if (o.hat === 'captain') {
    head.add(part(new THREE.CylinderGeometry(0.5, 0.5, 0.2, 10), lam('#1b2440'), 0, 0.36, 0, cast));
    head.add(part(new THREE.CylinderGeometry(0.62, 0.62, 0.06, 12), lam('#1b2440'), 0, 0.26, 0, cast));
    head.add(part(new THREE.SphereGeometry(0.08, 6, 4), basic('#ffc94d'), 0, 0.38, 0.48, false));
  } else if (o.hat === 'helmet') {
    head.add(part(new THREE.SphereGeometry(0.52, 10, 6, 0, Math.PI * 2, 0, Math.PI * 0.5), lam('#b8bcc6'), 0, 0.08, 0, cast));
    head.add(part(new THREE.ConeGeometry(0.08, 0.35, 5), lam('#e8443a'), 0, 0.68, 0, false));
  }
  body.add(head);

  if (o.scale) root.scale.setScalar(o.scale);

  let phase = Math.random() * 6;
  root.userData.animate = (dt, speed, talking) => {
    phase += dt * (speed > 0.1 ? 9 : 2);
    const swing = speed > 0.1 ? Math.sin(phase) * 0.7 : 0;
    legs[0].rotation.x = swing;
    legs[1].rotation.x = -swing;
    arms[0].rotation.x = -swing * 0.8;
    arms[1].rotation.x = swing * 0.8;
    body.position.y = speed > 0.1 ? Math.abs(Math.sin(phase)) * 0.08 : Math.sin(phase) * 0.02;
    head.rotation.z = talking ? Math.sin(phase * 3) * 0.06 : 0;
    if (talking) arms[1].rotation.x = -1.2 + Math.sin(phase * 2.5) * 0.3;
  };
  return root;
}

/** Coco the parrot: follows the player and gives hints. */
export function makeParrot({ weak = false } = {}) {
  const g = new THREE.Group();
  const body = new THREE.Mesh(new THREE.SphereGeometry(0.22, 8, 6), lam('#2fbf4a'));
  body.scale.set(0.9, 1.1, 1.2);
  body.castShadow = !weak;
  g.add(body);
  const head = new THREE.Mesh(new THREE.SphereGeometry(0.16, 8, 6), lam('#e8443a'));
  head.position.set(0, 0.24, 0.12);
  g.add(head);
  const beak = new THREE.Mesh(new THREE.ConeGeometry(0.06, 0.16, 5), lam('#ffc94d'));
  beak.rotation.x = Math.PI / 2;
  beak.position.set(0, 0.22, 0.3);
  g.add(beak);
  for (const s of [-1, 1]) {
    const eye = new THREE.Mesh(new THREE.SphereGeometry(0.03, 5, 4), basic('#1b2440'));
    eye.position.set(s * 0.08, 0.28, 0.24);
    g.add(eye);
  }
  const tail = new THREE.Mesh(new THREE.BoxGeometry(0.12, 0.04, 0.4), lam('#3d7bd9'));
  tail.position.set(0, -0.08, -0.3);
  tail.rotation.x = 0.4;
  g.add(tail);
  const wings = [-1, 1].map((s) => {
    const pivot = new THREE.Group();
    pivot.position.set(s * 0.18, 0.05, 0);
    const w = new THREE.Mesh(new THREE.BoxGeometry(0.36, 0.04, 0.24), lam('#2fbf4a'));
    w.position.x = s * 0.18;
    pivot.add(w);
    g.add(pivot);
    return { pivot, s };
  });
  let t = 0;
  g.userData.animate = (dt) => {
    t += dt;
    for (const { pivot, s } of wings) pivot.rotation.z = s * Math.sin(t * 18) * 0.8;
  };
  return g;
}

/** Morgane, the witch who stole the words. */
export function makeWitch({ weak = false } = {}) {
  const g = new THREE.Group();
  const robe = new THREE.Mesh(new THREE.ConeGeometry(0.75, 2.2, 8), lam('#3a1d5c'));
  robe.position.y = 1.1;
  robe.castShadow = !weak;
  g.add(robe);
  const head = new THREE.Mesh(new THREE.SphereGeometry(0.42, 10, 8), lam('#cdb6e6'));
  head.position.y = 2.45;
  g.add(head);
  for (const s of [-1, 1]) {
    const eye = new THREE.Mesh(new THREE.SphereGeometry(0.07, 6, 4), basic('#ff3df2'));
    eye.position.set(s * 0.15, 2.5, 0.37);
    g.add(eye);
  }
  const brim = new THREE.Mesh(new THREE.CylinderGeometry(0.8, 0.8, 0.06, 12), lam('#24113d'));
  brim.position.y = 2.78;
  g.add(brim);
  const hat = new THREE.Mesh(new THREE.ConeGeometry(0.45, 1.3, 8), lam('#24113d'));
  hat.position.set(0, 3.4, -0.1);
  hat.rotation.x = -0.25;
  g.add(hat);
  const orb = new THREE.Mesh(new THREE.SphereGeometry(0.22, 10, 8), new THREE.MeshBasicMaterial({ color: '#c34dff' }));
  orb.position.set(0.7, 1.6, 0.3);
  g.add(orb);
  let t = 0;
  g.userData.animate = (dt) => {
    t += dt;
    g.position.y = 0.4 + Math.sin(t * 2) * 0.2;
    orb.scale.setScalar(1 + Math.sin(t * 6) * 0.15);
  };
  return g;
}

/** A floating "!" or "?" above someone with something to say. */
export function makeMarker(symbol, color) {
  const c = document.createElement('canvas');
  c.width = c.height = 128;
  const x = c.getContext('2d');
  x.fillStyle = color;
  x.beginPath();
  x.arc(64, 64, 56, 0, Math.PI * 2);
  x.fill();
  x.lineWidth = 8;
  x.strokeStyle = '#ffffff';
  x.stroke();
  x.fillStyle = '#ffffff';
  x.font = 'bold 84px sans-serif';
  x.textAlign = 'center';
  x.textBaseline = 'middle';
  x.fillText(symbol, 64, 70);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  const s = new THREE.Sprite(new THREE.SpriteMaterial({ map: tex, depthTest: false }));
  s.scale.setScalar(0.8);
  s.renderOrder = 10;
  return s;
}
