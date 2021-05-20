/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Primary view controller portion of UISplitViewController.
*/

import UIKit

class PrimaryViewController: UITableViewController, DetailItemDelegate {

    // The content of the table view (dates and strings).
    var tableItems = [TableItem]()
        
    #if targetEnvironment(macCatalyst)
    var addItemToolbarItem: NSToolbarItem?
    var removeItemToolbarItem: NSToolbarItem?
    #endif
    
    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    lazy var detailViewController: DetailViewController = {
        var returnDetailViewController = DetailViewController()
        if let splitViewController = view.window!.rootViewController as? UISplitViewController {
            if let detailNavigationController = splitViewController.viewControllers[1] as? UINavigationController {
                if let detailViewController = detailNavigationController.topViewController as? DetailViewController {
                    returnDetailViewController = detailViewController
                    returnDetailViewController.detailItemDelegate = self
                }
            }
        }
        return returnDetailViewController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if targetEnvironment(macCatalyst)
            // Install the up and down arrow key commands to navigate through the table cells.
            //
            if #available(macOS 11.0, *) {
                // For Big Sur 11.0 or later, arrow key commands installed UIKeyCommands are no longer needed if list is in the left side bar.
            } else {
                // Arrow key commands installed via UIKeyCommand are needed for macOS 10.15 Catalina.
                installArrowKeyCommands()
            }
        #else
            // For iOS, use this edit button in the navigation bar for editing table cells.
            navigationItem.leftBarButtonItem = editButtonItem

