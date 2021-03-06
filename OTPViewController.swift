//
//  OTPViewController.swift
//  OTPviewcontroller
//

import UIKit

@objc public protocol OTPViewControllerDelegate {
    /**
     * Use this delegate method to make API calls, show loading animation in `viewController`, do whatever you want.
     * You can dismiss (if presented) the `viewController` when you're done.
     *
     * This method will get called only after the validation is successful, i.e., after the user has filled all the text fields.
     *
     * - Parameter otp: The full otp string entered.
     * - Parameter viewController: The otp view controller.
     *
     */
    @objc func authenticate(_ otp: String, from viewController: OTPViewController)
    
    /**
     * This method will get called whenever the otp view controller is closed, either by popping, dismissing, or tapping the close button.
     *
     * Use this to invalidate any timers, do clean-ups, etc..
     *
     * - Parameter viewController: The otp view controller.
     *
     */
    @objc func didClose(_ viewController: OTPViewController)
    
    /**
     * This delegate method will get called when the footer button at the bottom is tapped. Use this to resend one time code from the server
     *
     * This method will only be called when the `shouldFooterBehaveAsButton` is `true`.
     *
     * - Parameter button: The button that's tapped.
     * - Parameter viewController: The otp view controller. Use this to show loaders, spinners, present any other view controllers on top etc..
     *
     */
    @objc func didTap(footer button: UIButton, from viewController: OTPViewController)
}

