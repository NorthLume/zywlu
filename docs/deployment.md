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

```bash
DEPLOY_HOST=HOST \
DEPLOY_USER=root \
DEPLOY_DOMAIN=DOMAIN \
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

将版本化脚本上传到服务器后执行：

```bash
sudo bash scripts/rollback-release.sh
```

回滚脚本交换 `current` 与 `previous` 链接，执行 `nginx -t` 后平滑重载。完成后重新运行发布后检查。

## HTTPS

域名解析生效后，使用 Certbot 为 Nginx 申请证书并启用自动续期。证书签发前保留 HTTP 配置，避免预先强制 HTTPS。
