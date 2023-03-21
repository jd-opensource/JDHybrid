const puppeteer = require('puppeteer')
const nanoid = require('nanoid').nanoid
const path = require('path')
const fs = require("fs-extra");
const cookie = require('cookie')
async function urlParse(ctx) {
    const browser = await puppeteer.launch({
        ignoreHTTPSErrors: true,
        args: [
            '--disable-gpu',
            '--no-sandbox',
            '--disable-setuid-sandbox',
        ],
    });
    var map = {}
    ctx.request.url.split('?')[1].split('&').forEach(element => {
        var array = element.split('=')
        map[array[0]] = decodeURIComponent(array[1])
    });
    var url = map['url']
    var ua = map['user-agent']&&map['user-agent'].length > 0?map['user-agent']:'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.0 Safari/537.36'
    const page = await browser.newPage();
    await page.setDefaultTimeout(1000 * 60);
    const viewSize = { width: 400, height: 700 };
    await page.setViewport(viewSize);
    await page.setUserAgent(ua)
    await page.setCacheEnabled(false)
    if (map['cookie'] && map['cookie'].length > 0) {
        const cookieObject = []
        const cookieJSON = cookie.parse(map['cookie'])
        for (let key in cookieJSON) {
            cookieObject.push({
                name: key,
                value: cookieJSON[key],
                url: url
            })
        }
        if (cookieObject.length > 0) await page.setCookie(...cookieObject)
    }

    // 请求拦截资源集合
    const resourceUrls = [];

    const requestUrlMap = {};
    let urlIndex = 0

    page.on('request', request => {
        const resourceType = request.resourceType();
        if (
            ['media', 'image', 'stylesheet', 'font', 'script'].indexOf(
                resourceType,
            ) !== -1
        ) {
            const url = request.url();
            const noSearchUrl = url.split('?')[0];
            // 过滤base64
            if (url.startsWith('data:')) return;
            // 过滤非js请求
            if (resourceType === 'script' && !noSearchUrl.endsWith('.js')) return;
            // 过滤非css请求
            if (resourceType === 'stylesheet' && !noSearchUrl.endsWith('.css')) return;
            // 过滤非图片请求
            if (
                resourceType === 'image' &&
                !noSearchUrl.match(/.(png|jpe?g|svg|gif)$/g) // webp不添加
            ) return;

            const resource = {
                url: request.url(),
                resourceType: resourceType,
            };

            resourceUrls.push(resource);
            requestUrlMap[url] = urlIndex
            urlIndex++
        }
    })
        .on('pageerror', ({ message }) => console.log(`Puppeteer: page_error ${message}`))
        .on('requestfailed', request => {
            console.log(`Puppeteer: request_failed ${request.failure().errorText} ${request.url()}`)
        })
    page.on('response', response => {
        const url = response.url()
        const index = requestUrlMap[url]
        if (typeof index === 'number') {
            response.text().then(d => {
                resourceUrls[index].size = d.length
            })
        }
    })

    try {
        await page.goto(url, { timeout: 1000 * 30 });
        // 设置页面解析等待时间，默认为onLoad
        await page.waitForTimeout(3 * 1000)
    } catch (err) {
        browser.close();
        throw err
    }

    // 保存快照
    const screenshotName = `${nanoid(10)}.png`;
    const screenshotPath = `${ ctx.origin }/uploads/${ screenshotName }`
    var dir = `${__dirname}/../public/uploads`
    if (!fs.existsSync(dir)) {
        console.log(dir)
        fs.mkdir(dir, {recursive: true}, (err) => {

        })
    } 
    await page.screenshot({ path: `${__dirname}/../public/uploads/${ screenshotName}` });
    const htmlStr = await page.content()
    resourceUrls.unshift({
        url,
        resourceType: 'html',
        size: htmlStr.length,
    })
    browser.close();
    ctx.body = {
        screenshotDesc: {
            fileName: screenshotName,
            filePath: screenshotPath,
        },
        resource: resourceUrlsProcess(resourceUrls)
    }
}

function resourceUrlsProcess(resourceUrls) {
    resourceUrls = resourceUrls.filter(d => { // 过滤未拉取到大小的资源
        if (d.size === 0 || typeof d.size !== 'number') return false
        return true
    }).map(d => { // 计算文本文件gzip后的大小
        if (['stylesheet', 'html', 'script'].indexOf(d.resourceType) !== -1) {
            return Object.assign({}, d, { size: Math.floor(d.size * 0.3) })
        }
        return d
    })
    return resourceUrls.length > 40 ? resourceUrls.slice(0, 40) : resourceUrls
}
module.exports = urlParse;