/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/
import * as platform from './platform.js';
export function getRouterRouteIds() {
	const [, , , CompanyId, ProjectId] = window.location.pathname.match(/^\/([^/]+)\/([^/]+)\/([^/]+)\/([^/]+)\/([^/]+)\//) || [];
	return [CompanyId, ProjectId];
}
/**
 * 请求日志
 *
 * @param params 请求参数，可选 {name, content}
 * name: vscode.open.file; vscode.edit.file; vscode.delete.file; vscode.move.file
 * content: 文件路径
 * @returns 返回一个 Promise，表示请求结果
 */
export async function requestLog(params?: any) {
	const host = window.location.origin;
	const pathnameArr = window.location.pathname.split('/');
	const resourceId = pathnameArr[pathnameArr.length - 2];
	const endpoint = `${host}/api/cloudide/${getRouterRouteIds()[0]}/${getRouterRouteIds()[1]}/cloud/log/v1/log`;
	const dataParams = params || {};
	const payload = {
		resourceId,
		app: 'vscode.web.event.edit1',
		os: {
			platform: platform.OS === platform.OperatingSystem.Windows ? 'windows' : platform.OS === platform.OperatingSystem.Macintosh ? 'macos' : 'linux',
			release: platform.userAgent,
		},
		operation: {

			name: dataParams.name || 'vscode.edit.file',
			result: 'success',
			timestamp: +new Date(),
			content: {
				content: dataParams.content || '',
			}
		},
	};
	try {
		await fetch(
			endpoint,
			{
				method: 'POST',
				headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
				body: `data=${JSON.stringify({ type: 'vscode', payload })}`
			});
	}
	catch (error) {
		console.error('Failed to fetch log:', error.message);
		return undefined;
	}
}
