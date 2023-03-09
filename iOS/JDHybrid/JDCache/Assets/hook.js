;(function() {
    (function(self) {
        "use strict";
        var support = {
            searchParams: "URLSearchParams" in self,
            iterable: "Symbol" in self && "iterator" in Symbol,
            blob: "FileReader" in self && "Blob" in self && function() {
                try {
                    new Blob;
                    return true
                } catch (e) {
                    return false
                }
            }(),
            formData: "FormData" in self,
            arrayBuffer: "ArrayBuffer" in self
        };
        if (support.arrayBuffer) {
            var viewClasses = ["[object Int8Array]", "[object Uint8Array]", "[object Uint8ClampedArray]", "[object Int16Array]", "[object Uint16Array]", "[object Int32Array]", "[object Uint32Array]", "[object Float32Array]", "[object Float64Array]"];
            var isDataView = function(obj) {
                return obj && DataView.prototype.isPrototypeOf(obj)
            };
            var isArrayBufferView = ArrayBuffer.isView || function(obj) {
                return obj && viewClasses.indexOf(Object.prototype.toString.call(obj)) > -1
            }
        }
        function normalizeName(name) {
            if (typeof name !== "string") {
                name = String(name)
            }
            var re = new RegExp("[^a-z0-9\\-#$%&'*+.\\^_`|~]", "i");
            if (re.test(name)) {
                throw new TypeError("Invalid character in header field name")
            }
            return name.toLowerCase()
        }
        function normalizeValue(value) {
            if (typeof value !== "string") {
                value = String(value)
            }
            return value
        }
        function iteratorFor(items) {
            var iterator = {
                next: function() {
                    var value = items.shift();
                    return {
                        done: value === undefined,
                        value: value
                    }
                }
            };
            if (support.iterable) {
                iterator[Symbol.iterator] = function() {
                    return iterator
                }
            }
            return iterator
        }
        function Headers(headers) {
            this.map = {};
            if (headers instanceof Headers) {
                headers.forEach(function(value, name) {
                    this.append(name, value)
                }, this)
            } else if (Array.isArray(headers)) {
                headers.forEach(function(header) {
                    this.append(header[0], header[1])
                }, this)
            } else if (headers) {
                Object.getOwnPropertyNames(headers).forEach(function(name) {
                    this.append(name, headers[name])
                }, this)
            }
        }
        Headers.prototype.append = function(name, value) {
            name = normalizeName(name);
            value = normalizeValue(value);
            var oldValue = this.map[name];
            this.map[name] = oldValue ? oldValue + "," + value : value
        };
        Headers.prototype["delete"] = function(name) {
            delete this.map[normalizeName(name)]
        };
        Headers.prototype.get = function(name) {
            name = normalizeName(name);
            return this.has(name) ? this.map[name] : null
        };
        Headers.prototype.has = function(name) {
            return this.map.hasOwnProperty(normalizeName(name))
        };
        Headers.prototype.set = function(name, value) {
            this.map[normalizeName(name)] = normalizeValue(value)
        };
        Headers.prototype.forEach = function(callback, thisArg) {
            for (var name in this.map) {
                if (this.map.hasOwnProperty(name)) {
                    callback.call(thisArg, this.map[name], name, this)
                }
            }
        };
        Headers.prototype.keys = function() {
            var items = [];
            this.forEach(function(value, name) {
                items.push(name)
            });
            return iteratorFor(items)
        };
        Headers.prototype.values = function() {
            var items = [];
            this.forEach(function(value) {
                items.push(value)
            });
            return iteratorFor(items)
        };
        Headers.prototype.entries = function() {
            var items = [];
            this.forEach(function(value, name) {
                items.push([name, value])
            });
            return iteratorFor(items)
        };
        if (support.iterable) {
            Headers.prototype[Symbol.iterator] = Headers.prototype.entries
        }
        function consumed(body) {
            if (body.bodyUsed) {
                return Promise.reject(new TypeError("Already read"))
            }
            body.bodyUsed = true
        }
        function fileReaderReady(reader) {
            return new Promise(function(resolve, reject) {
                reader.onload = function() {
                    resolve(reader.result)
                };
                reader.onerror = function() {
                    reject(reader.error)
                }
            })
        }
        function readBlobAsArrayBuffer(blob) {
            var reader = new FileReader;
            var promise = fileReaderReady(reader);
            reader.readAsArrayBuffer(blob);
            return promise
        }
        function readBlobAsText(blob) {
            var reader = new FileReader;
            var promise = fileReaderReady(reader);
            reader.readAsText(blob);
            return promise
        }
        function readArrayBufferAsText(buf) {
            var view = new Uint8Array(buf);
            var chars = new Array(view.length);
            for (var i = 0; i < view.length; i++) {
                chars[i] = String.fromCharCode(view[i])
            }
            return chars.join("")
        }
        function bufferClone(buf) {
            if (buf.slice) {
                return buf.slice(0)
            } else {
                var view = new Uint8Array(buf.byteLength);
                view.set(new Uint8Array(buf));
                return view.buffer
            }
        }
        function Body() {
            this.bodyUsed = false;
            this._initBody = function(body) {
                this._bodyInit = body;
                if (!body) {
                    this._bodyText = ""
                } else if (typeof body === "string") {
                    this._bodyText = body
                } else if (support.blob && Blob.prototype.isPrototypeOf(body)) {
                    this._bodyBlob = body
                } else if (support.formData && FormData.prototype.isPrototypeOf(body)) {
                    this._bodyFormData = body
                } else if (support.searchParams && URLSearchParams.prototype.isPrototypeOf(body)) {
                    this._bodyText = body.toString()
                } else if (support.arrayBuffer && support.blob && isDataView(body)) {
                    this._bodyArrayBuffer = bufferClone(body.buffer);
                    this._bodyInit = new Blob([this._bodyArrayBuffer])
                } else if (support.arrayBuffer && (ArrayBuffer.prototype.isPrototypeOf(body) || isArrayBufferView(body))) {
                    this._bodyArrayBuffer = bufferClone(body)
                } else {
                    throw new Error("unsupported BodyInit type")
                }
                if (!this.headers.get("content-type")) {
                    if (typeof body === "string") {
                        this.headers.set("content-type", "text/plain;charset=UTF-8")
                    } else if (this._bodyBlob && this._bodyBlob.type) {
                        this.headers.set("content-type", this._bodyBlob.type)
                    } else if (support.searchParams && URLSearchParams.prototype.isPrototypeOf(body)) {
                        this.headers.set("content-type", "application/x-www-form-urlencoded;charset=UTF-8")
                    }
                }
            };
            if (support.blob) {
                this.blob = function() {
                    var rejected = consumed(this);
                    if (rejected) {
                        return rejected
                    }
                    if (this._bodyBlob) {
                        return Promise.resolve(this._bodyBlob)
                    } else if (this._bodyArrayBuffer) {
                        return Promise.resolve(new Blob([this._bodyArrayBuffer]))
                    } else if (this._bodyFormData) {
                        throw new Error("could not read FormData body as blob")
                    } else {
                        return Promise.resolve(new Blob([this._bodyText]))
                    }
                };
                this.arrayBuffer = function() {
                    if (this._bodyArrayBuffer) {
                        return consumed(this) || Promise.resolve(this._bodyArrayBuffer)
                    } else {
                        return this.blob().then(readBlobAsArrayBuffer)
                    }
                }
            }
            this.text = function() {
                var rejected = consumed(this);
                if (rejected) {
                    return rejected
                }
                if (this._bodyBlob) {
                    return readBlobAsText(this._bodyBlob)
                } else if (this._bodyArrayBuffer) {
                    return Promise.resolve(readArrayBufferAsText(this._bodyArrayBuffer))
                } else if (this._bodyFormData) {
                    throw new Error("could not read FormData body as text")
                } else {
                    return Promise.resolve(this._bodyText)
                }
            };
            if (support.formData) {
                this.formData = function() {
                    return this.text().then(decode)
                }
            }
            this.json = function() {
                return this.text().then(JSON.parse)
            };
            return this
        }
        var methods = ["DELETE", "GET", "HEAD", "OPTIONS", "POST", "PUT"];
        function normalizeMethod(method) {
            var upcased = method.toUpperCase();
            return methods.indexOf(upcased) > -1 ? upcased : method
        }
        function Request(input, options) {
            options = options || {};
            var body = options.body;
            if (input instanceof Request) {
                if (input.bodyUsed) {
                    throw new TypeError("Already read")
                }
                this.url = input.url;
                this.credentials = input.credentials;
                if (!options.headers) {
                    this.headers = new Headers(input.headers)
                }
                this.method = input.method;
                this.mode = input.mode;
                if (!body && input._bodyInit != null) {
                    body = input._bodyInit;
                    input.bodyUsed = true
                }
            } else {
                this.url = String(input)
            }
            this.credentials = options.credentials || this.credentials || "omit";
            if (options.headers || !this.headers) {
                this.headers = new Headers(options.headers)
            }
            this.method = normalizeMethod(options.method || this.method || "GET");
            this.mode = options.mode || this.mode || null;
            this.referrer = null;
            if ((this.method === "GET" || this.method === "HEAD") && body) {
                throw new TypeError("Body not allowed for GET or HEAD requests")
            }
            this._initBody(body)
        }
        Request.prototype.clone = function() {
            return new Request(this, {
                body: this._bodyInit
            })
        };
        function decode(body) {
            var form = new FormData;
            body.trim().split("&").forEach(function(bytes) {
                if (bytes) {
                    var split = bytes.split("=");
                    var reg = new RegExp("\\+", "g");
                    var name = split.shift().replace(reg, " ");
                    var value = split.join("=").replace(reg, " ");
                    form.append(decodeURIComponent(name), decodeURIComponent(value))
                }
            });
            return form
        }
        function parseHeaders(rawHeaders) {
            var headers = new Headers;
            var parsereg = new RegExp("\\r?\\n[\\t ]+", "g");
            var preProcessedHeaders = rawHeaders.replace(parsereg, " ");
            var parsereg2 = new RegExp("\\r?\\n");
            preProcessedHeaders.split(parsereg2).forEach(function(line) {
                var parts = line.split(":");
                var key = parts.shift().trim();
                if (key) {
                    var value = parts.join(":").trim();
                    headers.append(key, value)
                }
            });
            return headers
        }
        Body.call(Request.prototype);
        function Response(bodyInit, options) {
            if (!options) {
                options = {}
            }
            this.type = "default";
            this.status = options.status === undefined ? 200 : options.status;
            this.ok = this.status >= 200 && this.status < 300;
            this.statusText = "statusText" in options ? options.statusText : "OK";
            this.headers = new Headers(options.headers);
            this.url = options.url || "";
            this._initBody(bodyInit)
        }
        Body.call(Response.prototype);
        Response.prototype.clone = function() {
            return new Response(this._bodyInit, {
                status: this.status,
                statusText: this.statusText,
                headers: new Headers(this.headers),
                url: this.url
            })
        };
        Response.error = function() {
            var response = new Response(null, {
                status: 0,
                statusText: ""
            });
            response.type = "error";
            return response
        };
        var redirectStatuses = [301, 302, 303, 307, 308];
        Response.redirect = function(url, status) {
            if (redirectStatuses.indexOf(status) === -1) {
                throw new RangeError("Invalid status code")
            }
            return new Response(null, {
                status: status,
                headers: {
                    location: url
                }
            })
        };
        self.Headers = Headers;
        self.Request = Request;
        self.Response = Response;
        self.fetch = function(input, init) {
            return new Promise(function(resolve, reject) {
                var request = new Request(input, init);
                var xhr = new XMLHttpRequest;
                xhr.onload = function() {
                    var options = {
                        status: xhr.status,
                        statusText: xhr.statusText,
                        headers: parseHeaders(xhr.getAllResponseHeaders() || "")
                    };
                    options.url = "responseURL" in xhr ? xhr.responseURL : options.headers.get("X-Request-URL");
                    var body = "response" in xhr ? xhr.response : xhr.responseText;
                    resolve(new Response(body, options))
                };
                xhr.onerror = function() {
                    reject(new TypeError("Network request failed"))
                };
                xhr.ontimeout = function() {
                    reject(new TypeError("Network request failed"))
                };
                xhr.open(request.method, request.url, true);
                if (request.credentials === "include") {
                    xhr.withCredentials = true
                } else if (request.credentials === "omit") {
                    xhr.withCredentials = false
                }
                if ("responseType" in xhr && support.blob) {
                    xhr.responseType = "blob"
                }
                request.headers.forEach(function(value, name) {
                    xhr.setRequestHeader(name, value)
                });
                xhr.send(typeof request._bodyInit === "undefined" ? null : request._bodyInit)
            })
        };
        self.fetch.polyfill = true
    })(typeof self !== "undefined" ? self : this);
    window.jd_realxhr_callback = function(id, message) {
        var hookAjax = window.JDAjax.hookedXHR[id];
        if (hookAjax) {
            var statusCode = message.status;
            var responseText = !!message.data ? message.data : "";
            var responseHeaders = message.headers;
            window.JDAjax.nativeCallback(id, statusCode, responseText, responseHeaders, null)
        }
    };
    window.JDAjax = {
        hookedXHR: {},
        hookAjax: _JDHookAjax,
        nativeCallback: nativeCallback
    };
    function nativeCallback(xhrId, statusCode, responseText, responseHeaders, error) {
        var xhr = window.JDAjax.hookedXHR[xhrId];
        if (xhr.isAborted) {
            xhr.readyState = 1
        } else {
            xhr.status = statusCode;
            xhr.responseText = responseText;
            xhr.readyState = 4;
            xhr.jdResponseHeaders = responseHeaders
        }
        if (xhr.readyState >= 3) {
            if (xhr.status >= 200 && xhr.status < 300) {
                xhr.statusText = "OK"
            } else {
                xhr.statusText = "Fail"
            }
        }
        if (xhr.onreadystatechange) {
            xhr.onreadystatechange()
        }
        if (xhr.readyState == 4) {
            if (xhr.statusText == "OK") {
                if (xhr.onload) {
                    xhr.onload()
                }
            } else {
                if (xhr.onerror) {
                    xhr.onerror()
                }
            }
            if (xhr.onloadend) {
                xhr.onloadend()
            }
        }
        window.JDAjax.hookedXHR[xhrId] = undefined
    }
    window.JDAjax.hookAjax({
        setRequestHeader: function(args, xhr) {
            if (!this.JDHeaders) {
                this.JDHeaders = {}
            }
            this.JDHeaders[args[0]] = args[1]
        },
        getAllResponseHeaders: function(arg, xhr) {
            var headers = this.jdResponseHeaders;
            if (headers) {
                if (typeof headers === "object") {
                    var result = "";
                    for (var key in headers) {
                        result = result + key + ":" + headers[key] + "\r\n"
                    }
                    return result
                }
                return headers
            }
        },
        getResponseHeader: function(arg, xhr) {
            for (var key in this.jdResponseHeaders) {
                if (key.toLowerCase() == arg[0].toLowerCase()) {
                    return this.jdResponseHeaders[key]
                }
            }
            return null
        },
        open: function(arg, xhr) {
            this.jdOpenArgs = arg
        },
        send: function(arg, xhr) {
            this.isAborted = false;
            if (arg[0] instanceof Blob && (this.jdOpenArgs[0].toUpperCase() === "POST" || this.jdOpenArgs[0].toUpperCase() === "PUT")) {
                var blob = arg[0];
                var reader = new FileReader;
                reader.readAsArrayBuffer(blob);
                this.setRequestHeader("content-type", blob.type);
                var that = this;
                reader.onload = function(e) {
                    that.send(reader.result)
                };
                return true
            } else if (arg[0] instanceof FormData) {
                if (JDHybridHandlerFormdata(this.jdOpenArgs[1], arg[0], this)) {
                    return true
                }
            }
        },
        abort: function(arg, xhr) {
            if (this.jdOpenArgs[0].toUpperCase() === "POST" || this.jdOpenArgs[0].toUpperCase() === "PUT") {
                if (xhr.onabort) {
                    xhr.onabort()
                }
                return true
            }
        }
    });
    function _JDHookAjax(proxy) {
        window._JDXHRealxhr = window._JDXHRealxhr || XMLHttpRequest;
        XMLHttpRequest = function() {
            var xhr = new window._JDXHRealxhr;
            Object.defineProperty(this, "xhr", {
                value: xhr
            })
        };
        XMLHttpRequest.UNSENT = 0;
        XMLHttpRequest.OPENED = 1;
        XMLHttpRequest.HEADERS_RECEIVED = 2;
        XMLHttpRequest.LOADING = 3;
        XMLHttpRequest.DONE = 4;
        XMLHttpRequest.prototype.UNSENT = XMLHttpRequest.UNSENT;
        XMLHttpRequest.prototype.OPENED = XMLHttpRequest.OPENED;
        XMLHttpRequest.prototype.HEADERS_RECEIVED = XMLHttpRequest.HEADERS_RECEIVED;
        XMLHttpRequest.prototype.LOADING = XMLHttpRequest.LOADING;
        XMLHttpRequest.prototype.DONE = XMLHttpRequest.DONE;
        XMLHttpRequest.prototype.readyState = XMLHttpRequest.UNSENT;
        XMLHttpRequest.prototype.responseText = "";
        XMLHttpRequest.prototype.responseXML = null;
        XMLHttpRequest.prototype.status = 0;
        XMLHttpRequest.prototype.statusText = "";
        XMLHttpRequest.prototype.priority = "NORMAL";
        XMLHttpRequest.prototype.onreadystatechange = null;
        XMLHttpRequest.onreadystatechange = null;
        XMLHttpRequest.onopen = null;
        XMLHttpRequest.onsend = null;
        XMLHttpRequest.onabort = null;
        var prototype = window._JDXHRealxhr.prototype;
        for (var attr in prototype) {
            var type = "";
            try {
                type = typeof prototype[attr]
            } catch (e) {}
            if (type === "function") {
                XMLHttpRequest.prototype[attr] = jdhookfunc(attr)
            } else {
                Object.defineProperty(XMLHttpRequest.prototype, attr, {
                    get: getFactory(attr),
                    set: setFactory(attr),
                    enumerable: true
                })
            }
        }
        function getFactory(attr) {
            return function() {
                var v = this.hasOwnProperty(attr + "_") ? this[attr + "_"] : this.xhr[attr];
                var attrGetterHook = (proxy[attr] || {})["getter"];
                return attrGetterHook && attrGetterHook(v, this) || v
            }
        }
        function setFactory(attr) {
            return function(v) {
                var xhr = this.xhr;
                var that = this;
                var hook = proxy[attr];
                if (typeof hook === "function") {
                    xhr[attr] = function() {
                        hook.call(that, xhr) || v.apply(xhr, arguments)
                    }
                } else {
                    var attrSetterHook = (hook || {})["setter"];
                    v = attrSetterHook && attrSetterHook(v, that) || v;
                    xhr[attr] = v;
                    this[attr + "_"] = v
                }
            }
        }
        function jdhookfunc(func) {
            return function() {
                var args = [].slice.call(arguments);
                if (proxy[func]) {
                    var result = proxy[func].call(this, args, this.xhr);
                    if (result) {
                        return result
                    }
                }
                return this.xhr[func].apply(this.xhr, args)
            }
        }
        return window._JDXHRealxhr
    }
    function JDHybridPostMethodToIos(params) {
        window.webkit.messageHandlers.JDCache.postMessage({
            method: "fetchPostReuqestWithParams",
            params: params
        })
    }
    function JDHybridHandlerFormdata(url, formData, xhr) {
        var isHasBlob = false;
        var formDataMap = {};
        var totalCount = 0;
        var workCount = 0;
        function HandlerFormdata() {
            if (!isHasBlob)
                return;
            var xhrId = null;
            if (xhr !== null) {
                xhrId = "xhrId" + (new Date).getTime();
                while (window.JDAjax.hookedXHR[xhrId] != null) {
                    xhrId = xhrId + "0"
                }
                window.JDAjax.hookedXHR[xhrId] = xhr
            }
            JDHybridPostMethodToIos({
                url: url,
                body: JSON.stringify(formDataMap),
                type: "formData",
                id: xhrId,
                headers: xhr.JDHeaders,
            })
        }
        var ent = formData.entries();
        var item = ent.next();
        while (!item.done) {
            totalCount++;
            var pair = item.value;
            item = ent.next();
            let value = pair[1];
            if (value instanceof Blob) {
                var itemMap = {};
                var blobKey = pair[0];
                var reader = new FileReader;
                reader.readAsDataURL(value);
                let that = this;
                reader.onload = function(e) {
                    workCount++;
                    var string = reader.result;
                    if (!string.startsWith("data:image/png;base64,")) {
                        let search = ";base64,";
                        let start = string.indexOf(search);
                        if (start != -1) {
                            string = "data:image/png;base64," + string.substring(start + search.length)
                        }
                    }
                    itemMap["data"] = string;
                    formDataMap[blobKey] = itemMap;
                    if (workCount === totalCount && item.done) {
                        HandlerFormdata()
                    }
                };
                itemMap["type"] = value.type;
                if (value instanceof File) {
                    itemMap["name"] = value.name;
                    itemMap["size"] = value.size;
                    itemMap["lastModified"] = value.lastModified;
                    itemMap["lastModifiedDate"] = value.lastModified
                }
                isHasBlob = true
            } else {
                formDataMap[pair[0]] = value;
                workCount++;
                if (workCount === totalCount && item.done) {
                    HandlerFormdata()
                }
            }
        }
        return isHasBlob
    }
    window.jdUrlschemeSendBeacon = window.jdUrlschemeSendBeacon || navigator.sendBeacon;
    navigator.sendBeacon = function() {
        var args = Array.prototype.slice.call(arguments);
        if (args[1] instanceof Blob) {
            let blob = args[1];
            var reader = new FileReader;
            reader.readAsArrayBuffer(blob);
            var that = this;
            reader.onload = function(e) {
                that.sendBeacon(args[0], reader.result);
            };
            return true
        } else if (args[1] instanceof FormData) {
            if (JDHybridHandlerFormdata(args[0], args[1], null)) {
                return true
            }
        }
        if (window.jdUrlschemeSendBeacon) {
            return window.jdUrlschemeSendBeacon.apply(this, arguments)
        }
    }
})();
