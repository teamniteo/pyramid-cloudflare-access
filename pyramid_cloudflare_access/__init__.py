"""Verify Cloudflare Access requests."""

from jwt import decode as jwt_decode
from jwt import PyJWKClient
from jwt.api_jwk import PyJWK
from pyramid.config import Configurator
from pyramid.request import Request
from pyramid.tweens import INGRESS

import pyramid.httpexceptions as exc
import typing as t


def includeme(config: Configurator):
    # as possibly first tween in chain, order does not matter
    config.add_tween("pyramid_cloudflare_access.CloudflareAccess", over=INGRESS)


def _get_public_keys(team: str) -> t.List[PyJWK]:
    """Get JWK public keys for a team."""

    url = f"{team}/cdn-cgi/access/certs"
    client = PyJWKClient(url, cache_keys=False)
    return client.get_signing_keys()


class CloudflareAccess:
    """Deny access to Pyramid app when CF Access token is missing or invalid.

    ref: https://developers.cloudflare.com/cloudflare-one/identity/users/validating-json#python-example
    """

    def __init__(self, handler, registry):
        settings = getattr(registry, "settings", {})
        self.policy_audience = settings["pyramid_cloudflare_access.policy_audience"]
        self.public_keys = _get_public_keys(settings["pyramid_cloudflare_access.team"])

    def valid_request(self, request: Request) -> bool:
        token = request.cookies.get("CF_Authorization")

        if not token:
            raise exc.HTTPBadRequest()

        # Loop through the keys since we can't pass the key set to the decoder
        token_valid = False
        for key in self.public_keys:
            try:
                # decode returns the claims and verifies token against public keys
                claims = jwt_decode(
                    token, key=key, audience=self.policy_audience, algorithms=["RS256"]
                )
                token_valid = claims is not None
            except:
                pass

        return token_valid

    def __call__(self, request: Request):

        if not self.valid_request(request):
            raise exc.HTTPForbidden()

        return self.handler(request)
