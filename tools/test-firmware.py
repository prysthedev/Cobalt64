"""Run the firmware scripts against a disposable synthetic checkout."""

import hashlib
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


TOOLS = Path(__file__).resolve().parent


class FirmwareStaging(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.tools = self.root / "tools"
        self.tools.mkdir()
        self.source = self.root / "linux-firmware"
        self.blobs = self.source / "amdgpu"
        self.blobs.mkdir(parents=True)
        self.destination = self.root / "src/navi48-bringup/firmware"
        self.license = self.source / "LICENSE.amdgpu"
        self.license.write_bytes(b"Synthetic test license\n")
        for script in ("verify-dependencies.sh", "fetch-firmware.sh"):
            shutil.copyfile(TOOLS / script, self.tools / script)
        names = [line.split()[0] for line in
                 (TOOLS / "firmware-sha256.txt").read_text().splitlines()]
        self.assertEqual(len(set(names)), 10)
        manifest = []
        for name in names:
            data = name.encode()
            (self.blobs / f"{name}.bin").write_bytes(data)
            manifest.append(f"{name} {hashlib.sha256(data).hexdigest()}\n")
        (self.tools / "firmware-sha256.txt").write_bytes("".join(manifest).encode())
        self.blob = self.blobs / f"{names[-1]}.bin"

    def run_script(self, name):
        return subprocess.run(
            [shutil.which("bash") or "bash", f"tools/{name}.sh", "linux-firmware"],
            cwd=self.root, capture_output=True, text=True, check=False,
        )

    def stage(self):
        result = self.run_script("fetch-firmware")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(list(self.destination.glob("*.bin"))), 10)
        self.assertEqual((self.destination / self.blob.name).read_bytes(),
                         self.blob.stem.encode())
        self.assertEqual((self.destination / self.license.name).read_bytes(),
                         self.license.read_bytes())

    def test_matching_firmware(self):
        result = self.run_script("verify-dependencies")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.destination.exists())
        self.stage()

    def assert_preflight_failure(self, diagnostic):
        result = self.run_script("fetch-firmware")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn(diagnostic, result.stderr)
        self.assertFalse(self.destination.exists())

    def test_mismatch(self):
        self.blob.write_bytes(b"wrong")
        self.assert_preflight_failure("SHA-256 mismatch")

    def test_missing_blob(self):
        self.blob.unlink()
        self.assert_preflight_failure("Missing firmware")

    def test_missing_license(self):
        self.license.unlink()
        self.assert_preflight_failure("Missing or empty AMD license")

    @unittest.skipUnless(shutil.which("zstd"), "zstd executable required")
    def test_compressed_firmware(self):
        subprocess.run(["zstd", "-q", self.blob.name], cwd=self.blobs, check=True)
        self.blob.unlink()
        self.stage()


if __name__ == "__main__":
    unittest.main()
