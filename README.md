# Faux Lighting Simulation (Metal + SwiftUI Shader)

A lightweight “fake flashlight” / spotlight effect written as a **SwiftUI stitchable Metal shader**.  
It renders an **expanding cone beam** from a fixed source point, adds **chromatic dispersion** (RGB splitting), a soft **halo/glow**, and finishes with a **tone-mapping** pass so highlights feel bright without blowing out.

https://github.com/user-attachments/assets/e9714655-97c4-48b2-9245-aca1e8096049

## Parameters

- **`intensity`** — overall brightness of the beam  
- **`disperse`** — cone spread *and* chromatic separation strength  
- **`rotation`** — beam direction (radians), relative to “down”  
- **`radius`** — starting beam width at the source  

## Implementation notes

- `sdSegmentSim(p, a, b)` returns:
  - `distance` from `p` to the segment axis
  - `t` = clamped projection along the segment in `[0, 1]`
- Beam profile uses:
  - `beam = 1 - smoothstep(0, width, dist)`
  - then softened with `pow(beam, softness)`
- Chromatic dispersion uses a perpendicular vector to the beam direction:
  - `perp = (-dir.y, dir.x)`
  - offset positions drive **R** and **B** channel separation.

---

## Why it’s “faux”

This is not true volumetric lighting (no geometry occlusion, scattering volumes, or shadows).  
It’s a fast UI-friendly illusion built from **distance fields + tuned falloffs** that *reads* like a flashlight beam.



