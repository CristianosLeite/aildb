# TODO

What is left of the steps to version 1. The steps that are done, 2 to 11,
are in `BACKLOG.md` with every item they had. Version 1 was stated in a
file `REQUIREMENTS.md`, which left the repository on 2026-11-21 (its last
form is at the commit `ddc2b4d`); its four acceptance checks are met, and
the words of the first and the fourth are in `BACKLOG.md` under their
steps. The decisions behind the steps are in
`.agents/knowledge/architecture/`, and the questions still to be
decided in `.agents/knowledge/status/open-items.md`.

An item is a checkbox under the section of its step. One item is one
commit, with its tests and its documents. When it is completed it is moved
to `BACKLOG.md`, under the same section.

## 1. binary32 in AIL (work in the AIL repository)

The statements are written and `ail.pin` names the revision that has them
(`docs/BACKLOG.md`).

- [ ] Float literals (user's proposal): not needed for version 1.

## 11. Release

- [ ] The release itself, which is the user's: a tag and a version number;
  an executable that is passed on goes with
  `LICENSE` and `NOTICE`.
