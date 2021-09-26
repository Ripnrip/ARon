import UIKit
import AVFoundation
import Vision

final class CameraViewController: UIViewController {
  private let cameraCaptureSession = AVCaptureSession()
  private var cameraPreview: CameraPreview { view as! CameraPreview }

  private let videoDataOutputQueue = DispatchQueue(
    label: "CameraFeedOutput", qos: .userInteractive
  )
    
  private let fitnessClassifier = MyActionClassifier()
  
  private let handPoseRequest: VNDetectHumanHandPoseRequest = {
    let request = VNDetectHumanHandPoseRequest()
    request.maximumHandCount = 2
    return request
  }()
  
  private let bodyPoseRequest = VNDetectHumanBodyPoseRequest()
  private let posesWindow: [VNRecognizedPointsObservation?] = []
    
  private var actionDetectionRequest: VNCoreMLRequest!
  private let actionDetectionMinConfidence: VNConfidence = 0.6
  
  var pointsProcessor: ((_ points: [CGPoint], _ poses: [HandPose]) -> Void)?
  var bodyPointsProcessor: ((_ points: [CGPoint], _ pose: BodyPose) -> Void)?
  
  override func loadView() {
    view = CameraPreview()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    setupAVSession()
    setupPreview()
    cameraCaptureSession.startRunning()
    //setupModel()
    
  }
   func setupModel() {
        do {
            // Create Vision request based on CoreML model
            let model = try VNCoreMLModel(for: MyActionClassifier(configuration: MLModelConfiguration()).model)
            actionDetectionRequest = VNCoreMLRequest(model: model)

        } catch {
            print("Error in setting up the model \(error)")
        }
    }

  override func viewWillDisappear(_ animated: Bool) {
    cameraCaptureSession.stopRunning()
    super.viewWillDisappear(animated)
  }
  
  func setupPreview() {
    cameraPreview.previewLayer.session = cameraCaptureSession
    cameraPreview.previewLayer.videoGravity = .resizeAspectFill
  }
  
  func setupAVSession() {
    // Start session configuration
    cameraCaptureSession.beginConfiguration()
    
    // Setup video data input
    guard
      let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
      let deviceInput = try? AVCaptureDeviceInput(device: videoDevice),
      cameraCaptureSession.canAddInput(deviceInput)
    else { return }
    
    cameraCaptureSession.sessionPreset = AVCaptureSession.Preset.high
    cameraCaptureSession.addInput(deviceInput)
    
    // Setup video data output
    let dataOutput = AVCaptureVideoDataOutput()
    guard cameraCaptureSession.canAddOutput(dataOutput)
    else { return }
    
    cameraCaptureSession.addOutput(dataOutput)
    dataOutput.alwaysDiscardsLateVideoFrames = true
    dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
    
    // Commit session configuration
    cameraCaptureSession.commitConfiguration()
  }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    var recognizedPoints: [VNRecognizedPoint] = []
    var poses: [HandPose] = []
    
    var recognizedBodyPoints: [VNRecognizedPoint] = []
    var bodyPose = BodyPose.unsure

    func convertPoint(_ point: VNRecognizedPoint) -> CGPoint {
      let cgPoint = CGPoint(x: 1 - point.y, y: 1 - point.x)
      return cameraPreview.previewLayer.layerPointConverted(fromCaptureDevicePoint: cgPoint)
    }

    defer {
      DispatchQueue.main.sync {
        let convertedPoints = recognizedPoints.map(convertPoint(_:))
        pointsProcessor?(convertedPoints, poses)
        
        let convertedBodyPoints = recognizedBodyPoints.map(convertPoint(_:))
        bodyPointsProcessor?(convertedBodyPoints, bodyPose)
      }
    }
    
    let handler = VNImageRequestHandler(
      cmSampleBuffer: sampleBuffer,
      orientation: .right,
      options: [:]
    )
    
    do {
      try handler.perform([handPoseRequest, bodyPoseRequest])
      
      if let bodyPoseResults = bodyPoseRequest.results?.first {
        let armJoints: [VNHumanBodyPoseObservation.JointName] = [.leftWrist, .leftElbow, .leftShoulder, .rightShoulder, .rightElbow, .rightWrist]
        let fullBodyMinusFace: [VNHumanBodyPoseObservation.JointsGroupName] = [.leftArm,.rightArm,.leftLeg,.rightLeg,.torso]
        
        let armLandmarks = try bodyPoseResults.recognizedPoints(.all)
          .filter { armJoints.contains($0.key) }
          .filter { $0.value.confidence > 0.3 }
        
        let bodyLandmarks = try bodyPoseResults.recognizedPoints(.all)
          .filter { $0.value.confidence > 0.25 }
        
        bodyPose = BodyPose.evaluateBodyPose(from: armLandmarks)
        bodyPose = BodyPose.evaluateBodyPose(from: bodyLandmarks)
        //let totalParts = armLandmarks.values + bodyLandmarks.values
        recognizedBodyPoints = Array(bodyLandmarks.values)
      }

      guard
        let results = handPoseRequest.results?.prefix(2),
        !results.isEmpty
      else { return }
      
      try results.forEach { observation in
        let handLandmarks = try observation.recognizedPoints(.all)
          .filter { point in
            point.value.confidence > 0.6
          }
        
        let tipPoints: [VNHumanHandPoseObservation.JointName] = [.thumbTip, .indexTip, .middleTip, .ringTip, .littleTip]
        let recognizedTips = tipPoints
          .compactMap { handLandmarks[$0] }
        
        recognizedPoints += recognizedTips
        
        poses.append(HandPose.evaluateHandPose(from: handLandmarks))
      }
    } catch {
      cameraCaptureSession.stopRunning()
      print(error.localizedDescription)
    }
  }
    
}
