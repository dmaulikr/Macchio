//
//  UserState.swift
//  Macchio
//
//  Created by Ryan Anderson on 10/23/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation

class UserState {
    static var name: String = NSUserDefaults.standardUserDefaults().stringForKey("myName") ?? "Average Blob" {
        didSet {
            NSUserDefaults.standardUserDefaults().setObject(name, forKey:"myName")
            // Saves to disk immediately, otherwise it will save when it has time
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
    
    static var highScore: Int = NSUserDefaults.standardUserDefaults().integerForKey("myHighScore") ?? 0 {
        didSet {
            NSUserDefaults.standardUserDefaults().setInteger(highScore, forKey:"myHighScore")
            // Saves to disk immediately, otherwise it will save when it has time
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
}
