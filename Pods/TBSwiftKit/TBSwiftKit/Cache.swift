//
//  Cache.swift
//  ArkhamCompanion
//
//  Created by Tiago Bras on 14/03/2017.
//  Copyright © 2017 TiagoBras. All rights reserved.
//

import Foundation

class ValueWithTimestamp<T> {
    private(set) var lastAccess = Date()
    private var _value: T
    var value: T {
        get {
            lastAccess = Date()
            return _value
        }
        set {
            lastAccess = Date()
            _value = newValue
        }
    }
    
    init(_ value: T) {
        _value = value
    }
}

public class Cache<Key, Value> where Key: Hashable {
    public typealias DefaultValue = () -> Value?
    
    private let MIN_ITEMS_COUNT = 5
    private lazy var items = [Key: ValueWithTimestamp<Value>]()
    private var queue: DispatchQueue
    
    public let maxItems: Int
    public var count: Int {
        return items.count
    }
    
    /**
     - parameters:
     - maxItems: maximum number of items in cache (min = 5)
     */
    public init(maxItems: Int = 20) {
        self.maxItems = maxItems >= MIN_ITEMS_COUNT ? maxItems : MIN_ITEMS_COUNT
        self.queue = DispatchQueue(label: "CACHE:\(UUID().uuidString)",
            qos: .default,
            attributes: .concurrent,
            autoreleaseFrequency: .inherit,
            target: nil)
    }
    
    public func get(_ key: Key) -> Value? {
        var returnValue: Value?
        
        queue.sync {
            returnValue = items[key]?.value
        }
        
        return returnValue
    }
    
    public func get(_ key: Key, defaultValue: DefaultValue) -> Value? {
        var returnValue: Value?
        
        queue.sync {
            if items[key] != nil {
                returnValue = items[key]?.value
            }
            
            if let newValue = defaultValue() {
                if items.count >= maxItems && items[key] == nil {
                    removeLeastRecentlyUsedItem()
                }
                
                items[key] = ValueWithTimestamp(newValue)
                
                returnValue = items[key]?.value
            }
        }
        
        return returnValue
    }
    
    public func set(_ key: Key, value: Value) {
        queue.sync {
            if items.count >= maxItems && items[key] == nil {
                removeLeastRecentlyUsedItem()
            }
            
            items[key] = ValueWithTimestamp(value)
        }
    }
    
    public func clear() {
        queue.sync {
            items.removeAll()
        }
    }
    
    private func removeLeastRecentlyUsedItem() {
        guard var oldestItem = items.first else {
            return
        }
        
        for i in items {
            if i.value.lastAccess < oldestItem.value.lastAccess {
                oldestItem = i
            }
        }
        
        items.removeValue(forKey: oldestItem.key)
    }
}
