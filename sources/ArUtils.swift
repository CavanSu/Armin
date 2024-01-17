//
//  ACUtils.swift
//  Armin
//
//  Created by CavanSu on 2020/5/25.
//  Copyright © 2020 CavanSu. All rights reserved.
//

class ArAfterWorker {
    private var pendingRequestWorkItem: DispatchWorkItem?
    
    func perform(after: TimeInterval,
                 on queue: DispatchQueue,
                 _ block: @escaping (() -> Void)) {
        // Cancel the currently pending item
        pendingRequestWorkItem?.cancel()
        
        // Wrap our request in a work item
        let requestWorkItem = DispatchWorkItem(block: block)
        pendingRequestWorkItem = requestWorkItem
        queue.asyncAfter(deadline: .now() + after,
                         execute: requestWorkItem)
    }
    
    func cancel() {
        pendingRequestWorkItem?.cancel()
    }
}

class ArRetry {
    private let work = ArAfterWorker()
    private let queue: DispatchQueue
    private(set) var retryCount: Int
    let maxCount: Int
    
    init(maxCount: Int,
         queue: DispatchQueue) {
        self.maxCount = maxCount
        self.retryCount = 0
        self.queue = queue
    }
    
    func ifNeedRetry() -> Bool {
        if retryCount > maxCount {
            return false
        } else {
            return true
        }
    }
    
    func perform(_ block: @escaping (() -> Void)) {
        retryCount += 1
        
        guard ifNeedRetry() else {
            return
        }
        
        let after = (TimeInterval(retryCount) * 0.25)
        
        work.perform(after: after,
                     on: queue,
                     block)
    }
}
