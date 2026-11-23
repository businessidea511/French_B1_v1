// The chase: on a delivery scooter, through the streets of Liège at night.
// Élise gives the way on the phone, in French (« Tourne à gauche ! »);
// only the right street leads on. A grey car follows your exact path a
// few seconds behind: stop too long and it catches you, and you start
// that street again. Élise speaks before each crossroads.
import * as THREE from 'three';
import { t, isRtl } from './i18n.js';
import { say, sfx } from './speech.js';
import { music } from './music.js';

const $ = (id) => document.getElementById(id);
const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const ELISE_VOICE = { voice: 'charline', speed: 1 };

function makeScooter() {
  const g = new THREE.Group();
  const paint = new THREE.MeshStandardMaterial({ color: '#c0392b', roughness: 0.35, metalness: 0.4 });
  const dark = new THREE.MeshStandardMaterial({ color: '#15171b', roughness: 0.6 });
  const body = new THREE.Mesh(new THREE.BoxGeometry(0.5, 0.45, 1.5), paint);
  body.position.set(0, 0.5, 0);
  g.add(body);
  const shield = new THREE.Mesh(new THREE.BoxGeometry(0.5, 0.8, 0.12), paint);
  shield.position.set(0, 0.85, 0.65);
  shield.rotation.x = -0.25;
  g.add(shield);
  const seat = new THREE.Mesh(new THREE.BoxGeometry(0.42, 0.12, 0.7), dark);
  seat.position.set(0, 0.8, -0.25);
  g.add(seat);
  const box = new THREE.Mesh(new THREE.BoxGeometry(0.55, 0.45, 0.5), new THREE.MeshStandardMaterial({ color: '#e8c33a', roughness: 0.5 }));
  box.position.set(0, 1.1, -0.75);
  g.add(box);
  for (const z of [0.62, -0.62]) {
    const wheel = new THREE.Mesh(new THREE.CylinderGeometry(0.26, 0.26, 0.16, 14), dark);
    wheel.rotation.z = Math.PI / 2;
    wheel.position.set(0, 0.26, z);
    g.add(wheel);
  }
  const bar = new THREE.Mesh(new THREE.CylinderGeometry(0.03, 0.03, 0.7, 6), dark);
  bar.rotation.z = Math.PI / 2;
  bar.position.set(0, 1.25, 0.6);
  g.add(bar);
  const lamp = new THREE.Mesh(new THREE.SphereGeometry(0.09, 8, 6), new THREE.MeshBasicMaterial({ color: '#fff6d8' }));
  lamp.position.set(0, 1.05, 0.75);
  g.add(lamp);
  // Headlight on the road.
  const c = document.createElement('canvas');
  c.width = c.height = 128;
  const x = c.getContext('2d');
  const grad = x.createRadialGradient(64, 64, 0, 64, 64, 64);
  grad.addColorStop(0, 'rgba(255,245,210,0.7)');
  grad.addColorStop(1, 'rgba(255,245,210,0)');
  x.fillStyle = grad;
  x.fillRect(0, 0, 128, 128);
  const tex = new THREE.CanvasTexture(c);
  const beam = new THREE.Mesh(new THREE.PlaneGeometry(3, 6), new THREE.MeshBasicMaterial({ map: tex, transparent: true, depthWrite: false, blending: THREE.AdditiveBlending }));
  beam.rotation.x = -Math.PI / 2;
  beam.position.set(0, 0.03, 3.6);
  g.add(beam);
  return g;
}

function makeGreyCar() {
  const g = new THREE.Group();
  const paint = new THREE.MeshStandardMaterial({ color: '#4a4f57', roughness: 0.25, metalness: 0.7 });
  const body = new THREE.Mesh(new THREE.BoxGeometry(1.9, 0.65, 4.4), paint);
  body.position.y = 0.6;
  g.add(body);
  const cab = new THREE.Mesh(new THREE.BoxGeometry(1.7, 0.6, 2.3), new THREE.MeshStandardMaterial({ color: '#0b0e14', roughness: 0.1, metalness: 0.8 }));
  cab.position.set(0, 1.2, -0.2);
  g.add(cab);
  for (const s of [-0.6, 0.6]) {
    const head = new THREE.Mesh(new THREE.BoxGeometry(0.4, 0.15, 0.05), new THREE.MeshBasicMaterial({ color: '#f4f8ff' }));
    head.position.set(s, 0.7, 2.22);
    g.add(head);
  }
  for (const [x, z] of [[-0.9, 1.4], [0.9, 1.4], [-0.9, -1.4], [0.9, -1.4]]) {
    const wheel = new THREE.Mesh(new THREE.CylinderGeometry(0.34, 0.34, 0.25, 12), new THREE.MeshStandardMaterial({ color: '#0b0b0b' }));
    wheel.rotation.z = Math.PI / 2;
    wheel.position.set(x, 0.34, z);
    g.add(wheel);
  }
  const light = new THREE.PointLight('#e8f0ff', 10, 14, 1.6);
  light.position.set(0, 1.4, 3.2);
  g.add(light);
  return g;
}

