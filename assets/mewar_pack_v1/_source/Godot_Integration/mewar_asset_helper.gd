extends Node

## Helper for creating SpriteFrames from the included sprite atlases.
## Usage: var frames = MewarAssetHelper.make_frames(preload("res://Characters/Maharana_Pratap/maharana_pratap_4x8_spritesheet.png"), Vector2i(128,160), {"idle":0,"walk":1,"run":2,"jump":3,"attack":4,"block":5,"hurt":6,"victory":7})
static func make_frames(texture: Texture2D, frame_size: Vector2i, animation_rows: Dictionary, fps: float = 10.0) -> SpriteFrames:
    var frames := SpriteFrames.new()
    frames.clear()
    for animation_name in animation_rows.keys():
        frames.add_animation(animation_name)
        frames.set_animation_speed(animation_name, fps)
        frames.set_animation_loop(animation_name, animation_name in ["idle", "walk", "run", "block"])
        var row: int = animation_rows[animation_name]
        for col in range(4):
            var atlas := AtlasTexture.new()
            atlas.atlas = texture
            atlas.region = Rect2(col * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y)
            frames.add_frame(animation_name, atlas)
    return frames
