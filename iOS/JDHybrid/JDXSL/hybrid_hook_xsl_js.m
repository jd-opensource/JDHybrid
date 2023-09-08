//
//  hybrid_hook_xsl_js.m
//  JDBHybridModule
//
//  Created by zhoubaoyang on 2022/9/9.
//

#import "hybrid_hook_xsl_js.h"

NSString * hybrid_hook_xsl_js(void) {
    #define __hyhb_js_func__(x) #x
    
    // BEGIN preprocessorJSCode
    static NSString * preprocessorJSCode = @__hyhb_js_func__(
;(function(){
    "use strict";
    class $ElementName extends HTMLElement {
        messageToNative(params) {
            params['xsl_id'] = this.lowerClassName();
            params['hybrid_xsl_id'] = this.hybrid_xsl_id;
            if (window.XWebView && window.XWebView.callNative) {
              window.XWebView && window.XWebView.callNative('XWidgetPlugin', params['methodType'], params, params['callbackName'], params['callbackId']);
            }
        }
        $customfunction lowerClassName() {
            if (!this.x_className) {
              this.x_className = '$Element-Name' + this.constructor.index++;
            }
            return this.x_className;
        }
        
        finalClassName() {
            if (!this.final_className) {
                this.final_className = this.lowerClassName() + ' ' + this.className;
            }
            return this.final_className;
        }
        
        static get observedAttributes() {
            return ['$obsevers'];
        }
        constructor() {
            super();
            if (!$ElementName.index) {
              $ElementName.index = 0;
              $ElementName.isAddStyle = false;
            }
            this.canUse = window.XWidget && window.XWidget.canIUse('$Element-Name');
            this.x_className = '';
            this.final_className = '';
            this.element_name = '$Element-Name';
            this.display_style = '';
            this.hybrid_xsl_id = '';
            if (!$ElementName.isAddStyle) {
              var style = document.createElement('style');
              var xsl_style = `{ display:block; overflow:scroll; }`;
              style.textContent = '$Element-Name' + `::-webkit-scrollbar { display: none; width: 0; height: 0; color: transparent; }` + '$Element-Name' + xsl_style;
              document.body.appendChild(style);
              $ElementName.isAddStyle = true;
            }
            const shadowroot = this.attachShadow({
              mode: 'open'
            });
            var a = document.createElement('div');
            a.style.height = '102%';
            shadowroot.appendChild(a);
            this.messageToNative({
              'methodType': 'createXsl'
            });
        }
        connectedCallback() {
            this.className = this.finalClassName();
            this.messageToNative({
              'methodType': 'addXsl'
            })
        }
        
        disconnectedCallback() {
            this.messageToNative({
              'methodType': 'removeXsl'
            })
        }
        attributeChangedCallback(name, oldValue, newValue) {
            if (oldValue == newValue) {
                return;
            }
            if (name == 'hidden') {
                if (newValue != null) {
                    this.display_style = this.style.display;
                    this.style.display = 'none';
                } else {
                    this.style.display = this.display_style;
                }
                return;
            } else if (name == 'class') {
                return;
            } else if (name == 'hybrid_xsl_id') {
                this.hybrid_xsl_id = newValue;
                return;
            }
            var params = {
                  'methodType': 'changeXsl',
                  'methodName': name,
                  'oldValue': oldValue,
                  'newValue': newValue
            };
            this.messageToNative(params);
        }
    }
    customElements.define('$Element-Name', $ElementName)
})();

    ); // END preprocessorJSCode

    #undef __hyhb_js_func__
    return preprocessorJSCode;
};

