**Key Learnings: Houdini to Bevy Pipeline Architecture**

**1. The Pitfall of Asset Self-Containment (Morph Targets)**
* **Initial Assumption:** Baking the recoil animation directly into the `.glb` file using Morph Targets (`SopBlendshapes`) seemed like the most "self-contained" and elegant design.
* **The Reality:** In a procedural pipeline, this approach is extremely brittle. Operations like `SopMerge` or normal calculations (which split vertices for hard edges) alter the vertex count and IDs. glTF morph targets require strict 1:1 vertex matching between the base and target meshes, causing the export to fail or bake into a static mesh when the topology is disrupted.

**2. Procedural Hierarchy over Flat Meshes**
* To interact with specific parts of a model in a game engine, the asset must be exported as a structured Scene Graph, not a single flattened mesh.
* **The Solution:** Using `SopPack` combined with a primitive string attribute (`s@name = "barrel";`) in Houdini forces the glTF exporter to treat the packed geometry as an independent, named `Node` within the file's hierarchy.

**3. Decoupling Responsibilities (Houdini vs. Bevy)**
* **Houdini's Role:** Define the structural contract (geometry, materials, and named hierarchy).
* **Bevy's Role:** Handle the logic and behavior (procedural animation).
* Instead of relying on fragile animation clips or morph weights, traversing Bevy's ECS to find the `Name` component (e.g., "barrel") and procedurally manipulating its `Transform` component is highly robust. It allows for rapid iteration, such as adjusting easing functions or recoil duration directly in code without needing to re-export assets.

**4. Rigid vs. Organic Animation Paradigms**
* **Morph Targets** are vertex-shader heavy and designed for organic, non-linear deformations (e.g., facial expressions).
* For mechanical, rigid-body movements like a turret's recoil or yaw rotation, manipulating a 4x4 Transform matrix (or using Skeletal/Bone animation for complex rigs) is the computationally correct and industry-standard approach.