# Restore the applied tools list for readers

Chromium reproduced the regression at `8f77176`: opening a shared video project
through a read link showed the video while hiding **Applied**, even though the
project response included the brightness tool. The baseline rendered the applied
list in the carousel.

The editor now renders the list independently of edit permission. The existing
permission and processing lock gate undo, reset, removal and reordering.
The same item renders tool names for all viewers and enables its sortable
behavior only when its removal action is supplied.

## Validation

- `node --test --test-reporter=dot frontend/tests/*.test.mjs projects/tests/*.test.js`
  passed all 38 tests. `git diff --check` passed.
- `docker compose build frontend` passed compilation, type checking and static
  page generation with three existing lint warnings. Recreated only the frontend
  with `docker compose up -d --no-deps --no-build frontend`, restarted nginx and
  confirmed that `https://localhost:8080` responded successfully.
- The Chromium check at `/tmp/picturas-review-browser.lo4luA/check-fixed.py`
  created a two-tool video project and opened its carousel as the owner and
  through read and edit shares. All three could inspect both tools. The read
  view hid removal, reorder, undo and reset and disabled Clear. The edit share
  removed a tool with HTTP 204 and the API returned the updated pipeline.
- A subtitle run kept its applied tool visible while editing was locked. After
  the run completed and the editor switched to Results, reopening Edit exposed
  the controls again. Initial test attempts reused a stale project version when
  creating the second link and expected Edit controls in Results. The final
  driver used the current version and checked the normal mode transition.
