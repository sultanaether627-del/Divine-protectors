# Free SFX Asset Sources for Divine Protectors

Here are the best free sources for sound effects that you can use in your game:

## 1. Freesound.org (⭐ Recommended)
- **URL**: https://freesound.org/
- **Cost**: Free (requires attribution)
- **Quality**: Excellent - community-curated
- **Format**: Mostly WAV, some OGG
- **Best for**: Specific sounds, high-quality effects
- **Attribution**: Required (check individual sound licenses)
- **Search tips**: Use terms like "magic shot", "explosion", "footstep", "transform"

## 2. OpenGameArt.org (⭐ Recommended)
- **URL**: https://opengameart.org/
- **Cost**: Free (varies by asset)
- **Quality**: Good to Excellent
- **Format**: WAV, OGG
- **Best for**: Complete SFX packs, game-ready sets
- **Attribution**: Varies (CC0, CC-BY, etc.)
- **Recommended packs**: 
  - "Universal Sound FX" by @artturij
  - "RPG Sound Pack" by @joshuamoorcraft
  - "Magic Sounds" by @scrampunk

## 3. Mixkit.co (No Attribution Required)
- **URL**: https://mixkit.co/free-sound-effects/
- **Cost**: Free (no attribution required)
- **Quality**: Good
- **Format**: MP3, WAV
- **Best for**: Quick downloads, no attribution needed
- **License**: Free for commercial use

## 4. Zapsplat.com
- **URL**: https://www.zapsplat.com/
- **Cost**: Free tier available
- **Quality**: Professional
- **Format**: WAV
- **Best for**: Comprehensive library
- **Attribution**: Required for free tier
- **Note**: Sign-up required

## 5. Pixabay Audio
- **URL**: https://pixabay.com/music/sound-effects/
- **Cost**: Free (no attribution required)
- **Quality**: Variable
- **Format**: MP3
- **Best for**: Background effects, simple sounds

## Specific SFX Recommendations for Your Game

### Combat Sounds
- **Shooting**: Search for "magic projectile", "energy shot", "spell cast"
- **Hits**: "impact hit", "punch", "sword hit"
- **Explosions**: "explosion", "boom", "blast"
- **Enemy death**: "monster death", "creature die", "enemy fall"

### UI Sounds
- **Button clicks**: "ui click", "menu select", "button press"
- **Hover**: "ui hover", "menu highlight"
- **Level up**: "level up", "power up", "fanfare"
- **Form switch**: "magic transform", "whoosh", "power change"

### Player Sounds
- **Transformations**: "magic morph", "transformation", "shape change"
- **Ultimates**: "ultimate attack", "super move", "power blast"
- **Footsteps**: "footstep", "step", "walk"
- **Pickups**: "collect", "pickup", "item get"

### Boss/Enemy Sounds
- **Boss attacks**: "monster attack", "boss roar", "creature attack"
- **Boss death**: "boss death", "monster defeat", "final blow"
- **Enemy spawn**: "enemy appear", "spawn", "creature summon"

## Recommended SFX Packs

### "8-Bit Sound Effects" (OpenGameArt)
- Perfect for retro-style games
- Small file sizes
- Consistent style

### "Fantasy Sound Pack" (Freesound)
- Magic spells, transformations
- Combat sounds
- UI elements

### "Modern UI Sounds" (Mixkit)
- Clean button sounds
- Menu navigation
- Feedback sounds

## File Format Recommendations

### For Godot Games:
- **Preferred format**: OGG Vorbis (.ogg)
- **Alternative**: WAV (.wav) - higher quality but larger
- **Avoid**: MP3 for short sounds (compression artifacts)

### Settings:
- **Sample rate**: 44.1kHz or 48kHz
- **Bit depth**: 16-bit or 24-bit
- **Channels**: Mono for SFX (smaller files), Stereo for music

## Organization Tips

1. **Download with purpose**: Keep the original filenames meaningful
2. **Test in-game**: Always test sounds in your game before finalizing
3. **Volume balance**: Adjust individual file volumes as needed
4. **Keep backups**: Save original high-quality versions

## Attribution Tracking

Keep a text file called `ATTRIBUTIONS.txt` in your `audio/` folder with format:

```
Sound Effect Name - Source Website - Author
License Type - Attribution Requirements
```

Example:
```
Magic Shot 1 - Freesound.org - user123
CC-BY 4.0 - Must attribute author
```

## Next Steps

1. Browse the recommended sites
2. Download sounds that match your game's style
3. Place them in the appropriate folders in `res://audio/sfx/`
4. Test them using the SFX manager in your game
5. Adjust volumes and timing as needed