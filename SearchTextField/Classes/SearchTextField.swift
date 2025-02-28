//
//  SearchTextField.swift
//  SearchTextField
//
//  Created by Alejandro Pasccon on 4/20/16.
//  Copyright © 2016 Alejandro Pasccon. All rights reserved.
//

import UIKit

@objc(APSearchTextField)
open class SearchTextField: UITextField {
    
    ////////////////////////////////////////////////////////////////////////
    // Public interface
    
    /// Maximum number of results to be shown in the suggestions list
    @objc open var maxNumberOfResults = 0
    
    /// Maximum height of the results list
    @objc open var maxResultsListHeight = 0
    
    /// Indicate if this field has been interacted with yet
    @objc open var interactedWith = false
    
    /// Indicate if keyboard is showing or not
    @objc open var keyboardIsShowing = false

    /// How long to wait before deciding typing has stopped
    @objc open var typingStoppedDelay = 0.8
    
    /// Set your custom visual theme, or just choose between pre-defined SearchTextFieldTheme.lightTheme() and SearchTextFieldTheme.darkTheme() themes
    @objc open var theme = SearchTextFieldTheme.lightTheme() {
        didSet {
            tableView?.reloadData()
            
            if let placeholderColor = theme.placeholderColor {
                if let placeholderString = placeholder {
                    attributedPlaceholder = NSAttributedString(string: placeholderString, attributes: [NSAttributedString.Key.foregroundColor: placeholderColor])
                }
                
                placeholderLabel?.textColor = placeholderColor
            }
           
            if let highlightedFont = highlightAttributes[.font] as? UIFont {
                highlightAttributes[.font] = highlightedFont.withSize(theme.font.pointSize)
            }
        }
    }
    
    /// Show the suggestions list without filter when the text field is focused
    @objc open var startVisible = false
    
    /// Show the suggestions list without filter even if the text field is not focused
    @objc open var startVisibleWithoutInteraction = false {
        didSet {
            if startVisibleWithoutInteraction {
                textFieldDidChange()
            }
        }
    }
    
    /// Set an array of SearchTextFieldItem's to be used for suggestions
    @objc open func filterItems(_ items: [SearchTextFieldItem]) {
        filterDataSource = items
    }
    
    /// Set an array of strings to be used for suggestions
    @objc open func filterStrings(_ strings: [String]) {
        var items = [SearchTextFieldItem]()
        
        for value in strings {
            items.append(SearchTextFieldItem(title: value))
        }
        
        filterItems(items)
    }
    
    /// Closure to handle when the user pick an item
    @objc open var itemSelectionHandler: SearchTextFieldItemHandler?
    
    /// Closure to handle when the user stops typing
    @objc open var userStoppedTypingHandler: (() -> Void)?
    
    /// Set your custom set of attributes in order to highlight the string found in each item
    @objc open var highlightAttributes: [NSAttributedString.Key: AnyObject] = [.font: UIFont.boldSystemFont(ofSize: 10)]
    
    /// Start showing the default loading indicator, useful for searches that take some time.
    @objc open func showLoadingIndicator() {
        rightViewMode = .always
        indicator.startAnimating()
    }
    
    /// Force the results list to adapt to RTL languages
    @objc open var forceRightToLeft = false
    
    /// Hide the default loading indicator
    @objc open func stopLoadingIndicator() {
        rightViewMode = .never
        indicator.stopAnimating()
    }
    
    /// When InlineMode is true, the suggestions appear in the same line than the entered string. It's useful for email domains suggestion for example.
    @objc open var inlineMode: Bool = false {
        didSet {
            if inlineMode == true {
                autocorrectionType = .no
                spellCheckingType = .no
            }
        }
    }
    
    /// Only valid when InlineMode is true. The suggestions appear after typing the provided string (or even better a character like '@')
    @objc open var startFilteringAfter: String?
    
    /// Min number of characters to start filtering
    @objc open var minCharactersNumberToStartFiltering: Int = 0

    /// Force no filtering (display the entire filtered data source)
    @objc open var forceNoFiltering: Bool = false
    
