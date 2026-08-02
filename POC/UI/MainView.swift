import SwiftUI

@MainActor
struct MainView: View {
    @StateObject private var vm: ARVM

    init() {
        _vm = StateObject(
            wrappedValue: ARVM()
        )
    }

    var body: some View {
        ZStack {
            ARViewBox(vm: vm)
                .ignoresSafeArea()

            crosshair

            VStack {
                status

                Spacer()

                controls
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }

    private var status: some View {
        Text(vm.state.msg)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                Color.black.opacity(0.6)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 10
                )
            )
    }

    private var crosshair: some View {
        Image(systemName: "plus")
            .font(
                .system(
                    size: 26,
                    weight: .bold
                )
            )
            .foregroundStyle(.white)
            .shadow(radius: 3)
            .allowsHitTesting(false)
    }

    private var controls: some View {
        VStack(spacing: 8) {
            HStack {
                Button("Place") {
                    vm.spawn()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!vm.state.lidarOK)

                Button("Wave") {
                    vm.pulse()
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .disabled(!vm.state.hasBot)

                Button("Clear") {
                    vm.clear()
                }
                .buttonStyle(.bordered)
                .disabled(!vm.state.hasBot)
            }

            HStack {
                Button("<-") {
                    vm.turn(15)
                }
                .buttonStyle(.bordered)
                .disabled(!vm.state.hasBot)

                Button("->") {
                    vm.turn(-15)
                }
                .buttonStyle(.bordered)
                .disabled(!vm.state.hasBot)

                Button(
                    vm.state.meshOn
                        ? "Hide Mesh"
                        : "Show Mesh"
                ) {
                    vm.toggleMesh()
                }
                .buttonStyle(.bordered)
                .disabled(!vm.state.lidarOK)
            }

            Text(
                vm.state.hasBot
                    ? "drag to move the robot"
                    : "aim at floor / table"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(
            Color.black.opacity(0.65)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12
            )
        )
    }
}
