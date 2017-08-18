
//  Copyright (c) 2014-2016 SafeDrive. All rights reserved.
//

import Cocoa

class ReadyViewController: NSViewController {
    fileprivate weak var delegate: WelcomeStateDelegate?

    fileprivate weak var viewDelegate: WelcomeViewDelegate?
    
    override func viewDidLoad() {
        if #available(OSX 10.10, *) {
            super.viewDidLoad()
        } else {
            // Fallback on earlier versions
        }
        // Do view setup here.
    }
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(delegate: WelcomeStateDelegate, viewDelegate: WelcomeViewDelegate) {

        self.init(nibName: NSNib.Name(rawValue: "ReadyView"), bundle: nil)

        
        self.delegate = delegate
        
        self.viewDelegate = viewDelegate
    }

    
    @IBAction func ok(_ sender: AnyObject?) {
        self.delegate?.didFinish()
    }
}
