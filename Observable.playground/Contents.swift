//: Playground - noun: a place where people can play

// final class for operator <-
// 高级运算符重载必须声明在final顶级访问级别的类中

public final class Observable<T> {
    typealias ObserverBlock = (_ oldValue: T, _ newValue: T) -> ()
    typealias ObserversEntry = (block: ObserverBlock, observerName:String?)
    private var observers: Array<ObserversEntry>
    
    init(_ value: T) {
        self.value = value
        observers = []
    }
    
    var value: T {
        didSet {
            observers.forEach { (entry: ObserversEntry) in
                let (block, _) = entry
                block(oldValue, value)
            }
        }
    }
    
    func subscribe(block: @escaping ObserverBlock) -> Self {
        let entry: ObserversEntry = (block: block, nil)
        observers.append(entry)
        return self
    }
    
    // set ObserverName for unsubscribe
    func addObserverName(_ observerName: String) {
        if observers.count > 0 {
            observers[observers.count-1].observerName = observerName
        }
    }
    
    // remove subscribe with ObserverName
    func unSubscribe(_ observerName: String) {
        let filtered = observers.filter { entry in
            let (_, observerNameSaved) = entry
            if (observerNameSaved != nil) {
                return observerNameSaved != observerName
            } else {
                return true
            }
        }
        
        observers = filtered
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



// Example For Observable<T>
class Example {
    init() {
        let example = Observable<String>("")
        example.subscribe{ (old:String, new:String) in
            print("oldValue:", old, "newValue:", new)
        }.addObserverName("TheExampleName")
        example.value = "a"
        example.value = "b"
        example <- "a"
        example.unSubscribe("TheExampleName")
        example <- "c"
    }
}

Example()
