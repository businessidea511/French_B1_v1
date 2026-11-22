// Adult characters for a night in Brussels: real proportions, coats, hats.
// Made of simple shapes with soft materials, so they stay light on phones.
import * as THREE from 'three';

const mat = (color, extra = {}) => new THREE.MeshStandardMaterial({ color, roughness: 0.85, metalness: 0, ...extra });

function mesh(geo, material, x, y, z, cast) {
  const m = new THREE.Mesh(geo, material);
  m.position.set(x, y, z);
  m.castShadow = cast;
  return m;
}

/**
 * A person. Options: skin, hair, coat, coatLong, pants, shirt, hat ('fedora' | 'cap' | 'beret' | null),
 * hatColor, glasses, beard, apron, scarf, bag, height (1 = 1.8 m), build (1 = normal).
 */
export function makePerson(o, { weak = false } = {}) {
  const cast = !weak;
  const root = new THREE.Group();
  const body = new THREE.Group();
  root.add(body);
  const skin = mat(o.skin || '#d8a47f');
  const coat = mat(o.coat || '#3b4252');
  const pants = mat(o.pants || '#1f232b');
  const shoe = mat('#141414', { roughness: 0.4 });
  const w = o.build || 1;

  // Legs, pivoting at the hips.
  const legs = [-0.12, 0.12].map((x) => {
    const pivot = new THREE.Group();
    pivot.position.set(x * w, 0.92, 0);
    pivot.add(mesh(new THREE.CylinderGeometry(0.085 * w, 0.07 * w, 0.86, 8), pants, 0, -0.45, 0, cast));
    pivot.add(mesh(new THREE.BoxGeometry(0.13 * w, 0.08, 0.28), shoe, 0, -0.88, 0.05, cast));
    body.add(pivot);
    return pivot;
  });

  // Torso and coat.
  const torso = mesh(new THREE.CylinderGeometry(0.21 * w, 0.19 * w, 0.62, 10), coat, 0, 1.24, 0, cast);
  body.add(torso);
  if (o.coatLong) {
    const skirt = mesh(new THREE.CylinderGeometry(0.2 * w, 0.27 * w, 0.62, 10, 1, true), coat, 0, 0.72, 0, cast);
    body.add(skirt);
  }
  if (o.shirt) body.add(mesh(new THREE.BoxGeometry(0.12, 0.3, 0.02), mat(o.shirt), 0, 1.38, 0.19, false));
  if (o.apron) body.add(mesh(new THREE.BoxGeometry(0.34 * w, 0.7, 0.03), mat(o.apron), 0, 1.0, 0.2 * w, false));
  if (o.scarf) {
    const scarf = mesh(new THREE.TorusGeometry(0.13, 0.05, 6, 12), mat(o.scarf), 0, 1.56, 0, false);
    scarf.rotation.x = Math.PI / 2;
    body.add(scarf);
  }
  if (o.bag) body.add(mesh(new THREE.BoxGeometry(0.3, 0.24, 0.1), mat(o.bag, { roughness: 0.6 }), 0.28 * w, 0.95, 0.05, cast));

  // Shoulders and arms.
  const arms = [-1, 1].map((s) => {
    const pivot = new THREE.Group();
    pivot.position.set(s * 0.27 * w, 1.5, 0);
    pivot.add(mesh(new THREE.CylinderGeometry(0.065, 0.055, 0.62, 8), coat, 0, -0.31, 0, cast));
    pivot.add(mesh(new THREE.SphereGeometry(0.055, 8, 6), skin, 0, -0.64, 0, false));
    body.add(pivot);
    return pivot;
  });
  body.add(mesh(new THREE.SphereGeometry(0.23 * w, 10, 6, 0, Math.PI * 2, 0, Math.PI / 2), coat, 0, 1.5, 0, cast));

  // Neck and head (adult size: about 1/8 of the body).
  body.add(mesh(new THREE.CylinderGeometry(0.06, 0.07, 0.12, 8), skin, 0, 1.6, 0, false));
  const head = new THREE.Group();
  head.position.y = 1.76;
  const skull = mesh(new THREE.SphereGeometry(0.135, 14, 10), skin, 0, 0, 0, cast);
  skull.scale.set(0.92, 1.12, 1);
  head.add(skull);
  const nose = mesh(new THREE.ConeGeometry(0.025, 0.06, 5), skin, 0, -0.01, 0.135, false);
  nose.rotation.x = Math.PI / 2;
  head.add(nose);
  for (const s of [-1, 1]) head.add(mesh(new THREE.SphereGeometry(0.016, 6, 4), mat('#1a1a1a', { roughness: 0.3 }), s * 0.048, 0.025, 0.122, false));
  if (o.hair) {
    const hair = mesh(new THREE.SphereGeometry(0.145, 12, 8, 0, Math.PI * 2, 0, Math.PI * 0.52), mat(o.hair), 0, 0.02, -0.01, cast);
    hair.scale.set(0.95, 1.12, 1.02);
    head.add(hair);
    if (o.longHair) head.add(mesh(new THREE.BoxGeometry(0.26, 0.3, 0.1), mat(o.hair), 0, -0.12, -0.1, cast));
  }
  if (o.beard) head.add(mesh(new THREE.SphereGeometry(0.11, 10, 6, 0, Math.PI * 2, Math.PI * 0.55, Math.PI * 0.45), mat(o.beard), 0, -0.04, 0.03, false));
  if (o.glasses) {
    const glass = mat('#0b0b0b', { roughness: 0.15, metalness: 0.5 });
    for (const s of [-1, 1]) head.add(mesh(new THREE.BoxGeometry(0.06, 0.035, 0.01), glass, s * 0.048, 0.025, 0.135, false));
  }
  const hatMat = mat(o.hatColor || '#22252c');
  if (o.hat === 'fedora') {
    head.add(mesh(new THREE.CylinderGeometry(0.25, 0.25, 0.015, 16), hatMat, 0, 0.1, 0, cast));
    head.add(mesh(new THREE.CylinderGeometry(0.12, 0.14, 0.13, 12), hatMat, 0, 0.17, 0, cast));
    head.add(mesh(new THREE.CylinderGeometry(0.142, 0.142, 0.025, 12), mat('#111'), 0, 0.12, 0, false));
  } else if (o.hat === 'cap') {
    head.add(mesh(new THREE.SphereGeometry(0.15, 10, 6, 0, Math.PI * 2, 0, Math.PI / 2), hatMat, 0, 0.05, 0, cast));
    head.add(mesh(new THREE.BoxGeometry(0.2, 0.015, 0.12), hatMat, 0, 0.06, 0.15, false));
  } else if (o.hat === 'beret') {
    const b = mesh(new THREE.CylinderGeometry(0.16, 0.15, 0.05, 12), hatMat, 0.02, 0.12, 0, cast);
    b.rotation.z = -0.15;
    head.add(b);
  }
  body.add(head);

  root.scale.setScalar(o.height || 1);

  let phase = Math.random() * 6;
  root.userData.animate = (dt, speed, talking) => {
    phase += dt * (speed > 0.1 ? 8 : 1.5);
    const swing = speed > 0.1 ? Math.sin(phase) * 0.55 : 0;
    legs[0].rotation.x = swing;
    legs[1].rotation.x = -swing;
    arms[0].rotation.x = -swing * 0.7;
    arms[1].rotation.x = swing * 0.7;
    body.position.y = speed > 0.1 ? Math.abs(Math.sin(phase)) * 0.04 : Math.sin(phase) * 0.008;
    head.rotation.y = talking ? Math.sin(phase * 1.3) * 0.12 : 0;
    if (talking) arms[1].rotation.x = -0.5 + Math.sin(phase * 2) * 0.25;
  };
  return root;
}

