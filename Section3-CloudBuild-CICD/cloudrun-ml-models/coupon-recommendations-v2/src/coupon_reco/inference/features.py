from __future__ import annotations

import pandas as pd
from category_encoders import HashingEncoder


def preprocess_data(df: pd.DataFrame) -> pd.DataFrame:
    """Clean and feature-engineer raw request data.

    The logic is carried over from the original course project.
    """
    df = df.fillna(df.mode().iloc[0])
    df = df.drop_duplicates()

    df_fe = df.copy()

    age_mapping = {
        "below21": "<21",
        "21": "21-30",
        "26": "21-30",
        "31": "31-40",
        "36": "31-40",
        "41": "41-50",
        "46": "41-50",
    }
    df_fe["age"] = [age_mapping.get(str(v), ">50") for v in df_fe["age"]]

    df_fe["passanger_destination"] = df_fe["passanger"].astype(str) + "-" + df_fe["destination"].astype(str)
    df_fe["marital_hasChildren"] = df_fe["maritalStatus"].astype(str) + "-" + df_fe["has_children"].astype(str)
    df_fe["temperature_weather"] = df_fe["temperature"].astype(str) + "-" + df_fe["weather"].astype(str)

    df_fe = df_fe.drop(
        columns=["passanger", "destination", "maritalStatus", "has_children", "temperature", "weather"],
        errors="ignore",
    )
    df_fe = df_fe.drop(columns=["gender", "RestaurantLessThan20"], errors="ignore")

    df_le = df_fe.replace(
        {
            "expiration": {"2h": 0, "1d": 1},
            "age": {"<21": 0, "21-30": 1, "31-40": 2, "41-50": 3, ">50": 4},
            "education": {
                "Some High School": 0,
                "High School Graduate": 1,
                "Some college - no degree": 2,
                "Associates degree": 3,
                "Bachelors degree": 4,
                "Graduate degree (Masters or Doctorate)": 5,
            },
            "Bar": {"never": 0, "less1": 1, "1~3": 2, "4~8": 3, "gt8": 4},
            "CoffeeHouse": {"never": 0, "less1": 1, "1~3": 2, "4~8": 3, "gt8": 4},
            "CarryAway": {"never": 0, "less1": 1, "1~3": 2, "4~8": 3, "gt8": 4},
            "Restaurant20To50": {"never": 0, "less1": 1, "1~3": 2, "4~8": 3, "gt8": 4},
            "income": {
                "Less than $12500": 0,
                "$12500 - $24999": 1,
                "$25000 - $37499": 2,
                "$37500 - $49999": 3,
                "$50000 - $62499": 4,
                "$62500 - $74999": 5,
                "$75000 - $87499": 6,
                "$87500 - $99999": 7,
                "$100000 or More": 8,
            },
            "time": {"7AM": 0, "10AM": 1, "2PM": 2, "6PM": 3, "10PM": 4},
        }
    )

    return df_le


def encode_features(x: pd.DataFrame, n_components: int = 27) -> pd.DataFrame:
    """Hash-encode a subset of categorical features."""
    cols = ["passanger_destination", "marital_hasChildren", "occupation", "coupon", "temperature_weather"]
    enc = HashingEncoder(cols=cols, n_components=n_components).fit(x)
    x_encoded = enc.transform(x.reset_index(drop=True))
    return x_encoded


def preprocess_request(payload: dict) -> pd.DataFrame:
    """Convert JSON payload to model-ready features."""
    if not isinstance(payload, dict):
        raise ValueError("Request JSON must be an object/dictionary")

    df = pd.DataFrame(payload, index=[0])
    x = preprocess_data(df)
    x_encoded = encode_features(x)
    x_encoded = x_encoded.fillna(0)
    return x_encoded
