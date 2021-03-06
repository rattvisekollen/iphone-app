//
//  ScanViewController.swift
//  Rattvisekollen
//
//  Created by Fredrik Bystam on 15/08/15.
//  Copyright © 2015 nickenil_byrreb. All rights reserved.
//

import UIKit

protocol ScanViewControllerDelegate: class {
    
    func scanViewController(scanViewController: ScanViewController, foundBarcode barcode: String)
    
}

class ScanViewController: UIViewController, BarcodeOutputDelegate, UIViewControllerTransitioningDelegate {
    
    // MARK: Properties
    internal weak var delegate: ScanViewControllerDelegate?
    
    @IBOutlet weak var cameraLayerView: UIView!
    @IBOutlet weak var maskViewPositionView: UIView!
    @IBOutlet weak var scanFlashLabel: UILabel!

    @IBOutlet internal weak var closeButton: UIButton!
    @IBOutlet internal weak var infoLabel: UILabel!
    
    internal var maskView: UIView!
    var barcodeScanner: BarcodeScanner!
    var foundBarcode: Bool = false
    
    // MARK: Methods
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.modalPresentationStyle = .Custom
        self.transitioningDelegate = self
    }
    
    class func startScanningFromViewController(presentingViewController: UIViewController, delegate: ScanViewControllerDelegate) {
        let storyboard = UIStoryboard(name: "Scanner", bundle: nil)
        let scanViewController = storyboard.instantiateInitialViewController() as! ScanViewController
        scanViewController.delegate = delegate
        presentingViewController.presentViewController(scanViewController, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.barcodeScanner = BarcodeScanner(previewView: self.cameraLayerView, delegate: self)
        self.setupMaskView()
        self.setupCloseButton()
        self.setupDebugScanTouching()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.barcodeScanner.startScanning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onApplicationWillEnterForeground", name:UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onApplicationDidEnterBackground", name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    // MARK: View setup
    
    func setupCloseButton() {
        self.closeButton.layer.cornerRadius = 4.0
        self.closeButton.layer.borderWidth = 0.5
        self.closeButton.layer.borderColor = Theme.lightColor().CGColor
        self.closeButton.setTitleColor(Theme.primaryColor(), forState: UIControlState.Normal)
        self.closeButton.backgroundColor = Theme.backgroundColor()
    }
    
    func setupMaskView() {
        self.maskView = UIView()
        self.maskView.layer.cornerRadius = 6.0
        self.maskView.backgroundColor = UIColor.whiteColor()
        
        self.cameraLayerView.maskView = maskView;
    }
    
    override func viewDidLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.maskView.frame = self.maskViewPositionView.frame
    }
    
    func setupDebugScanTouching() {
        #if DEBUG
            let longPress = UILongPressGestureRecognizer(target: self, action: "debugLongPress:")
            self.infoLabel.addGestureRecognizer(longPress)
            self.infoLabel.userInteractionEnabled = true
        #endif
    }
    
    func debugLongPress(sender: AnyObject) {
        self.showFlashAndCompleteScanningWithBarcode("7340005403622")
    }
    
    // MARK: Actions
    
    @IBAction func closeButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    func onApplicationWillEnterForeground() {
        self.barcodeScanner.startScanning()
    }
    
    func onApplicationDidEnterBackground() {
        self.barcodeScanner.stopScanning();
    }
    
    // MARK: BarcodeOutputDelegate
    
    func scannerDidOutputData(data: String) {
        if self.foundBarcode {
            return
        }
        self.foundBarcode = true
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.showFlashAndCompleteScanningWithBarcode(data)
        }
    }
    
    func showFlashAndCompleteScanningWithBarcode(barcode: String) {
        self.scanFlashLabel.text = barcode
        self.scanFlashLabel.alpha = 1.0

        UIView.animateWithDuration(0.8, animations: {
            self.scanFlashLabel.alpha = 0.0
        }, completion: { finished in
            self.scanFlashLabel.hidden = true
            self.dismissViewControllerAnimated(true) {
                self.delegate?.scanViewController(self, foundBarcode: barcode)
            }
        })
    }
    
    
    // MARK : UIViewControllerTransitioningDelegate
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animation = ScanViewModalAnimation()
        animation.isPresenting = true
        return animation
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animation = ScanViewModalAnimation()
        animation.isPresenting = false
        return animation
    }
}
