#!/usr/bin/env bash
: <<'CHOSKO_FRONTMATTER'
---
name: pipeline-statusline
version: 0.2.0
type: statusline
description: Status line showing the session (model, folder, branch, context, cost, rate limits) and the project's pipeline progress — current runbook, tasks in scope, tasks in progress. Wire it with /pipeline-statusline.
---
CHOSKO_FRONTMATTER
# Claude Code status line: session on line 1, runbook + task progress on line 2,
# one line per task in scope that is [IN PROGRESS] or in flight in a
# wt/task-<N> worktree after that.
# One awk process and no other fork: Claude Code drops a render that arrives
# late, and every fork costs ~0.5 s on Windows under load.
# Usage: pipeline-statusline.sh [--no-nerd-font]   (status JSON on stdin)

# --- Labels: every user-visible word ---
L_CTX='ctx'
L_RESET='until reset'
L_TASK='task'
L_INPROG='in corso'
L_5H='5h'
L_7D='7d'

# --- Glyphs (octal UTF-8, all single-cell): Nerd Font, then --no-nerd-font ---
NF_FOLDER='\357\201\273'   # nf-fa-folder
NF_BRANCH='\356\234\245'   # nf-dev-git_branch
NF_COMMIT='\356\234\251'   # nf-dev-git_commit
NF_RESET='\357\211\222'    # nf-fa-hourglass_half
NF_RUNBOOK='\357\201\213'  # nf-fa-play
NF_DONE='\357\200\214'     # nf-fa-check
NF_TASK='\357\200\223'     # nf-fa-cog
UC_FOLDER=''
UC_BRANCH='\342\216\207'   # ⎇
UC_COMMIT='@'
UC_RESET='\342\247\227'    # ⧗
UC_RUNBOOK='\342\226\266'  # ▶
UC_DONE='\342\234\224'     # ✔
UC_TASK='\342\206\263'     # ↳

if [ "${1-}" = --no-nerd-font ]; then
  G_FOLDER=$UC_FOLDER G_BRANCH=$UC_BRANCH G_COMMIT=$UC_COMMIT G_RESET=$UC_RESET
  G_RUNBOOK=$UC_RUNBOOK G_DONE=$UC_DONE G_TASK=$UC_TASK
else
  G_FOLDER=$NF_FOLDER G_BRANCH=$NF_BRANCH G_COMMIT=$NF_COMMIT G_RESET=$NF_RESET
  G_RUNBOOK=$NF_RUNBOOK G_DONE=$NF_DONE G_TASK=$NF_TASK
fi

export LC_ALL=C
exec awk \
  -v L_CTX="$L_CTX" -v L_RESET="$L_RESET" -v L_TASK="$L_TASK" \
  -v L_INPROG="$L_INPROG" -v L_5H="$L_5H" -v L_7D="$L_7D" \
  -v G_FOLDER="$G_FOLDER" -v G_BRANCH="$G_BRANCH" -v G_COMMIT="$G_COMMIT" \
  -v G_RESET="$G_RESET" -v G_RUNBOOK="$G_RUNBOOK" -v G_DONE="$G_DONE" \
  -v G_TASK="$G_TASK" '

# ---------- helpers ----------

# Every line of path into A[1..n]; n is 0 when the file is missing or empty.
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

