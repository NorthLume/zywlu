import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath, URL } from 'node:url';

const distDirectory = fileURLToPath(new URL('../dist/', import.meta.url));

async function collectHtmlFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    const target = path.join(directory, entry.name);

    if (entry.isDirectory()) {
      files.push(...(await collectHtmlFiles(target)));
    } else if (entry.isFile() && entry.name.endsWith('.html')) {
      files.push(target);
    }
  }

  return files;
}

const htmlFiles = await collectHtmlFiles(distDirectory);
const relativeFiles = htmlFiles.map((file) => path.relative(distDirectory, file));
const requiredFiles = ['index.html', '404.html'];
const missingFiles = requiredFiles.filter((file) => !relativeFiles.includes(file));

if (missingFiles.length > 0) {
  throw new Error(`缺少必需构建页面：${missingFiles.join(', ')}`);
}

const violations = [];

for (const file of htmlFiles) {
  const html = await readFile(file, 'utf8');
  const relativeFile = path.relative(distDirectory, file);

  if (/<style(?:\s|>)/i.test(html)) {
    violations.push(`${relativeFile}: 包含内联 <style>`);
  }

  if (/\sstyle\s*=/i.test(html)) {
    violations.push(`${relativeFile}: 包含内联 style 属性`);
  }

  if (!/<link\s[^>]*rel=["']stylesheet["'][^>]*>/i.test(html)) {
    violations.push(`${relativeFile}: 缺少外部样式表`);
  }
}

if (violations.length > 0) {
  throw new Error(`构建产物与生产 CSP 不兼容：\n${violations.join('\n')}`);
}

process.stdout.write(`构建产物 CSP 检查通过：${relativeFiles.join(', ')}\n`);
