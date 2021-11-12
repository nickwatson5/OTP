//
//  UIFontExtensions.swift
//

import UIKit

extension UIFont {
    
    /**
     * A handy function which normalizes the font size for all the devices. If you call this method on a `UILabel`, the text will appear in the same size visually across different devices so you don't have to worry about setting different font sizes for devices like **iPhone 4s, iPhone 5, iPhone 8 plus, X's, and iPad's**.
     
     * When initially setting font for the label (either in Interface Builder or in code), always set for the smallest-sized device, iPhone SE. This method works by scaling the font size by multiplying it with a multiplier value. Since it is an incremental scaling, you have to set the font size for the smallest device, so that the size scales properly throughout all bigger deivces.
     
     * - Returns: The normalized font.
     */
    
    @objc func normalized() -> UIFont {
        
        //////////////////////////////////////////////////////
        //////Required values for multiplier calculation//////
        //////////////////////////////////////////////////////
        
        let deviceScaleFactor = UIScreen.main.scale
        let isiPad = UIDevice.current.userInterfaceIdiom == .pad
        
        let deviceWidth:Double = Double(UIScreen.main.bounds.width)
        let deviceHeight:Double = Double(UIScreen.main.bounds.height)
        
        let aspectRatio = NSObject.deviceIsInLandscape ? deviceHeight/deviceWidth : deviceWidth/deviceHeight
        
        /////////////////////////////////////
        //////Decide primary multiplier//////
        /////////////////////////////////////
        
        var primaryMultiplier = 0.01
        
        switch deviceScaleFactor {
        case 1:
            primaryMultiplier = 0.3
            break
        case 2:
            primaryMultiplier = 0.42
            break
        default:
            primaryMultiplier = 0.52
            break
        }
        
        //////////////////////////////////////
        //////Calculate final multiplier//////
        //////////////////////////////////////
        
        let finalMultiplier = aspectRatio + (isiPad ? 0.52 : primaryMultiplier)
        
        return self.withSize(self.pointSize * CGFloat(finalMultiplier))
    }
    
}

