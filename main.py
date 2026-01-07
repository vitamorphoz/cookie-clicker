import uuid
import time
from typing import Dict
from dataclasses import dataclass, field

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

app = FastAPI()
templates = Jinja2Templates(directory="templates")

@dataclass
class UserStats:
    score: int = 0
    best_score: int = 0
    start_time: float = field(default_factory=time.time)
    last_click_time: float = field(default_factory=time.time)
    click_history: list = field(default_factory=list)

user_stats: Dict[str, UserStats] = {}
SESSION_COOKIE = "cc_session"


def get_session_id(request: Request) -> str:
    session_id = request.cookies.get(SESSION_COOKIE)
    if session_id and session_id in user_stats:
        return session_id
    new_id = uuid.uuid4().hex
    user_stats[new_id] = UserStats()
    return new_id


@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    session_id = get_session_id(request)
    response = templates.TemplateResponse(
        "index.html",
        {"request": request, "score": user_stats[session_id].score},
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
    stats = user_stats[session_id]
    stats.score += 1
    
    # Update best score
    if stats.score > stats.best_score:
        stats.best_score = stats.score
    
    # Track click for CPS calculation
    current_time = time.time()
    stats.click_history.append(current_time)
    
    # Keep only last 10 seconds of clicks
    stats.click_history = [t for t in stats.click_history if current_time - t <= 10]
    
    # Calculate clicks per second
    cps = len(stats.click_history) / min(10, current_time - stats.start_time)
    
    return {
        "score": stats.score,
        "best_score": stats.best_score,
        "cps": round(cps, 1),
        "session_time": int(current_time - stats.start_time)
    }


@app.get("/state", response_class=JSONResponse)
async def state(request: Request):
    session_id = get_session_id(request)
    stats = user_stats[session_id]
    current_time = time.time()
    
    # Calculate CPS from history
    stats.click_history = [t for t in stats.click_history if current_time - t <= 10]
    cps = len(stats.click_history) / min(10, current_time - stats.start_time) if stats.click_history else 0
    
    return {
        "score": stats.score,
        "best_score": stats.best_score,
        "cps": round(cps, 1),
        "session_time": int(current_time - stats.start_time)
    }


app.mount("/static", StaticFiles(directory="static"), name="static")
