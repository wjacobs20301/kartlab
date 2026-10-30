// Experimental lab tuning in TOTK units, not recovered Mario Kart equations.
export class DriveState {
  constructor() { this.speed = 0; this.yaw = 0; }
  reset() { this.speed = 0; this.yaw = 0; }
  step(dt, throttle, steer, brake) {
    dt = Math.max(0, Math.min(0.1, dt));
    const target = brake ? 0 : throttle * 6;
    const change = (brake ? 18 : 5) * dt;
    this.speed += Math.max(-change, Math.min(change, target - this.speed));
    if (Math.abs(this.speed) > 0.1) this.yaw += steer * 0.75 * dt * Math.sign(this.speed);
    return { speed: this.speed, yaw: this.yaw };
  }
}
export function pulseScript(speed, yaw) {
  if (!Number.isFinite(speed) || !Number.isFinite(yaw) || Math.abs(speed) > 6.001) throw new Error('Invalid bounded drive command');
  const vx = (Math.sin(yaw) * speed).toFixed(6);
  const vz = (Math.cos(yaw) * speed).toFixed(6);
  const s = Math.sin(yaw).toFixed(6), c = Math.cos(yaw).toFixed(6);
  return `void main() {
    if (pause::isPauseRequest("LoadingPause") || pause::isPauseTarget("Actor")) { ActorWatcher::clearSlot(1); return; }
    ActorBase@ cart = ActorWatcher::get(1);
    if (cart is null || cart.getName() != "SpObj_Cart_A_01") return;
    RigidBody@ body = cart.getMainRigidBody(); if (body is null) return;
    cart.setRot(${c},0,${s}, 0,1,0, -(${s}),0,${c});
    Vector3f v = body.vel; body.setVel(${vx},v.y,${vz});
  }`;
}
