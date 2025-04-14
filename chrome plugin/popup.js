document.addEventListener("DOMContentLoaded", () => {
  chrome.storage.local.get("formAnalyzer", ({ formAnalyzer }) => {
    if (!formAnalyzer) {
      document.getElementById("results").innerText = "No hay datos disponibles.";
      return;
    }

    const riskClass = formAnalyzer.risk === "Alta" ? "high" : formAnalyzer.risk === "Media" ? "medium" : "low";

    document.getElementById("results").innerHTML = `
      <p><strong>URL:</strong> ${formAnalyzer.url}</p>
      <p><strong>Inputs:</strong> ${formAnalyzer.inputs}</p>
      <p><strong>CSRF tokens:</strong> ${formAnalyzer.csrfTokens}</p>
      <p><strong>Cookies sospechosas:</strong> ${formAnalyzer.suspiciousCookies.length}</p>
      <p><strong>Headers de Seguridad:</strong></p>
      <ul>
        <li>CSP: ${formAnalyzer.headers["Content-Security-Policy"] || 'N/A'}</li>
        <li>X-Frame-Options: ${formAnalyzer.headers["X-Frame-Options"] || 'N/A'}</li>
        <li>HSTS: ${formAnalyzer.headers["Strict-Transport-Security"] || 'N/A'}</li>
      </ul>
      <p class="${riskClass}"><strong>Riesgo estimado:</strong> ${formAnalyzer.risk}</p>
      <p><small>Detectado en: ${formAnalyzer.detectedAt}</small></p>
    `;
  });
});
