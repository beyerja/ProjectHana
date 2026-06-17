# Tasks — 001-applocale-and-fallback

- [x] T1: Add `.ko`/`.nah` to `AppLocale` (displayName, matching). Extend `L10n` with the
      `[rawValue, "es-MX", "en"]` chain for ko/nah only (per-key fallthrough in string(_:locale:)).
- [x] T2: Add `nameKo`/`nameNah` (+ Country `capitalKo`/`capitalNah`) optional fields and ko/nah
      fallback (`?? nameEs ?? name`) to Country, River, Sea, MountainRange (explicit memberwise inits
      default new fields to nil).
- [x] T3: Create ko.lproj/nah.lproj Localizable.strings (picker keys seeded; rest fall back).
      Registered in project.yml, ran just generate.
- [x] T4: Tests — AppLocaleTests (matching ko/nah, bundleCandidates chain, allCases=6), model
      localizedName/Capital fallback (ko/nah → es-MX → en).
- [x] T5: just lint + just test green; committed (0d59600).
