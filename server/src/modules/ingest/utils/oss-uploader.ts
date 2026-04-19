// ali-oss CJS 兼容
const AliOSS = require('ali-oss');

let client: any = null;

function getClient(): any {
  if (!client) {
    client = new AliOSS({
      region: process.env.OSS_REGION || 'oss-cn-beijing',
      accessKeyId: process.env.OSS_ACCESS_KEY_ID || '',
      accessKeySecret: process.env.OSS_ACCESS_KEY_SECRET || '',
      bucket: process.env.OSS_BUCKET || 'aihuantu',
    });
  }
  return client;
}

/**
 * 上传 JSON 字符串到 OSS
 */
export async function uploadJson(ossPath: string, content: string): Promise<string> {
  const oss = getClient();
  const result = await oss.put(ossPath, Buffer.from(content, 'utf-8'), {
    headers: { 'Content-Type': 'application/json; charset=utf-8' },
  });
  return result.url;
}

/**
 * 上传章节内容到 OSS
 */
export async function uploadChapter(bookId: number, chapterNum: number, jsonContent: string): Promise<string> {
  const ossPath = `ibooks/chapters/${bookId}/${chapterNum}.json`;
  return uploadJson(ossPath, jsonContent);
}

/**
 * 上传封面图片
 */
export async function uploadCover(bookId: number, imageBuffer: Buffer, ext: string): Promise<string> {
  const contentType = (ext === 'jpg' || ext === 'jpeg') ? 'image/jpeg' : 'image/png';
  const ossPath = `ibooks/covers/${bookId}.${ext}`;
  const oss = getClient();
  const result = await oss.put(ossPath, imageBuffer, {
    headers: { 'Content-Type': contentType },
  });
  return result.url;
}
