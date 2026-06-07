# Contributing to LLM Tracker

Thank you for your interest in contributing to the LLM Tracker project! This document provides guidelines for contributing.

## 🤝 Code of Conduct

Be respectful, inclusive, and professional in all interactions.

## 🐛 Reporting Issues

Before creating an issue, please:
1. Check existing issues to avoid duplicates
2. Use a clear, descriptive title
3. Provide detailed steps to reproduce
4. Include relevant logs or error messages
5. Specify your environment (OS, Python version, Docker version)

### Issue Template

```
## Description
Brief description of the issue.

## Steps to Reproduce
1. Step 1
2. Step 2
3. ...

## Expected Behavior
What should happen?

## Actual Behavior
What actually happens?

## Environment
- OS: [e.g., Ubuntu 20.04, Windows 11]
- Python: [e.g., 3.11]
- Docker: [e.g., 24.0.0]

## Logs
```
Relevant error logs here
```
```

## 🚀 Creating Pull Requests

### Before You Start

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make sure your environment is set up: `./setup.sh`

### Development Workflow

1. **Make Changes**
   - Follow the project's coding style
   - Keep commits atomic and focused
   - Write descriptive commit messages

2. **Test Your Changes**
   ```bash
   cd llm_tracker
   # Run tests
   docker-compose exec -T airflow-webserver python -m pytest tests/
   
   # Validate Python code
   python -m py_compile ingestion/*.py indexing/*.py dags/*.py
   
   # Run DBT tests
   docker-compose exec -T airflow-webserver bash -c "cd /opt/airflow/dbt_project && dbt test"
   ```

3. **Verify Formatting**
   - No trailing whitespace
   - Consistent indentation
   - Clear variable names

4. **Update Documentation**
   - Update README.md if behavior changes
   - Add docstrings to new functions
   - Include examples for new features

### Commit Message Guidelines

Follow conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (no functional changes)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build, dependency, or tooling changes

**Examples:**
```
feat(ingestion): add support for Claude models

fix(elasticsearch): handle index creation timeout

docs(setup): clarify prerequisites

refactor(pipeline): simplify date parsing logic
```

### Pull Request Template

```markdown
## Description
Describe your changes and why they're needed.

## Related Issues
Closes #123

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe how you tested your changes.

## Checklist
- [ ] Code follows project style guidelines
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] No new warnings generated
- [ ] Verified locally
```

## 📝 Coding Standards

### Python

- Follow PEP 8
- Use type hints for function parameters and returns
- Add docstrings to all public functions

Example:
```python
def calculate_value_score(performance: float, cost: float) -> float:
    """
    Calculate the value score (performance-to-cost ratio).
    
    Args:
        performance: Performance score (0-100)
        cost: Cost per 1M tokens (USD)
        
    Returns:
        Value score as float
        
    Raises:
        ValueError: If cost is zero or negative
    """
    if cost <= 0:
        raise ValueError("Cost must be positive")
    return (performance / 100) / cost
```

### SQL (dbt)

- Use lowercase for SQL keywords
- Use meaningful alias names
- Add comments for complex logic
- Follow consistent indentation

Example:
```sql
select
    model_id,
    model_name,
    provider,
    performance_score,
    avg_price_per_1m_usd as cost,
    (performance_score / 100) / (avg_price_per_1m_usd / 100) as value_score,
    ingestion_date
from {{ ref('openrouter_formatted') }}
where ingestion_date = '{{ var("run_date") }}'
```

### YAML

- Use 2-space indentation
- Keep lines under 80 characters
- Organize keys alphabetically

## 🧪 Testing Requirements

- Add tests for new functionality
- Ensure all tests pass: `docker-compose exec -T airflow-webserver python -m pytest`
- Maintain or improve test coverage
- Test edge cases and error conditions

## 📚 Documentation

- Update README.md for user-facing changes
- Add docstrings to all public functions
- Include examples for new features
- Update troubleshooting section if applicable

## 🔒 Security

- Never commit credentials or secrets
- Use environment variables for sensitive data
- Follow OWASP guidelines
- Report security issues privately (don't open public issues)

## ✅ Review Process

1. All PRs require at least one approval
2. Code review focuses on:
   - Functionality and correctness
   - Code quality and style
   - Performance implications
   - Security considerations
   - Documentation completeness

3. Address review comments and re-request review
4. PR is merged once approved and all checks pass

## 📦 Release Process

1. Version follows [Semantic Versioning](https://semver.org/)
2. Update CHANGELOG.md
3. Tag release: `git tag v1.0.0`
4. Create GitHub release with notes

## 🎓 Areas for Contribution

### High Priority
- [ ] Support for additional LLM providers
- [ ] Performance optimizations
- [ ] Comprehensive test suite
- [ ] Documentation improvements

### Medium Priority
- [ ] Real-time data ingestion
- [ ] Advanced analytics features
- [ ] UI improvements
- [ ] Docker optimization

### Low Priority
- [ ] Code style improvements
- [ ] Minor documentation updates
- [ ] Example notebooks
- [ ] Community tools

## ❓ Questions?

- Check existing GitHub issues and discussions
- Review project documentation
- Ask in PR comments
- Start a GitHub discussion

## 📜 License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to make LLM Tracker better! 🙏
