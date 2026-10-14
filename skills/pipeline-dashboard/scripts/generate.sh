#!/usr/bin/env bash
# Build the pipeline dashboard's data from the project's indexes, in one awk
# pass: the [ACTIVE] milestone of .claude/PLAN.md, its features and tasks, the
# current runbook and its steps, the units in flight in a wt/<unit> worktree
# (read from the git dir, no git call), and the question waiting in
# pending.json. Run from the project root. Writes nothing in the project.
# Usage: generate.sh                    write index.html (from ../assets/index.html, titled
#                                       "Pipeline <project>") and data.js into the state
#                                       folder, print the data.js path
#        generate.sh --text             print the text snapshot instead
#        generate.sh --print-state-dir  print the project's state folder and exit
# State folder: ${CLAUDE_HOME:-$HOME/.claude}/pipeline-dashboard/<slug>/, where
# <slug> is <owner>-<repo> of the origin remote, else the folder name.
set -u

case "${1-}" in
  --text) mode=text ;;
  --print-state-dir) mode=dir ;;
  '') mode=data ;;
  *) echo "usage: generate.sh [--text | --print-state-dir]" >&2; exit 2 ;;
esac

export LC_ALL=C
home="${CLAUDE_HOME:-$HOME/.claude}"
now=$(date '+%Y-%m-%d %H:%M')
asset="${0%/*}/../assets/index.html"

exec awk -v mode="$mode" -v root="$PWD" -v home="$home" -v now="$now" -v asset="$asset" '

# ---------- helpers ----------

function readfile(path, A,   n, line) {
  n = 0
  while ((getline line < path) > 0) { sub(/\r$/, "", line); A[++n] = line }
  close(path)
  return n
}

function exists(path,   line, r) {
  r = (getline line < path) > 0
  close(path)
  return r
}

function join(base, p) {
  gsub(/\\/, "/", p)
  return (p ~ /^\// || p ~ /^[A-Za-z]:/) ? p : base "/" p
}

function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }

function js(s) {
  gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); gsub(/\t/, "\\t", s)
  gsub(/[\001-\037]/, "", s)
  return "\"" s "\""
}

# Adds to SC every id named after "task"/"tasks" in s (single ids, ranges with
# a hyphen or an en dash, lists joined by commas, "and", "&" or "/").
function ids_from(s, SC,   n, a, b, t, m) {
  s = tolower(s); gsub(EN_DASH, "-", s); n = 0
  while (match(s, /tasks?[ ]+[0-9]/)) {
    s = substr(s, RSTART + RLENGTH - 1)
    while (match(s, /^[0-9]+/)) {
      a = substr(s, 1, RLENGTH) + 0; s = substr(s, RLENGTH + 1); b = a
      if (match(s, /^[ ]*-[ ]*[0-9]+/)) {
        t = substr(s, 1, RLENGTH); sub(/^[ ]*-[ ]*/, "", t)
        b = t + 0; s = substr(s, RLENGTH + 1)
      }
      if (b < a || b - a > 10000) b = a
      for (m = a; m <= b; m++) if (!(m in SC)) { SC[m] = 1; n++ }
      if (match(s, /^[ ]*(,|and|&|\/)[ ]*/)) s = substr(s, RLENGTH + 1)
      else break
    }
  }
  return n
}

# Sorted numeric keys of SET into OUT[1..n].
function sortkeys(SET, OUT,   n, k, i, j, v) {
  n = 0
  for (k in SET) OUT[++n] = k + 0
  for (i = 2; i <= n; i++) {
    v = OUT[i]
    for (j = i - 1; j > 0 && OUT[j] > v; j--) OUT[j + 1] = OUT[j]
    OUT[j + 1] = v
  }
  return n
}

function isdone(s) { return s == "DONE" || s == "SKIP" }

function bar(done, total, cells,   e, out, i) {
  e = (total > 0) ? int(done * cells * 8 / total) : 0
  if (e == 0 && done > 0) e = 1
  out = ""
  for (i = 0; i < int(e / 8); i++) out = out BLK[8]
  if (e % 8) { out = out BLK[e % 8]; i++ }
  for (; i < cells; i++) out = out BLK[0]
  return out
}