/**
 * A simple and neat-looking view controller that lets you type in OTP's quick and easy
 *
 * This is intended to be a drag and drop view controller that gets the work done quickly, in and out, that's it. No fancy customizations, no cluttering the screen with tons of UI elements and crazy colors. You'll be good to go with the default settings.
 *
 * * Supports Portrait | Landscape
 * * Light Mode | Dark Mode
 * * iOS | iPadOS
 *
 * **Example Usage:**
 
 * ```swift
 import OTPViewController
 
 ---------------------------------------------
 //PRESENTATION
 ---------------------------------------------
 
 // Initialise view controller
 let oneTimePasswordVC = OTPViewController.init(withHeading: "Two Factor Authentication",
                                                  withNumberOfCharacters: 6,
                                                  delegate: self)
 // Present it
 self.present(oneTimePasswordVC, animated: true, completion: nil)
 
 ---------------------------------------------
 //VISUALS
 ---------------------------------------------
 
 // Button title. Optional. Default is "AUTHENTICATE".
 oneTimePasswordVC.authenticateButtonTitle = "VERIFY OTP"

 // Sets the overall accent of the view controller. Optional. Default is system blue.
 oneTimePasswordVC.accentColor = UIColor.systemRed

 // Currently selected text field color. Optional. This takes precedence over the accent color.
 oneTimePasswordVC.currentTextFieldColor = UIColor.systemOrange

 // Button color. Optional. This takes precedence over the accent color.
 oneTimePasswordVC.authenticateButtonColor = UIColor.systemGreen
 
 ---------------------------------------------
 //DELEGATE
 ---------------------------------------------
 
 //Conform to OTPViewControllerDelegate

 func authenticate(_ otp: String, from viewController: OTPViewController) {
 
 /**
  * Use this delegate method to make API calls, show loading animation in `viewController`, do whatever you want.
  * You can dismiss (if presented) the `viewController` when you're done.
  *
  * This method will get called only after the validation is successful, i.e., after the user has filled all the text fields.
  *
  * - Parameter otp: The full otp string entered.
  * - Parameter viewController: The otp view controller.
  *
  */
 
 }

 func didClose(_ viewController: OTPViewController) {
 
 /**
  * This method will get called whenever the otp view controller is closed, either by popping, dismissing, or tapping the close button.
  *
  * Use this to invalidate any timers, do clean-ups, etc..
  *
  * - Parameter viewController: The otp view controller.
  *
  */
  
 }

 func didTap(footer button: UIButton, from viewController: OTPViewController) {
 
 /**
  * This delegate method will get called when the footer button at the bottom is tapped. Use this to resend one time code from the server
  *
  * This method will only be called when the `shouldFooterBehaveAsButton` is `true`.
  *
  * - Parameter button: The button that's tapped.
  * - Parameter viewController: The otp view controller. Use this to show loaders, spinners, present any other view controllers on top etc..
  *
  */
  
 }
 ```
 */
open class OTPViewController: UIViewController {
    
    
    ////////////////////////////////////////////////////////////////
    //MARK:-
    //MARK: Private Properties
    //MARK:-
    ////////////////////////////////////////////////////////////////

    
    private var isAutoFillingFromSMS = false
    private var autoFillBuffer: [String] = []
    private var didTapToDismissKeyboard = false
    private var timeIntervalBetweenAutofilledCharactersFromSMS: Date?
    
    private var headingString: String
    private let numberOfOtpCharacters: Int
    private var allTextFields: [OTPTextField] = []
    private var textFieldsIndexes: [OTPTextField: Int] = [:]
    
    private var closeButton: UIButton?
    private var stackView: UIStackView!
    private var isKeyBoardOn: Bool = false
    private var masterStackView: UIStackView!
    private var keyboardOffsetDuringEditing: CGFloat = 0.0
    private var headingTitleLabel: UILabel?
    
    private var footerButton: OTPAuthenticateButton?
    private var primaryHeaderLabel: UILabel?
    private var secondaryHeaderLabel: UILabel?
    private var headerTextsStackView: UIStackView?
    
    private var authenticateButton: OTPAuthenticateButton!
    private var masterStackViewCenterYConstraint: NSLayoutConstraint!
    private var originalMasterStackViewCenterYConstraintConstant: CGFloat!
    
    private weak var currentTextField: OTPTextField? = nil
    
    /**
     * Setting this property with a valid string will paste it in all the textfields and call the delegte method.
     *
     */
    private var stringToPaste: String = "" {
        didSet {
            if stringToPaste.count == self.numberOfOtpCharacters {
                for (idx, element) in stringToPaste.enumerated() {
                    allTextFields[idx].text = String(element)
                }
                self.touchesEnded(Set.init(arrayLiteral: UITouch()), with: nil)
                self.informDelegate(stringToPaste, from: self)
            }
        }
    }
    
    /**
     * Keeps track of the copied string from clipboard for the purpose of comparing old and new strings to decide on auto-pasting, or prompting user to paste it.
     *
     */
    private static var clipboardContent: String? = nil

    
    //
    ////////////////////////////////////////////////////////////////
    //MARK:-
    //MARK: Public Properties
    //MARK:-
    ////////////////////////////////////////////////////////////////
    //

    
    /**
     * The delegate object that is responsible for performing the actual authentication/verification process (with server via api call or whatever)
     *
     */
    @objc public var delegate: OTPViewControllerDelegate?
    
    /**
     * Setting this to true opens up the keyboard for the very first text field.
     *
     * Default is `false`. Consider the `hideLabelsWhenEditing` property when setting this one to `true`, because when the keyboard is open as soon as the view controller is presented/pushed, if `hideLabelsWhenEditing` is `true`, the labels will be hidden initially as a result, and the user won't even know that the labels exist. It will be a better user experience if the user sees the labels initially since it guides them what to do. Choose wisely.
     *
     */
    @objc public var openKeyboadDuringStartup: Bool = false
    
    /**
     * The color that will be used overall for the UI elements. Set this if you want a common color to be used in the view controller instead of worrying about each UI element's color.
     *
     * Separate colors can also be used for each UI element as allowed by the view controller (via public properties), which will override this property (`accentColor`). Default is `UIColor.systemBlue`
     *
     */
    @objc public var accentColor: UIColor = .systemBlue {
        willSet {
            self.closeButton?.setTitleColor(self.authenticateButtonColor ?? newValue, for: .normal)
            if self.authenticateButton != nil {
                self.authenticateButton.backgroundColor = self.authenticateButtonColor ?? newValue
            }
            if let tf = currentTextField {
                tf.layer.borderColor = currentTextFieldColor?.cgColor ?? newValue.cgColor
            }
        }
    }
    
    /**
     * The currently focused text field color. This color will appear faded (less opacity) to look good instead of being saturated.
     *
     */
    @objc public var currentTextFieldColor: UIColor? {
        willSet {
            if let tf = currentTextField {
                tf.setBorder(amount: 3, borderColor: (newValue ?? self.accentColor).withAlphaComponent(0.4), duration: 0)
            }
        }
    }
    
    /**
     * The color of the authenticate button.
     *
     * Settings this color will override the `accentColor`.
     *
     */
    @objc public var authenticateButtonColor: UIColor? {
        willSet {
            self.authenticateButton.backgroundColor = newValue ?? self.accentColor
        }
    }
    
    /**
     * The title of the authenticate button.
     *
     * Settings this color will override the `accentColor`.
     *
     */
    @objc public var authenticateButtonTitle: String = "AUTHENTICATE" {
        willSet {
            self.authenticateButton.setTitle(newValue, for: .normal)
        }
    }
    
    /**
     * The title of the primary header which stays above the OTP textfields.
     *
     * This is optional. In case of nil, the label won't be constructed at all. So make sure to set a string, or leave it as it is (`nil`). Changing this value after presenting or pushing `OTPViewController` won't have an effect; the label won't be constructed.
     *
     */
    @objc public var primaryHeaderTitle: String? {
        willSet {
            self.primaryHeaderLabel?.text = newValue
        }
    }
    
    /**
     * The title of the secondary header which comes below the primary header.
     *
     * This is optional. In case of nil, the label won't be constructed at all. So make sure to set a string, or leave it as it is (`nil`). Changing this value after presenting or pushing `OTPViewController` won't have an effect; the label won't be constructed.
     *
     */
    @objc public var secondaryHeaderTitle: String? {
        willSet {
            self.secondaryHeaderLabel?.text = newValue
        }
    }
    
    /**
     * The title of the footer label which comes below the authenticate button.
     *
     * This is optional. In case of nil, the label won't be constructed at all. So make sure to set a string, or leave it as it is (`nil`). Changing this value after presenting or pushing `OTPViewController` won't have an effect; the label won't be constructed.
     *
     */
    @objc public var footerTitle: String? {
        willSet {
            self.footerButton?.setTitle(newValue, for: .normal)
        }
    }
    
    /**
     * Set whether the primary, secondary, and footer labels are to be hidden during editing, i.e., when the keyboard is open.
     *
     * Default is `false`
     *
     */
    @objc public var hideLabelsWhenEditing: Bool = false
    
    /**
     * Setting this to `true` will show an alert to the user whenever a compatible text is copied to clipboard asking whether or not to paste the same. Yes or No option will be provided.
     *
     * Default is `true`.
     *
     * Tapping "Yes" will auto-fill all the textfields with copied text and will call the `authenticate` delegate method.
     *
     * Pop-up won't be shown for the same string copied over and over. Clipboard will be checked when the app comes to foreground, and when the view controller's view finished appearing.
     *
     */
    @objc public var shouldPromptUserToPasteCopiedStringFromClipboard: Bool = true
    
    /**
     * Setting this to `true` will automatically paste compatible text that is present in the clipboard and call the `authenticate` delegate method without asking any questions. This property will take precedence over `shouldPromptUserToPasteCopiedStringFromClipboard` property.
     *
     * Default is `false`.
     *
     * But be careful when setting this to `true` as this might not be the best user experiece all the time. This does not give the user the control of what code to paste.
     *
     * Some/most users may prefer quick submission and verification of OTP code without any extra clicks or taps. This saves a quite a few milliseconds from them.
     *
     * **Note:** OTP code won't be pasted for the same string copied over and over. Clipboard will be checked when the app comes to foreground, and when the view controller's view finished appearing.
     *
     */
    @objc public var shouldAutomaticallyPasteCopiedStringFromClipboard: Bool = false
    
    /**
     * Uses haptics for touches, interactions, successes and errors within the OTP view controller.
     *
     * Default is `true`.
     *
     */
    @objc public var hapticsEnabled: Bool = true
    
    /**
     * Asks whether the footer should behave as a button or just a normal label. Button will pass the action to the delegate method `didTap(footer button: UIButton)`.
     *
     * If `true`, the color of the footer will be `.systemBlue`, and gray otherwise. Default is `false`.
     *
     */
    @objc public var shouldFooterBehaveAsButton: Bool = false
    
    /**
     * The color of the footer.
     *
     * This color will be applied only when `shouldFooterBehaveAsButton` is set to `true`. Default gray color will be used otherwise. Default color is `.systemBlue`.
     *
     */
    @objc public var footerButtonColor: UIColor?
    
    
    ////////////////////////////////////////////////////////////////
    //MARK:-
    //MARK: Main Implementation
    //MARK:-
    ////////////////////////////////////////////////////////////////

    
    @objc public init(withHeading heading: String = "One Time Password",
                      withNumberOfCharacters numberOfOtpCharacters: Int,
                      delegate: OTPViewControllerDelegate? = nil) {
        self.delegate = delegate
        self.headingString = heading
        self.numberOfOtpCharacters = numberOfOtpCharacters
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.constructUI()
        self.initialConfiguration()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.checkClipboardAndPromptUserToPasteContent()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        let isBeingPopped: Bool!
        
        #if swift(>=5.0)
        isBeingPopped = isMovingFromParent
        #elseif swift(<5.0)
        isBeingPopped = isMovingFromParentViewController
        #endif
        
        if isBeingDismissed || isBeingPopped {
            self.delegate?.didClose(self)
        }
    }
    
    @objc func authenticateButtonTapped(_ sender: UIButton) {
        var otpString = ""
        let numberOfEmptyTextFields: Int = allTextFields.reduce(0, { emptyTextsCount, textField in
            otpString += textField.text!
            return (textField.text ?? "") == "" ? emptyTextsCount + 1 : emptyTextsCount
        })
        if numberOfEmptyTextFields > 0 {
            if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.error) }
            return
        }
        self.view.endEditing(true)
        self.informDelegate(otpString, from: self)
    }
    
    @objc private func closeButtonTapped(_ sender: UIButton) {
        if self.navigationController == nil {
            self.askUserConsentBeforeDismissingModal()
        }
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.headingTitleLabel?.numberOfLines = NSObject.deviceIsInLandscape ? 1 : 2
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animateAlongsideTransition(in: self.view, animation: { (coord) in
            self.masterStackViewCenterYConstraint = self.masterStackView.change(yOffset: self.offsetValueDuringRest())
            self.originalMasterStackViewCenterYConstraintConstant = self.masterStackViewCenterYConstraint.constant
            self.masterStackView.layoutIfNeeded()
        }, completion: nil)
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    /**
     * Call this method to dismiss the keyboard, and reset the position of the master stack view to its original position, and reset all labels' alpha to 1.0.
     *
     */
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.didTapToDismissKeyboard = true
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: [.curveEaseIn, .curveEaseOut], animations: {
            self.masterStackViewCenterYConstraint.constant = self.originalMasterStackViewCenterYConstraintConstant
            self.keyboardOffsetDuringEditing = 0.0
            self.setLabelsAlpha(1.0)
            self.view.layoutIfNeeded()
        }) { (completed) in
            self.didTapToDismissKeyboard = false
        }
        self.view.endEditing(true)
    }
    
    deinit {
        self.removeListeners()
        self.allTextFields.removeAll()
        self.textFieldsIndexes.removeAll()
    }
}


////////////////////////////////////////////////////////////////
//MARK:-
//MARK: UITextFields Handling
//MARK:-
////////////////////////////////////////////////////////////////


extension OTPViewController: UITextFieldDelegate {
    
    enum Direction { case left, right }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        ///We don't need any string that is more than the maximum allowed chatacters
        if string.count > self.numberOfOtpCharacters { return false }
        
        ///We don't need any white space either
        if ((string == "" || string == " ") && range.length == 0) {
            
            ///But, auto-fill from SMS - before sending in the characters one by one - will
            ///send two empty strings ("") in succession very fast, unlike the speed a human may enter passcode.
            ///
            ///We need to check for it and have to decide/assume that what we have received is indeed auto-filled code from SMS.
            ///
            ///This has to be done since we use a new textfield for each character instead of a single text field with all characters.
            
            if string == "" {
                if let oldInterval = timeIntervalBetweenAutofilledCharactersFromSMS {
                    if Date().timeIntervalSince(oldInterval) < 0.05 {
                        self.isAutoFillingFromSMS = true
                        timeIntervalBetweenAutofilledCharactersFromSMS = nil
                    }
                }
                timeIntervalBetweenAutofilledCharactersFromSMS = Date()
            }
            return false
        }
        
        ///We check if the text is pasted.
        if string.count > 1 {
            ///If the string is of the same length as the number of otp characters, then we proceed to
            ///fill all the text fields with the characters
            if string.count == numberOfOtpCharacters {
                for (idx, element) in string.enumerated() {
                    allTextFields[idx].text = String(element)
                }
                textField.resignFirstResponder()
                self.touchesEnded(Set.init(arrayLiteral: UITouch()), with: nil)
                self.informDelegate(string, from: self)
                ///If the replacing string is of 1 character length, then we just allow it to be replaced
                ///and set the responder to be the next text field
            } else if string.count == 1 {
                setNextResponder(textFieldsIndexes[textField as! OTPTextField], direction: .right)
                textField.text = string
            }
        } else {
            
            if isAutoFillingFromSMS {
                
                autoFillBuffer.append(string)
                                
                ///`checkOtpFromMessagesCount` below specifically checks if the entered string is less than the maximum allowed characters.
                ///Since we are debouncing it, `checkOtpFromMessagesCount` will get called only once.
                ///And we don't allow any characters that are less than the allowed ones.
                
                NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(OTPViewController.checkOtpFromMessagesCount), object: nil)
                self.perform(#selector(OTPViewController.checkOtpFromMessagesCount), with: nil, afterDelay: 0.1)

                ///We check if the auto-fill from SMS has finished entering all the characters.
                ///In this case, we need only up to the maximum number of otp characters set by the developer.
                ///At a later stage, this might be controlled by a flag which will strictly allow only equal number of characters set by the `numberOfOtpCharacters` property.
                
                if autoFillBuffer.count == numberOfOtpCharacters {
                    var finalOTP = ""
                    for (idx, element) in autoFillBuffer.enumerated() {
                        let otpChar = String(element)
                        finalOTP += otpChar
                        allTextFields[idx].text = otpChar
                    }
                    self.touchesEnded(Set.init(arrayLiteral: UITouch()), with: nil)
                    self.informDelegate(finalOTP, from: self)
                    isAutoFillingFromSMS = false
                    autoFillBuffer.removeAll()
                }
                return false
            }
            
            ///Normal text entry
            
            if range.length == 0 {
                textField.text = string
                setNextResponder(textFieldsIndexes[textField as! OTPTextField], direction: .right)
            } else if range.length == 1 {
                setNextResponder(textFieldsIndexes[textField as! OTPTextField], direction: string.isEmpty ? .left : .right)
                textField.text = string.isEmpty ? "" : string
            }
        }
        return false
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.roundCorners(amount: 4)
        textField.setBorder(amount: 3, borderColor: (currentTextFieldColor ?? accentColor).withAlphaComponent(0.4), duration: 0)
        self.currentTextField = textField as? OTPTextField
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        textField.setBorder(amount: 1.8, borderColor: UIColor.lightGray.withAlphaComponent(0.3), duration: 0.09)
        self.currentTextField = nil
    }
    
    private func setNextResponder(_ index: Int?, direction: Direction) {
        guard let index = index else { return }
        if direction == .left {
            index == 0 ?
                (self.resignFirstResponder(textField: allTextFields.first)) :
                (_ = allTextFields[(index - 1)].becomeFirstResponder())
        } else {
            index == numberOfOtpCharacters - 1 ?
                (self.resignFirstResponder(textField: allTextFields.last)) :
                (_ = allTextFields[(index + 1)].becomeFirstResponder())
        }
    }
    
    private func resignFirstResponder(textField: OTPTextField?) {
        textField?.resignFirstResponder()
        self.touchesEnded(Set.init(arrayLiteral: UITouch()), with: nil)
        var otpString = ""
        let numberOfEmptyTextFields: Int = allTextFields.reduce(0, { emptyTextsCount, textField in
            otpString += textField.text!
            return (textField.text ?? "").isEmpty ? emptyTextsCount + 1 : emptyTextsCount
        })
        if numberOfEmptyTextFields > 0 { return }
        if let _ = delegate {
            self.informDelegate(otpString, from: self)
        } else {
            fatalError("Delegate is nil in OTPViewController.")
        }
    }
    
    /**
     * This method detects if the auto-filled code from SMS is less than that of the allowed number of characters.
     *
     * This checking needs to be done to come to a conclusion on when to populate the code (stored in `autoFillBuffer`) in text fields from SMS. We don't need to populate any characters that are less than what is allowed max..
     *
     */
    @objc private func checkOtpFromMessagesCount() {
        if autoFillBuffer.count < numberOfOtpCharacters {
            isAutoFillingFromSMS = false
            autoFillBuffer.removeAll()
        }
    }
    
}


////////////////////////////////////////////////////////////////
//MARK:-
//MARK: UI Construction
//MARK:-
////////////////////////////////////////////////////////////////


extension OTPViewController {
    
    internal func constructUI() {
        
        /// All of the below UI code is strictly order-sensitive and tightly coupled to their previous elements' layout.
        /// Be careful and try not to change the order of the stuffs. Each UI element is laid out one by one,
        /// piece by piece to work correctly.
        
        /// 1. Layout Heading title lablel in case of navigation bar.
        title = headingString
        
        /// 2. Setup textfields.
        configureOTPTextFields()
        
        /// 3. Layout Heading title lablel in case of no navigation bar.
        layoutHeadingLabel()
        
        /// 4. Layout all stackviews and its contents.
        layoutAllStackViewsWith(allTextFields)
        
        /// 5. Make first text field the first responder or not based on the `openKeyboadDuringStartup` attribute.
        self.openKeyboadDuringStartup ? (_ = allTextFields.first?.becomeFirstResponder()) : doNothing()
        
        /// 6. Layout close button at the bottom.
        layoutBottomCloseButton()
        
        /// 7. Set background color.
        if #available(iOS 13.0, *) {
            view.backgroundColor = .otpVcBackgroundColor
        } else {
            view.backgroundColor = .white
        }
        
        /// 8. Offset and save the Top constraint of master stack view.
        saveMasterStackViewYConstraint()

    }
    
    fileprivate func layoutBottomCloseButton() {
        if self.navigationController == nil {
            self.view.layoutIfNeeded()
            let closeButton = OTPAuthenticateButton()
            closeButton.frame = .init(origin: .zero, size: .init(width: self.masterStackView.bounds.width, height: 35))
            closeButton.tarmic = false
            closeButton.useHaptics = false
            closeButton.setTitle("CLOSE", for: .normal)
            closeButton.showsTouchWhenHighlighted = false
            closeButton.setTitleColor(self.authenticateButtonColor ?? self.accentColor, for: .normal)
            closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold).normalized()
            closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
            
            self.view.addSubview(closeButton)
            closeButton.pinTo(.bottomMiddle)
            self.closeButton = closeButton
        }
    }
    
    fileprivate func saveMasterStackViewYConstraint() {
        self.masterStackViewCenterYConstraint = self.masterStackView.change(yOffset: offsetValueDuringRest())
        self.originalMasterStackViewCenterYConstraintConstant = self.masterStackViewCenterYConstraint.constant
    }
    
    fileprivate func configureOTPTextFields() {
        ///Create text fields for laying out in stackview
        for _ in 0 ..< numberOfOtpCharacters { allTextFields.append(otpTextField()) }
        for idx in 0 ..< allTextFields.count { textFieldsIndexes[allTextFields[idx]] = idx }
    }
    
    @discardableResult fileprivate func otpTextField() -> OTPTextField {
        
        let textField = OTPTextField()
        
        if #available(iOS 12.0, *) {
            textField.textContentType = .oneTimeCode
        }
        
        textField.tarmic = false
        textField.delegate = self
        textField.textColor = .black
        textField.borderStyle = .none
        textField.textAlignment = .center
        textField.menuActionDelegate = self
        textField.roundCorners(amount: 4)
        textField.backgroundColor = .white
        textField.isSecureTextEntry = true
        textField.keyboardType = .numberPad
        textField.setBorder(amount: 1.8, borderColor: UIColor.lightGray.withAlphaComponent(0.28), duration: 0.09)
        textField.widthAnchor.constraint(equalToConstant: NSObject.newWidth).isActive = numberOfOtpCharacters == 1
        textField.heightAnchor.constraint(equalTo: textField.widthAnchor, multiplier: 1.0).isActive = true
        
        return textField
    }
    
    fileprivate func layoutHeadingLabel() {
        
        if self.navigationController?.isNavigationBarHidden ?? true {
            
            let headingTitle = UILabel()
            headingTitle.tarmic = false
            headingTitle.tag = 2245
            headingTitle.numberOfLines = 2
            headingTitle.textAlignment = .center
            headingTitle.text = self.headingString
            headingTitle.adjustsFontSizeToFitWidth = true
            headingTitle.font = UIFont.systemFont(ofSize: 32, weight: .heavy).normalized()
            
            self.view.addSubview(headingTitle)
            
            if #available(iOS 11.0, *) {
                headingTitle.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 25).isActive = true
            } else {
                headingTitle.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 25).isActive = true
            }
            
            headingTitle.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
            
            let widthConstraint = headingTitle.widthAnchor.constraint(equalToConstant: self.view.frame.size.width * 85 / 100)
            widthConstraint.identifier = "Width"
            
            headingTitle.addConstraint(widthConstraint)
            
            self.headingTitleLabel = headingTitle
            
        }
    }
    
    fileprivate func layoutPrimaryHeaderLabel() {
        if let _ = primaryHeaderTitle {
            let primaryHeaderLabel = UILabel()
            primaryHeaderLabel.adjustsFontForContentSizeCategory = true
            
            let headlineFontMetric = UIFontMetrics.init(forTextStyle: .headline)
            let primaryHeaderLabelFont = headlineFontMetric.scaledFont(for: .systemFont(ofSize: 21, weight: .bold))
            primaryHeaderLabel.font = primaryHeaderLabelFont
            
            primaryHeaderLabel.setContentHuggingPriority(.init(1000), for: .vertical)
            primaryHeaderLabel.setContentCompressionResistancePriority(.init(1000), for: .vertical)
            primaryHeaderLabel.lineBreakMode = .byTruncatingMiddle
            primaryHeaderLabel.textAlignment = .center
            primaryHeaderLabel.numberOfLines = 0
            primaryHeaderLabel.text = self.primaryHeaderTitle
            primaryHeaderLabel.widthAnchor.constraint(equalToConstant: NSObject.newWidth).isActive = true
            self.primaryHeaderLabel = primaryHeaderLabel
        }
    }
    
    fileprivate func layoutSecondaryHeaderLabel() {
        if let _ = secondaryHeaderTitle {
            let secondaryHeaderLabel = UILabel()
            if #available(iOS 13.0, *) {
                secondaryHeaderLabel.textColor = .secondaryLabel
            } else {
                secondaryHeaderLabel.textColor = UIColor(red: 0.23529411764705882, green: 0.23529411764705882, blue: 0.2627450980392157, alpha: 0.6)
            }
            secondaryHeaderLabel.adjustsFontForContentSizeCategory = true
            secondaryHeaderLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
            secondaryHeaderLabel.setContentHuggingPriority(.init(1000), for: .vertical)
            secondaryHeaderLabel.setContentCompressionResistancePriority(.init(1000), for: .vertical)
            secondaryHeaderLabel.lineBreakMode = .byTruncatingMiddle
            secondaryHeaderLabel.textAlignment = .center
            secondaryHeaderLabel.numberOfLines = 0
            secondaryHeaderLabel.text = self.secondaryHeaderTitle
            secondaryHeaderLabel.widthAnchor.constraint(equalToConstant: NSObject.newWidth).isActive = true
            self.secondaryHeaderLabel = secondaryHeaderLabel
        }
    }
    
    @objc func footerButtonTapped(_ button: UIButton) {
        self.delegate?.didTap(footer: button, from: self)
    }
    
    fileprivate func layoutFooterLabel() {
        if let _ = footerTitle {
            let footerButton = OTPAuthenticateButton()
            
            let captionFontMetric = UIFontMetrics.init(forTextStyle: .caption2)
            let footerLabelFont = captionFontMetric.scaledFont(for: .systemFont(ofSize: shouldFooterBehaveAsButton ? 11 : 9, weight: .regular))
            
            footerButton.useHaptics = false
            footerButton.animate = shouldFooterBehaveAsButton
            footerButton.isUserInteractionEnabled = shouldFooterBehaveAsButton
            
            footerButton.titleLabel?.font = footerLabelFont
            footerButton.titleLabel?.textAlignment = .center
            footerButton.titleLabel?.adjustsFontForContentSizeCategory = true
            
            var labelTitleColor: UIColor!
            
            if #available(iOS 13.0, *) {
                labelTitleColor = UIColor.secondaryLabel.withAlphaComponent(0.4)
            } else {
                labelTitleColor = UIColor(red: 0.23529411764705882, green: 0.23529411764705882, blue: 0.2627450980392157, alpha: 0.6).withAlphaComponent(0.4)
            }
            
            if shouldFooterBehaveAsButton {
                footerButton.addTarget(self, action: #selector(footerButtonTapped(_:)), for: .touchUpInside)
            }
            
            footerButton.setTitleColor(shouldFooterBehaveAsButton ? (self.footerButtonColor ?? .systemBlue) : labelTitleColor, for: .normal)
            footerButton.setContentHuggingPriority(.init(1000), for: .vertical)
            footerButton.setContentCompressionResistancePriority(.init(1000), for: .vertical)
            footerButton.titleLabel?.lineBreakMode = .byTruncatingMiddle
            footerButton.titleLabel?.textAlignment = .center
            footerButton.titleLabel?.numberOfLines = 0
            footerButton.setTitle(self.footerTitle, for: .normal)
            
            self.footerButton = footerButton
        }
    }
    
    fileprivate func layoutStackViewForHeaderLabels() {
        let headerTextsStackView = UIStackView(arrangedSubviews: [self.primaryHeaderLabel, self.secondaryHeaderLabel].compactMap { view in view } )
        headerTextsStackView.axis = .vertical
        headerTextsStackView.spacing = -2
        headerTextsStackView.alignment = .center
        headerTextsStackView.distribution = .fill
        self.headerTextsStackView = headerTextsStackView
    }
    
    fileprivate func layoutAuthenticateButtonWith(sibling view: UIView) {
        
        let authenticateButton = OTPAuthenticateButton()
        authenticateButton.tarmic = false
        authenticateButton.roundCorners(amount: 6.0)
        authenticateButton.useHaptics = self.hapticsEnabled
        authenticateButton.setTitle(self.authenticateButtonTitle, for: .normal)
        
        let authenticateButtonFontMetric = UIFontMetrics.init(forTextStyle: .headline)
        let authenticateButtonFont = authenticateButtonFontMetric.scaledFont(for: .boldSystemFont(ofSize: 14))
        
        authenticateButton.titleLabel?.adjustsFontForContentSizeCategory = true
        authenticateButton.titleLabel?.lineBreakMode = .byTruncatingTail
        authenticateButton.titleLabel?.font = authenticateButtonFont
        authenticateButton.backgroundColor = self.authenticateButtonColor ?? self.accentColor
        authenticateButton.addTarget(self, action: #selector(authenticateButtonTapped(_:)), for: .touchUpInside)
        
        authenticateButton.heightAnchor.constraint(equalToConstant: (NSObject.newHeight * (NSObject.deviceIsiPad ? 90 : 75)) / 100).isActive = true
        self.authenticateButton = authenticateButton
    }
    
    fileprivate func layoutOTPStackViewWith(_ subviews: [UIView]) {
        let otpStackView = UIStackView.init(arrangedSubviews: subviews)
        otpStackView.tag = 234
        otpStackView.spacing = 12
        otpStackView.alignment = .fill
        otpStackView.distribution = .fill
        otpStackView.widthAnchor.constraint(equalToConstant: NSObject.newWidth).isActive = numberOfOtpCharacters >= 5
        otpStackView.heightAnchor.constraint(equalToConstant: NSObject.newHeight).isActive = numberOfOtpCharacters < 5
        self.stackView = otpStackView
    }
    
    fileprivate func layoutMasterStackView() {
        let masterStackView = UIStackView(arrangedSubviews: [self.headerTextsStackView, self.stackView, self.authenticateButton, self.footerButton].compactMap { view in view } )
        masterStackView.axis = .vertical
        masterStackView.spacing = 10
        masterStackView.alignment = .center
        masterStackView.distribution = .fill
        self.view.addSubview(masterStackView)
        self.masterStackView = masterStackView
        masterStackView.pinTo(.middle)
    }
    
    fileprivate func layoutAllStackViewsWith(_ subviews: [UIView]) {
        layoutOTPStackViewWith(subviews)
        layoutPrimaryHeaderLabel()
        layoutSecondaryHeaderLabel()
        layoutFooterLabel()
        layoutStackViewForHeaderLabels()
        layoutAuthenticateButtonWith(sibling: self.stackView)
        layoutMasterStackView()
        self.stackView.layoutIfNeeded()
        self.authenticateButton.widthAnchor.constraint(equalToConstant: self.stackView.bounds.width).isActive = true
        self.footerButton?.widthAnchor.constraint(equalToConstant: self.stackView.bounds.width).isActive = true
    }
    
    fileprivate func offsetValueDuringRest() -> CGFloat {
        
        var bottomInset: CGFloat = 0
        var statusBarHeight: CGFloat = 0
        let headingLabelTopOffset: CGFloat = 25
        
        #if targetEnvironment(macCatalyst)
        #else
        bottomInset = UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0.0
        statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        #endif
        
        if !(self.navigationController?.isNavigationBarHidden ?? true) {
            return (self.navBarHeight + statusBarHeight - bottomInset) / 2
        } else {
            return bottomInset == 0 ?
                ((self.headingTitleLabel?.intrinsicContentSize.height ?? 0 + headingLabelTopOffset) / 2) :
                (bottomInset / 2)
        }
    }
    
}


////////////////////////////////////////////////////////////////
//MARK:-
//MARK: Keyboard Handling
//MARK:-
////////////////////////////////////////////////////////////////


extension OTPViewController {
    
    fileprivate func initialConfiguration() {
        self.modalConfig()
        self.configureKeyboardAndOtherNotifications()
    }
    
    fileprivate func modalConfig() {
        if self.navigationController == nil {
            if #available(iOS 13.0, *) {
                self.isModalInPresentation = true
                self.presentationController?.delegate = self
            }
        }
    }
    
    fileprivate func configureKeyboardAndOtherNotifications() {
        #if swift(>=5.0)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        #elseif swift(<5.0)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        #endif
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        
        var keyboardFrameBeginKey = ""
        var keyboardFrameEndKey = ""
        
        #if swift(>=5.0)
        keyboardFrameBeginKey = UIResponder.keyboardFrameBeginUserInfoKey
        keyboardFrameEndKey = UIResponder.keyboardFrameEndUserInfoKey
        #elseif swift(<5.0)
        keyboardFrameBeginKey = UIKeyboardFrameBeginUserInfoKey
        keyboardFrameEndKey = UIKeyboardFrameEndUserInfoKey
        #endif
        
        let beginFrame = (notification.userInfo?[keyboardFrameBeginKey] as! NSValue).cgRectValue
        let endFrame = (notification.userInfo?[keyboardFrameEndKey] as! NSValue).cgRectValue

        ///Since `keyboardWillShow` method gets called sporadically, we handle it only when the start and end frames differ.
        ///We don't proceed further if there is no change in the keyboard's frame.
        guard !beginFrame.equalTo(endFrame) else {
            return
        }
        
        /**
         * Need this delay for the UI to finish being laid out
         * to check if the keyboard is obscuring the button or not initially.
         */
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.offsetForKeyboardPosition(notification as NSNotification)
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.resetToDefaultOffsetForKeyboardPosition(notification as NSNotification)
        }
    }
    
    @objc func appWillEnterForeground(_ notification: Notification) {
        checkClipboardAndPromptUserToPasteContent()
    }
    
    @objc fileprivate func offsetForKeyboardPosition(_ notification: NSNotification) {
        
        var keyboardFrameEndKey = ""
        
        #if swift(>=5.0)
        keyboardFrameEndKey = UIResponder.keyboardFrameEndUserInfoKey
        #elseif swift(<5.0)
        keyboardFrameEndKey = UIKeyboardFrameEndUserInfoKey
        #endif
        
        self.isKeyBoardOn = true
        let window = UIApplication.shared.windows.first
        let userInfo = (notification as NSNotification).userInfo!
        let keyboardFrame = (userInfo[keyboardFrameEndKey] as! NSValue).cgRectValue
        let authButtonMaxY = self.masterStackView.convert(self.authenticateButton.frame, to: window).maxY
        let keyboardMinY = keyboardFrame.origin.y
        
        self.keyboardOffsetDuringEditing = (authButtonMaxY - keyboardMinY + (NSObject.self.deviceIsiPad ? 10 : 5))
        ///Means the keyboard overlaps the authenticate button
        if authButtonMaxY > keyboardMinY {
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: [.curveEaseIn, .curveEaseOut], animations: {
                self.masterStackViewCenterYConstraint.constant -= self.keyboardOffsetDuringEditing
                self.setLabelsAlpha(0.0)
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    fileprivate func resetToDefaultOffsetForKeyboardPosition(_ notification: NSNotification) {
        
        var keyboardFrameEndKey = ""
        
        #if swift(>=5.0)
        keyboardFrameEndKey = UIResponder.keyboardFrameEndUserInfoKey
        #elseif swift(<5.0)
        keyboardFrameEndKey = UIKeyboardFrameEndUserInfoKey
        #endif
        
        if isKeyBoardOn {
            self.isKeyBoardOn = false
            let window = UIApplication.shared.windows.first
            let userInfo = (notification as NSNotification).userInfo!
            let keyboardFrame = (userInfo[keyboardFrameEndKey] as! NSValue).cgRectValue
            let authButtonLocalY = self.masterStackView.convert(self.authenticateButton.frame, to: window).maxY
            let keyboardLocalY = keyboardFrame.origin.y
            let keyboardLocalHeight = window?.convert(keyboardFrame, to: self.view).height ?? 0
            
            if keyboardLocalHeight >= CGFloat(0) ||
                authButtonLocalY >= (keyboardLocalY - self.keyboardOffsetDuringEditing) {
                UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: [.curveEaseIn, .curveEaseOut], animations: {
                    if self.didTapToDismissKeyboard == false {
                        self.masterStackViewCenterYConstraint.constant = self.originalMasterStackViewCenterYConstraintConstant
                        self.keyboardOffsetDuringEditing = 0.0
                        self.setLabelsAlpha(1.0)
                        self.view.layoutIfNeeded()
                    }
                    self.didTapToDismissKeyboard = false
                }, completion: nil)
            }
        }
    }
    
    fileprivate func setLabelsAlpha(_ value: CGFloat) {
        if value == 0 {
            if !NSObject.deviceIsInLandscape {
                return
            }
        }
        let finalAlpha = value == 0.0 ? hideLabelsWhenEditing ? value : 1.0 : value
        self.headingTitleLabel?.alpha = value
        self.primaryHeaderLabel?.alpha = finalAlpha
        self.secondaryHeaderLabel?.alpha = finalAlpha
        self.footerButton?.alpha = finalAlpha
    }
    
}

extension OTPViewController: MenuActionDelegate {
    public func canPerform(_ action: Selector) -> Bool {
        guard let copiedString = UIPasteboard.general.string else { return false }
        return copiedString.count != numberOfOtpCharacters ? false : true
    }
}


////////////////////////////////////////////////////////////////
//MARK:-
//MARK: Helper Methods
//MARK:-
////////////////////////////////////////////////////////////////

extension OTPViewController {
    
    /**
     * Responsible for checking if a new text (with same no. of allowed characters) has been copied to clipboard or not, and then prompting (via alert) the user to paste it, or auto-paste it based on the below attributes:
     *
     * * `shouldPromptUserToPasteCopiedStringFromClipboard`
     * * `shouldAutomaticallyPasteCopiedStringFromClipboard`
     *
     */
    fileprivate func checkClipboardAndPromptUserToPasteContent() {
        if UIPasteboard.general.hasStrings {
            let clipboardString = UIPasteboard.general.string
            if clipboardString?.count == numberOfOtpCharacters && clipboardString != Self.clipboardContent {
                Self.clipboardContent = clipboardString
                guard shouldAutomaticallyPasteCopiedStringFromClipboard == false else {
                    self.stringToPaste = clipboardString!
                    return
                }
                if shouldPromptUserToPasteCopiedStringFromClipboard {
                    if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
                    self.showSimpleAlertWithTitle("Do you want to paste the text from clipboard and proceed?", firstButtonTitle: "No", secondButtonTitle: "Yes") { (secondButtonAction) in
                        self.stringToPaste = clipboardString!
                    }
                }
            }
        }
    }
    
    /**
     * Use this method to inform the delegate that a valid OTP has been entered.
     *
     * This method can be useful if you want to prepend or appennd anything in success scenarios.
     *
     */
    private func informDelegate(_ otp: String, from viewController: OTPViewController) {
        self.delegate?.authenticate(otp, from: viewController)
    }
    
    private func askUserConsentBeforeDismissingModal() {
        if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.error) }
        self.showSimpleAlertWithTitle("Are you sure you want to close without authenticating?", message: nil, firstButtonTitle: "No", secondButtonTitle: "Yes", isSecondButtonDestructive: true, firstButtonAction: nil) { (action) in
            self.dismiss(animated: true)
        }
    }
    
    private func removeListeners() {
        #if swift(>=5.0)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        #elseif swift(<5.0)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        #endif
    }
}

extension OTPViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        self.askUserConsentBeforeDismissingModal()
    }
}
