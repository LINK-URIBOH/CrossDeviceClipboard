import pasteboard from '@ohos.pasteboard';
import { WebServer, ServerInfo } from '@cxy/webserver';
import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';

export type ClipCallback = (clip: string) => void;
export interface ClipboardBody {
  text: string;
  timestamp?: number;
}

class ClipboardWebService {
  private server: WebServer | null = null;
  private serverInfo: ServerInfo | null = null;
  private key: string = '';
  private clipboardHistory: Array<string> = [];
  private sysPb: pasteboard.SystemPasteboard | null = null;
  private pollTimer?: number;
  private staticRoot: string = '';

  constructor() {
    this.sysPb = pasteboard.getSystemPasteboard();
  }

  // /** 获取当前密钥 */
  // getKey(): string {
  //   return this.key;
  // }
  //
  // /** 生成一次性6位密钥 */
  // private generateKey(): string {
  //   const k = Math.floor(Math.random() * 900000 + 100000).toString();
  //   this.key = k;
  //   setTimeout(() => {
  //     this.key = '';
  //   }, 5 * 60 * 1000);
  //   return this.key;
  // }

  /** 初始化静态资源目录 */
  private async setupStatic(): Promise<void> {
    const context = getContext(this) as common.UIAbilityContext;
    this.staticRoot = `${context.filesDir}/web`;
    const exists = await fileIo.access(this.staticRoot);
    if (!exists) {
      await fileIo.mkdir(this.staticRoot);
    }

    // 拷贝 index.html
    const buf = await context.resourceManager.getRawFileContent('index.html');
    const path = `${this.staticRoot}/index.html`;
    const outFile = await fileIo.open(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
    await fileIo.write(outFile.fd, buf.buffer);
    await fileIo.close(outFile.fd);
  }

  /** 轮询剪贴板 */
  private async pollClipboard(cb: ClipCallback): Promise<void> {
    this.pollTimer = setInterval(async () => {
      if (!this.sysPb) this.sysPb = pasteboard.getSystemPasteboard();
      const pd = await this.sysPb!.getPasteData();
      if (pd) {
        const text = pd.getPrimaryText();
        if (text && text.length > 0 && !this.clipboardHistory.includes(text)) {
          this.clipboardHistory.unshift(text);
          cb(text);
        }
      }
    }, 2000) as number;
  }

  /** 启动服务 */
  async start(cb: ClipCallback, port: number = 8080): Promise<void> {
    if (this.server) {
      console.log('Server already running');
      return;
    }
    await this.setupStatic();

    this.server = new WebServer();
    this.server.logger();
    this.server.cors();
    this.server.auto();
    this.server.serveStatic(this.staticRoot);

    // const currentKey = this.generateKey();
    // console.log(`Clipboard WebService started, key=${currentKey}`);

    // GET /clipboard
    this.server.get('/clipboard', (req, res) => {
      // const key = req.query.get('key');
      // if (key !== this.key) {
      //   res.status(403).json({ error: 'Forbidden' });
      //   return;
      // }
      res.json(this.clipboardHistory);
    });

    this.server.get('/latest', (req, res) => {
      if (this.clipboardHistory.length > 0) {
        res.json({
          text: this.clipboardHistory[0],
          timestamp: Date.now()
        });
      } else {
        res.status(404).json({ error: 'Clipboard is empty' });
      }
    });

    // POST /clipboard
    this.server.post('/clipboard', async (req, res) => {
      // const key = req.query.get('key');
      // if (key !== this.key) {
      //   res.status(403).json({ error: 'Forbidden' });
      //   return;
      // }
      try {
        const body = req.body as ClipboardBody;
        if (body?.text) {
          if (!this.clipboardHistory.includes(body.text)) {
            this.clipboardHistory.unshift(body.text);
          }
          if (!this.sysPb) this.sysPb = pasteboard.getSystemPasteboard();
          const data = pasteboard.createPlainTextData(body.text);
          await this.sysPb!.setData(data);
        }
        res.json({ status: 'ok' });
      } catch (e) {
        res.status(400).json({ error: 'Bad Request' });
      }
    });

    this.serverInfo = await this.server.startServer(port);
    console.log(`Clipboard WebServer running on http://${this.serverInfo.address}:${this.serverInfo.port}`);
    this.pollClipboard(cb);
  }

  /** 停止服务 */
  async stop(): Promise<void> {
    if (this.server) {
      await this.server.stopServer();
      this.server = null;
    }
    if (this.pollTimer) {
      clearInterval(this.pollTimer);
    }
    // this.key = '';
    this.serverInfo = null;
    console.log('Clipboard WebService stopped');
  }
}

export default new ClipboardWebService();
