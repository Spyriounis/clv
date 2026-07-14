# clv — A Deep Probabilistic Model for Customer Lifetime Value Prediction

Implementation of the model described in:

> Xiaojing Wang, Tianqi Liu, Jingang Miao (Google), **"A Deep Probabilistic Model for Customer
> Lifetime Value Prediction"**, 2019. [arXiv:1912.07753](https://arxiv.org/abs/1912.07753)

> **Status:** project scaffold. The environment, tooling, Docker image, and CI are in place; the
> model itself is not implemented yet (see `src/clv/model.py`).

## Summary

Customer Lifetime Value (LTV/CLV) is the total future spend of a customer over a fixed horizon
(typically 1–3 years). Predicting the LTV of **new** customers is hard for two reasons:

1. **Many zeros** — a large fraction of customers are one-time purchasers with zero future value.
2. **Heavy tail** — among returning customers, LTV is highly skewed; a few high spenders dominate.

Standard Mean Squared Error (MSE) regression handles neither well: it averages over the zero and
positive regimes and is very sensitive to outliers, causing unstable training.

The paper proposes a **Zero-Inflated LogNormal (ZILN)** loss — the negative log-likelihood of a
mixture of a zero point-mass and a lognormal distribution. A single DNN with this loss jointly
learns the **churn probability** and the **monetary value** of returning customers, replacing the
usual two-stage (classify-then-regress) pipeline, and yields a full predictive distribution for
uncertainty quantification.

## Network architecture

Following Figure 3 of the paper, input features flow through shared hidden layers into a final
layer of **three logits**, each with its own activation:

| Output  | Meaning                                             | Activation |
| ------- | --------------------------------------------------- | ---------- |
| `p`     | probability of being a returning (nonzero) customer | sigmoid    |
| `mu`    | lognormal mean parameter                            | identity   |
| `sigma` | lognormal standard-deviation parameter              | softplus   |

The shared middle layers act as a multi-task representation across the classification (returning
vs. non-returning) and regression (returning-customer spend) tasks.

### ZILN loss

```
L_ZILN(x; p, mu, sigma) = BCE(1{x > 0}; p) + 1{x > 0} * L_Lognormal(x; mu, sigma)

L_Lognormal(x; mu, sigma) = log(x * sigma * sqrt(2*pi)) + (log(x) - mu)^2 / (2 * sigma^2)
```

The expected-LTV point prediction combines both heads:

```
E[X] = p * exp(mu + sigma^2 / 2)
```

### Reference hyperparameters (Kaggle Acquire Valued Shoppers experiment)

- DNN with 2 hidden layers (64 and 32 units); categorical features via embeddings.
- Adam optimizer, learning rate `2e-4`, batch size `1024`, up to `400` epochs with early stopping.

## Evaluation metrics

- **Normalized Gini coefficient** — model discrimination (ability to rank high-value customers).
- **Decile chart + decile-level MAPE** — model calibration.
- **AUC / AUC-PR** — returning-customer (binary) classification.
- **Spearman correlation** — rank agreement between true and predicted LTV.

## Getting started

This project uses the [uv](https://docs.astral.sh/uv/) package manager (Python 3.12).

```bash
# Install dependencies (creates .venv from uv.lock)
uv sync

# Run the test suite
uv run pytest

# Lint and format-check
uv run ruff check .
uv run ruff format --check .

# Enable pre-commit hooks (runs ruff on every commit)
uv run pre-commit install
```

## Docker

The repository is containerised so it can run remotely (e.g. on GitHub-hosted runners):

```bash
docker build -t clv:latest .

# Run tests / linting inside the container (what CI does)
docker run --rm clv:latest uv run pytest
docker run --rm clv:latest uv run ruff check .
```

## Continuous integration

GitHub Actions build the Docker image and then run linting and tests **inside** it. Composite
actions live in `.github/actions/` (`docker_build`, `check_code_style`, `run_unit_tests`) and are
combined by the workflows in `.github/workflows/` (`build_and_check_code_style.yaml`,
`build_and_run_unit_tests.yaml`), which run on every push to a non-`main` branch.

## Project layout

```
clv/
├── pyproject.toml            # project metadata, dependencies, ruff config
├── uv.lock                   # pinned, reproducible dependency set
├── .python-version           # 3.12
├── Dockerfile                # uv-based image (python:3.12-slim)
├── .pre-commit-config.yaml
├── src/clv/                  # package source (model lives here)
├── tests/                    # unit tests
└── .github/                  # composite actions + workflows
```
