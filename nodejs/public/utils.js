function urlhost(urlStr) {
   var url = new URL(urlStr);
   var host = url.protocol + '//' + url.host
   return host + '/'
}