# ============================================================
# OMP
# ============================================================

# Keep OMP agent state out of $HOME without relying on internal variables.
export PI_CODING_AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.local/share/omp/agent}"
