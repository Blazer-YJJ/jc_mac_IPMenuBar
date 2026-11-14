//
//  IPMenuBar — 在 macOS 菜单栏常驻显示本机局域网 IPv4
//  https://github.com/Blazer-YJJ/jc_mac_IPMenuBar
//
//  纯 AppKit，无第三方依赖，无网络请求：地址全部来自本机 getifaddrs()。
//

import AppKit

struct Interface {
    let name: String
    let address: String
}

/// 枚举本机所有 IPv4 地址，过滤回环、链路本地（169.254）与虚拟网卡。
func localIPv4Interfaces() -> [Interface] {
    var result: [Interface] = []
    var addrs: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&addrs) == 0 else { return result }
    defer { freeifaddrs(addrs) }

    var cursor = addrs
    while let ptr = cursor {
        let ifa = ptr.pointee
        defer { cursor = ifa.ifa_next }
        guard let sa = ifa.ifa_addr, sa.pointee.sa_family == UInt8(AF_INET) else { continue }

        let name = String(cString: ifa.ifa_name)
        var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let rc = getnameinfo(sa, socklen_t(sa.pointee.sa_len),
                             &host, socklen_t(host.count),
                             nil, 0, NI_NUMERICHOST)
        guard rc == 0 else { continue }

        let ip = String(cString: host)
        if ip.hasPrefix("127.") || ip.hasPrefix("169.254.") || ip == "0.0.0.0" { continue }
        if name.hasPrefix("utun") || name.hasPrefix("llw") || name.hasPrefix("awdl") { continue }
        result.append(Interface(name: name, address: ip))
    }
    return result
}

/// 首选地址：en0（Wi-Fi/以太网）→ en1（USB/雷雳网卡）→ 其他 en* → 任意。
func preferredInterface(_ all: [Interface]) -> Interface? {
    if let en0 = all.first(where: { $0.name == "en0" }) { return en0 }
    if let en1 = all.first(where: { $0.name == "en1" }) { return en1 }
    if let en = all.first(where: { $0.name.hasPrefix("en") }) { return en }
    return all.first
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var timer: Timer?
    private var interfaces: [Interface] = []
    private var primary: Interface?
    /// 用户手动选定的网卡（nil 表示自动选择）
    private var pinnedName: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)

        refresh()
        let t = Timer(timeInterval: 5, repeats: true) { [weak self] _ in self?.refresh() }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func copyToPasteboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    /// 每 5 秒刷新一次：插拔网线、切换 Wi-Fi 后菜单栏文字会跟着变。
    private func refresh() {
        interfaces = localIPv4Interfaces()
        if let pinned = pinnedName, let hit = interfaces.first(where: { $0.name == pinned }) {
            primary = hit
        } else {
            primary = preferredInterface(interfaces)
        }

        if let button = statusItem.button {
            button.title = primary.map { "IP \($0.address)" } ?? "IP —"
            button.toolTip = primary.map { "\($0.name): \($0.address)（点按可复制）" }
                ?? "未检测到局域网 IPv4 地址"
        }
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let title = NSMenuItem(title: "本机局域网 IP", action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)

        if let p = primary {
            let row = NSMenuItem(title: "\(p.address)   (\(p.name))", action: #selector(copyPrimary), keyEquivalent: "")
            row.target = self
            menu.addItem(row)
        } else {
            let row = NSMenuItem(title: "未检测到 IPv4 地址", action: nil, keyEquivalent: "")
            row.isEnabled = false
            menu.addItem(row)
        }

        menu.addItem(.separator())

        let copyItem = NSMenuItem(title: "复制 IP", action: #selector(copyPrimary), keyEquivalent: "c")
        copyItem.target = self
        copyItem.isEnabled = primary != nil
        menu.addItem(copyItem)

        let refreshItem = NSMenuItem(title: "刷新", action: #selector(refreshNow), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        if interfaces.count > 1 {
            let submenu = NSMenu()
            for iface in interfaces {
                let item = NSMenuItem(title: "\(iface.name)  \(iface.address)",
                                      action: #selector(selectInterface(_:)),
                                      keyEquivalent: "")
                item.target = self
                item.representedObject = iface.name
                item.state = (iface.name == primary?.name) ? .on : .off
                submenu.addItem(item)
            }
            let submenuItem = NSMenuItem(title: "切换网卡", action: nil, keyEquivalent: "")
            submenuItem.submenu = submenu
            menu.addItem(submenuItem)
        }

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func copyPrimary() {
        guard let ip = primary?.address else { return }
        copyToPasteboard(ip)
    }

    @objc private func refreshNow() {
        pinnedName = nil
        refresh()
    }

    @objc private func selectInterface(_ sender: NSMenuItem) {
        pinnedName = sender.representedObject as? String
        refresh()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
