/*
 Developer Tools: Console
 
 DTCommand.swift 11/14/16
 Copyright © 2016 Erik Bean. All rights reserved.
*/

import UIKit

internal class DTCommand {
    
    internal static let sharedInstance = DTCommand()
    let console = DTConsole.sharedInstance
    weak var delegate: DTCommandDelegate? { return DTConsole.sharedInstance.commandDelegate }
    var commands = [StockCommands.enterFS.rawValue, StockCommands.exitFS.rawValue, StockCommands.close.rawValue, StockCommands.enableDiag.rawValue, StockCommands.disableDiag.rawValue, StockCommands.diagTextColor.rawValue, StockCommands.diagBackground.rawValue, StockCommands.background.rawValue, StockCommands.textColor.rawValue, StockCommands.textBox.rawValue, StockCommands.email.rawValue]
    private var userCommands: Array<String>? {
        return delegate?.commandList()
    }
    
    private init() { }
    
    var command = String()
    var arguments = [String]()
    var total = Int()
    func filterCommand(for string: String) {
        let text = string.lowercased()
        
        SysConsole.prDiag("Command Text: \(text)")
        
        let parts = text.components(separatedBy: " ")
        
        SysConsole.prDiag("Command Parts: \(parts)")
        
        total = parts.count
        
        SysConsole.prDiag("Total Parts: \(total)")
        
        for part in parts {
            
            SysConsole.prDiag("Command: \(part)")
            
            if part.characters.first == "-" {
                if command == "" && total == 1 {
                    checkCommand(command: String(part.characters.dropFirst(1)), arguments: arguments)
                    arguments.removeAll()
                    command = ""
                    
                    SysConsole.prDiag("Exited")
                    
                } else if command != "" {
                    console.printError("You may only use one command at a time!", method: .both)
                    checkCommand(command: String(part.characters.dropFirst(1)), arguments: arguments)
                    arguments.removeAll()
                    command = ""
                    
                    SysConsole.prDiag("Exited")
                    
                    return
                } else {
                    command = String(part.characters.dropFirst(1))
                }
            } else {
                if total == 1 {
                    arguments.append(part)
                    checkCommand(command: command, arguments: arguments)
                    arguments.removeAll()
                    command = ""
                    
                    SysConsole.prDiag("Exited")
                    
                } else {
                    arguments.append(part)
                }
            }
            total -= 1
        }
    }
    
    func checkCommand(command c: String, arguments: [String]?) {
        let command = c.lowercased()
        if commands.contains(command) {
            if arguments!.isEmpty {
                commandList(command)
            } else {
                commandList(command, argument: arguments!.first)
            }
        } else if userCommands != nil && userCommands!.contains(command) {
            if delegate == nil {
                console.printError("CommandDelegate not set! Please call console.commandDelegate = self", method: .both)
            } else {
                
                delegate!.didGetCommand(command, withArguments: arguments)
            }
        } else {
            console.printError("Invalid Command", method: .both)
        }
    }
    
    func commandList(_ command: String, argument: String? = nil) {
        switch command {
        case StockCommands.enterFS.rawValue:
            console.displayFullscreen()
            console.print("Fullscreen Enabled", method: .both)
        case StockCommands.exitFS.rawValue:
            console.exitFullscreen()
            console.print("Fullscreen Disabled", method: .both)
        case StockCommands.close.rawValue:
            console.close()
            console.print("Console Closed", method: .both)
        case StockCommands.enableDiag.rawValue:
            console.enableDiagMode()
            console.print("Diagnostic Mode Enabled", method: .both)
        case StockCommands.disableDiag.rawValue:
            console.disableDiagMode()
            console.print("Diagnostic Mode Disabled", method: .both)
        case StockCommands.diagTextColor.rawValue:
            let color = getColor(argument)
            console.setDiagTextColor(color)
            console.print("Diagnostic text color changed to \(color)", method: .both)
        case StockCommands.diagBackground.rawValue:
            let color = getColor(argument)
            console.setDiagBackgroundColor(color)
            console.print("Diagnostic background color changed to \(color)", method: .both)
        case StockCommands.background.rawValue:
            let color = getColor(argument)
            console.setBackgroundColor(color)
            console.print("Background color changed to \(color)", method: .both)
        case StockCommands.textColor.rawValue:
            let color = getColor(argument)
            console.setTextColor(color)
            console.print("Text color changed to \(color)", method: .both)
        case StockCommands.textBox.rawValue:
            let color = getColor(argument)
            console.setTextFieldColor(color)
            console.print("Textbox changed to \(color)", method: .both)
        case StockCommands.reset.rawValue:
            console.resetConsole()
            console.print("Console Reset", method: .xcodeOnly)
        case StockCommands.email.rawValue:
            console.sendEmail(to: [argument!])
        default:
            console.printError("Unknown System Command \(command), please check function \(#function) for missing StockCommands variables", method: .both)
        }
    }
    
    func getColor(_ string: String?) -> UIColor {
        var color = String()
        if string != nil {
            color = string!
        }
        switch color {
        case "black":       return UIColor.black
        case "blue":        return UIColor.blue
        case "brown":       return UIColor.brown
        case "cyan":        return UIColor.cyan
        case "darkgray":    return UIColor.darkGray
        case "daktext":     return UIColor.darkText
        case "gray":        return UIColor.gray
        case "green":       return UIColor.green
        case "lightgray":   return UIColor.lightGray
        case "lighttext":   return UIColor.lightText
        case "magenta":     return UIColor.magenta
        case "orange":      return UIColor.orange
        case "purple":      return UIColor.purple
        case "red":         return UIColor.red
        case "whte":        return UIColor.white
        case "yellow":      return UIColor.yellow
            // DEFAULT as of 0.1.3 is Green instead of nil
        default:
            console.printError("Invalid Text Color", method: .both)
            console.printError("Setting color to default Green", method: .both)
            return UIColor.green
        }
    }
}
