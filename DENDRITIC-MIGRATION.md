# Dendritic Migration Guide

This document is the working reference for migrating this repository toward a dendritic layout built with `flake-parts`, `import-tree`, and `flake-file`.

The goal is not a big-bang rewrite. The repository should remain usable throughout the migration, with old and new patterns coexisting until each area is converted.

## Goals

- Generate `flake.nix` from `flake-file.nix`.
- Use `flake-parts` to structure outputs and publish reusable modules via `flake.modules`.
- Use `import-tree` to recursively import dendritic modules from `features/` and `hosts/`.
- Move from global module loading plus `config.modules.*.enable` switches toward import-based composition.
- Treat users as reusable features.
- Keep hosts as standalone compositions assembled from features.
- Allow feature-local input declarations where that improves clarity.

## Non-Goals

- Rewriting the entire repository in one pass.
- Eliminating the current `modules/`, `hosts/`, and `users/` trees immediately.
- Forcing every existing boolean option to disappear at once.
- Renaming `features/` to `modules/` before the migration is largely complete.

## Architectural Decisions

### Module Roots

The handwritten bootstrap files are:

- `flake-file.nix`
- files recursively imported from `features/`
- files recursively imported from `hosts/`

The generated file is:

- `flake.nix`

The `secrets/` flake remains a separate boundary.

### Directory Roles

#### `features/`

Contains reusable dendritic feature modules.

Examples:

- NixOS features such as `tailscale`, `stylix`, `firefox`, `impermanence`
- Home Manager features such as `cli`, `emacs`, `window-manager`, `firefox`
- user features such as `ben`
- flake-level wiring such as `perSystem` outputs and shared inputs

#### `hosts/`

Contains final host compositions and host-specific modules.

Hosts are assembled from features, but are not considered part of the reusable `features/` tree for repository organization.

### Naming Convention

Use flat exported feature names.

Directories are for organization. Public `flake.modules` names should stay simple and semantic.

Examples:

- `features/programs/firefox.nix` -> `self.modules.nixos.firefox` and `self.modules.homeManager.firefox`
- `features/services/homeManager.nix` -> `self.modules.nixos.homeManager`
- `features/users/ben/default.nix` -> `self.modules.nixos.ben` and `self.modules.homeManager.ben`
- `hosts/desktop/flake-module.nix` -> `self.modules.nixos.desktop`

Do not try to mirror deep directory structure in the exported attr path. `flake.modules` works best when directories express grouping and exported names express features.

### Shared Code Placement

Avoid a special `_shared/` directory.

Anything that must be imported automatically by `import-tree` should live under a real namespace, most likely `features/flake/...`.

Examples:

- `features/flake/root.nix`
- `features/flake/inputs/base.nix`
- `features/flake/outputs/per-system.nix`
- `features/flake/outputs/nixos-configurations.nix`

### Input Placement Policy

Use this rule consistently:

- foundational or cross-cutting inputs belong in `features/flake/inputs/base.nix`
- feature-specific inputs should live next to the feature that introduces and uses them

This keeps the root clear while still allowing `flake-file` to colocate an input with its actual usage.

### Composition Policy

Composition should move toward module `imports`, not global loading plus booleans.

Preferred:

```nix
imports = [ inputs.self.modules.nixos.tailscale ];
```

Legacy pattern to retire gradually:

```nix
config.modules.tailscale.enable = true;
```

Keep booleans when they describe runtime or contextual behavior, not feature selection.

Examples of booleans that may remain useful:

- desktop versus headless behavior inside an already-selected feature
- Linux-only or host-capability conditionals
- feature sub-options that are genuinely configuration, not composition

### User Model

Users are first-class reusable features.

For example, `ben` should eventually be represented as:

- `self.modules.nixos.ben`
- `self.modules.homeManager.ben`

The NixOS side creates and configures the system user and wires Home Manager when appropriate.

The Home Manager side imports personal app, CLI, and desktop features.

### Host Model

Hosts are final compositions stored under `hosts/` and exported as NixOS host modules.

Examples:

- `self.modules.nixos.desktop`
- `self.modules.nixos.laptop`
- `self.modules.nixos.pi`

Each host should mostly consist of imports plus host-local overrides.

### Migration Interop

The migration is expected to be hybrid for a while.

That means:

- new dendritic features may wrap or import old files from `modules/`, `users/`, and `hosts/`
- old host assembly may continue to work while new host modules are introduced
- migrated features should stop depending on `options.modules.*.enable`
- non-migrated features may continue to use the old option-based model temporarily

## Target State

### Bootstrap

- `flake-file.nix` is the only handwritten flake entrypoint.
- `flake.nix` is generated and should not be edited directly.
- `flake-file.nix` imports `flake-parts`, `flake-file`, and `import-tree`.
- `flake-file.nix` recursively imports `./features` and `./hosts`.

### Outputs

Top-level outputs are owned by `flake-parts`.

### `perSystem`

Move these here:

