//
//  BorderedButton.swift
//  MyFavoriteMovies
//
//  Created by Jarrod Parkes on 1/23/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

/*
    Use from Udacity MyFavoriteMovies as a borderedButton utility
*/
import UIKit

// MARK: - BorderedButton: Button

class BorderedButton: UIButton {
    
    // MARK: Properties
    
    /* Constants for styling and configuration */
    let darkerBlue = UIColor(red: 0.0, green: 0.298, blue: 0.686, alpha:1.0)
    let lighterBlue = UIColor(red: 0.0, green:0.502, blue:0.839, alpha: 1.0)
    let titleLabelFontSize : CGFloat = 17.0
    let borderedButtonHeight : CGFloat = 44.0
    let borderedButtonCornerRadius : CGFloat = 4.0
    let phoneBorderedButtonExtraPadding : CGFloat = 14.0
    
    var backingColor : UIColor? = nil
    var highlightedBackingColor : UIColor? = nil
    
    // MARK: Initialization
    // triggered by the button.
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.themeBorderedButton()

    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.themeBorderedButton()

    }
    //triggered by the button
    func themeBorderedButton() -> Void {

        self.layer.masksToBounds = true
        self.layer.cornerRadius = borderedButtonCornerRadius
        //self.highlightedBackingColor = darkerBlue
        //self.backingColor = lighterBlue
        //self.backgroundColor = lighterBlue
        self.setTitleColor(UIColor.white, for: UIControlState())
        self.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: titleLabelFontSize)
    }
    
    // MARK: Setters
    
    fileprivate func setBackingColor(_ backingColor : UIColor) -> Void {

        if (self.backingColor != nil) {
            self.backingColor = backingColor;
            self.backgroundColor = backingColor;
        }
    }
    
    fileprivate func setHighlightedBackingColor(_ highlightedBackingColor: UIColor) -> Void {

        self.highlightedBackingColor = highlightedBackingColor
        self.backingColor = highlightedBackingColor
    }
    
    // MARK: Tracking
    
    override func beginTracking(_ touch: UITouch, with withEvent: UIEvent?) -> Bool {

        self.backgroundColor = self.highlightedBackingColor
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {

        self.backgroundColor = self.backingColor
    }
    
    override func cancelTracking(with event: UIEvent?) {

        self.backgroundColor = self.backingColor
    }
    
    // MARK: Layout
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {

        let extraButtonPadding : CGFloat = phoneBorderedButtonExtraPadding
        var sizeThatFits = CGSize.zero
        sizeThatFits.width = super.sizeThatFits(size).width + extraButtonPadding
        sizeThatFits.height = borderedButtonHeight
        return sizeThatFits
        
    }
}
