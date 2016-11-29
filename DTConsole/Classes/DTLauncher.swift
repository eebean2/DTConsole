/*
 Developer Tools: Console
 
 DTLauncher.swift 11/7/16
 Copyright © 2016 Erik Bean. All rights reserved.
*/

import UIKit

internal class DTLauncher: NSObject, UITextFieldDelegate {
    
    /**************************************************************************/
    //                           Design & Animation
    
    // Console Design
    internal private(set) var orientation = ConsoleOrientation.default
    private var frame: CGRect!
    
    // Console Layout
    internal var x: CGFloat? = { return DTConsole.Settings.x }()
    internal var y: CGFloat? = { return DTConsole.Settings.y }()
    
    internal var height: CGFloat!
    internal var width: CGFloat!
    
    // Console Overrides
    internal var widthOverride: Bool = { return DTConsole.Settings.widthOverride }()
    internal var heightOverride: Bool = { return DTConsole.Settings.heightOverride }()
    internal var pointOverride: Bool = { return DTConsole.Settings.pointOverride }()
    
    /**************************************************************************/
    
    internal func getBackground(forFrame frame: CGRect, orientation: ConsoleOrientation = .default) -> UIView {
        self.frame = frame
        self.orientation = orientation
        let view = UIView(frame: getBackgroundFrame())
        if DTConsole.Settings.diagnosticMode {
            view.backgroundColor = DTConsole.Settings.diagnosticBackgroundColor
        } else {
            view.backgroundColor = DTConsole.Settings.backgroundColor
        }
        return view
    }
    