function join(root, p) {
  gsub(/\\/, "/", p)
  return (p ~ /^\// || p ~ /^[A-Za-z]:/) ? p : root "/" p
}

# Adds to SC every id named after "task"/"tasks" in s: single ids, ranges
# with a hyphen or an en dash, lists joined by commas, "and", "&" or "/".
# Returns how many ids it added.
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

# Ten cells at eighth-block resolution; any non-zero value shows one eighth.
function bar(done, total,   e, out, i) {
  e = (total > 0) ? int(done * 80 / total) : 0
  if (e == 0 && done > 0 && total > 0) e = 1
  if (e > 80) e = 80
  out = ""
  for (i = 0; i < int(e / 8); i++) out = out BLK[8]
  if (e % 8) { out = out BLK[e % 8]; i++ }
  for (; i < 10; i++) out = out BLK[0]
  return out
}

function pct(done, total) { return (total > 0) ? int(done * 100 / total) : 0 }

function level(v, warn, crit) { return (v >= crit) ? R : (v >= warn) ? Y : G }

# At most max bytes, cut at a word boundary, never inside a UTF-8 sequence.
function cut(t, max,   s, i, b, lead, need) {
  if (length(t) <= max) return t
  s = substr(t, 1, max)
  if (substr(t, max + 1, 1) != " " && match(s, /.* /) && RLENGTH > max / 2) s = substr(s, 1, RLENGTH - 1)
  # drop a trailing incomplete multi-byte sequence
  for (i = length(s); i > 0 && i > length(s) - 4; i--) {
    b = ORD[substr(s, i, 1)]
    if (b < 128) break
    if (b >= 192) {
      need = (b >= 240) ? 4 : (b >= 224) ? 3 : 2
      if (length(s) - i + 1 < need) s = substr(s, 1, i - 1)
      break
    }
  }
  sub(/[ ]+$/, "", s)
  return s ELLIPSIS
}

# Branch name, or "@<short sha>" when detached; "" outside a repository.
# Walks up from dir; the .git file of a worktree redirects through gitdir:.
# Leaves the common git dir in GITDIR (through a worktree commondir file), ""
# when none was found.
function git_head(dir,   d, line, gd, p, rel) {
  d = dir; GITDIR = ""
  while (d != "") {
    p = d "/.git/HEAD"
    if ((getline line < p) > 0) { close(p); GITDIR = d "/.git"; break }
    close(p)
    p = d "/.git"
    if ((getline line < p) > 0) {
      close(p); sub(/\r$/, "", line)
      if (line !~ /^gitdir: /) return ""
      gd = join(d, substr(line, 9)); p = gd "/HEAD"
      if ((getline line < p) > 0) {
        close(p); GITDIR = gd
        p = gd "/commondir"
        if ((getline rel < p) > 0) { sub(/\r$/, "", rel); GITDIR = join(gd, rel) }
        close(p)
        break
      }
      close(p)
      return ""
    }
    close(p)
    if (d !~ /\//) return ""
    sub(/\/[^\/]*$/, "", d)
  }
  if (d == "") return ""
  sub(/\r$/, "", line)
  if (line ~ /^ref: refs\/heads\//) return substr(line, 17)
  if (line ~ /^[0-9a-f]+$/) return "@" substr(line, 1, 7)
  return ""
}

# 1 when the worktree of unit (task-<N>) exists: git keeps one entry per
# worktree under <common git dir>/worktrees/, named after the directory
# basename, which the protocol makes the unit name, and its HEAD names the
# branch wt/<unit>.
function inflight(unit,   p, line, r) {
  if (GITDIR == "") return 0
  p = GITDIR "/worktrees/" unit "/HEAD"
  r = (getline line < p) > 0
  close(p)
  sub(/\r$/, "", line)
  return r && line == "ref: refs/heads/wt/" unit
}

# ---------- JSON: flatten scalars into F["dotted.path"] ----------

function utf8(h,   c) {
  c = 0; h = tolower(h)
  while (h != "") { c = c * 16 + index("0123456789abcdef", substr(h, 1, 1)) - 1; h = substr(h, 2) }
  if (c < 128) return CHR[c]
  if (c < 2048) return CHR[192 + int(c / 64)] CHR[128 + c % 64]
  return CHR[224 + int(c / 4096)] CHR[128 + int(c / 64) % 64] CHR[128 + c % 64]
}

function emit(v,   p, k) {
  p = ""
  for (k = 1; k <= d; k++) p = p (k > 1 ? "." : "") key[k]
  F[p] = v
}

function flatten(s,   n, i, c, e, v, j) {
  n = length(s); d = 0; i = 1
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "{") { d++; typ[d] = "o"; key[d] = ""; expk = 1; i++; continue }
    if (c == "[") { d++; typ[d] = "a"; key[d] = 0;  expk = 0; i++; continue }
    if (c == "}" || c == "]") { d--; i++; continue }
    if (c == ":") { expk = 0; i++; continue }
    if (c == ",") { if (typ[d] == "o") expk = 1; else key[d]++; i++; continue }
    if (c == " " || c == "\t" || c == "\r" || c == "\n") { i++; continue }
    if (c == "\"") {
      v = ""; i++
      while (i <= n) {
        c = substr(s, i, 1)
        if (c == "\\") {
          e = substr(s, i + 1, 1)
          if (e == "n" || e == "t" || e == "r") v = v " "
          else if (e == "u") { v = v utf8(substr(s, i + 2, 4)); i += 4 }
          else v = v e
          i += 2; continue
        }
        i++
        if (c == "\"") break
        v = v c
      }
      if (typ[d] == "o" && expk) key[d] = v; else emit(v)
      continue
    }
    j = i
    while (j <= n && substr(s, j, 1) !~ /[,}\] \t\r\n]/) j++
    v = substr(s, i, j - i); i = j
    if (v != "null") emit(v)
  }
}

# ---------- main ----------

{ input = input $0 "\n" }

