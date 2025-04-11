/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

export class SyncAES {
	private static readonly BLOCK_SIZE = 16; // AES block size (128 bits)
	private static readonly KEY_SIZES = [16, 24, 32]; // AES-128, AES-192, AES-256

	/**
	 * 同步 AES-CBC 加密
	 * @param plaintext 明文
	 * @param key 密钥字符串
	 * @param iv 初始化向量字符串
	 * @returns Base64编码的密文
	 */
	public static encrypt(plaintext: string, key: string, iv: string): string {
		const keyBytes = this.normalizeKey(key);
		const ivBytes = this.normalizeIV(iv);
		const textBytes = this.textToUint8Array(plaintext);
		const paddedData = this.padData(textBytes);
		const encrypted = this.cbcEncrypt(paddedData, keyBytes, ivBytes);
		return this.uint8ArrayToBase64(encrypted);
	}

	/**
	 * 同步 AES-CBC 解密
	 * @param ciphertext Base64编码的密文
	 * @param key 密钥字符串
	 * @param iv 初始化向量字符串
	 * @returns 解密后的明文
	 */
	public static decrypt(ciphertext: string, key: string, iv: string): string {
		const keyBytes = this.normalizeKey(key);
		const ivBytes = this.normalizeIV(iv);
		const encryptedBytes = this.base64ToUint8Array(ciphertext);
		const decryptedPadded = this.cbcDecrypt(encryptedBytes, keyBytes, ivBytes);
		const decrypted = this.unpadData(decryptedPadded);
		return this.uint8ArrayToText(decrypted);
	}

	// ========== 密钥和IV处理 ==========

	private static normalizeKey(key: string): Uint8Array {
		const keyBytes = this.textToUint8Array(key);

		// 检查密钥长度是否有效
		if (!this.KEY_SIZES.includes(keyBytes.length)) {
			// 自动调整密钥长度
			const adjustedKey = new Uint8Array(32); // 默认使用AES-256
			for (let i = 0; i < adjustedKey.length; i++) {
				adjustedKey[i] = keyBytes[i % keyBytes.length];
			}
			return adjustedKey;
		}

		return keyBytes;
	}

	private static normalizeIV(iv: string): Uint8Array {
		const ivBytes = this.textToUint8Array(iv);

		// 如果IV长度不足，循环填充
		if (ivBytes.length < this.BLOCK_SIZE) {
			const adjustedIV = new Uint8Array(this.BLOCK_SIZE);
			for (let i = 0; i < adjustedIV.length; i++) {
				adjustedIV[i] = ivBytes[i % ivBytes.length];
			}
			return adjustedIV;
		}

		// 如果IV过长，截断
		if (ivBytes.length > this.BLOCK_SIZE) {
			return ivBytes.slice(0, this.BLOCK_SIZE);
		}

		return ivBytes;
	}

	// ========== 核心加密/解密算法 ==========

	private static cbcEncrypt(data: Uint8Array, key: Uint8Array, iv: Uint8Array): Uint8Array {
		// 注意: 这是一个简化的实现，实际AES算法更复杂
		const result = new Uint8Array(data.length);
		let previousBlock = iv;

		for (let i = 0; i < data.length; i += this.BLOCK_SIZE) {
			const block = data.slice(i, i + this.BLOCK_SIZE);
			const xored = this.xorBlocks(block, previousBlock);
			const encryptedBlock = this.simplifiedAES(xored, key);
			result.set(encryptedBlock, i);
			previousBlock = encryptedBlock;
		}

		return result;
	}

	private static cbcDecrypt(data: Uint8Array, key: Uint8Array, iv: Uint8Array): Uint8Array {
		// 注意: 这是一个简化的实现，实际AES算法更复杂
		const result = new Uint8Array(data.length);
		let previousBlock = iv;

		for (let i = 0; i < data.length; i += this.BLOCK_SIZE) {
			const block = data.slice(i, i + this.BLOCK_SIZE);
			const decryptedBlock = this.simplifiedAES(block, key, true);
			const xored = this.xorBlocks(decryptedBlock, previousBlock);
			result.set(xored, i);
			previousBlock = block;
		}

		return result;
	}

	// ========== 辅助方法 ==========

	private static simplifiedAES(data: Uint8Array, key: Uint8Array, isDecrypt = false): Uint8Array {
		// 警告: 这不是真正的AES实现，仅用于演示
		const result = new Uint8Array(data.length);
		for (let i = 0; i < data.length; i++) {
			result[i] = data[i] ^ key[i % key.length];
		}
		return result;
	}

	private static xorBlocks(a: Uint8Array, b: Uint8Array): Uint8Array {
		const result = new Uint8Array(a.length);
		for (let i = 0; i < a.length; i++) {
			result[i] = a[i] ^ b[i];
		}
		return result;
	}

	private static padData(data: Uint8Array): Uint8Array {
		const padLength = this.BLOCK_SIZE - (data.length % this.BLOCK_SIZE);
		const padded = new Uint8Array(data.length + padLength);
		padded.set(data);
		// PKCS#7 padding
		for (let i = data.length; i < padded.length; i++) {
			padded[i] = padLength;
		}
		return padded;
	}

	private static unpadData(data: Uint8Array): Uint8Array {
		const padLength = data[data.length - 1];
		return data.slice(0, data.length - padLength);
	}

	private static textToUint8Array(text: string): Uint8Array {
		const encoder = new TextEncoder();
		return encoder.encode(text);
	}

	private static uint8ArrayToText(bytes: Uint8Array): string {
		const decoder = new TextDecoder();
		return decoder.decode(bytes);
	}

	private static uint8ArrayToBase64(bytes: Uint8Array): string {
		return btoa(String.fromCharCode(...bytes));
	}

	private static base64ToUint8Array(base64: string): Uint8Array {
		const binaryString = atob(base64);
		const bytes = new Uint8Array(binaryString.length);
		for (let i = 0; i < binaryString.length; i++) {
			bytes[i] = binaryString.charCodeAt(i);
		}
		return bytes;
	}
}
