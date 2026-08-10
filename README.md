# verified-version.org

Static landing page for `vv`, a small command that returns a tool's version as
one strict SemVer triple.

- Canonical site: <https://verified-version.org/>
- Redirect domain: <https://verifiedversion.org/>
- Hosting: DigitalOcean App Platform static site
- Production branch: `main`

## Local preview

The site has no build step. Serve the repository root with any static web
server, for example:

```sh
python -m http.server 8000
```

Then open <http://localhost:8000/>.

## Publishing

Changes pushed to `main` deploy automatically through DigitalOcean App
Platform. Keep the site static and do not commit credentials or generated local
configuration.

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidance.
