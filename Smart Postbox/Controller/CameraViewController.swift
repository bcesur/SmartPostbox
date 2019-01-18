//
//  CameraViewController.swift
//  Smart Postbox
//
//  Created by Berkay Cesur on 2.11.2018.
//  Copyright © 2018 Berkay Cesur. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Firebase
import MessageUI

class CameraViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {

    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var capturePhotoOutput: AVCapturePhotoOutput?
    var captureVideoOutput: AVCaptureVideoDataOutput?
    
    //Filter cam
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?
    var orientation: AVCaptureVideoOrientation = .portrait
    
    var isTakePhoto: Bool = false
    var luminosityArray: [Double] = []

    let context = CIContext()
    
    var user: User!
    let db = Database.database()
    
    @IBOutlet weak var imagePicked: UIImageView!
    
    @IBAction func takePhoto(_ sender: Any) {
        // Make sure capturePhotoOutput is valid
        guard let capturePhotoOutput = self.capturePhotoOutput else { return }
        
        // Get an instance of AVCapturePhotoSettings class
        let photoSettings = AVCapturePhotoSettings()
        
        // Set photo settings for our need
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .auto
        
        // Call capturePhoto method by passing our photo settings and a delegate implementing AVCapturePhotoCaptureDelegate
        capturePhotoOutput.capturePhoto(with: photoSettings, delegate: self)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        Auth.auth().addStateDidChangeListener { auth, user in
            guard let user = user else { return }
            self.user = User(authData: user)
        }
        
        setupDevice()
        setupInputOutput()
        
    }
    
    override func viewDidLayoutSubviews() {
        videoPreviewLayer?.frame = view.bounds
        if let previewLayer = videoPreviewLayer ,(previewLayer.connection?.isVideoOrientationSupported)! {
            previewLayer.connection?.videoOrientation = UIApplication.shared.statusBarOrientation.videoOrientation ?? .portrait
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) != .authorized
        {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:
                { (authorized) in
                    DispatchQueue.main.async
                        {
                            if authorized
                            {
                                self.setupInputOutput()
                            }
                    }
            })
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DispatchQueue.main.async {
            self.captureSession.stopRunning()
        }
        super.viewDidDisappear(animated)
    }
    
