/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Detail view controller portion of UISplitViewController.
*/

import UIKit

// Custom view subclass for contextual menus.
class ResponsiveView: UIView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

// MARK: -

protocol DetailItemDelegate: NSObjectProtocol {
    func performCutAction()
    func performCopyAction()
    func performPasteAction()
    func performDeleteAction()
    func didUpdateItem(_ item: TableItem)
}

class DetailViewController: UIViewController {
        
    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var detailDescriptionView: UIView!
    
    weak var detailItemDelegate: DetailItemDelegate?
    
    var detailItem: TableItem? {
        didSet {
            // Update the view.
            configureView()
        }
    }
    
    // Observer for the text field in the rename alert.
    var textDidChangeObserver: NSObjectProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        configureView()
           
        // Add a contextual menu so the user can either tap and hold (iPad OS), or control-click (macOS) on the content area.
        // for the Copy, Rename and Share operations.
        let interaction = UIContextMenuInteraction(delegate: self)
        self.view.addInteraction(interaction)
        
        // Listen for preference changes for the view's background color.
        backgroundColorObserver = UserDefaults.standard.observe(\.nameColorKey,
                                                                options: [.initial, .new],
                                                                changeHandler: { (defaults, change) in
            self.updateView()
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        #if targetEnvironment(macCatalyst)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        #endif
    }
    
    func configureView() {
        // Update the user interface for the detail item.

        detailDescriptionView.isHidden = detailItem == nil
        detailDescriptionLabel.isHidden = detailItem == nil
        
        if detailItem != nil {
            detailDescriptionLabel?.text = detailItem?.description
        } else {
            detailDescriptionLabel?.text = ""
        }
    }

// MARK: - Preferred Background Color
    
    static let nameColorKey = "nameColorKey" // Key for obtains the preference view color.

    // KVO for preference changes.
    var backgroundColorObserver: NSKeyValueObservation?
    
    func updateView() {
        let viewColor = UserDefaults.standard.integer(forKey: DetailViewController.nameColorKey)
        let colorValue = AppDelegate.BackgroundColors(rawValue: viewColor)
        
        switch colorValue {
        case .blue:
            detailDescriptionView.backgroundColor = UIColor.systemBlue
        case .teal:
            detailDescriptionView.backgroundColor = UIColor.systemTeal
        case .indigo:
            detailDescriptionView.backgroundColor = UIColor.systemIndigo
        default:
            Swift.debugPrint("invalid color")
        }
    }
    
}

// MARK: - User Defaults

// Extend UserDefaults for quick access to nameColorKey.
extension UserDefaults {
    
    @objc dynamic var nameColorKey: Int {
        return integer(forKey: DetailViewController.nameColorKey)
    }
    
}

// MARK: - UIContextMenuInteractionDelegate

extension DetailViewController: UIContextMenuInteractionDelegate {
    
    func renameDetailedItem() {
        let message = NSLocalizedString("RenameMessage", comment: "")
        let cancelButtonTitle = NSLocalizedString("CancelTitle", comment: "")
        let destructiveButtonTitle = NSLocalizedString("RenameTitle", comment: "")
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { _ in }
        let destructiveAction = UIAlertAction(title: destructiveButtonTitle, style: .destructive) { _ in
            let textField = alertController.textFields![0] as UITextField
            self.detailItem = .text(textField.text!)
            
            // Tell our delegate (PrimaryViewController) the item has been renamed.
            if let detailItem = self.detailItem {
                self.detailItemDelegate?.didUpdateItem(detailItem)
            }
        }
        
        // Add the text field for renaming the detailed item.
        alertController.addTextField { textField in
            /** Listen for changes to the text field's text so that the destructive action btton
                is enabled property based on whether the user has entered a value.
            */
            textField.text = self.detailDescriptionLabel.text
            
            // Listen for text changes.
            self.textDidChangeObserver = NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: textField,
                queue: OperationQueue.main) { (notification) in
                    if let textField = notification.object as? UITextField {
                        if let textContent = textField.text {
                            destructiveAction.isEnabled = !textContent.isEmpty
                        }
                    }
            }
        }
          
