# FastGit 的 nginx 配置文件
这是 `/etc/nginx` 目录下的配置文件，用于为 FastGit 提供服务。

## 文件结构
- `sites-enabled` 下存放各个子站点的配置，以域名命名。
- `modules-enabled` 下存放各个模块的配置，以模块名命名。目前这些模块的路径是为 Arch Linux AUR 的 `nginx-mainline-mod-*` 包设计的，其他发行版可能需要修改路径。
- `nginx.conf` 是主配置文件，包含了 `sites-enabled` 和 `modules-enabled` 下的所有配置。
- `snippets` 下存放一些配置片段，以功能命名。
其余部分文件为 nginx 的默认配置文件，不作介绍。


## 配置文件说明 & 安装指南
- `nginx.conf` 中配置有 `proxy_cache_path`，用于为 `raw` 和 `assets` 站点提供缓存。默认大小为 16G，路径为 `/var/cache/nginx`，可以根据需要修改。
- `snippets/ssl.conf` 为所有站点提供了 SSL 配置与 Web 端口监听。证书路径为 letsencrypt 的默认路径，可以根据需要修改。监听配置里面默认开启 QUIC，如果不需要可以注释对应行。
- `snippets/cache.conf` 是缓存配置，目前为 `raw` 提供缓存设置，默认缓存时间为 5 分钟，如果入站流量较大可以适当调大。*备注：`assets` 站点的缓存配置在 `sites-enabled/archive.<domain>.conf`，其默认缓存时间为 480 分钟，因为这个站点的文件不会经常更新。*
- `snippets/block-bot.conf` 用于屏蔽爬虫的 UA，避免本站被爬虫爬取。
- `snippets/compression.conf` 用于开启 gzip 和 brotli 压缩，提高传输效率。如果没有对应的模块，请注释对应行。
- `snippets/denylist.conf` 用于屏蔽某些 URL (location) 的访问。
- `snippets/cloudflare-real-ip.conf` 用于获取 Cloudflare 的真实 IP 地址，默认未启用，如果需要请在 `nginx.conf` 中 include 这个文件。
- `snippets/nobuffer.conf` 用于关闭 nginx 的缓冲，避免入站流量过大及硬盘 I/O 过大。
- `snippets/universal-headers.conf` (需改进) 用于设置一些通用的 HTTP 头，如 HSTS、Referrer-Policy 等。
- `sites-enabled/http-redir` 监听 80 端口，为本域名的所有站点提供 HTTP 重定向到 HTTPS 的功能。
- `conf.d/stream.conf` 用于配置 nginx stream，默认不启用，如果原配置中有需要 HTTPS 的后端 (例如 traefik)，可以在 `nginx.conf` 中取消注释，同时更改 `snippets/ssl.conf` 中的监听端口。
