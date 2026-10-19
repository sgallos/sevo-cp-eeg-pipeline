#!/bin/zsh
# Run a MATLAB command non-interactively from the repo root, retrying when
# MATLAB itself crashes. (R2024a crashes intermittently in background service
# threads on macOS 26; the crash is unrelated to the code being run.)
#   tools/matlab_batch.sh "runtests('tests')"
MATLAB_BIN="${MATLAB_BIN:-/Applications/MATLAB_R2024a.app/bin/matlab}"
cd "${0:A:h}/.." || exit 1
for attempt in 1 2 3 4 5; do
  out=$("$MATLAB_BIN" -batch "addpath(pwd); $1" 2>&1)
  code=$?
  if print -r -- "$out" | grep -q "MATLAB is exiting because of fatal error"; then
    print -u2 "[matlab_batch] MATLAB crashed (attempt $attempt), retrying..."
    rm -f ~/matlab_crash_dump.*(N)
    continue
  fi
  print -r -- "$out" | grep -vE "sun\.awt|illegal reflective|WARNING: (Please|Use --|All illegal|An illegal)"
  exit $code
done
print -u2 "[matlab_batch] MATLAB crashed 5 times in a row; giving up."
exit 1
