# 提取字段清单

分析参考图时把这份当清单用：逐项扫一遍以免漏看，**但只输出既与该图角色相关、又确实在图里能观察到的字段，空字段直接省略**，不要堆一大片空 YAML。看不出来的就不写，不要用合理推测填满。下方模板是字段全集，不是要求填满的表格。

---

## 参考图记录模板

一张 SUBJECT 参考图的实际输出可能只有十几行（只有 `subject:` 段 + `transfer:` 段，且段内也只写看得见的字段），这是正常的。

```yaml
reference_id: A
roles: [SUBJECT]
confidence: high
is_real_photo: false        # 真人照片时置 true，按 SKILL.md「真人照片参考」处理

subject:
  face_shape:
  eye_shape:
  eye_color:
  eyebrow_shape:
  nose_mouth:
  hairstyle:
  hair_color:
  bangs:
  hair_accessories:
  age_appearance:
  body_build:               # 仅在明显相关时填
  identity_anchors:         # 最不可丢失的几项，生成时优先保住

style:
  medium:
  realism_level:
  optics:
  contrast:
  exposure:
  saturation:
  palette:
  highlights:
  shadows:
  texture:
  depth_of_field:
  bokeh:
  mood:

pose:
  posture:
  torso:
  shoulders:
  head:
  arms:
  hands:
  legs:
  weight_distribution:
  gaze:
  interaction:              # 与椅子/桌子/窗/墙等的关系

expression:
  eyes:
  brows:
  mouth:
  emotional_intensity:

composition:
  shot_size:
  camera_height:
  camera_angle:
  camera_distance:
  camera_side:
  subject_position:
  foreground_occlusion:
  negative_space:
  crop:
  perspective:
  orientation:
  aspect_ratio:

outfit:
  garments:
  silhouette:
  neckline:
  sleeves:
  fit:
  materials:
  translucency:
  details:                  # 褶皱 / 蕾丝 / 打褶
  colors:
  accessories:
  jewelry:
  footwear:

lighting:
  key_direction:
  key_softness:
  key_temperature:
  ambient_temperature:
  fill_level:
  rim_light:
  practical_lights:
  exposure:
  shadow_density:
  highlight_intensity:
  bounce_light:

background:
  location:
  architecture:
  furniture:
  objects:
  weather:
  time_of_day:
  spatial_depth:
  practical_lights:
  scene_density:
  activity_level:

atmosphere:
  keywords:
  visual_translation:       # 必填：情绪词翻译成的可观测属性

transfer:
  keep:
  ignore:
```

---

## 各字段可用词汇

### style.medium 渲染媒介
动漫 / 半写实动漫 / 写实摄影 / 绘画感 / 水彩 / 油画质感 / 赛璐璐 / 3D·CGI / 插画 / 电影剧照 / 杂志人像 / 抓拍快照

### style.realism_level 写实度
描述二者的配比，例如：
- 动漫化的人体结构 + 写实光照
- 半写实五官 + 动漫化眼睛比例
- 照片级皮肤与头发 + 插画化的面部结构

### style.optics 光学特征
锐利 / 柔焦 / 光学扩散 / 高光溢出(bloom) / 光晕(halation) / 雾化 / 薄雾 / 运动柔化 / 镜头眩光 / 景深 / 散景大小与形状 / 前景虚化 / 轻微失焦 / 长焦压缩

### style 影调
反差强度 · 黑位 · 高光滚降 · 曝光 · 饱和度 · 色温 · 主导色对 · 阴影色 · 高光色 · 局部/微反差

### style.texture 表面质感
胶片颗粒 / 数码纯净 / 纸纹 / 笔触 / 皮肤质感 / 发丝细节 / 噪点 / 柔化程度

### style.mood 情绪视觉基调
梦幻 / 怀旧 / 私密 / 忧郁 / 浪漫 / 疏离 / 抓拍感 / 诡异 / 平静 / 奢华 / 纪实感

### composition.shot_size 景别
特写 / 胸上 / 半身 / 七分身 / 全身

### pose 提取要点
坐·站·倚靠 · 躯干朝向 · 肩线朝向 · 头部倾斜 · 头部转向 · 下巴角度 · 手臂位置 · 肘部位置 · 手腕角度 · 手掌位置 · 手指姿态（仅重要时）· 腿部位置 · 重心分配 · 与环境物件的接触关系 · 与姿势绑定的视线方向

### expression 提取要点
睁眼程度 · 视线方向 · 眼睑松弛度 · 眉部张力 · 嘴型 · 微笑强度 · 情绪强度 · 直视还是失焦远望

优先用克制的描述，例如：
> 眼睑放松，视线朝向镜头但略微失焦，嘴唇微启，安静中带一点怅然，而非在微笑。

---

## 情绪词 → 可观测属性

`atmosphere.visual_translation` 必须写满，参考：

**梦中感**：光学扩散 / 轻微雾化 / 边缘柔化 / 微反差降低 / 柔和高光溢出 / 眼部之外细节弱化 / 浅景深

**白月光**：皮肤柔和发光 / 安静表情 / 高光柔性滚降 / 低视觉攻击性 / 克制饱和度 / 通透疏离的情绪 / 优雅但自然的取景

**回忆感**：模拟胶片颗粒 / 色调略褪 / 黑位抬升 / 轻微失焦 / 柔和光晕 / 抓拍式构图

---

## 不自动继承表

| 角色 | 只取 | 明确忽略（除非用户另行要求） |
|---|---|---|
| SUBJECT | 身份锚点 | 原姿势 / 原服装 / 原背景 / 原构图 / 原光线 |
| STYLE | 呈现方式 | 人物身份 / 发色 / 服装 / 具体姿势 |
| POSE | 身体关系 | 身份 / 头发 / 服装 / 背景 / 画风 |
| COMPOSITION | 机位与取景 | 身份 / 画风 |
| OUTFIT | 服饰本身 | 服装模特的身份 |
| LIGHTING | 光的性质 | 参考图的环境场景 |
| BACKGROUND | 环境 | 背景里出现的人（除非用户明说要） |
