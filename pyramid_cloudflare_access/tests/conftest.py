"""
Pytest fixtures
"""
from zope.testing.loggingsupport import InstalledHandler

import pytest


@pytest.fixture(scope="session")
def tween_handler():
    yield InstalledHandler("pyramid_cloudflare_access")