            let addButton =
                UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewDateObject(_:)))
            navigationItem.rightBarButtonItem = addButton
        
            // Install the up and down arrow key commands to navigate through the table cells.
            if #available(iOS 14.0, *) {
                // For iOS 14.0 or later, arrow key commands installed UIKeyCommands are no longer needed if list is in the left side bar.
            } else {
                installArrowKeyCommands()
            }
        #endif

        /** Install the up and down arrow key commands to navigate through the table cells.
            Note that up and down key commands are automatically supported on Mac Catalyst.
        */
        let downArrowCommand =
            UIKeyCommand(input: UIKeyCommand.inputDownArrow,
                         modifierFlags: [],
                         action: #selector(PrimaryViewController.downArrowAction(_:)))
        addKeyCommand(downArrowCommand)
        
        let upArrowCommand =
            UIKeyCommand(input: UIKeyCommand.inputUpArrow,
                         modifierFlags: [],
                         action: #selector(PrimaryViewController.upArrowAction(_:)))
        addKeyCommand(upArrowCommand)
        
        // Install a delete key command to delete a table cell.
        let deleteCommand =
            UIKeyCommand(input: "\u{8}", // Apply the Unicode character input for backspace key.
                         modifierFlags: [],
                         action: #selector(PrimaryViewController.delete(_:)))
        addKeyCommand(deleteCommand)
        
        /** Install Command-N to this table view.
            Note: The discoverabilityTitle is used to display its command in the overlay window on the iPad when the command-key is held down.
            Note: If building and testing on the iPad Simulator make sure to select:
                    "Hardware -> Keyboard -> Send Keyboard Shortcuts to Device".
         */
        let newCommand =
            UIKeyCommand(title: NSLocalizedString("DateItemTitle", comment: ""),
                         image: nil,
                         action: #selector(PrimaryViewController.newAction(_:)),
                         input: "N",
                         modifierFlags: .command,
                         propertyList: nil)
        newCommand.discoverabilityTitle = NSLocalizedString("Command_N_DiscoveryTitle", comment: "")
        addKeyCommand(newCommand)
    }

    override func viewWillDisappear(_ animated: Bool) {
        #if targetEnvironment(macCatalyst)
        /** This view controller disappears (hides) when toggle side bar button is clicked by the user,
            disable the Add and Remove toolbar items while this view controller is hidden.
        */
        if let toolbar = view.window!.windowScene?.titlebar?.toolbar {
            for toolbarItem in toolbar.items where
                toolbarItem.itemIdentifier == PrimaryViewController.addItemID || toolbarItem.itemIdentifier == PrimaryViewController.removeItemID {
                toolbarItem.action = nil
            }
        }
        #endif
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        
        #if targetEnvironment(macCatalyst)
        // No navigation bar for Mac Catalyst, instead use the toolbar.
        navigationController?.setNavigationBarHidden(true, animated: animated)
        #endif
  
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Create and setup the window's toolbar.
        // This is done in viewDidAppear because the view controller's window property is needed,
        // and is allocated at this time.
        //
        // (For Mac Catalyst, use a toolbar for the add and remove buttons.)
        #if targetEnvironment(macCatalyst)
            if view.window!.windowScene?.titlebar?.toolbar == nil {
                let toolbar = NSToolbar(identifier: PrimaryViewController.toolbarID)
                toolbar.allowsUserCustomization = true
                toolbar.autosavesConfiguration = false
                toolbar.displayMode = .iconOnly
                toolbar.delegate = self
                view.window!.windowScene?.titlebar?.toolbar = toolbar
                
                // To move the toolbar into the title bar.
                view.window!.windowScene?.titlebar?.titleVisibility = .hidden
            }
            
            /** Now that this view controller is appearing or re-appearing, adjust the toolbar items,
                (add and remove items are disabled when hidden).
            */
            adjustToolbarItems()
        #endif
    }
    
    func installArrowKeyCommands() {
        /** Install the up and down arrow key commands to navigate through the table cells.
            Note that up and down key commands are automatically supported on Mac Catalyst.
        */
        let downArrowCommand =
            UIKeyCommand(input: UIKeyCommand.inputDownArrow,
                         modifierFlags: [],
                         action: #selector(PrimaryViewController.downArrowAction(_:)))
        addKeyCommand(downArrowCommand)
        
        let upArrowCommand =
            UIKeyCommand(input: UIKeyCommand.inputUpArrow,
                         modifierFlags: [],
                         action: #selector(PrimaryViewController.upArrowAction(_:)))
        addKeyCommand(upArrowCommand)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        if editing {
            // User tapped the Edit button, which removes the current table selection.
            detailViewController.detailItem = nil
        }
        super.setEditing(editing, animated: animated)
    }
    
    // MARK: - Selection Support
    
    func selectDetailItem(indexPath: IndexPath) {
        detailViewController.detailItem = tableItems[indexPath.row]
    }
    
    private func selectRow(at indexPath: IndexPath) {
        // Make sure to have a row to select.
        if indexPath.row >= 0 {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .bottom)
            selectDetailItem(indexPath: indexPath)
        }
    }
    
    // MARK: - DetailItemDelegate
    
    func performCutAction() {
        cut(self)
    }
    func performCopyAction() {
        copy(self)
    }
    func performPasteAction() {
        paste(self)
    }
    func performDeleteAction() {
        delete(self)
    }
    
    func didUpdateItem(_ item: TableItem) {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableItems[selectedIndexPath.row] = item
            tableView.reloadRows(at: [selectedIndexPath], with: .automatic)
            tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
        }
    }

}

// MARK: - UIResponder

extension PrimaryViewController {
    
    // Required, to use UIKeyCommands (up and down arrows) to work for iOS.
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    // The responder chain is asking which commands are supported.
    // Enable/disable certain Edit menu commands.
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(newAction(_:)) {
            // User wants to perform a "New" operation.
            return true
        } else {
            switch (tableView.indexPathForSelectedRow, action) {
            
            // These Edit commands are supported:
            case let (_?, action) where action == #selector(cut(_:)) ||
                                        action == #selector(copy(_:)) ||
                                        action == #selector(delete(_:)):
                return true
            case (_?, _):
                // Allow the nextResponder to make the determination.
                return super.canPerformAction(action, withSender: sender)
                
            // Paste is supported if the pasteboard has text.
            case (.none, action) where action == #selector(paste(_:)):
                return (UIPasteboard.general.string != nil) ? true :
                    // Allow the nextResponder to make the determination.
                    super.canPerformAction(action, withSender: sender)
            case (.none, _):
                return false
            }
        }
    }
    
    // MARK: - Actions
    
    func adjustToolbarItems() {
        #if targetEnvironment(macCatalyst)
        // The remove toolbar item is enabled only when user has made a table selection.
        removeItemToolbarItem!.action = tableView.indexPathForSelectedRow != nil ? #selector(toolbarRemoveAction(_:)) : nil
        
        addItemToolbarItem!.action = #selector(toolbarAddAction(_:))
        #endif
    }
    
    @objc
    // User chose "New" sub menu command from the File menu (New Date or Text item).
    func newAction(_ sender: UICommand) {
        if let splitViewController = view.window?.rootViewController as? UISplitViewController {
            if let navigationController = splitViewController.viewControllers.first as? UINavigationController {
                if let primaryViewController = navigationController.visibleViewController as? PrimaryViewController {
                    // Create a date or resular string, based on the propertyList selection.
                    switch sender.propertyList {
                    case nil: primaryViewController.insert(.date(Date()))
                    case .some: primaryViewController.insert(.text("Item \(primaryViewController.tableItems.count + 1)"))
                    }
                }
            }
        }
    }
 
    // Called to cut the currently selected table row.
    override func cut(_ sender: Any?) {
        guard let selectedIndexPath = tableView.indexPathForSelectedRow else { return }
        // Add the item to the pasteboard.
        UIPasteboard.general.string = tableItems[selectedIndexPath.row].description
        // Delete the item.
        delete(self)
    }
    
    // Called to copy the currently selected table row.
    override func copy(_ sender: Any?) {
        guard let selectedIndexPath = tableView.indexPathForSelectedRow else { return }
        // Add the item top the pasteboard.
        UIPasteboard.general.string = tableItems[selectedIndexPath.row].description
    }
    
    // Called to paste a new table row.
    override func paste(_ sender: Any?) {
        guard let pasteString = UIPasteboard.general.string else { return }
        
        // De-select any existing item.
        if let selectedIndexes = tableView.indexPathsForSelectedRows {
            for selectionIndex in selectedIndexes {
                tableView.deselectRow(at: selectionIndex, animated: false)
            }
        }
        // Create the item to paste.
        let objectToInsert: TableItem = {
            switch dateFormatter.date(from: pasteString) {
            case let date?: return TableItem.date(date)
            case nil: return TableItem.text(pasteString)
            }
        }()
        // Insert the item to the table at the top and then select it.
        tableItems.insert(objectToInsert, at: 0)
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
        selectRow(at: indexPath)
    }
    
    // Called by delete key UIKeyCommand, or the Edit menu to delete a table row.
    override func delete(_ sender: Any?) {
        deleteRow()
    }

    func deleteRow() {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            var newSelectedIndexPath = IndexPath(row: selectedIndexPath.row, section: 0)

            tableItems.remove(at: selectedIndexPath.row)
            tableView.deleteRows(at: [selectedIndexPath], with: .none)
            
            if newSelectedIndexPath.row >= tableItems.count {
                newSelectedIndexPath.row -= 1
                if newSelectedIndexPath.row == -1 {
                    // The user delete the last row, no more selection made.
                    detailViewController.detailItem = nil
                }
            }

            selectRow(at: newSelectedIndexPath)
            
            #if targetEnvironment(macCatalyst)
            if newSelectedIndexPath.row == -1 {
                // If the last item in the table is deleted, there is no more selection, so disable the delete button.
                if let toolbar = view.window!.windowScene?.titlebar?.toolbar {
                    for toolbarItem in toolbar.items where
                        toolbarItem.itemIdentifier == PrimaryViewController.removeItemID {
                        toolbarItem.action = nil
                    }
                }
            }
            #endif
        }
    }
}

