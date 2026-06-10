#!/usr/bin/env bash
# backlog.sh — Única puerta de escritura de backlog.json.
#
# Los agentes NO editan backlog.json a mano (un hook lo bloquea): toda mutación
# pasa por aquí, donde las transiciones de estado se validan mecánicamente.
# Esto hace el flujo robusto incluso con modelos débiles: el script no se
# olvida de las reglas.
#
# Uso:
#   ./backlog.sh next                       # ítem accionable + paquete de contexto (JSON; incluye lista 'blocked' si hay)
#   ./backlog.sh get <name>                 # paquete de contexto de un ítem (JSON)
#   ./backlog.sh add '<json>'               # añade un ítem (status forzado a pending)
#   ./backlog.sh set-status <name> <status> # transición validada de estado
#
# Transiciones legales:
#   pending     → spec_ready (sdd) | in_progress (solo sin sdd) | blocked
#   spec_ready  → in_progress (tras aprobación HUMANA) | pending | blocked
#   in_progress → done | spec_ready | blocked
#   blocked     → pending | spec_ready | in_progress
#   done        → (ninguna)
#
# Gates automáticos:
#   set-status <name> spec_ready  → corre ./check-spec.sh <name> --stage spec
#   set-status <name> done        → corre ./check-spec.sh <name> --stage impl

set -u
CMD="${1:-}"
ARG1="${2:-}"
ARG2="${3:-}"

case "$CMD" in
  next|get|add|set-status) ;;
  *)
    echo "uso: ./backlog.sh next | get <name> | add '<json>' | set-status <name> <status>" >&2
    exit 1
    ;;
esac

# Gates mecánicos previos a las transiciones que cierran fases (solo ítems sdd;
# check-spec.sh devuelve OK inmediato para ítems sin sdd).
if [ "$CMD" = "set-status" ]; then
  if [ "$ARG2" = "spec_ready" ]; then
    ./check-spec.sh "$ARG1" --stage spec || {
      echo "[FAIL]  Gate de spec en rojo: corrige el spec antes de marcar spec_ready." >&2
      exit 1
    }
  elif [ "$ARG2" = "done" ]; then
    ./check-spec.sh "$ARG1" --stage impl || {
      echo "[FAIL]  Gate de implementación en rojo: no se puede marcar done." >&2
      exit 1
    }
  fi
fi

BL_CMD="$CMD" BL_ARG1="$ARG1" BL_ARG2="$ARG2" node <<'JS'
const fs = require("fs");

const cmd = process.env.BL_CMD;
const arg1 = process.env.BL_ARG1;
const arg2 = process.env.BL_ARG2;

const fail = (msg) => { console.error(`[FAIL]  ${msg}`); process.exit(1); };

let data;
try {
  data = JSON.parse(fs.readFileSync("backlog.json", "utf8"));
} catch (e) {
  fail(`backlog.json inválido: ${e.message}`);
}
const items = Array.isArray(data.items) ? data.items : (data.items = []);
const areas = (data.rules && data.rules.areas) || [];
const areaNames = new Set(areas.map((a) => a.name));
const validStatus = new Set((data.rules && data.rules.valid_status) || ["pending", "spec_ready", "in_progress", "done", "blocked"]);
const validTypes = new Set((data.rules && data.rules.valid_types) || ["feature", "bug", "refactor"]);

// Paquete de contexto: todo lo que un subagente necesita para trabajar el ítem
// sin re-leer backlog.json ni adivinar qué ítem le toca.
function packet(it) {
  const itemAreas = Array.isArray(it.area) ? it.area : (it.area ? [it.area] : []);
  return {
    id: it.id, name: it.name, type: it.type || "feature", status: it.status,
    sdd: it.sdd || false,
    title: it.title || "", description: it.description || "",
    acceptance: it.acceptance || [],
    spec_dir: `specs/${it.name}/`,
    spec_files: it.sdd === "lite" ? ["spec.md"] : ["requirements.md", "design.md", "tasks.md"],
    areas: itemAreas.map((an) => {
      const a = areas.find((x) => x.name === an) || { name: an };
      return {
        name: a.name, path: a.path,
        docs: a.docs, skills: a.skills || `${a.docs}/skills/SKILLS.md`,
        verify: a.verify || a.test || null,
        qa: (a.qa && a.qa.kind) ? a.qa : { kind: "none" },
      };
    }),
  };
}

