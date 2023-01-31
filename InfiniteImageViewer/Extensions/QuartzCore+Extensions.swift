//
//  QuartzCore+Extensions.swift
//  InfiniteImageViewer
//
//  Created by Elijah Semyonov on 31/01/2023.
//

import QuartzCore

extension CADisplayLink {
    private class Proxy: NSObject {
        let closure: () -> Void
        
        init(closure: @escaping () -> Void) {
            self.closure = closure
        }
        
        @objc func performClosure() {
            closure()
        }
    }
    
    convenience init(closure: @escaping () -> Void) {
        self.init(target: Proxy(closure: closure), selector: #selector(Proxy.performClosure))
    }
}