// MARK: - Key Command Actions

extension PrimaryViewController {
    
    // User typed up the down from the keyboard.
    @objc
    func downArrowAction(_ sender: Any) {
        if let path = tableView.indexPathForSelectedRow {
            if path.row + 1 < tableItems.count {
                let newIndexPath = IndexPath(row: path.row + 1, section: 0)
                selectRow(at: newIndexPath)
            }
        }
    }
    
    // User typed up the arrow from the keyboard.
    @objc
    func upArrowAction(_ sender: Any) {
        if let path = tableView.indexPathForSelectedRow {
            if path.row - 1 >= 0 {
                let newIndexPath = IndexPath(row: path.row - 1, section: 0)
                selectRow(at: newIndexPath)
            }
        }
    }
    
    // User clicked or tapped the '+' UIBarButtonItem in the navigation bar, insert the current date object to the list.
    @objc
    func insertNewDateObject(_ sender: Any) {
        insert(.date(Date()))
    }
    
    // Insert either a date or text object.
    func insert(_ object: TableItem) {
        tableItems.append(object)
        let indexPath = IndexPath(row: tableItems.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
        
        // Select the added object.
        self.tableView.becomeFirstResponder()
        selectRow(at: indexPath)
    }
    
}

// MARK: - Menu Command validation

extension PrimaryViewController {
    
    override func validate(_ command: UICommand) {
        //Swift.debugPrint("PrimaryViewController: validation of: \(command.title)")
  
        // Example, to directly disable Select All.
        /*
        if command.action == #selector(selectAll(_:)) {
            command.state = .off
        }*/
        
        super.validate(command)
    }
}
