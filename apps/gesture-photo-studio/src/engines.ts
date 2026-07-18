import type { EditState, GestureName } from "./types";

export const classifyGesture = (t: number): { gesture: GestureName; confidence: number; x: number; y: number; pinch: number } => {
  const x = (Math.sin(t / 700) + 1) / 2;
  const y = (Math.cos(t / 800) + 1) / 2;
  const cycle = Math.floor(t / 2500) % 4;
  const gesture: GestureName = cycle === 0 ? "cursor" : cycle === 1 ? "pinch_nav" : cycle === 2 ? "pinch_rotate" : "pinch_color";
  const confidence = 0.75 + 0.2 * Math.sin(t / 500);
  return { gesture, confidence, x, y, pinch: 0.05 + 0.02 * Math.sin(t / 400) };
};

export const smoothCursor = (prev: { x: number; y: number }, next: { x: number; y: number }) => ({
  x: prev.x + 0.25 * (next.x - prev.x),
  y: prev.y + 0.25 * (next.y - prev.y)
});

const clamp = (v: number, min: number, max: number): number => Math.min(max, Math.max(min, v));

export const applyGesture = (
  gesture: GestureName,
  edit: EditState,
  dx: number,
  dy: number,
  dp: number
): Partial<EditState> => {
  if (gesture === "pinch_nav") return { zoom: clamp(edit.zoom + dp * 0.025, 0.2, 8), panX: edit.panX + dx * 900, panY: edit.panY + dy * 900 };
  if (gesture === "pinch_rotate") return { rotation: edit.rotation + dx * 180 };
  if (gesture === "pinch_color") return { brightness: clamp(edit.brightness - dy * 1.4, -1, 1), contrast: clamp(edit.contrast + dx * 0.9, 0.2, 2.5) };
  return {};
};
