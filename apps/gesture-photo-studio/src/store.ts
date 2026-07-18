import { create } from "zustand";
import type { EditState, GestureName } from "./types";

const baseEdit: EditState = {
  zoom: 1,
  rotation: 0,
  panX: 0,
  panY: 0,
  brightness: 0,
  contrast: 1,
  saturation: 1,
  exposure: 0,
  temperature: 0,
  sharpness: 0
};

interface AppState {
  imageUrl: string | null;
  activeGesture: GestureName;
  confidence: number;
  edit: EditState;
  history: EditState[];
  future: EditState[];
  setImageUrl: (url: string | null) => void;
  setGesture: (g: GestureName, c: number) => void;
  patchEdit: (patch: Partial<EditState>, push?: boolean) => void;
  undo: () => void;
  redo: () => void;
  reset: () => void;
}

export const useAppStore = create<AppState>((set, get) => ({
  imageUrl: null,
  activeGesture: "none",
  confidence: 0,
  edit: { ...baseEdit },
  history: [],
  future: [],
  setImageUrl: (url) => set({ imageUrl: url }),
  setGesture: (g, c) => set({ activeGesture: g, confidence: c }),
  patchEdit: (patch, push = true) =>
    set((s) => ({
      edit: { ...s.edit, ...patch },
      history: push ? [...s.history, s.edit].slice(-30) : s.history,
      future: push ? [] : s.future
    })),
  undo: () =>
    set((s) => {
      if (!s.history.length) return s;
      const prev = s.history[s.history.length - 1];
      return { edit: prev, history: s.history.slice(0, -1), future: [s.edit, ...s.future].slice(0, 30) };
    }),
  redo: () =>
    set((s) => {
      if (!s.future.length) return s;
      const [n, ...rest] = s.future;
      return { edit: n, history: [...s.history, s.edit].slice(-30), future: rest };
    }),
  reset: () => get().patchEdit(baseEdit)
}));
