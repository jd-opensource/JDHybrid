[![MIT](https://img.shields.io/github/license/JDFED/JDHybrid)](https://cocoapods.org/pods/JDHybrid) [![npm](https://img.shields.io/npm/v/jdhybrid_jdbridge)](https://www.npmjs.com/package/jdhybrid_jdbridge) [![Cocoapods](https://img.shields.io/cocoapods/v/JDHybrid)](https://cocoapods.org/pods/JDHybrid) [![Cocoapods platforms](https://img.shields.io/cocoapods/p/JDHybrid)](https://github.com/JDFED/JDHybrid) [![JitPack](https://img.shields.io/jitpack/version/com.github.JDFED/JDHybrid)](https://jitpack.io/#JDFED/JDHybrid) [![Android](https://img.shields.io/badge/platform-Android-green)](https://github.com/JDFED/JDHybrid)

> [简体中文文档](README-zh-CN.md)

<h2>Introduction</h2>

JDHybrid is a High-Performance hybrid framework for mobile apps, which is committed to improve the loading and rendering performance of H5 and the standardization of WebView containers. The project has been verified more fully by dozens of h5 projects in JD. Our projects mainly include:

* `JDBridge`: A JSbridge Framework
* `JDWebView`: WebView container integrating `JDBridge` capability and other features



<h2>Get Started</h2>

<h3>JSBridge</h3>
JSBridge(JDBridge) includes two parts --- jssdk & client framework. First, you can install jssdk to support bridge environment. Then app client integrates JDBridge framework. Finally creating js plugins or native plugins calling one another. For more detail, please read below:

* [H5 JSBridge](H5/JDBridge/README.md)
* [iOS JSBridge](iOS/JDHybrid/JDBridge/README.md)
* [Android JSBridge](android/JDBridge/README.md)

<h3>JDWebView </h3>
JDHybrid provides a WebView Container which integrates JDBridge Capacity right now，and offline package in the future. you can use it directly:

* [iOS WebView Container](iOS/JDHybrid/JDWebView/README.md)
* [Android WebView Container](android/JDWebView/README.md)

<h3>JDCache </h3>
* [iOS JDCache](iOS/JDHybrid/JDCache/README.md)

<h3>More Detail</h3>

* [iOS Demo](iOS/Example) In the `iOS/Example` directory，run `pod install` 
* [Android Demo](android/example) In the `android` directory(android Example's parent)，run `./gradlew installDebug` 
* [H5 JDBridge Demo](H5/JDBridge/Example) In the directory, run `npm install && npm run build` , then open the html in the `dist` directory, you also can run APP's demo after H5 demo built.

<h2>Contributing</h2>

We would love for you to contribute to JDHybrid and help make it better! All types of contributions are encouraged and valued. Thanks to all contributors. we are very pleasure to accept your PR.

If you have any questions, please feel free to open a new Discussion topic in our discussion forums.

<h2>License</h2>
JDHybrid (include sub projects）is released under the MIT, see the license file for more info.


<h2>Contact</h2>
Email: hybrid@jd.com
