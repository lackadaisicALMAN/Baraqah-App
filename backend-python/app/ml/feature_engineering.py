"""Feature extraction from raw PostgreSQL and MongoDB data."""

from datetime import datetime
from typing import Any


def extract_user_features(pg_user: dict, mongo_profile: dict | None) -> dict[str, Any]:
    """Build a normalized feature dict for a user."""
    prefs = (mongo_profile or {}).get("preference_vector", {})

    cuisine_weights = prefs.get("cuisine_weights", {})
    if isinstance(cuisine_weights, dict):
        cuisine_map = cuisine_weights
    else:
        cuisine_map = dict(cuisine_weights) if cuisine_weights else {}

    return {
        "user_id": pg_user["id"],
        "baraqah_score": float(pg_user.get("baraqah_score", 50)),
        "total_sessions": int(pg_user.get("total_sessions", 0)),
        "total_hosted": int(pg_user.get("total_hosted", 0)),
        "total_no_shows": int(pg_user.get("total_no_shows", 0)),
        "cuisine_weights": cuisine_map,
        "price_range_preference": prefs.get("price_range_preference", 2),
        "transport_preference": prefs.get("transport_preference", "NO_PREFERENCE"),
        "social_comfort_level": float(prefs.get("social_comfort_level", 0.5)),
        "dietary_restrictions": prefs.get("dietary_restrictions", []),
        "avg_session_rating_given": float(prefs.get("avg_session_rating_given", 3.0)),
        "preferred_group_size": prefs.get(
            "preferred_group_size", {"min": 2, "max": 6}
        ),
    }


def extract_session_features(session: dict, restaurant: dict) -> dict[str, Any]:
    """Build feature dict for a dining session."""
    scheduled = session.get("scheduled_at")
    if isinstance(scheduled, str):
        scheduled = datetime.fromisoformat(scheduled.replace("Z", "+00:00"))

    hour = scheduled.hour if scheduled else 12
    day_of_week = scheduled.strftime("%a").upper()[:3] if scheduled else "MON"
    day_map = {"MON": "MON", "TUE": "TUE", "WED": "WED", "THU": "THU",
               "FRI": "FRI", "SAT": "SAT", "SUN": "SUN"}
    dow = day_map.get(day_of_week, "MON")

    return {
        "session_id": session["id"],
        "host_user_id": session["host_user_id"],
        "restaurant_id": session["restaurant_id"],
        "restaurant_name": restaurant.get("name", ""),
        "food_category": session.get("food_category", ""),
        "cuisine_tags": restaurant.get("cuisine_tags", []),
        "price_range": restaurant.get("price_range", 2),
        "scheduled_at": scheduled.isoformat() if scheduled else None,
        "scheduled_hour": hour,
        "day_of_week": dow,
        "max_attendees": int(session.get("max_attendees", 4)),
        "current_attendees": int(session.get("current_attendees", 1)),
        "has_ride_available": session.get("has_ride_available", False),
        "split_type": session.get("split_type", "EQUAL"),
        "distance_km": float(session.get("distance_km", 0)),
        "host_baraqah_score": float(session.get("host_score", 50)),
    }


def build_preference_vector(user_features: dict) -> list[float]:
    """Convert user features to a numeric vector for similarity computation."""
    cuisine_keys = [
        "Desi", "Chinese", "Fast Food", "BBQ", "Karahi",
        "Continental", "Japanese", "Italian",
    ]
    cuisine_vec = [
        float(user_features.get("cuisine_weights", {}).get(c, 0.0))
        for c in cuisine_keys
    ]

    return cuisine_vec + [
        user_features["price_range_preference"] / 4.0,
        user_features["social_comfort_level"],
        min(user_features["baraqah_score"] / 100.0, 1.0),
        min(user_features["total_sessions"] / 50.0, 1.0),
        1.0 - min(user_features["total_no_shows"] / 10.0, 1.0),
        user_features["avg_session_rating_given"] / 5.0,
        1.0 if user_features["transport_preference"] == "RIDE_TOGETHER" else 0.0,
    ]


def build_session_vector(session_features: dict, user_features: dict) -> list[float]:
    """Build session-side vector aligned with user preference vector."""
    cuisine_keys = [
        "Desi", "Chinese", "Fast Food", "BBQ", "Karahi",
        "Continental", "Japanese", "Italian",
    ]

    food_cat = session_features.get("food_category", "")
    cuisine_vec = [
        1.0 if food_cat.lower() in c.lower() or c.lower() in food_cat.lower() else 0.0
        for c in cuisine_keys
    ]

    group_size = session_features["current_attendees"]
    pref_size = user_features.get("preferred_group_size", {"min": 2, "max": 6})
    size_fit = 1.0 if pref_size["min"] <= group_size <= pref_size["max"] else 0.5

    return cuisine_vec + [
        (session_features.get("price_range") or 2) / 4.0,
        size_fit,
        session_features["host_baraqah_score"] / 100.0,
        min(group_size / session_features["max_attendees"], 1.0),
        1.0 - min(session_features["distance_km"] / 20.0, 1.0),
        session_features["scheduled_hour"] / 23.0,
        1.0 if session_features["has_ride_available"] else 0.0,
    ]
