//
//  SearchTextfieldTheme.swift
//  SearchTextField
//
//  Created by Ivan on 11.10.2022.
//

import UIKit

@objc(APSearchTextFieldTheme)
public class SearchTextFieldTheme : NSObject {
    @objc public var cellHeight: CGFloat
    @objc public var cellMargins = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
    @objc public var bgColor: UIColor
    @objc public var borderColor: UIColor
    @objc public var borderWidth : CGFloat = 0
    @objc public var separatorColor: UIColor
    @objc public var font: UIFont
    @objc public var fontColor: UIColor
    @objc public var subtitleFontColor: UIColor
    @objc public var placeholderColor: UIColor?
    /// if true `cellHeight` is ignored and multiline title is enabled
    @objc public var titleUsesAutomaticHeight = false
    /// if true `cellHeight` is ignored and multiline subtitle is enabled
    @objc public var subtitleUsesAutomaticHeight = false

    @objc(initWithCellHeight:bgColor:borderColor:separatorColor:font:fontColor:subtitleFontColor:)
    init(cellHeight: CGFloat, bgColor:UIColor, borderColor: UIColor, separatorColor: UIColor, font: UIFont, fontColor: UIColor, subtitleFontColor: UIColor? = nil) {
        self.cellHeight = cellHeight
        self.borderColor = borderColor
        self.separatorColor = separatorColor
        self.bgColor = bgColor
        self.font = font
        self.fontColor = fontColor
        self.subtitleFontColor = subtitleFontColor ?? fontColor
    }

    @objc public static func lightTheme() -> SearchTextFieldTheme {
        SearchTextFieldTheme(cellHeight: 30, bgColor: UIColor(red: 1, green: 1, blue: 1, alpha: 0.6), borderColor: UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0), separatorColor: UIColor.clear, font: UIFont.systemFont(ofSize: 10), fontColor: UIColor.black)
    }

    @objc public static func darkTheme() -> SearchTextFieldTheme {
        SearchTextFieldTheme(cellHeight: 30, bgColor: UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.6), borderColor: UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0), separatorColor: UIColor.clear, font: UIFont.systemFont(ofSize: 10), fontColor: UIColor.white)
    }
}



 
