/**
 
 # Helper functions for numbers
 
 Achraf Kassioui
 Created: 27 March 2024
 Updated: 27 March 2024
 
 */

import Foundation

func truncateToDecimalPlace(value: CGFloat, decimalPlaces: Int) -> CGFloat {
    let divisor = pow(10.0, CGFloat(decimalPlaces))
    return floor(value * divisor) / divisor
}
