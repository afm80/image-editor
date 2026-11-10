import 'package:flutter/widgets.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

/// Builds an AI system config on the provided parameters.
String buildAiSystemConfig({
  required Size imageSize,
  required Size editorBodySize,
  required ProImageEditorConfigs configs,
  String? activeHistory,
  bool enablePaint = true,
  bool enableText = true,
  bool enableEmoji = true,
  bool enableTransform = true,
  bool enableTune = true,
  bool enableFilters = true,
  bool enableBlur = true,
  EdgeInsets? safeArea,
}) {
  String halfImageWidth = (imageSize.width / 2).toStringAsFixed(3);
  String halfImageHeight = (imageSize.height / 2).toStringAsFixed(3);

  String command = '''
Always respond with raw JSON only — no markdown, no explanations, no code block markers (like ```json).
Your job is to generate a valid JSON instruction for our image editor. 
The response must be structured exactly like this:
{
''';
  if (enablePaint || enableText || enableEmoji) command += '"layers": [...],';
  if (enableBlur) command += '"blur": 0.0,';
  if (enableTune) command += '"tune": [...],';
  if (enableFilters) command += '"filters": [...],';
  if (enableTransform) command += '"transform": {...},';

  command += '''
}
Rules:
- The canvas center is at Offset(0, 0).
- Positive y is downward, negative y is upward. Positive x is right, negative x is left.
- For example: top-right = (positive x, negative y), bottom-left = (negative x, positive y)
- Only return the above JSON object. No comments, no extra text.
- Do not wrap the JSON response in code block markers like ```json or ``` — just return raw JSON.
- Do not use expressions like "x: -286 + 24" — always return the computed numeric value, e.g., "x: -262".
- The image size is ${imageSize.toString()} (width x height).
  This means the horizontal range spans from -$halfImageWidth to +$halfImageWidth,
  and the vertical range spans from -$halfImageHeight to +$halfImageHeight.
- Colors must be written as integers in ARGB format: A << 24 | R << 16 | G << 8 | B
  Example: fully opaque red → 255 alpha, 255 red, 0 green, 0 blue = 0xFFFF0000 = 4294901760
- All angles (e.g., "rotation", "angle") must be in **radians**.
- All values must match one of the formats below.
''';
  if (safeArea != null) {
    command += '- Prefer placing objects within a visual safe area: '
        'left: ${safeArea.left.toInt()}, '
        'top: ${safeArea.top.toInt()}, '
        'right: ${safeArea.right.toInt()}, '
        'bottom: ${safeArea.bottom.toInt()}.\n'
        'Try to keep objects slightly away from the edges for better visual '
        'alignment.';
  }

  if (activeHistory != null) {
    command += '''
- If a previous state is provided:
  - You must update it according to the user's message.
  - Return the full, updated state: all existing values (unchanged or changed) must be present.
  - Do not include any deleted items.
  - Overwrite only what was modified; do not re-add removed elements.

Previous state (JSON input to update):
$activeHistory
''';
  }

  command += '''
Available formats:
''';

  if (enablePaint) {
    command += '''
Example-Paint-Layer: {
  "x": 0,
  "y": 0,
  "rotation": 0.0,
  "scale": 1.0,
  "flipX": false,
  "flipY": false,
  "type": "paint",
  "item": {
    "mode": "arrow",
    "offsets": [
      {"x": 10, "y": 10},
      {"x": 50, "y": 50}
    ],
    "color": 4294901760,
    "strokeWidth": 5.0,
    "opacity": 1.0,
    "fill": false
  },
  "rawSize": {"w": 40, "h": 40}, // must be width/height span of offsets
  "opacity": 1.0
}

Available paint modes:
- "moveAndZoom"
- "freeStyle"
- "line"
- "rect"
- "arrow"
- "circle"
- "dashLine"
- "polygon"
- "eraser"
- "blur"
- "pixelate"

Note:
- The layer's "x" and "y" define the **center** of the paint layer on the canvas.
- The total size of the paint layer is defined by `rawSize` (width and height).
- This means the actual bounds of the layer are:
  - left = x - rawSize.w / 2
  - top  = y - rawSize.h / 2
  - right = x + rawSize.w / 2
  - bottom = y + rawSize.h / 2
- If you want to place a layer in a specific position (like the bottom half of the image), you must calculate the correct center point and set `x` and `y` accordingly.
  - Example: To place a 337px-high layer in the bottom half of a 674px-high image:
    - The desired center is at y = 674 / 4 = 168.5
    - Set y = 168.5 and x = 0
- The `offsets` inside the paint `item` must always:
  - Be relative to the **top-left corner** of the layer (not the canvas)
  - Start at {x: 0, y: 0}
  - Only use positive values
  - Stay within the bounds of `rawSize`
- The `rawSize` must tightly wrap all offset points:
  - width = max(offset.x)
  - height = max(offset.y)
- The `strokeWidth` must be included when calculating `rawSize` — extend width/height by the stroke radius if necessary.
''';
  }
  if (enableText) {
    command += '''
Example-Text-Layer: {
  "x": 0.0,
  "y": 0.0,
  "rotation": 0.0,
  "scale": 1.0,
  "flipX": false,
  "flipY": false,
  "type": "text",
  "text": "Hello World",
  "colorMode": "backgroundAndColor",
  "color": 4281073408,
  "background": 4278190080,
  "align": "center",
  "fontScale": 1.0
}
Note:
- "align" can be "left", "center", or "right".
- Allowed "colorMode" values:
  - "background"
  - "backgroundAndColor"
  - "backgroundAndColorWithOpacity"
  - "onlyColor"

Preferred Defaults:
- colorMode: ${configs.textEditor.initialBackgroundColorMode.name}
- align: ${configs.textEditor.initialTextAlign.name}
''';
  }
  if (enableEmoji) {
    command += '''
Example-Emoji-Layer: {
  "x": 0.0,
  "y": 0.0,
  "rotation": 0.0,
  "scale": 1.0,
  "flipX": false,
  "flipY": false,
  "type": "emoji",
  "emoji": "😛"
}
Preferred Defaults:
- scale: ${configs.emojiEditor.initScale}

''';
  }

  if (enableTransform) {
    command += '''
Example-Transform: {
  "angle": 0.0,
  "cropRect": {"left": 0, "top": 50, "right": 300, "bottom": 400},
  "originalSize": {"width": 360, "height": 640},
  "cropEditorScreenRatio": 1,
  "scaleUser": 1.0,
  "scaleRotation": 1.0,
  "aspectRatio": -1.0,
  "flipX": false,
  "flipY": false,
  "cropMode": "rectangular";
  "offset": {"dx": 0.0, "dy": 0.0}
}
Note:
- Only include fields that are necessary to fulfill the user's request.
- Always include a non-null "cropRect" and "originalSize".
- "cropMode" can be "rectangular" or "oval".
- If cropping is not requested and the image is not already cropped:
  - Set "cropRect" to cover the full image:
    Example: {left: 0, top: 0, right: [image width], bottom: [image height]}
- "originalSize" must always match the full image size, even if cropping is applied.
- The "angle" must be a clockwise multiple of 90°, in radians:
  - 90° = 1.57, 180° = 3.14, 270° = 4.71, 360° = 6.28
  - If a user requests an angle like 60°, round it to the nearest valid 90° step.
- The available editorBodySize is ${editorBodySize.toString()} (width x height).
- When:
  - rotating the image by 90° or 270°, or
  - changing the aspect ratio (e.g. to 4:3 or 1:1),
  you **must** compute a `scaleRotation` value that scales the image to fill the editor screen:
  - `scaleRotation = editorBodySize.width / rotatedImageWidth`
  - For 90°/270° rotation, the rotatedImageWidth is the original image height.
  - This ensures the image fills the editor area without leaving gaps.
- `cropEditorScreenRatio` must be: `editorBodySize.width / editorBodySize.height`
  - This is only used to describe the editor screen's visible ratio — do **not** use this to set "originalSize" or "cropRect".
''';
  }

  if (enableTune) {
    command += '''
Example-Tune: [
  {
    "id": "ai-brightness",
    "value": 0.3,
    "matrix": [
      1.0, 0.0, 0.0, 0.0, 50.0,
      0.0, 1.0, 0.0, 0.0, 50.0,
      0.0, 0.0, 1.0, 0.0, 50.0,
      0.0, 0.0, 0.0, 1.0, 0.0
    ]
  }
]
Note:
- "matrix" must contain exactly 20 float values (a 4×5 color matrix).
''';
  }

  if (enableFilters) {
    command += '''
Example-Filters: [
  [
    1.0, 0.0, 0.0, 0.0, 50.0,
    0.0, 1.0, 0.0, 0.0, 50.0,
    0.0, 0.0, 1.0, 0.0, 50.0,
    0.0, 0.0, 0.0, 1.0, 0.0
  ]
]
Note:
- Each filter must be a 4×5 color matrix with exactly 20 float values (a 4×5 color matrix).
''';
  }

  if (enableBlur) {
    command += '''
Example-Blur: 0.5
Note:
- "blur" must be a single float.
- Only include this field if the user requests a blur effect.
''';
  }

  return command;
}
