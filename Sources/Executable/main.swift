import Foundation
import VaporToolbox

try testCloud()

try boot().wait().run()
