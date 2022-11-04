// 
// MIT License
// 
// Copyright (c) 2022 JD.com, Inc.
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

(function () {
    if (window.JDBridge) {
        return
    };

    const TAG = 'JDBridge: ';
    // debug show logs
    var debug = false;
    // the queue waiting for js plugin to execute
    var nativeRequestQueue = [];
    // the js functions handle native requests
    var jsPlugins = {};
    // ths js callbacks invoked after js calls native
    var responseCallbacks = {};
    // an unique id for response callback
    var uniqueId = 1;

    function logE(msg){
        if (debug) {
            console.error(TAG + msg);
        }
    }

    function logD(msg){
        if (debug) {
            console.log(TAG + msg);
        }
    }

    function setDebug(isDebug){
        debug = isDebug;
    }

    function isDebug(){
        return debug;
    }

    // the API to set default plugin, then native can call js without plugin name or plugin has not registered
    function registerDefaultPlugin(handler) {
        logD('register a defualt js plugin');
        if (handler && typeof handler != 'function') {
            logE('cannot register a default plugin that is not a function');
            return;
        }
        if (JDBridge._defaultPlugin) {
            logD('old defualt js plugin has been changed')
        };
        JDBridge._defaultPlugin = handler;
        if (nativeRequestQueue) {
            logD('dispatch request from native in queue');
            var reqQueue = nativeRequestQueue;
            // forbid to queue after set default js plugin
            nativeRequestQueue = null;
            for (var i = 0; i < reqQueue.length; i++) {
                logD('dispatch all request in queue: request = ' + JSON.stringify(reqQueue[i]));
                _doHandleFromNative(reqQueue[i]);
            }
        }
    };

    // the API to add the js plugin that native can call
    function registerPlugin(pluginName, handler) {
        logD('register a js plugin: ' + pluginName);
        if (!handler || typeof handler != 'function') {
            logE('cannot register a js plugin: ' + pluginName + ', handle is ' + handler);
            return;
        }
        jsPlugins[pluginName] = handler;
        var reqQueue = nativeRequestQueue;
        if (reqQueue && reqQueue.length > 0) {
            logD('dispatch request from native that can be handled by ' + pluginName + ' in queue(size:' + reqQueue.length + ')');
            for (var i = 0; i < reqQueue.length; i++) {
                var request = reqQueue[i];
                if (request.plugin && jsPlugins[request.plugin]) {
                    nativeRequestQueue.splice(i--, 1);
                    _doHandleFromNative(request);
                }
            }
            logD('now the native request queue size: ' + nativeRequestQueue.length);
        }
    };

    // the API to remove the js plugin
    function unregisterPlugin(pluginName) {
        logD('remove a js plugin: ' + pluginName);
        delete jsPlugins[pluginName];
    };

    // the API to call native code
    // can call like this: 
    //      callNative('pluginName')
    //      callNative('pluginName', {action: 'yourAction', params: 'yourParams', success: function(), error: function(), progress: function()})
    //      callNative({name: 'pulginName', action: 'yourAction', params: 'yourParams', success: function(), error: function(), progress: function()})
    function callNative() {
        if (!window.XWebView) {
            logE('Error! No JDBridge native enviroment detected.');
            return;
        }
        var callParams;
        var pluginName, action, params, successFunc, errorFunc, progressFunc;
        if (arguments.length == 1) {
            var arg = arguments[0];
            if (typeof arg == 'string') {
                pluginName = arg;
            } else {
                callParams = arg;
            }
        } else if (arguments.length == 2) {
            pluginName = arguments[0];
            callParams = arguments[1];
        }
        if (callParams) {
            if (callParams.name) {
                pluginName = callParams.name;
            }
            action = callParams.action;
            params = callParams.params;
            successFunc = callParams.success;
            errorFunc = callParams.error;
            progressFunc = callParams.progress;
        }
        logD('callNative -> pluginName:' + pluginName + ', action:' + action + ', params:' + params + ', successFunc:' + successFunc + ', errorFunc:' + errorFunc + ', progressFunc:' + progressFunc);
        if (pluginName && typeof pluginName != 'string') {
            logE('Error! Plugin\'s name provided must be a string.');
            return;
        }
        var callbackId;
        if (successFunc) {
            if (typeof successFunc == 'function') {
                callbackId = 'cb_' + (uniqueId++) + '_' + new Date().getTime();
                var callbacks = {};
                responseCallbacks[callbackId] = callbacks;
                callbacks.successFunc = successFunc;
                if (errorFunc) {
                    if (typeof errorFunc == 'function') {
                        callbacks.errorFunc = errorFunc;
                    } else {
                        logE('Error! Error callback is not a function.');
                    }
                }
                if (progressFunc) {
                    if (typeof progressFunc == 'function') {
                        callbacks.progressFunc = progressFunc;
                    } else {
                        logE('Error! Progress callback is not a function.');
                    }
                }
            } else {
                logE('Error! Success callback is not a function.');
                return;
            }
        }
        var request = {
            plugin: pluginName ? pluginName : '',
            action: action ? action : '',
            params: params,
            callbackId: callbackId
        };
        window.XWebView._callNative(JSON.stringify(request));
    };

    // actual work that processing message from native.
    // will check if there is plugin can handle, if no default plugin and named plugin found, then nothing happens.
    function _doHandleFromNative(request) {
        setTimeout(function () {
            if (!window.XWebView) {
                logE('Error! No JDBridge native enviroment detected.');
                return;
            }
            var plugin;
            if (request.plugin) {
                plugin = jsPlugins[request.plugin];
            }
            if (!plugin) {
                // can use default plugin if no specific plugin registered
                plugin = JDBridge._defaultPlugin;
            }
            if (plugin) {
                var jsCallback;
                if (request.callbackId) {
                    var callbackId = request.callbackId;
                    logD('request.callbackId = ' + callbackId);
                    jsCallback = function (result, success, complete) {
                        if (typeof success != 'boolean' || typeof success == 'undefined') {
                            success = true;
                        }
                        if (typeof complete != 'boolean' || typeof complete == 'undefined') {
                            complete = true;
                        }
                        var response = {
                            callbackId: callbackId,
                            complete: complete
                        };
                        if (success) {
                            response.status = '0';
                            response.data = result;
                        } else {
                            response.status = '-1';
                            response.msg = result;
                        }
                        logD('response to native: ' + JSON.stringify(response));
                        // window.XWebView._respondFromJs(JSON.stringify(response));
                        var request = {
                            plugin: '_jdbridge',
                            action: '_respondFromJs',
                            params: response,
                        };
                        window.XWebView._callNative(JSON.stringify(request));
                    }
                }
                try {
                    // If the function has more than 2 arguements, then it need a callback
                    if (plugin.length >= 2) {
                        // js async call
                        logD('call js async plugin');
                        plugin.call(this, request.params, jsCallback);
                    } else {
                        // js sync call
                        logD('call js sync plugin');
                        var result = plugin.call(this, request.params);
                        if (jsCallback) {
                            jsCallback(result, true, true);
                        }
                    }
                } catch (exception) {
                    logE("javascript plugin threw. ", request.plugin, exception);
                }
            } else {
                logD('no plugin to handle request:' + request.plugin);
            }
        });
    };

    // invoked by native, may queue and wait for js registering if there is no plugin can process this request.
    function _handleRequestFromNative(requestJSON) {
        logD('handle request from native: ' + requestJSON);
        var request = JSON.parse(requestJSON);
        if (!JDBridge._defaultPlugin) {
            // no default plugin registered
            if (request.plugin && !jsPlugins[request.plugin]) {
                // add this request into queue because there is no plugin can handle,
                // wait for js registering plugin.
                logD('cannot find plugin to handle this request[' + request.plugin + '], will wait for js adding this plugin.');
                nativeRequestQueue.push(request);
                return;
            }
        }
        // try to handle request, will check if there is plugin can handle,
        // if no default plugin and named plugin found, then nothing happens.
        _doHandleFromNative(request);
    };

    // invoked by native, receive response from native after native is called by js
    function _handleResponseFromNative(responseJSON) {
        logD('handle response from native: ' + responseJSON);
        var response = JSON.parse(responseJSON);
        if (response.callbackId) {
            var callback = responseCallbacks[response.callbackId];
            if (!callback) {
                logD('cannot find the callback: ' + response.callbackId);
                return;
            }
            if (response.status == '0') {
                if (response.complete == false) {
                    if (!callback.progressFunc) {
                        logD('cannot find the progress callback: ' + response.callbackId);
                    } else {
                        callback.progressFunc(response.data, response);
                    }
                } else {
                    if (!callback.successFunc) {
                        logD('cannot find the success callback: ' + response.callbackId);
                    } else {
                        callback.successFunc(response.data, response);
                    }
                }
            } else {
                if (!callback.errorFunc) {
                    logD('cannot find the error callback: ' + response.callbackId);
                } else {
                    callback.errorFunc(response.msg, response);
                }
            }
            if (response.complete == false) {
                logD('response from native is not completed, continue to hold callback: ' + response.callbackId);
            } else {
                delete responseCallbacks[response.callbackId];
            }
        }
    };

    // function _handleNativeDispatchEvent(eventName, params) {
    //     logD('dispatchEvent [' + eventName + '], params = ' + params);
    //     if (!eventName) {
    //         return;
    //     }
    //     var myEvent = new CustomEvent(eventName, { params: params });
    //     document.dispatchEvent(myEvent);
    // };

    function nativeReady(){
        return typeof window.XWebView != 'undefined';
    }

    //methods that web can call
    var JDBridge = window.JDBridge = {
        registerDefaultPlugin: registerDefaultPlugin,
        registerPlugin: registerPlugin,
        unregisterPlugin: unregisterPlugin,
        callNative: callNative,
        _handleRequestFromNative: _handleRequestFromNative,
        _handleResponseFromNative: _handleResponseFromNative,
        nativeReady: nativeReady,
        setDebug: setDebug,
        isDebug: isDebug
        // _handleNativeDispatchEvent: _handleNativeDispatchEvent
    };

    if (!window._jdbridgeInit) {
        // notify web that JDBridge completed initialization.
        logD('dispatchEvent JDBridgeReady');
        var readyEvent = new CustomEvent("JDBridgeReady", { detail: { bridge: JDBridge } });
        window.dispatchEvent(readyEvent);
        // notify native that this js kit completed initialization.
        window._jdbridgeInit = true;
        setTimeout(function () {
            if (!window.XWebView) {
                logE('Error! No JDBridge native enviroment detected.');
                return;
            };
            // window.XWebView && window.XWebView._jsInit();
            var request = {
                plugin: '_jdbridge',
                action: '_jsInit'
            };
            window.XWebView._callNative(JSON.stringify(request));
            logD('JDBridge is Ready.');
        });
    };


})()
