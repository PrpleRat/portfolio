import { useEffect, useMemo, useRef, useState } from "react";
import { applyGesture, classifyGesture, smoothCursor } from "./engines";
import { useAppStore } from "./store";

const filterFromState = (e: ReturnType<typeof useAppStore.getState>["edit"]) =>
  `brightness(${1 + e.brightness + e.exposure}) contrast(${e.contrast}) saturate(${e.saturation}) hue-rotate(${e.temperature * 10}deg)`;

export default function App() {
  const fileRef = useRef<HTMLInputElement>(null);
  const [gestureOn, setGestureOn] = useState(true);
  const [demo, setDemo] = useState(false);
  const [cursor, setCursor] = useState({ x: 0.5, y: 0.5 });
  const prevRef = useRef<{ x: number; y: number; pinch: number } | null>(null);

  const { imageUrl, setImageUrl, edit, patchEdit, activeGesture, confidence, setGesture, reset, undo, redo } = useAppStore();

  useEffect(() => {
    if (!gestureOn) return;
    let raf = 0;
    const tick = () => {
      const f = classifyGesture(performance.now());
      setGesture(f.gesture, Math.max(0, Math.min(1, f.confidence)));
      const next = smoothCursor(cursor, { x: f.x, y: f.y });
      setCursor(next);
      if (prevRef.current) {
        patchEdit(applyGesture(f.gesture, edit, next.x - prevRef.current.x, next.y - prevRef.current.y, f.pinch - prevRef.current.pinch), false);
      }
      prevRef.current = { x: next.x, y: next.y, pinch: f.pinch };
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [cursor, edit, gestureOn, patchEdit, setGesture]);

  const filter = useMemo(() => filterFromState(edit), [edit]);

  return (
    <main className="min-h-screen bg-slate-950 p-4 text-slate-100">
      <div className="mx-auto max-w-[1400px] space-y-4">
        <header className="rounded-xl border border-slate-700 bg-slate-900/80 p-4">
          <h1 className="text-2xl font-bold">Gesture Photo Studio</h1>
          <p className="text-sm text-slate-300">Onboarding: webcam -> calibration -> 3 gestes -> mini test.</p>
          <div className="mt-3 flex flex-wrap gap-2">
            <button className="rounded bg-cyan-700 px-3 py-1 text-sm" onClick={() => fileRef.current?.click()}>
              Importer
            </button>
            <button className="rounded bg-slate-700 px-3 py-1 text-sm" onClick={() => setGestureOn((v) => !v)}>
              {gestureOn ? "Pause caméra" : "Reprendre caméra"}
            </button>
            <button className="rounded bg-indigo-700 px-3 py-1 text-sm" onClick={() => setDemo((v) => !v)}>
              {demo ? "Demo OFF" : "Demo ON"}
            </button>
            <button className="rounded bg-slate-700 px-3 py-1 text-sm" onClick={undo}>
              Undo
            </button>
            <button className="rounded bg-slate-700 px-3 py-1 text-sm" onClick={redo}>
              Redo
            </button>
            <button className="rounded bg-rose-700 px-3 py-1 text-sm" onClick={reset}>
              Reset
            </button>
          </div>
          <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={(e) => e.target.files?.[0] && setImageUrl(URL.createObjectURL(e.target.files[0]))} />
        </header>

        <div className="grid gap-4 xl:grid-cols-[320px_1fr]">
          <section className="space-y-4">
            <div className="rounded-xl border border-slate-700 bg-slate-900/80 p-3 text-sm">
              <p>Geste actif: {activeGesture}</p>
              <div className="mt-2 h-2 rounded bg-slate-700">
                <div className="h-full rounded bg-emerald-400" style={{ width: `${Math.round(confidence * 100)}%` }} />
              </div>
              <p className="mt-1 text-xs text-slate-300">Confiance: {Math.round(confidence * 100)}%</p>
              <p className="mt-2 text-xs text-slate-300">Curseur virtuel: ({cursor.x.toFixed(2)}, {cursor.y.toFixed(2)})</p>
            </div>
            <div className="rounded-xl border border-slate-700 bg-slate-900/80 p-3 text-xs">
              <h2 className="font-semibold text-cyan-300">Cheat sheet</h2>
              <ul className="mt-2 space-y-1 text-slate-200">
                <li>Index seul: curseur</li>
                <li>Dwell 700ms / air tap: clic</li>
                <li>Pouce+Index: zoom/pan</li>
                <li>Pouce+Majeur: rotation</li>
                <li>Pouce+Annulaire: colorimétrie</li>
                <li>Poing 1s: lock/unlock</li>
              </ul>
            </div>
            <div className="rounded-xl border border-slate-700 bg-slate-900/80 p-3">
              {(["brightness", "contrast", "saturation", "exposure", "temperature", "sharpness"] as const).map((k) => (
                <label key={k} className="mb-2 block text-xs">
                  <span className="mb-1 block capitalize">{k}</span>
                  <input
                    aria-label={k}
                    type="range"
                    min={k === "contrast" || k === "saturation" ? 0 : -1}
                    max={k === "contrast" || k === "saturation" ? 2.5 : 1}
                    step={0.01}
                    value={edit[k]}
                    onChange={(e) => patchEdit({ [k]: Number(e.target.value) })}
                    className="w-full"
                  />
                </label>
              ))}
            </div>
          </section>
          <section className="relative h-[620px] overflow-hidden rounded-xl border border-slate-700 bg-black">
            {imageUrl ? (
              <img
                src={imageUrl}
                alt="preview"
                className="h-full w-full object-contain"
                style={{
                  transform: `translate(${edit.panX}px,${edit.panY}px) scale(${edit.zoom}) rotate(${edit.rotation}deg)`,
                  filter
                }}
              />
            ) : (
              <div className="grid h-full place-items-center text-slate-500">Importe une image</div>
            )}
            <div className="absolute left-2 top-2 rounded bg-slate-900/80 px-2 py-1 text-xs">Mode: {demo ? "demo sans webcam" : "webcam"}</div>
          </section>
        </div>
      </div>
    </main>
  );
}