# At most max bytes, never inside a UTF-8 sequence.
function cut(t, max,   s, i, b, need) {
  if (length(t) <= max) return t
  s = substr(t, 1, max - 3)
  for (i = length(s); i > 0 && i > length(s) - 4; i--) {
    b = ORD[substr(s, i, 1)]
    if (b < 128) break
    if (b >= 192) {
      need = (b >= 240) ? 4 : (b >= 224) ? 3 : 2
      if (length(s) - i + 1 < need) s = substr(s, 1, i - 1)
      break
    }
  }
  return s ELL
}

# Pads s with spaces to w display cells, counting a UTF-8 sequence as one.
function pad(s, w,   c, i, b) {
  c = 0
  for (i = 1; i <= length(s); i++) { b = ORD[substr(s, i, 1)]; if (b < 128 || b >= 192) c++ }
  while (c++ < w) s = s " "
  return s
}

# ---------- project identity ----------

# The common git dir: root/.git, or where the .git file of a worktree points
# through its gitdir: line and commondir file.
function gitdir(   gd, line, p) {
  gd = root "/.git"
  if (exists(gd "/config")) return gd
  if ((getline line < gd) > 0 && line ~ /^gitdir: /) {
    gd = join(root, trim(substr(line, 9)))
    p = gd "/commondir"
    if ((getline line < p) > 0) gd = join(gd, trim(line))
    close(p)
  }
  close(root "/.git")
  return gd
}

# 1 when the worktree of unit (task-<N>, runbook-<id>-step-<n>) exists: git
# keeps one entry per worktree under <common git dir>/worktrees/, named after
# the directory basename, which the protocol makes the unit name, and its
# HEAD names the branch wt/<unit>.
function inflight(unit,   p, line, r) {
  p = GITD "/worktrees/" unit "/HEAD"
  r = (getline line < p) > 0
  close(p)
  sub(/\r$/, "", line)
  return r && line == "ref: refs/heads/wt/" unit
}

