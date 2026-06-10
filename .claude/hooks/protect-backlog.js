// PreToolUse(Edit|Write|Bash) — bloquea la mutación directa de backlog.json.
//
// Toda mutación de backlog.json va por ./backlog.sh (transiciones validadas).
// - Edit/Write: bloquea si file_path apunta a backlog.json.
// - Bash: bloquea comandos que ESCRIBEN backlog.json (redirección, sed -i,
//   tee/mv/cp/rm/truncate, writeFileSync). La lectura (cat, git diff, jq)
//   sigue permitida. `./backlog.sh` no matchea (el comando nombra al .sh,
//   no al .json), así que la puerta legítima no se ve afectada.
// Excepción: estado-plantilla (project == "mi-proyecto"), porque el agente
// `setup` estampa el backlog completo durante el onboarding.
//
// exit 0 = permitir · exit 2 = bloquear (stderr vuelve al modelo)
//
// Vive en un .js (no inline en el .sh): MSYS corrompe los backslashes de los
// scripts pasados como argumento a node.exe.

let s = "";
process.stdin.on("data", (d) => (s += d));
process.stdin.on("end", () => {
  let input;
  try {
    input = JSON.parse(s.replace(/^﻿/, "").trim());
  } catch (e) {
    process.exit(0); // input no parseable: no bloquear
  }
  const tool = input.tool_name || "";
  const ti = input.tool_input || {};

  let targets = false;
  if (tool === "Bash") {
    const cmd = ti.command || "";
    if (/backlog\.json/.test(cmd)) {
      // Solo patrones de ESCRITURA. Best-effort: la red de seguridad final
      // siguen siendo init.sh + check-spec.sh, que validan el contenido.
      const writeish = [
        />>?\s*["']?(\.\/)?\S*backlog\.json/, // redirección > / >>
        /\bsed\b[^|;&]*\s-i[^|;&]*backlog\.json/, // sed -i in-place
        /\b(tee|mv|cp|rm|truncate)\b[^|;&]*backlog\.json/, // sobrescritura/borrado
        /writeFileSync\s*\([^)]*backlog\.json/, // node inline
      ];
      targets = writeish.some((r) => r.test(cmd));
    }
  } else {
    const fp = ti.file_path || "";
    const norm = fp.split("\\").join("/");
    targets = norm === "backlog.json" || norm.endsWith("/backlog.json");
  }
  if (!targets) process.exit(0);

  try {
    const b = JSON.parse(require("fs").readFileSync("backlog.json", "utf8"));
    if (b.project === "mi-proyecto") process.exit(0); // onboarding: setup estampa directo
  } catch (e) {
    process.exit(0); // backlog roto: permitir reparación manual
  }
  console.error(
    "backlog.json se modifica SOLO via ./backlog.sh:\n" +
      "  ./backlog.sh add '<json>'               (ítem nuevo, Fase 0)\n" +
      "  ./backlog.sh set-status <name> <status>  (transición validada)\n" +
      "Mutación directa bloqueada por hook (Edit/Write/Bash de escritura)."
  );
  process.exit(2);
});
