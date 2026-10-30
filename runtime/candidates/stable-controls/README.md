# Flat-road stability candidate

The user confirmed movement with v2 but reported rollover and poor steering. Its code premultiplied steering into the cart's evolving full physics rotation, retaining pitch/roll. That can carry an already tipping orientation through subsequent turns; it is a plausible contributor, not a complete physics diagnosis.

This v3 test tracks yaw independently from the initial forward direction and requests an upright orthonormal rotation when it differs. It reduces maximum horizontal speed from3 to0.8, acceleration step from0.10 to0.025, braking step from0.20 to0.08 and yaw step from0.025 to0.010. It preserves vertical velocity, skips rotation when already aligned, retains nearby-cart adoption and the five-minute/B exit. It is still remote driving with Link held at his start position, intended for a flat road. It does not implement suspension, ground-normal estimation, wheel forces or recovered Mario Kart handling.

Host scenarios pass upright recovery from an initial45degree roll, orthonormal yaw, forward/reverse speed caps and Y preservation, idle rotation avoidance, signature rejection, pause exit and cleanup. Those checks do not model collision or angular momentum; in-game stability is pending.

Installed module alias is drive_pad_v3.as. The updated clear_v2.as binds Right to it when first executed; normal autorun also points to it for future launches. Runtime receipt: research/stability-v3-install.json. The native rider diagnostic remains separate and unverified. None of these scripts starts a network listener.
