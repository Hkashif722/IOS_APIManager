//
//  UploadDelegate.swift
//  NetworkService
//
//  Created by Kashif Hussain on 17/02/26.
//

import Foundation
// MARK: - Upload Delegate for Progress Tracking

internal class UploadDelegate<T: Decodable>: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {
    
    let continuation: AsyncThrowingStream<UploadEvent, Error>.Continuation
    let decoder: JSONDecoder
    let middlewares: [NetworkMiddleware]
    let validators: [ResponseValidator]
    
    var task: URLSessionTask?
    var receivedData = Data()
    
    init(
        continuation: AsyncThrowingStream<UploadEvent, Error>.Continuation,
        decoder: JSONDecoder,
        middlewares: [NetworkMiddleware],
        validators: [ResponseValidator]
    ) {
        self.continuation = continuation
        self.decoder = decoder
        self.middlewares = middlewares
        self.validators = validators
    }
    
    // Track upload progress
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        continuation.yield(.progress(progress))
        
        #if DEBUG
        print("📤 Upload Progress: \(Int(progress * 100))% (\(totalBytesSent)/\(totalBytesExpectedToSend) bytes)")
        #endif
    }
    
    // Collect response data
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receivedData.append(data)
    }
    
    // Handle completion
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        defer {
            session.invalidateAndCancel()
        }
        
        if let error = error {
            continuation.finish(throwing: error)
            return
        }
        
        // Validate response
        guard let httpResponse = task.response as? HTTPURLResponse else {
            continuation.finish(throwing: APIError.invalidResponse)
            return
        }
        
        do {
            // Process response through middleware
            var processedData = receivedData
            for middleware in middlewares {
                processedData = try middleware.process(data: processedData, response: httpResponse)
            }
            
            // Run validators
            for validator in validators {
                processedData = try validator.validate(data: processedData, response: httpResponse)
            }
            
            // Decode response
            let decodedResponse = try decoder.decode(T.self, from: processedData)
            let responseString = String(data: processedData, encoding: .utf8) ?? "Success"
            
            continuation.yield(.response(responseString))
            continuation.finish()
            
        } catch {
            continuation.finish(throwing: error)
        }
    }
}
