//
//  UserState.swift
//  Macchio
//
//  Created by Ryan Anderson on 10/23/16.
//  Copyright © 2016 Ryan Anderson. All rights reserved.
//

import Foundation

class UserState {
    static var name: String = UserDefaults.standard.string(forKey: "myName") ?? "Average Blob" {
        didSet {
            UserDefaults.standard.set(name, forKey:"myName")
            // Saves to disk immediately, otherwise it will save when it has time
            UserDefaults.standard.synchronize()
        }
    }
    
    static var highScore: Int = UserDefaults.standard.integer(forKey: "myHighScore") ?? 0 {
        didSet {
            UserDefaults.standard.set(highScore, forKey:"myHighScore")
            // Saves to disk immediately, otherwise it will save when it has time
            UserDefaults.standard.synchronize()
        }
    }
}