export class Chase {
  /** g: { scene, player, city, ui, fade, setYaw } */
  constructor(g) {
    this.g = g;
    this.active = false;
    this.driving = false;
    this.speed = 0;
    this.heading = Math.PI;
    this.scooter = makeScooter();
    this.scooter.visible = false;
    g.scene.add(this.scooter);
    this.car = makeGreyCar();
    this.car.visible = false;
    g.scene.add(this.car);
    $('chaseReplay').onclick = () => this.leg !== undefined && this.announce();
  }

  /** The scooter parked somewhere (before the chase). */
  park(x, z, heading) {
    this.scooter.position.set(x, 0, z);
    this.scooter.rotation.y = heading;
    this.scooter.visible = true;
  }

  // ---------- the chase ----------
  /**
   * route: crossroads [{ x, z }], from the start; legs[i]: Élise's words to go
   * from route[i] to route[i + 1] ({ fr, en }). Resolves the number of wrong turns.
   */
  run(route, legs, startHeading) {
    this.route = route;
    this.legs = legs;
    this.startHeading = startHeading;
    this.mistakes = 0;
    this.active = true;
    this.driving = true;
    this.g.ui.busy = false;
    document.body.classList.add('driving');
    music.fight();
    this.car.visible = true;
    $('chase').hidden = false;
    this.placeAt(0, startHeading);
    return new Promise((resolve) => {
      this.done = resolve;
      setTimeout(() => this.announce(), 900);
    });
  }

  placeAt(i, heading) {
    const n = this.route[i];
    this.leg = i;
    this.speed = 0;
    this.clock = this.clock || 0;
    this.heading = heading;
    this.scooter.position.set(n.x, 0, n.z);
    this.scooter.rotation.y = heading;
    this.scooter.visible = true;
    // The grey car starts a little behind.
    const back = new THREE.Vector3(n.x - Math.sin(heading) * 24, 0, n.z - Math.cos(heading) * 24);
    this.car.position.copy(back);
    this.history = [{ t: this.clock, p: back.clone() }];
    this.legStart = this.clock;
    this.locked = false;
  }

  announce() {
    const line = this.legs[this.leg];
    if (!line) return;
    $('chaseFr').textContent = `📞 « ${line.fr} »`;
    const help = $('chaseHelp');
    help.hidden = !this.g.ui.helpOn;
    help.textContent = t(line.en);
    help.dir = isRtl ? 'rtl' : 'ltr';
    say(line.fr, ELISE_VOICE);
  }

  async fail(reason) {
    if (this.locked) return;
    this.locked = true;
    this.mistakes++;
    this.speed = 0;
    sfx.wrong();
    const words = reason === 'caught'
      ? { fr: 'Ils t\'ont rattrapé ! Recommence, vite !', en: 'They caught up with you! Start again, quick!' }
      : { fr: 'Non ! Pas par là ! Écoute bien.', en: 'No! Not that way! Listen carefully.' };
    $('chaseFr').textContent = `📞 « ${words.fr} »`;
    $('chaseHelp').textContent = t(words.en);
    await say(words.fr, ELISE_VOICE);
    await this.g.fade(async () => {
      const prev = this.route[this.leg - 1];
      const here = this.route[this.leg];
      const heading = prev ? Math.atan2(here.x - prev.x, here.z - prev.z) : this.startHeading;
      this.placeAt(this.leg, heading);
    });
    this.announce();
  }

  async success() {
    this.locked = true;
    sfx.right();
    this.leg++;
    if (this.leg >= this.legs.length) {
      this.active = false;
      this.driving = false;
      this.speed = 0;
      $('chase').hidden = true;
      document.body.classList.remove('driving');
      music.explore();
      // The grey car loses you.
      const away = this.car;
      let k = 0;
      const drive = setInterval(() => {
        k += 1;
        away.position.x += Math.sin(away.rotation.y) * 0.8;
        away.position.z += Math.cos(away.rotation.y) * 0.8;
        if (k > 40) { clearInterval(drive); away.visible = false; }
      }, 30);
      const p = this.scooter.position;
      this.g.player.position.set(p.x + Math.cos(this.heading) * 1.2, 0, p.z - Math.sin(this.heading) * 1.2);
      this.done(this.mistakes);
      return;
    }
    this.legStart = this.clock;
    await wait(150);
    this.locked = false;
    this.announce();
  }

