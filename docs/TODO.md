# TODO

The steps to version 1, in the order in which one unblocks the next.
Version 1 was stated in a file `REQUIREMENTS.md`, which left the repository
on 2026-11-21 (its last form is at the commit `ddc2b4d`); the two
acceptance checks that are still open are quoted from it under their
steps. The decisions behind these steps are in
`.agents/knowledge/architecture/`, and the questions still to be
decided in `.agents/knowledge/status/open-items.md`.

An item is a checkbox under the section of its step. One item is one
commit, with its tests and its documents. When it is completed it is moved
to `BACKLOG.md`, under the same section.

## 0. Decisions before the first code

- [ ] Git: the remote and the published name. The repository was
  initialized on 2026-11-21, with a `.gitignore`.

## 1. binary32 in AIL (work in the AIL repository)

The statements are written and `ail.pin` names the revision that has them
(`docs/BACKLOG.md`).

- [ ] Float literals (user's proposal): not needed for version 1.

## 11. Release

- [ ] `AGENTS.md` and the knowledge base brought up to date for the
  release (the section "State" was rewritten when step 8 was done).
- [ ] If a release ships executables: the MIT notice of AIL goes with
  them, since the code of its library is compiled into `build/aildb`.
