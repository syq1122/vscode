/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
import { generateUuid } from './uuid.js';
// eslint-disable-next-line local/code-import-patterns
// import * as CryptoJS from 'crypto-js';
import CryptoJS from 'crypto-js';
// import { CryptoJS } from '../../../../node_modules/crypto-js/crypto-js';
const textEncryptionKey: string = generateUuid();

const commonPrefix = 'cloud-ide-clipboard/';

// 加密文本
export function encrypt(content: string) {
	const encrypted = CryptoJS.AES.encrypt(content, textEncryptionKey).toString();
	return `${commonPrefix}${encrypted}`;
}

// 解密文本
export function decrypt(cipherText: string) {
	if (cipherText.startsWith(commonPrefix)) {
		const body = cipherText.slice(commonPrefix.length);
		const bytes = CryptoJS.AES.decrypt(body, textEncryptionKey);
		return bytes.toString(CryptoJS.enc.Utf8);
	}
	return cipherText;
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
