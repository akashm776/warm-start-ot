# Warm-Start Algorithms for Bipartite Matching and Optimal Transport

Reference implementation of the warm-start scaling algorithm from:

> **Warm Start Algorithms for Bipartite Matching and Optimal Transport.**
> Akash Mittal. M.S. Thesis, Virginia Tech, December 2024.

The warm-start algorithm wraps the LMR additive-approximate OT solver of
[Lahn, Mulchandani, and Raghvendra (NeurIPS 2019)][lmr-paper]: dual weights
from a coarse solve are reused to initialize a finer solve, cutting the
iteration count at small additive error δ.

## Status

Early scaffolding. Core algorithm (Java) is lifted from the thesis; Python
bindings and reproducible experiments are in progress.

| Piece | State |
|---|---|
| Algorithm 1 core — `Mapping`, `ScaledMapping` (Java) | ✅ ported from thesis |
| Gradle build for jar | ✅ untested |
| Python wrapper (JPype) | ⏳ not written |
| Unit-square synthetic driver (Fig 3.1, 3.2) | ⏳ not written |
| Algorithm 2 (learning-augmented, thesis §4.2) | ⏳ not written |

## Layout

```
java/src/main/java/optimaltransport/   # LMR solver + warm-start variant
warmstart_ot/                          # Python package (JPype wrapper)
warmstart_ot/experiments/              # figure-reproducing scripts
legacy-matlab/                         # original MATLAB experiment driver
figures/                               # output
tests/
```

## Build (planned)

```bash
# Build the Java jar
./gradlew jar

# Install Python package
uv sync
# or: pip install -e .

# Reproduce figures
python -m warmstart_ot.experiments.unit_square
```

## Attribution

The base LMR solver (`Mapping.java`, `GTTransport.java`) is joint work with
the authors of the 2019 NeurIPS paper; see [the original repository][lmr-code]
for that code's history. The warm-start extensions (`ScaledMapping.java`,
`ScaledGTTransport.java`) and the thesis contributions are the work of this
thesis's author.

[lmr-paper]: https://arxiv.org/abs/1905.11830
[lmr-code]: https://github.com/nathaniellahn/CombinatorialOptimalTransport

## License

MIT — see [LICENSE](LICENSE).
