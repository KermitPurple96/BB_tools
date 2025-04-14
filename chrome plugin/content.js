(function () {
  const inputs = document.querySelectorAll("input, textarea, select");
  const csrfTokens = [...document.querySelectorAll("input[name*='csrf']")].length;

  const headers = {};
  const cookies = document.cookie;
  const suspiciousCookies = cookies.split(';').filter(c => c.toLowerCase().includes('session') || c.toLowerCase().includes('token'));

  chrome.runtime.sendMessage({ type: "getHeaders" }, async (res) => {
    const responseHeaders = res?.headers || {};
    const securityHeaders = {
      "Content-Security-Policy": responseHeaders["content-security-policy"] || "",
      "X-Frame-Options": responseHeaders["x-frame-options"] || "",
      "Strict-Transport-Security": responseHeaders["strict-transport-security"] || ""
    };

    const score = inputs.length + csrfTokens;
    const risk = score > 10 ? "Alta" : score > 5 ? "Media" : "Baja";

    chrome.storage.local.set({
      formAnalyzer: {
        url: location.href,
        inputs: inputs.length,
        csrfTokens,
        cookies,
        suspiciousCookies,
        headers: securityHeaders,
        score,
        risk,
        detectedAt: new Date().toISOString()
      }
    });
  });
})();
