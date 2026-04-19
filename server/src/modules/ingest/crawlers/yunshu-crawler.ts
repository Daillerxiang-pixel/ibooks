import axios, { AxiosInstance } from 'axios';
import * as cheerio from 'cheerio';
import * as iconv from 'iconv-lite';

/**
 * 先不引入 iconv-lite，用 Buffer + TextDecoder 手动处理 GBK
 * Node 22 内置 TextDecoder 支持 GBK
 */

const BASE_URL = 'https://www.yunshu.tw';
const HEADERS = {
  'User-Agent':
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
  'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
};

export interface NovelInfo {
  title: string;
  author: string;
  category: string;
  status: string;
  description: string;
  coverUrl: string;
  tags: string[];
}

export interface ChapterLink {
  title: string;
  sourceId: string; // yunshu chapter ID
  sourceUrl: string;
}

export interface ChapterContent {
  title: string;
  paragraphs: string[];
  wordCount: number;
}

export class YunshuCrawler {
  private http: AxiosInstance;

  constructor() {
    this.http = axios.create({
      baseURL: BASE_URL,
      timeout: 20000,
      headers: HEADERS,
      responseType: 'arraybuffer',
      // 不自动转换，我们手动解码
      transformResponse: [(data: Buffer) => data],
    });
  }

  /**
   * 解码 GBK 响应
   */
  private decodeHtml(buf: Buffer): string {
    // 尝试多种编码
    const text = new TextDecoder('gbk').decode(buf);
    return text;
  }

  /**
   * 获取小说信息 + 章节列表
   */
  async getNovelInfo(novelId: string): Promise<{ info: NovelInfo; chapters: ChapterLink[] }> {
    const url = `/Novel.Asp?Id=${novelId}`;
    const resp = await this.http.get(url);
    const html = this.decodeHtml(Buffer.from(resp.data));
    const $ = cheerio.load(html);

    // ---- 基本信息 ----
    const info: NovelInfo = {
      title: '',
      author: '',
      category: '',
      status: '连载',
      description: '',
      coverUrl: '',
      tags: [],
    };

    // 书名
    const h1 = $('h1').first();
    if (h1.length) info.title = h1.text().trim();

    // 封面
    const coverImg = $('img').filter(function () {
      const src = $(this).attr('src') || '';
      return src.includes('cover') || src.includes('Cover') || ($(this).attr('width') === '120');
    }).first();
    if (coverImg.length) {
      const src = coverImg.attr('src') || '';
      info.coverUrl = src.startsWith('http') ? src : BASE_URL + src;
    }

    // 从页面文本提取元信息
    const fullText = $('body').text();
    const lines = fullText.split(/\n/).map((l) => l.trim()).filter(Boolean);

    for (const line of lines) {
      if (line.includes('著') && line.includes('·')) {
        const parts = line.split('·');
        if (parts.length >= 2) {
          info.category = parts[0].trim();
          info.author = parts[1].replace('著', '').trim();
        }
      }
      if (line.includes('已完结')) info.status = '已完结';
      if (line.includes('连载')) info.status = '连载中';
    }

    // 简介
    const bodyText = fullText;
    const descMatch = bodyText.match(/作品简?[介說明]\s*\n([\s\S]{0,500}?)(?:標簽|标签|推薦|推荐|開始|追書|收藏|分享)/);
    if (descMatch) {
      info.description = descMatch[1].trim();
    }

    // ---- 章节列表（支持翻页） ----
    const allChapters: ChapterLink[] = [];
    const seenIds = new Set<string>();
    let page = 1;

    while (true) {
      const chUrl = `/Novel.Asp?ID=${novelId}&Y=-1&page=${page}`;
      const chResp = await this.http.get(chUrl);
      const chHtml = this.decodeHtml(Buffer.from(chResp.data));
      const $$ = cheerio.load(chHtml);

      let pageChapters = 0;
      $$('a').each(function () {
        const href = $$(this).attr('href') || '';
        const text = $$(this).text().trim();
        const m = href.match(/Contents\.Asp\?ID=(\d+)/i);
        if (m && text) {
          // 清理章节名中的更新时间
          const cleanTitle = text.replace(/更新：?\d{4}\/\d{1,2}\/\d{1,2}.*$/, '').trim();
          if (!seenIds.has(m[1]) && cleanTitle) {
            seenIds.add(m[1]);
            allChapters.push({
              title: cleanTitle,
              sourceId: m[1],
              sourceUrl: `${BASE_URL}/Contents.Asp?ID=${m[1]}`,
            });
            pageChapters++;
          }
        }
      });

      // 翻页检测
      const pagesDiv = $$('.pages');
      let hasNext = false;
      if (pagesDiv.length) {
        const pagesText = pagesDiv.text();
        const totalMatch = pagesText.match(/(\d+)\/(\d+)/);
        if (totalMatch) {
          const totalPages = parseInt(totalMatch[2]);
          if (page < totalPages) hasNext = true;
        }
      }

      if (!hasNext || pageChapters === 0) break;
      page++;
      // 小延迟避免被封
      await new Promise((r) => setTimeout(r, 300));
    }

    return { info, chapters: allChapters };
  }

