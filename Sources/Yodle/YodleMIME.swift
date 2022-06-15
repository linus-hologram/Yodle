//
//  YodleMIME.swift
//  
//
//  Created by Linus Bohle on 14.06.22.
//

import Foundation

struct MIMEMultipartContainer {
    
}

struct MIMEBodyPart { // default struct for all MIME body parts
    let contentType: String
    let charset: String
    
    let data: Data
    
    private(set) var customHeaders: [String: String]
    
    mutating func declareHeaders(@CustomHeaderBuilder headers: () -> [String: String]) {
        customHeaders = headers()
    }
    
    func generateBodyData() -> Data {
        // MARK: - process data to match the MIME standard
        return data
    }
}

struct MIMEData {
    var content: Data
    
    mutating func addContainer(container: MIMEMultipartContainer) {
        
    }
    
    mutating func addBodyPart(bodyPart part: MIMEBodyPart) {
        
    }
}
