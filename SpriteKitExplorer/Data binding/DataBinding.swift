/**
 
 # Data binding with SwiftUI
 
 A setup to explore data binding with SwiftUI and Observation.
 Work in progress...
 
 Created: 14 February 2024
 
 */

import SwiftUI
import Observation

struct DataBinding: View {
    var myPlayground = MyPlayground()
    
    var body: some View {
        
        Button("AddNumber") {
            let newNumber = myPlayground.myModel.arrayOfNumbers.count + 1
            myPlayground.myModel.addNumber(number: newNumber)
        }
        
        
        ForEach(myPlayground.myModel.arrayOfNumbers.indices, id: \.self) { index in
            let numberBinding = Binding<Int>(
                get: { myPlayground.myModel.arrayOfNumbers[index] },
                set: { newValue in
                    myPlayground.myModel.editNumber(index: index, newNumber: newValue)
                }
            )
            
            HStack {
                Text(String(myPlayground.myModel.arrayOfNumbers[index]))
                Stepper(value: numberBinding, in: 0...100) {}
                Slider(
                    value: Binding(
                        get: { Double(myPlayground.myModel.arrayOfNumbers[index]) },
                        set: { newValue in
                            myPlayground.myModel.editNumber(index: index, newNumber: Int(newValue))
                        }
                    ),
                    in: 0...10
                )
            }
            .padding()
        }
    }
}

@Observable class MyModel {
    var arrayOfNumbers: [Int] = [1, 2, 3]
    
    func addNumber(number: Int) {
        arrayOfNumbers.append(number)
    }
    
    func editNumber(index: Int, newNumber: Int) {
        arrayOfNumbers[index] = newNumber
    }
}

class MyPlayground {
    var myModel = MyModel()
}

#Preview {
    DataBinding()
}
