ARG PYTHON_VERSION=3.13

FROM python:${PYTHON_VERSION}-alpine

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

CMD ["python", "app.py"]