/** One of the men in grey: long grey coat, hat, dark glasses, a torch. */
export function makeAgent({ weak = false, chief = false } = {}) {
  const p = makePerson({
    skin: chief ? '#c9a28a' : '#d2ab90', coat: chief ? '#2b2f36' : '#6b7079', coatLong: true, pants: '#2a2d33',
    hat: 'fedora', hatColor: chief ? '#15171b' : '#3d4148', glasses: true, height: chief ? 1.08 : 1.02, build: chief ? 1.15 : 1,
  }, { weak });
  // A torch: a small light cone on the ground in front of him.
  const cone = new THREE.Mesh(
    new THREE.CircleGeometry(2.6, 24, -0.55, 1.1),
    new THREE.MeshBasicMaterial({ color: '#fff2c4', transparent: true, opacity: 0.16, depthWrite: false }),
  );
  cone.rotation.x = -Math.PI / 2;
  cone.rotation.z = Math.PI / 2;
  cone.position.set(0, 0.03, 0.3);
  p.add(cone);
  p.userData.cone = cone;
  return p;
}

/** A floating marker ("!" or "?") above someone with something to say. */
export function makeMarker(symbol, color) {
  const c = document.createElement('canvas');
  c.width = c.height = 128;
  const x = c.getContext('2d');
  x.fillStyle = 'rgba(12, 16, 26, 0.85)';
  x.beginPath();
  x.arc(64, 64, 54, 0, Math.PI * 2);
  x.fill();
  x.lineWidth = 7;
  x.strokeStyle = color;
  x.stroke();
  x.fillStyle = color;
  x.font = 'bold 76px Georgia, serif';
  x.textAlign = 'center';
  x.textBaseline = 'middle';
  x.fillText(symbol, 64, 68);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  const s = new THREE.Sprite(new THREE.SpriteMaterial({ map: tex, depthTest: false }));
  s.scale.setScalar(0.55);
  s.renderOrder = 10;
  return s;
}
