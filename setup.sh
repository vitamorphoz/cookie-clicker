cat > requirements.txt <<'EOF'
fastapi==0.109.0
uvicorn[standard]==0.25.0
jinja2==3.1.3
EOF

cat > main.py <<'EOF'
import uuid
from typing import Dict

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

app = FastAPI()
templates = Jinja2Templates(directory="templates")

user_scores: Dict[str, int] = {}
SESSION_COOKIE = "cc_session"


def get_session_id(request: Request) -> str:
    session_id = request.cookies.get(SESSION_COOKIE)
    if session_id and session_id in user_scores:
        return session_id
    new_id = uuid.uuid4().hex
    user_scores[new_id] = 0
    return new_id


@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    session_id = get_session_id(request)
    response = templates.TemplateResponse(
        "index.html",
        {"request": request, "score": user_scores[session_id]},
    )
    if not request.cookies.get(SESSION_COOKIE):
        response.set_cookie(
            key=SESSION_COOKIE,
            value=session_id,
            httponly=True,
            samesite="lax",
        )
    return response


@app.post("/click", response_class=JSONResponse)
async def click(request: Request):
    session_id = get_session_id(request)
    user_scores[session_id] += 1
    return {"score": user_scores[session_id]}


@app.get("/state", response_class=JSONResponse)
async def state(request: Request):
    session_id = get_session_id(request)
    return {"score": user_scores[session_id]}


app.mount("/static", StaticFiles(directory="static"), name="static")
EOF

mkdir -p templates static

cat > templates/index.html <<'EOF'
<!doctype html>
<html lang="ru">
<head>
  <meta charset="utf-8" />
  <title>Cookie Clicker</title>
  <link rel="stylesheet" href="/static/style.css" />
</head>
<body>
  <div class="app">
    <h1>Cookie Clicker</h1>
    <div class="score">
      Клики: <span id="score">{{ score }}</span>
    </div>
    <button id="click-btn">Клик!</button>
  </div>
  <script src="/static/main.js"></script>
</body>
</html>
EOF

cat > static/style.css <<'EOF'
:root {
  font-family: Inter, system-ui, -apple-system, sans-serif;
  background: #f4f5fb;
  color: #1b1e28;
}
body {
  display: grid;
  place-items: center;
  min-height: 100vh;
  margin: 0;
}
.app {
  background: #fff;
  padding: 24px 28px;
  border-radius: 12px;
  box-shadow: 0 12px 30px rgba(0, 0, 0, 0.08);
  text-align: center;
  min-width: 280px;
}
h1 { margin-top: 0; }
.score {
  font-size: 18px;
  margin: 12px 0 18px;
}
button#click-btn {
  background: linear-gradient(135deg, #ff9f1c, #ff6f61);
  color: white;
  border: none;
  border-radius: 10px;
  padding: 12px 20px;
  font-size: 16px;
  cursor: pointer;
  transition: transform 120ms ease, box-shadow 120ms ease;
}
button#click-btn:active {
  transform: translateY(1px) scale(0.99);
  box-shadow: 0 6px 16px rgba(0,0,0,0.12);
}
EOF

cat > static/main.js <<'EOF'
async function fetchState() {
  const res = await fetch("/state");
  const data = await res.json();
  document.getElementById("score").textContent = data.score;
}

async function click() {
  const res = await fetch("/click", { method: "POST" });
  const data = await res.json();
  document.getElementById("score").textContent = data.score;
}

document.addEventListener("DOMContentLoaded", () => {
  document.getElementById("click-btn").addEventListener("click", click);
  fetchState();
});
EOF
