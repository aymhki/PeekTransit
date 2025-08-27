import MapKit
import Foundation
import SwiftUI

class CustomStopAnnotation: MKPointAnnotation {
    let stopNumber: Int
    var stopData: Stop
    
    init(stopNumber: Int, stopData: Stop) {
        self.stopNumber = stopNumber
        self.stopData = stopData
        super.init()
    }
}
