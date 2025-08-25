<div align="center">
    <img src="https://raw.githubusercontent.com/teakzc/crwrapper/refs/heads/main/assets/crwarpper.svg" alt="Helium Logo" width="256" height="256"/>

    <h1 align="center"><b>helium</b></h1>
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
- Thank you to @marunima for suggesting how to add fades and how to motor6d
- Thank you to @john_malakas for the SteelProjectsRBX/BasicCrunchyRollAnimPlayer that inspired this (I read through the src code and kind of copied it)
- Thank you to @jiwonz for some help

## Note
This is for my own personal use, if you want to use this please use @john_malakas's SteelProjectsRBX/BasicCrunchyRollAnimPlayer instead (I took full inspiration of it so he deserves all credit!!!). Although currently his one is outdated (planned to be updated soon as of 25 August 2025)

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
```

## `new(Character: Model, Rig: crunchyroll.Rig): self`

Creates a animation class, where you can play tracks and update the character's motor6d