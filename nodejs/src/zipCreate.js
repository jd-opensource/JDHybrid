const nanoid = require('nanoid').nanoid
const crypto = require('crypto');
const path = require('path')
const fs = require("fs-extra");
const url = require("url");
const axios = require("axios");
const archiver = require("archiver");
const child_process = require('child_process');
archiver.registerFormat('zip-encrypted', require("archiver-zip-encrypted"));
async function zipCreate(ctx) {
    var resources = JSON.parse(ctx.request.body);
    if (resources.length == 0) {
        ctx.body = {
            statusCode: -1,
            msg: "资源为空"
        }
        return
    }
    var dir = `${__dirname}/../public/ziparc/${nanoid(16)}`
    if (!fs.existsSync(dir)) {
        await new Promise((resolve, reject) => {
            fs.mkdir(dir, { recursive: true }, (err) => {

            })
            resolve()
        })
    }
    const downloadFiles = await Promise.all(
        resources.map(d => {
            return downloadUrl(d, dir);
        }),
    );
    const jsonName = 'resource.json';
    const json = {
        fileName: jsonName,
        filePath: path.resolve(dir, jsonName),
    };
    let statusCode;
    if (downloadFiles.every(data => data.code === 0)) statusCode = 0; // 所有资源都正确下载
    if (downloadFiles.some(data => data.code < 0)) statusCode = -1; // 有资源下载报错
    if (downloadFiles.some(data => data.code > 0)) statusCode = 1; // 有资源存在重定向
    if (statusCode < 0) {
        ctx.body = { statusCode }
        if (err) {
            deleteDir(dir)
        }
        return
    }
    const { files, JSONObject } = await generateJSON(downloadFiles);
    await fs.outputJSON(json.filePath, JSONObject);
    const password = '3fDC5a%9c1';
    if (ctx.request.query && ctx.request.query['zip'] == 1) {
        let filePaths = files.concat([json.filePath]);
        const encryptionMethod = 'zip20';
        const archive = archiver.create('zip-encrypted', {
            zlib: { level: 8 },
            encryptionMethod: encryptionMethod,
            password: password,
        });
        const output = fs.createWriteStream(`${dir}.zip`);
        output.on('end', function (err) {
            console.log(err)
        });

        archive.on('warning', function (warn) {
            console.log(err)
        });

        archive.on('error', function (err) {
            console.log(err)
        });
        archive.pipe(output);
        for (let i = 0; i < filePaths.length; i++) {
            var  filePath = filePaths[i]
            var  floderPath = ""
            if (typeof(filePath) == 'string') {
                floderPath = "resource.json";
            }else{
                floderPath = filePath['randomName'];
                filePath = filePath['filePath'];
            }
            const fileBuffer = await readFile(filePath).catch(err => {
                console.log(err)
            });
            archive.append(fileBuffer, { name: floderPath });
        }
        archive.finalize();
        deleteDir(dir)
        dir = dir + '.zip'
    }
    ctx.body = {
        statusCode,
        password:password,
        filesPath: dir
    }
}


function deleteDir(dir) {
    child_process.exec(`rm -rf ${dir}`, 
        (error, stdout, stderr) => {})
}
/**
 * 生成打包文件配置，多域名指向同一文件去重
 */
async function generateJSON(
    downloadFiles,
) {
    // 通过文件hash，去除不同url指向同一个下载资源的情况
    const map = {};
    // hash去重后的文件地址
    const filesPath = [];
    const files = downloadFiles.map(data => {
        const d = data.file;
        const key = map[d.md5];
        if (key) {
            const value = map[key];
            return Object.assign(d, {
                filePath: value.filePath,
                randomName: value.randomName,
            });
        } else {
            filesPath.push({ filePath: d.filePath, fileName: d.randomName });
            map[key] = d;
            return d;
        }
    });
    // 生成文件描述JSONObject
    const JSONObject = files.map((d) => {
        let resourceType = d.resourceType || 'unknown'
        if (resourceType === 'unknown') {
            if (d.extname === '.html') resourceType = 'html';
            if (d.extname === '.js') resourceType = 'script';
            if (d.extname === '.css') resourceType = 'stylesheet';
            if (d.extname.match(/.(png|jpe?g|webp|svg|gif)$/g)) resourceType = 'image';
        }

        return {
            filename: d.randomName,
            originUrl: d.url,
            url: d.url.split(/[?!]/g)[0],
            type: resourceType,
            header: {
                'content-type': d.headers['content-type'],
                'content-length': d.headers['content-length'],
                'access-control-allow-origin': d.headers['access-control-allow-origin'],
                'timing-allow-origin': d.headers['timing-allow-origin'],
            },
        };
    });
    return {
        files,
        JSONObject,
    };
}

async function downloadUrl(
    resource,
    dir,
) {
    const { pathname } = url.parse(resource.url)
    let nameFromUrl = path.basename(pathname);

    // 处理页面入口无扩展名,统一标记为index.html
    if (resource.resourceType === 'html') {
        nameFromUrl = 'index.html'
    }
    if (!nameFromUrl) {
        nameFromUrl = nanoid(8)
    }
    const extname = path.extname(nameFromUrl);
    const randomName = nanoid(8) + extname;
    const filePath = path.resolve(dir, randomName);
    const fmd5 = crypto.createHash('md5');
    const writer = fs.createWriteStream(filePath);
    const fileInfo = {
        resourceType: resource.resourceType,
        url: resource.url,
        nameFromUrl,
        randomName,
        extname,
        filePath: filePath,
        headers: null,
    };
    try {
        const response = await axios({
            url: resource.url,
            method: 'GET',
            responseType: 'stream',
        });
        fileInfo.headers = response.headers;

        if (response.status !== 200) {
            console.log('response', response);
            throw response;
        }
        response.data.pipe(writer);
        response.data.pipe(fmd5);
    } catch (err) {
        writer.end();
        return Promise.resolve({
            file: fileInfo,
            code: -100,
            log:
                `文件下载失败(-100): ${JSON.stringify(fileInfo)}`,
            message: JSON.stringify(
                err
            )
        });
    }

    return new Promise((resolve, reject) => {
        writer.on('finish', () => {
            const info = {
                ...fileInfo,
                md5: fmd5.digest('hex'),
            };
            resolve({
                file: info,
                log: `文件下载成功: ${JSON.stringify(info)}`,
                code: 0,
            });
        });
        writer.on('error', err => {
            resolve({
                file: fileInfo,
                code: -200,
                log: `文件下载失败(-200): ${JSON.stringify(fileInfo)}\n ${err}`,
                message: JSON.stringify(
                    err
                )
            });
        });
    });
}
function readFile(url) {
    return new Promise((resolve, reject) => {
        fs.readFile(url, (err, buffer) => {
            if (err) {
                reject(err);
            } else {
                resolve(buffer);
            }
        });
    });
}

module.exports = zipCreate;