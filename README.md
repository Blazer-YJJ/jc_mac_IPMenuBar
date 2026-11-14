# IPMenuBar

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2012%2B-lightgrey.svg)](#环境要求)
[![Language](https://img.shields.io/badge/Swift-5-orange.svg)](Sources/main.swift)

在 macOS 菜单栏常驻显示**本机局域网 IP** 的小工具。点一下就能复制，插拔网线、切 Wi‑Fi 会自动跟着变。

纯 AppKit 手写，无第三方依赖，**没有网络请求**——地址全部来自本机 `getifaddrs()`，不会把你的 IP 发到任何地方。

![菜单栏效果](screenshots/menubar.png)

## 为什么

调移动端 / 小程序时，天天要在终端里敲 `ifconfig | grep inet`，或者在「系统设置 → 网络」里翻半天。
把 IP 放到菜单栏，扫一眼就能看到，点一下就进剪贴板，粘到手机浏览器里就能连本机 dev server。

## 功能

| 能力 | 说明 |
| --- | --- |
| 常驻显示 | 菜单栏显示 `IP 192.168.x.x`，不占 Dock、不抢焦点（`LSUIElement`） |
| 自动刷新 | 每 5 秒重新枚举网卡，切网 / 插拔网线即时更新 |
| 智能优选 | en0（Wi‑Fi/以太网）→ en1（USB/雷雳网卡）→ 其他 `en*` |
| 点按复制 | 菜单里点 IP 即复制；也可 ⌘C |
| 多网卡 | 「切换网卡」子菜单可固定任意一块网卡 |
| 干扰项过滤 | 自动跳过 `127.*`、`169.254.*`、`utun*`、`awdl*`、`llw*` |
| 开机自启 | `make install` 会装到 `/Applications` 并注册 LaunchAgent |

菜单项：**复制 IP**（⌘C）· **刷新**（⌘R）· **切换网卡** · **退出**（⌘Q）。

## 环境要求

- macOS 12 Monterey 或更新
- 从源码编译需要 Xcode Command Line Tools：`xcode-select --install`

## 安装

### 从源码编译

```bash
git clone https://github.com/Blazer-YJJ/jc_mac_IPMenuBar.git
cd ip-menubar

make run       # 编译并直接运行（不装自启）
make install   # 编译 + 装到 /Applications + 注册登录自启
```

只想要一个可双击的 App：

```bash
make bundle
open build/IPMenuBar.app
```

### 直接用现成包

到 [Releases](https://github.com/Blazer-YJJ/jc_mac_IPMenuBar/releases) 下载 `IPMenuBar.app.zip` 解压，拖进「应用程序」即可。
包是 ad-hoc 签名（没有 Apple 开发者账号），首次打开若被 Gatekeeper 拦下：

```bash
xattr -dr com.apple.quarantine /Applications/IPMenuBar.app
```

## 卸载

```bash
make uninstall
```

等价于：`launchctl bootout gui/$(id -u)/io.github.blazeryjj.ipmenubar`、
删 `~/Library/LaunchAgents/io.github.blazeryjj.ipmenubar.plist`、删 `/Applications/IPMenuBar.app`。

只想临时关掉（下次登录还会回来）：

```bash
launchctl bootout gui/$(id -u)/io.github.blazeryjj.ipmenubar
```

## 实现

只有一个文件 [Sources/main.swift](Sources/main.swift)，大约 150 行：

1. `getifaddrs()` 遍历 `AF_INET` 地址，`getnameinfo(NI_NUMERICHOST)` 取点分十进制；
2. 过滤回环 / 链路本地 / 虚拟网卡，按 en0 → en1 → en* 排序取首选；
3. `NSStatusItem` 显示文字，`Timer` 每 5 秒刷新一次；
4. `NSMenu` 每次刷新重建，网卡列表和当前选中项实时同步。

App Bundle 就是 `Makefile` 里那几行：拷二进制 + 填 `Info.plist`（`LSUIElement=true`）+ ad-hoc `codesign`。

## 目录

```text
.
├── Sources/main.swift       # 全部逻辑
├── Resources/Info.plist     # Bundle 模板
├── Makefile                 # build / bundle / run / install / uninstall
├── scripts/install.sh       # 装 App + LaunchAgent
├── scripts/uninstall.sh
└── screenshots/menubar.png
```

## 已知行为

- 菜单里点「退出」会真的退出；`KeepAlive=false`，launchd 不会立刻把它拉起来，重新登录后才回来。
- 菜单栏文字宽度会随 IP 长度变化，属于预期行为。
- 只处理 IPv4；IPv6 未实现（欢迎 PR）。

## English

A tiny macOS menu bar app that shows your LAN IPv4 address. No dependencies, no network calls — it reads `getifaddrs()` locally. Click to copy, auto-refreshes every 5s, follows network changes.

```bash
make run       # build & run
make install   # build, copy to /Applications, register login item
make uninstall
```

MIT licensed.

## License

[MIT](LICENSE) © 2026 杨景丞 (Jingcheng Yang)
