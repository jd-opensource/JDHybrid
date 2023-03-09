;(function() {
    var cookieOriginSetter = document.__lookupSetter__("cookie"),
        cookieOriginGetter = document.__lookupGetter__("cookie");
    var HybridUpdateCookies;
    if (cookieOriginSetter && cookieOriginGetter) {
        Object.defineProperty(document, "cookie", {
            set: function(cookstr) {
                if (typeof cookstr !== "string") {
                    return
                }
                var message = {};
                message["cookie"] = cookstr;
                message["url"] = document.location.href;
                if (webkit && webkit.messageHandlers &&
                    webkit.messageHandlers.JDCache &&
                    webkit.messageHandlers.JDCache.postMessage) {
                    webkit.messageHandlers.JDCache.postMessage({
                        method: "syncCookie",
                        params: message
                    })
                }
                cookieOriginSetter.apply(document, [cookstr])
            },
            get: function() {
                return cookieOriginGetter.apply(document, [])
            },
            configurable: false
        })
    } else {
        if (window.SHOULDHYBRIDDORWC) {
            var cookieNameMap = {
                Version: "version",
                Name: "name",
                Value: "value",
                MaxAge: "maxAge",
                MaxAgeDate: "maxAgeDate",
                ExpiresDate: "expiresDate",
                Domain: "domain",
                Path: "path",
                Secure: "secure",
                HttpOnly: "httpOnly"
            };
            function idIPAddress(address) {
                return /^(d+).(d+).(d+).(d+)$/.test(address)
            }
            function isRegExp(value, rule) {
                if (rule && typeof rule === "string" && rule.length > 0) {
                    var reg = new RegExp(rule + "$");
                    return reg.test(value)
                } else {
                    return false
                }
            }
            function hasPrefix(value, rule) {
                if (rule.length > 0) {
                    var reg = new RegExp("^" + rule);
                    return reg.test(value)
                } else {
                    return false
                }
            }
            function domianMatch(value) {
                var hostMatch = value && isRegExp(document.location.hostname.toLowerCase(), value);
                var isRootDomain = false;
                var p = value.split(".");
                var q = p.length;
                if (q == 2 || q == 3 && p[1] === "com") {
                    isRootDomain = true
                }
                return hostMatch && !isRootDomain
            }
            function getPath() {
                var k = document.location.pathname;
                var l = k.lastIndexOf("/");
                var result = k.substring(0, l);
                if (result.length == 0) {
                    return "/"
                } else {
                    return result
                }
            }
            var cookieStore = [];
            function isCookieExpired(cookieObj) {
                var l = typeof cookieObj[cookieNameMap.MaxAgeDate] == "object";
                if (l && cookieObj[cookieNameMap.MaxAge] <= 0) {
                    return true
                } else {
                    if (l) {
                        return cookieObj[cookieNameMap.MaxAgeDate] < new Date
                    } else {
                        if (typeof cookieObj[cookieNameMap.ExpiresDate] == "object") {
                            return cookieObj[cookieNameMap.ExpiresDate] < new Date
                        } else {
                            return false
                        }
                    }
                }
            }
            function getCookieStr() {
                var length = cookieStore.length,
                    index = 0,
                    item,
                    result = [];
                for (; index < length; index++) {
                    item = cookieStore[index];
                    if (!isCookieExpired(item)) {
                        result.push(item[cookieNameMap.Name] + "=" + item[cookieNameMap.Value])
                    }
                }
                return result.join("; ")
            }
            function updateAllCookie(cookieObj) {
                var length = cookieStore.length,
                    index = 0,
                    item,
                    result = [];
                for (; index < length; index++) {
                    item = cookieStore[index];
                    if (!(item[cookieNameMap.Name] === cookieObj[cookieNameMap.Name] && item[cookieNameMap.Path] === cookieObj[cookieNameMap.Path] && item[cookieNameMap.Domain] === cookieObj[cookieNameMap.Domain])) {
                        result.push(item)
                    }
                }
                cookieStore = result
            }
            function updateCookie(cookieObj) {
                var cookiePath = cookieObj[cookieNameMap.Path];
                var isPrefixWithCookiePath = hasPrefix(getPath(), cookiePath) || hasPrefix(document.location.pathname, cookiePath);
                if (!isPrefixWithCookiePath) {
                    return
                }
                updateAllCookie(cookieObj);
                cookieStore.unshift(cookieObj)
            }
            function parseOthers(name, value, cookieObj) {
                var name = name.toLowerCase();
                var o;
                value = value.trim();
                switch (name) {
                case "expires":
                    {
                        var date = new Date(value);
                        if (!isNaN(date.getTime())) {
                            cookieObj[cookieNameMap.ExpiresDate] = date
                        }
                    };
                    break;
                case "max-age":
                    {
                        if (!isNaN(value)) {
                            var p = Number(parseInt(value));
                            var q = new Date;
                            q.setTime(q.getTime() + p * 1e3);
                            cookieObj[cookieNameMap.MaxAge] = p;
                            cookieObj[cookieNameMap.MaxAgeDate] = q
                        }
                    };
                    break;
                case "domain":
                    {
                        hostName = document.location.hostname.toLowerCase();
                        if (idIPAddress(hostName)) {
                            cookieObj[cookieNameMap.Domain] = hostName
                        } else {
                            if (value.length > 0) {
                                if (value.charAt(0) != ".") {
                                    value = "." + value
                                }
                                if (isRegExp(hostName, value)) {
                                    var p = value.split(".");
                                    var q = p.length;
                                    if (q == 2 || q == 3 && p[1] === "com") {
                                        cookieObj[cookieNameMap.Domain] = "." + hostName
                                    } else {
                                        cookieObj[cookieNameMap.Domain] = value
                                    }
                                } else {
                                    cookieObj[cookieNameMap.Domain] = "." + hostName
                                }
                            }
                        }
                    };
                    break;
                case "path":
                    {
                        if (value.length == 0 || value.charAt(0) !== "/") {
                            cookieObj[cookieNameMap.Path] = getPath()
                        } else {
                            cookieObj[cookieNameMap.Path] = value
                        }
                    };
                    break;
                case "secure":
                    {
                        cookieObj[cookieNameMap.Secure] = true
                    };
                    break;
                default:
                    {}break
                }
            }
            function saveCookieOtherPart(cookie, cookieObj) {
                var name,
                    value = "";
                var item;
                var length = cookie.length;
                for (var index = 0; index < length; index++) {
                    item = cookie[index];
                    var splitObj = item.split("=");
                    name = splitObj[0];
                    if (splitObj.length > 1) {
                        value = splitObj[1]
                    }
                    name = name.trim();
                    if (name.length == 0) {
                        continue
                    }
                    value = value.trim();
                    if (name.toLowerCase() === "httponly") {
                        return false
                    } else if (name.toLowerCase() === "path") {
                        var isPrefixWithCookiePath = hasPrefix(getPath(), value) || hasPrefix(document.location.pathname, value);
                        if (!isPrefixWithCookiePath) {
                            return false
                        } else {
                            parseOthers(name, value, cookieObj)
                        }
                    } else if (name.toLowerCase() === "domain") {
                        if (!domianMatch(value)) {
                            return false
                        } else {
                            parseOthers(name, value, cookieObj)
                        }
                    } else {
                        parseOthers(name, value, cookieObj)
                    }
                }
                if (typeof cookieObj["domain"] == "undefined") {
                    cookieObj["domain"] = document.location.hostname.toLowerCase()
                }
                return true
            }
            function saveCookieNameAndValue(cookie, cookieObj) {
                cookie = cookie.trim();
                if (cookie.length <= 0) {
                    return false
                }
                var eq_idx = cookie.indexOf("=");
                if (eq_idx < 0) {
                    return false
                }
                var key = cookie.substr(0, eq_idx).trim();
                var val = cookie.substr(++eq_idx, cookie.length).trim();
                if ('"' == val[0]) {
                    val = val.slice(1, -1)
                }
                cookieObj[cookieNameMap.Name] = key;
                cookieObj[cookieNameMap.Value] = val;
                return true
            }
            function saveCookieStr(cookieStr) {
                var hostname = document.location.hostname.toLowerCase(),
                    cookie = {
                        name: "",
                        value: "",
                        secure: false,
                        httpOnly: false,
                        path: getPath(),
                        domain: hostname
                    };
                var cookieSplit = cookieStr.split(";");
                if (cookieSplit.length > 0) {
                    var name = cookieSplit[0];
                    if (!saveCookieNameAndValue(name, cookie)) {
                        return null
                    }
                    if (!saveCookieOtherPart(cookieSplit.slice(1, cookieSplit.length), cookie)) {
                        return null
                    }
                    if (isCookieExpired(cookie)) {
                        updateAllCookie(cookie)
                    } else {
                        updateCookie(cookie)
                    }
                    return cookie
                }
                return null
            }
            var getCookieSuc = false;
            function getCurrentCookie() {
                var protocol = document.location.protocol,
                    host = document.location.host;
                if (protocol && host) {
                    try {
                        doCookieSyncRequest(protocol + "//" + host + "/" + requestTK + "/?" + document.location.href)
                    } catch (ex) {}
                }
            }
            function doCookieSyncRequest(url) {
                var xmlHttprequest = new XMLHttpRequest;
                xmlHttprequest.open("GET", url, false);
                xmlHttprequest.setRequestHeader("Content-Type", "text/plain");
                xmlHttprequest.send(null);
                if (xmlHttprequest.status == 200) {
                    var result = xmlHttprequest.responseText;
                    if (!result || result.length == 0) {
                        return
                    }
                    try {
                        var cookieJSON = JSON.parse(result);
                        if (typeof cookieJSON === "object") {
                            getCookieSuc = true;
                            saveCookies(cookieJSON)
                        }
                    } catch (ex) {}
                }
            }
            function saveCookies(cookies) {
                cookieStore = [];
                var index = 0,
                    length = cookies.length,
                    item;
                for (; index < length; index++) {
                    item = cookies[index];
                    if (typeof item[cookieNameMap.ExpiresDate] != "undefined") {
                        item[cookieNameMap.ExpiresDate] = new Date(item[cookieNameMap.ExpiresDate])
                    }
                    cookieStore.push(item)
                }
            }
            function updateIfameCookie(message) {
                var iframes = document.querySelectorAll("iframe");
                if (!iframes) {
                    return
                }
                var length = iframes.length;
                var index;
                var iframe;
                if (length > 0) {
                    for (index = 0; index < length; index++) {
                        iframe = iframes[index];
                        iframe.contentWindow.postMessage(message, "*")
                    }
                }
            }
            function updateCookies(cookies, host) {
                for (var i = 0; i < cookies.length; i++) {
                    var item = cookies[i],
                        domain;
                    if (domianMatch(item[cookieNameMap.Domain])) {
                        updateCookie(item)
                    }
                }
            }
            if (top != this) {
                window.addEventListener("message", function(event) {
                    var data = event["data"];
                    if (typeof data === "object") {
                        if (typeof data["host"] === "string" && data["hybrid_data"]) {
                            updateCookies(data["hybrid_data"], data["host"]);
                            updateIfameCookie(data);
                            if (event.stopImmediatePropagation) {
                                event.stopImmediatePropagation()
                            }
                            return false
                        }
                    }
                }, true)
            } else {
                HybridUpdateCookies = function(cookies, host, tk) {
                    if (kthybrid === tk) {
                        updateCookies(cookies, host);
                        var message = {};
                        message["host"] = host;
                        message["hybrid_data"] = cookies;
                        updateIfameCookie(message)
                    }
                }
            }
            getCurrentCookie();
            if (getCookieSuc) {
                Object.defineProperty(document, "cookie", {
                    get: function() {
                        var cookieStr = getCookieStr();
                        return cookieStr
                    },
                    set: function(cookieStr) {
                        if (typeof cookieStr !== "string") {
                            return
                        }
                        saveCookieStr(cookieStr);
                        var message = {};
                        message["cookie"] = cookieStr;
                        message["url"] = document.location.href;
                        if (webkit && webkit.messageHandlers && webkit.messageHandlers.JDCache && webkit.messageHandlers.JDCache.postMessage) {
                            webkit.messageHandlers.JDCache.postMessage({
                                method: "syncCookie",
                                params: message
                            })
                        }
                    },
                    configurable: false
                })
            }
        }
    }
})();