NSString * hybrid_hook_xsl_image_js(void) {
    #define __hyhb_js_func__(x) #x
    
    // BEGIN preprocessorJSCode
    static NSString * preprocessorJSCode = @__hyhb_js_func__(
;(function(){
    "use strict";
    class $ElementName extends HTMLElement {
        messageToNative(params) {
            params['xsl_id'] = this.lowerClassName();
            params['hybrid_xsl_id'] = this.hybrid_xsl_id;
            if (window.XWebView && window.XWebView.callNative) {
              window.XWebView && window.XWebView.callNative('XWidgetPlugin', params['methodType'], params, params['callbackName'], params['callbackId']);
            }
        }
        $customfunction lowerClassName() {
            if (!this.x_className) {
              this.x_className = '$Element-Name' + this.constructor.index++;
            }
            return this.x_className;
        }
        
        finalClassName() {
            if (!this.final_className) {
                this.final_className = this.lowerClassName() + ' ' + this.className;
            }
            return this.final_className;
        }
        
        static get observedAttributes() {
            return ['$obsevers'];
        }
        constructor() {
            super();
            if (!$ElementName.index) {
              $ElementName.index = 0;
              $ElementName.isAddStyle = false;
            }
            this.xWidgetExpandFuncEventList = ['onload','onerror','oncomplete'];
            if (!window.JDXSLMap) {
                window.JDXSLMap = {
                    element_map: {}
                };
                this._element_attatch_callback();
            }
            this.complete = false;
            this.onload_callback_params = {};
            this.error = {};
            this.naturalWidth = '';
            this.naturalHeight = '';
            this.width = '';
            this.height = '';
            this.elementConstructorTime = String(Date.parse(new Date()));
            this.elementConnectedTime = '';
            this.requestSrcSuccessTime = '';
            this.requestSrcStartTime = '';
            this.canUse = window.XWidget && window.XWidget.canIUse('$Element-Name');
            this.x_className = '';
            this.final_className = '';
            this.element_name = '$Element-Name';
            this.display_style = '';
            this.hybrid_xsl_id = '';
            if (!$ElementName.isAddStyle) {
              var style = document.createElement('style');
              var xsl_style = `{ display:block; overflow:scroll; width: 50px; height: 50px;}`;
              style.textContent = '$Element-Name' + `::-webkit-scrollbar { display: none; width: 0; height: 0; color: transparent; }` + '$Element-Name' + xsl_style;
              document.body.appendChild(style);
              $ElementName.isAddStyle = true;
            }
            const shadowroot = this.attachShadow({
              mode: 'open'
            });
            var a = document.createElement('div');
            a.style.height = '102%';
            shadowroot.appendChild(a);
            this.messageToNative({
              'methodType': 'createXsl'
            });
        }
        connectedCallback() {
            this.elementConnectedTime = String(Date.parse(new Date()));
            this.className = this.finalClassName();
            this._dispatch_native_event();
            var element = window.JDXSLMap.element_map[this.x_className];
            if (element) {
                let src = element['src'];
                if (src) {
                    let params = element['src_params'];
                    this.messageToNative(params);
                }
            }
            this.messageToNative({
              'methodType': 'addXsl'
            })
        }
        
        _dispatch_native_event () {
            var funArr = this.xWidgetExpandFuncEventList;
            funArr.forEach((name) => {
                this._dispatch_native_attatch_event(name);
            })
        }
        
        _dispatch_native_attatch_event (name) {
            var params = {
                'methodType': 'changeXsl',
                'methodName': name,
                'callbackName': 'jd_hybrid_element_' + name,
                'callbackId': this.x_className,
            };
            this.messageToNative(params);
        }
        
        _element_attatch_callback () {
            var funArr = this.xWidgetExpandFuncEventList;
            funArr.forEach((name) => {
                this.connectedFunction(name);
            })
        }
        
        connectedFunction(name) {
          if (name == 'onload') {
              if (!window.jd_hybrid_element_onload) {
                  window.jd_hybrid_element_onload = function (data){
                      var params = {};
                      try {
                          params = JSON.parse(data);
                      } catch(e) {
                          console.log('hybrid onload render state parse err', e);
                      }
                      
                      var obj;
                      var callbackId = params['callbackId'];
                      if (callbackId && window.JDXSLMap.element_map[callbackId]) {
                          obj = window.JDXSLMap.element_map[callbackId]['obj'];
                      }
                      if (obj) {
                          if (params && params.data) {
                              obj.onload_callback_params = params.data;
                              obj.naturalWidth = params.data.naturalWidth;
                              obj.naturalHeight = params.data.naturalHeight;
                              obj.width = params.data.width;
                              obj.height = params.data.height;
                              obj.requestSrcSuccessTime = params.data.requestSrcSuccessTime;
                              obj.requestSrcStartTime = params.data.requestSrcStartTime;
                          }
                          obj.dispatchEvent(new CustomEvent("load", {
                            detail: params,
                            bubbles: true,
                            composed: true //escape shadowDOM
                          }));
                      }
                  };
              }
          }
          if (name == 'onerror') {
              if (!window.jd_hybrid_element_onerror) {
                  window.jd_hybrid_element_onerror = function(data) {
                      var params = {};
                      try {
                          params = JSON.parse(data);
                      } catch(e) {
                          console.log('hybrid onload render state parse err', e);
                      }
                      var obj;
                      var callbackId = params['callbackId'];
                      if (callbackId && window.JDXSLMap.element_map[callbackId]) {
                          obj = window.JDXSLMap.element_map[callbackId]['obj'];
                      }
                      if (obj) {
                          obj.error = params;
                          obj.dispatchEvent(new CustomEvent("error", {
                            detail: params,
                            bubbles: true,
                            composed: true //escape shadowDOM
                          }));
                      }
                  };
              }
          }
          if (name == 'oncomplete') {
              if (!window.jd_hybrid_element_oncomplete) {
                  window.jd_hybrid_element_oncomplete = function (data){
                      var params = {};
                      try {
                          params = JSON.parse(data);
                      } catch(e) {
                          console.log('hybrid onload render state parse err', e);
                      }
                      var obj;
                      var callbackId = params['callbackId'];
                      if (callbackId && window.JDXSLMap.element_map[callbackId]) {
                          obj = window.JDXSLMap.element_map[callbackId]['obj'];
                      }
                      if (obj) {
                          obj.complete = params.data.complete;
                      }
                  };
              }
          }
        }
        disconnectedCallback() {
            this.messageToNative({
              'methodType': 'removeXsl'
            })
        }
        isSupportFuncValid(s) {
            var funArr = this.xWidgetExpandFuncEventList;
            if (funArr.indexOf(s) >= 0) {
                return true;
            }
            return false;
        }
        attributeChangedCallback(name, oldValue, newValue) {
            if (oldValue == newValue) {
                return;
            }
            if (name == 'hidden') {
                if (newValue != null) {
                    this.display_style = this.style.display;
                    this.style.display = 'none';
                } else {
                    this.style.display = this.display_style;
                }
                return;
            } else if (name == 'class') {
                return;
            } else if (name == 'hybrid_xsl_id') {
                this.hybrid_xsl_id = newValue;
                return;
            }
            var params = {
                  'methodType': 'changeXsl',
                  'methodName': name,
                  'oldValue': oldValue,
                  'newValue': newValue
            };
            if (this.isSupportFuncValid(name)) {
                if (newValue) {
                    params = {
                        'methodType': 'changeXsl',
                        'methodName': name,
                        'callbackName': newValue,
                        'callbackId': this.x_className
                    }
                }
                this.messageToNative(params);
            } else if (name == 'src') {
                if (newValue){
                    window.JDXSLMap.element_map[this.x_className] = {
                        'src': newValue,
                        'src_params': params,
                        'obj': this
                    }
                } else {
                    window.JDXSLMap.element_map[this.x_className] = {
                        'obj': this
                    }
                }
                if (oldValue){
                    this.messageToNative(params);
                }
            } else {
                this.messageToNative(params);
            }
        }
    }
    customElements.define('$Element-Name', $ElementName)
})();

    ); // END preprocessorJSCode

    #undef __hyhb_js_func__
    return preprocessorJSCode;
};
