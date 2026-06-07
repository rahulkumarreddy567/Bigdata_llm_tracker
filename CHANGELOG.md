# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-06-07

### Added
- Initial public release of LLM Cost vs Performance Tracker
- Airflow-based data pipeline for LLM pricing and performance data
- Integration with OpenRouter and LMSYS data sources
- DBT models for data transformation and quality
- Elasticsearch indexing and Kibana visualization
- Comprehensive documentation and setup guides
- Docker-based deployment with docker-compose
- Automated setup and verification scripts

### Security
- Updated requests to >=2.33.0 to fix temp directory vulnerability
- Updated pyarrow to >=18.0.0 to fix use-after-free vulnerability
- Implemented secure environment variable handling
- Added .gitignore for sensitive files
- Added security best practices documentation

### Documentation
- Comprehensive README with architecture overview
- CONTRIBUTING.md with code standards and guidelines
- .env.example for environment configuration
- GITHUB_READY.md for repository setup guidance
- Setup and verification automation scripts

### Infrastructure
- Apache Airflow 2.8.1 for workflow orchestration
- PostgreSQL 15 for metadata storage
- Elasticsearch 8.12.0 for data indexing
- Kibana 8.12.0 for visualization
- DuckDB for data transformation
- dbt for SQL-based transformations

## Future Releases

### [Planned] v1.1.0
- Real-time data ingestion support
- Additional LLM provider integrations
- Advanced analytics and forecasting
- Custom alert thresholds

### [Planned] v1.2.0
- Web UI for configuration management
- Cost optimization recommendations
- Automated report generation
- API endpoints for data access

---

**Release Maintainer**: Rahul Duggempudi
**License**: MIT
