import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .environmentObject(QuestionnaireViewModel())
        .environmentObject(SymptomTrackerViewModel.shared)
        .environmentObject(AppTabRouter())
}
