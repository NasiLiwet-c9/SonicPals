# Sonic Pals: Architecture

SwiftUI handles the screens. RealityKit's ECS (Entity Component System)
handles the AR gameplay.

## ECS basics

- Entities: the things in the scene, like the target or the ground. No
  behavior on their own.
- Components: data attached to an entity, like "this is a target" or
  "this can be revealed."
- Systems: the logic. Each system runs every frame on any entity with the
  right components.

Everything gets registered once, at launch, in the app's entry point
(App/POCApp.swift, soon SonicPalsApp.swift), using registerComponent() and
registerSystem().

## Folders

App: entry point, app state (AppModel.swift), and the shared theme
(AppTheme.swift, including the SF Pro Rounded font).

Game/World: the ECS engine. ECSWorld.swift owns the scene.
ECSWorld+Spawn, +Target, +Wave split its work by feature instead of one
huge file. Components.swift and ECSCmd.swift hold shared definitions.

Game/Scan: reads the floor and mesh from LiDAR.

Game/Reveal: builds a mesh from what's scanned and reveals the world as
you explore.

Game/Target: spawns the target (Target/Spawn), finds it with the sonar
ping (Target/Asset), and points you toward it once you have a rough idea
where it is (GuideArrow.swift, TargetGuideSys.swift).

Game/Mission: mission and quiz progress, kept separate from the AR
gameplay itself.

Game/Tutorial: coaching hints for new players (CoachSvc.swift), shown
through UI/Session/CoachBubble.swift and CoachSpotlight.swift.

Services: sound effects (SfxSvc.swift), haptics (HapticSvc.swift), AR
session handling (SessSvc.swift).

UI: screens grouped by area. Home, Session (the live HUD, ping button,
respawn button), Quiz, Splash, and Shared (reusable pieces like dialogue
bubbles, credits, the GIF player).

Debug: dev-only tools, stripped from release builds.

Resources and Assets.xcassets: audio lives in Resources/Audio since asset
catalogs can't play sound. Images, GIFs, and the app icon live in
Assets.xcassets.

## Naming

Short name plus a suffix for what it does:

- Svc: a service, like HapticSvc
- Sys: an ECS system, like TargetSys
- Comp: an ECS component, like TargetComp
- Cfg: config values, like TargetCfg
- Port: a protocol, like TargetPort

## Testing

Pure logic (config, timing, scoring, state) gets tested directly. ECS
systems get tested against a real but detached RealityKit scene where
possible, or by pulling out the core logic into something testable on its
own. Anything that needs a live camera is tested by hand on a device
instead.

<!-- Test #1 PR & Merge change auto test trigger -->
