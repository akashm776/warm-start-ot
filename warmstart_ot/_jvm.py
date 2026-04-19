"""JVM lifecycle management for JPype."""

from __future__ import annotations

import os
from pathlib import Path

import jpype


_JAR_PATH = Path(__file__).resolve().parent.parent / "java" / "build" / "libs" / "warmstart-ot-0.1.0.jar"


def ensure_jvm() -> None:
    """Start the JVM on first call; no-op on subsequent calls.

    JPype requires exactly one `startJVM` per process. Raises if the jar
    is missing — build it with `javac ... && jar cf ...` (see README).
    """
    if jpype.isJVMStarted():
        return
    if not _JAR_PATH.exists():
        raise FileNotFoundError(
            f"Java jar not found at {_JAR_PATH}. Build it first:\n"
            "  javac -d java/build/classes java/src/main/java/optimaltransport/*.java\n"
            "  jar cf java/build/libs/warmstart-ot-0.1.0.jar -C java/build/classes ."
        )
    jvm_path = os.environ.get("JVM_PATH") or jpype.getDefaultJVMPath()
    jpype.startJVM(jvm_path, classpath=[str(_JAR_PATH)])
