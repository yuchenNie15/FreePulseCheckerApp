import ComposableArchitecture

extension AlertState where Action == MeasurementFeature.Action.Alert {
    internal static var stopMeasuring: Self {
        AlertState {
            TextState("Stop measuring?")
        } actions: {
            ButtonState(role: .destructive, action: .stopTapped) {
                TextState("Stop")
            }
            ButtonState(role: .cancel) {
                TextState("Keep Measuring")
            }
        } message: {
            TextState("This reading won't be saved.")
        }
    }
}
