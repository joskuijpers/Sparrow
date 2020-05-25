//
//  JobQueue.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 24/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

/**
 A job queue that has a runner that performs a tak on jobs, and finishes with a list of all these job results in a defined order.
 */
class JobQueue<Input, Result> {
    let runner: JobRunner<Input, Result>
    
    // ATOMIC
    var results: [Int:Result?] = [:]
    var nextJobId = 0
    var numRunningJobs = 0
    
    private let dispatchQueue: DispatchQueue
    private let dispatchGroup: DispatchGroup
    private let lock: NSLock
    
    private var running = false
    
    var isRunning: Bool {
        running
    }
    
    enum Error: Swift.Error {
        case queueNotRunning
    }
    
    /// Create a new job queue
    init(runner: JobRunner<Input, Result>) {
        self.runner = runner
        self.dispatchQueue = DispatchQueue(label: "jobs",
                                           qos: .background,
                                           attributes: .concurrent,
                                           autoreleaseFrequency: .inherit,
                                           target: nil)
        self.dispatchGroup = DispatchGroup()
        self.lock = NSLock()
    }
    
    /// Start running the queue in the background
    func start() throws {
        running = true
    }
    
    /// Enqueue a new task. Returns the index in the result array.
    @discardableResult
    func enqueue(input: Input) throws -> Int {
        guard running else {
            throw Error.queueNotRunning
        }
        
        lock.lock()
        
        let jobId = nextJobId
        nextJobId += 1
        
        let job = Job(id: jobId, input: input)
        numRunningJobs += 1
        
        lock.unlock()
        
        dispatchQueue.async(group: dispatchGroup,
                            qos: .background,
                            flags: .assignCurrentContext)
        {
            // Long running process
            let result = self.runner.run(job)
            
            // Handling result
            self.lock.lock()
            
            self.results[job.id] = result
            self.numRunningJobs -= 1
            
            self.lock.unlock()
        }

        return jobId
    }
    
    /// Wait until all jobs have finished processing. This is blocking.
    func waitUntilFinished() throws -> [Result?] {
        guard running else {
            throw Error.queueNotRunning
        }
        
        print("[queue] Waiting for jobs to finish...")
        
        while running {
            // No atomic check here because it is slow
            while numRunningJobs > 0 {
                Thread.sleep(forTimeInterval: 1)
            }
            
            // Need atomic check
            lock.lock()
            if numRunningJobs == 0 {
                lock.unlock()
                break
            }
            lock.unlock()
        }
        
        // Prevent any further work
        running = false
        
        // Build list
        let resultList = (0..<nextJobId).map {
            results[$0]!
        }
        
        return resultList
    }

}

/// A job with an input
struct Job<Input> {
    let id: Int
    let input: Input
}

/// Class that can run jobs to transform from Input to Result. Can hold state. ???? CLONE?
class JobRunner<Input, Result> {
    let thread: Thread
    
    init() {
        thread = Thread.current
    }
    
    /// Clone this runner into a new thread
    func clone(thread: Thread) -> Self? {
        return nil
    }
    
    func run(_ job: Job<Input>) -> Result? {
        return nil
    }
}
