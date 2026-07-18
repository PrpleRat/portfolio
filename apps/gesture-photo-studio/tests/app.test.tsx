import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import App from "../src/App";

describe("app", () => {
  it("shows title", () => {
    render(<App />);
    expect(screen.getByText("Gesture Photo Studio")).toBeInTheDocument();
  });
});
