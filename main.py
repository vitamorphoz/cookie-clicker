import uuid
import time
import json
from pathlib import Path
from typing import Dict
from dataclasses import dataclass, field

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

app = FastAPI()
templates = Jinja2Templates(directory="templates")

# Path to store best scores
BEST_SCORES_FILE = Path("best_scores.json")

# In-memory cache of best scores - load at module initialization
_best_scores_cache: Dict[str, int] = {}

def _load_initial_scores():
    """Load best scores from file at module initialization"""
    global _best_scores_cache
    if BEST_SCORES_FILE.exists():
        try:
            with open(BEST_SCORES_FILE, 'r') as f:
                _best_scores_cache = json.load(f)
        except (json.JSONDecodeError, IOError):
            _best_scores_cache = {}

# Load scores when module is imported
_load_initial_scores()

@dataclass
class UserStats:
    score: int = 0
    best_score: int = 0
    start_time: float = field(default_factory=time.time)
    last_click_time: float = field(default_factory=time.time)
    click_history: list = field(default_factory=list)

user_stats: Dict[str, UserStats] = {}
SESSION_COOKIE = "cc_session"


def load_best_scores() -> Dict[str, int]:
    """Return the cached best scores"""
    return _best_scores_cache


def save_best_score(session_id: str, score: int) -> None:
    """Save best score to file and update cache"""
    _best_scores_cache[session_id] = score
    try:
        with open(BEST_SCORES_FILE, 'w') as f:
            json.dump(_best_scores_cache, f)
    except IOError:
        pass  # Fail silently if we can't write


def get_session_id(request: Request) -> tuple[str, bool]:
    session_id = request.cookies.get(SESSION_COOKIE)
    is_new = False
    
    # If no cookie, create new session ID
    if not session_id:
        session_id = uuid.uuid4().hex
        is_new = True
    
    # Return existing session if it exists
    if session_id in user_stats:
        return session_id, is_new
    
    # Create new session stats, preserving best score from cache
    best_score = _best_scores_cache.get(session_id, 0)
    
    user_stats[session_id] = UserStats(best_score=best_score)
    return session_id, is_new


def reset_session_for_page_load(session_id: str) -> None:
    """Reset session stats when page is loaded/reloaded, but keep best score"""
    best_score = _best_scores_cache.get(session_id, 0)
    user_stats[session_id] = UserStats(best_score=best_score)


def ensure_session_cookie(response: JSONResponse | HTMLResponse, request: Request, session_id: str, is_new: bool) -> None:
    if is_new or not request.cookies.get(SESSION_COOKIE):
        response.set_cookie(
            key=SESSION_COOKIE,
            value=session_id,
            httponly=True,
            samesite="lax",
        )


@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    session_id, is_new = get_session_id(request)
    # Reset stats on page load (requirement 3)
    reset_session_for_page_load(session_id)
    response = templates.TemplateResponse(
        "index.html",
        {"request": request, "score": user_stats[session_id].score},
    )
    ensure_session_cookie(response, request, session_id, is_new)
    return response


@app.post("/click", response_class=JSONResponse)
async def click(request: Request):
    session_id, is_new = get_session_id(request)
    stats = user_stats[session_id]
    stats.score += 1
    
    # Update best score
    if stats.score > stats.best_score:
        stats.best_score = stats.score
        save_best_score(session_id, stats.best_score)
    
    # Track click for CPS calculation
    current_time = time.time()
    stats.click_history.append(current_time)
    
    # Keep only last 60 seconds of clicks
    stats.click_history = [t for t in stats.click_history if current_time - t <= 60]
    
    # Calculate clicks per second (based on last 60 seconds or session duration, whichever is smaller)
    time_window = min(60, max(1, current_time - stats.start_time))
    cps = len(stats.click_history) / time_window
    
    response = JSONResponse({
        "score": stats.score,
        "best_score": stats.best_score,
        "cps": round(cps, 1),
        "session_time": int(current_time - stats.start_time)
    })
    ensure_session_cookie(response, request, session_id, is_new)
    return response


@app.get("/state", response_class=JSONResponse)
async def state(request: Request):
    session_id, is_new = get_session_id(request)
    stats = user_stats[session_id]
    current_time = time.time()
    
    # Calculate CPS from history (based on last 60 seconds or session duration, whichever is smaller)
    stats.click_history = [t for t in stats.click_history if current_time - t <= 60]
    time_window = min(60, max(1, current_time - stats.start_time))
    cps = len(stats.click_history) / time_window if stats.click_history else 0
    
    response = JSONResponse({
        "score": stats.score,
        "best_score": stats.best_score,
        "cps": round(cps, 1),
        "session_time": int(current_time - stats.start_time)
    })
    ensure_session_cookie(response, request, session_id, is_new)
    return response


app.mount("/static", StaticFiles(directory="static"), name="static")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
