// PreToolUse(Edit|Write) — bloquea la edición directa de backlog.json.
//
// Toda mutación de backlog.json va por ./backlog.sh (transiciones validadas).
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
  let fp = "";
  try {
    fp = (JSON.parse(s.replace(/^﻿/, "").trim()).tool_input || {}).file_path || "";
  } catch (e) {
    process.exit(0); // input no parseable: no bloquear
  }
  const norm = fp.split("\\").join("/");
  if (!(norm === "backlog.json" || norm.endsWith("/backlog.json"))) process.exit(0);
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
      "Edición directa bloqueada por hook."
  );
  process.exit(2);
});
