## Pixel texture loader — loads raw PNGs at runtime without relying on the
## editor's import cache (absent in headless/export builds). Each texture is
## wrapped in a CanvasTexture so it samples with nearest-neighbour filtering
## (crisp pixel art) and, when `tiled`, repeats across a Sprite2D region_rect.
extends RefCounted

const FILTER_NEAREST: int = 1   # CanvasTexture.TEXTURE_FILTER_NEAREST
const REPEAT_ENABLED: int = 2   # CanvasTexture.TEXTURE_REPEAT_ENABLED

static func load_texture(path: String, tiled: bool = false) -> Texture2D:
	var img := Image.new()
	if img.load(path) != OK:
		return null
	var base := ImageTexture.create_from_image(img)
	var ct := CanvasTexture.new()
	ct.diffuse_texture = base
	ct.texture_filter = FILTER_NEAREST
	if tiled:
		ct.texture_repeat = REPEAT_ENABLED
	return ct
