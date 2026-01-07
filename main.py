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
