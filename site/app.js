// Minimal hash-based router for the SPA.
const routes = {
  "/": `
    <div class="card">
      <h2>Welcome</h2>
      <p>This single-page app is hosted on Amazon S3 as a static website.</p>
      <p>Every push to <code>main</code> deploys it automatically with GitHub Actions.</p>
    </div>`,
  "/about": `
    <div class="card">
      <h2>About</h2>
      <p>Plain HTML, CSS and JavaScript. No build step is needed.</p>
      <p>Infrastructure is defined with Terraform in <code>infra/</code>.</p>
    </div>`,
  "/pipeline": `
    <div class="card">
      <h2>Pipeline</h2>
      <ol>
        <li>Developer pushes to <code>main</code></li>
        <li>GitHub Actions validates the site</li>
        <li>Files are synced to S3</li>
      </ol>
    </div>`,
};

const notFound = `
  <div class="card">
    <h2>404</h2>
    <p>Page not found. <a href="#/">Go home</a></p>
  </div>`;

function render() {
  const path = location.hash.replace(/^#/, "") || "/";
  document.getElementById("app").innerHTML = routes[path] || notFound;
  document.querySelectorAll("nav a").forEach((a) => {
    a.classList.toggle("active", a.dataset.route === path);
  });
}

window.addEventListener("hashchange", render);
window.addEventListener("DOMContentLoaded", render);

// version.txt is written by the pipeline; it is absent during local development.
fetch("version.txt")
  .then((r) => (r.ok ? r.text() : "local"))
  .then((v) => (document.getElementById("build").textContent = v.trim()))
  .catch(() => {});
