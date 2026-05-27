import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";
import { ProviderSetup } from "./ProviderSetup";

const mockApi = vi.hoisted(() => ({
  providers: {
    createM3u: vi.fn(),
    createXtream: vi.fn()
  }
}));

vi.mock("../../app/api", () => ({
  iptvApi: mockApi
}));

describe("ProviderSetup", () => {
  afterEach(() => {
    vi.clearAllMocks();
  });

  it("submits Xtream Codes login details when the Xtream source type is selected", async () => {
    const onCreated = vi.fn(async () => undefined);
    mockApi.providers.createXtream.mockResolvedValue({
      id: "provider-xtream",
      type: "xtream",
      name: "My IPTV",
      createdAt: "2026-05-26T08:00:00.000Z",
      updatedAt: "2026-05-26T08:00:00.000Z",
      lastRefreshAt: null,
    autoRefreshEnabled: true,
    autoRefreshIntervalHours: 24
    });

    render(<ProviderSetup onCreated={onCreated} />);

    fireEvent.change(screen.getByLabelText("Source type"), { target: { value: "xtream" } });
    fireEvent.change(screen.getByLabelText("Server URL"), { target: { value: " https://panel.example.test/ " } });
    fireEvent.change(screen.getByLabelText("Username"), { target: { value: " user " } });
    fireEvent.change(screen.getByLabelText("Password"), { target: { value: " pass " } });
    fireEvent.submit(screen.getByRole("button", { name: "Import provider" }).closest("form") as HTMLFormElement);

    await waitFor(() =>
      expect(mockApi.providers.createXtream).toHaveBeenCalledWith({
        name: "My IPTV",
        serverUrl: "https://panel.example.test/",
        username: "user",
        password: "pass"
      })
    );
    expect(mockApi.providers.createM3u).not.toHaveBeenCalled();
    expect(onCreated).toHaveBeenCalled();
  });

  it("shows provider import errors without the Electron IPC wrapper", async () => {
    mockApi.providers.createXtream.mockRejectedValue(
      new Error("Error invoking remote method 'providers:createXtream': Error: Xtream login failed")
    );

    render(<ProviderSetup onCreated={vi.fn()} />);

    fireEvent.change(screen.getByLabelText("Source type"), { target: { value: "xtream" } });
    fireEvent.change(screen.getByLabelText("Server URL"), { target: { value: "https://panel.example.test" } });
    fireEvent.change(screen.getByLabelText("Username"), { target: { value: "user" } });
    fireEvent.change(screen.getByLabelText("Password"), { target: { value: "pass" } });
    fireEvent.submit(screen.getByRole("button", { name: "Import provider" }).closest("form") as HTMLFormElement);

    expect((await screen.findByRole("alert")).textContent).toBe("Xtream login failed");
  });
});
