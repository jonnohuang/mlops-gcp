from __future__ import annotations

from flask import Flask

from coupon_reco.api.routes import bp
from coupon_reco.config import Settings
from coupon_reco.logging import configure_logging


def create_app() -> Flask:
    settings = Settings()
    configure_logging(settings.LOG_LEVEL)

    app = Flask(__name__)
    app.register_blueprint(bp)
    return app


# Gunicorn entrypoint
app = create_app()
