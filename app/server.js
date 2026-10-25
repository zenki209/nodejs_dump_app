const http = require("http");

const port = Number(process.env.PORT) || 3000;

const server = http.createServer((req, res) => {
  if (req.method === "GET" && req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify({ status: "ok" }));
  }
  res.writeHead(404);
  res.end();
});

server.listen(port, () => console.log(`listening on ${port}`));

process.on("SIGTERM", () => server.close(() => process.exit(0)));
