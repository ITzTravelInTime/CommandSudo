//
//  File.swift
//  
//
//  Created by Pietro Caruso on 10/07/21.
//

import Foundation
import SwiftLoggedPrint

internal class Printer: LoggedPrinter{
    override class var prefix: String{
        return "[CommandSudo]"
    }
    
    override class var printerID: String{
        return "CommandSudo"
    }
}

internal func print( _ str: Any){
    Printer.print("\(str)")
}
