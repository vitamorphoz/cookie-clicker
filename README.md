# Cookie Clicker (FastAPI)

Игровая версия с анимированной печенькой, всплывающими +1, показом кликов/сек и лучшим результатом за сессию.

## Запуск локально (macOS/Linux/Win)
```bash
python3 -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload
# Открыть http://127.0.0.1:8000
```
