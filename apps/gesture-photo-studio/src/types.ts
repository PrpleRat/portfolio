export type GestureName = "cursor" | "pinch_nav" | "pinch_rotate" | "pinch_color" | "open_palm" | "none";

export interface EditState {
  zoom: number;
  rotation: number;
  panX: number;
  panY: number;
  brightness: number;
  contrast: number;
  saturation: number;
  exposure: number;
  temperature: number;
  sharpness: number;
}
