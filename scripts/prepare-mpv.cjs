#!/usr/bin/env node

const { execFileSync } = require("node:child_process");
const { createHash } = require("node:crypto");
const fs = require("node:fs/promises");
const os = require("node:os");
const path = require("node:path");
const { path7za } = require("7zip-bin");

const projectRoot = path.resolve(__dirname, "..");
const vendorRoot = path.join(projectRoot, "vendor", "mpv");
const userAgent = "iptv-player-build-script";

const macAssets = {
  arm64: {
    name: "mpv-arm64-0.40.0.tar.gz",
    url: "https://laboratory.stolendata.net/~djinn/mpv_osx/mpv-arm64-0.40.0.tar.gz",
    sha256: "3170fb709defebaba33e9755297d70dc3562220541de54fc3d494a8309ef1260"
  },
  x64: {
    name: "mpv-0.39.0.tar.gz",
    url: "https://laboratory.stolendata.net/~djinn/mpv_osx/mpv-0.39.0.tar.gz",
    sha256: "35ec81ad86a97b24956a8d0f4fa1ba2690b44ae7741c920e923620bcd7bd402a"
  }
};

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const platform = options.platform ?? process.platform;
  const arch = options.arch ?? process.arch;

  if (platform === "darwin") {
    await prepareDarwinMpv(arch);
    return;
  }

  if (platform === "win32") {
    await prepareWindowsMpv(arch);
    return;
  }

  throw new Error(`Unsupported mpv bundle platform: ${platform}`);
}

function parseArgs(args) {
  const options = {};
  for (const arg of args) {
    const [name, value] = arg.split("=");
    if (name === "--platform" && value) {
      options.platform = value;
    }
    if (name === "--arch" && value) {
      options.arch = value;
    }
  }
  return options;
}

async function prepareDarwinMpv(arch) {
  const asset = macAssets[arch];
  if (!asset) {
    throw new Error(`Unsupported macOS mpv architecture: ${arch}. Expected arm64 or x64.`);
  }

  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "iptv-player-mpv-darwin-"));
  try {
    const archivePath = path.join(tempDir, asset.name);
    await downloadFile(asset.url, archivePath);
    await verifySha256(archivePath, asset.sha256);
    execFileSync("tar", ["-xzf", archivePath, "-C", tempDir], { stdio: "inherit" });

    const appPath = await findPath(tempDir, "mpv.app");
    if (!appPath) {
      throw new Error("Downloaded macOS mpv archive did not contain mpv.app");
    }

    const destination = path.join(vendorRoot, "darwin", "mpv.app");
    await fs.rm(destination, { recursive: true, force: true });
    await fs.mkdir(path.dirname(destination), { recursive: true });
    await fs.cp(appPath, destination, { recursive: true });
    await fs.chmod(path.join(destination, "Contents", "MacOS", "mpv"), 0o755);
    console.log(`Prepared bundled macOS mpv at ${path.relative(projectRoot, destination)}`);
  } finally {
    await fs.rm(tempDir, { recursive: true, force: true });
  }
}

async function prepareWindowsMpv(arch) {
  const assetPattern =
    arch === "arm64"
      ? /^mpv-aarch64-\d{8}-git-[a-f0-9]+\.7z$/
      : /^mpv-x86_64-\d{8}-git-[a-f0-9]+\.7z$/;
  const release = await fetchJson("https://api.github.com/repos/shinchiro/mpv-winbuild-cmake/releases/latest");
  const asset = release.assets?.find((candidate) => assetPattern.test(candidate.name));
  if (!asset?.browser_download_url) {
    throw new Error("Unable to find a suitable Windows mpv release asset");
  }

  const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "iptv-player-mpv-win32-"));
  try {
    const archivePath = path.join(tempDir, asset.name);
    await downloadFile(asset.browser_download_url, archivePath);
    if (typeof asset.digest === "string" && asset.digest.startsWith("sha256:")) {
      await verifySha256(archivePath, asset.digest.slice("sha256:".length));
    }

    const extractedDir = path.join(tempDir, "extracted");
    await fs.mkdir(extractedDir, { recursive: true });
    execFileSync(path7za, ["x", archivePath, `-o${extractedDir}`, "-y"], { stdio: "inherit" });

    const mpvExecutable = await findPath(extractedDir, "mpv.exe");
    if (!mpvExecutable) {
      throw new Error("Downloaded Windows mpv archive did not contain mpv.exe");
    }

    const destination = path.join(vendorRoot, "win32");
    await fs.rm(destination, { recursive: true, force: true });
    await fs.mkdir(destination, { recursive: true });
    await fs.cp(path.dirname(mpvExecutable), destination, { recursive: true });
    await pruneWindowsBundle(destination);
    console.log(`Prepared bundled Windows mpv at ${path.relative(projectRoot, destination)}`);
  } finally {
    await fs.rm(tempDir, { recursive: true, force: true });
  }
}

async function fetchJson(url) {
  const response = await fetch(url, { headers: { "User-Agent": userAgent } });
  if (!response.ok) {
    throw new Error(`Request failed with HTTP ${response.status}: ${url}`);
  }
  return response.json();
}

async function downloadFile(url, destination) {
  const response = await fetch(url, { headers: { "User-Agent": userAgent } });
  if (!response.ok) {
    throw new Error(`Download failed with HTTP ${response.status}: ${url}`);
  }

  const body = Buffer.from(await response.arrayBuffer());
  await fs.writeFile(destination, body);
}

async function verifySha256(filePath, expectedHash) {
  const body = await fs.readFile(filePath);
  const actualHash = createHash("sha256").update(body).digest("hex");
  if (actualHash !== expectedHash) {
    throw new Error(`Checksum mismatch for ${path.basename(filePath)}. Expected ${expectedHash}, got ${actualHash}.`);
  }
}

async function pruneWindowsBundle(destination) {
  for (const name of ["doc", "installer", "updater.bat", "mpv.com"]) {
    await fs.rm(path.join(destination, name), { recursive: true, force: true });
  }
}

async function findPath(root, basename) {
  const entries = await fs.readdir(root, { withFileTypes: true });
  for (const entry of entries) {
    const candidate = path.join(root, entry.name);
    if (entry.name === basename) {
      return candidate;
    }
    if (entry.isDirectory()) {
      const nested = await findPath(candidate, basename);
      if (nested) {
        return nested;
      }
    }
  }
  return null;
}
