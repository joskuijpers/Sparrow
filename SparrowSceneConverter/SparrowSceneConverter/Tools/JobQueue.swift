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
    
    
    /// Create a new job queue
    init(runner: JobRunner<Input, Result>) {
        self.runner = runner
    }
    
    /// Start running the queue in the background
    func start() {
        
    }
    
    /// Enqueue a new task. Returns the index in the result array.
    @discardableResult
    func enqueue(input: Input) -> Int {
        print("ENQUEUING NEW JOB \(input)")
        
        // ATOMIC
        let jobId = nextJobId
        nextJobId += 1
        
        let job = Job(id: jobId, input: input)
        
        // Run task
            let result = runner.run(job)
        
            // Atomic
            results[job.id] = result
        
            // Atomic
            numRunningJobs -= 1
        
        return jobId
    }
    
    /// Wait until all jobs have finished processing. This is blocking.
    func waitUntilFinished() -> [Result?] {
        print("WAIT UNTIL FINISHED")
        
        while numRunningJobs > 0 {
            print("Waiting for jobs to finish...")
            Thread.sleep(forTimeInterval: 0.5)
        }

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
