#!/usr/bin/env bash
# init.sh — Verificación e inicialización del entorno
#
# Este script lo ejecuta el agente al COMENZAR una sesión y antes de
# declarar cualquier tarea como `done`. Si falla, la sesión no debe avanzar.
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

# Node disponible
if ! command -v node >/dev/null 2>&1; then
  fail "node no está instalado"
  exit 1
fi
ok "node -> $(node --version)"

# Versión mínima 22 (ejecución nativa de TypeScript + node --test, cero deps)
NODE_MAJOR=$(node -e 'process.stdout.write(String(process.versions.node.split(".")[0]))')
if [ "$NODE_MAJOR" -lt 22 ]; then
  fail "Se requiere Node >= 22 (ejecución nativa de TypeScript)"
  exit 1
fi
ok "Versión de Node compatible"

echo ""
echo "── 2. Verificando archivos base del arnés ──────────────"

for f in AGENTS.md backlog.json progress/current.md docs/architecture.md docs/conventions.md docs/verification.md CHECKPOINTS.md; do
  if [ ! -f "$f" ]; then
    fail "Falta archivo base: $f"
    EXIT_CODE=1
  else
    ok "Existe $f"
  fi
done

echo ""
echo "── 3. Validando backlog.json y specs ─────────────"

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
  if (it.sdd && requiresSpec.has(it.status)) {
    const specDir = `specs/${it.name}`;
    for (const fname of ["requirements.md", "design.md", "tasks.md"]) {
      if (!fs.existsSync(`${specDir}/${fname}`)) {
        specErrors.push(`item ${it.id} (${it.name}) en ${it.status} sin ${specDir}/${fname}`);
      }
    }
  }
}
if (specErrors.length) {
  for (const e of specErrors) console.log(`[FAIL]  ${e}`);
  process.exit(1);
}
console.log(`[OK]    backlog.json válido (${items.length} items)`);
console.log("[OK]    Specs presentes para items sdd con estado no-pending");
JS

if [ $? -ne 0 ]; then EXIT_CODE=1; fi

echo ""
echo "── 4. Ejecutando tests ─────────────────────────────────"

if [ -d "tests" ] && ls tests/*.* >/dev/null 2>&1; then
  if node --test tests/ 2>&1; then
    ok "Todos los tests pasan"
  else
    fail "Hay tests rotos"
    EXIT_CODE=1
  fi
else
  warn "Carpeta tests/ vacía o inexistente todavía"
fi

echo ""
echo "── 5. Resumen ──────────────────────────────────────────"

if [ $EXIT_CODE -eq 0 ]; then
  ok "Entorno listo. Puedes empezar a trabajar."
else
  fail "Entorno NO está listo. Resuelve los errores antes de avanzar."
fi

exit $EXIT_CODE
