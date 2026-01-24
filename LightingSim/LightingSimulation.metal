#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Distance to a line segment
// P0: Start, P1: End
// Returns float2(distance, t parameter 0..1)
float2 sdSegmentSim(float2 p, float2 a, float2 b) {
    float2 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return float2( length( pa - ba*h ), h );
}

[[ stitchable ]] half4 lightingSimulation(float2 position, SwiftUI::Layer layer, float2 size, float intensity, float disperse, float rotation, float radius) {
    
    //Position is slightly down from center
    float2 sourceUV = float2(0.5, 0.6);
    float2 sourcePos = sourceUV * size;
    
    // Direction based on rotation
    // Base direction is Down (PI/2)
    float baseAngle = M_PI_F / 2.0; 
    float angle = baseAngle + rotation;
    float2 dir = float2(cos(angle), sin(angle));
    
    // Beam Geometry
    // We treat the beam as an expanding cone along a segment.
    float beamLen = length(size);
    float2 endPos = sourcePos + dir * beamLen;
    
    // Calculate SDF to the central axis
    float2 segment = sdSegmentSim(position, sourcePos, endPos);
    float distToAxis = segment.x;
    float t = segment.y;
    
    float w0 = radius;
    
    float spreadFactor = 2.0 * disperse; // Tuning constant
    
    float distAlongAxis = t * beamLen;
    float startSmoothing = smoothstep(0.0, 0.2, t);
    float currentWidth = w0 + distAlongAxis * spreadFactor * startSmoothing;
    
    
    //CA Functions
    float clampedDisperse = min(disperse, 0.78) / 0.78;
    float offsetAmt = 160.0 * clampedDisperse * t;
    
    float2 perp = float2(-dir.y, dir.x);
    
    float2 posR = position + perp * offsetAmt;
    float distR = sdSegmentSim(posR, sourcePos, endPos).x;
    float beamR = 1.0 - smoothstep(0.0, currentWidth, distR);
    
    beamR = pow(beamR, 1.2); // Softness
    
    float distG = distToAxis;
    float beamG = 1.0 - smoothstep(0.0, currentWidth, distG);
    beamG = pow(beamG, 1.2); // Softness
    
    float2 posB = position - perp * offsetAmt;
    float distB = sdSegmentSim(posB, sourcePos, endPos).x;
    float beamB = 1.0 - smoothstep(0.0, currentWidth, distB);
    beamB = pow(beamB, 1.2); // Softness
    
    float density = w0 / currentWidth;
    float flux = density * density;
    float distFromSource = length(position - sourcePos);
    float falloff = 1.0 / (1.0 + distFromSource * 0.005);
    
    // Halo
    half3 lightColor = half3(beamR, beamG, beamB);
    
    float outerSpreadFactor = spreadFactor * 8.0;
    float outerWidth = w0 + distAlongAxis * outerSpreadFactor * startSmoothing;
    float outerBeam = 1.0 - smoothstep(0.0, outerWidth, distG);
    outerBeam = pow(outerBeam, 3.5);
    
    float outerIntensity = 0.05 * intensity * falloff;
    
    
    half3 mainBeamColor = lightColor * half(intensity * flux * falloff);
    half3 outerBeamColor = half3(outerBeam) * half(outerIntensity);
    
    half3 combinedLight = mainBeamColor + outerBeamColor;
    
    half4 original = layer.sample(position);
    half3 color = original.rgb + combinedLight;
    
    const half a = 2.51;
    const half b = 0.03;
    const half c = 2.43;
    const half d = 0.59;
    const half e = 0.14;
    
    half3 mapped = clamp((color * (a * color + b)) / (color * (c * color + d) + e), 0.0, 1.0);
    
    return half4(mapped, original.a);
}
