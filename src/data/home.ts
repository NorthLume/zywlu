export const topics = [
  {
    index: '01',
    label: 'WEB FOUNDATIONS',
    title: 'Web 构建',
    description: '从语义化 HTML 到现代静态架构，关注真实体验，而不是堆叠框架。',
    tags: ['HTML / CSS', 'Astro', '性能'],
  },
  {
    index: '02',
    label: 'SHIP & OPERATE',
    title: '服务器与部署',
    description: '记录从空白服务器到稳定上线的完整路径，也记录每一步如何回退。',
    tags: ['Linux', 'Nginx', '自动化'],
  },
  {
    index: '03',
    label: 'WORK IN PUBLIC',
    title: '开源协作',
    description: '把仓库、文档、Issue 和评审流程整理成每个人都能参与的共同语言。',
    tags: ['Git', 'GitHub', '社区'],
  },
  {
    index: '04',
    label: 'WEB FOR EVERYONE',
    title: '无障碍体验',
    description: '让键盘、辅助技术、旧设备和低速网络用户都能顺利获取信息。',
    tags: ['WCAG', '可用性', '低带宽'],
  },
] as const;

export const firstGuides = [
  {
    number: '001',
    status: '正在整理',
    category: '服务器基础',
    title: '从零初始化一台 Ubuntu 24.04 服务器',
    description: '账号、更新、防火墙、SSH 与目录约定，一次建立可长期维护的服务器基线。',
    meta: '预计 12 分钟 · 含检查清单',
  },
  {
    number: '002',
    status: '首批计划',
    category: '网站部署',
    title: '使用 Astro 与 Nginx 发布静态网站',
    description: '构建、版本目录、健康检查与快速回退的完整发布流程。',
    meta: '预计 10 分钟 · 含配置模板',
  },
  {
    number: '003',
    status: '首批计划',
    category: '开源协作',
    title: '把 GitHub 仓库从“能用”整理到“能协作”',
    description: '从 README、工程约定到质量门槛，建立一个对贡献者友好的仓库。',
    meta: '预计 8 分钟 · 含仓库模板',
  },
] as const;

export const writingPrinciples = [
  {
    index: '01',
    title: '先写清环境',
    description: '系统、版本、依赖和前置条件都放在开头，让读者先判断是否适用。',
  },
  {
    index: '02',
    title: '命令必须跑过',
    description: '示例来自真实执行，关键步骤同时给出预期输出和验证方式。',
  },
  {
    index: '03',
    title: '错误也要留下',
    description: '记录失败现象、定位过程和回退路径，让踩过的坑真正产生价值。',
  },
  {
    index: '04',
    title: '内容持续校验',
    description: '文章标注最后验证日期；环境变化后更新正文，而不是只追加一句提醒。',
  },
] as const;
