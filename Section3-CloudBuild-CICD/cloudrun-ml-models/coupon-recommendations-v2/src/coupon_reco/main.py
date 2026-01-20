from __future__ import annotations

from coupon_reco.app import app
from coupon_reco.config import Settings


def main() -> None:
    settings = Settings()
    app.run(host="0.0.0.0", port=settings.PORT)


if __name__ == "__main__":
    main()
