import SwiftUI
import ARKit
import TipKit

struct ContentView: View {
    @ObservedObject var viewModel = DrawingViewModel()
    @State var drawingName: String = ""
    @State var textTitle: String = ""
    @State var textContent: String = ""
    @State var showMyDrawings = false
    @State private var isAnimating = false
    @State private var glowIntensity: Double = 0.5

    var body: some View {
        ZStack {
            ARViewContainer(viewModel: viewModel).edgesIgnoringSafeArea(.all)
            
            // Animated background gradient
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.1),
                    Color.blue.opacity(0.1),
                    Color.cyan.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: isAnimating)

            VStack {
                if !viewModel.isDrawing {
                    topBar
                }
                Spacer()

                if viewModel.isArtistMode {
                    if viewModel.isFreeHand {
                        drawButton
                    }
                } else {
                    captureButton
                }
            }
            .padding()
        }
        .onAppear {
            isAnimating = true
        }
        .overlay(alignment: .top) {
            HStack {
                Spacer()
                Rectangle()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(Color.white.opacity(0.00001)) // workaround
                    .gesture(
                        TapGesture(count: 3)
                            .onEnded {
                                viewModel.isArtistMode.toggle()
                            }
                    )
                    .popoverTip(InlineTip())

                Spacer()
            }
        }
        .onAppear {
            try? Tips.configure()
        }
        .animation(.spring(), value: viewModel.isArtistMode)
        .alert("🚀 Saved 🎉", isPresented: $viewModel.showSuccess) {}
        .alert("Save Drawing?", isPresented: $viewModel.showSaveAlert) {
            TextField("Enter the name", text: $drawingName)
            Button("Save") {
                viewModel.save(with: drawingName)
                drawingName = String()
            }
        }
        .alert("Add Text", isPresented: $viewModel.showTextAlert) {
            TextField("Enter text content", text: $textContent)
            Button("Save") {
                viewModel.saveText(textContent)
                textTitle = String()
                textContent = String()
            }
            Button("Cancel", role: .cancel) {
                textTitle = String()
                textContent = String()
            }
        }
        .sheet(isPresented: $showMyDrawings) {
            MyDrawingsView(viewModel: viewModel)
        }
        .sensoryFeedback(.success, trigger: viewModel.found)
    }
    
    private var topBar: some View {
        HStack(alignment: .top) {
            if viewModel.isArtistMode {
                VStack(alignment: .leading, spacing: 16) {
                    // Enhanced total counter with glow effect
                    
                    actionButton(title: "Total: \(viewModel.allDrawings.count + viewModel.allTextNodes.count)", icon: "list.bullet", color: .red) {
                        showMyDrawings.toggle()
                    }
                    
                    divider
                    HStack {
                        actionButton(title: "Free Hand", icon: "text.bubble", color: .indigo, action: viewModel.didTapFreeHand)
                        
                        Spacer()
                        
                        actionButton(title: "Text", icon: "text.bubble", color: .orange, action: viewModel.didTapText)
                    }
                    
                    if viewModel.isFreeHand {
                        artistButtons
                    }
                }
                .animation(.snappy, value: viewModel.isFreeHand)
            }
            Spacer()
        }
    }

    private var divider: some View {
    RoundedRectangle(cornerRadius: 2, style: .continuous)
        .foregroundStyle(
            LinearGradient(
                colors: [.purple, .blue, .cyan],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .frame(width: 140, height: 3)
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
        .padding(.vertical, 16)
    }
    
    private var artistButtons: some View {
        VStack(alignment: .leading, spacing: 16) {
            actionButton(title: "Save", icon: "square.and.arrow.down", color: .purple, action: viewModel.didTapSave)
            actionButton(title: "Reset", icon: "arrow.clockwise", color: .blue, action: viewModel.reset)
            divider
            
            // Enhanced radius stepper
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.cyan)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                
                Text("Radius \(Int(viewModel.radius))m")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Stepper("", value: $viewModel.radius, in: 3...20)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .cyan.opacity(0.4), radius: 8, x: 0, y: 4)
            )
        }
    }

    private var drawButton: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: viewModel.isDrawing ? "stop.circle.fill" : "pencil.circle.fill")
                    .font(.title2)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                
                Text(viewModel.isDrawing ? "Stop" : "Draw")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
        }
        .modifier(mainButtonStyle(color: .green))
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in viewModel.start() }
                .onEnded { _ in viewModel.stop() }
        )
        .scaleEffect(viewModel.isDrawing ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.isDrawing)
    }
    
    private var captureButton: some View {
        Button(action: viewModel.capture) {
            HStack(spacing: 12) {
                Image(systemName: "camera.circle.fill")
                    .font(.title2)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                
                Text("Capture")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
        }
        .modifier(mainButtonStyle(color: .green))
        .scaleEffect(isAnimating ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
        }
        .modifier(smallButtonStyle(color: color))
    }
    
    private func mainButtonStyle(color: Color) -> some ViewModifier {
        ButtonStyleModifier(color: color, width: 180, height: 55)
    }
    
    private func smallButtonStyle(color: Color) -> some ViewModifier {
        ButtonStyleModifier(color: color, width: 140, height: 40)
    }
}

struct CapsuleTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minWidth: 100)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [.purple, .blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}

struct ButtonStyleModifier: ViewModifier {
    let color: Color
    let width: CGFloat
    let height: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .fontWeight(.semibold)
            .padding()
            .frame(width: width, height: height)
            .background(
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: height / 2)
                            .stroke(
                                LinearGradient(
                                    colors: [color, color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .foregroundColor(.white)
            .shadow(color: color.opacity(0.6), radius: 15, x: 0, y: 8)
    }
}

#Preview {
    ContentView(viewModel: .init())
}
