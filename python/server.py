from __future__ import annotations

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from analysis import analyze_pdf


class AnalyzeRequest(BaseModel):
    fields: dict


app = FastAPI(title="Lab Analyzer", version="0.1.0")


@app.post("/analyze")
def analyze(req: AnalyzeRequest):
    try:
        result = analyze_pdf(req.fields)
        return result
    except Exception as exc:
        raise HTTPException(status_code=400, detail=str(exc))



