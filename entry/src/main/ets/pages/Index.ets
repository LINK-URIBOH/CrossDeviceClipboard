import { abilityAccessCtrl, common, Permissions, bundleManager, wantAgent, WantAgent } from '@kit.AbilityKit';
import { pasteboard, BusinessError } from '@kit.BasicServicesKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import webServer from '../services/WebServer';
import { PasteboardUtil } from '../utils/PasteboardUtil';
import wifiManager from '@ohos.wifiManager';

async function checkAccessToken(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
  let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

  try {
    const bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
    );
    const tokenId = bundleInfo.appInfo.accessTokenId;
    grantStatus = await atManager.checkAccessToken(tokenId, permission);
  } catch (error) {
    const err: BusinessError = error as BusinessError;
    console.error(`checkAccessToken error: ${err.message}`);
  }
  return grantStatus;
}
const ipInfo = wifiManager.getIpInfo();
function getIpAddrFromNum(ipNum: number): string {
  return (ipNum >>> 24) + '.' + (ipNum >> 16 & 0xFF) + '.' + (ipNum >> 8 & 0xFF) + '.' + (ipNum & 0xFF);
}

@Entry
@Component
struct Index {
  private TAG: string = 'ClipboardIndex';

  @State clipboardList: Array<string> = [];
  @State serviceRunning: boolean = false;
  @State permissionGranted: boolean = false;
  @State statusMessage: string = '';
  @State backgroundRunning: boolean = false;

  /** 请求权限 */
  reqPermissionsFromUser(permissions: Array<Permissions>): void {
    const context = getContext(this) as common.UIAbilityContext;
    const atManager = abilityAccessCtrl.createAtManager();
    atManager.requestPermissionsFromUser(context, permissions).then((data) => {
      const grantStatus: Array<number> = data.authResults;
      for (let i = 0; i < grantStatus.length; i++) {
        if (grantStatus[i] === 0) {
          this.permissionGranted = true;
          this.statusMessage = '申请权限成功';
        } else {
          this.permissionGranted = false;
          this.statusMessage = '申请权限失败，请到系统设置中开启权限';
        }
      }
    }).catch((err: string) => {
      console.error('requestPermissionsFromUser failed: ' + err);
    });
  }

  /** 手动获取剪贴板内容 */
  async getPaste(): Promise<void> {
    const permissions: Array<Permissions> = ['ohos.permission.READ_PASTEBOARD'];
    const grantStatus = await checkAccessToken(permissions[0]);

    if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      this.permissionGranted = true;
      try {
        const text = await PasteboardUtil.getDataStr();
        if (text && text.length > 0) {
          this.clipboardList.unshift(text);
          this.statusMessage = `剪贴板内容：${text}`;
        } else {
          this.statusMessage = '剪贴板为空';
        }
      } catch (err) {
        const e = err as BusinessError;
        hilog.error(0x0000, this.TAG, `getDataStr error: ${e.message}`);
        this.statusMessage = '读取剪贴板失败';
      }
    } else {
      this.reqPermissionsFromUser(permissions);
    }
  }

  /** 启停 Web 服务 */
  toggleService(): void {
    if (this.serviceRunning) {
      webServer.stop();
      this.serviceRunning = false;
      // this.serviceKey = '';
    } else {
      webServer.start((newClip: string) => {
        if (newClip.length > 0 && !this.clipboardList.includes(newClip)) {
          this.clipboardList.unshift(newClip);
        }
      }).then(() => {
        // this.serviceKey = webServer.getKey();
      });
      this.serviceRunning = true;
    }
  }

  /** 开启长时任务 */
  startContinuousTask(): void {
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: "cn.valna.crossdeviceclipboard",
          abilityName: "EntryAbility"
        }
      ],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      actionFlags: [
        wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG,
        wantAgent.WantAgentFlags.CONSTANT_FLAG
      ]
    };

    try {
      wantAgent.getWantAgent(wantAgentInfo).then((wantAgentObj: WantAgent) => {
        try {
          backgroundTaskManager.startBackgroundRunning(
            getContext(),
            backgroundTaskManager.BackgroundMode.DATA_TRANSFER,
            wantAgentObj,
            (error: BusinessError) => {
              if (error) {
                console.error(this.TAG, `startBackgroundRunning failed: ${error.message}`);
              } else {
                console.info(this.TAG, "startBackgroundRunning succeeded");
                promptAction.showToast({ message: "开启长时任务成功！" });
                this.backgroundRunning = true;
                this.serviceRunning = false;
                this.toggleService();
              }
            }
          );
        } catch (error) {
          const e = error as BusinessError;
          console.error(this.TAG, `startBackgroundRunning failed: ${e.message}`);
        }
      });
    } catch (error) {
      const e = error as BusinessError;
      console.error(this.TAG, `getWantAgent failed: ${e.message}`);
    }
  }

  /** 关闭长时任务 */
  stopContinuousTask(): void {
    backgroundTaskManager.stopBackgroundRunning(getContext())
      .then(() => {
        console.info(this.TAG, 'stopBackgroundRunning success');
        promptAction.showToast({ message: "取消长时任务！" });
        this.backgroundRunning = false;
        this.serviceRunning = true;
        this.toggleService();
      })
      .catch((err: BusinessError) => {
        console.error(this.TAG, `stopBackgroundRunning failed: ${err.message}`);
      });
  }

  /** UI 构建 */
  build() {
    Column({ space: 16 }) {
      Text('鸿蒙剪贴板服务')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)

      Row({ space: 3 }) {
        Button(this.serviceRunning ? "停止服务" : "开启服务")
          .fontSize(12.5)
          .onClick(() => this.toggleService())
          .width('33.3%')
        Button('获取剪贴板')
          .fontSize(12.5)
          .onClick(() => this.getPaste())
          .width('33.3%')
        Button(this.backgroundRunning ? '停止长时任务' : '启动长时任务')
          .fontSize(12.5)
          .onClick(() => this.backgroundRunning ? this.stopContinuousTask() : this.startContinuousTask())
          .width('33.3%')
      }

      if (this.statusMessage.length > 0) {
        Text(this.statusMessage)
          .fontSize(14)
          .fontColor(Color.Gray)
      }

      if (this.serviceRunning) {
        Column() {
          // Text(`服务密钥: ${this.serviceKey}`)
          //   .fontColor(Color.Green)
          //   .fontSize(12)
          Text(`Web 服务: http://${getIpAddrFromNum(ipInfo.ipAddress)}:8080`)
            .fontSize(12)
            .fontColor(Color.Gray)
          Text(`获取列表: GET http://${getIpAddrFromNum(ipInfo.ipAddress)}:8080/clipboard`)
            .fontSize(12)
            .fontColor(Color.Gray)
          Text(`获取最新内容: GET http://${getIpAddrFromNum(ipInfo.ipAddress)}:8080/latest`)
            .fontSize(12)
            .fontColor(Color.Gray)
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
      }

      Text('剪贴板内容：')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)

      List() {
        ForEach(this.clipboardList, (item: string, index: number) => {
          ListItem() {
            Text(`${index + 1}. ${item}`)
              .fontSize(14)
              .lineHeight(20)
          }
        })
      }
      .height('60%')
    }
    .padding(20)
    .justifyContent(FlexAlign.Start)
  }
}