function save() {
  fs.writeFileSync("backlog.json", JSON.stringify(data, null, 2) + "\n");
}

if (cmd === "next") {
  const it = items.find((i) => i.status !== "done" && i.status !== "blocked");
  const out = it ? packet(it) : { next: null, hint: "no hay ítems accionables" };
  // Los blocked no son accionables pero NUNCA invisibles: el leader debe
  // verlos y resolverlos con el humano (leader.md → Caso E).
  const blocked = items.filter((i) => i.status === "blocked").map((i) => i.name);
  if (blocked.length) out.blocked = blocked;
  console.log(JSON.stringify(out, null, 2));
  process.exit(0);
}

if (cmd === "get") {
  const it = items.find((i) => i.name === arg1);
  if (!it) fail(`no existe el ítem '${arg1}'`);
  console.log(JSON.stringify(packet(it), null, 2));
  process.exit(0);
}

if (cmd === "add") {
  let nu;
  try { nu = JSON.parse(arg1); } catch (e) { fail(`JSON inválido: ${e.message}`); }
  if (!nu.name || !/^[a-z0-9][a-z0-9-]*$/.test(nu.name)) fail("falta 'name' (kebab-case)");
  if (items.some((i) => i.name === nu.name)) fail(`ya existe un ítem con name '${nu.name}'`);
  if (!nu.title) fail("falta 'title'");
  const type = nu.type || "feature";
  if (!validTypes.has(type)) fail(`type inválido: ${type}`);
  if (nu.sdd && (!Array.isArray(nu.acceptance) || nu.acceptance.length === 0)) {
    fail("un ítem sdd requiere 'acceptance' (lista no vacía de criterios verificables)");
  }
  const itemAreas = Array.isArray(nu.area) ? nu.area : (nu.area ? [nu.area] : []);
  for (const an of itemAreas) {
    if (!areaNames.has(an)) fail(`área desconocida: ${an} (∈ rules.areas: ${[...areaNames].join(", ")})`);
  }
  const id = items.reduce((m, i) => Math.max(m, Number(i.id) || 0), 0) + 1;
  const item = { id, name: nu.name, type, title: nu.title, status: "pending" };
  if (nu.description) item.description = nu.description;
  if (itemAreas.length) item.area = itemAreas;
  if (nu.sdd !== undefined) item.sdd = nu.sdd;
  if (nu.acceptance) item.acceptance = nu.acceptance;
  items.push(item);
  save();
  console.log(`[OK]    ítem ${id} '${nu.name}' añadido como pending`);
  process.exit(0);
}

if (cmd === "set-status") {
  const it = items.find((i) => i.name === arg1);
  if (!it) fail(`no existe el ítem '${arg1}'`);
  if (!validStatus.has(arg2)) fail(`status inválido: ${arg2}`);

  const LEGAL = {
    pending: ["spec_ready", "in_progress", "blocked"],
    spec_ready: ["in_progress", "pending", "blocked"],
    in_progress: ["done", "spec_ready", "blocked"],
    blocked: ["pending", "spec_ready", "in_progress"],
    done: [],
  };
  const from = it.status;
  if (!(LEGAL[from] || []).includes(arg2)) {
    fail(`transición ilegal: ${from} → ${arg2} (legales desde ${from}: ${(LEGAL[from] || []).join(", ") || "ninguna"})`);
  }
  // Puerta de spec: un ítem sdd NUNCA salta de pending a in_progress.
  if (it.sdd && from === "pending" && arg2 === "in_progress") {
    fail("ítem sdd: pending → in_progress prohibido. Primero spec_ready + aprobación humana.");
  }
  // Una sola feature a la vez.
  if (arg2 === "in_progress" && items.some((i) => i !== it && i.status === "in_progress")) {
    fail("ya hay otro ítem in_progress (máximo 1)");
  }
  it.status = arg2;
  save();
  console.log(`[OK]    ${it.name}: ${from} → ${arg2}`);
  if (it.sdd && arg2 === "in_progress") {
    console.log("[NOTA]  Transición spec_ready → in_progress: requiere aprobación humana previa del spec.");
  }
  process.exit(0);
}
JS
exit $?
