from contextlib import contextmanager
from pathlib import Path
import re


PYPROJECT_PATH = Path(__file__).resolve().with_name("pyproject.toml")
JULIA_PROJECT_PATH = Path(__file__).resolve().parents[2] / "Project.toml"
VERSION_PATTERN = re.compile(r'(?m)^version\s*=\s*"([^"]+)"\s*$')


def _read_julia_version() -> str:
    project_text = JULIA_PROJECT_PATH.read_text(encoding="utf-8")
    match = VERSION_PATTERN.search(project_text)
    if match is None:
        raise RuntimeError(f"Could not find version in {JULIA_PROJECT_PATH}")
    return match.group(1)


@contextmanager
def _synced_pyproject():
    original = PYPROJECT_PATH.read_text(encoding="utf-8")
    version = _read_julia_version()

    match = VERSION_PATTERN.search(original)
    if match is None:
        raise RuntimeError(f"Could not find version in {PYPROJECT_PATH}")

    updated = VERSION_PATTERN.sub(f'version = "{version}"', original, count=1)
    if updated != original:
        PYPROJECT_PATH.write_text(updated, encoding="utf-8")

    try:
        yield
    finally:
        if updated != original:
            PYPROJECT_PATH.write_text(original, encoding="utf-8")


def _delegate(hook_name: str, *args, **kwargs):
    from hatchling import build as hatchling_build

    with _synced_pyproject():
        return getattr(hatchling_build, hook_name)(*args, **kwargs)


def build_wheel(wheel_directory, config_settings=None, metadata_directory=None):
    return _delegate(
        "build_wheel",
        wheel_directory,
        config_settings=config_settings,
        metadata_directory=metadata_directory,
    )


def build_sdist(sdist_directory, config_settings=None):
    return _delegate("build_sdist", sdist_directory, config_settings=config_settings)


def build_editable(wheel_directory, config_settings=None, metadata_directory=None):
    return _delegate(
        "build_editable",
        wheel_directory,
        config_settings=config_settings,
        metadata_directory=metadata_directory,
    )


def get_requires_for_build_wheel(config_settings=None):
    return _delegate("get_requires_for_build_wheel", config_settings=config_settings)


def get_requires_for_build_sdist(config_settings=None):
    return _delegate("get_requires_for_build_sdist", config_settings=config_settings)


def get_requires_for_build_editable(config_settings=None):
    return _delegate("get_requires_for_build_editable", config_settings=config_settings)


def prepare_metadata_for_build_wheel(metadata_directory, config_settings=None):
    return _delegate(
        "prepare_metadata_for_build_wheel",
        metadata_directory,
        config_settings=config_settings,
    )


def prepare_metadata_for_build_editable(metadata_directory, config_settings=None):
    return _delegate(
        "prepare_metadata_for_build_editable",
        metadata_directory,
        config_settings=config_settings,
    )