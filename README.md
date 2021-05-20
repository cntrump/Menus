# Adding Menus and Shortcuts to the Menu Bar and User Interface

Provide quick access to useful actions by adding menus and keyboard shortcuts to your Mac app built with Mac Catalyst.

## Overview

This sample project demonstrates how to add menu commands and keyboard shortcuts to the menu bar. The sample app uses its `MenuController` object to insert a [`UIMenu`](https://developer.apple.com/documentation/uikit/uimenusystem) object that adds the following menus:

* New --- Appears at the beginning of the File menu and contains two operations: Date Item and Text Item.

* Cities --- Contains a group of [`UICommand`](https://developer.apple.com/documentation/uikit/uicommand) and [`UIKeyCommand`](https://developer.apple.com/documentation/uikit/uikeycommand) objects.

* Navigation --- Contains a group of `UIKeyCommand` objects for command-key navigation.

* Style --- Contains a group of `UICommand` objects that have checkmark states. This grouping looks like a font-style menu for text formatting.

* Tools --- Contains a group of `UICommand` objects.

The sample project also shows you how to add contextual menus to views, and how to handle menu-command selection using [`UIContextMenuInteractionDelegate`](https://developer.apple.com/documentation/uikit/uicontextmenuinteractiondelegate). 

## Add Menus to the Menu Bar

The Mac version of an iPad app comes with a standard menu bar. Use the [`UIMenuSystem`](https://developer.apple.com/documentation/uikit/uimenusystem) class, an object that represents the main or contextual menu system, to modify the menu bar. 

The sample also uses `UIMenuSystem` to add menus to the [`main`](https://developer.apple.com/documentation/uikit/uimenusystem/3327314-main) system menu by implementing [`buildMenu(with:)`](https://developer.apple.com/documentation/uikit/uiresponder/3327317-buildmenu) in `AppDelegate`. This function receives a [`UIMenuBuilder`](https://developer.apple.com/documentation/uikit/uimenubuilder) object that the sample then uses to add and remove menus. Because menus can exist with no window or view hierarchy, the system only consults `UIApplication` and `UIApplicationDelegate` to build the app's menu bar.

Menu commands consist of `UICommand`, `UIKeyCommand`, and [`UIAction`](https://developer.apple.com/documentation/uikit/uiaction) objects that are grouped in a `UIMenu` container.

## Add a Menu Command to the File Menu

This sample inserts a `UIKeyCommand` called Command-O into the File Menu and creates a corresponding keyboard shortcut:

``` swift
class func openMenu() -> UIMenu {
    let openCommand =
        UIKeyCommand(title: NSLocalizedString("OpenTitle", comment: ""),
                     image: nil,
                     action: #selector(AppDelegate.openAction),
                     input: "O",
                     modifierFlags: .command,
                     propertyList: nil)
    let openMenu =
        UIMenu(title: "",
               image: nil,
               identifier: UIMenu.Identifier("com.example.apple-samplecode.menus.openMenu"),
               options: .displayInline,
               children: [openCommand])
    return openMenu
}
```

Notice that the `UIKeyCommand` title is a localized string using the [`NSLocalizedString`](https://developer.apple.com/documentation/foundation/nslocalizedstring) function, which can display the menu name in multiple languages.

This sample inserts the Open command into the middle of the menu bar's File menu:

``` swift
builder.insertChild(MenuController.openMenu(), atStartOfMenu: .file)
```

## Contribute to the Edit Menu

Editing operations, such as cut, copy, paste, and delete, are commonly used in most apps. This sample app provides these operations through the Edit menu, where the user can edit the sample's left-side content or its primary table-view content. These operations represent the first-responder functions: `cut(_ sender: Any?)`, `copy(_ sender: Any?)`, `paste(_ sender: Any?)`, `delete(_ sender: Any?)`.

This sample determines if these edit operations are supported by implementing `canPerformAction:withSender:`.

``` swift
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
```

## Add Commands to Control the User Interface

In the sample, the primary or left-side table view's selection can change by using `UIKeyCommands`. These key commands are connected to the up and down arrow keys and are added directly to the table view. The following example shows how to add the down arrow key as a `UIKeyCommand`:

``` swift
let downArrowCommand =
    UIKeyCommand(input: UIKeyCommand.inputDownArrow,
                 modifierFlags: [],
                 action: #selector(PrimaryViewController.downArrowAction(_:)))
addKeyCommand(downArrowCommand)
```

The sample also demonstrates how to add menu commands as command-key equivalents. The following example shows how to create a menu with all four arrow keys as Command-keys:

``` swift
class func navigationMenu() -> UIMenu {
    let keyCommands = [ UIKeyCommand.inputRightArrow,
                        UIKeyCommand.inputLeftArrow,
                        UIKeyCommand.inputUpArrow,
                        UIKeyCommand.inputDownArrow ]
    let arrows = Arrows.allCases
    
    let arrowKeyChildrenCommands = zip(keyCommands, arrows).map { (command, arrow) in
        UIKeyCommand(title: arrow.localizedString(),
                     image: nil,
                     action: #selector(AppDelegate.navigationMenuAction(_:)),
                     input: command,
                     modifierFlags: .command,
                     propertyList: [CommandPListKeys.ArrowsKeyIdentifier: arrow.rawValue])
    }
    
    let arrowKeysGroup = UIMenu(title: "",
                  image: nil,
                  identifier: UIMenu.Identifier("com.example.apple-samplecode.menus.arrowKeysSubMenu"),
                  options: .displayInline,
                  children: arrowKeyChildrenCommands)
    
    return UIMenu(title: NSLocalizedString("NavigationTitle", comment: ""),
                  image: nil,
                  identifier: UIMenu.Identifier("com.example.apple-samplecode.menus.navigationMenu"),
                  options: [],
                  children: [arrowKeysGroup])
}
```

## Display Contextual Menus

The sample displays a contextual menu through the use of  `UIContextMenuInteractionDelegate`, an interaction object used to display relevant actions for the content.

For macOS user control-clicks, or right-mouse clicks the `DetailViewController`. For iPadOS, the user taps and holds the `DetailViewController`.
The sample uses `UIContextMenuInteractionDelegate` to display Cut, Copy, Paste, Delete, Rename, and Share commands. This kind of contextual menu is a grouping of `UIAction` objects. `UIAction` is a menu element that performs its action in a closure. In iOS, optionally customize this contextual menu's highlight preview by using [`contextMenuInteraction(_:previewForHighlightingMenuWithConfiguration:)`](https://developer.apple.com/documentation/uikit/uicontextmenuinteractiondelegate/3295939-contextmenuinteraction). This delegate function returns a primary view controller overrides this function to enable menu commands based on the table view state or the state of the pasteboard.

## Adjust the Style Menu

The sample implements [`validate(_:)'](https://developer.apple.com/documentation/uikit/uiresponder/3229892-validate), where it can adjust the Style menu as the user selects between one or more of font styles: Plain, Bold, Italic, Underline.

``` swift
// The font style check states used in the Style menu.
var fontMenuStyleStates = Set<String>()

// Update the state of a given command from a menu; here adjust the Style menu.
// Note: Only command groups that are added will be called to validate.
override func validate(_ command: UICommand) {
    // Obtain the plist of the incoming command.
    if let fontStyleDict = command.propertyList as? [String: String] {
        // Check if the command comes from the Styles menu.
        if let fontStyle = fontStyleDict[MenuController.CommandPListKeys.StylesIdentifierKey] {
            // Update the "Style" menu command state (checked or unchecked).
            command.state = fontMenuStyleStates.contains(fontStyle) ? .on : .off
        }
    }
}
```

## Add a Preferences Menu
Mac apps typically display app-specific preferences using a preferences window. The sample adds a preferences window by adding a Settings bundle to the Xcode project's target. The window automatically becomes available to the user through the Preferences menu command in the Application menu. To learn more about preferences, see [`Displaying a Preferences Window`](https://developer.apple.com/documentation/uikit/mac_catalyst/displaying_a_preferences_window).
