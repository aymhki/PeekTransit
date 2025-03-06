import MapKit
import Foundation
import SwiftUI

class CustomStopAnnotation: MKPointAnnotation {
    let stopNumber: Int
    var stopData: [String: Any]
    
    init(stopNumber: Int, stopData: [String: Any]) {
        self.stopNumber = stopNumber
        self.stopData = stopData
        super.init()
    }
}
