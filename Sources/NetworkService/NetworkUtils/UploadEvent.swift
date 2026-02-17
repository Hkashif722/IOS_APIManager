//
//  UploadEvent.swift
//  NetworkService
//
//  Created by Kashif Hussain on 17/02/26.
//

import Foundation

//Helper Methods
public enum UploadEvent: Sendable {
    case progress(Double)
    case response(String)
}
