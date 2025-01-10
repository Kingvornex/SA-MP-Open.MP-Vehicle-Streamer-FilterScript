import numpy as np

# Define constants and configuration
GRID_SIZE = 100  # Example size
ITERATIONS = 100  # Number of iterations
DEBUG = False  # Enable debug logging

# Initialize grid
np.random.seed(42)  # For reproducibility
grid = np.random.randint(0, 2, (GRID_SIZE, GRID_SIZE), dtype=np.uint8)

def debug_log(message):
    if DEBUG:
        print(message)

def count_neighbors(grid):
    """Count neighbors using convolution for better performance."""
    kernel = np.array([[1, 1, 1], [1, 0, 1], [1, 1, 1]], dtype=np.uint8)
    return np.convolve(grid, kernel, mode="same")

def update_grid(grid):
    """Update grid based on neighbor count using vectorized operations."""
    neighbor_count = count_neighbors(grid)
    return (neighbor_count == 3) | ((grid == 1) & (neighbor_count == 2))

def main():
    global grid
    for iteration in range(ITERATIONS):
        if DEBUG:
            debug_log(f"Iteration {iteration}")
        grid = update_grid(grid)

if __name__ == "__main__":
    main()
