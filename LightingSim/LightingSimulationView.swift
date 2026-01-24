//
//  LightingSimulationView.swift
//  SwiftJan10
//
//  Created by Minsang Choi on 1/19/26.
//

import SwiftUI

struct LightingSimulationView: View {
    @State private var intensity: Float = 1.5
    @State private var disperse: Float = 0.5 // Width 0..1
    @State private var rotation: Float = 0 // Radians
    @State private var radius: Float = 30.0 // Light Source Radius
    
    var body: some View {
        ZStack {
            
            LinearGradient(colors: [.black.mix(with: .gray, by: 0.2), .gray.mix(with: .black, by: 0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing:40){
                
                
                VStack(spacing:4){
                    Text("Lighting Simulation")
                        .font(.system(size: 14, design: .monospaced))
                        .bold()
                    Text("-")
                    HStack{
                        
                        Text("I : \(intensity, specifier:"%.2f") /")
                        Text("D : \(disperse, specifier:"%.2f") /")
                        Text("R : \(radius, specifier:"%.0f")")

                    }

                }
                .foregroundStyle(.white)
                .font(.system(size:10, design: .monospaced))
                .textCase(.uppercase)


                ZStack{
                    Color.black
                        .frame(width: 380, height:400)
                        .layerEffect(
                            ShaderLibrary.lightingSimulation(
                                .float2(380, 80), // Size from GeometryReader
                                .float(intensity),
                                .float(disperse),
                                .float(rotation),
                                .float(radius)
                            ),
                            maxSampleOffset: CGSize(width: 0, height: 0)
                        )
                        .cornerRadius(20)
                        .shadow(color:.white.opacity(0.2), radius: 1)
                        
                        .rotationEffect(Angle(degrees: 180))
                        .animation(.spring, value: rotation)


                    //MARK: Add disperse approximation lines
                    Canvas { context, size in
                        let center = CGPoint(x: 190, y: 40)
                        let beamLength: CGFloat = 400
                        let baseAngle = Float.pi / 2.0
                        let angle = baseAngle + rotation
                        
                        // Background Radar Lines
                        // Concentric circles centered at light source
                        for r in stride(from: 40.0, through: 500.0, by: 40.0) {
                             let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                             let circlePath = Path(ellipseIn: rect)
                             context.stroke(circlePath, with: .color(.white.opacity(0.05)), style: StrokeStyle(lineWidth: 1))
                        }
                        
                        // Radial grid lines
                        for i in 0..<12 {
                            let radParams = Double(i) * (.pi / 6)
                            var line = Path()
                            line.move(to: center)
                            let endPt = CGPoint(x: center.x + CGFloat(cos(radParams) * 500), y: center.y + CGFloat(sin(radParams) * 500))
                            line.addLine(to: endPt)
                            context.stroke(line, with: .color(.white.opacity(0.03)), style: StrokeStyle(lineWidth: 1))
                        }
                         
                        // Shader logic replication
                        let dir = CGPoint(x: CGFloat(cos(angle)), y: CGFloat(sin(angle)))
                        let perp = CGPoint(x: -dir.y, y: dir.x)
                        
                        let spreadFactor = 2.0 * disperse
                        let outerSpreadFactor = spreadFactor * 4.0
                        
                        // Path generation helper
                        func pathFor(spread: Float, color: Color, style: StrokeStyle = StrokeStyle()) {
                            var leftLine = Path()
                            var rightLine = Path()
                            
                            // Sample points to capture smoothing
                            let steps = 100
                            for i in 0...steps {
                                let t = Float(i) / Float(steps)
                                let dist = CGFloat(t) * beamLength
                                
                                // Smoothing logic from shader: smoothstep(0.0, 0.2, t)
                                // t is segment.y (0..1 along beamLen).
                                // beamLen in shader is length(size) = length(380, 80) ~ 388.
                                // Our loop t is 0..1. So it matches.
                                let clampedT = max(0, min(1, t))
                                let smooth = clampedT * clampedT * (3 - 2 * clampedT) // smoothstep(0,1,x)
                                // Shader uses smoothstep(0.0, 0.2, t)
                                let t_mapped = t / 0.2
                                let clamped_t_mapped = max(0, min(1, t_mapped))
                                let startSmoothing = clamped_t_mapped * clamped_t_mapped * (3 - 2 * clamped_t_mapped)
                                
                                // Width calculation
                                let w0 = radius
                                // Shader: w0 + distAlongAxis * spread * smoothing
                                let currentWidth = w0 + Float(dist) * spread * startSmoothing
                                
                                let pointOnAxis = CGPoint(x: center.x + dir.x * dist, y: center.y + dir.y * dist)
                                let offset = CGPoint(x: perp.x * CGFloat(currentWidth), y: perp.y * CGFloat(currentWidth))
                                
                                let leftP = CGPoint(x: pointOnAxis.x + offset.x, y: pointOnAxis.y + offset.y)
                                let rightP = CGPoint(x: pointOnAxis.x - offset.x, y: pointOnAxis.y - offset.y)
                                
                                if i == 0 {
                                    leftLine.move(to: leftP)
                                    rightLine.move(to: rightP)
                                } else {
                                    leftLine.addLine(to: leftP)
                                    rightLine.addLine(to: rightP)
                                }
                            }
                            context.stroke(leftLine, with: .color(color), style: style)
                            context.stroke(rightLine, with: .color(color), style: style)
                        }
                        
                        // Draw Main Beam
                        pathFor(spread: spreadFactor, color: .yellow, style: StrokeStyle(lineWidth: 0.5, dash: [2]))
                        
                        // Draw Halo
                        pathFor(spread: outerSpreadFactor, color: .white, style: StrokeStyle(lineWidth: 0.5, dash: [2]))
                        
                    }
                    .frame(width: 380, height: 400)
                    .cornerRadius(20)
                    .rotationEffect(Angle(degrees: 180)) // Match the lighting layer rotation
                    
                    .allowsHitTesting(false)
                    
                }
                
                VStack{
                    VStack(alignment: .leading){
                        Text("Intensity")
                        Slider(value: $intensity, in:0...3)
                    }
                    VStack(alignment: .leading){
                        Text("Disperse")
                        Slider(value: $disperse, in:0.1...1)
                    }
                    VStack(alignment: .leading){
                        Text("radius")
                        Slider(value: $radius, in:0...120)
                    }

                }
                .foregroundStyle(.white)
                .font(.system(size:10, design: .monospaced))
                .textCase(.uppercase)
                .tint(.yellow)
                .padding()
                .background(.gray.opacity(0.1))
                .cornerRadius(20)
                

            }
            .padding()
        }
    }
}


#Preview {
    LightingSimulationView()
}
