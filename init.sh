#!/usr/bin/env bash
# init.sh — Verificación e inicialización del entorno
#
# Este script lo ejecuta el agente al COMENZAR una sesión y antes de
# declarar cualquier tarea como `done`. Si falla, la sesión no debe avanzar.
#
# El arnés es agnóstico de lenguaje y *area-first*: NO asume Node como runtime
# de tu proyecto. Cada área de `backlog.json` define su propio comando `verify`.
# `node` se usa aquí solo como herramienta interna del arnés para validar
# `backlog.json` y los specs.
#
# Salida esperada: códigos de salida claros y bloques marcados con [OK]/[FAIL].

set -u
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$1"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$1"; }
fail()  { printf "${RED}[FAIL]${NC}  %s\n" "$1"; }

EXIT_CODE=0

echo "── 1. Verificando entorno ─────────────────────────────"

# node es la herramienta interna del arnés (valida backlog.json y specs).
# NO es el runtime de tu proyecto: cada área define su propio `verify`.
if ! command -v node >/dev/null 2>&1; then
  fail "node no está disponible (el arnés lo usa para validar backlog.json)"
  exit 1
fi
ok "node (herramienta del arnés) -> $(node --version)"

echo ""
echo "── 2. Verificando archivos base del arnés ──────────────"

for f in AGENTS.md backlog.json backlog.sh check-spec.sh progress/current.md docs/architecture.md docs/conventions.md docs/verification.md CHECKPOINTS.md; do
  if [ ! -f "$f" ]; then
    fail "Falta archivo base: $f"
    EXIT_CODE=1
  else
    ok "Existe $f"
  fi
done

echo ""
echo "── 3. Validando backlog.json, áreas y specs ────────────"

node <<'JS'
const fs = require("fs");
let data;
try {
  data = JSON.parse(fs.readFileSync("backlog.json", "utf8"));
} catch (e) {
  console.log("[FAIL]  backlog.json o specs inválidos: " + e.message);
  process.exit(1);
}
const valid = new Set(["pending", "spec_ready", "in_progress", "done", "blocked"]);
const validTypes = new Set(data.rules?.valid_types || ["feature", "bug", "refactor"]);
const requiresSpec = new Set(["spec_ready", "in_progress", "done"]);
const items = Array.isArray(data.items) ? data.items : [];
const inProgress = items.filter((it) => it.status === "in_progress");
if (inProgress.length > 1) {
  console.log(`[FAIL]  Hay ${inProgress.length} tareas en in_progress (máximo 1)`);
  process.exit(1);
}
const specErrors = [];

