---
name: visual-reference-web-image
description: Direct new raster-image generation from text and multiple reference images, assigning each reference a controlled role such as subject, style, pose, composition, outfit, lighting, or background, confirming the visual plan, and generating through the user's logged-in ChatGPT website without silently falling back to the Codex image backend. Use when the user wants reference images combined, character consistency, a reusable visual preset, or ChatGPT Web image generation that conserves Codex image usage. Do not use for pixel-accurate editing of an existing image, vector work, or public end-user generation services.
---

# 视觉参考 · ChatGPT 网页生图

把参考图的角色拆清楚，先让用户看懂组合方案，再通过已登录的 ChatGPT Chrome 会话生成。底层包装器固定调用 `image-use --backend web`；除非用户明确要求消耗 Codex 生图额度，否则不得改成 `auto` 或 `codex`。

没有参考图时，跳过参考拆分，直接整理文字提示词并进入“生成”。只有风格分析问题时只解释，不生成。

## 1. 分配参考图角色

为每张图指定一个或多个角色：

- `SUBJECT`：人物或主体身份
- `STYLE`：媒介、质感、色调、光学表现
- `POSE`：动作和身体关系
- `EXPRESSION`：表情与视线
- `COMPOSITION`：机位、景别、裁切、空间布局
- `OUTFIT`：服装与配饰
- `LIGHTING`：光线性质
- `BACKGROUND`：场景环境
- `ATMOSPHERE`：情绪转译
- `PROP`：手持或交互物件

用户的明确说法优先于自动判断。能判断时直接进入确认单；只有歧义会实质改变成图时才一次问一个问题。

分析参考图时读取 [references/extraction-schema.md](references/extraction-schema.md)，只填写与该图角色相关且能观察到的字段。SUBJECT 只取身份锚点，不继承原姿势、服装、背景、构图或光线。风格必须翻译成可观察属性；动作必须描述关节、支撑、朝向和接触关系。

## 2. 防止属性串味

在内部为每张参考图写 `KEEP / IGNORE`：

```text
图A · SUBJECT
KEEP: 脸型、眼色、发型、识别性配饰
IGNORE: 原图姿势、服装、背景、光线

图B · STYLE
KEEP: 柔焦、低反差、冷暖色关系、高光扩散
IGNORE: 图中人物身份、发色、衣服、动作
```

同一人物多图时始终以最初的 SUBJECT 原图为身份锚点，生成图不得反过来取代原图。STYLE、POSE 或 COMPOSITION 参考不得改变身份特征。

## 3. 生成前确认

除非用户明确说“直接生成”或等价表达，否则先用用户当前语言给出确认单：

```text
【生成前确认】

参考图分工
- 图1 = 人物；图2 = 画风；图3 = 动作

主体人物
- ...

风格 / 动作 / 构图 / 服装 / 场景与光线
- 只保留实际相关段落

输出规格
- 比例：...（来源：用户指定 / 构图参考 / 工具默认）
- 张数：...

必须保持
- ...

重点避免
- ...

如果没问题，回复“确认生成”；需要修改可直接指出。
```

用户修改一处时只更新受影响部分；牵连多处才重发完整确认单。带修改条件的“可以，不过……”属于修订，不属于批准。更多边界情况见 [references/examples.md](references/examples.md)。

## 4. 组装最终提示词

批准后，把内容写成一段不依赖“图1/图2”指代的自然语言，顺序为：

`主体身份 → 服装 → 动作 → 表情 → 构图机位 → 背景 → 光线 → 渲染风格 → 光学处理 → 调色 → 氛围`

把限制写成正向目标，例如“哑光自然皮肤、保留细微纹理”“柔和高光滚降”“眼睛与主要五官保持最清晰”，不要机械堆叠否定词。

## 5. 映射参考图并生成

底层工具只原生理解 subject、style、composition 三类附件。按以下方式防串味：

- `SUBJECT` → `-SubjectReference`
- `STYLE` → `-StyleReference`
- `COMPOSITION` → `-CompositionReference`
- `POSE` 可在姿态依赖空间关系时作为 `-CompositionReference`，同时必须在文字提示词中写清动作；否则只使用提取出的文字属性
- `EXPRESSION / OUTFIT / LIGHTING / BACKGROUND / ATMOSPHERE / PROP` 默认只写入提示词，不附原图，避免错误继承人物身份

所有附件合计最多 4 张。拿不到参考图本地文件时，使用已提取的文字属性继续，并明确告诉用户视觉锚点未直接附加。

先在当前环境执行一次只读检查：

```powershell
& "<skill-dir>\scripts\generate.ps1" -Doctor
```

然后每次只生成一张：

```powershell
& "<skill-dir>\scripts\generate.ps1" `
  -Prompt "<最终自然语言提示词>" `
  -Output "<工作区内路径>" `
  -Size "1024x1536" `
  -SubjectReference "<人物图>" `
  -StyleReference "<风格图>" `
  -CompositionReference "<构图或动作图>"
```

输出路径必须在工作区内；已有文件只有用户明确同意覆盖时才加 `-Force`。多张结果按顺序逐张生成，不并行运行 Web 作业。

## 6. 检查结果

生成后检查图片，报告文件路径、最终提示词和参考图分工。结果明显偏离时只做一次有针对性的修订，不批量刷变体。

如果提交状态不确定，不得自动重发；先检查现有 ChatGPT 会话，因为图片可能已经生成。如果被限流则停止等待，不循环。Chrome 未连接或未登录时报告准确诊断，不回退到 Codex。DOM 或版本故障时先读 [references/compatibility.md](references/compatibility.md)。

## 7. 存档与复用

用户明确要求保存，或对成图满意后同意保存时，按 [references/library.md](references/library.md) 建立 preset。第一次写盘前必须完整读取该文件；存档库路径由用户决定，不写死。

存档必须包含确认单、角色化属性、原始参考图以及效果反馈。用户只说“上次那个”且可能匹配多个 preset 时，列出最近 3 个让他选，不要猜。删除或覆盖 preset 必须获得明确确认。

## 不可变规则

- 图片生成始终固定 Web 后端，除非用户明确改变费用路径。
- Web 并发为 1；不要开多个 ChatGPT 生图标签。
- 不把生成结果上传到公共图库，除非用户明确要求。
- 说明应准确：生图请求不走 Codex 图片后端，但普通任务编排仍会消耗少量 Codex token。
