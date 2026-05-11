GAME_123_FORM_SWAP_SCENE_BASED_CAMERA

Main scene:
- res://tscn/world.tscn

Player system:
- res://tscn/player_controller.tscn is the main player controller scene.
- It contains Camera2D, so the camera follows the active player controller automatically.
- Press 1/2/3/4 to switch forms mid-game.

Editable player form scenes:
- res://tscn/forms/water_form.tscn
- res://tscn/forms/fire_form.tscn
- res://tscn/forms/earth_form.tscn
- res://tscn/forms/wind_form.tscn

Each form scene has its own AnimatedSprite2D, ShotOrigin marker, base HP, and bullet scene reference.
Use these scenes to change animations without editing the main player script.

Bullets:
- res://tscn/bullets/water_bullet.tscn
- res://tscn/bullets/fire_bullet.tscn
- res://tscn/bullets/earth_bullet.tscn
- res://tscn/bullets/wind_bullet.tscn

Shared upgrades:
- Fire rate, damage, and healing are universal.
- Health is separate per character. A max-health upgrade only affects the currently active form, and it does not refill the extra HP instantly.

Knockout system:
- If a form reaches 0 HP, that form is knocked out for 60 seconds.
- The game automatically switches to another alive form.
- If all forms are knocked out, the scene reloads.

Current placeholder:
- Fire uses the water sprites/bullet until you add fire assets.
