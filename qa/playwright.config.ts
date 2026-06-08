import { defineConfig, devices } from '@playwright/test';

/**
 * Configuración de Playwright para la capa de aceptación del arnés.
 *
 * - Los specs viven en `qa/web/`, uno por feature: `<feature-name>.spec.ts`.
 * - La URL base la inyecta el agente `qa` por env var `QA_BASE_URL`
 *   (tomada del `qa.base_url` del área en `backlog.json`).
 * - La evidencia (screenshots, traces, video) va a `qa/results/`, que está
 *   gitignored: es prueba efímera, no registro permanente. El registro
 *   permanente es `specs/<name>/acceptance.md`.
 *
 * El arnés NO levanta la app aquí (`webServer`): de eso se encarga el agente
 * `qa`, que corre `qa.start` en background y espera `qa.ready` antes de testear.
 */
export default defineConfig({
  testDir: './web',
  outputDir: './results',
  fullyParallel: false,
  forbidOnly: true,
  retries: 0,
  reporter: [['list'], ['html', { outputFolder: './results/report', open: 'never' }]],
  use: {
    baseURL: process.env.QA_BASE_URL || 'http://localhost:3000',
    screenshot: 'on',
    trace: 'on',
    video: 'retain-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],
});