// El arnés es area-first: SIEMPRE debe existir al menos un área.
const areas = Array.isArray(data.rules?.areas) ? data.rules.areas : [];
if (areas.length === 0) {
  console.log("[FAIL]  rules.areas está vacío: el arnés exige al menos un área (modo area-first)");
  process.exit(1);
}
const areaNames = new Set(areas.map((a) => a.name));
// Capacidad de aceptación por área (opt-in). Mapea name -> kind para validar
// luego que los items 'done' con área qa-activa tengan su acceptance.md.
const validQaKinds = new Set(["web", "http", "both", "none"]);
const areaQaKind = {};
for (const a of areas) {
  if (!a.name || !a.path || !a.docs) {
    specErrors.push(`área inválida (requiere name, path, docs): ${JSON.stringify(a)}`);
    continue;
  }
  // Cada área exige su conocimiento: conventions.md + un índice de skills.
  const skillsIndex = a.skills || `${a.docs}/skills/SKILLS.md`;
  if (!fs.existsSync(`${a.docs}/conventions.md`)) {
    specErrors.push(`área ${a.name} sin ${a.docs}/conventions.md`);
  }
  if (!fs.existsSync(skillsIndex)) {
    specErrors.push(`área ${a.name} sin índice de skills (${skillsIndex})`);
  }
  // Cada área exige cómo se verifica.
  if (!a.verify && !a.test) {
    specErrors.push(`área ${a.name} sin comando 'verify'`);
  }
  // Capa de aceptación opcional (ver docs/qa.md). Omitir qa ⇒ kind 'none'.
  const kind = a.qa && a.qa.kind ? a.qa.kind : "none";
  if (!validQaKinds.has(kind)) {
    specErrors.push(`área ${a.name} con qa.kind inválido: ${kind} (web|http|both|none)`);
  }
  if (["web", "http", "both"].includes(kind)) {
    // base_url siempre: es a dónde apunta el qa. start es OPCIONAL: si falta,
    // la app es de ciclo de vida externo (la levantás vos / docker-compose) y
    // el qa solo la usa, sin arrancarla ni bajarla. Ver docs/qa.md.
    if (!a.qa.base_url) specErrors.push(`área ${a.name} con qa.kind=${kind} sin qa.base_url`);
  }
  areaQaKind[a.name] = kind;
}
for (const it of items) {
  if (!valid.has(it.status)) {
    console.log(`[FAIL]  Estado inválido en item ${it.id}: ${it.status}`);
    process.exit(1);
  }
  const type = it.type || "feature";
  if (!validTypes.has(type)) {
    console.log(`[FAIL]  Tipo inválido en item ${it.id}: ${type}`);
    process.exit(1);
  }
  const itemAreas = Array.isArray(it.area) ? it.area : (it.area ? [it.area] : []);
  for (const an of itemAreas) {
    if (!areaNames.has(an)) {
      console.log(`[FAIL]  item ${it.id} con área desconocida: ${an}`);
      process.exit(1);
    }
  }
  if (it.sdd && requiresSpec.has(it.status)) {
    const specDir = `specs/${it.name}`;
    // "sdd": "lite" → un solo spec.md; "sdd": true → los 3 archivos Kiro-style.
    const required = it.sdd === "lite" ? ["spec.md"] : ["requirements.md", "design.md", "tasks.md"];
    for (const fname of required) {
      if (!fs.existsSync(`${specDir}/${fname}`)) {
        specErrors.push(`item ${it.id} (${it.name}) en ${it.status} sin ${specDir}/${fname}`);
      }
    }
    // Gate de aceptación: un item 'done' que toca un área con qa activo
    // (web/http/both) debe tener su acceptance.md (lo produce el agente qa).
    // Solo se exige en 'done': la aceptación corre después del implementer.
    if (it.status === "done") {
      const touchesQa = itemAreas.some((an) => ["web", "http", "both"].includes(areaQaKind[an]));
      if (touchesQa && !fs.existsSync(`${specDir}/acceptance.md`)) {
        specErrors.push(`item ${it.id} (${it.name}) done con área qa-activa sin ${specDir}/acceptance.md`);
      }
    }
  }
}
if (specErrors.length) {
  for (const e of specErrors) console.log(`[FAIL]  ${e}`);
  process.exit(1);
}
console.log(`[OK]    backlog.json válido (${items.length} items, ${areas.length} áreas)`);
console.log("[OK]    Cada área tiene conventions + skills + verify (+ qa si aplica)");
console.log("[OK]    Specs presentes para items sdd con estado no-pending");
console.log("[OK]    acceptance.md presente para items done con área qa-activa");
JS

if [ $? -ne 0 ]; then EXIT_CODE=1; fi

echo ""
echo "── 4. Verificando áreas (verify) ───────────────────────"

AREAS_TESTS=$(node -e 'const d=require("./backlog.json");(d.rules&&d.rules.areas||[]).forEach(a=>{const c=a.verify||a.test;if(c)console.log(a.name+"\t"+c)})')

if [ -n "$AREAS_TESTS" ]; then
  while IFS=$'\t' read -r area_name area_cmd; do
    echo "  [$area_name] $area_cmd"
    if eval "$area_cmd"; then
      ok "verify [$area_name] verde"
    else
      fail "verify [$area_name] rojo"
      EXIT_CODE=1
    fi
  done <<< "$AREAS_TESTS"
else
  warn "Ningún área define 'verify' todavía"
fi

echo ""
echo "── 5. Resumen ──────────────────────────────────────────"

if [ $EXIT_CODE -eq 0 ]; then
  ok "Entorno listo. Puedes empezar a trabajar."
else
  fail "Entorno NO está listo. Resuelve los errores antes de avanzar."
fi

exit $EXIT_CODE
