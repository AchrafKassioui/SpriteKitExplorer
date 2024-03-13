/**
 
 # Main menu
 
 This SwiftUI view is the view that you would see if you build and run the project.
 This view is a SwiftUI menu that navigates you to several SpriteKit scenes within the project.
 
 However, the value of this project is in the code itself. Several scenes are not linked in this menu.
 
 Created: 19 January 2024
 Updated: 13 March 2024
 
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
                NavigationLink("Data Binding", destination: DataBinding())
                NavigationLink("SpriteKit UI", destination: SpriteKitUI())
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
