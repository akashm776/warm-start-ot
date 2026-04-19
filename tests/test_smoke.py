"""End-to-end smoke tests: Python → JPype → Java → result."""

from __future__ import annotations

import numpy as np
import pytest

from warmstart_ot import solve_lmr, solve_warmstart


def _unit_square_problem(n: int, seed: int = 0) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Thesis §3.3.1 setup: n points in [0,1]², Euclidean cost normalized to 1."""
    rng = np.random.default_rng(seed)
    A = rng.random((n, 2))
    B = rng.random((n, 2))
    C = np.linalg.norm(A[:, None, :] - B[None, :, :], axis=-1)
    C = C / C.max()
    mass = np.full(n, 1.0 / n)
    return mass, mass, C


def _assert_valid_transport(flow: np.ndarray, a: np.ndarray, b: np.ndarray, atol: float = 1e-6):
    assert flow.shape == (len(a), len(b))
    assert (flow >= -atol).all(), "negative flow entries"
    np.testing.assert_allclose(flow.sum(axis=1), a, atol=atol, err_msg="row sums ≠ a")
    np.testing.assert_allclose(flow.sum(axis=0), b, atol=atol, err_msg="col sums ≠ b")


def test_lmr_tiny():
    a, b, C = _unit_square_problem(n=8, seed=42)
    result = solve_lmr(a, b, C, delta=1e-3)
    _assert_valid_transport(result.flow, a, b)
    assert result.total_cost >= 0
    assert result.iterations >= 1


def test_warmstart_tiny():
    a, b, C = _unit_square_problem(n=8, seed=42)
    result = solve_warmstart(a, b, C, delta=1e-3)
    _assert_valid_transport(result.flow, a, b)
    assert result.num_scales >= 2


def test_warmstart_matches_lmr_cost():
    """Both solvers target the same δ — costs should be within 2δ of each other."""
    a, b, C = _unit_square_problem(n=8, seed=42)
    delta = 1e-3
    lmr = solve_lmr(a, b, C, delta=delta)
    ws = solve_warmstart(a, b, C, delta=delta)
    assert abs(lmr.total_cost - ws.total_cost) < 2 * delta, (
        f"costs diverge beyond 2δ: LMR={lmr.total_cost}, warm-start={ws.total_cost}"
    )
