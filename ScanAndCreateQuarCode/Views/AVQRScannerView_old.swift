import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins   // чтобы сразу рисовать QR-картинку

struct AVQRScannerView: UIViewControllerRepresentable {

    /// Вернёт строку из QR-кода + готовую картинку (ч/б).
    let onDetect: (_ payload: String, _ image: UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> ScannerVC {
        let vc = ScannerVC()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: ScannerVC, context: Context) { }

    // MARK: – Coordinator
    final class Coordinator: NSObject, QRDelegate {
        let parent: AVQRScannerView
        init(parent: AVQRScannerView) { self.parent = parent }

        func didDetect(qr: String) {
            let img = Self.makeQR(from: qr)
            parent.onDetect(qr, img)
            parent.dismiss()
        }

        /// Быстро генерируем QR-картинку 256×256
        private static func makeQR(from text: String) -> UIImage {
            let data = Data(text.utf8)
            let filter = CIFilter.qrCodeGenerator()
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let ciImage = filter.outputImage!.transformed(by: transform)
            let cgImage = CIContext().createCGImage(ciImage, from: ciImage.extent)!
            return UIImage(cgImage: cgImage)
        }
    }
}

// MARK: – UIKit Camera implementation

protocol QRDelegate: AnyObject { func didDetect(qr: String) }

final class ScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    weak var delegate: QRDelegate?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let device = AVCaptureDevice.default(for: .video),
              let input  = try? AVCaptureDeviceInput(device: device)
        else { return }

        let output = AVCaptureMetadataOutput()

        session.beginConfiguration()
        if session.canAddInput(input)   { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
        session.commitConfiguration()

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        session.startRunning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }

    // Delegate: получили QR-код
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput objects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let obj = objects.first as? AVMetadataMachineReadableCodeObject,
              obj.type == .qr,
              let str = obj.stringValue
        else { return }

        session.stopRunning()                 // прекращаем сканирование
        delegate?.didDetect(qr: str)
    }
}