    /// If startFilteringAfter is set, and startSuggestingImmediately is true, the list of suggestions appear immediately
    @objc open var startSuggestingImmediately = false
    
    /// Allow to decide the comparison options
    @objc open var comparisonOptions: NSString.CompareOptions = [.caseInsensitive]
    
    /// Set the results list's header
    @objc open var resultsListHeader: UIView?

    // Move the table around to customize for your layout
    @objc open var tableXOffset: CGFloat = 0.0
    @objc open var tableYOffset: CGFloat = 0.0
    @objc open var tableCornerRadius: CGFloat = 2.0
    @objc open var tableBottomMargin: CGFloat = 10.0
    
    @objc open var textInset = UIEdgeInsets()

    @objc open var leftViewLeadingMargin: CGFloat = 0
    
    ////////////////////////////////////////////////////////////////////////
    // Private implementation
    
    fileprivate var tableView: UITableView?
   var shadowView: UIView?
    fileprivate var direction: Direction = .down
     var fontConversionRate: CGFloat = 0.7
    fileprivate var keyboardFrame: CGRect?
    fileprivate var timer: Timer? = nil
    fileprivate var placeholderLabel: UILabel?
  static let cellIdentifier = "APSearchTextFieldCell"
    fileprivate let indicator = UIActivityIndicatorView(style: .gray)
    fileprivate var maxTableViewSize: CGFloat = 0
    
   var filteredResults = [SearchTextFieldItem]()
    fileprivate var filterDataSource = [SearchTextFieldItem]() {
        didSet {
            filter(forceShowAll: forceNoFiltering)
            buildSearchTableView()
            
            if startVisibleWithoutInteraction {
                textFieldDidChange()
            }
        }
    }
    
