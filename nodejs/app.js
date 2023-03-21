const koa = require('koa')
const koaBody = require('koa-body')
const Router = require('koa-router')
const path = require('path')
const send = require('koa-send');
const fs = require("fs");
const router = new Router()
const app = new koa()
const crypto = require('crypto');
const urlParse = require("./src/urlParse")
const zipCreate = require("./src/zipCreate");
process.on('uncaughtException', function (err) {
    console.log(err)
})

app.use(koaBody({
    // 支持文件格式
    multipart: true,
    formidable: {
        uploadDir: path.join(__dirname, '/public/uploads'),
        // 保留文件扩展名
        keepExtensions: true,
        maxFileSize: 2000 * 1024 * 1024, //最大2G
    }
}));
async function delayer(time = 2000) {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve();
        }, time);
    });
}

async function readAndWrite(ctx) {
    return new Promise((resolve) => {
        var basename;
        var hash = crypto.createHash('md5');
        var date = Date.parse(new Date()) / 1000
        if (ctx.request.body.length > 2) {
            var buffer = new Buffer('BUFFER OBJECT');
            hash.update(ctx.request.body, 'utf8');
            hash.update('' + date, 'utf8')
            basename = 'upload_' + hash.digest('hex');
            fs.writeFileSync(`public/uploads/${basename}`, buffer);
            resolve(basename);
        } else {
            var params = [];
            ctx.req.addListener('data', (chunk) => {
                params.push(chunk);
                hash.update(chunk, 'utf8');
            })
            ctx.req.addListener('end', (chunk) => {
                let buffer = Buffer.concat(params);
                hash.update('' + date, 'utf8')
                basename = 'upload_' + hash.digest('hex');
                fs.writeFileSync(`public/uploads/${basename}`, buffer);
                resolve(basename);
            })
        }
    });
}


router.post('/upload', async ctx => {
    var basename
    var contentType = ctx.request.headers['content-type']
    if (contentType && contentType.indexOf('multipart/form-data;') != -1) {
        try {
            const file = ctx.request.files.file
            basename = path.basename(file.path)
            ctx.body = { "url": `${ctx.origin}/uploads/${basename}` }
        } catch (error) {
            ctx.body = {"error":error}
        }
        
    } else {
        await readAndWrite(ctx).then(e => {
            basename = e;
        })
        ctx.body = { "url": `${ctx.origin}/uploads/${basename}` }
    }
})

router.post('/toZip', async ctx => {
    await zipCreate(ctx)
})

router.get('/(.*)', async (ctx, next) => {
    // await delayer(3000);
    var name = '';
    var realPath = '';
    if (path.extname(ctx.path).length == 0) {
        name = '/index.html'
    } else {
        var referer = ctx.request.headers["referer"]
        if (referer && referer.length > 0) {
            if (path.extname(referer).length == 0) {
                var url = new URL(referer)
                realPath = '/' + url.pathname;
            }
        }
    }
    var filepath = `public/${realPath}${ctx.request.path}${name}`;
    if (fs.existsSync(filepath)) {
        await send(ctx, filepath);
        return
    } else {
        filepath = `public/${ctx.request.path}${name}`;
        if (fs.existsSync(filepath)) {
            await send(ctx, filepath);
            return
        }
    }
    await next()
})
router.get('/parseurl', async ctx => {
    await urlParse(ctx)
})
    app.use(router.routes());
app.use(router.allowedMethods());
app.listen(3000, () => {
    console.log('启动成功')
    console.log('http://localhost:3000')
});