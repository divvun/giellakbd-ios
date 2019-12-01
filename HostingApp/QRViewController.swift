import UIKit
import AVFoundation
import BrotliKit

class QRView: UIView, Nibbable {
    @IBOutlet weak var cancelButton: UIButton!
}

class QRViewController: ViewController<QRView>, HideNavBar, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    var output: [String: Any]? = nil
    
    var task: URLSessionDataTask?
    
    @objc func onClickCancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView.cancelButton.addTarget(self, action: #selector(onClickCancel), for: .touchUpInside)
        
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)!
        
        defer {
            self.contentView.bringSubviewToFront(self.contentView.cancelButton)
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            let captureSession = AVCaptureSession()
            captureSession.addInput(input)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = UIScreen.main.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            captureSession.startRunning()
        } catch {
            print(error)
            return
        }
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var isProcessing = false
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if isProcessing {
            return
        }
        
        isProcessing = true
        
        guard let metadataObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject else {
            isProcessing = false
            return
        }
        
        if metadataObj.type != AVMetadataObject.ObjectType.qr {
            isProcessing = false
            return
        }
        
        guard let x = metadataObj.value(forKeyPath: "_internal.basicDescriptor") as? [String: Any],
            let garbageData = x["BarcodeRawData"] as? Data else
        {
            isProcessing = false
            return
        }
        
        let count = garbageData.count - 5
        var bytes = [UInt8](garbageData)
        bytes.append(0)
        var b = Binary(bytes: bytes)
        let compressedData: Data
        do {
            _ = try b.readBytes(2)
            _ = try b.readNibble()
            let bytes = try b.readBytes(count)
            var newBytes = [UInt8]()
            
            for cur in 0..<bytes.endIndex-1 {
                let next = bytes.index(after: cur)
                let fat = UnsafePointer([bytes[next], bytes[cur]]).withMemoryRebound(to: UInt16.self, capacity: 1) {
                    $0.pointee
                }
                
                let denibbled = fat << 4
                
                newBytes.append(denibbled.bytes[0])
            }
            
            compressedData = Data(newBytes)
        } catch {
            print("Invalid bytes")
            isProcessing = false
            return
        }
        
        guard let data = BrotliCompressor.decompressedData(with: compressedData) else {
            print(compressedData as NSData)
            print("Failed to decompress")
            isProcessing = false
            return
        }
        
        guard let rawDefinition = try? JSONDecoder().decode(RawKeyboardDefinition.self, from: data) else {
            isProcessing = false
            return
        }
        
        
        
        guard let definition = try? KeyboardDefinition(fromRaw: rawDefinition, traits: self.traitCollection) else {
            isProcessing = false
            return
        }
        
        captureSession?.stopRunning()
        KeyboardSettings.currentKeyboard = definition
        
        print(definition.name)
        print(KeyboardSettings.currentKeyboard.name)
        
        let alert = UIAlertController(
            title: "Done!",
            message: "The keyboard \"\(KeyboardSettings.currentKeyboard.name)\" is now installed.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Great!", style: .default, handler: { _ in
            self.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
}
