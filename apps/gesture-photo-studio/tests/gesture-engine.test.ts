import { describe, expect, it } from "vitest";
import { applyGesture } from "../src/engines";

describe("gesture edit mapping", () => {
  it("zoom en pinch_nav", () => {
    const patch = applyGesture(
      "pinch_nav",
      { zoom: 1, rotation: 0, panX: 0, panY: 0, brightness: 0, contrast: 1, saturation: 1, exposure: 0, temperature: 0, sharpness: 0 },
      0,
      0,
      0.3
    );
    expect((patch.zoom ?? 1) > 1).toBe(true);
  });
});
