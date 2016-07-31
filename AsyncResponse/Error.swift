//
//  Error.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 7/17/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

enum Error: ErrorType {

    case Combine([(index: Int, ErrorType)])

}
