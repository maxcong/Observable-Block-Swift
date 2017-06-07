//: Playground - noun: a place where people can play

import Foundation

// final class for operator <-
// 定义高级运算符重载，必须为final访问权限的声明
public final class Observable<T> {
    typealias ObserverBlock = (_ oldValue:T, _ newValue:T) -> ()    // Observer block
    typealias ObserverEntry = (observer: AnyObject, block: ObserverBlock)
    private var observers: [ObserverEntry]
    
    init(_ value:T) {
        self.value = value
        observers = []
    }
    var value:T {
        didSet {
            observers.forEach { (entry: ObserverEntry) in
                let (_, block) = entry
                block(oldValue, value)
            }
        }
    }
    
    func subscribe(observer:AnyObject, block:@escaping ObserverBlock) {
        observers.append(ObserverEntry(observer:observer, block:block))
    }
    
    func unSubscribe(observer:AnyObject) {
        let filtered = observers.filter { (entry: ObserverEntry) in
            let (owner, _) = entry
            return owner !== observer
        }
        
        observers = filtered
    }
}

infix operator <-: ObservableChange
precedencegroup ObservableChange {
    associativity: left                 // 左结合
}

// 运算符重载
public func <- <T> (left: Observable<T>, right: T) {
    left.value = right
}


// Example For Observable<T>
class Example {
    init() {
        let example = Observable<String>("")
        example.subscribe(observer: self) { (oldValue:String, newValue:String) in
            print("oldValue:", oldValue, "newValue:", newValue)
        }
        example.value = "a"
        example.value = "b"
        example <- "a"
        example.unSubscribe(observer: self)
        example <- "c"
    }
}

Example()