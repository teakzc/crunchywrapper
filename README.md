<div align="center">
  <img src="https://raw.githubusercontent.com/teakzc/crunchywrapper/refs/heads/main/assets/crwarpper.svg" alt="Logo" width="256" height="256"/>

  <h1 align="center"><b>crunchywrapper</b></h1>
  <p align="center"></p>
  
  This is a ffrostfall/crunchyroll wrapper, that uses a forked version of crunchyroll.

  [![License](https://img.shields.io/github/license/teakzc/crunchywrapper?style=for-the-badge)](https://github.com/teakzc/crunchywrapper/blob/main/LICENSE)
  [![Documentation](https://img.shields.io/badge/Documentation-Website-blue?style=for-the-badge)](https://teakzc.github.io/crunchywrapper/)
</div>

# crunchywrapper

## 📦 Installation
[pesde](https://pesde.dev/):
```bash
pesde add teakzc/crunchywrapper
```

## ⭐ Features
- (Exponential or Linear) Fade in and Fade out
- Motor6D support
- Strictly Typed API
- R6 only (R15 maybe soon)

## Special Thanks
- Thank you to @marunima for suggesting how to add fades and how to motor6ds
- Thank you to @john_malakas for the SteelProjectsRBX/BasicCrunchyRollAnimPlayer that inspired this
- Thank you to @jiwonz for some help

## Note
This uses teakzc/crunchyroll on wally (slight changes to support motor6d so use that too or fork it yourself)
```bash
wally add teakzc/crunchyroll
```

# Documentation

```luau
export type selfprops = {
	Character: Model,
	Animations: { [crunchyroll.AnimationAsset]: CompleteAnimationData },
	Rig: crunchyroll.Rig,
	Motor6D: { [string]: Motor6D },
	AnimationTracks: {
		[string]: {
			[string]: crunchyroll.AnimationAsset,
		},
	},
}

export type CustomData = {
	Looped: boolean,
	ExponentCurve: number,
	End: boolean?,
	Speed: number?,
	FadeIn: number?,
	FadeOut: number?,
	FadeInElapsed: number?,
	FadeOutElapsed: number?,
	FadeOutForce: number?,
	OriginalWeight: number?,
}
```

## ⚠️ FADE IN AND FADE OUT

Fade in and Fade out **requires** a `IDLE TRACK` or else it won't work! (It uses weight to fade so it needs another track)

## `new(Character: Model, Rig: crunchyroll.Rig): self`

Creates a animation class, where you can play tracks and update the character's motor6d. It is recommended to create new rigs for every time you do this.

## `AddTrack(self: self, AnimationAsset: crunchyroll.AnimationAsset, Data: AnimationData, Fade: number?, FadeOut: number?)`

AddTrack takes in the animation class of a player you want to use. You have to give the function a ``crunchyroll.AnimationAsset`` which is just ``crunchyroll.load_keyframe_sequence(keyframe_sequence, rig)`` using the same rig for ``animation.new``

Example:
```luau
animation:AddTrack(MyVeryAmazingAnimationAsset, {
    Looped = true,
    weight = 3,
    priority = 1,
    alpha = 0,
    ExponentCurve = 3
}, .25) --Fade in time included, make sure you have an idle track too
```

Loop loops the track, and exponentcurve determines the fade in fade out curve.

This graph is for how [ExponentCurve](https://www.desmos.com/calculator/8uyqm1rnrt) changes weight

## `RemoveTrack(self: self, AnimationAsset: crunchyroll.AnimationAsset, Fade: number?)`

Remove track will set will calculate if there is remaining time left for the fade time, if there is enough the track will fade using the exponent curve defined with :AddTrack(). If there isn't enough time then it will use the remaining lifespan of the animationtrack to fade out.

## `ForceRemoveTrack(self: self, AnimationAsset: crunchyroll.AnimationAsset)`

Forcefully sets the track to nil, removing it like it never existed.

## `UpdateMotor(self: self)`

Updates the player's motor6d to match the animation from crunchyroll.

## `Stepped(self: self, dT: number, UpdateMotor6: boolean?)`

Stepped updates the crunchyroll frame and calculates.

It is recommended to use `RunService.PreSimulation` for this
