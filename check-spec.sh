#!/usr/bin/env bash
# check-spec.sh — Gates mecánicos de un spec, por regex. Sin LLM.
#
# Todo lo que antes validaba el reviewer "a ojo" y se puede expresar como
# patrón, se valida aquí con exit code. El reviewer queda solo para lo que
# requiere criterio (causa raíz real, calidad del diseño, contrato público).
#
# Uso:
#   ./check-spec.sh <name> --stage spec   # tras el spec_author (pre-aprobación)
#   ./check-spec.sh <name> --stage impl   # tras el implementer (pre-done)
#
# Lo corre ./backlog.sh automáticamente en set-status spec_ready|done.
# Ítems sin "sdd" → OK inmediato (no tienen gates de spec).

set -u
NAME="${1:-}"
STAGE="spec"
if [ "${2:-}" = "--stage" ]; then STAGE="${3:-spec}"; fi
if [ -z "$NAME" ]; then
  echo "uso: ./check-spec.sh <name> [--stage spec|impl]" >&2
  exit 1
fi

CS_NAME="$NAME" CS_STAGE="$STAGE" node <<'JS'
const fs = require("fs");

const name = process.env.CS_NAME;
const stage = process.env.CS_STAGE;
let failures = 0;
const ok = (m) => console.log(`[OK]    ${m}`);
const bad = (m) => { console.log(`[FAIL]  ${m}`); failures++; };

let data;
try { data = JSON.parse(fs.readFileSync("backlog.json", "utf8")); }
catch (e) { bad(`backlog.json inválido: ${e.message}`); process.exit(1); }

const it = (data.items || []).find((i) => i.name === name);
if (!it) { bad(`no existe el ítem '${name}' en backlog.json`); process.exit(1); }
if (!it.sdd) { ok(`ítem '${name}' sin sdd: sin gates de spec`); process.exit(0); }

const lite = it.sdd === "lite";
const dir = `specs/${name}`;
const type = it.type || "feature";
const areas = (data.rules && data.rules.areas) || [];
const itemAreas = (Array.isArray(it.area) ? it.area : (it.area ? [it.area] : []))
  .map((an) => areas.find((a) => a.name === an)).filter(Boolean);
const qaActive = itemAreas.some((a) => a.qa && ["web", "http", "both"].includes(a.qa.kind));

// ── 1. Archivos del spec presentes ──────────────────────────────
const specFiles = lite ? ["spec.md"] : ["requirements.md", "design.md", "tasks.md"];
let missing = false;
for (const f of specFiles) {
  if (!fs.existsSync(`${dir}/${f}`)) { bad(`falta ${dir}/${f}`); missing = true; }
}
if (missing) { process.exit(1); }
ok(`spec ${lite ? "lite (spec.md)" : "completo (3 archivos)"} presente en ${dir}/`);

const read = (f) => fs.existsSync(`${dir}/${f}`) ? fs.readFileSync(`${dir}/${f}`, "utf8") : "";
const reqSrc = lite ? read("spec.md") : read("requirements.md");
const taskSrc = lite ? read("spec.md") : read("tasks.md");
const designSrc = lite ? read("spec.md") : read("design.md");

