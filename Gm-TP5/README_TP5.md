# TP5: Subdivision Implementations

## Overview
This project implements two fundamental subdivision algorithms from geometric modeling:

1. **Chaikin's Algorithm** - Curve subdivision
2. **Loop Subdivision** - Surface subdivision for triangle meshes

## Implementation Details

### Exercise 1: Chaikin's Algorithm (`ChaikinCurve.swift`)

Chaikin's corner-cutting algorithm smooths a polyline by iteratively replacing each edge with two new edges.

**Algorithm:**
- For each edge between points P₀ and P₁:
  - Create point Q at 3/4 from P₀ toward P₁ (or 1/4 from P₁)
  - Create point R at 1/4 from P₀ toward P₁ (or 3/4 from P₁)
  - Replace the edge with Q and R

**Implementation highlights:**
- Uses simple 2D/3D points for visualization
- Renders curve as connected line segments
- Shows control points as small red spheres
- Each iteration doubles the number of points
- Converges to a smooth B-Spline curve

**Usage:**
- Use the stepper to control subdivision iterations (0-8)
- Wire toggle affects the underlying visualization

### Exercise 2: Loop Subdivision (`LoopSubdivision.swift`)

Loop subdivision is a surface subdivision scheme for triangle meshes that produces smooth surfaces.

**Algorithm:**
1. **Compute odd vertices** (updated positions of existing vertices):
   - Use weighted average with neighbors
   - Weight formula: β = (1/n) × (5/8 - (3/8 + 1/4×cos(2π/n))²)
   - Special case for n=3: β = 3/16

2. **Compute even vertices** (new edge midpoints):
   - Interior edges: 3/8(p₀ + p₁) + 1/8(opposite₀ + opposite₁)
   - Boundary edges: simple midpoint (p₀ + p₁)/2

3. **Create new triangles**:
   - Each original triangle becomes 4 new triangles
   - 3 corner triangles + 1 center triangle

**Implementation highlights:**
- Builds adjacency information for efficient computation
- Handles both interior and boundary edges correctly
- Starts with a simple tetrahedron for demonstration
- Automatically computes smooth normals after subdivision
- Each iteration quadruples the number of triangles

**Data structures:**
- `Edge` struct: Order-independent edge representation
- Hash maps for efficient edge lookup
- Adjacency lists for vertex neighbors

## UI Controls

- **Segmented Picker**: Switch between Chaikin and Loop algorithms
- **Iterations Stepper**: Control subdivision depth (0-8 iterations)
- **Wire Toggle**: Show/hide wireframe overlay

## Technical Notes

### Mesh Structure
The existing `Mesh` class provides:
- Vertex and index storage
- Normal computation
- SceneKit node creation
- OFF file loading (can be used with Loop subdivision)

### Renderer
- Uses SceneKit for 3D visualization
- Custom camera controls (orbit, pan, zoom)
- Wireframe overlay support
- Constant shading for clear geometry visualization

## Extending the Implementation

### Loading custom meshes for Loop subdivision
Replace the tetrahedron in `LoopSubdivision()` with:

```swift
let mesh = Mesh()
try! mesh.load(named: "yourmodel", withExtension: "off")
mesh.center()
mesh.normalize()
```

### Adding colors for better visualization
To add random colors per triangle (as mentioned in instructions), modify the `makeNode()` function in `Mesh.swift` to assign random colors to each triangle face.

### Closed vs Open curves for Chaikin
Currently Chaikin uses an open curve. To make it closed, connect the last point back to the first:

```swift
// In chaikinSubdivide, add after the main loop:
if points.count > 2 {
    let p0 = points[points.count - 1]
    let p1 = points[0]
    let q = p0 * 0.75 + p1 * 0.25
    let r = p0 * 0.25 + p1 * 0.75
    newPoints.append(q)
    newPoints.append(r)
}
```

## Performance Considerations

- **Chaikin**: O(n) per iteration, n points → 2n points
- **Loop**: O(n) per iteration, n triangles → 4n triangles
- Memory grows exponentially with iterations
- Practical limit: 6-8 iterations for most meshes

## References

- Chaikin, G. (1974). "An algorithm for high-speed curve generation"
- Loop, C. (1987). "Smooth Subdivision Surfaces Based on Triangles"
- [B-Spline properties of Chaikin's algorithm](https://www.cs.unc.edu/~dm/UNC/COMP258/LECTURES/Chaikin.pdf)
