/**
 * GameOfLife Canvas Hook
 *
 * Renders the Game of Life grid on an HTML5 Canvas element.
 * Receives alive cell data from the server via push_event and
 * sends toggle_cell events back when the user clicks on cells.
 */
const GameOfLife = {
  mounted() {
    this.canvas = this.el;
    this.ctx = this.canvas.getContext("2d");
    this.rows = parseInt(this.el.dataset.rows);
    this.cols = parseInt(this.el.dataset.cols);
    this.aliveCells = [];

    this.resizeCanvas();
    this.draw();

    // Handle window resize
    this.resizeObserver = new ResizeObserver(() => {
      this.resizeCanvas();
      this.draw();
    });
    this.resizeObserver.observe(this.canvas.parentElement);

    // Handle click events for toggling cells
    this.canvas.addEventListener("click", (e) => {
      const rect = this.canvas.getBoundingClientRect();
      const scaleX = this.canvas.width / rect.width;
      const scaleY = this.canvas.height / rect.height;
      const x = (e.clientX - rect.left) * scaleX;
      const y = (e.clientY - rect.top) * scaleY;

      const cellSize = this.cellSize;
      const col = Math.floor(x / cellSize);
      const row = Math.floor(y / cellSize);

      if (row >= 0 && row < this.rows && col >= 0 && col < this.cols) {
        this.pushEvent("toggle_cell", { row: row, col: col });
      }
    });

    // Receive updates from the server
    this.handleEvent("game_update", (data) => {
      this.rows = data.rows;
      this.cols = data.cols;
      this.aliveCells = data.alive_cells;
      this.resizeCanvas();
      this.draw();
    });
  },

  destroyed() {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
    }
  },

  resizeCanvas() {
    const parent = this.canvas.parentElement;
    const maxWidth = parent.clientWidth;
    const maxHeight = window.innerHeight - 200;
    const maxDim = Math.min(maxWidth, maxHeight, 700);

    // Calculate cell size based on available space
    this.cellSize = Math.floor(maxDim / Math.max(this.rows, this.cols));
    this.cellSize = Math.max(this.cellSize, 3); // minimum 3px per cell

    this.canvas.width = this.cellSize * this.cols;
    this.canvas.height = this.cellSize * this.rows;
  },

  draw() {
    const ctx = this.ctx;
    const cellSize = this.cellSize;
    const w = this.canvas.width;
    const h = this.canvas.height;

    // Detect theme
    const theme = document.documentElement.getAttribute("data-theme");
    const isDark = theme === "dark" ||
      (!theme && window.matchMedia("(prefers-color-scheme: dark)").matches);

    const bgColor = isDark ? "#1a1a2e" : "#f8f9fa";
    const cellColor = isDark ? "#7c3aed" : "#4f46e5";
    const gridColor = isDark ? "rgba(255,255,255,0.06)" : "rgba(0,0,0,0.06)";

    // Clear
    ctx.fillStyle = bgColor;
    ctx.fillRect(0, 0, w, h);

    // Draw grid lines (only if cells are large enough)
    if (cellSize > 5) {
      ctx.strokeStyle = gridColor;
      ctx.lineWidth = 0.5;

      for (let r = 0; r <= this.rows; r++) {
        ctx.beginPath();
        ctx.moveTo(0, r * cellSize);
        ctx.lineTo(w, r * cellSize);
        ctx.stroke();
      }

      for (let c = 0; c <= this.cols; c++) {
        ctx.beginPath();
        ctx.moveTo(c * cellSize, 0);
        ctx.lineTo(c * cellSize, h);
        ctx.stroke();
      }
    }

    // Draw alive cells
    ctx.fillStyle = cellColor;
    const padding = cellSize > 8 ? 1 : 0;

    for (const [row, col] of this.aliveCells) {
      ctx.fillRect(
        col * cellSize + padding,
        row * cellSize + padding,
        cellSize - padding * 2,
        cellSize - padding * 2
      );
    }
  }
};

export default GameOfLife;