// ── 2. Requirements: EARS verificable ───────────────────────────
const rBlocks = [...reqSrc.matchAll(/^##+\s*(R\d+)\b[^\n]*\n([\s\S]*?)(?=^##|\n*$(?![\s\S]))/gm)];
const rIds = rBlocks.map((m) => m[1]);
if (rIds.length === 0) bad(`sin requirements: no hay encabezados '## R<n>' en ${lite ? "spec.md" : "requirements.md"}`);
else ok(`${rIds.length} requirement(s): ${rIds.join(", ")}`);
const dup = rIds.filter((r, i) => rIds.indexOf(r) !== i);
if (dup.length) bad(`ids de requirement duplicados: ${[...new Set(dup)].join(", ")}`);
for (const [, rid, body] of rBlocks) {
  if (!/\bDEBE\b|\bNO DEBE\b/.test(body)) bad(`${rid} sin 'DEBE'/'NO DEBE' (EARS exige verbo duro)`);
  if (/\b(podría|puede soportar|debería)\b/i.test(body)) bad(`${rid} usa verbo blando (podría/debería) — prohibido en EARS`);
}

// ── 3. Tasks: checklist con cobertura R<n> ──────────────────────
const taskLines = [...taskSrc.matchAll(/^- \[( |x)\] (T\d+)\b(.*)$/gm)];
if (taskLines.length === 0) bad(`sin tasks: no hay líneas '- [ ] T<n> — ... Cubre: R<n>' en ${lite ? "spec.md" : "tasks.md"}`);
else ok(`${taskLines.length} task(s)`);
const covered = new Set();
for (const [, , tid, rest] of taskLines) {
  const m = rest.match(/Cubre:\s*([^\n]*)/);
  if (!m) { bad(`${tid} sin 'Cubre: R<n>'`); continue; }
  for (const r of m[1].matchAll(/R\d+/g)) covered.add(r[0]);
}
for (const rid of rIds) {
  if (!covered.has(rid)) bad(`${rid} sin ninguna task que lo cubra`);
}
if (rIds.length && rIds.every((r) => covered.has(r))) ok("toda R<n> cubierta por al menos una task");

// ── 4. Design: conformidad por área y aceptación observable ─────
if (itemAreas.length > 0) {
  if (!/^##+\s*Conformidad\b/m.test(designSrc)) {
    bad(`falta sección '## Conformidad' (el ítem tiene área) en ${lite ? "spec.md" : "design.md"}`);
  } else {
    ok("sección '## Conformidad' presente");
    // Citas archivo:línea de la conformidad deben apuntar a archivos reales.
    const confSec = designSrc.split(/^##+\s*Conformidad\b/m)[1]?.split(/^##/m)[0] || "";
    for (const m of confSec.matchAll(/`([\w./\\-]+):(\d+)`/g)) {
      if (!fs.existsSync(m[1])) bad(`cita '${m[1]}:${m[2]}' en ## Conformidad: el archivo no existe`);
    }
  }
}
if (qaActive && !lite && !/^##+\s*Aceptación observable\b/m.test(designSrc)) {
  bad("falta sección '## Aceptación observable' en design.md (alguna área tiene qa.kind != none)");
}

// ── 5. Stage impl: tasks completas, trazabilidad, gates por tipo ─
if (stage === "impl") {
  const open = taskLines.filter(([, mark]) => mark !== "x").map(([, , tid]) => tid);
  if (open.length) bad(`tasks sin completar: ${open.join(", ")} (si hay justificación en impl.md, el humano decide el override)`);
  else ok("todas las tasks en [x]");

  const impl = read("impl.md");
  if (!impl) bad(`falta ${dir}/impl.md (informe del implementer)`);
  else {
    if (!/^##+\s*Trazabilidad\b/m.test(impl)) bad("impl.md sin sección '## Trazabilidad'");
    const trazSec = impl.split(/^##+\s*Trazabilidad\b/m)[1]?.split(/^##/m)[0] || "";
    for (const rid of rIds) {
      if (!new RegExp(`\\b${rid}\\b`).test(trazSec)) bad(`${rid} sin entrada en la trazabilidad de impl.md`);
    }
    if (type === "bug" && !(/ROJO/i.test(impl) && /VERDE/i.test(impl))) {
      bad("type=bug: impl.md sin evidencia rojo→verde del test de regresión");
    }
  }

  if (qaActive) {
    const acc = read("acceptance.md");
    if (!acc) bad(`falta ${dir}/acceptance.md (área con qa activo: el agente qa debe correr antes del done)`);
    else if (!/ACCEPTANCE_PASS/.test(acc)) bad("acceptance.md sin veredicto ACCEPTANCE_PASS");
    else ok("acceptance.md en ACCEPTANCE_PASS");
  }
}

console.log("");
if (failures) { console.log(`[FAIL]  check-spec '${name}' (--stage ${stage}): ${failures} problema(s)`); process.exit(1); }
console.log(`[OK]    check-spec '${name}' (--stage ${stage}): todos los gates mecánicos verdes`);
JS
exit $?
