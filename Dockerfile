# 1. Use an official Python runtime as a parent image
FROM python:3.11-slim

# 2. Set the working directory in the container
WORKDIR /app

# 3. Copy the requirements file into the container
COPY requirements.txt .

# 4. Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# 5. Copy the rest of your application code
COPY /app.py .

# 6. Expose port 5000 for the Flask app
EXPOSE 5000

# 7. Use Gunicorn for production instead of 'python app.py'
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]