/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Toolbar support for the primary view controller.
*/

import UIKit

#if targetEnvironment(macCatalyst)

extension PrimaryViewController: NSToolbarDelegate {
 
    // Item identifiers used to create and access NSToolbarItems.
    static let toolbarID = NSToolbar.Identifier("toolbarIdentifier")
    static let addItemID = NSToolbarItem.Identifier("addIdentifier")
    static let removeItemID = NSToolbarItem.Identifier("removeIdentifier")
    
    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

        var toolbarItemToAdd: NSToolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
        
        if itemIdentifier == PrimaryViewController.addItemID {
            if #available(macCatalyst 14.0, *) {
                // Mac Catalyst on macOS 11 Big Sir, use the system Add button.
                let barButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(toolbarAddAction(_:)))
                toolbarItemToAdd = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            } else {
                // Mac Catalyst on macOS 10.15.x Catalina, create our own Add button.
                if let buttonImage = toolbarImage(systemName: "plus") {
                    let barButtonItem = UIBarButtonItem(image: buttonImage,
                                                    style: .plain,
                                                    target: self,
                                                    action: #selector(toolbarAddAction(_:)))
                    toolbarItemToAdd = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
                }
            }
        } else if itemIdentifier == PrimaryViewController.removeItemID {
            if let buttonImage = toolbarImage(systemName: "minus") {
                let barButtonItem = UIBarButtonItem(image: buttonImage,
                                                style: .plain,
                                                target: self,
                                                action: #selector(toolbarRemoveAction(_:)))
                toolbarItemToAdd = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            }
        }
        
        return toolbarItemToAdd
    }
    
    func toolbarWillAddItem(_ notification: Notification) {
        let userInfo = notification.userInfo!
        if let addedItem = userInfo["item"] as? NSToolbarItem {
            let itemIdentifier = addedItem.itemIdentifier
            if itemIdentifier == PrimaryViewController.removeItemID {
                removeItemToolbarItem = addedItem
            } else if itemIdentifier == PrimaryViewController.addItemID {
                addItemToolbarItem = addedItem
            }
        }
    }

    func toolbarItems() -> [NSToolbarItem.Identifier] {
        var toolbarItemIdentifiers = [NSToolbarItem.Identifier]()
        if #available(macCatalyst 14.0, *) {
            toolbarItemIdentifiers.append(NSToolbarItem.Identifier.toggleSidebar)
        }
        toolbarItemIdentifiers.append(PrimaryViewController.addItemID)
        toolbarItemIdentifiers.append(PrimaryViewController.removeItemID)
        return toolbarItemIdentifiers
    }
    
    /** NSToolbar delegates require this function. It returns an array holding identifiers for the default
        set of toolbar items. It can also be called by the customization palette to display the default toolbar.
     */
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarItems()
    }
    
    /** NSToolbar delegates require this function. It returns an array holding identifiers for all allowed
        toolbar items in this toolbar. Any not listed here will not be available in the customization palette.
     */
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarItems()
    }

    func toolbarImage(systemName: String) -> UIImage? {
        var buttonImage: UIImage?
        if let image = UIImage(systemName: systemName) {
            if let symbol = image.applyingSymbolConfiguration(.init(pointSize: 13)) {
                let format = UIGraphicsImageRendererFormat()
                format.preferredRange = .standard
                buttonImage =
                    UIGraphicsImageRenderer(size: symbol.size, format: format).image { _ in
                        symbol.draw(at: .zero)
                    }.withRenderingMode(.alwaysTemplate)
            }
        }
        return buttonImage
    }
    
    // MARK: - Actions
    
    @objc
    func toolbarAddAction(_ sender: Any) {
        if let splitViewController = view.window?.rootViewController as? UISplitViewController {
            if let navigationController = splitViewController.viewControllers.first as? UINavigationController {
                if let primaryViewController = navigationController.visibleViewController as? PrimaryViewController {
                    primaryViewController.insert(.date(Date()))
                    
                    // Adjust the toolbar items (in case the first table item is inserted).
                    adjustToolbarItems()
                }
            }
        }
    }
    
    @objc
    func toolbarRemoveAction(_ sender: Any) {
        deleteRow()
    }
}

#endif
