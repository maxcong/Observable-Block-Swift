# Observable-Swift
A Observable&lt;T> for Swift 3~4


Author : Max.Cong

MVC一直以来是代码组织架构中苹果公司所推崇的开发模式，但由于工程类文件的日益增多，MVC中C层(Controller层)的日益臃肿，产品需求复杂化，迭代速度越来越快，老架构设计已经渐渐跟不上高强度的组件化团队化开发了。最近一直在寻求一种开发模式，能让多个团队成员可以同时开发且逻辑清晰。期间阅读了很多文章，比如VIPER架构、UBer公司未开源的Riblets架构、MVVM架构等，最终决定自己针对MVVM进行一次架构改造，并加入VIPER的特点。其中MVVM的ViewModel的轻实现，当下被列为攻坚环节。


![](http://upload-images.jianshu.io/upload_images/6174774-2c6ef04db2418c5e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


MVVM一个非常重要的环节ViewModel中采用KVO的观察者模式监听，调用ViewController来进行整个架构的解耦设计。在Objective-C当中得益于强大的Runtime机制可以实现对任意类型的观察者监听。虽然Objective-C中可以任意定义KVO，但是经历过大项目的朋友一定首先会想到Objective-C中的KVO在使用的轻便型上差强人意，需要addObserver和removeObserver，且如果Context上下文弄错了，会有一定的崩溃风险，这是需要深刻了解Objective-C的释放避免指针的循环引用等。

Swift作为一个静态编译型语言，它摒弃了Objective-C中的Runtime机制。想要开启动态Property需要再Swift的Property前面增加声明：dynamic，且使用dynamic必须是基于NSObject基类所构造的类型，这样做必然会丧失对Swift原始数据类型的支持，可见其是不好的。

很庆幸的是Swift语言在自己的Property中增加了getter/ setter的属性观察器，并对setter的属性观察器提供了willSet / didSet的两个观察器来详细监听值的变化。这让我们看到Swift本身是汲取了Objective-C在Runtime中创造的经验，并将观察者模式轻量化。

~~~
class valueDemo {
    var value:String = "" {
        willSet {
            print("newValue:", newValue)
        }
        didSet {
            print("done:", value)
        }
    }
}
~~~

可是我们在开发中不仅仅是这样的简单环境，我们需要针对MVVM中ViewModel开放一个被观察者连接给ViewController，两者产生联动。看到这里肯定有朋友想到，我提供一个闭包(block)设置给didSet就好了呀。确实，如果为每一个Property提供一个block虽然可行，但没有重用好这一机制是不优雅的，导致我们大量重写这一部分代码。那我们就要寻找一个好一点的方法来能让Property变成一个被观察者，当它发生变更的时候，触发一批block回调。

读到这里，肯定有朋友会想到使用ReactiveCocoa和RxSwift的第三方库来实现(笔者更喜欢后者的书写风格)。确实，现在MVVM中采用RxSwift解耦作为中间件确实是产品开发一波潮流，这就像某种服装搭配趋势一样的流行。是否采用这个方式得分析一下ReactiveCocoa和RxSwift都哪些共同缺点后方可抉择：
1. 订阅和分发导致它本身的执行效率低，会有大量的触发栈和循环去进行订阅消息的分发，遍历逐个投递。
2. Swift本身的语法导致从Swift v.2 -> v.3 -> v.4的语法升级受制于苹果的语言规则。Swift语言开发者的开发理念是快速激进式的开发（我给它定名为：语法摧毁），虽然xcode提供了自动化转换语法功能，但难免会有转换错误和手动修改的情况。这样对于我们程序本身是非常不稳定的变化，导致我们出现重写程序组件的问题，甚至摧毁式的无法编译
3. ReactiveCocoa和RxSwift的开发成本也比较高，语法体系奇特(碎片化的代码，打散业务逻辑)，导致团队间在合作时逻辑代码理解难度加大。团队成员间的代码沟通变慢，
4. 库文件升级缓慢，受制于他人，如果停止更新，可能你的产品就要赶紧寻找其他第三方库来进行重构。

基于以上几点缺点，我在这里不赞同采用这样的第三方组件的开发方式开发，虽然它们很酷炫！会写可能显得高大上！

那难道没有一个又轻又容易维护的观察者模式吗？答案是有的！
那我们就从零开始一步步实现一个基于Swift 3~4的观察者模式（由于我所书写的日期是2017-6-6，正好是Swift 4发布当日）

先来描述一下基本原理：
1. 实现一个用于产生被观察者的自定义泛型类：Observable<T>
2. Observable自身提供blocks的闭包数组存放订阅者的闭包
3. 基于Observable中的value的setter方法，手动调用每个闭包即可。

先来看一下基础Swift代码：
~~~
// 需要持有一批blocks，则必须创建一个变量作为空间
class Observable<T> {
    typealias ObservableBlock = (T) -> ()
    private var blocks: [ObserverBlock] = []  // 持有blocks
    
    init(_ t:T) { self.value = t }  // 初始化value
    var value:T {
        didSet {
            // 实现didSet来遍历block，触发回调
            for block in blocks {
                block(self.value)
            }
        }
    }

    // 订阅
    func subscribe(block:@escaping ObserverBlock) {
        blocks.append(block)
    }
}
~~~

run exmple:
~~~
let example = Observable<String>("")
example.subscribe { (newValue:String) in
    print("newValue:", newValue)
}
example.value = "a"
example.value = "b"
~~~

代码的运行结果：
~~~
newValue: a
newValue: b
~~~

看到运行结果，很不错！基于简单blocks持有，基于didSet就可以完成对于一个变量设置的变更监听。
仔细打量一下代码，中间缺少几个能力：

1. 如何将example.value = "a"的书写方法消耗的卡路里降到最低呢。这里想到了Swift的《高级运算符重载》：【此处应有链接】
2. 删除订阅者block能力。这个能力需要在订阅时将订阅者传递给Observable加以持有，并提供unSubscribe方法

第一步我们先来加入自定义高级运算符重载！片段代码：
~~~
infix operator <-: ObservableChange 
precedencegroup ObservableChange {
    associativity: left                 // 表示左结合
}
public func <- <T> (left: Observable<T>, right: T) {
    left.value = right
}
~~~

完整代码：
~~~
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
~~~

run exmple :
~~~
let example = Observable<String>("")
example.subscribe { (newValue:String) in
     print("newValue:", newValue)
}
example.value = "a"
example.value = "b"
example <- "a"
~~~

代码的运行结果：
~~~
newValue: a
newValue: b
newValue: a
~~~

第二步添加unSubscribe方法

这里起初我想直接通过block闭包的相等性检查，通过block闭包相等，来移除blocks中的指定闭包，但是失败了。比如代码：
~~~
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
    
    // 移除订阅
    func unSubscript(block:@escaping ObservableBlock) {
        var blocksFiltered = blocks.filter { (blockInArray:ObservableBlock) -> Bool in
            return blockInArray !== block  // !!!!!!!无法编译，编译报错!!!!!!!
            //报错信息：  Cannot check reference equality of functions;operands here have type '(T)->()' and '(T)->()'
        }

        self.blocks = blocksFiltered
    }
}
~~~


