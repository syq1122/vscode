/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
const secretKey = 'Gitee-CloudIDECP'; // 16 字节 密钥，用于AES加密
const iv = '1234561234567890'; // 16 字节 初始化向量，用于AES加密
const commonPrefix = 'CloudIDECopy';

// 加密函数
export async function encrypt(content: string): Promise<string> {
	// 加密
	const encrypted = await encryptAES(content, secretKey, iv);
	console.log('[CloudIDE] Encrypted:-----------------:', encrypted);
	return `${encrypted}:${commonPrefix}`;
	// const iv = randomBytes(16); // 每次加密生成随机IV
	// const cipher = createCipheriv('aes-128-cbc', Buffer.from(secretKey), iv);
	//
	// let encrypted = cipher.update(content, 'utf8');
	// encrypted = Buffer.concat([encrypted, cipher.final()]);
	//
	// // 返回格式: IV(hex):密文(base64):前缀
	// return `${iv.toString('hex')}:${encrypted.toString('base64')}:${commonPrefix}`;
}

// 配套的解密
export async function decrypt(encryptedContent: string): Promise<string> {
	if (!encryptedContent.endsWith(commonPrefix)) {
		return encryptedContent;
	}
	const parts = encryptedContent.split(':');
	if (parts.length !== 2 || !parts[1].endsWith(commonPrefix)) {
		throw new Error('Invalid encrypted content format');
	}

	const encryptedText = parts[0];
	// 解密
	const decrypted = await decryptAES(encryptedText, secretKey, iv);
	console.log('[CloudIDE] Decrypted:-----------------:', decrypted);

	return decrypted;
	//
	// const decipher = createDecipheriv('aes-128-cbc', Buffer.from(secretKey), iv);
	// let decrypted = decipher.update(encryptedText, 'base64');
	// decrypted = Buffer.concat([decrypted, decipher.final()]);
	//
	// return decrypted.toString('utf8');
}

/**
 * 使用 AES-CBC 加密（Web Crypto API）
 * @param plaintext 明文
 * @param key 密钥（需为 16/24/32 字节）
 * @param iv 初始化向量（16 字节）
 * @returns 返回 Base64 编码的加密数据
 */
async function encryptAES(plaintext: string, key: string, iv: string): Promise<string> {
	// 1. 准备密钥和 IV
	const encoder = new TextEncoder();
	const keyData = encoder.encode(key);
	const ivData = encoder.encode(iv);

	// 2. 导入密钥
	const cryptoKey = await crypto.subtle.importKey(
		'raw',
		keyData,
		{ name: 'AES-CBC', length: 128 },
		false,
		['encrypt']
	);

	// 3. 加密
	const encrypted = await crypto.subtle.encrypt(
		{ name: 'AES-CBC', iv: ivData },
		cryptoKey,
		encoder.encode(plaintext)
	);

	// 4. 返回 Base64
	return arrayBufferToBase64(encrypted);
}

/**
 * 使用 AES-CBC 解密（Web Crypto API）
 * @param ciphertext Base64 密文
 * @param key 密钥
 * @param iv 初始化向量
 * @returns UTF-8 解密字符串
 */
async function decryptAES(ciphertext: string, key: string, iv: string): Promise<string> {
	// 1. 准备密钥和 IV
	const encoder = new TextEncoder();
	const keyData = encoder.encode(key);
	const ivData = encoder.encode(iv);

	// 2. 导入密钥
	const cryptoKey = await crypto.subtle.importKey(
		'raw',
		keyData,
		{ name: 'AES-CBC', length: 128 },
		false,
		['decrypt']
	);

	// 3. 解密
	const decrypted = await crypto.subtle.decrypt(
		{ name: 'AES-CBC', iv: ivData },
		cryptoKey,
		base64ToArrayBuffer(ciphertext)
	);

	// 4. 返回 UTF-8 字符串
	return new TextDecoder().decode(decrypted);
}


const ideGlobalConfig: { [key: string]: any } = {};
// Function to set the global variable
export function setGlobalConfig(key: string, value: any) {
	ideGlobalConfig[key] = value;
}
// Function to get the global variable
export function getGlobalConfig(key: string): any {
	return ideGlobalConfig[key];
}

// 辅助函数：ArrayBuffer ↔ Base64
function arrayBufferToBase64(buffer: ArrayBuffer): string {
	return btoa(String.fromCharCode(...new Uint8Array(buffer)));
}

function base64ToArrayBuffer(base64: string): ArrayBuffer {
	const binaryStr = atob(base64);
	const bytes = new Uint8Array(binaryStr.length);
	for (let i = 0; i < binaryStr.length; i++) {
		bytes[i] = binaryStr.charCodeAt(i);
	}
	return bytes.buffer;
}
