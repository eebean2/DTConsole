/*
 Developer Tools: Console
 
 DTConsole.swift 11/7/16
 Copyright © 2016 Erik Bean. All rights reserved.
*/

import UIKit
import MessageUI

@available(watchOS, unavailable, message: "Please connect to an iPhone using Conosle to enable custom watchOS logging")
public class DTConsole: NSObject, MFMailComposeViewControllerDelegate {
    
    /// The Console
    public static let sharedInstance = DTConsole()
    private var launcher: DTLauncher!
    
    /**************************************************************************/
    //                           MARK: Variables
    
    private var setupComplete = false
    /// Current orientation of the console
    public private(set) var orientation = ConsoleOrientation.default
    /// The current state of the console
    public private(set) var state = ConsoleState.close
    private var diagConsole = String()
    private var warningConsole = String()
    private var silentConsole = String()
    private var console: UITextView?
    private var background: UIView?
    private var textField: UITextField?
    private var buttonBar: UIView?
    private var fullButton: UIButton?
    private var view: UIView?
    private var controller: UIViewController?
    /// The console delegate
    public weak var delegate: DTConsoleDelegate?
    ///Command Delegate
    public weak var commandDelegate: DTCommandDelegate?
    
    /**************************************************************************/
    //                         MARK: Setup & init
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.enterTextEdit), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.exitTextEdit), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        launcher = DTLauncher()
    }
    
    /*
     * Setup the console
     * 
     * - Parameters:
     *      - controller: The contorller you are attaching the console to
     *      - type: (optional) The type of console you wish to use, default is console
     *      - orientation: (optional) The orientation you are setting the view, default is bottom
     *      - completion: (optional) The code you wish to execure after the function has funished
     */
    public func setup(on controller: UIViewController, type: ConsoleType = .default, orientation: ConsoleOrientation = .default, completion: ((Bool)->())?) {
        if Settings.liveOverride {
            SysConsole.prErr("Console is disabled in a live enviroment, to re-enable, in Xcode, change Console.Settings.liveOverride to false")
            completion?(false)
            return
        }
        self.orientation = orientation
        self.controller = controller
        self.view = controller.view
        switch type {
        case .default, .popover:
            self.consoleSetup()
        case .textPopover:
            self.consoleTextSetup()
        case .view:
            self.viewSetup()
            self.state = .asView
        case .textView:
            self.viewTextSetup()
            self.state = .asView
        }
        self.setupComplete = true
        completion?(true)
    }
    
    /// Setup the console with a view
    ///
    /// - Parameters:
    ///     - view: The view you are attaching the console to
    ///     - type: (optional) The type of console you wish to use, default is console
    ///     - orientation: (optional) The orientation you are setting the view, default is botton
    ///     - completion: (optional) The code you wish to execute after the function has finished
    /// - Important: The command "sendemail" will not work using this setup due to lack of UIViewController
    public func setup(on view: UIView, type: ConsoleType = .default, orientation: ConsoleOrientation = .default, completion: ((Bool)->())?) {
        if Settings.liveOverride {
            SysConsole.prErr("Console is disabled in a live enviroment, to re-enable, in Xcode, change Console.Settings.liveOverride to false")
            completion?(false)
            return
        }
        SysConsole.prOvr("This is only a transition fucntion. Please use Setup(on: UIViewController, ...)")
        self.orientation = orientation
        self.view = view
        switch type {
        case .default, .popover:
            self.consoleSetup()
        case .textPopover:
            self.consoleTextSetup()
        case .view:
            self.viewSetup()
            self.state = .asView
        case .textView:
            self.viewTextSetup()
            self.state = .asView
        }
        self.setupComplete = true
        completion?(true)
    }
    
    /**************************************************************************/
    //                           MARK: Overrides
    
    /// Override console setup with custom shape
    ///
    /// - Parameters:
    ///     - view: The view you are attaching the console to
    ///     - rect: The shape you desire the view to be
    public func overrideSetup(on view: UIView, withShape rect: CGRect, completion: ((Bool)->())?) {
        if Settings.liveOverride {
            SysConsole.prErr("Console is disabled in a live enviroment, to re-enable, in Xcode, change Console.Settings.liveOverride to false")
            completion?(false)
            return
        }
        self.view = view
        self.overrideWidth(rect.width)
        self.overrideHeight(rect.height)
        self.overridePoint(CGPoint(x: rect.minX, y: rect.minY))
        self.setupComplete = true
        completion?(true)
    }
    
    /// Override console width
    ///
    /// - Parameters:
    ///     - width: The width you wish to set
    public func overrideWidth(_ width: CGFloat) {
        if !setupComplete {
            SysConsole.prErr("Do not forget to setup the console!")
        }
        Settings.width = width
        Settings.widthOverride = true
    }
    
    /// Override console height
    ///
    /// - Parameters:
    ///     - height: The height you wish to set
    public func overrideHeight(_ height: CGFloat) {
        if !setupComplete {
            SysConsole.prErr("Do not forget to setup the console!")
        }
        Settings.height = height
        Settings.heightOverride = true
    }
    
    /// Override console starting point
    ///
    /// - Parameters:
    ///     - point: The point you wish the conosle to start at
    public func overridePoint(_ point: CGPoint) {
        if !setupComplete {
            SysConsole.prErr("Do not forget to setup the console!")
        }
        Settings.pointOverride = true
        Settings.x = point.x
        Settings.y = point.y
    }
    
    /// Reset width override
    public func resetWidth() {
        Settings.widthOverride = false
        Settings.width = nil
        consoleSetup()
    }
    
    /// Reset height override
    public func resetHeight() {
        Settings.heightOverride = false
        Settings.height = nil
        consoleSetup()
    }
    
    /// Reset point override
    public func resetPoint() {
        Settings.pointOverride = false
        Settings.x = nil
        Settings.y = nil
        consoleSetup()
    }
    
    /**************************************************************************/
    //                         MARK: Other Functions
    
    
    /// Resets the console to default peramaters, call Console.setup(...) to setup again
    ///
    /// - Note: This resets Move, Fullscreen, and Gesture Overrides, but NOT the live override.
    public func resetConsole() {
        
        // Setting Reset
        
        Settings.textColor = .green
        Settings.warningColor = .yellow
        Settings.errorColor = .red
        Settings.backgroundColor = .black
        Settings.width = nil
        Settings.height = nil
        Settings.x = nil
        Settings.y = nil
        Settings.widthOverride = false
        Settings.heightOverride = false
        Settings.pointOverride = false
        //        Settings.moveOverride = false
        Settings.fullscreenOverride = true
        Settings.gestureOverride = true
        Settings.clearOverride = false
        
        // Console Reset
        
        orientation = .default
        state = .close
        if state != .close {
            close()
        }
        if console != nil {
            console!.removeFromSuperview()
            console = nil
        }
        if textField != nil {
            textField!.removeFromSuperview()
            textField = nil
        }
        if buttonBar != nil {
            buttonBar!.removeFromSuperview()
            buttonBar = nil
        }
        if background != nil {
            background!.removeFromSuperview()
            background = nil
        }
        if fullButton != nil {
            fullButton?.removeFromSuperview()
            fullButton = nil
        }
        if view != nil {
            view = nil
        }
        
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        
        setupComplete = false
        
        SysConsole.prOvr("--Console reset complete, call Console.setup(...) to restart the console")
    }
    
    /// Destroys the console
    public func removeConsole() {
        orientation = .default
        state = .close
        if state != .close {
            close()
        }
        if console != nil {
            console!.removeFromSuperview()
            console = nil
        }
        if textField != nil {
            textField!.removeFromSuperview()
            textField = nil
        }
        if buttonBar != nil {
            buttonBar!.removeFromSuperview()
            buttonBar = nil
        }
        if background != nil {
            background!.removeFromSuperview()
            background = nil
        }
        if fullButton != nil {
            fullButton?.removeFromSuperview()
            fullButton = nil
        }
        if view != nil {
            view = nil
        }
        
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        
        setupComplete = false
        
        SysConsole.prOvr("--Console removal complete, call Console.setup(...) to restart the console")
    }
    
    /// Clears the console
    @objc public func clear() {
        console!.text = nil
    }
    

    public func sendEmail(to: [String]?) {
        if MFMailComposeViewController.canSendMail() && controller != nil {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(to)
            mail.setSubject("DTConsole Log")
            mail.setMessageBody(console!.text!, isHTML: false)
            controller!.present(mail, animated: true)
        } else {
            printError("Could not send email to \(to)", method: .both)
        }
    }
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    /**************************************************************************/
    //                         MARK: Private Func's
    
    private func viewSetup() {
        background = launcher.getBackground(forFrame: view!.frame)
        background!.frame = CGRect(x: 0, y: 0, width: view!.frame.width, height: view!.frame.height)
        background!.center = view!.center
        console = launcher.getConsole(forFrame: background!.frame)
        console!.frame = CGRect(x: 0, y: 0, width: background!.frame.width, height: background!.frame.height)
        background!.addSubview(console!)
        view!.addSubview(background!)
    }
    
    private func viewTextSetup() {
        background = launcher.getBackground(forFrame: view!.frame)
        background!.frame = CGRect(x: 0, y: 0, width: view!.frame.width, height: view!.frame.height)
        background!.center = view!.center
        console = launcher.getConsole(forFrame: background!.frame)
        console!.frame = CGRect(x: 0, y: 0, width: background!.frame.width, height: background!.frame.height - 40)
        textField = launcher.getTextField(forFrame: background!.frame)
        background!.addSubview(console!)
        background!.addSubview(textField!)
        view!.addSubview(background!)
    }
    
    private func consoleTextSetup() {
        background = launcher.getBackground(forFrame: view!.frame)
        background!.backgroundColor = DTConsole.Settings.backgroundColor
        background!.center.x = view!.center.x
        console = launcher.getConsole(forFrame: background!.frame, textBox: true)
        textField = launcher.getTextField(forFrame: background!.frame)
        let temp = launcher.getButtonBar(forFrame: background!.frame, textBox: true)
        buttonBar = temp.bar
        giveTargets(for: temp.buttons)
        
        if Settings.gestureOverride {
            let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(gestureCheck(_:)))
            let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(gestureCheck(_:)))
            swipeUp.direction = .up
            swipeDown.direction = .down
            console!.addGestureRecognizer(swipeUp)
            console!.addGestureRecognizer(swipeDown)
        }
        
        background!.addSubview(console!)
        background!.addSubview(buttonBar!)
        background!.addSubview(textField!)
        
        view!.addSubview(background!)
    }
    
    private func consoleSetup() {
        background = launcher.getBackground(forFrame: view!.frame)
        console = launcher.getConsole(forFrame: background!.frame)
        let temp = launcher.getButtonBar(forFrame: background!.frame)
        buttonBar = temp.bar
        giveTargets(for: temp.buttons)
        
        if Settings.gestureOverride {
            let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(gestureCheck(_:)))
            let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(gestureCheck(_:)))
            swipeUp.direction = .up
            swipeDown.direction = .down
            console!.addGestureRecognizer(swipeUp)
            console!.addGestureRecognizer(swipeDown)
        }
        
        background!.addSubview(console!)
        background!.addSubview(buttonBar!)
        background!.bringSubview(toFront: buttonBar!)
        view!.addSubview(background!)
    }
    
    private func giveTargets(for buttons: [UIButton]) {
        if Settings.diagnosticMode {
            SysConsole.prDiag("Did run \(#function)")
        }
        for button in buttons {
            if Settings.diagnosticMode {
                SysConsole.prDiag("Did receive button tagged: \(button.tag)")
            }
            if button.tag == 1 {
                button.addTarget(self, action: #selector(self.close), for: .touchUpInside)
            } else if button.tag == 2 {
                button.addTarget(self, action: #selector(self.fullScreenCheck(_:)), for: .touchUpInside)
                fullButton = button
            } else if button.tag == 3 {
                button.addTarget(self, action: #selector(self.clear), for: .touchUpInside)
            }
        }
    }
    
    @objc private func fullScreenCheck(_ sender: UIButton) {
        if state == .fullscreen {
            sender.setTitle("Fullscreen", for: .normal)
            exitFullscreen()
        } else {
            sender.setTitle("Exit", for: .normal)
            displayFullscreen()
        }
    }
    
    private var i = false
    @objc private func gestureCheck(_ sender: UISwipeGestureRecognizer) {
        if sender.direction == .up {
            if Settings.diagnosticMode {
                SysConsole.prDiag("Swiped Up")
            }
            if state == .open {
                if orientation == .top {
                    if i {
                        i = false
                        close()
                    } else {
                        print("Swipe up again to close")
                        i = true
                    }
                } else if orientation == .bottom || orientation == .default {
                    if i {
                        i = false
                        print("Swipe up again to launch fullscreen")
                    } else {
                        displayFullscreen()
                        fullButton?.setTitle("Exit", for: .normal)
                    }
                }
            } else if orientation == .top {
                exitFullscreen()
                fullButton?.setTitle("Fullscreen", for: .normal)
            } else {
                i = false
                return
            }
        } else if sender.direction == .down {
            if Settings.diagnosticMode {
                SysConsole.prDiag("Swiped Down")
            }
            if state == .open {
                if orientation == .bottom || orientation == .default {
                    if i {
                        i = false
                        close()
                    } else {
                        print("Swipe down again to close")
                        i = true
                    }
                } else if orientation == .top {
                    if i {
                        i = false
                        print("Swipe down again to launch fullscreen")
                    } else {
                        displayFullscreen()
                        fullButton?.setTitle("Exit", for: .normal)
                    }
                }
            } else if orientation == .bottom || orientation == .default {
                exitFullscreen()
                fullButton?.setTitle("Fullscreen", for: .normal)
            } else {
                i = false
                return
            }
        } else {
            print("Unknown Direction", method: .both)
        }
    }
    
    @objc private func enterTextEdit(_ sender: NSNotification) {
        if let keyboardSize = (sender.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if state == .asView {
                UIView.animate(withDuration: 0.5, animations: { 
                    let frame = CGRect(x: 0, y: 0, width: self.view!.frame.width, height: self.view!.frame.height - keyboardSize.height)
                    self.background!.frame = frame
                    if self.textField != nil {
                        self.console!.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - 40)
                        self.textField!.frame = CGRect(x: 0, y: frame.height - 40, width: frame.width, height: 40)
                    } else {
                        self.console!.frame = frame
                    }
                })
            } else {
                if state != .fullscreen {
                    delegate?.launchedFullscreen!()
                }
                UIView.animate(withDuration: 0.5, animations: {
                    let frame = CGRect(x: 20, y: 20, width: self.view!.frame.width - 40, height: self.view!.frame.height - keyboardSize.height - 20)
                    self.background!.frame = frame
                    if self.buttonBar != nil {
                        if self.textField != nil {
                            self.console!.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - 70)
                            self.buttonBar!.frame = CGRect(x: 0, y: frame.height - 70, width: frame.width, height: 30)
                        } else {
                            self.console!.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - 30)
                            self.buttonBar!.frame = CGRect(x: 0, y: frame.height - 30, width: frame.width, height: 30)
                        }
                    } else {
                        self.console!.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - 40)
                    }
                    if self.textField != nil {
                        self.textField!.frame = CGRect(x: 0, y: frame.height - 40, width: frame.width, height: 40)
                    }
                })
            }
        }
    }
    
    @objc private func exitTextEdit(_ sender: NSNotification) {
        if state == .fullscreen {
            displayFullscreen()
        } else if state != .asView {
            delegate?.closedFullscreen!()
            display()
            exitFullscreen()
        } else {
            UIView.animate(withDuration: 0.5, animations: {
                let frame = CGRect(x: 0, y: 0, width: self.view!.frame.width, height: self.view!.frame.height)
                self.background!.frame = frame
                self.console!.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - 40)
                self.textField!.frame = CGRect(x: 0, y: frame.height - 40, width: frame.width, height: 40)
            })
        }
    }
    
    /**************************************************************************/
    //                         MARK: Console Display
    
    /// Display the console as a popover
    @available(tvOS, unavailable, message: "You can only currently launch in fullscreen on tvOS")
    public func display() {
        if !setupComplete {
            SysConsole.prErr("You must complete setup first")
            return
        }
        if Settings.diagnosticMode {
            SysConsole.prDiag("Did run \(#function)")
        }
        switch orientation {
        case .default, .bottom:
            UIView.animate(withDuration: 0.5, animations: {
                self.background!.frame = CGRect(x: 20, y: self.view!.frame.height - self.launcher.getBackgroundFrame().height, width: self.launcher.getBackgroundFrame().width, height: self.launcher.getBackgroundFrame().height)
            }, completion: { (complete) in
                if complete {
                    self.state = .open
                    self.delegate?.consoleDidOpen!()
                } else {
                    SysConsole.prErr("Failed to open the console")
                }
            })
        case .top:
            UIView.animate(withDuration: 0.5, animations: {
                if UIApplication.shared.isStatusBarHidden {
                    self.background!.frame = CGRect(x: 20, y: 0, width: self.launcher.getBackgroundFrame().width, height: self.launcher.getBackgroundFrame().height)
                } else {
                    self.background!.frame = CGRect(x: 20, y: 0, width: self.launcher.getBackgroundFrame().width, height: self.launcher.getBackgroundFrame().height + UIApplication.shared.statusBarFrame.height)
                }
            }, completion: { (complete) in
                if complete {
                    self.state = .open
                    self.delegate?.consoleDidOpen!()
                } else {
                    SysConsole.prErr("Failed to open the console")
                }
            })
        }
    }
    
    /// Close the display
    @objc public func close() {
        if !setupComplete {
            SysConsole.prErr("You must complete setup first")
            return
        }
        if state == .close {
            SysConsole.prErr("Console must be open first, call Console.display()")
            return
        }
        if state == .asView {
            print("You cannot close a console when it is its own view. We recommend setting the segue to a UIView and displaying that as a full window, then removing that window from view when finished. This method will only remove console from it's superview.", method: .both)
            console!.removeFromSuperview()
            return
        }
        if Settings.diagnosticMode {
            SysConsole.prDiag("Did run \(#function)")
        }
        if textField != nil && textField!.isFirstResponder {
            textField!.resignFirstResponder()
        }
        switch orientation {
        case .default, .bottom:
            UIView.animate(withDuration: 0.5, animations: {
                self.background!.frame = CGRect(x: 20, y: self.view!.frame.maxY, width: self.launcher.getBackgroundFrame().width, height: self.launcher.getBackgroundFrame().height)
            }, completion: { (complete) in
                if complete {
                    self.state = .close
                    self.delegate?.consoleDidClose!()
                } else {
                    SysConsole.prErr("Failed to close the console")
                }
            })
        case .top:
            UIView.animate(withDuration: 0.5, animations: {
                self.background!.frame = CGRect(x: 20, y: 0 - self.background!.frame.height, width: self.launcher.getBackgroundFrame().width, height: self.launcher.getBackgroundFrame().height)
            }, completion: { (complete) in
                if complete {
                    self.state = .close
                    self.delegate?.consoleDidClose!()
                } else {
                    SysConsole.prErr("Failed to close the console")
                }
            })
        }
    }
    
    /// Launch fullscreen
    public func displayFullscreen() {
        if !setupComplete {
            SysConsole.prErr("You must complete setup first")
            return
        }
        if !Settings.fullscreenOverride {
            SysConsole.prErr("Fullscreen has been disabled, please re-enable it by setting Console.Settings.fullscreenOverride to true")
        }
        if Settings.diagnosticMode {
            SysConsole.prDiag("Did run \(#function)")
        }
        UIView.animate(withDuration: 0.5, animations: {
            var frame = CGRect()
            if UIApplication.shared.isStatusBarHidden {
                frame = CGRect(x: 20, y: 20, width: self.view!.frame.width - 40, height: self.view!.frame.height - 40)
            } else {
                frame = CGRect(x: 20, y: 20 + UIApplication.shared.statusBarFrame.height, width: self.view!.frame.width - 40, height: self.view!.frame.height - 40 - UIApplication.shared.statusBarFrame.height)
            }
            self.background!.frame = frame
            if self.buttonBar != nil {
                if self.textField != nil {
                    self.console!.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - 70)
                    self.buttonBar!.frame = CGRect(x: 0, y: frame.height - 70, width: frame.width, height: 30)
                } else {
                    self.console!.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - 30)
                    self.buttonBar!.frame = CGRect(x: 0, y: frame.height - 30, width: frame.width, height: 30)
                }
            } else {
                self.console!.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - 40)
            }
            if self.textField != nil {
                self.textField!.frame = CGRect(x: 0, y: frame.height - 40, width: frame.width, height: 40)
            }
        }, completion: { (complete) in
            if complete {
                self.state = .fullscreen
                self.delegate?.launchedFullscreen!()
            } else {
                SysConsole.prErr("Failed to launch fullscreen")
            }
        })
    }
    
    /// Exit Fullscreen into the previous orientation
    public func exitFullscreen() {
        if !setupComplete {
            SysConsole.prErr("You must complete setup first")
            return
        }
        if Settings.diagnosticMode {
            SysConsole.prDiag("Did run \(#function)")
        }
        exitFullscreen(to: orientation)
    }
    
    /// Exit fullscreen in a new orientation
    ///
    /// - Parameters:
    ///     - orientation: The new orientation you wish to exit to
    public func exitFullscreen(to orientation: ConsoleOrientation) {
        if !setupComplete {
            SysConsole.prErr("You must complete setup first")
            return
        }
        if Settings.diagnosticMode {
            SysConsole.prDiag("Did run \(#function)")
        }
        switch orientation {
        case .default, .bottom:
            UIView.animate(withDuration: 0.5, animations: {
                let frame = CGRect(x: 20, y: self.view!.frame.maxY - self.launcher.getBackgroundFrame().height, width: self.launcher.getBackgroundFrame().width, height: self.launcher.getHeight())
                self.background!.frame = frame
                if self.buttonBar != nil {
                    if self.textField != nil {
                        self.console!.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - 70)
                        self.buttonBar!.frame = CGRect(x: 0, y: frame.height - 70, width: frame.width, height: 30)
                    } else {
                        self.console!.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - 30)
                        self.buttonBar!.frame = CGRect(x: 0, y: frame.height - 30, width: frame.width, height: 30)
                    }
                } else {
                    self.console!.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - 40)
                }
                if self.textField != nil {
                    self.textField!.frame = CGRect(x: 0, y: frame.height - 40, width: frame.width, height: 40)
                }
            }, completion: { (complete) in
                if complete {
                    self.state = .open
                    self.orientation = orientation
                    self.delegate?.closedFullscreen!()
                } else {
                    SysConsole.prErr("Failed to minimize")
                }
            })
        case .top:
            UIView.animate(withDuration: 0.5, animations: {
                let frame = CGRect(x: 20, y: 0, width: self.launcher.getBackgroundFrame().width, height: self.launcher.getBackgroundFrame().height)
                self.background!.frame = frame
                if self.buttonBar != nil {
                    if self.textField != nil {
                        self.console!.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - 70)
                        self.buttonBar!.frame = CGRect(x: 0, y: frame.height - 70, width: frame.width, height: 30)
                    } else {
                        self.console!.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - 30)
                        self.buttonBar!.frame = CGRect(x: 0, y: frame.height - 30, width: frame.width, height: 30)
                    }
                } else {
                    self.console!.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height - 40)
                }
                if self.textField != nil {
                    self.textField!.frame = CGRect(x: 0, y: frame.height - 40, width: frame.width, height: 40)
                }
            }, completion: { (complete) in
                if complete {
                    self.state = .open
                    self.orientation = orientation
                    self.delegate?.closedFullscreen!()
                } else {
                    SysConsole.prErr("Failed to minimize")
                }
            })
        }
    }
    
    /**************************************************************************/
    //                              MARK: Print
    
    /// Print a message in the console
    ///
    /// Default color is Green (changeable in Settings)
    /// - Parameters:
    ///     - item: The item you wish to print.
    ///     - method: (optional) The method you wish to print the item.
    public func print<Anything>(_ message: Anything, method: PrintMethod = .default) {
        if !setupComplete {
            SysConsole.prErr("You must complete setup first")
            return
        }
        if method == .both {
            let tt = NSMutableAttributedString(attributedString: console!.attributedText!)
            tt.append(NSAttributedString(string: "\(message)\n", attributes: [NSForegroundColorAttributeName: Settings.textColor]))
            console!.attributedText = tt
            SysConsole.prOvr(message)
        } else if method == .xcodeOnly {
            SysConsole.prOvr(message)
        } else if method == .default {
            let tt = NSMutableAttributedString(attributedString: console!.attributedText!)
            tt.append(NSAttributedString(string: "\(message)\n", attributes: [NSForegroundColorAttributeName: Settings.textColor]))
            console!.attributedText = tt
        }
    }
    
    /// Print an warning message in the console
    ///
    /// Default color is Yellow (changeable in Settings)
    /// - Parameters:
    ///     - item: The item you wish to print.
    ///     - method: (optional) The method you wish to print the item.
    /// - Bug: Warning text is not currently coloring correctly, defaults to Green
    public func printWarning<Anything>(_ message: Anything, method: PrintMethod = .default) {
        if !setupComplete {
            SysConsole.prErr("You must complete setup first")
            return
        }
        if method == .both {
            let tt = NSMutableAttributedString(attributedString: console!.attributedText!)
            tt.append(NSAttributedString(string: ":: WARNING :: \(message)\n", attributes: [NSForegroundColorAttributeName: Settings.warningColor]))
            console!.attributedText = tt
        } else if method == .xcodeOnly {
            SysConsole.prWarn(message)
        } else if method == .default {
            let tt = NSMutableAttributedString(attributedString: console!.attributedText!)
            tt.append(NSAttributedString(string: ":: WARNING :: \(message)\n", attributes: [NSForegroundColorAttributeName: Settings.warningColor]))
            console!.attributedText = tt
        }
    }
    
    /// Print an error message in the console
    ///
    /// Default color is Red (changeable in Settings)
    /// - Parameters:
    ///     - item: The item you wish to print.
    ///     - method: (optional) The method you wish to print the item.
    /// - Bug: Warning text is not currently coloring correctly, defaults to Green
    public func printError<Anything>(_ message: Anything, method: PrintMethod = .default) {
        if !setupComplete {
            SysConsole.prErr("You must complete setup first")
            return
        }
        if method == .both {
            let tt = NSMutableAttributedString(attributedString: console!.attributedText!)
            tt.append(NSAttributedString(string: ":: ERROR :: \(message)\n", attributes: [NSForegroundColorAttributeName: Settings.errorColor]))
            console!.attributedText = tt
        } else if method == .xcodeOnly {
            SysConsole.prErr(message)
        } else if method == .default {
            let tt = NSMutableAttributedString(attributedString: console!.attributedText!)
            tt.append(NSAttributedString(string: ":: ERROR :: \(message)\n", attributes: [NSForegroundColorAttributeName: Settings.errorColor]))
            console!.attributedText = tt
        }
    }
    
    public func printDiag<Anything>(_ message: Anything, method: PrintMethod = .both) {
        if !setupComplete {
            SysConsole.prErr("You must complete setup first")
            return
        }
        if method == .both {
            let tt = NSMutableAttributedString(attributedString: console!.attributedText!)
            tt.append(NSAttributedString(string: ":: DIAGNOSTIC :: \(message)\n", attributes: [NSForegroundColorAttributeName: Settings.diagnosticColor]))
            console!.attributedText = tt
            SysConsole.prDiag(message)
        } else if method == .xcodeOnly {
            SysConsole.prDiag(message)
        } else if method == .default {
            let tt = NSMutableAttributedString(attributedString: console!.attributedText!)
            tt.append(NSAttributedString(string: ":: DIAGNOSTIC :: \(message)\n", attributes: [NSForegroundColorAttributeName: Settings.diagnosticColor]))
            console!.attributedText = tt
        }
    }
    
    public func printSilent<Anything>(_ message: Anything, method: PrintMethod = .default) {
        if method == .both {
            silentConsole.append("\(message)\n")
            SysConsole.prOvr(message)
        } else if method == .xcodeOnly {
            SysConsole.prOvr(message)
        } else if method == .default {
            silentConsole.append("\(message)\n")
        }
    }
    
    public func diag<Anything>(_ message: Anything, method: PrintMethod = .both) {
        if method == .both {
            diagConsole.append("\(message)\n")
            SysConsole.prDiag(message)
        } else if method == .xcodeOnly {
            SysConsole.prDiag(message)
        } else if method == .default {
            diagConsole.append("\(message)\n")
        }
    }
    
    public func warning<Anything>(_ message: Anything, method: PrintMethod = .both) {
        if method == .both {
            warningConsole.append("\(message)\n")
            SysConsole.prOvr(message)
        } else if method == .xcodeOnly {
            SysConsole.prOvr(message)
        } else if method == .default {
            warningConsole.append("\(message)\n")
        }
    }
    
    public func printDiagnostics(method: PrintMethod = .default) {
        print(diagConsole, method: method)
    }
    
    public func printWarnings(method: PrintMethod = .default) {
        print(warningConsole, method: method)
    }
    
    /**************************************************************************/
    //                             MARK: Settings
    
    /// Change the background color of the console
    ///
    /// - Parameter color: The color you wish to set the console background
    public func setBackgroundColor(_ color: UIColor) {
        Settings.backgroundColor = color
        background?.backgroundColor = color
    }
    
    /// Change the console text color
    ///
    /// - Parameter color: The color you wish to set the console text
    public func setTextColor(_ color: UIColor) {
        Settings.textColor = color
        console?.textColor = color
    }
    
    /// Change the textfield border and text color
    ///
    /// - Parameter color: The color you wish to set the textbox background
    public func setTextFieldColor(_ color: UIColor) {
        Settings.textFieldColor = color
        textField?.tintColor = color
        textField?.textColor = color
        textField?.layer.borderColor = color.cgColor
        textField?.attributedPlaceholder = NSAttributedString(string: "Enter Command Here", attributes: [NSForegroundColorAttributeName: color])
    }
    
    internal func enableDiagMode() {
        Settings.diagnosticMode = true
        background?.backgroundColor = Settings.diagnosticBackgroundColor
        console?.textColor = Settings.diagnosticTextColor
    }
    
    internal func disableDiagMode() {
        Settings.diagnosticMode = false
        background?.backgroundColor = Settings.backgroundColor
        console?.textColor = Settings.textColor
    }
    
    internal func setDiagBackgroundColor(_ color: UIColor) {
        if Settings.diagnosticMode {
            background?.backgroundColor = color
        }
        Settings.diagnosticBackgroundColor = color
    }
    
    internal func setDiagTextColor(_ color: UIColor) {
        if Settings.diagnosticMode {
            console?.textColor = color
        }
        Settings.diagnosticTextColor = color
    }
    
    /// Console Settings
    public class Settings {
        // Console Design
        
        /// The text color in the console
        ///
        /// - Note: Default is Green
        public static var textColor: UIColor = .green
        /// The warning text color in the console
        ///
        /// Default is Yellow
        public static var warningColor: UIColor = .yellow
        /// The error text color in the console
        ///
        /// Default is Red
        public static var errorColor: UIColor = .red
        /// The error text color in the console
        ///
        /// Default is Blue
        public static var diagnosticColor: UIColor = .cyan
        /// The background color in the console
        ///
        /// - Note: Default is Black
        public static var backgroundColor: UIColor = .black
        /// The border and text color for the textbox
        ///
        /// - Note: Default is white
        public static var textFieldColor: UIColor = .white
        
        // Console Layout
        
        /// The height of a custom console
        public internal(set) static var width: CGFloat?
        /// The width of a custom console
        public internal(set) static var height: CGFloat?
        /// The x point of a point override for the console starting position
        public internal(set) static var x: CGFloat?
        /// The y point of a point override for the console starting position
        public internal(set) static var y: CGFloat?
        
        // Console Overrides
        
        /// Custom Width Override
        ///
        /// - Note: It is not recommended to have a 0 width, best practice is to set your final width, and move the entire console on and off screen
        public internal(set) static var widthOverride = false
        /// Custom Height Override
        ///
        /// - Note: It is not recommended to have a 0 height, best practice is to set your final height, move the entire console on and off screen
        public internal(set) static var heightOverride = false
        /// Custom console starting point
        ///
        /// - Note: This is the top left corner of the console
        public internal(set) static var pointOverride = false
        /// Allow a movable console on iPad
        ///
        /// - Note: False by default, set true to allow moving
        /// - Attention: DO NOT USE IN LIVE APP
        /// feature is not stable
        /// - Experiment: This feature is for iPad only. It may not work, or may even crash the app.
        @available(tvOS, unavailable, message: "The tvOS Console is static")
        @available(*, unavailable, message: "A moveable console is not avalible in this release")
        public static var moveOverride = false
        /// Fullscreen support on iOS
        ///
        /// - Note: True by default, set false to disable the fullscreen button
        @available(tvOS, unavailable, message: "You can only use fullscreen on tvOS.")
        public static var fullscreenOverride = true
        /// Set true for live enviroments
        public static var liveOverride = false
        /// Guesture Support in Popover Console
        ///
        /// - Note: True by default, set false to disable gestures
        @available(tvOS, unavailable, message: "Gestures are not supported on tvOS")
        public static var gestureOverride: Bool = true
        /// Option to disable the clear button
        ///
        /// - Note: False by default, set true to disable the clear button
        public static var clearOverride = false
        internal static var diagnosticMode = false
        internal static var diagnosticBackgroundColor: UIColor = .lightGray
        internal static var diagnosticTextColor: UIColor = .black
        
        /// Set an email for trial use
        @available(*, unavailable, introduced: 0.1.2, deprecated: 0.1.3, message: "You no longer need authentication")
        public func setEmail(_ email: String) { }
    }
    
    // MARK: Deprecated
    
    /// Setup the console for use as a popover
    ///
    /// - Parameters:
    ///     - view: The view you are attaching the console to
    ///     - orientation: (optional) The orientation you are setting the view
    @available(*, unavailable, introduced: 0.1, deprecated: 0.1.3, message: "Please use Setup(on: UIViewController, ...)")
    public func setup(on view: UIView, orientation: ConsoleOrientation = .default, completion: ((Bool)->())?) {
        setup(on: view, type: .default, orientation: orientation) { (success) in
            completion?(success)
        }
    }
    
    /// Setup and display the console for use as it's own view in another view
    ///
    /// - Parameters:
    ///     - view: The view you are attaching the console to
    @available(*, unavailable, introduced: 0.1, deprecated: 0.1.3, message: "Please use Setup(on: UIViewController, ...)")
    public func setupAndDisplay(in view: UIView, completion: ((Bool)->())?) {
        setup(on: view, type: .view) { (success) in
            completion?(success)
        }
    }
    
    /// Setup the console with a textbox for use as a popover
    ///
    /// - Parameters:
    ///     - view: The view you are attaching the console to
    ///     - orientation: (optional) The orientation you are setting the view
    @available(*, unavailable, introduced: 0.1, deprecated: 0.1.3, message: "Please use Setup(on: UIViewController, ...)")
    public func setupTextConsole(on view: UIView, orientation: ConsoleOrientation = .default, completion: ((Bool)->())?) {
        setup(on: view, type: .textPopover, orientation: orientation) { (success) in
            completion?(success)
        } 
    }
    
    /// Setup and display a console with textbox for use as it's own view in another view
    ///
    /// - Parameters:
    ///     - view: The view you are attaching the console to
    @available(*, unavailable, introduced: 0.1, deprecated: 0.1.3, message: "Please use Setup(on: UIViewController, ...)")
    public func setupTextConsoleAndDisplay(in view: UIView, completion: ((Bool) ->())?) {
        setup(on: view, type: .textView) { (success) in
            completion?(success)
        }
    }
    
    @available(*, unavailable, introduced: 0.1.2, deprecated: 0.1.3, message: "You no longer need authentication")
    public class Authentication {
        
        /// Re-Authenticate using your current key
        ///
        /// - Paramater passcode: The passcode associated with your API key
        /// - Note: It is recommended to update your key and passcode in Auth0.plist and use DTConsole.Authentication.authenticate() instead
        /// - Note: DTSuite keys are authenticated using DTConsole.Authenticate.authenticateDTSuite(withKey:, passcode:)
        @available(*, unavailable, introduced: 0.1.2, deprecated: 0.1.3, message: "You no longer need authentication")
        static public func authenticate(passcode: String, completion: ((Bool)->())?) { }
        
        /// Authenticate using a new key and passcode
        ///
        /// - Paramater
        ///     - key: The new API key to authenticate with
        ///     - passcode: The passcode associated with your API key
        /// - Note: It is recommended to update your key and passcode in Auth0.plist and use DTConsole.Authentication.authenticate() instead
        /// - Note: DTSuite keys are authenticated using DTConsole.Authenticate.authenticateDTSuite(withKey:, passcode:)
        @available(*, unavailable, introduced: 0.1.2, deprecated: 0.1.3, message: "You no longer need authentication")
        static public func authenticate(withKey key: String, passcode: String) { }
        
        /// Authenticate using key and passocde from your Auth0.plist
        ///
        /// - Note: DTSuite keys are authenticated using DTConsole.Authenticate.authenticateDTSuite(withKey:, passcode:)
        @available(*, unavailable, introduced: 0.1.2, deprecated: 0.1.3, message: "You no longer need authentication")
        static public func authenticate(completion: ((Bool)->())?) { }
        
        /// Activate trial of DTConsole
        ///
        /// - Paramater email: The email address you wish to use for the trial
        /// - Note: DTSuite trial codes are authenticated using DTConsole.Authenticate.activateDTSuiteTrial(withEmail:, key:)
        @available(*, unavailable, introduced: 0.1.2, deprecated: 0.1.3, message: "You no longer need authentication")
        static public func activateTrial(withEmail email: String) { }
        
        /// Activate DTConsole using a trial of DTSuite
        @available(*, unavailable, introduced: 0.1.2, deprecated: 0.1.3, message: "DTConsole will NOT be part of a suite")
        static public func activateDTSuiteTrial(withEmail email: String, key: String) { }
        
        /// Activate DTConsole using a DTSuite key
        @available(*, unavailable, introduced: 0.1.2, deprecated: 0.1.3, message: "DTConsole will NOT be part of a suite")
        static public func authenticateDTSuite(withKey key: String, passcode: String) { }
    }
}