看到//报错信息：  Cannot check reference equality of functions;operands here have type '(T)->()' and '(T)->()'
发现Swift中是不允许将两个闭包进行的比较的。虽然遗留的C API中是有unsafeBitCast可以对两个闭包进行比较，但我还是放弃这样的写法。

    unsafeBitCast 相关使用：https://stackoverflow.com/questions/24111984/how-do-you-test-functions-and-closures-for-equality

那既然block无法比较相等，就只能讲上下文与blocks进行绑定关系，来实现订阅和删除订阅。

~~~
// 定义高级运算符重载，必须为final访问权限的声明
public final class Observable<T> {
    typealias ObserverBlock = (_ oldValue:T, _ newValue:T) -> ()    // 订阅block，增加old和new的传值
    typealias ObserverEntry = (observer: AnyObject, block: ObserverBlock)   // 观察者元组
    private var observers: [ObserverEntry]  // 观察者Array
    
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
    
    // 订阅，创建观察者元组
    func subscribe(observer:AnyObject, block:@escaping ObserverBlock) {
        observers.append(ObserverEntry(observer:observer, block:block))
    }
    
    // 解除订阅，根据元组中的观察者移除
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
    associativity: left                 // 表示左结合
}

// 运算符重载
public func <- <T> (left: Observable<T>, right: T) {
    left.value = right
}
~~~

run example:

~~~
let example = Observable<String>("")
example.subscribe(observer: self) { (oldValue:String, newValue:String) in
    print("oldValue:", oldValue, "newValue:", newValue)
}
example.value = "a"
example.value = "b"
example <- "a"
example.unSubscribe(observer: self)
example <- "c"  // 取消订阅，则不会看到"c"的打印
~~~

代码的运行结果：
~~~
oldValue:  newValue: a
oldValue: a newValue: b
oldValue: b newValue: a
// 这里没有看到“c”
~~~

好了，经过打磨的Observable已经初步具备了观察者能力了，并且可以轻巧的应用于变量的观察
全部代码：
https://github.com/slazyk/Observable-Swift


	我在编写期间试用了google的一个开发者开发的Observable-Swift的，但这个只针对于Swift 3且功能略显复杂。

不过本观察者订阅模式和其他的第三方组件其实都有一个弊端：就是插入式编程，
插入式编程就是会将原有的代码的变量类型破坏，从而让类型都趋向于Observable<T>数据类型，这样喜欢纯正变量监听的话，当下除了willSet和didSet，尚未发现其他更优雅的方法！

此文抛砖引玉，希望看到的开发者如果有优雅的方法可以在文章后面留言。深表感谢！

Author: Max.Cong