    func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.back)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
                try? backCamera!.lockForConfiguration()
                backCamera!.focusMode = .continuousAutoFocus
                backCamera!.unlockForConfiguration()
            }
            else if device.position == AVCaptureDevice.Position.front {
                frontCamera = device
            }
        }
        currentCamera = backCamera
    }
    
    func setupInputOutput() {
        do {
            setupCorrectFramerate(currentCamera: currentCamera!)
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.sessionPreset = .photo
            // Get an instance of ACCapturePhotoOutput class
            capturePhotoOutput = AVCapturePhotoOutput()
            capturePhotoOutput?.isHighResolutionCaptureEnabled = true
            
            if captureSession.canAddInput(captureDeviceInput) {
                captureSession.addInput(captureDeviceInput)
            }

            let videoOutput = AVCaptureVideoDataOutput()
            
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate", attributes: []))
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
                // Set the output on the capture session
                captureSession.addOutput(capturePhotoOutput!)
            }
            captureSession.startRunning()
        } catch {
            print(error)
        }
    }
    
    func setupCorrectFramerate(currentCamera: AVCaptureDevice) {
        for vFormat in currentCamera.formats {
            //see available types
            //print("\(vFormat) \n")
            
            var ranges = vFormat.videoSupportedFrameRateRanges as [AVFrameRateRange]
            let frameRates = ranges[0]
            
            do {
                //set to 240fps - available types are: 30, 60, 120 and 240 and custom
                // lower framerates cause major stuttering
                if frameRates.maxFrameRate == 240 {
                    try currentCamera.lockForConfiguration()
                    currentCamera.activeFormat = vFormat as AVCaptureDevice.Format
                    //for custom framerate set min max activeVideoFrameDuration to whatever you like, e.g. 1 and 180
                    currentCamera.activeVideoMinFrameDuration = frameRates.minFrameDuration
                    currentCamera.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
                }
            }
            catch {
                print("Could not set active format")
                print(error)
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        connection.videoOrientation = orientation
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)

        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(cvImageBuffer: pixelBuffer!)
        
        DispatchQueue.main.async {
            
            //Calculating the luminosity
            let rawMetadata = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
            let metadata = CFDictionaryCreateMutableCopy(nil, 0, rawMetadata) as NSMutableDictionary
            let exifData = metadata.value(forKey: "{Exif}") as? NSMutableDictionary
            
            let FNumber : Double = exifData?["FNumber"] as! Double
            let ExposureTime : Double = exifData?["ExposureTime"] as! Double
            let ISOSpeedRatingsArray = exifData!["ISOSpeedRatings"] as? NSArray
            let ISOSpeedRatings : Double = ISOSpeedRatingsArray![0] as! Double
            let CalibrationConstant : Double = 50
            
            let luminosity : Double = (CalibrationConstant * FNumber * FNumber ) / ( ExposureTime * ISOSpeedRatings )
            self.luminosityArray.append(luminosity)
            
            print(luminosity)
//            if luminosity > 16.0 && !self.isTakePhoto && self.luminosityArray.count > 10 {
//                // Waiting for 5 seconds in order to take photo with flash
//                sleep(5)
//                self.takePhoto(AnyClass.self)
//                self.isTakePhoto = true
//            }
            let cgImage = self.context.createCGImage(cameraImage, from: self.imagePicked.frame)
            self.imagePicked.image = UIImage(cgImage: cgImage!)
        }
    }
    
    func analyzePic(image: UIImage) {
        let vision = Vision.vision()
        let textRecognizer = vision.onDeviceTextRecognizer()
        let image = VisionImage(image: image)
        
        textRecognizer.process(image) { result, error in
            guard error == nil, let result = result else {
                print("CameraViewController - Text Recognizer failed to read text.")
                self.isTakePhoto = false
                return
            }
            //let resultText = result.text
            let mail: String = self.analyzeAndParseText(text: result.text.lowercased())
            self.sendToDB(text: mail)
            self.sendEmail(text: mail)
            for block in result.blocks {
                print(block.text)
            }
        }
    }
    
    func sendEmail(text: String) {
        let smtpSession = MCOSMTPSession()
        smtpSession.hostname = "smtp.gmail.com"
        smtpSession.username = "projevatoz@gmail.com"
        smtpSession.password = "@bYb2016@"
        smtpSession.port = 465
        smtpSession.authType = MCOAuthType.saslPlain
        smtpSession.connectionType = MCOConnectionType.TLS
        smtpSession.connectionLogger = {(connectionID, type, data) in
            if data != nil {
                if let string = NSString(data: data!, encoding: String.Encoding.utf8.rawValue){
                    NSLog("Connectionlogger: \(string)")
                }
            }
        }
        let builder = MCOMessageBuilder()
        builder.header.to = [MCOAddress(displayName: user.name, mailbox: user.email)]
        builder.header.from = MCOAddress(displayName: "Smart Postbox", mailbox: "projevatoz@gmail.com")
        builder.header.subject = "You have a new post!"
        builder.htmlBody="<p>"+text+"</p>"
        
        let rfc822Data = builder.data()
        let sendOperation = smtpSession.sendOperation(with: rfc822Data)
        sendOperation?.start { (error) -> Void in
            if (error != nil) {
                NSLog("CameraViewController - Error sending email: \(error)")
                
                
            } else {
                NSLog("CameraViewController - Successfully sent email!")
            }
        }
    }
    
    func analyzeAndParseText(text: String) -> String {
        if (text.contains("aok")) {
            return "You have a new mail from AOK"
        }
        else if(text.contains("commerzbank")) {
            return "You have a new mail from CommerzBank"
        }
        else if(text.contains("deutschebank")) {
            return "You have a new mail from DeutscheBank"
        }
        else if(text.contains("ard") || text.contains("zdf")) {
            return "You have a new mail from ARD ZDF"
        }
        else if(text.contains("kreisverwaltungsreferat")) {
            return "You have a new mail from Kreisverwaltungsreferat"
        }
        else{
            return "You have some shit in your postbox"
        }
    }
    
    func sendToDB(text: String) {
        let mailItem = Mail(receiver: user.uid, text: text, checked: false)
        let ref = db.reference(withPath: "users")
        let userRef = ref.child(user.uid)
        let mailItemRef = userRef.child("mails")
        let details = mailItemRef.childByAutoId()
        details.setValue(mailItem.toAnyObject())
        isTakePhoto = false
    }
    
}


extension CameraViewController : AVCapturePhotoCaptureDelegate {
    func photoOutput(_ captureOutput: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
                     previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                     resolvedSettings: AVCaptureResolvedPhotoSettings,
                     bracketSettings: AVCaptureBracketedStillImageSettings?,
                     error: Error?) {
        // Make sure we get some photo sample buffer
        guard error == nil,
            let photoSampleBuffer = photoSampleBuffer else {
                print("Error capturing photo: \(String(describing: error))")
                return
        }
        
        // Convert photo same buffer to a jpeg image data by using AVCapturePhotoOutput
        guard let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer) else {
            return
        }
        
        // Initialise an UIImage with our image data
        let capturedImage = UIImage.init(data: imageData , scale: 1.0)
        if let image = capturedImage {
            // Save our captured image to photos album
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
        analyzePic(image: capturedImage!)
        //upload(image: capturedImage!)
        
        
    }
    
    
}

extension UIInterfaceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
        case .portrait: return .portrait
        default: return nil
        }
    }
}
