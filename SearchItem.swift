//
//  SearchItem.swift
//  SearchTextField
//
//  Created by Ivan on 08.10.2022.
//

import UIKit
// Filter Item

@objc(APSearchTextFieldItem)
open class SearchTextFieldItem : NSObject {

   var attributedTitle: NSMutableAttributedString?
   var attributedSubtitle: NSMutableAttributedString?
    // use original* versions to restore attributed strings after adding highlighting attributes
   var originalAttributedTitle: NSMutableAttributedString?
 var originalAttributedSubtitle: NSMutableAttributedString?
     
    var titleSearchRange: NSRange?
    var subtitleSearchRange: NSRange?

    // Public interface
    @objc public var title: String
    @objc public var subtitle: String?
    @objc public var image: UIImage?
    /// Arbitrary object associated with search item
    @objc public var object: AnyObject?

    @objc(initWithTitle:subtitle:image:)
    public init(title: String, subtitle: String?, image: UIImage?) {
        self.title = title
        self.subtitle = subtitle
        self.image = image
    }

    @objc(initWithTitle:subtitle:)
    public init(title: String, subtitle: String?) {
        self.title = title
        self.subtitle = subtitle
    }

    @objc(initWithTitle:)
    public init(title: String) {
        self.title = title
    }

    @objc(initWithAttributedTitle:attributedSubtitle:)
    public convenience init(
            attributedTitle: NSAttributedString,
            attributedSubtitle: NSAttributedString?) {
        self.init(title: attributedTitle.string, subtitle: attributedSubtitle?.string)
        originalAttributedTitle = (attributedTitle.mutableCopy() as! NSMutableAttributedString)
        originalAttributedSubtitle = (attributedSubtitle?.mutableCopy() as! NSMutableAttributedString)
    }

    @objc(initWithAttributedTitle:attributedSubtitle:object:)
    public convenience init(
            attributedTitle: NSAttributedString,
            attributedSubtitle: NSAttributedString?,
            object: AnyObject?) {
        self.init(title: attributedTitle.string, subtitle: attributedSubtitle?.string)
        originalAttributedTitle = (attributedTitle.mutableCopy() as! NSMutableAttributedString)
        originalAttributedSubtitle = (attributedSubtitle?.mutableCopy() as! NSMutableAttributedString)
        titleSearchRange = NSMakeRange(0, attributedTitle.string.count)
        subtitleSearchRange = NSMakeRange(0, attributedSubtitle?.string.count ?? 0)
        self.object = object
    }

    @objc(initWithAttributedTitle:attributedSubtitle:titleSearchRange:subtitleSearchRange:object:)
    public convenience init(
            attributedTitle: NSAttributedString,
            attributedSubtitle: NSAttributedString?,
            titleSearchRange: NSRange,
            subtitleSearchRange: NSRange,
            object: AnyObject?) {
        self.init(title: attributedTitle.string, subtitle: attributedSubtitle?.string)
        originalAttributedTitle = (attributedTitle.mutableCopy() as! NSMutableAttributedString)
        originalAttributedSubtitle = (attributedSubtitle?.mutableCopy() as! NSMutableAttributedString)
        self.titleSearchRange = titleSearchRange
        self.subtitleSearchRange = subtitleSearchRange
        self.object = object
    }
}

public typealias SearchTextFieldItemHandler = (_ filteredResults: [SearchTextFieldItem], _ index: Int) -> Void

