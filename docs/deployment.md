# 生产部署

## 环境基线

- Ubuntu 24.04 LTS
- Nginx
- SSH 运维入口
- 站点目录：`/var/www/zywlu`
- 当前版本：`/var/www/zywlu/current`
- 上一版本：`/var/www/zywlu/previous`

## 首次与后续发布

发布脚本从当前已验证提交构建静态产物，上传到独立版本目录，通过符号链接原子切换版本，并保留最近三个版本。
远程切换后会执行 HTTP 健康检查；检查失败时自动运行回滚命令，检查成功后清理上传暂存目录。

```bash
DEPLOY_HOST=HOST \
DEPLOY_USER=root \
DEPLOY_DOMAIN="DOMAIN www.DOMAIN" \
bash scripts/deploy.sh
```

域名接入前可将 `DEPLOY_DOMAIN` 设为 `_`。部署凭据由 SSH Agent、密钥或交互式密码输入提供，仓库与命令参数中不保存凭据。

## 发布后检查

```bash
curl --fail --head http://HOST/
curl --fail http://HOST/ | grep '把复杂技术'
curl --fail --head http://HOST/favicon.svg
curl --silent --output /dev/null --write-out '%{http_code}\n' http://HOST/missing-page
ssh root@HOST 'systemctl is-active nginx && nginx -t'
```

预期结果：主页与 favicon 返回 `200`，缺失路径返回品牌 404 页面与 `404` 状态，Nginx 为 `active` 且配置检查通过。

## 回滚

部署脚本会把版本化回滚命令安装到服务器，执行：

```bash
sudo zywlu-rollback
```

回滚脚本交换 `current` 与 `previous` 链接，执行 `nginx -t` 后平滑重载。完成后重新运行发布后检查。

## HTTPS

域名解析生效后，上传 HTTPS 模板与启用脚本并执行：

```bash
sudo env \
  PRIMARY_DOMAIN=DOMAIN \
  SERVER_NAMES="DOMAIN www.DOMAIN" \
  CERTIFICATE_DOMAINS="DOMAIN www.DOMAIN" \
  CERT_NAME=DOMAIN \
  EMAIL=EMAIL \
  HTTPS_TEMPLATE=/tmp/zywlu-https.conf \
  bash scripts/enable-https.sh
```

脚本使用 Webroot 方式签发证书，安装 HTTPS 站点与 HTTP `308` 跳转，启用 `certbot.timer`，安装续期后的 Nginx 平滑重载钩子，并执行一次模拟续期。