  /** Every frame while driving: steering, the crossroads, the grey car. */
  update(dt, dir) {
    if (!this.driving) return;
    this.clock = (this.clock || 0) + dt; // game time, not the wall clock
    const s = this.scooter;
    const throttle = this.locked ? 0 : -dir.y;
    const steer = this.locked ? 0 : dir.x;
    this.speed += throttle * 11 * dt;
    this.speed -= this.speed * 0.9 * dt; // rolling resistance
    if (Math.abs(throttle) < 0.05) this.speed -= this.speed * 1.4 * dt;
    this.speed = Math.max(-3, Math.min(14, this.speed));
    const turn = Math.min(1, Math.abs(this.speed) / 3) * Math.sign(this.speed || 1);
    this.heading -= steer * 2.9 * dt * turn;
    const nx = s.position.x + Math.sin(this.heading) * this.speed * dt;
    const nz = s.position.z + Math.cos(this.heading) * this.speed * dt;
    const city = this.g.city;
    const blocked = !city.walkable(nx, nz) || city.colliders.some((c) => (nx - c.x) ** 2 + (nz - c.z) ** 2 < (c.r + 0.6) ** 2);
    if (blocked) this.speed *= -0.3;
    else { s.position.x = nx; s.position.z = nz; }
    s.rotation.y = this.heading;
    s.rotation.z = -steer * Math.min(0.25, Math.abs(this.speed) / 40); // leaning in the turns
    // The player sits on it.
    const p = this.g.player;
    p.position.set(s.position.x - Math.sin(this.heading) * 0.15, 0.32, s.position.z - Math.cos(this.heading) * 0.15);
    p.rotation.y = this.heading;
    this.g.setYaw(this.heading);
    p.userData.animate(dt, 0, false);

    if (!this.active || this.locked) return;
    const now = this.clock;
    // Crossroads: the right one leads on, any other is a wrong turn.
    const near = (n) => Math.hypot(n.x - s.position.x, n.z - s.position.z) < 4.6;
    const target = this.route[this.leg + 1];
    if (Math.hypot(target.x - s.position.x, target.z - s.position.z) < 9) return this.success();
    const here = this.route[this.leg];
    for (const n of this.nodes || []) {
      if (near(n) && !(n.x === here.x && n.z === here.z)) return this.fail('wrong');
    }
    // The grey car follows your path, 4 seconds behind, a little slower than you.
    this.history.push({ t: now, p: s.position.clone() });
    while (this.history.length > 2 && this.history[1].t < now - 4) this.history.shift();
    const behind = this.history[0].p;
    const c = this.car.position;
    const d = Math.hypot(behind.x - c.x, behind.z - c.z);
    const toYou = Math.hypot(c.x - s.position.x, c.z - s.position.z);
    // Coming back towards it after a wrong turn: the car waits instead of crashing into you.
    const fromBehind = Math.sin(this.heading) * (s.position.x - c.x) + Math.cos(this.heading) * (s.position.z - c.z) > 0;
    if (d > 0.05 && (fromBehind || toYou > 7)) {
      const step = Math.min(d, 11 * dt);
      const ang = Math.atan2(behind.x - c.x, behind.z - c.z);
      c.x += Math.sin(ang) * step;
      c.z += Math.cos(ang) * step;
      this.car.rotation.y = ang;
    }
    if (now - this.legStart > 6 && fromBehind && toYou < 2.2) this.fail('caught');
    else if (now - this.legStart > 60) this.fail('caught');
  }

  /** Chase camera: behind the scooter, looking ahead. */
  camera(camTarget, lookWant) {
    if (!this.driving) return false;
    const s = this.scooter.position;
    const fx = Math.sin(this.heading);
    const fz = Math.cos(this.heading);
    // High enough to see over the grey car when it comes close.
    camTarget.set(s.x - fx * 6, 5.2, s.z - fz * 6);
    lookWant.set(s.x + fx * 6, 0.8, s.z + fz * 6);
    return true;
  }
}

/** English texts used here. */
export const chaseTexts = ['They caught up with you! Start again, quick!', 'No! Not that way! Listen carefully.'];
export const chaseLines = ["Ils t'ont rattrapé ! Recommence, vite !", 'Non ! Pas par là ! Écoute bien.'];