    internal func getConsole(forFrame frame: CGRect, textBox: Bool = false) -> UITextView {
        let console = UITextView()
        if textBox {
            console.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - 70)
        } else {
            console.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - 30)
        }
        console.backgroundColor = .clear
        if DTConsole.Settings.diagnosticMode {
            console.textColor = DTConsole.Settings.diagnosticTextColor
        } else {
            console.textColor = DTConsole.Settings.textColor
        }
        #if os(iOS)
            console.isEditable = false
        #endif
        console.text = "Welcome to \(Bundle.main.infoDictionary![kCFBundleNameKey as String]!)\n\n"
        return console
    }
    
    internal func getButtonBar(forFrame frame: CGRect, textBox: Bool = false) -> (bar: UIView, buttons: [UIButton]) {
        var buttons = [UIButton]()
        let buttonBar = UIView()
        if textBox {
            buttonBar.frame = CGRect(x: 0, y: frame.height - 70, width: frame.width, height: 30)
        } else {
            buttonBar.frame = CGRect(x: 0, y: frame.height - 30, width: frame.width, height: 30)
        }
        let close = UIButton()
        if DTConsole.Settings.fullscreenOverride {
            let fullButton = UIButton()
            if !DTConsole.Settings.clearOverride {
                let clear = UIButton(frame: CGRect(x: buttonBar.frame.width / 3, y: 0, width: buttonBar.frame.width / 3, height: 30))
                clear.setTitle("Clear", for: .normal)
                clear.tag = 3
                close.frame = CGRect(x: buttonBar.frame.width - (buttonBar.frame.width / 3), y: 0, width: buttonBar.frame.width / 3, height: 30)
                fullButton.frame = CGRect(x: 0, y: 0, width: buttonBar.frame.width / 3, height: 30)
                buttons.append(clear)
                buttonBar.addSubview(clear)
            } else {
                close.frame = CGRect(x: buttonBar.frame.width / 2, y: 0, width: buttonBar.frame.width / 2, height: 30)
                fullButton.frame = CGRect(x: 0, y: 0, width: buttonBar.frame.width / 2, height: 30)
            }
            fullButton.setTitle("Fullscreen", for: .normal)
            fullButton.tag = 2
            buttons.append(fullButton)
            buttonBar.addSubview(fullButton)
        } else {
            if !DTConsole.Settings.clearOverride {
                let clear = UIButton(frame: CGRect(x: 0, y: 0, width: buttonBar.frame.width / 2, height: 30))
                clear.setTitle("Clear", for: .normal)
                clear.tag = 3
                close.frame = CGRect(x: buttonBar.frame.width / 2, y: 0, width: buttonBar.frame.width / 2, height: 30)
                buttons.append(clear)
                buttonBar.addSubview(clear)
            } else {
                close.frame = buttonBar.frame
            }
        }
        close.setTitle("Close", for: .normal)
        close.setTitleColor(.white, for: .normal)
        close.tag = 1
        buttons.append(close)
        buttonBar.addSubview(close)
        return (buttonBar, buttons)
    }
    
    internal func getTextField(forFrame frame: CGRect) -> UITextField {
        let text = UITextField(frame: CGRect(x: 0, y: frame.height - 40, width: frame.width, height: 40))
        text.placeholder = "Enter Command Here"
        text.font = .systemFont(ofSize: 15)
        text.borderStyle = .line
        text.autocorrectionType = .no
        text.returnKeyType = .default
        text.clearButtonMode = .whileEditing
        text.textAlignment = .center
        text.textColor = DTConsole.Settings.textFieldColor
        text.tintColor = DTConsole.Settings.textFieldColor
        text.layer.borderColor = DTConsole.Settings.textFieldColor.cgColor
        text.layer.borderWidth = 1.0
        text.attributedPlaceholder = NSAttributedString(string: "Enter Command Here", attributes: [NSForegroundColorAttributeName: UIColor.white])
        text.delegate = self
        return text
    }
    
    internal func getBackgroundFrame() -> CGRect {
        var w = CGFloat()
        var h = CGFloat()
        var x = CGFloat()
        var y = CGFloat()
        
        switch orientation {
        case .default:
            if UIDevice.current.systemName == "tvOS" {
                h = frame.height - 40
                height = frame.height - 40
            } else {
                h = frame.height / 3
                height = frame.height / 3
            }
            
            w = frame.width - 40
            width = frame.width - 40
        case .top, .bottom:
            h = frame.height / 3
            height = frame.height / 3
            
            w = frame.width - 40
            width = frame.width - 40
        case .left, .right:
            h = frame.height - 40
            height = frame.height - 40
            
            w = frame.width / 3
            width = frame.width / 3
        }
        
        if pointOverride {
            x = self.x!
            y = self.y!
        } else {
            switch orientation {
            case .default:
                x = 20
                if UIDevice.current.systemName == "tvOS" {
                    y = 20
                } else {
                    y = frame.maxY
                }
            case .top:
                x = 20
                y = frame.minY
            case .bottom:
                x = 20
                y = frame.maxY
            case .left:
                x = frame.minX
                y = 20
            case .right:
                x = frame.maxX
                y = 20
            }
        }
        
        return CGRect(x: x, y: y, width: w, height: h)
    }
    
    internal func getHeight() -> CGFloat {
        if DTConsole.Settings.heightOverride {
            if DTConsole.Settings.height == nil {
                SysConsole.prErr("No height set in Console.Settings, returning default")
                DTConsole.Settings.heightOverride = false
                return getHeight()
            } else {
                return DTConsole.Settings.height!
            }
        } else {
            switch orientation {
            case .default, .top, .bottom:
                return frame.height / 3
            case .left, .right:
                return height
            }
        }
    }
    
    internal func getWidth() -> CGFloat {
        if DTConsole.Settings.widthOverride {
            if DTConsole.Settings.width == nil {
                SysConsole.prErr("No width set in Console.Settings, returning default")
                DTConsole.Settings.widthOverride = false
                return getWidth()
            } else {
                return DTConsole.Settings.width!
            }
        } else {
            switch orientation {
            case .default, .top, .bottom:
                return width
            case .left, .right:
                return frame.width / 3
            }
        }
    }
    
    internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    internal func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text != "" {
            DTCommand().filterCommand(for: textField.text!)
        }
    }
}