function origin_slug(gd,   line, n, C, i, sect, url, parts, k) {
  n = readfile(gd "/config", C); url = ""
  for (i = 1; i <= n; i++) {
    if (C[i] ~ /^\[/) sect = C[i]
    else if (sect ~ /^\[remote "origin"\]/ && C[i] ~ /^[ \t]*url[ \t]*=/) { url = C[i]; sub(/^[^=]*=[ \t]*/, "", url) }
  }
  if (url == "") return ""
  sub(/\/+$/, "", url); sub(/\.git$/, "", url)
  k = split(url, parts, /[\/:]/)
  if (k < 2) return ""
  return tolower(parts[k - 1] "-" parts[k])
}

# ---------- main ----------

BEGIN {
  for (i = 1; i < 256; i++) ORD[sprintf("%c", i)] = i
  EN_DASH = "\342\200\223"; EM_SEP = " \342\200\224 "; ELL = "\342\200\246"
  BLK[0] = "\342\226\221"; BLK[8] = "\342\226\210"
  BLK[1] = "\342\226\217"; BLK[2] = "\342\226\216"; BLK[3] = "\342\226\215"; BLK[4] = "\342\226\214"
  BLK[5] = "\342\226\213"; BLK[6] = "\342\226\212"; BLK[7] = "\342\226\211"

  gsub(/\\/, "/", root)
  project = root; sub(/\/+$/, "", project); sub(/.*\//, "", project)
  GITD = gitdir()
  slug = origin_slug(GITD)
  if (slug == "") slug = tolower(project)
  gsub(/[^a-z0-9._-]/, "-", slug)
  state = home "/pipeline-dashboard/" slug
  if (mode == "dir") { print state; exit 0 }

  cl = root "/.claude"
  nun = 0

  # ---- PLAN.md: the first [ACTIVE] milestone ----
  npl = readfile(cl "/PLAN.md", PL); nb = 0; mid = ""
  for (i = 1; i <= npl; i++) {
    if (PL[i] ~ /^## /) {
      nb++; h = substr(PL[i], 4); p = index(h, EM_SEP)
      MI[nb] = p ? substr(h, 1, p - 1) : h; MT[nb] = p ? substr(h, p + length(EM_SEP)) : ""
      MS[nb] = ""; MF[nb] = ""
    } else if (nb && PL[i] ~ /^Status: \[/) { s = PL[i]; sub(/^Status: \[/, "", s); sub(/\].*/, "", s); MS[nb] = s }
    else if (nb && PL[i] ~ /^Features: /) MF[nb] = substr(PL[i], 11)
  }
  for (i = 1; i <= nb && mid == ""; i++) if (MS[i] == "ACTIVE") { mid = MI[i]; mtitle = MT[i]; mfeats = MF[i] }
  nmf = 0
  if (mid != "" && mfeats != "none") {
    k = split(mfeats, FL, /[ ]*,[ ]*/)
    for (i = 1; i <= k; i++) { f = trim(FL[i]); if (f != "" && !(f in MFSET)) { MFSET[f] = 1; MFL[++nmf] = f } }
  }

  # ---- FEATURES.md ----
  nfe = readfile(cl "/FEATURES.md", FE); nfeat = 0; cur = ""
  for (i = 1; i <= nfe; i++) {
    if (FE[i] ~ /^## /) { split(FE[i], w, " "); cur = w[2]; FEAT[cur] = 1; FSTAT[cur] = ""; FTASKS[cur] = ""; nfeat++ }
    else if (cur != "" && FE[i] ~ /^Status: \[/) { s = FE[i]; sub(/^Status: \[/, "", s); sub(/\].*/, "", s); FSTAT[cur] = s }
    else if (cur != "" && FE[i] ~ /^Tasks: /) {
      s = substr(FE[i], 8); out = ""
      k = split(s, IDS, /[^0-9]+/)
      for (j = 1; j <= k; j++) if (IDS[j] != "") { out = out (out != "" ? " " : "") (IDS[j] + 0); TF[IDS[j] + 0] = cur }
      FTASKS[cur] = out
    }
  }

  # ---- TASKS.md ----
  ntk = readfile(cl "/TASKS.md", TK); ntask = 0; cur = ""
  for (i = 1; i <= ntk; i++) {
    if (TK[i] ~ /^## [0-9]+\. /) {
      cur = TK[i]; sub(/^## /, "", cur); sub(/\..*/, "", cur); cur += 0
      t = TK[i]; sub(/^## [0-9]+\. /, "", t)
      TT[cur] = t; TS[cur] = ""; TFE[cur] = ""; ntask++
    } else if (cur != "" && TS[cur] == "" && TK[i] ~ /^Status: \[/) { s = TK[i]; sub(/^Status: \[/, "", s); sub(/\].*/, "", s); TS[cur] = s }
    else if (cur != "" && TK[i] ~ /^Feature: /) TFE[cur] = trim(substr(TK[i], 10))
  }

  # ---- scope: the milestone features tasks, else every task ----
  if (mid != "") {
    for (i = 1; i <= nmf; i++) { k = split(FTASKS[MFL[i]], IDS, " "); for (j = 1; j <= k; j++) SCOPE[IDS[j] + 0] = 1 }
    for (id in TT) if (TFE[id] in MFSET) SCOPE[id] = 1
  } else for (id in TT) SCOPE[id] = 1
  for (id in SCOPE) WANT[id] = 1

  # ---- RUNBOOKS.md and the runbook body ----
  nrb = readfile(cl "/RUNBOOKS.md", RB); nr = 0; pick = 0
  for (i = 1; i <= nrb; i++) {
    if (RB[i] ~ /^## [0-9]+\. /) {
      nr++; h = RB[i]; sub(/^## /, "", h); RBI[nr] = h + 0; sub(/^[0-9]+\. /, "", h); p = index(h, EM_SEP)
      RBN[nr] = p ? substr(h, 1, p - 1) : h; RBT[nr] = p ? substr(h, p + length(EM_SEP)) : ""; RBS[nr] = ""; RBF[nr] = ""
    } else if (nr && RB[i] ~ /^Status: \[/) { s = RB[i]; sub(/^Status: \[/, "", s); sub(/\].*/, "", s); RBS[nr] = s }
    else if (nr && RB[i] ~ /^File: /) RBF[nr] = trim(substr(RB[i], 7))
  }
  for (i = 1; i <= nr && !pick; i++) if (RBS[i] == "RUNNING") pick = i
  if (!pick) pick = nr
  nst = 0
  if (pick && RBF[pick] != "") {
    nbody = readfile(join(root, RBF[pick]), BODY)
    if (!nbody) UN[++nun] = RBF[pick]
    for (i = 1; i <= nbody; i++) {
      if (BODY[i] ~ /^## Do not re-propose/) break
      if (BODY[i] ~ /^## \[.\] [0-9]+\. /) {
        nst++; SM[nst] = substr(BODY[i], 5, 1)
        h = substr(BODY[i], 8); SN[nst] = h; sub(/\..*/, "", SN[nst]); sub(/^[0-9]+\. /, "", h)
        ST[nst] = h; SD[nst] = ""
        delete SC
        if (!ids_from(h, SC)) {
          k = split(h, WD, /[^a-z0-9-]+/)
          for (j = 1; j <= k; j++) if (WD[j] in FEAT) {
            m = split(FTASKS[WD[j]], IDS, " "); for (q = 1; q <= m; q++) SC[IDS[q] + 0] = 1
            for (id in TT) if (TFE[id] == WD[j]) SC[id] = 1
            break
          }
        }
        n = sortkeys(SC, SO); out = ""
        for (j = 1; j <= n; j++) { out = out (out != "" ? " " : "") SO[j]; WANT[SO[j]] = 1 }
        SI[nst] = out
      } else if (nst && BODY[i] ~ /^Done: /) SD[nst] = substr(BODY[i], 7)
    }
    # a step in flight in its worktree renders as running
    for (i = 1; i <= nst; i++) if (inflight("runbook-" RBI[pick] "-step-" SN[i])) SM[i] = "~"
  }

  # ---- pending.json ----
  npd = readfile(state "/pending.json", PD); pend = ""
  for (i = 1; i <= npd; i++) pend = pend (i > 1 ? "\n" : "") PD[i]
  pend = trim(pend)
  if (pend !~ /^\{/) pend = "null"

  # ---- tasks shown: the scope plus every task a step names ----
  # a task in flight in its worktree renders as IN PROGRESS
  ntl = sortkeys(WANT, TL)
  for (i = 1; i <= ntl; i++) {
    id = TL[i]
    if (id in TT) { T_T[id] = TT[id]; T_S[id] = inflight("task-" id) ? "IN PROGRESS" : TS[id]; T_F[id] = TFE[id] != "" ? TFE[id] : TF[id] }
    else if (exists(cl "/tasks/archive/" id ".md")) {
      getline line < (cl "/tasks/archive/" id ".md"); close(cl "/tasks/archive/" id ".md")
      sub(/\r$/, "", line); sub(/^# Task [0-9]+ [^ ]+ /, "", line); sub(/^# /, "", line)
      T_T[id] = line; T_S[id] = "DONE"; T_F[id] = TF[id]
    } else { T_T[id] = ""; T_S[id] = "MISSING"; T_F[id] = TF[id]; T_GONE[id] = 1 }
  }

  # features shown: the milestone ones, else those with tasks in scope
  if (mid != "") for (i = 1; i <= nmf; i++) FSHOW[MFL[i]] = 1
  else for (i = 1; i <= ntl; i++) if ((TL[i] in SCOPE) && T_F[TL[i]] != "") FSHOW[T_F[TL[i]]] = 1

  if (mode == "text") text()
  else data()
  exit 0
}

function data(   out, i, id, f, first, j, k, IDS, sep, line, name) {
  system("mkdir -p \"" state "\"")
  name = project; gsub(/&/, "\\&amp;", name); gsub(/</, "\\&lt;", name); gsub(/>/, "\\&gt;", name)
  while ((getline line < asset) > 0) {
    if ((i = index(line, "__PROJECT__"))) line = substr(line, 1, i - 1) name substr(line, i + 11)
    print line > (state "/index.html")
  }
  close(asset); close(state "/index.html")
  out = state "/data.js"
  printf "window.DASH = {\n" > out
  printf "  project: %s,\n  slug: %s,\n  generated: %s,\n", js(project), js(slug), js(now) > out
  if (mid != "") {
    printf "  milestone: {id: %s, title: %s, features: [", js(mid), js(mtitle) > out
    for (i = 1; i <= nmf; i++) printf "%s%s", (i > 1 ? ", " : ""), js(MFL[i]) > out
    printf "]},\n" > out
  } else printf "  milestone: null,\n" > out
  printf "  features: {" > out; first = 1
  for (f in FSHOW) {
    k = split(FTASKS[f], IDS, " "); sep = ""
    printf "%s\n    %s: {status: %s, tasks: [", (first ? "" : ","), js(f), js(FSTAT[f]) > out
    for (j = 1; j <= k; j++) printf "%s%s", (j > 1 ? "," : ""), IDS[j] > out
    printf "]}" > out; first = 0
  }
  printf "\n  },\n  tasks: [\n" > out
  for (i = 1; i <= ntl; i++) {
    id = TL[i]
    printf "    {id: %d, title: %s, status: %s, feature: %s, scope: %s}%s\n", id, js(T_T[id]), js(T_S[id]), js(T_F[id]), ((id in SCOPE) ? "true" : "false"), (i < ntl ? "," : "") > out
  }
  printf "  ],\n" > out
  if (pick) {
    printf "  runbook: {name: %s, title: %s, status: %s, steps: [\n", js(RBN[pick]), js(RBT[pick]), js(RBS[pick]) > out
    for (i = 1; i <= nst; i++) {
      gsub(/ /, ",", SI[i])
      printf "    {n: %d, mark: %s, title: %s, done: %s, tasks: [%s]}%s\n", SN[i], js(SM[i]), js(ST[i]), js(SD[i]), SI[i], (i < nst ? "," : "") > out
    }
    printf "  ]},\n" > out
  } else printf "  runbook: null,\n" > out
  printf "  unreadable: [" > out
  for (i = 1; i <= nun; i++) printf "%s%s", (i > 1 ? ", " : ""), js(UN[i]) > out
  printf "],\n  pending: %s\n};\n", pend > out
  close(out)
  print out
}

function stepcount(i, D,   k, IDS, j, n) {
  k = split(SI[i], IDS, /[ ,]/); n = 0; D[1] = 0
  for (j = 1; j <= k; j++) if (IDS[j] != "") { n++; if (isdone(T_S[IDS[j] + 0])) D[1]++ }
  return n
}

function text(   i, j, sd, sr, sdone, tdone, ttot, trun, mk, n, D, k, IDS, id, shown, cnt, line, last) {
  if (!ntask && !pick && mid == "") { print project; print ""; print "No pipeline data in .claude/."; return }
  print project (mid != "" ? " \302\267 milestone " mid (mtitle != "" ? EM_SEP mtitle : "") : "")
  if (pick) print "runbook " RBN[pick] " (" RBS[pick] ")"
  print ""
  sdone = 0; for (i = 1; i <= nst; i++) if (SM[i] == "x") sdone++
  tdone = 0; ttot = 0; trun = 0
  for (i = 1; i <= ntl; i++) if (TL[i] in SCOPE) { ttot++; if (isdone(T_S[TL[i]])) tdone++; else if (T_S[TL[i]] == "IN PROGRESS") trun++ }
  if (pick) printf "steps  %s %d/%d\n", bar(sdone, nst, 20), sdone, nst
  printf "tasks  %s %d/%d%s\n", bar(tdone, ttot, 20), tdone, ttot, (trun ? "  (" trun " in progress)" : "")
  if (nst) {
    print ""
    last = 0; for (i = 1; i <= nst; i++) if (SM[i] == "x") last = i
    cnt = 0; for (i = 1; i <= nst; i++) if (SM[i] == "x") cnt++
    shown = 0
    for (i = 1; i <= nst; i++) {
      if (SM[i] == "x") { shown++; if (shown <= cnt - 2) continue }
      mk = SM[i] == "x" ? "\342\234\224" : SM[i] == "~" ? "\342\226\266" : SM[i] == "!" ? "\342\234\226" : SM[i] == "P" ? "\342\200\226" : "\302\267"
      n = stepcount(i, D)
      line = sprintf("%s %2d. %s", mk, SN[i], cut(ST[i], 52))
      if (n) line = pad(line, 60) " " bar(D[1], n, 6) " " D[1] "/" n
      print line
      k = split(SI[i], IDS, /[ ,]/)
      for (j = 1; j <= k; j++) { id = IDS[j] + 0; if (IDS[j] != "" && T_S[id] == "IN PROGRESS") print "      \342\206\263 #" id " " cut(T_T[id], 60) " (in progress)" }
    }
  }
  line = ""; cnt = 0
  for (i = ntl; i >= 1 && cnt < 3; i--) if ((TL[i] in SCOPE) && isdone(T_S[TL[i]]) && !(TL[i] in T_GONE)) { cnt++; line = line (line != "" ? "\n" : "") "  #" TL[i] " " cut(T_T[TL[i]], 70) }
  if (line != "") { print ""; print "last tasks done:"; print line }
  if (nun) { print ""; printf "unreadable:"; for (i = 1; i <= nun; i++) printf " %s", UN[i]; print "" }
}
'
