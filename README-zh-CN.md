
<h2>简介</h2>
JDHybrid是一个移动端高性能Hybrid容器框架，致力于提升h5加载与渲染性能、WebView容器标准化，项目经过了亿级PV的业务验证， 项目主要包括：

* jsbridge --- JDBridge
* 集成各种开源能力的WebView容器 --- JDWebView
* 离线包加载框架 --- JDCache (即将开源)


<h2>快速入门指南</h2>
<h3>使用JSBridge</h3>
JSBridge(JDBridge) 包含jssdk部分与客户端部分，使用时js先引入JSSDK(见下文), 并添加js插件供native调用，或通过jssdk api调用native插件，使用方式参考：

* [H5 JSBridge](H5/JDBridge/README-zh-CN.md)
* [iOS JSBridge](iOS/JDHybrid/JDBridge/README-zh-CN.md)
* [Android JSBridge](android/JDBridge/README-zh-CN.md)

<h3>使用WebView容器</h3>
JDHybrid 提供了支持JDBridge的容器，未来还会支持离线加载能力，可直接使用

* [iOS WebView容器](iOS/JDHybrid/JDWebView/README-zh-CN.md)
* [Android WebView容器](android/JDWebView/README-zh-CN.md)

<h3>更多使用方式</h3>

* [h5 Demo](H5/JDBridge/Example) 进入[H5/JDBridge/Example](H5/JDBridge/Example)下执行 `npm install && npm run build` , 打开 `dist` 文件夹内的html即可, 客户端试用下面Demo前也请先安装h5 demo，我们会自动copy产物到Example内
* [iOS Demo](iOS/Example) 进入[iOS/Example](/iOS/Example)文件夹，执行 `pod install` 
* [Android Demo ](android/example)进入[android](/android)文件夹，执行`./gradlew installDebug`

<h2>Contributing</h2>
我们希望你能为JDHybrid做出贡献，帮助它变得比现在更好！我们鼓励并重视所有类型的贡献，请参阅我们的贡献指南了解更多信息。

如果你有任何问题，请随时在我们的讨论区开启一个新的讨论主题。

<h2>License</h2>
JDHybrid(包括子项目) 基于MIT协议开源，具体查看 LICENSE 文件了解更多信息.


<h2>Contact</h2>

邮箱: hybrid@jd.com