- `formatter`
- `checks`
- `devShells`
- `apps`

### `flake`

Move these here:

- `nixosConfigurations`
- `modules`
- any flake-level helpers that belong in the flake output schema

### Target Tree

This is the intended shape, not a requirement to create every file immediately.

```text
flake-file.nix
flake.nix

features/
  flake/
    root.nix
    inputs/
      base.nix
    outputs/
      per-system.nix
      nixos-configurations.nix
      overlays.nix
  generic/
    constants.nix
  services/
    homeManager.nix
    stylix.nix
    tailscale.nix
    impermanence.nix
  programs/
    firefox.nix
    emacs.nix
  desktop/
    window-manager.nix
  users/
    ben/
      default.nix

hosts/
  desktop/
    default.nix
  laptop/
    default.nix
  pi/
    default.nix
```

### Example Shapes

### Flake Root Module

`features/flake/root.nix` should own the minimal foundational flake-parts wiring that is globally true for this flake.

Examples:

- importing `inputs.flake-parts.flakeModules.modules`
- importing `inputs.flake-file.flakeModules.default`
- baseline `systems`
- stable root-wide flake behavior that should not be feature-local

### Feature Module

Where practical, a feature file should contain:

- the extra input declaration it introduces
- any `follows` wiring it needs
- any required flake-parts imports
- its exported `flake.modules.*`
- its local configuration

This is especially desirable for niche dependencies that only exist to support one feature.

### User Module

The eventual `features/users/ben/default.nix` should likely define both:

- `flake.modules.nixos.ben`
- `flake.modules.homeManager.ben`

The NixOS module should import the HM user module or otherwise wire it in as part of a multi-context feature.

### Host Module

The eventual `hosts/desktop/flake-module.nix` should mostly compose features.

Roughly:

```nix
{ inputs, ... }:
{
  flake.modules.nixos.hosts.desktop = {
    imports = [
      inputs.self.modules.nixos.system-base
      inputs.self.modules.nixos.homeManager
      inputs.self.modules.nixos.stylix
      inputs.self.modules.nixos.tailscale
      inputs.self.modules.nixos.impermanence
      inputs.self.modules.nixos.firefox
      inputs.self.modules.nixos.ben
    ];

    # desktop-specific overrides
  };
}
```

### Current Repository Mapping

These are likely migration destinations for the current layout.

### Current `flake.nix`

Current responsibilities to relocate:

- inputs -> split between `flake-file.nix` and feature-local input declarations
- `nixosConfigurations` -> `features/flake/outputs/nixos-configurations.nix`
- `apps`, `devShells`, `formatter`, `checks` -> `features/flake/outputs/per-system.nix`

### Current `modules/system/*`

Most of these should migrate into:

- `features/services/*`
- `features/programs/*`
- `features/system/*`

Examples:

- `modules/system/home-manager.nix` -> `features/services/homeManager.nix`
- `modules/system/stylix.nix` -> `features/services/stylix.nix`
- `modules/system/tailscale.nix` -> `features/services/tailscale.nix`
- `modules/system/firefox.nix` -> `features/programs/firefox.nix`

### Current `modules/home/*`

Most of these should migrate into shared feature directories wherever a feature spans both contexts.

Likely destinations:

- `features/programs/*`
- `features/desktop/*`
- `features/base/*`

Examples:

- `modules/home/firefox.nix` -> `features/programs/firefox.nix`
- `modules/home/emacs/default.nix` -> `features/programs/emacs.nix`
- `modules/home/window-manager/default.nix` -> `features/desktop/window-manager.nix`

### Current `users/ben/*`

Likely target:

- `features/users/ben/default.nix`

This should gradually absorb system user creation, Home Manager wiring, and personal module imports.

### Current `hosts/*`

These remain under `hosts/`, but should be converted from option-setting entrypoints into import-based compositions.

## Migration Phases

### Phase 0: Establish the Scaffold

Objective:

- add `flake-file`, `flake-parts`, and `import-tree`
- preserve existing behavior as much as possible
- create the new import roots without forcing immediate feature rewrites

Deliverables:

- `flake-file.nix`
- generated `flake.nix`
- `features/flake/root.nix`
- `features/flake/inputs/base.nix`
- `features/flake/outputs/per-system.nix`
- `features/flake/outputs/nixos-configurations.nix`

Checklist:

- [x] Add `flake-file` input and module bootstrap.
- [x] Add `flake-parts` input and modules support.
- [x] Add `import-tree` input.
- [x] Create `flake-file.nix` as the handwritten root.
- [x] Generate `flake.nix` from `flake-file.nix`.
- [x] Import both `./features` and `./hosts` recursively.
- [x] Move current `apps`, `checks`, `devShells`, and `formatter` into `perSystem` without behavior changes.
- [x] Move `nixosConfigurations` into a flake-parts module.
- [x] Verify `nix flake check` evaluates for all hosts.

Current status:

