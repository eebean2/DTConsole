/*
 Developer Tools: Console
 
 DTConsole.swift 11/7/16
 Copyright © 2016 Erik Bean. All rights reserved.
*/

import UIKit
import Auth0
import Lock

@available(watchOS, unavailable, message: "Please connect to an iPhone using Conosle to enable custom watchOS logging")
public class DTConsole {
    
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
    private var console: UITextView?
    private var background: UIView?
    private var textField: UITextField?
    private var buttonBar: UIView?
    private var fullButton: UIButton?
    private var view: UIView?
    private var setup = false
    /// The console delegate
    public weak var delegate: DTConsoleDelegate?
    ///Command Delegate
    public var commandDelegate: DTCommandDelegate? {
        get { return DTCommand().delegate }
        set { DTCommand().delegate = newValue }
    }
    
    /**************************************************************************/
    //                         MARK: Auth Variables
    internal var token: AuthTokenStatus = .unauthenticated
    internal var profile: A0UserProfile?
    internal var status = 0
    internal var ex = Date()
    internal var localToken: A0Token?
    internal var email: String?
    
    /**************************************************************************/
    //                         MARK: Setup & init
    
    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.enterTextEdit(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.exitTextEdit), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        launcher = DTLauncher()
    }
    
    /// Setup the console for use as a popover
    ///
    /// - Parameters:
    ///     - view: The view you are attaching the console to
    ///     - orientation: (optional) The orientation you are setting the view
    public func setup(on view: UIView, orientation: ConsoleOrientation = .default, completion: ((Bool)->())?) {
        if Settings.liveOverride {
            SysConsole.prErr("Console is disabled in a live enviroment, to re-enable, in Xcode, change Console.Settings.liveOverride to false")
            completion?(false)
            return
        }
        if status != 200 {
            DTAuth().login(key: nil, passcode: nil, completion: { (profile) in
                if profile != nil {
                    self.status = DTAuth().getStatus(profile!.appMetadata["type"] as! String)
                    self.orientation = orientation
                    self.view = view
                    self.consoleSetup()
                    self.setupComplete = true
                    completion?(true)
                } else {
                    SysConsole.prErr("Auth :: There was an error logging in, please try again")
                    self.status = DTAuth().getStatus("sorry")
                    Settings.gestureOverride = false
                    Settings.fullscreenOverride = false
//                    Settings.moveOverride = false
                    self.view = view
                    self.consoleSetup()
                    self.setupComplete = true
                    completion?(true)
                }
            })
        } else if ex > Date() {
            status = DTAuth().getStatus("expired")
            Settings.gestureOverride = false
            Settings.fullscreenOverride = false
//            Settings.moveOverride = false
            self.view = view
            self.consoleSetup()
            self.setupComplete = true
            completion?(true)
        } else {
            self.orientation = orientation
            self.view = view
            self.consoleSetup()
            self.setupComplete = true
            completion?(true)
        }
    }
    
    /// Setup and display the console for use as it's own view in another view
    ///
    /// - Parameters:
    ///     - view: The view you are attaching the console to
    public func setupAndDisplay(in view: UIView, completion: ((Bool)->())?) {
        if Settings.liveOverride {
            SysConsole.prErr("Console is disabled in a live enviroment, to re-enable, in Xcode, change Console.Settings.liveOverride to false")
            completion?(false)
            return
        }
        if status != 200 {
            DTAuth().login(key: nil, passcode: nil, completion: { (profile) in
                
                self.status = DTAuth().getStatus(profile!.appMetadata["type"] as! String)
                if self.status != 200 {
                    SysConsole.prErr("While \(self.token.description), you may only use the standard popover console from the bottom.")
                    completion?(false)
                    return
                } else {
                    self.view = view
                    self.viewSetup()
                    self.state = .asView
                    self.setupComplete = true
                    completion?(true)
                }
                
//                if profile != nil {
//                    
//                } else {
//                    SysConsole.prErr("Auth :: There was an error logging in, please try again")
//                    completion?(false)
//                    return
//                }
            })
        } else if ex > Date() {
            status = DTAuth().getStatus("expired")
            SysConsole.prErr("While \(self.token.description), you may only use the standard popover console from the bottom.")
            completion?(false)
            return
        } else {
            self.view = view
            self.viewSetup()
            self.state = .asView
            self.setupComplete = true
            completion?(true)
        }
    }
    
    /// Setup the console with a textbox for use as a popover
    ///
    /// - Parameters:
    ///     - view: The view you are attaching the console to
    ///     - orientation: (optional) The orientation you are setting the view
    public func setupTextConsole(on view: UIView, orientation: ConsoleOrientation = .default, completion: ((Bool)->())?) {
        if Settings.liveOverride {
            SysConsole.prErr("Console is disabled in a live enviroment, to re-enable, in Xcode, change Console.Settings.liveOverride to false")
            completion?(false)
            return
        }
        if status != 200 {
            DTAuth().login(key: nil, passcode: nil, completion: { (profile) in
                
                self.status = DTAuth().getStatus(profile!.appMetadata["type"] as! String)
                if self.status != 200 {
                    SysConsole.prErr("While \(self.token.description), you may only use the standard popover console from the bottom.")
                    completion?(false)
                    return
                } else {
                    self.view = view
                    self.orientation = orientation
                    self.consoleTextSetup()
                    self.setupComplete = true
                    completion?(true)
                }
                
//                if profile != nil {
//                    
//                } else {
//                    SysConsole.prErr("Auth :: There was an error logging in, please try again")
//                    completion?(false)
//                    return
//                }
            })
        } else if ex > Date() {
            status = DTAuth().getStatus("expired")
            SysConsole.prErr("While \(self.token.description), you may only use the standard popover console from the bottom.")
            completion?(false)
            return
        } else {
            self.view = view
            self.orientation = orientation
            self.consoleTextSetup()
            self.setupComplete = true
            completion?(true)
        }
    }
    
    /// Setup and display a console with textbox for use as it's own view in another view
    ///
    /// - Parameters:
    ///     - view: The view you are attaching the console to
    public func setupTextConsoleAndDisplay(in view: UIView, completion: ((Bool) ->())?) {
        if Settings.liveOverride {
            SysConsole.prErr("Console is disabled in a live enviroment, to re-enable, in Xcode, change Console.Settings.liveOverride to false")
            completion?(false)
            return
        }
        if status != 200 {
            DTAuth().login(key: nil, passcode: nil, completion: { (profile) in
                if profile != nil {
                    self.status = DTAuth().getStatus(profile!.appMetadata["type"] as! String)
                    if self.status != 200 {
                        SysConsole.prErr("While \(self.token.description), you may only use the standard popover console from the bottom.")
                        completion?(false)
                        return
                    } else {
                        self.view = view
                        self.viewTextSetup()
                        self.state = .asView
                        self.setupComplete = true
                        completion?(true)
                    }
                } else {
                    SysConsole.prErr("Auth :: There was an error logging in, please try again")
                    completion?(false)
                    return
                }
            })
        } else if ex > Date() {
            status = DTAuth().getStatus("expired")
            SysConsole.prErr("While \(self.token.description), you may only use the standard popover console from the bottom.")
            completion?(false)
        } else {
            self.view = view
            self.viewTextSetup()
            self.state = .asView
            self.setupComplete = true
            completion?(true)
        }
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
        if status != 200 {
            DTAuth().login(key: nil, passcode: nil, completion: { (profile) in
                if profile != nil {
                    self.status = DTAuth().getStatus(profile!.appMetadata["type"] as! String)
                    if self.status != 200 {
                        SysConsole.prErr("While \(self.token.description), you may only use the standard popover console from the bottom.")
                        completion?(false)
                        return
                    } else {
                        self.view = view
                        self.overrideWidth(rect.width)
                        self.overrideHeight(rect.height)
                        self.overridePoint(CGPoint(x: rect.minX, y: rect.minY))
                        completion?(true)
                    }
                } else {
                    SysConsole.prErr("Auth :: There was an error logging in, please try again")
                    completion?(false)
                    return
                }
            })
        } else if ex > Date() {
            status = DTAuth().getStatus("expired")
            SysConsole.prErr("While \(self.token.description), you may only use the standard popover console from the bottom.")
            completion?(false)
            return
        } else {
            self.view = view
            self.overrideWidth(rect.width)
            self.overrideHeight(rect.height)
            self.overridePoint(CGPoint(x: rect.minX, y: rect.minY))
            completion?(true)
        }
    }
    
    /// Override console width
    ///
    /// - Parameters:
    ///     - width: The width you wish to set
    public func overrideWidth(_ width: CGFloat) {
        if status != 200 {
            SysConsole.prErr("While \(token.description), you may only use the standard popover console from the bottom.")
            return
        }
        Settings.width = width
        Settings.widthOverride = true
    }
    
    /// Override console height
    ///
    /// - Parameters:
    ///     - height: The height you wish to set
    public func overrideHeight(_ height: CGFloat) {
        if status != 200 {
            SysConsole.prErr("While \(token.description), you may only use the standard popover console from the bottom.")
            return
        }
        Settings.height = height
        Settings.heightOverride = true
    }
    
    /// Override console starting point
    ///
    /// - Parameters:
    ///     - point: The point you wish the conosle to start at
    public func overridePoint(_ point: CGPoint) {
        if status != 200 {
            SysConsole.prErr("While \(token.description), you may only use the standard popover console from the bottom.")
            return
        }
        Settings.pointOverride = true
        Settings.x = point.x
        Settings.y = point.y
    }
    
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
        if status == 200 {
//            Settings.moveOverride = false
            Settings.fullscreenOverride = true
            Settings.gestureOverride = true
            Settings.clearOverride = false
        }
        
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
        
        setupComplete = false
        
        SysConsole.prOvr("--Console reset complete, call Console.setup(...) to restart the console")
    }
    
    /// Destroys the console
    public func removeConsole() {
        setupComplete = false
        orientation = .default
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
    
    /// Clears the console
    @objc public func clear() {
        console!.text = nil
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
            let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(gestureCheck(_:)))
            let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(gestureCheck(_:)))
            swipeUp.direction = .up
            swipeDown.direction = .down
            swipeLeft.direction = .left
            swipeRight.direction = .right
            console!.addGestureRecognizer(swipeUp)
            console!.addGestureRecognizer(swipeDown)
            console!.addGestureRecognizer(swipeLeft)
            console!.addGestureRecognizer(swipeRight)
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
            let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(gestureCheck(_:)))
            let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(gestureCheck(_:)))
            swipeUp.direction = .up
            swipeDown.direction = .down
            swipeLeft.direction = .left
            swipeRight.direction = .right
            console!.addGestureRecognizer(swipeUp)
            console!.addGestureRecognizer(swipeDown)
            console!.addGestureRecognizer(swipeLeft)
            console!.addGestureRecognizer(swipeRight)
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
                } else {
                    i = false
                    return
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
                } else {
                    i = false
                    return
                }
            } else if orientation == .bottom || orientation == .default {
                exitFullscreen()
                fullButton?.setTitle("Fullscreen", for: .normal)
            } else {
                i = false
                return
            }
        } else if sender.direction == .left {
            if Settings.diagnosticMode {
                SysConsole.prDiag("Swiped Left")
            }
            if state == .open {
                if orientation == .left {
                    if i {
                        i = false
                        close()
                    } else {
                        print("Swipe left again to close")
                        i = true
                    }
                } else if orientation == .right {
                    if i {
                        i = false
                        print("Swipe left again to launch fullscreen")
                    } else {
                        displayFullscreen()
                        fullButton?.setTitle("Exit", for: .normal)
                    }
                } else {
                    i = false
                    return
                }
            } else if orientation == .left {
                exitFullscreen()
                fullButton?.setTitle("Fullscreen", for: .normal)
            } else {
                i = false
                return
            }
        } else if sender.direction == .right {
            if Settings.diagnosticMode {
                SysConsole.prDiag("Swiped Right")
            }
            if state == .open {
                if orientation == .right {
                    if i {
                        i = false
                        close()
                    } else {
                        print("Swipe right again to close")
                        i = true
                    }
                } else if orientation == .left {
                    if i {
                        i = false
                        print("Swipe right again to launch fullscreen")
                    } else {
                        displayFullscreen()
                        fullButton?.setTitle("Exit", for: .normal)
                    }
                } else {
                    i = false
                    return
                }
            } else if orientation == .right {
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
        if state != .fullscreen {
            delegate?.launchedFullscreen!()
        }
        
        if let keyboardSize = (sender.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
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
    
    @objc private func exitTextEdit() {
        if state == .fullscreen {
            displayFullscreen()
        } else {
            delegate?.closedFullscreen!()
            display()
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
        if state != .close {
            SysConsole.prErr("You have already displayed the console, call Console.close() to close it")
            return
        }
        if Settings.diagnosticMode {
            SysConsole.prDiag("Did run \(#function)")
        }
        switch orientation {
        case .default, .bottom:
            UIView.animate(withDuration: 0.5, animations: {
                self.background!.frame = CGRect(x: 20, y: self.view!.frame.maxY - self.background!.frame.height, width: self.background!.frame.width, height: self.background!.frame.height)
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
                self.background!.frame = CGRect(x: 20, y: 0, width: self.launcher.getWidth(), height: self.launcher.getHeight())
            }, completion: { (complete) in
                if complete {
                    self.state = .open
                    self.delegate?.consoleDidOpen!()
                } else {
                    SysConsole.prErr("Failed to open the console")
                }
            })
        case .left:
            UIView.animate(withDuration: 0.5, animations: {
                self.background!.frame = CGRect(x: 0, y: self.view!.center.y - (self.background!.frame.height / 2), width: self.launcher.getWidth(), height: self.launcher.getHeight())
            }, completion: { (complete) in
                if complete {
                    self.state = .open
                    self.delegate?.consoleDidOpen!()
                } else {
                    SysConsole.prErr("Failed to open the console")
                }
            })
        case .right:
            UIView.animate(withDuration: 0.5, animations: {
                self.background!.frame = CGRect(x: self.view!.frame.maxX - self.background!.frame.width, y: self.view!.center.y - (self.background!.frame.height / 2), width: self.launcher.getWidth(), height: self.launcher.getHeight())
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
                self.background!.frame = CGRect(x: 20, y: self.view!.frame.maxY, width: self.launcher.getWidth(), height: self.launcher.getHeight())
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
                self.background!.frame = CGRect(x: 20, y: self.view!.frame.minY - self.background!.frame.height, width: self.launcher.getWidth(), height: self.launcher.getHeight())
            }, completion: { (complete) in
                if complete {
                    self.state = .close
                    self.delegate?.consoleDidClose!()
                } else {
                    SysConsole.prErr("Failed to close the console")
                }
            })
        case .left:
            UIView.animate(withDuration: 0.5, animations: {
                self.background!.frame = CGRect(x: self.view!.frame.minX - self.background!.frame.width, y: self.view!.center.y - (self.background!.frame.height / 2), width: self.launcher.getWidth(), height: self.launcher.getHeight())
            }, completion: { (complete) in
                if complete {
                    self.state = .close
                    self.delegate?.consoleDidClose!()
                } else {
                    SysConsole.prErr("Failed to close the console")
                }
            })
        case .right:
            UIView.animate(withDuration: 0.5, animations: {
                self.background!.frame = CGRect(x: self.view!.frame.maxX, y: self.view!.center.y - (self.background!.frame.height / 2), width: self.launcher.getWidth(), height: self.launcher.getHeight())
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
        if status != 200 {
            SysConsole.prErr("While \(token.description), you may only use the standard popover console from the bottom.")
            return
        }
        if !Settings.fullscreenOverride {
            SysConsole.prErr("Fullscreen has been disabled, please re-enable it by setting Console.Settings.fullscreenOverride to true")
        }
        if Settings.diagnosticMode {
            SysConsole.prDiag("Did run \(#function)")
        }
        UIView.animate(withDuration: 0.5, animations: {
            let frame = CGRect(x: 20, y: 20, width: self.view!.frame.width - 40, height: self.view!.frame.height - 40)
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
        if state != .fullscreen {
            SysConsole.prErr("Console must be open first, call Console.displayFullscreen()")
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
        if state != .fullscreen {
            SysConsole.prErr("Console must be open first, call Console.displayFullscreen()")
            return
        }
        if Settings.diagnosticMode {
            SysConsole.prDiag("Did run \(#function)")
        }
        switch orientation {
        case .default, .bottom:
            UIView.animate(withDuration: 0.5, animations: {
                let frame = CGRect(x: 20, y: self.view!.frame.maxY - self.launcher.getHeight(), width: self.launcher.getWidth(), height: self.launcher.getHeight())
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
                let frame = CGRect(x: 20, y: 0, width: self.launcher.getWidth(), height: self.launcher.getHeight())
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
        case .left:
            UIView.animate(withDuration: 0.5, animations: {
                let frame = CGRect(x: 0, y: self.view!.center.y - (self.launcher.getHeight() / 2), width: self.launcher.getWidth(), height: self.launcher.getHeight())
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
        case .right:
            UIView.animate(withDuration: 0.5, animations: {
                let frame = CGRect(x: self.view!.frame.maxX - self.launcher.getWidth(), y: self.view!.center.y - (self.launcher.getHeight() / 2), width: self.launcher.getWidth(), height: self.launcher.getHeight())
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
    public func print<Anything>(_ item: Anything, method: PrintMethod = .default) {
        if !setupComplete {
            SysConsole.prErr("You must complete setup first")
            return
        }
        if method == .both {
            var current = console!.text!
            current.append(String(describing: "\(item)\n"))
            console!.text = current
            SysConsole.prOvr(item)
        } else if method == .xcodeOnly {
            SysConsole.prOvr(item)
        } else if method == .default {
            var current = console!.text!
            current.append(String(describing: "\(item)\n"))
            console!.text = current
        }
    }
    
    /// Print an warning message in the console
    ///
    /// Default color is Yellow (changeable in Settings)
    /// - Parameters:
    ///     - item: The item you wish to print.
    ///     - method: (optional) The method you wish to print the item.
    /// - Bug: Warning text is not currently coloring correctly, defaults to Green
    public func printWarning<Anything>(_ item: Anything, method: PrintMethod = .default) {
        if !setupComplete {
            SysConsole.prErr("You must complete setup first")
            return
        }
        if status != 200 {
            SysConsole.prErr("While \(token.description), you may only use the standard print function.")
            return
        }
        print("\"Print Warning\" is not fully avalible yet and has been processed as normal text. Sorry for this inconviance.", method: .both)
        if method == .both {
            var current = console!.text!
            current.append(String(describing: "\(item)\n"))
            console!.text = current
            SysConsole.prOvr(item)
        } else if method == .xcodeOnly {
            SysConsole.prOvr(item)
        } else if method == .default {
            var current = console!.text!
            current.append(String(describing: "\(item)\n"))
            console!.text = current
        }
    }
    
    /// Print an error message in the console
    ///
    /// Default color is Red (changeable in Settings)
    /// - Parameters:
    ///     - item: The item you wish to print.
    ///     - method: (optional) The method you wish to print the item.
    /// - Bug: Warning text is not currently coloring correctly, defaults to Green
    public func printError<Anything>(_ item: Anything, method: PrintMethod = .default) {
        if !setupComplete {
            SysConsole.prErr("You must complete setup first")
            return
        }
        print("\"Print Error\" is not fully avalible yet and has been processed as normal text. Sorry for this inconviance.", method: .both)
        if method == .both {
            var current = console!.text!
            current.append(String(describing: "\(item)\n"))
            console!.text = current
            SysConsole.prOvr(item)
        } else if method == .xcodeOnly {
            SysConsole.prOvr(item)
        } else if method == .default {
            var current = console!.text!
            current.append(String(describing: "\(item)\n"))
            console!.text = current
        }
    }
    
    /**************************************************************************/
    //                             MARK: Settings
    
    /// Set an email for trial use
    public func setEmail(_ email: String) {
        self.email = email
    }
    
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
        if token != AuthTokenStatus.authenticated || token != AuthTokenStatus.trial {
            SysConsole.prErr("While \(token.description), you may only use the standard popover console from the bottom.")
            return
        }
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
        /// - Bug: Warning text is not currently coloring correctly, defaults to Green
        public static var warningColor: UIColor = .yellow
        /// The error text color in the console
        ///
        /// Default is Red
        /// - Bug: Error text is not currently coloring correctly, defaults to Green
        public static var errorColor: UIColor = .red
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
        public static var moveOverride = false {
            willSet(newOverride) {
                if DTConsole.sharedInstance.status != 200 {
                    if newOverride != false {
                        SysConsole.prErr("While \(DTConsole.sharedInstance.token.description), you may not move the console")
                        return
                    } else {
                        self.gestureOverride = newOverride
                    }
                } else {
                    self.gestureOverride = newOverride
                }
            }
        }
        /// Fullscreen support on iOS
        ///
        /// - Note: True by default, set false to disable the fullscreen button
        @available(tvOS, unavailable, message: "You can only use fullscreen on tvOS.")
        public static var fullscreenOverride = true {
            willSet(newOverride) {
                if DTConsole.sharedInstance.status != 200 {
                    if newOverride != false {
                        SysConsole.prErr("While \(DTConsole.sharedInstance.token.description), you may not use fullscreen")
                        return
                    } else {
                        self.gestureOverride = newOverride
                    }
                } else {
                    self.gestureOverride = newOverride
                }
            }
        }
        /// Set true for live enviroments
        public static var liveOverride = false
        /// Guesture Support in Popover Console
        ///
        /// - Note: True by default, set false to disable gestures
        @available(tvOS, unavailable, message: "Gestures are not supported on tvOS")
        public static var gestureOverride: Bool = true {
            willSet(newOverride) {
                if DTConsole.sharedInstance.status != 200 {
                    if newOverride != false {
                        SysConsole.prErr("While \(DTConsole.sharedInstance.token.description), you may not use gestures")
                        return
                    } else {
                        self.gestureOverride = newOverride
                    }
                } else {
                    self.gestureOverride = newOverride
                }
            }
        }
        /// Option to disable the clear button
        ///
        /// - Note: False by default, set true to disable the clear button
        public static var clearOverride = false
        internal static var diagnosticMode = false
        internal static var diagnosticBackgroundColor: UIColor = .lightGray
        internal static var diagnosticTextColor: UIColor = .black
    }
    
    /**************************************************************************/
    //                             MARK: Authenticaion
    
    public class Authentication {
        
        /// Re-Authenticate using your current key
        ///
        /// - Paramater passcode: The passcode associated with your API key
        /// - Note: It is recommended to update your key and passcode in Auth0.plist and use DTConsole.Authentication.authenticate() instead
        /// - Note: DTSuite keys are authenticated using DTConsole.Authenticate.authenticateDTSuite(withKey:, passcode:)
        static public func authenticate(passcode: String, completion: ((Bool)->())?) {
            DTAuth().login(key: nil, passcode: passcode, completion: { (profile) in
                if profile != nil {
                    DTConsole.sharedInstance.status = DTAuth().getStatus(profile!.appMetadata["type"] as! String)
                    completion?(true)
                } else {
                    completion?(false)
                }
            })
        }
        
        /// Authenticate using a new key and passcode
        ///
        /// - Paramater
        ///     - key: The new API key to authenticate with
        ///     - passcode: The passcode associated with your API key
        /// - Note: It is recommended to update your key and passcode in Auth0.plist and use DTConsole.Authentication.authenticate() instead
        /// - Note: DTSuite keys are authenticated using DTConsole.Authenticate.authenticateDTSuite(withKey:, passcode:)
        static public func authenticate(withKey key: String, passcode: String) {
            DTAuth().login(key: key, passcode: passcode, completion: nil)
        }
        
        /// Authenticate using key and passocde from your Auth0.plist
        ///
        /// - Note: DTSuite keys are authenticated using DTConsole.Authenticate.authenticateDTSuite(withKey:, passcode:)
        static public func authenticate(completion: ((Bool)->())?) {
            DTAuth().login(key: nil, passcode: nil, completion: { (profile) in
                if profile != nil {
                    DTConsole.sharedInstance.status = DTAuth().getStatus(profile!.appMetadata["type"] as! String)
                    completion?(true)
                } else {
                    completion?(false)
                }
            })
        }
        
        /// Activate trial of DTConsole
        ///
        /// - Paramater email: The email address you wish to use for the trial
        /// - Note: DTSuite trial codes are authenticated using DTConsole.Authenticate.activateDTSuiteTrial(withEmail:, key:)
        static public func activateTrial(withEmail email: String) {
            
        }
        
        /// Activate DTConsole using a trial of DTSuite
        @available(*, unavailable, message: "DTSuite authentication is currently unavalible in this release")
        static public func activateDTSuiteTrial(withEmail email: String, key: String) {
            // TODO: Connect DTSuite Trial Authentication
        }
        
        /// Activate DTConsole using a DTSuite key
        @available(*, unavailable, message: "DTSuite authentication is currently unavalible in this release")
        static public func authenticateDTSuite(withKey key: String, passcode: String) {
            // TODO: Connect DTSuite Full Authentication
        }
    }
}

