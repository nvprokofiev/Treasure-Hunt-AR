import SwiftUI
import ARKit
import TipKit

struct ContentView: View {
    @ObservedObject var viewModel = DrawingViewModel()
    @State var drawingName: String = ""
    @State var showMyDrawings = false

    var body: some View {
        ZStack {
            ARViewContainer(viewModel: viewModel).edgesIgnoringSafeArea(.all)

            VStack {
                if !viewModel.isDrawing {
                    topBar
                }
                Spacer()

                if viewModel.isArtistMode {
                    drawButton
                } else {
                    captureButton
                }
            }
            .padding()
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
        .sheet(isPresented: $showMyDrawings) {
            MyDrawingsView(viewModel: viewModel)
        }
        .sensoryFeedback(.success, trigger: viewModel.found)
    }
    
    private var topBar: some View {
        HStack(alignment: .top) {
            if viewModel.isArtistMode {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Total: \(viewModel.allDrawings.count)")
                        .modifier(CapsuleTextStyle())
                    divider
                    artistButtons
                }
            }
            Spacer()
        }
    }

    private var divider: some View {
        RoundedRectangle(cornerRadius: 1, style: .continuous)
            .foregroundStyle(Color.white.opacity(0.3))
            .frame(width: 100, height: 2)
            .padding(.vertical, 8)
    }
    
    private var artistButtons: some View {
        VStack(alignment: .leading, spacing: 16) {
            actionButton(title: "Save", color: .purple, action: viewModel.didTapSave)
            actionButton(title: "Reset", color: .blue, action: viewModel.reset)
            divider
            actionButton(title: "View All", color: .red) {
                showMyDrawings.toggle()
            }
            Stepper("Radius \(Int(viewModel.radius))m", value: $viewModel.radius, in: 3...20)
                .frame(width: 200)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minWidth: 100)
                .background(
                    Capsule()
                        .fill(Color(uiColor: .magenta).opacity(0.6))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
        }
    }

    private var drawButton: some View {
        Button(action: {}) {
            Text(viewModel.isDrawing ? "Stop" : "Draw")
        }
        .modifier(mainButtonStyle(color: .green))
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in viewModel.start() }
                .onEnded { _ in viewModel.stop() }
        )
        .sensoryFeedback(.success, trigger: viewModel.isDrawing)
    }
    
    private var captureButton: some View {
        Button(action: viewModel.capture) {
            Text("Capture 📸")
        }
        .modifier(mainButtonStyle(color: .green))
    }

    private func actionButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
        }
        .modifier(smallButtonStyle(color: color))
    }
    
    private func mainButtonStyle(color: Color) -> some ViewModifier {
        ButtonStyleModifier(color: color, width: 140, height: 55)
    }
    
    private func smallButtonStyle(color: Color) -> some ViewModifier {
        ButtonStyleModifier(color: color, width: 100, height: 40)
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
                    .fill(Color.black.opacity(0.6))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
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
                LinearGradient(gradient: Gradient(colors: [color.opacity(0.9), color.opacity(0.7)]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
            )
            .foregroundColor(.white)
            .cornerRadius(height / 2)
            .overlay(
                RoundedRectangle(cornerRadius: height / 2)
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ContentView(viewModel: .init())
}
