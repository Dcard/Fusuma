//
//  FusumaViewController.swift
//  Fusuma
//
//  Created by Yuta Akizuki on 2015/11/14.
//  Copyright © 2015年 ytakzk. All rights reserved.
//

import UIKit

public protocol FusumaDelegate: class {
    
    func fusumaImageSelected(image: UIImage)
    func fusumaDismissedWithImage(image: UIImage)
    func fusumaCameraRollUnauthorized()
    func FusumaViewControllerDidLoad(controller: FusumaViewController)
}

public var fusumDefaultColor     = UIColor.hex("#ffffff", alpha: 1.0)
public var fusumaTintColor       = UIColor.hex("#009688", alpha: 1.0)
public var fusumaBackgroundColor = UIColor.hex("#212121", alpha: 1.0)

public final class FusumaViewController: UIViewController, FSCameraViewDelegate, FSAlbumViewDelegate {
    
    enum Mode {
        case Camera
        case Library
    }
    
    var mode: Mode?
    var willFilter = true

    @IBOutlet public weak var photoLibraryViewerContainer: UIView!
    @IBOutlet public weak var cameraShotContainer: UIView!

    @IBOutlet public weak var titleLabel: UILabel!
    @IBOutlet public weak var menuView: UIView!
    @IBOutlet public weak var closeButton: UIButton!
    @IBOutlet public weak var libraryButton: UIButton!
    @IBOutlet public weak var cameraButton: UIButton!
    @IBOutlet public weak var doneButton: UIButton!
    
    public var albumView  = FSAlbumView.instance()
    public var cameraView = FSCameraView.instance()
    public var cameraRollTitle = "CAMERA ROLL" {
        didSet {
            if self.mode == Mode.Library {
                self.titleLabel.text = self.cameraRollTitle
            }
        }
    }
    public var photoTitle = "PHOTO" {
        didSet {
            if self.mode == Mode.Camera {
                self.titleLabel.text = self.photoTitle
            }
        }
    }
    
    public var didLoadCallBack: ((viewController: FusumaViewController)->())?
    
    public weak var delegate: FusumaDelegate? = nil
    
    override public func loadView() {
        
        if let view = UINib(nibName: "FusumaViewController", bundle: NSBundle(forClass: self.classForCoder)).instantiateWithOwner(self, options: nil).first as? UIView {
            
            self.view = view
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
    
        self.view.backgroundColor = fusumaBackgroundColor
        
        cameraView.delegate = self
        albumView.delegate  = self

        menuView.backgroundColor = fusumaBackgroundColor
        menuView.addBottomBorder(UIColor.blackColor(), width: 1.0)
        
        let bundle = NSBundle(forClass: self.classForCoder)
        
        let albumImage = UIImage(named: "ic_insert_photo", inBundle: bundle, compatibleWithTraitCollection: nil)
        let cameraImage = UIImage(named: "ic_photo_camera", inBundle: bundle, compatibleWithTraitCollection: nil)
        let checkImage = UIImage(named: "ic_check", inBundle: bundle, compatibleWithTraitCollection: nil)

        
        libraryButton.setImage(albumImage, forState: .Normal)
        libraryButton.setImage(albumImage, forState: .Highlighted)
        libraryButton.setImage(albumImage, forState: .Selected)

        cameraButton.setImage(cameraImage, forState: .Normal)
        cameraButton.setImage(cameraImage, forState: .Highlighted)
        cameraButton.setImage(cameraImage, forState: .Selected)
        
        closeButton.tintColor = UIColor.whiteColor()
        
        libraryButton.tintColor = fusumaTintColor
        cameraButton.tintColor  = fusumaTintColor
        
        cameraButton.adjustsImageWhenHighlighted  = false
        libraryButton.adjustsImageWhenHighlighted = false
        cameraButton.clipsToBounds  = true
        libraryButton.clipsToBounds = true

        changeMode(Mode.Library)
        
        photoLibraryViewerContainer.addSubview(albumView)
        cameraShotContainer.addSubview(cameraView)
        
        doneButton.setImage(checkImage, forState: .Normal)
        doneButton.tintColor = UIColor.whiteColor()
        
        self.delegate?.FusumaViewControllerDidLoad(self)
        self.didLoadCallBack?(viewController: self)
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }

    override public func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        albumView.frame  = CGRect(origin: CGPointZero, size: photoLibraryViewerContainer.frame.size)
        albumView.layoutIfNeeded()
        cameraView.frame = CGRect(origin: CGPointZero, size: cameraShotContainer.frame.size)
        cameraView.layoutIfNeeded()
        
        albumView.initialize()
        cameraView.initialize()
    }

    override public func prefersStatusBarHidden() -> Bool {
        
        return true
    }
    
    @IBAction func closeButtonPressed(sender: UIButton) {

        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func libraryButtonPressed(sender: UIButton) {
        
        changeMode(Mode.Library)
    }
    
    @IBAction func photoButtonPressed(sender: UIButton) {
    
        changeMode(Mode.Camera)
    }
    
    @IBAction func doneButtonPressed(sender: UIButton) {
        
        let view = albumView.imageCropView
        
        UIGraphicsBeginImageContextWithOptions(view.frame.size, true, 0)
        let context = UIGraphicsGetCurrentContext()
        CGContextTranslateCTM(context, -albumView.imageCropView.contentOffset.x, -albumView.imageCropView.contentOffset.y)
        view.layer.renderInContext(context!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        delegate?.fusumaImageSelected(image)
        
        self.dismissViewControllerAnimated(true, completion: {
            
            self.delegate?.fusumaDismissedWithImage(image)
        })
    }
    
    func changeMode(mode: Mode) {

        if self.mode == mode {
            
            return
        }
        
        self.mode = mode
        
        dishighlightButtons()
        
        if mode == Mode.Library {
            
            titleLabel.text = self.cameraRollTitle
            doneButton.hidden = false
            
            highlightButton(libraryButton)
            self.view.insertSubview(photoLibraryViewerContainer, aboveSubview: cameraShotContainer)
            
        } else {

            titleLabel.text = self.photoTitle
            doneButton.hidden = true
            
            highlightButton(cameraButton)
            self.view.insertSubview(cameraShotContainer, aboveSubview: photoLibraryViewerContainer)
        }
    }
    
    
    func dishighlightButtons() {
        
        self.cameraButton.tintColor = fusumDefaultColor.colorWithAlphaComponent(0.75)
        self.libraryButton.tintColor = fusumDefaultColor.colorWithAlphaComponent(0.75)
    }
    
    func highlightButton(button: UIButton) {
        
        button.tintColor = fusumaTintColor
    }
    
    // MARK: FSCameraViewDelegate
    func cameraShotFinished(image: UIImage) {
        
        delegate?.fusumaImageSelected(image)
        self.dismissViewControllerAnimated(true, completion: {
        
            self.delegate?.fusumaDismissedWithImage(image)
        })
    }
    
    // MARK: FSAlbumViewDelegate
    public func albumViewCameraRollUnauthorized() {
        
        delegate?.fusumaCameraRollUnauthorized()
    }
}