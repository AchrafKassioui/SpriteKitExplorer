/**
 
 # Data Models
 
 Examples of how to model data in Swift
 
 Achraf Kassioui
 Created: 13 June 2024
 Updated: 13 June 2024
 
 */

import Foundation

// MARK: Sample Data
/**
 
 Source: https://medium.com/@jpmtech/swiftui-navigationsplitview-30ce87b5de03
 
 */
struct DataModel: Identifiable, Hashable {
    let id = UUID()
    let text: String
}

class SampleData {
    static let firstScreenData = [
        DataModel(text: "🚂 Trains"),
        DataModel(text: "✈️ Planes"),
        DataModel(text: "🚗 Automobiles"),
    ]
    
    static let secondScreenData = [
        DataModel(text: "Slow"),
        DataModel(text: "Regular"),
        DataModel(text: "Fast"),
    ]
    
    static let lastScreenData = [
        DataModel(text: "Wrong"),
        DataModel(text: "So-so"),
        DataModel(text: "Right"),
    ]
}
