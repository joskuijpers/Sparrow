//
//  SceneLoader.swift
//  
//
//  Created by Jos Kuijpers on 10/06/2020.
//

import SparrowECS

/// Loader of scene files (.sps).
///
/// Loading results in a hierarchy of entities with components.
/// Entities might have mesh components. These will already be loaded.
public class SceneLoader {
  
    
    enum Error: Swift.Error {
        /// The file is not a valid Sparow scene file.
        case invalidFile
    }
    
    public func load() throws -> Entity {
        // TODO.....
        throw Error.invalidFile
    }
}
