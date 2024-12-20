# Use a lightweight Python base image
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Copy the model and API files
COPY model/model.pkl /app/model/model.pkl
COPY api/ /app/

# Install required dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose Flask API port
EXPOSE 5001

# Run the Flask API
CMD ["python", "app.py"]



