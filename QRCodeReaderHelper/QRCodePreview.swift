//
//  QRCodePreview.swift
//  QRCodeReaderHelper
//
//  Created by Adrien Surugue on 18/08/2023.
//

import Foundation
import AVFoundation
import SwiftUI

struct BarCodePreview: UIViewRepresentable{
    
    @Binding var showAlert: Bool
    var isRunning = false
    var stringCode: (String) -> Void
    
    @Binding var captureSession: AVCaptureSession
    
    var photoOutput = AVCapturePhotoOutput()
    
    init(stringCode: @escaping (String) -> Void, showAlert: Binding<Bool>, captureSession:Binding<AVCaptureSession>){
        self.stringCode = stringCode
        self._showAlert = showAlert
        self._captureSession = captureSession
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> some UIView {
        
        let configuration = openSession(session: captureSession)
        metaOutput(session: captureSession, context: context)
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        view.backgroundColor = UIColor.black
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        previewLayer.connection?.videoOrientation = .portrait
        
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        if configuration {
            DispatchQueue.global(qos: .background).async {
                captureSession.startRunning()
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
    //add Privacy - Camera Usage Description at info.plist
    func checkPermission(){
        
        switch AVCaptureDevice.authorizationStatus(for: .video){
        case .authorized:
            let _ = openSession(session: captureSession)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { status in
                if status{
                    let _ = openSession(session: captureSession)
                }
            })
        case .restricted:
            return
        case .denied:
            return
        @unknown default:
            return
        }
    }
    
    func openSession(session: AVCaptureSession)-> Bool {
        
        guard let videoCaptureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera,
                                                               for: AVMediaType.video, position: .back) else{
            
            DispatchQueue.main.async {
                showAlert = true
            }
            return false}
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
        } catch {return false}
        
        if  session.canAddInput(videoInput) && session.canAddOutput(photoOutput){
            session.addInput(videoInput)
            session.addOutput(photoOutput)
            return true
        } else {return false}
    }
    
    // MARK: - Connect detection barcode, QRcode ...
    func metaOutput(session: AVCaptureSession, context: Context){
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddOutput(metadataOutput){
            session.addOutput(metadataOutput)
            
            /*
             let x = 0.3 as CGFloat
             let y = 0.3 as CGFloat
             let width = 0.5 as CGFloat
             let height = 0.5 as CGFloat
             metadataOutput.rectOfInterest = CGRect(x: x, y: y, width: width, height: height)*/
            
            metadataOutput.setMetadataObjectsDelegate(context.coordinator.self, queue: DispatchQueue.main)
            if metadataOutput.availableMetadataObjectTypes != []{
                metadataOutput.metadataObjectTypes = [.qr, .interleaved2of5, .dataMatrix, .code128, .code39, .code93, .ean13, .microQR]
            }
            
        } else {return}
    }
    
    
    
    //MARK: - Coordinator
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate, AVCapturePhotoCaptureDelegate{
        
        var parent: BarCodePreview
        
        init(parent: BarCodePreview){
            self.parent = parent
        }
        
        //Decoding code
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {return}
                
                guard let stringValue = readableObject.stringValue
                else{return}
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                self.parent.stringCode(stringValue)
                
                self.parent.captureSession.stopRunning()
            }
        }
        
        
    }
}
