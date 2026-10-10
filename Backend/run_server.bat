@echo off
echo Starting Solar Rooftop Management Backend API...
cd /d "%~dp0"
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
pause
