---
name: visual-reference-web-image
description: Generate new raster images through Codex's built-in image_gen tool from text and role-labeled references for subject, style, pose, composition, outfit, lighting, or background. Use for combining reference images, preserving character identity, or reusing visual presets. Do not use for pixel-accurate editing, vector work, or public end-user generation services.
---

# 视觉参考 · Codex 图片生成

把参考图的角色拆清楚，再通过 Codex 内置 image_gen 工具生成。保留原 skill 名称以兼容已有调用；执行后端已改为 Codex 图片生成，不需要 Chrome、ChatGPT 网页登录或 image-use。

没有参考图时，跳过参考拆分，直接整理文字提示词并生成。只有风格分析问题时只解释，不生成。

## 1. 分配参考图角色

为每张图指定一个或多个角色：

- SUBJECT：人物或主体身份
- STYLE：媒介、质感、色调、光学表现
- POSE：动作和身体关系
- EXPRESSION：表情与视线
- COMPOSITION：机位、景别、裁切、空间布局
- OUTFIT：服装与配饰
- LIGHTING：光线性质
- BACKGROUND：场景环境
- ATMOSPHERE：情绪转译
- PROP：手持或交互物件

用户的明确说法优先于自动判断。分析参考图时读取 [references/extraction-schema.md](references/extraction-schema.md)，只填写与该图角色相关且能观察到的字段。SUBJECT 只取身份锚点，不继承原姿势、服装、背景、构图或光线。风格必须翻译成可观察属性；动作必须描述关节、支撑、朝向和接触关系。

## 2. 防止属性串味

在内部为每张参考图写 KEEP / IGNORE：

~~~text
图A · SUBJECT
KEEP: 脸型、眼色、发型、识别性配饰
IGNORE: 原图姿势、服装、背景、光线

图B · STYLE
KEEP: 柔焦、低反差、冷暖色关系、高光扩散
IGNORE: 图中人物身份、发色、衣服、动作
~~~

同一人物多图时始终以最初的 SUBJECT 原图为身份锚点，生成图不得反过来取代原图。STYLE、POSE 或 COMPOSITION 参考不得改变身份特征。

## 3. 整理生成方案

沿用用户已确认的要求；指令清楚时简短说明参考图分工并直接生成，不增加重复确认。用户明确要求先看方案时，提供以下内容并等待确认；仅当歧义会实质改变成图时才提问。

~~~text
参考图分工
- 图1 = 人物；图2 = 画风；图3 = 动作

主体人物
- 身份锚点

风格 / 动作 / 构图 / 服装 / 场景与光线
- 只保留实际相关段落

输出规格
- 比例及来源：用户指定 / 构图参考 / 合理默认
- 张数

必须保持
- 关键约束

重点避免
- 容易串味的属性
~~~

用户修改一处时只更新受影响部分。用户要求先确认时，带修改条件的“可以，不过……”属于修订，不属于批准。更多边界情况见 [references/examples.md](references/examples.md)。

## 4. 组装最终提示词

视觉内容按以下顺序组织：

主体身份 → 服装 → 动作 → 表情 → 构图机位 → 背景 → 光线 → 渲染风格 → 光学处理 → 调色 → 氛围

提示词应独立描述目标画面，同时附上与实际工具输入顺序一致的参考图角色表及各图 KEEP / IGNORE。明确这些图片是生成新画面的参考，不是要求逐像素修改的原图。工具没有原生的 SUBJECT、STYLE 等角色参数，角色限制全部写在 prompt 中。

把限制写成正向目标，例如“哑光自然皮肤、保留细微纹理”“柔和高光滚降”“眼睛与主要五官保持最清晰”。比例、尺寸意图、张数和画面文字也写入提示词；不虚构工具没有暴露的 size、quality 或输出路径参数。

## 5. 通过 Codex 内置工具生成

使用当前环境提供的 image_gen 工具（本环境为 image_gen.imagegen / tools.image_gen__imagegen）。普通生图不调用 CLI/API，不要求 API key，不运行旧网页包装器或浏览器登录检查。

参考图输入根据实际可用来源选择：

- 所有参考图都有本地路径：先用 view_image 查看尚未看过的图片，再用 referenced_image_paths 传入原始参考图，顺序与提示词角色表一致。
- 至少一张参考图只有对话附件：使用 num_last_images_to_include，取能覆盖所有目标参考图的最小最近图片数（最多 5 张）。明确被一起包含的额外图片仅供忽略，不让它们覆盖原始身份锚点。
- 不同时设置 referenced_image_paths 和 num_last_images_to_include。若任一方式都无法覆盖所有必需参考图，请用户重新附上缺失图片，不能声称已附加，也不能静默退化为纯文字参考。
- 全新纯文字生图省略这两个参考图参数。

所有附图的用途由提示词控制，不沿用旧工具只支持 subject/style/composition 三类附件或最多 4 张附件的限制。对非主体参考明确忽略人物身份；只需借鉴文字化属性的参考可以不附图，但应准确说明实际使用了哪些视觉锚点。

需要透明背景时设置 transparent_background: true，其他情况设为 false。已有透明参考的衍生修改，除非用户要求改变，否则保留透明背景。

通过 functions.exec 调用时，使用工具要求的等待时长，并用 generatedImage(result) 返回结果；不要打印完整图片数据。示例为纯文字生图，prompt 应替换为实际整理后的提示词：

~~~javascript
// @exec: {"yield_time_ms": 120000, "max_output_tokens": 1000}
const result = await tools.image_gen__imagegen({
  prompt: "实际生成提示词，包含构图、比例和必须保持的内容",
  transparent_background: false
});
generatedImage(result);
~~~

多个独立成品或姿势变体分别调用，每次保留原始主体身份锚点。

## 6. 检查与交付

检查主体身份、风格、动作、构图、文字和透明背景是否符合要求。报告最终提示词、实际参考图分工及已保存的文件路径。结果明显偏离时做一次有针对性的修订，不批量刷变体。

内置工具通常把图片保存到 $CODEX_HOME/generated_images/...。指定了交付目录或图片供当前项目使用时，将工具返回的实际输出复制到用户目录或工作区；不要猜测文件名、伪造保存成功或把输出路径当工具参数。未要求覆盖时使用新文件名。仅供预览的图片可以保留默认位置并直接展示。

工具不可用、失败或限流时报告准确状态，不自动改走 ChatGPT 网页、image-use 或另行计费的 API。工具与输出问题见 [references/compatibility.md](references/compatibility.md)。

## 7. 存档与复用

用户明确要求保存，或对成图满意后同意保存时，按 [references/library.md](references/library.md) 建立 preset。第一次写盘前必须完整读取该文件；存档库路径由用户决定，不写死。

存档必须包含生成方案、角色化属性、原始参考图以及效果反馈。用户只说“上次那个”且可能匹配多个 preset 时，列出最近 3 个让他选，不要猜。删除或覆盖 preset 必须获得明确确认。

## 执行约束

- 默认固定使用 Codex 内置图片工具；只有用户明确改变执行方式时才切换后端。
- 不把生成结果上传到公共图库，除非用户明确要求。
- 说明应准确：生图使用 Codex 图片生成能力，额度及限制以当前账户和工具实际返回为准；不承诺免费或不占额度。
