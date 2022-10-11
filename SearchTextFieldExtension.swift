//
//  SearchTextFieldExtension.swift
//  SearchTextField
//
//  Created by Ivan on 11.10.2022.
//

import UIKit
extension SearchTextField: UITableViewDelegate, UITableViewDataSource {
   
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.isHidden = !interactedWith || (filteredResults.count == 0)
   
        shadowView?.isHidden = !interactedWith || (filteredResults.count == 0)
        
        if maxNumberOfResults > 0 {
            return min(filteredResults.count, maxNumberOfResults)
        } else {
            return filteredResults.count
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath) as! SearchTextFieldTableViewCell
        
        cell.backgroundColor = UIColor.clear
        cell.margins = theme.cellMargins
        cell.titleLabel.font = theme.font
        cell.subtitleLabel.font = theme.font.withSize(theme.font.pointSize * fontConversionRate)
        cell.titleLabel.textColor = theme.fontColor
        cell.subtitleLabel.textColor = theme.subtitleFontColor
        
        cell.titleLabel.text = filteredResults[(indexPath as NSIndexPath).row].title
        cell.subtitleLabel.text = filteredResults[(indexPath as NSIndexPath).row].subtitle
        cell.titleLabel.attributedText = filteredResults[(indexPath as NSIndexPath).row].attributedTitle
        cell.subtitleLabel.attributedText = filteredResults[(indexPath as NSIndexPath).row].attributedSubtitle

        cell.titleLabel.numberOfLines = theme.titleUsesAutomaticHeight ? 0 : 1;
        cell.subtitleLabel.numberOfLines = theme.subtitleUsesAutomaticHeight ? 0 : 1;

        cell.imageView?.image = filteredResults[(indexPath as NSIndexPath).row].image
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        (theme.titleUsesAutomaticHeight || theme.subtitleUsesAutomaticHeight)
                ? UITableView.automaticDimension
                : theme.cellHeight
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if itemSelectionHandler == nil {
            text = filteredResults[(indexPath as NSIndexPath).row].title
        } else {
            let index = indexPath.row
            itemSelectionHandler!(filteredResults, index)
        }
        
        clearResults()
    }
}