    fileprivate var currentInlineItem = ""
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        tableView?.removeFromSuperview()
    }
    
    override open func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        addTarget(self, action: #selector(SearchTextField.textFieldDidChange), for: .editingChanged)
        addTarget(self, action: #selector(SearchTextField.textFieldDidBeginEditing), for: .editingDidBegin)
        addTarget(self, action: #selector(SearchTextField.textFieldDidEndEditing), for: .editingDidEnd)
        addTarget(self, action: #selector(SearchTextField.textFieldDidEndEditingOnExit), for: .editingDidEndOnExit)
        
        NotificationCenter.default.addObserver(self, selector: #selector(SearchTextField.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SearchTextField.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SearchTextField.keyboardDidChangeFrame(_:)), name: UIResponder.keyboardDidChangeFrameNotification, object: nil)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        if inlineMode {
            buildPlaceholderLabel()
        } else {
            buildSearchTableView()
        }
        
        // Create the loading indicator
        indicator.hidesWhenStopped = true
        rightView = indicator
    }
    
    override open func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        var rightFrame = super.rightViewRect(forBounds: bounds)
        rightFrame.origin.x -= 5
        return rightFrame
    }

    open override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        var leftFrame = super.leftViewRect(forBounds: bounds)
        leftFrame.origin.x += leftViewLeadingMargin
        return leftFrame
    }

    open override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.inset(by: textInset)
    }
    
    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.inset(by: textInset)
    }
    
    // Create the filter table and shadow view
    fileprivate func buildSearchTableView() {
        guard let tableView = tableView, let shadowView = shadowView else {
            tableView = UITableView(frame: CGRect.zero)
            shadowView = UIView(frame: CGRect.zero)
            buildSearchTableView()
            return
        }
        
        tableView.layer.masksToBounds = true
        tableView.layer.borderWidth = theme.borderWidth > 0 ? theme.borderWidth : 0.5
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.tableHeaderView = resultsListHeader
        tableView.register(SearchTextFieldTableViewCell.self, forCellReuseIdentifier: SearchTextField.cellIdentifier)

        if forceRightToLeft {
            tableView.semanticContentAttribute = .forceRightToLeft
        }
        
        shadowView.backgroundColor = UIColor.lightText
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowOffset = CGSize.zero
        shadowView.layer.shadowOpacity = 1
        
        window?.addSubview(tableView)
        
        redrawSearchTableView()
    }
    
    fileprivate func buildPlaceholderLabel() {
        var newRect = placeholderRect(forBounds: bounds)
        var caretRect = caretRect(for: beginningOfDocument)
        let textRect = textRect(forBounds: bounds)
        
        if let range = textRange(from: beginningOfDocument, to: endOfDocument) {
            caretRect = firstRect(for: range)
        }
        
        newRect.origin.x = caretRect.origin.x + caretRect.size.width + textRect.origin.x
        newRect.size.width = newRect.size.width - newRect.origin.x
        
        if let placeholderLabel = placeholderLabel {
            placeholderLabel.font = font
            placeholderLabel.frame = newRect
        } else {
            placeholderLabel = UILabel(frame: newRect)
            placeholderLabel?.font = font
            placeholderLabel?.backgroundColor = UIColor.clear
            placeholderLabel?.lineBreakMode = .byClipping
            
            if let placeholderColor = attributedPlaceholder?.attribute(NSAttributedString.Key.foregroundColor, at: 0, effectiveRange: nil) as? UIColor {
                placeholderLabel?.textColor = placeholderColor
            } else {
                placeholderLabel?.textColor = UIColor ( red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0 )
            }
            
            addSubview(placeholderLabel!)
        }
    }
    
    // Re-set frames and theme colors
    fileprivate func redrawSearchTableView() {
        if inlineMode {
            tableView?.isHidden = true
            return
        }
        
        if let tableView = tableView {
            let frame = self.convert(bounds, to: nil)
            
            //TableViews use estimated cell heights to calculate content size until they
            //  are on-screen. We must set this to the theme cell height to avoid getting an
            //  incorrect contentSize when we have specified non-standard fonts and/or
            //  cellHeights in the theme. We do it here to ensure updates to these settings
            //  are recognized if changed after the tableView is created
            tableView.estimatedRowHeight = theme.cellHeight
            
            if direction == .down {
                
                var tableHeight: CGFloat = 0
                if keyboardIsShowing, let keyboardHeight = keyboardFrame?.size.height {
                    tableHeight = min((tableView.contentSize.height), (UIScreen.main.bounds.size.height - frame.origin.y - frame.height - keyboardHeight))
                } else {
                    tableHeight = min((tableView.contentSize.height), (UIScreen.main.bounds.size.height - frame.origin.y - frame.height))
                }
                
                if maxResultsListHeight > 0 {
                    tableHeight = min(tableHeight, CGFloat(maxResultsListHeight))
                }
                
                // Set a bottom margin of 10p
                if tableHeight < tableView.contentSize.height {
                    tableHeight -= tableBottomMargin
                }
                
                var tableViewFrame = CGRect(x: 0, y: 0, width: frame.size.width - 4, height: tableHeight)
                tableViewFrame.origin = self.convert(tableViewFrame.origin, to: nil)
                tableViewFrame.origin.x += 2 + tableXOffset
                tableViewFrame.origin.y += frame.size.height + 2 + tableYOffset
                self.tableView?.frame.origin = tableViewFrame.origin // Avoid animating from (0, 0) when displaying at launch
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    self?.tableView?.frame = tableViewFrame
                })
                
                var shadowFrame = CGRect(x: 0, y: 0, width: frame.size.width - 6, height: 1)
                shadowFrame.origin = self.convert(shadowFrame.origin, to: nil)
                shadowFrame.origin.x += 3
                shadowFrame.origin.y = tableView.frame.origin.y
                shadowView!.frame = shadowFrame
            } else {
                let tableHeight = min(
                    tableView.contentSize.height,
                    frame.origin.y - UIApplication.shared.statusBarFrame.height
                )

                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    self?.tableView?.frame = CGRect(
                        x: frame.origin.x + 2,
                        y: frame.origin.y - tableHeight,
                        width: frame.size.width - 4,
                        height: tableHeight)
                    self?.shadowView?.frame = CGRect(
                        x: frame.origin.x + 3,
                        y: frame.origin.y + 3,
                        width: frame.size.width - 6,
                        height: 1)
                })
            }
            
            superview?.bringSubviewToFront(tableView)
            superview?.bringSubviewToFront(shadowView!)
            
            if isFirstResponder {
                superview?.bringSubviewToFront(self)
            }
            
            tableView.layer.borderColor = theme.borderColor.cgColor
            tableView.layer.cornerRadius = tableCornerRadius
            tableView.separatorColor = theme.separatorColor
            tableView.backgroundColor = theme.bgColor
            
            tableView.reloadData()
        }
    }
    
    // Handle keyboard events
    @objc open func keyboardWillShow(_ notification: Notification) {
        if !keyboardIsShowing && isEditing {
            keyboardIsShowing = true
            keyboardFrame = ((notification as NSNotification).userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            interactedWith = true
            prepareDrawTableResult()
        }
    }
    
    @objc open func keyboardWillHide(_ notification: Notification) {
        if keyboardIsShowing {
            keyboardIsShowing = false
            direction = .down
            redrawSearchTableView()
        }
    }
    
    @objc open func keyboardDidChangeFrame(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.keyboardFrame = ((notification as NSNotification).userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            self?.prepareDrawTableResult()
        }
    }
    
    @objc open func typingDidStop() {
        userStoppedTypingHandler?()
    }
    
    // Handle text field changes
    @objc open func textFieldDidChange() {
        if !inlineMode && tableView == nil {
            buildSearchTableView()
        }
        
        interactedWith = true
        
        // Detect pauses while typing
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: typingStoppedDelay, target: self, selector: #selector(SearchTextField.typingDidStop), userInfo: self, repeats: false)
        
        if text!.isEmpty {
            clearResults()
            tableView?.reloadData()
            if startVisible || startVisibleWithoutInteraction {
                filter(forceShowAll: true)
            }
            placeholderLabel?.text = ""
        } else {
            filter(forceShowAll: forceNoFiltering)
            prepareDrawTableResult()
        }
        
        buildPlaceholderLabel()
    }
    
    @objc open func textFieldDidBeginEditing() {
        if (startVisible || startVisibleWithoutInteraction) && text!.isEmpty {
            clearResults()
            filter(forceShowAll: true)
        }
        placeholderLabel?.attributedText = nil
    }
    
    @objc open func textFieldDidEndEditing() {
        clearResults()
        tableView?.reloadData()
        placeholderLabel?.attributedText = nil
    }
    
    @objc open func textFieldDidEndEditingOnExit() {
        if let firstElement = filteredResults.first {
            if let itemSelectionHandler = itemSelectionHandler {
                itemSelectionHandler(filteredResults, 0)
            }
            else {
                if inlineMode, let filterAfter = startFilteringAfter {
                    let stringElements = text?.components(separatedBy: filterAfter)
                    
                    text = stringElements!.first! + filterAfter + firstElement.title
                } else {
                    text = firstElement.title
                }
            }
        }
    }
    
    open func hideResultsList() {
        if let tableFrame:CGRect = tableView?.frame {
            let newFrame = CGRect(x: tableFrame.origin.x, y: tableFrame.origin.y, width: tableFrame.size.width, height: 0.0)
            UIView.animate(withDuration: 0.2, animations: { [weak self] in
                self?.tableView?.frame = newFrame
            })
            
        }
    }
    
    fileprivate func filter(forceShowAll addAll: Bool) {
        clearResults()
        
        if text!.count < minCharactersNumberToStartFiltering {
            return
        }
        
        for i in 0 ..< filterDataSource.count {
            
            let item = filterDataSource[i]
            
            if !inlineMode {
                // Find text in title and subtitle
                var titleFilterRange = (item.title as NSString).range(of: text!, options: comparisonOptions)

                if let titleSearchRange = item.titleSearchRange {
                    if NSIntersectionRange(titleFilterRange, titleSearchRange).length == 0 {
                        titleFilterRange.location = NSNotFound
                    }
                }

                var subtitleFilterRange = item.subtitle != nil ? (item.subtitle! as NSString).range(of: text!, options: comparisonOptions) : NSMakeRange(NSNotFound, 0)

                if let subtitleSearchRange = item.subtitleSearchRange {
                    if NSIntersectionRange(subtitleFilterRange, subtitleSearchRange).length == 0 {
                        subtitleFilterRange.location = NSNotFound
                    }
                }
                
                if titleFilterRange.location != NSNotFound || subtitleFilterRange.location != NSNotFound || addAll {
                    item.attributedTitle = (item.originalAttributedTitle?.mutableCopy() as? NSMutableAttributedString) ?? NSMutableAttributedString(string: item.title)

                    item.attributedSubtitle = (item.originalAttributedSubtitle?.mutableCopy() as? NSMutableAttributedString) ?? NSMutableAttributedString(string: (item.subtitle != nil ? item.subtitle! : ""))

                    item.attributedTitle!.addAttributes(highlightAttributes, range: titleFilterRange)
                    
                    if subtitleFilterRange.location != NSNotFound {
                        item.attributedSubtitle!.addAttributes(highlightAttributesForSubtitle(), range: subtitleFilterRange)
                    }
                    
                    filteredResults.append(item)
                }
            } else {
                var textToFilter = text!.lowercased()
                
                if inlineMode, let filterAfter = startFilteringAfter {
                    if let suffixToFilter = textToFilter.components(separatedBy: filterAfter).last, (suffixToFilter != "" || startSuggestingImmediately == true), textToFilter != suffixToFilter {
                        textToFilter = suffixToFilter
                    } else {
                        placeholderLabel?.text = ""
                        return
                    }
                }
                
                if item.title.lowercased().hasPrefix(textToFilter) {
                    let indexFrom = textToFilter.index(textToFilter.startIndex, offsetBy: textToFilter.count)
                    let itemSuffix = item.title[indexFrom...]
                    
                    item.attributedTitle = NSMutableAttributedString(string: String(itemSuffix))
                    filteredResults.append(item)
                }
            }
        }
        
        tableView?.reloadData()
        
        if inlineMode {
            handleInlineFiltering()
        }
    }
    
    // Clean filtered results
 func clearResults() {
        filteredResults.removeAll()
        tableView?.removeFromSuperview()
    }
    
    // Look for Font attribute, and if it exists, adapt to the subtitle font size
    fileprivate func highlightAttributesForSubtitle() -> [NSAttributedString.Key: AnyObject] {
        var highlightAttributesForSubtitle = [NSAttributedString.Key: AnyObject]()
        
        for attr in highlightAttributes {
            if attr.0 == NSAttributedString.Key.font {
                let pointSize = (attr.1 as! UIFont).pointSize * fontConversionRate
                highlightAttributesForSubtitle[attr.0] = (attr.1 as! UIFont).withSize(pointSize)
            } else {
                highlightAttributesForSubtitle[attr.0] = attr.1
            }
        }
        
        return highlightAttributesForSubtitle
    }
    
    // Handle inline behaviour
    func handleInlineFiltering() {
        if let text = text {
            if text == "" {
                placeholderLabel?.attributedText = nil
            } else {
                if let firstResult = filteredResults.first {
                    placeholderLabel?.attributedText = firstResult.attributedTitle
                } else {
                    placeholderLabel?.attributedText = nil
                }
            }
        }
    }
    
    // MARK: - Prepare for draw table result
    
    fileprivate func prepareDrawTableResult() {
        guard let frame = superview?.convert(frame, to: UIApplication.shared.keyWindow) else { return }
        if let keyboardFrame = keyboardFrame {
            var newFrame = frame
            newFrame.size.height += theme.cellHeight
            
            if keyboardFrame.intersects(newFrame) {
                direction = .up
            } else {
                direction = .down
            }
            
            redrawSearchTableView()
        } else {
            if center.y + theme.cellHeight > UIApplication.shared.keyWindow!.frame.size.height {
                direction = .up
            } else {
                direction = .down
            }
        }
    }
}

