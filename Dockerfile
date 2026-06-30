FROM python:3.11-slim

WORKDIR /app

# Install dbt-snowflake
RUN pip install --no-cache-dir dbt-snowflake

# Copy the dbt project into the image
COPY . .

# Install dbt packages (e.g. dbt_utils)
RUN dbt deps

# Default command: run dbt models when the container starts
CMD ["dbt", "run"]