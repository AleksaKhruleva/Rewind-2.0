import SwiftUI

public struct ContentView: View {
    public init() {}
    
    public var body: some View {
        Text("Rewind will be\nhere soon...")
            .font(.largeTitle)
            .foregroundStyle(.pink)
            .padding()
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
