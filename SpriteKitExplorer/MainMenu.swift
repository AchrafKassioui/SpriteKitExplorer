/**
 
 # Main menu
 
 Created: 19 January 2024
 Updated: 29 January 2024
 
 */

import SwiftUI

struct MainMenu: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Combine", destination: Combine())
                NavigationLink("Simulation Speed", destination: SimulationSpeed())
                NavigationLink("Lighting", destination: Lighting())
                NavigationLink("Fling Drag", destination: FlingDrag())
                NavigationLink("Filters", destination: ImageFilters())
            }
            .navigationTitle("SpriteKit Explorer")
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Image("SpriteKit_128x128_2x")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .padding()
                }
            }
        }
    }
}

#Preview {
    MainMenu()
}
