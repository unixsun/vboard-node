# vboard-node

VBoard Linux 子节点的公开安装入口与 Release 下载仓库。

此仓库只发布安装脚本和编译后的节点程序，不包含 VBoard 面板源码、服务器
Token、数据库配置或其他私密信息。

## 安装

先在 VBoard 管理后台创建服务器，并取得服务器 Token 和机器 ID，然后在目标
Linux 服务器执行：

```bash
curl -fsSL https://raw.githubusercontent.com/unixsun/vboard-node/main/install.sh | sudo bash -s -- \
  --mode machine \
  --panel "https://panel.example.com" \
  --token "vbnode_xxx" \
  --machine-id 1 \
  --kernel sing-box \
  --kernel-mode embedded \
  --enable-kernel \
  --enable-upgrade
```

`--panel` 必须是子节点能够访问的面板地址。服务器 Token 具有节点配置拉取、
心跳、流量和在线设备上报权限，请妥善保管，不要写入脚本或提交到仓库。

## TLS 节点

Trojan TLS、Hysteria2、TUIC 或启用 TLS 的 VMess 节点需要配置证书：

```bash
--certificate-path /etc/letsencrypt/live/node.example.com/fullchain.pem \
--key-path /etc/letsencrypt/live/node.example.com/privkey.pem
```

## Release 文件

正式 Release 应至少包含：

```text
vboard-node-linux-amd64
vboard-node-linux-amd64.sha256
vboard-node-linux-arm64
vboard-node-linux-arm64.sha256
```

安装器会在执行二进制前校验 SHA256。生产环境不要使用
`--skip-checksum`。

安装器默认从本仓库的 GitHub Releases 下载与当前 Linux 架构匹配的最新版
节点程序，因此常规安装不需要额外传入 `--binary-url` 或
`--release-base`。

## 常用命令

```bash
systemctl status vboard-node --no-pager
journalctl -u vboard-node -f
systemctl restart vboard-node
sudo bash install.sh status
sudo bash install.sh uninstall
```

节点服务默认启用 systemd 安全限制，并通过受控升级服务执行固定的
HTTPS 下载、SHA256 校验、版本自检、备份、替换和失败回滚流程。