END {
  for (i = 1; i < 256; i++) { CHR[i] = sprintf("%c", i); ORD[CHR[i]] = i }
  E = "\033"; C = E "[36m"; G = E "[32m"; Y = E "[33m"; R = E "[31m"; D = E "[2m"; X = E "[0m"
  DOT = " " D "\302\267" X " "; ELLIPSIS = "\342\200\246"
  EN_DASH = "\342\200\223"; EM_SEP = " \342\200\224 "
  BLK[0] = "\342\226\221"; BLK[8] = "\342\226\210"
  BLK[1] = "\342\226\217"; BLK[2] = "\342\226\216"; BLK[3] = "\342\226\215"; BLK[4] = "\342\226\214"
  BLK[5] = "\342\226\213"; BLK[6] = "\342\226\212"; BLK[7] = "\342\226\211"
  srand(); now = srand()

  flatten(input)

  # ---- line 1: session ----
  dir = ("workspace.current_dir" in F) ? F["workspace.current_dir"] : ("cwd" in F) ? F["cwd"] : ""
  gsub(/\\/, "/", dir); if (dir ~ /.\/$/) sub(/\/+$/, "", dir)
  n1 = 0
  if ("model.display_name" in F) L1[++n1] = C F["model.display_name"] X
  if (dir != "") {
    base = dir; sub(/.*\//, "", base); if (base == "") base = dir
    L1[++n1] = (G_FOLDER != "" ? G_FOLDER " " : "") base
    h = git_head(dir)
    if (h ~ /^@/) L1[++n1] = Y G_COMMIT X " " substr(h, 2)
    else if (h != "") L1[++n1] = G G_BRANCH X " " h
  }
  if ("context_window.used_percentage" in F) {
    v = sprintf("%.0f", F["context_window.used_percentage"]) + 0
    L1[++n1] = level(v, 70, 90) v "%" X " " L_CTX
  }
  if ("cost.total_cost_usd" in F) L1[++n1] = sprintf("$%.2f", F["cost.total_cost_usd"])
  if ("rate_limits.five_hour.used_percentage" in F) {
    v = sprintf("%.0f", F["rate_limits.five_hour.used_percentage"]) + 0
    t = level(v, 50, 80) v "%" X " " L_5H
    r = F["rate_limits.five_hour.resets_at"]
    if (r ~ /^[0-9]+$/ && now > 0 && r - now > 0) {
      r -= now
      t = t " " D "(" X G_RESET " " C int(r / 3600) "h" int((r % 3600) / 60) "m" X " " D L_RESET ")" X
    }
    L1[++n1] = t
  }
  if ("rate_limits.seven_day.used_percentage" in F) {
    v = sprintf("%.0f", F["rate_limits.seven_day.used_percentage"]) + 0
    L1[++n1] = level(v, 50, 80) v "%" X " " L_7D
  }
  out = ""
  for (i = 1; i <= n1; i++) out = out (i > 1 ? DOT : "") L1[i]
  print out
  if (dir == "") exit

  # ---- pipeline files ----
  cl = dir "/.claude"
  nrb = readfile(cl "/RUNBOOKS.md", RB)
  ntk = readfile(cl "/TASKS.md", TK)
  if (nrb == 0 && ntk == 0) exit

  # runbook: first [RUNNING] block, else the last one
  nb = 0; pick = 0
  for (i = 1; i <= nrb; i++) {
    if (RB[i] ~ /^## [0-9]+\. /) {
      nb++; h = RB[i]; sub(/^## [0-9]+\. /, "", h)
      p = index(h, EM_SEP)
      if (p) { BN[nb] = substr(h, 1, p - 1); BT[nb] = substr(h, p + length(EM_SEP)) }
      else { BN[nb] = h; BT[nb] = "" }
      BS[nb] = ""; BF[nb] = ""; BD[nb] = 0; BTT[nb] = 0
    } else if (nb) {
      if (RB[i] ~ /^Status: \[/) { s = RB[i]; sub(/^Status: \[/, "", s); sub(/\].*/, "", s); BS[nb] = s }
      else if (RB[i] ~ /^File: /) BF[nb] = substr(RB[i], 7)
      else if (RB[i] ~ /^Steps: [0-9]+\/[0-9]+/) {
        s = substr(RB[i], 8); split(s, st, "/"); BD[nb] = st[1] + 0; BTT[nb] = st[2] + 0
      }
    }
  }
  for (i = 1; i <= nb && !pick; i++) if (BS[i] == "RUNNING") pick = i
  if (!pick) pick = nb

  # tasks: id, title, status, in file order
  nt = 0; cur = ""
  for (i = 1; i <= ntk; i++) {
    if (TK[i] ~ /^## [0-9]+\. /) {
      cur = TK[i]; sub(/^## /, "", cur); sub(/\..*/, "", cur); cur += 0
      t = TK[i]; sub(/^## [0-9]+\. /, "", t)
      ORDER[++nt] = cur; TT[cur] = t; TS[cur] = ""
    } else if (cur != "" && TS[cur] == "" && TK[i] ~ /^Status: \[/) {
      s = TK[i]; sub(/^Status: \[/, "", s); sub(/\].*/, "", s); TS[cur] = s
    }
  }

  # scope: (a) runbook title, (b) runbook step headings, (c) active milestone, (d) all
  scoped = 0
  if (pick) scoped = ids_from(BT[pick], SC)
  if (!scoped && pick && BF[pick] != "") {
    nbody = readfile(join(dir, BF[pick]), BODY)
    for (i = 1; i <= nbody; i++) {
      if (BODY[i] ~ /^## Do not re-propose/) break
      if (BODY[i] ~ /^## \[.\] [0-9]+\./) scoped += ids_from(BODY[i], SC)
    }
    # no id in any step heading: the Done: lines of the steps name them instead
    for (i = 1; i <= nbody && !scoped; i++) {
      if (BODY[i] ~ /^## Do not re-propose/) break
      if (BODY[i] ~ /^Done: /) nd += ids_from(BODY[i], DSC)
    }
    if (!scoped && nd) { for (id in DSC) SC[id] = 1; scoped = nd }
  }
  if (!scoped) {
    npl = readfile(cl "/PLAN.md", PL); act = 0; feats = ""
    for (i = 1; i <= npl && feats == ""; i++) {
      if (PL[i] ~ /^## /) act = 0
      else if (PL[i] ~ /^Status: \[ACTIVE\]/) act = 1
      else if (act && PL[i] ~ /^Features: /) feats = substr(PL[i], 11)
    }
    if (feats != "") {
      nf = split(feats, FL, /[ ]*,[ ]*/)
      for (i = 1; i <= nf; i++) { gsub(/[ ]/, "", FL[i]); if (FL[i] != "") WANT[FL[i]] = 1 }
      nfe = readfile(cl "/FEATURES.md", FE); slug = ""
      for (i = 1; i <= nfe; i++) {
        if (FE[i] ~ /^## /) { split(FE[i], w, " "); slug = w[2] }
        else if ((slug in WANT) && FE[i] ~ /^Tasks: [0-9]/) {
          nids = split(substr(FE[i], 8), IDS, /[^0-9]+/)
          for (j = 1; j <= nids; j++) if (IDS[j] != "" && !((IDS[j] + 0) in SC)) { SC[IDS[j] + 0] = 1; scoped++ }
        }
      }
    }
  }

  # a task in flight in its worktree counts and renders as [IN PROGRESS]
  for (i = 1; i <= nt; i++) {
    id = ORDER[i]
    if ((!scoped || (id in SC)) && inflight("task-" id)) TS[id] = "IN PROGRESS"
  }

  total = 0; done = 0; prog = 0
  if (scoped) {
    for (id in SC) {
      if (id in TS) {
        total++
        if (TS[id] == "DONE" || TS[id] == "SKIP") done++
        else if (TS[id] == "IN PROGRESS") prog++
      } else if (exists(cl "/tasks/archive/" id ".md")) { total++; done++ }
    }
  } else {
    for (i = 1; i <= nt; i++) {
      id = ORDER[i]; SC[id] = 1; total++
      if (TS[id] == "DONE" || TS[id] == "SKIP") done++
      else if (TS[id] == "IN PROGRESS") prog++
    }
  }

  # ---- line 2: runbook + tasks ----
  out = ""
  if (pick) {
    out = C G_RUNBOOK X " " BN[pick] " " bar(BD[pick], BTT[pick]) " " pct(BD[pick], BTT[pick]) "% " \
          BD[pick] "/" BTT[pick] (BS[pick] != "" ? " (" BS[pick] ")" : "")
  }
  if (ntk) {
    out = out (out != "" ? DOT : "") G G_DONE X " " L_TASK " " bar(done, total) " " pct(done, total) "% " \
          done "/" total (prog ? " (+" prog " " L_INPROG ")" : "")
  }
  if (out != "") print out

  # ---- lines 3+: tasks in progress, in scope ----
  for (i = 1; i <= nt; i++) {
    id = ORDER[i]
    if (TS[id] == "IN PROGRESS" && (id in SC))
      print Y G_TASK X " " C L_TASK " " id X DOT cut(TT[id], 90)
  }
}' 2>/dev/null
