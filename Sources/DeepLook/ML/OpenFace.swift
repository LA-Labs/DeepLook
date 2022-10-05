import CoreML


/// Model Prediction Input Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public class OpenFaceInput : MLFeatureProvider {

    /// data as color (kCVPixelFormatType_32BGRA) image buffer, 96 pixels wide by 96 pixels high
    public var data: CVPixelBuffer

    public var featureNames: Set<String> {
        get {
            return ["data"]
        }
    }

    public func featureValue(for featureName: String) -> MLFeatureValue? {
        if (featureName == "data") {
            return MLFeatureValue(pixelBuffer: data)
        }
        return nil
    }

    public init(data: CVPixelBuffer) {
        self.data = data
    }
}

/// Model Prediction Output Type
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public class OpenFaceOutput : MLFeatureProvider {

    /// Source provided by CoreML

    private let provider : MLFeatureProvider


    /// output as 128 element vector of doubles
    public lazy var output: MLMultiArray = {
        [unowned self] in return self.provider.featureValue(for: "output")!.multiArrayValue
        }()!

    public var featureNames: Set<String> {
        return self.provider.featureNames
    }

    public func featureValue(for featureName: String) -> MLFeatureValue? {
        return self.provider.featureValue(for: featureName)
    }

    public init(output: MLMultiArray) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["output" : MLFeatureValue(multiArray: output)])
    }

    public init(features: MLFeatureProvider) {
        self.provider = features
    }
}


/// Class for model loading and prediction
@available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
public class OpenFace {
    public var model: MLModel

    /// URL of model assuming it was installed in the same bundle as this class
    public class var urlOfModelInThisBundle : URL {
        return Bundle.main.url(forResource: "OpenFace", withExtension:"mlmodelc")!
    }

    /**
     Construct a model with explicit path to mlmodelc file
     - parameters:
     - url: the file url of the model
     - throws: an NSError object that describes the problem
     */
    public init(contentsOf url: URL) throws {
        self.model = try MLModel(contentsOf: url)
    }

    /// Construct a model that automatically loads the model from the app's bundle
    public convenience init() {
        try! self.init(contentsOf: type(of:self).urlOfModelInThisBundle)
    }

    /**
     Construct a model with configuration
     - parameters:
     - configuration: the desired model configuration
     - throws: an NSError object that describes the problem
     */
    @available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, *)
    public convenience init(configuration: MLModelConfiguration) throws {
        try self.init(contentsOf: type(of:self).urlOfModelInThisBundle, configuration: configuration)
    }

    /**
     Construct a model with explicit path to mlmodelc file and configuration
     - parameters:
     - url: the file url of the model
     - configuration: the desired model configuration
     - throws: an NSError object that describes the problem
     */
    @available(macOS 10.14, iOS 12.0, tvOS 12.0, watchOS 5.0, *)
    public init(contentsOf url: URL, configuration: MLModelConfiguration) throws {
        self.model = try MLModel(contentsOf: url, configuration: configuration)
    }

    /**
     Make a prediction using the structured interface
     - parameters:
     - input: the input to the prediction as OpenFaceInput
     - throws: an NSError object that describes the problem
     - returns: the result of the prediction as OpenFaceOutput
     */
    public func prediction(input: OpenFaceInput) throws -> OpenFaceOutput {
        return try self.prediction(input: input, options: MLPredictionOptions())
    }

    /**
     Make a prediction using the structured interface
     - parameters:
     - input: the input to the prediction as OpenFaceInput
     - options: prediction options
     - throws: an NSError object that describes the problem
     - returns: the result of the prediction as OpenFaceOutput
     */
    public func prediction(input: OpenFaceInput, options: MLPredictionOptions) throws -> OpenFaceOutput {
        let outFeatures = try model.prediction(from: input, options:options)
        return OpenFaceOutput(features: outFeatures)
    }

    /**
     Make a prediction using the convenience interface
     - parameters:
     - data as color (kCVPixelFormatType_32BGRA) image buffer, 96 pixels wide by 96 pixels high
     - throws: an NSError object that describes the problem
     - returns: the result of the prediction as OpenFaceOutput
     */
    public func prediction(data: CVPixelBuffer) throws -> OpenFaceOutput {
        let input_ = OpenFaceInput(data: data)
        return try self.prediction(input: input_)
    }

}
