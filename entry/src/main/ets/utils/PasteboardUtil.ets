import { pasteboard } from '@kit.BasicServicesKit';
import { StrUtil } from './StrUtil';

export class PasteboardUtil {

  /**
   * 将数据写入系统剪贴板，使用Promise异步回调。
   * @param mimeType 数据类型
   * @param data 数据内容
   * @returns Promise<void>
   */
  static setData(mimeType: string, data: string): Promise<void> {
    const pasteData = pasteboard.createData(mimeType, data);
    return PasteboardUtil.getSystemPasteboard().setData(pasteData);
  }

  /**
   * 将纯文本数据写入系统剪贴板。
   * @param text 纯文本内容
   * @returns Promise<void>
   */
  static setDataText(text: string): Promise<void> {
    return PasteboardUtil.setData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
  }

  /**
   * 将HTML数据写入系统剪贴板。
   * @param html HTML内容
   * @returns Promise<void>
   */
  static setDataHtml(html: string): Promise<void> {
    return PasteboardUtil.setData(pasteboard.MIMETYPE_TEXT_HTML, html);
  }

  /**
   * 将URI数据写入系统剪贴板。
   * @param uri URI内容
   * @returns Promise<void>
   */
  static setDataUri(uri: string): Promise<void> {
    return PasteboardUtil.setData(pasteboard.MIMETYPE_TEXT_URI, uri);
  }

  /**
   * 获取系统剪贴板内容。
   * @returns Promise<pasteboard.PasteData>
   */
  static getData(): Promise<pasteboard.PasteData> {
    return PasteboardUtil.getSystemPasteboard().getData();
  }

  /**
   * 读取系统剪贴板内容，优先级为：文本 > HTML > URI。
   * @returns Promise<string>
   */
  static async getDataStr(): Promise<string> {
    if (!await PasteboardUtil.hasData()) {
      return '';
    }
    const data = await PasteboardUtil.getData();
    return PasteboardUtil.extractPrimaryText(data);
  }

  /**
   * 同步读取系统剪贴板内容，优先级为：文本 > HTML > URI。
   * @returns string
   */
  static getDataSyncStr(): string {
    if (!PasteboardUtil.hasDataSync()) {
      return '';
    }
    const data = PasteboardUtil.getSystemPasteboard().getDataSync();
    return PasteboardUtil.extractPrimaryText(data);
  }

  /**
   * 清空系统剪贴板内容。
   * @returns Promise<void>
   */
  static clearData(): Promise<void> {
    return PasteboardUtil.getSystemPasteboard().clearData();
  }

  /**
   * 判断系统剪贴板中是否有内容（异步）。
   * @returns Promise<boolean>
   */
  static hasData(): Promise<boolean> {
    return PasteboardUtil.getSystemPasteboard().hasData();
  }

  /**
   * 判断系统剪贴板中是否有内容（同步）。
   * @returns boolean
   */
  static hasDataSync(): boolean {
    return PasteboardUtil.getSystemPasteboard().hasDataSync();
  }

  /**
   * 获取系统剪贴板对象。
   * @returns SystemPasteboard
   */
  private static getSystemPasteboard(): pasteboard.SystemPasteboard {
    return pasteboard.getSystemPasteboard();
  }

  /**
   * 提取剪贴板数据中的主要文本内容。
   * @param data 剪贴板数据
   * @returns string
   */
  private static extractPrimaryText(data: pasteboard.PasteData): string {
    let text = data.getPrimaryText() || data.getPrimaryHtml() || data.getPrimaryUri() || '';
    return StrUtil.isEmpty(text) ? '' : text;
  }
}