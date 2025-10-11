import util from '@ohos.util';
import { buffer } from '@kit.ArkTS';

export class StrUtil {
  /**
   * 判断字符串是否为 null 或 undefined
   * @param str 被检测的字符串
   * @returns 是否为 null 或 undefined
   */
  static isNull(str: string | undefined | null): boolean {
    return str === undefined || str === null;
  }

  /**
   * 判断字符串是否为非空（非 null 和非 undefined）
   * @param str 被检测的字符串
   * @returns 是否为非空
   */
  static isNotNull(str: string | undefined | null): boolean {
    return !StrUtil.isNull(str);
  }

  /**
   * 判断字符串是否为空（null、undefined 或长度为 0）
   * @param str 被检测的字符串
   * @returns 是否为空
   */
  static isEmpty(str: string | undefined | null): boolean {
    let length = str?.length;
    return StrUtil.isNull(str) || length === 0;
  }

  /**
   * 判断字符串是否为非空
   * @param str 被检测的字符串
   * @returns 是否为非空
   */
  static isNotEmpty(str: string | undefined | null): boolean {
    return !StrUtil.isEmpty(str);
  }


  /**
   * 格式化字符串，若为空则返回默认值
   * @param source 输入字符串
   * @param defaultValue 默认值
   * @returns 格式化后的字符串
   */
  static toStr(source: string | null | undefined, defaultValue = ''): string {
    return StrUtil.isNull(source) ? defaultValue : String(source);
  }

  /**
   * 替换字符串中匹配的内容
   * @param str 待替换的字符串
   * @param pattern 匹配的正则或字符串
   * @param replaceValue 替换的内容
   * @returns 替换后的字符串
   */
  static replace(str: string, pattern: RegExp | string, replaceValue = ''): string {
    return str.replace(pattern, replaceValue);
  }

  /**
   * 替换字符串中所有匹配的内容
   * @param str 待替换的字符串
   * @param pattern 匹配的正则或字符串
   * @param replaceValue 替换的内容
   * @returns 替换后的字符串
   */
  static replaceAll(str: string, pattern: RegExp | string, replaceValue = ''): string {
    return str.replaceAll(pattern, replaceValue);
  }

  /**
   * 判断字符串是否以指定内容开头
   * @param str 要检索的字符串
   * @param target 要匹配的内容
   * @param position 检索起始位置
   * @returns 是否以指定内容开头
   */
  static startsWith(str: string, target: string, position = 0): boolean {
    return str.startsWith(target, position);
  }

  /**
   * 判断字符串是否以指定内容结尾
   * @param str 要检索的字符串
   * @param target 要匹配的内容
   * @param position 检索结束位置
   * @returns 是否以指定内容结尾
   */
  static endsWith(str: string, target: string, position = str.length): boolean {
    return str.endsWith(target, position);
  }

  /**
   * 将字符串重复指定次数
   * @param str 要重复的字符串
   * @param n 重复次数
   * @returns 重复后的字符串
   */
  static repeat(str: string, n = 1): string {
    return str.repeat(n);
  }

  /**
   * 将字符串转换为小写
   * @param str 要转换的字符串
   * @returns 转换后的小写字符串
   */
  static toLower(str: string): string {
    return str.toLowerCase();
  }

  /**
   * 将字符串转换为大写
   * @param str 要转换的字符串
   * @returns 转换后的大写字符串
   */
  static toUpper(str: string): string {
    return str.toUpperCase();
  }

  /**
   * 将字符串首字母大写，其余部分小写
   * @param str 待转换的字符串
   * @returns 转换后的字符串
   */
  static capitalize(str: string): string {
    return StrUtil.isNotEmpty(str)
      ? `${str.charAt(0).toUpperCase()}${str.slice(1).toLowerCase()}`
      : '';
  }

  /**
   * 判断两个值是否相等
   * @param source 输入值
   * @param target 目标值
   * @returns 是否相等
   */
  static equal(source: string | number, target: string | number): boolean {
    return source === target;
  }

  /**
   * 判断两个值是否不相等
   * @param source 输入值
   * @param target 目标值
   * @returns 是否不相等
   */
  static notEqual(source: string | number, target: string | number): boolean {
    return !StrUtil.equal(source, target);
  }

  /**
   * 字符串转 Uint8Array
   * @param src 字符串
   * @param encoding 编码方式
   * @returns Uint8Array
   */
  static strToUint8Array(src: string, encoding: buffer.BufferEncoding = 'utf-8'): Uint8Array {
    const textEncoder = new util.TextEncoder(encoding);
    return textEncoder.encode(src);
  }

  /**
   * Uint8Array 转字符串
   * @param src Uint8Array
   * @param encoding 编码方式
   * @returns 字符串
   */
  static uint8ArrayToStr(src: Uint8Array, encoding: buffer.BufferEncoding = 'utf-8'): string {
    const textDecoder = util.TextDecoder.create(encoding, { ignoreBOM: true });
    return textDecoder.decodeToString(src);
  }

  /**
   * 十六进制字符串转 Uint8Array
   * @param hexStr 十六进制字符串
   * @returns Uint8Array
   */
  static strToHex(hexStr: string): Uint8Array {
    return new Uint8Array(buffer.from(hexStr, 'hex').buffer);
  }

  /**
   * Uint8Array 转十六进制字符串
   * @param arr Uint8Array
   * @returns 十六进制字符串
   */
  static hexToStr(arr: Uint8Array): string {
    return buffer.from(arr).toString('hex');
  }

  /**
   * 字符串转字节数组
   * @param str 字符串
   * @returns Uint8Array
   */
  static strToBytes(str: string): Uint8Array {
    return new Uint8Array(Array.from(str).map(char => char.charCodeAt(0)));
  }

  /**
   * 字节数组转字符串
   * @param bytes Uint8Array
   * @returns 字符串
   */
  static bytesToStr(bytes: Uint8Array): string {
    return Array.from(bytes).map(byte => String.fromCharCode(byte)).join('');
  }

  /**
   * 字符串转 ArrayBuffer
   * @param src 字符串
   * @param encoding 编码方式
   * @returns ArrayBuffer
   */
  static strToBuffer(src: string, encoding: buffer.BufferEncoding = 'utf-8'): ArrayBuffer {
    return buffer.from(src, encoding).buffer;
  }

  /**
   * ArrayBuffer 转字符串
   * @param src ArrayBuffer
   * @param encoding 编码方式
   * @returns 字符串
   */
  static bufferToStr(src: ArrayBuffer, encoding: buffer.BufferEncoding = 'utf-8'): string {
    return buffer.from(src).toString(encoding);
  }

  /**
   * ArrayBuffer 转 Uint8Array
   * @param src ArrayBuffer
   * @returns Uint8Array
   */
  static bufferToUint8Array(src: ArrayBuffer): Uint8Array {
    return new Uint8Array(src);
  }

  /**
   * Uint8Array 转 ArrayBuffer
   * @param src Uint8Array
   * @returns ArrayBuffer
   */
  static uint8ArrayToBuffer(src: Uint8Array): ArrayBuffer {
    return src.buffer;
  }

  /**
   * 获取系统错误码对应的详细信息
   * @param errno 错误码
   * @returns 错误信息
   */
  static getErrnoToString(errno: number): string {
    return util.errnoToString(errno);
  }
}