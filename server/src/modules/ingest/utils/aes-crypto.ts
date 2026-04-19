import * as crypto from 'crypto';

const ALGORITHM = 'aes-256-cbc';

/**
 * AES-256-CBC 加密
 * @param plaintext 明文
 * @param keyBase64 Base64 编码的 32 字节密钥
 * @returns { ciphertext: string, iv: string } 均为 hex
 */
export function aesEncrypt(plaintext: string, keyBase64: string): { ciphertext: string; iv: string } {
  const key = Buffer.from(keyBase64, 'base64');
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
  let encrypted = cipher.update(plaintext, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return { ciphertext: encrypted, iv: iv.toString('hex') };
}

/**
 * AES-256-CBC 解密
 */
export function aesDecrypt(ciphertext: string, ivHex: string, keyBase64: string): string {
  const key = Buffer.from(keyBase64, 'base64');
  const iv = Buffer.from(ivHex, 'hex');
  const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
  let decrypted = decipher.update(ciphertext, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

/**
 * 构建加密后的 JSON 包（与客户端约定格式一致）
 */
export function buildEncryptedPayload(
  chapterTitle: string,
  paragraphs: string[],
  keyBase64: string,
): { ossJson: string; preview: string } {
  const plainPayload = JSON.stringify({ title: chapterTitle, paragraphs });
  const { ciphertext, iv } = aesEncrypt(plainPayload, keyBase64);

  // 前 200 字试读摘要
  const fullText = paragraphs.join('');
  const preview = fullText.substring(0, 200);

  const ossJson = JSON.stringify({
    encrypted: true,
    algorithm: 'aes-256-cbc',
    iv,
    data: ciphertext,
  });

  return { ossJson, preview };
}

/**
 * 构建免费章节的明文 JSON
 */
export function buildPlainPayload(chapterTitle: string, paragraphs: string[]): string {
  return JSON.stringify({ title: chapterTitle, paragraphs });
}
