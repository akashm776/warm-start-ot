"""High-level Python wrappers around the Java LMR / warm-start solvers."""

from __future__ import annotations

from dataclasses import dataclass

import jpype
import numpy as np

from ._jvm import ensure_jvm


@dataclass
class SolveResult:
    """Output of a single solve."""

    flow: np.ndarray
    total_cost: float
    iterations: int
    time_ms: float
    ap_lengths: int


@dataclass
class WarmStartResult(SolveResult):
    """Output of a warm-start schedule: aggregates across all scales."""

    num_scales: int


def _to_java_1d(x: np.ndarray) -> jpype.JArray:
    return jpype.JArray(jpype.JDouble)(np.ascontiguousarray(x, dtype=np.float64).tolist())


def _to_java_2d(M: np.ndarray) -> jpype.JArray:
    return jpype.JArray(jpype.JDouble, 2)(np.ascontiguousarray(M, dtype=np.float64).tolist())


def _from_java_2d(J) -> np.ndarray:
    return np.asarray(J, dtype=np.float64)


def solve_lmr(a: np.ndarray, b: np.ndarray, C: np.ndarray, delta: float) -> SolveResult:
    """Baseline LMR solve — a single call to `Mapping` at additive error δ.

    Args:
        a: length-n distribution (sums to 1).
        b: length-n distribution (sums to 1).
        C: n×n cost matrix.
        delta: target additive error.
    """
    ensure_jvm()
    Mapping = jpype.JClass("optimaltransport.Mapping")

    n = len(a)
    solver = Mapping(n, _to_java_1d(a), _to_java_1d(b), _to_java_2d(C), float(delta))
    return SolveResult(
        flow=_from_java_2d(solver.getFlow()),
        total_cost=float(solver.getTotalCost()),
        iterations=int(solver.getIterations()),
        time_ms=float(solver.getTimeTaken()),
        ap_lengths=int(solver.getAPLengths()),
    )


def solve_warmstart(
    a: np.ndarray,
    b: np.ndarray,
    C: np.ndarray,
    delta: float,
    *,
    start_delta: float = 1.0,
) -> WarmStartResult:
    """Warm-start schedule — cold-start at `start_delta`, halve down to `delta`.

    Reuses dual weights across scales (thesis Ch 3.2, Algorithm 1). The final
    scale is flagged so the solver can do post-processing.

    Returns totals across all scales; flow and cost are from the final scale.
    """
    ensure_jvm()
    ScaledMapping = jpype.JClass("optimaltransport.ScaledMapping")

    n = len(a)
    a_j, b_j, C_j = _to_java_1d(a), _to_java_1d(b), _to_java_2d(C)

    # Cold start at start_delta.
    solver = ScaledMapping(n, a_j, b_j, C_j, float(start_delta))
    duals = solver.getDuals()
    total_time = float(solver.getTimeTaken())
    total_iters = int(solver.getIterations())
    total_ap = int(solver.getAPLengths())
    num_scales = 1

    current = start_delta / 2
    while current > delta:
        solver = ScaledMapping(n, a_j, b_j, C_j, float(current), duals, False)
        duals = solver.getDuals()
        total_time += float(solver.getTimeTaken())
        total_iters += int(solver.getIterations())
        total_ap += int(solver.getAPLengths())
        num_scales += 1
        current /= 2

    # Final scale — flag finalScale=True for any cleanup the solver does.
    solver = ScaledMapping(n, a_j, b_j, C_j, float(current), duals, True)
    total_time += float(solver.getTimeTaken())
    total_iters += int(solver.getIterations())
    total_ap += int(solver.getAPLengths())
    num_scales += 1

    return WarmStartResult(
        flow=_from_java_2d(solver.getFlow()),
        total_cost=float(solver.getTotalCost()),
        iterations=total_iters,
        time_ms=total_time,
        ap_lengths=total_ap,
        num_scales=num_scales,
    )