  /**
   * 抓取单章正文
   * 1. 先访问章节页获取 Session + C 参数
   * 2. 再请求 N.Asp 接口获取正文
   */
  async getChapterContent(
    novelId: string,
    chapterId: string,
    cookie?: string,
  ): Promise<ChapterContent> {
    // Step 1: 访问章节页
    const pageUrl = `/Contents.Asp?ID=${chapterId}`;
    const pageResp = await this.http.get(pageUrl, {
      headers: cookie ? { Cookie: cookie } : undefined,
    });
    const pageHtml = this.decodeHtml(Buffer.from(pageResp.data));

    // 提取 C 参数
    const cMatch = pageHtml.match(/N\.Asp\?Z=\d+&S=\d+&C=(\d+)/);
    if (!cMatch) {
      throw new Error(`无法提取 C 参数: chapterId=${chapterId}`);
    }
    const cParam = cMatch[1];

    // 提取章节标题
    const titleMatch = pageHtml.match(/<h1[^>]*>([^<]+)<\/h1>/);
    const title = titleMatch ? titleMatch[1].trim() : '';

    // 从 Set-Cookie 获取 session
    const setCookies = pageResp.headers['set-cookie'];
    let sessionCookie = cookie || '';
    if (setCookies) {
      const sessionPart = setCookies
        .map((c: string) => c.split(';')[0])
        .join('; ');
      sessionCookie = sessionCookie
        ? sessionCookie + '; ' + sessionPart
        : sessionPart;
    }

    // Step 2: 请求正文接口
    const contentUrl = `/JS/N.Asp?Z=${chapterId}&S=${novelId}&C=${cParam}`;
    const contentResp = await this.http.get(contentUrl, {
      headers: {
        Referer: `${BASE_URL}${pageUrl}`,
        Cookie: sessionCookie,
      },
    });
    const rawContent = this.decodeHtml(Buffer.from(contentResp.data));

    // 解析 document.writeln('...')
    const paragraphs = this.parseContent(rawContent);

    return {
      title,
      paragraphs,
      wordCount: paragraphs.reduce((sum, p) => sum + p.length, 0),
    };
  }

  /**
   * 解析 document.writeln 格式的正文
   */
  private parseContent(raw: string): string[] {
    // 提取所有 document.writeln('...')
    const writes = raw.match(/document\.writeln\('(.+?)'\);/g);
    if (!writes) return [];

    const full = writes
      .map((w) => {
        const m = w.match(/document\.writeln\('(.+?)'\);/);
        return m ? m[1] : '';
      })
      .join('\n');

    // 检测错误
    if (full.includes('文件獲取錯误') || full.includes('文件获取错误')) {
      return [];
    }

    // 去掉混淆用的空 span 标签
    let cleaned = full.replace(/<span class="Y_\d+"><\/span>/g, '');
    cleaned = cleaned.replace(/<span class="Y_\d+"><\\\/span>/g, '');

    // 处理换行
    cleaned = cleaned.replace(/<br\s*\/?>/gi, '\n');

    // 反转义
    cleaned = cleaned.replace(/\\'/g, "'").replace(/\\\//g, '/').replace(/\\n/g, '\n');

    // 去掉剩余 HTML 标签
    cleaned = cleaned.replace(/<[^>]+>/g, '');

    // 分段并清理
    const lines = cleaned
      .split(/\n/)
      .map((l) => l.trim())
      .filter((l) => l.length > 0);

    return lines;
  }

  /**
   * 批量抓取章节正文（串行，带进度回调）
   */
  async fetchAllChapters(
    novelId: string,
    chapterLinks: ChapterLink[],
    onProgress?: (done: number, total: number, title: string) => void,
    onError?: (chapterId: string, error: string) => void,
  ): Promise<Map<string, ChapterContent>> {
    const results = new Map<string, ChapterContent>();
    let cookie: string | undefined;

    for (let i = 0; i < chapterLinks.length; i++) {
      const ch = chapterLinks[i];
      try {
        const content = await this.getChapterContent(novelId, ch.sourceId, cookie);
        results.set(ch.sourceId, content);
        if (onProgress) onProgress(i + 1, chapterLinks.length, ch.title);
      } catch (err: any) {
        if (onError) onError(ch.sourceId, err.message || String(err));
      }
      // 延迟 0.5s 避免被封
      if (i < chapterLinks.length - 1) {
        await new Promise((r) => setTimeout(r, 500));
      }
    }

    return results;
  }
}
