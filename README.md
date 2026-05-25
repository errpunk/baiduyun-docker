# baiduyun-docker

把百度网盘封装成 docker 容器，供群晖 NAS 使用。

参考了 [funcman/115pc](https://github.com/funcman/docker_115pc)

## 镜像信息

- **基础镜像**: `jlesage/baseimage-gui:ubuntu-22.04-v4`
- **百度网盘版本**: `4.17.8`
- **架构**: `linux/amd64`（适配群晖 x86_64 机型）
- **镜像大小**: ~645MB

## 快速开始

### 1. 构建镜像

```bash
docker build -t baiduyun:synology .
```

### 2. 运行容器

```bash
docker run -d \
  --name baiduyun \
  -p 5800:5800 \
  -p 5900:5900 \
  -v /volume1/docker/baiduyun/config:/config \
  -v /volume1/downloads:/downloads \
  -e USER_ID=1026 \
  -e GROUP_ID=100 \
  -e DISPLAY_WIDTH=1920 \
  -e DISPLAY_HEIGHT=1080 \
  --restart unless-stopped \
  baiduyun:synology
```

## 群晖 NAS 部署指南

### 使用 Container Manager（DSM 7.x）

1. **上传镜像**
   - 打开 Container Manager → 映像 → 新增 → 从文件添加
   - 选择构建好的 `baiduyun:synology` 镜像 tar 包（或用 SSH 导入）

2. **创建容器**
   - 映像 → 选择 `baiduyun:synology` → 运行
   - **容器名称**: `baiduyun`
   - **端口设置**:
     - 本地端口 `5800` → 容器端口 `5800`（Web VNC 界面）
     - 本地端口 `5900` → 容器端口 `5900`（原生 VNC，可选）
   - **存储空间设置**:
     - `/config` → 映射到群晖的持久化目录（如 `/volume1/docker/baiduyun/config`）
     - `/downloads` → 映射到群晖的下载目录（如 `/volume1/downloads`）
   - **环境变量**:
     - `USER_ID`: 群晖用户的 UID（默认 `1026`，可在 SSH 用 `id` 查看）
     - `GROUP_ID`: 群晖用户的 GID（默认 `100`）
     - `DISPLAY_WIDTH`: 显示宽度（默认 `1920`）
     - `DISPLAY_HEIGHT`: 显示高度（默认 `1080`）
   - **重启策略**: 除非手动停止，否则总是重启

3. **访问百度网盘**
   - 打开浏览器访问 `http://<群晖IP>:5800`
   - 首次使用需要登录百度账号

### 使用 Docker（DSM 6.x 或命令行）

```bash
docker run -d \
  --name baiduyun \
  -p 5800:5800 \
  -p 5900:5900 \
  -v /volume1/docker/baiduyun/config:/config \
  -v /volume1/downloads:/downloads \
  -e USER_ID=1026 \
  -e GROUP_ID=100 \
  --restart unless-stopped \
  baiduyun:synology
```

## 端口说明

| 端口 | 说明 |
|------|------|
| 5800 | Web VNC 界面（浏览器访问） |
| 5900 | 原生 VNC 协议（可用 VNC 客户端连接） |

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `USER_ID` | `0` | 运行用户 ID（建议改为群晖用户 UID） |
| `GROUP_ID` | `0` | 运行用户组 ID（建议改为群晖用户 GID） |
| `DISPLAY_WIDTH` | `1920` | 虚拟显示宽度 |
| `DISPLAY_HEIGHT` | `1080` | 虚拟显示高度 |
| `ENABLE_CJK_FONT` | `1` | 启用中文字体支持 |

## 查看群晖 UID/GID

通过 SSH 登录群晖，执行：

```bash
id <你的用户名>
# 例如：id admin
# uid=1026(admin) gid=100(users) groups=100(users),101(administrators)
```

将 `uid=` 后的数字填入 `USER_ID`，`gid=` 后的数字填入 `GROUP_ID`。

## 注意事项

- 群晖 NAS 需开启 Docker / Container Manager 套件
- 建议为 `/downloads` 映射足够的存储空间
- 下载路径在容器内为 `/downloads`，在百度网盘客户端中可选择该路径
- 如需更新百度网盘版本，修改 `Dockerfile` 中的 `APP_VERSION` 后重新构建

## License

MIT
