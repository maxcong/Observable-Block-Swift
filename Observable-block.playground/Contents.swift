//: Playground - noun: a place where people can play

import Foundation


// 高级运算符重载必须声明在final顶级访问级别的类中
public final class Observable<T> {
    typealias ObserverBlock = (T) -> ()
    private var blocks: Array<ObserverBlock> = Array()
    
    init(_ t:T) { self.value = t }
    var value:T {
        didSet {
            for block in blocks {
                block(self.value)
            }
        }
    }
    func subscribe(block:@escaping ObserverBlock) {
        blocks.append(block)
    }
    deinit {
        print("Observable", #function)
    }
}

/*
 定义 <- 运算符
 运算符定义必须放在文件级别当中
 */
infix operator <-: ObservableChange
precedencegroup ObservableChange {
    associativity: left                 // 表示左结合
}

public func <- <T> (left: Observable<T>, right: T) {
    left.value = right
}


var example = Observable("String 1")
example.subscribe { (new:String) in
    print(new)
}
example <- "String 2"