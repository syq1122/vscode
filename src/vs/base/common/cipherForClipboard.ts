/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
import { SyncAES } from './syncaes.js'; // 引入同步AES加密函数

const secretKey = 'Gitee-CloudIDECP'; // 16 字节 密钥，用于AES加密
const iv = '1234561234567890'; // 16 字节 初始化向量，用于AES加密
export const commonPrefix = 'CloudIDECopy';

// 加密函数
export function encrypt(content: string): string {
	// 加密
	const encrypted = SyncAES.encrypt(content, secretKey, iv);
	console.log('[CloudIDE] Encrypted:-----------------:', encrypted);
	return `${encrypted}:${commonPrefix}`;
}

// 配套的解密
export function decrypt(encryptedContent: string): string {
	if (!encryptedContent.endsWith(commonPrefix)) {
		return encryptedContent;
	}
	const parts = encryptedContent.split(':');
	if (parts.length !== 2 || !parts[1].endsWith(commonPrefix)) {
		throw new Error('Invalid encrypted content format');
	}

	const encryptedText = parts[0];
	// 解密
	const decrypted = SyncAES.decrypt(encryptedText, secretKey, iv);
	console.log('[CloudIDE] Decrypted:-----------------:', decrypted);

	return decrypted;
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
