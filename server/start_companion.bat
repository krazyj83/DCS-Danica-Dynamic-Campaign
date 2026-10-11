@echo off
rem Danica Dynamic Campaign companion: web map on http://localhost:8088/ and Discord feed.
rem Copy dcc_companion.example.json to dcc_companion.json and fill in your folder and webhook first.
cd /d "%~dp0"
python dcc_companion.py
pause
