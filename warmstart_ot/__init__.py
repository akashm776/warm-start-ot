"""Warm-start algorithms for additive-approximate optimal transport and bipartite matching."""

from .solver import SolveResult, WarmStartResult, solve_lmr, solve_warmstart

__version__ = "0.1.0"
__all__ = ["SolveResult", "WarmStartResult", "solve_lmr", "solve_warmstart"]