        // Add the rename and cancel button actions.
        alertController.addAction(destructiveAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
    
    func shareDetailedItem() {
        if let content = self.detailItem?.description {
            // Present UIActivityViewController anchored from the detail view label.
            let activityItems = ["Shared piece of text", content] as [Any]
            let activityViewController =
                UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.detailDescriptionLabel
            activityViewController.popoverPresentationController?.sourceRect = self.detailDescriptionLabel.bounds
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    func contextMenuActions() -> [UIMenuElement] {
        // Actions for the contextual menu.
        let cutAction = UIAction(title: NSLocalizedString("CutTitle", comment: ""),
                                   image: UIImage(systemName: "doc.on.doc"),
                                   identifier: UIAction.Identifier(rawValue: "com.example.apple-samplecode.menus.cut")) { action in
            // Perform the "Cut" action, by copying the detail label string.
            self.detailItemDelegate!.performCutAction()
        }
        
        let copyAction = UIAction(title: NSLocalizedString("CopyTitle", comment: ""),
                                   image: UIImage(systemName: "doc.on.doc"),
                                   identifier: UIAction.Identifier(rawValue: "com.example.apple-samplecode.menus.copy")) { action in
            // Perform the "Copy" action, by copying the detail label string.
            self.detailItemDelegate!.performCopyAction()
        }
         
        let pasteAction = UIAction(title: NSLocalizedString("PasteTitle", comment: ""),
                                   image: UIImage(systemName: "doc.on.doc"),
                                   identifier: UIAction.Identifier(rawValue: "com.example.apple-samplecode.menus.paste")) { action in
            // Perform the "Paste" action, by pasting string contents of the pasteboard.
            self.detailItemDelegate!.performPasteAction()
        }
        
        let deleteAction = UIAction(title: NSLocalizedString("DeleteTitle", comment: ""),
                                   image: UIImage(systemName: "doc.on.doc"),
                                   identifier: UIAction.Identifier(rawValue: "com.example.apple-samplecode.menus.delete")) { action in
            // Perform the "Delete" action, by deleting the selected item.
            self.detailItemDelegate!.performDeleteAction()
        }
        
        let renameAction = UIAction(title: NSLocalizedString("RenameTitle", comment: ""),
                                     image: UIImage(systemName: "square.and.pencil"),
                                     identifier: UIAction.Identifier(rawValue: "com.example.apple-samplecode.menus.rename")) { action in
            // Perform the "Rename" action, with a UIAlertController.
            self.renameDetailedItem()
        }
         
        let shareAction = UIAction(title: NSLocalizedString("ShareTitle", comment: ""),
                                    image: UIImage(systemName: "square.and.arrow.up"),
                                    identifier: UIAction.Identifier(rawValue: "com.example.apple-samplecode.menus.share")) { action in
            // Perform the "Share" action, with a UIActivityViewController.
            self.shareDetailedItem()
        }
         
        // The Rename and Share commands will be separated from edit actions..
        let renameGroup = UIMenu(title: "", options: .displayInline, children: [renameAction])
        let shareGroup = UIMenu(title: "", options: .displayInline, children: [shareAction])
        
        return [cutAction, copyAction, pasteAction, deleteAction, renameGroup, shareGroup]
    }
    
    // Open a contextual menu from this view.
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        /** Allow for contextual menu for the rest of the detail view.
            Mac Catalyst: User control-clicked or right-mouse clicked on the detail view controller's content.
            iOS: User tapped and held the detail view controller's content.
        */
        let configuration =
            UIContextMenuConfiguration(identifier: NSString(""), previewProvider: nil) { (elements) -> UIMenu? in
                guard self.detailItem != nil else { return nil }
                let menu = UIMenu(title: "Detail View",
                                  image: nil,
                                  identifier: UIMenu.Identifier("com.example.apple-samplecode.menus.detailContextMenu"),
                                  options: [],
                                  children: self.contextMenuActions())
                return menu
            }
        return configuration
    }

    // Make a custom highlight preview for this detail view controller, using the detailDescriptionLabel as the preview.
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = UIColor.clear
        let visibleRect = detailDescriptionLabel.bounds.insetBy(dx: -10, dy: -10)
        let visiblePath = UIBezierPath(roundedRect: visibleRect, cornerRadius: 10.0)
        parameters.visiblePath = visiblePath
        return UITargetedPreview(view: detailDescriptionLabel, parameters: parameters)
    }
    
}
