<div class="landing-page">
  <nav class="landing-nav" aria-label="Primary navigation">
    <a class="landing-brand" href="./index.html" aria-label="Nix Test home">
      <span class="landing-brand-mark" aria-hidden="true">❄</span>
      <span>Nix Test</span>
    </a>
    <div class="landing-nav-links">
      <a href="./getting-started.html">Docs</a>
      <a href="./getting-started.html">Get Started</a>
      <a href="./reference/index.html">API Reference</a>
      <a class="landing-github" href="https://github.com/sand4rt/nix-test" aria-label="Nix Test on GitHub" title="GitHub">
        <svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M12 .7a11.5 11.5 0 0 0-3.64 22.4c.58.1.79-.25.79-.56v-2.23c-3.22.7-3.9-1.37-3.9-1.37-.52-1.34-1.29-1.7-1.29-1.7-1.05-.72.08-.71.08-.71 1.17.08 1.78 1.2 1.78 1.2 1.04 1.78 2.72 1.27 3.38.97.1-.75.4-1.27.74-1.56-2.57-.3-5.27-1.29-5.27-5.69 0-1.26.45-2.28 1.19-3.09-.12-.3-.52-1.47.11-3.05 0 0 .97-.31 3.16 1.18a10.9 10.9 0 0 1 5.76 0c2.2-1.49 3.16-1.18 3.16-1.18.63 1.58.23 2.75.11 3.05.74.81 1.19 1.83 1.19 3.09 0 4.42-2.71 5.39-5.29 5.68.42.36.79 1.06.79 2.14v3.17c0 .31.21.67.8.56A11.5 11.5 0 0 0 12 .7Z"/></svg>
      </a>
    </div>
  </nav>
  <section class="landing-hero">
    <div class="landing-hero-copy">
      <div class="landing-snowflake" aria-hidden="true">
        <span></span><span></span><span></span>
      </div>
      <h1>Integration tests,<br><em>the Nix way.</em></h1>
      <p>Test what users and operators can observe. Define the environment, interactions, and expectations in one declarative Nix expression.</p>
      <div class="landing-actions">
        <a class="landing-button landing-button-primary" href="./getting-started.html">Get Started <span aria-hidden="true">→</span></a>
        <a class="landing-button landing-button-secondary" href="./reference/index.html">API Reference <span aria-hidden="true">→</span></a>
      </div>
      <p class="landing-meta"><span>MIT Licensed</span><i></i><span>Built for NixOS &amp; Flakes</span></p>
    </div>
    <div class="landing-code-card" aria-label="Nix Test example">
      <div class="landing-code-bar">
        <div class="landing-dots" aria-hidden="true"><span></span><span></span><span></span></div>
        <strong>example.test.nix</strong>
        <button class="landing-copy" type="button" aria-label="Copy example code" title="Copy code">
          <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M9 8h10v11H9zM5 5h10v3M5 5v11h4" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/></svg>
        </button>
      </div>
      <div class="landing-code-content"><code><span class="tok-blue">test</span>.<span class="tok-green">&quot;service is healthy&quot;</span> = {&#10;  <span class="tok-blue">machine</span>, <span class="tok-blue">expect</span>, ...&#10;}: [&#10;  (<span class="tok-blue">machine</span>.configure {&#10;    modules = [ <span class="tok-violet">./service.nix</span> ];&#10;  })&#10;  (<span class="tok-blue">expect</span>.toBeActive&#10;    (<span class="tok-blue">machine</span>.service <span class="tok-green">&quot;app.service&quot;</span>))&#10;  (<span class="tok-blue">expect</span>.toHaveStatus <span class="tok-cyan">200</span>&#10;    (<span class="tok-blue">machine</span>.http.get&#10;      <span class="tok-green">&quot;http://localhost/health&quot;</span>))&#10;];</code></div>
      <div class="landing-code-footer">
        <span><i class="landing-check">✓</i> Declarative</span>
        <span><i class="landing-check">✓</i> Reproducible</span>
        <span><i class="landing-check">✓</i> CI-ready</span>
      </div>
    </div>
  </section>
  <section class="landing-features" aria-label="Features">
    <article>
      <span class="landing-feature-icon">⌁</span>
      <div><h2>Nix-native</h2><p>No separate test runner or configuration language. Tests are ordinary flake checks.</p></div>
    </article>
    <article>
      <span class="landing-feature-icon">◫</span>
      <div><h2>Behavior-first</h2><p>Drive terminals, services, HTTP endpoints, files, browsers, and full NixOS VMs.</p></div>
    </article>
    <article>
      <span class="landing-feature-icon">✓</span>
      <div><h2>Reliable by default</h2><p>Retry observable state until it is ready while side effects execute exactly once.</p></div>
    </article>
  </section>
  <footer class="landing-footer">
    <span>Built for the Nix ecosystem.</span>
    <span><a href="./getting-started.html">Documentation</a><i></i><a href="https://github.com/sand4rt/nix-test">GitHub</a></span>
  </footer>
</div>
