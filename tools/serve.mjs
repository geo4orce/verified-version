import { createServer } from "node:http";
import { readFile, stat } from "node:fs/promises";
import { dirname, extname, join, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const port = Number.parseInt(process.argv[2] ?? "8000", 10);

if (!Number.isInteger(port) || port < 1 || port > 65535) {
  throw new Error("PORT must be an integer from 1 to 65535");
}

const contentTypes = new Map([
  [".css", "text/css; charset=utf-8"],
  [".html", "text/html; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".json", "application/json; charset=utf-8"],
  [".png", "image/png"],
  [".svg", "image/svg+xml"],
]);

async function sendFile(response, filePath, status = 200, method = "GET") {
  const body = await readFile(filePath);
  response.writeHead(status, {
    "Cache-Control": "no-store",
    "Content-Length": body.length,
    "Content-Type": contentTypes.get(extname(filePath)) ?? "application/octet-stream",
  });
  response.end(method === "HEAD" ? undefined : body);
}

const server = createServer(async (request, response) => {
  if (request.method !== "GET" && request.method !== "HEAD") {
    response.writeHead(405, { Allow: "GET, HEAD" });
    response.end();
    return;
  }

  try {
    const pathname = decodeURIComponent(new URL(request.url, "http://localhost").pathname);
    let filePath = resolve(root, `.${pathname}`);
    const insideRoot = filePath === root || filePath.startsWith(`${root}${sep}`);

    if (!insideRoot) {
      await sendFile(response, join(root, "404.html"), 404, request.method);
      return;
    }

    if ((await stat(filePath)).isDirectory()) {
      filePath = join(filePath, "index.html");
    }

    await sendFile(response, filePath, 200, request.method);
  } catch (error) {
    if (error?.code === "ENOENT" || error instanceof URIError) {
      await sendFile(response, join(root, "404.html"), 404, request.method);
      return;
    }

    console.error(error);
    response.writeHead(500);
    response.end("Internal server error\n");
  }
});

server.listen(port, "127.0.0.1", () => {
  console.log(`Serving ${root}`);
  console.log(`http://localhost:${port}`);
  console.log("Press Ctrl+C to stop.");
});