- `desktop`, `laptop`, and `pi` all evaluate through the new flake entrypoint.
- `nix flake check` passes on the working tree.
- `pi` now uses an explicit Grafana file-provider secret path instead of relying on the removed upstream default.

### Phase 1: First Vertical Slice

Objective:

- prove the model on a small but representative set of modules

Initial slice:

- Home Manager bootstrap wiring
- Firefox as a unified multi-context feature
- user `ben`
- host `desktop`

Deliverables:

- `features/services/homeManager.nix`
- `features/programs/firefox.nix`
- `features/users/ben/default.nix`
- `hosts/desktop/flake-module.nix`

Checklist:

- [x] Add `features/services/homeManager.nix` as the first bootstrap service feature.
- [x] Add `features/programs/firefox.nix` as a unified multi-context feature.
- [x] Create `features/users/ben/default.nix` as a multi-context feature.
- [x] Convert `hosts/desktop/flake-module.nix` to import-based composition.
- [x] Keep compatibility with remaining old Home Manager modules through transitional imports.
- [x] Verify desktop evaluates through the new host-module path.

Current status:

- Public `flake.modules` names are now flat feature names.
- Feature directories remain grouped by concern, but exported names do not mirror directory depth.
- `homeManager` is preferred over `home-manager` for new public feature names.
- `laptop` now also evaluates through the new flat-name host-module path.
- `desktop`, `laptop`, and `pi` host modules now import `homeManager`, `firefox`, `tailscale`, and `impermanence` explicitly where appropriate.

### Phase 2: Host Conversions

Objective:

- convert remaining hosts to compose features directly

Checklist:

- [x] Convert `hosts/laptop/flake-module.nix` to import-based composition.
- [x] Convert `hosts/pi/flake-module.nix` to import-based composition.
- [ ] Decide which host-private modules remain under each host versus becoming reusable features.
- [x] Verify all hosts evaluate through the new `flake.nixosConfigurations` path.

Current status:

- `desktop`, `laptop`, and `pi` now use `flake.modules.nixos.<host>`.
- `pi` still needs a real provisioned file at `/run/secrets/grafana-secret-key` for deployment-time Grafana startup.
- Global host defaults for `firefox`, `home-manager`, and `stylix` have been removed in favor of host imports.

### Phase 3: Feature Migration

Objective:

- move reusable modules out of the legacy option-toggle model

Checklist:

- [ ] Migrate core system features such as `stylix`, `tailscale`, and `impermanence`.
- [ ] Migrate Home Manager base features such as CLI and desktop layers.
- [ ] Migrate remaining reusable app and service modules.
- [ ] Add feature-local inputs where a module is the natural owner of a niche dependency.
- [ ] Replace host-side `config.modules.*.enable` usage with imports for migrated features.

Current status:

- Flat wrappers now exist for `stylix`, `tailscale`, and `impermanence` under `features/services/`.
- Host composition now selects these features via imports instead of relying on `hosts/default.nix` defaults.
- Host-local option sets still carry feature-specific configuration data such as Tailscale auth arguments and impermanence persistence roots.
- `ben` no longer depends on `allHomeModules`; Home Manager dependencies are now imported explicitly.
- `hyprbar` and `centerpiece` are now feature-local `flake-file` inputs, colocated with the features that use them.

### Phase 4: Cleanup

Objective:

- remove the old composition infrastructure once it is no longer needed

Checklist:

- [ ] Remove or drastically reduce `lib.allHomeModules`.
- [ ] Remove or drastically reduce `lib.mkUser`.
- [ ] Stop injecting broad module trees through `lib.mkSystem`.
- [ ] Delete migrated `options.modules.*.enable` selectors.
- [ ] Remove compatibility wrappers that are no longer used.
- [ ] Rename `features/` to `modules/` when the old tree is gone or clearly obsolete.

## Guardrails

These rules are intended to keep the migration predictable.

- Prefer wrappers and adapters over invasive rewrites early on.
- Keep changes vertical where possible: feature plus one host is better than partial broad churn.
- Do not point `import-tree` at the old mixed `modules/` tree.
- Every file under `features/` should be a real flake-class module suitable for recursive import.
- Keep host-specific code under `hosts/` unless it is genuinely reusable.
- Keep root-owned inputs minimal.
- Prefer flat feature names in `flake.modules`.
- Use directories for organization, not as a namespace that must be mirrored in exported names.

## Verification Checklist

Run these regularly during migration.

- [ ] `nix flake check`
- [ ] `nixos-rebuild build --flake .#desktop`
- [ ] `nixos-rebuild build --flake .#laptop`
- [ ] `nixos-rebuild build --flake .#pi`

When an individual feature is being migrated, also verify the smallest realistic evaluation path that exercises it.

## Notes

- The final state should feel smaller, not more abstract: modules should become easier to locate because naming and paths line up.
- The migration can leave old modules in place for quite a while if new dendritic wrappers make the transition safe.
- Once enough code has moved into `features/` and hosts are composing those features directly, renaming `features/` to `modules/` should be mostly mechanical.
